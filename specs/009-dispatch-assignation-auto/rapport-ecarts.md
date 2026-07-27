# Rapport d'écarts — cycle DSP 009 (dispatch automatique)

Ce que le cycle **n'a pas fait comme prévu**, et pourquoi. Chaque écart est à
**porter au produit**, pas à contourner en silence : un écart tu devient une
dette dont personne ne connaît le prix.

---

## 1. Écarts avec les maquettes

### 1.1 « Quartier Sokoura » de K2 — impossible en donnée

**Ce que la maquette demande** : `docs/design/png/K2-offre-course.png` affiche
« Livraison — quartier Sokoura ».

**Ce qui est livré** : « Livraison — Tiassalé », c'est-à-dire le nom de la
**ville**.

**Pourquoi** : aucun quartier n'existe en donnée. `TypeZone::Quartier` est une
**PROVISION** — « données seulement, aucune UI, aucune logique »
(constitution IX) — et l'arbre seedé s'arrête à la ville. Construire ce libellé
exigerait soit d'activer la provision (donc de peupler un référentiel de
quartiers de Tiassalé), soit un service de géocodage inverse. Aucun des deux
n'est au périmètre de ce cycle, et les improviser produirait un libellé faux
plutôt qu'un libellé absent.

**Conséquence pour Yao** : il voit la ville et une distance approximative, plus
la mention « adresse exacte après acceptation ». Il sait donc **où** il va à
l'échelle qui compte pour décider (1,8 km), sans qu'aucune coordonnée du client
ne sorte avant acceptation (ARTCI).

**À décider par le produit** : peupler un référentiel de quartiers (ADM/ZON), ou
assumer le nom de ville.

### 1.2 Gains du jour, note et acceptation de K1 — hors périmètre

**Ce que la maquette demande** : K1 affiche « Gains du jour — 7 courses livrées
8 400 FCFA », « Note du jour 4,8 / 5 », « Acceptation 92 % » et un raccourci
« Caisse ».

**Ce qui est livré** : rien de tout cela.

**Pourquoi** : les gains et la caisse appartiennent à **CRS-01/CRS-06**, la note
à **AVI**. Les afficher ici obligerait à **inventer** leurs données — ce qui est
pire qu'une absence : un coursier qui lit « 8 400 FCFA » et ne les retrouve pas
dans sa caisse perd confiance dans tout le reste de l'écran.

**Conséquence pour Yao** : K1 montre ce que le dispatch sait vraiment — sa
disponibilité, son plafond, son état de connexion.

### 1.3 Aucune sonnerie, aucune vibration, aucun push

**Ce que la maquette demande** : K2 est décrit « Plein écran + sonnerie ».

**Ce qui est livré** : l'app **va chercher** son offre toutes les 2 s tant qu'un
écran de dispatch est monté.

**Pourquoi** : FR-094 attribue le transport à **NTF-01**, story distincte de la
même tranche T1. Le cycle livre le **contrat d'émission**
(`NotificationsDispatch`, trois canaux nommés) : NTF-01 s'y branchera sans
changer une ligne de contrat, et le jour où le push arrivera, il **réveillera**
l'app qui appellera le même endpoint (research R16).

**Conséquence, et elle est réelle** : téléphone en poche, écran éteint, Yao ne
sait pas qu'une course lui est offerte. Les 40 secondes s'écouleront. C'est une
**non-réponse franche** (aucune pénalité les 3 premières fois du jour), mais
c'est une course perdue pour la cliente.

---

## 2. Limites assumées de la surface coursier

### 2.1 Position publiée en **premier plan seulement**

Sans service de premier plan Android, l'app cesse de publier dès qu'elle passe
en arrière-plan, et le coursier sort du pool par expiration du TTL (90 s).

C'est **conforme** à DSP-01 — « un coursier muet sort du pool » — et honnête
vis-à-vis de Yao, qui voit son bandeau de reconnexion. Le suivi en arrière-plan
appartient à **CRS**, avec sa propre décision de dépendance et sa permission
(research R15).

