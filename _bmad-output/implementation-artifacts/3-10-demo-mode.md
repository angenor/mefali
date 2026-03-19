# Story 3.10: Demo Mode

Status: done

## Story

As an agent terrain,
I want to show a demo to merchants before signup,
So that they see the value of the app and sign up.

## Business Context

Le demo mode est l'outil de vente principal de l'agent terrain. FR59 : "Agent terrain peut montrer une démo interactive de l'app au marchand avant inscription." Stratégie Trojan Horse : l'ERP B2B freemium est l'arme d'acquisition — la démo doit convaincre en < 5 min que l'app remplace le carnet et WhatsApp. L'agent montre l'app B2B sur son propre téléphone avant d'installer sur celui du marchand.

## Acceptance Criteria

1. **AC1 — Activation demo mode** : Given agent terrain sur l'écran de login B2B, When il tape "Démo", Then l'app entre en mode demo sans authentification API, avec un restaurant simulé affiché.

2. **AC2 — Restaurant simulé** : Given mode demo actif, When l'écran principal s'affiche, Then un restaurant fictif "Chez Dramane" est présenté avec catalogue (Garba 500F, Alloco-Poisson 800F, Attiéké-Poisson 700F, Jus Bissap 200F), statut "Ouvert", et horaires fictifs.

3. **AC3 — Commande simulée avec notification** : Given mode demo actif, When agent tape "Simuler commande", Then après ~3 secondes une notification sonore mefali joue (UX-DR15) et un OrderCard B2B (UX-DR4) apparaît avec une commande simulée (ex: 2× Garba + 1× Jus Bissap = 1200F).

4. **AC4 — Interaction OrderCard** : Given commande simulée affichée, When le marchand tape ACCEPTER, Then le statut passe à "En préparation". When il tape PRÊTE, Then le statut passe à "Prête — livreur en route". Puis après ~3s, "Livrée — 1200F crédité" s'affiche.

5. **AC5 — Dashboard simulé** : Given mode demo actif, When l'onglet Stats est sélectionné, Then un dashboard de ventes fictif s'affiche (47 commandes cette semaine, CA 58 500F, +12% vs semaine précédente, top produit Garba 49%).

6. **AC6 — Sortie demo** : Given mode demo actif, When agent tape "Quitter la démo", Then retour à l'écran de login. Aucune donnée demo ne persiste.

7. **AC7 — Aucun appel réseau** : Given mode demo actif, Then AUCUN appel API/réseau n'est effectué. Toutes les données sont locales et hardcodées.

## Tasks / Subtasks

- [x] Task 1 — Modèles demo dans mefali_core (AC: 2, 3, 5)
  - [x] 1.1 Créer `packages/mefali_core/lib/models/demo_data.dart` avec les fixtures statiques : `DemoData` class contenant merchant, products, order, dashboard stats
  - [x] 1.2 Réutiliser les modèles existants (`Merchant`, `Product`, `Order`, `OrderItem`, `WeeklySales`) — ne PAS créer de nouveaux modèles
  - [x] 1.3 Exporter depuis `mefali_core.dart`

- [x] Task 2 — DemoProvider Riverpod (AC: 1, 3, 4, 6, 7)
  - [x] 2.1 Créer `packages/mefali_api_client/lib/providers/demo_provider.dart`
  - [x] 2.2 `StateNotifierProvider<DemoNotifier, DemoState>` avec états : `inactive`, `active`, `orderArriving`, `orderIncoming`, `orderAccepted`, `orderReady`, `orderDelivered`
  - [x] 2.3 Méthode `activateDemo()` → charge fixtures locales, aucun appel réseau
  - [x] 2.4 Méthode `simulateOrder()` → attend ~3s via `Future.delayed`, joue son systeme + haptic, transition vers `orderIncoming`
  - [x] 2.5 Méthode `acceptOrder()` → transition vers `orderAccepted`
  - [x] 2.6 Méthode `markReady()` → transition vers `orderReady`, puis ~3s → `orderDelivered`
  - [x] 2.7 Méthode `exitDemo()` → reset à `inactive`
  - [x] 2.8 Exporter depuis `mefali_api_client.dart`

