# Rapport d'écarts — cycle CRS 010 (app coursier)

Ce que le cycle **n'a pas fait comme prévu**, et pourquoi. Chaque écart est à
**porter au produit**, pas à contourner en silence : un écart tu devient une
dette dont personne ne connaît le prix.

Trois familles : les **écarts de maquette** (§1), les **limites déférées** à un
module non construit (§2), et les **décisions prises en cours
d'implémentation** (§3) — celles qui ne contredisent aucune spec mais que
personne ne pourrait deviner en relisant le code.

---

## 1. Écarts avec les maquettes

### 1.1 K1-1c « paie fixe » — hors produit, pas hors périmètre

**Ce que la maquette demande** : `K1-disponibilite.png` état 1c affiche
« Livraisons offertes — paie fixe en cours : 800 FCFA / course livrée » et
« 3 courses × 800 FCFA (paie fixe) ».

**Ce qui est livré** : le bandeau montre la **somme des parts coursier** des
courses livrées du jour, calculée sur le devis figé du cycle 007.

**Pourquoi** : la promotion de lancement est nommée « **hors produit** » par
`docs/user-stories-v2.md` (module CRS, note de fin) et par le cadrage §7.1 :
engagement opérationnel, présence vérifiée par les heartbeats DSP-01 déjà
livrés, paie **manuelle**. Il n'existe donc ni tarif de paie fixe en base, ni
règle qui dise quand elle s'applique. Le construire reviendrait à inventer les
deux.

**Conséquence pour Yao** : pendant la promotion, le bandeau affiche ce que le
produit sait calculer, pas ce que l'agence lui versera. L'écart est réel et
doit être expliqué au coursier à l'oral — c'est déjà le cas pour la paie.

**À décider par le produit** : modéliser la paie fixe (un paramètre de zone et
une règle de tarification), ou l'assumer comme un versement hors plateforme.

### 1.2 « Note du jour 4,8 / 5 » — un tiret plutôt qu'un chiffre inventé

**Ce que la maquette demande** : une tuile « Note du jour » sur K1-1a et 1b.

**Ce qui est livré** : la tuile existe, sa valeur est un **tiret**
(`crsJourneeNoteAbsente`). L'API rend explicitement `note_centiemes: null`.

**Pourquoi** : le module d'avis (AVI) n'est pas construit. Le cycle 009 avait
déjà tranché la même question pour le plafond d'avance : l'absence vaut mieux
qu'un chiffre inventé. Un « 5,0 / 5 » par défaut apprendrait à Yao à ignorer la
note le jour où elle deviendra réelle.

**À décider par le produit** : rien — l'écart se referme quand AVI arrive.

### 1.3 K5-1a « Signaler ou bloquer » et la feuille K5-1d — CRS-07

**Ce que la maquette demande** : une carte « Signaler ou bloquer — un client ou
un vendeur, traité par l'agence » sur K5-1a et 1c, et la feuille basse 1d
(5 motifs, commentaire libre, envoi à l'agence).

**Ce qui est livré** : **rien**. La caisse s'arrête aux indemnisations.

**Pourquoi** : **CRS-07** est P1, tranche T4 (`docs/cadrage-v5.md`). Il n'existe
aucun endpoint de signalement, aucune table, aucun destinataire côté agence.
Poser l'écran sans le chemin serveur donnerait un bouton qui ne fait rien —
pire qu'un bouton absent, parce qu'un coursier agressé croirait avoir signalé.

**Conséquence pour Yao** : le chemin reste le téléphone de l'agence, déjà servi
par K4-1d (blocage du code) et par les deux clés `texte.*` de contact au niveau
ville posées au cycle précédent.

**À décider par le produit** : ordonnancer CRS-07.

### 1.4 K4-1a « lien de paiement sur place » — PAY-03

**Ce que la maquette demande** : proposer au client un lien de paiement mobile
money quand il n'a pas l'appoint.

**Ce qui est livré** : le renvoi au chemin de secours (arbre d'échec §7.5-5,
« sans appoint »), sans lien.

**Pourquoi** : **PAY-03**, P1, tranche T3 (FR-050). Aucun fournisseur n'est
intégré, et la constitution III interdit tout chemin de paiement partiel.

### 1.5 Le nom d'usage du client et la distance inter-arrêts — absents en donnée

**Ce que la maquette demande** : « Awa K. » sur K4-1a, et « + 40 m » entre deux
arrêts sur K3.

**Ce qui est livré** : `client.nom_usage = null` et
`arret.distance_precedent_m = null` — les deux champs existent au contrat, ils
ne sont simplement jamais remplis.

**Pourquoi** : le cycle CPT 003 a tranché « un numéro vérifié, rien d'autre » —
aucun nom d'usage n'est collecté nulle part. La distance inter-arrêts, elle,
n'est pas décomposée par le devis figé (cycle 007), qui ne porte qu'une
distance totale ; la recalculer violerait FR-009.

**Conséquence** : K4-1a affiche le repère et l'heure d'arrivée, jamais un nom
fabriqué. Le même vide se retrouve dans l'**exposition admin**, où la colonne
`nom` est vide — l'exploitation identifie par identifiant.

**À décider par le produit** : collecter un nom d'usage (CPT), ou assumer.

### 1.6 K5-1c « L'agence vous rappelle avant 17 h » — sans l'heure

**Ce que la maquette demande** : un engagement de rappel horodaté.

**Ce qui est livré** : « Indemnisation demandée : {montant}. L'agence vous
rappelle. »

**Pourquoi** : aucun délai de traitement n'est tenu en base (AVI-04 n'existe
pas). Afficher « avant 17 h » serait une promesse que rien ne garantit — et
qu'aucun coursier ne pardonnerait deux fois.

