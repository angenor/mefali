# Quickstart — Prestataires agréés et catalogue vendeur (cycle 005)

Guide de VALIDATION : prouver de bout en bout que le cycle tient ses Success
Criteria. Les détails de modèle sont dans [data-model.md](data-model.md), le
contrat dans [contracts/prestataires-api.yaml](contracts/prestataires-api.yaml),
les décisions dans [research.md](research.md).

## 1. Prérequis

```bash
# Services (Postgres 5433, Redis, Garage, OSRM)
docker compose -f infra/docker-compose.yml up -d

# Backend — depuis backend/
export DATABASE_URL=postgres://mefali:mefali@localhost:5433/mefali
cargo sqlx migrate run            # applique 0004_prestataires.sql
cargo run -p api --bin seed       # seeds 10/20/30/35 — rejouables
cargo run -p api --bin api        # .env : PLAQUE_SECRET requis (nouveau, research R2)
```

Variables `.env` nouvelles ce cycle : `PLAQUE_SECRET` (HMAC du jeton de plaque).
S3 : mêmes réglages que le cycle 003 (`S3_ENDPOINT` avec l'IP LAN si un appareil
physique doit lire les photos).

## 2. Vérification automatique (l'essentiel)

```bash
cd backend
cargo test -p prestataires        # domaine : transitions, état effectif, fenêtre, prix
cargo test -p api                 # HTTP : gardes, neutralité, consultation, seeds
cargo test && cargo sqlx prepare  # tout vert + cache sqlx à jour (porte d'avant-commit)
./scripts/generate-clients.sh && git diff --exit-code clients/  # clients régénérés sans diff

cd apps/mefali_pro && dart analyze && flutter test   # V1/V2 (JAMAIS flutter analyze)
cd apps/packages/mefali_core && dart analyze && flutter test    # formaterMontant
```

Couverture attendue par fichier de test d'intégration (backend) :

| Fichier | Scénarios prouvés |
|---|---|
| `crates/prestataires/tests/agrement.rs` | SC-001, SC-010 — agrément complet sans compte, refus si incomplet (motif explicite), plaque créée, activation recalculée, rattachement idempotent (FR-007), correction FR-056 (2 recalculs, 1 transaction) |
| `crates/prestataires/tests/suspension.rs` | SC-002, SC-003 — suspension coupe fiche/commandable/jeton/actions vendeur SANS action distincte ; rétablissement à l'identique (jeton + code inchangés) |
| `crates/prestataires/tests/catalogue.rs` | SC-005, SC-006 — prix barré ≤ prix refusé (API et CHECK), montants entiers + devise, `figer_prix` puis modification → montant figé invariant, retrait/remise réversibles |
| `crates/prestataires/tests/boutique.rs` | SC-004, SC-007 — matrice état effectif (horaires × statut × pause × échéance), réouverture auto SANS événement, pause échue hors horaires ne rouvre pas, « fermé pour la journée » cesse au prochain jour d'ouverture, rappel FR-035 |
| `crates/prestataires/tests/ruptures.rs` | SC-008 — 3 sources tracées, précondition coursier (port fake éligible/inéligible), rejeu idempotent, 2 coursiers distincts / 7 j → masquage auto, levée vendeur, re-masquage immédiat, verrou admin (FR-041), sortie de fenêtre (SQL brut sur `recu_le`) |
| `api/src/…_http.rs` (tests intégrés) | SC-013 — consultation publique sans contact/GPS sur TOUS les états, 404 neutre (suspendu = inconnu), gardes 401/403 des trois refus vendeur, grisé vs masqué selon config |
| `api/src/lib.rs` (seeds) | SC-012 — double exécution identique, zéro événement, prestataires seedés commandables |
| SC-009, SC-011 | transversal : chaque test de transition vérifie SON événement (auteur, source, horodatage) et l'absence de nom/GPS dans le payload |

## 3. Parcours manuel de validation (curl)

Jetons : `ADMIN_JWT` et `VENDEUR_JWT` obtenus par le parcours OTP du cycle 003
(`/dev/otp` en dev). Les seeds fournissent Tantie Affoué (agréée, sans compte),
Kofi (agréé, compte rattaché) et un prospect.

### 3.1 SC-001 — agréer le prospect seedé, sans aucun compte

```bash
API=http://localhost:8080
PROSPECT=<uuid du prospect seedé>

# L'agrément passe (fiche + charte + site sont seedés complets)
curl -s -X POST $API/admin/prestataires/$PROSPECT/agrement -H "Authorization: Bearer $ADMIN_JWT"
# → statut=agree, jeton_plaque et code_secours posés

# Immédiatement consultable et commandable, sans étape supplémentaire
curl -s $API/prestataires/$PROSPECT | jq '{commandable, boutique, articles: (.articles|length)}'
```

### 3.2 SC-002/SC-003 — la suspension coupe tout, le rétablissement rend tout

