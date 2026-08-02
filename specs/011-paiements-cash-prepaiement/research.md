# Research — Cycle PAY 011 : chaîne cash et prépaiement mobile money

**Feature** : `011-paiements-cash-prepaiement` | **Date** : 2026-08-01
**Entrée** : [spec.md](./spec.md), constitution v1.1.0, cadrage §7.5, §10.7, §12
**Sortie** : décisions techniques closes — aucune NEEDS CLARIFICATION ne subsiste.

Format : **Décision** / **Raison** / **Alternatives rejetées**.

---

## R1 — Le crate `paiements` devient réel, et ne dépend que de `commandes`

**Décision.** `backend/crates/paiements` passe de 5 lignes vides à un crate de domaine
avec `socle`, `zones`, `commandes`, `sqlx`, `chrono`, `uuid`, `serde`, `thiserror`,
`async-trait`, `tracing`, `reqwest` (client HTTP sortant) et `hmac`+`sha2`
(vérification de signature). Il possède le schéma SQL `paiements`. Il ne dépend
**ni de `coursier`, ni de `dispatch`, ni de `prestataires`**.

**Raison.** Constitution II : le sens des dépendances est `paiements ──▶ commandes`.
Le module `commandes` porte déjà tout ce dont le paiement a besoin — total figé,
`etat_paiement`, `EtatCommande::EnAttentePaiement`, `confirmer_prepaiement()`,
`annuler()` — et ne doit jamais apprendre qu'un fournisseur existe. Ce que
`paiements` ne peut pas atteindre par dépendance (la caisse du coursier), il
l'atteint par **l'outbox**, exactement comme `coursier` atteint `commandes` sans
en dépendre (cycle 010, R9).

**Alternatives rejetées.** (a) Loger le paiement dans `commandes` : ferait entrer
`reqwest` et un secret de fournisseur dans le crate le plus central du produit.
(b) Un crate `paiements` qui écrit dans le schéma `coursier` : deux propriétaires
pour une table, et la règle d'immuabilité du livre deviendrait indéfendable.

---

## R2 — La session s'ouvre par un endpoint dédié, jamais dans la transaction de création

**Décision.** `POST /commandes` reste **inchangé** : il crée la commande en
`EN_ATTENTE_PAIEMENT` comme aujourd'hui. L'app enchaîne immédiatement sur
`POST /commandes/{id}/paiement`, qui ouvre la session chez le fournisseur et
renvoie l'accès. L'endpoint est **idempotent** : rappelé, il renvoie la session
vivante existante.

