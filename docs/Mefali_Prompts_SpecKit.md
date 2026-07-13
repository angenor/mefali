# Mefali — Prompts Spec-Kit (prompts exacts, prêts à coller)

*Compagnon d'exécution du Cadrage v5, des User Stories v2 et de la maquette (docs/design/) — Développement solo avec Claude Code + GitHub Spec-Kit*

---

## 0. Préparation (une seule fois)

```bash
uvx --from git+https://github.com/github/spec-kit.git specify init mefali --ai claude
cd mefali
mkdir -p docs/design
# → copier Mefali_Cadrage_MVP_v5.md        vers docs/cadrage-v5.md
# → copier Mefali_User_Stories_MVP_v2.md   vers docs/user-stories-v2.md
# → copier les exports maquette            vers docs/design/png/, docs/design/html/,
#                                          docs/design/tokens.md
# → copier Mefali_CLAUDE.md                vers ./CLAUDE.md (racine du dépôt, commité)
```

Vérifie le préfixe des commandes de ta version (`/speckit-specify` sur les versions récentes, `/specify` sur les anciennes).

### 0.1 Monorepo — arborescence de référence (créée au cycle 1)

```
mefali/
├── backend/                  # workspace Rust (Cargo workspace)
│   ├── crates/               # zones, comptes, prestataires, qr, tarification,
│   │                         # commandes, dispatch, coursier, paiements,
│   │                         # notifications, avis, metriques
│   ├── api/                  # binaire Actix (assemble les crates, expose utoipa)
│   └── migrations/           # migrations sqlx versionnées + seeds/
├── apps/
│   ├── mefali_client/        # Flutter — app client
│   ├── mefali_pro/           # Flutter — app coursier + vendeur
│   └── packages/
│       └── mefali_core/      # package Dart partagé (thème M3, composants, offline queue)
├── clients/
│   ├── dart/                 # client API généré — jamais édité à la main
│   └── ts/                   # client API généré — jamais édité à la main
├── web/                      # Nuxt 4 (public SSR + /admin ssr:false)
├── infra/                    # docker-compose dev (Postgres, Redis, MinIO, OSRM), VPS, backups
├── docs/                     # cadrage-v5.md, user-stories-v2.md, taxonomie-evenements.md
│   └── design/               # png/ (cible visuelle), html/ (référence de mesures),
│                             # tokens.md (valeurs exactes)
├── specs/                    # généré par Spec-Kit (un dossier par cycle)
└── .github/workflows/        # CI filtrée par chemins + génération clients (échec sur diff)
```

**Cycle par module** (un module = un cycle complet, ordre du §3) :

```
/speckit.constitution   (1 seule fois, §1)
puis : /speckit-specify (§3) → /speckit.clarify (§2.1) → /speckit.plan (§2.2)
→ /speckit.tasks (§2.3) → /speckit.analyze (§2.4) → /speckit.implement (§2.5)
→ commit / merge
```

---

## 1. Constitution (à coller une seule fois)

