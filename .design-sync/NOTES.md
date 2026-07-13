# Notes de synchro Mefali Design

- **2026-07-12 — Amorçage guidelines-only.** Ce dépôt ne contient aucun code de composant
  (pas de `package.json`, ni Storybook, ni `dist/`). Import initial fait à partir de la seule
  spécification `docs/design/Mefali_DESIGN.md`.
- **Projet cible** : « Mefali Design System » — `f0b9e5ab-3b8a-476c-9e2a-82cac6c7a135`
  (https://claude.ai/design/p/f0b9e5ab-3b8a-476c-9e2a-82cac6c7a135). Créé neuf lors de cette synchro.
- **Contenu uploadé** : `README.md` (conventions injectées dans l'agent de design), `styles.css`
  (tokens CSS + vocabulaire `.mf-*` fidèle à la spec), `tokens/tokens.json`,
  `guidelines/Mefali_DESIGN.md` (spec source).
- **Pas d'ancre `_ds_sync.json`** : shape guidelines-only, aucun rendu vérifiable à hasher.
  C'est volontaire — la prochaine synchro re-vérifiera tout, ce qui est correct.
- **Décisions authorées (non issues de la spec, à revoir si un vrai code arrive)** :
  - Teintes `*-tint` dérivées (échelle ~100 des couleurs de base) pour fonds de chips/badges/bandeaux.
  - Classes de base `.mf-btn-primary`, `.mf-card`, `.mf-chip`, `.mf-offline-banner`, `.mf-amount`
    écrites depuis les descriptions §5 de la spec (composants « canoniques » non encore codés).
- **2026-07-12 (maj) — Ajout §10 « Cible d'implémentation ».** La spec a gagné une section
  imposant Flutter Material 3 thémé (`ColorScheme.fromSeed(#F97316)`), Inter + Material Symbols
  Rounded embarqués, identité unique Android+iOS via `.adaptive` dans `mefali_core`, console admin
  Nuxt aux mêmes tokens. Répercuté dans `guidelines/`, le README (bloc « Cible d'implémentation » +
  précision icônes) et `tokens.json` (bloc `implementation`). `styles.css` inchangé (tokens identiques).
- **Le jour où un dépôt de composants Mefali existe** : relancer `/design-sync` en le pointant sur
  ce dépôt (shape `storybook` ou `package`). La fondation restera compatible ; les composants réels
  compilés remplaceront/compléteront le vocabulaire `.mf-*` de `styles.css`.
