# Seeds — jeu de démonstration (TRX-05)

Versionnés **à part** des migrations (constitution I). Chargés en UNE commande :

```bash
cargo run -p api --bin seed     # DATABASE_URL requis
```

## Fonctionnement

Le runner (`backend/api/src/bin/seed.rs`) ouvre **une seule transaction**, rejoue
les fichiers `NN_<module>.sql` **dans l'ordre**, puis commite (rollback si
interruption). Chaque fichier est **idempotent par construction** (upsert /
`CREATE ... IF NOT EXISTS` / `TRUNCATE`+`INSERT`) : re-seed → état identique,
zéro doublon (data-model.md §3).

## Ordre de chargement

| Fichier | Contenu | Cycle |
|---|---|---|
| `00_demo_marker.sql` | Marqueur du jeu de démo | socle |
| `10_zones.sql` | Zones de Tiassalé | ZON *(à venir)* |
| `20_comptes.sql` | Comptes de démo | CPT *(à venir)* |
| `30_vendeurs.sql`, `35_articles.sql` | Vendeurs agréés + catalogues | VND *(à venir)* |
| `40_tarification.sql` | Grilles de tarif | TRF *(à venir)* |

Chaque cycle **ajoute ses fichiers** ici ; le runner ne change pas.