```
/speckit.constitution

Projet : Mefali — plateforme de services de proximité pour les villes de
l'intérieur de la Côte d'Ivoire. Premier vertical (MVP) : livraison restauration
+ courses chez vendeurs agréés. D'autres verticaux suivront (prestations à
domicile — plomberie, électricité —, e-entrepôt…) : AUCUN crate partagé ne doit
supposer que toute commande est une livraison, ni que tout prestataire est un
vendeur. Ville 1 : Tiassalé. Développeur solo. Monorepo unique.
Documents produit de référence : docs/cadrage-v5.md et docs/user-stories-v2.md —
en cas de doute, ces documents priment sur toute supposition.

Principes non négociables :

1. SOURCES DE VÉRITÉ. (a) Le contrat OpenAPI est généré par utoipa depuis le code
   Actix ; les clients Dart (Flutter) et TypeScript (Nuxt) sont générés depuis ce
   contrat en CI, jamais écrits à la main ; un diff de client non commité fait
   échouer le build. (b) Le schéma PostgreSQL n'est modifié que par migrations
   sqlx versionnées ; une migration appliquée n'est jamais modifiée — on en crée
   une nouvelle ; les seeds (Tiassalé, catégories, grilles) sont rejouables à part.
   (c) Tout paramètre métier qualifié de « paramétrable » vit dans la configuration
   de zone (héritage parent → enfant), jamais en dur dans le code.

2. ARCHITECTURE. Monolithe modulaire Rust : un crate par domaine (zones, comptes,
   prestataires, qr, tarification, commandes, dispatch, coursier, paiements,
   notifications, avis, métriques), interfaces par traits, un schéma Postgres par
   module. L'entité centrale est le PRESTATAIRE (agrément, QR, sites, notes,
   plan) ; le vendeur en est la spécialisation MVP (catalogue, stock). Le tronc
   de commande ne contient AUCUN champ logistique ; la livraison est un composant
   OPTIONNEL (0..n) rattaché à la commande — les verticaux de livraison du MVP en
   créent exactement une ; livraison → segments (1..n) → arrêts (1..n collectes
   + 1 remise) ; le MVP crée 1 segment, le multi-arrêts est actif. Toute
   spécificité de vertical vit dans une table de détails dédiée derrière le trait
   ServiceWorkflow. Le dispatch filtre sur des CAPACITÉS requises (MVP : types de
   véhicule ; le filtre est générique). Redis ne porte que de l'éphémère
   reconstructible (GEO coursiers, verrous SET NX EX, pub/sub, cache, rate-limit).
   MinIO via API S3. Postgres est la seule vérité durable.

3. ARGENT. Tous les montants sont des entiers en unités mineures + code ISO 4217
   porté par la zone (XOF, 0 décimale). Les prix sont verrouillés à la création
   de commande. Aucun paiement partiel, jamais : totalité en cash ou totalité en
   mobile money. La chaîne cash est tracée par arrêt (qui détient quoi, à chaque
   état, échecs compris). Les webhooks de paiement sont idempotents.

4. DISTANCES. Toujours par itinéraire routier (OSRM auto-hébergé), avec waypoints
   pour le multi-arrêts et cache Redis. Jamais de vol d'oiseau, sauf dégradé
   explicite ×1,4 marqué degraded=true et journalisé — une commande n'est jamais
   bloquée par le routage.

5. OFFLINE & IDEMPOTENCE. Toute action de l'app coursier (scans, photos,
   transitions, confirmations) porte un UUID client + horodatage local, part dans
   une file locale hors réseau, et son rejeu est idempotent ; en conflit, le
   serveur fait foi. Les empreintes (hash) du code et du jeton QR de livraison
   sont pré-provisionnées à l'assignation pour valider hors ligne.

6. ÉVÉNEMENTS & MÉTRIQUES. Toute transition d'état écrit un événement outbox dans
   la même transaction SQL. Toute fonctionnalité avec parcours utilisateur déclare
   ses événements dans docs/taxonomie-evenements.md. Aucun KPI manuel.

7. QUALITÉ. Transitions de la machine à états couvertes par des tests
   d'intégration ; requêtes sqlx vérifiées à la compilation (cargo sqlx prepare).
   Aucune chaîne utilisateur en dur : clés i18n (fr, structure prête pour en).
   Logs structurés avec corrélation ; Sentry ; /health.

8. SÉCURITÉ & CONFORMITÉ. OTP SMS rate-limité ; JWT court + refresh révocable ;
   endpoints protégés par rôle ; Swagger UI désactivée ou protégée en production ;
   rétention limitée des photos et notes vocales (ARTCI, minimisation).

9. PÉRIMÈTRE. « Prêt ≠ construit » : les provisions du cadrage §11 (villages,
   interville, multi-sites, plans freemium, flotte vendeur, points relais) sont
   des choix de modèle de données uniquement — aucune UI, aucune logique au MVP.
   Toute fonctionnalité qui n'augmente pas les commandes/jour ou la fiabilité des
   livraisons est refusée (cadrage §3.2). Les priorités P0/P1/P2/PROVISION des
   user stories font foi.

10. VERSIONS. Dernières versions stables de chaque brique (Rust, Actix, sqlx,
    utoipa, Flutter, Shorebird, Nuxt 4, Postgres, Redis, MinIO, OSRM, Metabase),
    vérifiées à l'initialisation puis figées par lockfiles ; revue mensuelle.

11. RÉFÉRENCE VISUELLE. docs/design/png/ = cible visuelle des écrans ;
    docs/design/tokens.md = valeurs exactes (couleurs, typo, espacements) consommées
    par le ThemeData Flutter (Material 3 thémé, Inter embarquée, Material Symbols
    Rounded — DESIGN.md §10) et le thème Nuxt. docs/design/html/ = référence de
    mesures UNIQUEMENT : ne jamais transposer sa structure DOM/CSS en Flutter —
    implémenter en widgets Material 3 + composants mefali_core. Exception : l'admin
    Nuxt peut s'appuyer sur la structure HTML, adaptée aux composants du projet.
    Une seule identité sur Android et iOS : pas de variante Cupertino, conventions
    système via les constructeurs .adaptive.
```

---

## 2. Prompts communs (identiques à chaque cycle, à coller tels quels)

### 2.1 `/speckit-clarify`

```
/speckit-clarify

Avant de me poser une question, vérifie si la réponse est dans docs/cadrage-v5.md
ou docs/user-stories-v2.md et cite la section. Ne me pose que les questions dont
la réponse n'y figure pas. Toute ambiguïté sur un montant, seuil ou timer se
résout par le « Récapitulatif des paramètres de zone » en fin de
docs/user-stories-v2.md (valeur seed, éditable). Toute ambiguïté visuelle se
résout par docs/design/png/ et docs/design/tokens.md.
```

### 2.2 `/speckit-plan`

