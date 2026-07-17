# Taxonomie des événements Mefali

Registre des événements métier du journal outbox (TRX-02, constitution VI).
Le journal est la **matière première des métriques** — aucun KPI manuel :
tout indicateur dérive d'événements enregistrés ici.

Ce document résout le TODO de la constitution (principe VI). Le cycle socle
n'émet aucun événement produit ; le registre se remplit avec les parcours
utilisateur des cycles suivants.

## Convention de nommage

`<entite>.<action>` — entité au singulier, action au participe passé.

Exemples (à créer par leurs cycles, **non émis ce cycle**) :
`commande.creee`, `commande.terminee`, `livraison.affectee`,
`coursier.disponibilite_changee`, `paiement.encaisse`, `avis.depose`.

## Propriétés standard du `payload` (cadrage §10.9)

Chaque événement porte, quand elles existent, les propriétés transverses qui
permettent de segmenter les métriques sans retraitement :

| Propriété | Description |
|---|---|
| `zone` | Zone concernée (héritage de configuration — cycle ZON) |
| `categorie` | Catégorie de service / vertical (ex. `resto_courses`) |
| `role` | Rôle de l'acteur à l'origine de la transition (client, coursier, vendeur, admin) |
| `version_app` | Version de l'app émettrice (client / pro) |

Les propriétés spécifiques à l'événement s'ajoutent à côté de ces clés standard.

## Format d'enregistrement

Colonnes de `outbox.evenement` (data-model.md §1) : `type_evenement`,
`entite_type`, `entite_id`, `payload` (jsonb), `survenu_le`. L'`id` est un
UUIDv7 (ordre temporel) ; l'idempotence des consommateurs se fait par cet `id`.

## Registre

