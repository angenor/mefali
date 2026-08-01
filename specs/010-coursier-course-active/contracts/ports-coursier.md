# Contrat — traits, structures et événements du crate `coursier` (cycle 010)

Le crate `coursier` est un **domaine** : il porte sqlx et son schéma
(`PgCoursier`), tout le reste passe par des traits doublables (constitution II).
Signatures indicatives — ce qui fait contrat, c'est la **forme** des ports et le
sens des issues.

Sens des dépendances, à ne jamais inverser :

```text
coursier ──▶ commandes        (lecture de course, port PreuvesEchec à implémenter)
coursier ──▶ qr               (empreinte de plaque, politique photo résolue)
coursier ──▶ prestataires     (nom, position, téléphone du vendeur)
commandes ─╳▶ coursier        JAMAIS — comme commandes ─╳▶ dispatch
```

---

## 1. Ce que `coursier` **implémente** pour les autres

### `commandes::PreuvesEchec` — la précondition que le cycle 008 attendait

```rust
#[async_trait]
impl commandes::PreuvesEchec for PgCoursier {
    /// Vrai si les TROIS preuves de la livraison sont réunies, selon les
    /// paramètres de la zone de la commande (FR-056, FR-057).
    async fn preuves_reunies(&self, livraison: Uuid) -> Result<bool, ErreurCommandes>;
}
```

C'est **le** branchement du cycle : la composition dans `backend/api` remplace
`Arc::new(commandes::PreuvesFixes::nouveau())` par
`Arc::new(depot_coursier.clone())`. À partir de là, un échec ne se déclare plus
jamais sans preuves — en test comme en production.

### `socle::ConsommateurOutbox` — le livre de caisse

```rust
#[async_trait]
impl socle::ConsommateurOutbox for CaisseOutbox {
    fn nom(&self) -> &'static str { "caisse" }
    async fn consommer(&self, e: &EvenementPublie) -> Result<(), ConsommationError>;
}
```

Second consommateur réel du produit (le premier, `DispatchOutbox`, date du cycle
009). Il ne réagit qu'à trois types et **ignore tout le reste** :

| Événement consommé | Écriture produite | Règle |
|---|---|---|
| `arret.collecte` | `avance` de `−montant_avance` | uniquement si `montant_avance > 0` |
| `livraison.livree` | `remboursement` de `+Σ avances` | **uniquement si `mode_paiement = cash`** (R10) |
| `indemnisation.due` | ligne `coursier.indemnisation` à l'état `demandee` | l'écriture de caisse n'arrive qu'à la **validation** |

Idempotence : `evenement_id UNIQUE`. Un lot rejoué par le worker n'écrit qu'une
fois — et une erreur laisse l'événement non publié, donc re-tenté (contrat
`socle`).

---

## 2. Ce que `coursier` **consomme**

### `commandes::ports::CourseCoursier` — NOUVEAU port, offert par `commandes`

```rust
#[async_trait]
pub trait CourseCoursier: Send + Sync {
    /// Course active complète d'un coursier : arrêts ordonnés, LIGNES par
    /// arrêt, client (repère, position, téléphone), secrets HACHÉS de remise,
    /// montant à encaisser, état du blocage. `None` si aucune course.
    async fn course_active(&self, coursier: Uuid)
        -> Result<Option<CourseComplete>, ErreurCommandes>;

    /// Montant total à encaisser, recalculé après substitutions (FR-023).
    async fn montant_a_encaisser(&self, livraison: Uuid)
        -> Result<Montant, ErreurCommandes>;

    /// Livraisons du jour civil de la zone dont la remise est validée
    /// (bandeau de gains, FR-091).
    async fn livrees_du_jour(&self, coursier: Uuid, jour: NaiveDate)
        -> Result<Vec<LivraisonLivree>, ErreurCommandes>;
}
```

Implémenté par `PgCommandes` ; double `CourseFixe` pour les tests de `coursier`
sans base de commandes — patron `ArretsFixes` / `PreuvesFixes` déjà en place.

### `coursier::ports::LitigesOuverts` — AVI-04 n'existe pas

```rust
#[async_trait]
pub trait LitigesOuverts: Send + Sync {
    /// Litiges rattachés à un coursier, avec leur état (FR-074).
    async fn litiges_du_coursier(&self, coursier: Uuid)
        -> Result<Vec<LitigeVu>, ErreurCoursier>;
}
/// Double par défaut, et **état exact du monde** tant qu'AVI n'est pas construit.
pub struct AucunLitige;
```

### `coursier::ports::PhotosPreuve` — stockage objet

Réutilise `socle::DepotObjets` (Garage / mémoire en test) — aucun nouveau port :
la photo de preuve suit le chemin de la photo de récupération du cycle 006.

### Pas d'arête `coursier → dispatch` : `/moi/journee` est composé dans `api`

Le bandeau de K1 mélange trois sources : les **gains** et les **avances**
viennent de `coursier`, le **plafond retenu** et le **taux d'acceptation** de
`dispatch`. Faire dépendre `coursier` de `dispatch` pour deux nombres créerait
une arête permanente entre deux domaines qui n'ont rien à se dire. La
**composition se fait dans `backend/api`**, qui détient déjà les deux dépôts —
exactement comme `PgQr` reçoit `PgCommandes` à la construction. Le handler
`GET /moi/journee` lit les deux et assemble ; aucun crate n'apprend l'existence
de l'autre.

