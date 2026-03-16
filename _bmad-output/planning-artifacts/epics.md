---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
workflow_completed: true
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/planning-artifacts/ux-design-specification.md'
---

# mefali - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for mefali, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

- FR1: Client B2C peut créer un compte via numéro de téléphone + SMS OTP
- FR2: Client B2C peut consulter et modifier son profil (nom, téléphone)
- FR3: Marchand peut créer un compte B2B assisté par un agent terrain
- FR4: Marchand peut consulter et modifier son profil commerce (nom, adresse, horaires, photos)
- FR5: Livreur peut créer un compte via KYC physique + parrain
- FR6: Agent terrain peut créer et valider les comptes marchands et livreurs
- FR7: Admin peut désactiver ou suspendre tout compte utilisateur
- FR8: Marchand peut gérer son catalogue produits (ajouter, modifier, supprimer avec photos et prix)
- FR9: Marchand peut gérer les niveaux de stock par produit
- FR10: Marchand peut définir son état de disponibilité (ouvert / débordé / auto-pausé / fermé)
- FR11: Client B2C peut parcourir les restaurants et marchands à proximité
- FR12: Client B2C peut consulter le catalogue d'un marchand avec photos, prix et notes
- FR13: Client B2C peut ajouter des produits au panier et passer commande
- FR14: Client B2C peut voir le prix total transparent avant confirmation (articles + frais de livraison)
- FR15: Marchand peut recevoir, accepter ou refuser les commandes entrantes
- FR16: Marchand peut marquer une commande comme "prête pour collecte"
- FR17: Système auto-pause un marchand après 3 non-réponses consécutives
- FR18: Livreur peut recevoir des missions de livraison via notification push
- FR19: Livreur peut recevoir des missions via SMS avec données de commande encodées quand hors connexion
- FR20: Livreur peut accepter ou refuser une mission
- FR21: Livreur peut confirmer la collecte chez le marchand
- FR22: Livreur peut naviguer vers l'adresse de livraison via GPS intégré
- FR23: Livreur peut confirmer la livraison complétée
- FR24: Livreur peut déclencher le protocole "client absent" (timer + appel + routing)
- FR25: Client B2C peut suivre sa livraison en temps réel sur une carte
- FR26: Livreur peut définir son statut de disponibilité (actif / en pause)
- FR27: Système peut assigner les livraisons aux livreurs disponibles les plus proches
- FR28: Système peut mettre en file d'attente les confirmations offline et synchroniser au retour de connexion
- FR29: Client B2C peut payer en cash à la livraison (COD)
- FR30: Client B2C peut payer via mobile money (Orange Money, MTN MoMo, Wave) via agrégateur paiement
- FR31: Système retient le paiement en escrow jusqu'à confirmation de livraison
- FR32: Livreur reçoit le paiement sur son wallet < 5 min après confirmation de livraison
- FR33: Livreur peut retirer son solde wallet vers mobile money
- FR34: Marchand reçoit le paiement sur son wallet après libération escrow
- FR35: Marchand peut retirer son solde wallet vers mobile money
- FR36: Système peut réconcilier les soldes wallet internes avec l'agrégateur paiement quotidiennement
- FR37: Admin peut créditer un avoir sur le wallet client (résolution litige)
- FR38: Système envoie des notifications push pour commandes, statuts livraison, paiements
- FR39: Système bascule en SMS quand la notification push échoue (événements critiques livraison)
- FR40: Livreur peut appeler le client directement depuis l'app (scénario client absent)
- FR41: Client B2C peut noter le marchand et le livreur après livraison (double notation)
- FR42: Client B2C peut partager un marchand ou l'app via lien WhatsApp
- FR43: Marchand peut consulter un dashboard de ventes hebdomadaire (total ventes, répartition par produit)
- FR44: Marchand peut recevoir des alertes quand le stock d'un produit descend sous 20% du stock initial
- FR45: Marchand peut gérer ses horaires d'ouverture et fermetures exceptionnelles
- FR46: Marchand peut consulter son historique de commandes et détails des transactions
- FR47: Agent terrain peut onboarder un marchand via flux guidé étape par étape
- FR48: Agent terrain peut capturer les documents KYC (CNI, permis) via caméra
- FR49: Agent terrain peut valider le KYC livreur avec confirmation du parrain
- FR50: Agent terrain peut consulter son dashboard de performance d'onboarding
- FR51: Admin peut consulter le dashboard opérationnel temps réel (commandes, marchands, livreurs)
- FR52: Admin peut gérer et résoudre les litiges avec timeline complète de la commande
- FR53: Admin peut configurer les zones de livraison et le multiplicateur tarifaire par ville
- FR54: Client B2C peut signaler un litige (commande incomplète, problème qualité)
- FR55: Admin peut consulter l'historique marchand et livreur (commandes, litiges, notes)
- FR56: Livreur peut parrainer de nouveaux livreurs (max 3 filleuls actifs)
- FR57: Système contacte le parrain en premier quand un filleul a un problème
- FR58: Système retire le droit de parrainage si les filleuls accumulent des problèmes
- FR59: Agent terrain peut montrer une démo interactive de l'app au marchand avant inscription