| Type d'événement | Entité | Émis par | Statut |
|---|---|---|---|
| `socle.ping` | `socle` | tests d'intégration outbox | **Technique** — hors taxonomie produit, sert à valider le cycle de vie de l'outbox |
| `zone.parametre_modifie` | `zone` | `PgZones::definir_parametre` (cycle ZON) | **Produit** — modification d'un paramètre de zone |
| `categorie.forcage_change` | `activation_categorie` | `PgZones::forcer_categorie` (cycle ZON) | **Produit** — changement du mode de forçage admin |
| `categorie.activation_changee` | `activation_categorie` | `PgZones::forcer_categorie` / `recalculer_activation` (cycle ZON) | **Produit** — bascule de l'état EFFECTIF d'activation |
| `compte.cree` | `compte` | `PgComptes::creer_compte` (cycle CPT) | **Produit** — inscription d'un numéro vérifié + consentement |
| `session.creee` | `session` | `PgComptes::creer_session` (cycle CPT) | **Produit** — ouverture d'une session d'appareil |
| `session.revoquee` | `session` | `PgComptes::revoquer_session` / `tourner_refresh` (cycle CPT) | **Produit** — fin de session (locale, à distance, réutilisation détectée) |
| `role.demande` | `attribution_role` | `PgComptes::soumettre_dossier_coursier` (cycle CPT) | **Produit** — demande de rôle coursier (in-app) |
| `role.attribue` | `attribution_role` | `PgComptes::attribuer_role` (cycle CPT) | **Produit** — attribution directe par un admin (vendeur à l'agrément, admin) |
| `role.valide` | `attribution_role` | `PgComptes::decider_role` (cycle CPT) | **Produit** — demande acceptée par un admin |
| `role.refuse` | `attribution_role` | `PgComptes::decider_role` (cycle CPT) | **Produit** — demande refusée (motif requis) |
| `role.suspendu` | `attribution_role` | `PgComptes::decider_role` (cycle CPT) | **Produit** — rôle suspendu (motif requis) |
| `role.retabli` | `attribution_role` | `PgComptes::decider_role` (cycle CPT) | **Produit** — rôle rétabli après suspension |
| `dossier_coursier.soumis` | `dossier_coursier` | `PgComptes::soumettre_dossier_coursier` (cycle CPT) | **Produit** — dépôt du dossier (première fois ou re-soumission) |
| `adresse.enregistree` | `adresse` | `PgComptes::enregistrer_adresse` (cycle CPT) | **Produit** — adresse enregistrée après livraison |
| `adresse.modifiee` | `adresse` | `PgComptes::modifier_adresse` (cycle CPT) | **Produit** — renommage ou nouveau repère |
| `adresse.supprimee` | `adresse` | `PgComptes::supprimer_adresse` (cycle CPT) | **Produit** — suppression (soft delete) |
| `adresse.repere_vocal_purge` | `adresse` | `PgComptes::purger_reperes_vocaux` (cycle CPT) | **Produit** — repère vocal purgé après la rétention de zone |

### Événements du cycle ZON (002 — zones & configuration héritée)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que la mutation
(constitution VI, research R9). `entite_id` = identifiant de la ligne mutée.
Le journal « qui/quand/avant/après » exigé par ADM-05 est porté par ces
événements — pas de table d'audit parallèle. Les seeds (chargement initial)
n'émettent aucun événement.

| Type | `entite_type` | Payload spécifique (en plus des propriétés standard) |
|---|---|---|
| `zone.parametre_modifie` | `zone` | `zone` (id), `cle`, `avant` (`null` si création), `apres`, `acteur` |
| `categorie.forcage_change` | `activation_categorie` | `zone` (id), `categorie` (slug), `avant`, `apres` (modes de forçage), `acteur` |
| `categorie.activation_changee` | `activation_categorie` | `zone` (id), `categorie` (slug), `avant`, `apres` (état effectif booléen), `origine` (`seuil` \| `forcage`), `nb_vendeurs` (si `origine=seuil`), `seuil` |

`categorie.forcage_change` est émis à CHAQUE forçage ; `categorie.activation_changee`
seulement quand l'état effectif (`actif`) bascule — les deux dans la même
transaction que l'UPDATE. Les métriques d'activation dériveront de ces
événements (aucun KPI manuel).

### Événements du cycle CPT (003 — comptes, authentification OTP et rôles)

Écrits via `socle::ecrire_evenement` dans la MÊME transaction que la transition
(constitution VI, research R10). Le registre est posé AVANT l'implémentation.

**Identification des entités.** `attribution_role` a une clé primaire composite
`(compte_id, role)` et donc aucun `id` de substitution : ses événements portent
`entite_id` = `compte_id`, le rôle concerné vivant dans le payload. Idem pour
`dossier_coursier`, dont la clé primaire EST `compte_id` (1:1 avec le compte).

**Minimisation (ARTCI).** Les payloads ne portent AUCUNE donnée nominative ni
position GPS : ni numéro de téléphone, ni libellé d'adresse, ni `lat`/`lng`.
Les repères sont décrits par des booléens de présence. Le journal des décisions
admin exigé par FR-014 (qui / quand / motif) est porté par `decide_par` +
`motif` + `survenu_le`, doublé par les colonnes de `attribution_role` — aucune
table d'audit parallèle (patron du cycle 002).

| Type | `entite_type` | `entite_id` | Payload spécifique (en plus des propriétés standard) |
|---|---|---|---|
| `compte.cree` | `compte` | `compte.id` | `zone`, `role` (`client` — l'attribution automatique de l'inscription y est INCLUSE, data-model §4), `consentement_version`, `consentement_le` |
| `session.creee` | `session` | `session.id` | `zone`, `compte`, `appareil_plateforme` (`android` \| `ios`), `origine` (`verification_otp` \| `inscription`) |
| `session.revoquee` | `session` | `session.id` | `zone`, `compte`, `origine` (`locale` \| `a_distance` \| `reutilisation_detectee`), `revoquee_par` (compte de l'appareil demandeur ; `null` si détection automatique) |
| `role.demande` | `attribution_role` | `compte_id` | `zone`, `compte`, `role` (`coursier`), `avant` (`null` \| `refuse`), `apres` (`en_attente`) |
| `role.attribue` | `attribution_role` | `compte_id` | `zone`, `compte`, `role` (`vendeur` \| `admin`), `avant` (`null`), `apres` (`valide`), `decide_par`, `motif` |
| `role.valide` | `attribution_role` | `compte_id` | `zone`, `compte`, `role`, `avant` (`en_attente`), `apres` (`valide`), `decide_par`, `motif` (facultatif) |
| `role.refuse` | `attribution_role` | `compte_id` | `zone`, `compte`, `role`, `avant` (`en_attente`), `apres` (`refuse`), `decide_par`, `motif` (REQUIS) |
| `role.suspendu` | `attribution_role` | `compte_id` | `zone`, `compte`, `role`, `avant` (`valide`), `apres` (`suspendu`), `decide_par`, `motif` (REQUIS) |
| `role.retabli` | `attribution_role` | `compte_id` | `zone`, `compte`, `role`, `avant` (`suspendu`), `apres` (`valide`), `decide_par`, `motif` (facultatif) |
| `dossier_coursier.soumis` | `dossier_coursier` | `compte_id` | `zone`, `compte`, `role` (`coursier`), `vehicules` (slugs déclarés), `re_soumission` (booléen — `true` si le dossier repart d'un `refuse`) |
| `adresse.enregistree` | `adresse` | `adresse.id` | `zone`, `compte`, `a_repere_texte`, `a_repere_vocal`, `livraison_origine` (`null` tant que CMD/CRS ne le posent pas — PROVISION) |
| `adresse.modifiee` | `adresse` | `adresse.id` | `zone`, `compte`, `champs` (noms des champs modifiés : `libelle`, `repere_texte`, `repere_vocal`) |
| `adresse.supprimee` | `adresse` | `adresse.id` | `zone`, `compte` |
| `adresse.repere_vocal_purge` | `adresse` | `adresse.id` | `zone`, `compte`, `retention_jours` (paramètre de zone appliqué), `derniere_utilisation_le` |

**Ce qui n'émet PAS d'événement outbox** (research R10) :

- les demandes et vérifications d'OTP — aucune entité durable ne transitionne ;
  l'entonnoir d'inscription relèvera de la taxonomie produit du cycle MET ;
- la rotation du refresh — ce n'est pas une transition d'état (data-model §4) ;
  seule la révocation qu'une réutilisation déclenche en émet une ;
- les seeds — chargement initial, pas une transition (patron du cycle 002).

*(Les autres événements produit — `commande.*`, `livraison.*`, `paiement.*`… —
sont ajoutés à ce registre par les cycles qui les émettent, avec leurs parcours.)*
