# Phase 0 — Recherche : cycle de vie complet d'une commande multi-vendeurs

Contexte : stack imposée (cadrage §10) ; les cycles 002 (zones), 003 (comptes), 005 (prestataires), 006 (QR + socle logistique) et 007 (tarification) sont livrés. Il ne reste que des décisions de **conception**. Format : Décision / Rationale / Alternatives rejetées. Les seuils monétaires et temporels sont des **seeds de zone éditables** (« Récapitulatif des paramètres de zone »).

## R1 — Extension du crate `commandes`, pas de nouveau crate

**Décision** : implémenter dans le crate **`commandes` existant**, en étendant son schéma Postgres homonyme. Le crate passe de 4 modules (socle 006) à 13, sans changer de frontière.

**Rationale** : le socle logistique (`commande`, `livraison`, `segment`, `arret`, la collecte par scan et le gating de bascule) **vit déjà là**, et le cycle 006 l'a explicitement annoncé comme « socle MINIMAL que CMD étendra (par de NOUVELLES migrations, jamais celle-ci) ». Un schéma par module (constitution II) ; découper CMD en deux crates séparerait la boucle de collecte de son gating et forcerait un couplage circulaire.

**Alternatives rejetées** : (a) nouveau crate `panier` + `commandes` → la création de commande écrit dans les deux, le devis figé et les lignes seraient à cheval sur deux frontières ; (b) crate unique `logistique` regroupant CMD et DSP → DSP a son propre cycle et ses propres tables Redis.

## R2 — Deux migrations : `ALTER TYPE … ADD VALUE` isolé du reste

**Décision** : livrer **`0008_commandes_enums.sql`** contenant **uniquement** les `ALTER TYPE … ADD VALUE` (nouvelles valeurs de `statut_arret` et `etat_livraison`) et les `CREATE TYPE` neufs, puis **`0009_commandes_tronc.sql`** contenant tables, colonnes, `CHECK`, `DEFAULT` et index qui **référencent** ces valeurs.

**Rationale** : PostgreSQL interdit d'**utiliser** une valeur d'énum dans la transaction qui l'ajoute (`unsafe use of new value of enum type`), et sqlx exécute chaque fichier de migration dans une transaction. Or `0009` a besoin des nouvelles valeurs dans un `DEFAULT`, dans des `CHECK` de cohérence et dans des index partiels. Deux fichiers = deux transactions = contrainte levée, sans artifice.

**Alternatives rejetées** : (a) fichier unique → **échec au déploiement**, pas au développement — le pire moment pour le découvrir ; (b) recréer les énums (`statut_arret_v2` + `ALTER COLUMN … USING`) → casse les index, le code et les tests du cycle 006 pour un bénéfice nul ; (c) remplacer les énums par des `text` + `CHECK` → perd la garde de typage que tout le dépôt utilise depuis le cycle 002.

## R3 — Répartition tronc / livraison : le devis est logistique, les articles ne le sont pas

**Décision** : le **tronc `commande`** porte identité (client, zone, catégorie), prestataires concernés, **lieu de prestation**, `montant_articles_unites`, `total_unites`, `devise`, mode et état de paiement, `etat` de très haut niveau, et les secrets de remise (code, jeton). La **`livraison`** porte le **devis figé complet** (prix client, part coursier, marge, composantes d'effort, distance, ETA, `degraded`, `proposer_scission`), le coursier, et son état logistique.

**Rationale** : « le tronc ne contient AUCUN champ logistique » (constitution II). Les frais de livraison **sont** un attribut de la livraison : un vertical sans livraison (prestation à domicile facturée sur place) a un total égal au montant des articles, sans qu'aucune colonne ne devienne dénuée de sens. Le `total_unites` du tronc reste calculable — c'est la somme des articles et des prix client des livraisons rattachées, écrite à la création et jamais recalculée (devis figé).

**Alternatives rejetées** : (a) frais de livraison sur le tronc → champ logistique explicite, viole II et rend la colonne absurde pour un vertical sans livraison ; (b) montant des articles sur la livraison → un vertical sans livraison perdrait ses montants ; (c) tout en JSON sur le tronc → perd le typage monétaire entier et les contraintes SQL.

## R4 — La remise est un arrêt — et le gating hérité du cycle 006 doit être corrigé

**Décision** : ajouter `commandes.type_arret` (`collecte` | `remise`), rendre `arret.prestataire_id` **nullable** avec un `CHECK` de cohérence (collecte ⇒ prestataire présent ; remise ⇒ prestataire absent), et **corriger `gating_livraison`** pour ne compter que les arrêts de type `collecte`. Le test d'intégration du cycle 006 est **conservé** et complété par un cas « livraison avec arrêt de remise ».

**Rationale** : le cadrage §7.2 et le périmètre imposé décrivent « 1..n collectes **+ 1 remise** » comme des arrêts du segment. Le gating hérité compte `count(*)` de **tous** les arrêts du segment : avec la remise (jamais `collecte`), `resolus = total` ne serait **jamais** vrai et la livraison ne basculerait plus — la commande resterait bloquée en collecte pour toujours. C'est la régression la plus dangereuse du cycle : silencieuse, elle ne casse aucun test existant (le cycle 006 ne crée pas d'arrêt de remise) mais casse la production.

