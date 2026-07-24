# Phase 0 — Recherche : moteur de tarification, routage et grille d'effort

Contexte : stack imposée (cadrage §10), infra OSRM/Redis/Postgres déjà provisionnée. Il ne reste que des décisions de **conception**. Format : Décision / Rationale / Alternatives rejetées. Les valeurs monétaires et seuils sont des **seeds de zone éditables** (Récapitulatif des paramètres de zone).

## R1 — Découpage : nouveau crate `tarification`, schéma Postgres propre, knobs en config de zone

**Décision** : implémenter dans le crate `tarification` (aujourd'hui un stub). Un **schéma Postgres `tarification`** porte le **catalogue versionné** (`grille`, `regle`). Les **paramètres scalaires** (bornes de marge, pas d'arrondi, facteur dégradé, TTL de cache, seeds de la grille d'effort, plafonds, drapeaux) vivent en **configuration de zone héritée** (`zones.parametre_zone`) et sont lus via `ConfigurationZones`.

**Rationale** : « un schéma par module » (constitution II). Le catalogue de règles est un objet **versionné multi-lignes** (brouillon → en vigueur → historique, priorité, dates d'effet) qui n'entre pas dans un store clé-valeur ; les *knobs* scalaires, eux, sont exactement ce que la config de zone modélise (héritage par paramètre, constitution I). Cette césure est justifiée en Complexity Tracking du plan.

**Alternatives rejetées** : (a) tout mettre en `parametre_zone` (blobs JSON de règles) → détruit l'héritage par paramètre, la sélection de règle et la traçabilité de version ; (b) un schéma commun avec `zones` → couple deux domaines et casse « un schéma par module ».

## R2 — Client OSRM : service `/table` (matrice), pas `/route` par permutation

**Décision** : interroger OSRM en **un seul appel `/table/v1/driving/{coords}?annotations=distance,duration`** pour obtenir la **matrice** distance/durée entre tous les points de la course (retraits + client). L'optimisation d'ordre (R6) brute-force ensuite les permutations **sur la matrice en mémoire** ; la distance/ETA du devis = somme des tronçons de l'ordre retenu. Client HTTP = `reqwest` (déjà en workspace), base `Config.osrm_url`.

**Rationale** : `/table` renvoie tous les tronçons en une requête ; optimiser l'ordre par `/route` demanderait un appel par permutation (jusqu'à 4! = 24) — gaspillage réseau et latence. La matrice est aussi ce qu'il faut pour classer la « distance au précédent arrêt » (barème d'effort, R6) sans second aller-retour.

**Alternatives rejetées** : (a) `/route` par permutation → N! appels ; (b) `/trip` (TSP d'OSRM) → boîte noire non déterministe, ne renvoie pas la matrice pour le barème d'effort, contourne notre garde ≤ 4 exhaustive.

## R3 — Cache de routage Redis : par paire de points arrondis (tronçon), TTL 24 h

**Décision** : cacher **chaque tronçon** (paire de points) individuellement : clé `tarif:route:v1:{lat_a},{lon_a}:{lat_b},{lon_b}` (coordonnées **arrondies** à une précision de zone, défaut ~4 décimales ≈ 11 m), valeur `{distance_m, duree_s}`, **TTL 24 h**. Avant d'appeler `/table`, on lit le cache pour les paires connues ; on n'interroge OSRM que pour les manquantes. Accès Redis via le pattern existant (`redis`, `Config.redis_url`), namespace propre.

**Rationale** : le cache par **tronçon** (et non par course entière) maximise la réutilisation — deux courses partageant un étal→client réutilisent le tronçon. Conforme à « cache par paire de points arrondis » (spec/FR-014). Éphémère reconstructible (constitution II).

**Alternatives rejetées** : (a) cacher la matrice complète d'une course → clé rarement réutilisée (l'ensemble exact de points se répète peu) ; (b) pas de cache → coût OSRM et latence inutiles sur trajets répétés.

## R4 — Réconciliation « marge 0 au lancement » vs « bornes 25–100 » : par le drapeau, pas par la règle

**Décision** : la **règle stocke une marge dans les bornes** (Tiassalé seed : `marge = 50`). La **marge 0 du lancement** est produite par le **drapeau de zone `gratuite_commissions`** (déjà seedé `true`), qui **force `marge = 0` à l'évaluation** — jamais par une règle de marge 0 (qui serait refusée par la borne 25–100). De même, `livraison_offerte_mefali` force `prix_client = 0`. À la bascule (drapeaux OFF), la marge 50 de la règle s'applique.

**Rationale** : lève la contradiction apparente entre TRF-05 (« marge 0 puis 50 ») et TRF-01 (bornes 25–100) : « 0 » est un **effet de drapeau** (état de lancement), « 50 » est la **valeur de règle** (état régulier). Le mécanisme existe déjà (drapeaux seedés). Aucune règle hors bornes n'est jamais stockée.

**Alternatives rejetées** : (a) autoriser une règle de marge 0 → viole la borne, casse la garde TRF-01 ; (b) borne min 0 pour Tiassalé → perd la garde économique et diverge du défaut documenté 25–100.

