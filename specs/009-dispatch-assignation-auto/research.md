# Phase 0 — Recherche : dispatch automatique (cycle 009)

Chaque décision est prise contre le **code déjà livré** (cycles 001→008), pas
contre une intention. Les numéros `R*` sont cités par `plan.md`, `data-model.md`,
`contracts/` et le seront par `tasks.md`.

---

## R1 — Déclencheur du pipeline : consommateur outbox **+** tic périodique sur échéances persistées

**Décision.** Deux mécanismes, complémentaires, tous deux dans le process `api` :

1. **Consommateur outbox** `DispatchOutbox` branché sur `commande.prete_a_dispatcher`
   et `commande.paiement_confirme` → lance une évaluation immédiate.
2. **Tic périodique** `job_tic_dispatch` (intervalle 5 s) → résout tout ce qui est
   **temporel** : expiration d'offre, ouverture de broadcast, escalade,
   réassignation, reprise FIFO. Il ne lit que des **échéances persistées** en
   Postgres.

**Rationale.** `socle::WorkerOutbox` existe, est testé (`socle/tests/outbox.rs`) et
tourne déjà (`backend/api/src/lib.rs:325`) — mais **avec zéro consommateur**
(`WorkerOutbox::new(pool.clone(), Vec::new())`). DSP est donc le **premier
consommateur réel** de l'outbox : le trait `ConsommateurOutbox` est le point
d'extension prévu, et son intervalle par défaut de 1 s donne une latence
d'assignation d'environ une seconde après création — très en dessous de SC-002.

Le tic est calqué sur `job_expirer_substitutions` (`lib.rs:234`), dont le
commentaire porte la règle du cycle 008 (R10) : « ⚠ Ce job n'est PAS la source de
vérité de l'expiration : l'échéance est PERSISTÉE et toute lecture la respecte
déjà. » Même règle ici : `dispatch.offre.echeance_le` est en base, et
`GET /courses/offre-courante` refuse une offre échue **même si le tic n'a pas
encore passé**. Un redémarrage ne perd donc aucun compte à rebours.

**Piège à ne pas répéter.** Le worker marque l'événement publié seulement si
**tous** les consommateurs rendent `Ok` ; un `Err` incrémente `tentatives` et
l'événement est **rejoué au lot suivant, indéfiniment**. Donc :
`DispatchOutbox::consommer` ne rend `Err` **que** sur une panne d'infrastructure
récupérable. Toute issue métier — aucun éligible, bascule prépaiement, pool vide —
est un **succès** : elle est écrite en base et rend `Ok`. Sinon une commande sans
coursier bloquerait sa propre ligne d'outbox pour toujours.

**Alternatives rejetées.**
- *Minuteurs en mémoire* (`tokio::time::sleep` par offre) : perdus au
  redémarrage, et le compte à rebours de 40 s dériverait — contraire à la règle
  R10 du cycle 008.
- *Balayage seul, sans outbox* : ajoute jusqu'à un tic (5 s) de latence sur le
  chemin le plus sensible du produit.
- *Notifications d'expiration de clé Redis* : au mieux « au plus une fois »,
  silencieusement perdables, et Redis est déclaré éphémère reconstructible
  (constitution II) — une échéance d'argent ne peut pas en dépendre.

---

## R2 — Pool temps réel : **trois clés Redis**, et la durée de vie portée par le hash

**Décision.** Une publication de position écrit trois choses, dans cet ordre :

| Clé | Type | Contenu | Expiration |
|---|---|---|---|
| `coursier:pos:{coursier}` | string | `lat:lon:epoch_s` — **format existant, inchangé** | `EX dispatch.pool_ttl_s` |
| `dispatch:etat:{coursier}` | hash | zone, statut, capacités, note retenue, plafond du jour, course active | `EXPIRE dispatch.pool_ttl_s` |
| `dispatch:pool:{zone}` | GEO (zset) | `GEOADD lon lat {coursier}` | **aucune** — voir ci-dessous |

