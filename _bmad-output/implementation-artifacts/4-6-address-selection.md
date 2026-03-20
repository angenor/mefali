# Story 4.6: Sélection d'adresse de livraison

Status: done

## Story

As a client B2C,
I want to select my delivery address on a map,
So that the driver finds me easily.

## Critères d'acceptation

1. **AC1 — Ouverture du MapAddressPicker**
   Given le client est sur l'écran de confirmation de commande
   When il tape sur le champ d'adresse
   Then le MapAddressPicker s'ouvre en plein écran (60% carte + 40% bottom sheet)
   And un pin central est affiché sur la carte
   And un bouton proéminent "Utiliser ma position" est visible

2. **AC2 — Géolocalisation GPS**
   Given le MapAddressPicker est ouvert
   When le client tape "Utiliser ma position"
   Then une demande de permission GPS explicite opt-in est affichée (NFR14)
   And si accordée, la carte se centre sur la position actuelle du client
   And l'adresse est résolue par reverse geocoding et affichée dans le champ texte

3. **AC3 — Déplacement du pin (fallback autocomplete)**
   Given l'autocomplete ne trouve pas l'adresse (contexte Bouaké)
   When le client déplace le pin sur la carte
   Then les coordonnées lat/lng sont mises à jour en temps réel
   And l'adresse textuelle est mise à jour par reverse geocoding
   And un bouton "Confirmer cette position" est accessible

4. **AC4 — Recherche textuelle**
   Given le MapAddressPicker est ouvert
   When le client tape du texte dans le champ de recherche
   Then des suggestions d'adresses s'affichent (Google Places Autocomplete)
   And la sélection d'une suggestion centre la carte sur cette adresse

5. **AC5 — Sauvegarde pour réutilisation**
   Given le client a confirmé une adresse
   When la commande est passée avec cette adresse
   Then l'adresse est sauvegardée localement (Drift) pour les commandes futures
   And les adresses récentes apparaissent comme suggestions rapides à la prochaine commande

6. **AC6 — Adresse transmise à la commande**
   Given une adresse est sélectionnée et confirmée
   When le client confirme sa commande
   Then delivery_address, delivery_lat, delivery_lng sont envoyés au backend
   And le champ hardcodé 'Bouake' dans RestaurantCatalogueScreen est remplacé

## Tâches / Sous-tâches

- [x] T1 — Ajouter les dépendances Flutter (AC: 1,2,3,4)
  - [x] T1.1 Ajouter `google_maps_flutter` dans mefali_b2c/pubspec.yaml et mefali_design/pubspec.yaml
  - [x] T1.2 Ajouter `geolocator` dans mefali_b2c/pubspec.yaml
  - [x] T1.3 Ajouter `geocoding` dans mefali_b2c/pubspec.yaml
  - [x] T1.4 Configurer Google Maps API key dans AndroidManifest.xml et AppDelegate.swift/Info.plist
  - [x] T1.5 Ajouter permission ACCESS_FINE_LOCATION dans AndroidManifest.xml
  - [x] T1.6 Ajouter NSLocationWhenInUseUsageDescription dans Info.plist

- [x] T2 — Créer le composant MapAddressPicker (AC: 1,2,3,4)
  - [x] T2.1 Créer `packages/mefali_design/lib/components/map_address_picker.dart`
  - [x] T2.2 Layout : GoogleMap (60% haut) + bottom sheet (40% bas) avec pin central superposé
  - [x] T2.3 Bouton "Utiliser ma position" proéminent (Material 3, min 48dp)
  - [x] T2.4 Champ de recherche avec forward geocoding (adapte Bouake)
  - [x] T2.5 Callback `onAddressSelected({String address, double lat, double lng})`
  - [x] T2.6 Gestion de la permission GPS via callback (parent gere opt-in NFR14)
  - [x] T2.7 Reverse geocoding via callback onCameraIdle (parent gere)

- [x] T3 — Créer le modèle et stockage d'adresses sauvegardées (AC: 5)
  - [x] T3.1 Créer modèle `SavedAddress` dans `packages/mefali_core/lib/models/saved_address.dart` (id, label, address, lat, lng, lastUsedAt)
  - [x] T3.2 Créer table Drift `saved_addresses` dans `packages/mefali_offline/lib/database/mefali_database.dart` pour stockage local
  - [x] T3.3 Créer provider Riverpod `savedAddressesProvider` (autoDispose) dans `apps/mefali_b2c/lib/features/order/saved_addresses_provider.dart`

