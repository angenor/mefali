# Feature Specification: QR prestataire, plaque et scans de collecte

**Feature Branch**: `006-qr-plaque-collecte`

**Created**: 2026-07-22

**Status**: Draft

**Input**: User description: "Lis docs/user-stories-v2.md, module QRC — QR & traçabilité, et docs/cadrage-v5.md section §5.3. Fonctionnalité : QR prestataire, plaque et scans de collecte. Périmètre : QRC-01, QRC-02, QRC-03, QRC-04 — critères tels quels. QR encodant https://mefali.com/v/{vendor_id}?t={jeton HMAC révocable} + code de secours à 4 chiffres propre au prestataire ; PDF de plaque (MinIO) téléchargeable depuis l'admin ; scan en course PAR ARRÊT : correspondance prestataire/arrêt, GPS < 100 m (paramétrable), horodatage serveur → arrêt COLLECTÉ (+ photo si la politique résolue l'exige : prestataire > catégorie > défaut de zone, forcée au-dessus d'un seuil de montant) ; toutes les collectes faites → commande EN_LIVRAISON ; révocation immédiate à la suspension ; mode dégradé : saisie du code 4 chiffres (confirmation locale comparée au prestataire de l'arrêt — PAS un identifiant global), géoloc toujours exigée, 3 essais max, incident « plaque à remplacer » créé. Hors périmètre : rien de plus — le scan hors contexte (fiche publique) est implémenté au cycle WEB, prévois seulement l'endpoint de résolution du jeton. Personas : Yao, Admin. Points d'attention : les jetons sont révocables côté serveur sans changer la plaque physique ; maquette de référence : docs/design/png/K3."

## Clarifications

### Session 2026-07-22

- Q: Les docs placent le modèle `livraison → segment → arrêt` dans CMD (`docs/user-stories-v2.md` §CMD « Structure » ; `docs/cadrage-v5.md` §7.3), mais CMD n'est pas construit. Que livre ce cycle pour rendre le scan de collecte démontrable ? → A: Ce cycle introduit la **structure d'arrêt-collecte documentée** (prestataire, scan, photo, montant, statut {à collecter, collecté, indisponible}) comme socle que CMD étendra, et **simule la course active et l'affectation dans les tests** — même patron que le cycle 005. QRC n'y pose que la transition **COLLECTÉ** : le statut `indisponible` relève de CMD-06, les états de suivi `EN_ROUTE_ARRÊT`/`ARRIVÉ` de DSP/CRS.
- Q: Quand créer l'incident « plaque à remplacer » (les docs disent « automatiquement » sans préciser le moment — `docs/cadrage-v5.md` §5.3, QRC-04) ? → A: **Dès le basculement en mode dégradé** (QR déclaré illisible), **une seule fois par arrêt** — le signal décrit la plaque physiquement abîmée, établi que le code réussisse ou non.
- Q: Qu'advient-il d'une collecte confirmée hors-ligne puis **refusée à la synchronisation** (prestataire suspendu entre-temps, distance recalculée hors seuil côté serveur — cas absent des docs) ? → A: L'arrêt **repasse « à collecter »** et le coursier est **notifié du motif** ; il re-collecte ou escalade. Aucune collecte invalide côté serveur n'apparaît COLLECTÉE à tort.

### Session 2026-07-23

- Q: `/speckit-analyze` (I1) — la spec disait « la **commande** passe à EN_LIVRAISON », alors que le plan/data-model portent cet état sur le composant `livraison` (le tronc `commande` doit rester sans champ logistique). Comment lever la contradiction ? → A: EN_LIVRAISON est l'état du **composant `livraison`** de la commande (constitution II). FR-003, FR-018, SC-005 et les scénarios d'US2 sont reformulés « la livraison passe à EN_LIVRAISON » ; le plan (R8) fait foi.

## User Scenarios & Testing *(mandatory)*

Personas de ce cycle : **Yao (coursier)** — livreur à moto ou à vélo, smartphone modeste, réseau intermittent sur le terrain, collecte à plusieurs étals avant de livrer ; **Admin (toi)** — fondateur, seul au lancement, imprime les plaques, les remet aux prestataires agréés et suspend ceux qui ne tiennent pas la charte.

Priorités produit : les quatre stories QRC-01 → QRC-04 sont toutes **P0** dans `docs/user-stories-v2.md` (QRC-01/02 en tranche T1, QRC-03/04 en tranche T2). Les priorités P1→P2 ci-dessous sont l'ordre de livraison interne au cycle (dépendances), pas une hiérarchie produit.