```
/speckit-plan

Stack imposée (cadrage v5 §10 — non négociable) :
- Backend : Rust stable, Actix Web, sqlx + PostgreSQL (migrations versionnées),
  utoipa + utoipa-swagger-ui, Redis, MinIO (S3), OSRM auto-hébergé.
- Apps : Flutter (mefali_client, mefali_pro) + package partagé mefali_core
  (ThemeData Material 3 depuis docs/design/tokens.md, Inter embarquée .ttf,
  Material Symbols Rounded, composants canoniques, file d'actions offline),
  Shorebird OTA. Une seule identité Android/iOS, conventions via .adaptive.
- Web : Nuxt 4 hybride (pages publiques SSR, /admin/** en ssr:false), client TS
  généré, mêmes tokens.
- CI : régénération clients Dart/TS depuis openapi.json, cargo sqlx prepare,
  tests, lint — filtrée par chemins du monorepo.

Référence visuelle : docs/design/png/ = cible ; docs/design/tokens.md = valeurs
exactes ; docs/design/html/ = mesures uniquement, ne JAMAIS transposer la
structure DOM/CSS en Flutter (exception : l'admin Nuxt peut s'en inspirer
structurellement). Respecte la constitution, en particulier : prestataire ≠
vendeur, commande sans champ logistique (livraison = composant optionnel),
dispatch par capacités, provisions = données seulement.

Livrables attendus du plan : migrations à créer, endpoints (annotations utoipa),
structures de données et traits exposés aux autres crates, événements outbox et
métriques émis, écrans/widgets concernés, tests d'intégration.
```

### 2.3 `/speckit-tasks`

```
/speckit-tasks

Découpe en tâches d'une demi-journée à une journée maximum, ordonnées par
dépendance. Chaque tâche qui touche l'API se termine par : mise à jour des
annotations utoipa + régénération des clients + build vert. Chaque tâche qui
touche le schéma commence par sa migration sqlx. Chaque tâche d'UI référence la
capture docs/design/png/ correspondante. Termine la liste par une tâche « revue
Definition of Done » (docs/user-stories-v2.md §0.4).
```

### 2.4 `/speckit-analyze`

```
/speckit-analyze

Vérifie la cohérence spec ↔ plan ↔ tâches ↔ constitution. Signale toute exigence
des stories du périmètre de ce module non couverte par une tâche, toute tâche qui
déborde du périmètre (P2, PROVISION, hors-périmètre listés dans la spec), et
toute violation des principes 2, 3, 5 et 11 de la constitution.
```

### 2.5 `/speckit-implement`

```
/speckit-implement

Implémente les tâches dans l'ordre. Après chaque tâche : compile, teste, commite
avec un message conventionnel référençant la story (ex. "feat(dispatch): DSP-04
offre en cascade avec verrou Redis"). Ne saute jamais la régénération des
clients. À la fin, déroule cette checklist et liste ce qui resterait non conforme :
[ ] Critères d'acceptation des stories du périmètre couverts par des tests
[ ] Annotations utoipa à jour ; clients Dart/TS régénérés, aucun diff
[ ] Migrations sqlx versionnées ; cargo sqlx prepare vert ; seeds à jour
[ ] Événements outbox émis pour chaque transition ; événements métriques déclarés
[ ] Aucune chaîne en dur (clés i18n fr) ; aucun paramètre métier en dur
[ ] Montants en entiers + devise ; aucun chemin de paiement partiel possible
[ ] Actions offline idempotentes (UUID) là où le module en produit
[ ] UI conforme aux captures docs/design/png/ et aux tokens
[ ] Rien construit au-delà du périmètre (provisions = données seulement)
```

---

## 3. Les 16 prompts `/speckit-specify` (ordre d'exécution)

### Cycle 1 — TRX (bootstrappe le monorepo)

```
/speckit-specify

Lis docs/user-stories-v2.md, module TRX — Transverse & infrastructure, et
docs/cadrage-v5.md sections §10 et §11.

Fonctionnalité : socle technique du monorepo Mefali.
Périmètre : stories TRX-01, TRX-02, TRX-03, TRX-04, TRX-05 — reprends leurs
critères d'acceptation tels quels, n'invente pas d'exigences supplémentaires.
Ce cycle crée aussi : l'arborescence monorepo complète (backend/ workspace Rust
avec un crate par domaine — dont prestataires — vides mais compilables, le trait
ServiceWorkflow défini dans le crate commandes ; apps/mefali_client,
apps/mefali_pro, apps/packages/mefali_core avec le ThemeData Material 3 construit
depuis les tokens, Inter embarquée et Material Symbols Rounded ; web/ Nuxt 4
hybride ; clients/dart et clients/ts générés ; infra/ docker-compose Postgres +
Redis + MinIO + OSRM avec extrait OSM Côte d'Ivoire ; .github/workflows CI
filtrée par chemins). Première tâche obligatoire : vérifier que
docs/design/tokens.md est complet et exploitable (hex, échelle typo, espacements,
rayons — compléter depuis docs/design/html/ si une valeur manque) — c'est ce
fichier que consomme mefali_core.
Hors périmètre : TRX-06 (Shorebird, tranche T4) et TRX-07 (ARTCI, P1) — prévois
seulement l'emplacement.
Personas : Admin (toi).
Points d'attention : premier cycle du projet — vérifie et fige les dernières
versions stables de toute la stack (lockfiles) ; l'openapi.json doit exister dès
ce cycle avec au moins /health documenté, et la CI doit déjà échouer sur un diff
de client non commité.
```