---

## 2. Limites déférées à un module non construit

| Limite | Module | Ce que le cycle fait à la place |
|---|---|---|
| **Avance non soldée sur commande prépayée** (FR-117, R10) | PAY-01/02 | l'avance reste **ouverte** et est **annoncée** comme telle, en caisse comme dans l'historique. La masquer la ferait disparaître de l'écran dont c'est la seule raison d'être |
| Solde et mouvements du **fonds d'incidents** | ADM-07 | les indemnisations sont écrites et décidées par API ; aucun solde de fonds n'est tenu |
| **Seuil d'alerte** sur l'exposition cash | ADM-07 | l'exposition est servie ; l'écart au **plafond du jour** est signalé (FR-078), mais aucun seuil global n'existe |
| Écrans Nuxt d'exploitation | ADM-02/04/07 | les 8 endpoints admin sont exercés **par API** dans les tests, patron du cycle 009 |
| Rattachement d'un **litige** à une indemnisation | AVI-04 | port `LitigesOuverts` + double `AucunLitige` — et c'est **l'état exact du monde**, pas un bouchon : il n'existe aucun litige nulle part |
| Émission du **push** d'offre | NTF-01 | l'app se réveille elle-même (service continu, R12/R13) |

---

## 3. Décisions prises en cours d'implémentation

Celles qui ne contredisent aucune spec, mais que personne ne devinerait.

### 3.1 Session 2 — remise, dépôt et blocage

- **Le blocage du code ne ferme QUE la saisie** (FR-043). Le scan QR reste
  proposé sur K4-1d : le jeton est un aléa long, inattaquable par force brute,
  et fermer les deux voies enfermerait un coursier honnête devant une porte
  ouverte.
- **Migrations 0017 et 0018** créées plutôt que retouche des précédentes
  (constitution I) — une colonne découverte en branchant l'écran ne justifie
  jamais de réécrire une migration appliquée.
- **Deux clés `texte.*` de contact d'agence au niveau ville** : le numéro
  affiché sur K4-1d est un paramètre de zone, pas une constante d'app.
- **`commandes::exploitation`** : les lectures d'exploitation vivent dans leur
  propre module plutôt que d'épaissir `collecte`.
- **`reference_courte` est une fonction Rust**, pas une colonne : une seconde
  colonne à resynchroniser pour une chaîne d'affichage serait une seconde
  vérité.

### 3.2 Session 3 — les preuves

- **Migration 0019** (`coursier.preuves_reunies`) : la mémoire du basculement.
  Sans elle, `preuves_echec.reunies` serait réémis à chaque lecture.
- **`PgCommandes::avec_preuves`** — rebranchement du port **après**
  construction. `coursier` dépend de `commandes`, jamais l'inverse : le port ne
  peut donc pas être injecté au constructeur, et la composition se fait dans
  `api`, qui détient les deux.