**Alternatives rejetées** : (a) remise en champ du segment → contredit explicitement le cadrage et le périmètre, et rendrait le scan de remise inhomogène avec les collectes ; (b) remise comme arrêt marqué « déjà résolu » à la création → un état mensonger, et le comptage de progression (« 2 collectes sur 3 ») deviendrait faux ; (c) laisser le gating et le contourner à l'appel → la garde vivrait hors du domaine.

## R5 — Machine à états à trois niveaux, table de transitions fermée

**Décision** : trois énums distincts et une **table de transitions déclarative** (constante Rust `(niveau, depuis, vers, acteur autorisé)`), consultée par une garde unique. Toute transition absente de la table est refusée en **409**.

| Niveau | Énum | Valeurs |
|---|---|---|
| Tronc | `etat_commande` | `nouvelle`, `en_attente_paiement`, `en_attente_coursier`, `en_cours`, `terminee`, `annulee`, `echouee` |
| Livraison | `etat_livraison` (étendu) | `assignee`, `en_collecte`, `en_livraison`, `livree`, `echouee`, `annulee` |
| Arrêt | `statut_arret` (étendu) | `a_collecter`, `en_route`, `arrive`, `collecte`, `indisponible` |

**Rationale** : le cadrage §7.2 mêle en un seul diagramme des états de nature différente — `NOUVELLE`/`ANNULÉE` sont des états de commande, `EN_COLLECTE`/`EN_LIVRAISON` des états de livraison, `EN_ROUTE_ARRÊT`/`ARRIVÉ`/`COLLECTÉ` des états d'arrêt. Les séparer est exactement ce qu'impose la constitution II, et rend chaque garde locale. Une table déclarative rend la couverture de test **mécanique** (SC-002 : une transition = un test) et empêche qu'une transition oubliée soit implicitement autorisée.

**Alternatives rejetées** : (a) un seul énum plat de 15 valeurs sur le tronc → champs logistiques sur le tronc, violation frontale de II ; (b) gardes dispersées dans chaque fonction d'écriture → aucune preuve d'exhaustivité, et le « refus par défaut » deviendrait un « oubli par défaut ».

## R6 — Code de livraison en clair côté serveur, empreintes pour le coursier

**Décision** : générer à la création un **code à 4 chiffres** (aléatoire cryptographique) et un **jeton QR de réception** (aléatoire, encodé dans le QR). Stocker le code **en clair** et le jeton **en clair**, plus leurs **empreintes salées** via les fonctions déjà livrées `qr::verification::empreinte_code` et `empreinte_jeton`. Le client propriétaire lit le code et le jeton ; le **coursier ne reçoit que les empreintes**.