### NonFunctional Requirements

- NFR1: Latence API (p95) < 500ms
- NFR2: Temps d'ouverture app < 3s cold start
- NFR3: Taille APK < 30 MB
- NFR4: Consommation data < 5 MB/heure d'usage actif
- NFR5: Sync offline → serveur < 60s après reconnexion
- NFR6: Chargement catalogue marchand < 2s
- NFR7: Mise à jour position GPS livreur toutes les 10s
- NFR8: Chiffrement données en transit TLS 1.2+
- NFR9: Chiffrement documents KYC at rest AES-256
- NFR10: Tokens d'authentification avec expiration < 24h et rotation automatique
- NFR11: Aucun crédit wallet sans transaction agrégateur confirmée
- NFR12: Accès données KYC restreint aux rôles Admin + Agent terrain
- NFR13: Logs d'audit toute action admin/agent terrain
- NFR14: Consentement GPS explicite opt-in
- NFR15: 500 utilisateurs concurrents MVP
- NFR16: 5 000 concurrents Phase 2 sans dégradation > 10%
- NFR17: Base de données avec partitionnement géographique préparé
- NFR18: Stockage photos avec compression automatique WebP
- NFR19: SMS gateway 1 000 SMS/heure en pic
- NFR20: Uptime global > 99%
- NFR21: Paiement livreur post-confirmation < 5 min dans 99.5% des cas
- NFR22: SMS fallback delivery < 30s après échec push
- NFR23: Zéro perte de données offline
- NFR24: Crash rate app < 1% des sessions
- NFR25: Backup base de données quotidien, rétention 30 jours
- NFR26: Agrégateur paiement API latence < 3s
- NFR27: Gestion indisponibilités agrégateur avec queue + retry
- NFR28: SMS gateway dual provider avec basculement automatique
- NFR29: Cache offline zones de livraison Google Maps
- NFR30: Push notification delivery rate > 95% en < 5s

### Additional Requirements

- Starter template : Flutter Melos monorepo (4 apps + 4 packages) + Cargo workspace (6 crates)
- Docker Compose : API (port configurable) + PostgreSQL + Redis + MinIO + Caddy
- PaymentProvider trait abstrait avec CinetPay adapter (swappable)
- SmsProvider trait avec dual provider failover
- Offline sync : Drift SyncQueue + SyncService + conflict resolver
- WebSocket + Redis PubSub pour GPS tracking temps réel
- SQLx migrations (9 tables principales)
- JWT auth avec access token 15 min + refresh 7 jours rotation
- Riverpod pour state management Flutter
- go_router pour navigation Flutter
- Dio pour HTTP client avec interceptors
- Organisation par feature/domaine (pas par type)
- snake_case JSON/DB/API, UUID v4 pour tous les IDs

### UX Design Requirements

