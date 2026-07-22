# Research — Prestataires agréés et catalogue vendeur (cycle 005)

**Branch**: `005-prestataires-catalogue-vendeur` | **Date**: 2026-07-18

Phase 0 du plan. Chaque décision résout un point que la spec renvoie explicitement
au plan, ou un choix d'intégration avec l'existant (cycles 002 zones, 003 comptes,
004 Riverpod). Aucun « NEEDS CLARIFICATION » ne subsiste dans le Technical Context.

---

## R1 — Reprise du port de stockage objet : `DepotObjets` migre de `comptes` vers `socle`

**Decision** : déplacer le port `DepotObjets` (avec `ErreurObjets`, `UrlPresignee`
et le double de test `MemoireObjets`) de `crates/comptes/src/ports.rs` vers un
nouveau module `crates/socle/src/objets.rs`. Le crate `comptes` ré-exporte les
types depuis `socle` (aucun changement d'API publique pour ses consommateurs) ;
`api/src/infra_s3.rs` implémente désormais le trait de `socle`. Le crate
`prestataires` consomme `socle::DepotObjets` pour les photos de fiche, les photos
d'articles et la charte signée.

**Rationale** : la spec l'annonce (« le port d'accès vit aujourd'hui dans le
domaine des comptes ; le rendre consommable par ce cycle suppose une reprise »).
Le stockage objet est une capacité TECHNIQUE transverse, pas un concept du domaine
comptes — sa place naturelle est `socle`, qui porte déjà l'outbox, la télémétrie
et la connexion Postgres (constitution, principe II : interfaces par traits, un
crate par domaine ; `socle` est le seul crate transverse).

**Alternatives considered** :
- `prestataires` dépend de `comptes` pour le port → couplage de domaine pour un
  besoin technique ; tout futur crate à médias (avis, coursier) hériterait du même
  couplage. Rejeté.
- Dupliquer le trait dans `prestataires` → deux définitions du même port, deux
  impls S3 à maintenir. Rejeté (principe I : un lieu de modification).

---

## R2 — Jeton de plaque : HMAC signé, STOCKÉ sur la ligne, résolu par recherche exacte

**Decision** : à l'agrément, générer `jeton_plaque = base64url(id_prestataire ‖
troncature_128(HMAC-SHA256(secret, "plaque:" ‖ id_prestataire ‖ nonce)))` avec un
nonce aléatoire, et le STOCKER en colonne `UNIQUE` sur `prestataires.prestataire`.
La résolution (`GET /prestataires/plaque/{jeton}`) est une recherche exacte sur
cette colonne ; la validité rendue est `statut = 'agree'` — dérivée, jamais
stockée. Le secret HMAC est une nouvelle variable d'environnement `PLAQUE_SECRET`
(distincte du secret JWT : rotation indépendante, le jeton de plaque vit des
années). Le code de secours est tiré à l'agrément (`0000`–`9999`, aléatoire
uniforme), stocké en clair (il n'est PAS un secret d'authentification : c'est un
comparateur local, FR-014), sans contrainte d'unicité à aucune échelle.

**Rationale** : le cadrage §5.3 exige un « jeton signé HMAC révocable serveur ».
Stocker le jeton rend la résolution triviale et fait dériver la révocation de
l'état d'agrément sans liste de révocation (clarification de la spec : « il
n'existe aucune action de révocation séparée qu'on pourrait oublier d'appeler »).
La signature reste vérifiable hors base — c'est ce que le cycle QRC exploitera
pour le pré-provisionnement hors-ligne (constitution, principe V). Rétablissement
= le jeton stocké n'a pas bougé (SC-003).

**Alternatives considered** :
- Jeton auto-porteur vérifié par signature seule (non stocké) → il faudrait une
  liste de révocation pour la suspension, exactement ce que la clarification
  interdit. Rejeté.
- JWT → surdimensionné (expiration, claims) pour un identifiant gravé sur une
  plaque physique qui ne doit JAMAIS expirer de lui-même. Rejeté.

---

## R3 — État effectif de boutique : fonction PURE, aucun ordonnanceur, aucun événement d'échéance

**Decision** : l'état effectif est calculé à CHAQUE lecture par une fonction pure
du crate `prestataires` :

```rust
pub fn etat_effectif(
    agree: bool,
    statut: StatutBoutique,          // ouvert | ferme | ferme_journee | en_pause
    pause_fin: Option<DateTime<Utc>>,
    ferme_journee_le: Option<NaiveDate>, // date locale couverte par « fermé pour la journée »
    horaires: &HorairesSemaine,
    maintenant_local: DateTime<Tz>,   // horloge dans le fuseau de la zone
) -> EffectifBoutique                 // { ouvert: bool, reouverture_estimee: Option<DateTime<Utc>> }
```

Ordre d'évaluation (FR-032) : non agréé → fermé ; hors horaires du jour → fermé ;
`en_pause` et `maintenant < pause_fin` → fermé ; `ferme_journee` et
`aujourd'hui ≤ ferme_journee_le` → fermé ; `ferme` → fermé ; sinon ouvert. Une
pause échue ou un « fermé pour la journée » dont le jour est passé cessent de
produire effet À LA LECTURE : la colonne `statut` reste telle quelle jusqu'au
prochain changement DÉCIDÉ — aucune transaction ne s'ouvre, donc aucun événement
(clarification de la spec ; l'événement de mise en pause porte `pause_fin`, ce qui
suffit aux métriques). `reouverture_estimee` = fin de pause recalée dans les
horaires, sinon début de la prochaine plage du prochain jour ouvert (FR-029).