**Rationale** : le client doit pouvoir **réafficher** son code et son QR à tout moment (FR-042), y compris après réinstallation ou sur un second appareil — un stockage haché seul le rendrait impossible. Le coursier, lui, doit vérifier **hors ligne** (CRS-04) : l'empreinte pré-provisionnée à l'assignation suffit et ne fuite rien. Le code à 4 chiffres n'est pas un secret d'authentification (3 essais maximum, portée d'une seule commande) : le protéger par rôle et propriété est proportionné. Les fonctions d'empreinte existent déjà et sont testées.

**Alternatives rejetées** : (a) hachage seul → réaffichage client impossible ; (b) code dérivé de l'identifiant de commande → devinable ; (c) jeton signé HMAC comme les plaques → la révocation par signature n'a pas de sens ici (le jeton meurt avec la commande) et empêcherait la vérification hors ligne par simple comparaison d'empreinte.

## R7 — Idempotence de création par clé client, patron du cycle 003

**Décision** : `POST /commandes` accepte un en-tête `Idempotency-Key` (UUIDv7 client) **utilisé comme identifiant de la commande créée**, sous contrainte d'unicité. Un rejeu renvoie la commande existante avec le **même corps** et un `200` au lieu d'un `201`.

**Rationale** : c'est exactement le patron déjà livré pour les adresses au cycle 003 (`id = Idempotency-Key du POST`), éprouvé et cohérent pour un développeur solo. Il rend l'idempotence **structurelle** (contrainte SQL) plutôt que procédurale, ce qui la rend vraie même sous concurrence.

**Alternatives rejetées** : (a) table de clés d'idempotence séparée → une table de plus, une purge de plus, pour une garantie identique ; (b) déduplication par empreinte du panier → deux commandes identiques légitimes (Awa recommande la même chose) seraient fusionnées à tort.

## R8 — Le panier est local ; l'API expose un devis de panier sans effet de bord

**Décision** : aucune table de panier serveur. `POST /paniers/devis` reçoit le contenu du panier, renvoie le regroupement par vendeur, les sous-totaux, le devis détaillé, les drapeaux de mixage et de scission — **sans rien écrire** (aucun outbox, aucune ligne). Le panier vit dans une table **drift** locale.

**Rationale** : rien n'est engagé tant que la commande n'existe pas ; la maquette C3-3c montre un panier **modifiable hors ligne** avec « total estimé » et envoi unique à la reconnexion. Un panier serveur imposerait un cycle de vie complet (expiration, purge, conflits multi-appareils) sans aucune valeur métier. Le patron « service sans effet de bord » est celui du simulateur admin du cycle 007.

**Alternatives rejetées** : (a) panier serveur persistant → complexité pure ; (b) devis calculé côté client → dupliquerait le moteur tarifaire dans l'app, contredirait « une seule source de vérité » et rendrait les frais falsifiables.

## R9 — Deux déclencheurs de scission, un seul mécanisme

**Décision** : la proposition de scission a **deux causes** — catégorie non `mixable` mélangée aux courses, et `proposer_scission` du devis (détour au-delà du plafond d'éclatement de la zone) — mais **une seule** surface : le devis de panier renvoie une proposition unique portant sa cause et la **prévisualisation chiffrée** des commandes résultantes. La scission n'est **jamais** appliquée par le serveur : le client renvoie N créations indépendantes.

**Rationale** : les deux causes produisent la même action utilisateur et le même écran (C3-3d) ; les fusionner évite deux chemins d'UI divergents. Le cycle 007 a explicitement laissé la mécanique à CMD (« CMD PROPOSERA de scinder — TRF ne scinde pas »). Ne jamais scinder d'office est une exigence (FR-010).

**Alternatives rejetées** : (a) deux propositions distinctes → un panier mixte **et** dispersé afficherait deux bandeaux contradictoires ; (b) scission serveur automatique → viole FR-010 et retire la décision au client.

## R10 — Échéance de substitution persistée, jamais un minuteur en mémoire

**Décision** : une proposition de substitution porte une colonne `echeance timestamptz` (instant + délai de zone, défaut 60 s). L'expiration est **résolue à la lecture** (toute consultation d'une proposition échue la traite comme expirée) et **balayée par un job périodique** au même titre que les purges existantes. L'expiration déclenche l'appel journalisé, puis le retrait si le client reste injoignable.

**Rationale** : un minuteur en mémoire disparaît au redémarrage et ne survit pas à plusieurs instances — la décision d'argent ne peut pas dépendre de la vie d'un processus. Le dépôt a déjà deux jobs périodiques (purge des repères vocaux, purge des photos de collecte) : le patron est établi. La résolution à la lecture garantit qu'une réponse tardive de 61 s est refusée **même si** le job n'est pas encore passé.

**Alternatives rejetées** : (a) `tokio::time::sleep` par proposition → perdu au redémarrage, non testable de façon déterministe ; (b) job seul sans résolution à la lecture → fenêtre où une réponse hors délai serait acceptée.

## R11 — Le devis est évalué dans la transaction de création, puis figé pour de bon

**Décision** : la création appelle `EvaluationTarifaire::evaluer` et `OptimisationArrets::optimiser`, **copie** le résultat (montants, composantes, ordre, `degraded`, `proposer_scission`) sur la livraison, et **ne le recalcule jamais** — ni à la substitution, ni au retrait, ni à la réassignation. L'ordre optimisé devient l'`ordre` des arrêts, figé.

**Rationale** : décision de spécification tranchée en séance (frais figés, seuls les articles bougent) et exigence constitutionnelle (prix verrouillés à la création). Copier plutôt que référencer garantit que l'évolution ultérieure de la grille tarifaire ne modifie pas rétroactivement une commande. L'évaluation est un appel réseau (OSRM) : elle est faite **avant** l'ouverture de la transaction d'écriture et son résultat y est injecté, pour ne pas tenir une transaction ouverte pendant un appel externe.

**Alternatives rejetées** : (a) référencer la règle tarifaire → une édition de grille changerait le passé ; (b) évaluer dans la transaction → transaction longue tenue pendant un appel HTTP externe ; (c) recalculer à chaque mutation → contredit la clarification de spec et ferait varier les frais en course.

## R12 — Restrictions de compte : port côté CMD, implémentation côté `comptes`

**Décision** : CMD déclare un port `RestrictionsCompte { restrictions(compte), poser_restriction(tx, compte, restriction, motif) }` ; l'implémentation vit dans un module **`restriction.rs` du crate `comptes`**, qui écrit les colonnes `prepaiement_impose` / `bloque` (déjà en base, provisions CPT-06) et émet l'événement de sanction.

**Rationale** : la garde de CMD-03 et la sanction de CMD-08 sont **dans le périmètre CMD**, mais les colonnes appartiennent au schéma `comptes` — « un schéma par module » impose que l'écriture vive dans son crate. Le port garde CMD testable avec un double, sans base.

**Alternatives rejetées** : (a) `commandes` écrit dans `comptes.compte` → franchit une frontière de schéma ; (b) dupliquer les drapeaux dans le schéma `commandes` → deux vérités pour un même fait ; (c) attendre le cycle CPT-06 → CMD-03 et CMD-08 seraient inimplémentables.

## R13 — Position du coursier : Redis éphémère, exposée avec son âge

**Décision** : le suivi lit la dernière position du coursier dans **Redis** (clé éphémère avec TTL) et renvoie **la position et son âge en secondes**, ou l'absence de position. L'**alimentation** relève de DSP-01 (non construit) : elle est simulée dans les tests et dans le parcours de validation.

**Rationale** : la position est de l'éphémère reconstructible — le cas d'école de « Redis ne porte que de l'éphémère » (constitution II). Exposer l'**âge** plutôt qu'une position nue est une exigence (FR-040, maquette C4-4d « Position non actualisée — il y a 4 min ») : c'est ce qui empêche l'app d'inventer une position.

**Alternatives rejetées** : (a) historiser les positions en Postgres → volume élevé, aucune exigence produit, données de géolocalisation à conserver (contraire à la minimisation ARTCI) ; (b) masquer une position périmée → l'utilisateur croirait le coursier immobile plutôt que déconnecté.

## R14 — Arbre §7.5 : une table d'issues avec détenteurs explicites

**Décision** : une table `issue_echec` porte, pour chaque échec, son **type** (les 10 lignes du tableau §7.5), l'arrêt concerné le cas échéant, le **détenteur de l'argent** et le **détenteur de la marchandise** (énums : `client`, `coursier`, `vendeur`, `mefali`, `consigne`), la sanction éventuelle et le motif. Chaque issue émet ses événements, dont `litige.ouvert` et `indemnisation.due` — **sans consommateur** ce cycle.

**Rationale** : « chaque issue journalise qui détient l'argent et la marchandise » (CMD-08) devient une **colonne**, donc une assertion de test, et non une phrase de documentation. Les deux détenteurs sont indépendants (le coursier peut détenir la marchandise pendant que Mefali détient la dette) — deux colonnes, pas un état combiné. Une commande multi-vendeurs peut mêler périssable et non-périssable : la résolution est **par arrêt**, comme l'exige CMD-08.

**Alternatives rejetées** : (a) un seul énum d'issue combinant les détenteurs → explosion combinatoire et sémantique confuse ; (b) journaliser en texte libre → intestable, et les métriques MET n'en dériveraient pas ; (c) résolution par commande → impossible sur un panier mixte périssable/non périssable.

## R15 — Périssable : paramètre de catégorie, jamais attribut d'article

**Décision** : introduire le paramètre de zone `categorie.<slug>.perissable` (seed : `restauration` vrai, les autres faux), résolu par héritage comme `mixable`.

**Rationale** : « chaque catégorie est une **configuration** » (cadrage §4) et §7.5 nomme « denrée périssable / plat préparé », c'est-à-dire la restauration. Le mécanisme existe déjà, à l'identique de `mixable` déjà seedé. Aucune migration n'est nécessaire.

**Alternatives rejetées** : (a) colonne sur l'article → des milliers de saisies vendeur pour une information de catégorie, et un vendeur pourrait la falsifier pour éviter le retour ; (b) valeur en dur dans le code → viole le principe I.

## R16 — Doubles des modules absents, patron du cycle 006

**Décision** : quatre doubles de test, tous dans `ports.rs` à côté de leur trait, sur le modèle d'`ArretsFixes` déjà livré : `AffectationSimulee` (dispatch — assigne un coursier, réassigne), `PaiementSimule` (paiements — confirme ou fait expirer un prépaiement), `PreuvesFixes` (coursier — preuves d'échec réunies ou non), `PositionFixe` (position et âge).

