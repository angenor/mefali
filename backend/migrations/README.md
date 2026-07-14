# Migrations sqlx (backend/migrations/)

Une migration par changement de schéma, jamais de modification d'une migration
déjà appliquée (constitution I). Format `NNNN_description.sql`.

Historique :

- `0001_outbox.sql` — journal outbox (cycle 001, T017).
- `0002_zones.sql` — arbre de zones, configuration héritée, catégories, types de
  transport, activation par ville (cycle 002, T002 ; data-model.md §1–2).
