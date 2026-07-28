# Feature Specification: App coursier — course active multi-arrêts, cash et hors-ligne

**Feature Branch**: `010-coursier-course-active`

**Created**: 2026-07-28

**Status**: Draft

**Input**: User description: "Lis docs/user-stories-v2.md, module CRS — Coursier, et docs/cadrage-v5.md sections §7.4, §7.5 et §7.6. Fonctionnalité : app coursier — course active multi-arrêts, cash et hors-ligne. Périmètre : CRS-01, CRS-02, CRS-03, CRS-04, CRS-05, CRS-06, CRS-08 — critères tels quels. Disponibilité + plafond d'avance du jour + gains ; écran d'offre (arrêts ordonnés, gain total, montant total à avancer, timer, sonnerie canal haute importance) ; course active = itinéraire multi-arrêts avec checklist des collectes par vendeur, lecture des notes vocales de repère, appels via l'app journalisés, scan par arrêt, transitions 1 tap ; confirmation de livraison à trois voies (scan du QR de réception client / code 4 chiffres / dégradé dépôt autorisé) avec PRÉ-PROVISIONNEMENT HORS-LIGNE : à l'assignation l'app télécharge les empreintes (hash salé) du code et du jeton QR pour valider sans réseau, 3 codes faux = blocage + alerte admin ; preuves d'échec (bouton inactif tant que ≥ 2 appels via l'app espacés de 3 min + 10 min de présence géolocalisée + 1 photo ne sont pas réunis) ; caisse (avances par arrêt, remboursements, indemnisations liées à un litige) ; file d'actions hors-ligne avec UUID client, rejeu idempotent, serveur fait foi en conflit — test obligatoire : couper le réseau entre le scan et la livraison, tout se réconcilie sans perte ni doublon. Hors périmètre : CRS-07 (signaler/bloquer, P1). La paie fixe de la promo est HORS PRODUIT (aucune story) : présence vérifiable via les heartbeats DSP-01. Personas : Yao. Points d'attention : c'est le module le plus critique opérationnellement ; maquettes : docs/design/png/K1, K2, K3, K4, K5 — la checklist multi-arrêts de K3 est la cible exacte."

## Clarifications

### Session 2026-07-28