**Raison.** Un appel HTTP sortant à l'intérieur d'une transaction SQL tient un
verrou pendant toute la latence d'un tiers — et un fournisseur qui répond en
8 s bloquerait la ligne de commande d'Awa pour 8 s. La séparation garantit aussi
que **la commande existe même si le fournisseur est en panne** : Awa la voit dans
son suivi, elle peut réessayer ou attendre l'expiration, ce que FR-018 exige.
SC-001 (< 10 s pour disposer d'un moyen de payer) est tenu : deux appels
successifs, le second seul touchant le réseau externe.

**Alternatives rejetées.** (a) Ouvrir la session dans `POST /commandes` :
verrou tenu, et un échec fournisseur ferait échouer une création de commande
pourtant valide. (b) Ouvrir la session par un consommateur outbox : l'app devrait
attendre un aller-retour de worker (latence de l'ordre de la seconde, plus la
file), pour un gain nul — le client est là, devant l'écran, il peut demander.

---

## R3 — Le trait `PaymentProvider` : trois opérations, un vocabulaire neutre

**Décision.**

```rust
#[async_trait]
pub trait PaymentProvider: Send + Sync {
    fn nom(&self) -> &'static str;
    async fn create_checkout(&self, d: DemandeCheckout) -> Result<Checkout, ErreurFournisseur>;
    fn verify_webhook(&self, e: &NotificationEntrante) -> Result<Notification, ErreurFournisseur>;
    async fn refund(&self, d: DemandeRemboursement) -> Result<Remboursement, ErreurFournisseur>;
    async fn consulter(&self, reference: &str) -> Result<Notification, ErreurFournisseur>;
}
```

Types neutres, définis par nous : `DemandeCheckout { reference_marchande, montant_unites,
devise, description_cle, retour_succes, retour_annulation }`, `Checkout { reference_fournisseur,
acces_paiement, expire_le }`, `Notification { reference_fournisseur, reference_marchande,
issue: IssuePaiement, montant_unites, devise, moyen: Option<MoyenPaiement>, survenu_le }`,
`IssuePaiement { Reussi, Echoue, Annule, EnCours }`, `MoyenPaiement { Wave, OrangeMoney,
MtnMoMo, MoovMoney, Carte, Autre(String) }`.

`verify_webhook` est **synchrone** : elle ne fait que vérifier une signature et
traduire un corps — aucune I/O. `consulter` sort du trio nommé par PAY-05 mais
est indispensable à R7 (réconciliation avant annulation) ; c'est une opération de
lecture, pas un quatrième chemin d'argent.

**Raison.** FR-003 et FR-042 : aucun nom de fournisseur, aucun code d'état
propriétaire ne franchit cette frontière. `MoyenPaiement::Autre(String)` évite
qu'un moyen inconnu d'un futur agrégateur force une migration d'enum côté domaine
tout en gardant les cinq moyens nommés typés pour l'analyse (FR-012).

**Alternatives rejetées.** (a) Passer le JSON brut du fournisseur au domaine :
c'est exactement la fuite que PAY-05 existe pour empêcher. (b) `verify_webhook`
asynchrone « au cas où » : une signature se vérifie en mémoire ; la rendre `async`
inviterait un jour un appel réseau dans un chemin qui doit rester instantané.

---

## R4 — Deux implémentations, dont aucune n'est l'agrégateur retenu

**Décision.** Trois implémentations sont livrées :

| Implémentation | Rôle | Vit dans |
|---|---|---|
| `AgregateurHttp` | client HTTP générique paramétré (URL de base, clé, secret HMAC, en-tête de signature) | `paiements::fournisseur::agregateur` |
| `FournisseurSimule` | double pilotable : succès, échec, expiration, signature invalide, montant divergent, indisponibilité | `paiements::fournisseur::simule` |
| `FournisseurAlternatif` | **second** double, au vocabulaire, à l'algorithme de signature et aux codes d'état différents | `paiements` (tests) |

Le fournisseur actif est choisi par `PAIEMENT_FOURNISSEUR` (`simule` par défaut en
dev, `agregateur` en production) et câblé dans `api::run()` derrière
`Arc<dyn PaymentProvider>`.

**Raison.** Le cadrage §10.7 dit l'agrégateur **non choisi**. Livrer
`AgregateurHttp` avec un contrat HTTP paramétré permet de brancher CinetPay,
PayDunya, Bizao ou HUB2 en ajustant configuration et adaptateur, sans toucher au
domaine. `FournisseurAlternatif` n'est pas un luxe : c'est **l'instrument de
mesure de SC-010** — sans lui, « le fournisseur est interchangeable » resterait
une affirmation.

**Alternatives rejetées.** (a) N'écrire que le double et attendre le choix :
`AgregateurHttp` est justement l'endroit où les surprises d'intégration
apparaissent (format de signature, encodage du montant) ; le poser maintenant les
fait apparaître maintenant. (b) Choisir un agrégateur d'autorité dans ce cycle :
hors du mandat, et le cadrage liste des critères (frais, délais de reversement,
KYB) qui ne se tranchent pas depuis un plan technique.

---

## R5 — L'idempotence du webhook est une contrainte de base, pas un `if`

**Décision.** Table `paiements.notification_recue` avec
`UNIQUE (fournisseur, reference_fournisseur, empreinte_charge)`. Le traitement :
`INSERT … ON CONFLICT DO NOTHING RETURNING id` ; si rien ne revient, la
notification est un **rejeu** → réponse 200 « déjà traité », aucun effet. Sinon
le traitement continue dans la même transaction, sous
`SELECT … FOR UPDATE` sur la ligne `paiements.transaction`.

**Raison.** FR-021 et FR-022, et le patron déjà éprouvé du produit :
`coursier.ecriture_caisse.evenement_id UNIQUE` (cycle 010, R9),
`commande.id` = clé d'idempotence du POST (cycle 008). L'unicité inclut
l'**empreinte de la charge utile** : un fournisseur qui renvoie la même référence
avec un contenu différent (passage `en_cours` → `réussi`) doit être traité, pas
avalé comme un doublon.

**Alternatives rejetées.** (a) Un verrou Redis : Redis est éphémère par
constitution II — l'idempotence de l'argent ne peut pas dépendre d'un cache.
(b) Un test « la transaction est-elle déjà réglée ? » : deux notifications
concurrentes passent le test toutes les deux avant que l'une n'écrive.

---

## R6 — La signature se vérifie avant de lire le corps, et le corps brut est requis

**Décision.** L'endpoint reçoit le corps **brut** (`web::Bytes`, pas
`web::Json<T>`), le passe à `verify_webhook` avec les en-têtes, et ne
désérialise qu'après validation. Secret dans `PAIEMENT_WEBHOOK_SECRET`
(≥ 32 octets, validé au démarrage comme `jwt_secret` et `plaque_secret`).
Comparaison en **temps constant**. Horodatage de signature accepté à ±5 min.
Une signature refusée → `401`, ligne `notification_recue` avec
`signature_valide = false`, log `warn` sans le corps.