### Cycle 2 — ZON

```
/speckit-specify

Lis docs/user-stories-v2.md, module ZON — Zones & configuration, et
docs/cadrage-v5.md sections §4, §9.4 et §11.1.

Fonctionnalité : arbre de zones et configuration héritée.
Périmètre : ZON-01, ZON-02, ZON-03, ZON-04 — critères d'acceptation tels quels,
seeds Tiassalé inclus (catégories avec seuils d'activation et drapeau mixable —
courses : oui, restauration : non ; types de transport à pied/vélo/moto actifs ;
devise XOF ; drapeaux de zone : livraison offerte Mefali = ON, gratuité
commissions = ON, pluie = OFF).
Hors périmètre : ZON-05 (i18n en, P1) ; niveaux village/quartier = provision de
modèle uniquement (le type de zone existe, aucun écran).
Personas : Admin.
Points d'attention : la résolution de configuration (héritage parent → enfant
avec surcharge) est utilisée par TOUS les modules suivants — expose-la comme un
trait propre du crate zones, testé exhaustivement, y compris les cas de
surcharge partielle.
```

### Cycle 3 — CPT

```
/speckit-specify

Lis docs/user-stories-v2.md, module CPT — Comptes & identité, et
docs/cadrage-v5.md sections §7.1 et §8.2.

Fonctionnalité : comptes, authentification OTP et rôles.
Périmètre : CPT-01, CPT-02, CPT-03, CPT-04, CPT-05 — critères tels quels.
Numéros E.164 (+225 par défaut selon zone) ; OTP 6 chiffres, 5 min, 3 essais,
3 SMS/h/numéro (compteur Redis) ; JWT court + refresh révocable, multi-appareils ;
rôles cumulables {client, coursier, vendeur, admin} sur un compte, coursier et
vendeur validés par l'admin, Mefali Pro bascule d'interface selon rôle ; dossier
coursier (pièce → MinIO, véhicules déclarés depuis le référentiel ZON-03,
référent local) ; adresses enregistrées après livraison réussie, note vocale de
repère incluse.
Hors périmètre : CPT-06 (drapeaux prépaiement_imposé/bloqué, P1) — prévois les
colonnes, pas la logique.
Personas : Awa, Yao, Kofi, Admin.
Points d'attention : le consentement ARTCI est coché à l'inscription ; les
messages d'erreur OTP ne révèlent jamais si un numéro existe.
```

### Cycle 4 — VND (crate `prestataires`)

```
/speckit-specify

Lis docs/user-stories-v2.md, module VND — Vendeurs & catalogue (crate
prestataires), et docs/cadrage-v5.md sections §5, §6 et §11.13.

Fonctionnalité : prestataires agréés et catalogue vendeur.
Périmètre : VND-01, VND-02, VND-03, VND-04 — critères tels quels. Le crate
s'appelle prestataires : agrément, charte, QR (lien vers QRC), sites, notes,
score et plan freemium sont portés par le prestataire ; catalogue d'articles et
stock vivent dans l'extension vendeur (type de prestataire du MVP). Prix barrés
(prix_barré > prix, informatif) ; prix verrouillés à la création de commande ;
statut boutique ouvert/fermé/pause avec horaires ; site unique par défaut ;
rupture par trois sources (vendeur, coursier sur place avec masquage auto après
2 signalements/7 j, admin), chaque bascule émettant un événement.
Hors périmètre : VND-05 (score de fiabilité, P1), VND-08 (livraison offerte, P1,
tranche T3), VND-09 (« me prévenir au retour », P1, tranche T4), VND-06/07
(multi-sites et plans = PROVISIONS : tables seulement) ; article à prix variable
du marché = P1.
Personas : Tantie Affoué, Kofi, Admin.
Points d'attention : la suspension d'un prestataire retire la fiche ET révoque
le QR immédiatement ; la charte inclut l'acceptation de la retenue à la source ;
maquettes de référence : docs/design/png/V1, V2, C2.
```

### Cycle 5 — QRC

```
/speckit-specify

Lis docs/user-stories-v2.md, module QRC — QR & traçabilité, et
docs/cadrage-v5.md section §5.3.

Fonctionnalité : QR prestataire, plaque et scans de collecte.
Périmètre : QRC-01, QRC-02, QRC-03, QRC-04 — critères tels quels. QR encodant
https://mefali.ci/v/{vendor_id}?t={jeton HMAC révocable} + code de secours à
4 chiffres propre au prestataire ; PDF de plaque (MinIO) téléchargeable depuis
l'admin ; scan en course PAR ARRÊT : correspondance prestataire/arrêt, GPS
< 100 m (paramétrable), horodatage serveur → arrêt COLLECTÉ (+ photo si la
politique résolue l'exige : prestataire > catégorie > défaut de zone, forcée
au-dessus d'un seuil de montant) ; toutes les collectes faites → commande
EN_LIVRAISON ; révocation immédiate à la suspension ; mode dégradé : saisie du
code 4 chiffres (confirmation locale comparée au prestataire de l'arrêt — PAS un
identifiant global), géoloc toujours exigée, 3 essais max, incident « plaque à
remplacer » créé.
Hors périmètre : rien de plus — le scan hors contexte (fiche publique) est
implémenté au cycle WEB, prévois seulement l'endpoint de résolution du jeton.
Personas : Yao, Admin.
Points d'attention : les jetons sont révocables côté serveur sans changer la
plaque physique ; maquette de référence : docs/design/png/K3.
```