- Q: Le cadrage **§7.6** exige « Position GPS toutes les 15–30 s » et **DSP-01** sort du pool tout coursier muet ; **CRS-02** veut une sonnerie prolongée et **CRS-05** dix minutes de présence géolocalisée. Aucune section ne dit si l'app doit rester active écran éteint — le cycle 009 a livré le premier plan seulement et a laissé la décision à CRS. Que construit ce cycle ? → A: **Un service continu tant que le coursier est en ligne** : position publiée, offre reçue et sonnée, présence géolocalisée mesurée **même écran éteint et téléphone en poche**. C'est la seule lecture qui tienne les trois exigences citées à la fois — un coursier qui roule doit rester dans le pool, une offre de 40 s doit le réveiller, et les 10 min de présence ne peuvent pas dépendre de sa discipline à garder l'écran allumé. Coût assumé : notification permanente, permission de localisation, gestion de la batterie. Reflété en FR-111 à FR-115, US7, les cas limites et SC-018.
- Q: Le cadrage **§7.4-5** dit « Mode dépôt autorisé **par le client** : photo + géolocalisation », mais aucune section ne dit **où ni quand** le client l'autorise — **CMD-02/03** énumèrent ce que porte la commande, et le dépôt n'y figure pas. D'où vient cette autorisation ? → A: **Un drapeau porté par la commande, FERMÉ par défaut, que seule l'exploitation peut ouvrir** avec un motif tracé (le client appelle l'agence). L'app cliente le posera elle-même dans son propre cycle, sans changement de contrat. Respecte « autorisé par le client » sans ouvrir le périmètre de ce cycle à une surface cliente. Reflété en FR-039, FR-048 et FR-116.
- Q: Le coursier paie le vendeur en espèces à chaque arrêt. Si la commande a été **prépayée** en mobile money (**§7.5** : au-delà du plafond, prépaiement obligatoire), le client ne lui rembourse rien à la livraison — et aucune section ne dit qui le rembourse : **PAY-01** ne décrit que la chaîne cash, et **PAY-01/02/05 sont en tranche T3** (§0.5). Comment la caisse le modélise-t-elle ? → A: **Déféré à PAY (T3)**. Ce cycle ne modélise que le remboursement **par encaissement cash** ; le mouvement « remboursement dû par Mefali » n'est pas construit. Limite assumée et **explicite** : tant que PAY-01/PAY-02 ne l'ont pas posé, une commande prépayée dont un arrêt a été collecté laisse une avance **non soldée** dans la caisse — ce cycle la signale comme telle plutôt que de la faire disparaître. Reflété en FR-117, les cas limites et les hypothèses.

**Décisions confirmées par les sources (sans question, sections citées)** — ambiguïtés candidates tranchées par les documents produit, le socle déjà livré ou les maquettes, plutôt que par supposition :

- **La paie fixe de la promotion de lancement n'est PAS construite.** `docs/user-stories-v2.md` (module CRS, note de fin) et le cadrage **§7.1** la nomment « **hors produit** » : engagement opérationnel, présence vérifiée par les heartbeats DSP-01 déjà livrés, paie manuelle. L'état **1c de K1** (« Livraisons offertes — paie fixe en cours : 800 FCFA / course livrée », « 3 courses × 800 FCFA (paie fixe) ») est donc un **écart de maquette assumé** : le bandeau de gains montre ce que le produit sait calculer — la somme des **parts coursier** des courses livrées du jour. Reflété en FR-091 et dans les hypothèses.
- **Le coursier ne reçoit JAMAIS le code de livraison en clair, ni hors ligne.** Le cycle 008 l'a posé comme invariant (« il en reçoit l'empreinte, et c'est le client qui le lui dicte ») ; le pré-provisionnement de CRS-04 transporte des **empreintes salées**, jamais des secrets, exactement comme le pré-provisionnement d'arrêts déjà livré au cycle 006. Reflété en FR-037 et FR-038.
- **La vérification hors ligne n'est pas la vérité : c'est une autorisation à continuer.** Le code saisi et le jeton lu **voyagent dans la file** et sont **revalidés par le serveur** au rejeu (constitution V — « en cas de conflit au rejeu, le serveur fait foi »), comme le fait déjà le code de secours vendeur du cycle 006. La validation locale sert à ce que Yao **ne reste pas planté devant la porte** ; elle ne clôt rien de définitif. Reflété en FR-045, FR-046 et FR-085.
- **La boucle d'états, la remise et l'arbre des échecs existent déjà côté serveur** (cycle 008 : `en_route` / `arrivé` / `indisponible` / substitutions / remise à trois voies avec compteur d'essais / arbre §7.5 complet). Ce cycle **branche l'app dessus** et **implémente la précondition de preuves** que le cycle 008 avait laissée à un double. Il ne réécrit aucune de ces règles. Reflété dans « Ce que ce cycle NE construit PAS ».
- **La checklist de K3 coche des ARTICLES, pas des arrêts.** `docs/user-stories-v2.md` CRS-03 dit « articles regroupés par vendeur, cochés arrêt par arrêt », et K3-1a montre une coche par ligne avec un bouton « Indisponible » **par ligne**. L'indisponibilité d'une **ligne** emprunte le chemin de substitution déjà livré (CMD-06) ; l'indisponibilité d'un **arrêt entier** (vendeur fermé) emprunte le chemin d'arrêt déjà livré. Deux chemins distincts, aucun nouveau. Reflété en FR-014 à FR-020.
- **La note du coursier reste absente** (module AVI non construit) : K1 affiche « Note du jour 4,8 / 5 » que rien ne peut alimenter. Le cycle 009 avait déjà tranché — l'absence vaut mieux qu'un chiffre inventé. Le **taux d'acceptation**, lui, est un compteur **réellement tenu** par le dispatch : il peut être affiché. Reflété en FR-093 et FR-094.
- **Le montant total à avancer ne dépasse jamais le plafond du jour** : le filtre d'éligibilité du cycle 009 l'a garanti avant l'offre. L'écran de course active **affiche** le reste disponible, il ne re-décide rien. Reflété en FR-013.
- **Aucune coordonnée du client ne sort avant acceptation** (minimisation ARTCI, cycle 009 FR-088) : l'adresse exacte, le repère textuel, la note vocale et le numéro n'entrent dans le pré-provisionnement **qu'à l'assignation**. Reflété en FR-011 et FR-104.
- **CRS-07 (signaler / bloquer) est hors périmètre** (P1, tranche T4). La carte « Signaler ou bloquer » de **K5-1a** et la feuille **K5-1d** ne sont pas construites ; le port des paires bloquées posé par le cycle 009 continue de répondre « aucune paire bloquée ». Reflété en FR-110.
- **La validation d'indemnisation, le fonds d'incidents et l'écran d'exposition appartiennent à ADM-07**, qui les nomme mot pour mot : « file des litiges avec preuves ; **validation d'indemnisation** ; solde et mouvements du **fonds** ; **exposition temps réel (Σ avances) avec seuil d'alerte** » — et CRS-06 y renvoie explicitement « (ADM-07) ». Ce cycle pose donc les **écritures, les états et les endpoints** (exercés par API, comme le cycle 009 l'a fait pour ses surfaces d'exploitation) ; il ne construit ni écran Nuxt, ni **solde du fonds d'incidents**, ni **seuil d'alerte**. Reflété en FR-072, FR-075 et FR-109.
- **Le lien de paiement mobile money sur place n'est PAS construit** : c'est **PAY-03**, story **P1** du module PAY (§0.6), et les stories PAY sont en tranche **T3** (§0.5). L'option « Générer un lien de paiement mobile money » de **K4-1a** est donc un **écart de maquette assumé** ; l'app rappelle l'absence de paiement partiel et renvoie au chemin de secours. Reflété en FR-050.
- **La sonnerie : ce cycle pose le canal et le réveil côté app, pas l'émission serveur.** **NTF-01** (« coursier haute importance, sonnerie prolongée ») est une story distincte du module NTF, de la même tranche T1 (§0.5, §0.6), et le cycle 009 a déjà posé le contrat d'émission. Reflété en FR-098 et FR-113.

## User Scenarios & Testing *(mandatory)*

Persona de ce cycle : **Yao (coursier)** — moto, Android d'entrée de gamme, réseau intermittent au marché couvert et dans les cours, **avance le cash sur ses fonds propres**, souvent une main sur le guidon et l'autre sur le téléphone, en plein soleil. Deux personas secondaires apparaissent sans que leurs surfaces soient modifiées : **Awa (cliente)**, qui dicte un code ou montre un QR sans avoir besoin d'internet, et **l'Admin (exploitation Tiassalé)**, destinataire des alertes de blocage et des demandes d'indemnisation.

Priorités produit : **CRS-01 à CRS-06 et CRS-08 sont toutes P0** (`docs/user-stories-v2.md` §0.6 : 6 P0 + 2 P1 pour le module). Les priorités P1→P7 attachées aux stories ci-dessous sont l'**ordre de livraison interne** au cycle (chaîne de dépendances), pas une hiérarchie produit. CRS-01→04 relèvent de la tranche T1, CRS-05/06 de T2, CRS-08 de T4 pour son durcissement final (§0.2).

### Ce que ce cycle NE construit PAS parce que c'est déjà là

- **Socle (cycle 001)** : journal d'événements transactionnel, idempotence des actions par identifiant fourni par le client, contrat d'interface et clients générés.
- **Zones (cycle 002)** : configuration héritée — ce cycle **ajoute ses paramètres** dans ce mécanisme, il n'en crée aucun autre.
- **Comptes (cycle 003)** : rôle coursier, dossier validé, sessions, véhicules déclarés.
- **Prestataires (cycle 005)** : sites vendeurs, positions, horaires, catalogue.
- **QR (cycle 006)** : **scan du QR de plaque à chaque arrêt**, code de secours vendeur (3 essais), contrôle de proximité, photo de récupération, **pré-provisionnement des empreintes d'arrêt**, et la **file locale d'actions** avec son rejeu idempotent — sur laquelle ce cycle s'appuie et qu'il **étend**.
- **Tarification (cycle 007)** : ordre optimisé des arrêts, distances routières, devis figé, **part coursier** et sa décomposition (déplacement, arrêts, effort).
- **Commandes (cycle 008)** : machine à états fermée à trois niveaux, **boucle déclarative par arrêt** (« je pars », « je suis arrivé », « indisponible »), **substitutions** selon la préférence du client, **remise à trois voies** avec compteur d'essais et verrouillage, **arbre complet des échecs §7.5** avec ses issues, sanctions et indemnisations dues, code et jeton remis au client dès la création, appel client journalisé.
- **Dispatch (cycle 009)** : pool temps réel, éligibilité (dont la **capacité d'avance**), scoring, offre en cascade et broadcast, escalade, réassignation, et **les deux surfaces coursier déjà livrées** — disponibilité (mise en ligne, plafond du jour, état de reconnexion, maquette K1) et **écran d'offre** (compte à rebours, arrêts, gain, montant à avancer, accepter/refuser, « déjà prise »).

### Ce que ce cycle construit

L'**app coursier complète**, du moment où la course est acceptée jusqu'à ce que l'argent soit rendu :

- la **course active** telle que K3 la dessine — arrêt courant développé, **checklist des articles regroupés par vendeur**, montant à payer par vendeur, transitions en un tap, itinéraire, appels **journalisés**, lecture de la **note vocale de repère** du client ;
- la **confirmation de livraison à trois voies** de K4, avec le **pré-provisionnement des empreintes de remise** qui la rend possible **sans réseau**, son compteur d'essais et son blocage ;
- les **preuves d'échec** de CRS-05, mesurées par l'app et **vérifiées par le serveur** — la précondition que le cycle 008 avait laissée à un double devient réelle ;
- la **caisse** de K5 — avances en cours, historique du jour, remboursements, indemnisations liées à un litige — et son **exposition temps réel** pour l'exploitation ;
- le **bandeau de gains du jour** de K1 ;
- le **fonctionnement continu** qui rend tout cela vrai hors de l'écran : tant que Yao est en ligne, l'app publie sa position, reçoit son offre et **sonne**, et mesure sa présence — téléphone verrouillé, dans sa poche ;
- et la **file d'actions hors-ligne complète** : plus seulement les collectes, mais les transitions, les confirmations, les photos et les appels — avec la réconciliation qui, en cas de conflit, **donne raison au serveur** et le dit clairement à Yao.

### Surface d'interface, frontières et modules simulés

Maquettes de référence : `docs/design/png/K3-course-active.png` (**cible exacte** de la checklist multi-arrêts), `K4-confirmation-livraison.png`, `K5-caisse-historique.png`, et les **affinages** de `K1-disponibilite.png` (bandeau de gains, raccourci caisse, navigation basse Tableau / Courses / Caisse) et `K2-offre-course.png`.

Trois modules dont ce cycle dépend **ne sont pas construits** et restent exercés par des doubles ou par API :

| Module non construit | Ce que ce cycle pose | Ce qu'il ne construit pas |
|---|---|---|
| **Notifications (NTF-01/02, T1)** | le contrat d'émission déjà posé par le cycle 009 reste inchangé | le push haute priorité serveur et le repli SMS |
| **Console admin (ADM-02/04/07)** | les **endpoints** d'exploitation (blocages de code, exposition cash totale, indemnisations à valider) exercés par API | les écrans Nuxt correspondants |
| **Avis & litiges (AVI-04, T2)** | la **lecture** d'un litige rattaché à une indemnisation, et le rattachement inverse | l'enregistrement du litige lui-même |

L'**app cliente n'est pas modifiée**.

---

### User Story 1 - La checklist qui dit quoi acheter et combien avancer (CRS-03, Priority: P1 — produit : P0)

Yao a accepté une course de trois étals. Son écran ne lui montre **qu'un arrêt à la fois** : l'étal courant, développé, avec le nom du vendeur, sa distance, un bouton d'itinéraire, un bouton d'appel — et surtout **la liste des articles à prendre chez CE vendeur**, cochables un par un. Sous la liste, en gros, **ce qu'il doit payer à ce vendeur** : le montant des articles réellement pris, pas celui de la commande entière. Un article manque : il le déclare indisponible sur sa ligne, la ligne se barre, le montant à payer baisse immédiatement, et la préférence de la cliente s'applique — retirer, appeler, ou proposer un remplacement. Le bouton principal, en bas, est toujours le même : **scanner le QR du vendeur**. Le scan fait, l'arrêt se replie avec son heure, l'arrêt suivant se développe. Les trois arrêts collectés, l'écran bascule : bandeau vert « en route vers le client », le repère de la cliente avec **sa note vocale jouable**, et le montant total à **encaisser** à l'arrivée.

**Why this priority**: C'est l'écran où Yao passe 90 % de son temps de travail, et le seul qui empêche l'erreur qui coûte le plus cher — payer le mauvais montant au mauvais vendeur. Toutes les autres stories du cycle en dépendent : sans course active, il n'y a rien à confirmer, rien à prouver, rien à mettre en caisse.

**Independent Test**: Assigner une course de trois vendeurs, dérouler les trois arrêts en cochant les articles, déclarer un article indisponible et vérifier que le montant à payer baisse du bon montant et que la préférence de la cliente s'applique, scanner chaque arrêt, puis vérifier la bascule « en route vers le client » avec la note vocale jouable et le montant à encaisser — sans qu'aucune confirmation de livraison ne soit encore construite.

**Acceptance Scenarios**:

1. **Given** une course de 3 arrêts assignée à Yao, **When** il ouvre sa course, **Then** l'arrêt 1 est développé avec ses articles et son montant, les arrêts 2 et 3 sont repliés en « à collecter », et l'entête indique « Arrêt 1 / 3 ».
2. **Given** l'arrêt 1 développé avec 3 articles pour 1 500 FCFA, **When** Yao déclare un article à 700 FCFA indisponible, **Then** la ligne est barrée, le montant à payer affiché passe à 800 FCFA, et la préférence de la cliente pour cet article est appliquée sans qu'il ait à la choisir.
3. **Given** un article dont la préférence est « m'appeler », **When** Yao le déclare indisponible, **Then** l'app lui propose l'appel en action mise en avant, et l'appel qu'il passe est **journalisé** avec son motif.
4. **Given** l'arrêt 1 collecté par scan, **When** l'écran se rafraîchit, **Then** l'arrêt 1 est replié avec son heure de collecte et l'arrêt 2 est développé, sans que Yao ait rien à faire d'autre.
5. **Given** les 3 arrêts collectés, **When** le dernier scan est accepté, **Then** l'écran bascule en « en route vers le client » avec le repère, la note vocale jouable, la distance, et le **montant total à encaisser** (articles + livraison).
6. **Given** l'écran « en route vers le client », **When** Yao appuie « je suis arrivé chez le client », **Then** l'arrivée est enregistrée en un seul tap et l'écran de confirmation s'ouvre.

---

### User Story 2 - Confirmer la livraison, même sans réseau (CRS-04, Priority: P2 — produit : P0)

Yao est devant la porte d'Awa, dans une cour où le réseau ne passe pas. Trois voies s'offrent à lui, dans cet ordre : **scanner le QR de réception** qu'Awa affiche sur son téléphone, **saisir le code à 4 chiffres** qu'elle lui dicte, ou — si et seulement si l'agence a ouvert le dépôt pour cette commande — **déposer** le colis avec une photo et sa position. Les deux premières voies **fonctionnent sans réseau** : à l'assignation, son app a téléchargé les **empreintes** du code et du jeton, jamais les secrets. L'app le lui dit : « validation locale — sera synchronisée ». S'il se trompe de code trois fois, la saisie se **bloque** pour cette livraison, l'app lui donne le numéro de l'agence, et l'exploitation est alertée dès que le réseau revient.

**Why this priority**: C'est le point de bascule où l'argent change de mains. Une confirmation impossible, c'est un coursier planté devant une porte avec 5 800 FCFA de marchandise avancée sur ses fonds propres.

**Independent Test**: Assigner une course, la mener jusqu'à l'arrivée, couper le réseau, confirmer par QR puis (sur une autre course) par code ; vérifier dans les deux cas que l'app accepte localement, que la course se clôt à l'écran, et qu'au retour du réseau le serveur la clôt réellement. Vérifier que 3 codes faux bloquent la saisie et produisent une alerte d'exploitation.

**Acceptance Scenarios**:

1. **Given** une course arrivée chez le client et le réseau coupé, **When** Yao scanne le QR de réception d'Awa, **Then** l'app accepte, affiche « validation locale — sera synchronisée », et clôt la course à l'écran.
2. **Given** la même situation, **When** Yao saisit le code à 4 chiffres dicté par Awa, **Then** l'app le vérifie **sans réseau** et accepte de la même manière.
3. **Given** un code faux saisi hors ligne, **When** Yao valide, **Then** l'app affiche « code faux — il reste N essais » sans jamais révéler le bon code.
4. **Given** 3 codes faux sur la même livraison, **When** Yao valide le troisième, **Then** la saisie par code est **bloquée** pour cette livraison, l'écran affiche le motif en langage clair et le numéro de l'agence, le **scan QR reste disponible**, et une alerte d'exploitation est émise (immédiatement, ou au retour du réseau).
5. **Given** une confirmation validée hors ligne, **When** le réseau revient, **Then** le serveur revalide la preuve et clôt la livraison ; **et si** la preuve est refusée, la course **n'est pas close**, Yao reçoit un message clair et l'exploitation est alertée.
6. **Given** un client qui n'a pas l'appoint, **When** Yao ouvre la confirmation, **Then** l'app rappelle qu'il n'existe **aucun paiement partiel** et renvoie au chemin de secours (appel à l'agence) — le lien de paiement sur place relève de PAY-03 (P1) et n'est pas construit ici.
7. **Given** une commande dont le dépôt n'a pas été ouvert par l'agence, **When** Yao ouvre la confirmation, **Then** la voie « dépôt » n'apparaît pas du tout — jamais grisée, jamais suggérée.

---

### User Story 3 - Rien ne se perd, rien ne double (CRS-08, Priority: P3 — produit : P0)

Yao travaille dans un marché couvert : son réseau apparaît et disparaît toutes les deux minutes. Chaque action qu'il fait — partir vers un arrêt, arriver, cocher, scanner, photographier, appeler, confirmer — est **enregistrée localement avec son identifiant unique et son heure**, puis rejouée dès que le réseau revient, **dans l'ordre**. Un rejeu ne crée jamais de doublon. Si le serveur a déjà décidé autre chose — la course lui a été retirée, l'arrêt est déjà collecté — **c'est le serveur qui a raison**, et l'app le lui dit dans une phrase qu'il comprend, sans jargon.

**Why this priority**: C'est la garantie qui rend les deux stories précédentes utilisables à Tiassalé. Elle est testable seule : c'est le **test obligatoire** du module — couper le réseau entre le scan du dernier arrêt et la livraison, et vérifier que tout se réconcilie sans perte ni doublon.

**Independent Test**: Dérouler une course complète avec le réseau coupé entre le dernier scan et la confirmation de livraison ; rétablir le réseau ; vérifier qu'exactement une collecte et exactement une remise ont été enregistrées côté serveur, dans le bon ordre, et que l'app affiche l'état réel. Rejouer manuellement la même file deux fois : aucun doublon.

**Acceptance Scenarios**:

1. **Given** le réseau coupé, **When** Yao scanne un arrêt puis confirme la livraison, **Then** les deux actions sont enfilées avec leur heure locale et l'app continue de fonctionner normalement.
2. **Given** une file de 2 actions en attente, **When** le réseau revient, **Then** elles sont rejouées **dans l'ordre de leur création** et la file se vide, en moins de 5 secondes après le retour du réseau.
3. **Given** une action déjà rejouée avec succès, **When** elle est rejouée une seconde fois, **Then** le serveur rend le même résultat sans rien réécrire ni ré-émettre.
4. **Given** une course réassignée à un autre coursier pendant la coupure, **When** la file de Yao se rejoue, **Then** ses actions sont refusées, l'app affiche un message clair (« cette course ne vous est plus attribuée »), et **rien n'est perdu en silence** — le refus est tracé et l'avance éventuellement engagée part en litige.
5. **Given** une action en échec réseau répété, **When** l'app la rejoue, **Then** elle reste en file avec son compteur de tentatives, et Yao voit combien d'actions attendent d'être synchronisées.

---

### User Story 4 - Prouver qu'on a vraiment essayé (CRS-05, Priority: P4 — produit : P0)

Awa ne répond pas. Yao ne peut pas déclarer la livraison impossible d'un simple tap : le bouton reste **inactif** tant que trois preuves ne sont pas réunies — **au moins 2 appels via l'app espacés d'au moins 3 minutes**, **10 minutes de présence géolocalisée** sur place, et **une photo** du lieu. L'écran affiche les trois, chacune avec son état : faite, en cours avec son décompte, à faire. Quand les trois sont là, le bouton s'active, et les preuves partent **attachées au dossier** : c'est ce qui garantit à Yao d'être indemnisé, et à Mefali de ne pas l'être pour un faux refus.

**Why this priority**: C'est la condition d'entrée de l'arbre des échecs déjà construit (le cycle 008 la vérifie déjà, mais contre un double). Sans elle, « le coursier ne perd jamais » devient une invitation à déclarer des échecs fictifs.

**Independent Test**: Assigner une course, arriver chez le client, tenter de déclarer l'échec (bouton inactif), passer 2 appels espacés de 3 min, attendre 10 min sur place, prendre une photo, vérifier que le bouton s'active exactement à ce moment, déclarer l'échec, et vérifier que les trois preuves sont attachées et lisibles par l'exploitation.

**Acceptance Scenarios**:

1. **Given** une course arrivée chez le client, **When** Yao ouvre « livraison impossible », **Then** les 3 preuves sont listées avec leur état et le bouton de déclaration est **inactif**, avec le compteur « N preuve(s) sur 3 réunie(s) ».
2. **Given** 2 appels passés à 2 minutes d'intervalle, **When** Yao consulte l'écran, **Then** la preuve « 2 appels » n'est **pas** validée et l'app indique ce qui manque (l'espacement).
3. **Given** 6 minutes de présence sur place, **When** Yao consulte l'écran, **Then** la preuve de présence affiche sa progression (« encore 4 min ») et se met à jour sans qu'il ait à quitter l'écran.
4. **Given** les 3 preuves réunies, **When** Yao déclare la livraison impossible, **Then** l'issue est enregistrée avec ses preuves, l'arbre des échecs décide qui détient l'argent et la marchandise, et l'indemnisation due (le cas échéant) apparaît dans la caisse de Yao.
5. **Given** un serveur qui reçoit une déclaration d'échec dont les preuves ne sont **pas** réunies, **When** il la traite, **Then** il la **refuse** — l'app n'est pas la seule gardienne de la règle.
6. **Given** les preuves réunies hors ligne, **When** le réseau revient, **Then** la déclaration et ses preuves (dont la photo) sont rejouées sans perte.

---

### User Story 5 - La caisse : savoir à tout instant ce qu'on a avancé (CRS-06, Priority: P5 — produit : P0)

Yao a 5 550 FCFA de son propre argent chez trois vendeurs. Sa caisse le lui dit en gros, en haut de l'écran, avec la mention qui compte : « remboursé dès l'encaissement chez le client ». Dessous, l'**historique du jour**, course par course : ce qu'il a avancé, ce qui lui a été remboursé, ce qu'il a gagné. Puis les **indemnisations** — celles qui sont demandées, celles qui sont validées — chacune rattachée à son litige. Quand un litige est ouvert, il le voit avec son état et l'engagement de rappel de l'agence. Côté exploitation, la **somme de tout ce que les coursiers ont avancé** est lisible en temps réel : c'est l'exposition de Mefali, et elle ne doit jamais être une surprise.

**Why this priority**: C'est ce qui rend le mécanisme d'avance tenable pour Yao — et c'est le seul endroit où « le coursier ne perd jamais » devient vérifiable par lui, pas seulement promis.

**Independent Test**: Dérouler deux courses cash (une livrée, une en cours), déclarer un échec indemnisable sur une troisième, puis vérifier que la caisse affiche l'avance en cours exacte, l'historique des trois courses avec leurs trois chiffres, l'indemnisation à l'état « demandée » puis « validée » après action de l'exploitation, et que l'exposition totale visible côté exploitation égale la somme des avances en cours de tous les coursiers.

**Acceptance Scenarios**:

1. **Given** une course en cours avec 2 arrêts collectés pour 5 550 FCFA, **When** Yao ouvre sa caisse, **Then** « argent avancé en cours » affiche exactement 5 550 FCFA, avec le nombre de courses concernées.
2. **Given** la même course livrée et encaissée, **When** la caisse se rafraîchit, **Then** l'avance en cours retombe à 0 et la course apparaît dans l'historique avec avancé / remboursé / gain.
3. **Given** un échec de livraison avec preuves réunies sur une denrée périssable, **When** l'arbre des échecs décide l'indemnisation, **Then** une indemnisation **« demandée »** apparaît dans la caisse de Yao, rattachée à son litige.
4. **Given** une indemnisation demandée, **When** l'exploitation la valide (par API — l'écran appartient à ADM-07), **Then** elle passe à **« validée »**, l'écriture correspondante est tracée, et Yao la voit changer d'état.
5. **Given** trois coursiers avec des avances en cours, **When** l'exploitation consulte l'exposition, **Then** elle lit la somme exacte en temps réel, par coursier et au total, dans la devise de la zone — le **seuil d'alerte** sur cette somme appartenant à ADM-07.
6. **Given** aucune course du jour, **When** Yao ouvre sa caisse, **Then** l'écran affiche l'état vide de K5-1b — un solde à 0 et une invitation à passer en ligne, jamais une carte manquante.

---

### User Story 6 - Voir ce qu'on a gagné aujourd'hui (CRS-01, Priority: P6 — produit : P0)

Yao se met en ligne le matin et déclare son plafond d'avance du jour — cela existe déjà. Ce qu'il n'a pas encore, c'est le **bandeau de gains** : combien de courses livrées, combien gagné, et un **raccourci vers sa caisse**. Le plafond affiche aussi ce qui lui **reste disponible** compte tenu de ce qu'il a déjà avancé. Les trois destinations de l'app — tableau de bord, courses, caisse — deviennent accessibles depuis une navigation basse permanente.

**Why this priority**: C'est un affinage d'un écran déjà livré, dont la valeur (savoir ce qu'on gagne) est réelle mais qui ne bloque aucune autre story.

**Independent Test**: Livrer trois courses dans la journée, vérifier que le bandeau affiche 3 courses et la somme exacte des parts coursier ; engager une avance et vérifier que « reste disponible » diminue d'autant ; naviguer entre les trois destinations.

**Acceptance Scenarios**:

1. **Given** 7 courses livrées aujourd'hui, **When** Yao ouvre son tableau de bord, **Then** le bandeau affiche « 7 courses livrées » et la somme des parts coursier de ces courses, dans la devise de la zone.
2. **Given** un plafond déclaré de 10 000 FCFA et 3 500 FCFA avancés, **When** Yao consulte son plafond, **Then** « reste disponible » affiche 6 500 FCFA.
3. **Given** un changement de jour civil de la zone, **When** Yao ouvre son tableau de bord, **Then** les gains repartent de zéro — jamais de report.
4. **Given** n'importe quel écran de l'app coursier, **When** Yao utilise la navigation basse, **Then** il atteint tableau de bord, courses et caisse sans repasser par un menu.

---

### User Story 7 - Être réveillé par une offre (CRS-02, Priority: P7 — produit : P0)

L'écran d'offre existe déjà (cycle 009) : arrêts ordonnés, gain total, montant à avancer, compte à rebours, accepter/refuser en un tap. Ce qui manque, c'est **le réveil** — et ce qui le rend possible, **le fonctionnement continu**. Tant que Yao est en ligne, son app reste vivante écran éteint : elle publie sa position à la période de la zone (il ne sort plus du pool parce qu'il a rangé son téléphone), elle reçoit l'offre et **sonne longuement** sur un canal dédié de haute importance, et l'écran d'offre s'ouvre directement. Une notification permanente lui dit, en retour, que l'app travaille pour lui — et il peut la faire taire en se mettant hors ligne.

**Why this priority**: Sans réveil, les 40 secondes s'écoulent dans la poche de Yao et la cliente attend — mais l'écran lui-même fonctionne déjà, ce qui en fait le dernier maillon à poser. Le fonctionnement continu qu'il apporte sert aussi la présence géolocalisée de US4 et le suivi client de US1.

**Independent Test**: Mettre Yao en ligne, verrouiller le téléphone et le laisser 30 minutes : vérifier qu'il reste dans le pool sans interruption. Émettre une offre : vérifier que la sonnerie retentit sur le canal dédié, que l'écran d'offre s'ouvre en un tap, et que le compte à rebours affiché correspond au temps réellement restant, pas à 40 s remis à zéro.

**Acceptance Scenarios**:

1. **Given** Yao en ligne, sans course, téléphone verrouillé depuis 20 minutes, **When** une offre lui est émise, **Then** il est **toujours dans le pool** (sa position n'a jamais cessé d'être publiée) et une sonnerie prolongée retentit sur un canal dédié de haute importance.
2. **Given** cette sonnerie, **When** Yao ouvre la notification, **Then** l'écran d'offre s'affiche avec le **temps réellement restant** sur le compte à rebours.
3. **Given** une offre déjà expirée ou prise par un autre, **When** Yao l'ouvre, **Then** il lit « course attribuée à un autre coursier — sans pénalité » et non un compte à rebours mensonger.
4. **Given** Yao hors ligne ou déjà en course, **When** le système évalue les offres, **Then** aucune sonnerie ne retentit.
5. **Given** Yao qui se met hors ligne, **When** il quitte l'app, **Then** le fonctionnement continu s'arrête, la notification permanente disparaît, et plus aucune position n'est publiée.

---

### Edge Cases

- **Le vendeur n'a rien de ce qui est commandé** : tous les articles de l'arrêt sont déclarés indisponibles → l'arrêt entier devient indisponible, le montant à avancer tombe à zéro pour ce vendeur, et la course continue vers l'arrêt suivant (chemin d'arrêt existant, cycle 008).
- **Le montant à payer chez un vendeur dépasse ce que Yao a en poche** : l'éligibilité l'a exclu en amont sur le **total** ; l'écran affiche néanmoins le reste disponible pour qu'il constate l'écart, et le chemin de secours reste l'appel à l'agence.
- **Le QR de la plaque vendeur est illisible** (soleil, plaque abîmée) : le code de secours vendeur, déjà livré, reste la voie dégradée — 3 essais.
- **Le client montre un QR de réception qui n'est pas le sien** (autre commande) : l'empreinte ne correspond pas, l'app refuse sans révéler quoi que ce soit du bon jeton.
- **Le téléphone du client est éteint** et il ne connaît pas son code : voie « dépôt » si l'agence l'a ouverte pour cette commande, sinon **ultime recours** — appel à l'agence et confirmation manuelle admin (existant, cycle 008 / ADM-02).
- **Commande prépayée dont un arrêt a été collecté** : le client ne rembourse rien à la livraison, et le mouvement « remboursement dû par Mefali » n'existe pas encore (déféré à PAY, tranche T3). La caisse laisse alors l'avance **explicitement non soldée**, avec son motif — jamais un solde faussement remis à zéro.
- **Le coursier refuse la permission de localisation en arrière-plan, ou le système tue le service** : l'app le lui dit sans détour (il ne recevra pas d'offres écran éteint et sa présence ne sera pas mesurée), et le dispatch le sort du pool par expiration comme aujourd'hui — jamais un silence qui lui laisse croire qu'il attend une course.
- **La batterie du téléphone passe en économie d'énergie agressive** : la publication de position s'espace ou s'arrête ; l'app affiche son bandeau de reconnexion plutôt que de prétendre être en ligne.
- **Yao confirme la remise hors ligne puis son téléphone meurt** : la file est **durable** — elle survit à l'arrêt de l'app et au redémarrage du téléphone, et se rejoue au réseau suivant.
- **Le serveur refuse au rejeu une remise validée localement** : la livraison **ne se clôt pas**, Yao est prévenu par un message clair, l'exploitation est alertée, et la course reste ouverte (jamais « livrée » d'un côté et « en cours » de l'autre).
- **Deux appareils, une même course** : la file est locale à un appareil ; le serveur, seul juge, refuse la seconde exécution d'une action déjà résolue.
- **Le jour civil change au milieu d'une course** : les gains du jour et le plafond basculent au nouveau jour, mais **la course en cours garde son plafond d'origine** — rien n'est retiré à une course déjà acceptée.
- **10 minutes de présence géolocalisée sans position fiable** (GPS coupé, intérieur) : la preuve ne progresse pas et l'app dit pourquoi, plutôt que de valider une présence qu'elle n'a pas mesurée.
- **Yao appelle le client depuis son répertoire, hors de l'app** : l'appel n'est **pas** journalisé et ne compte pas comme preuve — l'app le dit explicitement sur l'écran de preuves.
- **Une indemnisation validée puis contestée** : l'écriture reste, une écriture inverse est ajoutée — jamais de suppression rétroactive.
- **Photo prise hors ligne** : elle attend dans la file avec son action ; l'app indique ce qui reste à envoyer et ne bloque jamais la suite de la course.

## Requirements *(mandatory)*

### Frontières et invariants (transversaux)

- **FR-001**: Le système MUST traiter tout montant comme un entier en unités mineures accompagné du code ISO 4217 de la zone ; aucun affichage, calcul ou transport de montant en nombre décimal.
- **FR-002**: Le système MUST refuser tout chemin de paiement partiel : la totalité en cash, ou la totalité en mobile money.
- **FR-003**: Le système MUST écrire un événement dans la même transaction que toute transition d'état qu'il provoque, et déclarer tous ses événements dans la taxonomie avant implémentation.
- **FR-004**: Toute chaîne affichée à Yao MUST être une clé i18n fr ; aucun texte en dur, y compris dans les messages de refus et de réconciliation.
- **FR-005**: Tout paramètre qualifié de paramétrable par ce cycle MUST vivre dans la configuration de zone héritée ; ce cycle ne code aucun seuil en dur.
- **FR-006**: Le système MUST refuser toute action de course émise par un compte qui n'est pas le coursier assigné à cette course, y compris au rejeu d'une action de la file (contrôle de propriété au rejeu, dette relevée au cycle 008).
- **FR-007**: Le système MUST ne jamais journaliser ni transporter en clair, dans un événement, une notification ou un journal : le code de livraison, le jeton de réception, le code de secours vendeur, ou un numéro de téléphone.
- **FR-008**: L'app MUST rester utilisable sur un écran de 360 × 800 en plein soleil : cibles tactiles d'au moins 48 dp pour toute action de course, contrastes conformes aux jetons de design.
- **FR-009**: Le système MUST utiliser les distances par itinéraire routier déjà calculées par le devis figé ; l'app ne recalcule aucune distance et n'affiche jamais une distance à vol d'oiseau non signalée.
- **FR-010**: Le système MUST conserver l'horodatage local des actions comme donnée d'observation, et faire foi sur l'horodatage serveur pour toute conséquence financière.

### Course active et checklist (CRS-03)

- **FR-011**: À l'assignation, le système MUST fournir à l'app la course complète : arrêts dans l'ordre optimisé avec leur vendeur, position, distance depuis le précédent, **articles à collecter par vendeur** (libellé, quantité, prix verrouillé, préférence de substitution), montant à avancer par arrêt, politique photo résolue, et — pour la remise — le nom d'usage du client, son repère (texte et/ou note vocale), sa position et le montant total à encaisser.
- **FR-012**: L'app MUST développer **un seul arrêt à la fois** — l'arrêt courant — et présenter les suivants repliés avec leur état (« à collecter »), les précédents repliés avec leur heure de collecte.
- **FR-013**: L'app MUST afficher, pour l'arrêt courant, le montant exact à payer à ce vendeur, recalculé à chaque changement de disponibilité d'un article, et rappeler le reste disponible du plafond du jour sans jamais re-décider l'éligibilité.
- **FR-014**: Yao MUST pouvoir cocher chaque article de l'arrêt courant ; les coches sont **locales**, persistantes, et survivent à la fermeture de l'app comme à l'absence de réseau.
- **FR-015**: Yao MUST pouvoir déclarer **une ligne** indisponible ; la ligne est barrée, retirée du montant à payer de l'arrêt, et la **préférence du client** pour cet article s'applique par le chemin de substitution existant.
- **FR-016**: Quand la préférence est « m'appeler », l'app MUST mettre l'appel en avant comme action principale de la ligne concernée.
- **FR-017**: Quand la préférence est « remplacer », l'app MUST permettre de proposer un remplacement avec sa photo et son prix, et afficher la fenêtre de décision restante du client.
- **FR-018**: Yao MUST pouvoir déclarer l'**arrêt entier** indisponible (vendeur fermé, plus rien en stock) avec un motif prédéfini, par le chemin d'arrêt existant.
- **FR-019**: L'app MUST proposer, pour l'arrêt courant, une action **itinéraire** vers la position du vendeur et une action **appeler** ; les deux sont grisées avec leur motif quand elles exigent le réseau et qu'il est absent.
- **FR-020**: L'action principale de l'arrêt courant MUST être le scan du QR du vendeur, disponible **hors ligne**, et l'app MUST indiquer explicitement que le scan et les coches fonctionnent sans connexion.
- **FR-021**: Après une collecte acceptée, l'app MUST replier l'arrêt avec son heure et développer l'arrêt suivant, sans action supplémentaire de Yao.
- **FR-022**: Yao MUST pouvoir déclarer « je pars vers cet arrêt » et « je suis arrivé » en **un tap**, chacune enfilée et idempotente.
- **FR-023**: Quand tous les arrêts sont résolus, l'app MUST basculer sur l'écran « en route vers le client » : récapitulatif des arrêts avec leurs heures, repère du client, distance, et **montant total à encaisser** (articles révisés + livraison).
- **FR-024**: L'app MUST permettre de **jouer la note vocale de repère** du client, y compris **hors ligne** : la note est téléchargée à l'assignation, jamais au moment où Yao en a besoin.
- **FR-025**: L'app MUST afficher le repère textuel du client quand il existe, à côté ou à la place de la note vocale.
- **FR-026**: L'app MUST afficher un bandeau d'état hors-ligne quand la connexion manque, indiquant que les actions sont enregistrées et seront synchronisées automatiquement.
- **FR-027**: L'app MUST afficher la progression de la course (« arrêt N / total ») dans son entête, à tout moment.
- **FR-028**: Le système MUST rendre la course active consultable après un redémarrage de l'app **sans réseau**, à partir de ce qui a été pré-provisionné.

### Appels journalisés (CRS-03, CRS-05)

- **FR-029**: Yao MUST pouvoir appeler le client et le vendeur **depuis l'app**, sans avoir à lire ni composer un numéro.
- **FR-030**: Le système MUST journaliser chaque intention d'appel émise par le coursier avec sa direction, son motif et son horodatage — **jamais le numéro**.
- **FR-031**: Le système MUST accepter la journalisation d'un appel **coursier** (le chemin existant ne couvre que le client).
- **FR-032**: L'app MUST enfiler l'intention d'appel quand le réseau manque ; l'appel lui-même reste possible hors ligne (il ne dépend pas d'internet).
- **FR-033**: Le système MUST conserver les horodatages des appels d'une course de façon à pouvoir vérifier leur **nombre** et leur **espacement**.
- **FR-034**: L'app MUST indiquer explicitement que seuls les appels passés **via l'app** comptent comme preuve.
- **FR-035**: Le système MUST distinguer les appels par motif (suivi, substitution, absence du client) pour que la preuve d'échec ne compte que ce qui la concerne.
- **FR-036**: L'app MUST afficher, sur la ligne d'un appel déjà passé, son heure et son issue déclarée (sans réponse / répondu).

### Confirmation de livraison, y compris hors ligne (CRS-04)

- **FR-037**: À l'assignation, le système MUST fournir à l'app les **empreintes salées** du code de livraison et du jeton de réception, et **jamais** les valeurs elles-mêmes.
- **FR-038**: Le sel des empreintes MUST rendre une empreinte inutilisable hors de sa commande (aucune table pré-calculée réutilisable d'une commande à l'autre).
- **FR-039**: L'app MUST proposer les trois voies dans un ordre hiérarchisé : **scan du QR de réception** en action principale, **code à 4 chiffres** en action secondaire, **dépôt** en action discrète — cette dernière n'étant **affichée que si le drapeau de dépôt de la commande est ouvert**, et jamais affichée grisée sinon.
- **FR-040**: L'app MUST vérifier **localement** le jeton scanné et le code saisi contre les empreintes pré-provisionnées, **sans réseau**.
- **FR-041**: L'app MUST afficher, quand elle valide hors ligne, un bandeau « validation locale — sera synchronisée » qui ne prétend jamais que la course est close côté serveur.
- **FR-042**: L'app MUST refuser un code faux en indiquant le **nombre d'essais restants**, sans jamais révéler ni suggérer le bon code.
- **FR-043**: Après le nombre d'essais de la zone (défaut : 3), l'app MUST **bloquer la saisie par code** pour cette livraison, afficher le motif en langage clair et le numéro de l'agence, et **laisser le scan QR disponible**.
- **FR-044**: Le système MUST émettre une **alerte d'exploitation** au blocage du code — immédiatement si le réseau est là, au retour du réseau sinon — et la rendre lisible par l'exploitation.
- **FR-045**: Le compteur d'essais MUST être **partagé** entre l'app et le serveur : le compteur retenu est le plus élevé des deux, et les essais faits hors ligne comptent au rejeu.
- **FR-046**: Le système MUST **revalider côté serveur** toute preuve de remise reçue par la file ; en cas de refus, la livraison n'est pas close, Yao reçoit un message clair et l'exploitation est alertée.
- **FR-047**: Le système MUST enregistrer le **mode de remise** retenu (QR, code, dépôt) et le nombre d'essais consommés.
- **FR-048**: La voie **dépôt** MUST exiger une photo sur place et la position, et n'être acceptée par le serveur que si le drapeau de dépôt de la commande est ouvert — une demande de dépôt sur une commande sans ce drapeau est refusée. La photo MUST **voyager avec la demande de remise** (et non référencer un dépôt préalable), faute de quoi la voie dépôt serait impossible hors ligne.
- **FR-048b**: La voie **dépôt** MUST rester utilisable **sans réseau** au même titre que les deux voies secrètes : la photo et la position attendent dans la file avec leur demande.
- **FR-049**: L'app MUST rappeler, sur l'écran de confirmation, le **montant exact à encaisser** et l'absence totale de paiement partiel.
- **FR-050**: Quand le client n'a pas l'appoint, l'app MUST rappeler l'absence totale de paiement partiel et renvoyer au chemin de secours (appel à l'agence) ; elle MUST NE PAS générer de lien de paiement sur place — cela relève de **PAY-03 (P1, tranche T3)**, hors périmètre de ce cycle.
- **FR-051**: Le système MUST tenir la voie de l'**ultime recours** (confirmation manuelle par l'exploitation, avec motif tracé) accessible sans que l'app ait à la porter elle-même ; l'app y renvoie clairement.
- **FR-052**: L'app MUST afficher le nom d'usage du client, son repère et l'heure d'arrivée sur l'écran de confirmation.
- **FR-053**: La confirmation MUST être atteignable en **un tap** depuis l'écran « arrivé chez le client ».
- **FR-054**: Le système MUST clore la commande et régler le paiement à la validation **serveur** de la remise — jamais à la validation locale seule.
- **FR-055**: Le système MUST rendre le blocage de code **levable par l'exploitation**, avec motif tracé.

### Preuves d'échec (CRS-05)

- **FR-056**: Le système MUST considérer les preuves d'un échec de livraison réunies **seulement si** les trois conditions le sont : au moins 2 appels via l'app espacés d'au moins 3 minutes, au moins 10 minutes de présence géolocalisée sur le lieu de livraison, et au moins 1 photo prise sur place.
- **FR-057**: Les seuils (nombre d'appels, espacement, durée de présence, nombre de photos, rayon de présence) MUST être des paramètres de zone.
- **FR-058**: L'app MUST afficher les trois preuves avec leur état individuel — faite (avec ses horodatages), en cours (avec son décompte), à faire — et un compteur global « N sur 3 ».
- **FR-059**: L'app MUST garder le bouton « déclarer livraison impossible » **inactif** tant que les trois preuves ne sont pas réunies.
- **FR-060**: Le serveur MUST **revérifier** les preuves à la déclaration et refuser toute déclaration dont les preuves ne sont pas réunies, indépendamment de ce que l'app affiche.
- **FR-061**: La présence géolocalisée MUST être mesurée par rapport à la position de livraison, dans le rayon paramétré, et ne progresser que lorsqu'une position fiable est disponible.
- **FR-062**: L'app MUST expliquer pourquoi une preuve ne progresse pas (position indisponible, appels trop rapprochés) plutôt que de laisser Yao attendre sans comprendre.
- **FR-063**: Le système MUST attacher les preuves (horodatages d'appels et leur issue, trace de présence, photo) au dossier d'échec, et les rendre lisibles par l'exploitation — par une surface d'exploitation distincte de celle du coursier.
- **FR-064**: Les preuves MUST pouvoir être réunies **hors ligne** et rejouées ensuite sans perte, photo comprise.
- **FR-065**: Le système MUST appliquer la rétention paramétrée de la zone aux photos de preuve, au même titre qu'aux photos de récupération.
- **FR-066**: L'app MUST proposer « rappeler le client » comme action secondaire permanente de l'écran de preuves.

### Caisse et indemnisations (CRS-06)

- **FR-067**: Le système MUST tenir, par coursier, le **montant avancé en cours** — somme des montants avancés aux arrêts collectés de ses courses non encore encaissées.
- **FR-068**: L'app MUST afficher ce montant en tête de la caisse, avec le nombre de courses concernées et la mention du remboursement à l'encaissement.
- **FR-069**: Le système MUST tenir l'**historique du jour** par course : montant avancé, montant remboursé, gain, état, heure.
- **FR-070**: Le système MUST enregistrer une écriture de caisse pour chaque mouvement (avance à un arrêt, remboursement à l'encaissement, indemnisation), **rattachée** à sa course et, le cas échéant, à son litige.
- **FR-071**: Le système MUST créer une **indemnisation « demandée »** à chaque indemnisation décidée par l'arbre des échecs, en consommant l'événement que le cycle 008 émet déjà sans consommateur.
- **FR-072**: L'exploitation MUST pouvoir **valider** une indemnisation ; la validation écrit le mouvement correspondant et change l'état visible par Yao. Ce cycle en pose le **contrat et l'écriture**, exercés par API ; l'écran de validation, le **solde du fonds d'incidents** et ses mouvements appartiennent à ADM-07.
- **FR-073**: Le système MUST rendre les écritures de caisse **immuables** : une correction s'écrit par une écriture inverse, jamais par suppression ou modification.
- **FR-074**: L'app MUST afficher les litiges en cours attachés au coursier avec leur état et le montant d'indemnisation demandé.
- **FR-075**: Le système MUST exposer à l'exploitation l'**exposition cash totale** en temps réel : par coursier et au total, dans la devise de la zone. Le **seuil d'alerte** sur cette exposition et son affichage appartiennent à ADM-07.
- **FR-076**: La caisse MUST être consultable **hors ligne** dans son dernier état connu, annoncé comme tel.
- **FR-077**: L'app MUST afficher un état vide explicite quand aucune course n'a eu lieu dans la journée, avec le solde à 0 et l'action « passer en ligne ».
- **FR-078**: Le système MUST signaler comme incident tout écart constaté entre les avances en cours d'un coursier et son plafond du jour.

### File d'actions hors-ligne (CRS-08)

- **FR-079**: Toute action de course **envoyée au serveur** — transition d'arrêt, déclaration d'indisponibilité, scan, photo, appel, relevé de présence, confirmation de remise, déclaration d'échec — MUST porter un identifiant unique généré par l'app et son horodatage local. La **coche d'un article** n'en fait pas partie : elle reste locale (aide-mémoire d'achat), le serveur ne connaissant que « arrêt collecté » et « ligne retirée ou remplacée ».
- **FR-080**: Le système MUST rendre le rejeu de toute action **idempotent** : rejouer une action déjà appliquée rend le même résultat sans rien réécrire ni ré-émettre.
- **FR-081**: La file MUST être **durable** : elle survit à la fermeture de l'app et au redémarrage de l'appareil.
- **FR-082**: La file MUST se rejouer **dans l'ordre de création** des actions, et se vider automatiquement au retour du réseau sans intervention de Yao.
- **FR-083**: L'app MUST afficher le nombre d'actions en attente de synchronisation et l'état de la file.
- **FR-084**: En cas de conflit au rejeu, le **serveur fait foi** : l'app adopte l'état serveur et affiche à Yao un message en langage clair expliquant ce qui a changé.
- **FR-085**: Le système MUST distinguer les échecs **réessayables** (réseau) des refus **définitifs** (métier) : les premiers restent en file avec leur compteur de tentatives, les seconds en sortent après réconciliation affichée.
- **FR-086**: Une action refusée définitivement MUST laisser une trace consultable — jamais une disparition silencieuse — et, si elle engageait de l'argent avancé, ouvrir le chemin de litige.
- **FR-087**: La file MUST transporter les photos (récupération, remplacement, dépôt, preuve) et indiquer ce qui reste à envoyer.
- **FR-088**: Le système MUST garantir qu'aucune action rejouée ne peut appliquer une transition à une course qui n'appartient plus à son auteur.
- **FR-089**: Le test obligatoire du module MUST être couvert : réseau coupé **entre le scan du dernier arrêt et la confirmation de livraison**, puis rétabli — exactement une collecte et exactement une remise enregistrées, dans le bon ordre, sans perte ni doublon.
- **FR-090**: La publication de position et l'acceptation d'offre MUST rester hors de la file (dérogation déjà déclarée au cycle 009 : une position périmée rejouée ment, une offre acceptée trop tard n'a plus d'objet).

### Disponibilité, plafond et gains (CRS-01)

- **FR-091**: L'app MUST afficher le **bandeau de gains du jour** : nombre de courses livrées et somme des parts coursier de ces courses, dans la devise de la zone.
- **FR-092**: Les gains MUST être bornés au **jour civil de la zone**, sans report.
- **FR-093**: L'app MUST afficher le **taux d'acceptation** tenu par le dispatch.
- **FR-094**: L'app MUST **ne pas afficher** de note tant qu'aucune note réelle n'existe (module d'avis non construit) — jamais une valeur inventée.
- **FR-095**: L'app MUST afficher le **reste disponible** du plafond du jour (plafond retenu moins avances en cours).
- **FR-096**: L'app MUST offrir un **raccourci vers la caisse** depuis le tableau de bord, et une navigation basse permanente entre tableau de bord, courses et caisse.
- **FR-097**: Le plafond d'une course **déjà acceptée** MUST rester celui en vigueur à l'acceptation, même si le jour civil change en cours de course.

### Offre — réveil et affinages (CRS-02)

- **FR-098**: Le système MUST faire sonner le téléphone de Yao sur un **canal dédié de haute importance**, avec sonnerie prolongée, à l'émission d'une offre.
- **FR-099**: La notification d'offre MUST ouvrir directement l'écran d'offre.
- **FR-100**: L'écran d'offre MUST afficher le **temps réellement restant**, jamais un compte à rebours remis à zéro à l'ouverture.
- **FR-101**: Aucune sonnerie MUST retentir quand Yao est hors ligne ou déjà en course.
- **FR-102**: L'app MUST se taire dès que l'offre est acceptée, refusée, expirée ou prise par un autre.
- **FR-103**: L'offre expirée ou déjà prise MUST afficher son message « sans pénalité » plutôt qu'un compte à rebours.
- **FR-104**: Aucune donnée personnelle du client MUST apparaître avant acceptation ; le pré-provisionnement complet (adresse, repère, note vocale, numéro) n'intervient qu'à l'assignation.

### Paramètres, périmètre et traçabilité

- **FR-105**: Ce cycle MUST ajouter à la configuration de zone au moins : nombre d'appels de preuve (défaut 2), espacement minimal des appels (défaut 3 min), durée de présence géolocalisée (défaut 10 min), rayon de présence, intervalle maximal entre deux relevés de présence, rétention des photos de preuve, période d'interrogation d'offre en arrière-plan.
- **FR-106**: Ce cycle MUST réutiliser les paramètres déjà seedés sans en créer de doublon — en particulier le **nombre d'essais du code de livraison** (`commande.essais_code_livraison`, seedé et lu en production depuis le cycle 008), la distance max de scan, la politique photo, le seuil de photo obligatoire et la grille de plafonds d'avance.
- **FR-107**: Ce cycle MUST déclarer dans la taxonomie tous ses nouveaux événements avant implémentation, dont : appel coursier journalisé, blocage du code de remise, preuves réunies, mouvement de caisse, indemnisation demandée/validée, conflit de réconciliation.
- **FR-108**: Ce cycle MUST NE PAS construire la paie fixe de la promotion de lancement (hors produit, aucune story).
- **FR-109**: Ce cycle MUST NE PAS construire les écrans de la console admin ; ses surfaces d'exploitation sont des endpoints exercés par API.
- **FR-110**: Ce cycle MUST NE PAS construire « signaler / bloquer » (CRS-07, P1) — ni la carte de K5-1a, ni la feuille de K5-1d.

### Fonctionnement continu, écran éteint (CRS-01, CRS-02, CRS-05)

- **FR-111**: Tant que Yao est **en ligne**, l'app MUST continuer de publier sa position à la période de la zone **même écran éteint et application en arrière-plan**, de sorte qu'il ne sorte du pool que s'il cesse réellement d'être joignable.
- **FR-112**: Le fonctionnement continu MUST s'arrêter dès que Yao se met **hors ligne** — plus aucune position publiée, plus aucune sonnerie.
- **FR-113**: L'app MUST pouvoir **recevoir une offre et sonner** alors qu'elle est en arrière-plan, sans dépendre de l'émission serveur qui appartient à NTF-01.
- **FR-114**: L'app MUST mesurer la **présence géolocalisée** de CRS-05 en arrière-plan : Yao n'a pas à garder un écran ouvert devant la porte du client pendant 10 minutes.
- **FR-115**: L'app MUST rendre son fonctionnement continu **visible et réversible** : une indication permanente pendant qu'il est actif, et un motif explicite quand il ne peut pas l'être (permission refusée, service arrêté par le système, économie d'énergie) — jamais un silence qui laisserait croire à Yao qu'il attend une course.

### Périmètre différé — dépôt et prépaiement

- **FR-116**: Le drapeau de **dépôt autorisé** MUST être porté par la commande, **fermé par défaut**, et n'être ouvrable que par l'exploitation avec un motif tracé ; l'app cliente pourra le poser dans son propre cycle sans changement de contrat.
- **FR-117**: Ce cycle MUST NE PAS modéliser le remboursement d'une avance sur **commande prépayée** (déféré à PAY-01/PAY-02, tranche T3) ; il MUST en revanche **signaler** l'avance correspondante comme **non soldée**, avec son motif, plutôt que de la faire disparaître d'un solde.

### Key Entities *(include if feature involves data)*

- **Course pré-provisionnée** : ce que l'app détient d'une course dès l'assignation pour fonctionner sans réseau — arrêts ordonnés, articles par vendeur, montants, politique photo, empreintes d'arrêt, **empreintes de remise**, repère du client (texte et note vocale), position de livraison, montant à encaisser.
- **Ligne de checklist** : un article d'un arrêt — libellé, quantité, prix verrouillé, préférence de substitution, état (à prendre / pris / indisponible), coche locale.
- **Appel journalisé** : intention d'appel émise par le coursier — direction, motif, horodatage ; jamais de numéro.
- **Preuve d'échec** : agrégat rattaché à une livraison — appels retenus et leur espacement, durée de présence mesurée, photo(s) ; état « réunies » ou non.
- **Confirmation de remise** : mode retenu (QR, code, dépôt), preuve présentée, essais consommés, validation locale ou serveur, horodatages local et serveur.
- **Blocage de code** : état d'une livraison dont les essais sont épuisés — horodatage, essais, alerte émise, levée éventuelle par l'exploitation avec motif.
- **Écriture de caisse** : mouvement immuable rattaché à un coursier — type (avance, remboursement, indemnisation, correction), montant, devise, course, arrêt éventuel, litige éventuel, horodatage.
- **Indemnisation** : montant dû à un coursier, rattaché à un litige et à une issue d'échec — état (demandée, validée, refusée), validation tracée.
- **Action en attente** : élément de la file locale — identifiant client, cible, contenu, photo éventuelle, horodatage local, tentatives, dernier motif d'échec.
- **Journée coursier** : agrégat du jour civil — courses livrées, gains, plafond déclaré et retenu, avances en cours, taux d'acceptation.
- **Drapeau de dépôt** : autorisation de dépôt portée par une commande — fermée par défaut, ouverture tracée (qui, quand, motif).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Yao mène une course de 3 vendeurs et 8 articles de bout en bout — 3 scans, 3 paiements, 1 livraison — sans jamais quitter la course active ni consulter une autre source d'information.
- **SC-002**: Sur l'écran de course active, le montant à payer au vendeur courant est exact au franc près dans 100 % des cas, y compris après une ou plusieurs indisponibilités d'articles.
- **SC-003**: Une confirmation de livraison réussit **sans aucune connexion réseau** par les deux voies secrètes (QR et code), et l'écran passe à « course terminée » en moins de 2 secondes après la présentation de la preuve.
- **SC-004**: Après une coupure réseau couvrant le dernier scan et la confirmation de livraison, la réconciliation enregistre **exactement une** collecte et **exactement une** remise, dans le bon ordre, en moins de 5 secondes après le retour du réseau — vérifié sur 20 exécutions consécutives sans un seul doublon ni une seule perte.
- **SC-005**: Trois codes faux bloquent la saisie dans 100 % des cas, et l'alerte d'exploitation correspondante est disponible au plus tard 5 secondes après le retour du réseau.
- **SC-006**: Aucune preuve de remise validée localement n'est acceptée sans revalidation serveur : 100 % des preuves rejouées sont revérifiées, et un code faux rejoué ne clôt jamais une livraison.
- **SC-007**: Le bouton « déclarer livraison impossible » ne s'active jamais avant que les trois preuves ne soient réunies — 0 activation prématurée sur l'ensemble des combinaisons testées (chaque preuve manquante, chaque paire manquante).
- **SC-008**: Une déclaration d'échec dont les preuves ne sont pas réunies est refusée dans 100 % des cas, même émise hors de l'app.
- **SC-009**: Le montant « avancé en cours » de la caisse égale, à tout instant, la somme des montants avancés aux arrêts collectés non encore encaissés — vérifié après chaque transition d'une course cash de 3 arrêts.
- **SC-010**: L'exposition cash totale lue par l'exploitation égale la somme des avances en cours de tous les coursiers, avec un retard maximal de 5 secondes sur la dernière collecte.
- **SC-011**: Une indemnisation décidée par l'arbre des échecs apparaît dans la caisse du coursier concerné en moins de 10 secondes, et son passage à « validée » est visible par lui sans qu'il ait à redémarrer l'app.
- **SC-012**: La note vocale de repère du client se joue **sans réseau** dans 100 % des courses assignées depuis plus de 30 secondes.
- **SC-013**: Le bandeau de gains du jour égale la somme des parts coursier des courses livrées du jour civil de la zone, au franc près, et repart de zéro au changement de jour.
- **SC-014**: Une offre émise à un coursier en ligne, téléphone verrouillé, déclenche la sonnerie dédiée dans 100 % des cas, et l'écran d'offre ouvert affiche un compte à rebours qui correspond au temps réellement restant à ±1 seconde.
- **SC-015**: Aucun secret (code de livraison, jeton, code vendeur, numéro de téléphone) n'apparaît dans une réponse d'interface, un événement ou un journal — vérifié par un contrôle automatisé sur l'ensemble des charges utiles émises par ce cycle.
- **SC-016**: Une action rejouée par un coursier qui n'est plus assigné à la course est refusée dans 100 % des cas, et sa trace reste consultable.
- **SC-017**: L'app coursier reste utilisable de bout en bout sur un appareil sans connexion pendant 30 minutes consécutives : toutes les actions sont enfilées, aucune n'est perdue, et l'écran ne présente jamais un état qu'il n'a pas vérifié.
- **SC-018**: Un coursier en ligne, téléphone verrouillé et app en arrière-plan pendant 30 minutes, **ne sort jamais du pool** : ses positions sont publiées sans interruption à la période de la zone, et il reste offreable pendant toute la durée.
- **SC-019**: Les 10 minutes de présence géolocalisée de CRS-05 se mesurent **sans que l'écran reste allumé** : la preuve progresse à l'identique, écran éteint ou écran ouvert.

## Assumptions

- **Paie fixe hors produit** : le bandeau de gains montre la somme des parts coursier des courses livrées. L'état 1c de K1 (« paie fixe ») n'est pas construit ; si la promotion doit être visible dans l'app, cela relève d'une décision produit à porter d'abord dans les documents de cadrage.
- **Livraison offerte et gains** : pendant la promotion « livraison offerte », la part coursier reste calculée par le devis figé (c'est elle que l'écran d'offre affiche déjà) ; le bandeau de gains la reprend telle quelle.
- **Itinéraire** : l'action « itinéraire » ouvre l'application de navigation présente sur le téléphone vers la position visée. Aucune carte n'est intégrée à l'app coursier dans ce cycle — aucune n'existe aujourd'hui dans le monorepo, et l'itinéraire optimisé est déjà calculé côté serveur.
- **Note du coursier** : absente (module d'avis non construit) ; le taux d'acceptation, lui, est réellement tenu par le dispatch et peut être affiché.
- **Dépôt d'espèces à l'agence** : le « ce qu'il reste à déposer » de K1 est calculable (frais encaissés en cash), mais l'enregistrement d'un versement à l'agence n'est couvert par aucune story CRS ; il relève de la caisse admin (ADM-07). Ce cycle affiche le montant dû, il ne construit pas l'opération de versement.
- **Commandes prépayées** : PAY-02 (prépaiement) et PAY-01 (chaîne cash finalisée) sont en tranche T3 ; ce cycle ne construit pas le remboursement d'une avance sur commande prépayée et laisse cette avance visible comme non soldée. C'est une **limite assumée**, à lever par le cycle PAY.
- **Fonctionnement continu** : l'app coursier reste active en arrière-plan tant que Yao est en ligne. Cela suppose une permission de localisation et une indication permanente à l'écran ; le mécanisme exact relève du plan, l'exigence est que Yao reste dans le pool et soit réveillé par une offre sans garder l'app ouverte.
- **Confirmation manuelle admin** (ultime recours) : déjà prévue côté admin (ADM-02) et exercée par API ; ce cycle ne la reconstruit pas, il s'assure que l'app y renvoie clairement.
- **Litiges** : le module d'avis et litiges (AVI-04) n'est pas construit ; ce cycle rattache ses indemnisations à un identifiant de litige et affiche son état, sans construire le dossier lui-même.
- **Un appareil à la fois** : la file est locale à l'appareil ; un coursier qui change de téléphone en cours de course perd ses actions non synchronisées — le serveur reste la vérité, et l'app le lui dit.
- **Photos** : soumises à la rétention paramétrée de la zone, comme les photos de récupération déjà livrées.
- **Le serveur reste la seule vérité durable** ; l'app ne conserve localement que ce qui lui permet de fonctionner sans réseau, et l'annonce toujours comme un état connu, jamais comme un état courant.