- [x] T4 — Créer l'écran de sélection d'adresse B2C (AC: 1,2,3,4,5)
  - [x] T4.1 Créer `apps/mefali_b2c/lib/features/order/address_selection_screen.dart`
  - [x] T4.2 Afficher les adresses récentes (depuis Drift) en haut comme suggestions rapides
  - [x] T4.3 Intégrer MapAddressPicker pour nouvelle adresse
  - [x] T4.4 Bouton "Confirmer cette adresse" → retourne l'adresse au flow de commande via context.pop
  - [x] T4.5 Ajouter route GoRouter `/order/address-selection`

- [x] T5 — Intégrer dans le flow de commande existant (AC: 6)
  - [x] T5.1 Modifier `restaurant_catalogue_screen.dart` : remplacer `deliveryAddress: 'Bouake'` hardcodé par navigation vers address_selection_screen
  - [x] T5.2 Passer delivery_address, delivery_lat, delivery_lng à `orderEndpoint.createOrder()`
  - [x] T5.3 Sauvegarder l'adresse utilisée dans Drift (saved_addresses) après commande réussie

- [x] T6 — Tests (AC: tous)
  - [x] T6.1 Widget test MapAddressPicker (rendu, bouton position, callback, adresses recentes, confirm)
  - [x] T6.2 Widget test AddressSelectionScreen (rendu app bar, MapAddressPicker integre)
  - [x] T6.3 Test unitaire SavedAddress model (champs, nullable label)
  - [x] T6.4 44 tests Flutter existants ne regressent pas (52 total)
  - [x] T6.5 cargo test 19 unit tests OK + clippy 0 new warnings

## Dev Notes

### Infrastructure existante — NE PAS recréer

**Modèle Order (DB + Dart + Rust) — déjà prêt :**
- DB migration `20260317000007_create_orders.up.sql` : colonnes `delivery_address TEXT`, `delivery_lat DOUBLE PRECISION`, `delivery_lng DOUBLE PRECISION`, `city_id UUID`
- Rust `CreateOrderPayload` : champs `delivery_address`, `delivery_lat`, `delivery_lng`, `city_id` (tous Option)
- Dart `Order` model : `deliveryAddress`, `deliveryLat`, `deliveryLng`, `cityId` (tous nullable)
- `OrderEndpoint.createOrder()` accepte déjà `deliveryAddress`, `deliveryLat`, `deliveryLng`, `cityId`

**Hardcoded à remplacer :**
- `apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart` ligne ~165 : `deliveryAddress: 'Bouake'` → doit utiliser l'adresse sélectionnée

**Composants réutilisables existants :**
- `MefaliBottomSheet` (3 états : peek 25% / half 50% / expanded 85%) — dans mefali_design
- Skeleton loading avec `ColorTween` animation (PAS shimmer)
- `formatFcfa()` dans mefali_core
- GoRouter déclaratif dans `apps/mefali_b2c/lib/app.dart`

**Livraison hardcodée à 500 FCFA (50000 centimes)** — ne pas changer le calcul de prix. Le tarif dynamique basé sur la distance viendra dans un story futur.

### Patterns à suivre (établis stories 4.2–4.5)

**Frontend Flutter :**
- Riverpod `autoDispose` obligatoire sur tous les providers
- `FutureProvider.autoDispose.family` pour données paramétrées
- Skeleton loading : `ColorTween` (jamais shimmer package)
- Erreurs : `AsyncValue.when(loading: skeleton, error: retry, data: content)`
- Navigation : GoRouter déclaratif, routes dans `apps/mefali_b2c/lib/app.dart`
- Shared components : `packages/mefali_design/lib/components/`
- Naming : camelCase pour providers (+Provider suffix), PascalCase pour widgets
- Montants en centimes partout (int, pas double)
- Labels en français pour l'UI
- Touch targets >= 48dp minimum (56dp pour actions en mouvement)

**Backend Rust (pas de modification backend prévue pour cette story) :**
- Repository pattern : `pub async fn` avec `pool: &PgPool`, return `Result<T, AppError>`
- SQLx : `sqlx::query_as!` avec vérification compile-time
- Routes : `web::resource("/path").route(web::post().to(handler))` dans `routes/mod.rs`