### Cycle 6 — TRF

```
/speckit-specify

Lis docs/user-stories-v2.md, module TRF — Tarification & devises, et
docs/cadrage-v5.md section §9.

Fonctionnalité : moteur de tarification à règles, routage et grille d'effort.
Périmètre : TRF-01, TRF-02, TRF-03, TRF-04, TRF-05 (P0) et TRF-06 (P1, requise
avant la fin de la promo) — critères tels quels. Règles {zone, catégorie?,
véhicule, tranche de distance, plage horaire/jour, point relais?} → {prix client,
part coursier, marge Mefali bornée 25–100 par zone, devise}, priorité, dates
d'effet ; distance et ETA par ITINÉRAIRE ROUTIER via OSRM avec points de passage
(waypoints — le moteur tarife toujours l'itinéraire complet multi-arrêts), cache
Redis 24 h par paire de points arrondis, dégradé vol d'oiseau ×1,4 journalisé ;
drapeaux de zone (livraison offerte Mefali → prix client 0 ; gratuité → marge 0) ;
simulateur admin obligatoire avant publication ; devises en unités mineures +
ISO 4217 ; seed Tiassalé (à pied 100 ≤ 800 m ; vélo 150 ≤ 2 km ; moto 200 + 50/km
au-delà de 2 km, plafond 500 ; pluie +100 OFF ; marge 0 puis 50). Grille
d'effort : paliers d'articles (6–10 : +50 ; 11–20 : +100 ; 21+ : +150), prime
d'attente (> 15 min entre arrivée géolocalisée et scan : +100), supplément par
arrêt indexé sur la distance au précédent (< 100 m : +25 ; 100 m–1 km : +50 ;
> 1 km : +100), premier arrêt inclus, plafond optionnel du total, plafond
d'éclatement (proposition de scinder) ; 100 % reversée au coursier ; pendant la
promo : calculée et journalisée, non facturée.
Hors périmètre : dimension point relais = présente mais inutilisée ; commission
vendeur (PAY-06, P2).
Personas : Admin, Yao, Awa.
Points d'attention : l'optimisation de l'ordre des arrêts (permutations ≤ 4)
vit ici et est exposée au dispatch et aux commandes ; maquette : docs/design/png/A3.
```

### Cycle 7 — CMD

```
/speckit-specify

Lis docs/user-stories-v2.md, module CMD — Commandes, et docs/cadrage-v5.md
sections §7.2, §7.5 et §8.

Fonctionnalité : cycle de vie complet d'une commande multi-vendeurs.
Périmètre : CMD-01, CMD-02, CMD-03, CMD-04, CMD-05, CMD-06, CMD-07, CMD-08,
CMD-10 — critères tels quels. Le modèle structurel est impératif : table
commande = tronc commun SANS champ logistique (identité, prestataire(s), lieu de
prestation, montants, paiement, états de très haut niveau) ; la livraison est un
composant OPTIONNEL (0..n) rattaché — les verticaux du MVP en créent exactement
une ; livraison → segments (MVP : 1) → arrêts (1..n collectes + 1 remise),
chaque arrêt portant prestataire, scan, photo éventuelle, montant avancé, statut,
dans l'ordre optimisé par TRF ; détails de vertical dans resto_details derrière
le trait ServiceWorkflow ; machine à états gardée serveur avec la boucle de
collecte par arrêt ; panier multi-vendeurs pour les catégories courses, articles
regroupés par vendeur, drapeau mixable (restauration mono-vendeur, proposition
de scinder en 2 commandes) ; livraison offerte vendeur = mono-vendeur uniquement ;
adresse = pin GPS + « ma position actuelle » + repère TEXTE OU NOTE VOCALE
≤ 30 s (MinIO) + téléphone vérifié ; code de livraison + jeton QR de réception
générés et remis au client DÈS LA CRÉATION (cache local — base du hors-ligne de
CRS-04) ; substitutions selon la préférence par article, chez le même vendeur,
total toujours payé en une fois ; l'arbre complet des échecs du cadrage §7.5 est
couvert par des tests d'intégration, cas par cas.
Hors périmètre : CMD-09 (aller-retour pressing, P2 — le modèle segments n ≥ 2
suffit) ; réaffectation d'un article vers un autre vendeur (phase 2).
Personas : Awa, Yao, Tantie Affoué, Kofi.
Points d'attention : dépendances = zones, comptes, prestataires, tarification
(devis figé), QR (scan par arrêt) ; maquettes : docs/design/png/C3, C4.
```