- UX-DR1: Package mefali_design avec thème marron light+dark centralisé (mefali_theme.dart, mefali_colors.dart, mefali_typography.dart)
- UX-DR2: MefaliBottomSheet progressif (3 états : peek 25% / half 50% / expanded 85%)
- UX-DR3: RestaurantCard (grille 2 colonnes, photo WebP + nom + note ★ + ETA + prix livraison dynamique)
- UX-DR4: OrderCard B2B (commande entrante avec actions ACCEPTER vert/REFUSER/PRÊTE, notification sonore)
- UX-DR5: DeliveryMissionCard (course avec carte preview + restaurant→destination + distance + gain + CTA pleine largeur)
- UX-DR6: WalletCreditFeedback (animation scale-up "+X FCFA" + son positif + vibration, 2s auto-dismiss)
- UX-DR7: VendorStatusIndicator (4 états : ouvert vert / débordé orange / auto-pausé gris / fermé rouge, interactif B2B, read-only B2C)
- UX-DR8: OrderTimeline (timeline horodatée commande pour litiges admin, états vert/marron pulsant/gris)
- UX-DR9: PriceBreakdownSheet (récapitulatif articles + livraison + total, total = texte le plus gros)
- UX-DR10: DeliveryTracker (carte Google Maps + marker livreur point bleu animé + ETA, updates 10s)
- UX-DR11: MapAddressPicker (carte plein écran + pin central + bouton "Utiliser ma position" proéminent + recherche)
- UX-DR12: Architecture multi-services B2C (ServiceGrid masqué quand 1 service, visible dès 2+)
- UX-DR13: Bottom nav B2C 4 items (Home, Recherche, Commandes, Profil) avec icônes + labels visibles
- UX-DR14: Skeleton screens pour tous les loading states (jamais spinner seul)
- UX-DR15: Son notification custom mefali pour commandes B2B et courses Livreur

### FR Coverage Map

| FR | Epic | Description |
|----|------|-------------|
| FR1 | Epic 2 | Inscription B2C phone+OTP |
| FR2 | Epic 2 | Profil client B2C |
| FR3 | Epic 3 | Compte B2B assisté agent |
| FR4 | Epic 3 | Profil commerce |
| FR5 | Epic 2 | Compte livreur KYC+parrain |
| FR6 | Epic 3 | Agent crée/valide comptes |
| FR7 | Epic 8 | Admin désactive comptes |
| FR8 | Epic 3 | Gestion catalogue produits |
| FR9 | Epic 3 | Gestion stock |
| FR10 | Epic 3 | 4 états disponibilité |
| FR11 | Epic 4 | Browse restaurants |
| FR12 | Epic 4 | Catalogue marchand |
| FR13 | Epic 4 | Panier + commande |
| FR14 | Epic 4 | Prix total transparent |
| FR15 | Epic 3 | Commandes entrantes B2B |
| FR16 | Epic 3 | Marquer commande prête |
| FR17 | Epic 3 | Auto-pause 3 non-réponses |
| FR18 | Epic 5 | Mission via push |
| FR19 | Epic 5 | Mission via SMS offline |
| FR20 | Epic 5 | Accepter/refuser mission |
| FR21 | Epic 5 | Confirmer collecte |
| FR22 | Epic 5 | Navigation GPS |
| FR23 | Epic 5 | Confirmer livraison |
| FR24 | Epic 5 | Protocole client absent |
| FR25 | Epic 5 | Suivi temps réel B2C |
| FR26 | Epic 5 | Statut disponibilité livreur |
| FR27 | Epic 5 | Assignation par proximité |
| FR28 | Epic 5 | Queue offline sync |
| FR29 | Epic 4 | Paiement COD |
| FR30 | Epic 4 | Paiement mobile money |
| FR31 | Epic 4 | Escrow retenue paiement |
| FR32 | Epic 5 | Paiement wallet livreur |
| FR33 | Epic 5 | Retrait wallet livreur |
| FR34 | Epic 6 | Paiement wallet marchand |
| FR35 | Epic 6 | Retrait wallet marchand |
| FR36 | Epic 6 | Réconciliation quotidienne |
| FR37 | Epic 6 | Crédit avoir admin |
| FR38 | Epic 5 | Push notifications |
| FR39 | Epic 5 | SMS fallback |
| FR40 | Epic 5 | Appel client depuis app |
| FR41 | Epic 7 | Notation double |
| FR42 | Epic 7 | Partage WhatsApp |
| FR43 | Epic 3 | Dashboard ventes |
| FR44 | Epic 3 | Alertes stock < 20% |
| FR45 | Epic 3 | Horaires ouverture |
| FR46 | Epic 3 | Historique commandes |
| FR47 | Epic 3 | Onboarding agent guidé |
| FR48 | Epic 3 | Capture KYC caméra |
| FR49 | Epic 3 | KYC livreur + parrain |
| FR50 | Epic 3 | Dashboard agent |
| FR51 | Epic 8 | Dashboard admin ops |
| FR52 | Epic 8 | Litiges + timeline |
| FR53 | Epic 8 | Config zones + pricing |
| FR54 | Epic 7 | Signalement litige client |
| FR55 | Epic 8 | Historique marchand/livreur |
| FR56 | Epic 9 | Parrainage livreur max 3 |
| FR57 | Epic 9 | Contact parrain en premier |
| FR58 | Epic 9 | Retrait droit parrainage |
| FR59 | Epic 3 | Démo interactive agent |

