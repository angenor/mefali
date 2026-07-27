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

### 4.2 Désaccord de lockfiles Flutter — **non corrigé, hors périmètre**

`./scripts/verifier-accord-locks.sh` signale `source_gen` en **4.2.4** dans
`apps/mefali_client/pubspec.lock` contre **4.2.3** dans `mefali_core` et
`mefali_pro`.

Ce désaccord **préexiste** au cycle DSP 009 — vérifié en le rejouant sur l'arbre
`git stash`. Le corriger suppose de toucher `apps/mefali_client/`, que le plan de
ce cycle liste explicitement parmi les zones **non touchées** : l'app cliente
n'est pas modifiée par le dispatch, et y aligner une dépendance de génération
ferait sortir le cycle de son périmètre (constitution IX) sans qu'aucun test du
cycle ne couvre l'effet.

**À traiter** par un `flutter pub add source_gen:4.2.3 --dev` incrémental dans
`mefali_client` (jamais `pub upgrade`, FR-032), au prochain cycle qui touche
cette app.

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
