# Mefali — User Stories MVP par module (v2)

*Complément d'exécution du Document de cadrage v5 — Ville de lancement : Tiassalé — Développement : solo + Claude Code*

---

## 0. Mode d'emploi

### 0.1 Avec Claude Code + Spec-Kit

- **Un module = un epic = un cycle Spec-Kit** : copier la section du module dans `/specify`, dérouler `/plan` en pointant le cadrage v5 (§10 architecture, §11 provisions) comme contrainte, puis `/tasks` et implémentation.
- **Implémenter par tranches verticales (§0.5)**, pas module par module.
- Le **contrat OpenAPI est la source de vérité** : toute story qui touche l'API met d'abord à jour les annotations utoipa, puis régénère les clients Dart et TypeScript (TRX-01).
- **Dernières versions stables** : à l'initialisation, vérifier et figer (lockfiles) les versions stables les plus récentes de chaque brique (Flutter, Shorebird, Actix, utoipa, Nuxt 4, Postgres, Redis, Garage, OSRM, Metabase) ; revue mensuelle.

### 0.2 Priorités

| Priorité | Signification |
|----------|---------------|
| **P0** | Sans cette story, on ne lance pas. L'ensemble des P0 constitue un produit lançable. |
| **P1** | Dans le périmètre MVP ; avant le lancement si le calendrier le permet, sinon dans les 2 semaines qui suivent (un fallback P0 existe toujours). |
| **P2** | Phase 2. Documentée ici uniquement quand elle contraint le modèle de données dès maintenant. |
| **PROVISION** | Modèle de données / interface uniquement. Aucune UI, aucune logique au MVP. |

### 0.3 Personas

- **Awa (cliente)** : employée d'agence à Tiassalé, Android milieu de gamme, Wave, commande au déjeuner.
- **Yao (coursier)** : moto personnelle, avance le cash sur ses fonds, réseau intermittent ; payé au fixe pendant la promo de lancement (engagement hors produit), puis à la course.
- **Tantie Affoué (vendeuse)** : maquis, pas d'app, veut son argent immédiatement, peu lettrée — les repères vocaux la concernent aussi côté cliente.
- **Kofi (vendeur équipé)** : boutique, smartphone, installera Mefali Pro, fera des promos (prix barrés, livraison offerte).
- **Admin (toi)** : fondateur, console Nuxt 4, seul au lancement.

### 0.4 Definition of Done (commune)

1. Critères d'acceptation couverts par des tests (unitaires + intégration sur les transitions).
2. Annotations utoipa à jour ; clients Dart/TS régénérés sans diff manuel.
3. Migration SQL versionnée ; seeds à jour.
4. Événement outbox pour tout changement d'état métier (TRX-02) **+ événements métriques de la taxonomie MET-01 si le parcours utilisateur est concerné**.
5. Clés i18n (fr) externalisées.
6. Paramètres exposés en configuration de zone quand la story dit « paramétrable ».

### 0.5 Ordre d'implémentation — 4 tranches verticales