---

## 3. Événements outbox — 7 nouveaux types

À déclarer dans `docs/taxonomie-evenements.md` **avant** implémentation
(constitution VI, FR-107). Aucun ne porte de secret ni de numéro (FR-007).

| Type | Entité | Émetteur | Charge utile |
|---|---|---|---|
| `preuves_echec.reunies` | `livraison` | `coursier::preuves` | `commande`, `appels_retenus`, `presence_s`, `photos`, `delai_depuis_arrivee_s` — l'**issue** déclarée des appels n'y figure pas : elle n'est pas un critère (R19) |
| `caisse.mouvement` | `ecriture_caisse` | `coursier::caisse` | `coursier`, `type`, `montant`, `devise`, `commande`, `arret`, `source` (`outbox` \| `admin`) |
| `indemnisation.validee` | `indemnisation` | `coursier::indemnisation` | `coursier`, `commande`, `montant`, `devise`, `litige`, `acteur` |
| `indemnisation.refusee` | `indemnisation` | `coursier::indemnisation` | `coursier`, `commande`, `montant`, `motif_cle`, `acteur` |
| `remise.code_debloque` | `commande` | `commandes::collecte` | `livraison`, `essais_avant`, `motif_cle`, `acteur` — **aucun code** |
| `depot.autorise` | `commande` | `commandes::creation` | `autorise` (booléen), `motif_cle`, `acteur` |
| `coursier.action_reconciliee` | `livraison` | `coursier::course` | `action` (`collecte` \| `transition` \| `remise` \| `echec`), `issue` (`rejouee` \| `refusee_definitivement`), `motif_cle`, `age_local_s` |

Deux événements **existants** sont réutilisés sans changement de forme :

- `appel.intention` — la taxonomie prévoit déjà `de: coursier` ; ce cycle est le
  premier à l'émettre avec cette valeur.
- `remise.code_epuise` — émis par `commandes::collecte::valider_remise` depuis le
  cycle 008 ; ce cycle lui donne enfin **un consommateur** (l'alerte
  d'exploitation, FR-044).

**Métriques** : aucun KPI manuel. Le taux d'échec avec preuves, la durée moyenne
de présence avant échec, l'exposition cash moyenne et le taux de remise hors
ligne se dérivent tous de ces événements (constitution VI).

---

## 4. Structures publiques du crate

```rust
pub struct CourseComplete { livraison_id, commande_id, etat, devise,
                            arrets: Vec<ArretComplet>, client: ClientCourse,
                            remise: RemisePreprovisionnee }
pub struct ArretComplet   { /* arrêt + lignes + empreintes plaque + téléphone */ }
pub struct LigneArret     { ligne_id, libelle, quantite, prix_unitaire_unites,
                            preference: PreferenceSubstitution, statut: StatutLigne }
pub struct RemisePreprovisionnee { empreinte_code, empreinte_jeton,
                                   essais_consommes, essais_max, code_bloque,
                                   montant_a_encaisser_unites, mode_paiement,
                                   seuils_preuves: SeuilsPreuves }
pub struct EtatPreuves    { appels: PreuveAppels, presence: PreuvePresence,
                            photos: PreuvePhotos, reunies: bool }
pub struct VueCaisse      { avance_en_cours_unites, courses_concernees,
                            avances_en_attente_reglement_unites,
                            historique: Vec<LigneHistorique>,
                            indemnisations: Vec<IndemnisationVue>,
                            litiges: Vec<LitigeVu>, devise }
pub struct VueJournee     { courses_livrees, gains_unites, plafond_retenu_unites,
                            reste_disponible_unites, taux_acceptation_pourcent,
                            note: Option<u16>, devise }
pub struct ExpositionCash { total_unites, devise, par_coursier: Vec<LigneExposition> }
```

Erreurs : `ErreurCoursier` porte ses **clés i18n** (patron `ErreurCommandes`) —
`coursier.preuves.incompletes`, `coursier.depot.non_autorise`,
`coursier.course.non_proprietaire`, `coursier.indemnisation.deja_decidee`,
`coursier.caisse.ecriture_immuable`.

---

## 5. Contrat côté app (`mefali_pro`) — ce qui doit rester vrai

| Règle | Vérifiée par |
|---|---|
| Toute action de course passe par la file locale **avant** le réseau | test widget « aucune action n'échoue hors ligne » |
| La vérification d'empreinte est **locale** et ne consulte jamais le réseau | test unitaire sur le vérificateur |
| Le compteur d'essais survit à la reconstruction de l'écran | test de provider (`Notifier`, `keepAlive`) |
| Aucun secret n'est écrit dans un journal Dart | revue + test de sérialisation |
| Le numéro de téléphone est effacé du cache à la clôture de la course | test de la base locale |
| Le bouton d'échec reste inactif tant que les 3 preuves ne sont pas réunies | test widget par combinaison (7 cas) |