### Cycle 8 — DSP

```
/speckit-specify

Lis docs/user-stories-v2.md, module DSP — Dispatch automatique, et
docs/cadrage-v5.md section §7.3.

Fonctionnalité : assignation automatique des courses, sans intervention humaine.
Périmètre : DSP-01, DSP-02, DSP-03, DSP-04, DSP-05, DSP-06, DSP-07 — critères
tels quels. Pool temps réel Redis (GEO + TTL, heartbeats 15–30 s, coursier muet
hors pool) ; éligibilité : CAPACITÉS requises couvertes (MVP : types de véhicule,
filtre générique), rayon 4 km, capacité d'avance cash sur le MONTANT TOTAL tous
arrêts confondus ≤ min(grille par note, plafond déclaré du jour) sinon bascule
prépaiement mobile money notifiée, paires bloquées exclues ; scoring pondéré
normalisé (0,4 proximité ETA / 0,3 inactivité / 0,2 note / 0,1 acceptation,
poids par zone) ; offre en cascade avec verrou SET offer:{order} NX EX 45 et
timer 40 s, 3 premiers timeouts du jour non pénalisés ; broadcast après 3
candidats ou 120 s, premier accepteur ; escalade écran admin à 5 min +
notification client avec annulation sans frais ; réassignation automatique (pas
de mouvement 5 min / pas de scan prépa+10 min) ; file FIFO si aucun éligible.
Tous les paramètres viennent de la configuration de zone, aucun en dur.
Hors périmètre : DSP-08 (anti-abus, P1) ; stacking 2 commandes (phase 2).
Personas : Yao, Admin.
Points d'attention : la double acceptation doit être physiquement impossible
(test de concurrence sur le verrou) ; une perte Redis ne perd aucune donnée
métier (Postgres = vérité, pool reconstruit par heartbeats) ; maquette :
docs/design/png/K2.
```

### Cycle 9 — CRS

```
/speckit-specify

Lis docs/user-stories-v2.md, module CRS — Coursier, et docs/cadrage-v5.md
sections §7.4, §7.5 et §7.6.

Fonctionnalité : app coursier — course active multi-arrêts, cash et hors-ligne.
Périmètre : CRS-01, CRS-02, CRS-03, CRS-04, CRS-05, CRS-06, CRS-08 — critères
tels quels. Disponibilité + plafond d'avance du jour + gains ; écran d'offre
(arrêts ordonnés, gain total, montant total à avancer, timer, sonnerie canal
haute importance) ; course active = itinéraire multi-arrêts avec checklist des
collectes par vendeur, lecture des notes vocales de repère, appels via l'app
journalisés, scan par arrêt, transitions 1 tap ; confirmation de livraison à
trois voies (scan du QR de réception client / code 4 chiffres / dégradé dépôt
autorisé) avec PRÉ-PROVISIONNEMENT HORS-LIGNE : à l'assignation l'app télécharge
les empreintes (hash salé) du code et du jeton QR pour valider sans réseau,
3 codes faux = blocage + alerte admin ; preuves d'échec (bouton inactif tant que
≥ 2 appels via l'app espacés de 3 min + 10 min de présence géolocalisée + 1 photo
ne sont pas réunis) ; caisse (avances par arrêt, remboursements, indemnisations
liées à un litige) ; file d'actions hors-ligne avec UUID client, rejeu
idempotent, serveur fait foi en conflit — test obligatoire : couper le réseau
entre le scan et la livraison, tout se réconcilie sans perte ni doublon.
Hors périmètre : CRS-07 (signaler/bloquer, P1). La paie fixe de la promo est
HORS PRODUIT (aucune story) : présence vérifiable via les heartbeats DSP-01.
Personas : Yao.
Points d'attention : c'est le module le plus critique opérationnellement ;
maquettes : docs/design/png/K1, K2, K3, K4, K5 — la checklist multi-arrêts de
K3 est la cible exacte.
```

### Cycle 10 — PAY

```
/speckit-specify

Lis docs/user-stories-v2.md, module PAY — Paiements, et docs/cadrage-v5.md
sections §10.7 et §12.

Fonctionnalité : chaîne cash et prépaiement mobile money via agrégateur.
Périmètre : PAY-01, PAY-02, PAY-05 — critères tels quels. Trait PaymentProvider
{ create_checkout, verify_webhook, refund } ; implémentation MVP = AGRÉGATEUR
(le checkout expose tous les moyens disponibles : Wave, Orange Money, MTN MoMo,
Moov, carte le cas échéant ; le moyen utilisé est enregistré sur la transaction) ;
session de paiement à la commande, EN_ATTENTE_PAIEMENT jusqu'au webhook signé,
expiration 15 min → annulation notifiée, webhooks idempotents ; chaîne cash
tracée PAR ARRÊT (avance au scan — ou montant − frais si livraison offerte,
mono-vendeur uniquement, retenue visible sur le reçu —, remboursement client à
la livraison en totalité et en une fois, frais encaissés) ; « qui détient quoi »
cohérent à chaque état, échecs compris.
Hors périmètre : PAY-03 (mobile money sur place, P1), PAY-04 (remboursements,
P1), PAY-06 (commission dégressive, P2). Le routage par moyen de paiement vers
des intégrations directes opérateurs = phase 2+, l'interface le permet déjà.
Personas : Awa, Yao, Admin.
Points d'attention : l'agrégateur précis n'est pas encore choisi — isole tout ce
qui lui est spécifique derrière le trait pour que le choix reste réversible ;
JAMAIS de chemin de paiement partiel.
```