**Raison.** FR-020 : « avant que son contenu ne produise le moindre effet ». Une
désérialisation Actix a déjà lieu **avant** le corps du handler : accepter
`web::Json<T>` reviendrait à faire confiance à la structure d'un inconnu. La
tolérance d'horloge ferme la fenêtre de rejeu d'une capture réseau (FR-020,
« périmée »).

**Alternatives rejetées.** (a) Vérifier la signature après désérialisation :
plus simple à écrire, et faux au sens exact de l'exigence. (b) Filtrer par
adresse IP : les agrégateurs changent d'IP sans préavis, et un filtre d'IP ne
prouve pas l'intégrité du contenu.

---

## R7 — L'échéance est persistée ; le job ne fait qu'écrire ce que la lecture savait

**Décision.** `paiements.transaction.expire_le` est **persistée** à l'ouverture.
Toute lecture la respecte déjà (le suivi affiche « expirée », le paiement est
refusé). Un job `job_expirer_sessions` toutes les **10 s** (constante
`BALAYAGE_SESSIONS_PAIEMENT`, patron `BALAYAGE_SUBSTITUTIONS` du cycle 008)
matérialise l'annulation. **Avant** d'annuler, il appelle
`PaymentProvider::consulter` sur chaque session échue sans issue connue : si le
fournisseur dit « réussi », la confirmation est appliquée au lieu de
l'annulation.

**Raison.** FR-027 : une notification perdue ne doit coûter ni la commande ni
l'argent du client. Et le commentaire du cycle 008 vaut mot pour mot ici : « une
décision d'argent ne dépend pas de la vie d'un processus ». Le job est un
matérialisateur, pas la source de vérité.

**Alternatives rejetées.** (a) Un `pg_cron` : dépendance d'extension serveur pour
ce que trois lignes de tokio font déjà ailleurs dans le produit. (b) Annuler sans
consulter : transforme chaque webhook perdu en litige client.

---

## R8 — Le paiement hors délai ouvre un dossier ; il ne ressuscite rien

**Décision.** Une notification `Reussi` sur une transaction `expiree` (ou dont la
commande est `annulee`) écrit `etat = payee_hors_delai`, ouvre un
`paiements.dossier` de type `paiement_hors_delai`, émet `paiement.hors_delai`
(consommé par NTF pour prévenir Awa) et **ne touche pas la commande**.

**Raison.** Clarification Q3, tranchée A. Rejouer une commande annulée rendrait
au client des prix figés il y a vingt minutes, un stock qui a bougé et un
créneau qui n'existe plus. Ignorer la notification laisserait de l'argent
encaissé sans trace — le pire des deux mondes pour un produit dont la seule
promesse est « qui détient quoi ».

**Alternatives rejetées.** (a) Fenêtre de grâce : rend l'échéance floue, et le
vendeur a pu fermer entre-temps. (b) Remboursement automatique via
`PaymentProvider::refund` : c'est PAY-04, explicitement hors périmètre (FR-041) ;
appeler `refund` ici construirait la story qu'on a exclue.

---

## R9 — La retenue vendeur est LUE, pas recalculée, et écrêtée à zéro

**Décision.** `commandes::depot::marquer_arret_collecte` lit
`livraison.devis_composantes->>'retenue_vendeur'` (déjà persistée par le cycle
008) et calcule :

