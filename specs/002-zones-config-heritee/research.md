# Research — Arbre de zones et configuration héritée (002)

Décisions de conception résolvant les inconnues du Technical Context. Chaque
décision cite sa source de vérité ; aucune ne contredit
`docs/cadrage-v5.md`, `docs/user-stories-v2.md` ni la constitution v1.0.1.

## R1 — Stockage de la configuration : clé/valeur par zone (pas de JSONB monolithique)

- **Décision** : table `zones.parametre_zone (zone_id, cle, valeur jsonb)` —
  une ligne par paramètre défini sur une zone. La présence de la ligne = «
  défini » ; son absence = « explicitement absent » (FR-009). Les clés sont
  namespacées : `devise.code`, `devise.decimales`,
  `drapeau.livraison_offerte_mefali`, `drapeau.gratuite_commissions`,
  `drapeau.pluie`, `transport.actifs`,
  `categorie.<slug>.seuil_activation`, `categorie.<slug>.mixable`,
  `texte.<cle>`, `client.<cle>` — et demain `dispatch.rayon_km`,
  `tarification.*`… sans migration (FR-011).
- **Rationale** : la sémantique de surcharge « au paramètre près » (cœur de
  ZON-01) devient triviale — l'ancêtre le plus proche possédant la ligne
  gagne ; le « Récapitulatif des paramètres de zone » (fin de
  user-stories-v2) s'y loge intégralement sans évolution de schéma ;
  distinction absent/défini native ; `seuil_activation` et `mixable` sont
  bien des paramètres de zone (constitution I : « tout paramètre paramétrable
  vit dans la configuration de zone » ; Récapitulatif : « Catégories mixables
  au panier » y figure) et ne sont PAS des colonnes de la table catégorie —
  une seule source de vérité.
- **Alternatives rejetées** : colonne JSONB unique par zone (fusion profonde
  ambiguë, audit par paramètre impossible, absent/défini flou) ; colonnes
  typées par paramètre (une migration par nouveau paramètre — viole FR-011).

## R2 — Résolution : CTE récursive + fusion en Rust, trait du crate `zones`

- **Décision** : la chaîne d'ancêtres est chargée par `WITH RECURSIVE`
  (profondeur ≤ 6 types, index sur `parent_id`), les lignes
  `parametre_zone` de la chaîne sont fusionnées en Rust (zone la plus proche
  en tête). Le crate `zones` expose un trait de LECTURE consommé par tous les
  modules suivants (spec, FR-007) :

  ```rust
  #[async_trait]
  pub trait ConfigurationZones: Send + Sync {
      async fn configuration_effective(&self, zone: Uuid)
          -> Result<ConfigurationEffective, ErreurZones>;
      async fn parametre(&self, zone: Uuid, cle: &str)
          -> Result<Option<serde_json::Value>, ErreurZones>; // None = absent explicite
      async fn devise(&self, zone: Uuid) -> Result<Devise, ErreurZones>; // absente = erreur (FR-010)
      async fn drapeau(&self, zone: Uuid, cle: &str) -> Result<Option<bool>, ErreurZones>;
      async fn transports_actifs(&self, zone: Uuid) -> Result<Vec<String>, ErreurZones>;
      async fn categories_actives(&self, zone: Uuid) -> Result<Vec<CategorieActive>, ErreurZones>;
  }
  ```

  Implémentation `PgZones` (PgPool). `ConfigurationEffective` porte, pour
  chaque clé, la valeur ET la zone de provenance (utile aux tests de
  surcharge partielle et à l'admin T3). Les écritures (créer une zone,
  définir un paramètre, forcer une catégorie, recalculer une activation) sont
  des méthodes inhérentes de `PgZones` prenant `&mut PgTransaction` — pas
  dans le trait de lecture.
- **Rationale** : 2 requêtes indexées par résolution (chaîne + paramètres),
  aucune dénormalisation à invalider ; le trait par crate est la règle
  d'architecture (constitution II) ; provenance = testabilité exhaustive
  demandée par la spec.
- **Alternatives rejetées** : vue matérialisée de la config effective
  (invalidation en cascade pour un gain nul à l'échelle MVP — 1 pays,
  1 ville) ; cache Redis (constitution II l'autorise mais rien ne le justifie
  à ce volume ; à réévaluer quand dispatch/tarification liront la config sur
  chemin chaud).

## R3 — Version de configuration : empreinte canonique (pas de compteur)

- **Décision** : la `version` servie par `/config` est le SHA-256 (hex) du
  document JSON canonique (clés triées) effectivement servi. Dépendance :
  `sha2` (dernière stable, figée — constitution X).
