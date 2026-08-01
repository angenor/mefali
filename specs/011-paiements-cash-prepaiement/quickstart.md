# Quickstart — valider le cycle PAY 011 (paiements)

Comment prouver que le cycle fait ce qu'il annonce. Deux niveaux : **automatisé**
(ce que la CI exécute) et **sur appareil** (ce qu'aucun test ne peut voir — un
navigateur qui s'ouvre, une app tuée pendant le paiement, un réseau qui tombe
entre le webhook et le retour).

L'argent est le seul domaine du produit où « ça a l'air de marcher » ne suffit
pas : chaque scénario ci-dessous se termine par un **contrôle de solde**.

---

## 1. Prérequis

```bash
docker compose -f infra/docker-compose.yml up -d      # Postgres, Redis, Garage, OSRM
# ⚠ Le port publié dépend de l'environnement (compose du dépôt : 5432 ; postes de
#   dev où d'autres bases tournent : 5433/5435). C'est `DATABASE_URL` qui tranche.
cd backend && cargo sqlx migrate run                  # jusqu'à 0021
psql "$DATABASE_URL" -f seeds/90_paiements_parametres.sql
cargo sqlx prepare                                    # obligatoire après 0020/0021
```

Variables d'environnement ajoutées (`backend/.env`) :

```bash
PAIEMENT_FOURNISSEUR=simule          # `agregateur` une fois le prestataire choisi
PAIEMENT_WEBHOOK_SECRET=<≥ 32 octets>  # l'API REFUSE de démarrer sans, en `agregateur`
# PAIEMENT_BASE_URL / PAIEMENT_CLE_API : requis uniquement en `agregateur`
```

App cliente sur appareil ou émulateur — l'IP du poste, jamais `localhost` :

```bash
cd apps/mefali_client
flutter run \
  --dart-define=MEFALI_API_URL=http://<ip-lan>:8080 \
  --dart-define=MEFALI_DEV_OTP=true
```

⚠ **`url_launcher` est un plugin natif** : après son ajout, `flutter run` doit
recompiler la partie native. Un patch Shorebird ne suffira jamais pour cet écran
(research R17) — le vérifier avant de promettre un correctif à chaud.

---

## 2. Validation automatisée

```bash
cd backend
cargo test -p paiements                        # domaine : états, signature, écrêtage
cargo test --test paiements_session            # ouverture idempotente, reprise
cargo test --test paiements_webhook            # ⭐ signature, rejeu, concurrence
cargo test --test paiements_expiration         # réconciliation puis annulation
cargo test --test paiements_hors_delai         # succès tardif → dossier, pas de résurrection
cargo test --test paiements_registre           # rapprochement dans les deux sens
cargo test -p paiements --test fournisseur_alternatif   # ⭐ SC-010
cargo test -p coursier                         # créances, frais encaissés, 3 positions
cargo test --test coursier_positions           # ⭐ la table de vérité de SC-006
cargo test --test commandes_retenue_vendeur    # retenue, mono-vendeur, écrêtage
cargo test                                     # non-régression 006 → 010

cd ../apps/mefali_client && flutter test && dart analyze
cd ../mefali_pro && flutter test && dart analyze
cd ../packages/mefali_core && flutter test && dart analyze
cd ../../.. && ./scripts/verifier-accord-locks.sh
./scripts/generate-clients.sh && git diff --exit-code clients/   # doit être vide
```

Le contrôle qui compte le plus n'est pas la couleur du test, c'est
`cargo test --test coursier_positions` : il parcourt les **dix** états de
[data-model §5](./data-model.md) et échoue à la moindre unité mineure d'écart.

---

## 3. Scénarios de validation

### 3.1 Le parcours nominal — Awa paie d'avance (US1, SC-001, SC-002)

```bash
# 1. Une commande au-dessus du plafond de zone (le seed Tiassalé plafonne à 15 000)
curl -X POST localhost:8080/commandes -H "Authorization: Bearer $AWA" \
     -d '{"id":"…","mode_paiement":"mobile_money", …}'
# → 201, "etat":"en_attente_paiement"

# 2. La session
curl -X POST localhost:8080/commandes/$CMD/paiement -H "Authorization: Bearer $AWA"
# → 200, "acces_paiement":"…", "restant_s":900

# 3. Le fournisseur simulé confirme
curl -X POST localhost:8080/paiements/notifications/simule \
     -H "X-Signature: $(signer succes.json)" --data-binary @succes.json
# → 200 {"traite":true}
```

