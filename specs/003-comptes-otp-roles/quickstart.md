# Quickstart — validation du cycle 003 (comptes, OTP, rôles)

Guide de validation de bout en bout : chaque section prouve un critère de
succès de la spec (SC-001 → SC-008). Références : [data-model.md](data-model.md)
(schéma, machines à états), [contracts/openapi-comptes.yaml](contracts/openapi-comptes.yaml)
(formes exactes des requêtes/réponses), [research.md](research.md) (décisions).

## Prérequis

```bash
# 1. Infra dev — Postgres, Redis (première utilisation réelle ce cycle),
#    Garage (init buckets/clé via infra/garage/init.sh), OSRM (non utilisé ici)
docker compose -f infra/docker-compose.yml up -d

# 2. Variables d'environnement (infra/.env.example mis à jour ce cycle)
#    ⚠ dev local de ce dépôt : Postgres dédié sur le port 5433
export DATABASE_URL='postgres://mefali:mefali@localhost:5433/mefali'
export JWT_SECRET='<32+ octets aléatoires>'   # nouveau ce cycle
export SMS_MODE=traces                        # les OTP partent dans les logs (R6)
# S3_ENDPOINT/S3_ACCESS_KEY/S3_SECRET_KEY/S3_BUCKET — comme .env.example
# ADMIN_API_TOKEN n'existe PLUS (remplacé par JWT + rôle admin, R5)

# 3. Backend — ⚠ les migrations sont EMBARQUÉES à la compilation :
#    reconstruire le binaire après l'ajout de 0003_comptes.sql
cd backend && cargo build -p api --bin api && cargo sqlx migrate run
cargo sqlx prepare --workspace          # obligatoire après tout SQL
cargo run -p api --bin seed             # seeds rejouables (dont 20_comptes.sql)

# 4. Clients régénérés (jamais édités à la main)
export JAVA_HOME=/opt/homebrew/opt/openjdk && export PATH="$JAVA_HOME/bin:$PATH"
./scripts/generate-clients.sh           # openapi.json → clients/dart + clients/ts

# 5. Lancer l'API
cargo run -p api --bin api              # http://localhost:8080
```

Suite de tests complète (toutes les transitions des machines à états, garde-fous
OTP, neutralité, seeds ×2) :

```bash
cd backend && cargo test                # inclut #[sqlx::test] sur ../migrations
cd apps/packages/mefali_core && flutter test
cd apps/mefali_client && flutter test && cd ../mefali_pro && flutter test
```

## SC-001 — Inscription complète < 2 minutes

```bash
ZONE='01900000-0000-7000-8000-000000000002'   # Tiassalé (seed)

# 1. Demande d'OTP — saisie LOCALE sans indicatif : normalisation +225 (R4)
curl -s -X POST localhost:8080/auth/otp/demander \
  -H 'content-type: application/json' \
  -d "{\"telephone\":\"0701020304\",\"zone\":\"$ZONE\"}"
# → 202 {"message_cle":"comptes.otp.envoye_si_valide"}
# SMS_MODE=traces : le code apparaît dans les logs de l'API

# 2. Vérification — numéro inconnu → consentement requis (flux unique)
curl -s -X POST localhost:8080/auth/otp/verifier \
  -H 'content-type: application/json' \
  -d "{\"telephone\":\"0701020304\",\"zone\":\"$ZONE\",\"code\":\"<code>\",
       \"appareil\":{\"nom\":\"Pixel de test\",\"plateforme\":\"android\"}}"
# → 200 {"resultat":"consentement_requis","jeton_inscription":"…"}

# 3. Inscription — consentement ARTCI obligatoire (FR-006)
curl -s -X POST localhost:8080/auth/inscription \
  -H 'content-type: application/json' \
  -d '{"jeton_inscription":"<jeton>","consentement_version":"<version config zone>"}'
# → 201 {"resultat":"session","jetons":{…},"compte":{…}}  — compte réduit au numéro
```

Attendu : parcours complet en < 2 min ; le compte créé porte
`consentement_version` + horodatage (SC-008) ; événements `compte.cree` et
`session.creee` dans `outbox.evenement`.

## SC-002 — Garde-fous OTP (expiration, essais, plafond SMS)

Couvert par les tests d'intégration (impl `MemoireEphemere` à horloge
injectable — R3) : code > 5 min → 401 neutre ; 4ᵉ saisie → code invalidé ;
4ᵉ demande de SMS dans l'heure → AUCUN envoi mais 202 identique ; nouvelle
demande → l'ancien code ne passe plus. Vérification manuelle rapide : demander
2 codes de suite et constater que seul le second fonctionne.

## SC-003 — Neutralité anti-énumération

```bash
# Même corps, numéro INSCRIT vs numéro INCONNU : réponses de /auth/otp/demander
# et des échecs de /auth/otp/verifier strictement identiques (statut, corps).
diff <(curl -s -X POST …/auth/otp/demander -d '{"telephone":"<inscrit>",…}') \
     <(curl -s -X POST …/auth/otp/demander -d '{"telephone":"<inconnu>",…}')
# → aucune différence
```

Le test d'intégration `neutralite_otp` compare les octets des réponses pour
toutes les issues d'échec (code faux, expiré, plafond atteint).

## SC-004 — Déconnexion à distance ≤ 15 minutes