**Rationale** : zéro ordonnanceur, zéro état incohérent possible, testable sans
base ni horloge réelle (l'horloge est un paramètre). C'est la seule lecture
compatible avec « la réouverture n'émet aucun événement » ET « tout événement
dans la même transaction ».

**Alternatives considered** : job périodique qui « rouvre » les pauses échues →
contredit frontalement la clarification (état décidé vs état dérivé), introduit
une fenêtre d'incohérence et un événement sans décision. Rejeté.

---

## R4 — « Je reste fermé aujourd'hui » = la transition « fermé pour la journée »

**Decision** : la sortie du rappel non bloquant de la maquette V1 (état 1c) est
mappée sur l'action `fermer_pour_la_journee`. Le serveur expose dans la réponse
boutique un booléen dérivé `rappel_ouverture` vrai si `statut = ferme` (fermeture
manuelle) ET l'heure courante tombe dans les horaires du jour. Comme choisir
« je reste fermé » bascule le statut en `ferme_journee`, la condition devient
fausse pour la journée : le rappel n'est pas réaffiché (FR-035) sans AUCUN état
supplémentaire ni côté serveur ni côté app.

**Rationale** : un seul état fait foi (même principe que la dérivation des
capacités vendeur) ; l'anti-réaffichage tombe gratuitement de la machine à états
existante au lieu d'un drapeau « rappel vu » à stocker et à réinitialiser.

**Alternatives considered** : drapeau local app « rappel ignoré le J » →
divergerait entre appareils d'un même prestataire (plusieurs comptes rattachés) et
survivrait mal aux réinstallations. Rejeté.

---

## R5 — Précondition coursier : port `CommandesActives` injecté, bouchon fermé en production

**Decision** : le crate `prestataires` définit un port :

```rust
#[async_trait]
pub trait CommandesActives: Send + Sync {
    /// Le coursier porte-t-il une commande active comportant un arrêt chez le
    /// prestataire de cet article, cet article appartenant à la commande ?
    async fn arret_actif(&self, coursier: Uuid, article: Uuid)
        -> Result<bool, ErreurCommandesActives>;
}
```

`PgPrestataires` le reçoit à la construction (patron des ports de `PgComptes`).
L'impl branchée en production ce cycle est `AucuneCommandeActive` (répond toujours
`false`) : tant que le module commandes n'existe pas, AUCUNE commande active
n'existe, donc aucun signalement coursier n'est recevable — c'est exact, pas un
bouchon menteur. Les tests injectent `CommandesActivesFixes` (double mémoire
paramétrable) pour exercer l'éligibilité et le refus (FR-038). Le cycle CMD
fournira l'impl réelle sans toucher au crate `prestataires`.

