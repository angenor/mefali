# Feature Specification: Cycle de vie complet d'une commande multi-vendeurs

**Feature Branch**: `008-commandes-cycle-de-vie`

**Created**: 2026-07-25

**Status**: Draft

**Input**: User description: "Lis docs/user-stories-v2.md, module CMD — Commandes, et docs/cadrage-v5.md sections §7.2, §7.5 et §8. Fonctionnalité : cycle de vie complet d'une commande multi-vendeurs. Périmètre : CMD-01, CMD-02, CMD-03, CMD-04, CMD-05, CMD-06, CMD-07, CMD-08, CMD-10 — critères tels quels. Le modèle structurel est impératif : table commande = tronc commun SANS champ logistique (identité, prestataire(s), lieu de prestation, montants, paiement, états de très haut niveau) ; la livraison est un composant OPTIONNEL (0..n) rattaché — les verticaux du MVP en créent exactement une ; livraison → segments (MVP : 1) → arrêts (1..n collectes + 1 remise), chaque arrêt portant prestataire, scan, photo éventuelle, montant avancé, statut, dans l'ordre optimisé par TRF ; détails de vertical dans resto_details derrière le trait ServiceWorkflow ; machine à états gardée serveur avec la boucle de collecte par arrêt ; panier multi-vendeurs pour les catégories courses, articles regroupés par vendeur, drapeau mixable (restauration mono-vendeur, proposition de scinder en 2 commandes) ; livraison offerte vendeur = mono-vendeur uniquement ; adresse = pin GPS + « ma position actuelle » + repère TEXTE OU NOTE VOCALE ≤ 30 s (MinIO) + téléphone vérifié ; code de livraison + jeton QR de réception générés et remis au client DÈS LA CRÉATION (cache local — base du hors-ligne de CRS-04) ; substitutions selon la préférence par article, chez le même vendeur, total toujours payé en une fois ; l'arbre complet des échecs du cadrage §7.5 est couvert par des tests d'intégration, cas par cas. Hors périmètre : CMD-09 (aller-retour pressing, P2 — le modèle segments n ≥ 2 suffit) ; réaffectation d'un article vers un autre vendeur (phase 2). Personas : Awa, Yao, Tantie Affoué, Kofi. Points d'attention : dépendances = zones, comptes, prestataires, tarification (devis figé), QR (scan par arrêt) ; maquettes : docs/design/png/C3, C4."

## Clarifications

### Session 2026-07-25

- Q: Ce cycle construit-il les écrans clients Flutter des maquettes C3 (panier) et C4 (suivi), ou seulement le domaine et l'API ? → A: **Domaine + API + écrans clients C3/C4 dans l'app Flutter cliente**. Les critères CMD-01/02/03/05 sont des critères d'**expérience** (regroupement par vendeur, préférence par article, appoint exact, repère vocal, QR et code hors ligne, âge de la position) qui ne sont pas vérifiables sans écran, et la démo de fin de tranche T1 (`docs/user-stories-v2.md` §0.5) exige un parcours client de bout en bout. Les apps **coursier** (CRS) et **admin** (ADM) restent hors périmètre : leurs surfaces sont exercées par API et par des doubles dans les tests. Reflété en FR-068, US1, US2, US6 et Assumptions.
- Q: Après une substitution ou un retrait d'article en course, le devis de livraison figé (frais de déplacement + grille d'effort) est-il recalculé ? → A: **Non — le devis de livraison reste figé à la création** ; seul le **montant des articles** est révisé, et le total dû suit. La grille d'effort promise au coursier à l'acceptation reste due même si un retrait fait descendre le panier d'un palier d'articles (« le coursier ne perd jamais », cadrage §7.5), et les frais annoncés à la cliente avant confirmation ne montent jamais en cours de course (prix verrouillés, constitution III). Reflété en FR-050, US7 et SC-007.
- Q: Où s'arrête CMD-08 (échec de livraison) et où commencent les litiges (AVI-04) et la caisse coursier (CRS-06), tous deux en tranche T2 ? → A: **CMD-08 décide l'issue, la journalise et pose la sanction client** ; il **émet** les événements d'ouverture de litige et d'indemnisation due, mais **ne construit ni l'enregistrement de litige (AVI-04) ni l'écriture de caisse (CRS-06)** — consommateurs des cycles de tranche T2. Les preuves d'échec (CRS-05) sont une **précondition vérifiée**, fournie par un double dans les tests puisque l'app coursier n'est pas construite. Reflété en FR-056, FR-062 et US9.

**Décisions confirmées par les sources (sans question, sections citées)** — ambiguïtés candidates tranchées par les docs, les maquettes ou le code déjà livré plutôt que par supposition :

- **La remise au client est un arrêt** du segment — le dernier, de type remise, **sans prestataire** — et non un champ du segment : cadrage §7.2 (« un segment = arrêts de collecte (1..n vendeurs) + une remise client ») et périmètre imposé (« arrêts (1..n collectes + 1 remise) »). Le socle du cycle 006 ne modélisait que les arrêts de collecte. Reflété en FR-003.
- **Le plafond cash de zone se compare au TOTAL de la commande** (articles + frais), pas au seul montant des articles : maquette **C3-3b** (« Total de la commande 28 400 FCFA » face à « Le cash est limité à … »). Le **montant des articles tous arrêts confondus** reste, lui, la base de la capacité d'avance du coursier — plafond distinct porté par DSP-02, non construit ici. Reflété en FR-024.
- **Sans réponse du client à la validation de substitution (60 s) → appel, puis retrait si injoignable** : la maquette **C4-4c** (« Sans réponse dans 60 s, on appelle. Injoignable : article retiré, rien à payer ») précise CMD-06 (« sans réponse → retrait ») sans le contredire. Reflété en FR-046.
- **La scission proposée au-delà du plafond d'éclatement est déjà décidée par la tarification** : le devis figé du cycle 007 porte le drapeau `proposer_scission`, documenté « CMD PROPOSERA de scinder — TRF ne scinde pas ». Ce cycle **consomme** ce drapeau et réutilise le mécanisme de proposition de la règle de mixage. Reflété en FR-015.
- **La re-livraison après consigne (vendeur fermé, §7.5) est une NOUVELLE commande liée à la première**, avec son propre devis, et non un second segment : CMD-09 (aller-retour à 2 segments planifiés) est **P2 et explicitement hors périmètre**, et §7.5 qualifie la re-livraison de « facturée » — donc porteuse de son propre devis. Reflété en FR-060.
- **Le caractère périssable est un paramètre de catégorie** (hérité par zone), pas un champ d'article : cadrage §4 (« chaque catégorie est une configuration ») et §7.5 (« Denrée périssable / plat préparé » = la restauration). Reflété en FR-059.
- **Le panier hors ligne est un brouillon local, jamais une commande** : maquette **C3-3c** (« Le panier reste modifiable, total estimé conservé, action unique en file d'attente », « Prix confirmés à l'envoi — les stocks seront vérifiés au retour du réseau »). Le code de livraison et le QR n'existent donc qu'après création en ligne. Reflété en FR-016.
- **L'adresse de commande réutilise le carnet d'adresses du cycle 003** : `comptes.adresse` porte déjà pin GPS, repère texte, repère vocal (objet S3 + durée) et la fonction `marquer_adresse_utilisee`, documentée « que le cycle CMD appellera ». Une adresse dont le repère vocal a été purgé par la rétention redemande un repère à la commande. Reflété en FR-017 à FR-021.

## User Scenarios & Testing *(mandatory)*