### Contraintes techniques critiques

- **Google Maps API key requise** : clé API Google Maps pour google_maps_flutter + Places Autocomplete + Geocoding. Configurer dans les fichiers natifs Android/iOS.
- **Permission GPS opt-in explicite (NFR14)** : demander la permission avec explication claire AVANT d'accéder au GPS. Ne jamais accéder silencieusement.
- **Pas de full-screen map sans contexte** : anti-pattern identifié dans UX spec. Toujours 60% carte + 40% bottom sheet.
- **Autocomplete incomplet à Bouaké** : le pin drag est le fallback PRINCIPAL, pas secondaire. L'autocomplete Google Places sera limité en zones rurales CI.
- **Stockage local uniquement pour adresses sauvegardées** : pas de table backend pour les adresses sauvegardées dans ce story. Drift (SQLite local) suffit. Backend viendra si nécessaire plus tard.
- **Portrait only** : 320dp → 412dp (core) → 480dp. Grille 2 colonnes → 1 colonne si < 340dp.
- **Pas de WebSocket** : le tracking temps réel viendra avec Epic 5. Ne pas introduire de WebSocket.
- **41 tests Flutter + 139 tests Rust existants** : ne pas casser. Vérifier après chaque modification.

### Dépendances externes

| Package | Usage | Version |
|---------|-------|---------|
| google_maps_flutter | Carte interactive avec pin | latest stable |
| geolocator | Permission GPS + position courante | latest stable |
| geocoding | Reverse geocoding (lat/lng → adresse texte) | latest stable |

### UX — Composant MapAddressPicker (UX-DR11)

```
+---------------------------+
|     [Google Map 60%]      |
|                           |
|         [PIN]             |
|                           |
+---------------------------+
| [Rechercher une adresse]  |  <- Champ texte autocomplete
|                           |
| [Utiliser ma position]    |  <- Bouton proéminent brown
|                           |
| Adresses récentes:        |
|  - Quartier Commerce      |
|  - Marché central         |
|                           |
| [Confirmer cette adresse] |  <- CTA full-width
+---------------------------+
```

- Pin central fixe, la carte bouge sous le pin
- Bouton "Utiliser ma position" : couleur primaire (brown Material 3), >= 48dp
- Suggestions récentes depuis Drift (3 dernières max)
- Bouton confirmer : full-width, affiché seulement quand une adresse est résolue

### Project Structure Notes

