# CLAUDE.md — Mefali (monorepo)

Plateforme de services de proximité (Côte d'Ivoire, puis toute l'afrique plus tard). Premier vertical MVP :
livraison restauration + courses chez vendeurs agréés, à Tiassalé.
Développeur solo. Langue du projet : français (code en anglais, textes
utilisateur en clés i18n fr).

## Sources de vérité (les consulter, ne jamais les contredire)

- Produit : `docs/cadrage-v5.md` et `docs/user-stories-v2.md` — les priorités
  P0/P1/P2/PROVISION et le « Récapitulatif des paramètres de zone » font foi.
- Principes : `.specify/memory/constitution.md` (créée via /speckit.constitution).
- Design : `docs/design/png/` (cible visuelle), `docs/design/tokens.md`
  (valeurs exactes), `docs/design/html/` (mesures uniquement).
- API : `openapi.json` généré par utoipa — les clients `clients/dart` et
  `clients/ts` sont GÉNÉRÉS. NE JAMAIS les éditer à la main.
- Schéma : migrations sqlx dans `backend/migrations/`. NE JAMAIS modifier une
  migration déjà appliquée — en créer une nouvelle.
- Événements : `docs/taxonomie-evenements.md`.

## Structure du monorepo

- `backend/` — workspace Rust (Actix). `backend/crates/` : zones, comptes,
  prestataires, qr, tarification, commandes, dispatch, coursier, paiements,
  notifications, avis, metriques. `backend/api/` : binaire qui assemble tout.
- `apps/mefali_client/`, `apps/mefali_pro/` — Flutter.
  `apps/packages/mefali_core/` — thème M3 + composants partagés.
- `web/` — Nuxt 4 (public SSR, `/admin/**` en ssr:false).
- `infra/` — docker-compose dev (Postgres, Redis, Garage, OSRM), VPS, backups.
- `specs/` — cycles Spec-Kit.

## Commandes (précisées/complétées au cycle TRX — les maintenir ici)

- Environnement dev : `docker compose -f infra/docker-compose.yml up -d`
- Backend : `cargo build` / `cargo test` / `cargo sqlx migrate run` /
  `cargo sqlx prepare` (obligatoire après tout changement SQL)
- Contrat + clients : script de génération openapi.json → clients Dart/TS
  (défini au cycle TRX ; la CI échoue sur un diff de client non commité)
- Apps : `flutter test` / `flutter run` dans chaque app. Sur appareil ou
  émulateur, passer l'URL de l'API — le défaut `localhost` désigne l'appareil
  lui-même, pas le poste :
  `flutter run --dart-define=MEFALI_API_URL=http://<ip-lan-du-poste>:8080`
  Ajouter `--dart-define=MEFALI_DEV_OTP=true` pour lire le code OTP sur l'écran
  de saisie (`SMS_MODE=traces` + `APP_ENV=dev` ; surface absente en production).
  Ajouter `--dart-define=MEFALI_DEV_ADRESSE=true` (client) pour ouvrir l'atelier
  DEV du repère vocal depuis l'accueil provisoire : il déroule micro + permission
  + enregistrement + réécoute + envoi RÉEL (`POST /moi/adresses`) sur un pin GPS
  bouchon, avant que le cycle CMD ne fournisse le vrai déclencheur post-livraison.
  Gaté comme `/dev/otp` (constante de compilation, éliminée en release).
  ⚠ L'API doit signer ses URLs présignées avec la MÊME ip que l'appareil peut
  joindre : `S3_ENDPOINT=http://<ip-lan-du-poste>:3900`, sinon les repères
  vocaux ne se lisent pas. iOS n'est pas vérifié (Xcode/CocoaPods à installer).
- Web : `pnpm dev` / `pnpm build` dans `web/`

## Règles impératives (elles changent le comportement — les respecter toutes)

- IMPORTANT : le tronc `commande` ne contient AUCUN champ logistique ; la
  `livraison` est un composant optionnel (0..n). Tout prestataire n'est pas un
  vendeur — le vendeur est la spécialisation MVP du prestataire.
- IMPORTANT : montants = entiers en unités mineures + code ISO 4217. Jamais de
  float pour l'argent. Jamais de chemin de paiement partiel.
- Tout paramètre métier « paramétrable » → configuration de zone (héritage),
  jamais en dur. Toute chaîne utilisateur → clé i18n fr, jamais en dur.
- Distances par itinéraire routier (OSRM, waypoints) — jamais de vol d'oiseau
  hors dégradé ×1,4 journalisé.
- Actions coursier : UUID client + rejeu idempotent (file hors-ligne).
- Toute transition d'état écrit un événement outbox dans la même transaction.
- UI Flutter : widgets Material 3 thémés via `mefali_core` depuis
  `docs/design/tokens.md` — ne JAMAIS transposer la structure DOM/CSS des
  exports `docs/design/html/` (exception : l'admin Nuxt peut s'en inspirer).
  Une seule identité Android/iOS : constructeurs `.adaptive`, pas de Cupertino.
- État des apps Flutter : **Riverpod codegen** (constitution XII). Tout porteur
  d'état est un provider GÉNÉRÉ par annotation (`.g.dart` commité, jamais édité) ;
  injection par la PORTÉE, jamais par constructeur ni conteneur global ; l'état
  strictement local reste local ; `retry: pasDeRetry` sur toute portée ; durée de
  vie EXPLICITE (`@Riverpod(keepAlive: true)` vs `@riverpod` nu) ; DEUX MOULES —
  `Notifier<Etat…>` (session, rôles) / `AsyncNotifier` (listes), jamais
  `AsyncValue` uniforme. Analyse par `dart analyze` (JAMAIS `flutter analyze`).
- « Prêt ≠ construit » : les PROVISIONS sont des tables/enums seulement —
  aucune UI, aucune logique.

## Avant chaque commit

1. `cargo test` + `cargo sqlx prepare` verts ; clients régénérés sans diff.
2. Message conventionnel référençant la story : `feat(dispatch): DSP-04 …`.
3. Rien construit hors du périmètre du cycle en cours (voir `specs/`).

## Si une décision produit change

Mettre à jour d'abord `docs/` (cadrage, user stories, design), puis relancer le
`/speckit.specify` du module concerné — jamais l'inverse.