- **Garde temporelle de la présence** : un relevé horodaté dans le futur par
  l'appareil ne compte pas (FR-010). Vérifié en T085.
- **Le « trou » de présence n'est PAS servi à l'app** : il n'a aucun usage
  d'affichage. L'app en tient un miroir local (`_trouMaxS = 120` dans
  `etat_preuves.dart`) ; le seul risque est un décompte local légèrement
  optimiste, que le serveur corrige.
- **Le plafond du jour est lu directement dans `dispatch.plafond_jour`**, sans
  port dédié : une arête permanente entre deux domaines pour un seul nombre
  serait un prix trop élevé.

### 3.3 Session 4 — caisse, journée, service continu

- **`GET /moi/journee` est composé DANS LE HANDLER** (contrat §2). Les gains et
  les avances viennent de `coursier`, le plafond retenu et le taux
  d'acceptation de `dispatch`. `dispatch::taux_acceptation_pourcent` devient
  `pub` pour cela — c'est un compteur réellement tenu, et K1 l'affiche
  (FR-093).
- **Le cache de caisse est une table drift à UNE ligne** (`caisse_cache`,
  schemaVersion 8), qui range la vue **telle que le serveur l'a rendue** (JSON).
  Éclater la caisse en colonnes locales créerait une seconde modélisation à
  resynchroniser à chaque évolution du contrat.
- **`EtatCaisse` est `autoDispose`, `EtatJournee` aussi.** Un `keepAlive`
  afficherait un solde périmé au retour sur l'écran, exactement là où la
  fraîcheur compte. Le hors-ligne est couvert par le cache, pas par la durée de
  vie du provider.
- **Le bandeau de gains est SILENCIEUX en cas de coupure** : il s'efface, il ne
  bloque pas K1. C'est l'écran depuis lequel Yao se met en ligne, et le bloquer
  sur un chargement de gains lui coûterait des courses. FR-076 (lecture
  hors-ligne annoncée) vaut pour **K5**, pas pour ce bandeau.
- **Le raccourci Caisse du tableau de bord n'apparaît que si de l'argent est
  engagé.** Une carte « 0 FCFA en main » ne pousserait que vers un écran vide ;
  la barre basse, elle, mène toujours à la caisse.
- **La barre basse suit la course, mais pas l'offre.** Une offre en vol garde
  l'écran entier (40 s pour décider — une barre d'onglets donnerait le moyen de
  la perdre) ; une course active garde la barre et ouvre sur la course.
- **« Passer en ligne » de K5-1b ramène à K1** au lieu de basculer sur place :
  passer en ligne exige un plafond déclaré (`capacite_non_declaree`, cycle
  009), et c'est sur K1 qu'il se règle.
- **Le service continu n'a PAS d'horloge de position.** `EmetteurPosition` est
  observé par l'espace coursier et sa cadence bat déjà à la période de zone. Ce
  qui l'arrêtait écran éteint, c'était la suspension du processus par Android —
  ce que le service empêche. Une seconde horloge doublerait le débit sans rien
  couvrir de plus.
- **Les textes du service sont résolus dans la portée**, pas au point d'appel :
  le service peut devoir notifier alors qu'aucun `BuildContext` n'existe. Les
  chaînes restent dans l'ARB fr ; seule leur résolution change de moment.
- **La garde de cadence de la présence vit dans `EtatPreuves`**, pas au point
  d'appel : deux sources l'appellent (l'écran au premier plan, le service écran
  éteint), et un appelant de plus l'oublierait.
- **`periodeOffreArrierePlan = 5 s` est un miroir local** de
  `coursier.offre_interrogation_arriere_plan_s`. Le paramètre n'est pas servi à
  l'app ; l'écart tolérable est celui d'un réveil, pas d'une décision.

### 3.4 Un défaut de production corrigé en passant

`ValeurInconnue` retombait dans le fourre-tout `500`. Une énumération mal
orthographiée par l'appelant (`?etat=peut-etre`) répondait donc « le serveur est
cassé » là où la demande était simplement invalide. Passée en **422** avec sa
clé i18n `valeur_inconnue`. Trouvé par
`admin_coursier::la_file_des_indemnisations_se_filtre_par_etat`.