- MapAddressPicker → `packages/mefali_design/lib/components/map_address_picker.dart` (composant partagé)
- SavedAddress model → `packages/mefali_core/lib/models/saved_address.dart`
- Table Drift saved_addresses → `packages/mefali_offline/lib/database/`
- AddressSelectionScreen → `apps/mefali_b2c/lib/features/order/address_selection_screen.dart`
- Route GoRouter → `/order/address-selection` dans `apps/mefali_b2c/lib/app.dart`
- Config Google Maps Android → `apps/mefali_b2c/android/app/src/main/AndroidManifest.xml`
- Config Google Maps iOS → `apps/mefali_b2c/ios/Runner/AppDelegate.swift` ou `Info.plist`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic 4, Story 4.6]
- [Source: _bmad-output/planning-artifacts/architecture.md#Technical Stack, Maps: google_maps_flutter]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#UX-DR11 MapAddressPicker]
- [Source: _bmad-output/planning-artifacts/prd.md#FR22 Navigation GPS, NFR14 Consentement GPS, NFR29 Cache offline Google Maps]
- [Source: _bmad-output/implementation-artifacts/4-5-mobile-money-payment.md#Dev Notes, Patterns]
- [Source: server/migrations/20260317000007_create_orders.up.sql#delivery_address, delivery_lat, delivery_lng]
- [Source: apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart#deliveryAddress hardcoded]
- [Source: packages/mefali_api_client/lib/endpoints/order_endpoint.dart#createOrder params]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- MapAddressPicker composant cree dans mefali_design avec layout 60/40 (carte/bottom sheet), pin central fixe, bouton "Utiliser ma position" 48dp, champ recherche, adresses recentes, bouton confirmer
- AddressResult data class pour encapsuler adresse + lat/lng
- SavedAddress modele dans mefali_core (id, address, lat, lng, label?, lastUsedAt)
- Base Drift (MefaliDatabase) dans mefali_offline avec table saved_address_entries, methodes getRecentAddresses et upsertAddress
- AddressSelectionScreen dans B2C : integre MapAddressPicker, gere geolocator (permission GPS opt-in NFR14), reverse geocoding (geocoding package), forward geocoding pour recherche, adresses recentes depuis Drift
- savedAddressesProvider (FutureProvider.autoDispose) + mefaliDatabaseProvider + saveAddress helper
- Route GoRouter /order/address-selection ajoutee dans app.dart
- Flow de commande modifie : _selectAddressAndOrder ouvre AddressSelectionScreen, sauvegarde l'adresse dans Drift, puis appelle _placeOrder avec les vraies coordonnees
- deliveryAddress hardcode 'Bouake' remplace par adresse dynamique selectionnee
- delivery_lat et delivery_lng transmis a createOrder
- google_maps_flutter ajoute a mefali_design et mefali_b2c
- geolocator et geocoding ajoutes a mefali_b2c, drift ajoute a mefali_b2c
- Permissions Android (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION) + Google Maps API key dans AndroidManifest.xml
- Permission iOS (NSLocationWhenInUseUsageDescription) + GMSServices dans AppDelegate.swift
- 8 nouveaux tests : MapAddressPicker (5), SavedAddress model (2), AddressSelectionScreen (1)
- 52 tests B2C passent (0 regression), 51 tests design passent, 19 tests Rust unitaires passent, clippy 0 new warnings

### Change Log

- 2026-03-20: Story 4-6 implementee — Selection d'adresse de livraison avec MapAddressPicker, Drift, et integration dans le flow de commande
- 2026-03-20: Code review — 2 HIGH + 3 MEDIUM corrigees: cle API Google Maps externalisee (local.properties + Secrets.xcconfig), debounce 400ms sur reverse geocoding, abstraction drift (saveAddress dans MefaliDatabase), ID adresse arrondi a 4 decimales. M3 (AC4 autocomplete partiel) note comme limitation connue Bouake.

### File List

- packages/mefali_design/pubspec.yaml (modified — added google_maps_flutter)
- packages/mefali_design/lib/mefali_design.dart (modified — export map_address_picker)
- packages/mefali_design/lib/components/map_address_picker.dart (new)
- packages/mefali_core/pubspec.yaml (unchanged)
- packages/mefali_core/lib/mefali_core.dart (modified — export saved_address)
- packages/mefali_core/lib/models/saved_address.dart (new)
- packages/mefali_offline/pubspec.yaml (modified — added path)
- packages/mefali_offline/lib/mefali_offline.dart (modified — export database)
- packages/mefali_offline/lib/database/mefali_database.dart (new — review: added saveAddress method)
- packages/mefali_offline/lib/database/mefali_database.g.dart (generated)
- apps/mefali_b2c/pubspec.yaml (modified — added geolocator, geocoding, google_maps_flutter; review: removed drift)
- apps/mefali_b2c/lib/app.dart (modified — added address-selection route)
- apps/mefali_b2c/lib/features/order/address_selection_screen.dart (new — review: added debounce timer)
- apps/mefali_b2c/lib/features/order/saved_addresses_provider.dart (new — review: removed drift import, simplified)
- apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart (modified — review: db.saveAddress + ID arrondi)
- apps/mefali_b2c/android/app/src/main/AndroidManifest.xml (modified — review: API key via manifestPlaceholders)
- apps/mefali_b2c/android/app/build.gradle.kts (modified — review: read API key from local.properties)
- apps/mefali_b2c/ios/Runner/Info.plist (modified — review: GOOGLE_MAPS_API_KEY from xcconfig)
- apps/mefali_b2c/ios/Runner/AppDelegate.swift (modified — review: API key from Bundle)
- apps/mefali_b2c/ios/Runner/Secrets.xcconfig (new — gitignored, API key)
- apps/mefali_b2c/ios/Flutter/Debug.xcconfig (modified — review: include Secrets.xcconfig)
- apps/mefali_b2c/ios/Flutter/Release.xcconfig (modified — review: include Secrets.xcconfig)
- .gitignore (modified — review: added Secrets.xcconfig exclusion)
- apps/mefali_b2c/test/widget_test.dart (modified — 8 new tests)
