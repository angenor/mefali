# Feature Specification: Dispatch automatique — assignation des courses sans intervention humaine

**Feature Branch**: `009-dispatch-assignation-auto`

**Created**: 2026-07-26

**Status**: Draft

**Input**: User description: "Lis docs/user-stories-v2.md, module DSP — Dispatch automatique, et docs/cadrage-v5.md section §7.3. Fonctionnalité : assignation automatique des courses, sans intervention humaine. Périmètre : DSP-01, DSP-02, DSP-03, DSP-04, DSP-05, DSP-06, DSP-07 — critères tels quels. Pool temps réel Redis (GEO + TTL, heartbeats 15–30 s, coursier muet hors pool) ; éligibilité : CAPACITÉS requises couvertes (MVP : types de véhicule, filtre générique), rayon 4 km, capacité d'avance cash sur le MONTANT TOTAL tous arrêts confondus ≤ min(grille par note, plafond déclaré du jour) sinon bascule prépaiement mobile money notifiée, paires bloquées exclues ; scoring pondéré normalisé (0,4 proximité ETA / 0,3 inactivité / 0,2 note / 0,1 acceptation, poids par zone) ; offre en cascade avec verrou SET offer:{order} NX EX 45 et timer 40 s, 3 premiers timeouts du jour non pénalisés ; broadcast après 3 candidats ou 120 s, premier accepteur ; escalade écran admin à 5 min + notification client avec annulation sans frais ; réassignation automatique (pas de mouvement 5 min / pas de scan prépa+10 min) ; file FIFO si aucun éligible. Tous les paramètres viennent de la configuration de zone, aucun en dur. Hors périmètre : DSP-08 (anti-abus, P1) ; stacking 2 commandes (phase 2). Personas : Yao, Admin. Points d'attention : la double acceptation doit être physiquement impossible (test de concurrence sur le verrou) ; une perte Redis ne perd aucune donnée métier (Postgres = vérité, pool reconstruit par heartbeats) ; maquette : docs/design/png/K2."

## Clarifications

### Session 2026-07-26

- Q: Ce cycle construit-il des surfaces Flutter coursier, alors que les documents placent l'écran d'offre sous CRS-02 et la mise en ligne + plafond du jour sous CRS-01 — stories distinctes de DSP dans la même tranche T1 (`docs/user-stories-v2.md` §0.5) ? → A: **Oui — l'écran d'offre K2 ET la tranche de disponibilité dont le pool dépend** (mise en ligne, publication de position, déclaration du plafond du jour) sont construits dans l'app `mefali_pro`. Les critères de DSP-01 (« heartbeat manquant → hors pool avec message « reconnexion » ») et de DSP-04 (compte à rebours de 40 s, accepter/refuser en un tap, « déjà prise sans pénalité ») sont des critères d'**expérience** qu'aucun test serveur ne couvre, et le pool ne se peuple pas depuis un téléphone sans émetteur de position. Ce que CRS-01 et CRS-02 gardent : le bandeau de gains du jour et les affinages de l'écran d'offre. Reflété en FR-093, US1, US4 et Assumptions.
- Q: Deux commandes deviennent prêtes au même instant et un seul coursier est éligible aux deux ; le verrou par commande de DSP-04 ne l'empêche pas de recevoir les deux offres. Que doit-il se passer ? → A: **Une seule offre en vol par coursier, toutes commandes confondues**, garantie par un **second verrou par coursier pris atomiquement avec celui de la commande**. La seconde commande passe immédiatement à son candidat suivant. Deux offres plein écran ne peuvent pas se disputer le même téléphone (K2 est un écran plein, avec un seul compte à rebours), et une commande ne brûle pas un candidat pour une offre qu'il ne pouvait pas honorer. Reflété en FR-056, FR-057, US4, les cas limites et SC-014.

**Décisions confirmées par les sources (sans question, sections citées)** — ambiguïtés candidates tranchées par les documents produit, le socle déjà livré ou la maquette, plutôt que par supposition :

- **Le canal qui porte l'offre jusqu'au téléphone n'est pas l'affaire de ce cycle** : `docs/user-stories-v2.md` **§0.5** liste **NTF-01** comme story **distincte** dans la **même tranche T1** que DSP-01→05, et **§0.6** l'attribue au module NTF ; NTF-01 porte explicitement « coursier haute importance, sonnerie prolongée ». Ce cycle pose donc le **contrat d'émission** avec ses canaux et ses clés i18n, et l'app **va chercher son offre courante** ; le push haute priorité et la sonnerie arrivent avec NTF-01, sans changement de contrat. Reflété en FR-094.
- **« Pas de progression » est un défaut de MOUVEMENT, pas un défaut d'état** : le « Récapitulatif des paramètres de zone » — qui fait foi — nomme la ligne « **Réassignation sans mouvement / sans scan**, 5 min / prépa + 10 min, DSP-07 », et le cadrage **§7.3 étape 6** dit « pas de **mouvement vers le vendeur** en X min ». La dimension d'état est portée par le **second** critère, « sans scan » (déjà distinct en FR-072) : les deux ne sont pas deux lectures concurrentes du même critère, ce sont **deux critères**. La formulation « pas de progression » de DSP-07 est une paraphrase de la même ligne. Reflété en FR-071 et FR-095.
- **L'écran d'opérations de la console admin est en tranche T3** (**§0.6** : module ADM en T3 ; **§0.5** : ADM-01→06 dans T3) : son absence dans ce cycle n'est pas un arbitrage, c'est le découpage produit. Reflété en FR-096.
- **L'acceptation d'une offre n'entre PAS dans la file d'actions hors-ligne** : CRS-08 énumère ce qui s'y enfile — « scans, photos, transitions, confirmations et appels » — et l'acceptation n'y figure pas. Une offre acceptée deux minutes trop tard n'a plus d'objet ; le rejeu reste néanmoins idempotent pour couvrir le double tap et la reprise réseau immédiate. Reflété en FR-054.

- **La note du coursier n'existe pas encore et ne sera pas inventée ici.** Le module d'avis n'est pas construit, et le cycle 008 a laissé `coursier.note` à `null` en le renvoyant explicitement à AVI (« rien à inventer ici »). Ce cycle traite donc l'absence de note de **deux façons distinctes et argumentées** : pour le **plafond d'avance**, absence de note = **palier d'entrée** de la grille, le plus bas (cadrage §7.5 : « plafonds bas puis relevés avec les notes ») ; pour la **composante de score**, absence de note = **valeur neutre**, qui ne récompense ni ne punit. Reflété en FR-024, FR-025 et FR-034.
- **Le seuil d'escalade est celui que le cycle 008 a déjà seedé** (`commande.escalade_attente_coursier_s` = 300 s) : ce cycle le **réutilise** au lieu d'en créer un doublon, conformément à la source de vérité unique des paramètres de zone (constitution I). Ce cycle **étend** en revanche la couverture de l'escalade : le cycle 008 n'escalade que les commandes déjà en file d'attente ; DSP-06 escalade **toute commande non assignée** au bout du même délai, cascade et broadcast compris. Reflété en FR-055 et FR-058.
- **La capacité requise d'une commande n'est pas persistée aujourd'hui** : le cycle 008 ne la porte que dans la charge utile de l'événement `commande.prete_a_dispatcher` (`transport_requis`), et le type de transport ne vit en base que sur la **règle tarifaire**. Le filtre d'éligibilité a besoin de la lire sur la commande — c'est une donnée que ce cycle **ajoute**. Reflété en FR-020.
- **Le rayon se mesure du coursier au premier arrêt de collecte**, jamais à l'adresse du client : le contrat offert au dispatch par le cycle 008 (`CommandeADispatcher`) expose délibérément la seule position de la première collecte, « parce que c'est lui qui décide de l'éligibilité géographique d'un coursier », et **aucune** coordonnée du client (minimisation ARTCI). Reflété en FR-021 et FR-088.
- **La période de publication de position est déjà un paramètre de zone** (`suivi.position_periode_s` = 30 s, cycle 008, fourchette DSP-01 de 15–30 s respectée) : ce cycle la **consomme** et n'ajoute que la **durée de vie** de l'inscription au pool, qui en dérive (plusieurs publications manquées). Reflété en FR-003 et FR-090.
- **La bascule prépaiement n'est pas déclenchée par « le pool est vide » mais par « la capacité d'avance est le SEUL critère bloquant »** : le cadrage §7.3 étape 1 conditionne l'exigence de prépaiement au dépassement de la capacité d'avance, pas à l'absence de coursier. Un pool vide pour une autre raison (personne en ligne, tous occupés, hors rayon) relève de la **file d'attente FIFO** déjà livrée par le cycle 008, où le prépaiement ne changerait rien. Reflété en FR-026, FR-027 et FR-028.
- **Une course dont au moins un arrêt est collecté n'est jamais réassignée automatiquement** : le coursier y a engagé ses fonds propres, et « le coursier ne perd jamais » (cadrage §7.5) interdit qu'un traitement automatique lui retire une marchandise qu'il a payée. Ces courses sont **escaladées à l'exploitation**, qui décide avec un motif tracé. Reflété en FR-064.
- **L'affectation passe obligatoirement par le contrat offert par le cycle 008** (`affecter`), jamais par une écriture directe : le cycle 008 a constaté qu'affecter un coursier en base laisse le tronc en `nouvelle` et fait ensuite refuser la remise par la table de transitions fermée. Reflété en FR-041.