- [x] Task 3 — Son notification demo (AC: 3)
  - [x] 3.1 Vérifié : aucun son custom n'existe dans le B2B app. Utilisation de `SystemSound.play(SystemSoundType.alert)` + `HapticFeedback.heavyImpact()` pour le son de notification
  - [x] 3.2 Pas de mécanisme existant — implémenté directement dans DemoNotifier
  - [x] 3.3 Non nécessaire — son système utilisé, pas de fichier .mp3 requis

- [x] Task 4 — Bouton Demo sur écran login B2B (AC: 1, 6)
  - [x] 4.1 Modifié `apps/mefali_b2b/lib/features/auth/phone_screen.dart`
  - [x] 4.2 Ajouté `TextButton.icon` "Voir la demo" avec icône play_circle_outline orange
  - [x] 4.3 Au tap, appelle `demoNotifier.activateDemo()` et navigue vers `/demo`

- [x] Task 5 — DemoScreen principal (AC: 2, 3, 4, 5)
  - [x] 5.1 Créé `apps/mefali_b2b/lib/features/demo/demo_screen.dart`
  - [x] 5.2 Layout identique au HomeScreen B2B : tabs Commandes | Catalogue | Stats
  - [x] 5.3 AppBar avec "Chez Dramane" + badge "DEMO" orange + bouton close "Quitter"
  - [x] 5.4 Tab Commandes : état vide avec bouton "Simuler une commande", puis OrderCard
  - [x] 5.5 Tab Catalogue : liste des 4 produits avec icônes Material
  - [x] 5.6 Tab Stats : dashboard fictif complet (summary cards + comparaison + product breakdown)
  - [x] 5.7 Bouton "Simuler une commande" sur tab Commandes
  - [x] 5.8 Réutilise OrderCard de mefali_design, VendorStatusIndicator, MefaliCustomColors

- [x] Task 6 — Interaction commande demo (AC: 3, 4)
  - [x] 6.1 Simuler commande → Timer 3s → son systeme + haptic → OrderCard avec highlight orange
  - [x] 6.2 Bouton ACCEPTER (vert, 56dp) → statut "En preparation"
  - [x] 6.3 Bouton PRETE → statut "Prete"
  - [x] 6.4 Timer 3s → "Livree !" avec icone check_circle succes + "credite sur votre wallet"
  - [x] 6.5 Bouton "Relancer la demo" pour recommencer le cycle

- [x] Task 7 — Navigation et routing (AC: 1, 6)
  - [x] 7.1 Ajouté route `/demo` dans `apps/mefali_b2b/lib/app.dart`
  - [x] 7.2 Route bypass auth redirect (`isDemoRoute` check)
  - [x] 7.3 Bouton "Quitter la demo" → `context.go('/auth/phone')` + `exitDemo()`

- [x] Task 8 — Tests widgets Flutter (AC: 1-7)
  - [x] 8.1 Test activation demo depuis login screen (bouton "Voir la demo" présent)
  - [x] 8.2 Test affichage catalogue fictif (4 produits : Garba, Alloco-Poisson, Attieke-Poisson, Jus Bissap)
  - [x] 8.3 Test cycle complet commande : simuler → OrderCard → ACCEPTER → PRETE → Livree
  - [x] 8.4 Test dashboard stats (Total ventes, 47 commandes, Comparaison, Garba top produit)
  - [x] 8.5 Test exit demo : bouton close présent + état reset à inactive
  - [x] 8.6 Test transitions synchrones DemoNotifier (aucun appel API)

## Dev Notes

### Architecture : Feature 100% Frontend Flutter

Le demo mode est entièrement côté client. **AUCUN code Rust backend, AUCUNE migration DB, AUCUN endpoint API.** Toutes les données sont des fixtures Dart hardcodées. Le demo mode simule l'expérience B2B complète avec des données fictives locales.

**Justification :** La démo est montrée AVANT l'inscription du marchand. Il n'a pas de compte, pas de JWT. Le backend n'est pas impliqué.

### Patterns existants à réutiliser obligatoirement