**Attendu** : la commande est `nouvelle`, `etat_paiement = 'regle'`, la
transaction porte `moyen = 'wave'`, et le dispatch la voit dans la seconde qui
suit (`commande.paiement_confirme` est déjà consommé par `DispatchOutbox` depuis
le cycle 009 — rien à câbler).

**Contrôle** : `POST /commandes/{id}/paiement` rappelé renvoie **la même**
transaction, pas une seconde.

### 3.2 Le rejeu et la fausse notification (US3, SC-003, SC-004)

```bash
for i in $(seq 1 10); do curl -X POST … --data-binary @succes.json; done
# → 1 × {"traite":true}, 9 × {"traite":false,"motif":"rejeu"}

curl -X POST … -H "X-Signature: bidon" --data-binary @succes.json
# → 401
```

**Attendu** : `SELECT count(*) FROM outbox.evenement
WHERE type_evenement = 'paiement.confirme' AND …` vaut **1**. La tentative
refusée laisse une ligne `notification_recue(signature_valide = false)` — et rien
d'autre : ni transaction touchée, ni commande bougée.

### 3.3 L'expiration, et le paiement qui arrive trop tard (US2, SC-005, SC-011)

```bash
# Session ouverte, rien de payé, on porte l'horloge au-delà de l'échéance
psql "$DATABASE_URL" -c "UPDATE paiements.transaction
                            SET expire_le = now() - interval '1 minute'
                          WHERE commande_id = '$CMD'"
# le job passe toutes les 10 s
```

**Attendu** : la transaction est `expiree`, la commande `annulee` **sans frais**,
`paiement.session_expiree` écrit. Puis :

```bash
curl -X POST localhost:8080/paiements/notifications/simule --data-binary @succes.json
```

**Attendu** : la commande **reste annulée** ; la transaction passe
`payee_hors_delai` ; un `paiements.dossier` de type `paiement_hors_delai` est
ouvert ; `paiement.hors_delai` est écrit pour NTF. Aucune résurrection, aucun
argent perdu de vue.

**Variante à ne pas manquer** : refaire le scénario en programmant le fournisseur
simulé pour répondre « réussi » à `consulter`. La commande doit alors être
**confirmée**, pas annulée (FR-027) — c'est le webhook perdu qui ne coûte rien.

### 3.4 La chaîne cash et la retenue (US4, US5, SC-007, SC-009)

```bash
# Le vendeur déclare son offre
curl -X PUT localhost:8080/vendeur/prestataires/$P/offre-livraison \
     -H "Authorization: Bearer $VENDEUR" -d '{"offre":"toujours"}'
# Drapeau de zone au repos, sinon il PRIME (VND-08)
psql "$DATABASE_URL" -c "UPDATE zones.parametre_zone SET valeur='false'::jsonb
                          WHERE cle='drapeau.livraison_offerte_mefali'"
```

Passer une commande mono-vendeur cash, scanner l'arrêt, livrer.

**Attendu, dans l'ordre** :

1. `GET /courses/active` affiche `montant_articles_unites: 3000`,
   `retenue_appliquee_unites: 500`, `montant_avance: 2500` ;
2. `arret.collecte` porte les trois montants ;
3. le reçu vendeur (`GET /vendeur/arrets/{id}/recu`) et le reçu client
   (`GET /commandes/{id}/recu`) affichent **les mêmes** 3000 / 500 / 2500 ;
4. la caisse porte `avance −2500`, puis à la remise `remboursement +2500` et
   **`frais_encaisses +500`** — Yao a payé 2500 au vendeur et encaissé 3000 chez
   Awa : les 500 sont sa part, financée par la retenue du vendeur. C'est le cas
   qui invalide la formule naïve `frais_encaisses = devis_prix_client`, lequel
   vaut 0 ici (research R13) ;
5. la créance `part_course` vaut **0** : la course a été payée par le vendeur, il
   ne reste rien à devoir.

