# Research — Comptes, authentification OTP et rôles (cycle 003)

Toutes les inconnues du Technical Context sont résolues ici. Format : Décision /
Rationale / Alternatives considérées. Les faits sur l'existant viennent du
rapport d'exploration du monorepo (cycles 001/002 livrés).

## R1 — Jeton d'accès : JWT HS256, 15 minutes, sans rôles embarqués

**Décision** : `jsonwebtoken` (dernière stable), algorithme HS256, secret 256
bits via env `JWT_SECRET`. Claims : `sub` (compte_id), `sid` (session_id),
`iat`, `exp` (= iat + 15 min). Les rôles ne sont PAS embarqués dans le jeton.

**Rationale** : un seul émetteur et un seul vérificateur (le monolithe) —
la crypto asymétrique n'apporte rien ici. 15 min borne l'effet d'une révocation
(SC-004). Les rôles restent hors du jeton parce que la spec exige la prise
d'effet immédiate d'une suspension (US3 scénario 6) : ils sont lus en base à
chaque requête (R5) ; un jeton porteur de rôles resterait valide 15 min après
une suspension.

**Alternatives considérées** : EdDSA/RS256 (utile seulement avec des
vérificateurs tiers — aucun au MVP) ; PASETO/Biscuit (écosystème Rust moins
mature côté outillage, aucun besoin des capacités avancées) ; sessions
opaques pures en DB (une requête de plus par requête même non-rôle ; le JWT
courtcircuite la DB pour l'identité, la DB reste l'autorité pour les rôles).

## R2 — Refresh : jeton opaque, rotation à chaque usage, détection de réutilisation