## User Scenarios & Testing *(mandatory)*

Personas de ce cycle : **Yao (coursier)** — moto, réseau intermittent, avance le cash sur ses fonds propres, veut une décision en un tap et ne veut jamais être puni d'un réseau capricieux ; **l'Admin (exploitation Tiassalé)** — une personne, un écran, qui doit être alertée seulement quand l'automatisme a échoué et jamais noyée par des alertes répétées. **Awa (cliente)** apparaît en persona secondaire : elle est destinataire des notifications d'escalade et de bascule prépaiement, mais aucune de ses surfaces n'est modifiée.

Priorités produit : **DSP-01 à DSP-07 sont toutes P0** (`docs/user-stories-v2.md` §0.6 : 7 P0 + 1 P1). Les priorités P1→P4 attachées aux stories ci-dessous sont l'**ordre de livraison interne** au cycle (chaîne de dépendances), pas une hiérarchie produit. DSP-01 à DSP-05 relèvent de la tranche T1, DSP-06 et DSP-07 de la tranche T2 (§0.2).

### Ce que ce cycle NE construit PAS parce que c'est déjà là

- **Zones & configuration héritée (cycle 002)** : l'arbre de zones, l'héritage parent → enfant des paramètres, le référentiel des **types de transport** (slug + clé i18n + ordre) et la devise de zone. Ce cycle **ajoute et seede ses paramètres** dans ce mécanisme ; il n'en crée aucun autre.
- **Comptes & identité (cycle 003)** : rôle coursier, dossier validé, sessions, et surtout les **véhicules déclarés** du coursier (`comptes.vehicule_declare`, rattachés au référentiel de transport de la zone) — c'est là que vivent ses capacités au MVP. Le drapeau de compte `bloque` existe également.
- **Prestataires (cycle 005)** : sites vendeurs avec leur position GPS, horaires et statut de boutique. Le point de première collecte dont l'éligibilité géographique dépend en découle.
- **Tarification (cycle 007)** : l'**ordre optimisé des arrêts**, la matrice routière distances/durées, le **cache de routage par tronçon** (dont ce cycle lit les ETA sans jamais appeler le routage par candidat), le dégradé vol d'oiseau ×1,4 journalisé, et le devis figé dont l'ETA et la part coursier sont affichés dans l'offre.
- **Commandes (cycle 008)** : le **contrat explicitement offert au dispatch** — file FIFO par âge des commandes sans coursier et affectation atomique (`en_attente_coursier` / `affecter`) —, l'état `en_attente_coursier` sans table dédiée, l'événement `commande.prete_a_dispatcher` déclaré « sans consommateur, branché par DSP », la **lecture** de la dernière position d'un coursier avec son âge, la machine à états **fermée** à trois niveaux, la remise du code et du QR au client, et l'escalade de la file d'attente au seuil de zone.
- **Socle (cycle 001)** : journal d'événements transactionnel, idempotence des actions par identifiant fourni par le client, contrat d'interface et clients générés à partir de lui.

### Ce que ce cycle construit

Le **pipeline complet de dispatch**, déclenché sans aucune intervention humaine : le **pool temps réel** des coursiers disponibles (inscription par publication de position, sortie par silence), le **filtre d'éligibilité** (capacités requises, rayon, capacité d'avance, paires bloquées), le **classement pondéré** des candidats, l'**offre en cascade** protégée par deux verrous qui rendent la double acceptation impossible, le **broadcast** de dernier recours, l'**escalade** vers l'exploitation avec annulation sans frais offerte au client, et la **réassignation automatique** d'une course qui n'avance pas. Plus les **compteurs propres au module** dont le classement dépend : inactivité, taux d'acceptation, non-réponses non pénalisées du jour.

Et, côté app coursier, les **deux surfaces sans lesquelles le pipeline n'existe pas du point de vue de Yao** : la **disponibilité** (mise en ligne, publication de position, déclaration du plafond du jour, état de reconnexion) et l'**écran d'offre** (compte à rebours, arrêts, gain, montant à avancer, accepter/refuser, « déjà prise — sans pénalité »).

### Surface d'interface, frontières et modules simulés

Côté **coursier**, la maquette de référence est `docs/design/png/K2` (« App coursier (Mefali Pro) — K2 · Offre de course ») : plein écran, compte à rebours de 40 s sur bandeau sombre, arrêts dans l'ordre optimisé avec leurs distances, **destination approximative** (« Adresse exacte après acceptation »), gain total détaillé, montant à avancer avec rappel du plafond, accepter/refuser en un tap ; et son état 1b, « Course attribuée à un autre coursier — sans pénalité, 1 sur 3 aujourd'hui ». **Cet écran est construit ici**, ainsi que la **tranche de disponibilité dont le pool dépend** — mise en ligne, publication de position, déclaration du plafond du jour (maquette `docs/design/png/K1`). Ce que CRS-01 et CRS-02 gardent : le **bandeau de gains du jour** et les affinages de l'écran d'offre.

Cinq modules dont ce cycle dépend **ne sont pas construits** et sont exercés par des doubles, comme les cycles 006, 007 et 008 l'ont fait pour la course active, les courses tarifées et le dispatch :

| Module non construit | Ce que ce cycle pose | Ce qu'il simule dans les tests |
|---|---|---|
| **Notifications (NTF-01/02, tranche T1)** | le contrat d'émission d'une offre, d'une alerte d'exploitation et d'une notification client, avec leurs clés i18n et leurs canaux | le transport réel (push haute priorité, canal dédié, sonnerie prolongée, repli SMS) : l'app **va chercher son offre courante** en attendant |
| **Console admin (ADM-02/04, tranche T3)** | l'alerte d'escalade, l'incident de réassignation, la liste des courses non assignées et la grille des plafonds d'avance en paramètres de zone | l'**écran d'opérations** et son écran de grille : exercés par API, jamais construits ici |
| **Avis & notation (AVI)** | la lecture d'une note quand elle existera, et le traitement explicite de son absence | la note elle-même — palier d'entrée pour le plafond, valeur neutre pour le score |
| **Coursier (CRS-06/07)** | l'exclusion des **paires bloquées** derrière un contrat, et l'incident de réassignation que la caisse lira | l'enregistrement des paires bloquées (CRS-07, P1) et les écritures de caisse |
| **Paiements (PAY)** | la **bascule en prépaiement** et son motif, la reprise du pipeline une fois payé | la confirmation du paiement mobile money |

L'**app cliente n'est pas modifiée** : les notifications d'escalade et de bascule prépaiement sont posées comme contrats et vérifiées par API et par événements.

---

### User Story 1 - Être dans le pool tant qu'on donne signe de vie (DSP-01, Priority: P1 — produit : P0)

Yao se met en ligne et déclare son plafond d'avance du jour. À partir de là, son téléphone publie sa position à la période de la zone (30 s) : chaque publication le **réinscrit** au pool des coursiers offreables et repousse la durée de vie de son inscription. Le pool porte, pour lui, sa position, son statut, ses **types de véhicule déclarés**, la note retenue, son **plafond d'avance du jour** et l'identifiant de sa course active s'il en a une. Quand son réseau tombe et qu'il cesse de publier, son inscription **expire** : il ne reçoit plus aucune offre, et son app le lui dit clairement plutôt que de le laisser croire qu'il attend une course. La donnée métier, elle, ne dépend jamais de ce pool : si tout le pool disparaît, aucune commande n'est perdue et le pool se reconstitue tout seul à la publication suivante.

**Why this priority**: Sans pool, il n'y a personne à qui offrir une course — c'est la seule story dont toutes les autres dépendent, et la seule qui puisse être livrée seule. C'est aussi elle qui porte la garantie de robustesse la plus exposée : l'éphémère ne doit jamais devenir une source de vérité.

**Independent Test**: Mettre trois coursiers en ligne, vérifier qu'ils sont interrogeables par zone et par rayon avec leur état complet ; couper les publications de l'un et vérifier qu'il sort du pool à l'expiration, qu'il ne reçoit plus d'offre et que son app affiche l'état de reconnexion ; effacer intégralement le pool et vérifier qu'aucune commande n'est perdue, qu'aucune n'est assignée deux fois, et que le pool se reconstitue à la publication suivante — sans qu'aucune offre ne soit encore construite.