**Coverage : 59/59 FRs → 9 Epics. 0 FR orphelin.**

## Epic List

### Epic 1: Project Foundation & Design System
L'équipe de dev a un environnement opérationnel avec monorepo Flutter, backend Rust, infrastructure Docker, et design system centralisé prêt à l'emploi.
**FRs couverts :** Aucun (enabler technique)
**UX-DR :** UX-DR1
**Addl Req :** Monorepo Melos, Cargo workspace, Docker Compose, SQLx migrations, packages partagés

### Epic 2: Authentication & User Management
Tous les types d'utilisateurs (client, marchand, livreur, agent, admin) peuvent s'inscrire via phone+OTP, se connecter, et gérer leur profil.
**FRs couverts :** FR1, FR2, FR5

### Epic 3: Merchant ERP & Onboarding (Standalone Value)
L'agent terrain onboarde des marchands, le marchand gère son commerce de A à Z (catalogue, stock, commandes, dashboard ventes, horaires). L'ERP fonctionne sans marketplace — c'est le Trojan Horse.
**FRs couverts :** FR3, FR4, FR6, FR8-FR10, FR15-FR17, FR43-FR50, FR59
**UX-DR :** UX-DR4, UX-DR7, UX-DR15

### Epic 4: Customer Food Ordering & Payment
Le client découvre les restaurants, commande, paie (COD ou mobile money), et le paiement est retenu en escrow.
**FRs couverts :** FR11-FR14, FR29-FR31
**UX-DR :** UX-DR2, UX-DR3, UX-DR9, UX-DR11, UX-DR12, UX-DR13, UX-DR14

### Epic 5: Delivery Operations & Real-Time Tracking
Le livreur reçoit les missions (push + SMS fallback), navigue, livre, gère le client absent, et est payé instantanément. Le client suit en temps réel.
**FRs couverts :** FR18-FR28, FR32-FR33, FR38-FR40
**UX-DR :** UX-DR5, UX-DR6, UX-DR10

### Epic 6: Wallet & Financial Operations
Le marchand reçoit ses paiements escrow, retire vers mobile money. Réconciliation quotidienne. Admin crédite des avoirs.
**FRs couverts :** FR34-FR37

### Epic 7: Ratings, Sharing & Customer Feedback
Le client note marchand+livreur, partage via WhatsApp, signale des litiges.
**FRs couverts :** FR41, FR42, FR54

### Epic 8: Admin Dashboard & Operations
L'admin a une vue opérationnelle complète, résout les litiges avec timeline, configure zones et pricing par ville, gère les comptes.
**FRs couverts :** FR7, FR51-FR53, FR55
**UX-DR :** UX-DR8

### Epic 9: Driver Sponsorship System
Le livreur parraine de nouveaux livreurs (max 3), responsabilité partagée, pénalités progressives.
**FRs couverts :** FR56-FR58

