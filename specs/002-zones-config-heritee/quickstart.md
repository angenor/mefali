# Quickstart — Validation du cycle 002 (zones & configuration héritée)

Guide de validation de bout en bout. Références : [spec.md](spec.md),
[data-model.md](data-model.md), [contracts/openapi-zones.yaml](contracts/openapi-zones.yaml).

## Prérequis

- Environnement dev démarré : `docker compose -f infra/docker-compose.yml up -d`
- `.env` backend renseigné (voir `infra/.env.example`) + `ADMIN_API_TOKEN`
  (garde temporaire du forçage — research R5)

## 1. Backend : migrations, seeds, tests

```bash
cd backend
cargo sqlx migrate run              # applique 0002_zones.sql
cargo run -p api --bin seed         # charge backend/seeds/ (dont 10_zones_tiassale.sql)
cargo test -p zones                 # résolution exhaustive, activation, anti-cycle
cargo test -p api                   # endpoints /config + forçage
cargo sqlx prepare --workspace      # OBLIGATOIRE après tout changement SQL
```

**Attendu** : tests verts, y compris la matrice de surcharge (SC-001), le
paramètre fictif de bout en bout (SC-006) et le double seed sans doublon
(SC-008 — re-lancer `cargo run -p api --bin seed` puis vérifier l'état).

## 2. `/config` public — SC-003 en une consultation

```bash
curl -s 'http://localhost:8080/config?zone=01900000-0000-7000-8000-000000000002' | jq
```

**Attendu** (voir exemple complet dans le contrat) : `devise` XOF/0 (héritée
du pays), `drapeaux` {livraison_offerte_mefali: true, gratuite_commissions:
true, pluie: false}, `transports_actifs` [a_pied, velo, moto], `categories`
= [] (aucun vendeur en base au cycle ZON → rien d'actif), `version` non vide.

Vérifications complémentaires :

```bash
# 404 explicite (FR-021)
curl -si 'http://localhost:8080/config?zone=00000000-0000-7000-8000-00000000dead' | head -1
# 304 sur If-None-Match (polling horaire économe)
V=$(curl -s '…/config?zone=0190…0002' | jq -r .version)
curl -si -H "If-None-Match: $V" '…/config?zone=0190…0002' | head -1
```

## 3. Héritage & version — SC-004

```sql
-- via psql : surcharger un texte au niveau pays puis relire la ville
INSERT INTO zones.parametre_zone (zone_id, cle, valeur)
VALUES ('01900000-0000-7000-8000-000000000001', 'texte.bandeau', '"Bienvenue"');
```

**Attendu** : la config de Tiassalé contient `textes.bandeau` ET sa
`version` a changé (empreinte — research R3).

## 4. Forçage de catégorie — SC-005

```bash
curl -si -X PUT -H "X-Admin-Token: $ADMIN_API_TOKEN" -H 'Content-Type: application/json' \
  -d '{"forcage":"force_actif"}' \
  'http://localhost:8080/admin/zones/01900000-0000-7000-8000-000000000002/categories/marche/forcage'
```

**Attendu** : `200 {…, forcage: force_actif, actif: true}` ; `marche`
apparaît désormais dans `categories` de `/config` (mixable: true, hérité du
pays) ; sans jeton → `401` ; événements `categorie.forcage_change` +
`categorie.activation_changee` présents dans `outbox.evenement` (même
transaction) :

```sql
SELECT type_evenement, payload FROM outbox.evenement ORDER BY cree_le DESC LIMIT 2;
```

## 5. Contrat & clients — dérive interdite

```bash
./scripts/generate-clients.sh && git status --porcelain openapi.json clients/
```

**Attendu** : régénération sans diff après commit (la CI contrat-clients
échoue sinon).

## 6. Apps Flutter — cache & rafraîchissement (FR-020, SC-007)

```bash
cd apps/packages/mefali_core && flutter test   # cache, refresh horaire (fake_async), hors-ligne
cd ../../mefali_client && flutter test && cd ../mefali_pro && flutter test
```

**Attendu** : démarrage hors-ligne servi par le cache (`shared_preferences`),
rafraîchissement au démarrage + horaire, zone de bootstrap =
`01900000-0000-7000-8000-000000000002` (constante Tiassalé — research R7).

## 7. Avant commit (constitution, workflow)

`cargo test` + `cargo sqlx prepare` verts ; clients régénérés sans diff ;
`docs/taxonomie-evenements.md` enrichi des 3 événements (research R9) ;
message conventionnel `feat(zones): ZON-0x …`.
