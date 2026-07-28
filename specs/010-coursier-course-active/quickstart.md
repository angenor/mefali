# Quickstart — valider le cycle CRS 010 (app coursier)

Comment prouver que le cycle fait ce qu'il annonce. Deux niveaux : **automatisé**
(ce que la CI exécute) et **sur appareil** (ce qu'aucun test ne peut voir — une
sonnerie, un écran en plein soleil, un réseau qui tombe pour de vrai).

---

## 1. Prérequis

```bash
docker compose -f infra/docker-compose.yml up -d      # Postgres 5433, Redis, Garage, OSRM
cd backend && cargo sqlx migrate run                  # jusqu'à 0016
psql "$DATABASE_URL" -f seeds/80_coursier_parametres.sql
cargo sqlx prepare                                    # obligatoire après 0015/0016
```

L'app coursier sur appareil ou émulateur a besoin de l'IP du poste, jamais de
`localhost` :

```bash
cd apps/mefali_pro
flutter run \
  --dart-define=MEFALI_API_URL=http://<ip-lan>:8080 \
  --dart-define=MEFALI_DEV_OTP=true
# ⚠ S3_ENDPOINT côté API doit pointer sur la MÊME ip, sinon la note vocale de
#   repère ne se joue pas (URL présignée injoignable) — piège du cycle 006.
```

---

## 2. Validation automatisée

```bash
cd backend
cargo test -p coursier                    # domaine : preuves, caisse, présence
cargo test --test coursier_course_active  # pré-provisionnement complet
cargo test --test coursier_reconciliation # ⭐ le test obligatoire du module
cargo test --test coursier_preuves
cargo test --test coursier_caisse
cargo test --test coursier_remise_hors_ligne
cargo test --test admin_coursier
cargo test                                # non-régression 006/007/008/009

cd ../apps/mefali_pro && flutter test && dart analyze
cd ../packages/mefali_core && flutter test && dart analyze
cd ../../.. && ./scripts/verifier-accord-locks.sh
./scripts/generate-clients.sh && git diff --exit-code clients/   # doit être vide
```

### 2.1 Le test qui fait foi — `coursier_reconciliation.rs` (FR-089, SC-004)

Le scénario, dans l'ordre exact :