---

## Epic 1: Project Foundation & Design System

L'équipe de dev a un environnement opérationnel avec monorepo, infrastructure, et design system prêts.

### Story 1.1: Initialize Flutter Monorepo
As a developer, I want a Melos monorepo with 4 apps and 4 shared packages, So that the team can develop in parallel with shared code.
**Acceptance Criteria:**
**Given** a fresh repository **When** I run `melos bootstrap` **Then** 4 apps and 4 packages are created and linked **And** each app can import shared packages without errors

### Story 1.2: Initialize Rust Backend Workspace
As a developer, I want a Cargo workspace with 6 crates, So that the backend is modular and testable.
**Acceptance Criteria:**
**Given** the server/ directory **When** I run `cargo build --workspace` **Then** all 6 crates compile successfully **And** crate dependencies are correctly resolved

### Story 1.3: Docker Compose Infrastructure
As a developer, I want Docker Compose with API, PostgreSQL, Redis, MinIO, and Caddy, So that the full stack runs locally with one command.
**Acceptance Criteria:**
**Given** a `.env` file with configurable ports (API:8090, PG:5433, Redis:6380, MinIO:9000) **When** I run `docker-compose up` **Then** all 5 services start on configured ports **And** MinIO console is accessible

### Story 1.4: Database Schema & Migrations
As a developer, I want SQLx migrations for all core tables, So that the database is ready for feature development.
**Acceptance Criteria:**
**Given** a running PostgreSQL **When** I run `sqlx migrate run` **Then** all migrations execute successfully **And** tables have UUID primary keys and proper foreign keys

### Story 1.5: Design System Package (Theme)
As a developer, I want mefali_design with marron light+dark theme, So that all 4 apps share a consistent look.
**Acceptance Criteria:**
**Given** mefali_design package **When** an app imports `MefaliTheme.light()` or `.dark()` **Then** M3 theme applies with marron palette **And** ThemeMode.system follows device setting

### Story 1.6: CI/CD Pipeline
As a developer, I want GitHub Actions for Flutter and Rust CI, So that code quality is validated on every push.
**Acceptance Criteria:**
**Given** a push to any branch **When** CI runs **Then** `melos run analyze` and `cargo clippy --workspace` and `cargo test --workspace` all pass

---

## Epic 2: Authentication & User Management

Tous les types d'utilisateurs peuvent s'inscrire, se connecter, et gérer leur profil.

### Story 2.1: Phone + OTP Registration (B2C)
As a client B2C, I want to register with my phone number and SMS OTP, So that I can start using the app in 30 seconds.
**Acceptance Criteria:**
**Given** I open the app for the first time **When** I enter my phone and OTP **Then** my account is created with role "client" and I see the home screen **And** registration takes < 30 seconds

### Story 2.2: JWT Authentication System
As any user, I want to login with auto-refreshing tokens, So that I don't re-login constantly.
**Acceptance Criteria:**
**Given** valid credentials **When** I authenticate **Then** I receive access token (15 min) + refresh token (7 days) **And** expired tokens are refreshed transparently via Dio interceptor

### Story 2.3: Multi-Role Registration
As a livreur, I want to register with my phone and link to my sponsor, So that I'm ready for KYC validation.
**Acceptance Criteria:**
**Given** phone + sponsor's phone **When** I register as livreur **Then** account created with status "pending_kyc" **And** sponsorship link recorded **And** I cannot receive missions until KYC validated

### Story 2.4: User Profile Management
As any user, I want to view and edit my profile, So that my information is up to date.
**Acceptance Criteria:**
**Given** I am logged in **When** I navigate to profile **Then** I see name, phone, role **And** I can edit name **And** phone change requires new OTP

---

## Epic 3: Merchant ERP & Onboarding (Standalone Value)

L'agent terrain onboarde des marchands qui gèrent leur commerce. L'ERP fonctionne sans marketplace.