---

## 4. Trois plugins natifs, pas deux

Le plan en annonçait **deux** (service de premier plan, notifications locales).
`url_launcher` s'y ajoute — c'est lui qui compose un numéro **sans l'afficher**
(FR-034) et ouvre l'itinéraire. Il était déjà au `pubspec` mais n'avait jamais
été compté comme dépendance native du cycle.

**Conséquence** : la règle du plan reste tenue — les plugins sont ajoutés en une
fois, tôt, et toute la logique reste en Dart. Le passage store était de toute
façon obligatoire.

---

## 5. Validation sur appareil (T087) — ce qu'elle a trouvé

**Menée le 2026-08-01** sur émulateur Android (Pixel API 36.1), API locale et
Garage joignables par l'IP LAN. Aucun appareil physique : ce qui relève de la
perception — lisibilité en plein soleil, sonnerie entendue — reste à la charge
d'une passe humaine (§5.3).

Elle a trouvé **trois défauts bloquants**, tous invisibles des 757 tests
backend et des 133 tests Flutter, plus une dette d'outillage. Chacun cassait
un parcours entier.

### 5.1 Les trois défauts

**(1) L'app coursier ne se construisait plus pour Android** — commit `d6040fa`.
`flutter_local_notifications`, le plugin qui porte la sonnerie d'US7, exige le
*core library desugaring*. `assembleDebug` échouait : l'app n'était donc pas
constructible depuis l'entrée du plugin au cycle. `flutter test` tourne sur la
VM Dart de l'hôte et ne voit jamais Gradle.

**(2) La sonnerie se taisait dès la deuxième mise en ligne** — commit `9fb0635`.
`preparer()` déduisait l'autorisation de `requestNotificationsPermission()`,
qui rend `null` sur Android < 13 (no-op) **et** quand la permission est déjà
accordée. Le `?? false` faisait de ces deux `null` un refus : `sonner()`
sortait à la première ligne, et Yao n'était plus jamais réveillé — pendant que
le bandeau lui affirmait qu'il avait refusé une permission qu'il venait
d'accorder. **US7 ne tenait donc pas sa raison d'être.** La vérité est
maintenant relue (`areNotificationsEnabled`) plutôt que déduite.

**(3) Aucune course ne pouvait démarrer** — commit `78de238`.
`arret_de_coursier` n'acceptait un arrêt que si la livraison était déjà
`en_collecte`. Or une course sort du dispatch en `assignee` : c'est la première
action sur un arrêt qui l'ouvre. Le premier scan répondait `arret_hors_course`
et la course restait bloquée pour toujours. Le bac de test ne le voyait pas :
il appelle `marquer_arret_collecte` sur le domaine, sans traverser la route
HTTP que l'app emprunte. **Même piège que les doubles menteurs du cycle 009,
sous une autre forme — un raccourci de test qui saute la couche fautive.**