```text
montant_articles = Σ lignes vivantes de l'arrêt          (déjà en place, T087)
retenue_applicable = retenue_vendeur, si et seulement si :
      la livraison n'a qu'UN arrêt de collecte           (mono-vendeur, FR-051)
   ET cet arrêt est celui-ci
retenue_appliquee = min(retenue_applicable, montant_articles)   (FR-052)
montant_avance = montant_articles − retenue_appliquee
ecretee = retenue_applicable > montant_articles
```

L'événement `arret.collecte` gagne `montant_articles`, `retenue_appliquee`,
`retenue_ecretee`. Le consommateur de caisse continue de lire `montant_avance` —
**aucun changement dans `coursier`**.

**Raison.** Le moteur de tarification a déjà tout arbitré (cycle 007,
`evaluation.rs` §8) : mono-vendeur, après les drapeaux de zone, donc « le drapeau
de zone prime » (VND-08) est déjà vrai sans une ligne de plus. Recalculer ici
créerait une seconde vérité tarifaire. L'écrêtage à zéro tient FR-052 sans
`CHECK` négatif : la colonne `montant_avance >= 0` reste satisfaite.

**Alternatives rejetées.** (a) Stocker la retenue sur l'arrêt à la création : un
retrait de ligne la rendrait périmée, exactement le défaut que T087 a corrigé sur
`montant_avance`. (b) Autoriser une avance négative pour « faire payer le
vendeur » : la constitution interdit qu'un coursier finance quoi que ce soit, et
`ecriture_caisse` deviendrait illisible.

---

## R10 — VND-08 minimal : deux colonnes sur le prestataire, lues à la création

**Décision.** `prestataires.prestataire` gagne
`offre_livraison prestataires.offre_livraison NOT NULL DEFAULT 'jamais'`
(enum `jamais | toujours | au_dela`) et
`offre_livraison_seuil_unites bigint` (requis si et seulement si `au_dela`,
tenu par un `CHECK`). `PgPrestataires` expose
`offre_livraison(prestataire_id) -> Option<tarification::OffreLivraison>` ;
`commandes::panier::evaluer_panier` remplace son `offre_livraison_vendeur: None`
par cette lecture **quand le panier est mono-vendeur**.

**Raison.** Clarification Q1, tranchée A. `commandes` dépend déjà de
`prestataires` (prix figés, sites, commandabilité) : aucune arête nouvelle.
`tarification::OffreLivraison` existe déjà avec ses deux variantes — le type
traverse tel quel. Le devis étant figé à la création, FR-048 (« aucune commande
existante retarifée ») est acquis sans travail supplémentaire.

**Alternatives rejetées.** (a) Sur `prestataires.site` : VND-08 dit
« configuration par **vendeur** », et le multi-sites est une provision non
construite (§11). (b) En configuration de zone : ce n'est pas un paramètre de
zone mais une décision commerciale d'un vendeur donné.

---

## R11 — Le montant à encaisser d'une commande prépayée vaut zéro (trou du cycle 010)

**Décision.** `commandes::suivi::course_active` et `montant_a_encaisser`
renvoient `0` quand `mode_paiement <> 'cash'`. L'événement `commande.terminee`
distingue `total_du` et `total_encaisse` (`0` si prépayé).

**Raison.** C'est un **défaut réel du code livré** :
`suivi.rs:555` pose `montant_a_encaisser_unites: e.total_unites` sans regarder le
mode, et `collecte.rs:767` écrit `total_encaisse: commande.total_unites` de même.
Sur une commande prépayée, l'app coursier affiche donc aujourd'hui un montant à
réclamer à un client qui a déjà payé. FR-057, FR-093 et SC-012 ferment ce trou.
Le total dû, lui, suit déjà correctement les retraits et les arrêts
indisponibles (`substitution.rs:75`), donc FR-055 est acquis.

**Alternatives rejetées.** Corriger seulement l'affichage Flutter : le serveur
resterait la source d'une valeur fausse, et la file hors-ligne la rejouerait.

---

## R12 — La créance n'entre pas au livre de trésorerie : elle a sa table

**Décision.** Nouvelle table `coursier.creance` (schéma `coursier`, propriété du
crate `coursier`) : `coursier_id, commande_id, livraison_id, nature
(avance_prepayee | part_course), montant_unites > 0, devise, etat (due | reglee),
regle_par, regle_le, evenement_id UNIQUE`. Le **règlement** écrit, dans la même
transaction, une écriture de caisse `reglement` (+montant) portant `creance_id`.