### Story 3.1: Agent Terrain Merchant Onboarding Flow
As an agent terrain, I want a guided 5-step flow to register a merchant, So that I onboard in < 30 minutes.
**Acceptance Criteria:**
**Given** logged in as agent **When** I follow steps 1-5 (info→catalogue→hours→payment→verify) **Then** merchant created with status "active" **And** progress bar visible **And** each step saveable

### Story 3.2: KYC Document Capture
As an agent terrain, I want to capture CNI/permis photos via camera, So that identity is documented.
**Acceptance Criteria:**
**Given** livreur with status "pending_kyc" **When** I take photos **Then** documents uploaded to MinIO encrypted (AES-256) **And** livreur status changes to "active" **And** sponsor recorded

### Story 3.3: Product Catalogue Management
As a marchand, I want to add/edit/delete products with photos and prices, So that customers see my offerings.
**Acceptance Criteria:**
**Given** logged in as marchand **When** I add a product **Then** it appears in catalogue **And** photos compressed WebP < 200KB stored in MinIO **And** I can edit and delete

### Story 3.4: Stock Level Management
As a marchand, I want to manage stock levels, So that I don't sell items I don't have.
**Acceptance Criteria:**
**Given** a product **When** stock drops below 20% **Then** I receive an alert **And** stock 0 shows "Indisponible"

### Story 3.5: Vendor Availability (4 States)
As a marchand, I want to set availability (ouvert/débordé/auto-pausé/fermé), So that customers know my state.
**Acceptance Criteria:**
**Given** logged in **When** I tap VendorStatusIndicator **Then** I switch between states **And** auto-pausé activates after 3 non-réponses **And** I reactivate in 1 tap

### Story 3.6: Order Reception & Management (B2B)
As a marchand, I want to receive and manage orders with notification sound, So that I never miss an order.
**Acceptance Criteria:**
**Given** order placed **When** it arrives **Then** mefali sound plays, OrderCard shows **And** I can ACCEPTER or REFUSER **And** PRÊTE button triggers livreur assignment

### Story 3.7: Sales Dashboard
As a marchand, I want weekly sales dashboard, So that I understand my business.
**Acceptance Criteria:**
**Given** orders this week **When** I view Stats tab **Then** I see total, count, breakdown by product **And** comparison to previous week **And** works offline via Drift cache

### Story 3.8: Business Hours Management
As a marchand, I want to set opening hours and closures, So that customers know when I'm available.
**Acceptance Criteria:**
**Given** Settings screen **When** I set hours per day **Then** restaurant auto-shows "fermé" outside hours **And** I can add exceptional closures

### Story 3.9: Agent Terrain Performance Dashboard
As an agent terrain, I want my onboarding stats, So that I track daily performance.
**Acceptance Criteria:**
**Given** logged in as agent **When** I view dashboard **Then** I see merchants onboarded, KYC validated, first orders received

### Story 3.10: Demo Mode
As an agent terrain, I want to show a demo to merchants before signup, So that they see the value.
**Acceptance Criteria:**
**Given** potential merchant **When** I activate demo mode **Then** simulated restaurant with sample order is shown **And** notification sound plays

---

## Epic 4: Customer Food Ordering & Payment

Le client découvre, commande, et paie.

### Story 4.1: Restaurant Discovery & Home
As a client B2C, I want restaurants near me in a 2-column grid, So that I quickly find where to order.
**Acceptance Criteria:**
**Given** logged in **When** home loads **Then** RestaurantCards in grid sorted by proximity **And** filter chips at top **And** skeleton screens during loading

### Story 4.2: Restaurant Catalogue View
As a client B2C, I want to view a restaurant's products, So that I choose what to order.
**Acceptance Criteria:**
**Given** I tap a restaurant **When** page opens in MefaliBottomSheet **Then** products listed with photo, name, price **And** VendorStatus visible **And** "+" to add to cart

### Story 4.3: Cart & Order Placement
As a client B2C, I want transparent pricing before ordering, So that I know what I'll pay.
**Acceptance Criteria:**
**Given** items in cart **When** I tap cart **Then** PriceBreakdownSheet shows items + delivery (dynamic) + total **And** total is biggest text **And** I can modify quantities