### Cycle 11 — NTF

```
/speckit-specify

Lis docs/user-stories-v2.md, module NTF — Notifications, et docs/cadrage-v5.md
section §10.8.

Fonctionnalité : push FCM et SMS strictement limités.
Périmètre : NTF-01, NTF-02 — critères tels quels. Canaux Android distincts :
client (normal), coursier (haute importance, sonnerie prolongée), vendeur ; deep
links vers l'écran concerné ; accusés de réception journalisés ; SMS uniquement
pour l'OTP et le fallback conditionnel des événements critiques listés (code de
livraison, « coursier arrivé ») si le push n'est pas accusé en 60 s (paramétrable,
désactivable par événement) ; compteur de coût SMS visible admin.
Hors périmètre : NTF-03 (templates éditables, P1).
Personas : tous.
Points d'attention : le fallback SMS du code de livraison est ce qui garantit le
scénario « client sans internet à la livraison » (CRS-04) — teste-le explicitement.
```

### Cycle 12 — MET

```
/speckit-specify

Lis docs/user-stories-v2.md, module MET — Métriques, et docs/cadrage-v5.md
sections §10.9 et §16.

Fonctionnalité : taxonomie d'événements et ingestion analytics.
Périmètre : MET-01, MET-02 — critères tels quels. Catalogue versionné dans
docs/taxonomie-evenements.md : événements produit (ouverture d'app, vue fiche,
vue article, ajout panier, début checkout, commande créée, abandon, abonnement
« me prévenir », clic notification) et opérations (dérivés de l'outbox) avec
propriétés standard {zone, catégorie, rôle, version d'app, plateforme} ;
endpoint /events acceptant des lots, idempotence par UUID d'événement, file
locale dans les apps (mêmes garanties que la file coursier), horodatages client
ET serveur conservés, échantillonnage configurable par type.
Hors périmètre : MET-03 (agrégats quotidiens + Metabase, P1, tranche T3).
Personas : Admin.
Points d'attention : mets à jour la Definition of Done du projet pour que toute
nouvelle fonctionnalité déclare ses événements ici.
```

### Cycle 13 — AVI

```
/speckit-specify

Lis docs/user-stories-v2.md, module AVI — Avis, litiges & modération, et
docs/cadrage-v5.md sections §7.5 et §5.1.

Fonctionnalité : litiges et résolution des incidents.
Périmètre : AVI-04 — critères tels quels. Entité litige liée à une commande /
un segment / un arrêt : type (refus périssable, refus de reprise vendeur, casse,
non-conformité, faux billet, autre), preuves attachées (appels horodatés, photos,
géolocalisation, issues de CRS-05), statut {ouvert, résolu}, résolution
(indemnisation coursier → écriture au fonds d'incidents, remboursement, sanction
client via les drapeaux CPT-06, sanction prestataire) — chaque résolution
journalisée.
Hors périmètre : AVI-01 (notation), AVI-02 (agrégation), AVI-03 (file de
modération) — P1, tranche T4.
Personas : Yao, Admin.
Points d'attention : le litige est le pivot de la promesse « le coursier ne perd
jamais » — l'indemnisation est impossible sans preuves attachées.
```

### Cycle 14 — ADM

```
/speckit-specify

Lis docs/user-stories-v2.md, module ADM — Console admin, et docs/cadrage-v5.md
sections §7.3, §9 et §16.

Fonctionnalité : console d'administration Nuxt 4.
Périmètre : ADM-01, ADM-02, ADM-03, ADM-04, ADM-05, ADM-06, ADM-07 — critères
tels quels. Auth admin séparée (mot de passe fort, journal des connexions) ;
écran opérations temps réel (commandes par état, ALERTES d'escalade en tête,
carte des coursiers, actions réassigner/annuler/appeler, bouton d'ultime recours
« Confirmer la livraison manuellement » avec motif obligatoire et traçage) ;
prestataires & agrément (CRUD, catalogue avec prix barrés, config livraison
offerte, plaque PDF, suspension → révocation QR) ; coursiers (validation
dossiers, grille des plafonds d'avance par note : 5 000 / 10 000 / 15 000) ;
paramètres de zone (tous les « paramétrables », héritage, journal
avant/après) ; tarification (CRUD règles + drapeaux + SIMULATEUR obligatoire
avec itinéraire affiché avant publication) ; caisse & litiges (file avec preuves,
validation d'indemnisation, solde du fonds, EXPOSITION CASH TEMPS RÉEL = Σ
avances en cours avec seuil d'alerte).
Hors périmètre : ADM-08 (modération, P1), ADM-09 (statistiques, P1, dépend de
MET-03) ; 2FA TOTP = P1.
Personas : Admin.
Points d'attention : /admin/** en ssr:false ; ici l'exception du principe 11
s'applique — les exports docs/design/html/ (A1–A4) peuvent servir de référence
structurelle, adaptés aux composants du projet ; maquettes : docs/design/png/A1,
A2, A3, A4.
```

