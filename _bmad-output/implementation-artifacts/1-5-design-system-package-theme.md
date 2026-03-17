# Story 1.5: Design System Package (Theme)

Status: done

---

## Story

En tant que **developpeur**,
Je veux **un package mefali_design complet avec theme marron light+dark**,
Afin que **les 4 apps partagent un look consistant conforme au design system**.

## Criteres d'Acceptation

1. **AC1**: Quand une app importe `MefaliTheme.light()`, le theme M3 s'applique avec la palette marron complete (primary, secondary, tertiary, error, surface + tous les `on*` variants)
2. **AC2**: Quand une app importe `MefaliTheme.dark()`, le theme M3 dark s'applique avec les couleurs inversees conformes au tableau de la spec UX
3. **AC3**: `ThemeMode.system` est configure dans les 4 apps et suit le reglage systeme de l'appareil
4. **AC4**: Contraste WCAG AA (>= 4.5:1) respecte pour les combinaisons texte/fond en light et dark mode
5. **AC5**: Tous les composants M3 utilises (FilledButton, OutlinedButton, TextButton, Card, BottomNavigationBar, TabBar, AppBar, TextField, SnackBar, Chip, Badge) ont leurs themes configures dans MefaliTheme
6. **AC6**: Une `ThemeExtension` custom expose les couleurs `success` (non-standard M3) accessible via `Theme.of(context).extension<MefaliCustomColors>()`
7. **AC7**: Touch targets minimum 48x48dp appliques sur tous les boutons et elements interactifs
8. **AC8**: `melos run analyze` et `melos run test` passent sans erreur, incluant les tests du package mefali_design

## Taches / Sous-taches