| Composant | Fichier source | Usage dans cette story |
|-----------|----------------|----------------------|
| OrderCard B2B | `apps/mefali_b2b/lib/features/orders/` | Réutiliser le widget OrderCard pour afficher la commande simulée |
| Son notification | `apps/mefali_b2b/` (vérifier assets/sounds/) | Réutiliser le mécanisme de lecture son de 3-6 |
| StatCard / Dashboard | `apps/mefali_b2b/lib/features/sales/sales_dashboard_screen.dart` | Réutiliser `_StatCard`, `_CacheBanner` patterns pour tab Stats demo |
| VendorStatusIndicator | Composant existant (4 états) | Afficher "Ouvert" en vert sur le restaurant demo |
| `_SkeletonLoading` | `sales_dashboard_screen.dart` | NE PAS utiliser — pas de chargement en demo |
| `_formatFcfa` | `sales_dashboard_screen.dart` | Réutiliser pour formater les montants |
| Navigation tabs | `apps/mefali_b2b/lib/features/home/home_screen.dart` | Copier la structure tabs Commandes/Catalogue/Stats |

### Données demo hardcodées

```dart
// Restaurant fictif
const demoMerchant = Merchant(
  id: '00000000-0000-0000-0000-000000000001',
  name: 'Chez Dramane',
  address: 'Marché central, Bouaké',
  status: MerchantStatus.open,
);

// Catalogue fictif (prix en FCFA)
const demoProducts = [
  Product(name: 'Garba', price: 500, stock: 50, photoUrl: null),
  Product(name: 'Alloco-Poisson', price: 800, stock: 30, photoUrl: null),
  Product(name: 'Attiéké-Poisson', price: 700, stock: 25, photoUrl: null),
  Product(name: 'Jus Bissap', price: 200, stock: 40, photoUrl: null),
];

// Commande simulée
const demoOrder = Order(
  items: [
    OrderItem(product: 'Garba', quantity: 2, price: 500),
    OrderItem(product: 'Jus Bissap', quantity: 1, price: 200),
  ],
  total: 1200,
  customerName: 'Koffi A.',
  paymentType: PaymentType.cod,
);

// Stats dashboard fictif
const demoStats = WeeklySales(
  totalOrders: 47,
  totalRevenue: 58500,
  previousWeekRevenue: 52200, // +12%
  topProduct: ProductBreakdown(name: 'Garba', percentage: 49),
);
```

### Anti-patterns à éviter absolument

- **NE PAS** appeler d'API ou endpoint backend en mode demo
- **NE PAS** créer de nouveaux modèles Dart — réutiliser `Merchant`, `Product`, `Order`, `WeeklySales` existants de `mefali_core`
- **NE PAS** persister des données demo en Drift/SQLite
- **NE PAS** créer une migration backend
- **NE PAS** dupliquer les widgets OrderCard ou StatCard — importer et réutiliser depuis les features existantes
- **NE PAS** oublier de vérifier que le son notification existe et fonctionne (implémenté en story 3-6)
- **NE PAS** ajouter de spinner/CircularProgressIndicator — les données demo sont instantanées
- **NE PAS** permettre l'accès au demo mode depuis un état authentifié — c'est un mode pré-login uniquement

### UX Critique

- Touch targets ≥ 48dp (appareils Tecno Spark, Infinix, Itel avec 2GB RAM)
- Badge "DÉMO" visible en permanence en haut de l'écran (orange, pour que le marchand sache que c'est une démo)
- Bouton ACCEPTER : vert, gros, typographie `headlineSmall` minimum
- Le son notification est le son custom mefali (UX-DR15), pas un son système
- Flow "1 tap, pas 3" — chaque action critique = 1 interaction
- Pas de skeleton loading en demo (données locales = instantanées)

### Project Structure Notes

```
apps/mefali_b2b/lib/
  ├── features/
  │   ├── auth/
  │   │   └── phone_screen.dart          ← MODIFIER : ajouter bouton "Voir la démo"
  │   ├── demo/                           ← NOUVEAU dossier
  │   │   └── demo_screen.dart            ← Écran principal demo
  │   ├── catalogue/
  │   ├── home/
  │   ├── orders/                         ← IMPORTER OrderCard widget
  │   ├── sales/                          ← IMPORTER StatCard, _formatFcfa
  │   └── settings/
  ├── app.dart                            ← MODIFIER : ajouter route /demo
  └── main.dart

packages/mefali_core/lib/
  ├── models/
  │   └── demo_data.dart                  ← NOUVEAU : fixtures statiques
  └── mefali_core.dart                    ← MODIFIER : export demo_data

packages/mefali_api_client/lib/
  ├── providers/
  │   └── demo_provider.dart              ← NOUVEAU : StateNotifierProvider
  └── mefali_api_client.dart              ← MODIFIER : export demo_provider
```

