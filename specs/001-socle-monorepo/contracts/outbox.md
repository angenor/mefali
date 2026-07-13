# Contrat — Outbox (crate `socle`)

Interface exposée aux crates de domaine à partir de ce cycle. Table et
invariants : voir `../data-model.md` §1.

## Écriture (dans la transaction de la transition)

```rust
/// Écrit un événement dans la MÊME transaction que la transition d'état.
/// Prend obligatoirement une transaction ouverte — jamais un pool — pour
/// rendre l'atomicité impossible à contourner (constitution VI).
pub async fn ecrire_evenement(
    tx: &mut sqlx::PgTransaction<'_>,
    evenement: NouvelEvenement<'_>,
) -> Result<Uuid, OutboxError>;

pub struct NouvelEvenement<'a> {
    pub type_evenement: &'a str,   // clé de docs/taxonomie-evenements.md
    pub entite_type: &'a str,
    pub entite_id: Uuid,
    pub payload: serde_json::Value,
    pub survenu_le: DateTime<Utc>,
}
```

## Consommation (worker de publication)

```rust
/// Un consommateur (notifications, métriques…) reçoit chaque événement
/// AU MOINS une fois. Il DOIT être idempotent (dédoublonnage par `id`).
#[async_trait]
pub trait ConsommateurOutbox: Send + Sync {
    fn nom(&self) -> &'static str;
    async fn consommer(&self, evenement: &EvenementPublie) -> Result<(), ConsommationError>;
}

/// Démarré par le binaire `api` (tâche tokio) : lit par lots
/// (FOR UPDATE SKIP LOCKED), distribue aux consommateurs enregistrés,
/// marque `publie_le`, incrémente `tentatives` en cas d'échec.
pub struct WorkerOutbox { /* pool, consommateurs, intervalle, taille de lot */ }
```

## Garanties contractuelles

| Garantie | Détail |
|---|---|
| Atomicité | Événement présent ssi la transaction de la transition a commité |
| Ordre | Par `id` UUIDv7 (ordre temporel) — ordre strict non garanti entre lots ; les consommateurs ne doivent pas en dépendre |
| Livraison | At-least-once ; jamais de perte (l'événement reste en base tant que non publié) |
| Idempotence | À la charge du consommateur, dédoublonnage par `id` |
| Échec | `tentatives`++, `derniere_erreur` renseignée, re-tentative au lot suivant |

## Ce cycle

- Type d'événement de test : `socle.ping` (technique, hors taxonomie produit).
- Consommateur de test en mémoire pour les tests d'intégration.
- `docs/taxonomie-evenements.md` créé avec la structure des propriétés
  standard (zone, catégorie, rôle, version d'app — cadrage §10.9), sans
  événement produit (ils arrivent avec les parcours utilisateur, constitution VI).