## R5 — Sélection de la règle : spécificité → priorité → effet → départage déterministe

**Décision** : parmi les règles **actives** de la grille **en vigueur** de la zone (ou du brouillon en simulation), filtrer celles qui **matchent** {véhicule, catégorie?, plage horaire/jour, tranche de distance} à l'instant considéré, puis retenir la plus **spécifique** (score : catégorie renseignée > absente ; plage horaire renseignée ; tranche de distance plus étroite), à **priorité** supérieure, **en vigueur** à la date/heure ; à égalité stricte, départage par **identifiant de règle** (ordre stable). Distance connue **avant** la sélection (l'ordre optimisé donne les km).

**Rationale** : rend le devis **déterministe et rejouable** (spec FR-010, clarification). La priorité éditable par l'admin tranche les cas volontaires ; le départage par id garantit qu'aucun choix n'est non reproductible.

**Alternatives rejetées** : (a) première règle trouvée → non déterministe selon l'ordre SQL ; (b) dernière écrite → surprenant pour l'admin ; (c) score de spécificité sans départage final → égalités non résolues.

## R6 — Optimisation de l'ordre des arrêts : brute force ≤ 4 (min distance), heuristique bornée au-delà

**Décision** : l'origine de l'itinéraire tarifé est le **premier retrait** (pas le coursier — R11/clarification), la destination est le **client** (fixe). On **minimise la distance routière totale** retraits → client. Pour **n ≤ 4 retraits**, énumérer **toutes les permutations** sur la matrice (R2) et retenir la meilleure (départage déterministe si égalité). Pour **n > 4**, heuristique bornée **explicite** (plus proche voisin + 2-opt), jamais présentée comme exhaustive. Le résultat (ordre + distance totale + matrice) est **exposé** via le trait `OptimisationArrets` à DSP/CMD.

**Rationale** : conforme à « permutations, trivial ≤ 4 » (§9.3/TRF-06) et à l'objectif « km réels minimaux » (clarification). Minimiser la distance = minimiser le prix client (monotone) et l'effort coursier. La matrice R2 rend l'énumération gratuite en réseau.

**Alternatives rejetées** : (a) `/trip` OSRM → non déterministe, boîte noire ; (b) exhaustif au-delà de 4 → explosion factorielle ; (c) minimiser l'ETA → la tarification est en distance, découplerait prix et objectif.

## R7 — Grille versionnée & garde de publication : états + empreinte de simulation

**Décision** : `tarification.grille` porte `etat ∈ {brouillon, en_vigueur, historique}`, `version`, `effet_le`, `simulee_le`, `simulee_empreinte`. La **publication** (transaction) exige `simulee_le` posé **sur l'empreinte courante** du brouillon **et** aucune règle hors bornes ; elle passe l'ancienne `en_vigueur` à `historique`, le brouillon à `en_vigueur` avec `effet_le`, écrit `grille.publiee`. **Toute édition de règle recalcule l'empreinte** → invalide la simulation (réarmement, FR-021). Un **index unique partiel** garantit **une seule grille `en_vigueur` par zone**.

**Rationale** : matérialise la garde du simulateur (mockup A3 : « Publier désactivé tant qu'une simulation n'a pas été faite ✓ » et « corriger la règle hors bornes ») et l'historique versionné, de façon inviolable côté serveur.

**Alternatives rejetées** : (a) booléen `simulee` sans empreinte → une édition post-simulation passerait la garde avec un contenu non simulé ; (b) pas d'index partiel → deux grilles en vigueur possibles (course non déterministe).

## R8 — Devise par zone : lue via `ConfigurationZones::devise`, aucune conversion

**Décision** : la devise du devis/de la règle **provient de la zone** (`ConfigurationZones::devise` → `{code, decimales}` ; Tiassalé = XOF/0). Toute règle et tout montant héritent de ce code ; une opération qui mêlerait deux devises est **rejetée** (erreur), jamais convertie. Le backend renvoie des **unités mineures + code** ; le **formatage localisé** est une clé i18n côté client (hors périmètre UI ce cycle).

**Rationale** : constitution III + TRF-04 ; la brique existe déjà (cycle 002, seed XOF au niveau pays). Prêt multi-devise (provision) sans logique de conversion.

**Alternatives rejetées** : (a) devise en dur XOF → casse la portabilité et le principe I ; (b) conversion au MVP → hors périmètre, source d'erreurs monétaires.

## R9 — VND-08 : créneau de calcul réservé, entrée simulée, config/financement hors périmètre

**Décision** : l'évaluation accepte une entrée optionnelle `offre_livraison_vendeur: Option<OffreLivraison>` (`{toujours}` ou `{seuil: montant}`) et l'**applique après les drapeaux de zone**, **uniquement** pour les commandes **mono-vendeur** : `prix_client → 0` (ou 0 au-delà du seuil), **part coursier inchangée**. La **configuration vendeur** {jamais/toujours/seuil} (cycle VND) et la **retenue à la source** (cycle PAY) ne sont **pas construites** ; l'entrée est **fournie par les tests** (patron cycle 006).