**« Être dans le pool » = le hash `dispatch:etat:{coursier}` existe.** L'index GEO
n'est qu'un **index de pré-filtrage** ; ses membres survivent à l'expiration du
hash (Redis n'offre pas d'expiration par membre de zset). Deux garde-fous :
un `ZREM` **paresseux** dès qu'un candidat GEO n'a pas de hash, et un balayage
d'élagage dans le tic. Un membre fantôme ne peut donc jamais recevoir d'offre —
il ne fait que coûter un `ZREM`.

**Rationale.** La clé `coursier:pos:{coursier}` est **déjà lue en production** par
`RedisPositions` (cycle 008, `infra_redis.rs:380`) pour le suivi client, avec son
décodage `lat:lon:epoch_s` et son calcul d'âge. La changer casserait le suivi.
Écrire les deux — la clé historique **et** le hash d'état — est le seul choix qui
livre DSP-01 sans régression sur CMD-05. C'est aussi ce qui donne à DSP-01 sa
sortie de pool : le TTL du hash EST le « heartbeat manquant » de la story.

**Alternatives rejetées.**
- *GEO seul* : aucune expiration par membre → fantômes permanents, et DSP-01 exige
  précisément qu'un coursier muet sorte du pool.
- *Hash seul, balayage de tous les coursiers* : correct à 4 coursiers, faux à
  l'échelle d'une ville — et le rayon est le premier filtre de DSP-02.
- *Un second numéro de base Redis* : sépare des données qui expirent ensemble et
  double la configuration.

**Reconstruction (FR-008).** Les trois clés se réécrivent intégralement à la
publication suivante. Aucune n'est lue comme une vérité : l'éligibilité **se
confirme en Postgres** (R12).

---

## R3 — Double verrou atomique : **un script Lua**, deux clés

**Décision.** Pose et libération par `EVAL`, jamais par deux allers-retours.

```
-- pose (KEYS[1]=offre:cmd:{commande}, KEYS[2]=offre:crs:{coursier},
--       ARGV[1]=jeton d'offre, ARGV[2]=verrou_offre_s)
if redis.call('SET', KEYS[1], ARGV[1], 'NX', 'EX', ARGV[2]) then
  if redis.call('SET', KEYS[2], ARGV[1], 'NX', 'EX', ARGV[2]) then return 1 end
  redis.call('DEL', KEYS[1])          -- tout ou rien (FR-056)
  return 0                            -- coursier déjà porteur d'une offre
end
return -1                              -- commande déjà offerte
```

La libération compare le **jeton** avant de supprimer : on ne libère jamais un
verrou qu'on ne détient pas (une offre échue puis reprise par un autre passage ne
doit pas se faire effacer sous les pieds).

**Rationale.** FR-056 exige « les deux ensemble, ou aucun ». Deux `SET NX EX`
successifs laissent une fenêtre où le coursier est verrouillé pour une commande
qui n'a pas obtenu son propre verrou. `MULTI/EXEC` ne sait pas décider en
fonction du résultat de la première commande. Lua est déjà le patron maison :
`RedisEphemere::consommer_essai` l'utilise pour son « vérifier-et-décrémenter »
atomique, et `backend/api/tests/infra_redis.rs` existe précisément parce que
« les scripts Lua ne sont ni compilés ni typés par `cargo build` ».

**Nommage.** DSP-04 écrit `SET offer:{order} {courier} NX EX 45`. Le plan garde la
sémantique et adopte la convention de préfixe du dépôt :
`dispatch:offre:cmd:{commande}` et `dispatch:offre:crs:{coursier}`.

**Le verrou n'est pas le registre.** La ligne `dispatch.offre` en Postgres porte
l'échéance, le destinataire et l'issue. Perdre Redis perd au pire **une offre en
vol**, que le tic redétecte par son échéance persistée.

---