```bash
# Deux sessions (appareils A et B) sur le même compte, puis depuis A :
curl -s localhost:8080/moi/sessions -H "authorization: Bearer $ACCES_A"
curl -s -X DELETE localhost:8080/moi/sessions/$SESSION_B -H "authorization: Bearer $ACCES_A"
# B : /auth/rafraichir → 401 immédiat ; l'accès court de B expire ≤ 15 min.
# A : toujours fonctionnel. Événement session.revoquee émis.
```

Réutiliser un ancien refresh déjà tourné (rotation R2) → 401 + session
entièrement révoquée (test `reutilisation_du_refresh_revoque_la_session`,
`backend/crates/comptes/tests/sessions.rs` ; son pendant HTTP est
`rafraichir_200_puis_ancien_refresh_401`).

## SC-005 — Porte coursier : zéro contournement

```bash
# Yao (compte client) soumet son dossier depuis Mefali Pro :
curl -s -X POST localhost:8080/moi/dossier-coursier -H "authorization: Bearer $ACCES_YAO" \
  -H "idempotency-key: $(uuidgen)" \
  -F piece=@piece.jpg -F referent_nom='K. Abou' -F referent_telephone='0705060708' \
  -F vehicules='moto'
# Rejouer la MÊME requête (même idempotency-key) → 200 état courant, pas de doublon (R14)
# → 201 statut "en_attente" ; role.demande + dossier_coursier.soumis émis

# Un véhicule NON actif à Tiassalé (ex. camion) → 422 vehicule_hors_zone
# La porte (trait Comptes::coursier_autorise_en_ligne) répond false —
# vérifié par tests pour en_attente/refuse/suspendu ; true UNIQUEMENT si valide.
```

Admin (JWT du compte seed) valide, suspend, rétablit — chaque transition de
[data-model §4](data-model.md) testée avec son événement outbox, les
transitions invalides → 409.

```bash
curl -s -X POST localhost:8080/admin/comptes/$YAO/roles/coursier \
  -H "authorization: Bearer $ACCES_ADMIN" -H 'content-type: application/json' \
  -d '{"action":"valider"}'          # → 200 {"role":"coursier","statut":"valide"}
curl -s localhost:8080/admin/comptes/$YAO/dossier-coursier \
  -H "authorization: Bearer $ACCES_ADMIN"   # → piece_url présignée (TTL 10 min)
```

Remplacement d'AdminAuth (R5) : `PUT /admin/zones/…/forcage` répond 200 avec un
JWT admin, 403 avec un JWT sans rôle admin, 401 avec l'ancien `X-Admin-Token`.

## SC-006 — Bascule Mefali Pro sans reconnexion

`flutter run` dans `apps/mefali_pro` : compte avec coursier + vendeur validés
(vendeur attribué par l'admin : `{"action":"attribuer"}` sur
`/admin/comptes/{id}/roles/vendeur`) → le routeur d'accueil propose la bascule
entre les deux interfaces sans repasser par l'OTP (< 5 s). Compte sans rôle pro
validé → écran d'état de la demande. Test widget `bascule_role_sans_reconnexion`.

## SC-007 — Adresse réutilisée en un geste, repère vocal identique

```bash
# Enregistrement (déclencheur « livraison réussie » simulé — assumption spec)
curl -s -X POST localhost:8080/moi/adresses -H "authorization: Bearer $ACCES" \
  -H "idempotency-key: $(uuidgen)" \
  -F libelle='Maison' -F lat=5.898 -F lng=-4.823 -F duree_s=12 -F note_vocale=@repere.m4a
# La clé devient l'id de l'adresse ; rejeu → adresse existante, aucun doublon (R14)
# → 201 ; adresse.enregistree émis
curl -s localhost:8080/moi/adresses/$ID/repere-vocal -H "authorization: Bearer $ACCES"
# → URL présignée : l'audio téléchargé est IDENTIQUE à repere.m4a (octets)
```

Renommer (PATCH) / supprimer (DELETE, soft) ; purge : le test d'intégration
`purge_repere_vocal` recule `derniere_utilisation_le` de 366 jours, exécute le
job (R8) et vérifie `a_repere_vocal=false` + `adresse.repere_vocal_purge` émis
+ objet S3 supprimé (port mémoire) ; l'adresse reste utilisable (FR-022).

Note (analyze S1) : l'écoute côté coursier réutilisera exactement ce mécanisme
de présignée — la capacité (octets identiques) est prouvée ici via la présignée
propriétaire ; l'écran coursier sera validé au cycle CRS.

## SC-008 — Consentement et journalisation à 100 %

- `SELECT count(*) FROM comptes.compte WHERE consentement_le IS NULL` → 0
  (colonnes NOT NULL : garanti par le schéma).
- Toute décision admin porte `decide_par`/`decide_le`/`motif` et son événement
  `role.*` — test `decision_journalisee` (`backend/api/src/comptes_http.rs`)
  recoupe la table et l'outbox. Côté dossier, `cycle_complet_du_dossier_et_de_la_porte`
  (`backend/crates/comptes/tests/dossier.rs`) suit le motif du refus jusqu'à la
  re-soumission qui l'efface.
- Seeds ×2 : `cargo run -p api --bin seed` deux fois → état identique
  (test `seed_comptes_idempotent`, patron du cycle 002).

## Rappels DoD avant commit (§0.4 + CLAUDE.md)

`cargo test` + `cargo sqlx prepare` verts ; `./scripts/generate-clients.sh`
sans diff non commité ; `docs/taxonomie-evenements.md` à jour (les 14
événements AVANT implémentation) ; clés i18n fr externalisées (backend
`message_cle`, apps gen-l10n) ; messages de commit `feat(comptes): CPT-0X …`.