**Rationale** : c'est le « déclencheur simulé » que la spec impose (patron du
cycle 003 : `marquer_adresse_utilisee` appelé directement par les tests), exprimé
en port pour que la précondition soit STRUCTURELLEMENT infalsifiable côté
handler — le handler ne peut pas oublier de la vérifier, elle est dans le domaine.

**Alternatives considered** : endpoint de dev qui « pose » une commande active →
surface à gater, à éliminer en release, et qui anticipe le modèle de CMD. Rejeté.

---

## R6 — Verrouillage des prix : table `prix_fige` + méthode inhérente, PAS d'endpoint

**Decision** : `PgPrestataires::figer_prix(&self, tx: &mut PgTransaction<'_>,
article: Uuid) -> Result<PrixFige, _>` copie le prix courant (montant + devise)
dans `prestataires.prix_fige` et rend la ligne. Aucun endpoint HTTP ce cycle : le
module commandes appellera la méthode DANS SA transaction de création de commande
(CMD-03), exactement comme `comptes` appelle `PgZones::recalculer_activation`
dans la sienne. Les tests l'appellent directement, modifient ensuite le prix de
l'article et vérifient l'invariance du montant figé (SC-005).

**Rationale** : précédent établi au cycle 003 — les écritures inter-domaines sont
des méthodes inhérentes sur transaction, les traits servent aux lectures. Un
endpoint sans appelant réel serait une surface morte à protéger.

**Alternatives considered** : figer par copie des montants dans les futures lignes
de commande (pas de table) → le verrou n'existerait pas avant CMD et SC-005 ne
serait pas démontrable ce cycle. Rejeté.

---

## R7 — Recalcul d'activation de catégorie : comptage dans la transaction + appel `PgZones`

**Decision** : dans la MÊME transaction que l'agrément, le rétablissement, la
suspension ou la correction (FR-009, FR-056) :

```sql
SELECT count(*) FROM prestataires.prestataire
WHERE ville_id = $1 AND categorie_id = $2 AND statut = 'agree'
```

puis `PgZones::recalculer_activation(&mut tx, ville, slug_categorie, n)`. Pour la
correction FR-056, DEUX appels dans la même transaction : ancien couple
catégorie/ville puis nouveau. L'événement `categorie.activation_changee` (déclaré
au cycle 002) tombe alors dans la même transaction que la transition du
prestataire. La règle reste monotone à la hausse — la suspension déclenche le
recalcul « sans effet attendu », comme la spec l'exige.