- **Rationale** : FR-019 littéral — la version change si et seulement si la
  configuration effective servie change, y compris quand la modification
  vient d'un ancêtre ; aucun cascade de compteurs vers les descendantes ;
  déterministe (seeds rejouables → même version, SC-008) ; sert d'ETag HTTP
  gratuit (`If-None-Match` → 304, économe pour le polling horaire des apps).
- **Alternatives rejetées** : compteur par zone (doit se propager aux
  descendantes ou se calculer en max de chaîne — logique en plus pour rien) ;
  horodatage de dernière modification (non déterministe au re-seed).

## R4 — `/config` public : sous-ensemble servi par liste blanche de namespaces

- **Décision** : `GET /config?zone=<uuid>` (public, lecture seule —
  clarification Q1 de la spec) ne sert QUE : `devise`, `drapeau.*`,
  `texte.*`, `client.*`, plus deux vues dérivées — `categories` (actives
  uniquement : slug, clé i18n de nom, mixable) et `transports_actifs`
  (slugs). Les namespaces internes (`dispatch.*`, `tarification.*`, …) ne
  sortent JAMAIS par cet endpoint. Rate-limit par IP en mémoire de processus
  via `actix-governor` (dernière stable vérifiée et figée à
  l'implémentation — constitution X ; Redis inutile pour un simple
  garde-fou de politesse, et la constitution réserve Redis à l'éphémère
  reconstructible, ce qu'un compteur governor est aussi).
- **Rationale** : matérialise la clarification Q1 (« sous-ensemble destiné
  aux apps, jamais de donnée sensible ») par une liste blanche structurelle
  plutôt que par relecture au cas par cas ; l'accueil (§8.1) a besoin des
  catégories activées et CMD-01 du drapeau mixable — d'où les vues dérivées.
- **Alternatives rejetées** : servir toute la config effective (fuite des
  paramètres opérationnels internes) ; deux endpoints public/authentifié
  (option C de la clarification, écartée par l'utilisateur).

## R5 — Garde admin temporaire : jeton d'environnement, remplacé au cycle CPT

- **Décision** : l'unique écriture API du cycle (forçage de catégorie,
  clarification Q2) est protégée par un jeton statique `ADMIN_API_TOKEN`
  (variable d'environnement, comparaison à temps constant, en-tête
  `X-Admin-Token`), encapsulé dans un extracteur Actix `AdminAuth` que le
  cycle CPT remplacera par la vérification JWT + rôle admin (CPT-02/03) sans
  toucher aux handlers.
- **Rationale** : l'ordre imposé des cycles (TRX → ZON → CPT,
  user-stories §0.1 et « Prochaine étape suggérée ») fait que ni comptes ni
  rôles n'existent quand ZON se construit, alors que ZON-02 exige un forçage
  admin testable dès maintenant. L'extracteur isole la stratégie
  d'authentification : le remplacement en CPT est un changement local.
  Écart au principe VIII (« protégé par rôle ») consigné en Complexity
  Tracking du plan.