**Rationale** : c'est le patron déjà éprouvé deux fois (cycle 006 pour la course active, cycle 007 pour le routage et les courses). Il permet d'exercer **toutes** les branches sans construire DSP, PAY ni CRS, et laisse ces cycles brancher leur implémentation réelle sans toucher au contrat.

**Alternatives rejetées** : (a) implémentations minimales « pour de vrai » → construit hors périmètre, et le cycle propriétaire devrait ensuite les défaire ; (b) tests limités aux chemins sans dépendance → l'arbre §7.5 et la file d'attente ne seraient pas couverts, alors que ce sont les exigences les plus risquées.

## R17 — Cache client : deux tables drift, providers Riverpod codegen

**Décision** : étendre la base **drift** existante de deux tables locales — `brouillon_panier` (contenu, total estimé, horodatage) et `commande_cache` (identifiant, dernier état connu, progression, **code**, **jeton QR**, dernière position et son âge). L'état d'écran passe par des providers **générés** : `Notifier<EtatPanier>` pour le brouillon (porteur de processus, `keepAlive`), `AsyncNotifier` pour la liste des commandes et le suivi (chargements), conformément aux deux moules nommés de la constitution XII.

**Rationale** : la base drift, la file d'actions hors ligne et le pré-provisionnement d'arrêts existent déjà (cycle 006) — il ne s'agit que d'ajouter deux tables. Le bloc « À la livraison » doit se rendre **sans réseau** (FR-042/FR-043), ce qui exige un cache local et non un simple cache HTTP. Le choix des deux moules suit la règle explicite : ne jamais uniformiser derrière `AsyncValue`.

**Alternatives rejetées** : (a) `shared_preferences` → pas de requête, pas de migration de schéma, mauvais outil pour des données structurées ; (b) cache HTTP → ne survit pas à l'invalidation et ne garantit pas la disponibilité hors ligne ; (c) un seul `AsyncNotifier` pour tout → détruit la sémantique du brouillon (qui n'est pas un chargement), interdit par la constitution XII.
