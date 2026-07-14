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

*(Les autres événements produit — `commande.*`, `livraison.*`, `paiement.*`… —
sont ajoutés à ce registre par les cycles qui les émettent, avec leurs parcours.)*