## R4 — Double acceptation : la garantie est **en Postgres**, et elle existe déjà

**Décision.** Deux barrières, dont la seconde suffit seule.

1. **Redis** : un seul destinataire d'offre par commande (R3).
2. **Postgres** : l'affectation passe par `CommandesADispatcher::affecter`, qui
   appelle `assigner_coursier_tx` → `transition_commande`, lequel fait
   `SELECT etat … FOR UPDATE` sur la ligne `commandes.commande` **puis**
   `verifier_transition`. La table de transitions est **fermée** et ne contient
   pas `en_cours → en_cours`.

Conséquence, vérifiée dans le code (`depot.rs`, `etats.rs`) : deux acceptations
concurrentes se **sérialisent** sur le `FOR UPDATE`, la seconde lit `en_cours`,
`verifier_transition` la refuse, **sa transaction est annulée** — y compris
l'`UPDATE livraison.coursier_id` qui la précède. Il ne peut donc pas exister deux
coursiers sur une commande, **même si Redis est totalement absent**.

**Rationale.** C'est ce qui rend SC-001 démontrable sans dépendre d'un service
éphémère, et c'est exactement le « physiquement impossible » demandé. L'API
traduit `TransitionRefusee` en réponse « déjà prise » sans pénalité (FR-049).

**Conséquence pour les tests.** Deux tests, pas un : concurrence **avec** Redis
(le chemin réel) et concurrence **sans** Redis (`affecter` appelé deux fois en
parallèle) — le second prouve que la garantie n'est pas louée à Redis.

---

## R5 — Proximité : **une seule** matrice routière par évaluation, pré-filtrée par le GEO

**Décision.** Deux étages.

1. **Pré-filtre GEO** : `GEOSEARCH … BYRADIUS dispatch.rayon_m` autour du premier
   arrêt de collecte. Sûr par construction : le vol d'oiseau **minore** la route,
   donc un coursier écarté ici est certainement hors rayon routier.
2. **Test exact et scoring** : un **unique** appel `tarification::routage::matrice_ou_degrade`
   avec `[position de chaque candidat…, premier arrêt]` → matrice `n × n` en une
   seule requête OSRM `/table`, cache par tronçon compris, dégradé ×1,4
   `degraded=true` journalisé si OSRM est muet, et **jamais d'erreur** (la
   fonction rend toujours une matrice).

La composante de proximité utilise la **durée**, le test de rayon la **distance**.

**Rationale.** FR-035 interdit « un calcul de routage **par candidat** » — pas un
appel groupé. Or `matrice_ou_degrade` est justement conçue pour le groupé :
`OptionsCache` + cache par tronçon (`tarif:route:v1:{a}:{b}`) et repli inconditionnel.
Constitution IV, elle, **impose** la route et ne tolère le vol d'oiseau qu'en
dégradé explicite : lire le cache seul livrerait un dégradé quasi permanent,
puisque le tarif ne réchauffe que les tronçons vendeur→vendeur et vendeur→client,
jamais coursier→vendeur. Un appel groupé sur OSRM auto-hébergé coûte quelques
millisecondes pour 5 points (Tiassalé : ~4 coursiers) et donne l'ETA réelle que
DSP-03 demande.

**Alternatives rejetées.**
- *Cache seul, sans appel* : conforme à la lettre la plus stricte de FR-035, mais
  met le produit en dégradé permanent sur son classement principal.
- *Un appel par candidat* : explicitement interdit par FR-035.
- *Rayon en vol d'oiseau ×1,4 sans route* : écarterait des coursiers réellement
  joignables et remplirait la file d'attente pour rien.

---

## R6 — Scoring en **entiers**, du début à la fin

**Décision.** Composantes normalisées en **millièmes** (`0..1000`), poids en
**centièmes** (`40/30/20/10`), score = `Σ(poids × composante) / 100` → entier.
Les distances et durées f64 d'OSRM sont converties en mètres et secondes entiers
**avant** d'entrer dans le calcul.