| Tranche | Semaines | Contenu | Démo de fin de tranche |
|---------|----------|---------|------------------------|
| **T1 — Colonne vertébrale** | S3–S6 | TRX-01/02/05, ZON-01/03/04, CPT-01/02/03/04, VND-01/02/03, QRC-01/02, TRF-01/02 (avec routage), CMD-01/02/03/04/05/10, DSP-01→05, CRS-01/02/03/04, NTF-01, MET-01/02 | Awa commande 8 articles chez 2 étals du marché, dispatch automatique, Yao collecte arrêt par arrêt (scan QR à chaque étal) et livre par scan du QR client — de bout en bout, itinéraire multi-arrêts, événements métriques émis. |
| **T2 — Cash & cas limites** | S7–S8 | CMD-06/07/08, CRS-05/06, AVI-04, ADM-07, QRC-03/04, DSP-06/07, VND-04 | Tous les scénarios d'échec du §7.5 du cadrage se déroulent proprement, preuves et indemnisations tracées, y compris confirmation hors-ligne. |
| **T3 — Argent & pilotage** | S9–S11 | PAY-02/05, PAY-01 finalisé, TRF-03/04/05/06, VND-08 (livraison offerte), ADM-01→06, NTF-02, WEB-01, MET-03 | Prépaiement mobile money (tous les moyens via l'agrégateur) ; pilotage complet depuis l'admin ; badge « livraison gratuite » actif ; grille d'effort visible au devis ; Metabase branché sur les agrégats. |
| **T4 — Confort & durcissement** | S12 | VAP-01/02/03, VND-09 (« me prévenir au retour »), AVI-01/02, VND-05, CRS-07/08 finalisé, TRX-06, ADM-09 | Kofi gère ses commandes ; une rupture notifie ses abonnés au retour en stock ; l'app coursier survit à une coupure réseau totale ; un patch Shorebird est déployé. |

S13–S14 : bêta fermée. S15–S16 : correctifs, P1 restants, lancement.

### 0.6 Vue d'ensemble

| Module | Préfixe | P0 | P1 | P2/Prov. | Tranche principale |
|--------|---------|----|----|----------------|--------------------|
| Transverse & infra | TRX | 5 | 3 | — | T1 |
| Zones & configuration | ZON | 4 | 1 | — | T1 |
| Comptes & identité | CPT | 5 | 1 | — | T1 |
| Vendeurs & catalogue | VND | 4 | 3 | 2 | T1/T3/T4 |
| QR & traçabilité | QRC | 4 | — | — | T1/T2 |
| Tarification & devises | TRF | 5 | 1 | — | T1/T3 |
| Commandes | CMD | 8 | — | 1 | T1/T2 |
| Dispatch automatique | DSP | 7 | 1 | — | T1/T2 |
| Coursier | CRS | 6 | 2 | — | T1/T2/T4 |
| Paiements | PAY | 3 | 2 | 1 | T3 |
| Notifications | NTF | 2 | 1 | — | T1/T3 |
| Avis, litiges & modération | AVI | 1 | 3 | — | T2/T4 |
| App vendeur (Mefali Pro) | VAP | — | 3 | 1 | T4 |
| Console admin | ADM | 7 | 2 | — | T3 |
| Web public | WEB | 1 | — | 1 | T3 |
| Métriques | MET | 2 | 1 | — | T1/T3 |

---

## Module TRX — Transverse & infrastructure

**TRX-01 — Contrat OpenAPI et génération des clients (P0)**
- Handlers annotés `#[utoipa::path]` ; schémas `ToSchema`/`IntoParams` ; spec `/api-docs/openapi.json` ; Swagger UI protégée hors production.
- CI : génération client Dart (openapi-generator) + client TypeScript ; diff non commité = build en échec.

**TRX-02 — Journal d'événements métier (outbox) (P0)**
- Toute transition d'état insère `{type, entité, payload, horodatage}` dans la même transaction ; worker de publication ; consommateurs (notifications, métriques) idempotents.

**TRX-03 — Observabilité (P0)**
- Logs structurés avec corrélation par requête ; Sentry ; sonde uptime sur `/health` ; alerte si indisponibilité > 2 min.

**TRX-04 — Sauvegardes (P0)**
- `pg_dump` quotidien chiffré externalisé + sync du stockage objet (Garage) ; **restauration complète testée et documentée avant la bêta**. Immutabilité/versioning des sauvegardes portés par le bucket externe (object lock), jamais par Garage.

**TRX-05 — Seeds & démo (P0)**
- Zone Tiassalé, 5 vendeurs multi-catégories (dont un avec prix barrés et un en « livraison offerte dès X »), 20 articles, 2 coursiers, grille tarifaire, comptes de test — rechargeables en une commande.

**TRX-06 — Pipeline Shorebird (P1)**
- Release store + canal de patchs pour les 2 apps ; procédure documentée (Dart = patch ; natif = store) ; test réel d'un patch reçu sans store.

**TRX-07 — Conformité ARTCI (P1)**
- Export/suppression des données d'un utilisateur (endpoint admin) ; rétention photos et **notes vocales** limitée (90 jours, paramétrable) ; consentement à l'inscription.

**TRX-08 — Moule de gestion d'état des apps Flutter (P1)**
- Un pattern unique pour l'état des apps (Riverpod, providers générés), injecté par la portée et vérifié à la compilation ; état local réservé à ce qui ne sort pas du widget ; règles d'analyse dédiées ; CI : code généré commité, diff non commité = build en échec.
- Refactor pur : aucun changement visible pour l'utilisateur — les tests existants font contrat. Règle inscrite dans la constitution pour que les cycles suivants (VND, CMD, DSP, CRS…) partent du même moule.

---

## Module ZON — Zones & configuration

**ZON-01 — Arbre de zones à profondeur variable (P0)**
- Modèle `zone {parent_id, type ∈ [pays, région, ville, commune, village, quartier], config}` — **la profondeur n'est pas figée** : un village pourra être ajouté sous une commune en phase 2+ sans migration.
- Toute entité métier référence une zone ; la configuration effective d'une zone hérite de ses parents avec surcharge locale.
- Seed : Côte d'Ivoire > Tiassalé (ville), devise XOF (0 décimale, montants entiers).

**ZON-02 — Catégories par configuration (P0)**
- Catégorie = enregistrement : champs de fiche, politique photo (obligatoire/facultative/désactivée), workflow vendeur, véhicule minimal, **seuil d'activation par ville**.
- Activation automatique au franchissement du seuil ; toggle manuel admin prioritaire.
- Seed Tiassalé : restauration (8), boutique/supérette (3), marché (3), pharmacie (1), gaz (2), quincaillerie (2). *(Pas d'hôtellerie : vertical hors MVP, module séparé en phase 2+.)*

**ZON-03 — Référentiel des types de transport (P0)**
- Seed : à pied, vélo, moto, tricycle taxi, tricycle cargo, voiture, camionnette, camion ; activable par zone. Tiassalé : à pied, vélo, moto.

**ZON-04 — Configuration produit distante (P0)**
- `/config?zone=` : feature flags (dont « livraison offerte Mefali » du lancement), textes, paramètres ; versionnée ; rafraîchie au démarrage et toutes les heures, cache local.

**ZON-05 — i18n (P1)**
- Chaînes en clés fr ; structure prête pour en ; langue = zone puis préférence utilisateur.

---

## Module CPT — Comptes & identité

**CPT-01 — Inscription téléphone + OTP (P0)**
- E.164 (+225 par défaut) ; OTP 6 chiffres, 5 min, 3 essais ; 3 SMS/h/numéro (Redis) ; message d'expiration neutre ; profil minimal ; consentement ARTCI.

**CPT-02 — Sessions (P0)**
- JWT court + refresh révocable ; multi-appareils ; déconnexion à distance ; endpoints protégés par rôle.

**CPT-03 — Rôles multiples (P0)**
- 1..n rôles {client, coursier, vendeur, admin} par compte ; coursier/vendeur validés par l'admin ; Mefali Pro bascule d'interface selon rôle.

**CPT-04 — Dossier coursier (P0)**
- Pièce d'identité (Garage), véhicules déclarés, référent local, statut {en attente, validé, suspendu} ; non validé = pas de mise en ligne.

**CPT-05 — Adresses enregistrées (P0)**
- Proposition d'enregistrement après livraison réussie (« Maison », « Bureau », libre) ; réutilisation en 1 tap — **y compris la note vocale de repère associée**.

**CPT-06 — Restrictions de compte (P1)**
- Drapeaux `prépaiement_imposé` et `bloqué`, posés par l'admin ou les règles automatiques ; historique des sanctions.

---

## Module VND — Vendeurs & catalogue (crate `prestataires`)

*Le crate s'appelle `prestataires` : le vendeur est le **type de prestataire du MVP**. Agrément, charte, QR, sites, notes, score de fiabilité et plan freemium sont portés par le prestataire ; le catalogue d'articles et le stock vivent dans l'extension vendeur. Un artisan de phase N (plombier, électricien) sera un autre type de prestataire réutilisant tout le socle sans migration (cadrage §11.13).*

**VND-01 — Agrément (P0)**
- Fiche admin : nom, catégorie, photos, GPS, horaires, délai de préparation, contact, charte signée (scan Garage, incluant l'acceptation de la retenue à la source) ; statut {prospect, agréé, suspendu} ; suspension → retrait fiche + révocation QR immédiats.

**VND-02 — Catalogue avec prix barrés (P0)**
- Article : nom, **prix**, **prix_barré optionnel** (contrainte : prix_barré > prix ; affichage promo côté client), photo optionnelle, disponibilité, catégorie interne.
- Prix **verrouillés à la création de commande** ; le montant retenu est le prix courant (le prix barré est purement informatif).
- P1 (marché) : article à prix variable — fourchette affichée, prix exact confirmé sur place dans la fourchette, sinon traité en substitution (CMD-06).

**VND-03 — Statut boutique et site (P0)**
- Ouvert/fermé/pause + horaires par défaut ; hors horaires → fiche fermée, commandes bloquées.
- Modèle `vendeur → site` (1 site par défaut) ; GPS, horaires, stock portés par le site.

**VND-04 — Rupture — trois sources (P0)**
- Bascule par vendeur (VAP-02), **coursier sur place** (auto-masquage après 2 signalements/7 j, paramétrable), admin ; article en rupture grisé/masqué (config par catégorie) ; chaque bascule émet un événement (consommé par VND-09).

**VND-05 — Score de fiabilité et classement (P1)**
- Taux de rupture constatée + note + taux d'acceptation → score quotidien ; tri catalogue pondéré distance × fiabilité ; file « à réévaluer » admin selon les règles d'agrément.

**VND-08 — Livraison offerte par le vendeur (P1)**
- Configuration par vendeur : {jamais, toujours, à partir de X FCFA d'achat} ; badge client « Livraison gratuite » / « Livraison gratuite dès X FCFA » sur fiche et panier.
- Étant donné une commande éligible, alors frais client = 0, part coursier inchangée, et le paiement vendeur à la récupération = **montant articles − frais de livraison** (retenue à la source, visible sur le reçu des deux côtés).
- Compatible prépaiement mobile money (même retenue à la récupération) ; interaction avec le drapeau de zone « livraison offerte Mefali » : pendant le lancement, le drapeau de zone prime (frais déjà nuls, aucune retenue vendeur).
- **Commandes mono-vendeur uniquement** : dans un panier multi-vendeurs, les frais s'appliquent normalement (pas de répartition de gratuité entre vendeurs).

**VND-09 — « Me prévenir au retour » (P1 — engagement MVP)**
- Sur un article en rupture, bouton d'abonnement en 1 tap (lié au compte) ; badge « vous serez prévenu ».
- Étant donné le retour en stock (quelle que soit la source VND-04), alors les abonnés reçoivent un push avec lien direct vers l'article ; l'abonnement se consomme (one-shot) ; anti-spam : 1 notification max par article par 24 h.
- Métriques : abonnements, notifications envoyées, conversions en commande (MET).

**VND-06 — Multi-sites (PROVISION)** — n sites par vendeur, stock/horaires par site ; aucune UI ; MVP = 1 site.

**VND-07 — Plans freemium (PROVISION)** — `plan` + `plan_features` ; tous « Gratuit ».

---

## Module QRC — QR & traçabilité

**QRC-01 — Génération QR + plaque (P0)**
- QR : `https://mefali.ci/v/{vendor_id}?t={jeton HMAC révocable}` ; **code de secours à 4 chiffres** propre au vendeur ; PDF de plaque (QR + nom + code) dans Garage, téléchargeable admin.

**QRC-02 — Scan en course (P0)**
- Préconditions : commande active du coursier comportant un **arrêt** chez ce vendeur, état compatible ; vérifications : correspondance vendeur/arrêt, GPS < 100 m (paramétrable), horodatage serveur ; succès → arrêt **COLLECTÉ** (+ photo si la politique résolue l'exige : vendeur > catégorie > défaut, forcée au-dessus d'un seuil de montant) ; toutes les collectes faites → commande EN_LIVRAISON.

**QRC-03 — Révocation (P0)**
- Suspension vendeur → jeton invalide immédiatement ; scan → « vendeur temporairement indisponible ».

**QRC-04 — Mode dégradé (P0)**
- QR illisible → saisie du code à 4 chiffres. **Le code n'est pas un identifiant global** : c'est une confirmation comparée au code du vendeur de la commande active — aucun problème d'échelle, même avec des millions de vendeurs. Protections : géolocalisation < 100 m toujours exigée, **3 essais max**, incident « plaque à remplacer » créé automatiquement.

---

## Module TRF — Tarification & devises

**TRF-01 — Modèle de règles (P0)**
- Conditions {zone, catégorie?, véhicule, tranche de distance, plage horaire/jour, point relais?} → sorties {prix client (base + FCFA/km au-delà d'un seuil), part coursier, marge Mefali, devise} + priorité, dates d'effet, actif ; marge bornée par zone (défaut 25–100), borne violée → règle refusée.

**TRF-02 — Évaluation avec distance routière (P0)**
- **Distance et ETA par itinéraire routier** (jamais à vol d'oiseau) : service de routage configuré (OSRM auto-hébergé sur extrait OSM CI, ou Directions du fournisseur retenu) ; résultats mis en cache (paire de points arrondis, TTL 24 h, Redis).
- Dégradé : routage indisponible → vol d'oiseau × 1,4, marqué `degraded=true` et journalisé — une commande n'est jamais bloquée par le routage.
- Le service de routage accepte des **points de passage (waypoints)** : le moteur tarife toujours l'itinéraire complet réel — c'est la base de la mécanique multi-arrêts de TRF-06.
- Sélection de la règle la plus spécifique ; suppléments activés (pluie — drapeau de zone —, plage horaire, longue distance) ; arrondi (25 FCFA sup.) ; devis figé {frais client, part coursier, marge}.
- Drapeau de zone **« livraison offerte Mefali »** (lancement) → prix client = 0 ; drapeau « gratuité commissions » → marge = 0.
- Application de VND-08 après le drapeau de zone (voir story).

**TRF-03 — Simulateur admin (P0)**
- Vendeur (ou point) + destination + véhicule + heure → détail complet (itinéraire utilisé, règle retenue, composantes, retenue vendeur éventuelle, arrondi) avant publication d'une grille.

**TRF-04 — Devises (P0)**
- Unités mineures entières + ISO 4217 par zone ; XOF sans décimales ; formatage localisé ; aucune conversion au MVP.

**TRF-05 — Grille de départ Tiassalé (P0)**
- Seed éditable (distances **routières**) : à pied 100 (≤ 800 m) ; vélo 150 (≤ 2 km) ; moto base 200 jusqu'à 2 km + 50/km au-delà, plafond 500 ; pluie +100 (OFF) ; marge 0 (lancement) puis 50 ; drapeau « livraison offerte Mefali » ON à l'ouverture, OFF à la date annoncée.

**TRF-06 — Grille d'effort (P1 — requise avant la fin de la promo de lancement)**
- Trois composantes, **100 % reversées au coursier**, éditables par zone, détaillées au devis client avant confirmation et sur l'écran d'offre coursier (gain total) :
  1. **Paliers d'articles** (actif au MVP, mono-vendeur inclus) : 1–5 : 0 ; 6–10 : +50 ; 11–20 : +100 ; 21+ : +150 (seeds éditables).
  2. **Prime d'attente mesurée** (actif au MVP) : (scan QR − arrivée géolocalisée) > 15 min → +100 — calculée sur des événements déjà tracés, infalsifiable.
  3. **Supplément par arrêt supplémentaire, indexé sur la distance au précédent** (actif au MVP — panier multi-vendeurs natif) : < 100 m (étals voisins au marché) → **+25** ; 100 m–1 km → +50 ; > 1 km → +100 (seeds éditables) ; premier arrêt compris dans le prix de base ; plafond optionnel du total des suppléments par commande.
- **Arrêts éloignés** : la distance n'est jamais couverte par le supplément d'arrêt — la composante kilométrique du devis est calculée sur **l'itinéraire complet avec waypoints** (TRF-02) : coursier → arrêt 1 → … → client, ordre des arrêts **optimisé** (permutations, trivial ≤ 4 arrêts). **Plafond d'éclatement** paramétrable : détour total au-delà du seuil → l'app propose au client de scinder en plusieurs commandes.
- **Arrêts collés (marché)** : trois étals voisins ≈ 0 km d'itinéraire réel et +25 par arrêt supplémentaire seulement — l'effort de shopping est rémunéré par les paliers d'articles et la prime d'attente, pas par les arrêts.
- Pendant le drapeau « livraison offerte Mefali » (promo), la grille est **calculée et journalisée mais non facturée** ; elle s'active à la bascule au paiement à la course.

---

## Module CMD — Commandes

**CMD-01 — Panier multi-vendeurs (P0)**
- Le panier accepte des articles de **plusieurs vendeurs agréés** pour les catégories « courses » (marché, boutique, pharmacie, gaz, quincaillerie…) — indispensable au marché où une vendeuse a rarement tout le panier ; articles **regroupés par vendeur** à l'écran, avec le détail des arrêts et de leurs suppléments (TRF-06).
- **Règle de mixage par catégorie** (drapeau `mixable`, paramétrable) : la restauration reste **mono-vendeur par commande** (un plat chaud ne patiente pas pendant trois arrêts) et ne se mélange pas aux courses — si Awa tente, l'app **propose de scinder en 2 commandes distinctes**.
- Quantités ; total articles + frais (TRF-02) avant confirmation ; préférence de substitution par article {remplacer, m'appeler, retirer} (défaut « m'appeler ») ; si cash : montant exact + « préparez l'appoint ».
- **Livraison offerte vendeur (VND-08) : commandes mono-vendeur uniquement** ; panier multi-vendeurs → frais normaux.

**CMD-02 — Adresse de livraison (P0)**
- Pin GPS + bouton « Utiliser ma position actuelle » ; **repère obligatoire : texte (≥ 10 caractères) OU note vocale (≤ 30 s, Garage, jouable par le coursier en course)** ; téléphone vérifié ; adresse enregistrée en 1 tap (repère vocal inclus).

**CMD-03 — Création et choix du paiement (P0)**
- Cash autorisé si montant ≤ plafond de zone ET client sans `prépaiement_imposé` ; restauration + client sans historique : plafond réduit (paramétrable) ; sinon prépaiement mobile money (PAY-02) avant dispatch.
- La commande porte : articles à prix verrouillés, devis figé, préférences, adresse (texte/vocal), mode de paiement, **code de livraison + jeton QR de réception générés et remis au client immédiatement** (voir CRS-04 pour le hors-ligne).

**CMD-04 — Machine à états, cœur générique + extensions (P0)**
- États et transitions du cadrage §7.2 (dont la boucle de collecte **par arrêt**), gardés côté serveur (transition illégale → 409) ; horodatage ; outbox systématique.
- **Structure** : table `commande` = tronc commun **sans aucun champ logistique** (identité, prestataire(s), lieu de prestation, montants, paiement, états de très haut niveau) ; la **`livraison` est un composant optionnel (0..n) rattaché à la commande** — les verticaux de livraison du MVP en créent exactement une ; `livraison → segments (1..n)` (MVP : 1 segment coursier) ; **`segment → arrêts (1..n collectes + 1 remise)`** — chaque arrêt porte prestataire, scan QR, photo éventuelle, montant avancé, statut {à collecter, collecté, indisponible}, dans l'ordre de l'itinéraire optimisé (TRF-06) ; **détails par vertical dans une table dédiée** (`resto_details` au MVP) derrière le trait `ServiceWorkflow` (états additionnels, validations, hooks tarifaires) — provisions anti-divergence du cadrage §11.11/13/14 : aucun champ spécifique à un service, ni logistique, dans le tronc.

**CMD-05 — Suivi client temps réel (P0)**
- États en langage clair ; position coursier ≤ 30 s dès la première collecte, tracée **le long de l'itinéraire multi-arrêts** (progression des arrêts visible : « 2 collectes sur 3 faites ») ; appel coursier (intention journalisée) ; code + QR de réception accessibles à tout moment, **y compris hors ligne** (mis en cache local à la création).

**CMD-06 — Substitutions en course (P0)**
- Article indisponible → application de la préférence : « retirer » → recalcul ; « m'appeler » → appel journalisé + résolution saisie ; « remplacer » → photo + prix, validation push 60 s, sans réponse → retrait ; écart de prix max ±20 % (paramétrable) ; montant recalculé, client notifié — **le total reste payé en une fois** (jamais de partiel).
- La substitution reste **chez le même vendeur** au MVP ; la réaffectation vers un autre vendeur agréé du marché (ajout d'un arrêt en cours de course) est une évolution de phase 2.

**CMD-07 — Annulations (P0)**
- Client : sans frais avant tout achat/récupération ; après achat coursier → règles CMD-08. Admin : à tout moment avec motif ; dédommagement coursier selon règle (part due si RÉCUPÉRÉE atteinte).

**CMD-08 — Échec de livraison (P0)**
- Déclenchable seulement avec les preuves CRS-05 réunies.
- Arbre §7.5 du cadrage : non périssable → retour aux vendeurs concernés (remboursements tracés **par arrêt**) ; refus de reprise → litige + indemnisation coursier ; périssable → litige + sanction client (`prépaiement_imposé` puis `bloqué`) ; vendeur fermé → consigne + re-livraison facturée. Chaque issue journalise qui détient l'argent et la marchandise.

**CMD-10 — File d'attente sans coursier (P0)**
- EN_ATTENTE_COURSIER, client informé (délai estimé + annulation sans frais), FIFO par âge, reprise automatique.

**CMD-09 — Commande aller-retour, 2 segments (P2 — pressing)**
- Contrainte immédiate couverte par CMD-04 (segments n ≥ 2 planifiables).

---

## Module DSP — Dispatch automatique

**DSP-01 — Pool temps réel (P0)**
- `GEOADD` positions (15–30 s, TTL, heartbeat manquant → hors pool avec message « reconnexion ») ; hash état {statut, véhicules, note, plafond du jour, commande active} ; Postgres = vérité, Redis reconstruit sans perte.

**DSP-02 — Éligibilité (P0)**
- En ligne sans commande active ; **capacités requises couvertes** (MVP : type de véhicule — le filtre est générique : d'autres capacités comme les qualifications d'artisans s'y brancheront en phase N sans refonte) ; distance ≤ rayon (Tiassalé : 4 km) ; **capacité d'avance** cash : **montant total des articles (tous arrêts confondus)** ≤ min(grille par note, plafond déclaré) — aucun éligible → bascule prépaiement mobile money notifiée ; paires bloquées exclues.

**DSP-03 — Scoring (P0)**
- `w1·proximité (ETA routière si en cache, sinon distance) + w2·inactivité + w3·note + w4·taux d'acceptation` ; poids éditables (défaut 0,4/0,3/0,2/0,1) ; égalité → aléatoire.

**DSP-04 — Offre en cascade + verrou (P0)**
- `SET offer:{order} {courier} NX EX 45` ; push haute priorité + sonnerie ; timer 40 s ; refus/timeout → suivant ; 3 premiers timeouts du jour non pénalisés ; double acceptation impossible (verrou), le second reçoit « déjà prise » sans pénalité.

**DSP-05 — Broadcast (P0)** — après 3 candidats ou 120 s → tous les éligibles, premier accepteur.

**DSP-06 — Escalade (P0)** — 5 min sans assignation → alerte écran opérations + notification client avec annulation sans frais.

**DSP-07 — Réassignation automatique (P0)** — pas de progression en 5 min ou pas de scan en (prépa + 10) min → relance, retrait, retour pipeline, incident tracé.

**DSP-08 — Anti-abus (P1)** — X annulations post-acceptation / 7 j → suspension auto 24 h, motivée, levable admin.

---

## Module CRS — Coursier

**CRS-01 — Disponibilité et plafond du jour (P0)**
- Toggle en ligne ; déclaration du plafond d'avance ; bandeau gains du jour (pendant la promo de lancement, la paie fixe est gérée hors produit).

**CRS-02 — Écran d'offre (P0)**
- Les **arrêts** (vendeurs dans l'ordre optimisé, distances entre eux), destination approximative, **gain total** (déplacement + grille d'effort), **montant total à avancer**, timer visuel ; sonnerie prolongée (canal dédié) ; accepter/refuser 1 tap.

**CRS-03 — Course active (P0)**
- Itinéraire **multi-arrêts** (arrêt suivant mis en avant) ; **checklist des collectes** : articles regroupés par vendeur, cochés arrêt par arrêt ; **lecture de la note vocale de repère** ; appels via l'app (journalisés) ; scan QR à chaque arrêt ; photo si exigée ; transitions 1 tap.

**CRS-04 — Confirmation de livraison, y compris hors-ligne (P0)**
- Voies : scan du **QR de réception** du client, ou **code à 4 chiffres**, ou dégradé (dépôt autorisé : photo + GPS).
- **Pré-provisionnement hors-ligne** : à l'assignation, l'app télécharge l'empreinte (hash salé) du code et du jeton QR → la vérification fonctionne **sans réseau**, l'événement de confirmation rejoint la file CRS-08 ; le client, lui, n'a jamais besoin d'internet au moment T (code/QR remis à la commande, cf. CMD-03/05).
- 3 codes faux → confirmation bloquée + alerte admin.
- **Ultime recours** (coursier et client hors ligne, code indisponible) : appel au numéro Mefali → confirmation manuelle admin (ADM-02), tracée avec motif et rappel client ultérieur.

**CRS-05 — Preuves d'échec (P0)**
- « Livraison impossible » actif seulement après : ≥ 2 appels via l'app (espacés ≥ 3 min) + 10 min de présence géolocalisée + 1 photo sur place ; preuves attachées au segment et au litige.

**CRS-06 — Caisse et indemnisations (P0)**
- Avances en cours, remboursements, indemnisations (liées à un litige avec preuves) ; validation admin → écriture fonds d'incidents ; **exposition totale temps réel visible admin** (ADM-07).

**CRS-07 — Signaler / bloquer (P1)**
- Motifs prédéfinis + commentaire → modération ; blocage = paire exclue du dispatch ; levable admin.

**CRS-08 — File d'actions hors-ligne (P0)**
- Scans, photos, transitions, confirmations et appels enfilés avec UUID client + horodatage local ; rejeu idempotent ; conflit → serveur fait foi, resynchronisation avec message clair.
- Test : couper le réseau entre le scan QR et la livraison (confirmation locale par hash) ; tout se réconcilie sans perte ni doublon.

*Promotion de lancement — hors produit* : la paie fixe des coursiers pendant la promo est un engagement opérationnel de Mefali, pas une fonctionnalité. Présence vérifiable via les heartbeats existants (DSP-01), paie manuelle ; la bascule au paiement à la course se fait par le drapeau de zone (TRF-02/TRF-05). Aucune story dédiée.

---

## Module PAY — Paiements

**PAY-01 — Chaîne cash (P0)**
- Trace complète **par arrêt** : avance coursier à chaque scan (montant des articles de l'arrêt — ou montant − frais si livraison offerte, mono-vendeur uniquement, retenue visible sur le reçu), remboursement client à la livraison (**totalité de la commande, en une fois**), frais encaissés ; « qui détient quoi » cohérent à chaque état, échecs compris.

**PAY-02 — Prépaiement mobile money via agrégateur (P0)**
- Via `PaymentProvider` (implémentation MVP : **agrégateur**) : le checkout expose **tous les moyens disponibles** chez l'agrégateur retenu — Wave, Orange Money, MTN MoMo, Moov Money, carte le cas échéant ; le moyen utilisé est enregistré sur la transaction (donnée d'analyse).
- Session (lien/page de paiement) à la commande ; EN_ATTENTE_PAIEMENT jusqu'au webhook signé ; expiration 15 min → annulation notifiée ; webhooks idempotents.

**PAY-05 — Abstraction fournisseur (P0)**
- Trait `PaymentProvider { create_checkout, verify_webhook, refund }` ; implémentation MVP = **agrégateur** (tous les moyens d'un coup).
- **Phase 2+** : implémentations directes opérateurs (Wave d'abord) pour réduire les frais ; **routage par moyen de paiement via la configuration de zone** (ex. Wave → direct, le reste → agrégateur), bascule sans toucher au métier, agrégateur conservé en secours.

**PAY-03 — Mobile money sur place (P1)**
- Lien/page de paiement généré par le coursier **du montant total dû** (jamais partiel) — la seule alternative au cash intégral ; confirmation webhook avant clôture.

**PAY-04 — Remboursements (P1)**
- Annulation d'une commande prépayée → refund provider si supporté, sinon procédure manuelle tracée.

**PAY-06 — Commission vendeur dégressive (P2 — activation M4)**
- Barème **marginal** par tranches de CA mensuel via Mefali, **taux décroissants** (valeurs éditables par zone ; indicatif cadrage §12.1 : franchise 0 % ≤ 50 k ; 10 % ; 5 % ; 1 %) ; calcul mensuel depuis les agrégats MET ; recouvrement : retenue prioritaire sur les flux mobile money transitant par Mefali + facture du solde (lien de paiement) ; relevé détaillé visible vendeur.

---

## Module NTF — Notifications

**NTF-01 — Push FCM (P0)**
- Canaux distincts (client normal ; coursier haute importance, sonnerie prolongée ; vendeur) ; deep links ; accusés journalisés.

**NTF-02 — SMS restreints (P0)**
- SMS uniquement : OTP + fallback d'événements critiques listés (**code de livraison**, « coursier arrivé ») si push non accusé en 60 s (paramétrable, désactivable par événement) ; compteur de coût visible admin. Le fallback « code de livraison » sécurise le scénario client hors-ligne (CRS-04).

**NTF-03 — Templates (P1)**
- Push/SMS en templates i18n éditables via config distante ; variables typées ; prévisualisation admin.

---

## Module AVI — Avis, litiges & modération

**AVI-04 — Litiges (P0)**
- Litige lié à commande/segment : type (refus périssable, refus reprise vendeur, casse, non-conformité, faux billet, autre), preuves, statut, résolution (indemnisation → fonds d'incidents, remboursement, sanction) — tout journalisé.

**AVI-01 — Notation (P1)**
- Écran unique facultatif post-livraison : étoiles vendeur + coursier, chips prédéfinis, champ libre ; une notation par commande.

**AVI-02 — Agrégation (P1)**
- Moyennes glissantes fiches/profils ; chips négatifs graves → file de modération.

**AVI-03 — File de modération (P1)**
- Signalements (CRS-07) + chips graves ; actions : avertir, suspendre vendeur (→ QRC-03), suspendre coursier, drapeaux client (CPT-06) ; journalisé.

---

## Module VAP — App vendeur minimale (dans Mefali Pro)

*Lancement possible sans ce module : les fallbacks (dispatch direct, coursier commande sur place) sont en P0.*

**VAP-01 — Statut boutique (P1)** — ouvert/fermé/pause 1 tap ; reflet immédiat ; rappel si « fermé » pendant les horaires habituels.

**VAP-02 — Disponibilité des articles (P1)** — bascule stock/rupture par article (alimente VND-04 et déclenche VND-09 au retour) ; gestion des prix barrés de ses articles (dans les limites fixées par l'admin).

**VAP-03 — Réception de commande (P1)** — sonnerie prolongée ; accepter avec délai (10/20/30/45 min) ou refuser avec motif ; timeout → fallback automatique notifié.

**VAP-04 — Historique du jour (P2)** — commandes, montants (retenues « livraison offerte » détaillées), articles les plus demandés.

---

## Module ADM — Console admin (Nuxt 4)

**ADM-01 — Authentification admin (P0)** — comptes séparés, mot de passe fort, journal des connexions ; 2FA TOTP en P1.

**ADM-02 — Écran opérations (P0)**
- Temps réel : commandes par état, **alertes d'escalade** en tête, carte des coursiers ; actions : réassigner, annuler avec motif, appeler, **« confirmer la livraison manuellement »** (ultime recours hors-ligne CRS-04 — motif obligatoire, tracé, limité au rôle admin).

**ADM-03 — Vendeurs & agrément (P0)** — CRUD fiche + catalogue (prix barrés, config livraison offerte), cycle d'agrément, plaque PDF, suspension, file « à réévaluer » (P1).

**ADM-04 — Coursiers (P0)** — validation dossiers, grille des plafonds d'avance par note (seed : < 4,0 → 5 000 ; 4,0–4,5 → 10 000 ; > 4,5 → 15 000), suspension, incidents.

**ADM-05 — Paramètres de zone (P0)** — tous les paramètres « paramétrables », groupés par module, avec héritage de l'arbre de zones ; chaque modification journalisée (qui, quand, avant/après).

**ADM-06 — Tarification (P0)** — CRUD des règles (bornes de marge validées), **simulateur avec itinéraire affiché** obligatoire avant activation, gestion des drapeaux (livraison offerte Mefali, gratuité commissions, pluie).

**ADM-07 — Caisse, litiges & fonds d'incidents (P0)** — file des litiges avec preuves ; validation d'indemnisation ; solde et mouvements du fonds ; **exposition temps réel** (Σ avances) avec seuil d'alerte.

**ADM-08 — Modération (P1)** — interface de AVI-03.

**ADM-09 — Statistiques (P1)** — consomme les agrégats MET-03 : KPIs du cadrage §16 (dont conversion funnel et conversions « me prévenir »), coût SMS, export CSV ; lien vers Metabase pour l'exploration libre.

---

## Module WEB — Web public

**WEB-01 — Fiche vendeur publique (P0)**
- Nuxt 4 SSR sur `mefali.ci/v/{vendor_id}` : nom, photos, statut, catalogue lecture seule (prix barrés visibles, badge livraison offerte), note ; « Commander dans l'app » (deep link → store) ; balises OG (aperçu WhatsApp) ; vendeur suspendu → page neutre.

**WEB-02 — Annuaire de ville (P2)** — liste SEO des vendeurs agréés par catégorie.

---

## Module MET — Métriques

**MET-01 — Taxonomie d'événements (P0)**
- Catalogue versionné des événements **produit** (ouverture d'app, vue fiche, vue article, ajout panier, début checkout, commande créée, abandon, abonnement « me prévenir », clic notification) et **opérations** (dérivés de l'outbox : transitions, scans, substitutions, litiges), avec propriétés standard {zone, catégorie, rôle, version d'app, plateforme}.
- Toute nouvelle fonctionnalité déclare ses événements (cf. Definition of Done) ; document de taxonomie maintenu dans le dépôt.

**MET-02 — Ingestion batchée et hors-ligne (P0)**
- Endpoint `/events` acceptant des lots ; idempotence par UUID d'événement ; file locale dans les apps (mêmes garanties que CRS-08) ; horodatage client conservé + horodatage serveur ; échantillonnage configurable par type.

**MET-03 — Agrégats et exploration (P1)**
- Agrégats quotidiens (SQL planifié / vues matérialisées) : funnel vue → panier → commande → livraison, KPIs §16, cohortes de re-commande à 30 j, conversions « me prévenir », taux de rupture constatée, délais par étape.
- **Metabase auto-hébergé** branché en lecture sur Postgres ; 3 tableaux de bord de départ : Acquisition & funnel, Opérations du jour, Vendeurs & catalogue.

---

## Récapitulatif des paramètres de zone (référence ADM-05)

| Paramètre | Défaut Tiassalé | Story |
|-----------|-----------------|-------|
| Rayon de dispatch | 4 km | DSP-02 |
| Timer d'offre | 40 s | DSP-04 |
| Broadcast après | 3 candidats ou 120 s | DSP-05 |
| Escalade admin après | 5 min | DSP-06 |
| Réassignation sans mouvement / sans scan | 5 min / prépa + 10 min | DSP-07 |
| Poids de scoring w1–w4 | 0,4 / 0,3 / 0,2 / 0,1 | DSP-03 |
| Plafond cash de zone | 15 000 FCFA | CMD-03 |
| Plafond cash restauration, client sans historique | 5 000 FCFA | CMD-03 |
| Grille plafonds d'avance par note | 5 000 / 10 000 / 15 000 | ADM-04 |
| Distance max de scan QR | 100 m | QRC-02 |
| Essais code (vendeur / livraison) | 3 / 3 | QRC-04, CRS-04 |
| Masquage auto après signalements rupture | 2 en 7 jours | VND-04 |
| Affichage d'un article en rupture (par catégorie) | grisé | VND-04 |
| Conservation de la charte après fin de relation | 5 ans | VND-01 |
| Écart de prix max substitution | ±20 % | CMD-06 |
| Validation client substitution | 60 s | CMD-06 |
| Fallback SMS si push non accusé | 60 s | NTF-02 |
| Anti-spam « me prévenir » | 1 notif / article / 24 h | VND-09 |
| Facteur dégradé routage | × 1,4 (journalisé) | TRF-02 |
| Durée note vocale de repère | ≤ 30 s | CMD-02 |
| Drapeaux de zone | livraison offerte Mefali = ON (lancement), gratuité commissions = ON, pluie = OFF | TRF-02 |
| Grille d'effort — paliers d'articles | 6–10 : +50 ; 11–20 : +100 ; 21+ : +150 | TRF-06 |
| Grille d'effort — prime d'attente | > 15 min : +100 | TRF-06 |
| Grille d'effort — supplément/arrêt (selon distance au précédent) | < 100 m : +25 ; 100 m–1 km : +50 ; > 1 km : +100 | TRF-06 |
| Grille d'effort — plafond d'éclatement (détour max) | seuil à définir | TRF-06 |
| Catégories mixables au panier | courses : oui ; restauration : non | CMD-01 |

---

## Prochaine étape suggérée

Trancher les **valeurs des tranches de commission** et le **choix de l'agrégateur de paiement** (annexe B du cadrage), puis démarrer la tranche T1 : initialisation du dépôt (workspace Rust multi-crates avec le trait `ServiceWorkflow`, 2 apps Flutter, Nuxt 4), vérification des dernières versions stables, et `/specify` sur TRX, ZON, CPT dans cet ordre. Je peux te préparer le squelette du workspace ou les prompts Spec-Kit prêts à coller.