### Ce que ce cycle NE construit PAS parce que c'est déjà là (cycle 005)

L'identité de plaque existe déjà. Le prestataire **porte** depuis son agrément un jeton signé (HMAC, auto-porteur, vérifiable hors base) et un code de secours à quatre chiffres ; la validité du jeton **dérive** de l'état d'agrément (suspendu → invalide immédiatement ; rétabli → valide à l'identique, sans changer la plaque physique) — il n'existe aucune action de révocation distincte. La **résolution** d'un jeton (à quel prestataire il renvoie, et s'il est valide) est déjà exposée. Ce cycle **consomme** ces capacités ; il ne les redéveloppe pas. Le point du prompt « prévois seulement l'endpoint de résolution du jeton » est donc déjà satisfait par le cycle 005 : QRC s'appuie dessus, la fiche publique et le scan hors contexte restent au cycle WEB.

### Ce que ce cycle construit

QRC porte les **parcours** que le cycle 005 a explicitement renvoyés ici : le **PDF de plaque** (rendu imprimable du jeton et du code existants, téléchargeable par l'Admin), le **scan de collecte en course arrêt par arrêt** (correspondance, distance, horodatage serveur, photo conditionnelle, progression vers EN_LIVRAISON), la **révocation observée au scan** (message « prestataire temporairement indisponible ») et le **mode dégradé** (saisie du code, géoloc exigée, trois essais, incident « plaque à remplacer »).

### Surface d'interface et modèle de course

Côté Admin, comme aux cycles 002, 003 et 005, aucun écran n'est construit avant le cycle ADM : le téléchargement de la plaque PDF est exposé en API protégée par le rôle admin et journalisée. Côté coursier, ce cycle construit dans **Mefali Pro** la **tranche « scanner et collecter »** de la maquette K3 — l'action de scan, la coche d'arrêt **COLLECTÉ**, la saisie du code en mode dégradé et la progression visible « tout est collecté → en route ». La coquille complète de la course active (itinéraire multi-arrêts, appels, encaissement par arrêt, repère vocal du client, arrivée) appartient aux cycles CMD et CRS ; sans la tranche scan, QRC-02 et QRC-04 ne seraient démontrables par personne.

Le modèle de commande, de course et d'arrêt **n'existe pas encore** dans le code : le tronc `commande` est défini sans aucun champ logistique, et les modules dispatch, coursier et livraison ne sont pas construits. Les docs le spécifient pourtant en entier — `livraison → segments → arrêts`, chaque arrêt portant prestataire, scan, photo éventuelle, montant avancé et **statut {à collecter, collecté, indisponible}** (`docs/user-stories-v2.md` §CMD « Structure » ; `docs/cadrage-v5.md` §7.3), avec la machine d'états `EN_ROUTE_ARRÊT → ARRIVÉ → COLLECTÉ → EN_LIVRAISON (toutes collectes terminées)` (§7.2). Ce cycle **introduit cette structure d'arrêt-collecte documentée comme socle** que CMD étendra, mais n'y **pose que la transition COLLECTÉ** : le statut `indisponible` est du ressort de CMD-06 (article indisponible / substitution) et les états de suivi `EN_ROUTE_ARRÊT`/`ARRIVÉ` de DSP/CRS. La précondition « le coursier a une course active comportant un arrêt chez ce prestataire, dans un état compatible » est **exercée par un déclencheur simulé dans les tests**, exactement comme le cycle 005 a simulé le verrouillage des prix et la présence du coursier sur place. Quand les cycles CMD et DSP arriveront, ce sont eux qui produiront ces arrêts ; QRC apporte la mécanique de collecte qui agit dessus.

---

### User Story 1 - Imprimer et remettre la plaque d'un prestataire agréé (QRC-01, Priority: P1 — produit : P0)

L'Admin vient d'agréer un prestataire sur le terrain (cycle 005). Pour matérialiser l'agrément, il télécharge la **plaque** : un document imprimable qui porte le QR code du prestataire, son nom, et le code de secours à quatre chiffres. Il l'imprime, la plastifie, la pose sur le mur de l'étal. Le QR encode l'URL courte du prestataire assortie de son jeton signé ; le code de secours imprimé dessous sert de repli quand le QR devient illisible. Rien dans la plaque n'est recalculé : le jeton et le code sont ceux posés à l'agrément, si bien qu'une réimpression donne exactement la même plaque.

**Why this priority**: Sans plaque imprimable, il n'y a rien à scanner : c'est le préalable physique de toute traçabilité, et il est entièrement autonome puisque l'identité de plaque existe déjà. C'est la tranche T1 du produit, livrable et démontrable seule.

**Independent Test**: Agréer un prestataire (capacité 005), demander sa plaque en tant qu'Admin, vérifier que le document obtenu contient un QR menant à l'URL du prestataire avec son jeton, son nom et son code à quatre chiffres, puis le redemander et constater que le jeton et le code n'ont pas changé — le tout sans qu'aucun scan ni aucune autre story de ce cycle ne soit livré.

**Acceptance Scenarios**:

1. **Given** un prestataire agréé portant une identité de plaque, **When** l'Admin demande sa plaque, **Then** le système produit un document imprimable contenant le QR (URL courte du prestataire + jeton signé), le nom du prestataire et son code de secours à quatre chiffres, téléchargeable par l'Admin.
2. **Given** une plaque déjà produite pour un prestataire, **When** l'Admin la redemande après plusieurs jours, **Then** le jeton encodé et le code de secours sont identiques à la première fois — aucune plaque physique n'a besoin d'être réimprimée du fait de l'application.
3. **Given** un prestataire encore prospect, jamais agréé et donc sans identité de plaque, **When** on demande sa plaque, **Then** le système refuse : il n'y a pas de plaque à produire.
4. **Given** un utilisateur sans rôle admin, **When** il tente de télécharger une plaque, **Then** l'accès est refusé et la tentative est journalisée.

---

### User Story 2 - Collecter un arrêt en scannant le QR du prestataire (QRC-02, Priority: P1 — produit : P0)

Yao a une course active à trois étals. Au premier, l'écran affiche l'arrêt courant et le bouton « Scanner le QR du vendeur ». Il scanne la plaque posée sur le mur. Le système vérifie que ce QR correspond bien au prestataire attendu à cet arrêt, que Yao est physiquement à moins de la distance de zone (100 m par défaut) de l'étal, puis marque l'arrêt **COLLECTÉ** avec l'heure du serveur. Si la politique résolue l'exige, Yao doit d'abord prendre une **photo** de la récupération. Il paie le vendeur, passe à l'étal suivant, scanne, collecte. Quand le **dernier** arrêt bascule à COLLECTÉ, la livraison passe automatiquement à **EN_LIVRAISON** : tout est dans le sac, Yao part chez le client. Comme le terrain a du réseau par intermittence, le scan et les coches fonctionnent **hors connexion** : l'action est enregistrée sur l'appareil et rejouée à la reconnexion, sans jamais collecter deux fois.

**Why this priority**: C'est le cœur anti-fraude du QR — la preuve horodatée et géolocalisée qu'un coursier était bien chez un prestataire agréé, impossible à falsifier à distance — et le déclencheur de la mise en livraison. C'est la raison d'être du module (tranche T1).

**Independent Test**: Simuler une course active dont un arrêt vise un prestataire agréé, présenter au scan le jeton de ce prestataire depuis une position à moins de 100 m, et vérifier que l'arrêt passe COLLECTÉ avec un horodatage serveur, qu'une photo est exigée ou non selon la politique résolue, et que la bascule du dernier arrêt fait passer la livraison à EN_LIVRAISON — chaque transition ayant émis un événement — puis rejouer l'action et constater qu'aucune double collecte n'a lieu.

**Acceptance Scenarios**:

1. **Given** une course active dont l'arrêt courant vise un prestataire agréé, Yao à moins de la distance de zone de l'étal, une politique photo résolue « non exigée », **When** il scanne le jeton de ce prestataire, **Then** l'arrêt passe COLLECTÉ à l'horodatage serveur et la transition émet un événement dans la même transaction.
2. **Given** le même contexte mais une politique photo résolue « exigée » (par le prestataire, sa catégorie, le défaut de zone, ou parce que le montant de l'arrêt atteint le seuil de zone), **When** Yao scanne sans fournir de photo, **Then** la collecte ne se conclut pas tant que la photo n'est pas jointe.
3. **Given** une course active dont l'arrêt vise le prestataire A, **When** Yao scanne le jeton du prestataire B, **Then** la collecte est refusée pour non-correspondance prestataire/arrêt et l'arrêt reste à collecter.
4. **Given** l'arrêt courant vise le bon prestataire mais Yao est à plus de la distance de zone de l'étal, **When** il scanne, **Then** la collecte est refusée pour distance excessive et l'arrêt reste à collecter.
5. **Given** une course dont tous les arrêts sauf le dernier sont déjà COLLECTÉS, **When** Yao collecte le dernier arrêt, **Then** la livraison passe à EN_LIVRAISON et la transition émet un événement dans la même transaction.
6. **Given** Yao hors connexion, **When** il scanne et coche une collecte, **Then** l'action est confirmée localement et mise en file ; à la reconnexion elle est rejouée une seule fois (idempotente par identifiant client), le serveur applique sa validation faisant autorité et pose l'horodatage.

---

### User Story 3 - Un prestataire suspendu ne peut plus être collecté (QRC-03, Priority: P2 — produit : P0)

Trois incidents graves sur le même étal : l'Admin suspend le prestataire (cycle 005). La plaque reste sur le mur, mais son jeton ne vaut plus rien à l'instant même. Quand un coursier scanne ce QR, le système répond « prestataire temporairement indisponible » et refuse la collecte — sans qu'aucun geste de révocation distinct n'ait été nécessaire, puisque la validité dérive de l'agrément. Quand la situation est réglée et l'Admin rétablit le prestataire, la même plaque redevient valide sans changer de valeur.

**Why this priority**: C'est la garantie que la traçabilité reflète l'agrément en temps réel : un prestataire écarté cesse instantanément d'être collectable, sans intervention physique sur la plaque. Le mécanisme de révocation existe déjà (005) ; ce cycle le rend observable là où ça compte, au scan.

**Independent Test**: Suspendre un prestataire agréé, présenter son jeton au scan dans un contexte de course par ailleurs valide, et vérifier sans délai ni redémarrage que la collecte est refusée avec le message « prestataire temporairement indisponible » ; rétablir le prestataire et constater que le même jeton redevient collectable, valeur inchangée.

**Acceptance Scenarios**:

1. **Given** un prestataire agréé collectable, **When** l'Admin le suspend puis qu'un coursier scanne son jeton, **Then** la collecte est refusée et le message « prestataire temporairement indisponible » est renvoyé — sans aucune action de révocation distincte.
2. **Given** un prestataire suspendu dont un coursier a scanné le jeton hors connexion avant de savoir la suspension, **When** l'action est rejouée à la reconnexion, **Then** le serveur refuse la collecte à la résolution (validité dérivée courante) et l'arrêt n'est pas marqué COLLECTÉ.
3. **Given** un prestataire suspendu puis rétabli, **When** un coursier scanne son jeton, **Then** la collecte est de nouveau possible, le jeton et le code de secours ayant conservé leur valeur et la plaque physique n'ayant pas bougé.

---

### User Story 4 - Collecter en mode dégradé quand le QR est illisible (QRC-04, Priority: P2 — produit : P0)

La plaque du deuxième étal est éraflée, le QR ne se lit plus. Yao bascule en mode dégradé et saisit le **code à quatre chiffres** imprimé sur la plaque. Ce code n'est **pas** un identifiant global : le système le compare au code du prestataire **attendu à cet arrêt**, pas à un annuaire mondial — aucun problème d'échelle, même avec des millions de prestataires. La géolocalisation à moins de 100 m reste exigée. Yao a droit à **trois essais** ; au-delà, la saisie est refusée. Parce que le QR était illisible, un incident « plaque à remplacer » est créé automatiquement pour que l'Admin réimprime et remplace la plaque abîmée.

**Why this priority**: C'est le filet qui empêche qu'une plaque abîmée bloque une collecte, sans ouvrir de faille anti-fraude — la géoloc reste exigée, le code est une confirmation locale, et les essais sont bornés. C'est la tranche T2 du produit, adossée au scan de QRC-02.

**Independent Test**: Sur un arrêt visant un prestataire agréé, refuser le scan (QR illisible), saisir le code de secours de ce prestataire depuis une position à moins de 100 m et vérifier que l'arrêt passe COLLECTÉ ; saisir un mauvais code trois fois et vérifier que la quatrième tentative est refusée ; vérifier qu'un incident « plaque à remplacer » a été créé dès le recours au mode dégradé.

**Acceptance Scenarios**:

1. **Given** un arrêt courant visant un prestataire agréé, QR illisible, Yao à moins de la distance de zone, **When** il saisit le code de secours correct de ce prestataire, **Then** l'arrêt passe COLLECTÉ (photo appliquée selon la même politique résolue qu'au scan) et la transition émet un événement.
2. **Given** le même contexte, **When** Yao saisit un code qui ne correspond pas au prestataire de l'arrêt, **Then** la confirmation échoue — le code n'est jamais utilisé pour retrouver un prestataire, seulement comparé à celui attendu.
3. **Given** un arrêt en mode dégradé, **When** Yao échoue trois fois la saisie du code, **Then** toute nouvelle tentative est refusée pour cet arrêt.
4. **Given** un coursier qui bascule en mode dégradé parce que le QR est illisible, **When** il entame la saisie du code, **Then** un incident « plaque à remplacer » est créé automatiquement pour ce prestataire, avec le contexte de la course, et un événement est émis.
5. **Given** Yao en mode dégradé mais à plus de la distance de zone de l'étal, **When** il saisit le bon code, **Then** la collecte est refusée : la géolocalisation reste exigée en mode dégradé.

---

### Edge Cases

- **Jeton forgé ou inconnu** : un QR qui ne résout aucun prestataire connu (jeton jamais émis, altéré) est refusé au scan comme « plaque invalide », distinct du message de suspension.
- **Collecte hors connexion invalidée au rejeu** : une collecte confirmée localement peut être refusée à la synchronisation (prestataire entre-temps suspendu, ou distance recalculée hors seuil côté serveur) ; l'arrêt revient alors « à collecter » avec un motif, sans rester faussement COLLECTÉ.
- **Double scan / rejeu** : scanner deux fois le même arrêt, ou rejouer une action en file, ne produit qu'une seule collecte (idempotence par identifiant client).
- **Scan d'un arrêt déjà collecté** : sans effet nouveau, l'arrêt reste COLLECTÉ à son horodatage initial.
- **Scan hors de toute course active** : un coursier sans course active comportant cet arrêt ne peut pas collecter — la précondition n'est pas satisfaite (le scan hors contexte, sur la fiche publique, relève du cycle WEB).
- **Photo exigée sans caméra disponible** : si la politique exige la photo et que la capture échoue, la collecte ne se conclut pas ; l'arrêt reste à collecter.
- **Suspension pendant la course** : un prestataire suspendu après le début de la course mais avant la collecte de son arrêt devient non collectable ; l'arrêt ne peut être ni scanné ni confirmé au code tant qu'il est suspendu.
- **Seuil de montant à la limite** : un arrêt dont le montant est exactement au seuil de zone force la photo (comparaison « atteint ou dépasse »).
- **Plaque déjà signalée à remplacer** : un second recours au mode dégradé sur la même course/arrêt ne crée pas d'incident en double.

## Requirements *(mandatory)*

### Functional Requirements

#### Cadre transverse

- **FR-001**: Toute chaîne destinée à l'utilisateur (messages de refus, « prestataire temporairement indisponible », libellés du scan et du mode dégradé) DOIT être une clé i18n fr, jamais un texte en dur.
- **FR-002**: Tout montant manipulé (le seuil de zone qui force la photo, le montant d'un arrêt) DOIT être un entier en unités mineures assorti d'un code de devise ISO 4217 ; aucun flottant, aucun chemin partiel.
- **FR-003**: Toute transition d'état de ce cycle (arrêt → COLLECTÉ, livraison → EN_LIVRAISON, création d'incident « plaque à remplacer ») DOIT écrire un événement outbox dans la même transaction que la transition.
- **FR-004**: Les paramètres métier de ce cycle — distance maximale de scan (défaut 100 m), seuil de montant forçant la photo, exigence de photo par défaut — DOIVENT être des paramètres de zone hérités, jamais des valeurs en dur.
- **FR-005**: Les écritures d'administration (téléchargement de plaque) DOIVENT être protégées par le rôle admin et journalisées (qui, quand), selon le précédent des cycles 002, 003 et 005.

#### Identité de plaque consommée (dépendance cycle 005, non reconstruite)

- **FR-006**: Ce cycle DOIT consommer l'identité de plaque déjà portée par le prestataire — jeton signé, code de secours à quatre chiffres, validité dérivée de l'agrément — et la capacité de résolution d'un jeton déjà exposée, sans les redévelopper ni exposer d'action de révocation distincte.
- **FR-007**: Le code de secours NE DOIT jamais servir à retrouver un prestataire : aucune recherche par ce code, à aucune échelle. Il est uniquement comparé au code du prestataire attendu (FR-021).

#### QRC-01 — Plaque imprimable

- **FR-008**: Le système DOIT produire, pour un prestataire portant une identité de plaque, un document de plaque imprimable contenant le QR code, le nom du prestataire et le code de secours à quatre chiffres.
- **FR-009**: Le QR code DOIT encoder l'URL courte du prestataire assortie de son jeton signé existant, sous la forme `{domaine}/v/{prestataire_id}?t={jeton}`. La production de la plaque NE DOIT ni régénérer ni modifier le jeton ou le code : une réimpression rend une plaque identique.
- **FR-010**: Le document de plaque DOIT être conservé en stockage objet et téléchargeable par l'Admin. Il DOIT pouvoir être reproduit à la demande sans changer le jeton ni le code.
- **FR-011**: Une demande de plaque pour un prestataire sans identité de plaque (jamais agréé) DOIT être refusée.

#### QRC-02 — Scan de collecte en course

- **FR-012**: Une collecte NE DOIT être acceptée que si le coursier a une course active comportant un arrêt qui vise le prestataire scanné, cet arrêt étant dans un état compatible avec la collecte (« à collecter »). Le modèle d'arrêt suit la structure documentée `livraison → segment → arrêt` (`docs/user-stories-v2.md` §CMD ; `docs/cadrage-v5.md` §7.3), introduite par ce cycle comme socle. Faute de modules commande et dispatch à ce stade, l'existence de cette course active est fournie par un déclencheur simulé dans les tests.
- **FR-013**: Le scan DOIT vérifier la correspondance prestataire/arrêt : le jeton présenté DOIT résoudre le prestataire attendu à l'arrêt courant, sinon la collecte est refusée et l'arrêt reste à collecter.
- **FR-014**: Le scan DOIT vérifier que la position du coursier au moment de l'action est à moins de la distance maximale de zone (défaut 100 m) de la position du site de l'arrêt ; au-delà, la collecte est refusée.
- **FR-015**: En cas de succès, l'arrêt DOIT passer COLLECTÉ avec un horodatage faisant autorité côté serveur.
- **FR-016**: Le système DOIT résoudre l'exigence de photo selon la hiérarchie prestataire > catégorie > défaut de zone, et la FORCER exigée lorsque le montant de l'arrêt atteint ou dépasse le seuil de zone. Quand la photo est exigée, la collecte NE DOIT pas se conclure sans photo jointe.
- **FR-017**: La photo de récupération, quand elle est fournie, DOIT être attachée à la collecte et conservée avec une rétention limitée conforme au principe de minimisation (elle atteste la conformité de l'article pris, cadrage §5.2).
- **FR-018**: Lorsque tous les arrêts de collecte d'une course sont résolus — COLLECTÉS, un arrêt marqué `indisponible` par CMD-06 comptant comme résolu et non plus en attente — la livraison DOIT passer à EN_LIVRAISON (état porté par le composant `livraison` — le tronc `commande` reste sans champ logistique, constitution II ; `docs/cadrage-v5.md` §7.2 « toutes les collectes terminées »). Ce cycle pose la transition COLLECTÉ et déclenche EN_LIVRAISON ; il ne pose pas lui-même le statut `indisponible`.

#### QRC-03 — Révocation observée au scan

- **FR-019**: Une collecte dont le jeton résout un prestataire dont la validité courante est fausse (suspendu) DOIT être refusée et renvoyer le message « prestataire temporairement indisponible ». La révocation DOIT prendre effet immédiatement, sans changer la plaque physique ni la valeur du jeton, un rétablissement rendant le jeton de nouveau collectable.
- **FR-020**: Un jeton qui ne résout aucun prestataire (inconnu ou forgé) DOIT être refusé comme plaque invalide, message distinct de la suspension.

#### QRC-04 — Mode dégradé

- **FR-021**: Quand le QR est illisible, le coursier DOIT pouvoir confirmer la collecte en saisissant le code de secours à quatre chiffres, comparé au code du prestataire attendu à l'arrêt courant — jamais utilisé comme identifiant global (FR-007).
- **FR-022**: La vérification de distance (FR-014) DOIT rester exigée en mode dégradé ; une saisie correcte hors distance est refusée.
- **FR-023**: Le mode dégradé DOIT autoriser au plus trois essais de code par arrêt ; au-delà, toute nouvelle tentative est refusée pour cet arrêt.
- **FR-024**: Le basculement en mode dégradé (QR déclaré illisible) DOIT créer automatiquement un incident « plaque à remplacer » rattaché au prestataire, avec le contexte de la course/arrêt, **une seule fois par arrêt** — le signal décrit la plaque physiquement abîmée et naît que le code saisi ensuite réussisse ou non.
- **FR-025**: Une collecte réussie en mode dégradé DOIT appliquer la même politique de photo et produire le même résultat qu'une collecte par scan (arrêt COLLECTÉ, événement, progression).

#### Transverse — hors connexion et rejeu idempotent

- **FR-026**: Les actions de collecte (scan et confirmation par code) DOIVENT pouvoir être saisies hors connexion, confirmées localement, mises en file, puis rejouées de façon idempotente, chaque action portant un identifiant client unique (règle « actions coursier » du projet ; maquette K3).
- **FR-027**: L'appareil DOIT pouvoir pré-provisionner, pour la course active, les données de plaque attendues de ses arrêts (identité du prestataire, jeton attendu, code de secours, position du site, exigence de photo) afin d'évaluer le scan, la distance et la confirmation par code hors connexion — la signature du jeton étant vérifiable hors base.
- **FR-028**: À la synchronisation, le serveur DOIT appliquer la validation faisant autorité — validité courante du jeton (révocation dérivée), distance, horodatage serveur — et une action qui échoue à cette validation NE DOIT pas marquer l'arrêt COLLECTÉ : l'arrêt **revient « à collecter »** et le coursier est **notifié du motif** (il re-collecte ou escalade). Aucune collecte invalide côté serveur n'apparaît COLLECTÉE à tort.

#### Hors périmètre explicite

- **FR-029**: Ce cycle NE DOIT construire ni la fiche publique du prestataire ni le scan hors contexte (cycle WEB), ni la logique de dispatch/affectation (DSP), ni le cycle de vie de la commande hors segment de collecte (CMD), ni la coquille complète de la course active au-delà de la tranche scan/collecte (CRS/CMD), ni le remplacement physique de la plaque au-delà de la création de l'incident.

### Key Entities *(include if feature involves data)*

- **Identité de plaque** *(existante, cycle 005)* : jeton signé révocable et code de secours à quatre chiffres portés par le prestataire ; validité dérivée de l'agrément ; jeton résolvable. Consommée, non redéfinie.
- **Document de plaque** *(nouveau)* : rendu imprimable — QR (URL courte + jeton), nom du prestataire, code de secours — conservé en stockage objet, reproductible à la demande, téléchargeable par l'Admin. Rattaché au prestataire.
- **Arrêt de collecte** *(structure documentée introduite ici comme socle)* : maillon `livraison → segment → arrêt` visant un prestataire — référence de commande, référence de prestataire, position attendue du site, montant avancé (soumis au seuil de photo), **statut {à collecter, collecté, indisponible}**, horodatage/méthode/photo de collecte, dans l'ordre de l'itinéraire (TRF-06). Conforme au modèle des docs ; QRC n'y pose que `collecté`, `indisponible` revenant à CMD-06 et les états de suivi à DSP/CRS.
- **Collecte** *(nouveau)* : acte de collecte d'un arrêt — références course/arrêt/coursier, méthode {scan QR, code dégradé}, position capturée, horodatage serveur, identifiant client (idempotence), photo optionnelle, résultat.
- **Politique de photo résolue** *(résolution, non stockée)* : résultat de la hiérarchie prestataire > catégorie > défaut de zone, forcée par le seuil de montant de zone.
- **Incident « plaque à remplacer »** *(nouveau)* : signalement automatique — type, référence prestataire, contexte course/arrêt, coursier, horodatage, statut — créé au recours au mode dégradé.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'Admin obtient au premier essai la plaque imprimable (QR + nom + code) de tout prestataire agréé, et une réimpression rend une plaque au jeton et au code identiques — aucune plaque physique n'a jamais à être réimprimée du fait de l'application.
- **SC-002**: 100 % des collectes effectuées à moins de la distance de zone du bon prestataire, sur une plaque valide et selon la politique photo résolue, marquent l'arrêt COLLECTÉ avec un horodatage serveur.
- **SC-003**: 100 % des tentatives de collecte au-delà de la distance de zone, ou visant un prestataire différent de celui attendu à l'arrêt, sont refusées et laissent l'arrêt à collecter.
- **SC-004**: 100 % des scans d'un prestataire suspendu sont refusés avec « prestataire temporairement indisponible », la révocation prenant effet immédiatement après la suspension et sans changement de plaque ; un rétablissement rend le même jeton de nouveau collectable.
- **SC-005**: Lorsque le dernier arrêt d'une course est collecté, la livraison de la commande passe à EN_LIVRAISON sans aucun geste manuel, 100 % du temps.
- **SC-006**: En mode dégradé, après trois échecs de saisie du code aucune tentative supplémentaire n'est acceptée, et un incident « plaque à remplacer » est enregistré 100 % du temps dès le recours au mode dégradé ; un code correct dans la distance et le budget d'essais conclut la collecte.
- **SC-007**: Il est impossible de marquer un arrêt collecté sans être physiquement à moins de la distance de zone du prestataire — 0 % de collecte à distance (garantie anti-fraude).
- **SC-008**: Une collecte effectuée hors connexion se reflète à l'identique après reconnexion, sans double collecte même en cas de rejeu (idempotence), 100 % du temps ; une collecte invalidée au rejeu (suspension, distance) n'apparaît jamais comme COLLECTÉE à tort.
- **SC-009**: Chaque collecte et chaque transition de commande de ce cycle laisse un événement métier traçable.

## Assumptions

- **Domaine de l'URL** : le domaine canonique de la plaque est `mefali.com` (`docs/user-stories-v2.md` QRC-01 et `docs/cadrage-v5.md` §5.3, harmonisés sur `.com` le 2026-07-22 — la valeur `.ci` qui subsistait dans ces deux fichiers était une incohérence, `mefali.com` figurant déjà dans le prompt, dans `docs/Mefali_Prompts_SpecKit.md` et dans la recherche du cycle 005). Le libellé `{domaine}` de FR-009 se résout sur `mefali.com` en production, l'hôte exact restant un paramètre d'environnement (dev/prod).
- **Stockage objet** : le document de plaque et les photos de récupération sont conservés dans le stockage objet du projet (Garage/MinIO, compatible S3) ; le téléchargement admin passe par un lien à durée limitée. Le prompt dit « MinIO », l'infra du dépôt dit « Garage » — même rôle, détail d'implémentation.
- **Identité de plaque déjà livrée** : le jeton, le code, la validité dérivée et la résolution proviennent du cycle 005 et sont consommés ici, jamais reconstruits. La demande du prompt « prévois seulement l'endpoint de résolution du jeton » est déjà satisfaite.
- **Modèle de course simulé** : les modules commande, dispatch et coursier n'étant pas construits, ce cycle introduit la structure d'arrêt-collecte **documentée** (`livraison → segment → arrêt`) et la bascule vers EN_LIVRAISON comme socle que CMD étendra, et simule dans les tests l'existence d'une course active affectée au coursier — même patron que le cycle 005 (verrouillage des prix, coursier sur place).
- **Seuil de photo à seeder** : le « seuil de montant » qui force la photo (`docs/cadrage-v5.md` §4 l.76) ne figure pas encore au « Récapitulatif des paramètres de zone » ; il DOIT y être ajouté comme paramètre de zone à valeur seed éditable, comme le cycle 005 y a inscrit la conservation de la charte (5 ans). Valeur seed retenue : **10 000 FCFA** (XOF, unités mineures = `10000`), éditable — elle n'est pas bloquante : la politique de catégorie {obligatoire/facultative/désactivée} et l'override vendeur déterminent déjà la photo dans le cas courant.
- **Géo-vérification par rayon** : la distance de scan est une proximité point-rayon à la position du site de l'arrêt (« suis-je physiquement à l'étal »), distincte des distances de livraison par itinéraire routier régies par la tarification (TRF) — la règle OSRM ne s'applique pas à ce contrôle de proximité. Défaut 100 m, paramètre de zone.
- **Déclenchement de l'incident** : l'incident « plaque à remplacer » est créé dès le recours au mode dégradé (QR illisible ⇒ plaque à remplacer), pas seulement après trois échecs, et dédupliqué par course/arrêt pour éviter les doublons.
- **Pré-provisionnement hors-ligne** : l'appareil du coursier met en cache les données de plaque attendues de sa course active pour évaluer scan, distance et code hors connexion ; la révocation et l'horodatage faisant autorité sont réconciliés au rejeu côté serveur (collecte optimiste). La file d'actions hors-ligne pourra s'appuyer sur une infrastructure partagée avec le cycle coursier.
- **Code non unique** : le code à quatre chiffres n'est unique à aucune échelle et aucune recherche par ce code n'existe (cycle 005) ; sa comparaison est toujours locale au prestataire de l'arrêt.
- **Surface coursier minimale** : ce cycle construit dans Mefali Pro la seule tranche scan/collecte de la maquette K3 pour rendre QRC-02/04 démontrables ; la coquille complète de la course active relève de CMD/CRS.

## Dependencies

- **Cycle 005 (prestataires)** : identité de plaque, résolution du jeton, validité dérivée, suspension/rétablissement.
- **Cycle 002 (zones)** : paramètres de zone hérités — distance de scan, seuil de montant photo, exigence de photo par défaut.
- **Cycle 003 (comptes)** : session et rôle coursier pour le scan ; rôle admin pour le téléchargement de plaque.
- **Stockage objet (Garage/MinIO)** : document de plaque et photos de récupération.
- **Cycles CMD/DSP/CRS (à venir)** : cycle de vie de la commande, dispatch/affectation, coquille de course active — simulés ici par un déclencheur de test.
- **Cycle WEB (à venir)** : fiche publique et scan hors contexte, qui consommeront la résolution du jeton — hors périmètre de ce cycle.