### References

- [Source: _bmad-output/planning-artifacts/prd.md — FR59, Journey 4 Fatou, Stratégie Trojan Horse]
- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.10]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Flow 4 Onboarding, UX-DR4 OrderCard, UX-DR15 Son notification]
- [Source: _bmad-output/planning-artifacts/architecture.md — Flutter monorepo structure, B2B features, Riverpod patterns]
- [Source: _bmad-output/implementation-artifacts/3-9-agent-terrain-performance-dashboard.md — Patterns code Flutter/Rust établis]

### Previous Story Intelligence (3-9)

**Learnings appliqués :**
- Provider pattern : `FutureProvider.autoDispose` avec cache in-memory. Pour la demo, utiliser `StateNotifierProvider` (pas FutureProvider) car les données sont synchrones et l'état change de manière interactive.
- Widgets réutilisables : `_StatCard`, `_CacheBanner`, `_ErrorState` de sales_dashboard_screen. Réutiliser `_StatCard` pour le dashboard demo.
- Cache clearing : `clearAgentStatsCache()` pattern au logout. Le demo ne nécessite pas de cache clearing car aucune donnée n'est persistée.
- Tests : 4 widget tests minimum (data display, loading, error, cache). Pour la demo : tester cycle complet (activation → commande → interaction → sortie).

**Review corrections 3-9 (H1) :** Cache leak entre agents → corrigé en appelant `clearAgentStatsCache()` au logout. Leçon : toujours vérifier qu'aucun état ne fuit entre sessions. En demo mode, `exitDemo()` doit reset TOUT l'état du `DemoNotifier`.

### Git Intelligence

Derniers commits Epic 3 :
- `6bd14e0` 3-9-agent-terrain-performance-dashboard: done
- `3a311b8` 3-8-business-hours-management: done
- `7d5daa9` 3-7-sales-dashboard: done
- `be72a3b` 3-6-order-reception-and-management-b2b: done

Pattern de commit : `{story-key}: done` en message final. L'implémentation suit toujours le pattern 3-tier pour le backend (model → repository → service) mais cette story n'a PAS de backend.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Feature 100% frontend Flutter, aucun code Rust backend
- DemoData fixtures statiques reutilisant les modeles existants (Merchant, Product, Order, WeeklySales) — prix en centimes
- DemoNotifier StateNotifier avec machine a etats : inactive → active → orderArriving → orderIncoming → orderAccepted → orderReady → orderDelivered
- Son notification via SystemSound.play(SystemSoundType.alert) + HapticFeedback — pas de package externe ajoute
- Route /demo accessible sans authentification (bypass GoRouter auth redirect)
- 7 widget tests couvrant AC1-AC7, 40 tests total B2B, 0 regression

### Change Log

- 2026-03-19: Implementation complete story 3.10 — demo mode B2B frontend
- 2026-03-19: Code review — 3 MEDIUM fixes: extracted `_formatFcfa` to shared `mefali_core/utils/formatting.dart`, added `autoDispose` to `demoProvider`, converted `_DemoOrdersEmpty` from StatelessWidget to ConsumerWidget

### File List

packages/mefali_core/lib/models/demo_data.dart (new)
packages/mefali_core/lib/mefali_core.dart (modified: export demo_data)
packages/mefali_api_client/lib/providers/demo_provider.dart (new)
packages/mefali_api_client/lib/mefali_api_client.dart (modified: export demo_provider)
apps/mefali_b2b/lib/features/demo/demo_screen.dart (new)
apps/mefali_b2b/lib/features/auth/phone_screen.dart (modified: bouton "Voir la demo")
apps/mefali_b2b/lib/app.dart (modified: route /demo + bypass auth)
apps/mefali_b2b/test/widget_test.dart (modified: 7 tests demo mode ajoutes)
packages/mefali_core/lib/utils/formatting.dart (new — review fix: formatFcfa shared)
apps/mefali_b2b/lib/features/sales/sales_dashboard_screen.dart (modified — review fix: uses shared formatFcfa)
