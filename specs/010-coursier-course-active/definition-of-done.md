# Revue Definition of Done — cycle CRS 010 (T090)

`docs/user-stories-v2.md` §0.4, **point par point pour les 7 stories**. Règle du
cycle : *toute case non cochée devient une tâche, jamais une note*.

Vérifié le 2026-08-01, sur la branche `010-coursier-course-active`.

---

## 1. Critères d'acceptation couverts par des tests

| Story | Ce qui la couvre | ✓ |
|---|---|---|
| **US1** — checklist multi-arrêts (K3) | `coursier_course_active` (structure complète, 204, 403, aucun secret, lignes groupées) · `coursier_appels` · widgets `ecran_course_active_test`, `etat_course_test` | ✓ |
| **US2** — remise hors ligne (K4) | `coursier_remise_hors_ligne` (3 voies dont dépôt multipart, idempotence, `max()` des essais, blocage à 3, `423`, levée admin, dépôt refusé) · `verificateur_empreinte_test` · `ecran_confirmation_test` | ✓ |
| **US3** — rien ne se perd, rien ne double | `coursier_reconciliation` — le test qui fait foi, **et sa cardinalité de caisse enfin vérifiée** (§2.1 point 6) par `coursier_caisse::trois_avances_un_remboursement_solde_a_zero` | ✓ |
| **US4** — les trois preuves | `coursier_preuves` (les 7 combinaisons, espacement, trou, refus serveur, lecture admin) · `ecran_preuves_test` (8 combinaisons côté app) | ✓ |
| **US5** — la caisse (K5) | `coursier_caisse` (13 tests) · `admin_coursier` (9 tests) · `ecran_caisse_test` (9 widgets) | ✓ |
| **US6** — la journée (K1) | `coursier_caisse::journee` (6 tests) · `journee_et_navigation_test` (9 widgets) | ✓ |
| **US7** — service continu | `service_continu_test` (12 tests) · `interface_coursier_test` (bascule d'horloge) | ⚠ voir §7 |

**Transitions d'état** (constitution VII) : chacune a son test d'intégration —
collecte, arrêt indisponible, en-route, arrivée, remise (3 voies), échec,
indemnisation demandée → validée / refusée, écriture de caisse.

**Totaux** : `cargo test --workspace` **228 verts** · `flutter test` **133**
(`mefali_pro`) + **116** (`mefali_core`) · `dart analyze` vert dans les trois
paquets.

**✓ Coché**, avec la réserve du §7.

---

## 2. Annotations utoipa à jour ; clients régénérés sans diff manuel

Les **7 endpoints coursier** du contrat §1 portent leur `#[utoipa::path]`, ainsi
que les **8 endpoints d'exploitation** du contrat §3 :

```
/courses/active · /courses/{id}/appels (POST + PATCH) · /courses/{id}/presence
/courses/{id}/preuves/photo · /courses/{id}/preuves · /moi/caisse · /moi/journee
/admin/remises/bloquees · /admin/commandes/{id}/code/debloquer
/admin/commandes/{id}/depot · /admin/livraisons/{id}/preuves
/admin/coursiers/exposition · /admin/indemnisations
/admin/indemnisations/{id}/valider · /admin/indemnisations/{id}/refuser
```

`./scripts/generate-clients.sh` puis `git diff --exit-code clients/` : **vide**.
Aucun fichier de `clients/dart` ou `clients/ts` n'a été édité à la main.

**✓ Coché.**

---

## 3. Migrations versionnées ; seeds à jour

Cinq migrations, toutes **nouvelles** — aucune migration appliquée n'a été
retouchée (constitution I) :

| Migration | Objet |
|---|---|
| `0015_coursier.sql` | schéma `coursier`, 4 énumérations, 5 tables |
| `0016_commandes_remise_depot.sql` | dépôt autorisé, blocage/levée du code, idempotence remise et échec |
| `0017_livraison_depot_position.sql` | position du dépôt (découverte en branchant K4) |
| `0018_transitions_rejouees.sql` | trace des transitions rejouées |
| `0019_coursier_preuves_reunies.sql` | mémoire du basculement des preuves |

`backend/seeds/80_coursier_parametres.sql` : les **7 paramètres** du cycle, au
niveau pays, rejouables (`ON CONFLICT DO UPDATE`), aucun événement émis. Le
seuil d'essais du code de remise **n'en fait pas partie** :
`commande.essais_code_livraison` existe depuis le cycle 008 et est réutilisé
tel quel (R5, FR-106).

Côté app, la base locale monte en `schemaVersion 8` par migrations
**strictement additives** — aucune action en vol n'est perdue au passage de
version.

**✓ Coché.**

---

## 4. Événement outbox pour tout changement d'état + événements métriques

Les **7 nouveaux types** sont déclarés dans `docs/taxonomie-evenements.md`
**avant** implémentation (T001), et tous sont émis :

| Événement | Émetteur |
|---|---|
| `preuves_echec.reunies` | `coursier::preuves`, au basculement |
| `caisse.mouvement` | `coursier::caisse`, dans la transaction de l'écriture |
| `indemnisation.validee` / `.refusee` | `coursier::indemnisation` |
| `remise.code_debloque` | `admin_coursier_http::debloquer_code` |
| `depot.autorise` | `admin_coursier_http::autoriser_depot` |
| `coursier.action_reconciliee` | refus de propriété au rejeu (FR-088) |

Deux contrats du cycle 008 trouvent enfin leur **consommateur** :
`indemnisation.due` (→ indemnisation « demandée ») et `remise.code_epuise`.
`appel.intention` gagne son premier émetteur `de: coursier`.

`chaque_ecriture_porte_son_evenement` vérifie l'invariant : autant d'événements
`caisse.mouvement` que d'écritures, ni plus ni moins.

**Aucun secret dans aucune charge utile** :
`coursier_transverses::aucun_secret_n_echappe_du_parcours_complet` balaye
**toutes** les charges utiles d'un parcours complet.

**✓ Coché.**

---

## 5. Clés i18n (fr) externalisées

Toutes les chaînes des 5 écrans du cycle vivent dans
`apps/mefali_pro/lib/l10n/app_fr.arb`. Aucune chaîne utilisateur en dur — y
compris les textes du **service continu**, qui sont résolus dans la portée
plutôt qu'au point d'appel, précisément pour que le service puisse notifier sans
`BuildContext` **sans** qu'on soit tenté d'y écrire une chaîne (§3.3 du rapport
d'écarts).

Trois clés posées en T009 ont été **corrigées en pluriel ICU** au moment de les
consommer : `crsCaisseAvanceEnCoursCourses`, `crsCaisseLitigeBadge`,
`crsJourneeCoursesLivrees` — « 2 course » se lisait mal.

Côté serveur, chaque refus métier porte sa clé (`{ code, message_cle }`), y
compris `valeur_inconnue`, ajoutée en soldant le défaut du §3.4 du rapport
d'écarts.

**✓ Coché.**

---

## 6. Paramètres « paramétrables » en configuration de zone, sans doublon

Les **7 paramètres** du cycle sont en configuration de zone, hérités par
l'arbre, aucun en dur :

`coursier.preuve_appels_min` · `coursier.preuve_appels_espacement_s` ·
`coursier.preuve_presence_s` · `coursier.preuve_presence_rayon_m` ·
`coursier.preuve_presence_trou_max_s` ·
`coursier.retention_photo_preuve_jours` ·
`coursier.offre_interrogation_arriere_plan_s`

**Aucun doublon** — c'est le point que la révision du 2026-07-28 avait relevé :
le seuil d'essais du code **n'est pas redéclaré**, `commande.essais_code_livraison`
est lu tel quel. Les **trois** rétentions de photo (`qr.`, `substitution.`,
`coursier.`) sont distinctes par nature de preuve, pas dupliquées — documenté en
tête du seed.

Les 7 sont publiés au « Récapitulatif des paramètres de zone » (T089).

**Deux miroirs locaux assumés**, tous deux documentés dans le code et au
rapport d'écarts : `_trouMaxS = 120` (`etat_preuves.dart`) et
`periodeOffreArrierePlan = 5 s` (`service_continu.dart`). Ni l'un ni l'autre
n'est servi à l'app par le contrat ; l'écart tolérable est celui d'un affichage
ou d'un réveil, jamais d'une décision — le serveur tranche dans les deux cas.

**✓ Coché.**

---

## 7. Ce qui reste NON CONFORME

### 7.1 T087 — validation sur appareil : **non faite**

Les six scénarios de `quickstart.md` §3 n'ont pas été déroulés : ils exigent un
appareil ou un émulateur et une API joignable. C'est la **seule case non
cochée** de la DoD du quickstart.

Le plus important est le **§3.4 (réveil écran éteint)** : c'est la raison d'être
d'US7, et aucun test ne peut voir une sonnerie. `service_continu_test` prouve
que le service démarre, s'arrête, se tait quand il doit et annonce le temps
réellement restant — il ne prouve pas qu'Android sonne.

→ **Reste une tâche**, pas une note : dérouler `quickstart.md` §3.1 à §3.6 sur
appareil et consigner les résultats.

### 7.2 `PreuvesFixes` : instancié transitoirement, jamais utilisé

La DoD du quickstart dit « `PreuvesFixes` n'est plus câblé dans `backend/api`
(production) ». Il apparaît encore **une fois** dans `lib.rs`, comme port
provisoire au constructeur de `PgCommandes` — et il est remplacé quelques lignes
plus bas par `PgCoursier` (`avec_preuves`), **avant tout usage**.

Ce n'est pas un contournement : `coursier` dépend de `commandes`, jamais
l'inverse, donc les deux ne peuvent pas se construire l'un dans l'autre
(constitution II). La composition en deux temps est la seule forme possible, et
le bac de test compose **exactement pareil** — c'est ce qui ferme le piège du
« double qui ment » du cycle 009.

→ **Conforme en substance.** Aucune tâche.

### 7.3 Réserve du cycle 009 : la bascule K2 → course, toujours non observée

Reconduite telle quelle : l'enchaînement complet « accepter une offre → l'écran
de course s'ouvre » n'a jamais été observé à l'écran, ni en test ni sur
émulateur. Il sera couvert par §3.4 de T087.

---

## Verdict

**5 des 6 points de la DoD sont pleinement cochés.** Le premier l'est aussi,
avec une réserve d'observation : ce qui est testable l'est, ce qui ne l'est pas
attend un appareil (§7.1).

Une seule tâche reste ouverte : **T087**.