**Rationale** : le crate `zones` ne connaît pas les vendeurs (commentaire explicite
dans `categorie.rs` : le comptage est un PARAMÈTRE d'entrée) ; c'est donc au crate
`prestataires` de compter les siens. La signature existante prend `&mut
PgTransaction` précisément pour cet usage.

**Alternatives considered** : événement outbox consommé en asynchrone par zones →
l'activation ne serait plus « dans la même opération » (SC-010) et il n'existe
aucun consommateur outbox câblé aujourd'hui. Rejeté.

---

## R8 — Paramètres de zone du cycle et lecture par les apps (FR-049/FR-050)

**Decision** : quatre clés, résolues par l'héritage `ConfigurationZones` :

| Clé | Type | Seed (Récapitulatif) |
|---|---|---|
| `rupture.masquage_seuil` | entier ≥ 1 | `2` |
| `rupture.masquage_fenetre_jours` | entier ≥ 1 | `7` |
| `categorie.<slug>.affichage_rupture` | `"grise"` \| `"masque"` | `"grise"` (les 6 catégories) |
| `charte.conservation_post_relation_annees` | entier ≥ 0 | `5` |

Plus une clé technique `zone.fuseau_horaire` (seed `"Africa/Abidjan"`, posée à la
racine CI) pour interpréter les horaires d'ouverture — la spec fixe « le fuseau de
la zone » sans le matérialiser ; une clé de configuration évite une migration du
schéma `zones`. Le validateur de `crates/zones/src/parametre.rs` est étendu pour
accepter `affichage_rupture` dans le namespace `categorie.<slug>.*` (valeurs
énumérées) — modification du crate `zones`, pas de son schéma.

**Lecture par les apps (FR-050)** : le mode d'affichage n'est PAS ajouté à
`/config` (ne pas élargir la liste blanche). Il est APPLIQUÉ ET SERVI par la
consultation de ce cycle : la fiche publique porte `affichage_rupture` (résolu
pour la catégorie du prestataire) ; si `masque`, les articles indisponibles sont
ABSENTS de la réponse ; si `grise`, ils sont servis avec `disponible=false`.
L'aperçu « ce que voit le client » de V2 consomme la même consultation publique —
cohérence garantie par construction.

**Rationale** : le Récapitulatif des paramètres de zone (mis à jour le 2026-07-18,
il fait foi) fixe les trois valeurs métier ; « accessible sans élargir la portée
des paramètres exposés » se satisfait en servant le mode là où il s'applique.

**Alternatives considered** : vue dérivée dans `/config` (comme
`note_vocale_duree_max_s`) → exposerait un paramètre par catégorie dans un
document global alors qu'il n'a de sens que sur une fiche. Rejeté.

---

## R9 — Surfaces de consultation : fiche publique, résolution de plaque sous session

*Amendé le 2026-07-18 après l'analyse croisée (/speckit-analyze, finding C1) :
la résolution de plaque, initialement publique, passe sous session authentifiée.*

**Decision** :
- `GET /prestataires/{id}` — SANS authentification, rate-limité par IP (même
  `Governor` que `/config`) : fiche + catalogue, sous-ensemble strict de FR-027 :
  nom, photos (URLs présignées TTL 10 min), catégorie, état effectif de boutique,
  horaires, `reouverture_estimee`, `commandable`, `affichage_rupture`, articles
  (nom, prix, prix barré, photo, catégorie interne, disponibilité). JAMAIS le
  contact téléphonique, JAMAIS les coordonnées du site (SC-013). C'est la SEULE
  surface qui échappe au principe VIII — exactement le périmètre que FR-011
  autorise.
- `GET /prestataires/plaque/{jeton}` — sous SESSION VALIDE (extracteur `Auth`,
  AUCUN rôle particulier) : `{ prestataire_id, valide }`, rien d'autre.

Neutralité (FR-017) : un id inconnu, un prospect et un suspendu rendent la MÊME
réponse `404 { code: "prestataire_indisponible" }` — indistinguables, sans photo
ni motif. La résolution de plaque, elle, répond `valide: false` avec l'id pour un
jeton connu de prestataire suspendu (FR-016 : la révocation doit être OBSERVABLE),
mais ne sert aucune autre donnée. Boutique fermée ≠ indisponible : la fiche est
servie en lecture seule avec horaires et réouverture (FR-029).

**Rationale** : FR-011 dit que SEULE la consultation de FR-027 échappe à la
protection par rôle — et la résolution n'a aucun consommateur public réel : les
tests et le scan en course (QRC) sont authentifiés, et le scan hors contexte
d'un passant passe par l'URL `mefali.ci/v/{vendor_id}` imprimée sur la plaque
(fiche publique du cycle WEB), pas par la résolution du jeton. L'exception VIII
reste donc limitée à la consultation, documentée au Complexity Tracking au même
titre que `/config?zone=` (cycle 002) et les URLs présignées (cycle 003) — la
plaque reste un canal d'acquisition (cadrage §3.1, §5.3).

**Alternatives considered** :
- Résolution PUBLIQUE (design initial du plan) → élargissait l'exception au
  principe VIII sans consommateur public réel et contredisait la lettre de
  FR-011. Rejetée à l'analyse (finding C1).
- `200 { indisponible: true }` pour un suspendu sur la fiche → distinguerait
  suspendu (200) d'inexistant (404), fuite d'information. Rejeté.

---

## R10 — Fenêtre glissante des signalements : évaluation À L'ÉCRITURE, aucun cron

**Decision** : le masquage automatique est évalué dans la transaction de chaque
signalement ACCEPTÉ :

```sql
SELECT count(DISTINCT coursier_compte_id) FROM prestataires.signalement_rupture
WHERE article_id = $1 AND recu_le > now() - make_interval(days => $fenetre)
```

Si le compte ≥ seuil ET l'article est disponible → bascule `disponible=false`
(source `coursier`, `automatique=true`) dans la même transaction, avec son
événement. Les signalements sur un article DÉJÀ en rupture sont enregistrés et
comptés sans changement d'état (edge case de la spec) — c'est ce qui fait que la
remise en vente par le vendeur est re-masquée au signalement éligible suivant
(FR-041) : la fenêtre porte encore le seuil, le prochain signalement re-déclenche.
Les signalements sortis de la fenêtre ne comptent plus par construction de la
requête. Aucun réarmement du compteur à la remise en vente. Idempotence du rejeu :
`id` = UUID client, `INSERT … ON CONFLICT (id) DO NOTHING` (patron des adresses du
cycle 003) — un rejeu ne recompte ni ne re-bascule.

**Rationale** : la fenêtre glissante se lit, elle ne se maintient pas ; tout
vieillissement se teste par `UPDATE … SET recu_le = …` en SQL brut (patron du
cycle 003 pour la purge des repères vocaux).

**Alternatives considered** : compteur matérialisé sur l'article + job de
décrément → double vérité, cron, dérive possible. Rejeté.

---

## R11 — Rattachement de compte : idempotence et rôle vendeur déjà porté

**Decision** : `POST /admin/prestataires/{id}/rattachements` dans UNE transaction :
(0) REFUS (409) si le prestataire n'est pas à l'état `agree` — FR-007 rattache un
compte vérifié « à un prestataire AGRÉÉ » et aucun rôle vendeur n'existe avant
l'agrément (amendement du 2026-07-18, analyse A1) ;
(1) `INSERT INTO prestataires.rattachement_compte … ON CONFLICT DO NOTHING` ;
(2) si le compte ne porte pas déjà le rôle vendeur à l'état `valide`,
`PgComptes::decider_role(tx, compte, Vendeur, Attribuer, admin, None)` (∅ →
valide, l'agrément vaut validation) ; s'il le porte déjà (rattaché à un autre
prestataire), AUCUNE écriture de rôle et aucun événement `role.attribue` — le
rejeu et le multi-rattachement n'échouent jamais (FR-007). Le détachement
(`DELETE`) supprime la ligne de rattachement SANS toucher au rôle : les capacités
dérivent du rattachement + de l'état du prestataire (FR-008), un rôle sans
rattachement n'autorise rien (edge case de la spec). La garde des endpoints
vendeur est un helper d'API : `Auth::exiger_role(Vendeur)` puis vérification
`rattachement(compte, prestataire)` puis `statut = 'agree'` — trois refus
distincts, zéro cascade.

**Rationale** : réutilise la machine à états du cycle 003 SANS la redéfinir (la
transition `Attribuer` n'est légale que depuis ∅ — l'éviter quand le rôle existe
est la seule lecture idempotente possible), et matérialise la clarification
« aucune cascade, un seul état fait foi ».

**Alternatives considered** : suspendre le rôle vendeur à la suspension du
prestataire → échec transactionnel dès qu'un rôle n'est pas à l'état attendu,
rejeu au rétablissement — exactement le piège que la clarification ferme. Rejeté.

---

## R12 — Deux surfaces d'écriture (vendeur, admin) sur un domaine unique

**Decision** : les capacités de pilotage existent en DEUX groupes d'endpoints —
`/vendeur/prestataires/{id}/…` (garde R11) et `/admin/prestataires/{id}/…`
(`exiger_role(Admin)`, sans condition de rattachement) — qui appellent les MÊMES
méthodes de domaine, lesquelles reçoivent `source: SourceBascule` (`vendeur` |
`admin`) et `acteur: Uuid`. La source et l'auteur sont tracés sur la ligne (
colonnes `…_par`, `…_le`, `source`) ET dans le payload de l'événement (FR-037,
SC-009). Un article mis en rupture par l'Admin ne peut être remis en vente que par
l'Admin (FR-041) : la garde lit `source = 'admin' AND disponible = false`.

