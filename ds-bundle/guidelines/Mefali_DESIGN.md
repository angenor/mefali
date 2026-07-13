# DESIGN.md — Système de design Mefali

*Asset fondateur à uploader dans Claude Design (création du design system, avant tout projet). Marque : Mefali — plateforme de services de proximité, premier vertical livraison, Tiassalé, Côte d'Ivoire.*

## 1. Identité

Chaleureux, fiable, direct. Une app de quartier professionnelle : dense en information utile, jamais en décoration. L'utilisateur type est sur un Android d'entrée de gamme, en plein soleil, parfois peu lettré, souvent pressé.

## 2. Couleurs (tokens)

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | #F97316 | Actions principales, marque, éléments actifs |
| `primary-dark` | #C2570C | Pressed/hover, texte sur fond clair primaire |
| `success` | #15803D | Cash, confirmations, statut « collecté », toggle ouvert |
| `danger` | #DC2626 | Erreurs, montants à avancer, suspension, toggle fermé |
| `warning` | #B45309 | Alertes d'escalade, litiges en cours, hors-ligne |
| `surface` | #FFFFFF | Cartes |
| `background` | #FAFAF7 | Fond d'écran |
| `text` | #171717 | Texte principal |
| `text-muted` | #525252 | Texte secondaire (jamais en dessous de ce contraste) |
| `border` | #E5E5E5 | Séparateurs, contours de carte |

Règle absolue : contraste AAA sur tout texte porteur d'information critique (montants, codes, statuts) — l'app se lit en plein soleil. Jamais de texte clair sur fond clair.

## 3. Typographie

Police : Inter (repli Roboto). Échelle :
- `display` 36–40, bold — montants d'action (« Encaissez 5 800 FCFA »), code de livraison.
- `title` 22, semibold — titres d'écran.
- `heading` 18, semibold — titres de carte, noms de vendeurs.
- `body` 16, regular — texte courant (jamais en dessous de 16).
- `caption` 13, medium — métadonnées (horodatage, distances).

Montants : FCFA en entier, sans décimales, séparateur de milliers par espace fine (5 800 FCFA). Le montant est toujours l'élément le plus visible de son bloc.

## 4. Espacements, rayons, élévation

Grille de 8 px (4 px autorisé en intra-composant). Rayon 16 px pour les cartes, 12 px pour les boutons, plein pour les chips. Ombres légères (une seule élévation), pas de dégradés décoratifs. Marges d'écran : 16 px.

## 5. Composants canoniques

1. **Bouton primaire** : pleine largeur, 56 px de haut, fond `primary`, libellé bold 18, picto à gauche. Toute cible tactile ≥ 48 dp. Les actions principales vivent en bas d'écran (usage à une main, sur moto).
2. **Carte vendeur** : photo 16:9, nom `heading`, note ★ + nombre d'avis, délai moyen, badge statut (OUVERT vert / FERMÉ rouge), badge promotionnel « Livraison gratuite » ou « Livraison gratuite dès X FCFA » (fond `primary` clair).
3. **Ligne article** : photo carrée 64, nom, prix `heading` ; prix barré éventuel en `text-muted` barré à côté ; état rupture = ligne grisée + bouton « Me prévenir au retour » ; stepper quantité − / +.
4. **Stepper d'états de commande** : horizontal, 4 étapes en langage clair, étape courante en `primary`, collectes affichées « 2/3 ✓ ».
5. **Chip de statut d'arrêt** : « À collecter » (contour), « Collecté ✓ 14:32 » (fond `success` clair), « Indisponible » (fond `danger` clair).
6. **Bandeau hors-ligne** : barre fine `warning` clair sous l'en-tête — « Hors connexion — vos actions seront synchronisées ». Ne bloque jamais l'écran ; ce qui reste utilisable reste visiblement actif.
7. **Bouton audio** : rond 48 dp, picto lecture + durée (« 0:12 »), pour les notes vocales de repère — toujours accompagné du libellé « Écouter le repère ».
8. **Montant d'action** : bloc pleine largeur, `display`, contexte en `body` au-dessus (« Payez à Étal Adjoua »), couleur `success` (à encaisser) ou `danger` (à avancer).

## 6. Iconographie & langage

Pictogrammes systématiques à côté de chaque libellé important (public partiellement lettré) : trait plein, style unique, 24 dp. Français simple, phrases courtes, verbes d'action (« Scanner le QR », « Payez 2 100 FCFA »). Jamais de jargon (« checkout », « dispatch » interdits à l'écran).

## 7. États obligatoires (chaque écran)

Normal · chargement (squelettes, jamais de spinner plein écran) · vide (message + action) · erreur réseau (réessayer) · **hors-ligne** (bandeau §5.6 + fonctions locales actives : panier, QR/code de réception, checklist et scans coursier).

## 8. Cadres

Apps mobiles : Android 360 × 800, une colonne. Console admin : desktop 1440, densité élevée assumée (poste de pilotage), mêmes tokens.

## 9. À ne pas faire

Pas de mode sombre au MVP. Pas d'illustrations décoratives ni d'animations gratuites. Pas de texte < 16 px. Pas d'action principale en haut d'écran mobile. Pas de montant en petit. Pas d'écran qui devient inutilisable hors connexion sans l'indiquer.

## 10. Cible d'implémentation (contrainte pour la maquette ET le développement)

- **Flutter Material 3 thémé** : `ColorScheme.fromSeed(#F97316)` ajusté aux tokens du §2, `TextTheme` en Inter (échelle §3), rayons §4. Les maquettes restent **Material-compatibles** : composants standards thémés (bottom nav, cartes, champs, chips, dialogs) — tout écart à Material est un widget custom à justifier.
- **Polices embarquées** : fichiers Inter (.ttf, licence OFL) inclus dans les apps — jamais de chargement de police au runtime (réseau intermittent).
- **Icônes : Material Symbols Rounded**, via police embarquée, 24 dp, un seul style dans tout le produit. La console admin Nuxt utilise les mêmes tokens et les mêmes icônes.
- **Stratégie plateforme : une seule identité Mefali sur Android et iOS** (pas de variante Cupertino des écrans — les apps de livraison imposent leur marque sur les deux OS). Les conventions système iOS sont obtenues via Flutter, encodées une fois dans `mefali_core` : constructeurs `.adaptive` (Switch, AlertDialog, indicateurs de progression, icône retour), transitions de page et physique de défilement Cupertino, geste de retour par balayage, pickers date/heure système. iOS n'est livré que « quand la demande existe » (cadrage §10.1) ; rien à maquetter en double aujourd'hui.
