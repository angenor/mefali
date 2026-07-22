# Migrations sqlx (backend/migrations/)

Une migration par changement de schéma, jamais de modification d'une migration
déjà appliquée (constitution I). Format `NNNN_description.sql`.

Historique :

- `0001_outbox.sql` — journal outbox (cycle 001, T017).
- `0002_zones.sql` — arbre de zones, configuration héritée, catégories, types de
  transport, activation par ville (cycle 002, T002 ; data-model.md §1–2).
- `0003_comptes.sql` — schéma `comptes` : comptes (numéro E.164 vérifié +
  consentement ARTCI), sessions par appareil, attributions de rôle (l'unique
  machine à états), dossier coursier, véhicules déclarés, adresses avec repère
  vocal (cycle 003, T002 ; specs/003-comptes-otp-roles/data-model.md §1–2).
- `0004_prestataires.sql` — schéma `prestataires` : prestataire (fiche, cycle
  de vie, identité de plaque), photos, chartes signées, sites + horaires
  (multi-sites en provision VND-06), rattachements compte ↔ prestataire,
  extension vendeur + articles (CHECK prix barré > prix), disponibilité par
  site, signalements de rupture (idempotence par UUID client), prix figés,
  plans en provision VND-07 (cycle 005, T004 ;
  specs/005-prestataires-catalogue-vendeur/data-model.md §2–3).

⚠ Les migrations sont EMBARQUÉES dans le binaire (`sqlx::migrate!` dans
`api::run`) : après l'ajout d'un fichier ici, reconstruire
`cargo build -p api --bin api`, sinon le binaire déjà compilé applique
l'ancienne liste.