**Rationale** : précédent du cycle 003 (`/moi/*` vs `/admin/comptes/*`) — les
gardes diffèrent, la journalisation admin est explicite, et les handlers restent
minces (annotation + garde + délégation).

**Alternatives considered** : un seul groupe d'endpoints acceptant les deux rôles
→ gardes conditionnelles dans chaque handler, source déduite au lieu d'affirmée,
contrat moins lisible pour les écrans ADM à venir. Rejeté.

---

## R13 — Devise des montants : copiée de la zone à l'écriture, vérifiée à chaque écriture

**Decision** : chaque montant (article, prix figé) est stocké `bigint` unités
mineures + colonne `devise` (ISO 4217). À la création/modification d'un article,
la devise est LUE de la zone du prestataire (`ConfigurationZones::devise`) et
posée par le serveur — jamais fournie par le client. La contrainte
`CHECK (prix_barre_unites IS NULL OR prix_barre_unites > prix_unites)` porte
FR-023 au niveau du schéma : la base elle-même refuse un prix barré ≤ prix, quelle
que soit la surface d'écriture (SC-006).

**Rationale** : principe III (entiers + ISO 4217, jamais de flottant) ; la
contrainte en base rend la violation impossible même par un chemin d'écriture
futur.

**Alternatives considered** : devise implicite (colonne absente, « c'est du
XOF ») → contredit le principe III et le multi-zone à venir. Rejeté.