1. Créer une commande cash de 3 arrêts, l'affecter à un coursier.
2. Collecter les arrêts 1 et 2 **en ligne**.
3. **Couper le réseau** (le test n'appelle plus l'API ; l'app simulée enfile).
4. Scanner l'arrêt 3, puis confirmer la remise par code, hors ligne.
5. **Rétablir** : rejouer la file dans l'ordre.
6. Assertions : `arret.collecte` compté **une** fois pour l'arrêt 3 · remise
   enregistrée **une** fois · `livraison.livree` émis **une** fois · commande
   `terminee` · caisse : 3 avances puis 1 remboursement, solde à 0.
7. Rejouer la file **une seconde fois** : aucun nouvel événement, aucune nouvelle
   écriture de caisse.

### 2.2 Couverture attendue par story

| Story | Tests |
|---|---|
| US1 checklist | `coursier_course_active` (lignes par arrêt, montant révisé après indisponibilité) + widget K3 |
| US2 remise | `coursier_remise_hors_ligne` (3 voies, essais, blocage à 3, levée admin, dépôt refusé si fermé) + widget K4 |
| US3 file | `coursier_reconciliation` (§2.1) + réassignation pendant la coupure → refus tracé |
| US4 preuves | `coursier_preuves` : les 7 combinaisons de preuves manquantes, l'espacement < 3 min refusé, le « trou » de présence, le refus serveur |
| US5 caisse | `coursier_caisse` (avance → remboursement → solde 0 ; prépayée → avance ouverte) + `admin_coursier` (exposition, validation) |
| US6 gains | `coursier_caisse::journee` (somme des parts coursier, bascule de jour civil) |
| US7 offre | widget + validation appareil §3.4 |

---

## 3. Validation sur appareil — ce qu'aucun test ne voit

### 3.1 La course active en conditions réelles (US1, SC-001, SC-002)

Assigner une course de 3 vendeurs et 8 articles. Vérifier, **en plein soleil** :
lisibilité des montants, arrêt courant seul développé, coche d'un article,
« Indisponible » sur une ligne → montant qui baisse **immédiatement**, scan,
repli automatique et passage à l'arrêt suivant.

### 3.2 La note vocale hors ligne (SC-012)

Assigner une course dont le client a un repère **vocal**. Attendre 30 secondes,
**activer le mode avion**, ouvrir l'écran « en route vers le client », jouer la
note : elle doit se jouer. Si elle ne se joue pas, vérifier `S3_ENDPOINT` (§1).

### 3.3 Le hors-ligne complet (US2, US3, SC-003, SC-017)

Mode avion **avant** le dernier scan. Scanner, arriver, confirmer par code.
Vérifier : bandeau « validation locale — sera synchronisée », passage à « course
terminée » en moins de 2 s, compteur d'actions en attente. Rétablir le réseau :
la file se vide en moins de 5 s, et la commande est `terminee` côté serveur.
Recommencer avec un **code faux** ×3 : blocage, numéro d'agence affiché, scan QR
toujours actif ; au retour du réseau, l'alerte est visible sur
`GET /admin/remises/bloquees`.

### 3.4 Le réveil, écran éteint (US7, SC-014, SC-018)

Se mettre en ligne, **verrouiller** le téléphone, le poser 30 minutes. Vérifier
sur `GET /admin/dispatch/pool` qu'il n'est jamais sorti du pool. Émettre une
offre : la sonnerie doit retentir (canal dédié, son prolongé), la notification
ouvrir l'écran d'offre, et le compte à rebours afficher le temps **réellement
restant**. Se mettre hors ligne : la notification permanente disparaît, plus
aucune position n'est publiée.

### 3.5 Les preuves d'échec (US4, SC-007, SC-019)

Arriver chez un client qui ne répond pas. Vérifier que le bouton est **inactif**,
passer 2 appels espacés de moins de 3 min (la preuve reste rouge et **dit
pourquoi**), attendre l'espacement, laisser tourner 10 minutes **écran éteint**,
prendre la photo. Le bouton s'active exactement quand la 3ᵉ preuve tombe.
Déclarer : l'issue part avec ses preuves, et l'indemnisation apparaît en caisse.

### 3.6 La caisse (US5, SC-009)

Pendant une course à 2 arrêts collectés : « argent avancé en cours » doit égaler
la somme des deux montants, au franc près. Après encaissement : retour à 0 et
apparition dans l'historique avec les trois chiffres (avancé / remboursé / gain).

---

## 4. Points de vigilance appris des cycles précédents

| Piège | D'où il vient | Comment l'éviter |
|---|---|---|
| Note vocale muette sur appareil | cycle 006 | `S3_ENDPOINT` = IP LAN, pas `localhost` |
| `.g.dart` périmés dans le dépôt | cycle 009 | `build_runner` **avant** de commiter, `dart analyze` dans les 3 paquets |
| Tempête d'événements de connectivité | cycle 006 | le flux réseau reste `.distinct()` — ne pas le retirer en refondant K3 |
| Doubles de test qui « mentent » | cycle 009 | `PreuvesFixes` ne doit plus être câblé en production : la composition utilise `PgCoursier` |
| Horloge serveur vs appareil | cycle 005 | tout ce qui fonde de l'argent (présence, arrivée, remise) est horodaté **serveur** |
| Lockfiles désaccordés | cycle 009 | `./scripts/verifier-accord-locks.sh` après l'ajout des 2 plugins |

---

## 5. Definition of Done du cycle

- [ ] `cargo test` vert, `cargo sqlx prepare` à jour, clients régénérés sans diff
- [ ] `flutter test` + `dart analyze` verts dans `mefali_pro` et `mefali_core`
- [ ] Les 7 événements déclarés dans `docs/taxonomie-evenements.md` **avant** le code
- [ ] `PreuvesFixes` n'est plus câblé dans `backend/api` (production)
- [ ] Validation sur appareil §3.1 à §3.6 effectuée et consignée
- [ ] Écarts de maquette consignés dans un `rapport-ecarts.md` (paie fixe K1-1c,
      lien mobile money K4-1a, signaler/bloquer K5-1a/1d)
