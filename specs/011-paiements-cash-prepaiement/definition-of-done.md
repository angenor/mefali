# Definition of Done — cycle PAY 011 (T086)

Revue des six points de `docs/user-stories-v2.md` §0.4, dans l'ordre, par écrit.
Chaque point est **coché**, **coché avec réserve**, ou **non conforme**. Rien
n'est laissé implicite : une case qui ne se coche pas devient une réserve
nommée, avec ce qu'il faudrait pour la fermer.

État à la revue : `cargo test --workspace` **957 / 0 échec** ; `flutter test`
**102** (core) + **76** (client) + **156** (pro) = **334 / 0 échec** ;
`dart analyze` 0 (client), 0 (core), 8 avertissements **préexistants** (pro,
`keep_alive` et `provider_dependencies`, antérieurs à ce cycle) ;
`generate-clients.sh` exécuté deux fois, sortie **stable** ;
`verifier-accord-locks.sh` et `verifier-frontiere-paiement.sh` verts.

---

## 1. Critères d'acceptation couverts par des tests (unitaires **et** d'intégration sur les transitions)

**✅ Coché.**

Les transitions du domaine sont couvertes par des suites d'intégration dédiées,
exécutées contre une vraie base : `paiements_session`, `paiements_webhook`,
`paiements_expiration`, `paiements_hors_delai`, `paiements_registre`,
`paiements_recus`, `paiements_secrets`, `paiements_bac`, `coursier_creances`,
`coursier_positions`, `commandes_retenue_vendeur`, plus
`fournisseur_alternatif` et `refund_jamais_appelee` côté crate.

`coursier_positions.rs` est le test qui fait foi : il parcourt les **dix** états
de [data-model §5](./data-model.md) et échoue à la moindre unité mineure d'écart.

