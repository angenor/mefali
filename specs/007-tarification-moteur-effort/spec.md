# Feature Specification: Moteur de tarification à règles, routage et grille d'effort

**Feature Branch**: `007-tarification-moteur-effort`

**Created**: 2026-07-24

**Status**: Draft

**Input**: User description: "Lis docs/user-stories-v2.md, module TRF — Tarification & devises, et docs/cadrage-v5.md section §9. Fonctionnalité : moteur de tarification à règles, routage et grille d'effort. Périmètre : TRF-01, TRF-02, TRF-03, TRF-04, TRF-05 (P0) et TRF-06 (P1, requise avant la fin de la promo) — critères tels quels. Règles {zone, catégorie?, véhicule, tranche de distance, plage horaire/jour, point relais?} → {prix client, part coursier, marge Mefali bornée 25–100 par zone, devise}, priorité, dates d'effet ; distance et ETA par ITINÉRAIRE ROUTIER via OSRM avec points de passage (waypoints) ; cache Redis 24 h par paire de points arrondis, dégradé vol d'oiseau ×1,4 journalisé ; drapeaux de zone (livraison offerte Mefali → prix client 0 ; gratuité → marge 0) ; simulateur admin obligatoire avant publication ; devises en unités mineures + ISO 4217 ; seed Tiassalé ; grille d'effort (paliers d'articles, prime d'attente, supplément par arrêt indexé sur la distance au précédent, plafonds) 100 % reversée au coursier, non facturée pendant la promo. Hors périmètre : dimension point relais présente mais inutilisée ; commission vendeur (PAY-06, P2). Personas : Admin, Yao, Awa. Points d'attention : l'optimisation de l'ordre des arrêts (permutations ≤ 4) vit ici et est exposée au dispatch et aux commandes ; maquette : docs/design/png/A3."

## Clarifications

### Session 2026-07-24

- Q: Prime d'attente (> 15 min entre arrivée géolocalisée et scan QR → +100) — comment l'agréger sur une course multi-arrêts, point non tranché par §9.3, TRF-06 ni le « Récapitulatif des paramètres de zone » ? → A: **Une seule fois par course** — au plus **+100 par course**, quel que soit le nombre d'arrêts dont l'attente dépasse 15 min (montant seed éditable par zone). Reflété en FR-028, FR-029, US6 scénario 3 et Edge Cases.

**Décisions confirmées par les sources (sans question, sections citées)** — ambiguïtés candidates tranchées par les docs/design plutôt que par supposition :

- **Origine de l'itinéraire tarifé** = retraits optimisés → client, **sans** jambe d'approche coursier (le client voit les frais **avant dispatch**, donc sans coursier assigné) — TRF-03 (entrées du simulateur : « Vendeur (ou point) + destination + véhicule + heure »), maquette **A3**, CMD-01 ; la jambe coursier → 1er retrait relève de DSP. Reflété en FR-013.
- **Objectif d'optimisation de l'ordre des arrêts** = minimiser la **distance routière totale** de l'itinéraire retraits → client — §9.3 (« détour total », « km réels », « autorégule les paniers trop dispersés »). Reflété en FR-031.
- **« distance au précédent arrêt »** (barème de supplément) = **tronçon routier** entre arrêts consécutifs de l'itinéraire optimisé (sous-produit du routage à waypoints), jamais un vol d'oiseau — constitution IV. Reflété en FR-029.
- **Imputation de l'arrondi (25 FCFA)** = reliquat d'arrondi + part variable au km → **part coursier**, **marge fixe** par règle — §9.3 (« la marge Mefali reste fixe »), §7.5 (« le coursier ne perd jamais »), maquette A3 (marges fixes par ligne). Reflété en FR-016, FR-019.
- **Simulation invalidée par toute édition ultérieure du brouillon** (la simulation doit refléter le contenu exact publié) — maquette A3 (« Publier reste désactivé tant qu'une simulation n'a pas été faite »). Reflété en FR-021.

## User Scenarios & Testing *(mandatory)*

Personas de ce cycle : **Admin (toi)** — fondateur, seul au lancement, édite la grille tarifaire de Tiassalé, la simule sur des courses réelles avant de la publier, active les drapeaux de zone ; **Yao (coursier)** — livreur à moto ou à vélo, dont chaque course affiche un gain total dont il faut que la part effort soit lisible et infalsifiable ; **Awa (cliente)** — commande chez plusieurs étals du marché et voit, avant de confirmer, le prix total et le détail des frais (déplacement réel + effort) — c'est ce prix affiché qui autorégule les paniers trop dispersés.

Priorités produit : TRF-01, TRF-02, TRF-03, TRF-04, TRF-05 sont **P0** ; TRF-06 est **P1** (requise avant la fin de la promo de lancement). Les priorités P1→P3 attachées aux stories ci-dessous sont l'**ordre de livraison interne** au cycle (chaîne de dépendances), pas une hiérarchie produit — la mention « produit : P0/P1 » rappelle le rang réel.

### Ce que ce cycle NE construit PAS parce que c'est déjà là

- **La configuration de zone à héritage (cycle 002)** porte déjà les paramètres métier de ce module : les règles tarifaires, les drapeaux de zone (`livraison_offerte_mefali` déjà seedé pour Tiassalé), les bornes de marge, la devise portée par la zone, le facteur dégradé (×1,4), le pas d'arrondi et les seeds de la grille d'effort figurent au « Récapitulatif des paramètres de zone » (`docs/user-stories-v2.md`) et se résolvent par héritage parent → enfant. Ce cycle **écrit et lit** ces paramètres comme configuration de zone ; il ne réinvente aucun mécanisme de stockage ou d'héritage (constitution I).
- **Le serveur de routage OSRM** est déjà provisionné dans l'infra (`infra/docker-compose.yml`, extrait OSM Côte d'Ivoire) et son URL est déjà configurée (`OSRM_URL`, crate `socle`). Aucun service n'en dépend pour démarrer : son indisponibilité ne bloque rien. Ce cycle construit le **client** de routage qui l'interroge (avec waypoints), pas le serveur.
- **Redis** est déjà en service et utilisé comme cache par d'autres crates. Ce cycle y ajoute son **espace de cache de routage** ; il ne provisionne pas l'infrastructure.
- **La discipline monétaire** (entiers en unités mineures + code ISO 4217, jamais de flottant, jamais de chemin partiel) est déjà transverse au dépôt (constitution III). Ce cycle s'appuie dessus ; TRF-04 y ajoute la sélection de devise **par zone** et le formatage.
- **Le rôle admin et la journalisation des écritures d'administration** (cycles 002/003/005) sont réutilisés pour l'édition, la simulation et la publication de grilles.

### Ce que ce cycle construit

