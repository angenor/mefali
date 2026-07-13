# Mefali — Design System

Plateforme de services de proximité (premier vertical : livraison), Tiassalé, Côte d'Ivoire.
Identité : **chaleureux, fiable, direct** — une app de quartier professionnelle, dense en
information utile, jamais décorative.

> **Statut de cet import.** Aucun composant compilé n'existe encore. Ce projet fournit la
> **fondation de tokens + un vocabulaire on-brand** (`styles.css`) et la **spec fondatrice**
> (`guidelines/Mefali_DESIGN.md`). Construis les écrans avec ces tokens et ces classes ; ne
> réinvente pas de couleurs, de tailles de texte ni de rayons.

## Contexte utilisateur — dicte chaque arbitrage
Android d'entrée de gamme, en plein soleil, utilisateur pressé et parfois peu lettré.
→ Contraste élevé (AAA sur tout texte critique : montants, codes, statuts). Texte **jamais < 16px**.
→ Un **pictogramme à côté de chaque libellé important** (icônes **Material Symbols Rounded**,
24 dp, un seul style dans tout le produit). Français simple, verbes d'action
(« Scanner le QR », « Payez 2 100 FCFA »). Jargon interdit à l'écran (« checkout », « dispatch »).
→ Les **actions principales vivent en bas d'écran** (usage à une main, sur moto), jamais en haut.
→ Le **montant est toujours l'élément le plus visible** de son bloc. FCFA en entier, espace fine
comme séparateur de milliers : `5 800 FCFA`.

## Idiome de style : tokens CSS + classes `.mf-*`
Tout passe par `styles.css` (lis-le avant de styler). N'invente pas de valeurs — utilise :

**Couleurs** (`var(--…)`) : `--primary` `--primary-dark` `--success` `--danger` `--warning`
`--surface` `--background` `--text` `--text-muted` `--border`, plus les fonds teintés
`--primary-tint` `--success-tint` `--danger-tint` `--warning-tint`.
Sémantique : primary = actions/marque ; success = cash/confirmé ; danger = erreur/à avancer ;
warning = escalade/hors-ligne.

**Typo** (`var(--font-…)` ou classes) : `.mf-display` (montants, code livraison) · `.mf-title`
(titres d'écran) · `.mf-heading` (cartes, vendeurs) · `.mf-body` (courant) · `.mf-caption` (méta).

**Espace / rayon** : grille 8px via `--space-1..5`, marge d'écran `--screen-margin` (16px) ;
`--radius-card` (16) · `--radius-button` (12) · `--radius-chip` (plein). Une seule élévation
`--elevation-1`. Pas de dégradés.

**Composants de base fournis** (compose-les, ajoute ta glue de layout avec les tokens) :
`.mf-btn-primary` (pleine largeur, 56px, picto à gauche) · `.mf-card` · `.mf-chip`
(+ `--outline` `--success` `--danger` `--warning`) · `.mf-offline-banner` ·
`.mf-amount` (+ `--collect` / `--advance`, avec `.mf-amount__label` / `.mf-amount__value`).

## États obligatoires — chaque écran
Normal · chargement (**squelettes**, jamais de spinner plein écran) · vide (message + action) ·
erreur réseau (réessayer) · **hors-ligne** (bandeau `.mf-offline-banner` + fonctions locales
actives : panier, QR/code de réception, checklist et scans coursier). Ce qui reste utilisable
hors connexion doit rester **visiblement actif**.

## Cadres
Mobile : **Android 360 × 800**, une colonne. Console admin : desktop 1440, densité élevée
assumée, **mêmes tokens**.

## Cible d'implémentation — contraint la maquette (§10)
Les écrans seront construits en **Flutter Material 3 thémé** (`ColorScheme.fromSeed(#F97316)`
ajusté aux tokens ci-dessus, `TextTheme` Inter, rayons §4). Conçois donc **Material-compatible** :
composants standards thémés (bottom nav, cartes, champs, chips, dialogs) — **tout écart à Material
est un widget custom à justifier**. Police Inter et icônes Material Symbols Rounded embarquées
(pas de chargement runtime, réseau intermittent). **Identité Mefali unique sur Android ET iOS**
(pas de variante Cupertino des écrans à maquetter) : les conventions iOS passent par les
constructeurs Flutter `.adaptive`, encodés une fois dans `mefali_core`. La console admin (Nuxt)
réutilise les **mêmes tokens et les mêmes icônes**.

## À ne pas faire
Pas de mode sombre (MVP). Pas d'illustrations décoratives ni d'animations gratuites.
Pas de texte < 16px. Pas d'action principale en haut d'écran mobile. Pas de montant en petit.
Pas d'écran qui devient inutilisable hors connexion sans l'indiquer.

## Exemple idiomatique
```html
<!-- Écran de collecte : contexte en body, montant en display success, action en bas -->
<main style="min-height:100dvh;display:flex;flex-direction:column;
             padding:var(--screen-margin);gap:var(--space-3)">
  <section class="mf-card" style="padding:var(--space-3)">
    <div class="mf-amount mf-amount--collect">
      <span class="mf-amount__label">Encaissez chez Étal Adjoua</span>
      <span class="mf-amount__value">5 800 FCFA</span>
    </div>
  </section>
  <span class="mf-chip mf-chip--success">Collecté ✓ 14:32</span>
  <div style="margin-top:auto">
    <button class="mf-btn-primary">✓ Confirmer l'encaissement</button>
  </div>
</main>
```