**Rationale.** Deux raisons, aucune décorative. D'abord l'égalité de FR-039 :
« à score égal, l'ordre est aléatoire » exige une égalité **exacte**, que des
flottants rendent fortuite. Ensuite la reproductibilité des tests : un classement
assertable au rang près ne peut pas dépendre d'un arrondi de plateforme. Le
principe III (« jamais de flottant pour l'argent ») ne couvre pas le score, mais
sa raison d'être — la décision doit être exactement rejouable — s'y applique.

**Normalisations.** Proximité : `1000 - min(1000, durée_s × 1000 / plafond)`, où
le plafond est la pire durée du lot (le meilleur candidat vaut 1000, le pire 0 —
un classement est relatif). Inactivité : `min(1000, inactivité_s × 1000 /
dispatch.inactivite_plafond_s)`. Note : `note_centiemes × 1000 / 500` (barème sur
5), ou `dispatch.note_composante_neutre_millimes` si absente. Acceptation :
`taux × 10`, ou la même valeur neutre si aucune offre sur la fenêtre.

---

## R7 — Note absente : **deux** traitements opposés, tous deux justifiés

**Décision.** Un port `NotePrestataire` (consommé, rendu par `avis` plus tard),
`async fn note_centiemes(compte) -> Option<i32>`, avec le double `NoteAbsente`
pour toute la suite de tests. Puis :

- **Plafond d'avance** → note absente = **palier d'entrée** de la grille (5 000).
- **Composante de score** → note absente = **valeur neutre** (500 ‰).

**Rationale.** Ce n'est pas une incohérence, ce sont deux questions différentes.
Le plafond est une **exposition financière** : cadrage §7.5, « plafonds bas puis
relevés avec les notes » — un inconnu commence bas. Le score est un **classement
relatif** : pénaliser un nouveau coursier sur une note qu'il n'a pas eu l'occasion
de mériter l'empêcherait d'en obtenir une. Le cycle 008 avait laissé
`coursier.note` à `null` en renvoyant explicitement à AVI (« rien à inventer
ici ») : ce cycle ne l'invente pas davantage, il traite son absence.

**Grille en un seul paramètre.** `dispatch.grille_avance_par_note` est un tableau
JSON, comme `transport.actifs` l'est déjà — un seul point d'édition pour ADM-04,
un seul paramètre à seeder.

---

## R8 — Paires bloquées : port + double, **aucun stockage créé**

**Décision.** Port `PairesBloquees` avec
`async fn bloquees(coursier, contreparties: &[Uuid]) -> HashSet<Uuid>` (lot, pas
un aller-retour par arrêt), double `PairesSimulees`, et **aucune table**.

**Rationale.** CRS-07 est **P1** et en tranche T4 ; c'est lui qui possède les
motifs, la modération et la levée admin. Créer la table ici en faisant semblant
serait une provision déguisée en fonctionnalité (constitution IX). Le port rend
FR-025 vérifiable au niveau du domaine, et CRS-07 l'implémentera sans toucher au
contrat. Patron identique à `RestrictionsCompte`/`RestrictionsSimulees` du cycle
008.

---

## R9 — Capacité requise : sur la **livraison**, générique, jamais sur le tronc

**Décision.** Nouvelle table `commandes.capacite_requise(livraison_id, famille,
valeur)`, PK `(livraison_id, famille, valeur)`, écrite par
`commandes::creation` depuis `demande.transport_slug` (famille `transport`).

**Rationale.** Trois contraintes se rencontrent ici.
- Le tronc **ne peut pas** la porter : constitution II, « le tronc de commande ne
  contient AUCUN champ logistique ». Quel véhicule il faut est logistique.
- Elle **n'est nulle part** aujourd'hui : `creation.rs:494` s'en sert pour choisir
  la règle tarifaire et `creation.rs:780` la met dans la charge utile de
  `commande.prete_a_dispatcher`, mais aucune colonne ne la garde ;
  `devis_composantes` ne porte que le détail d'effort, et `transport_slug` ne vit
  en base que sur `tarification.regle`.
- FR-018 exige un filtre **générique**. Une table `(famille, valeur)` accepte les
  qualifications d'artisan de la phase N sans migration ni réécriture du filtre.

**Alternatives rejetées.**
- *`livraison.transport_requis text`* : plus simple aujourd'hui, mais chaque
  nouvelle famille de capacité coûterait une migration **et** une réécriture du
  filtre — exactement ce que FR-018 interdit.
- *Relire la règle tarifaire* : une règle peut être versionnée ou retirée ; la
  capacité requise d'une commande est figée à sa création, comme ses prix.

---

## R10 — Bascule prépaiement : **une ligne** de plus dans la table fermée

**Décision.** Ajouter `en_cours`-hors-sujet mis à part, **deux** transitions au
niveau `Commande`, acteur `Systeme` :

| Depuis | Vers | Motif |
|---|---|---|
| `nouvelle` | `en_attente_paiement` | capacité d'avance seule bloquante (FR-026) |
| `en_cours` | `en_attente_coursier` | retrait du coursier par réassignation (R13) |

La reprise `en_attente_paiement → nouvelle` (Systeme) et la sortie
`en_attente_paiement → annulee` existent déjà : la boucle se ferme sans autre
ajout. Le tronc passe aussi `mode_paiement` de `cash` à `mobile_money`.

**Condition exacte (FR-026).** L'évaluation rend, par coursier écarté, la
**liste** de ses motifs (`EcartEligibilite { coursier, motifs }`). La bascule ne se
déclenche que s'il existe au moins un écart dont `motifs == [CapaciteAvance]` —
« la capacité d'avance est le SEUL critère bloquant ». Un pool vide pour une autre
raison part en file FIFO, où le prépaiement ne changerait rien.

**Rationale.** La table de transitions est déclarative et fermée : « une transition
ABSENTE est refusée ». Aujourd'hui `en_attente_paiement` n'est atteignable qu'à la
**création** (`depuis: None`) — un `nouvelle → en_attente_paiement` serait donc
refusé. C'est une ligne de table plus un test, pas une refonte : exactement ce que
le cycle 008 a conçu.

---

## R11 — Où vivent les données : schéma `dispatch` en Postgres, `PgDispatch` dans le crate

**Décision.** Nouveau schéma `dispatch` avec 4 tables (`offre`, `plafond_jour`,
`incident_reassignation`, `suivi_progression`) — détail en `data-model.md`. Le
crate `dispatch` porte **sqlx** et `PgDispatch` (patron `PgCommandes`,
`PgZones`) ; **Redis** reste derrière un port, implémenté dans
`backend/api/src/infra_redis.rs` (patron `RedisEphemere`, `RedisPositions`).

**Rationale.** C'est le découpage déjà en place dans tout le dépôt : les crates de
domaine possèdent leur schéma et leurs requêtes vérifiées à la compilation ; les
dépendances externes non-Postgres passent par des traits pour rester doublables.
`cargo sqlx prepare` couvre alors tout le SQL de DSP.

**Pas de table pour le taux d'acceptation ni l'inactivité.** Le taux se calcule
depuis `dispatch.offre` sur la fenêtre de zone ; l'inactivité se lit par un port
sur `commandes` (R12). Un agrégat matérialisé serait une seconde vérité à
resynchroniser.

---

## R12 — Le pool ne rend jamais éligible : confirmation en base, par ports

**Décision.** Après le pré-filtre GEO, chaque candidat est **confirmé en
Postgres** :

| Vérification | Source | Chemin |
|---|---|---|
| rôle coursier valide, compte non bloqué | `comptes` | port `EtatCoursier` (nouveau, implémenté dans `comptes`) |
| aucune course active | `commandes` | `CommandesADispatcher::course_active` (méthode ajoutée) |
| fin de la dernière course (inactivité) | `commandes` | `CommandesADispatcher::fin_derniere_course` (méthode ajoutée) |
| capacités déclarées | `comptes` | port `EtatCoursier` (véhicules de `comptes.vehicule_declare`) |

**Rationale.** FR-009. Un hash Redis survit à une suspension : le pool est un
index, pas une autorisation. Les deux méthodes s'ajoutent au trait
`CommandesADispatcher` **existant** — le cycle 008 l'a créé pour ça (« Contrat
offert à DSP ») — plutôt que dans un second trait qui découperait le même contrat
en deux. `comptes` possède `vehicule_declare` et `compte.bloque` : DSP ne cite
jamais ces tables, il passe par un port, comme le cycle 008 l'a fait pour
`RestrictionsCompte`.