Personas de ce cycle : **Awa (cliente)** — employée d'agence, Android milieu de gamme, commande au déjeuner et fait ses courses au marché chez plusieurs étals ; **Yao (coursier)** — avance le cash sur ses fonds, réseau intermittent, collecte arrêt par arrêt ; **Tantie Affoué (vendeuse)** — maquis, pas d'app, veut son argent immédiatement, peu lettrée — elle est aussi cliente, et c'est pour elle que le repère vocal existe ; **Kofi (vendeur équipé)** — boutique, smartphone, promotions et livraison offerte.

Priorités produit : **CMD-01 à CMD-08 et CMD-10 sont toutes P0** (`docs/user-stories-v2.md` §0.6 : 8 P0 + 1 P2). Les priorités P1→P3 attachées aux stories ci-dessous sont l'**ordre de livraison interne** au cycle (chaîne de dépendances), pas une hiérarchie produit.

### Ce que ce cycle NE construit PAS parce que c'est déjà là

- **Zones & configuration héritée (cycle 002)** : le drapeau **`mixable` est déjà un paramètre de zone par catégorie** (`categorie.<slug>.mixable`, documenté dans la migration des zones comme « pas une colonne : un paramètre de zone hérité — une seule source de vérité »), au même titre que les plafonds cash, la politique photo, la devise et les rétentions. Ce cycle **lit et seede** ces paramètres, il ne réinvente ni stockage ni héritage.
- **Comptes & identité (cycle 003)** : téléphone vérifié par OTP, rôles, sessions ; le **carnet d'adresses avec pin GPS et repère texte/vocal** existe (`comptes.adresse`, objet audio dans le stockage S3, durée bornée par un paramètre de zone, purge de rétention, `marquer_adresse_utilisee` prévue pour ce cycle) ; les **drapeaux de restriction `prepaiement_impose` et `bloque`** sont déjà en base (CPT-06).
- **Prestataires & catalogue (cycle 005)** : fiche vendeur, site et position GPS, horaires et statut boutique, catalogue avec prix, prix barré et disponibilité, verrouillage de prix. Ce cycle **consomme** ces prix, il ne les redéfinit pas.
- **QR & traçabilité (cycle 006)** : le **socle logistique minimal** est déjà posé — ancre `commande`, `livraison`, `segment`, `arret` (prestataire, ordre, position du site, montant avancé, statut, journal de collecte, idempotence) — ainsi que le **scan par arrêt**, le **code de secours vendeur**, la politique photo et la **bascule en livraison quand toutes les collectes sont résolues**. Ce cycle **étend** ce socle par de nouvelles migrations ; il ne le réécrit pas.
- **Tarification (cycle 007)** : le **devis figé** {prix client, part coursier, marge, devise} avec ses composantes détaillées (base, km, suppléments, effort par paliers/attente/arrêts, arrondi, retenue vendeur), l'**ordre optimisé des arrêts**, le drapeau **`proposer_scission`**, le dégradé de routage et les drapeaux de zone. Ce cycle **appelle** l'évaluation et **verrouille** son résultat.
- **Journal outbox et taxonomie d'événements (cycle 001)** : mécanique d'écriture transactionnelle et registre. Ce cycle y **déclare** ses événements manquants avant implémentation.

### Ce que ce cycle construit

Le **tronc de commande** et son composant de livraison : identité, prestataires, lieu de prestation, montants, paiement et états de très haut niveau côté tronc ; toute la logistique côté livraison → segments → arrêts. Le **panier multi-vendeurs** avec regroupement par vendeur, règle de mixage et proposition de scission. L'**adresse de commande** (pin, position actuelle, repère texte ou vocal, téléphone vérifié). La **création** avec prix verrouillés, devis figé, choix du paiement et remise immédiate au client du **code de livraison et du jeton QR de réception**. La **machine à états gardée serveur** avec la boucle de collecte par arrêt. La **file d'attente sans coursier**. Le **suivi client temps réel**, hors ligne compris. Les **substitutions en course**, les **annulations** et l'**arbre complet des échecs** du cadrage §7.5.

### Surface d'interface, frontières et modules simulés

Côté **client**, les écrans du panier (`docs/design/png/C3`) et du suivi (`docs/design/png/C4`) sont construits dans l'app Flutter cliente : ce sont eux qui portent les critères d'acceptation d'expérience — regroupement par vendeur, préférence de substitution par article, appoint exact, repère vocal, QR et code hors ligne, âge de la position.

Trois modules dont ce cycle dépend **ne sont pas construits** et sont exercés par des doubles, exactement comme le cycle 006 a simulé la course active et le cycle 007 les courses tarifées :

| Module non construit | Ce que ce cycle pose | Ce qu'il simule dans les tests |
|---|---|---|
| **Dispatch (DSP)** | l'état de commande prête à dispatcher, l'événement correspondant, la file d'attente sans coursier et sa reprise | l'assignation d'un coursier et la réassignation |
| **Paiements (PAY)** | l'état d'attente de paiement, la bascule cash → prépaiement, la trace « qui détient quoi » par arrêt | la confirmation de paiement mobile money et les remboursements |
| **Coursier (CRS) et Avis/litiges (AVI)** | les transitions par arrêt exposées en API, la précondition de preuves d'échec, les événements d'ouverture de litige et d'indemnisation due | l'app coursier, la constitution des preuves, la caisse et la modération |

L'**app coursier n'est pas construite** : les transitions de collecte sont exercées par API avec les identifiants d'idempotence prévus, ce qui laisse le cycle CRS les brancher sans changement de contrat.

---

### User Story 1 - Composer un panier chez plusieurs vendeurs (CMD-01, Priority: P1 — produit : P0)