### 2.2 Dérogation déclarée au principe V — deux actions hors file

Ni la **publication de position** ni l'**acceptation d'offre** n'entrent dans la
file d'actions hors-ligne. Dérogation **déclarée et justifiée** dans
[plan.md](./plan.md) (Complexity Tracking) :

- une position vieille de dix minutes rejouée au retour du réseau réinscrirait le
  coursier avec une localisation fausse ;
- une offre acceptée deux minutes trop tard porterait sur une course déjà
  attribuée : le rejeu produirait systématiquement « déjà prise », c'est-à-dire
  une déception garantie plutôt qu'une résilience.

Les trois autres garanties de V sont tenues : `uuid_client`, horodatage local
observé, rejeu **idempotent**, serveur faisant foi.

---

## 3. Décisions prises en cours d'implémentation

Ces points n'étaient pas tranchés par les artefacts de conception ; ils l'ont été
par le code, et méritent une relecture produit.

### 3.1 L'intention d'être en ligne est **persistée** (migration 0013)

Le contrat distingue `en_ligne: true` et `dans_le_pool: false`. Sans persistance,
ces deux faits se confondraient, et `GET /moi/disponibilite` après un
redémarrage d'app rendrait « hors ligne » à un coursier qui roule.

Elle ne pouvait pas vivre en Redis : une intention perdue au vidage ferait
ignorer (`204`) toutes les publications suivantes, et le pool ne se
reconstituerait **jamais** — SC-004 tomberait.

Elle vit donc sur `dispatch.plafond_jour`, avec la même durée de vie que le
plafond : le **jour civil**, jamais reporté. Conséquence : un coursier qui
travaille à cheval sur minuit doit se remettre en ligne. Cohérent avec FR-011,
mais à confirmer par le produit.

### 3.2 L'unicité d'offre par commande ne vaut plus que pour la **cascade**
(migration 0014)

`0011` posait un index UNIQUE partiel sur `(commande_id) WHERE issue = 'en_vol'`.
Or DSP-05 est **précisément** le fait d'offrir la même course à plusieurs
coursiers en même temps : l'index rendait le broadcast impossible.

L'invariant qui compte n'est pas « une offre par commande » mais **un coursier
par commande**, et il est tenu ailleurs et mieux : `SELECT … FOR UPDATE` +
table de transitions fermée (research R4), y compris **sans Redis**.

### 3.3 L'inactivité part de la **mise en ligne**, pas de la dernière publication

Découvert par le test d'équité SC-007. L'inactivité d'un coursier sans course
livrée valait l'âge de sa dernière publication de position — quelques secondes.
Un coursier en ligne depuis le matin sans rien recevoir avait donc la même
inactivité que celui qui vient de terminer une course : l'inverse exact de
l'équité que DSP-03 cherche.

Elle part désormais de sa **mise en ligne du jour**, et du plafond de zone quand
on l'ignore (index reconstruit après un vidage) : un coursier dont on ne sait pas
depuis quand il attend est **présumé avoir attendu**, jamais présumé venir de
finir.

### 3.4 `mettre_en_attente` et `escalader_attentes` entrent au contrat

Le cycle 008 laissait la mise en file « à l'appelant ». Cet appelant, c'est le
pipeline de dispatch — d'où deux méthodes de plus sur `CommandesADispatcher`
(8 au total, au lieu des 6 planifiées) plutôt qu'un accès direct de `dispatch`
au schéma `commandes`, que la constitution II interdit.

### 3.5 Le pas de saisie du plafond (1 000 FCFA) est une constante d'UI

La maquette K1 dit « Par pas de 1 000 FCFA ». Ce n'est **pas** un paramètre
métier : il ne change aucun comportement serveur (le montant retenu vient de la
grille de zone). Il vit donc dans l'écran, documenté comme tel. S'il devait
varier par zone, il deviendrait un 19ᵉ paramètre.