### Cycle 15 — WEB

```
/speckit-specify

Lis docs/user-stories-v2.md, module WEB — Web public, et docs/cadrage-v5.md
section §5.3.

Fonctionnalité : fiche prestataire publique (cible du scan QR hors contexte).
Périmètre : WEB-01 — critères tels quels. Page Nuxt 4 SSR sur
mefali.ci/v/{vendor_id} : nom, photos, statut ouvert/fermé, catalogue en lecture
seule (prix barrés visibles, badge livraison offerte), note ; bouton « Commander
dans l'app » (deep link, sinon store) ; balises OG pour un aperçu propre au
partage WhatsApp ; prestataire suspendu → page neutre « indisponible ».
Hors périmètre : WEB-02 (annuaire de ville, P2).
Personas : Awa (et tout passant qui scanne une plaque).
Points d'attention : cette page est un canal d'acquisition — performance sur
connexion limitée (SSR léger, images optimisées) ; réutilise l'endpoint de
résolution de jeton du cycle QRC.
```

### Cycle 16 — VAP

```
/speckit-specify

Lis docs/user-stories-v2.md, module VAP — App vendeur minimale, et
docs/cadrage-v5.md sections §6.2 et §6.3.

Fonctionnalité : rôle vendeur dans Mefali Pro (entièrement P1 — le lancement est
possible sans : les fallbacks sont en P0 côté CMD/DSP).
Périmètre : VAP-01, VAP-02, VAP-03 — critères tels quels. Statut boutique
ouvert/fermé/pause en 1 tap avec rappel si fermé pendant les horaires habituels ;
bascule stock/rupture par article (alimente VND-04 et déclenchera VND-09) +
gestion des prix barrés dans les limites fixées par l'admin ; réception de
commande plein écran avec sonnerie prolongée, accepter avec délai (10/20/30/45
min) ou refuser avec motif, timeout → fallback automatique notifié au vendeur.
Hors périmètre : VAP-04 (historique du jour, P2).
Personas : Tantie Affoué (peu technophile — c'est ELLE qui dimensionne l'UX :
gestes uniques, toggles géants, pictos, couleurs franches), Kofi.
Points d'attention : maquettes : docs/design/png/V1, V2, V3 — respecte leur
extrême simplicité, ne rajoute rien.
```

---

## 4. Ordre d'exécution par tranche

| Tranche | Cycles à dérouler | Démo de sortie |
|---------|-------------------|----------------|
| T1 (S3–S6) | 1 → 9 (TRX, ZON, CPT, VND, QRC, TRF, CMD, DSP, CRS) + NTF-01 du cycle 11 et MET du cycle 12 | Awa commande 8 articles chez 2 étals, dispatch auto, Yao collecte arrêt par arrêt et livre par scan du QR client — de bout en bout |
| T2 (S7–S8) | Fin des cycles 7–9 (échecs, preuves, caisse) + cycle 13 (AVI) + ADM-07 | Tous les cas d'échec du §7.5 tracés, indemnisations sur preuves |
| T3 (S9–S11) | Cycles 10 (PAY), 14 (ADM), 15 (WEB) + TRF-06, VND-08, NTF-02, MET-03 | Mobile money tous moyens ; pilotage admin complet ; fiche publique scannable |
| T4 (S12) | Cycle 16 (VAP) + VND-05/09, AVI-01/02/03, CRS-07, DSP-08, TRX-06, ADM-08/09 | Vendeur équipé ; « me prévenir au retour » actif ; patch Shorebird déployé |

S13–S14 : bêta fermée. S15–S16 : correctifs, P1 restants, lancement Tiassalé.

Chaque cycle spécifie l'ensemble de son périmètre ; dans `/speckit.tasks`, les
tâches P1 sont placées en fin de liste pour être livrables après le cœur P0.

---

## 5. Règles de conduite du dépôt

- **Une branche par cycle** (`feat/dsp-dispatch`), merge quand la checklist du §2.5 passe.
- **Commits conventionnels référençant les stories** : `feat(cmd): CMD-04 machine à états segment→arrêts`.
- **Si une décision produit change** : mettre à jour d'abord `docs/cadrage-v5.md` / `docs/user-stories-v2.md` (et `docs/design/` si visuel), puis relancer `/speckit-specify` du module concerné — jamais l'inverse.
- **Fin de chaque tranche** : tag Git (`t1-done`), démo réelle sur téléphone Android d'entrée de gamme, restauration de sauvegarde testée.