---

## R14 — Extension vendeur : table + trait de lecture séparés du prestataire

**Decision** : la spécialisation est une table d'extension
`prestataires.vendeur (prestataire_id PK/FK)` créée à la création du prestataire
(au MVP, toutes les catégories actives sont des catégories de vente) ; les
articles la référencent, jamais le prestataire directement. Côté code, DEUX traits
de lecture exposés par le crate :

```rust
#[async_trait] pub trait Prestataires: Send + Sync {   // l'entité générale
    async fn commandable(&self, prestataire: Uuid) -> Result<Commandabilite, ErreurPrestataires>;
    async fn resoudre_jeton(&self, jeton: &str) -> Result<Option<ResolutionPlaque>, ErreurPrestataires>;
    async fn fiche_publique(&self, prestataire: Uuid) -> Result<Option<FichePublique>, ErreurPrestataires>;
    async fn prestataires_pilotables(&self, compte: Uuid) -> Result<Vec<Uuid>, ErreurPrestataires>;
}
#[async_trait] pub trait Vendeurs: Send + Sync {       // la spécialisation MVP
    async fn articles_commandables(&self, prestataire: Uuid) -> Result<Vec<ArticleCommandable>, ErreurPrestataires>;
}
```

`PgPrestataires` implémente les deux. Les cycles avals consomment : QRC →
`resoudre_jeton` ; CMD → `commandable`, `articles_commandables`, la méthode
inhérente `figer_prix` ; WEB → `fiche_publique` ; CRS → `prestataires_pilotables`
(rien ce cycle). AUCUNE méthode de `Prestataires` ne suppose l'existence d'un
catalogue — un artisan de phase N implémentera un autre trait à côté de
`Vendeurs`, sans migration (constitution, principe II ; cadrage §11.13).