---

## 4. Dette antérieure rencontrée et corrigée

### 4.1 Deux tests de routeur restés sur un libellé disparu — **corrigés**

`test/roles/routeur_roles_test.dart` attendait le libellé « Espace coursier »,
disparu au cycle QRC 006 quand l'espace coursier est devenu l'écran de course
active (« Ma course »). **Deux tests étaient rouges avant ce cycle** — vérifié
par `git stash`. Ils ont été mis à jour ici : un test rouge qui traîne finit par
ne plus être lu, et masque le suivant.

### 4.2 Désaccord de lockfiles Flutter — **corrigé**

`./scripts/verifier-accord-locks.sh` signalait `source_gen` en **4.2.4** dans
`apps/mefali_client/pubspec.lock` contre **4.2.3** dans `mefali_core` et
`mefali_pro`. Le désaccord **préexistait** au cycle DSP 009 — vérifié en le
rejouant sur l'arbre `git stash`.

Il avait d'abord été renvoyé « au prochain cycle qui touche `mefali_client` », au
nom du périmètre. C'était une mauvaise économie : le script fait partie de la
Definition of Done, et un contrôle laissé rouge cesse d'être lu. Corrigé par
`flutter pub add dev:source_gen:4.2.3` — **incrémental** (FR-032, jamais
`pub upgrade`) : un seul paquet a bougé au lockfile. Aligné vers le **bas**,
parce que les deux paquets qui portent le code du cycle sont ceux qu'il ne faut
pas déplacer.

Non-régression vérifiée : `flutter test` + `dart analyze` verts dans les **trois**
paquets.

**Dette antérieure découverte au passage** : deux `.g.dart` de `mefali_client`
(`etat_panier`, `etat_confirmation`) étaient **périmés dans le dépôt** depuis le
cycle CMD 008 — leur hash de provider ne correspondait plus à leur source. Sans
rapport avec `source_gen` : régénérer **avant** le changement de version, en
4.2.4, produit exactement le même résultat qu'en 4.2.3. Rafraîchis ici.

---

## 5. Ce que le cycle n'a délibérément pas construit

| Non construit | Pourquoi | Ce qui le remplace |
|---|---|---|
| Push et sonnerie | NTF-01, story distincte (§0.5) | contrat d'émission + interrogation courte |
| Écran d'opérations admin | module ADM, tranche T3 (FR-096) | 3 endpoints admin, exercés par API |
| Note du coursier | module AVI | port `NotePrestataire` + `NoteAbsente` |
| Paires bloquées | CRS-07, P1, tranche T4 | port `PairesBloquees` + `AucunePaireBloquee` |
| Bandeau gains du jour | CRS-01 | rien — l'écran n'en dépend pas |
| Anti-abus (DSP-08) | P1, hors périmètre | les compteurs d'issues d'offre suffiront |
| Superposition de 2 commandes | phase 2 | `course_active` exclut, un seul segment |
| Suivi en arrière-plan | dépendance et permission à décider par CRS | publication en premier plan |

Aucune **provision** n'a été activée : `TypeZone::Quartier` reste données
seulement, et c'est ce qui produit l'écart 1.1.

---

## 6. Revue de conformité du 2026-07-27 — après relecture du code livré