**Ce que ces tests ne voient pas** — et c'est établi, pas supposé : la
validation sur appareil (T085) a trouvé **quatre** défauts qu'aucune des 1 291
assertions ne voyait, dont deux qui rendaient une fonctionnalité entière
inopérante (§1.1 et §1.6 du [rapport d'écarts](./rapport-ecarts.md)). Trois sont
corrigés, chacun avec le test qui manquait :
`sonde_paiement_test.dart` (3 tests, vérifiés en échec sans le correctif) et
`offre_livraison_test.dart`, qui échouait dès la régénération du contrat.

## 2. Annotations utoipa à jour ; clients Dart/TS régénérés **sans diff manuel**

**✅ Coché, après correction d'une faute que ce point n'attrapait pas.**

Les clients sont régénérés par `./scripts/generate-clients.sh`, deux exécutions
successives donnant une sortie identique. Aucune édition manuelle : les fichiers
de `clients/` ne sont touchés que par le générateur.

**Mais** : le contrôle « pas de diff » ne dit rien de la **justesse** du
contrat. Deux types Rust déclaraient `#[schema(as = OffreLivraisonVendeur)]` ;
un seul survit dans `openapi.json`, et le client généré désérialisait la réponse
d'une route avec le modèle d'une autre. Le diff était vide, la CI verte, et le
geste vendeur cassé en production (rapport §1.6). Corrigé par renommage en
`OffreLivraisonReglee`.

**Réserve R7** : rien n'empêche la prochaine collision. Un contrôle mécanique
de l'unicité des `#[schema(as = …)]` du workspace fermerait la famille ; il
n'est pas écrit.

## 3. Migrations SQL versionnées ; seeds à jour

**✅ Coché.**

`0020_paiements_enums.sql` et `0021_paiements_tables.sql` sont versionnées et
appliquées (`_sqlx_migrations` à **21**). Aucune migration antérieure n'a été
modifiée. `backend/seeds/90_paiements_parametres.sql` est chargé par le runner
(11 fichiers rejoués), idempotent (`ON CONFLICT … DO UPDATE`), et n'émet aucun
événement — conforme à la taxonomie (« ce qui n'émet PAS »).

Vérifié en base après chargement : les quatre clés `paiement.*` sont présentes
avec leurs valeurs de seed.

## 4. Événement outbox pour **tout** changement d'état métier + événements MET-01

**✅ Coché pour l'outbox. ⚠️ Réserve pour MET-01.**

Les types émis par le cycle sont : `paiement.session_ouverte`,
`paiement.confirme`, `paiement.echoue`, `paiement.session_expiree`,
`paiement.hors_delai`, `paiement.dossier_ouvert`, `caisse.creance_ouverte`,
`caisse.creance_reglee`, `caisse.mouvement`, plus
`commande.paiement_confirme` et `commande.annulee` sur le tronc. **Tous** sont
déclarés dans `docs/taxonomie-evenements.md`, et tous sont écrits dans la
**même transaction** que la transition (règle impérative du projet). Le
consommateur `paiements` est le troisième monté sur l'outbox.

⚠️ **MET-01** : le crate `metriques` reste un **stub** — la taxonomie le dit
elle-même. Le parcours client de ce cycle alimente donc l'outbox sans qu'aucune
métrique produit ne soit calculée. C'est l'état voulu jusqu'au cycle MET, pas
un manque de ce cycle.

## 5. Clés i18n (fr) externalisées — **aucune chaîne en dur**

**✅ Coché.**

Balayage des 20 fichiers Dart ajoutés ou modifiés par le cycle : un seul
`Text('…')` littéral, `'${etat.arrets.length} / ${etat.arrets.length}'` —
une interpolation de nombres, pas une chaîne utilisateur. Les motifs de dossier
et de refus passent par des clés, y compris les motifs de retenue
(`motif_retenue_cle`) et d'annulation.

Confirmé à l'écran : tous les textes lus pendant T085 sont en français naturel,
sans jargon de paiement — « Le délai de paiement est écoulé. Votre commande a
été annulée, sans aucun frais. » plutôt qu'une mention de session ou de
transaction.

**Une réserve de vocabulaire, pas de conformité** : le titre « À la livraison »
(clé `suiviALaLivraison`, titre du bloc de remise) réapparaît dans un parcours
où la cliente vient d'écarter « Espèces à la livraison ». Deux sens pour les
mêmes mots (rapport §1.5).

## 6. Paramètres exposés en configuration de zone quand la story dit « paramétrable »

**✅ Coché.**

Les quatre paramètres du cycle sont en configuration de zone héritée, au niveau
**pays**, aucun en dur :

| Clé | Valeur seed | Ce qu'elle commande |
|---|---|---|
| `paiement.session_duree_s` | `900` | durée de vie d'une session (FR-030) |
| `paiement.reconciliation_avant_expiration_s` | `60` | âge à partir duquel on interroge le fournisseur avant d'annuler (R7, FR-027) |
| `paiement.creance_alerte_unites` | `50000` | seuil d'alerte d'exposition d'un coursier (FR-065) |
| `paiement.moyens_actifs` | `[]` | vide = **tous** actifs ; FR-011 interdit de masquer un moyen |

Vérifié à l'usage, pas seulement en base : abaisser `paiement.session_duree_s`
à 90 s a fait expirer une vraie commande sur l'appareil, sans redéploiement —
ce qui est exactement l'argument du seed contre une constante Rust.

---

## Ce qui reste non conforme, ou non vu

Aucun point de la DoD n'est **non conforme**. Trois zones d'ombre subsistent, et
elles sont nommées dans le [rapport d'écarts](./rapport-ecarts.md) :

1. **Les gestes 5 et 6 n'ont pas été déroulés** (rapport §2). Un coursier de
   démo ne peut pas passer en ligne : la déclaration de véhicule n'est
   atteignable que depuis le formulaire d'inscription, qu'un coursier déjà
   validé ne repasse jamais (§1.8, défaut CRS/CPT). La caisse à trois positions
   n'a donc été vue **qu'à zéro**, et la retenue à l'écran pas du tout.
2. **Aucun contact avec un fournisseur réel** (réserve R1). `simule.rs`,
   `AgregateurHttp` et `FournisseurAlternatif` valident la forme de
   l'abstraction. Le cycle CRS 010 avait trouvé neuf défauts à sa première
   exécution réelle ; ce cycle vient d'en trouver quatre à la sienne.
3. **Deux défauts constatés et non corrigés**, parce qu'ils relèvent de
   décisions produit hors périmètre PAY : l'écran de confirmation qui s'intercale
   sur une commande non payée (§1.2) et le suivi muet d'une commande en attente
   sans session ouverte (§1.3).

Les huit réserves ouvertes sont listées au §4 du rapport d'écarts.