```bash
P=<uuid Kofi> ; JETON=$(curl -s $API/admin/prestataires/$P -H "Authorization: Bearer $ADMIN_JWT" | jq -r .jeton_plaque)

curl -s -X POST $API/admin/prestataires/$P/suspension \
  -H "Authorization: Bearer $ADMIN_JWT" -H 'Content-Type: application/json' \
  -d '{"motif":"trois incidents graves"}'

curl -s $API/prestataires/$P                        # → 404 prestataire_indisponible (neutre)
curl -s $API/prestataires/plaque/$JETON -H "Authorization: Bearer $ADMIN_JWT"   # → { prestataire_id, valide: false }
curl -s -X POST $API/vendeur/prestataires/$P/boutique/action \
  -H "Authorization: Bearer $VENDEUR_JWT" -H 'Content-Type: application/json' \
  -d '{"action":"ouvrir"}'                         # → 403 prestataire_non_agree (rôle INTACT)

curl -s -X POST $API/admin/prestataires/$P/retablissement -H "Authorization: Bearer $ADMIN_JWT"
curl -s $API/prestataires/plaque/$JETON -H "Authorization: Bearer $ADMIN_JWT"   # → valide: true, MÊME jeton (SC-003)
```

### 3.3 SC-006/SC-007 — prix barré et bascule en un geste

```bash
# Refusé : prix barré ≤ prix (422, l'opération échoue — la promo n'est pas retirée en silence)
curl -s -X POST $API/vendeur/prestataires/$P/articles \
  -H "Authorization: Bearer $VENDEUR_JWT" -H 'Content-Type: application/json' \
  -d '{"nom":"alloco","prix_unites":800,"prix_barre_unites":800}'   # → 422

# Accepté puis bascule rupture en UN geste ; la consultation suivante rend le nouvel état
A=<uuid article>
curl -s -X POST $API/vendeur/prestataires/$P/articles/$A/disponibilite \
  -H "Authorization: Bearer $VENDEUR_JWT" -H 'Content-Type: application/json' \
  -d '{"disponible":false}'
curl -s $API/prestataires/$P | jq '.articles[] | select(.id=="'$A'") | .disponible'   # → false (grisé)
```

### 3.4 SC-008 — masquage automatique (précondition simulée)

La précondition « commande active » passe par le port `CommandesActives` : en
production réelle il répond toujours faux (aucun module commandes) — la
validation du masquage se fait donc par `cargo test -p prestataires
ruptures` (port fake), qui déroule : 2 coursiers distincts → masquage, levée
vendeur, re-masquage au signalement suivant, refus non compté du coursier
inéligible. Le curl direct vérifie seulement le REFUS :

```bash
curl -s -X POST $API/coursier/signalements-rupture \
  -H "Authorization: Bearer $COURSIER_JWT" -H "Idempotency-Key: $(uuidgen)" \
  -H 'Content-Type: application/json' \
  -d '{"article_id":"'$A'","horodatage_local":"2026-07-18T14:00:00Z"}'   # → 403, compté nulle part
```

### 3.5 SC-012 — seeds rejouables

```bash
cargo run -p api --bin seed && cargo run -p api --bin seed   # deux fois
psql "$DATABASE_URL" -c "SELECT count(*) FROM outbox.evenement WHERE entite_type LIKE 'prestataire%' OR entite_type IN ('article','site','charte_signee')"
# → 0 (les seeds n'émettent rien)
```

## 4. Validation des écrans V1/V2 (Mefali Pro, émulateur Android)

```bash
cd apps/mefali_pro
flutter run --dart-define=MEFALI_API_URL=http://<ip-lan-du-poste>:8080 \
            --dart-define=MEFALI_DEV_OTP=true
```

Se connecter avec le compte Kofi (seed), rôle vendeur → l'interface vendeur
remplace le placeholder :

1. **V1 · Boutique** — puce d'état, interrupteur OUVERT/FERMÉ en un geste,
   pause 30 min/1 h/2 h avec échéance affichée, « +30 min » et « Fermer pour
   aujourd'hui », horaires du jour + édition ; fermer manuellement pendant les
   horaires → rappel non bloquant avec « Ouvrir maintenant » / « Je reste fermé
   aujourd'hui » (qui ne réapparaît plus de la journée).
2. **V2 · Articles** — recherche, compteur « N articles · M en rupture »,
   bascule En stock/Rupture 84×44 en un geste (ligne grisée + bordure danger),
   badge PROMO + prix barré, ajout d'article, retrait + section « Articles
   retirés » repliée, fiche article : steppers de prix, toggle promo avec
   aperçu « Le client verra », enregistrer.
3. **Aperçu client** — l'onglet aperçu de V2 rend la consultation PUBLIQUE
   (même endpoint que C2) : rupture grisée, `+` désactivé.
4. Suspendre Kofi via curl (§3.2) pendant que l'app est ouverte → toute action
   vendeur rend le refus i18n « prestataire non agréé » ; rétablir → tout
   revient sans reconnexion.

## 5. Portes d'avant-commit (rappel)

1. `cargo test` + `cargo sqlx prepare` verts ; `./scripts/generate-clients.sh`
   sans diff ; `dart analyze` + `flutter test` verts dans les deux packages.
2. `docs/taxonomie-evenements.md` : les 18 événements outbox + la sous-section
   MET-01 déclarés AVANT l'implémentation (FR-051, FR-053).
3. Messages conventionnels : `feat(prestataires): VND-01 …`.