**Décision** : jeton de rafraîchissement opaque de 256 bits (CSPRNG `rand`),
stocké haché SHA-256 (`sha2`, déjà au workspace) dans `comptes.session`
(colonnes `refresh_hash` + `refresh_precedent_hash`). À chaque
`/auth/rafraichir` : nouveau jeton, l'ancien hash glisse dans
`refresh_precedent_hash`. Si un jeton présenté correspond à
`refresh_precedent_hash` (réutilisation d'un jeton déjà tourné) → la session
entière est révoquée. Aucune expiration propre (clarification du 2026-07-14) ;
`derniere_activite_le` tenue à jour.

**Rationale** : opaque = révocable instantanément par simple lookup indexé,
contrairement à un JWT. La rotation avec détection de réutilisation est la
défense standard contre le vol de refresh (un voleur ou le légitime finit par
rejouer un jeton tourné → tout tombe). La session illimitée est le choix
clarifié : la sécurité d'un appareil perdu repose sur la déconnexion à
distance (US2) — satisfait le principe VIII (« révocable », aucune durée
imposée).

**Alternatives considérées** : refresh JWT (révocation = liste noire, plus
complexe que l'inverse) ; expiration glissante 30/90 j (rejetée par
clarification — coût SMS et friction pour un client occasionnel) ; famille de
jetons multi-lignes (table dédiée : sur-ingénierie, deux colonnes suffisent
pour détecter la réutilisation immédiate).

## R3 — OTP et compteurs : Redis derrière le port `DepotEphemere`

**Décision** : première connexion Redis réelle du backend (`deadpool-redis`,
déjà au workspace), encapsulée derrière un trait `DepotEphemere` défini dans
le crate `comptes` :

- `otp:defi:{e164}` — hash du code (HMAC-SHA256, clé dérivée de `JWT_SECRET`),
  essais restants, TTL 300 s ; toute nouvelle demande ÉCRASE la clé
  (invalidation de l'ancien code, FR-002) ; décrément d'essai atomique.
- `otp:sms:{e164}` — compteur INCR + EXPIRE 3600 s (plafond 3, FR-003).
- `otp:ip:{ip}` — compteur INCR + EXPIRE 3600 s (plafond 10, R12).
- `insc:{jeton}` — jeton d'inscription 128 bits, payload {e164, zone, appareil},
  TTL 600 s, usage unique (GETDEL). L'appareil fourni à la vérification est
  conservé dans le payload : `/auth/inscription` crée la session
  (`session.appareil_*` NOT NULL) sans le redemander (analyze C1).

Deux implémentations : `RedisEphemere` (prod, atomicité par script Lua pour
« vérifier-et-décrémenter ») et `MemoireEphemere` (tests — horloge injectable
pour tester l'expiration sans attendre).

**Rationale** : conforme constitution II — un défi OTP perdu (redémarrage
Redis) coûte une re-demande de code, rien d'autre : éphémère reconstructible,
Postgres n'est pas pollué par des données à durée de vie de 5 min. Le rôle
« rate-limiting OTP » de Redis est explicitement prévu au cadrage §10.3. Le
hachage du code est une défense de surface (un dump Redis n'expose pas les
codes en clair) — la vraie protection d'un code à 10⁶ combinaisons est le
trio TTL 5 min + 3 essais atomiques + plafond SMS, pas le hash.

**Alternatives considérées** : table Postgres `defi_otp` (durable pour une
donnée jetable, nettoyage à orchestrer, contredit « Postgres = vérité
durable ») ; fenêtre glissante pour le compteur SMS (ZADD/ZRANGEBYSCORE —
précision inutile : la fenêtre fixe d'une heure satisfait « 3 SMS/h » au sens
produit) ; argon2 sur le code OTP (coût CPU par essai sans gain réel — l'espace
de recherche est 10⁶, la protection vient des essais limités).

## R4 — E.164 : crate `phonenumber`, indicatif par défaut en paramètre de zone

**Décision** : parsing/validation par le crate `phonenumber` (port Rust de
libphonenumber). La demande d'OTP porte `{telephone, zone}` ; l'indicatif par
défaut est lu via `ConfigurationZones::parametre(zone, "telephone.indicatif_defaut")`
(seed : `"+225"` posé sur Côte d'Ivoire, hérité par Tiassalé). Une saisie
locale sans indicatif est interprétée dans la région par défaut de la zone ;
un numéro complet (`+…`) est validé tel quel ; non normalisable → 422 avec
message de format neutre.

**Rationale** : la normalisation maison des numéros ivoiriens (renumérotation
2021, mobiles à 10 chiffres) est un piège connu ; libphonenumber la connaît.
L'indicatif en paramètre de zone est exigé par la spec (FR-001, FR-024) et
prépare les villes/pays suivants sans code.

**Alternatives considérées** : regex E.164 simple + préfixe (+225) en dur
(violerait FR-024 et casserait à la première zone hors CI) ; validation par
SMS seul sans validation de format (gaspille le quota SMS sur des numéros
impossibles).

## R5 — Extracteur `Auth` + `exiger_role` ; remplacement d'`AdminAuth`

**Décision** : nouvel extracteur Actix `Auth` (couche `api`,
`auth_http.rs`) : valide signature + exp du JWT, puis UNE requête indexée qui
charge en un aller la session (non révoquée) et les rôles au statut `valide`
du compte. Méthode `exiger_role(Role)` → 403 `comptes.erreur.role_requis`.
L'extracteur temporaire `AdminAuth` (X-Admin-Token, `zones_http.rs`) est
SUPPRIMÉ : `forcer_categorie` prend `Auth` + `exiger_role(Admin)` sans changer
sa logique (isolation prévue au cycle 002, research R5 de ce cycle-là).
`ADMIN_API_TOKEN` disparaît de `socle::Config` et d'`infra/.env.example` ;
le `SecurityScheme` OpenAPI `adminToken` (ApiKey header) devient `bearerAuth`
(HTTP bearer JWT).

**Rationale** : le contrôle en base à chaque requête donne la prise d'effet
immédiate des suspensions (US3) ET rend la révocation de session effective
avant même l'expiration du jeton court — mieux que l'exigence SC-004, pour le
prix d'un SELECT indexé (< 5 ms, trivial à l'échelle d'un VPS mono-ville). Le
remplacement d'AdminAuth était le contrat passé au cycle 002.

**Alternatives considérées** : rôles dans le JWT + cache (prise d'effet
différée de 15 min — contredit la spec) ; cache mémoire des rôles à TTL court
(complexité d'invalidation pour économiser des millisecondes non demandées) ;
garder X-Admin-Token en parallèle (deux systèmes d'auth = surface doublée).

## R6 — SMS : port `EnvoiSms`, fournisseur différé au cycle NTF

**Décision** : trait `EnvoiSms` dans le crate `comptes`
(`envoyer(e164, message_cle, params) -> Result<(), ErreurSms>`). Ce cycle
livre `SmsTraces` (journalise le message via `tracing` — dev, tests, staging)
sélectionnée par env `SMS_MODE=traces`. Le choix du fournisseur SMS réel
(agrégateur local type LeTexto/Orange CI — annexe B du cadrage, non tranchée)
et son implémentation appartiennent au cycle NTF (§10.8 : « SMS limités :
OTP + fallback »), qui fournira l'impl production du même port.

**Rationale** : le cadrage réserve la décision fournisseur (annexe B) ; CPT ne
doit pas la préempter. Le port permet de tester tout le flux OTP (dont la
neutralité) sans réseau, et le branchement NTF ne touchera ni le domaine ni
les handlers.

**Alternatives considérées** : intégrer un fournisseur maintenant (décision
produit non prise, KYB non fait — hors périmètre) ; passer par l'outbox pour
les SMS (l'OTP exige une latence de secondes ; l'outbox est un canal
at-least-once différé — inadapté au chemin chaud, reste pertinent pour le
fallback NTF-02).

## R7 — Stockage objet : aws-sdk-s3 vers Garage, upload via l'API, URLs présignées en lecture

**Décision** : premier usage réel de Garage via `aws-sdk-s3` (déjà au
workspace) : endpoint override `S3_ENDPOINT` + `force_path_style(true)`,
bucket privé unique `S3_BUCKET`. Port `DepotObjets` (put/presign_get/delete)
avec impl `S3Objets` (prod) et `MemoireObjets` (tests). Uploads ENTRANTS via
l'API (`actix-multipart`) : pièce d'identité ≤ 10 Mo (jpeg/png/webp/pdf), note
vocale ≤ 1,5 Mo (m4a/aac, durée déclarée ≤ paramètre de zone
`medias.note_vocale_duree_max_s`). Clés : `comptes/pieces/{compte_id}/{uuidv7}`
et `comptes/reperes/{compte_id}/{uuidv7}`. Lectures par URL présignée GET
(TTL 10 min) émise derrière un endpoint authentifié : la pièce pour l'admin,
le repère vocal pour son propriétaire (la lecture coursier arrive au cycle
CRS).

**Rationale** : cadrage §10.4 — Garage remplace MinIO (décision 2026-07-13,
constitution 1.0.1 ; le « MinIO » de l'input du plan est l'ancien libellé),
périmètre S3 requis vérifié au POC = put/get, multipart, présignées. L'upload
via l'API garde le bucket totalement privé et la validation (taille, type,
appartenance) côté serveur — à 2–4 coursiers et quelques adresses/jour, la
bande passante du VPS n'est pas un sujet pour l'ENTRANT ; les lectures,
potentiellement répétées (écoute du repère), sortent en présigné.

**Alternatives considérées** : presigned PUT pour l'upload (le client écrit
directement au bucket : validation de contenu après coup, politique de clés à
verrouiller — complexité sans bénéfice à cette échelle) ; proxy intégral des
lectures (double la bande passante sortante pour rien — écart VIII justifié au
plan) ; bucket par usage (l'init Garage du compose en provisionne un ; les
préfixes de clés suffisent au MVP).

## R8 — Purge des repères vocaux : job quotidien, transition en base d'abord

**Décision** : tâche `tokio` quotidienne dans le binaire `api` (même patron
que `WorkerOutbox`) : sélectionne les adresses non supprimées dont
`derniere_utilisation_le < now() - interval retention` (retention lue par zone
via `ConfigurationZones` : `adresse.retention_repere_vocal_jours`, seed 365 —
clarification « 12 mois »), puis PAR adresse : transaction Postgres
(`repere_vocal_cle_objet` → NULL + événement outbox
`adresse.repere_vocal_purge`) puis suppression S3 best-effort (échec →
journalisé, re-tenté au prochain passage via un balayage des clés orphelines).

**Rationale** : la vérité (l'adresse n'a plus de repère vocal) vit dans
Postgres et est émise atomiquement (constitution VI) ; l'objet S3 est un
artefact dont la suppression peut se rattraper — l'inverse (S3 d'abord)
laisserait des adresses pointant vers du vide en cas de crash entre les deux.

**Alternatives considérées** : TTL/lifecycle côté Garage (les règles de cycle
de vie S3 ne connaissent pas « dernière utilisation » métier) ; purge à la
lecture (lazy — laisse traîner les données au repos, contraire à la
minimisation ARTCI) ; pg_cron (dépendance infra de plus pour un intervalle
que tokio fait très bien dans le process existant).

## R9 — Une seule machine à états : le statut vit sur l'attribution de rôle

**Décision** : `comptes.attribution_role (compte_id, role, statut, motif,
decide_par, decide_le, demande_le)` porte l'UNIQUE machine à états. Le
« statut du dossier » (FR-016) EST le statut de l'attribution `coursier` — le
`dossier_coursier` ne porte que le contenu (pièce, référent), les véhicules
dans `vehicule_declare`. Transitions coursier : ∅ → `en_attente` (soumission
du dossier) → `valide` | `refuse` ; `refuse` → `en_attente` (re-soumission) ;
`valide` ⇄ `suspendu` (suspendre/rétablir). Vendeur : ∅ → `valide`
(attribution à l'agrément, clarification §5.1) ; `valide` ⇄ `suspendu`.
Client : `valide` à l'inscription, immuable ce cycle. Admin : `valide` par
seed ou attribution par un admin (FR-012).

**Rationale** : deux statuts (rôle + dossier) divergeraient fatalement — une
seule source de vérité, exposée sous les deux noms dans l'API (le DTO dossier
inclut le statut du rôle). La machine reste testable exhaustivement
(constitution VII) : 6 transitions coursier, 3 vendeur, 2 attributions.

**Alternatives considérées** : statut dupliqué sur le dossier (synchronisation
= bugs) ; table d'historique des décisions dédiée (le journal exigé par FR-014
est déjà porté par les colonnes de dernière décision + les événements outbox —
patron du cycle 002 pour le forçage de catégorie).

## R10 — Événements outbox (registre à jour AVANT implémentation)

**Décision** : 14 événements ajoutés à `docs/taxonomie-evenements.md`
(convention `<entite>.<action au participe passé>`, propriétés standard zone/
role) : `compte.cree` (consentement version incluse), `session.creee`,
`session.revoquee` (par qui : locale/à distance/réutilisation détectée),
`role.demande`, `role.attribue` (vendeur/admin par admin), `role.valide`,
`role.refuse`, `role.suspendu`, `role.retabli`, `dossier_coursier.soumis`
(re-soumission incluse, drapeau), `adresse.enregistree`, `adresse.modifiee`,
`adresse.supprimee`, `adresse.repere_vocal_purge`. Chaque événement est écrit
via `socle::ecrire_evenement(&mut tx, …)` dans la transaction de la
transition. Les demandes/vérifications OTP n'émettent PAS d'événement outbox
(pas une transition d'entité durable) — les métriques d'entonnoir
d'inscription viendront de la taxonomie produit du cycle MET.

**Rationale** : constitution VI + DoD §0.4. La granularité suit les
transitions réelles des machines à états de R9 ; le payload porte
`decide_par`/`motif` pour servir de journal admin (FR-014).

**Alternatives considérées** : événement générique `role.transitionne` avec
état avant/après (moins lisible dans le registre, filtres consommateurs plus
fragiles) ; émettre aussi `otp.demande` (bruit sans entité durable — rejoint
la taxonomie produit MET, pas l'outbox).

## R11 — Flutter : module d'auth partagé dans mefali_core, plugins natifs stabilisés tôt

**Décision** : `mefali_core` gagne trois sous-modules : `auth/`
(`SessionAuth` — stockage des jetons via `flutter_secure_storage`,
intercepteur dio sur le client généré : Authorization + refresh automatique
sur 401 + déconnexion propre sur échec ; écrans partagés `EcranTelephone`,
`EcranOtp` à 6 cases avec compte à rebours de renvoi, `EcranConsentement`),
`adresses/` (`ListeAdresses`, `FeuilleEnregistrerAdresse` avec chips
Maison/Bureau/libre, `LecteurNoteVocale` (`just_audio`),
`EnregistreurNoteVocale` (`record`, borné par le paramètre de zone)),
`appareils/` (`EcranAppareils` : liste + déconnexion à distance).
`mefali_pro` ajoute le routeur d'accueil par rôle validé (bascule
coursier/vendeur sans reconnexion, état de demande sinon) et
`FormulaireDossierCoursier` (photo de pièce via `image_picker`, véhicules
cochés depuis `transport.actifs` de la config distante déjà servie par
`ServiceConfig`, référent). `mefali_client` branche navigation
(splash → auth → accueil provisoire) et paramètres. Aucun PNG cible n'existe
pour ces parcours (exploration §10) : conception directe depuis
`docs/design/tokens.md` (plancher 16 px, actions principales en bas, cibles
≥ 48 dp, bouton primaire 56 px), widgets M3 `.adaptive`, pas de mode sombre.

**Rationale** : les deux apps partagent tout le parcours d'auth (constitution
XI : composants canoniques dans `mefali_core`) ; le cadrage §10.1 impose de
stabiliser tôt les plugins natifs (caméra, audio) parce que Shorebird ne
patche que le Dart — les ajouter à CE cycle évite un passage store plus tard.
La proposition d'enregistrement d'adresse est un composant déclenché par
événement de livraison : ce cycle le livre et le teste avec un déclencheur
simulé (assumption de la spec), CMD/CRS le brancheront.

**Alternatives considérées** : écrans dupliqués par app (dérive visuelle
garantie) ; `shared_preferences` pour les jetons (non chiffré — inacceptable
pour un refresh sans expiration) ; reporter les plugins audio/caméra au cycle
CMD (passage store supplémentaire, contraire à §10.1).

## R12 — Anti-abus complémentaire : plafond par IP sur la demande d'OTP

**Décision** : en plus du Governor global par IP (cycle 002) et du plafond
3 SMS/h/numéro, la demande d'OTP porte un plafond de 10 demandes/h/IP
(compteur `DepotEphemere`, constante produit). Réponse au plafond : la même
202 neutre que le succès (aucun canal d'énumération ni d'oracle de quota).

**Rationale** : le plafond par numéro ne protège pas du « SMS pumping »
(beaucoup de numéros, une IP) — première cause de facture SMS qui explose.
La réponse neutre préserve SC-003.

**Alternatives considérées** : CAPTCHA (friction disproportionnée au MVP,
dépendance tierce) ; plafond global quotidien (utile plus tard côté NTF —
constante d'exploitation, pas de quoi bloquer ce cycle).

## R13 — Zone de rattachement du compte

**Décision** : l'app envoie sa zone (bootstrap Tiassalé, constante
`zoneBootstrapTiassale` déjà présente dans `mefali_core`) dans la demande
d'OTP et l'inscription ; le compte est créé rattaché à cette zone
(FK `zones.zone`). La sélection fine de zone par adresse arrive avec
CPT-05/CMD-02 côté commande (commentaire déjà présent dans `mefali_core`).

**Rationale** : mono-ville au MVP, mais le rattachement est structurel
(indicatif, paramètres, devise à terme) — le poser maintenant coûte une
colonne FK, le rétrofitter coûterait une migration de données.

**Alternatives considérées** : géolocaliser à l'inscription (permission GPS
avant même d'avoir un compte : friction et taux de refus élevés) ; zone
implicite serveur (un seul défaut global en dur — violerait FR-024).

## R14 — Idempotence des POST de création depuis mobile (analyze V1)

**Décision** : en-tête `Idempotency-Key` REQUIS (UUIDv7 généré côté client) sur
les deux seuls POST créateurs du cycle. `POST /moi/adresses` : la clé DEVIENT
l'id de l'adresse — `INSERT … ON CONFLICT (id) DO NOTHING` + retour de
l'existante (201 rejouable, aucune table supplémentaire).
`POST /moi/dossier-coursier` (1:1 compte) : rejeu de la même clé pendant
`en_attente` → 200 avec l'état courant (le 409 reste réservé aux transitions
invalides depuis `valide`/`suspendu`).

**Rationale** : la lettre du principe V (file offline) vise les actions de
course (cycle CRS), mais son esprit — UUID client + rejeu idempotent — protège
Yao (réseau intermittent) d'un doublon d'adresse ou d'un 409 trompeur après
timeout. Header requis : l'UI est à nous (`mefali_core`), coût d'adoption nul.

**Alternatives considérées** : header optionnel (footgun — l'oubli silencieux
recrée les doublons qu'on voulait éviter) ; table de clés d'idempotence dédiée
(inutile : l'id client et la cardinalité 1:1 portent déjà la sémantique) ;
documentation seule « GET l'état après timeout » (reporte la charge sur chaque
client futur).