**(4) Dette levée en passant** — commit `65ccb37`. Le cache `.sqlx` ne pouvait
plus être régénéré (`ligne_en_rupture` ne compilait qu'en lisant le cache),
et `SQLX_OFFLINE=true` échouait symétriquement. `cargo sqlx prepare`, exigé par
`CLAUDE.md` après tout changement SQL, était donc inutilisable.

### 5.2 Ce qui est observé

| Scénario | Statut | Ce qui a été vu |
|---|---|---|
| §3.1 course active | **partiel** | arrêt courant seul développé (« Arrêt 1 / 3 »), suivants repliés + badge « À collecter », montant par arrêt, coche d'article, bouton « Indisponible » par ligne ; collecte du 1ᵉʳ arrêt par code de secours **après** le défaut (3) |
| §3.2 note vocale | **partiel** | URL présignée émise sur l'IP LAN (`:3910`), pas `localhost` — piège du cycle 006 évité ; fichier téléchargé (17 775 o). Lecture hors ligne dans l'app **non observée** |
| §3.3 hors-ligne | **non fait** | — |
| §3.4 réveil écran éteint | **VALIDÉ** | voir §5.2.1 |
| §3.5 preuves | **non fait** | — |
| §3.6 caisse | **non fait** | caisse à 0 vérifiée en entrée de course seulement |

#### 5.2.1 §3.4 — le scénario qui justifiait le cycle

- Service de premier plan vivant **app absente du premier plan et écran
  éteint** ; notification permanente sur `mefali_service_continu`
  (importance LOW, `ONGOING|NO_CLEAR`), « Mefali — en ligne / Vous recevez les
  offres de course, écran éteint. »
- Canal de sonnerie `mefali_offres_course` en **importance MAX**, `playSound`,
  vibration, `fullScreenIntent` — distinct du canal du service, comme prévu.
- **Maintien dans le pool : 30 min 23 s d'écran éteint sans une seule sortie**,
  relevés toutes les 5 min, `age_s ≤ 6` en continu alors que `pool_ttl_s = 90`.
- **Réveil : offre émise écran éteint → notification postée à t+8 s** sur le
  canal MAX, écran toujours éteint (après le correctif (2) ; avant, rien).
- Compte à rebours au temps **réellement restant** (offre reprise affichée à
  21 s, pas 40) — FR-100.
- Mise hors ligne → service arrêté, notification disparue, coursier sorti du
  pool. Rien ne survit.
- **La bascule K2 → écran de course a été observée** : la réserve reconduite du
  cycle 009 est **levée**.

### 5.3 Ce qui reste à une passe humaine

Non pas par manque de temps, mais parce qu'aucun outil ne les voit :

- **§3.1 en plein soleil** : lisibilité réelle des montants, confort de la
  coche — jugement visuel, dehors, sur un vrai écran.
- **§3.4 la sonnerie entendue** : le canal, l'importance, le son et le
  `fullScreenIntent` sont vérifiés ; le son qui sort du haut-parleur, non.

Et trois scénarios restent à dérouler : **§3.3** (hors-ligne complet et
3 codes faux), **§3.5** (preuves, 10 min écran éteint), **§3.6** (caisse en
cours de course).

### 5.4 Comportements corrects relevés au passage

Mise en ligne refusée sans véhicule déclaré, avec le motif ; bandeau explicite
quand la notification n'est pas autorisée ; course exigeant 10 300 FCFA
d'avance **jamais** offerte à un coursier plafonné à 5 000 ; offre expirée →
« sans pénalité — 1 sur 3 aujourd'hui » ; reprise `sans_mouvement` après 300 s
d'immobilité ; dégradé de routage ×1,4 journalisé (`degraded: true`, OSRM
absent du poste) ; l'offre ne révèle pas l'adresse exacte et le
pré-provisionnement ne porte que des **empreintes** de jeton et de code
(SC-015).

### 5.5 Réserves ouvertes

- **`dart analyze` (mefali_pro) : 8 avertissements** — 4
  `only_use_keep_alive_inside_keep_alive`, 4 `provider_dependencies`.
  Préexistants, stables après `build_runner clean`, non traités ici.
- **`flutter test` (mefali_core) : 1 échec** —
  `session_intercepteur_test` « renouvellement partagé (FR-014) ». Passe seul,
  échoue en suite, y compris `--concurrency=1`, et **aussi sans les correctifs
  ci-dessus** : pollution entre tests (`Ref … after it has been disposed`,
  piège connu du cycle 004). La suite s'arrête à 101 au lieu de 116.
- **Le canal d'offre n'a pas de son « prolongé »** : `canal_offre.dart` l'annonce
  en tête de fichier, l'implémentation utilise `playSound: true`, donc le son de
  notification par défaut du système. Le canal est bien dédié ; le son, non.
- **L'app garde l'écran d'une course annulée côté serveur** (`204` reçu, K3
  toujours affiché) et **n'ouvre pas sur la course active au démarrage** : elle
  reste sur le tableau de bord, il faut l'onglet « Courses ».
- **Exception non gérée** vue en journal :
  `TimeoutException … Time limit reached while waiting for position update`,
  suivie de « Geolocator position updates stopped ». Le service continue de
  publier (le pool ne se vide pas), mais l'exception remonte non traitée.

### 5.6 Verts au 2026-08-01, après correctifs

`cargo test --workspace` **757 passés / 0 échec** · `flutter test` mefali_pro
**133** · `verifier-accord-locks.sh` OK · `generate-clients.sh` **sans diff** ·
`cargo sqlx prepare --workspace` de nouveau opérationnel.
