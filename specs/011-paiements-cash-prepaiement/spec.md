# Feature Specification: Paiements — chaîne cash tracée par arrêt et prépaiement mobile money via agrégateur

**Feature Branch**: `011-paiements-cash-prepaiement`

**Created**: 2026-08-01

**Status**: Draft

**Input**: User description: "Lis docs/user-stories-v2.md, module PAY — Paiements, et docs/cadrage-v5.md sections §10.7 et §12. Fonctionnalité : chaîne cash et prépaiement mobile money via agrégateur. Périmètre : PAY-01, PAY-02, PAY-05 — critères tels quels. Trait PaymentProvider { create_checkout, verify_webhook, refund } ; implémentation MVP = AGRÉGATEUR (le checkout expose tous les moyens disponibles : Wave, Orange Money, MTN MoMo, Moov, carte le cas échéant ; le moyen utilisé est enregistré sur la transaction) ; session de paiement à la commande, EN_ATTENTE_PAIEMENT jusqu'au webhook signé, expiration 15 min → annulation notifiée, webhooks idempotents ; chaîne cash tracée PAR ARRÊT (avance au scan — ou montant − frais si livraison offerte, mono-vendeur uniquement, retenue visible sur le reçu —, remboursement client à la livraison en totalité et en une fois, frais encaissés) ; « qui détient quoi » cohérent à chaque état, échecs compris. Hors périmètre : PAY-03 (mobile money sur place, P1), PAY-04 (remboursements, P1), PAY-06 (commission dégressive, P2). Le routage par moyen de paiement vers des intégrations directes opérateurs = phase 2+, l'interface le permet déjà. Personas : Awa, Yao, Admin. Points d'attention : l'agrégateur précis n'est pas encore choisi — isole tout ce qui lui est spécifique derrière le trait pour que le choix reste réversible ; JAMAIS de chemin de paiement partiel."

## Clarifications

### Session 2026-08-01