Une relecture ligne à ligne a trouvé quatre non-conformités **réelles** (des
règles du cycle qui n'étaient pas tenues, pas des écarts assumés). Elles sont
**corrigées** ; elles figurent ici pour que le prix de chacune reste lisible.

| Trouvé | Ce que ça coûtait | Corrigé par |
|---|---|---|
| `contenu_offre` mesurait son itinéraire **tronçon par tronçon** — 4 requêtes de routage pour 3 collectes, alors que FR-035 pose « une matrice par évaluation ». Le commentaire annonçait pourtant « une seule matrice routière » | 4 allers-retours OSRM sur le chemin qui prépare l'écran d'un coursier qui a 40 s pour décider — et le cache par tronçon du cycle 007 ne les absorbait pas, il ne réchauffe jamais coursier→vendeur | port `ProximiteRoutiere::troncons_consecutifs`, UNE matrice pour tout l'itinéraire. Test comptant les appels |
| `GET /admin/dispatch/pool` exigeait `lat`/`lon` que son `#[utoipa::path]` ne déclarait pas | endpoint **inappelable** depuis `clients/dart` et `clients/ts` : `400` garanti à tout appelant conforme au contrat | port `PoolCoursiers::membres(zone)` ; retour à la signature du contrat, qui gagne sa §2.2 (jusque-là absente) |
| Le contournement `dans_rayon(zone, lat, lon, rayon_m * 10)` | la carte d'exploitation écartait **en silence** tout coursier au-delà de 40 km | idem — l'index GEO de Redis est un zset, `ZRANGE 0 -1` sait l'énumérer |
| `alertes()` : `LEFT JOIN … WHERE e.id IS NOT NULL` | un `INNER JOIN` déguisé — le lecteur croyait l'événement d'escalade facultatif | `JOIN` interne explicite |

Deux **faux-semblants** de moindre portée, corrigés au même passage : le dérive
`serde::Serialize` sur `Alertes` / `EscaladeVue` / `CourseBloqueeVue`, qui donnait
au domaine une capacité de sérialisation HTTP qui ne lui appartient pas
(constitution II) et que personne ne consommait ; et `DemandeEligibilite.zone`,
seconde vérité sur une zone que `ConfigDispatch` portait déjà. Plus cinq `let _ =
…` sans effet dans les tests, dont un sous un commentaire annonçant un contrôle
qui n'existait pas.

Corrigé aussi : `plafond_unites` était documenté « déclaré » alors qu'il porte le
**RETENU** (`min(palier, déclaré)`) — dans le modèle du domaine comme dans le DTO
admin. Un exploitant lisant « 8 000 » sur un coursier qui ne peut avancer que
5 000 se serait trompé sur ce qu'il pouvait lui confier.

### 6.1 N+1 de lecture dans le filtre d'éligibilité — **assumé, avec seuil**

`filtrer` interroge `commandes.course_active(coursier)` et
`coursiers.coursier(coursier)` **par candidat** : `2n` requêtes Postgres pour `n`
membres du pré-filtre (et `2n` de plus vers l'index et les paires bloquées, moins
coûteuses). C'est le chemin le plus sensible du produit.

**Pourquoi ce n'est pas court-circuitable** : FR-026 exige la liste **complète**
des motifs d'écart, jamais le premier. Un filtre qui s'arrête au premier refus
rend « la capacité d'avance est le SEUL obstacle » indécidable — et c'est
précisément la question que la bascule prépaiement doit trancher.

**Pourquoi ce n'est pas mis en lot maintenant** : le pré-filtre géographique
borne déjà `n` au rayon de zone (4 km à Tiassalé), où il vaut quelques unités. Le
lot exigerait de changer le contrat de **deux ports** implémentés par `commandes`
et `comptes` — hors du périmètre de ce cycle, et sans mesure pour l'appuyer.
Optimiser à l'aveugle un chemin qu'on n'a pas encore vu ralentir, c'est payer
comptant une dette hypothétique.

**Déclencheur, écrit dans le doc-comment de `filtrer`** : au-delà d'une
cinquantaine de membres durables dans le pool d'une zone, passer les quatre
lectures en lot. La boucle consomme déjà des tableaux indexés — la substitution
est locale.

**À décider par le produit** : rien. C'est une dette technique nommée, avec son
seuil ; elle n'engage aucune promesse faite à un utilisateur.

---

## 7. Validation sur émulateur (T071) — ce que le terrain a trouvé

Déroulée le 2026-07-27 sur `Medium_Phone_API_36.1`, API sur IP LAN, émulateur
positionné sur Tiassalé. **Neuf défauts**, tous invisibles à une suite de tests
pourtant verte — parce qu'aucun ne regardait les **jonctions** entre des pièces
qui, prises une par une, étaient justes.

Le plus grave d'abord : **K1 et K2 étaient inatteignables**. L'espace coursier
menait directement à l'écran de course du cycle QRC, et les deux écrans du cycle
n'étaient référencés que par leurs propres tests widget. Tout DSP était injouable
sur le terrain. Les huit autres :

| Trouvé | Ce que Yao vivait |
|---|---|
| K2-1b escamoté ; son bouton `Navigator.maybePop()` sans route à dépiler | il ne pouvait pas LIRE « sans pénalité — n sur 3 » et croyait avoir été puni |
| Acceptation réussie affichant « temps écoulé » | il gagnait la course et lisait qu'il l'avait perdue |
| Détail du gain toujours à zéro (clés `deplacement`/`arrets`/`effort` inexistantes) | « 0 + 0 + 0 » sous un gain de 150 FCFA — un détail qui contredit le total fait douter du total |
| Publication seulement sur mouvement du capteur | **arrêté au carrefour**, il sortait du pool en 90 s, en lisant « en attente de courses » |
| Permission de position jamais demandée | sur un appareil neuf, il n'entrait **jamais** dans le pool |
| K1 disant « en attente de courses » hors du pool | il croyait travailler ; aucune course ne pouvait lui parvenir |
| Course active jamais relue après acceptation | il retombait sur K1, sa course invisible |
| Publication interrompue tant que K2 tenait l'écran | il sortait du pool en lisant « restez en ligne » |

**Validé sur appareil** : connexion coursier, K1 (plafond retenu + palier
d'entrée, FR-010 ; verrouillage en ligne ; « nouveau jour, déclarez »), entrée au
pool, `GET /admin/dispatch/pool` **par HTTP avec la seule `zone_id`**, dispatch →
K2 plein écran (arrêts et distances inter-arrêts, destination sans coordonnée,
gain détaillé faisant le total, avance avec son plafond, « distances estimées »
en dégradé sans OSRM), une acceptation en 25 s, expiration → K2-1b persistant
avec « sans pénalité — 1 sur 3 aujourd'hui » et retour au tableau de bord,
demande de permission, et **un coursier immobile depuis plus de trois minutes
resté dans le pool** grâce à la cadence.

**Non validé visuellement** : la bascule K2 → écran de course après acceptation.
Le correctif est en place et la suite est verte, mais piloter un compte à rebours
de 40 s par `adb shell input tap` à l'aveugle n'a pas permis de l'observer. À
reprendre à la main.

**Pièges d'environnement rencontrés**, à ajouter aux rappels du quickstart :

- `adb emu geo fix` avec la MÊME position n'émet aucun relevé — il faut déplacer ;
- une réinstallation par `flutter run` **révoque** les permissions accordées par
  `adb shell pm grant` ;
- `mode_paiement` vaut `cash` (pas `especes`), et `POST /commandes` exige
  l'en-tête `Idempotency-Key` **et** un repère (`repere_texte`) ;
- allonger `dispatch.timer_offre_s` pour tester à la main **casse la
  configuration** si `dispatch.verrou_offre_s` ne suit pas — le garde-fou du
  domaine refuse, à juste titre, et le tic s'arrête.

### 7.1 Défaut d'affichage mineur — **non corrigé**

Quand la disponibilité tombe en erreur, K1 affiche **deux fois** le même message
(« Vous ne recevez pas de courses ») : une fois en bandeau de reconnexion, une
fois en carte d'erreur — parce qu'un code d'erreur inconnu retombe sur la même
clé i18n. Redondant, jamais faux. Laissé tel quel : le corriger demande de
décider quel message porte quel cas, ce qui est une question de produit et non de
code.
