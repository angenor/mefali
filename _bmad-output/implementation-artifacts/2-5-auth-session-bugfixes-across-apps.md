# Story 2.5: Correction bugs auth/session sur les 3 apps (B2B, B2C, Livreur)

Status: ready-for-dev

## Story

As a développeur,
I want corriger les bugs critiques d'authentification et de session sur les 3 apps mobiles,
so that les testeurs et futurs utilisateurs puissent créer un compte, se connecter, et retrouver leur session sans perte de données.

## Contexte

Trois bugs critiques ont été identifiés lors des tests sur les apps :

1. **B2B** : Après création de compte, la page d'accueil s'affiche correctement. Mais quand l'utilisateur quitte l'app et revient, toutes ses infos disparaissent (nom, données, etc.)
2. **B2C** : Après avoir entré le code OTP `123456`, une erreur s'affiche (capture fournie par le testeur)
3. **Livreur** : L'app ne démarre même pas — elle reste bloquée en permanence sur un écran noir

Le serveur est configuré avec `DEV_MODE=true`, ce qui fait que le code OTP `123456` est accepté pour toutes les apps.

## Acceptance Criteria

### Bug 1 — B2B : Session perdue au redémarrage

1. **Given** un marchand qui vient de créer son compte via l'app B2B **When** il quitte l'app et la relance **Then** il est automatiquement redirigé vers `/home` avec son nom et ses données visibles (pas de retour à l'écran de login)
2. **Given** un marchand authentifié dont l'access token a expiré (15 min) **When** il relance l'app **Then** les tokens sont restaurés depuis SecureStorage ET le profil utilisateur est rechargé depuis le serveur

### Bug 2 — B2C : Erreur après saisie OTP

3. **Given** un nouveau client B2C sur l'écran OTP **When** il entre le code `123456` **Then** il est redirigé vers l'écran de saisie du prénom (`/auth/name`) sans erreur
4. **Given** le client B2C a saisi son prénom sur `/auth/name` **When** il appuie sur "Commencer" **Then** `verifyOtp` est appelé avec `(phone, otp, name)` et l'utilisateur est redirigé vers `/home` (ou une erreur explicite est affichée si le serveur est injoignable)

### Bug 3 — Livreur : Écran noir au démarrage

5. **Given** l'app mefali_livreur est installée sur un appareil Android **When** l'utilisateur ouvre l'app **Then** l'écran de login (`/auth/phone`) s'affiche en moins de 3 secondes
6. **Given** l'app livreur démarre **When** Firebase n'est pas configuré (pas de `google-services.json`) **Then** l'app doit quand même démarrer et fonctionner (auth, navigation) sans Firebase/FCM

### Transversal

7. **Given** `DEV_MODE=true` sur le serveur **When** n'importe quelle app envoie le code `123456` **Then** l'authentification réussit pour les 3 apps (B2B, B2C, Livreur)

## Tasks / Subtasks

### Bug 1 : B2B — Session perdue au redémarrage (AC: #1, #2)

- [ ] **Task 1.1** : Restaurer le profil utilisateur après chargement des tokens (AC: #1, #2)
  - Le problème : `loadFromStorage()` dans `auth_provider.dart` restaure les tokens mais PAS l'objet `User`. Après redémarrage, `authState.user` est `null` même si `isAuthenticated == true`.
  - [ ] Dans `AuthNotifier.loadFromStorage()`, après avoir restauré les tokens, appeler l'endpoint `/api/v1/users/me` (ou équivalent) pour recharger le profil utilisateur
  - [ ] Si l'appel API échoue (offline), garder `user: null` — le home screen doit gérer ce cas gracieusement
  - [ ] Alternativement, persister le `User` dans SecureStorage (sérialisé en JSON) et le restaurer en local, puis rafraîchir en background

### Bug 2 : B2C — Erreur après saisie OTP (AC: #3, #4)

- [ ] **Task 2.1** : Diagnostiquer l'erreur exacte (AC: #3)
  - La navigation B2C après OTP fonctionne ainsi : OtpScreen entre 6 chiffres → `context.go('/auth/name', extra: {'phone': phone, 'otp': otp})` → NameScreen → appuie "Commencer" → `verifyOtp(phone, otp, name)`
  - Les causes possibles sont :
    - **API_BASE_URL incorrecte** : par défaut `http://10.0.2.2:8090/api/v1` (emulateur Android), ne fonctionne pas sur appareil réel
    - **Erreur réseau** : le serveur n'est pas joignable depuis l'appareil de test
    - **Le code OTP expire** entre la saisie et la vérification (peu probable, TTL 5 min)
    - **Erreur serveur** : si le user n'existe pas et que `name` n'est pas fourni correctement
  - [ ] Vérifier que l'app B2C est buildée avec le bon `API_BASE_URL` pointant vers `api.mefali.com` ou l'IP du serveur de test
  - [ ] Ajouter un log visible ou un message d'erreur plus explicite dans NameScreen pour afficher le détail de l'erreur serveur (pas juste "Erreur: ...")

- [ ] **Task 2.2** : S'assurer que le build de test utilise la bonne URL API (AC: #4)
  - [ ] Documenter ou fixer la commande de build pour les 3 apps avec le bon `--dart-define=API_BASE_URL=...`
  - [ ] Envisager un fichier `.env` ou config centralisée pour éviter ce problème

### Bug 3 : Livreur — Écran noir (AC: #5, #6)

- [ ] **Task 3.1** : Diagnostiquer la cause de l'écran noir (AC: #5)
  - Causes probables (par ordre de priorité) :
    1. **Firebase.initializeApp() bloque** : si `google-services.json` est absent ou invalide, `Firebase.initializeApp()` peut throw mais le catch ne couvre pas tous les cas
    2. **MainActivity.kt modifiée** : le fichier est dans `git status` comme modifié (ajout deep link handling) — vérifier qu'il compile et s'exécute correctement
    3. **DeepLinkHandler.instance.initialize()** : le `await` sur cette ligne pourrait bloquer si le MethodChannel ne répond pas avant que FlutterEngine soit prêt
    4. **driverAvailabilityProvider bloque le rendering** : si l'API est injoignable et le provider reste en `loading`, le UI peut ne jamais se dessiner

  - [ ] Vérifier que `Firebase.initializeApp()` est bien dans un try-catch complet qui n'empêche jamais l'app de démarrer
  - [ ] Vérifier que `DeepLinkHandler.instance.initialize()` a un timeout ou ne bloque pas indéfiniment
  - [ ] Vérifier que le `MainActivity.kt` modifié compile et s'exécute sans crash natif

- [ ] **Task 3.2** : Rendre l'initialisation robuste (AC: #6)
  - [ ] S'assurer que chaque étape d'initialisation dans `main()` est wrappée dans un try-catch individuel
  - [ ] Ajouter un timeout à `DeepLinkHandler.instance.initialize()` (max 3s)
  - [ ] Vérifier que `HomeScreen` gère les états `loading` et `error` des providers `driverAvailabilityProvider` et `fcmTokenProvider` sans bloquer le rendu

### Transversal (AC: #7)

- [ ] **Task 4.1** : Vérifier que DEV_MODE est correctement propagé
  - [ ] Confirmer que `docker-compose.yml` passe `DEV_MODE=true` au container API
  - [ ] Tester manuellement le flux OTP `123456` sur les 3 apps

## Dev Notes

### Analyse de la cause racine

#### Bug 1 — B2B Session
**Fichier clé** : `packages/mefali_api_client/lib/providers/auth_provider.dart` (lignes 160-178)

`loadFromStorage()` ne restaure que `accessToken` et `refreshToken`. L'objet `User` n'est jamais persisté ni rechargé. Conséquence : après redémarrage, `authState.user == null` mais `isAuthenticated == true`, donc le router redirige vers `/home` mais avec des données vides.

**Solution recommandée** : Ajouter un appel API `GET /users/me` dans `loadFromStorage()` après restauration des tokens. Alternative : persister le `User` dans SecureStorage et le restaurer au démarrage.

#### Bug 2 — B2C OTP
**Fichier clé** : `apps/mefali_b2c/lib/features/auth/name_screen.dart` (lignes 38-66)

Le flux B2C est : PhoneScreen → OtpScreen → NameScreen → verifyOtp(). L'erreur se produit probablement lors de l'appel `verifyOtp()` dans NameScreen. Le message d'erreur actuel est `"Erreur: $error"` ce qui affiche le toString() de l'exception Dio — souvent peu lisible.

**Cause probable** : `API_BASE_URL` par défaut est `http://10.0.2.2:8090/api/v1` (emulateur Android seulement). Sur un appareil physique, cette adresse est injoignable → DioException timeout.

**Fichier URL** : `packages/mefali_api_client/lib/dio_client/dio_client.dart` (lignes 7-10)

#### Bug 3 — Livreur écran noir
**Fichier clé** : `apps/mefali_livreur/lib/main.dart` (lignes 14-34)

Le `main()` fait `await Firebase.initializeApp()` dans un try-catch, mais `PushNotificationHandler.instance.initialize()` est dans le MÊME try-catch. Si Firebase réussit mais le handler FCM échoue, l'erreur est silencieuse mais peut laisser l'app dans un état instable.

De plus, `await DeepLinkHandler.instance.initialize()` (ligne 26) est HORS du try-catch et bloque le démarrage. Si le MethodChannel ne répond pas (ex: la partie native n'est pas configurée correctement), l'app reste bloquée.

**Fichier natif modifié** : `apps/mefali_livreur/android/app/src/main/kotlin/com/mefali/mefali_livreur/MainActivity.kt` — récemment modifié pour le deep link handling, visible dans `git status`.

### Project Structure Notes

- **Auth provider partagé** : `packages/mefali_api_client/lib/providers/auth_provider.dart` est utilisé par les 3 apps. Toute modification impacte B2B, B2C et Livreur
- **Dio client partagé** : `packages/mefali_api_client/lib/dio_client/dio_client.dart` contient l'URL API par défaut
- **Conventions existantes** : Riverpod NotifierProvider pour l'état, GoRouter pour la navigation, FlutterSecureStorage pour les tokens

### Fichiers à modifier (estimation)

| Fichier | Modification |
|---------|-------------|
| `packages/mefali_api_client/lib/providers/auth_provider.dart` | Ajouter chargement du User après restauration tokens |
| `packages/mefali_api_client/lib/endpoints/auth_endpoint.dart` | Ajouter endpoint `getMe()` si absent |
| `apps/mefali_b2c/lib/features/auth/name_screen.dart` | Améliorer messages d'erreur |
| `apps/mefali_livreur/lib/main.dart` | Wrapper DeepLinkHandler dans try-catch, robustifier init |
| `apps/mefali_livreur/android/...MainActivity.kt` | Vérifier/corriger le deep link natif |

### Contraintes

- **Ne PAS casser les 3 autres apps** en modifiant le auth_provider partagé
- **FlutterSecureStorage** fonctionne différemment sur appareils Tecno/Infinix (Android Go) — tester sur ces appareils si possible
- **DEV_MODE** est server-side seulement — pas de changement côté Flutter pour le code OTP

### References

- [Source: packages/mefali_api_client/lib/providers/auth_provider.dart — loadFromStorage()]
- [Source: packages/mefali_api_client/lib/dio_client/dio_client.dart — API_BASE_URL]
- [Source: apps/mefali_livreur/lib/main.dart — Firebase + DeepLink init]
- [Source: apps/mefali_b2c/lib/features/auth/name_screen.dart — verifyOtp error handling]
- [Source: server/crates/domain/src/users/otp_service.rs — DEV_OTP_CODE "123456"]
- [Source: server/crates/common/src/config.rs — dev_mode config]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Screenshot de l'erreur B2C non disponible au moment de la création — à demander au testeur pour confirmer le diagnostic
- Le bug livreur pourrait aussi être lié à un problème Gradle/compilation natif (MainActivity.kt modifié) — vérifier les logs `adb logcat` au démarrage

### File List

- `packages/mefali_api_client/lib/providers/auth_provider.dart`
- `packages/mefali_api_client/lib/dio_client/dio_client.dart`
- `packages/mefali_api_client/lib/endpoints/auth_endpoint.dart`
- `apps/mefali_b2c/lib/features/auth/name_screen.dart`
- `apps/mefali_b2c/lib/features/auth/otp_screen.dart`
- `apps/mefali_livreur/lib/main.dart`
- `apps/mefali_livreur/lib/app.dart`
- `apps/mefali_livreur/lib/features/home/home_screen.dart`
- `apps/mefali_livreur/android/app/src/main/kotlin/com/mefali/mefali_livreur/MainActivity.kt`
- `server/crates/domain/src/users/otp_service.rs`
- `server/crates/common/src/config.rs`