**Rationale** : la séparation en deux traits est la forme opposable de
« prestataire ≠ vendeur » — un consommateur qui ne dépend que de `Prestataires` ne
peut structurellement rien supposer du catalogue.

**Alternatives considered** : un trait unique avec méthodes optionnelles
(`Option<Catalogue>`) → chaque consommateur devrait gérer l'absence, et rien
n'empêcherait un crate partagé de supposer le vendeur. Rejeté.

---

## R15 — Seeds : activation posée directement, catégories des prestataires seedés

**Decision** : `backend/seeds/30_prestataires.sql` (prestataires, sites, chartes,
plaques — UUID et jetons FIGÉS) et `35_articles.sql` (articles + disponibilités),
rejouables par `ON CONFLICT … DO UPDATE` avec horodatages littéraux, N'ÉMETTANT
AUCUN événement (précédent des cycles 002/003, FR-054). Trois prestataires de
Tiassalé : « Étal Tantie Affoué » (restauration, sans compte rattaché — cas
nominal), « Boutique Kofi » (boutique_superette, compte Kofi du seed 20 rattaché),
un troisième en `prospect` (pour exercer l'agrément à la main). Les seeds posent
DIRECTEMENT `zones.activation_categorie.actif_auto = true` pour `restauration` et
`boutique_superette` à Tiassalé (`ON CONFLICT … DO UPDATE SET actif_auto = true` —
monotone à la hausse, n'écrase aucun forçage), sans passer par le recalcul de
FR-009 : c'est ce que FR-054 exige, et c'est ce qui rend les prestataires seedés
commandables (SC-012) alors que 1 à 2 prestataires n'atteignent pas les seuils
réels (8 et 3). Les quatre clés de zone de R8 sont ajoutées au seed
`10_zones_tiassale.sql` (les seeds sont vivants et convergents, contrairement aux
migrations).

**Rationale** : FR-054 verbatim ; le README des seeds annonçait déjà
`30_vendeurs.sql`/`35_articles.sql` — les noms sont alignés sur le crate
(`30_prestataires.sql`).

**Alternatives considered** : seeder 8 restaurants pour franchir le seuil réel →
volume de seed artificiel, et le recalcul resterait interdit aux seeds de toute
façon. Rejeté.

---

## R16 — Événements du cycle et taxonomie produit MET-01

**Decision** : 18 types d'événements outbox (liste exhaustive et payloads en
data-model.md §6), à DÉCLARER dans `docs/taxonomie-evenements.md` AVANT
implémentation (FR-051, précédent 002/003). Convention `<entite>.<action>`,
entité au singulier, participe passé sans accents : `prestataire.cree`,
`prestataire.agree`, `prestataire.suspendu`, `prestataire.retabli`,
`prestataire.corrige`, `prestataire.modifie`, `charte.deposee`,
`rattachement.cree`, `rattachement.supprime`, `site.statut_boutique_change`,
`site.horaires_modifies`, `article.cree`, `article.modifie`,
`article.retire_du_catalogue`, `article.remis_au_catalogue`,
`article.mis_en_rupture`, `article.remis_en_vente`, `signalement_rupture.recu`.
Minimisation (FR-052) : aucun nom, aucun contact, aucune coordonnée GPS dans les
payloads — identifiants, slugs, listes de noms de CHAMPS modifiés, booléens.

**Taxonomie produit (FR-053, MET-01)** : le module MET (ingestion `/events`)
n'existe pas encore ; ce cycle DÉCLARE, dans une nouvelle sous-section « Taxonomie
produit (MET-01) — déclarations en attente d'ingestion » de
`docs/taxonomie-evenements.md`, les événements produit du parcours vendeur V1/V2 :
`vendeur_boutique_bascule`, `vendeur_pause_demarree`, `vendeur_pause_prolongee`,
`vendeur_article_bascule_dispo`, `vendeur_article_cree`,
`vendeur_prix_modifie` (propriétés standard zone/catégorie/rôle/version_app).
AUCUNE émission côté app ce cycle — la déclaration satisfait la DoD §0.4 point 4,
l'émission arrive avec MET-02.

**Rationale** : le registre outbox est le précédent établi ; pour MET-01, déclarer
sans émettre est la seule lecture compatible avec « prêt ≠ construit » (aucun
endpoint d'ingestion n'existe).

**Alternatives considered** : émettre les événements produit vers l'outbox serveur
→ confondrait deux taxonomies que le cadrage §10.9 sépare (produit vs opérations).
Rejeté.

---

## R17 — Écrans V1/V2 : insertion, moules Riverpod, composants

**Decision** :
- **Insertion** : la branche `RolePro.vendeur` de `InterfacePro.build()`
  (`apps/mefali_pro/lib/roles/interface_pro.dart`) rend désormais
  `InterfaceVendeur(etat: etat)` — nouveau shell portant une `NavigationBar` M3 à
  DEUX destinations (Boutique = V1, Articles = V2 ; PAS d'onglet Commandes ni de
  compteur du jour — hors périmètre, la spec l'exclut). `RouteurRoles`, `_Bascule`
  (rendue en tête par le shell), `EcranEtatDemande` et le comportement de
  `PiedPro` ne sont PAS modifiés (FR-046) ; `PiedPro` est rendu en fin de contenu
  de l'onglet Boutique (l'accès déconnexion/appareils reste à un scroll).
- **Moules** (constitution XII) : `Boutique` = `AsyncNotifier<BoutiqueData>`
  (`@riverpod` nu, autoDispose — chargement serveur + mutations
  `AsyncValue.guard`, calqué sur `MesAdresses`) ; `MesArticles` =
  `AsyncNotifier<List<ArticleVendeur>>` (idem). Le prestataire piloté = premier
  de `GET /vendeur/prestataires` (MVP mono-prestataire ; aucune sélection de site
  nulle part — FR-019). L'état de FORMULAIRE de la fiche article (steppers,
  brouillon non soumis) reste LOCAL au widget — jamais providerifié. `retry:
  pasDeRetry` reste posé sur le conteneur, pas par provider.
