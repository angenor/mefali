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
| `10_zones_tiassale.sql` | CI > Tiassalé, 8 transports, 6 catégories, devise/drapeaux/seuils, 6 activations (UUID fixes) | ZON |
| `20_comptes.sql` | Premier admin (UUID fixe, `client`+`admin` valides) + paramètres de zone du module : indicatif par défaut, rétention du repère vocal, durée max de note vocale, version ARTCI | CPT |
| `30_prestataires.sql` | 3 prestataires de Tiassalé (Tantie Affoué agréée sans compte, Kofi agréé + compte rattaché, un prospect complet) : sites, horaires, chartes, plaques et activations figées (UUID/jetons/horodatages fixes) | VND |
| `35_articles.sql` | Catalogues + disponibilités par site (attiéké, garba, bissap, promo Kofi, un article en rupture) | VND |
| `40_tarification.sql` | Grilles de tarif | TRF *(à venir)* |

Chaque cycle **ajoute ses fichiers** ici ; le runner ne change pas.

- `50_tarification_tiassale.sql` — knobs tarifaires de Tiassalé (bornes de
  marge, arrondi, supplément pluie, routage, grille d'effort) et **grille en
  vigueur v1** : à pied 100 (≤ 800 m), vélo 150 (≤ 2 km), moto 200 + 50/km
  au-delà de 2 km, plafond 500 — marge 50 partout (la marge 0 du lancement vient
  du drapeau `gratuite_commissions`, pas d'une règle). `effort.plafond_eclatement_m`
  reste volontairement NON seedé (dormant, à calibrer en promo). Cycle TRF 007,
  T027 ; specs/007-tarification-moteur-effort/data-model.md §2.
- `60_commandes_parametres.sql` — paramètres du cycle de vie d'une commande :
  catégories périssables, longueur minimale du repère écrit, essais du code de
  remise, délais et plafonds de substitution, période de position, plafonds cash
  et seuil d'escalade de la file d'attente. Cycle CMD 008.
- `70_dispatch_parametres.sql` — les **18 paramètres** du pipeline de dispatch :
  7 au niveau PAYS (durée de vie du pool, compte à rebours d'offre et
  exclusivité qui le couvre, non-réponses franches, fenêtre d'acceptation,
  valeur neutre, bruit GPS) et 11 au niveau VILLE (rayon, grille d'avance par
  note, les 4 poids du classement, plafond d'inactivité, seuils de broadcast et
  de réassignation). Trois paramètres existants sont RÉUTILISÉS et jamais
  redéclarés : `suivi.position_periode_s`, `commande.escalade_attente_coursier_s`
  et `transport.actifs`. Cycle DSP 009 ;
  specs/009-dispatch-assignation-auto/data-model.md §4.