**Raison.** Le livre existant suit la **trésorerie de poche** — sa documentation
est explicite : « écrire un remboursement fictif ferait mentir un solde d'argent
réel » (cycle 010, R10). Une créance n'est pas de l'argent en poche ; l'inscrire
au livre casserait précisément l'invariant que le cycle 010 a défendu. Deux
objets, deux sémantiques, une jointure — et la clarification Q2 tranchée A est
tenue : la créance naît **automatiquement**, seul son règlement est un geste
humain.

**Alternatives rejetées.** (a) Une écriture `creance` au livre : le solde
cesserait de correspondre à la poche de Yao, et l'écran de caisse (dont c'est la
seule raison d'être) mentirait. (b) Une table dans `paiements` : ferait dépendre
`paiements` de `coursier` ou l'inverse, pour un objet qui est de la caisse.

---

## R13 — Trois soldes, une seule vérité par solde

**Décision.** La vue de caisse expose trois positions, toutes **calculées**,
aucune stockée :

| Position | Calcul | MVP |
|---|---|---|
| **Avancé non récupéré** | Σ `avance` non compensées par un `remboursement` sur la même livraison (existant) | actif |
| **Dû par Mefali** | Σ `coursier.creance` à l'état `due` | actif |
| **Détenu pour Mefali** | Σ `min(frais_encaisses, devis_marge)` des livraisons **cash livrées** − Σ écritures `reversement` | vaut 0 (marge nulle jusqu'à M4) |

À la remise **cash**, une écriture s'ajoute à l'existante : `remboursement`
(+Σ avances, inchangée) et **`frais_encaisses`**, dont le montant est

```text
frais_encaisses = total_du_client − Σ avances de la livraison
```

**et non `devis_prix_client`.** Les deux coïncident dans le cas ordinaire, mais
pas quand la retenue joue — et c'est justement là que la différence compte
(voir le tableau ci-dessous). La formule dit la **trésorerie réelle** : ce que Yao
encaisse moins ce qu'il a sorti, quelle que soit la façon dont la course a été
financée.

La créance `part_course` vaut, elle :

```text
part_course = max(devis_part_coursier − max(frais_encaisses − devis_marge, 0), 0)
```

À la remise **prépayée**, aucune écriture de trésorerie, mais deux créances :
`avance_prepayee` (Σ avances) et `part_course` (qui vaut alors `devis_part_coursier`,
`frais_encaisses` étant nul).

**Vérification des quatre cas** — `A` = Σ avances, `PC` = prix client,
`P` = part coursier, `M` = marge, `R` = retenue vendeur :

| Cas | Total dû | `A` | `frais_encaisses` | `part_course` | Solde final |
|---|---|---|---|---|---|
| Cash ordinaire | articles + PC | articles | PC = P + M | `P − (P+M−M)` = **0** | +P+M |
| Cash + retenue VND-08 (PC = 0, R = P+M) | articles | articles − R | R = P + M | **0** | +P+M |
| Cash + promo Mefali (PC = 0, pas de retenue) | articles | articles | **0** | `P − max(0−M,0)` = **P** | 0, puis +P après règlement |
| Prépayée | 0 encaissé | articles | **0** | **P** | −A, puis +P après règlement |

Les quatre convergent sur la même position finale. C'est cette table qui devient
la table de vérité de SC-006 (data-model §5).

**Raison.** FR-056, FR-060, FR-066, SC-006. Le cas 2 est celui qui a fait rejeter
la première formule : avec `frais_encaisses = devis_prix_client`, une course à
livraison offerte aurait porté `0` au livre alors que Yao a bien 500 F de plus
dans sa poche — le livre aurait menti exactement là où la retenue existe pour
qu'il dise vrai. Le cas 3 (promotion de lancement) tombe juste tout seul : la
part devient une créance, ce que la spec assumait déjà (« ce cycle la compte comme
créance ; il n'organise pas son versement »).

**Alternatives rejetées.** (a) Une table de soldes : seconde vérité à
réconcilier, refusée par le cycle 010 (data-model §1.3). (b)
`frais_encaisses = devis_prix_client` : faux dès que la retenue joue (cas 2).
(c) Ne pas écrire `frais_encaisses` du tout : le livre ignorerait les frais, que
PAY-01 nomme explicitement.

---

## R14 — Les dossiers d'exploitation naissent d'un consommateur outbox

**Décision.** Table `paiements.dossier` (`type_dossier`, `commande_id`,
`transaction_id`, `montant_constate`, `montant_attendu`, `motif_cle`, `etat`
(`ouvert | clos`), `evenement_id UNIQUE`, `clos_par`, `clos_le`). Elle est
alimentée par deux voies : directement par le traitement du webhook (montant
divergent, devise divergente, hors délai, orpheline), et par un consommateur
outbox `PaiementsOutbox` qui écoute `arret.collecte` (`retenue_ecretee = true`)
et `commande.annulee` (`remboursement_du = true`).

**Raison.** FR-024, FR-037, FR-052, FR-082. Le consommateur outbox est ce qui
permet à `paiements` de réagir à `commandes` sans qu'aucune arête n'apparaisse en
sens inverse — le patron exact de `CaisseOutbox` (cycle 010). `evenement_id
UNIQUE` rend le rejeu du worker sans effet, comme partout ailleurs.

**Alternatives rejetées.** (a) Faire créer le dossier par `commandes` :
`commandes ──▶ paiements`, cycle de dépendances interdit. (b) Un simple log
`warn` : un dossier d'argent qui n'existe que dans les logs n'est pas un dossier.

---

## R15 — Les reçus sont des lectures, pas des tables

**Décision.** `GET /commandes/{id}/recu` (client) et `GET /arrets/{arret_id}/recu`
(vendeur) composent leur réponse à la volée depuis les lignes de commande, le
devis figé, les arrêts et les écritures de caisse. Aucune table `recu`.

**Raison.** FR-072 : « aucun recalcul, aucune estimation » — les montants sont
déjà figés et déjà écrits ; les recopier dans une table créerait une troisième
copie à maintenir cohérente. Une table de reçus ne se justifierait que pour un
document légal horodaté et immuable, ce que le MVP ne demande pas.

**Alternatives rejetées.** Générer un PDF : rien dans PAY-01 ne le demande, et le
stockage objet + la rétention ARTCI qui s'ensuivraient sont un cycle à eux seuls.

---

## R16 — `etat_paiement = 'en_attente'` : la valeur existe, personne ne la pose

**Décision.** `PgPaiements::ouvrir_session` pose
`commandes.commande.etat_paiement = 'en_attente'` via une méthode ajoutée au port
`commandes` (`marquer_paiement_en_attente`), dans la transaction d'ouverture.

**Raison.** L'enum `commandes.etat_paiement AS ENUM ('du','en_attente','regle','rembourse')`
existe depuis le cycle 008 (migration 0008), mais aucune ligne de code ne pose
jamais `'en_attente'` : une commande mobile money reste à `'du'`, indiscernable
d'une commande cash. FR-014 ferme l'écart. L'écriture passe par un port plutôt
qu'un `UPDATE` direct : `paiements` n'écrit pas dans le schéma d'un autre crate
(constitution II).

**Alternatives rejetées.** Ajouter une valeur d'enum : elle est déjà là.

---

## R17 — `url_launcher` dans `mefali_client` : un plugin natif, donc un passage par le store

**Décision.** `mefali_client` gagne `url_launcher` (version alignée sur
`mefali_pro`, `6.3.2`, figée par lockfile). L'accès de paiement s'ouvre dans le
navigateur système via `LaunchMode.externalApplication`. Le retour se fait par le
**suivi de commande**, qui interroge l'état — jamais par un lien de retour dont
le contenu ferait foi (FR-025).

**Raison.** Contrainte inscrite dans `CLAUDE.md` : Shorebird ne patche que le
Dart, tout ce qui touche un plugin natif passe par le store. C'est un **coût de
livraison** à annoncer maintenant, pas à découvrir au moment du correctif.
`./scripts/verifier-accord-locks.sh` doit rester vert dans les trois paquets.

**Alternatives rejetées.** (a) Une WebView embarquée : plugin natif également,
plus lourd, et une page de paiement bancaire dans une WebView applicative est un
motif de refus chez plusieurs agrégateurs. (b) Réutiliser un lancement d'intent
maison : réécrire `url_launcher` en moins bien.

---

## R18 — Paramètres de zone ajoutés (seed `90_paiements_parametres.sql`)

**Décision.** Quatre clés, toutes héritées, aucune en dur :

| Clé | Défaut | Sert à |
|---|---|---|
| `paiement.session_duree_s` | `900` (15 min) | FR-030 |
| `paiement.reconciliation_avant_expiration_s` | `60` | R7 — consulter avant d'annuler |
| `paiement.creance_alerte_unites` | `50000` | FR-065, seuil d'alerte d'exploitation |
| `paiement.moyens_actifs` | `[]` (vide = tous) | garde-fou d'exploitation, jamais un filtre produit |

**Raison.** Constitution I et FR-100. `paiement.moyens_actifs` mérite un mot :
il est **vide par défaut**, donc sans effet — FR-011 interdit de masquer un moyen.
Il n'existe que pour couper en urgence un moyen défaillant chez l'agrégateur, et
sa présence non vide est journalisée.

**Alternatives rejetées.** Une constante Rust pour les 15 minutes : contredit la
règle « tout paramètre métier est de zone », et 15 min est justement le genre de
valeur qu'un lancement fait bouger.

---

## R19 — Modules non construits : ce qui est simulé, et par quoi

| Manquant | Ce que ce cycle fait | Preuve que c'est suffisant |
|---|---|---|
| **NTF** (push/SMS) | émet `paiement.session_expiree`, `paiement.hors_delai` ; l'information est **aussi** portée par `GET /commandes/{id}` | FR-033 : le suivi ne dépend d'aucun push |
| **ADM** (écrans Nuxt) | endpoints d'exploitation + client TS régénéré ; aucune page `/admin/**` | patron des cycles 009 et 010 (FR-084) |
| **PAY-04** (remboursements) | `refund` **définie**, jamais appelée ; dossiers visibles | FR-041, FR-111 |
| **PAY-03** (paiement sur place) | rien ; l'écart K4-1a reste assumé | FR-110 |
| **MET** (métriques) | événements émis avec leurs propriétés ; aucun agrégat | constitution VI — les KPI dérivent des événements |

---

## R20 — Le webhook est la seule surface non authentifiée du cycle

**Décision.** `POST /paiements/notifications/{fournisseur}` n'exige **aucun JWT**
(un agrégateur n'en a pas). Il est protégé par : signature HMAC vérifiée
(R6), taille de corps plafonnée (64 Kio), limitation de débit par IP réutilisant
le patron OTP du cycle 003, et journalisation de toute tentative refusée. Il est
exclu de Swagger UI en production comme les autres surfaces sensibles.

**Raison.** Constitution VIII : « chaque endpoint est protégé par rôle » — ici le
rôle est remplacé par une preuve cryptographique, ce qui est plus fort qu'un
rôle porteur. À justifier explicitement dans le Constitution Check du plan.

**Alternatives rejetées.** (a) Un jeton statique en en-tête : un secret partagé
qui ne prouve pas l'intégrité du corps. (b) Une allow-list d'IP seule : voir R6.

---

## R21 — Le piège `ALTER TYPE … ADD VALUE` impose deux migrations

**Décision.** `0020_paiements_enums.sql` crée le schéma `paiements`, ses enums,
**et** ajoute les valeurs manquantes aux enums existants
(`coursier.type_ecriture` += `frais_encaisses`, `reglement`, `reversement`).
`0021_paiements_tables.sql` crée les tables et les colonnes qui les utilisent.

**Raison.** PostgreSQL interdit d'utiliser dans la même transaction une valeur
d'enum qu'elle vient d'ajouter — le découpage 0008/0009 et 0010/0011 existe pour
cette raison exacte, et le cycle 010 l'a documenté en tête de `0015_coursier.sql`.
Les migrations 0001..0019 sont **intouchées** (constitution I).

---

## R22 — Tests : ce qui est vérifié, et où

| Niveau | Emplacement | Couvre |
|---|---|---|
| Unitaire (domaine pur) | `crates/paiements/src/**` | machine à états de la transaction, écrêtage de retenue, calcul des trois positions |
| Intégration crate | `crates/paiements/tests/` | idempotence, signature, expiration, réconciliation, dossiers |
| Intégration crate | `crates/coursier/tests/` | créances, écritures `frais_encaisses`, positions |
| Intégration API | `backend/api/tests/` | parcours de bout en bout, rôles, webhook non authentifié, reçus |
| Contrat fournisseur | `crates/paiements/tests/fournisseur_alternatif.rs` | **SC-010** : même suite, second vocabulaire |
| Flutter | `apps/*/test/` | compte à rebours, montant net de retenue, « rien à encaisser », caisse à trois positions |

Constitution VII : chaque transition de la machine à états de la transaction a
son test d'intégration, chemins d'échec compris.