- Q: **PAY-01 exige la retenue « montant − frais si livraison offerte »**, mais la configuration qui rend une livraison offerte par le vendeur est **VND-08** (P1, même tranche T3, non listée au périmètre). Le moteur de tarification calcule DÉJÀ la retenue (`composantes.retenue_vendeur`, mono-vendeur, après les drapeaux de zone), mais la création de commande lui passe toujours « aucune offre » faute de configuration vendeur. Que construit ce cycle ? → A: **La configuration vendeur MINIMALE est incluse** — le choix {jamais, toujours, à partir de X FCFA} et son passage au calcul du devis, rien de plus. « Critères tels quels » demande une retenue réellement exerçable ; une retenue qui ne se déclenche jamais en production n'est pas un critère vérifié, et le cycle VND-08 devrait alors revalider toute la chaîne d'argent. Ce qui reste à VND-08 : le **badge client** « Livraison gratuite / dès X FCFA » sur la fiche et le panier, et le merchandising associé — surfaces séparables sans dette. Reflété en FR-046 à FR-049, FR-053, US5 et SC-009.
- Q: Le cycle 010 a **explicitement déféré à PAY** le remboursement de l'avance d'un coursier sur une commande **prépayée** (FR-117 : « une commande prépayée dont un arrêt a été collecté laisse une avance non soldée dans la caisse »). Le client ne rembourse rien à la remise : c'est **Mefali** qui doit à Yao. Comment ce mouvement naît-il ? → A: **Automatiquement à la confirmation de livraison**, avec un **état de règlement** porté par la créance (dû → réglé), que l'exploitation marque lorsqu'elle a réellement versé. Une créance mécanique — le montant est certain, le bénéficiaire est certain, l'événement déclencheur est certain — n'a pas à attendre un clic : la caisse de Yao mentirait jusque-là, exactement ce que le cycle 010 refusait de laisser passer. La validation d'exploitation reste ce qu'elle est aujourd'hui : le chemin des **indemnisations**, c'est-à-dire des cas litigieux. Reflété en FR-063, FR-067, FR-068, US6 et SC-008.
- Q: Une notification de paiement **réussi** peut arriver **après** l'expiration des 15 minutes et l'annulation de la commande (retard de l'agrégateur, client qui valide au dernier moment). L'argent d'Awa a quitté son compte, sa commande n'existe plus, et **PAY-04 (remboursements) est hors périmètre**. Que fait le système ? → A: **La commande reste annulée** ; la transaction est enregistrée « payée hors délai », ouvre un dossier d'exploitation et Awa est informée qu'elle sera remboursée — traitement manuel jusqu'à PAY-04. Ressusciter une commande annulée rendrait au client des prix, un stock et un créneau que plus rien ne garantit ; ignorer la notification laisserait de l'argent encaissé sans trace ni contrepartie. Reflété en FR-036 à FR-038, FR-082 et SC-011.

**Décisions confirmées par les sources (sans question, sections citées)** — ambiguïtés candidates tranchées par les documents produit, le socle déjà livré ou les cycles précédents, plutôt que par supposition :

- **Le checkout n'offre AUCUN choix de moyen côté Mefali.** `docs/user-stories-v2.md` PAY-02 (« le checkout expose **tous les moyens disponibles** chez l'agrégateur retenu ») et le cadrage **§10.7** (« intégrer **d'un coup tous les moyens de paiement disponibles** ») sont sans ambiguïté : c'est la page de l'agrégateur qui présente Wave, Orange Money, MTN MoMo, Moov et la carte. Le produit n'en présélectionne aucun, n'en masque aucun, n'en tarife aucun différemment. Le moyen n'est connu qu'**après** — communiqué par le fournisseur, enregistré comme donnée d'analyse. Reflété en FR-011, FR-012 et FR-043.
- **La décision « cash ou prépaiement » n'appartient pas à ce cycle.** CMD-03 (cycle 008) l'a livrée entière : plafond de zone, plafond réduit « restauration + client sans historique », sanction `prepaiement_impose`, refus à la création. Ce cycle **branche un vrai encaissement** derrière une décision déjà prise ; il ne rouvre aucun plafond. Reflété dans « Ce que ce cycle NE construit PAS ».
- **`EN_ATTENTE_PAIEMENT` et sa sortie existent déjà** : le cycle 008 a posé l'état, la transition de sortie et l'événement `commande.paiement_confirme`, en notant lui-même « PAY **simulé** ce cycle ». Ce cycle **remplace la simulation par la notification signée** sans inventer un second chemin de sortie. Reflété en FR-023 et FR-032.
- **Le livre de caisse du coursier est déjà append-only et déjà idempotent** (cycle 010, CRS-06) : écritures signées, identifiant d'événement unique, corrections par écriture INVERSE, aucune table de solde. Ce cycle **ajoute les mouvements qui manquaient** — il ne réécrit ni le livre, ni ses règles, ni son immuabilité. Reflété en FR-061 et FR-064.
- **Le montant réellement avancé à un arrêt est déjà recalculé au scan** depuis les lignes vivantes (cycle 010, correctif T087 — « 900 F d'écart entre les deux écrans de la même app »). Ce cycle **soustrait la retenue** de ce montant ; il ne revient pas à la colonne figée. Reflété en FR-050.
- **La retenue de la livraison offerte est déjà CALCULÉE par la tarification** (cycle 007) : mono-vendeur seulement, après les drapeaux de zone, avec la règle d'arbitrage de VND-08 — « pendant le lancement, le drapeau de zone prime (frais déjà nuls, aucune retenue vendeur) ». Ce cycle l'**applique** au terrain (avance, caisse, reçus) ; il ne la recalcule ni ne la réarbitre. Reflété en FR-050 à FR-053.
- **L'annulation pose déjà l'état de paiement, pas le mouvement d'argent.** Le cycle 008 écrit `etat_paiement = 'rembourse'` sur une commande prépayée annulée, avec ce commentaire : « `rembourse` est un état de paiement, pas un mouvement de caisse : l'écriture comptable appartient à PAY, qui s'y branchera par l'événement ». Ce cycle **rend ce remboursement visible et traçable** ; il ne construit pas son exécution automatique (PAY-04, P1). Reflété en FR-082 et FR-111.
- **L'annulation par expiration emprunte le chemin d'annulation existant**, avec sa règle « sans frais » déjà calculée (aucun arrêt collecté). Une commande expirée n'a rien fait acheter : elle est annulée sans frais, sans part coursier due, sans indemnisation. Créer une seconde règle d'annulation serait une seconde vérité. Reflété en FR-031 et FR-032.
- **Aucun écran d'administration n'est construit ici.** Le pilotage admin est **ADM-01→06**, stories distinctes de la même tranche T3 (§0.5). Ce cycle pose les **endpoints d'exploitation** et les fait exercer par les tests d'API — exactement ce que les cycles 009 et 010 ont fait pour leurs surfaces d'exploitation. Reflété en FR-083.
- **La notification d'annulation passe par le contrat NTF déjà utilisé.** NTF-01/NTF-02 sont des stories distinctes ; le module de notifications n'est pas construit. Ce cycle **émet l'événement** que NTF consommera et **affiche l'information dans le suivi client**, qui ne dépend d'aucun push. Reflété en FR-033.
- **Le paiement mobile money SUR PLACE reste absent** (PAY-03, P1) : le cycle 010 l'a déjà consigné comme écart de maquette assumé sur K4-1a. Ce cycle ne le construit pas davantage — l'abstraction qu'il pose le rendra possible sans réécriture. Reflété en FR-110.
- **La commission vendeur n'existe pas au MVP.** Le cadrage **§12.1** fixe 0 % de commission jusqu'à M4 et PAY-06 est P2. Le modèle de « qui détient quoi » porte donc une **marge Mefali** qui vaut 0 en pratique aujourd'hui — mais qui existe dans la ventilation, sinon l'activation M4 exigerait de reprendre toute la chaîne d'argent. Reflété en FR-056 et FR-112.

## User Scenarios & Testing *(mandatory)*

Personas de ce cycle :

- **Awa (cliente)** — commande depuis un Android d'entrée de gamme, paie en espèces quand elle le peut, en mobile money quand le montant dépasse le plafond de sa zone. Elle n'a **aucune notion** d'agrégateur : elle voit une page de paiement, choisit son opérateur, revient dans l'app. Un paiement qui « passe » sans que sa commande démarre, ou une commande qui démarre sans qu'elle ait payé, sont l'un comme l'autre des ruptures de confiance définitives.
- **Yao (coursier)** — sort l'argent de sa poche à chaque arrêt et le récupère chez le client. Sur une commande prépayée, il ne récupère **rien** chez le client : c'est Mefali qui lui doit. Sa caisse doit rester vraie au franc près, cash et prépayé mêlés dans la même journée.
- **Admin (exploitation Tiassalé)** — doit pouvoir répondre à « où est cet argent ? » pour n'importe quelle commande, à n'importe quel état, sans ouvrir la base ni le tableau de bord de l'agrégateur.

Priorités produit : **PAY-01, PAY-02 et PAY-05 sont toutes P0** (`docs/user-stories-v2.md` §0.6 : 3 P0 + 2 P1 + 1 P2 pour le module), tranche **T3 — Argent & pilotage** (§0.2). Les priorités P1→P7 attachées aux stories ci-dessous sont l'**ordre de livraison interne** au cycle (chaîne de dépendances), pas une hiérarchie produit.

### Ce que ce cycle NE construit PAS parce que c'est déjà là

- **La décision cash / prépaiement** (CMD-03, cycle 008) : plafonds de zone, plafond réduit restauration sans historique, sanction `prepaiement_impose`, refus du cash à la création. Ce cycle la consomme telle quelle.
- **L'état EN_ATTENTE_PAIEMENT, sa transition de sortie et son événement** (cycle 008). Ce cycle remplace la confirmation simulée par la confirmation réelle.
- **Le livre de caisse append-only du coursier**, ses écritures signées, son idempotence par événement, ses corrections inverses, sa vue caisse et son exposition admin (cycle 010, CRS-06).
- **Le recalcul du montant réellement avancé** à chaque scan depuis les lignes vivantes (cycles 006 et 010).
- **Le calcul de la retenue de livraison offerte** et son arbitrage avec le drapeau de zone (cycle 007, TRF).
- **L'annulation de commande**, sa règle « sans frais », sa part coursier due et son événement d'indemnisation (cycle 008).
- **L'outbox transactionnel et son worker au-moins-une-fois** (cycle 001), qui impose l'idempotence de tout consommateur.
- **Le verrouillage des prix à la création** et le devis figé (cycles 007/008) : aucun reçu, aucune retenue, aucun encaissement ne recalcule quoi que ce soit.

### Ce que ce cycle construit

1. **Un module de paiement dont le fournisseur est interchangeable** : trois opérations (ouvrir un encaissement, vérifier une notification entrante, rembourser), une implémentation agrégateur, un double de test, et **zéro nom de fournisseur** hors de cette frontière.
2. **La session de prépaiement de bout en bout** : ouverture à la commande, accès remis à Awa, attente, confirmation par notification signée, expiration à 15 minutes, annulation notifiée.
3. **La chaîne cash tracée par arrêt** : avance nette de retenue au scan, encaissement du total en une fois à la remise, ventilation des frais — avec l'invariant « aucun chemin partiel » tenu partout.
4. **La position d'argent — « qui détient quoi »** : trois contreparties (vendeurs, client, Mefali), vraies à chaque état de commande, échecs et annulations compris, et la levée de l'avance non soldée laissée ouverte par le cycle 010.
5. **Les reçus des deux côtés** : ce qu'Awa doit, ce que le vendeur reçoit, et la retenue quand elle joue.
6. **La part minimale de VND-08 qui rend la retenue exerçable** : la déclaration {jamais, toujours, à partir de X FCFA} par vendeur, et son passage au calcul du devis. Rien d'autre — le badge client et le merchandising restent à VND-08.
7. **Le registre d'exploitation des transactions** : état, moyen utilisé, référence fournisseur, rapprochement avec la commande, cas orphelins visibles.

### Surface d'interface, frontières et modules simulés

- **Frontière fournisseur** : tout ce qui est propre à un agrégateur (adresse d'appel, format et algorithme de signature, vocabulaire d'états, nomenclature des moyens de paiement, codes d'erreur) vit **derrière** l'abstraction. Aucune règle métier, aucun état de commande, aucun écran n'en dépend. Le choix de l'agrégateur (CinetPay, PayDunya, Bizao, HUB2 — cadrage §10.7) reste ouvert et **réversible**.
- **Sens des dépendances** : `paiements ──▶ commandes`, jamais l'inverse. Le module de commandes ne connaît pas l'existence d'un fournisseur ; il expose ce dont le paiement a besoin (total figé, état, transition de confirmation).
- **Modules simulés** : **NTF** (notifications) n'est pas construit — l'annulation par expiration émet son événement et le suivi client porte l'information sans dépendre d'un push. **ADM** n'est pas construit — les surfaces d'exploitation sont des endpoints exercés par les tests d'API, sans écran d'administration.
- **Emprunt assumé à VND-08** : la déclaration d'offre de livraison par vendeur est construite ici parce que PAY-01 ne peut pas être vérifié sans elle (FR-046 à FR-049). Le badge client, le merchandising et le tri restent la story VND-08.
- **Écart de maquette assumé** : l'option « Générer un lien de paiement mobile money » de l'écran coursier K4-1a reste absente (PAY-03, P1).

---

### User Story 1 - Payer d'avance sans quitter le parcours (PAY-02, Priority: P1 — produit : P0)

Awa compose un panier au-dessus du plafond cash de sa zone. L'app lui dit que le paiement à l'avance est requis et lui ouvre une page de paiement où **tous** les moyens de son opérateur sont proposés. Elle paie avec Wave. En quelques secondes, sa commande quitte l'attente et part chercher un coursier.

**Why this priority**: sans encaissement réel, toutes les commandes au-dessus du plafond sont mortes à la création. C'est la seule story qui débloque du chiffre d'affaires aujourd'hui inaccessible.

**Independent Test**: créer une commande dépassant le plafond de zone, suivre l'accès retourné, faire confirmer le paiement par le double de fournisseur, vérifier que la commande est passée en NOUVELLE avec un paiement réglé et qu'elle est visible du dispatch.

**Acceptance Scenarios**:

1. **Given** une commande dont le total dépasse le plafond cash, **When** Awa confirme, **Then** la commande naît EN_ATTENTE_PAIEMENT avec une session vivante et un accès exploitable, et son paiement est marqué « en attente » — pas « dû ».
2. **Given** une session vivante, **When** Awa paie et que la notification signée du fournisseur arrive, **Then** la commande passe NOUVELLE, le paiement passe « réglé », le moyen effectivement utilisé est enregistré, et un seul événement de confirmation est écrit.
3. **Given** une commande confirmée, **When** le dispatch la regarde, **Then** elle est éligible exactement comme une commande cash — aucune règle de dispatch ne connaît le mode de paiement.
4. **Given** Awa qui ferme l'app juste après avoir été redirigée, **When** elle rouvre le suivi de sa commande, **Then** elle retrouve l'état d'attente, le temps restant et le moyen de reprendre le paiement.
5. **Given** un paiement refusé par l'opérateur (solde insuffisant), **When** la notification d'échec arrive, **Then** la commande reste en attente jusqu'à l'échéance et Awa peut réessayer sans repasser commande.

---

### User Story 2 - La commande fantôme n'existe pas (PAY-02, Priority: P2 — produit : P0)

Awa ouvre la page de paiement puis abandonne. Quinze minutes plus tard, sa commande est annulée, elle en est informée, et rien n'a été mobilisé pour rien : aucun vendeur n'a préparé, aucun coursier n'a été sollicité.

**Why this priority**: une commande en attente éternelle pollue le dispatch, trompe le vendeur et fausse toutes les métriques. L'expiration est ce qui rend la première story sûre.

**Independent Test**: créer une commande prépayée, ne rien confirmer, porter l'horloge au-delà de l'échéance, déclencher le balayage, vérifier l'annulation, son motif, son caractère « sans frais » et l'événement de notification.

**Acceptance Scenarios**:

1. **Given** une session ouverte depuis plus que la durée de vie configurée, **When** le balayage passe, **Then** la commande est annulée avec un motif tracé, sans frais, sans part coursier due, et un événement de notification cliente est écrit.
2. **Given** une commande annulée par expiration, **When** Awa consulte son suivi, **Then** elle voit l'annulation et son motif en clair, sans jargon de paiement.
3. **Given** une commande dont le paiement a été confirmé à la quatorzième minute, **When** le balayage passe à la seizième, **Then** elle n'est PAS annulée — une commande réglée ne s'annule jamais par échéance.
4. **Given** l'échéance dépassée, **When** Awa rouvre l'accès de paiement, **Then** le paiement lui est refusé côté produit avec un message clair, et l'app lui propose de recommander.
5. **Given** une commande déjà annulée par expiration, **When** une notification de **succès** arrive malgré tout, **Then** la commande **reste annulée**, la transaction est enregistrée « payée hors délai », un dossier d'exploitation est ouvert avec son motif, et Awa est informée qu'elle sera remboursée.

---

### User Story 3 - Une notification signée, comptée une seule fois (PAY-02 / PAY-05, Priority: P3 — produit : P0)

Le fournisseur renvoie la même notification cinq fois, un tiers en poste une fausse, et deux arrivent en même temps. Il ne se passe rien de plus qu'une seule confirmation.

**Why this priority**: c'est l'endroit exact où un défaut fabrique de l'argent qui n'existe pas, ou en efface qui existe. La constitution III en fait une règle non négociable.

**Independent Test**: rejouer une notification valide N fois, poster une notification à signature invalide, poster deux notifications concurrentes — vérifier qu'il n'existe qu'une confirmation, qu'un événement, qu'une transition, et que l'invalide n'a laissé qu'une trace de refus.

**Acceptance Scenarios**:

1. **Given** une notification correctement signée, **When** elle est rejouée dix fois, **Then** la commande n'est confirmée qu'une fois, l'événement n'est écrit qu'une fois, et les rejeux répondent « déjà traité » sans erreur.
2. **Given** une notification à signature absente, falsifiée ou périmée, **When** elle arrive, **Then** elle est refusée avant toute lecture de son contenu, journalisée comme tentative, et n'a **aucun** effet.
3. **Given** deux notifications concurrentes pour la même transaction, **When** elles sont traitées en parallèle, **Then** une seule produit un effet et l'autre est neutre.
4. **Given** une notification annonçant un montant différent du total figé de la commande, **When** elle est vérifiée, **Then** elle ne vaut PAS confirmation : la commande reste en attente et l'écart ouvre un dossier d'exploitation.
5. **Given** un retour de navigateur affirmant « paiement réussi » sans notification correspondante, **When** l'app le présente, **Then** le produit ne crédite rien : seule la vérification côté serveur fait foi.

---

### User Story 4 - Ce que Yao sort de sa poche, au franc près (PAY-01, Priority: P4 — produit : P0)

À chaque arrêt, Yao voit le montant exact à donner au vendeur. Il l'avance, le récupère chez Awa à la livraison — en totalité, en une fois — et garde les frais de course. Sa caisse dit la même chose que sa poche.

**Why this priority**: c'est la promesse « le coursier ne perd jamais » (cadrage §7.5). Un livre qui ment une fois ne se rattrape pas.

**Independent Test**: dérouler une course cash à deux arrêts avec un article retiré et un arrêt indisponible, puis la remise ; comparer le livre de caisse ligne à ligne avec le cash réellement manipulé.

**Acceptance Scenarios**:

1. **Given** un arrêt dont une ligne a été retirée, **When** Yao scanne, **Then** l'avance écrite au livre est la somme des lignes **vivantes** de cet arrêt — jamais le montant figé à la création.
2. **Given** un arrêt déclaré entièrement indisponible, **When** la course continue, **Then** **aucune** avance n'est écrite pour cet arrêt et le montant à encaisser chez Awa est diminué d'autant.
3. **Given** une commande cash livrée, **When** la remise est validée, **Then** un seul encaissement est écrit, égal au **total dû** de la commande, et il n'existe aucun état intermédiaire « partiellement encaissé ».
4. **Given** une livraison échouée après achat (client absent, preuves réunies), **When** l'échec est déclaré, **Then** l'avance reste **ouverte** au livre et une créance apparaît explicitement — elle ne disparaît d'aucun solde.
5. **Given** une journée mêlant deux courses cash, un échec et une correction d'exploitation, **When** Yao ouvre sa caisse, **Then** chaque mouvement est lisible avec son sens (sortie / entrée), son motif et sa commande.

---

### User Story 5 - La retenue de la livraison offerte, visible des deux côtés (PAY-01 + part minimale de VND-08, Priority: P5 — produit : P0)

Le vendeur offre la livraison. Awa ne paie pas de frais. Yao donne au vendeur le montant des articles **moins** les frais de course — et ni l'un ni l'autre n'a à faire le calcul de tête : les deux reçus l'affichent.

**Why this priority**: c'est le seul mécanisme du MVP où l'argent d'une course change de main ailleurs que chez le client. Non tracé, il devient une dispute hebdomadaire sur le marché.

**Independent Test**: déclarer l'offre chez un vendeur, passer une commande mono-vendeur éligible, drapeau de zone au repos ; vérifier l'avance nette au scan, la retenue au reçu vendeur, la retenue au reçu client, et l'absence totale de retenue sur un panier multi-vendeurs.

**Acceptance Scenarios**:

1. **Given** un vendeur qui déclare offrir la livraison {toujours} ou {à partir de X FCFA}, **When** une commande est créée ensuite, **Then** le devis en tient compte ; **When** on regarde les commandes créées avant, **Then** aucune n'est retarifée — le devis figé ne bouge jamais.
2. **Given** une commande mono-vendeur dont la livraison est offerte par le vendeur, **When** Yao scanne l'arrêt, **Then** le montant affiché et l'avance écrite valent « articles − frais », et l'écran explique la retenue.
3. **Given** la même commande, **When** le reçu du vendeur et celui d'Awa sont produits, **Then** tous deux montrent le montant des articles, la retenue et le net — mêmes chiffres des deux côtés.
4. **Given** un panier **multi-vendeurs**, **When** un vendeur offre la livraison, **Then** **aucune** retenue n'est appliquée nulle part et les frais sont dus normalement.
5. **Given** le drapeau de zone « livraison offerte Mefali » actif (promotion de lancement), **When** un vendeur offre aussi la livraison, **Then** le drapeau prime : frais client déjà nuls, **aucune** retenue vendeur.
6. **Given** une retenue supérieure au montant des articles de l'arrêt, **When** Yao scanne, **Then** l'avance est nulle — jamais négative — et l'écart ouvre un dossier d'exploitation au lieu de faire payer le coursier.

---

### User Story 6 - Personne ne détient l'argent d'un autre sans que ça se voie (PAY-01, Priority: P6 — produit : P0)

À n'importe quel instant, pour n'importe quelle commande, l'admin peut dire qui détient quoi : ce que Yao a avancé et pas récupéré, ce qu'il détient pour Mefali, ce que Mefali lui doit. Y compris sur les commandes prépayées, les échecs et les annulations.

**Why this priority**: c'est la formulation littérale de PAY-01 et de la constitution III. C'est aussi ce qui lève la limite assumée du cycle 010.

**Independent Test**: parcourir les états de commande un à un (créée, en attente de paiement, prépayée, assignée, partiellement collectée, livrée, annulée avant achat, annulée après achat, échouée, expirée) et vérifier à chaque fois que la ventilation équilibre à l'unité près.

**Acceptance Scenarios**:

1. **Given** une commande **prépayée** dont Yao a collecté les arrêts, **When** la livraison est confirmée, **Then** l'avance de Yao cesse **automatiquement** d'être une exposition ouverte : elle devient une créance identifiée sur Mefali, à l'état « dû », sans qu'aucun humain n'ait à intervenir.
2. **Given** cette même créance, **When** l'exploitation la consulte puis marque le versement effectué, **Then** elle passe à « réglé » avec qui a marqué et quand ; **When** la même livraison est rejouée depuis la file hors-ligne, **Then** aucune seconde créance n'apparaît.
3. **Given** une commande cash livrée, **When** la position est calculée, **Then** ce que Yao détient pour Mefali (la marge, nulle au MVP) et ce que Mefali lui doit (sa part de course) sont distincts et chacun explicite.
4. **Given** une commande annulée après achat, **When** la position est calculée, **Then** l'avance ouverte et la part coursier due apparaissent toutes deux, et l'indemnisation existante les rapproche.
5. **Given** n'importe lequel de ces états, **When** on somme les trois positions, **Then** elles s'équilibrent avec les montants figés de la commande, sans écart d'une seule unité mineure.

---

### User Story 7 - Changer d'agrégateur sans toucher au métier (PAY-05, Priority: P7 — produit : P0)

Le prestataire retenu déçoit sur les délais de reversement. On en branche un autre. Aucun état de commande, aucune règle, aucun écran ne bouge.

**Why this priority**: le cadrage §10.7 dit que l'agrégateur n'est **pas encore choisi** et que la phase 2+ passera par des intégrations directes opérateurs. Une abstraction posée après coup coûte une réécriture de la chaîne d'argent.

**Independent Test**: faire passer à un **second** double de fournisseur, au vocabulaire et aux signatures différents, la totalité de la suite de tests de paiement — sans modifier une seule règle métier.

**Acceptance Scenarios**:

1. **Given** la suite de tests de paiement, **When** on substitue un fournisseur au vocabulaire différent, **Then** tous les scénarios passent sans modification hors de la frontière fournisseur.
2. **Given** le code du domaine (commandes, caisse, reçus, dispatch), **When** on y cherche un nom d'agrégateur ou de moyen de paiement propriétaire, **Then** on n'en trouve aucun.
3. **Given** l'abstraction posée, **When** on projette le routage de phase 2+ (« Wave en direct, le reste par l'agrégateur »), **Then** il ne demande qu'une nouvelle implémentation et un paramètre — aucune règle métier ne change ; **aucune règle de routage n'est construite ce cycle**.
4. **Given** un fournisseur en panne ou trop lent, **When** Awa confirme sa commande, **Then** elle reçoit un message clair et sa commande n'est **jamais** laissée dans un état bancal ni confirmée par défaut.

---

### Edge Cases

- **La notification arrive avant la fin de l'ouverture de session** (course entre le fournisseur et notre propre écriture) : la confirmation ne doit ni se perdre, ni créer une seconde transaction.
- **La notification n'arrive jamais** (perte réseau du fournisseur) alors que le client a payé : sans rattrapage, la commande expire et l'argent est parti. Une réconciliation à l'échéance interroge le fournisseur avant d'annuler.
- **Le paiement réussit après l'expiration** : la commande reste annulée, la transaction est « payée hors délai », un dossier s'ouvre, Awa est prévenue du remboursement à venir (FR-037/FR-038).
- **Le montant notifié diffère du total figé** (frais du prestataire prélevés à la source, arrondi) : jamais de confirmation sur un montant qui ne correspond pas.
- **La devise notifiée diffère de celle de la zone** : refus, dossier d'exploitation.
- **Awa relance la création deux fois** (double appui, réseau lent) : une seule commande, une seule session, un seul accès.
- **La retenue vendeur dépasse le montant des articles** de l'arrêt (petit panier, longue course) : avance nulle, jamais négative, dossier d'exploitation.
- **Un vendeur offre la livraison sur un panier multi-vendeurs** : aucune retenue, nulle part.
- **Le drapeau « livraison offerte Mefali » et l'offre vendeur jouent ensemble** : le drapeau prime, aucune retenue.
- **Yao encaisse une commande dont un arrêt était indisponible** : le montant à encaisser doit avoir suivi, sinon il réclame de l'argent qu'Awa ne doit pas.
- **Yao termine une commande prépayée hors ligne** puis se resynchronise : le solde de son avance ne doit ni doubler, ni manquer.
- **Une correction d'exploitation sur une écriture déjà rapprochée** : l'inverse s'ajoute, le rapprochement se refait, rien ne s'efface.
- **Une commande annulée alors que le remboursement client est dû** : l'état « remboursé » est posé sans qu'aucun argent ne soit rendu tant que PAY-04 n'existe pas — la dette doit rester **visible**, pas silencieuse.
- **Une transaction confirmée sans commande correspondante** (référence corrompue, commande purgée) : orpheline et visible comme telle, jamais rattachée au hasard.

## Requirements *(mandatory)*

### Frontières et invariants (transversaux)

- **FR-001**: Tout montant manipulé par ce cycle MUST être un entier en unités mineures accompagné du code ISO 4217 de la zone ; aucun flottant, à aucun endroit, y compris dans les échanges avec le fournisseur.
- **FR-002**: Le système MUST NE JAMAIS accepter, produire ni représenter un paiement partiel : une transaction couvre la **totalité** du montant dû, ou n'existe pas. Aucun état « partiellement payé », « solde restant » ou « acompte » ne MUST pouvoir être atteint.
- **FR-003**: Tout élément propre à un fournisseur (adresse d'appel, secrets, algorithme et format de signature, vocabulaire d'états, nomenclature des moyens, codes d'erreur) MUST être confiné derrière l'abstraction de paiement ; aucun module métier, aucun état de commande, aucun écran ne MUST en dépendre.
- **FR-004**: Toute transition d'état produite par ce cycle MUST écrire son événement outbox dans la **même** transaction que la transition.
- **FR-005**: Toute chaîne destinée à un utilisateur MUST être une clé i18n fr ; aucun texte en dur, y compris les messages d'erreur de paiement.
- **FR-006**: Aucun secret de fournisseur, aucune signature, aucun accès complet à une session MUST apparaître en clair dans un journal, un événement outbox ou une réponse d'API.
- **FR-007**: Le sens des dépendances MUST rester `paiements ──▶ commandes` : le module de commandes MUST NE JAMAIS lire l'état interne du module de paiement.

### Session de prépaiement (PAY-02)

- **FR-010**: À la création d'une commande dont le mode est mobile money, le système MUST ouvrir une session de paiement pour le **total figé** de la commande et remettre au client un moyen d'y accéder, sans qu'il ait à ressaisir un montant.
- **FR-011**: Le parcours de paiement MUST exposer **tous** les moyens disponibles chez le fournisseur retenu (Wave, Orange Money, MTN MoMo, Moov Money, carte le cas échéant) ; le produit MUST NE présélectionner, masquer ni tarifer différemment aucun moyen.
- **FR-012**: Le moyen effectivement utilisé MUST être enregistré sur la transaction dès que le fournisseur le communique, et MUST rester « inconnu » tant qu'il ne l'a pas fait — jamais déduit ni supposé.
- **FR-013**: La commande MUST rester en EN_ATTENTE_PAIEMENT et MUST NE PAS être visible du dispatch tant que le paiement n'est pas confirmé.
- **FR-014**: À l'ouverture de la session, l'état de paiement de la commande MUST passer à « en attente » — aujourd'hui il reste « dû », valeur qui ne distingue pas une commande cash d'une commande en cours de paiement.
- **FR-015**: Une seule session vivante MUST exister par commande ; une seconde demande pour la même commande MUST renvoyer la session existante plutôt que d'en créer une deuxième.
- **FR-016**: Le client MUST pouvoir reprendre un paiement interrompu (app fermée, réseau perdu, retour manqué) depuis le suivi de sa commande, tant que la session vit.
- **FR-017**: Le suivi de commande MUST afficher l'état du paiement et le **temps restant** avant expiration, en clair, sans vocabulaire de fournisseur.
- **FR-018**: Une indisponibilité du fournisseur MUST produire un message explicite et MUST NE JAMAIS laisser la commande dans un état qui la rendrait ni payable ni annulable.

### Notification entrante et idempotence (PAY-02, PAY-05)

- **FR-020**: Toute notification entrante MUST être authentifiée par la signature du fournisseur **avant** que son contenu ne produise le moindre effet ; une signature absente, invalide ou périmée MUST entraîner un refus journalisé et **aucun** effet.
- **FR-021**: Le traitement d'une notification MUST être idempotent : le rejeu de la même notification MUST produire exactement une confirmation, une transition et un événement — les rejeux répondant « déjà traité ».
- **FR-022**: Deux notifications concurrentes portant sur la même transaction MUST aboutir à un seul effet ; la seconde MUST être neutre, jamais en erreur visible du fournisseur.
- **FR-023**: Une confirmation valide MUST faire passer la commande de EN_ATTENTE_PAIEMENT à NOUVELLE et son état de paiement à « réglé », **dans la même transaction** que l'événement de confirmation, par le chemin de transition existant.
- **FR-024**: Une notification annonçant un montant ou une devise différents de ceux figés sur la commande MUST NE PAS valoir confirmation ; l'écart MUST ouvrir un dossier d'exploitation visible.
- **FR-025**: Le système MUST NE JAMAIS créditer un paiement sur la foi d'un retour de navigateur, d'une redirection ou d'une affirmation de l'application cliente ; seule la vérification côté serveur fait foi.
- **FR-026**: Une notification d'échec (refus, fonds insuffisants, abandon) MUST laisser la commande en attente jusqu'à l'échéance et MUST permettre au client de réessayer sans repasser commande.
- **FR-027**: À l'approche de l'échéance, le système MUST vérifier directement auprès du fournisseur l'issue des sessions restées sans notification, afin qu'une notification perdue ne coûte ni la commande ni l'argent du client.

### Expiration et annulation (PAY-02)

- **FR-030**: La durée de vie d'une session MUST être un paramètre de zone à héritage, de valeur par défaut **15 minutes** ; aucune durée en dur.
- **FR-031**: À l'échéance sans confirmation, le système MUST annuler la commande par le **chemin d'annulation existant**, avec un motif tracé, sans frais, sans part coursier due.
- **FR-032**: L'annulation par expiration MUST NE PAS introduire une seconde règle d'annulation ni un second chemin de sortie de EN_ATTENTE_PAIEMENT.
- **FR-033**: Le client MUST être informé de l'annulation : événement de notification émis pour NTF, **et** information portée par le suivi de commande, qui ne MUST dépendre d'aucun push.
- **FR-034**: Une commande dont le paiement a été confirmé avant l'échéance MUST NE JAMAIS être annulée par le balayage, quelle que soit l'heure à laquelle celui-ci passe.
- **FR-035**: Après expiration, une tentative de paiement sur la même session MUST être refusée côté produit avec un message clair, et le client MUST se voir proposer de recommander.
- **FR-036**: Une commande annulée MUST NE JAMAIS être ressuscitée, y compris par une notification de succès tardive : le client repasse commande, avec des prix et un devis réévalués.
- **FR-037**: Une notification de **succès** arrivant après l'expiration MUST être **enregistrée** — jamais ignorée : la transaction passe à « payée hors délai », un dossier d'exploitation est ouvert avec son motif, et le rapprochement pointe la commande annulée.
- **FR-038**: Le client MUST être informé qu'un paiement hors délai a été reçu et sera remboursé ; le dossier MUST rester ouvert jusqu'à son traitement, qui est **manuel** tant que PAY-04 n'existe pas.

### Abstraction fournisseur (PAY-05)

- **FR-040**: L'abstraction de paiement MUST exposer exactement trois opérations : **ouvrir un encaissement**, **vérifier une notification entrante**, **rembourser**.
- **FR-041**: L'opération de remboursement MUST être **définie** mais son parcours métier MUST NE PAS être construit (PAY-04, P1) ; aucun remboursement automatique MUST être déclenché par ce cycle.
- **FR-042**: Remplacer le fournisseur MUST NE demander aucune modification des règles métier, des états de commande, des écritures de caisse ni des écrans — seule l'implémentation change.
- **FR-043**: L'abstraction MUST porter le moyen de paiement utilisé, de sorte que le routage par moyen de phase 2+ (« Wave en direct, le reste par l'agrégateur ») ne demande qu'une implémentation supplémentaire ; **aucune règle de routage MUST être construite ce cycle**.
- **FR-044**: Un double de fournisseur MUST permettre d'exercer sans réseau tous les chemins : succès, échec, expiration, signature invalide, rejeu, notification hors délai, montant divergent, indisponibilité.
- **FR-045**: Les secrets du fournisseur MUST provenir de la configuration d'exécution, jamais du code ni d'un fichier versionné.

### Livraison offerte par le vendeur — part minimale de VND-08

- **FR-046**: Un vendeur MUST pouvoir déclarer son offre de livraison selon exactement trois valeurs : **jamais**, **toujours**, **à partir de X unités mineures d'achat** ; la valeur par défaut est **jamais**.
- **FR-047**: Cette déclaration MUST être lue à la **création** de la commande et transmise au calcul du devis, qui décide seul de la retenue (mono-vendeur, après les drapeaux de zone).
- **FR-048**: Un changement de déclaration MUST NE PAS retarifer les commandes existantes : le devis figé ne bouge jamais (règle des cycles 007/008).
- **FR-049**: Ce cycle MUST NE PAS construire le reste de VND-08 — badge client « Livraison gratuite / dès X FCFA » sur la fiche et le panier, merchandising et tri associés.

### Chaîne cash tracée par arrêt (PAY-01)

- **FR-050**: À chaque scan d'arrêt, le montant avancé écrit au livre MUST être la somme des lignes **vivantes** de cet arrêt, **diminuée de la retenue** quand la livraison est offerte par le vendeur.
- **FR-051**: La retenue MUST NE s'appliquer qu'aux commandes **mono-vendeur**, donc à un unique arrêt de collecte ; sur un panier multi-vendeurs, aucune retenue MUST être appliquée nulle part.
- **FR-052**: L'avance écrite MUST NE JAMAIS être négative : si la retenue dépasse le montant des articles de l'arrêt, l'avance est nulle et l'écart MUST ouvrir un dossier d'exploitation plutôt que d'être supporté par le coursier.
- **FR-053**: La retenue MUST être visible **des deux côtés** — reçu du vendeur et reçu du client — avec le montant des articles, la retenue et le net, aux mêmes chiffres.
- **FR-054**: À la remise d'une commande cash, le système MUST enregistrer **un seul** encaissement, égal au montant total dû par le client, en une fois.
- **FR-055**: Un arrêt déclaré indisponible MUST NE produire aucune avance, et le montant dû par le client MUST en tenir compte — le coursier ne MUST JAMAIS réclamer un article non acheté.
- **FR-056**: Après un encaissement cash, la ventilation MUST distinguer explicitement ce que le coursier **récupère** (ses avances), ce qu'il **gagne** (sa part de course) et ce qu'il **détient pour Mefali** (la marge — nulle au MVP, présente dans le modèle pour l'activation M4).
- **FR-057**: Sur une commande **prépayée**, aucun encaissement cash MUST être écrit à la remise.
- **FR-058**: Un échec de livraison après achat MUST laisser l'avance **ouverte** et faire apparaître une créance explicite ; elle MUST NE disparaître d'aucun solde.

### Position d'argent — « qui détient quoi » (PAY-01)

- **FR-060**: Le système MUST pouvoir présenter, pour tout coursier et à tout instant, trois positions distinctes : **avancé non récupéré** (vis-à-vis des vendeurs), **détenu pour Mefali**, **dû par Mefali**.
- **FR-061**: Ces positions MUST être des sommes du livre append-only ; aucune colonne ni table de solde MUST être introduite.
- **FR-062**: La position MUST être définie et vérifiée pour **chacun** de ces états : créée, en attente de paiement, prépayée, assignée, partiellement collectée, livrée, annulée avant achat, annulée après achat, échouée, expirée.
- **FR-063**: À la confirmation de livraison d'une commande **prépayée**, le système MUST créer **automatiquement** — sans validation humaine — la créance qui solde l'avance du coursier, à l'état « dû », levant la limite assumée du cycle 010 (FR-117).
- **FR-064**: Toute correction MUST être une écriture **inverse** qui pointe l'originale ; aucune modification ni suppression d'écriture existante.
- **FR-065**: L'exploitation MUST voir, en plus de l'exposition cash déjà livrée, le **total des créances** dues aux coursiers et leur état de règlement.
- **FR-066**: La somme des positions MUST équilibrer avec les montants figés de la commande, à l'unité mineure près, dans tous les états de FR-062.
- **FR-067**: Une créance MUST porter un état de règlement **dû → réglé** ; l'exploitation MUST pouvoir marquer le versement effectué, et le marquage MUST conserver qui l'a fait et quand.
- **FR-068**: La création d'une créance MUST être idempotente : un rejeu de la confirmation de livraison depuis la file hors-ligne du coursier MUST NE JAMAIS produire une seconde créance ni un second mouvement.
- **FR-069**: Le règlement d'une créance MUST NE PAS emprunter le chemin de **validation des indemnisations** (cycle 010), réservé aux cas litigieux : une créance certaine ne se valide pas, elle se règle.

### Reçus (PAY-01)

- **FR-070**: Le client MUST disposer d'un reçu détaillant les articles à prix verrouillés, les frais, la retenue le cas échéant, le mode de paiement, le moyen utilisé et le montant réellement encaissé.
- **FR-071**: Le vendeur MUST disposer d'un reçu détaillant le montant des articles collectés, la retenue le cas échéant et le net qui lui a été versé.
- **FR-072**: Les deux reçus MUST reposer sur les montants **figés** de la commande et sur les écritures réellement enregistrées ; aucun recalcul, aucune estimation.
- **FR-073**: Sur une commande prépayée, le reçu client MUST indiquer que la commande est déjà réglée et que le montant à remettre au coursier est **nul**.

### Registre d'exploitation et rapprochement

- **FR-080**: L'exploitation MUST disposer d'un registre des transactions, filtrable par état, moyen utilisé, période et zone, portant la référence du fournisseur.
- **FR-081**: Toute transaction confirmée MUST pointer une commande, et toute commande prépayée réglée MUST pointer sa transaction — le rapprochement MUST être exact dans les deux sens.
- **FR-082**: Les cas **orphelins** — transaction confirmée sans commande valide, paiement hors délai, montant divergent, remboursement client dû non exécuté — MUST être visibles comme tels dans le registre, avec leur motif.
- **FR-083**: L'exploitation MUST disposer d'une vue des **créances de coursiers** filtrable par état de règlement, et du moyen d'y marquer un versement effectué (FR-067).
- **FR-084**: Ce cycle MUST poser les **endpoints d'exploitation** exercés par les tests d'API ; il MUST NE PAS construire d'écran d'administration (ADM-01→06, stories distinctes).

### Surfaces applicatives

- **FR-090**: L'app cliente MUST ouvrir le parcours de paiement, afficher un compte à rebours, gérer le retour et refléter l'état réel de la commande — sans jamais rester bloquée en attente d'une notification.
- **FR-091**: L'app cliente MUST signaler clairement une commande annulée par expiration et proposer de recommander.
- **FR-092**: L'app coursier MUST afficher le montant à avancer **net de la retenue** et en donner l'explication à l'écran.
- **FR-093**: L'app coursier MUST afficher un montant à encaisser **nul** sur une commande prépayée, sans ambiguïté possible avec un encaissement oublié.
- **FR-094**: La caisse du coursier MUST montrer les trois positions de FR-060 et, pour chaque créance, son état de règlement.
- **FR-095**: Les surfaces Flutter MUST respecter la gestion d'état imposée (Riverpod codegen, constitution XII) et le thème partagé ; aucune structure importée des exports HTML de design.

### Paramètres, périmètre et traçabilité

- **FR-100**: Tout paramètre métier de ce cycle (durée de vie de session, cadence du balayage, seuil d'alerte de créances) MUST être une configuration de zone à héritage ; aucune valeur en dur.
- **FR-101**: Ce cycle MUST déclarer ses événements dans `docs/taxonomie-evenements.md` avant implémentation, avec leurs propriétés standard.
- **FR-102**: Toute transition d'état introduite MUST être couverte par un test d'intégration, chemins d'échec compris.
- **FR-103**: Les événements de paiement MUST NE JAMAIS transporter de donnée permettant d'initier un paiement (accès complet à une session, jeton, signature).

### Périmètre différé

- **FR-110**: Ce cycle MUST NE PAS construire le paiement mobile money **sur place** (PAY-03, P1) ; l'écart de maquette de l'écran coursier reste assumé.
- **FR-111**: Ce cycle MUST NE PAS construire le parcours de **remboursement** (PAY-04, P1) : l'opération existe dans l'abstraction, les remboursements dus sont **visibles** comme dossiers et traités hors produit.
- **FR-112**: Ce cycle MUST NE PAS construire la **commission vendeur dégressive** (PAY-06, P2) ; la ventilation porte une marge Mefali qui vaut 0 aujourd'hui.
- **FR-113**: Ce cycle MUST NE PAS construire le **routage par moyen de paiement** ni aucune intégration directe opérateur (phase 2+).
- **FR-114**: Ce cycle MUST NE PAS construire le reste de **VND-08** au-delà de la déclaration de FR-046 : ni badge client, ni merchandising, ni tri (voir FR-049).

### Key Entities *(include if feature involves data)*

- **Transaction de paiement** : ce qu'un client doit ou a payé pour une commande — montant total figé, devise, état (ouverte, réglée, échouée, expirée, orpheline), moyen effectivement utilisé, référence du fournisseur, horodatages d'ouverture et d'issue. Une transaction couvre toujours la totalité ; il n'en existe jamais deux vivantes pour la même commande.
- **Session d'encaissement** : la fenêtre pendant laquelle le client peut payer — échéance, accès remis au client, état. Elle appartient à la transaction et meurt avec elle.
- **Notification de fournisseur reçue** : trace d'une notification entrante — identifiant du fournisseur, signature vérifiée ou refusée, issue, horodatage. Sa clé d'unicité porte l'idempotence ; sa présence permet de répondre « déjà traité » sans rejouer d'effet.
- **Écriture de caisse** (existante, cycle 010) : mouvement signé au livre append-only du coursier. Ce cycle en ajoute les natures manquantes — remboursement dû par Mefali, marge détenue pour Mefali — sans toucher aux règles du livre.
- **Créance de coursier** : ce que Mefali doit à un coursier (avance sur commande prépayée, part de course, indemnisation validée), avec son état de règlement (dû / réglé), qui l'a marqué et quand. C'est elle qui lève l'avance non soldée du cycle 010. Elle naît **automatiquement** de l'événement qui la rend certaine ; seul son règlement est un geste humain.
- **Offre de livraison du vendeur** : la déclaration {jamais, toujours, à partir de X} attachée à un vendeur, lue à la création de commande. Elle est une **entrée** du calcul du devis, jamais une décision de tarification en soi.
- **Reçu** : la vue figée de ce qui a été dû, retenu et encaissé, produite pour le client et pour le vendeur à partir des montants verrouillés et des écritures réelles.
- **Dossier d'exploitation** : anomalie d'argent qui doit être vue par un humain — montant divergent, paiement hors délai, transaction orpheline, retenue supérieure aux articles, remboursement client dû non exécuté.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Awa dispose d'un moyen de payer **moins de 10 secondes** après avoir confirmé une commande au-dessus du plafond, et y trouve **tous** les moyens proposés par le fournisseur.
- **SC-002**: **100 %** des commandes dont le paiement est confirmé quittent l'attente et deviennent dispatchables **sans aucune intervention humaine**.
- **SC-003**: Une notification rejouée **10 fois** produit exactement **1** confirmation, **1** transition et **1** événement — 0 doublon.
- **SC-004**: Sur **100** notifications non signées, falsifiées ou périmées, **0** produit le moindre effet et **100** laissent une trace de refus exploitable.
- **SC-005**: **100 %** des sessions non confirmées à l'échéance donnent lieu à une annulation notifiée **en moins d'une minute** après l'échéance, et **0 %** des commandes réglées sont annulées par le balayage.
- **SC-006**: Pour **chacun** des 10 états de commande listés en FR-062, la ventilation « qui détient quoi » équilibre avec les montants figés, **sans écart d'une seule unité mineure**.
- **SC-007**: Après une journée mêlant deux courses cash, une course prépayée, un échec après achat et une correction d'exploitation, Yao retrouve dans sa caisse un solde **exact au franc près**, contrôlable ligne à ligne, chaque ligne portant son sens et son motif.
- **SC-008**: **0** avance reste signalée « non soldée » après la livraison d'une commande prépayée : la créance est créée dans la **même** opération que la confirmation de livraison, et un rejeu hors-ligne n'en produit **jamais** une seconde.
- **SC-009**: Un vendeur qui déclare offrir la livraison voit la retenue s'appliquer dès la **commande suivante** et sur **0** commande antérieure ; sur **100 %** des commandes éligibles, le reçu client et le reçu vendeur affichent les **mêmes** trois montants (articles, retenue, net) ; sur **0 %** des paniers multi-vendeurs une retenue apparaît.
- **SC-010**: La totalité de la suite de tests de paiement passe avec un **second** fournisseur au vocabulaire différent, **sans modification** hors de la frontière fournisseur ; une recherche de nom d'agrégateur dans le code métier ne renvoie **aucun** résultat.
- **SC-011**: **100 %** des transactions confirmées sont rapprochées d'une commande, et **100 %** des anomalies d'argent (montant divergent, hors délai, orpheline, remboursement dû) apparaissent dans le registre d'exploitation avec leur motif — **0** notification de succès tardive n'est perdue, **0** commande annulée n'est ressuscitée.
- **SC-012**: Sur une commande prépayée, l'app coursier affiche « rien à encaisser » dans **100 %** des cas, et **0** encaissement cash n'est écrit.

## Assumptions

- **L'agrégateur n'est pas choisi.** Le cadrage §10.7 laisse le choix ouvert (CinetPay, PayDunya, Bizao, HUB2). Ce cycle est construit pour que le choix se fasse **après**, sans réécriture : l'implémentation concrète est la seule chose à remplacer.
- **Le double de fournisseur est le véhicule de test principal.** Aucun test automatisé ne dépend d'un service externe ; l'environnement de recette du fournisseur retenu servira à la validation manuelle finale, sur appareil.
- **Le remboursement client d'une commande annulée reste manuel** (PAY-04, P1). L'état « remboursé » posé par le cycle 008 continue de l'être ; ce cycle rend la dette **visible** dans le registre au lieu de la laisser silencieuse. Limite assumée, à lever par PAY-04. Il en va de même du paiement reçu **hors délai** (FR-037) : enregistré, notifié, remboursé à la main.
- **Le versement effectif des créances de coursiers se fait hors produit** (mobile money ou espèces à l'agence) : ce cycle crée la créance automatiquement et enregistre son règlement, il n'exécute aucun virement.
- **La marge Mefali vaut 0 au MVP** (cadrage §12.1 : 0 % de commission jusqu'à M4, 100 % des frais au coursier de M2/M3 à M3). Elle figure malgré tout dans la ventilation : l'omettre ferait de l'activation M4 une reprise de toute la chaîne d'argent.
- **Pendant la promotion de lancement, le drapeau de zone « livraison offerte Mefali » est actif** (seed Tiassalé) : les frais client sont nuls et, conformément à VND-08, **aucune retenue vendeur** ne joue, même si un vendeur a déclaré son offre. L'exercice réel de la retenue commence à la fin de la promotion — la déclaration construite ici est prête à cet instant, sans nouveau développement.
- **La déclaration d'offre de livraison est éditable par le vendeur et par l'exploitation**, comme les autres réglages de fiche vendeur livrés au cycle 005 ; aucune règle d'agrément ni de modération nouvelle n'est introduite.
- **La part de course due au coursier pendant la promotion est payée hors produit** (paie fixe, `docs/user-stories-v2.md` module CRS, note de fin). Ce cycle la **compte** comme créance ; il n'organise pas son versement.
- **NTF n'est pas construit** : les notifications d'expiration sont des événements émis pour un consommateur futur, doublés d'une information portée par le suivi de commande, qui n'exige aucun push.
- **ADM n'est pas construit** : les surfaces d'exploitation sont des endpoints, exercés par les tests d'API, comme aux cycles 009 et 010.
- **Le balayage d'expiration s'appuie sur le patron d'échéance déjà employé** par les substitutions et les offres de dispatch : une échéance en base, un passage périodique, aucune horloge cliente ne décide.
- **L'horloge du serveur fait foi** pour l'ouverture, l'échéance et l'issue d'une session — comme pour toute transition d'état depuis le cycle 003.