### Story 4.4: COD Payment Flow
As a client B2C, I want to pay cash on delivery as default, So that I pay when I receive.
**Acceptance Criteria:**
**Given** payment screen **When** COD pre-selected and I confirm **Then** order created, assigned to merchant **And** no payment processed until delivery

### Story 4.5: Mobile Money Payment
As a client B2C, I want to pay via mobile money, So that I pay digitally.
**Acceptance Criteria:**
**Given** I select Mobile Money **When** I confirm **Then** redirect to PaymentProvider flow **And** on success: order created with escrow hold **And** on failure: clear error + retry

### Story 4.6: Address Selection
As a client B2C, I want to select delivery address on a map, So that the driver finds me.
**Acceptance Criteria:**
**Given** address needed **When** I tap address field **Then** MapAddressPicker opens with "Utiliser ma position" **And** I can drag pin if autocomplete fails **And** address saved for future

---

## Epic 5: Delivery Operations & Real-Time Tracking

Le livreur reçoit, livre, et est payé. Le client suit en temps réel.

### Story 5.1: Delivery Mission Notification (Push)
As a livreur, I want mission notifications with details, So that I decide whether to accept.
**Acceptance Criteria:**
**Given** status "actif" **When** order needs driver **Then** push notification + DeliveryMissionCard **And** ACCEPTER full-width button **And** auto-dismiss 30s

### Story 5.2: SMS Fallback for Offline
As a livreur, I want missions via SMS when offline, So that I never miss an opportunity.
**Acceptance Criteria:**
**Given** push fails **When** no acknowledgement within 5s **Then** SMS sent with deep link Base64 **And** tapping link opens app with order data **And** I can accept from decoded data

### Story 5.3: Mission Accept/Refuse & Assignment
As a livreur, I want to accept or refuse missions, So that I only take what I can handle.
**Acceptance Criteria:**
**Given** DeliveryMissionCard **When** ACCEPTER **Then** mission assigned, navigation starts **When** REFUSER or timeout **Then** offered to next closest driver

### Story 5.4: Order Collection & Navigation
As a livreur, I want GPS navigation and collection confirmation, So that I pick up efficiently.
**Acceptance Criteria:**
**Given** accepted mission **When** navigation shows **Then** GPS to merchant **And** tap COLLECTÉ when order in hand **And** merchant notified

### Story 5.5: Real-Time Tracking (Client Side)
As a client B2C, I want to track delivery on a map, So that I know when food arrives.
**Acceptance Criteria:**
**Given** order being delivered **When** tracking screen **Then** DeliveryTracker with blue marker, updates 10s via WebSocket **And** ETA displayed **And** notification at 2 min

### Story 5.6: Delivery Confirmation & Instant Payment
As a livreur, I want to confirm delivery and get paid instantly, So that I'm motivated.
**Acceptance Criteria:**
**Given** at client location **When** tap LIVRÉ **Then** wallet credited < 5 min **And** WalletCreditFeedback "+X FCFA" animation + sound **And** escrow released to merchant

### Story 5.7: Client Absent Protocol
As a livreur, I want a clear protocol when client is absent, So that I'm protected.
**Acceptance Criteria:**
**Given** client absent **When** tap CLIENT ABSENT **Then** 10 min timer + call option **When** timeout + COD **Then** return to resto/base, still paid **When** timeout + prepaid **Then** return to base mefali, client notified, still paid

### Story 5.8: Driver Availability & Wallet Withdrawal
As a livreur, I want to toggle availability and withdraw earnings, So that I control my work.
**Acceptance Criteria:**
**Given** logged in **When** toggle actif/pause **Then** only receive missions when actif **And** withdraw to mobile money arrives in 2 min

---

## Epic 6: Wallet & Financial Operations

### Story 6.1: Merchant Wallet & Escrow Release
As a marchand, I want payment after delivery confirmed, So that I'm paid for orders.
**Acceptance Criteria:**
**Given** delivery confirmed **When** escrow released **Then** amount minus commission credited to wallet **And** transaction in history