---

## R13 — Réassignation : mouvement mesuré sur **distances observées persistées**

**Décision.** Table `dispatch.suivi_progression(livraison_id, distance_m,
observe_le)`, une ligne par livraison assignée, mise à jour à chaque publication
de position du coursier assigné. Le tic compare :

- **sans mouvement** : `distance_m` n'a pas diminué d'au moins
  `dispatch.reassignation_deplacement_min_m` depuis `dispatch.reassignation_sans_mouvement_s`,
  **ou** aucune observation fraîche sur la fenêtre (FR-078) ;
- **sans scan** : aucun arrêt collecté au-delà de `assignee_le + prépa +
  dispatch.reassignation_sans_scan_marge_s`.

Puis : `livraison.coursier_id = NULL`, tronc `en_cours → en_attente_coursier`,
ligne `dispatch.incident_reassignation`, et le coursier retiré est **exclu** des
offres de cette commande (`dispatch.offre` porte déjà l'historique : FR-074 se lit
dessus, sans colonne de plus).

**Pourquoi persister la distance.** Redis ne garde que la **dernière** position :
il n'y a aucun historique pour dire « il ne s'est pas rapproché depuis 5 minutes ».
Et la décision retire une course à quelqu'un : elle ne peut pas dépendre d'un
service éphémère.