- **Alternatives rejetées** : attendre CPT (bloque le critère d'acceptation
  ZON-02 et inverse l'ordre des cycles) ; construire un mini-système de
  rôles jetable (travail hors périmètre, refait en CPT).

## R6 — Règle d'activation : le crate `zones` possède la règle, pas le comptage

- **Décision** : `PgZones::recalculer_activation(tx, ville, categorie,
  nb_vendeurs_agrees)` applique la règle — `actif_auto := actif_auto OR
  (nb ≥ seuil résolu)` (jamais de désactivation automatique, spec FR-015) ;
  l'état effectif est `CASE forcage WHEN force_actif→true,
  force_inactif→false, automatique→actif_auto` (colonne générée). Le nombre
  de vendeurs agréés est un PARAMÈTRE d'entrée : le crate zones ne connaît
  pas les vendeurs (constitution II — prestataire/vendeur vivent dans leurs
  crates) ; le cycle VND appellera cette fonction à chaque transition
  d'agrément ; dans ce cycle, seuls les tests et les seeds l'exercent (spec,
  Assumptions). Catégorie sans `seuil_activation` résolu = jamais
  d'activation automatique (absence explicite, FR-009) — le forçage admin
  reste possible.
- **Rationale** : frontière de dépendance propre (zones ne dépend d'aucun
  crate métier) ; règle testable exhaustivement sans fixtures vendeurs.
- **Alternatives rejetées** : requête SQL de comptage dans le crate zones
  (couplage au schéma prestataires, qui n'existe pas encore) ; événement
  outbox consommé (asynchrone — l'activation doit être transactionnelle avec
  l'agrément qui la déclenche, constitution VI).

## R7 — Côté apps : module `config` de `mefali_core`, zone de bootstrap seedée

- **Décision** : `mefali_core` gagne un module `config` : service qui lit
  `GET /config` via le client Dart GÉNÉRÉ (`clients/dart`,
  `mefali_api_client` — jamais d'appel HTTP artisanal, constitution I),
  met la réponse en cache local (`shared_preferences`, dernière stable
  figée), la recharge au démarrage puis toutes les heures
  (`Timer.periodic`), et sert la dernière valeur connue hors ligne
  (FR-020). Zone de bootstrap : l'UUID FIXE de la zone Tiassalé posé par le
  seed (voir data-model §Seeds), exposé en constante par le module — ville
  unique du MVP ; la sélection de zone par adresse arrive avec CPT-05/CMD-02.
  `mefali_client` et `mefali_pro` initialisent le service au démarrage
  (aucun écran nouveau — spec, Assumptions). L'API est injectée derrière une
  interface pour tester cache/rafraîchissement/hors-ligne avec des fakes
  (`fake_async`).
- **Rationale** : la logique est écrite une fois, partagée par les deux apps
  (rôle de `mefali_core`) ; UUID de seed fixe = déterminisme (SC-008) et
  bootstrap trivial.
- **Alternatives rejetées** : config par défaut embarquée dans chaque app
  (dérive entre apps et serveur) ; géolocalisation au premier lancement
  (hors périmètre ZON, arrive avec l'adressage).

## R8 — Périmètre non touché ce cycle

- **Décision** : AUCUN usage de Redis, Garage (S3) ni OSRM dans ce cycle ;
  aucune page Nuxt (les écrans admin arrivent en T3 — clarification Q2) ;
  `clients/ts` est simplement régénéré et commité (CI contrat-clients).
  NB : la stack citée dans la demande mentionne « MinIO » — remplacé par
  **Garage** depuis l'amendement 1.0.1 de la constitution (2026-07-13,
  cycle 001) ; sans impact ici.
- **Rationale** : « rien construit hors du périmètre du cycle en cours »
  (constitution, workflow) ; le cadrage §10 reste respecté, ces briques
  servent aux cycles qui en ont besoin.

## R9 — Événements outbox du cycle (taxonomie)

- **Décision** : trois types ajoutés au registre
  `docs/taxonomie-evenements.md`, écrits via `socle::ecrire_evenement` dans
  la MÊME transaction que la mutation (constitution VI) :

  | Type | Entité | Émis quand | Payload spécifique |
  |---|---|---|---|
  | `zone.parametre_modifie` | `zone` | `definir_parametre` (écriture domaine ; consommée par tests, puis ADM en T3) | `cle`, `avant`, `apres`, `acteur` |
  | `categorie.forcage_change` | `activation_categorie` | changement du mode de forçage par l'admin | `zone`, `categorie`, `avant`, `apres`, `acteur` (journal ADM-05 : qui/quand/avant/après) |
  | `categorie.activation_changee` | `activation_categorie` | changement de l'état EFFECTIF (auto ou forçage) | `zone`, `categorie`, `avant`, `apres`, `origine` (`seuil`\|`forcage`), `nb_vendeurs`, `seuil` |

  Les seeds chargent l'état initial en SQL brut et n'émettent PAS
  d'événements (chargement initial, pas une transition de parcours —
  même pratique que le cycle 001).
- **Rationale** : le journal « qui/quand/avant/après » exigé par ADM-05 est
  porté par l'outbox — pas de table d'audit parallèle ; aucun KPI manuel
  (constitution VI), les métriques d'activation dériveront de ces
  événements.
- **Alternatives rejetées** : table d'audit dédiée (doublon de l'outbox) ;
  événement unique fourre-tout (perd la distinction forçage/effectif).

## R10 — Conventions de code : suivre le socle 001 (identifiants français)

- **Décision** : le crate `zones`, les handlers et les schémas suivent les
  conventions du code livré au cycle 001 (`socle` : `ecrire_evenement`,
  `NouvelEvenement`, commentaires français) — identifiants métier en
  français, cohérents dans tout le workspace.
- **Rationale** : la cohérence du monorepo prime pour un développeur solo ;
  le socle mergé fait précédent. ATTENTION : `CLAUDE.md` et la constitution
  (« Code et identifiants en anglais ») disent l'inverse du code livré —
  divergence à trancher par amendement de `CLAUDE.md`/constitution ou par
  renommage du socle ; signalée au rapport de fin de plan, hors périmètre de
  ce cycle.
- **Alternatives rejetées** : basculer ce crate en anglais (mélange des
  deux conventions dans un même workspace — pire des deux mondes).