### Story 6.2: Merchant Withdrawal
As a marchand, I want to withdraw to mobile money, So that I access earnings.
**Acceptance Criteria:**
**Given** positive balance **When** tap Retirer **Then** processed via PaymentProvider **And** funds arrive in mobile money

### Story 6.3: Daily Reconciliation
As the system, I want daily reconciliation, So that no funds are lost.
**Acceptance Criteria:**
**Given** day of transactions **When** reconciliation runs **Then** all credits matched to aggregator transactions **And** discrepancies flagged **And** no credit without confirmed aggregator transaction

### Story 6.4: Admin Credit/Refund
As an admin, I want to credit client wallet, So that disputes are resolved.
**Acceptance Criteria:**
**Given** resolved dispute **When** I enter amount and confirm **Then** client wallet credited **And** notification sent **And** logged with admin ID

---

## Epic 7: Ratings, Sharing & Customer Feedback

### Story 7.1: Double Rating
As a client B2C, I want to rate merchant and driver separately, So that quality improves.
**Acceptance Criteria:**
**Given** delivery confirmed **When** rating sheet appears **Then** 1-5 stars for merchant AND driver independently **And** visible on cards/profiles

### Story 7.2: WhatsApp Sharing
As a client B2C, I want to share via WhatsApp, So that friends discover mefali.
**Acceptance Criteria:**
**Given** viewing restaurant or app **When** tap share **Then** WhatsApp intent opens with link **And** link includes referral ID

### Story 7.3: Dispute Reporting
As a client B2C, I want to report a problem, So that it gets resolved.
**Acceptance Criteria:**
**Given** completed order **When** tap "Signaler un problème" **Then** select type (incomplete, quality, wrong) **And** dispute created for admin **And** notification when resolved

---

## Epic 8: Admin Dashboard & Operations

### Story 8.1: Admin Operational Dashboard
As an admin, I want real-time dashboard, So that I monitor operations.
**Acceptance Criteria:**
**Given** logged in admin web **When** dashboard loads **Then** orders today, merchants actifs, drivers online, disputes pending **And** auto-refresh

### Story 8.2: Dispute Management with Timeline
As an admin, I want to resolve disputes with full timeline, So that I make informed decisions.
**Acceptance Criteria:**
**Given** dispute reported **When** I open it **Then** OrderTimeline shows all events with timestamps **And** merchant/driver history visible **And** resolve with credit/warn/dismiss

### Story 8.3: City Configuration
As an admin, I want to configure zones and pricing per city, So that prices reflect local economy.
**Acceptance Criteria:**
**Given** Config page **When** set delivery_multiplier **Then** all delivery prices use it **And** zones definable on map **And** changes immediate

### Story 8.4: Account Management
As an admin, I want to deactivate accounts, So that I handle violations.
**Acceptance Criteria:**
**Given** user account **When** deactivate **Then** user cannot login **And** active orders handled **And** action logged

### Story 8.5: Merchant & Driver History
As an admin, I want detailed history, So that I understand performance.
**Acceptance Criteria:**
**Given** merchant/driver profile **When** view history **Then** total orders, completion rate, avg rating, disputes, KYC status

---

## Epic 9: Driver Sponsorship System

### Story 9.1: Driver Sponsorship
As a livreur, I want to sponsor new drivers (max 3), So that I grow the network.
**Acceptance Criteria:**
**Given** active driver with < 3 sponsorships **When** new driver registers with my phone as sponsor **Then** sponsorship recorded **And** max 3 enforced

### Story 9.2: Sponsor-First Contact
As the system, I want to contact sponsor first on issues, So that social accountability works.
**Acceptance Criteria:**
**Given** sponsored driver in dispute **When** system processes it **Then** sponsor notified first **And** contact logged in timeline

### Story 9.3: Progressive Penalties
As the system, I want to revoke sponsorship rights on accumulated problems, So that sponsors take responsibility.
**Acceptance Criteria:**
**Given** sponsor's drivers have 3+ disputes **When** threshold reached **Then** sponsorship rights revoked **And** sponsor notified **And** existing sponsorships stay active