**Pourquoi `coursier_id = NULL` + `en_attente_coursier`.** La colonne est
documentée pour ça depuis le cycle 006 : « `coursier_id` est POSÉ par DSP
(affectation) — NULL tant que non assignée » (`0005_commandes.sql:33`). Et
`en_attente_coursier` **est** l'entrée du pipeline (file FIFO par âge de CMD-10) :
la réassignation réutilise intégralement la machinerie existante au lieu d'en
inventer une. L'index partiel `livraison_coursier_active` reste correct — une
livraison sans coursier n'y est simplement pas.

**Garde d'argent (FR-075).** Si `EXISTS (arret collecté)`, aucune réassignation :
événement `dispatch.course_bloquee_escaladee` vers l'exploitation. Le coursier a
engagé ses fonds propres ; « le coursier ne perd jamais » (§7.5) interdit qu'un
automatisme lui retire une marchandise payée.

---

## R14 — Escalade : **étendre** `escalader_attentes`, ne pas en créer une seconde

**Décision.** Trois gestes sur l'existant, aucun doublon.

1. **Câbler** `PgCommandes::escalader_attentes` dans le tic — elle n'est
   aujourd'hui appelée que par `backend/api/tests/commandes_file.rs` : le cycle
   008 a écrit la fonction et **ne l'a jamais planifiée**.
2. **Étendre son `WHERE`** aux commandes en `nouvelle` dont l'âge dépasse le seuil,
   pas seulement `en_attente_coursier` : DSP-06 escalade *toute* commande non
   assignée, cascade et broadcast compris.
3. **Ajouter `chemin`** (`file` \| `pipeline`) au payload de
   `commande.attente_coursier_escaladee`, et amender la taxonomie.