**Contre-épreuve** : refaire la même course avec le drapeau de zone
« livraison offerte Mefali » **actif** et l'offre vendeur inopérante (le drapeau
prime). `frais_encaisses` vaut alors 0, et c'est la créance `part_course` qui
porte la part de course — la promotion de lancement, comptée au lieu d'être
oubliée.

**Contre-épreuve obligatoire** : refaire avec un panier **multi-vendeurs**.
Aucune retenue nulle part, frais dus normalement (FR-051).

### 3.5 La commande prépayée, de bout en bout (US6, SC-008, SC-012)

Commande prépayée, deux arrêts collectés, livraison confirmée.

**Attendu** :

- `GET /courses/active` → `remise.montant_a_encaisser_unites` vaut **0** (c'est le
  trou de `suivi.rs:555` que ce cycle ferme) ;
- aucune écriture `remboursement` — aucun cash n'a changé de main ;
- **deux créances** créées automatiquement : `avance_prepayee` (Σ avances) et
  `part_course` (part du devis), à l'état `due` ;
- `GET /moi/caisse` → `du_par_mefali_unites` = somme des deux ;
- `POST /admin/creances/{id}/regler` → l'écriture `reglement` apparaît, le solde
  du livre remonte, la créance passe `reglee` avec son auteur et son instant ;
- **rejouer** la fin de course depuis la file hors-ligne : **aucune** créance
  supplémentaire (`evenement_id UNIQUE`).

### 3.6 Changer de fournisseur sans rien casser (US7, SC-010)

```bash
cargo test -p paiements --test fournisseur_alternatif
grep -riE "cinetpay|paydunya|bizao|hub2" backend/crates/commandes backend/crates/coursier \
     backend/crates/dispatch apps/ web/     # doit ne rien renvoyer
```

**Attendu** : la même suite passe avec un vocabulaire, une signature et des codes
d'état différents ; aucun nom d'agrégateur n'existe hors de
`backend/crates/paiements/src/fournisseur/`.

---

## 4. Validation sur appareil — ce qu'aucun test ne voit

| # | Geste | Ce qu'on regarde |
|---|---|---|
| 1 | Commander au-dessus du plafond, payer | Le navigateur système s'ouvre sur la page du fournisseur, **tous** les moyens y sont, le retour ramène dans l'app avec le bon état |
| 2 | Tuer l'app pendant le paiement, la rouvrir | Le suivi montre l'attente et le temps restant ; le bouton reprend le paiement (FR-016) |
| 3 | Laisser expirer, écran allumé | L'annulation apparaît **d'elle-même** dans le suivi, avec un motif lisible, sans jargon de paiement |
| 4 | Couper le réseau après avoir payé, le rétablir | La commande est confirmée au retour du réseau — le produit ne s'est fié à aucun retour de navigateur |
| 5 | Côté coursier, ouvrir une course prépayée | « Rien à encaisser » est **sans ambiguïté** : personne ne doit pouvoir le confondre avec un encaissement oublié |
| 6 | Côté coursier, arrêt avec retenue | Le montant net est en gros, la retenue est **expliquée** à l'écran, pas seulement soustraite |
| 7 | Ouvrir la caisse après une journée mixte | Les trois positions se lisent d'un coup d'œil ; chaque créance dit son état de règlement |
| 8 | Côté vendeur, activer l'offre de livraison | La commande suivante en tient compte ; les commandes en cours n'ont **pas** bougé (FR-048) |

---

## 5. Ce qui ne peut PAS être validé ce cycle

| Non validable | Pourquoi | Quand |
|---|---|---|
| L'intégration réelle de l'agrégateur | Le prestataire n'est pas choisi (cadrage §10.7) | à la sélection — recette du fournisseur, sur appareil |
| Le remboursement effectif d'un client | PAY-04, P1 — `refund` existe, rien ne l'appelle | cycle PAY-04 |
| Le paiement mobile money sur place | PAY-03, P1 | cycle PAY-03 |
| La notification push d'expiration | NTF non construit — l'événement est émis, le suivi porte l'info | cycle NTF |
| Les écrans d'administration | ADM-01→06 — les endpoints sont exercés par les tests d'API | cycle ADM |
| iOS | Xcode/CocoaPods non installés | quand l'environnement sera monté |
