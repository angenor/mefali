# Recherche — QR prestataire, plaque et scans de collecte

Stack imposée (cadrage §10) : aucune inconnue de technologie. Cette recherche fige les **décisions de conception** ancrées dans les conventions réelles du dépôt (crates 002/003/005, `socle`, `mefali_core`). Format : Décision / Rationale / Alternatives.

---

## R1 — Découpage en crates : `commandes` (socle) + `qr`

**Décision** : le cycle touche **deux** crates de domaine.
- `commandes` (aujourd'hui stub de 109 l.) reçoit le **socle logistique minimal** : `commande` (ancre), `livraison`, `segment`, `arret`, la machine à états d'arrêt, la transition `marquer_arret_collecte`, le gating `EN_LIVRAISON`, et un port `ArretsDeCollecte` (lecture de l'arrêt à collecter d'un coursier chez un prestataire).
- `qr` (stub de 5 l.) reçoit **tout le QR** : composition du PDF de plaque, orchestration de la vérification de scan (résolution, proximité, politique photo, code dégradé, incident), pré-provisionnement d'empreintes, table `incident_plaque`, registre d'idempotence.

**Rationale** : constitution II range explicitement le modèle `livraison → segment → arrêt` dans le domaine logistique (crate `commandes`), et le QR/traçabilité dans le crate `qr`. La clarification (session 2026-07-22) a tranché : introduire la **structure documentée** comme socle. `qr` dépend de `commandes` (marquer l'arrêt), `prestataires` (résolution), `zones` (paramètres) — DAG sans cycle. Le crate `qr` reste **domaine pur** (constitution II) : Garage passe par `socle::DepotObjets`, la course active par le port `ArretsDeCollecte` — leurs impls réelles vivent dans `api`.

**Alternatives rejetées** : (a) tout dans `qr` (arrêt compris) → viole « un schéma par module » et crée un modèle jetable que CMD refondrait ; (b) attendre CMD → QRC-02/03/04 non démontrables, contredit le choix produit de faire QRC maintenant.

---

## R2 — Génération du QR et composition du PDF de plaque

**Décision** : crate `qr`, deux dépendances pures (aucune I/O) :
- `qrcode` — produit la **matrice de modules** (`QrCode::new(url).to_colors()`), niveau de correction **M** (plaque plastifiée, lisible même abîmée aux coins).
- `printpdf` — compose le PDF A6/A5 : titre « Vendeur agréé Mefali » (clé i18n rendue serveur), le QR **dessiné en rectangles vectoriels** (un rect noir par module sombre), le **nom** du prestataire, le **code de secours** en gros. Police intégrée Helvetica de `printpdf` (le PDF est un artefact d'impression sans contrainte de tokens — aucune maquette dans `docs/design/png/`).

**Rationale** : dessiner les modules en vectoriel évite d'ajouter une lib raster (`image`) et donne un QR net à toute échelle d'impression. `hmac`/`sha2`/`rand` restent inutiles ici (le jeton existe déjà, cycle 005). Versions figées à la dernière stable vérifiée à l'init du crate (constitution X).

**Alternatives rejetées** : rendu raster (`qrcode` + `image` → PNG embarqué) — dépendance et perte de netteté superflues ; SVG intermédiaire — `printpdf` ne l'embarque pas nativement.

---

## R3 — Géo-vérification : proximité grand-cercle, jamais OSRM

**Décision** : la vérification « à moins de 100 m » est une **distance grand-cercle** (haversine) entre la position capturée du coursier et la `position_site` de l'arrêt, comparée au paramètre de zone `qr.distance_scan_max_m` (seed 100). Aucune allocation OSRM.

**Rationale** : c'est une **porte de présence** anti-fraude, pas une distance de trajet. Consigné en Complexity Tracking (tension principe IV assumée et bornée). Le paramètre est hérité (`zones::ConfigurationZones::parametre(zone, "qr.distance_scan_max_m")`), jamais en dur (constitution I).

**Alternatives rejetées** : OSRM (absurde pour une présence < 100 m, et le principe IV vise les distances de livraison/tarification — TRF, hors périmètre).

---

## R4 — Politique photo résolue : prestataire > catégorie > seuil de montant

**Décision** : le crate `qr` résout l'exigence de photo dans cet ordre :
1. **Override prestataire** — colonne nullable `prestataires.prestataire.politique_photo_collecte` (`obligatoire|facultative|desactivee`), ajoutée par une migration au schéma `prestataires` ; `NULL` = pas d'override.
2. **Défaut de catégorie** — paramètre `categorie.<code>.politique_photo` (seed : restauration = `facultative`, pharmacie = `obligatoire` — cadrage §4 l.83), lu via `zones`.
3. **Forçage par montant** — si `arret.montant_avance >= qr.photo_seuil_montant` (paramètre de zone, en unités mineures), la photo devient `obligatoire` **quel que soit** le niveau résolu au-dessus.

**Rationale** : reproduit exactement la hiérarchie de la spec (FR-016) et du cadrage §4 (« éditable aussi par vendeur et par seuil de montant »). Le seuil manque au « Récapitulatif des paramètres de zone » — à y **ajouter comme seed : 10 000 FCFA (XOF, `10000`), éditable** (patron de la charte 5 ans du cycle 005). Résolution testable sans réseau (params en base de test via seeds).

**Alternatives rejetées** : politique photo en dur par catégorie (viole constitution I) ; ignorer l'override prestataire (contredit FR-016).

---

## R5 — File d'actions offline : `drift` dans `mefali_core`

**Décision** : construire la file d'actions offline (aujourd'hui un README de 2 lignes) avec **`drift`** (SQLite) : table `action_en_attente(uuid_client PK, endpoint, methode, payload_json, photo_octets?, cree_le_local, tentatives, dernier_motif)`. Un provider `@Riverpod(keepAlive: true)` (durée du processus, moule de `clientSession`) expose `enfiler(action)` et un **rejeu** déclenché au retour réseau et à la reprise d'app ; l'idempotence tient au `uuid_client` (UUIDv7, `uuid` 4.5 déjà présent). Le pré-provisionnement (R6) est mis en cache dans une table drift `arret_preprovisionne`.

**Rationale** : `drift` est durable (survit au kill), transactionnel et requêtable — nécessaire pour une file portant des **octets de photo** ; `shared_preferences` ne convient pas. Aligne V (« file locale hors réseau »). C'est la **première** matérialisation de la provision `offline/` (constitution IX levée pour ce cycle).

**Alternatives rejetées** : `shared_preferences`/`secure_storage` seuls (pas de file transactionnelle avec blobs) ; file en mémoire (perdue au kill — viole V).

---

## R6 — Pré-provisionnement : empreintes (hash), jamais de secret

**Décision** : à la lecture de la course active, le serveur renvoie par arrêt `{arret_id, prestataire_id, empreinte_jeton, empreinte_code, site{lat,lon}, montant_avance, devise, photo_exigee}`, où :
- `empreinte_jeton = base16(sha256(jeton))` — le jeton est public (imprimé sur la plaque) ; l'empreinte sert au **match hors-ligne** (le scan lit le jeton, calcule son sha256, compare).
- `empreinte_code = base16(sha256(prestataire_id ‖ code_secours))` — salée par l'UUID du prestataire pour interdire toute table arc-en-ciel entre arrêts ; le **code en clair ne quitte jamais le serveur**.

L'appareil valide hors-ligne (match d'empreinte + proximité via `site`), confirme localement, met en file. Au rejeu, le **serveur re-valide en autorité** (résolution du jeton = révocation dérivée, proximité recalculée, horodatage serveur).

**Rationale** : constitution V, littéral — « les empreintes (hash) du code et du jeton QR sont pré-provisionnées à l'assignation pour permettre la validation hors ligne ». `sha256` = `sha2` 0.11 déjà présent. La révocation (prestataire suspendu **après** pré-provisionnement) est rattrapée au rejeu, jamais offline (collecte optimiste — spec Q3/FR-028).

**Alternatives rejetées** : envoyer le code en clair (fuite d'un secours) ; vérifier la signature HMAC du jeton sur l'appareil (exigerait `PLAQUE_SECRET` sur le terminal — interdit).

---

## R7 — Compteur d'essais du code dégradé : Redis + local

**Décision** : côté **appareil**, la saisie du code est vérifiée hors-ligne par comparaison d'empreinte (R6), avec un compteur **local** borné à 3 par arrêt (au 3ᵉ échec, saisie refusée + escalade). Côté **serveur**, backstop en Redis : `INCR qr:essais:{arret_id}` avec TTL, refus au-delà de 3 (éphémère reconstructible, constitution II — Redis).

**Rationale** : offline, l'appareil connaît immédiatement l'issue (empreinte) — le compteur doit donc être local d'abord ; Redis borne les tentatives **en ligne** et au rejeu. L'incident « plaque à remplacer » est créé au **premier** passage en mode dégradé (clarification Q2), indépendamment du compteur.

**Alternatives rejetées** : compteur en colonne Postgres (transition d'échec = écriture durable inutile) ; compteur uniquement serveur (impossible hors-ligne).

---

## R8 — EN_LIVRAISON porté par la `livraison`, pas par le tronc `commande`

**Décision** : l'état `EN_LIVRAISON` est une valeur de `livraison.etat` (`en_collecte → en_livraison`). Quand tous les arrêts d'une livraison sont **résolus** (COLLECTÉ, ou `indisponible` posé par CMD-06), `marquer_arret_collecte` fait basculer la livraison et émet `livraison.mise_en_livraison`. Le **tronc `commande` ne reçoit aucun champ logistique**.

**Rationale** : constitution II (« le tronc de commande ne contient AUCUN champ logistique ») + cadrage §11.11 : EN_LIVRAISON est logistique → sur le composant `livraison`. « commande EN_LIVRAISON » de la spec = « la livraison de la commande est EN_LIVRAISON ». Un arrêt `indisponible` compte comme résolu dans le gating (spec FR-018) ; QRC ne pose que `collecté`.

**Alternatives rejetées** : `commande.etat = EN_LIVRAISON` (met un champ logistique dans le tronc — viole II).

---

## R9 — PDF de plaque : génération à la demande, dépôt + URL présignée

**Décision** : `GET /admin/prestataires/{id}/plaque` (rôle admin) → le crate `qr` compose le PDF (R2), le **dépose** sous `qr/plaques/{prestataire_id}.pdf` via `socle::DepotObjets::deposer`, émet `plaque.generee`, puis renvoie une **URL présignée** de lecture (`presigner_get`, TTL 10 min — patron `prestataires::consultation`/repère vocal). Le jeton étant stable (cycle 005), une régénération produit un PDF identique.

**Rationale** : réutilise le port objets déjà câblé (`infra_s3::S3Objets`) et le patron de téléchargement admin. Génération paresseuse : pas de job à l'agrément, pas de table de métadonnées (la traçabilité est l'événement outbox). Refus si le prestataire n'a pas d'identité de plaque (jamais agréé, FR-011).

**Alternatives rejetées** : génération eager à l'agrément (couple 005 à `qr`, travail inutile pour un prestataire jamais scanné) ; flux d'octets inline (contredit « conservé en stockage objet » — spec FR-010).

---

## R10 — Précondition « course active » : requête interne + double de test

**Décision** : `qr` possède les tables d'arrêt (via `commandes`) et lit directement la précondition : « le coursier a-t-il une livraison active dont un arrêt `à_collecter` vise ce prestataire ? ». L'**affectation** coursier↔livraison (`livraison.coursier_id`, posée par DSP) est **simulée dans les tests** en insérant une livraison assignée — même patron que `prestataires::CommandesActivesFixes`. En production, sans DSP, aucune course n'est assignée : la lecture renvoie vide (exact, comme `AucuneCommandeActive`).

**Rationale** : puisque `qr`/`commandes` possèdent désormais l'arrêt, nul besoin d'un port externe pour la donnée ; le port `ArretsDeCollecte` (dans `commandes`) sert seulement l'API/les tests. Le port `prestataires::CommandesActives` (signalement rupture, VND) reste `AucuneCommandeActive` — le brancher sur `commandes` est un suivi hors périmètre.

**Alternatives rejetées** : réutiliser tel quel `CommandesActives::arret_actif(coursier, article) -> bool` (renvoie un booléen, pas l'arrêt ni sa position/montant — insuffisant pour QRC-02).

---

## R11 — Plugins Flutter et permissions natives

**Décision** : ajouter à Mefali Pro (et manifestes) :
- `mobile_scanner` (lecture QR via ML Kit / AVFoundation) — déclarer **CAMERA** (Android) ; `NSCameraUsageDescription` déjà présent (iOS) ; permission runtime.
- `geolocator` (position GPS) — déclarer **ACCESS_FINE_LOCATION** (Android) et **`NSLocationWhenInUseUsageDescription`** (iOS) ; permission runtime.
- `image_picker` — **déjà présent** (photo de récupération, délègue à l'app caméra, pas de permission CAMERA propre).
- `drift` (R5) et `permission_handler` (unifie les demandes runtime caméra + localisation).

**Rationale** : le cycle plateformes a laissé le projet **sans** scanner ni GPS (`image_picker`/`record` seulement). Le passage de `mobile_scanner` par la caméra impose la déclaration CAMERA (au contraire d'`image_picker`) — piège consigné (cf. mémoire cycle plateformes : « CAMERA volontairement absente »). Versions à la dernière stable, figées (constitution X).

**Alternatives rejetées** : `qr_code_scanner` (moins maintenu) ; `location` (moins précis que `geolocator` pour un rayon de 100 m).

---

## R12 — Événements outbox et minimisation ARTCI

**Décision** : cinq événements, écrits dans la même transaction que la mutation (`socle::ecrire_evenement`), **déclarés d'abord dans `docs/taxonomie-evenements.md`** (constitution VI) :

| Événement | entite_type | entite_id | Payload (hors zone/categorie/role) |
|---|---|---|---|
| `plaque.generee` | `plaque` | `prestataire.id` | `prestataire`, `format=pdf`, `regeneration`(bool), `acteur` |
| `arret.collecte` | `arret` | `arret.id` | `commande`, `livraison`, `segment`, `prestataire`, `mode`(`scan_qr\|code_secours`), `avec_photo`(bool), `gps_ok`(bool), `montant_avance`, `devise`, `acteur` |
| `livraison.mise_en_livraison` | `livraison` | `livraison.id` | `commande`, `nb_arrets`, `acteur` |
| `plaque.remplacement_requis` | `plaque` | `prestataire.id` | `prestataire`, `origine=qr_illisible`, `commande`, `arret`, `automatique=true`, `acteur` |
| `arret.collecte_rejetee` | `arret` | `arret.id` | `commande`, `mode`, `motif`(`jeton_revoque\|hors_zone\|etat_incompatible\|code_epuise`), `horodatage_client`, `acteur` |

**Rationale** : convention `<entite>.<action>` (participe passé) ; **minimisation ARTCI** — aucun lat/lng brut (booléen `gps_ok` ou `distance_m` arrondi), `acteur` = UUID de compte, jamais de nominatif. Le **téléchargement** admin du PDF n'est **pas** une transition durable → pas d'outbox (métrique produit, hors cycle). Le crate `metriques` reste un **stub** : QRC ne fait qu'**alimenter** l'outbox (matière première des métriques MET-01/02/03, cycles ultérieurs). Les **rejeux idempotents** (même `uuid_client`) n'émettent **rien** ; seuls les rejets **métier** émettent `arret.collecte_rejetee`.

**Alternatives rejetées** : mettre EN_LIVRAISON sur `commande` (R8) ; émettre au téléchargement du PDF (pas une transition) ; construire le crate `metriques` (constitution IX — hors périmètre).