**Rationale.** Son idempotence est déjà exactement FR-066 : le `NOT EXISTS` sur
l'événement `commande.attente_coursier_escaladee` de l'outbox fait office de
marqueur, « donc aucune colonne supplémentaire n'est nécessaire, et aucune ne peut
se désynchroniser de lui ». Un second événement d'escalade casserait précisément
cette propriété : « exactement une alerte par commande, quel que soit le chemin ».
Le seuil `commande.escalade_attente_coursier_s` (300 s) est déjà seedé — le
réutiliser, c'est la source de vérité unique du principe I.

---

## R15 — Surfaces Flutter : deux tranches, Riverpod codegen, **ni son ni push**

**Décision.**

| Dossier | Contenu | Moule d'état |
|---|---|---|
| `apps/mefali_pro/lib/coursier/disponibilite/` | K1 (tranche DSP) : bascule en ligne, plafond du jour, émetteur de position, bandeau reconnexion | `Notifier<EtatDisponibilite>`, `@Riverpod(keepAlive: true)` — porteur de **processus** |
| `apps/mefali_pro/lib/coursier/offre/` | K2 : offre courante, compte à rebours, arrêts, gain, avance, accepter/refuser, « déjà prise » | `AsyncNotifier`, `@riverpod` nu (autoDispose) — **chargement** jetable |

- **Compte à rebours = état LOCAL** du widget, jamais providerifié : constitution
  XII nomme explicitement « comptes à rebours ergonomiques » parmi ce qui reste
  local. L'autorité est `echeance_le`, rendue par le serveur.
- **Position** : `geolocator` est **déjà** une dépendance de `mefali_pro`
  (`^14.0.2`, porte de présence QRC) — aucune dépendance nouvelle. Publication en
  **premier plan** via `getPositionStream`, à `suivi.position_periode_s`.
- **Aucune sonnerie, aucune notification locale, aucune vibration** : FR-094 les
  attribue à NTF-01. Donc **aucune** nouvelle dépendance Flutter dans ce cycle —
  ce qui respecte aussi le principe X (chaque brique en dernière version stable
  puis figée : on n'en fige pas une dont on n'a pas besoin).
- Réutilisation : `BandeauHorsLigne` de `mefali_core` (`src/coursier/bandeaux.dart`)
  pour l'état reconnexion, `formaterMontant` pour les montants, jetons de
  `src/theme/tokens.dart`, `pasDeRetry` de `src/portee.dart`.
- Piège du cycle 008 à ne pas repayer : la couche d'appel rend le **corps JSON du
  contrat** (via `standardSerializers`), pas les DTO — les vues se construisent
  depuis le JSON, et c'est ce chemin que les tests widget couvrent.

**Limite assumée et documentée.** Sans service de premier plan Android, l'app
cesse de publier quand elle passe en arrière-plan : le coursier sort du pool par
TTL. C'est **conforme** à DSP-01 (« un coursier muet sort du pool ») et honnête
vis-à-vis de Yao, qui voit son bandeau de reconnexion. Le suivi en arrière-plan
appartient à CRS, avec sa propre décision de dépendance.

---

## R16 — Transport de l'offre : **interrogation courte**, pas de canal durable

**Décision.** `GET /courses/offre-courante`, interrogé toutes les 2 s tant que
l'écran de disponibilité ou d'offre est monté. Limitation de débit par le patron
`governor` déjà en place dans `zones_http.rs`.

**Rationale.** FR-094 : le transport est NTF-01. Construire ici un canal durable
(WebSocket, SSE) serait payer deux fois une brique destinée à être remplacée par
le push, et immobiliser des workers Actix pour un produit dont l'offre dure 40 s.
L'interrogation courte ne construit rien qui doive être défait : le jour où le
push arrive, il **réveille** l'app, qui appelle le même endpoint.

