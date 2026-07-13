# Mefali — Design Tokens

Plateforme de services de proximité (livraison), Tiassalé, Côte d'Ivoire.
Identité : **chaleureux, fiable, direct**. Densité utile, jamais décorative.

Contexte cible : Android d'entrée de gamme, plein soleil, utilisateur pressé, parfois peu lettré.
Cible d'implémentation : Flutter Material 3 thémé (`ColorScheme.fromSeed(#F97316)`), console admin Nuxt.

---

## Couleurs

| Token | Valeur | Usage |
|---|---|---|
| `--primary` | `#F97316` | Actions principales, marque, éléments actifs |
| `--primary-dark` | `#C2570C` | Pressed/hover, texte primaire sur fond clair |
| `--success` | `#15803D` | Cash, confirmations, « collecté », toggle ouvert |
| `--danger` | `#DC2626` | Erreurs, montants à avancer, suspension, fermé |
| `--warning` | `#B45309` | Escalade, litiges en cours, hors-ligne |
| `--surface` | `#FFFFFF` | Cartes |
| `--background` | `#FAFAF7` | Fond d'écran |
| `--text` | `#171717` | Texte principal |
| `--text-muted` | `#525252` | Texte secondaire (contraste plancher) |
| `--border` | `#E5E5E5` | Séparateurs, contours de carte |

### Teintes claires (fonds de chips / badges / bandeaux — texte reste foncé, AAA)

| Token | Valeur |
|---|---|
| `--primary-tint` | `#FFEDD5` |
| `--success-tint` | `#DCFCE7` |
| `--danger-tint` | `#FEE2E2` |
| `--warning-tint` | `#FEF3C7` |

---

## Typographie

Famille : `'Inter', 'Roboto', system-ui, -apple-system, sans-serif`. Plancher : **jamais < 16px**.

| Token / classe | Style | Usage |
|---|---|---|
| `--font-display` / `.mf-display` | 700 40px/1.1 | Montants d'action, code livraison (36–40) |
| `--font-title` / `.mf-title` | 600 22px/1.3 | Titres d'écran |
| `--font-heading` / `.mf-heading` | 600 18px/1.35 | Titres de carte, noms vendeurs |
| `--font-body` / `.mf-body` | 400 16px/1.5 | Texte courant (plancher 16px) |
| `--font-caption` / `.mf-caption` | 500 13px/1.4 | Métadonnées : horodatage, distances |

Montant : FCFA en entier, espace fine comme séparateur de milliers → `5 800 FCFA`.

---

## Espacement — grille 8px (4px autorisé en intra-composant)

| Token | Valeur |
|---|---|
| `--space-1` | 4px |
| `--space-2` | 8px |
| `--space-3` | 16px (marge d'écran standard) |
| `--space-4` | 24px |
| `--space-5` | 32px |
| `--screen-margin` | 16px |

## Rayons

| Token | Valeur |
|---|---|
| `--radius-card` | 16px |
| `--radius-button` | 12px |
| `--radius-chip` | 999px (plein) |

## Élévation & cibles tactiles

| Token | Valeur |
|---|---|
| `--elevation-1` | `0 1px 3px rgba(23,23,23,0.10)` (une seule élévation, pas de dégradés) |
| `--tap-min` | 48px (toute cible tactile ≥ 48 dp) |
| `--button-height` | 56px (bouton primaire pleine largeur) |

---

## Composants de base (`.mf-*`)

- `.mf-btn-primary` — pleine largeur, 56px, fond primary, picto à gauche. **Actions principales en bas d'écran.**
- `.mf-card` — surface, rayon 16, contour border, élévation légère.
- `.mf-chip` (+ `--outline` `--success` `--danger` `--warning`) — statut, plein, fond teinté + texte foncé.
- `.mf-offline-banner` — barre fine warning clair, ne bloque jamais l'écran.
- `.mf-amount` (+ `--collect` / `--advance`, avec `.mf-amount__label` / `.mf-amount__value`) — montant d'action, toujours l'élément le plus visible.

---

## Règles d'or

1. Contraste élevé (AAA sur montants, codes, statuts). Texte jamais < 16px.
2. Un pictogramme (Material Symbols Rounded, 24dp, un seul style) à côté de chaque libellé important.
3. Actions principales en bas d'écran (usage à une main, sur moto).
4. Le montant est toujours l'élément le plus visible de son bloc.
5. Chaque écran gère : normal · chargement (squelettes) · vide · erreur réseau · hors-ligne.
6. Ce qui reste utilisable hors connexion reste visiblement actif.

## À ne pas faire

Pas de mode sombre (MVP). Pas d'illustrations décoratives ni d'animations gratuites.
Pas de texte < 16px. Pas d'action principale en haut d'écran mobile. Pas de montant en petit.
Pas d'écran inutilisable hors connexion sans l'indiquer.

## Cadres

- Mobile : Android **360 × 800**, une colonne.
- Console admin : desktop **1440**, densité élevée, mêmes tokens.