Awa fait ses courses au marché : des tomates chez Étal Adjoua, du poisson chez Étal Konan, du riz chez Boutique Yao. Le panier accepte les articles de **plusieurs vendeurs agréés** dès lors que la catégorie est déclarée **mixable**, les affiche **regroupés par vendeur** avec un sous-total par vendeur, et présente le **détail des frais** avant confirmation : articles, livraison (déplacement + suppléments d'arrêt) et effort de préparation. Chaque article porte sa **préférence de substitution** — remplacer, m'appeler, retirer — avec « m'appeler » par défaut. La **restauration n'est pas mixable** : elle reste mono-vendeur et ne se mélange pas aux courses ; si Awa ajoute un plat chaud à ses courses, l'app **propose de scinder en 2 commandes**, prévisualise les deux et annonce explicitement les **deux frais de déplacement** — elle ne scinde jamais d'office. Même proposition quand le **détour** de l'itinéraire dépasse le plafond d'éclatement de la zone.

**Why this priority**: Sans panier, il n'y a rien à commander. C'est la story qui rend le multi-vendeurs réel — le cas d'usage du marché, où une vendeuse a rarement tout le panier — et la seule qui puisse être livrée sans aucune des autres.

**Independent Test**: Composer un panier de 12 articles chez 3 vendeurs d'une catégorie mixable et vérifier le regroupement par vendeur, les sous-totaux, le détail des frais et la préférence par défaut « m'appeler » ; ajouter un plat de restauration et vérifier que la commande telle quelle est impossible et que la scission en 2 est proposée, prévisualisée et chiffrée ; forcer un détour au-delà du plafond d'éclatement et vérifier la même proposition — sans qu'aucune création de commande ne soit livrée.

**Acceptance Scenarios**:

1. **Given** une catégorie déclarée mixable pour la zone, **When** Awa ajoute des articles de trois vendeurs agréés, **Then** le panier les accepte, les regroupe par vendeur avec un sous-total par vendeur, et affiche le total articles + frais (déplacement, suppléments d'arrêt, effort) avant confirmation.
2. **Given** un panier de courses, **When** Awa y ajoute un plat d'un vendeur de restauration (catégorie non mixable), **Then** la commande unique est refusée et l'app propose de **scinder en 2 commandes**, prévisualise leur contenu et indique que deux livraisons entraînent deux frais de déplacement.
3. **Given** la proposition de scission affichée, **When** Awa ne l'accepte pas, **Then** rien n'est scindé d'office et le panier reste modifiable — la décision lui appartient.
4. **Given** un panier multi-vendeurs dont l'itinéraire présente un détour au-delà du plafond d'éclatement de la zone, **When** le devis est calculé, **Then** l'app propose de scinder, avec le même mécanisme que pour la règle de mixage.
5. **Given** un article au panier, **When** Awa n'exprime aucune préférence de substitution, **Then** la préférence retenue est **« m'appeler »**.
6. **Given** un vendeur qui offre la livraison, **When** le panier est **mono-vendeur**, **Then** les frais client tombent selon sa règle ; **Given** un panier **multi-vendeurs**, **Then** les frais s'appliquent normalement — aucune répartition de gratuité entre vendeurs.
7. **Given** Awa hors connexion, **When** elle compose son panier, **Then** le panier est conservé sur le téléphone avec un **total estimé**, aucune commande n'est créée, et une **action unique** part en file d'attente pour la reconnexion — prix et stocks étant confirmés à l'envoi.

---

### User Story 2 - Donner une adresse qu'un coursier peut trouver (CMD-02, Priority: P1 — produit : P0)

Awa indique où livrer : un **pin GPS**, posé à la main ou par le bouton **« Utiliser ma position actuelle »**, et un **repère obligatoire** — soit un **texte d'au moins 10 caractères**, soit une **note vocale d'au plus 30 secondes** que Yao pourra écouter en course. Son **téléphone vérifié** est requis. Une adresse déjà enregistrée se réutilise en un tap, **repère vocal compris** ; si le repère vocal a été purgé par la rétention, l'app en redemande un. Tantie Affoué, peu lettrée, commande avec un repère uniquement vocal.

**Why this priority**: Sans adresse trouvable, la livraison échoue — c'est le premier poste d'échec dans une ville sans adressage formel. La story est autonome : le carnet d'adresses existe déjà, il s'agit de le rendre exploitable à la commande.

**Independent Test**: Créer une adresse avec pin GPS et repère **texte** de 10 caractères et vérifier qu'elle est acceptée ; recommencer avec un repère **uniquement vocal** de 30 secondes et vérifier l'acceptation, puis avec 31 secondes et vérifier le refus ; tenter une adresse sans aucun repère et vérifier le refus ; réutiliser une adresse enregistrée en un tap et vérifier que le repère vocal suit ; purger le repère vocal et vérifier qu'un repère est redemandé — sans qu'aucune commande ne soit créée.

**Acceptance Scenarios**:

1. **Given** l'écran d'adresse, **When** Awa appuie sur « Utiliser ma position actuelle », **Then** le pin GPS est renseigné et reste déplaçable à la main.
2. **Given** un pin posé, **When** le repère saisi est un texte d'au moins 10 caractères **ou** une note vocale d'au plus la durée maximale de la zone (30 s), **Then** l'adresse est acceptée ; **When** aucun repère n'est fourni, ou le texte est trop court, ou la note dépasse la durée maximale, **Then** l'adresse est refusée avec un message explicite.
3. **Given** une adresse portant une note vocale, **When** la commande est en course, **Then** la note est **jouable** par le coursier.
4. **Given** un compte sans téléphone vérifié, **When** il tente de fournir une adresse de livraison, **Then** l'opération est refusée tant que la vérification n'est pas faite.
5. **Given** une adresse enregistrée dont le repère vocal a été purgé par la rétention, **When** Awa la réutilise, **Then** l'app **redemande un repère** avant de laisser confirmer.
6. **Given** une adresse réutilisée pour une commande, **When** la commande est créée, **Then** son **usage est marqué** (la rétention repart de cette date).

---

### User Story 3 - Créer la commande : prix verrouillés, devis figé, code et QR remis tout de suite (CMD-03 + structure de CMD-04, Priority: P1 — produit : P0)

Awa confirme. Le système crée une **commande** dont le **tronc** ne porte **aucun champ logistique** — identité, prestataires, lieu de prestation, montants, paiement, état de très haut niveau — et lui rattache **une livraison** (composant optionnel, 0..n), elle-même faite d'**un segment** contenant les **arrêts** : une collecte par vendeur, dans l'**ordre optimisé** fourni par la tarification, puis la **remise** au client. Les **prix des articles sont verrouillés** et le **devis est figé**. Le paiement suit le plafond : **cash** si le total est sous le plafond de la zone et si le compte n'est pas sous prépaiement imposé — avec le **montant exact** et « préparez l'appoint » ; sinon **prépaiement mobile money** obligatoire avant dispatch, le cash étant grisé avec sa raison affichée. Dès la confirmation, le **code de livraison à 4 chiffres et le jeton QR de réception** sont générés et remis au client, mis en cache sur son téléphone.

**Why this priority**: C'est le cœur : la commande naît ici, avec la structure imposée par la constitution et les invariants d'argent. Toutes les stories suivantes en dépendent. Le code et le QR remis à la création sont la base du hors-ligne côté client.

**Independent Test**: Confirmer un panier de 3 vendeurs et vérifier qu'une commande est créée avec un tronc sans champ logistique, une livraison, un segment et 4 arrêts (3 collectes dans l'ordre optimisé + 1 remise), les prix verrouillés, le devis figé et un code + QR remis immédiatement ; passer le total au-dessus du plafond cash et vérifier la bascule vers le prépaiement ; rejouer la même création avec la même clé et vérifier qu'une seule commande existe.

**Acceptance Scenarios**:

1. **Given** un panier validé de 3 vendeurs, **When** Awa confirme, **Then** une commande est créée : tronc **sans aucun champ logistique**, **une** livraison rattachée, **un** segment, et des arrêts dans l'**ordre optimisé** — 3 collectes portant chacune prestataire, montant à avancer et statut « à collecter », plus **1 arrêt de remise** au client.
2. **Given** la création, **When** on inspecte les montants, **Then** les **prix des articles sont verrouillés** au prix courant du catalogue à cet instant et le **devis est figé** (frais, part coursier, marge, devise), en entiers d'unités mineures avec le code ISO 4217 de la zone.
3. **Given** un total inférieur au plafond cash de la zone et un compte sans prépaiement imposé, **When** Awa choisit le paiement, **Then** le **cash** est disponible, avec le **montant exact** et la mention « préparez l'appoint ».
4. **Given** un total supérieur au plafond cash — ou un compte sous **prépaiement imposé**, ou une commande de restauration d'un client sans historique au-dessus du plafond réduit —, **When** Awa choisit le paiement, **Then** le cash est **indisponible** avec sa raison affichée et le **prépaiement mobile money** est requis avant tout dispatch.
5. **Given** la commande confirmée, **When** Awa consulte son suivi, **Then** le **code de livraison à 4 chiffres** et le **jeton QR de réception** sont déjà présents et conservés sur le téléphone.
6. **Given** un compte portant le drapeau **bloqué**, **When** il tente de commander, **Then** la création est refusée.
7. **Given** un vendeur fermé ou hors horaires, ou un article devenu indisponible, **When** Awa confirme, **Then** la création est refusée avec le motif, avant tout verrouillage de prix.
8. **Given** une confirmation renvoyée deux fois avec la même clé (réseau instable), **When** le serveur la traite, **Then** **une seule** commande existe et la seconde réponse est identique à la première.

---

### User Story 4 - Faire avancer la commande sous garde serveur, arrêt par arrêt (CMD-04, Priority: P1 — produit : P0)

La commande suit la machine à états du cadrage §7.2 : **nouvelle → assignée → en collecte**, puis, **pour chaque arrêt dans l'ordre optimisé**, la boucle **en route vers l'arrêt → arrivé → collecté** (scan QR, photo si la politique l'exige) ; quand **toutes les collectes sont résolues**, la livraison passe **en livraison**, puis **livrée**. Les branches **annulée**, **échec de livraison**, **en attente de coursier** et **en attente de paiement** complètent le graphe. Toute transition est **gardée côté serveur** : une transition illégale est refusée, l'état ne bouge pas. Chaque transition est **horodatée par le serveur** et écrit un **événement outbox dans la même transaction**. Les états de **très haut niveau** vivent sur le tronc ; les états **logistiques** vivent sur la livraison, le segment et l'arrêt. Les spécificités du vertical restauration vivent dans une **table de détails dédiée** derrière le trait de workflow de service — jamais dans le tronc.

**Why this priority**: C'est l'ossature que le dispatch, le coursier, les paiements et les litiges viendront brancher. Sans garde serveur, tout le reste est décoratif ; sans séparation tronc/livraison, les verticaux suivants imposeraient une refonte.

**Independent Test**: Dérouler une commande à 3 collectes de bout en bout par API et vérifier chaque transition, la bascule automatique en livraison une fois les 3 collectes résolues, et l'événement outbox écrit à chaque pas ; tenter une transition hors séquence (par exemple livrer avant la dernière collecte) et vérifier le refus sans changement d'état ; rejouer une transition avec le même identifiant d'action et vérifier l'absence de doublon.

**Acceptance Scenarios**:

1. **Given** une commande à 3 collectes, **When** elle est assignée puis déroulée arrêt par arrêt, **Then** chaque arrêt suit **en route → arrivé → collecté**, dans l'**ordre figé à la création**, et le progrès est lisible (« 2 collectes sur 3 »).
2. **Given** deux collectes faites et une troisième en cours, **When** on tente de passer la livraison en « livrée », **Then** la transition est **refusée** et l'état reste inchangé.
3. **Given** la dernière collecte résolue — **collectée** ou **indisponible** —, **When** le serveur enregistre la transition, **Then** la livraison bascule automatiquement **en livraison**.
4. **Given** n'importe quelle transition acceptée, **When** elle est enregistrée, **Then** un **événement outbox** est écrit dans la **même transaction**, avec l'horodatage **serveur**.
5. **Given** une action coursier rejouée avec le même identifiant d'action (file hors ligne), **When** le serveur la reçoit deux fois, **Then** l'effet est appliqué **une seule fois** et la seconde réponse est identique.
6. **Given** le modèle de données, **When** on inspecte le tronc de commande, **Then** il ne contient **aucun champ logistique** ni **aucun champ spécifique à un vertical** ; les détails de restauration vivent dans leur table dédiée derrière le trait de workflow de service.
7. **Given** un vertical qui ne livre pas (aucune livraison rattachée), **When** on crée une commande, **Then** le modèle l'accepte — la livraison est un composant **optionnel**.

---

### User Story 5 - Attendre un coursier sans rester dans le noir (CMD-10, Priority: P2 — produit : P0)

Aucun coursier n'est disponible. La commande passe **en attente de coursier** au lieu d'échouer : Awa voit qu'on cherche, avec un **délai estimé** et la possibilité d'**annuler sans frais**. Les commandes en attente sont reprises **automatiquement** dès qu'un coursier redevient éligible, dans l'ordre **FIFO par âge**.

**Why this priority**: Une commande perdue faute de coursier est une commande perdue tout court. La story est courte, autonome et directement mesurable ; elle se livre après la machine à états dont elle est une branche.

**Independent Test**: Créer une commande alors qu'aucun coursier n'est éligible et vérifier l'état d'attente, le message avec délai estimé et l'annulation sans frais ; créer trois commandes en attente, rendre un coursier disponible et vérifier que la plus ancienne est reprise en premier, automatiquement.

**Acceptance Scenarios**:

1. **Given** aucun coursier éligible, **When** la commande est créée (et payée si le prépaiement était requis), **Then** elle passe **en attente de coursier** et Awa en est informée avec un **délai estimé**.
2. **Given** une commande en attente, **When** Awa l'annule, **Then** l'annulation est **sans frais**.
3. **Given** trois commandes en attente d'âges différents, **When** un coursier redevient éligible, **Then** la **plus ancienne** est reprise en premier, **automatiquement**, sans intervention.
4. **Given** une commande en attente depuis le seuil d'escalade de la zone, **When** le seuil est franchi, **Then** l'événement d'escalade est émis (consommé par le dispatch, non construit ici) et Awa est notifiée avec la possibilité d'annuler sans frais.

---

### User Story 6 - Suivre sa commande, même sans réseau (CMD-05, Priority: P2 — produit : P0)

Awa suit sa commande en **langage clair** : commande reçue, collecte en cours (avec « 2 collectes sur 3 » et le nom du vendeur en cours), en route vers vous, livrée. La **position du coursier** est rafraîchie au moins toutes les 30 secondes dès la première collecte et se lit **le long de l'itinéraire multi-arrêts**, avec l'**âge** de la dernière position. Elle peut **appeler le coursier** depuis l'app, l'intention étant journalisée. Son **code et son QR de réception** sont accessibles **à tout moment**, y compris **hors ligne** : hors connexion, l'écran affiche le **dernier état connu**, l'âge de la position, et met le QR et le code en avant.

**Why this priority**: C'est l'écran qui absorbe l'anxiété d'attente et supprime le besoin d'appeler le support ; et c'est lui qui garantit qu'Awa n'a **jamais besoin d'internet** au moment de la livraison. Il dépend des états (story 4) et de la création (story 3).

**Independent Test**: Suivre une commande de bout en bout et vérifier le stepper en langage clair, la progression par arrêt, une position de moins de 30 secondes avec son âge, et l'appel journalisé ; couper le réseau et vérifier que le QR et le code restent affichés, que le dernier état connu est présenté comme tel et que l'âge de la position est visible.

**Acceptance Scenarios**:

1. **Given** une commande à 3 collectes dont 2 sont faites, **When** Awa ouvre le suivi, **Then** elle lit **« 2 collectes sur 3 »**, l'étape en cours en langage clair et le vendeur concerné.
2. **Given** la première collecte effectuée, **When** Awa consulte la carte, **Then** la position du coursier date de **moins de 30 secondes** et se situe **sur l'itinéraire multi-arrêts**, l'âge de la position étant affiché.
3. **Given** le suivi ouvert, **When** Awa appuie sur « Appeler », **Then** l'appel part et l'**intention est journalisée**.
4. **Given** Awa **hors ligne**, **When** elle ouvre le suivi, **Then** le **QR et le code** restent accessibles et mis en avant, le **dernier état connu** est présenté comme tel, et l'**âge** de la position est affiché.
5. **Given** une commande en attente de coursier, **When** Awa ouvre le suivi, **Then** elle voit l'état de recherche, le délai estimé et le bouton d'annulation sans frais.

---

### User Story 7 - Gérer un article manquant sans casser la commande (CMD-06, Priority: P2 — produit : P0)

Yao arrive chez Étal Adjoua : les tomates fraîches sont épuisées. Le système applique la **préférence exprimée par Awa sur cet article** : **« retirer »** → l'article sort et le montant des articles est révisé ; **« m'appeler »** → l'appel est passé depuis l'app, journalisé, et la résolution est saisie ; **« remplacer »** → Yao propose un équivalent **chez le même vendeur** avec **photo et prix**, Awa valide par notification dans les **60 secondes** ; **sans réponse à 60 secondes, on l'appelle**, et si elle est injoignable, l'article est **retiré** (rien à payer pour lui). L'**écart de prix** est plafonné à ±20 % (paramétrable). Le **devis de livraison reste figé** : seuls les articles bougent. Le **total reste payé en une fois** — jamais de paiement partiel.

**Why this priority**: Les ruptures sont quotidiennes au marché et en boutique ; sans cette story, une rupture annule la commande. Elle dépend de la machine à états et de la boucle de collecte.

**Independent Test**: Provoquer une rupture sur un article de chaque préférence et vérifier les trois comportements, la validation à 60 secondes, l'appel puis le retrait en cas d'injoignabilité, le refus d'un remplacement à +25 % et l'acceptation à +20 %, l'impossibilité de proposer un article d'un autre vendeur, la révision du **seul** montant des articles (frais et effort inchangés) et l'absence totale de chemin de paiement partiel.

**Acceptance Scenarios**:

1. **Given** un article dont la préférence est **« retirer »**, **When** il est signalé indisponible, **Then** il sort de la commande, le montant des articles est révisé et Awa est notifiée.
2. **Given** un article dont la préférence est **« m'appeler »**, **When** il est signalé indisponible, **Then** l'appel est passé depuis l'app et **journalisé**, et la résolution saisie est appliquée.
3. **Given** un article dont la préférence est **« remplacer »**, **When** Yao propose un équivalent **du même vendeur** avec photo et prix dans la limite de ±20 %, **Then** Awa reçoit la proposition et dispose de **60 secondes** pour l'accepter ou la refuser ; acceptée, elle remplace l'article ; refusée, l'article est retiré.
4. **Given** une proposition de remplacement sans réponse au bout de **60 secondes**, **When** le délai expire, **Then** Awa est **appelée** ; **When** elle est injoignable, **Then** l'article est **retiré** et n'est pas facturé.
5. **Given** un remplacement dont le prix dépasse l'écart maximal de la zone (défaut ±20 %), **When** Yao tente de le proposer, **Then** la proposition est **refusée**.
6. **Given** un remplacement proposé, **When** l'article de remplacement appartient à un **autre vendeur**, **Then** la proposition est **refusée** (la réaffectation vers un autre vendeur est hors périmètre).
7. **Given** une substitution ou un retrait appliqué, **When** on recalcule le total, **Then** le **devis de livraison reste figé** (frais et effort inchangés), seul le **montant des articles** est révisé, et le total dû est encaissé **en une seule fois**.
8. **Given** tous les articles d'un arrêt indisponibles, **When** l'arrêt est traité, **Then** son statut passe **indisponible**, il est **compté comme résolu** pour la bascule en livraison, et aucun montant n'y est avancé.

---

### User Story 8 - Annuler proprement, sans que personne ne perde (CMD-07, Priority: P3 — produit : P0)

Awa annule. Tant qu'**aucun achat ni aucune récupération n'a eu lieu**, l'annulation est **sans frais**. Dès qu'un arrêt a été **collecté** — donc que Yao a avancé de l'argent —, l'annulation bascule sur les règles d'échec de livraison. L'**admin** peut annuler **à tout moment** avec un motif. Le **dédommagement du coursier** suit la règle : sa part est **due** dès qu'au moins un arrêt a été collecté.

**Why this priority**: L'annulation est le chemin de sortie de toutes les branches ; elle est courte mais engage l'argent, donc elle vient après que la collecte et les substitutions soient stables.

**Independent Test**: Annuler avant toute collecte et vérifier l'absence de frais ; annuler après une collecte et vérifier la bascule sur les règles d'échec avec la part coursier due ; annuler en tant qu'admin à différents états et vérifier que le motif est obligatoire et journalisé.

**Acceptance Scenarios**:

1. **Given** une commande sans aucun arrêt collecté, **When** Awa annule, **Then** l'annulation est **sans frais** et l'état passe à annulée.
2. **Given** une commande dont au moins un arrêt est **collecté**, **When** Awa annule, **Then** les **règles d'échec de livraison** s'appliquent et la **part du coursier est due**.
3. **Given** n'importe quel état non terminal, **When** l'admin annule, **Then** un **motif est obligatoire**, l'annulation est journalisée avec son auteur, et le dédommagement du coursier suit la même règle.
4. **Given** une commande **déjà livrée**, **When** on tente de l'annuler, **Then** la transition est **refusée**.
5. **Given** une commande **prépayée** annulée sans frais, **When** l'annulation est enregistrée, **Then** l'événement de remboursement dû est **émis** (son exécution relève des paiements, non construits ici).

---

### User Story 9 - Dérouler l'arbre des échecs sans jamais que le coursier perde (CMD-08, Priority: P3 — produit : P0)

Awa est injoignable devant chez elle. Yao ne peut déclarer l'échec qu'une fois les **preuves réunies** (appels via l'app espacés, présence géolocalisée, photo sur place). Le système déroule alors l'**arbre du cadrage §7.5**, **arrêt par arrêt** : marchandise **non périssable** → retour aux vendeurs concernés, **remboursements tracés par arrêt** ; **refus de reprise** d'un vendeur → litige et **indemnisation du coursier** ; marchandise **périssable** → litige, indemnisation, et **sanction client** (prépaiement imposé au premier refus, compte bloqué au second) ; **client injoignable et vendeur fermé** → consigne au local et **re-livraison facturée** sous forme d'une nouvelle commande liée. Chaque issue **journalise qui détient l'argent et qui détient la marchandise**. Les autres cas du §7.5 — contestation du montant, absence d'appoint, faux billet, non-conformité, casse, annulation après achat, suspicion de faux refus — ont chacun leur issue tracée.

**Why this priority**: C'est la story qui tient la promesse « le coursier ne perd jamais », condition de la confiance de la flotte. Elle vient en dernier car elle consomme tout le reste : arrêts, montants avancés, annulations, sanctions.

**Independent Test**: Écrire **un test d'intégration par ligne du tableau §7.5** et vérifier pour chacun l'issue attendue, la trace « qui détient l'argent / qui détient la marchandise », l'événement d'indemnisation le cas échéant, et la sanction client quand elle s'applique ; vérifier qu'un échec déclaré **sans les preuves** est refusé.

**Acceptance Scenarios**:

1. **Given** une commande non livrable et des preuves **incomplètes**, **When** Yao déclare l'échec, **Then** la déclaration est **refusée**.
2. **Given** des preuves complètes et une marchandise **non périssable**, **When** l'échec est déclaré, **Then** le retour est organisé **vers chaque vendeur concerné** et les remboursements sont tracés **par arrêt**.
3. **Given** un vendeur qui **refuse la reprise**, **When** le retour est tenté, **Then** un **litige** est ouvert (événement) et l'**indemnisation du coursier** est due — le coursier ne supporte pas la perte.
4. **Given** une marchandise **périssable** (catégorie déclarée périssable), **When** l'échec est déclaré, **Then** l'indemnisation du coursier est due, un litige est ouvert, et le client reçoit la **sanction** : **prépaiement imposé** au premier refus, **compte bloqué** au second.
5. **Given** un client injoignable **et** un vendeur **fermé**, **When** l'échec est déclaré, **Then** la marchandise part en **consigne** et une **nouvelle commande de re-livraison** liée à la première est proposée, **facturée** avec son propre devis.
6. **Given** n'importe quelle issue de l'arbre, **When** elle est enregistrée, **Then** l'état journalise explicitement **qui détient l'argent** et **qui détient la marchandise**, et l'événement correspondant est écrit dans la même transaction.
7. **Given** un client qui **conteste le montant** ou **n'a pas l'appoint**, **When** la remise est tentée, **Then** aucune négociation ni paiement partiel n'est possible : soit la **totalité** en cash, soit la **totalité** en mobile money, soit un **refus** traité comme les cas ci-dessus.

---

### Edge Cases

- **Vendeur qui ferme entre la confirmation et la collecte** : l'arrêt ne peut pas être collecté ; il est traité comme indisponible (préférences de substitution appliquées article par article), et si tous les arrêts deviennent indisponibles, la commande bascule en annulation sans frais pour la cliente.
- **Article devenu indisponible entre le panier et la confirmation** : la création est refusée avant tout verrouillage de prix, avec le motif — pas de commande créée sur un stock fantôme.
- **Panier hors ligne envoyé après un changement de prix** : à la reconnexion, les prix et stocks sont confirmés au moment de l'envoi ; un écart est présenté à la cliente avant verrouillage, jamais appliqué en silence.
- **Deux collectes chez le même vendeur** (deux arrêts distincts sur un même prestataire) : chaque arrêt garde son propre scan, son propre montant avancé et son propre statut.
- **Arrêt entièrement indisponible** : compté comme résolu pour la bascule en livraison, montant avancé nul, remboursement sans objet.
- **Toutes les collectes indisponibles** : il ne reste rien à livrer — la commande se solde sans remise, sans encaissement, et le coursier est dédommagé selon la règle d'annulation après acceptation.
- **Rupture signalée après la bascule en livraison** : trop tard pour une substitution — l'article part en litige de non-conformité, pas en substitution.
- **Adresse dont le repère vocal est purgé pendant que la commande est en course** : la note déjà téléchargée par le coursier reste jouable ; la purge ne casse pas une course en cours.
- **Position du coursier absente ou périmée** (réseau du coursier coupé) : le suivi affiche l'âge de la dernière position au lieu de la masquer ; aucune position inventée.
- **Client hors ligne au moment de la livraison** : le code et le QR fonctionnent quand même — ils ont été remis à la création et mis en cache.
- **Double confirmation de commande** (double tap, retry réseau) : une seule commande, réponse identique.
- **Détour au-delà du plafond d'éclatement combiné à un panier mixte** : les deux propositions de scission portent sur le même mécanisme et ne se contredisent pas — la cliente voit une proposition unique, chiffrée.
- **Commande de catégorie non livrée** (vertical futur sans livraison) : le tronc existe sans composant de livraison ; aucun état logistique n'est exigé.

## Requirements *(mandatory)*

### Functional Requirements

**Modèle structurel (CMD-04, constitution II)**

- **FR-001**: Le tronc `commande` DOIT porter uniquement : identité (client, zone, catégorie), prestataire(s) concerné(s), lieu de prestation, montants, paiement et états de **très haut niveau** — et AUCUN champ logistique.
- **FR-002**: La `livraison` DOIT être un composant **optionnel (0..n)** rattaché à la commande ; les verticaux de livraison du MVP en créent **exactement une**. Aucun élément partagé ne DOIT supposer que toute commande est une livraison.
- **FR-003**: Une livraison DOIT se composer de **segments (1..n**, MVP : 1**)**, chaque segment de **1..n arrêts de collecte + 1 arrêt de remise** ; la remise est un **arrêt du segment** (le dernier, sans prestataire), pas un champ du segment.
- **FR-004**: Chaque arrêt DOIT porter son prestataire (hors remise), son **ordre**, son **scan**, sa **photo éventuelle**, son **montant avancé** et son **statut** {à collecter, collecté, indisponible}.
- **FR-005**: L'**ordre des arrêts** DOIT être l'ordre optimisé fourni par la tarification, **figé à la création** de la commande.
- **FR-006**: Les spécificités du vertical restauration DOIVENT vivre dans une **table de détails dédiée** derrière le trait de workflow de service ; AUCUN champ spécifique à un vertical ni logistique ne DOIT entrer dans le tronc.

**Panier multi-vendeurs (CMD-01)**

- **FR-007**: Le panier DOIT accepter des articles de **plusieurs vendeurs agréés** lorsque la catégorie est déclarée **mixable** pour la zone (paramètre de zone hérité, jamais en dur).
- **FR-008**: Les articles DOIVENT être affichés **regroupés par vendeur**, avec un **sous-total par vendeur** et le **détail des frais** (déplacement, suppléments d'arrêt, effort) avant confirmation.
- **FR-009**: Une catégorie **non mixable** (restauration) DOIT rester **mono-vendeur par commande** et ne DOIT pas se mélanger aux courses ; toute tentative DOIT déclencher une **proposition de scinder en 2 commandes**, prévisualisées, avec la mention explicite de **deux frais de déplacement**.
- **FR-010**: Le système NE DOIT JAMAIS scinder d'office : la décision appartient au client.
- **FR-011**: Le panier DOIT gérer les **quantités** et afficher **total articles + frais** avant confirmation.
- **FR-012**: Chaque article DOIT porter une **préférence de substitution** {remplacer, m'appeler, retirer}, avec **« m'appeler » par défaut**.
- **FR-013**: En paiement cash, le panier DOIT afficher le **montant exact** et la mention « préparez l'appoint ».
- **FR-014**: La **livraison offerte par le vendeur** DOIT s'appliquer aux commandes **mono-vendeur uniquement** ; dans un panier multi-vendeurs, les frais s'appliquent normalement (aucune répartition de gratuité).
- **FR-015**: Lorsque le devis signale un **détour au-delà du plafond d'éclatement** de la zone, le système DOIT proposer la **même scission** que pour la règle de mixage — sans jamais scinder d'office.
- **FR-016**: Hors connexion, le panier DOIT être **conservé localement** avec un **total estimé** ; aucune commande n'est créée ; une **action unique** part en file d'attente et, à la reconnexion, prix et stocks sont **confirmés avant** verrouillage.

**Adresse de livraison (CMD-02)**

- **FR-017**: L'adresse DOIT comporter un **pin GPS**, renseignable par le bouton **« Utiliser ma position actuelle »** et déplaçable à la main.
- **FR-018**: Un **repère est obligatoire** : **texte d'au moins 10 caractères** OU **note vocale** d'au plus la durée maximale de la zone (défaut 30 s) ; la note DOIT être **jouable par le coursier** en course.
- **FR-019**: Un **téléphone vérifié** DOIT être exigé pour toute adresse de livraison.
- **FR-020**: Une adresse enregistrée DOIT être réutilisable **en un tap**, **repère vocal compris** ; si le repère vocal a été **purgé** par la rétention, un repère DOIT être redemandé avant confirmation.
- **FR-021**: L'utilisation d'une adresse pour une commande DOIT **marquer son usage** (base de la rétention).

**Création et paiement (CMD-03)**

- **FR-022**: Les **prix des articles** DOIVENT être **verrouillés** à la création, au prix courant du catalogue (le prix barré reste informatif).
- **FR-023**: Le **devis** produit par la tarification DOIT être **figé** sur la commande {frais client, part coursier, marge, devise, composantes}.
- **FR-024**: Le **cash** DOIT être autorisé si le **total de la commande** (articles + frais) est inférieur ou égal au **plafond cash de la zone** ET si le compte ne porte pas `prépaiement imposé` ; pour la **restauration d'un client sans historique**, le **plafond réduit** de la zone s'applique. Un client est réputé **sans historique** tant qu'il compte **moins de commandes terminées** que le seuil de la zone (paramètre `commande.historique_min_commandes_terminees`, défaut **1** — la première commande de restauration d'un compte est donc plafonnée). Seules les commandes **terminées** comptent : une commande annulée ou échouée ne constitue pas un historique.
- **FR-025**: Au-delà des plafonds, le **prépaiement mobile money** DOIT être exigé **avant dispatch**, le cash étant présenté comme indisponible **avec sa raison**.
- **FR-026**: Un compte portant le drapeau **bloqué** NE DOIT PAS pouvoir créer de commande.
- **FR-027**: Un **code de livraison à 4 chiffres** et un **jeton QR de réception** DOIVENT être générés **à la création** et remis **immédiatement** au client, mis en cache sur son appareil pour un accès **hors ligne**.
- **FR-028**: La commande DOIT porter : articles à prix verrouillés, devis figé, préférences de substitution, adresse (pin + repère texte/vocal), mode de paiement, code et jeton.
- **FR-029**: La création DOIT vérifier la **disponibilité du vendeur** (statut boutique, horaires) et des **articles** ; un échec DOIT refuser la création **avant** tout verrouillage de prix, avec un motif.
- **FR-030**: La création DOIT être **idempotente** sur la clé fournie par le client : un renvoi donne **une seule** commande et une réponse identique.

**Machine à états (CMD-04)**

- **FR-031**: Le système DOIT implémenter les états et transitions du cadrage §7.2 : **nouvelle → assignée → en collecte →** [par arrêt, dans l'ordre : **en route vers l'arrêt → arrivé → collecté**] **→ en livraison → livrée**, avec les branches **annulée**, **échec de livraison**, **en attente de coursier** et **en attente de paiement**.
- **FR-032**: Toute transition DOIT être **gardée côté serveur** ; une transition illégale DOIT être **refusée en conflit** sans modifier l'état.
- **FR-033**: Toute transition acceptée DOIT être **horodatée par le serveur** et écrire un **événement outbox dans la même transaction**.
- **FR-034**: Les états **logistiques** DOIVENT vivre sur la livraison, le segment et l'arrêt ; le tronc ne porte que les états de **très haut niveau**.
- **FR-035**: Lorsque **toutes les collectes sont résolues** (collectée ou indisponible), la livraison DOIT basculer automatiquement **en livraison**.
- **FR-036**: Les actions de collecte et de transition DOIVENT être **idempotentes** sur l'identifiant d'action fourni par le client (file hors ligne) ; en cas de conflit, le **serveur fait foi**.

**File d'attente sans coursier (CMD-10)**

- **FR-037**: Sans coursier éligible, la commande DOIT passer **en attente de coursier**, être rangée en **FIFO par âge** et **reprise automatiquement** dès qu'un coursier redevient éligible.
- **FR-038**: Le client DOIT être informé (état de recherche, **délai estimé**) et pouvoir **annuler sans frais** tant que la commande est en attente.

**Suivi client (CMD-05)**

- **FR-039**: Le suivi DOIT présenter les états en **langage clair** et la **progression par arrêt** (« 2 collectes sur 3 »), avec le vendeur en cours.
- **FR-040**: La **position du coursier** DOIT être rafraîchie au moins toutes les **30 secondes** dès la première collecte, située **le long de l'itinéraire multi-arrêts**, et son **âge** DOIT être affiché ; aucune position ne DOIT être inventée.
- **FR-041**: Le client DOIT pouvoir **appeler le coursier** depuis l'app, l'**intention étant journalisée**.
- **FR-042**: Le **code** et le **QR de réception** DOIVENT être accessibles **à tout moment**, y compris **hors ligne**.
- **FR-043**: Hors connexion, le suivi DOIT présenter le **dernier état connu** comme tel et mettre le QR et le code **en avant**.

**Substitutions (CMD-06)**

- **FR-044**: À la découverte d'une indisponibilité, le système DOIT appliquer la **préférence exprimée sur cet article**.
- **FR-045**: « Retirer » DOIT sortir l'article et réviser le montant ; « m'appeler » DOIT déclencher un **appel journalisé** et une **résolution saisie** ; « remplacer » DOIT exiger **photo et prix** et une **validation client de 60 secondes**.
- **FR-046**: Sans réponse à l'expiration des **60 secondes**, le client DOIT être **appelé** ; **injoignable**, l'article DOIT être **retiré** et **non facturé**.
- **FR-047**: L'**écart de prix** d'un remplacement DOIT être borné par le paramètre de zone (défaut **±20 %**) ; au-delà, la proposition est refusée.
- **FR-048**: Une substitution DOIT rester **chez le même vendeur** ; toute proposition portant sur un autre vendeur DOIT être refusée (réaffectation = phase 2).
- **FR-049**: Le total DOIT rester payé **en une seule fois** ; AUCUN chemin de paiement partiel ne DOIT exister.
- **FR-050**: Après substitution ou retrait, le **devis de livraison DOIT rester figé** (frais de déplacement et grille d'effort inchangés) ; seul le **montant des articles** est révisé. La part d'effort promise au coursier reste due même si un retrait fait descendre le panier d'un palier d'articles, et les frais annoncés au client avant confirmation ne montent jamais en cours de course.
- **FR-051**: Un arrêt dont tous les articles sont indisponibles DOIT passer **indisponible**, être **compté comme résolu** pour la bascule en livraison, et ne porter **aucun montant avancé**.

**Annulations (CMD-07)**

- **FR-052**: Le client DOIT pouvoir annuler **sans frais** tant qu'aucun achat ni aucune récupération n'a eu lieu.
- **FR-053**: Après qu'au moins un arrêt a été **collecté**, l'annulation client DOIT basculer sur les **règles d'échec de livraison**.
- **FR-054**: L'**admin** DOIT pouvoir annuler à tout moment (hors état terminal) **avec un motif obligatoire**, journalisé avec son auteur.
- **FR-055**: Le **dédommagement du coursier** DOIT être dû dès qu'**au moins un arrêt a été collecté**.

**Échec de livraison (CMD-08)**

- **FR-056**: La déclaration d'échec DOIT être **refusée tant que les preuves ne sont pas réunies** (appels via l'app espacés, présence géolocalisée, photo sur place — produites par le module coursier, non construit ici).
- **FR-057**: Marchandise **non périssable** → **retour aux vendeurs concernés**, avec **remboursements tracés par arrêt**.
- **FR-058**: **Refus de reprise** d'un vendeur → **litige ouvert** et **indemnisation du coursier due**.
- **FR-059**: Marchandise **périssable** (catégorie déclarée périssable, paramètre de zone) → litige, indemnisation du coursier, et **sanction client** : `prépaiement imposé` au premier refus, `bloqué` au second.
- **FR-060**: **Client injoignable et vendeur fermé** → **consigne** et **re-livraison facturée** sous forme d'une **nouvelle commande liée**, portant son propre devis.
- **FR-061**: Chaque issue DOIT journaliser explicitement **qui détient l'argent** et **qui détient la marchandise**.
- **FR-062**: CMD-08 DOIT **décider l'issue, la journaliser, poser la sanction client et émettre** les événements d'ouverture de litige et d'indemnisation due ; il NE DOIT construire **ni l'enregistrement de litige** (module avis) **ni l'écriture de caisse** (module coursier), tous deux prévus en tranche T2.
- **FR-063**: Les autres cas du cadrage §7.5 — contestation du montant, absence d'appoint, faux billet, non-conformité, casse en transport, annulation après achat, suspicion de faux refus — DOIVENT chacun avoir une **issue tracée**, couverte par un test d'intégration dédié.

**Transverse**

- **FR-064**: Tous les paramètres métier de ce cycle — mixabilité par catégorie, caractère périssable, plafonds cash (zone et restauration sans historique), **seuil d'historique client**, délai de validation de substitution (60 s), écart de prix maximal (±20 %), durée maximale de note vocale, longueur minimale du repère texte, fréquence de position (30 s) — DOIVENT être des **paramètres de zone hérités**, jamais des valeurs en dur.
- **FR-065**: Toute chaîne destinée à l'utilisateur DOIT être une **clé i18n fr** ; aucune chaîne en dur.
- **FR-066**: Tous les montants DOIVENT être des **entiers en unités mineures** accompagnés du **code ISO 4217** de la zone ; aucun flottant, aucune conversion.
- **FR-067**: Les événements de ce cycle (création, transitions, collecte, substitution, annulation, échec) DOIVENT être **déclarés dans la taxonomie** avant implémentation, avec leurs propriétés standard (zone, catégorie, rôle, version d'app).
- **FR-068**: La portée applicative de ce cycle DOIT couvrir le **domaine, l'API et les écrans clients** du panier (maquette C3) et du suivi (maquette C4) ; les apps **coursier** et **admin** restent hors périmètre et leurs surfaces sont exercées par API et par des doubles dans les tests.

### Key Entities

- **Commande (tronc)** : identité du client, zone, catégorie, prestataire(s), lieu de prestation, montants (articles verrouillés, devis figé, total), paiement (mode, état), état de très haut niveau, code de livraison et jeton QR de réception. Aucun champ logistique.
- **Ligne de commande** : article, vendeur, quantité, prix verrouillé, préférence de substitution, statut (présent, remplacé, retiré) et lien vers l'arrêt qui la collecte.
- **Détails de vertical (restauration)** : table dédiée derrière le trait de workflow de service — délai de préparation, états additionnels et hooks propres au vertical. Jamais dans le tronc.
- **Livraison** : composant optionnel (0..n) rattaché à la commande — état logistique, coursier assigné, horodatages.
- **Segment** : niveau transporteur ordonné d'une livraison (MVP : 1). Le modèle en accepte n ≥ 2 sans changement (provision pour le pressing, hors périmètre).
- **Arrêt** : maillon d'un segment — type (collecte ou remise), prestataire (hors remise), ordre figé, position attendue, montant avancé, statut, journal de collecte (scan, mode, photo, horodatage serveur, identifiant d'action).
- **Adresse de commande** : pin GPS, repère texte ou vocal, téléphone vérifié — reprise du carnet d'adresses existant, dont l'usage est marqué à chaque commande.
- **Proposition de substitution** : arrêt, ligne concernée, article proposé (même vendeur), photo, prix, échéance de validation, issue (acceptée, refusée, expirée puis appelée, retirée).
- **Issue d'échec** : type (refus périssable, refus de reprise vendeur, contestation, appoint, faux billet, non-conformité, casse, vendeur fermé, suspicion), arrêt(s) concerné(s), détenteur de l'argent, détenteur de la marchandise, sanction posée, événements émis.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Awa compose un panier de 12 articles chez 3 vendeurs et confirme sa commande en **moins de 3 minutes**, en ayant vu le détail des frais (articles, livraison, effort) **avant** de confirmer.
- **SC-002**: **100 % des transitions** de la machine à états, branches d'échec comprises, sont couvertes par un test d'intégration ; **toute** transition illégale est refusée sans changer l'état.
- **SC-003**: **Chacune des 10 lignes** du tableau des cas limites du cadrage §7.5 a son test d'intégration dédié, et chacun établit **qui détient l'argent** et **qui détient la marchandise**.
- **SC-004**: Le code de livraison et le QR de réception sont consultables par le client **sans aucune connexion**, **100 % du temps** dès la confirmation de la commande.
- **SC-005**: **Aucune** commande ne peut se solder par un encaissement partiel : le total est encaissé en une fois, en cash ou en mobile money.
- **SC-006**: **100 %** des tentatives de mélanger restauration et courses aboutissent à une proposition de scission chiffrée ; **0 %** sont scindées d'office.
- **SC-007**: Le total encaissé à la livraison est **égal au total annoncé** (au franc près), substitutions et retraits compris ; les **frais de livraison** annoncés avant confirmation **ne varient jamais** en cours de course.
- **SC-008**: Une commande sans coursier éligible reste **visible, annulable sans frais** et **reprise automatiquement** dans l'ordre d'ancienneté — **aucune** commande n'est perdue faute de coursier.
- **SC-009**: Le suivi affiche la progression **par arrêt** et une position de **moins de 30 secondes** dès la première collecte ; hors ligne, il affiche le dernier état connu **avec son âge**, jamais une position inventée.
- **SC-010**: Une action rejouée (double tap, retry réseau, drain de file hors ligne) ne crée **jamais** de doublon : une commande créée deux fois reste une, une collecte rejouée reste une.
- **SC-011**: Une commande à 3 collectes se déroule **de bout en bout** — création, assignation simulée, 3 collectes scannées, remise contre code ou QR — sans qu'aucun champ logistique n'apparaisse sur le tronc.

## Assumptions

- **Portée applicative** : ce cycle livre le domaine, l'API et les **écrans clients** du panier (maquette C3) et du suivi (maquette C4) dans l'app Flutter cliente. Les apps **coursier** (CRS) et **admin** (ADM) ne sont pas construites ; leurs surfaces sont exercées par API et par des doubles, comme les cycles 006 et 007 l'ont fait pour la course active et les courses tarifées.
- **Modules simulés** : le dispatch (assignation, réassignation), les paiements (confirmation mobile money, remboursements), les preuves d'échec du coursier et les litiges sont **simulés dans les tests**. Ce cycle pose les états, les préconditions et les événements que ces modules brancheront sans changement de contrat.
- **Le caractère périssable** est un paramètre de **catégorie** hérité par zone (la restauration est périssable par défaut), et non un attribut d'article — cohérent avec « chaque catégorie est une configuration » (cadrage §4).
- **La re-livraison après consigne** est une **nouvelle commande liée** portant son propre devis, et non un second segment : le multi-segment planifié (CMD-09, pressing) est P2 et hors périmètre ; le modèle l'accepte néanmoins sans migration.
- **Le dédommagement du coursier** est dû dès qu'**au moins un arrêt est collecté** — c'est l'équivalent multi-arrêts de « part due si récupérée atteinte » (CMD-07), puisque c'est à la première collecte que le coursier engage ses fonds.
- **Le plafond cash de zone** se compare au **total de la commande** ; la **capacité d'avance du coursier** (montant des articles, tous arrêts confondus) est un plafond distinct porté par le dispatch, non construit ici.
- **Le carnet d'adresses, les prix du catalogue, le devis figé, l'ordre optimisé, le scan par arrêt et la politique photo** sont consommés tels quels des cycles 002, 003, 005, 006 et 007 ; ce cycle ne les redéfinit pas.
- **Les seuils numériques cités** (10 caractères de repère, 30 s de note vocale, 60 s de validation, ±20 %, 30 s de position, plafonds cash) sont des **valeurs par défaut de zone** issues du « Récapitulatif des paramètres de zone » — toutes éditables, aucune en dur.
- **La réaffectation d'un article vers un autre vendeur** en cours de course et la **commande aller-retour à 2 segments** (pressing) sont explicitement **hors périmètre** ; le modèle de segments les rend possibles sans migration future.