**Acceptance Scenarios**:

1. **Given** Yao en ligne sans course active, **When** son app publie sa position, **Then** il est inscrit au pool avec sa position, ses véhicules déclarés, la note retenue, son plafond du jour et l'absence de course active, et la durée de vie de son inscription repart de zéro.
2. **Given** Yao inscrit au pool, **When** il ne publie plus rien pendant plus que la durée de vie de l'inscription, **Then** il **sort du pool**, ne reçoit plus aucune offre, et son app affiche l'état « reconnexion » — jamais une attente silencieuse.
3. **Given** Yao inscrit au pool, **When** il se met hors ligne volontairement, **Then** il sort du pool **immédiatement**, sans attendre l'expiration.
4. **Given** Yao avec une course active, **When** le pool est interrogé pour une nouvelle commande, **Then** il n'est pas offreable — aucune superposition de deux commandes au MVP.
5. **Given** trois commandes en attente et un pool peuplé, **When** l'intégralité du pool est perdue, **Then** aucune commande n'est perdue ni assignée deux fois, l'exploitation n'a rien à réparer, et le service reprend dès que les coursiers publient à nouveau.
6. **Given** Yao qui déclare un plafond d'avance supérieur à celui que sa note autorise, **When** il valide, **Then** le plafond retenu est le **plus petit des deux**, et il voit lequel s'applique.
7. **Given** un nouveau jour, **When** Yao se met en ligne, **Then** son plafond du jour est **redemandé** — un plafond déclaré ne se reporte jamais tacitement d'un jour sur l'autre.

---

### User Story 2 - Ne proposer une course qu'à ceux qui peuvent réellement la faire (DSP-02, Priority: P1 — produit : P0)

Une commande devient prête à dispatcher. Le pipeline part du pool et écarte, dans cet ordre, tout ce qui rendrait la course impossible : les coursiers **hors ligne ou déjà en course**, ceux dont les **capacités déclarées ne couvrent pas les capacités requises** par la commande (au MVP le type de véhicule — le filtre est générique et acceptera les qualifications d'artisan sans refonte), ceux qui sont **au-delà du rayon** de la zone (4 km, mesuré jusqu'au premier arrêt de collecte, jamais jusque chez la cliente), ceux dont la **capacité d'avance** est insuffisante — le montant total des articles, **tous arrêts confondus**, doit tenir sous le plus petit de la grille par note et du plafond déclaré du jour — et ceux qui forment une **paire bloquée** avec la cliente ou l'un des vendeurs de la course. Si le seul obstacle restant est l'argent à avancer, la commande **bascule en prépaiement mobile money** et la cliente est prévenue avec le motif ; si le pool est vide pour toute autre raison, la commande rejoint la **file d'attente** existante et la cliente est informée.

**Why this priority**: C'est le filtre qui empêche d'offrir une course à quelqu'un qui la refusera nécessairement — chaque offre inutile coûte 40 secondes à la cliente. C'est aussi lui qui protège Yao : on ne lui propose jamais d'avancer plus qu'il ne peut perdre.

**Independent Test**: Peupler un pool avec des coursiers qui échouent chacun sur un seul critère (occupé, mauvais véhicule, à 5 km, plafond trop bas, paire bloquée) et vérifier que la liste des éligibles est exactement celle attendue, critère par critère ; vider la capacité d'avance de tous les coursiers pourtant éligibles par ailleurs et vérifier la bascule en prépaiement notifiée ; vider le pool pour une autre raison et vérifier le passage en file d'attente — sans qu'aucune offre ne soit émise.

**Acceptance Scenarios**:

1. **Given** une commande exigeant un véhicule motorisé, **When** le pipeline évalue un coursier qui n'a déclaré qu'un vélo, **Then** il est écarté, et la raison de l'écart est journalisée.
2. **Given** une commande dont le premier arrêt est à 5 km d'un coursier et le rayon de zone à 4 km, **When** le pipeline évalue, **Then** ce coursier est écarté ; **Given** un coursier à 3,9 km, **Then** il est retenu.
3. **Given** une course dont les articles totalisent 12 000 unités et un coursier dont la grille par note plafonne à 10 000, **When** le pipeline évalue, **Then** il est écarté **même si** son plafond déclaré du jour est de 15 000 — c'est le plus petit des deux qui décide.
4. **Given** une paire bloquée entre Yao et la cliente, **When** le pipeline évalue, **Then** Yao est écarté quelle que soit sa position et son score.
5. **Given** au moins un coursier éligible sur **tous** les critères sauf la capacité d'avance, **When** le pipeline conclut, **Then** la commande **exige un prépaiement mobile money**, la cliente est notifiée avec le motif, et le pipeline reprend dès le paiement confirmé — sans que personne n'avance quoi que ce soit.
6. **Given** un pool vide pour une autre raison (personne en ligne, tous occupés, tous hors rayon), **When** le pipeline conclut, **Then** la commande rejoint la **file d'attente FIFO par âge** et la cliente est informée — le prépaiement n'est pas proposé, il ne changerait rien.
7. **Given** un routage indisponible, **When** le pipeline mesure les distances, **Then** il retombe sur le mode dégradé journalisé et **aucune commande n'est bloquée**.

---

### User Story 3 - Classer les candidats pour que ce soit à la fois rapide et équitable (DSP-03, Priority: P2 — produit : P0)

Parmi les éligibles, le pipeline construit un **classement** : quatre composantes ramenées chacune sur une même échelle, puis pondérées par des poids de zone (par défaut 0,4 pour la proximité, 0,3 pour l'inactivité, 0,2 pour la note, 0,1 pour le taux d'acceptation). La **proximité** s'appuie sur le temps de trajet routier quand il est déjà connu, sinon sur la distance — jamais au prix d'un calcul qui retarderait l'offre. L'**inactivité** est ce qui rend le système vivable : à proximité comparable, celui qui attend depuis le plus longtemps passe devant, et personne ne se retrouve à ne jamais rien recevoir parce qu'un autre est mieux placé. En cas d'égalité parfaite, l'ordre est **tiré au hasard** — aucun favori systématique. Le classement est journalisé de façon auditable, sans jamais exposer où habite la cliente.

**Why this priority**: Sans classement, l'ordre des offres serait arbitraire ; sans la composante d'inactivité, les coursiers les moins bien placés abandonneraient la plateforme. C'est la story qui décide si le réseau de coursiers tient dans le temps.

**Independent Test**: Construire un vivier de candidats égaux hormis une composante à la fois et vérifier que le classement suit cette composante ; changer les poids de la zone et vérifier que l'ordre change en conséquence ; rendre deux candidats parfaitement égaux et vérifier que l'ordre varie d'une évaluation à l'autre ; dérouler 20 dispatches sur 4 coursiers de profils comparables et vérifier qu'aucun n'est laissé de côté.

**Acceptance Scenarios**:

1. **Given** quatre candidats identiques hormis leur distance au premier arrêt, **When** le classement est calculé, **Then** l'ordre suit la proximité.
2. **Given** deux candidats à proximité identique dont l'un est inactif depuis bien plus longtemps, **When** le classement est calculé avec les poids par défaut, **Then** l'inactif passe devant.
3. **Given** un temps de trajet routier déjà connu pour un tronçon, **When** la proximité est mesurée, **Then** c'est le **temps** qui est utilisé ; **Given** un tronçon inconnu, **Then** c'est la **distance**, sans appel de routage supplémentaire par candidat.
4. **Given** des poids de zone modifiés (proximité seule à 1, le reste à 0), **When** le classement est calculé, **Then** il ne dépend plus que de la proximité — le comportement change **sans redéploiement**.
5. **Given** deux candidats de score strictement égal, **When** le classement est calculé plusieurs fois, **Then** leur ordre relatif **varie**.
6. **Given** un coursier sans note (module d'avis non construit), **When** son score est calculé, **Then** la composante de note prend la **valeur neutre** — elle ne l'avantage ni ne le pénalise.
7. **Given** un coursier qui vient d'entrer dans le pool, **When** son inactivité est mesurée, **Then** elle part de son entrée dans le pool, pas de zéro — un nouvel arrivant n'est pas traité comme quelqu'un qui vient de finir une course.
8. **Given** un classement calculé, **When** il est journalisé, **Then** les candidats, leurs composantes et leur score y figurent, et **aucune coordonnée de la cliente** n'y apparaît.

---

### User Story 4 - Une course, un seul preneur — physiquement (DSP-04, Priority: P2 — produit : P0)

Le meilleur candidat reçoit l'offre : plein écran, sonnerie, **compte à rebours de 40 s**, les arrêts dans l'ordre optimisé avec leurs distances, la destination **approximative** — l'adresse exacte n'apparaît qu'après acceptation —, le **gain total** avec son détail, et le **montant à avancer** avec le rappel de son plafond. Un tap suffit pour accepter ou refuser. Pendant tout ce temps, **deux verrous** tiennent, pris ensemble ou pas du tout : le **verrou de commande** — aucune autre offre de cette course n'existe — et le **verrou de coursier** — Yao ne détient qu'une seule offre en vol, toutes commandes confondues, si bien que deux courses prêtes au même instant ne peuvent pas se disputer son écran. Tous deux sont posés en création exclusive, expirent seuls (45 s, soit toujours après le compte à rebours), et rendent la **double acceptation impossible** — si deux coursiers acceptent au même instant, un seul emporte la course, l'autre voit « déjà prise », sans pénalité, et reste dans le pool. Un refus explicite passe immédiatement au suivant sans faire attendre la cliente. Une non-réponse passe aussi au suivant, et les **trois premières du jour ne coûtent rien** à Yao : ni sur son taux d'acceptation, ni en sanction, et son écran le lui dit — « sans pénalité, 1 sur 3 aujourd'hui ».

**Why this priority**: C'est le cœur du module et le point de défaillance le plus grave : une course assignée deux fois, ce sont deux coursiers qui avancent le même argent chez le même vendeur. La garantie doit être structurelle, pas conventionnelle.

**Independent Test**: Offrir une course au meilleur candidat et vérifier le contenu de l'offre, le compte à rebours, l'affectation à l'acceptation ; faire accepter **deux coursiers simultanément** (test de concurrence) et vérifier qu'exactement une affectation existe, que le second reçoit « déjà prise » sans pénalité et reste offreable ; lancer **deux pipelines simultanés sur un seul coursier éligible** et vérifier qu'il ne reçoit qu'une offre et que la seconde commande passe à son candidat suivant ; refuser puis laisser expirer et vérifier le passage au suivant et le compteur de non-réponses non pénalisées.

**Acceptance Scenarios**:

1. **Given** un classement non vide, **When** le pipeline offre la course, **Then** **un seul** coursier — le mieux classé — reçoit une offre portant les arrêts ordonnés et leurs distances, la destination approximative, le gain total détaillé, le montant à avancer avec son plafond, et un compte à rebours.
2. **Given** une offre en vol, **When** le pipeline tente d'en émettre une seconde pour la même commande, **Then** c'est **refusé** — une seule offre en vol par commande.
3. **Given** une offre en vol, **When** deux coursiers l'acceptent **au même instant**, **Then** **exactement une** affectation est créée, le tronc passe en cours et la livraison est assignée une seule fois ; le second reçoit « déjà prise », **sans pénalité**, et reste dans le pool.
4. **Given** une offre en vol, **When** Yao refuse explicitement, **Then** le candidat suivant est sollicité **immédiatement**, sans attendre la fin du compte à rebours.
5. **Given** une offre en vol, **When** le compte à rebours expire, **Then** le candidat suivant est sollicité, et le coursier qui n'a pas répondu **n'est pas re-sollicité pour cette même commande**.
6. **Given** les deux premières non-réponses du jour de Yao, **When** la troisième expire, **Then** aucune des trois n'affecte son taux d'acceptation ni ne déclenche de sanction, et son écran affiche le décompte du jour sans reproche.
7. **Given** la quatrième non-réponse du jour, **When** elle expire, **Then** elle **compte** dans le taux d'acceptation.
8. **Given** une offre en vol chez un coursier dont le réseau tombe, **When** son inscription au pool expire, **Then** l'offre se libère à son échéance et la course repart au candidat suivant — l'expiration du verrou survient **toujours après** la fin du compte à rebours.
9. **Given** un tap d'acceptation rejoué (double tap, reprise réseau), **When** il arrive deux fois, **Then** il produit **une seule** affectation.
10. **Given** deux commandes prêtes au même instant et Yao seul éligible aux deux, **When** les deux pipelines évaluent, **Then** Yao reçoit **une seule** offre — un seul écran, un seul compte à rebours — et la seconde commande passe **immédiatement** à son candidat suivant, ou attend le broadcast s'il n'y en a pas.
11. **Given** l'offre de Yao qui se conclut (acceptation, refus ou non-réponse), **When** elle se conclut, **Then** son verrou de coursier est libéré et il peut recevoir l'offre de la seconde commande.

---

### User Story 5 - Quand la cascade s'essouffle, demander à tout le monde (DSP-05, Priority: P3 — produit : P0)

Après **trois candidats** sollicités sans preneur, ou **120 secondes** de recherche, le pipeline arrête la cascade un-par-un et propose la course à **tous les éligibles** en même temps. Le **premier qui accepte** l'emporte, par le même verrou — les autres voient « déjà prise », sans pénalité. Si personne n'accepte, le pipeline ne s'arrête pas pour autant : il réévalue et continue de chercher jusqu'à l'escalade.

**Why this priority**: La cascade seule laisse une cliente attendre trois fois 40 secondes derrière des coursiers qui ne répondent pas. Le broadcast est la soupape qui transforme trois attentes en une seule course.

**Independent Test**: Laisser trois candidats ne pas répondre et vérifier le basculement en broadcast ; forcer le délai à échoir avant les trois candidats et vérifier le même basculement ; faire accepter deux coursiers en broadcast et vérifier l'unicité du gagnant ; ne laisser personne accepter et vérifier que la recherche continue.

**Acceptance Scenarios**:

1. **Given** trois candidats sollicités sans preneur, **When** le troisième conclut, **Then** la course est proposée **simultanément à tous les éligibles**.
2. **Given** le délai de broadcast atteint alors que seuls deux candidats ont été sollicités, **When** le délai échoit, **Then** le broadcast s'ouvre — les deux conditions sont **alternatives**, pas cumulatives.
3. **Given** un broadcast ouvert, **When** deux coursiers acceptent presque simultanément, **Then** **un seul** emporte la course et les autres reçoivent « déjà prise », sans pénalité.
4. **Given** un coursier devenu occupé entre le début du pipeline et l'ouverture du broadcast, **When** le broadcast est émis, **Then** il ne le reçoit pas — l'éligibilité est **réévaluée** à l'émission.
5. **Given** un coursier qui décide déjà sur l'offre d'une autre commande, **When** un broadcast est émis, **Then** il ne le reçoit pas : un coursier ne détient jamais deux offres, cascade et broadcast confondus, et deux broadcasts concurrents se **sérialisent** au lieu de se disputer les mêmes écrans.
6. **Given** un broadcast que personne n'accepte, **When** il se termine, **Then** le pipeline **poursuit** sa recherche et l'escalade reste en cours de compte.

---

### User Story 6 - Prévenir l'exploitation et la cliente quand l'automatisme n'y arrive pas (DSP-06, Priority: P3 — produit : P0)

Au bout de **5 minutes** sans assignation — que la commande soit passée par la cascade, le broadcast ou la file d'attente —, l'exploitation reçoit une **alerte** destinée à son écran d'opérations, et la cliente une **notification** qui lui offre d'**annuler sans frais**. L'alerte est émise **une seule fois** par commande : une alerte répétée toutes les minutes est une alerte qu'on n'ouvre plus. Et l'escalade **ne stoppe pas** la recherche : le pipeline continue, si bien qu'une course peut encore trouver preneur après avoir été escaladée.

**Why this priority**: C'est le filet de sécurité : la seule story qui garantit qu'aucune commande ne reste indéfiniment silencieuse. Elle vient après le pipeline parce qu'elle mesure son échec.

**Independent Test**: Laisser une commande sans preneur au-delà du seuil et vérifier qu'exactement une alerte d'exploitation et une notification client avec annulation sans frais sont émises ; balayer plusieurs fois et vérifier qu'aucune n'est ré-émise ; vérifier qu'une commande escaladée peut encore être assignée ; vérifier que la cliente peut annuler sans frais depuis cet état.

**Acceptance Scenarios**:

1. **Given** une commande prête à dispatcher, **When** le seuil de zone est franchi sans assignation, **Then** une alerte destinée à l'écran d'opérations et une notification cliente sont émises, la seconde offrant l'**annulation sans frais**.
2. **Given** une commande déjà escaladée, **When** le balayage repasse, **Then** **aucune** nouvelle alerte n'est émise.
3. **Given** une commande escaladée, **When** un coursier accepte enfin, **Then** l'assignation se fait normalement — l'escalade n'était pas un état terminal.
4. **Given** une commande escaladée, **When** la cliente annule, **Then** l'annulation est **sans frais** et personne n'a rien à réclamer.
5. **Given** une commande escaladée depuis la file d'attente et une autre escaladée depuis la cascade, **When** les deux sont comptées, **Then** chacune a produit **exactement une** alerte — le chemin d'arrivée ne change rien.

---

### User Story 7 - Reprendre une course qui n'avance pas (DSP-07, Priority: P4 — produit : P0)

Une course assignée qui **n'avance pas** est reprise automatiquement, sur **deux critères distincts** : aucun **mouvement vers le premier arrêt** dans le délai de zone (5 minutes) — un coursier qui a cessé de publier sa position étant traité comme immobile, puisque c'est exactement le coursier injoignable qu'il s'agit d'attraper —, ou aucun **scan de collecte** au-delà du **temps de préparation annoncé plus 10 minutes**. Le pipeline retire le coursier, **remet la commande en recherche**, trace un **incident** avec son motif, et prévient les deux parties. Le coursier retiré n'est pas re-sollicité pour cette course. Une seule limite, et elle est nette : si Yao a **déjà collecté un arrêt**, il a engagé ses fonds propres — la course n'est **jamais** reprise automatiquement, elle est escaladée à l'exploitation qui décide avec un motif tracé.

**Why this priority**: C'est la story qui évite qu'une commande meure entre les mains d'un coursier injoignable. Elle vient en dernier parce qu'elle réutilise tout le pipeline et qu'elle est la plus dangereuse à automatiser : reprendre une course à un coursier qui a payé le vendeur lui ferait perdre son argent.

**Independent Test**: Assigner une course, laisser le coursier immobile au-delà du délai et vérifier la reprise, l'incident tracé et la re-proposition ; refaire l'essai en le laissant se rapprocher du premier arrêt et vérifier qu'il **n'est pas** repris ; couper ses publications de position et vérifier qu'il **est** repris ; annoncer un temps de préparation, dépasser prépa + 10 min sans scan et vérifier la reprise pour ce motif distinct ; collecter un arrêt puis provoquer l'immobilité et vérifier qu'**aucune** reprise automatique n'a lieu mais qu'une escalade est émise.

**Acceptance Scenarios**:

1. **Given** une course assignée sans aucun arrêt collecté, **When** le délai de zone s'écoule sans que le coursier se soit rapproché du premier arrêt au-delà du seuil de déplacement de la zone, **Then** le coursier est retiré, la commande **repart en recherche**, un incident portant le motif est tracé, et les deux parties sont prévenues.
2. **Given** une course assignée dont le coursier **se rapproche** du premier arrêt sans y être encore arrivé, **When** le délai de zone s'écoule, **Then** la course **n'est pas** reprise — un embouteillage n'est pas un abandon ; **Given** un coursier qui a **cessé de publier** sa position, **Then** elle **est** reprise.
3. **Given** une course dont le temps de préparation annoncé est de 15 minutes, **When** aucun scan de collecte n'est survenu 25 minutes après l'assignation, **Then** la course est reprise pour ce motif distinct.
4. **Given** une course reprise, **When** le pipeline re-propose, **Then** le coursier retiré **n'est pas** re-sollicité pour cette commande.
5. **Given** une course dont **au moins un arrêt est collecté**, **When** la course cesse d'avancer, **Then** **aucune reprise automatique** n'a lieu : une escalade est émise vers l'exploitation, qui tranche avec un motif tracé.
6. **Given** un balayage qui repasse sur une course déjà reprise, **When** il l'évalue, **Then** elle n'est pas reprise une seconde fois pour le même motif — pas de reprise en boucle.
7. **Given** une course reprise puis réassignée à un autre coursier, **When** la nouvelle assignation est écrite, **Then** le devis figé n'est pas recalculé et la cliente ne paie pas plus qu'annoncé.

---

### Edge Cases

- **Le pool contient un coursier que la base ne reconnaît plus** (rôle suspendu, compte bloqué depuis sa dernière publication) : l'éligibilité se vérifie contre la base, jamais contre le seul pool — le pool ne peut pas rendre éligible quelqu'un qui ne l'est pas.
- **Deux commandes prêtes en même temps et un seul coursier éligible** : le verrou de coursier fait que la seconde commande **n'émet pas** d'offre vers lui et passe à son candidat suivant. Aucun coursier ne voit deux écrans d'offre, et aucune commande ne brûle un candidat pour une offre qu'il ne pouvait pas honorer.
- **Le pipeline s'interrompt alors qu'un verrou de coursier est posé** : les deux verrous expirent d'eux-mêmes ; un incident d'exécution ne peut pas geler un coursier au-delà de l'expiration de l'offre.
- **Un coursier accepte au moment exact où le verrou expire** : l'acceptation est refusée sans ambiguïté et sans pénalité, et la course reste dispatchable.
- **Le coursier accepte alors qu'il vient de sortir du pool** (heartbeat perdu juste avant son tap) : l'acceptation reste valide s'il est encore éligible en base — sortir du pool empêche de **recevoir** une offre, pas d'**honorer** celle qu'on a déjà.
- **Le montant des articles change après l'offre** (substitution) : la capacité d'avance a été vérifiée à l'offre ; un dépassement postérieur relève de la substitution (cycle 008) et n'annule pas l'affectation.
- **Le plafond du jour est abaissé par le coursier alors qu'une offre est en vol** : l'offre en cours reste valide au plafond qui a servi à la calculer ; la nouvelle valeur s'applique aux offres suivantes.
- **Aucun type de transport actif ne couvre la commande** dans la zone : aucun coursier n'est éligible pour une raison structurelle — la commande part en file d'attente et l'écart est journalisé, jamais silencieux.
- **Le routage est indisponible pendant tout le pipeline** : la proximité retombe sur la distance dégradée journalisée, le classement reste calculable, aucune commande n'est bloquée.
- **Le pool est perdu pendant qu'une offre est en vol** : l'offre suit son verrou, qui est éphémère lui aussi — au pire la course repart en recherche, jamais en double assignation.
- **Une commande escaladée est annulée par la cliente pendant qu'une offre est en vol** : l'annulation gagne ; le coursier qui accepte ensuite reçoit un refus explicite, sans pénalité.
- **Un même coursier est le seul éligible et refuse trois fois** : la cascade est épuisée, le broadcast ne trouve personne d'autre, l'escalade survient — le refus répété ne bloque pas la commande.
- **L'horloge du téléphone est en avance** : les délais du pipeline se comptent sur l'horloge serveur ; un horodatage client ne raccourcit jamais un compte à rebours.

## Requirements *(mandatory)*

### Functional Requirements

**Pool temps réel (DSP-01)**

- **FR-001**: Un coursier en ligne DOIT publier sa position à la **période définie par la zone** ; chaque publication DOIT le (ré)inscrire au pool des coursiers offreables et **repousser la durée de vie** de son inscription.
- **FR-002**: L'inscription au pool DOIT porter, pour chaque coursier : sa **position**, son **statut de disponibilité**, ses **capacités déclarées** (au MVP : types de véhicule), la **note retenue**, son **plafond d'avance du jour** et l'identifiant de sa **course active** s'il en a une.
- **FR-003**: Une absence de publication au-delà de la **durée de vie de l'inscription** (paramètre de zone, dérivé de plusieurs périodes manquées) DOIT faire **sortir le coursier du pool** ; il ne DOIT alors recevoir **aucune** offre.
- **FR-004**: Un coursier sorti du pool par silence DOIT en être informé par un état explicite (clé i18n de reconnexion), jamais par une attente silencieuse.
- **FR-005**: Un passage **hors ligne volontaire** DOIT retirer le coursier du pool **immédiatement**, sans attendre l'expiration.
- **FR-006**: Le pool DOIT être interrogeable **par zone** et **par rayon autour d'un point**.
- **FR-007**: Un coursier ayant une **course active** NE DOIT PAS être offreable (aucune superposition de deux commandes au MVP).
- **FR-008**: Le pool NE DOIT contenir **aucune donnée métier durable** : sa perte totale NE DOIT entraîner **aucune** perte de commande, **aucune** double affectation, et **aucune** intervention humaine ; il DOIT se reconstituer par les publications suivantes.
- **FR-009**: L'**éligibilité** DOIT toujours être confirmée contre les données durables (rôle, suspension, blocage, course active) ; le pool seul NE DOIT jamais suffire à rendre un coursier éligible.
- **FR-010**: Le coursier DOIT pouvoir **déclarer son plafond d'avance du jour** ; le plafond retenu DOIT être le **minimum** entre ce plafond déclaré et celui que sa note autorise, et il DOIT voir lequel s'applique.
- **FR-011**: Le plafond déclaré DOIT être **journalier** : il NE DOIT PAS se reporter tacitement d'un jour sur l'autre (jour civil de la zone).

**Éligibilité (DSP-02)**

- **FR-015**: Le pipeline DOIT être déclenché **automatiquement**, sans intervention humaine, à la mise à disposition d'une commande (événement de commande prête à dispatcher) **et** à chaque relance : refus, non-réponse, fin de broadcast, réassignation, reprise depuis la file d'attente, confirmation d'un prépaiement.
- **FR-016**: Le filtre DOIT écarter tout coursier **hors ligne** ou **déjà en course**.
- **FR-017**: Le filtre DOIT écarter tout coursier dont les **capacités déclarées ne couvrent pas** l'ensemble des **capacités requises** par la commande.
- **FR-018**: Le filtre de capacités DOIT être **générique** : l'ajout d'une famille de capacités (par exemple une qualification d'artisan) NE DOIT exiger **ni changement de contrat, ni refonte** du filtre. Au MVP, une seule famille est active : le **type de véhicule**.
- **FR-019**: Les capacités d'un coursier DOIVENT être lues de ses **véhicules déclarés** existants ; ce cycle NE DOIT PAS en créer un second stockage.
- **FR-020**: La **capacité requise** d'une commande DOIT être **persistée et lisible** sur la commande — elle n'existe aujourd'hui que dans la charge utile d'un événement.
- **FR-021**: Le filtre DOIT écarter tout coursier dont la distance au **premier arrêt de collecte** dépasse le **rayon de la zone**. Cette distance NE DOIT jamais être mesurée jusqu'à l'adresse de la cliente.
- **FR-022**: Le filtre DOIT écarter tout coursier dont la **capacité d'avance** est insuffisante : le **montant total des articles, tous arrêts confondus**, DOIT être ≤ **min(plafond de la grille par note, plafond déclaré du jour)**.
- **FR-023**: La grille des plafonds d'avance par note DOIT être un **paramètre de zone** (défauts : 5 000 / 10 000 / 15 000 unités selon la note) ; l'écran d'édition appartient à la console admin, non construite ici.
- **FR-024**: En **absence de note** (module d'avis non construit), le plafond retenu DOIT être celui du **palier d'entrée** — le plus bas.
- **FR-025**: Le filtre DOIT écarter tout coursier formant une **paire bloquée** avec la cliente ou avec l'un des vendeurs de la course, quelles que soient sa position et son score.
- **FR-026**: Si le **seul** critère bloquant est la capacité d'avance — c'est-à-dire s'il existe au moins un coursier éligible sur **tous** les autres critères —, la commande DOIT **basculer en prépaiement mobile money**, et la cliente DOIT être notifiée **avec le motif**.
- **FR-027**: Après confirmation du prépaiement, le pipeline DOIT **reprendre** sans appliquer le critère de capacité d'avance : plus personne n'avance rien.
- **FR-028**: Si aucun coursier n'est éligible pour **toute autre raison**, la commande DOIT rejoindre la **file d'attente FIFO par âge** existante, la cliente DOIT être informée, et le prépaiement NE DOIT PAS être proposé.
- **FR-029**: Chaque écart DOIT être **journalisé avec son motif** ; un pipeline qui ne trouve personne NE DOIT jamais être silencieux sur la raison.
- **FR-030**: L'indisponibilité du routage NE DOIT **jamais** bloquer une commande : le mode dégradé journalisé s'applique.

**Scoring (DSP-03)**

- **FR-033**: Le score d'un candidat DOIT être la **somme pondérée** de quatre composantes **normalisées sur une même échelle** : proximité, inactivité, note, taux d'acceptation.
- **FR-034**: Les **quatre poids** DOIVENT être des paramètres de zone (défauts 0,4 / 0,3 / 0,2 / 0,1) ; leur cohérence DOIT être vérifiée au chargement, et leur modification DOIT changer le comportement observable **sans redéploiement**.
- **FR-035**: La **proximité** DOIT s'appuyer sur le **temps de trajet routier** quand il est déjà connu, et sur la **distance** sinon ; elle NE DOIT PAS déclencher un calcul de routage par candidat qui retarderait l'offre.
- **FR-036**: L'**inactivité** DOIT se compter depuis la fin de la dernière course du coursier ou, à défaut, depuis son **entrée dans le pool**, et être normalisée par un plafond de zone.
- **FR-037**: La **note** DOIT être lue quand elle existe ; en son absence, la composante DOIT prendre une **valeur neutre** qui n'avantage ni ne pénalise.
- **FR-038**: Le **taux d'acceptation** DOIT être calculé sur une **fenêtre glissante de zone** à partir des offres émises par ce module ; un coursier sans offre sur la fenêtre DOIT recevoir la valeur neutre.
- **FR-039**: À **score égal**, l'ordre DOIT être **aléatoire** — aucun favori systématique.
- **FR-040**: Le classement DOIT être **journalisé de façon auditable** (candidats, composantes, score, écarts et leurs motifs) **sans** aucune coordonnée de la cliente.

**Offre en cascade et verrou (DSP-04)**

- **FR-043**: Le pipeline DOIT offrir la course au **mieux classé**, à **un seul coursier à la fois** pendant la phase de cascade.
- **FR-044**: Une seule offre DOIT pouvoir être en vol **par commande**, garantie par un **verrou de commande** posé en **création exclusive** (l'échec de pose est la garantie, pas une lecture préalable) portant la commande et le coursier, et assortie d'une **expiration automatique**.
- **FR-045**: L'expiration du verrou DOIT être **strictement postérieure** à la fin du compte à rebours (défauts de zone : 45 s contre 40 s) — le verrou survit toujours au timer.
- **FR-046**: L'offre DOIT présenter : les **arrêts dans l'ordre optimisé** avec leurs distances, la **destination approximative** (l'adresse exacte n'apparaissant qu'**après** acceptation), le **gain total** avec son détail, le **montant total à avancer** avec le rappel du plafond applicable, et le **compte à rebours**.
- **FR-047**: Le coursier DOIT pouvoir **accepter ou refuser en un tap**.
- **FR-048**: L'acceptation DOIT créer l'affectation **par le contrat offert par le module commandes** (livraison assignée, tronc en cours), jamais par une écriture directe.
- **FR-049**: Une **double acceptation DOIT être impossible** : deux acceptations concurrentes DOIVENT produire **exactement une** affectation ; le second coursier DOIT recevoir « déjà prise », **sans pénalité**, et **rester** dans le pool.
- **FR-050**: Un **refus explicite** DOIT solliciter le candidat suivant **immédiatement**, sans attendre la fin du compte à rebours.
- **FR-051**: Une **non-réponse** DOIT solliciter le candidat suivant, et le coursier concerné NE DOIT PAS être re-sollicité **pour la même commande**.
- **FR-052**: Les **N premières non-réponses du jour** (paramètre de zone, défaut 3) NE DOIVENT **ni** compter dans le taux d'acceptation **ni** entraîner de sanction ; au-delà, elles comptent.
- **FR-053**: Le coursier DOIT voir, sur une non-réponse non pénalisée, un message **neutre** portant son décompte du jour — jamais un reproche.
- **FR-054**: Une action d'acceptation ou de refus **rejouée** (double tap, reprise réseau, drain de file hors ligne) DOIT être **idempotente** : une seule affectation, un seul refus.
- **FR-055**: Tous les délais du pipeline DOIVENT se compter sur l'**horloge serveur** ; un horodatage client NE DOIT jamais raccourcir un compte à rebours.
- **FR-056**: Une seule offre DOIT pouvoir être en vol **par coursier**, **toutes commandes confondues**, garantie par un **verrou de coursier** posé **atomiquement avec celui de la commande** — les deux ensemble, ou aucun. Un coursier NE DOIT jamais recevoir deux offres concurrentes.
- **FR-057**: Un pipeline qui n'obtient pas le verrou d'un coursier DOIT passer **immédiatement** à son candidat suivant — ou attendre le broadcast s'il n'y en a pas — sans attendre la conclusion de l'offre concurrente. Les deux verrous DOIVENT être **libérés à la conclusion** de l'offre (acceptation, refus, non-réponse) et **expirer d'elles-mêmes** en cas d'interruption : aucun incident d'exécution NE DOIT geler un coursier au-delà de l'expiration.

**Broadcast (DSP-05)**

- **FR-058**: Après **N candidats sollicités** sans preneur **OU** après le **délai de broadcast** écoulé depuis le début du pipeline (paramètres de zone, défauts 3 et 120 s), la course DOIT être proposée **simultanément à tous les éligibles**. Les deux conditions DOIVENT être **alternatives**.
- **FR-059**: L'éligibilité DOIT être **réévaluée à l'émission** du broadcast : un coursier devenu occupé, hors pool, hors rayon **ou détenant déjà une offre en vol** NE DOIT PAS le recevoir.
- **FR-060**: Le **premier accepteur** DOIT emporter la course, par le **même verrou de commande** ; les autres DOIVENT recevoir « déjà prise », **sans pénalité**.
- **FR-061**: Un broadcast sans preneur NE DOIT PAS arrêter le pipeline : la recherche DOIT **continuer** jusqu'à l'escalade et au-delà.
- **FR-062**: L'invariant « **une offre en vol par coursier** » (FR-056) DOIT s'appliquer **aussi au broadcast** : le broadcast prend le verrou de coursier de chacun de ceux qu'il atteint et le libère à sa conclusion. Deux broadcasts concurrents se **sérialisent** donc naturellement — le second n'atteint personne et repart au tour suivant — plutôt que d'afficher deux écrans d'offre au même coursier.

**Escalade (DSP-06)**

- **FR-064**: Une commande **non assignée** au-delà du **seuil d'escalade de la zone** DOIT produire une **alerte destinée à l'écran d'opérations** et une **notification à la cliente**.
- **FR-065**: La notification cliente DOIT offrir l'**annulation sans frais**.
- **FR-066**: L'alerte DOIT être émise **exactement une fois par commande**, quel que soit le chemin par lequel la commande a atteint le seuil (file d'attente, cascade, broadcast).
- **FR-067**: L'escalade NE DOIT PAS être un état terminal : le pipeline DOIT **continuer** à chercher, et une commande escaladée DOIT pouvoir être assignée normalement ensuite.
- **FR-068**: Le seuil d'escalade DOIT être le **paramètre de zone existant** ; aucun doublon NE DOIT être créé.

**Réassignation automatique (DSP-07)**

- **FR-071**: Une course assignée **sans mouvement vers son premier arrêt** au-delà du délai de zone DOIT être **reprise automatiquement**. « Sans mouvement » DOIT se constater sur les **positions publiées** : un rapprochement du premier arrêt **inférieur au seuil de déplacement de la zone** sur la fenêtre. La dimension d'état est portée par le critère distinct de FR-072 — les deux sont **deux critères**, pas deux lectures d'un seul.
- **FR-072**: Une course dont **aucun scan de collecte** n'est survenu au-delà du **temps de préparation annoncé plus la marge de zone** DOIT être **reprise automatiquement**, pour un motif distinct du précédent.
- **FR-073**: Une reprise DOIT : **retirer** le coursier de la course, **remettre** la commande en recherche, **tracer un incident** avec son motif, et **prévenir** le coursier retiré comme la cliente.
- **FR-074**: Le coursier retiré NE DOIT PAS être re-sollicité **pour cette commande**.
- **FR-075**: Une course dont **au moins un arrêt est collecté** NE DOIT **jamais** être reprise automatiquement : elle DOIT être **escaladée à l'exploitation**, qui tranche avec un motif tracé — le coursier a engagé ses fonds propres.
- **FR-076**: Une même course NE DOIT PAS être reprise deux fois pour le même motif (pas de reprise en boucle).
- **FR-077**: Une réassignation NE DOIT **pas** recalculer le devis figé : la cliente ne paie pas plus qu'annoncé, et la part promise au coursier reste celle du devis.
- **FR-078**: L'**absence de position récente** sur la fenêtre DOIT compter comme une absence de mouvement : un coursier assigné qui ne publie plus rien est au moins aussi indisponible qu'un coursier immobile, et c'est précisément le coursier injoignable que la reprise doit attraper.

**Paramètres de zone (transverse)**

- **FR-080**: **Tous** les paramètres du pipeline DOIVENT être des **paramètres de zone hérités**, seedés pour Tiassalé à leurs valeurs par défaut, et **aucun** NE DOIT être en dur — **18 paramètres** : durée de vie de l'inscription au pool, rayon, grille des plafonds d'avance par note, poids de scoring (×4), plafond de normalisation de l'inactivité, fenêtre du taux d'acceptation, valeur neutre de note, compte à rebours d'offre, expiration des verrous, nombre de non-réponses non pénalisées par jour, nombre de candidats avant broadcast, délai de broadcast, délai de réassignation sans mouvement, **seuil de déplacement minimal**, marge de réassignation sans scan.
- **FR-081**: Les paramètres **déjà existants** — période de publication de position et seuil d'escalade — DOIVENT être **réutilisés**, jamais dupliqués.
- **FR-082**: Toute modification d'un paramètre DOIT changer le comportement observable **sans redéploiement**.

**Argent, événements, confidentialité (transverse)**

- **FR-085**: Tous les montants comparés DOIVENT être des **entiers en unités mineures** accompagnés du **code ISO 4217** de la zone ; aucun flottant, aucune conversion.
- **FR-086**: Aucune bascule de paiement NE DOIT ouvrir un chemin de **paiement partiel** : le total est dû en une fois, en cash ou en mobile money.
- **FR-087**: Toute décision du pipeline — inscription, écart, classement, offre, refus, non-réponse, affectation, broadcast, escalade, reprise — DOIT écrire un **événement dans le journal transactionnel**, déclaré dans la taxonomie **avant** implémentation.
- **FR-088**: **Aucun** événement, journal ou charge utile de ce module NE DOIT porter de **coordonnée de la cliente**, ni de **numéro de téléphone**.
- **FR-089**: Toute chaîne destinée à l'utilisateur DOIT être une **clé i18n fr** ; aucune chaîne en dur.
- **FR-090**: Ce cycle NE DOIT construire **ni** l'anti-abus (suspension automatique après annulations post-acceptation) **ni** la superposition de deux commandes sur un même coursier : tous deux explicitement hors périmètre.

**Surface applicative**

- **FR-093**: La portée applicative de ce cycle DOIT couvrir le domaine, l'API et, dans l'app coursier, **l'écran d'offre** (maquette K2 : compte à rebours, arrêts ordonnés et distances, destination approximative, gain détaillé, montant à avancer, accepter/refuser en un tap, état « déjà prise — sans pénalité ») **et la tranche de disponibilité dont le pool dépend** : mise en ligne, publication de position à la période de zone, déclaration du plafond du jour, état de reconnexion. Le **bandeau de gains du jour** et les affinages de l'écran d'offre restent aux stories du module coursier.
- **FR-094**: L'offre DOIT être émise par un **contrat d'émission** portant ses canaux et ses clés i18n, que le module de notifications branchera **sans changement de contrat** ; tant qu'il n'existe pas, l'app DOIT pouvoir **récupérer son offre courante**. Le push haute priorité et la sonnerie prolongée NE DOIVENT PAS être construits ici : ils appartiennent à une story distincte de la même tranche.
- **FR-095**: Les surfaces coursier construites ici DOIVENT suivre la **référence visuelle unique** du projet — les maquettes K1/K2 pour la cible, les jetons de design pour les valeurs exactes — et présenter **une seule identité** sur les deux plateformes mobiles ; les exports HTML de référence NE DOIVENT servir **qu'à des mesures**, jamais de structure à transposer.
- **FR-096**: L'**écran d'opérations** de la console admin NE DOIT PAS être construit ici — la console admin appartient à une tranche postérieure : l'alerte d'escalade, l'incident de réassignation et la liste des courses non assignées sont posés comme contrats et exercés par API.

### Key Entities

- **Inscription au pool** : un coursier offreable à un instant donné — position, statut, capacités déclarées, note retenue, plafond du jour, course active éventuelle, durée de vie. Éphémère et reconstructible : ne porte jamais de vérité métier.
- **Plafond d'avance du jour** : montant déclaré par le coursier pour la journée, borné par la grille par note. Journalier, jamais reporté.
- **Capacité** : une exigence qu'une commande pose et qu'un coursier couvre ou non. Famille + valeur ; au MVP une seule famille (type de véhicule), le modèle en accepte d'autres sans refonte.
- **Candidat évalué** : un coursier retenu par le filtre, avec ses quatre composantes normalisées, son score et son rang — ou écarté, avec le motif de l'écart.
- **Offre** : proposition d'une course à un coursier — commande, coursier, échéance du compte à rebours, contenu présenté (arrêts, gain, montant à avancer), issue (acceptée, refusée, non répondue, déjà prise), et rang dans la cascade ou appartenance au broadcast.
- **Verrou de commande** : exclusivité éphémère portant la commande et son destinataire, posée en création exclusive et expirant seule. C'est lui, et lui seul, qui rend la double acceptation impossible.
- **Verrou de coursier** : exclusivité éphémère portant le coursier, posée atomiquement avec le précédent. C'est lui qui garantit qu'un seul écran d'offre s'affiche à la fois, cascade et broadcast confondus.
- **Compteur de non-réponses du jour** : par coursier et par jour, sert la franchise des N premières non-réponses.
- **Taux d'acceptation** : agrégat par coursier sur une fenêtre glissante, alimenté par les issues d'offre de ce module.
- **Alerte d'escalade** : commande, âge, seuil franchi, chemin d'arrivée. Une par commande, destinée à l'écran d'opérations non construit.
- **Incident de réassignation** : commande, coursier retiré, motif (sans progression / sans scan), horodatage. Lu plus tard par la caisse et les incidents coursier.
- **Paire bloquée** : couple (coursier, client) ou (coursier, vendeur) exclu du dispatch. Consommée derrière un contrat ; son enregistrement appartient au module coursier.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: **Aucune** commande n'est jamais assignée à deux coursiers : sur un test de concurrence répété (acceptations simultanées, y compris en broadcast), **exactement une** affectation existe, **100 %** du temps.
- **SC-002**: Une commande créée dans une zone où au moins un coursier éligible est en ligne reçoit un coursier assigné en **moins de 2 minutes** dans **95 %** des cas.
- **SC-003**: Un coursier silencieux au-delà de la durée de vie de son inscription ne reçoit **plus aucune** offre (**100 %**), et son app le lui indique explicitement.
- **SC-004**: Après une **perte totale** des données temps réel, **aucune** commande n'est perdue, **aucune** n'est doublement assignée, et le service reprend en **moins de deux périodes de publication** sans intervention humaine.
- **SC-005**: Le coursier décide en **un tap** avant la fin du compte à rebours ; les verrous de l'offre expirent **toujours après** ce compte à rebours — **jamais l'inverse**, sur l'ensemble des cas testés.
- **SC-006**: **100 %** des commandes non assignées au seuil de zone produisent **exactement une** alerte d'exploitation et **une** notification cliente offrant l'annulation sans frais — quel que soit leur chemin d'arrivée.
- **SC-007**: **Équité** : sur 20 dispatches consécutifs dans une zone à 4 coursiers de profils comparables, **chacun** est sollicité au moins **3 fois** — aucun coursier n'est structurellement laissé de côté.
- **SC-008**: **Aucun** paramètre du pipeline n'est en dur : les **18 paramètres** listés changent le comportement observable par simple modification de la configuration de zone, **sans redéploiement**.
- **SC-009**: Les **3 premières** non-réponses du jour n'altèrent **ni** le taux d'acceptation **ni** l'éligibilité, et ne déclenchent **aucune** sanction ; la 4ᵉ compte.
- **SC-010**: Une course assignée qui n'avance pas est reprise et re-proposée en **moins de 6 minutes**, avec un incident tracé et les deux parties prévenues ; une course dont un arrêt est collecté n'est **jamais** reprise automatiquement (**0 %**).
- **SC-011**: **Aucun** événement, journal ou charge utile du module ne contient de coordonnée de la cliente ni de numéro de téléphone — vérifié sur la totalité des événements déclarés.
- **SC-012**: Une commande dont le **seul** obstacle est la capacité d'avance bascule en prépaiement notifié dans **100 %** des cas, sans qu'aucun chemin de paiement partiel n'existe ; une commande sans éligible pour une autre raison rejoint la file d'attente dans **100 %** des cas.
- **SC-013**: **Toutes** les décisions du pipeline (inscription, écart, classement, offre, issue, affectation, broadcast, escalade, reprise) sont couvertes par un test d'intégration, et **chaque** motif d'écart d'éligibilité a le sien.
- **SC-014**: **Aucun** coursier ne détient jamais deux offres en vol : sur deux pipelines lancés simultanément avec un seul coursier éligible, il reçoit **exactement une** offre (**100 %**) et la seconde commande passe à son candidat suivant sans attendre — cascade et broadcast confondus.
- **SC-015**: Un coursier assigné qui **se rapproche** de son premier arrêt n'est **jamais** repris automatiquement (**0 %**) ; un coursier immobile ou dont les positions ont cessé l'est **dans tous les cas** au-delà du délai de zone.

## Assumptions

- **Portée applicative** : le domaine, l'API, l'**écran d'offre** et la **tranche de disponibilité** de l'app coursier (mise en ligne, publication de position, plafond du jour, état de reconnexion) sont livrés. L'**écran d'opérations admin** (tranche postérieure) et l'**app cliente** ne sont pas construits : leurs surfaces sont exercées par API, par événements et par des doubles, comme les cycles 006, 007 et 008 l'ont fait pour les modules non encore construits.
- **Le canal de l'offre reste celui d'une autre story** : ce cycle pose le contrat d'émission avec ses canaux et ses clés i18n, et l'app **va chercher son offre courante**. Le push haute priorité et la sonnerie prolongée arrivent avec la story de notifications de la même tranche, sans changement de contrat — donc, en démonstration, un téléphone en veille ne sonne pas encore.
- **Une seule offre en vol par coursier**, toutes commandes confondues, garantie par un verrou de coursier pris atomiquement avec celui de la commande. Conséquence assumée : une commande peut **sauter un candidat pourtant éligible** parce qu'il décide déjà sur une autre course, et deux broadcasts concurrents se **sérialisent**. C'est le prix d'un écran d'offre plein qui ne peut afficher qu'un compte à rebours.
- **« Sans mouvement » se mesure sur les positions publiées**, avec un **seuil de déplacement minimal** de zone dimensionné au-dessus du bruit GPS ; l'**absence de position récente** compte comme une absence de mouvement, puisque c'est le coursier injoignable que la reprise doit attraper. La dimension d'état est portée par le critère distinct « sans scan ».
- **L'acceptation d'une offre n'est pas une action de la file hors-ligne** : elle reste néanmoins idempotente pour couvrir le double tap et la reprise réseau immédiate.
- **La note du coursier n'existe pas** : le module d'avis n'est pas construit et le cycle 008 a explicitement renvoyé `coursier.note` à AVI. Absence de note = **palier d'entrée** de la grille pour le plafond d'avance (« plafonds bas puis relevés avec les notes », cadrage §7.5), **valeur neutre** pour la composante de score.
- **Les paires bloquées** (module coursier, P1, non construit) sont consommées derrière un contrat et exercées par un double : l'exclusion est vérifiable au niveau du domaine sans que ce cycle crée le stockage des paires.
- **Le plafond d'avance déclaré du jour** est fourni par le coursier depuis la tranche de disponibilité construite ici ; la donnée et son plafonnement par la grille appartiennent à ce cycle, faute de quoi l'éligibilité serait indécidable.
- **La grille des plafonds d'avance par note** est un paramètre de zone (défauts 5 000 / 10 000 / 15 000 unités) ; son **écran d'édition** appartient à la console admin, hors périmètre.
- **Le seuil d'escalade et la période de publication de position sont réutilisés tels quels** du cycle 008 (300 s et 30 s) — aucun doublon de paramètre n'est créé. La **durée de vie de l'inscription au pool** est en revanche nouvelle : elle dérive de plusieurs périodes manquées.
- **La capacité requise d'une commande est ajoutée en donnée persistée** : elle n'existe aujourd'hui que dans la charge utile d'un événement, et le filtre d'éligibilité a besoin de la lire sur la commande.
- **Le rayon se mesure jusqu'au premier arrêt de collecte**, position d'un site vendeur (donnée professionnelle), jamais jusqu'à l'adresse de la cliente — c'est ce que le contrat offert par le cycle 008 expose délibérément, par minimisation des données.
- **Les temps de trajet routiers ne sont lus que s'ils sont déjà connus** : le pipeline n'engage aucun calcul de routage par candidat, sous peine de retarder l'offre. Le mode dégradé journalisé s'applique sinon, et aucune commande n'est bloquée par le routage.
- **Une nouvelle transition d'état est nécessaire** sur le tronc de commande pour la bascule prépaiement après création (aujourd'hui la table fermée n'autorise l'attente de paiement qu'à la création) ; elle s'ajoute par migration et par ligne de table, sans réécrire l'existant.
- **La réassignation automatique s'arrête à la première collecte** : au-delà, le coursier a engagé ses fonds propres et « le coursier ne perd jamais » (cadrage §7.5) interdit qu'un automatisme lui retire une marchandise payée — l'exploitation tranche.
- **Le stacking de deux commandes** sur un même coursier et l'**anti-abus** (suspension automatique après annulations post-acceptation, P1) sont explicitement **hors périmètre** ; les compteurs d'issues d'offre que ce cycle construit pour le scoring suffiront à l'anti-abus sans refonte.
- **Les seuils numériques cités** (4 km, 40 s, 45 s, 3 candidats, 120 s, 5 min, prépa + 10 min, poids 0,4/0,3/0,2/0,1, 3 non-réponses franches) sont les **valeurs par défaut de zone** du « Récapitulatif des paramètres de zone » — toutes éditables, aucune en dur.
- **L'affectation passe par le contrat offert par le module commandes** ; aucune écriture directe en base, sous peine de laisser le tronc dans un état qui fait ensuite refuser la remise.