- **Composants** : `formaterMontant(int unites, String devise)` → « 1 500 FCFA »
  (espace fine insécable U+202F, tokens.md) dans un NOUVEAU
  `mefali_core/lib/src/format/montant.dart` (le client en aura besoin au cycle
  CMD) ; `InterrupteurBoutique` (96 px, deux moitiés) et `BasculeStock` (84×44,
  vert/rouge plein, libellé sous le pouce) restent LOCAUX à `mefali_pro`
  (`lib/vendeur/composants.dart`) — promotion vers `mefali_core/src/components/`
  seulement quand un second consommateur existera (précédent
  `CarteMefali`/`PuceStatut`). V2 ajoute une section repliée « Articles retirés »
  (absente de la maquette mais exigée par FR-055 : le vendeur DOIT pouvoir
  remettre au catalogue) ; le bandeau « N clients seront prévenus » de la maquette
  n'est PAS construit (VND-09, hors périmètre).
- **i18n** : clés `proBoutique…` / `proArticle…` dans
  `apps/mefali_pro/lib/l10n/app_fr.arb` (FR-047).

**Rationale** : chaque choix reprend le patron livré aux cycles 003/004 (rapport
d'exploration) ; les durées 30 min/1 h/2 h et le pas de +30 min sont des
constantes d'app MVP (assumption de la spec — absentes du Récapitulatif).

**Alternatives considered** : go_router / navigation par routes nommées →
l'app n'en a pas ; introduire un routeur pour deux onglets contredirait « rien
hors périmètre ». Rejeté.