- [x] **T1** Completer la palette de couleurs M3 (AC: #1, #2, #4)
  - [x] T1.1 Ajouter les tokens manquants dans `mefali_colors.dart` : `seedColor`, `onSuccess`, `successContainer`, `onSuccessContainer`, `warning` (light + dark). Les tokens secondary/tertiary/outline sont auto-generes par `ColorScheme.fromSeed()`.
  - [x] T1.2 Verifier le contraste WCAG AA (>= 4.5:1) pour chaque paire `on*/container` — tests WCAG inclus
  - [x] T1.3 Documenter chaque couleur avec son usage prevu — docstrings ajoutees

- [x] **T2** Creer la `ThemeExtension` pour les couleurs custom (AC: #6)
  - [x] T2.1 Creer `lib/theme/mefali_custom_colors.dart` avec `MefaliCustomColors extends ThemeExtension<MefaliCustomColors>`
  - [x] T2.2 Exposer `success`, `onSuccess`, `successContainer`, `onSuccessContainer`, `warning` (light + dark)
  - [x] T2.3 Implementer `copyWith()` et `lerp()` pour les transitions de theme
  - [x] T2.4 Enregistrer l'extension dans `MefaliTheme.light()` et `.dark()` via `extensions: [...]`

- [x] **T3** Completer la configuration des composants M3 dans MefaliTheme (AC: #5, #7)
  - [x] T3.1 `OutlinedButton.styleFrom()` — bordure marron, min 48dp hauteur
  - [x] T3.2 `TextButton.styleFrom()` — min 48dp hauteur
  - [x] T3.3 `CardTheme` — elevation 1 light / 0 dark, shape arrondi 12dp
  - [x] T3.4 `NavigationBarThemeData` — remplace BottomNavigationBar (M3), hauteur 64dp, indicateur primaryContainer
  - [x] T3.5 `TabBarTheme` — couleurs marron, indicateur
  - [x] T3.6 `InputDecorationTheme` — labels au-dessus (floatingLabelBehavior: always), bordure marron
  - [x] T3.7 `SnackBarThemeData` — floating, shape arrondi
  - [x] T3.8 `ChipThemeData` — shape arrondi 8dp, selectedColor primaryContainer
  - [x] T3.9 `BadgeTheme` — smallSize 8, largeSize 16
  - [x] T3.10 `ElevatedButton` + `IconButton` — touch target 48dp aussi

- [x] **T4** Integrer le theme dans les 4 apps (AC: #3)
  - [x] T4.1 `apps/mefali_b2c/lib/app.dart` — deja configure avec MefaliTheme (story 1-1)
  - [x] T4.2 `apps/mefali_b2b/lib/app.dart` — deja configure
  - [x] T4.3 `apps/mefali_livreur/lib/app.dart` — deja configure
  - [x] T4.4 `apps/mefali_admin/lib/app.dart` — deja configure

- [x] **T5** Ecrire les tests (AC: #8)
  - [x] T5.1 Tests unitaires : `MefaliTheme.light()` et `.dark()` retournent un `ThemeData` M3 valide (8 tests)
  - [x] T5.2 Tests couleurs : chaque token de `MefaliColors` correspond a la spec (7 tests)
  - [x] T5.3 Tests typographie : tailles minimales body >= 14sp, labels >= 12sp (3 tests)
  - [x] T5.4 Tests `MefaliCustomColors` : extension accessible, copyWith, lerp (6 tests)
  - [x] T5.5 Tests composants : chaque component theme est configure (11 tests)
  - [x] T5.6 Tests contraste WCAG AA : primary/white, surface/onSurface light+dark >= 4.5:1 (3 tests)
  - [x] T5.7 Tests touch target : 5 types de boutons ont `minimumSize >= 48` (5 tests)

- [x] **T6** Mettre a jour les exports (AC: #8)
  - [x] T6.1 Ajouter l'export de `MefaliCustomColors` dans `mefali_design.dart`
  - [x] T6.2 `dart analyze` passe avec 0 issues

## Dev Notes

### IMPORTANT : Code existant — NE PAS recreer

Le package `mefali_design` existe deja avec une base fonctionnelle creee lors du story 1-1. **Tu dois ETENDRE ce code, pas le remplacer.**

Fichiers existants a modifier (pas recreer) :
- `packages/mefali_design/lib/mefali_colors.dart` — palette basique, ajouter tokens manquants
- `packages/mefali_design/lib/mefali_theme.dart` — theme light/dark basique, enrichir les component themes
- `packages/mefali_design/lib/mefali_typography.dart` — OK tel quel, ne pas toucher sauf bug
- `packages/mefali_design/lib/mefali_design.dart` — ajouter nouveaux exports
- `packages/mefali_design/test/mefali_design_test.dart` — enrichir les tests existants

Fichier a creer :
- `packages/mefali_design/lib/theme/mefali_custom_colors.dart` — ThemeExtension pour success

### Palette de couleurs — Spec UX exacte

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `primary` | `#5D4037` (Brown 700) | `#D7CCC8` (Brown 100) | Boutons principaux, app bar |
| `primaryContainer` | `#D7CCC8` | `#5D4037` | Backgrounds cartes, selections |
| `onPrimary` | `#FFFFFF` | `#3E2723` | Texte sur boutons marron |
| `onPrimaryContainer` | `#3E2723` | `#D7CCC8` | Texte sur fond marron clair |
| `surface` | `#FAFAFA` | `#1C1B1F` | Background ecran principal |
| `onSurface` | `#212121` | `#E6E1E5` | Texte body |
| `error` | `#B3261E` | `#EF9A9A` | Alertes, erreurs |
| `success` | `#4CAF50` | `#81C784` | "+350 FCFA", confirmations |

Les tokens `secondary`, `tertiary`, `outline`, `surfaceVariant` peuvent etre derives automatiquement par `ColorScheme.fromSeed()` — ne pas les hardcoder inutilement, laisser M3 les generer.

### Configuration composants M3 — Regles strictes

**Boutons (hierarchie UX) :**
- `FilledButton` = Primary CTA. Marron, full width, min 48dp. 1 seul par ecran. Verbe d'action.
- `OutlinedButton` = Secondary. Bordure marron, min 48dp.
- `TextButton` = Tertiaire. Min 48dp.
- `FilledButton` rouge = Danger (suppression). Utiliser `colorScheme.error`.

**Touch targets :** TOUS les elements interactifs >= 48x48dp. C'est critique pour Kone qui conduit une moto.

**Inputs :** Labels AU-DESSUS du champ (PAS en placeholder). Bordure marron. Erreur inline sous le champ.

**Cards :** Elevation 1 en light, elevation 0 en dark (surfaces M3).

**SnackBar :** Differents styles selon le type (success=vert, error=rouge persistant, warning=orange 5s).

### ThemeExtension — Pattern Flutter pour couleurs custom

Flutter M3 `ColorScheme` n'a pas de `success`. Utiliser `ThemeExtension` :

```dart
// theme/mefali_custom_colors.dart
@immutable
class MefaliCustomColors extends ThemeExtension<MefaliCustomColors> {
  final Color success;
  final Color onSuccess;

  const MefaliCustomColors({required this.success, required this.onSuccess});

  @override
  MefaliCustomColors copyWith({Color? success, Color? onSuccess}) {
    return MefaliCustomColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
    );
  }

  @override
  MefaliCustomColors lerp(MefaliCustomColors? other, double t) {
    if (other is! MefaliCustomColors) return this;
    return MefaliCustomColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }
}
```

Usage dans les apps :
```dart
final successColor = Theme.of(context).extension<MefaliCustomColors>()!.success;
```

### Integration dans les apps — Pattern exact

Chaque `main.dart` des 4 apps doit suivre ce pattern :

```dart
MaterialApp(
  title: 'mefali B2C', // ou B2B, Livreur, Admin
  theme: MefaliTheme.light(),
  darkTheme: MefaliTheme.dark(),
  themeMode: ThemeMode.system,
  // ...
)
```

Verifier que les apps n'ont PAS deja un theme hardcode. Si oui, le remplacer par `MefaliTheme`.

### Contraintes techniques cles

- **Pas de dependances externes** : le package ne depend que de `flutter` SDK. Pas de package de couleurs, pas de google_fonts.
- **Roboto est le default Flutter** : pas besoin de l'importer, il est inclus nativement.
- **Performance** : eviter les computations lourdes dans les getters de theme. Utiliser `const` partout ou possible.
- **Pas de business logic** dans mefali_design — uniquement presentation.
- **snake_case** pour les noms de fichiers. `PascalCase` pour les classes Dart.

### Project Structure Notes

Structure cible apres implementation :

```
packages/mefali_design/
  lib/
    mefali_design.dart          ← exports (modifier)
    mefali_colors.dart          ← palette complete (modifier)
    mefali_theme.dart           ← theme M3 complet (modifier)
    mefali_typography.dart      ← OK tel quel
    theme/
      mefali_custom_colors.dart ← NOUVEAU : ThemeExtension success
    components/
      .gitkeep                  ← vide pour le moment
  test/
    mefali_design_test.dart     ← enrichir (modifier)
```

Le dossier `components/` reste vide — les 10 composants custom (MefaliBottomSheet, RestaurantCard, etc.) seront implementes dans des stories ulterieures des epics 3, 4, 5.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 1, Story 1.5]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — UX-DR1, Section Palette, Section Composants M3]
- [Source: _bmad-output/planning-artifacts/architecture.md — Section Packages partages, Section Design System]
- [Source: _bmad-output/planning-artifacts/prd.md — NFR24 Crash rate, NFR1-7 Performance]

### Intelligence Story Precedente (1-4)

- Pattern de fichiers : les fichiers de migration suivent un naming sequentiel avec timestamps
- Conventions strictes : `snake_case` partout confirme en 1-4
- Les 30 tests existants doivent continuer a passer (`cargo test --workspace`)
- `melos run analyze` doit passer sans erreur pour le workspace Flutter

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- 43 tests passes (0 echecs)
- `dart analyze` : 0 issues
- `cargo test --workspace` : aucune regression backend

### Completion Notes List

- Palette enrichie avec `seedColor`, tokens success complets (container, onContainer), warning light/dark
- Les tokens secondary/tertiary/outline ne sont PAS hardcodes — generes automatiquement par `ColorScheme.fromSeed()` comme recommande par la spec
- `MefaliCustomColors` ThemeExtension creee avec presets `light` et `dark` const
- Theme factorise via `_buildTheme()` pour eviter la duplication entre light() et dark()
- 11 component themes configures : AppBar, FilledButton, OutlinedButton, TextButton, ElevatedButton, IconButton, Card, NavigationBar, TabBar, InputDecoration, SnackBar, Chip, Badge
- `NavigationBar` (M3) utilise a la place de `BottomNavigationBar` (Material 2)
- Touch target 48dp enforce sur les 5 types de boutons + `materialTapTargetSize: padded`
- T4 deja fait par story 1-1 — les 4 apps utilisent MefaliTheme dans app.dart
- Tests WCAG AA avec calcul sRGB correct (linearisation gamma 2.4)

### Change Log

- 2026-03-17 : Implementation complete du design system theme (T1-T6)
- 2026-03-17 : Code review — 1 MEDIUM corrige (test BadgeTheme manquant ajoute), 3 LOW notes. 43 tests passent.

### File List

- packages/mefali_design/lib/mefali_colors.dart (modifie)
- packages/mefali_design/lib/mefali_theme.dart (modifie)
- packages/mefali_design/lib/mefali_design.dart (modifie)
- packages/mefali_design/lib/theme/mefali_custom_colors.dart (nouveau)
- packages/mefali_design/test/mefali_design_test.dart (modifie)