**Alternatives rejetées.** *Long-poll* : tient un worker par coursier en ligne.
*WebSocket/SSE* : brique durable jetable. *FCM ici* : reprend le travail de NTF-01,
exige un projet Firebase, des identifiants et un canal Android — et iOS reste hors
d'atteinte (Xcode/CocoaPods non installés, cf. cycle plateformes natives).

---

## R17 — Tests : concurrence réelle, double mémoire pour le reste

**Décision.**

- Port `PoolCoursiers` + **deux** implémentations : `RedisPool` (production, dans
  `api`) et `MemoirePool` (double, dans le crate `dispatch`). Patron
  `DepotEphemere` / `MemoireEphemere` du cycle 003 : la suite entière tourne sans
  Redis, et des tests dédiés prouvent que l'implémentation réelle tient les mêmes
  promesses.
- **Test de concurrence A (avec Redis)** : N tâches tokio appellent
  `POST /courses/offres/{id}/accepter` sur l'app réelle → exactement un `200`,
  N−1 « déjà prise », zéro pénalité. Sauté si Redis est absent (patron
  `infra_redis.rs`).
- **Test de concurrence B (sans Redis)** : `affecter` appelé en parallèle → une
  seule affectation, la seconde refusée par la table fermée. Prouve que SC-001 ne
  dépend pas de Redis (R4).
- **Test de perte totale** : vider le pool en pleine cascade → aucune commande
  perdue, aucune double affectation, pool reconstitué à la publication suivante.
- Bac d'essai `bac_dispatch/mod.rs` sur le modèle de `bac_commandes/mod.rs` : app
  Actix réelle, zone Tiassalé, paramètres du cycle, coursiers avec véhicules
  déclarés et jetons valides.

**Piège d'environnement recensé.** Le seed n'active que
`transport.actifs = ["a_pied","velo","moto"]` et `a_pied` plafonne à 800 m : un
bac de dispatch doit déclarer des coursiers **`moto`** et poser des positions
proches, sinon le devis échoue avant même le dispatch (« aucune règle tarifaire
applicable », cycle 008).

---

## R18 — Ce que le cycle **ne** construit pas, et pourquoi c'est sûr

| Non construit | Raison citée | Ce qui le remplace ici |
|---|---|---|
| Push et sonnerie | NTF-01, story distincte, même tranche T1 (§0.5) | contrat d'émission + interrogation courte (R16) |
| Écran d'opérations admin | module ADM en tranche T3 (§0.6) | événements + endpoints admin exercés par API |
| Note du coursier | module AVI | port `NotePrestataire` + double (R7) |
| Paires bloquées | CRS-07, P1, tranche T4 | port `PairesBloquees` + double (R8) |
| Bandeau gains du jour | CRS-01 | hors périmètre, l'écran n'en dépend pas |
| Anti-abus (DSP-08) | P1, hors périmètre | les compteurs d'issues d'offre suffiront sans refonte |
| Superposition de 2 commandes | phase 2 | `course_active` exclut, un seul segment |
| Suivi de position en arrière-plan | dépendance et permission à décider par CRS | publication en premier plan (R15) |

---

## R19 — Écart de dépendance à surveiller

`dispatch` dépendra de `zones` (paramètres), `comptes` (état coursier),
`commandes` (contrat offert, affectation) et `tarification` (matrice routière).
**Aucune dépendance inverse** : `commandes` ne dépendra jamais de `dispatch` —
c'est pour cela que le cycle 008 a placé le contrat `CommandesADispatcher` dans
`commandes::ports` et non l'inverse. Le même écart qu'au cycle 008 (« `commandes`
ne peut pas dépendre de `qr` ») se re-rencontrerait sinon sous forme de cycle
Cargo.

**Note sur l'entrée utilisateur.** Le prompt de ce cycle cite « MinIO (S3) » ;
la constitution a été amendée en 1.0.1 (MinIO → **Garage**). Sans effet ici : le
dispatch ne stocke **aucun objet**, donc aucune des deux briques n'est touchée.