**Rationale** : honore le critère TRF-02 « application de VND-08 » (le créneau et la garde mono-vendeur sont construits et testés) sans déborder sur VND/PAY. Le drapeau `livraison_offerte_mefali` (Mefali) reste distinct de l'offre vendeur.

**Alternatives rejetées** : (a) construire la config vendeur ici → hors périmètre, empiète sur VND ; (b) ignorer VND-08 → contredit « critères tels quels » de TRF-02.

## R10 — Événements & métriques : trois événements, simulateur muet, minimisation ARTCI

**Décision** : déclarer et émettre `grille.publiee` (entité `grille`, à la publication), `routage.degrade` (entité `devis`/`zone`, au repli ×1,4), `effort.calcule` (entité `devis`, quand l'effort est calculé **non facturé** pendant la promo). Chacun via `ecrire_evenement` **dans la même transaction** que son opération. Le **simulateur n'émet aucun événement** (dry run). Payloads **minimisés** : zone, catégorie, véhicule, distances **arrondies**, montants en unités mineures, `degraded`, `acteur` = UUID — **aucun lat/lng brut**. Déclarés dans `docs/taxonomie-evenements.md` **avant** implémentation.

**Rationale** : constitution VI (événement dans la transaction, déclaration préalable, métriques dérivées, aucun KPI manuel). L'exclusion du simulateur évite de polluer les métriques avec des dry runs. Minimisation = constitution VIII/ARTCI.

**Alternatives rejetées** : (a) émettre un `devis.calcule` par évaluation → volume élevé sans valeur métrique nette (le devis vit dans la commande) ; (b) journaliser les coordonnées brutes → viole la minimisation.

## R11 — Simulateur : même cœur d'évaluation, sans coursier, sans effet de bord

**Décision** : le simulateur admin appelle **le même cœur d'évaluation** que la production, mais **contre le brouillon** et avec pour entrées **{vendeur(s)/point(s), destination, véhicule, heure, panier}** — **pas de coursier** (le devis client précède le dispatch, CMD-01/TRF-03/A3). Il renvoie le **détail complet** (itinéraire utilisé et `degraded`, règle retenue, composantes base/km/suppléments/effort, retenue vendeur éventuelle, arrondi, devis final) et **n'écrit rien** (ni outbox, ni état en vigueur, ni marquage de cache différent).

**Rationale** : garantit que « ce qui est simulé = ce qui sera facturé » (un seul cœur), et que la simulation est **sans risque** (dry run). Confirme l'origine « retraits → client » du devis (clarification).

**Alternatives rejetées** : (a) un moteur de simulation séparé → dérive entre simulé et réel ; (b) simulation qui écrit dans le cache de production sous une autre clé → complexité inutile (le cache par tronçon est déjà partagé et sûr).

## R12 — Découplage de la géométrie : la course est en entrée, simulée en tests (aucune migration `commandes`)

**Décision** : l'évaluation opère sur une **`DemandeDevis`** portant la **géométrie** (points de retrait ordonnables + destination), le véhicule, la zone, le nombre d'articles, l'instant, la catégorie éventuelle, les horodatages d'attente éventuels et l'entrée VND-08 — **pas** de référence aux tables `commandes`. Les tests fabriquent ces demandes ; **aucune** migration `commandes` n'est créée/modifiée.

**Rationale** : découple la tarification de la logistique (constitution II — pas de supposition « commande = livraison ») ; rend l'évaluation pure et testable ; laisse CMD/DSP fournir la géométrie réelle (adresse client CMD-02, arrêts) plus tard. Même patron que le cycle 006 (course active simulée).

**Alternatives rejetées** : (a) lire `commandes.arret`/adresse client → couple TRF à des tables non construites et au tronc logistique ; (b) créer un socle `commandes` ici → inutile (l'évaluation n'a besoin que de points), surface non requise.

## R13 — Aucune UI ce cycle : API admin + traits exposés

**Décision** : ne construire **aucun écran** (Flutter/Nuxt). Exposer : (a) une **API admin** (`Role::Admin`) pour éditer le brouillon, simuler, publier ; (b) des **traits** (`EvaluationTarifaire`, `OptimisationArrets`) pour CMD/DSP/CRS. La maquette A3 est la **cible du cycle ADM**.

**Rationale** : cohérent avec 002/003/005 (aucun écran admin avant ADM) et avec la spec (« Surface d'interface »). Concentrer le cycle sur le moteur et son contrat.

**Alternatives rejetées** : (a) écran admin Nuxt maintenant → empiète sur ADM, sans le reste de la console ; (b) écran devis client → empiète sur CMD, non démontrable sans le panier.

---

**Toutes les inconnues sont résolues — aucun `NEEDS CLARIFICATION` résiduel.** La clarification produit du 2026-07-24 (prime d'attente une seule fois par course) est intégrée à R6/effort et au data-model.