Le **moteur de tarification** : le modèle de règles à priorité et dates d'effet avec marge bornée par zone (TRF-01) ; l'**évaluation routée** qui, à partir d'un itinéraire multi-arrêts réel, produit un **devis figé** {prix client, part coursier, marge} avec cache, dégradé et drapeaux de zone (TRF-02) ; le **simulateur admin** qui rejoue un brouillon sur une course réelle et **garde la publication** (TRF-03) ; les **devises par zone** (TRF-04) ; la **grille de départ Tiassalé** seedée (TRF-05) ; et la **grille d'effort** à trois composantes intégralement reversée au coursier, assortie de l'**optimisation de l'ordre des arrêts** (TRF-06). L'évaluation routée de TRF-02 est le **premier consommateur de routage tarifaire** du dépôt (la vérification de proximité du scan QR, cycle 006, était un rayon point-à-point, pas un itinéraire OSRM).

### Surface d'interface, consommateurs du devis et modèle de course

Côté **Admin**, comme aux cycles 002/003/005, **aucun écran n'est construit avant le cycle ADM** : l'édition de la grille (brouillon), la simulation obligatoire et la publication sont exposées en **API protégée par le rôle admin et journalisées**. La maquette `docs/design/png/A3` (grille éditable à gauche, simulateur obligatoire à droite, publication bloquée tant qu'une règle est hors bornes ou qu'aucune simulation n'a été faite) est la **cible du cycle ADM** ; ce cycle en fournit le moteur et le contrat, pas l'écran.

Les **consommateurs du devis** — l'écran de confirmation d'Awa (CMD-03 : « total articles + frais avant confirmation »), l'écran d'offre de Yao (part effort au gain total), le verrouillage des prix à la création de commande — relèvent des cycles CMD, DSP et CRS, **non construits**. Ce cycle **produit** le devis figé et le **détail d'effort** et les **expose comme capacité** consommée plus tard ; il les exerce par API et par des courses **simulées dans les tests**, exactement comme le cycle 006 a simulé la course active et l'affectation.

L'**optimisation de l'ordre des arrêts** (permutations, triviale jusqu'à 4 arrêts) **vit dans ce module** et est **exposée au dispatch (DSP) et aux commandes (CMD)**. Comme DSP et CMD ne sont pas construits, l'ordre optimisé est produit par le moteur et **consommé par des itinéraires simulés dans les tests** ; quand ces cycles arriveront, ils appelleront cette capacité au lieu de la recalculer.

---

### User Story 1 - Éditer un modèle de règles à marge bornée (TRF-01, Priority: P1 — produit : P0)

L'Admin construit la grille tarifaire d'une zone. Chaque **règle** associe des **conditions** {zone, catégorie (optionnelle), type de véhicule, tranche de distance routière, plage horaire/jour, point relais (dimension présente, inutilisée au MVP)} à des **sorties** {prix client (base + FCFA/km au-delà d'un seuil), part coursier, **marge Mefali**, devise}, plus une **priorité**, des **dates d'effet** et un drapeau **actif**. La **marge Mefali est bornée par la zone** (défaut 25–100 FCFA, bornes éditables par zone) : une règle dont la marge sort des bornes est **refusée** — elle ne peut pas être enregistrée telle quelle dans un brouillon publiable. Les règles sont éditées dans une **grille brouillon** distincte de la grille en vigueur.

**Why this priority**: Sans modèle de règles, il n'y a rien à évaluer : c'est le catalogue tarifaire dont tout le reste dérive. La borne de marge est la garde qui empêche une grille économiquement absurde d'atteindre la production. Foncièrement autonome (la config de zone existe déjà), livrable et testable seul.

**Independent Test**: Créer un brouillon de grille pour une zone, y ajouter une règle bien formée et vérifier qu'elle est acceptée avec sa priorité et ses dates d'effet ; modifier sa marge pour la porter hors des bornes de la zone et vérifier qu'elle est refusée — sans qu'aucune évaluation, simulation ni publication ne soit livrée.

**Acceptance Scenarios**:

1. **Given** une zone dont les bornes de marge sont 25–100, **When** l'Admin ajoute une règle {véhicule, tranche de distance, plage horaire} → {prix client, part coursier, marge 75, devise de la zone} avec priorité et dates d'effet, **Then** la règle est acceptée dans le brouillon.
2. **Given** la même zone, **When** l'Admin saisit une règle de marge 110 (hors borne 100), **Then** la règle est refusée et signalée comme hors bornes ; le brouillon ne peut pas être publié tant qu'elle subsiste.
3. **Given** deux règles également applicables à une même situation, **When** l'évaluation devra choisir, **Then** la règle **la plus spécifique**, de **priorité** supérieure et **en vigueur à la date/heure** considérée est celle qui fera foi (départage déterministe).
4. **Given** une règle portant une dimension **point relais**, **When** on l'édite au MVP, **Then** cette dimension reste **présente mais jamais renseignée** (provision, aucune logique de point relais).

---

### User Story 2 - Calculer un devis figé sur un itinéraire routier multi-arrêts (TRF-02, Priority: P1 — produit : P0)

À partir d'une course — un coursier, un véhicule, une suite d'arrêts de collecte et une remise chez le client — le moteur calcule la **distance et l'ETA par itinéraire routier réel** (OSRM avec **waypoints** sur l'itinéraire **retraits → client** en ordre optimisé ; la jambe d'approche du coursier est hors devis client — cf. FR-013), sélectionne la **règle la plus spécifique en vigueur**, applique les **suppléments activés** (pluie via le drapeau de zone, plage horaire, longue distance), **arrondit** (pas de 25 FCFA), puis **fige** le devis {prix client, part coursier, marge}. Le résultat de routage est **mis en cache** (paire de points arrondis, 24 h). Si le routage est **indisponible**, le moteur bascule en **dégradé** : distance à vol d'oiseau **× 1,4**, marquée `degraded=true` et **journalisée** — une commande n'est **jamais bloquée** par le routage. Les **drapeaux de zone** s'appliquent ensuite : « livraison offerte Mefali » → **prix client = 0** ; « gratuité commissions » → **marge = 0**. La **livraison offerte par le vendeur (VND-08)** s'applique **après** le drapeau de zone, pour les commandes **mono-vendeur uniquement**.

**Why this priority**: C'est le cœur du module — la fonction qui transforme une course en argent, sur des **kilomètres réels** et jamais à vol d'oiseau (sauf dégradé tracé). Avec la story 1, elle forme la tranche minimale viable : on peut tarifer une livraison. Le devis figé est la brique que CMD verrouillera à la création de commande.

**Independent Test**: Simuler une course multi-arrêts affectée à un coursier, appeler l'évaluation et vérifier que la distance provient d'un **itinéraire avec waypoints** (et non d'un vol d'oiseau), que la règle retenue est la plus spécifique en vigueur, que les suppléments et l'arrondi sont appliqués, et que le devis {prix client, part coursier, marge} est **figé** ; couper le routage et vérifier la bascule **dégradée ×1,4 journalisée** sans blocage ; rejouer la même paire de points et vérifier le **cache** ; activer le drapeau « livraison offerte Mefali » et vérifier **prix client = 0**.

**Acceptance Scenarios**:

1. **Given** une course à trois arrêts et une remise, un véhicule et une zone couverts par une règle en vigueur, **When** on évalue, **Then** la distance et l'ETA proviennent de l'**itinéraire routier complet avec waypoints** (retraits → client, en ordre optimisé) et le devis {prix client, part coursier, marge} est figé, avec sa devise.
2. **Given** une même paire de points arrondis déjà évaluée il y a moins de 24 h, **When** on ré-évalue, **Then** le résultat de routage provient du **cache** (aucun nouvel appel de routage nécessaire).
3. **Given** le service de routage indisponible, **When** on évalue, **Then** la distance est calculée à **vol d'oiseau × 1,4**, le devis est marqué `degraded=true`, l'événement de dégradé est **journalisé**, et la commande **n'est pas bloquée**.
4. **Given** une zone dont le drapeau **« livraison offerte Mefali »** est ON, **When** on évalue, **Then** le **prix client est forcé à 0** (la part coursier reste calculée et journalisée) ; **Given** le drapeau **« gratuité commissions »** ON, **Then** la **marge est 0** (prix client = part coursier).
5. **Given** une commande **mono-vendeur** dont le vendeur offre la livraison (VND-08), **When** on évalue après application du drapeau de zone, **Then** le **prix client passe à 0** (ou 0 au-delà du seuil du vendeur) et la **part coursier reste inchangée** ; **Given** un panier **multi-vendeurs**, **Then** VND-08 ne s'applique pas et les frais restent normaux.
6. **Given** un devis calculé, **When** on inspecte les montants, **Then** l'**invariant** est vérifié : prix client = part coursier + marge Mefali (hors mise à 0 par drapeau/VND-08), la marge reste **dans les bornes** de la zone, et l'arrondi respecte le pas de 25 FCFA.

---

### User Story 3 - Simuler un brouillon avant de le publier (TRF-03, Priority: P2 — produit : P0)

Avant de publier une nouvelle grille, l'Admin la **simule** : il choisit un ou plusieurs vendeurs (les arrêts), une destination, un véhicule et une heure, et le moteur rejoue le **brouillon** sur cette course réelle et renvoie le **détail complet** — itinéraire utilisé (et s'il est dégradé), règle retenue, chaque composante (base, km, suppléments, effort), retenue vendeur éventuelle, arrondi, et le devis final. La **publication est gardée** : un brouillon ne peut devenir la grille en vigueur que si **au moins une simulation a été exécutée** dessus **et** qu'**aucune règle n'est hors bornes**. Publier fixe la grille et sa **date d'entrée en vigueur** ; l'ancienne grille reste l'historique versionné.

**Why this priority**: C'est la porte qui empêche une grille fausse d'atteindre la production — l'Admin voit le prix réel sur une vraie course avant d'engager la zone. Story P0 du produit, elle s'appuie sur les stories 1 et 2 (il faut des règles et une évaluation à rejouer).

**Independent Test**: Créer un brouillon comportant une règle hors bornes, tenter de le publier et vérifier que la publication est **refusée** ; corriger la règle, lancer une **simulation** sur une course (vendeurs + destination + véhicule + heure) et vérifier que le **détail complet** est renvoyé (itinéraire, règle, composantes, arrondi) ; publier et vérifier que la grille devient la grille **en vigueur** à sa date d'effet, l'ancienne étant conservée.

**Acceptance Scenarios**:

1. **Given** un brouillon de grille et une course (un ou plusieurs vendeurs, destination, véhicule, heure), **When** l'Admin simule, **Then** le moteur renvoie le détail complet : itinéraire utilisé (dégradé ou non), règle retenue, composantes (base, km, suppléments, effort), retenue vendeur éventuelle, arrondi, et le devis final — **sans** modifier la grille en vigueur.
2. **Given** un brouillon **jamais simulé**, **When** l'Admin tente de le publier, **Then** la publication est **refusée** (simulation obligatoire non satisfaite).
3. **Given** un brouillon contenant **une règle hors bornes**, **When** l'Admin tente de le publier, **Then** la publication est **refusée** tant que la règle n'est pas corrigée, même si une simulation a été faite.
4. **Given** un brouillon simulé et sans règle hors bornes, **When** l'Admin le publie, **Then** il devient la grille **en vigueur** à sa date d'entrée en vigueur et la grille précédente est **conservée** (historique versionné).

---

### User Story 4 - Servir la grille de départ de Tiassalé (TRF-05, Priority: P2 — produit : P0)

La zone de Tiassalé est livrée avec une **grille seed éditable**, calculée sur **distances routières** : à pied **100** (≤ 800 m) ; vélo **150** (≤ 2 km) ; moto **base 200** jusqu'à 2 km **+ 50/km au-delà**, **plafond 500** ; supplément **pluie +100** (drapeau OFF par défaut) ; **marge 0** au lancement, puis **50**. Le drapeau **« livraison offerte Mefali »** est **ON à l'ouverture** et passera **OFF à la date annoncée**. Cette grille est un **seed rejouable et versionné** (constitution I), éditable ensuite par l'Admin comme n'importe quelle grille.

**Why this priority**: C'est la grille concrète qui permet à Tiassalé de fonctionner le premier jour ; elle pin les montants de lancement pour qu'ils soient vérifiables. Story P0, elle dépend du modèle de règles (story 1) et de l'évaluation (story 2) pour avoir un sens.

**Independent Test**: Charger le seed de Tiassalé et, via l'évaluation ou la simulation, vérifier chaque valeur : 100 à pied ≤ 800 m ; 150 vélo ≤ 2 km ; moto 200 jusqu'à 2 km puis +50/km avec plafond 500 ; pluie +100 quand le drapeau est ON ; marge 0 au lancement ; drapeau « livraison offerte Mefali » ON à l'ouverture. Rejouer le seed et constater qu'il est idempotent.

**Acceptance Scenarios**:

1. **Given** la zone Tiassalé seedée, **When** on tarife une course moto de 4 km, **Then** le prix client de déplacement est **200 + 2×50 = 300** (base 2 km + 2 km au-delà), plafonné à 500 le cas échéant.
2. **Given** Tiassalé au lancement, **When** on tarife n'importe quelle course, **Then** la **marge est 0** et le drapeau **« livraison offerte Mefali » est ON** (prix client = 0 à l'affichage, part coursier calculée) ; après la bascule annoncée, la marge devient **50** et le drapeau passe OFF.
3. **Given** le drapeau **pluie** activé manuellement, **When** on tarife une course, **Then** **+100** s'ajoute ; drapeau OFF, aucun supplément pluie.
4. **Given** le seed déjà appliqué, **When** on le rejoue, **Then** l'opération est **idempotente** (aucune duplication de règle).

---

### User Story 5 - Porter et formater la devise par zone (TRF-04, Priority: P2 — produit : P0)

Chaque zone porte sa **devise** en **code ISO 4217** ; tous les montants (règles, suppléments, devis, effort) sont des **entiers en unités mineures** dans cette devise. Pour Tiassalé, la devise est **XOF, sans décimales**. Les montants sont **formatés localement** (pas de séparateur décimal pour XOF). **Aucune conversion** de devise n'a lieu au MVP : une grille, un devis et une commande vivent entièrement dans une seule devise, celle de leur zone ; le modèle est **prêt pour une expansion** hors zone CFA mais n'exerce aucune conversion.

**Why this priority**: C'est la garantie que l'argent est toujours exact et non ambigu, et que la plateforme est prête à sortir de la zone CFA sans refonte. Story P0 ; elle s'appuie sur la discipline monétaire déjà transverse (constitution III) et l'étend au choix de devise par zone.

**Independent Test**: Vérifier qu'une règle et un devis portent le code ISO 4217 de leur zone ; que les montants XOF s'affichent sans décimale et se calculent en unités mineures entières ; qu'aucune conversion n'est effectuée et qu'un mélange de devises entre zones est rejeté plutôt que converti.

**Acceptance Scenarios**:

1. **Given** la zone Tiassalé (XOF), **When** on lit une règle ou un devis, **Then** le montant est un entier en unités mineures assorti du code **XOF** et s'affiche **sans décimale**.
2. **Given** deux zones de devises différentes, **When** une opération tenterait de mêler leurs montants, **Then** elle est **rejetée** (aucune conversion au MVP), pas silencieusement convertie.
3. **Given** le formatage localisé, **When** on affiche un prix, **Then** il respecte les conventions de la devise de la zone (XOF : pas de décimale).

---

### User Story 6 - Rémunérer l'effort et optimiser l'ordre des arrêts (TRF-06, Priority: P3 — produit : P1)

En plus du déplacement, le moteur calcule la **grille d'effort** — trois composantes **éditables par zone**, **100 % reversées au coursier** (la marge Mefali reste inchangée), **détaillées au client avant confirmation** et sur l'**écran d'offre coursier** :

1. **Paliers d'articles** : 1–5 : 0 ; 6–10 : +50 ; 11–20 : +100 ; 21+ : +150 (seeds éditables).
2. **Prime d'attente mesurée** : écart (scan QR − arrivée géolocalisée) **> 15 min → +100** **une seule fois par course** (clarification 2026-07-24), calculée sur des événements déjà tracés (infalsifiable).
3. **Supplément par arrêt supplémentaire, indexé sur la distance au précédent** : **< 100 m → +25** ; **100 m–1 km → +50** ; **> 1 km → +100** (seeds éditables) ; **premier arrêt inclus** dans le prix de base ; **plafond optionnel** du total des suppléments par commande.

La **distance** n'est **jamais** couverte par le supplément d'arrêt : la composante kilométrique reste calculée sur l'**itinéraire complet avec waypoints** (TRF-02). L'**ordre des arrêts est optimisé** automatiquement (permutations, trivial ≤ 4 arrêts) et cette optimisation est **exposée au dispatch et aux commandes**. Un **plafond d'éclatement** paramétrable : quand le détour total dépasse le seuil, l'app **propose au client de scinder** en plusieurs commandes. Pendant le drapeau **« livraison offerte Mefali »** (promo), la grille d'effort est **calculée et journalisée mais non facturée** ; elle s'active à la bascule au paiement à la course.

**Why this priority**: C'est ce qui rend le métier soutenable pour le coursier (les grosses listes et les paniers dispersés sont rémunérés au juste effort) et acceptable pour le client (arrêts voisins au marché quasi gratuits). Produit P1, requise **avant la fin de la promo** ; elle vient après le socle du moteur car elle s'ajoute au devis routé de la story 2.

**Independent Test**: Simuler une course de 12 articles chez 3 étals voisins du marché et vérifier le total : km réels (quasi nuls entre étals) + 2×25 (arrêts voisins) + 100 (palier 11–20) ; simuler une course à 4 arrêts dispersés et vérifier que l'**ordre est optimisé** (meilleure permutation) et que le **plafond d'éclatement** déclenche la **proposition de scinder** au-delà du seuil ; provoquer une attente > 15 min à un ou plusieurs arrêts et vérifier **+100 une seule fois pour la course** ; vérifier que **100 %** de l'effort va à la **part coursier** (marge inchangée) et que, drapeau promo ON, l'effort est **journalisé mais non facturé**.

**Acceptance Scenarios**:

1. **Given** une commande de 12 articles chez 3 étals **voisins** (< 100 m entre eux), **When** on tarife, **Then** l'effort = **2 × 25** (arrêts voisins supplémentaires) **+ 100** (palier 11–20 articles), le premier arrêt étant inclus, et la composante déplacement reste sur les km réels de l'itinéraire.
2. **Given** une course à **4 arrêts** dispersés, **When** on tarife, **Then** l'**ordre des arrêts est optimisé** (meilleure permutation retenue) et cette optimisation est **exposable** au dispatch et aux commandes ; **Given** un détour total au-delà du **plafond d'éclatement**, **Then** l'app **propose de scinder** en plusieurs commandes.
3. **Given** une course où l'attente dépasse 15 min (écart arrivée géolocalisée − scan QR) à **un ou plusieurs** arrêts, **When** on tarife, **Then** la **prime d'attente +100** s'ajoute **une seule fois pour la course** (au plus +100), calculée sur les événements tracés.
4. **Given** n'importe quelle composante d'effort, **When** on répartit le devis, **Then** **100 %** de l'effort abonde la **part coursier** et la **marge Mefali est inchangée** ; l'effort est **détaillé** au devis client et à l'offre coursier.
5. **Given** la zone en **promo** (drapeau « livraison offerte Mefali » ON), **When** on tarife, **Then** la grille d'effort est **calculée et journalisée** mais **non facturée** ; à la bascule au paiement à la course, elle **s'active**.
6. **Given** un **plafond du total des suppléments d'arrêt** configuré pour la zone, **When** les suppléments cumulés le dépassent, **Then** le total d'effort d'arrêt est **plafonné** à cette valeur.

---

### Edge Cases

- **Aucune règle applicable** : si aucune règle en vigueur ne couvre la situation (zone/véhicule/distance/heure), l'évaluation ne fabrique pas un prix arbitraire — elle échoue explicitement (à traiter par l'appelant), plutôt que de renvoyer un devis silencieusement faux.
- **Marge hors bornes au moment de l'évaluation** : une règle publiée ne peut pas être hors bornes (gardée à l'édition et à la publication) ; si les bornes de zone changent après publication, une règle devenue hors bornes est signalée et ne peut pas alimenter une nouvelle publication.
- **Départage de règles à égalité** : deux règles également spécifiques, de même priorité et toutes deux en vigueur → un critère de départage **déterministe** tranche (jamais un choix non reproductible), pour que le devis soit stable et rejouable.
- **Routage partiellement dégradé** : si le routage répond pour certains tronçons et pas d'autres, la course entière bascule en dégradé cohérent (×1,4 sur la portion manquante ou sur le tout) et le devis est marqué `degraded=true` — jamais un mélange non tracé.
- **Cache périmé ou points quasi identiques** : deux points qui s'arrondissent à la même clé partagent le cache ; au-delà de 24 h, le routage est recalculé — le devis ne s'appuie jamais sur un routage périmé sans le savoir.
- **Drapeaux cumulés** : « livraison offerte Mefali » (prix client 0) **et** « gratuité commissions » (marge 0) simultanés → prix client 0 et marge 0, la part coursier restant calculée et journalisée (payée au fixe hors moteur pendant la promo).
- **VND-08 sur panier multi-vendeurs** : la livraison offerte vendeur ne s'applique **jamais** à un panier multi-vendeurs (règle simple anti-litige de retenue) — les frais restent normaux.
- **Plafond d'éclatement atteint** : au-delà du détour maximal, l'app **propose** de scinder mais ne scinde pas d'office — la décision revient au client (la mécanique de scission est côté CMD).
- **Optimisation au-delà de 4 arrêts** : la permutation exhaustive est triviale jusqu'à 4 arrêts ; au-delà, l'ordre reste optimisé par une méthode bornée (pas d'explosion combinatoire), l'exhaustivité éventuellement abandonnée étant **explicite**, jamais un ordre silencieusement sous-optimal présenté comme optimal.
- **Prime d'attente sans les deux horodatages** : si l'arrivée géolocalisée **ou** le scan manque, la prime d'attente n'est pas inventée (0 par défaut) — elle ne se calcule que sur deux événements réellement tracés.
- **Prime d'attente sur plusieurs arrêts lents** : même si l'attente dépasse 15 min à deux ou trois arrêts d'une même course, la prime reste **plafonnée à +100 pour la course** (décision de clarification du 2026-07-24), jamais cumulée par arrêt.
- **Arrondi et mise à 0** : l'arrondi (25 FCFA) ne s'applique pas pour « rattraper » un prix client forcé à 0 par un drapeau ou VND-08 — 0 reste 0.
- **Course sans arrêt de collecte** (remise directe, un seul point) : le premier arrêt est inclus, aucun supplément d'arrêt ; le devis reste bien formé.

## Requirements *(mandatory)*

### Functional Requirements

#### Cadre transverse

- **FR-001**: Toute chaîne destinée à l'utilisateur (libellés du simulateur, messages de refus de publication, mentions « hors bornes », « livraison offerte », détail des composantes) DOIT être une clé i18n fr, jamais un texte en dur.
- **FR-002**: Tout montant (prix client, part coursier, marge, suppléments, effort, bornes, seuils, plafonds) DOIT être un **entier en unités mineures** assorti du **code ISO 4217** porté par la zone ; **aucun flottant** pour l'argent, **aucun chemin partiel**.
- **FR-003**: Toute transition ou opération journalisable de ce cycle — **publication d'une grille**, **recours au dégradé de routage**, **calcul d'effort non facturé pendant la promo** — DOIT écrire un **événement outbox dans la même transaction** que l'opération, et les événements DOIVENT être déclarés dans `docs/taxonomie-evenements.md` avant implémentation (constitution VI).
- **FR-004**: Tous les paramètres métier de ce cycle — bornes de marge (défaut 25–100), pas d'arrondi (25), facteur dégradé (×1,4), TTL du cache de routage (24 h), drapeaux de zone, seeds de la grille d'effort, seuil du plafond d'éclatement, plafond des suppléments d'arrêt — DOIVENT être des **paramètres de zone hérités**, jamais des valeurs en dur (constitution I).
- **FR-005**: Les écritures d'administration (édition de brouillon, simulation, publication de grille) DOIVENT être **protégées par le rôle admin** et **journalisées** (qui, quand), selon le précédent des cycles 002/003/005.

#### Configuration de zone consommée (dépendance cycle 002, non reconstruite)

- **FR-006**: Ce cycle DOIT stocker et résoudre ses paramètres (règles, drapeaux, bornes, devise, seeds, seuils) comme **configuration de zone à héritage parent → enfant** déjà fournie par le cycle 002 ; il NE DOIT PAS réimplémenter de mécanisme de stockage ou d'héritage parallèle.
- **FR-007**: Le drapeau de zone **`livraison_offerte_mefali`** (déjà seedé pour Tiassalé) et le drapeau **« gratuité commissions »** DOIVENT être consommés tels quels ; ce cycle en applique l'effet tarifaire sans redéfinir leur stockage.

#### TRF-01 — Modèle de règles

- **FR-008**: Le système DOIT permettre de définir des **règles** dont les **conditions** sont {zone, catégorie (optionnelle), type de véhicule, tranche de distance **routière**, plage horaire/jour, point relais (dimension présente, inutilisée)} et les **sorties** {prix client (base + FCFA/km au-delà d'un seuil), part coursier, **marge Mefali**, **devise**}, assorties d'une **priorité**, de **dates d'effet** et d'un drapeau **actif**.
- **FR-009**: La **marge Mefali** de chaque règle DOIT être **bornée par la zone** (défaut 25–100, bornes éditables par zone) ; une règle dont la marge **viole les bornes DOIT être refusée** et ne peut alimenter un brouillon publiable.
- **FR-010**: L'évaluation DOIT sélectionner la règle **la plus spécifique**, de **priorité** supérieure et **en vigueur** à la date/heure considérée ; à égalité stricte, un critère de départage **déterministe** DOIT trancher (devis rejouable).
- **FR-011**: La dimension **point relais** DOIT exister dans le modèle de règles mais rester **jamais renseignée ni utilisée** au MVP (provision — aucune UI, aucune logique ; constitution IX).
- **FR-012**: Les règles DOIVENT être éditées dans une **grille brouillon** distincte de la **grille en vigueur** ; l'édition d'un brouillon NE DOIT PAS affecter la tarification en cours.

#### TRF-02 — Évaluation routée & devis figé

- **FR-013**: La **distance et l'ETA** DOIVENT être calculées par **itinéraire routier réel** via le service de routage configuré, avec **points de passage (waypoints)** : le moteur tarife **l'itinéraire complet des retraits vers le client** (arrêt 1 → … → arrêt n → client) dans l'**ordre optimisé** (FR-031). La **jambe d'approche coursier → 1er retrait est exclue du devis client** — le devis est produit **avant dispatch** (CMD-01, « frais avant confirmation »), donc sans coursier assigné, et le simulateur (TRF-03) comme la maquette A3 prennent « vendeur(s) + destination », pas de coursier ; la distance d'approche du coursier relève du dispatch (DSP). **Jamais** de vol d'oiseau hors mode dégradé (constitution IV).
- **FR-014**: Les résultats de routage DOIVENT être **mis en cache** par **paire de points arrondis**, avec un **TTL de 24 h** ; une paire déjà connue dans la fenêtre NE DOIT PAS déclencher un nouvel appel de routage.
- **FR-015**: Si le service de routage est **indisponible**, l'évaluation DOIT basculer en **dégradé** : distance à **vol d'oiseau × 1,4**, devis marqué **`degraded=true`**, événement **journalisé** ; une commande **NE DOIT JAMAIS être bloquée** par le routage.
- **FR-016**: L'évaluation DOIT appliquer les **suppléments activés** (pluie via drapeau de zone, plage horaire, longue distance), puis l'**arrondi** au pas configuré (25 FCFA) **appliqué au prix client**, dont le **reliquat abonde la part coursier** (marge fixe — §9.3 « la marge Mefali reste fixe », §7.5 « le coursier ne perd jamais »), et **figer** le devis {prix client, part coursier, marge, devise, distance, ETA, `degraded`}. L'arrondi ne s'applique pas pour « rattraper » un prix client forcé à 0 par un drapeau ou VND-08 (0 reste 0).
- **FR-017**: Après le calcul de base, les **drapeaux de zone** DOIVENT s'appliquer : **« livraison offerte Mefali »** → **prix client = 0** (part coursier calculée et journalisée) ; **« gratuité commissions »** → **marge = 0** (prix client = part coursier).
- **FR-018**: La **livraison offerte par le vendeur (VND-08)** DOIT s'appliquer **après** le drapeau de zone et **seulement** pour les commandes **mono-vendeur** : prix client → **0** (ou 0 au-delà du seuil du vendeur), **part coursier inchangée** ; sur un panier **multi-vendeurs**, VND-08 **ne s'applique pas**. Ce cycle **réserve et exerce le créneau de calcul** de VND-08 (avec une entrée de configuration vendeur simulée dans les tests) ; la **configuration vendeur** {jamais/toujours/seuil} et son **financement par retenue à la source** relèvent des cycles VND et PAY (hors périmètre — voir Assumptions).
- **FR-019**: Le devis figé DOIT respecter l'**invariant** prix client = part coursier + marge Mefali (hors mise à 0 par drapeau/VND-08), avec la marge **dans les bornes** de la zone. La **marge Mefali est fixe par règle** ; la **part variable au km**, la **grille d'effort** et le **reliquat d'arrondi** abondent la **part coursier**, jamais la marge (§9.3).

#### TRF-03 — Simulateur obligatoire

- **FR-020**: Le système DOIT fournir un **simulateur** qui, pour {un ou plusieurs vendeurs (arrêts), une destination, un véhicule, une heure}, rejoue le **brouillon** et renvoie le **détail complet** : itinéraire utilisé (et `degraded` le cas échéant), règle retenue, **composantes** (base, km, suppléments, effort), **retenue vendeur** éventuelle, **arrondi**, et le **devis final** — **sans** modifier la grille en vigueur.
- **FR-021**: La **publication** d'un brouillon DOIT être **gardée** : elle N'EST autorisée QUE si **au moins une simulation a été exécutée** sur ce brouillon **et** qu'**aucune règle n'est hors bornes**. **Toute modification du brouillon postérieure à une simulation réarme l'obligation** — la simulation doit refléter le contenu exact qui sera publié (maquette A3). Sinon la publication est **refusée** (simulateur obligatoire avant publication).
- **FR-022**: Publier un brouillon DOIT en faire la **grille en vigueur** à sa **date d'entrée en vigueur** et **conserver** la grille précédente comme **historique versionné**.

#### TRF-04 — Devises par zone

- **FR-023**: Chaque **zone** DOIT porter sa **devise** en **code ISO 4217** ; toute règle, tout devis et tout montant d'effort héritent de cette devise ; **XOF** est **sans décimales**.
- **FR-024**: Les montants DOIVENT être **formatés localement** selon la devise de la zone (XOF : aucune décimale). *Ce cycle fournit le substrat — code ISO 4217 + montants en unités mineures ; le **rendu localisé** (séparateurs, position du symbole) relève des consommateurs UI (CMD/apps), non construits ici (cf. « Surface d'interface »).*
- **FR-025**: **Aucune conversion** de devise NE DOIT être effectuée au MVP ; une opération qui mêlerait des montants de devises différentes DOIT être **rejetée**, pas convertie. Le modèle reste **prêt pour une expansion** hors zone CFA (provision, aucune logique de conversion).

#### TRF-05 — Grille de départ Tiassalé

- **FR-026**: Le système DOIT fournir un **seed rejouable et versionné** de la grille de Tiassalé, sur **distances routières** : à pied **100** (≤ 800 m) ; vélo **150** (≤ 2 km) ; moto **base 200** jusqu'à 2 km **+ 50/km** au-delà, **plafond 500** ; **pluie +100** (drapeau OFF par défaut) ; **marge 0** au lancement puis **50** ; drapeau **« livraison offerte Mefali » ON à l'ouverture**, OFF à la date annoncée.
- **FR-027**: Le seed DOIT être **éditable** ensuite comme toute grille et **idempotent** au rejeu (aucune duplication de règle), séparé des migrations de schéma (constitution I).

#### TRF-06 — Grille d'effort & optimisation de l'ordre des arrêts

- **FR-028**: Le système DOIT calculer la **grille d'effort** à trois composantes, **éditables par zone** et **100 % reversées à la part coursier** (marge Mefali inchangée) : (1) **paliers d'articles** 1–5 : 0 ; 6–10 : +50 ; 11–20 : +100 ; 21+ : +150 ; (2) **prime d'attente** — si l'écart (scan QR − arrivée géolocalisée) dépasse 15 min à **au moins un** arrêt, **+100 une seule fois par course** (au plus +100, quel que soit le nombre d'arrêts en attente — clarification 2026-07-24) ; (3) **supplément par arrêt supplémentaire indexé sur la distance au précédent** : < 100 m → +25 ; 100 m–1 km → +50 ; > 1 km → +100, **premier arrêt inclus**, **plafond optionnel** du total des suppléments par commande.
- **FR-029**: Le supplément d'arrêt NE DOIT **jamais** couvrir la **distance** : la composante kilométrique reste calculée sur l'**itinéraire complet avec waypoints** (FR-013). Le barème de supplément DOIT classer la **« distance au précédent arrêt »** sur le **tronçon routier** entre arrêts consécutifs de l'itinéraire optimisé (sous-produit du routage à waypoints, constitution IV — jamais un vol d'oiseau). La **prime d'attente** DOIT se calculer **uniquement** à partir des événements tracés (arrivée géolocalisée, scan QR) et s'appliquer **une seule fois par course** ; à défaut des deux horodatages, elle vaut **0** (jamais inventée).
- **FR-030**: L'effort DOIT être **détaillé** (composante par composante) au **devis client avant confirmation** et sur l'**écran d'offre coursier** (part effort du gain total). *(Consommé par CMD/DSP/CRS — ici exposé comme capacité et exercé par API/tests.)*
- **FR-031**: Le moteur DOIT **optimiser l'ordre des arrêts** en **minimisant la distance routière totale** de l'itinéraire retraits → client (§9.3 « km réels » / « détour total »), de façon **déterministe et rejouable** — permutations, exhaustif ≤ 4 arrêts ; au-delà, méthode bornée **explicite** (jamais un ordre sous-optimal présenté comme optimal) — et **exposer** cet ordre optimisé au **dispatch (DSP)** et aux **commandes (CMD)**. Faute de ces modules, l'ordre optimisé est produit et **exercé par des itinéraires simulés dans les tests**.
- **FR-032**: Un **plafond d'éclatement** paramétrable par zone DOIT, lorsque le **détour total dépasse le seuil**, produire un signal invitant à **proposer au client de scinder** la commande (la scission elle-même relève de CMD ; ce cycle **propose**, ne scinde pas).
- **FR-033**: Pendant le drapeau **« livraison offerte Mefali »** (promo), la grille d'effort DOIT être **calculée et journalisée** mais **non facturée** ; à la bascule au paiement à la course, elle **s'active** (facturée au client, versée au coursier).

#### Transverse — routage & cache

- **FR-034**: Ce cycle DOIT construire le **client de routage** qui interroge le serveur OSRM déjà provisionné (waypoints), **sans** provisionner ni modifier le serveur ; c'est le **premier consommateur de routage tarifaire** du dépôt.
- **FR-035**: Le cache de routage DOIT vivre dans l'infrastructure **Redis** existante (éphémère reconstructible, constitution II), dans son propre espace, avec la clé « paire de points arrondis » et le TTL 24 h (FR-014).

#### Hors périmètre explicite

- **FR-036**: Ce cycle NE DOIT construire ni la **console admin** (écrans de la maquette A3 — cycle ADM), ni le **verrouillage des prix à la création de commande** ni l'affichage client du total (CMD), ni l'**écran d'offre coursier** (DSP/CRS), ni la **scission effective** d'une commande (CMD), ni la **configuration vendeur** de la livraison offerte et son **financement par retenue à la source** (VND-08 config + PAY), ni la **commission vendeur** (PAY-06, P2), ni aucune **conversion de devise** (provision). Il **produit et expose** le devis, le détail d'effort et l'ordre optimisé consommés par ces cycles.

### Key Entities *(include if feature involves data)*

- **Grille tarifaire (versionnée)** *(nouveau)* : ensemble de règles d'une zone, à l'état **brouillon** ou **en vigueur**, avec **version**, **date d'entrée en vigueur** et **statut de simulation** (a-t-elle été simulée) ; la publication garde l'historique.
- **Règle tarifaire** *(nouveau)* : conditions {zone, catégorie?, véhicule, tranche de distance routière, plage horaire/jour, point relais (provision)} → sorties {prix client (base + FCFA/km au-delà d'un seuil), part coursier, marge Mefali, devise} + priorité, dates d'effet, actif. Marge bornée par la zone.
- **Bornes de marge de zone** *(paramètre de zone)* : min/max de la marge Mefali (défaut 25–100), éditables par zone ; gardent l'édition et la publication.
- **Drapeaux de zone** *(paramètres de zone, existants)* : `livraison_offerte_mefali` (prix client 0), gratuité commissions (marge 0), pluie (supplément) — consommés, non redéfinis.
- **Devis figé** *(nouveau)* : résultat d'évaluation d'une course — {prix client, part coursier, marge, **devise**}, **distance** et **ETA** routières, drapeau **`degraded`**, détail des **composantes** (base, km, suppléments, **effort** décomposé), ordre d'arrêts retenu. Destiné à être **verrouillé** par CMD.
- **Résultat de routage (caché)** *(nouveau, Redis)* : distance/ETA d'une **paire de points arrondis**, TTL 24 h, indicateur dégradé — éphémère reconstructible.
- **Grille d'effort** *(paramètres de zone + calcul)* : paliers d'articles, prime d'attente, barème de supplément d'arrêt (par tranche de distance au précédent), premier arrêt inclus, plafond des suppléments, plafond d'éclatement ; 100 % coursier.
- **Livraison offerte vendeur (VND-08)** *(entrée consommée, config hors périmètre)* : réglage {jamais/toujours/à partir de X} appliqué au prix client des commandes mono-vendeur ; ici **entrée** du calcul (simulée en tests), la configuration et le financement relevant de VND/PAY.
- **Course / itinéraire multi-arrêts** *(structure consommée/simulée)* : coursier + véhicule + suite d'arrêts (collectes) + remise client, dans l'ordre **optimisé** ; conforme au modèle `livraison → segment → arrêt` (docs §CMD/§7.3) ; produite par CMD/DSP à terme, **simulée** ici.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100 % des règles publiées respectent les bornes de marge de leur zone : une règle hors bornes ne peut jamais atteindre une grille en vigueur.
- **SC-002**: 100 % des devis calculés en fonctionnement nominal reposent sur une **distance d'itinéraire routier réel avec waypoints** — 0 % de vol d'oiseau non marqué ; toute distance non routière porte `degraded=true` et un événement journalisé.
- **SC-003**: Une indisponibilité du routage ne bloque **aucune** commande : 100 % des évaluations aboutissent, en dégradé ×1,4 tracé si nécessaire.
- **SC-004**: Une paire de points déjà routée dans les 24 h est resservie par le cache sans nouvel appel de routage (réduction mesurable des appels sur trajets répétés).
- **SC-005**: Aucune grille ne peut être publiée sans avoir été simulée au moins une fois **et** exempte de règle hors bornes — 100 % des publications satisfont la porte du simulateur.
- **SC-006**: Le simulateur reproduit **exactement** les montants de la grille de Tiassalé seedée (à pied 100 ≤ 800 m ; vélo 150 ≤ 2 km ; moto 200 + 50/km, plafond 500 ; pluie +100 ; marge 0 puis 50), vérifiables au FCFA près.
- **SC-007**: 100 % de la grille d'effort abonde la **part coursier** ; la **marge Mefali** est strictement inchangée par l'effort, vérifiable sur tout devis.
- **SC-008**: Pour une commande de 12 articles chez 3 étals voisins (< 100 m), l'effort vaut exactement **2×25 + 100** et la distance reste sur les km réels — le marché n'est ni punitif pour le client ni perdant pour le coursier.
- **SC-009**: Pour toute course ≤ 4 arrêts, l'**ordre retenu est le meilleur** parmi les permutations, de façon **déterministe et rejouable**, et cet ordre est exposable au dispatch et aux commandes.
- **SC-010**: Pendant la promo (drapeau « livraison offerte Mefali » ON), 100 % des courses ont un prix client de livraison à **0** et une grille d'effort **journalisée mais non facturée** ; à la bascule, l'effort devient facturé sans changement de code (paramètre de zone).
- **SC-011**: Tout montant de ce module est un entier en unités mineures avec sa devise ISO 4217 ; aucune conversion n'a lieu et un mélange de devises est rejeté, 100 % du temps.
- **SC-012**: Le devis figé vérifie l'invariant prix client = part coursier + marge (hors mise à 0 par drapeau/VND-08) sur 100 % des évaluations nominales.

## Assumptions

- **Invariant de composition du devis** : prix client = part coursier + marge Mefali ; la **marge est fixe par règle** (bornée par zone), et la **part variable au km**, la **grille d'effort** (100 % coursier) et le **reliquat d'arrondi** abondent la **part coursier** — jamais la marge. Dérivé de la maquette A3 (ex. Centre-ville moto 0–2 km : 500 = 425 + 75 ; marges fixes par ligne), de §9.3 (« la marge Mefali reste fixe ») et de §7.5 (« le coursier ne perd jamais »).
- **Ordre du pipeline d'évaluation** : règle la plus spécifique en vigueur → composante km sur l'**itinéraire complet retraits → client** en ordre optimisé (FR-013/FR-031) → suppléments (pluie/horaire/longue distance) → grille d'effort (articles + supplément d'arrêt ajoutés client+coursier ; **prime d'attente une seule fois par course**) → arrondi (25 FCFA, reliquat → part coursier) → drapeaux de zone (livraison offerte Mefali : prix client 0 ; gratuité : marge 0) → VND-08 (après drapeau, mono-vendeur). Le devis est ensuite figé. L'arrondi ne « rattrape » jamais un 0 forcé.
- **VND-08 réservé, non configuré ici** : ce cycle construit et teste l'**application** de la livraison offerte vendeur dans le devis (créneau, garde mono-vendeur, mise à 0 du prix client, part coursier préservée) en consommant une **entrée simulée** ; la **configuration vendeur** {jamais/toujours/à partir de X} (VND) et le **financement par retenue à la source** (PAY) ne sont pas construits — même patron que le cycle 006 (course active simulée). Le drapeau de zone `livraison_offerte_mefali`, lui, existe déjà (seed 002).
- **ETA calculée et exposée** : le routage renvoie distance **et** ETA ; le devis porte l'ETA à côté de la distance. Sa consommation (affichage client, dispatch) relève de cycles ultérieurs ; ici elle est produite et vérifiable.
- **Plafond d'éclatement à seeder** : le « seuil de détour maximal » est **paramétrable par zone** ; sa valeur seed reste **à calibrer** avec les données journalisées pendant la promo (Annexe B du cadrage, point 13). Non bloquant : la mécanique (proposer de scinder au-delà du seuil) est spécifiée, seule la valeur est TBD.
- **Arrondi** : pas de **25 FCFA** appliqué au **prix client**, paramétrable par zone ; le **reliquat d'arrondi abonde la part coursier**, la marge restant fixe et dans ses bornes (résolu au /speckit-clarify du 2026-07-24 par §9.3/§7.5/A3, cf. FR-016/FR-019).
- **Départage déterministe** : à spécificité, priorité et validité égales, un critère stable (ex. identifiant de règle) tranche pour que le devis soit **rejouable** ; aucune sélection non reproductible.
- **Cache de routage** : Redis, clé = paire de points **arrondis** (précision de l'arrondi paramétrable), TTL **24 h**, espace de noms propre au module ; éphémère reconstructible (constitution II). Le serveur OSRM (infra) n'est pas modifié.
- **Premier consommateur de routage tarifaire** : QRC (cycle 006) faisait une proximité point-rayon pour le scan, **pas** un itinéraire ; TRF-02 introduit le client OSRM à waypoints. La règle OSRM/waypoints s'applique à la **tarification**, distincte du contrôle de proximité du scan.
- **Consommateurs simulés** : CMD (verrouillage/affichage), DSP (offre, ordre des arrêts), CRS (gain coursier) ne sont pas construits ; le devis, le détail d'effort et l'ordre optimisé sont **exposés comme capacité** et **exercés par des courses simulées dans les tests**. La structure de course suit le modèle documenté `livraison → segment → arrêt`.
- **Devise MVP** : Tiassalé en **XOF** (0 décimale) ; aucune conversion ; la zone porte l'ISO 4217. Le multi-devise réel est une **provision** (cadrage §11.2 « devises dynamiques »).
- **Catégorie optionnelle** : la condition « catégorie » des règles est facultative ; une règle sans catégorie s'applique à toutes, une règle catégorisée est plus spécifique (entre dans la sélection FR-010).
- **Point relais** : dimension **présente mais jamais renseignée** au MVP (provision, constitution IX) ; aucune règle ne la fixe, aucun calcul ne la lit.

## Dependencies

- **Cycle 002 (zones)** : configuration à héritage — règles, drapeaux de zone, bornes de marge, devise de zone, seeds, facteur dégradé, pas d'arrondi, TTL de cache, seuils d'effort et d'éclatement. Ce cycle écrit/lit ces paramètres, ne réimplémente pas l'héritage.
- **Cycle 003 (comptes)** : session et **rôle admin** pour l'édition, la simulation et la publication de grilles.
- **Infra OSRM** (`infra/docker-compose.yml`) **+ `OSRM_URL`** (crate `socle`) : serveur de routage déjà provisionné ; ce cycle construit le **client** à waypoints.
- **Redis** (infra existante) : espace de **cache de routage** (paire de points arrondis, TTL 24 h).
- **Discipline monétaire** (constitution III, transverse) : entiers en unités mineures + ISO 4217, verrouillage des prix, aucun chemin partiel.
- **Cycles VND-08 & PAY (à venir)** : configuration vendeur de la livraison offerte et **retenue à la source** — **hors périmètre**, consommés ici via une entrée simulée ; commission vendeur (PAY-06, P2) exclue.
- **Cycles CMD / DSP / CRS (à venir)** : verrouillage et affichage du devis, écran d'offre coursier, **consommation de l'ordre d'arrêts optimisé** et de l'ETA — **simulés** ici par des déclencheurs de test.
- **Cycle ADM (à venir)** : console admin (maquette `docs/design/png/A3`) — ce cycle expose le **contrat** (édition/simulation/publication en API protégée), pas l'écran.
