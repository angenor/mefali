# Amendement de constitution — préparation (FR-040, SC-012)

⚠ **Édition manuelle de `.specify/memory/constitution.md` INTERDITE** (gouvernance).
Ce document PRÉPARE l'amendement ; il est appliqué via `/speckit.constitution`.

## Version

**1.0.1 → 1.1.0** — bump **MINOR** : ajout d'un principe (aucun retrait, aucune
redéfinition incompatible). Versionnage sémantique de la Governance : MINOR =
ajout de principe.

## Rapport d'impact (propagation aux templates dépendants)

- `.specify/memory/constitution.md` : ajout du principe **XII** ; ajout de
  « Riverpod » à la liste nommée du principe **X** ; en-tête de version et
  « Last Amended » mis à jour.
- `.specify/templates/` : les gabarits `plan`/`spec`/`tasks` référencent la
  constitution par principe numéroté — le nouveau principe XII s'ajoute sans
  invalider les références existantes (I–XI inchangés). Aucun gabarit ne code en
  dur le nombre de principes.
- `CLAUDE.md` : la règle correspondante y est ajoutée en parallèle (FR-041,
  T029) — même règle, sans la contredire.
- Aucune migration, aucun client, aucun code applicatif n'est concerné : la
  constitution DÉCRIT une pratique déjà livrée par ce cycle (elle ne la crée pas).

## Ajout à la liste nommée du principe X (Versions à jour puis figées)

Liste actuelle : « Rust, Actix, sqlx, utoipa, Flutter, Shorebird, Nuxt 4,
Postgres, Redis, Garage, OSRM, Metabase ». **Ajouter « Riverpod »** (chaîne
codegen : `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`,
`build_runner`, `riverpod_lint`) — figée par lockfile, sauf `riverpod_lint`
(hors lockfile, gel par script `verifier-accord-locks.sh`, écart X consigné).

## Texte du nouveau principe

### XII. Gestion d'état des apps Flutter — Riverpod codegen

- Tout **porteur d'état** des apps Flutter est un **provider GÉNÉRÉ par
  annotation** (`@riverpod` / `@Riverpod`) ; son `.g.dart` est commité à côté de
  sa bibliothèque, gardé par un contrôle de dérive, et **JAMAIS édité à la main**
  (même règle que `clients/dart`, principe I).
- L'**injection se fait par la PORTÉE** (`ProviderScope` / `overrides`), jamais
  par constructeur ni par conteneur global (anti-pattern explicite de Riverpod).
- L'**état strictement local** — contrôleurs de saisie, focus, comptes à rebours
  ergonomiques, brouillons non soumis, ressources natives liées au widget —
  **reste où il est**, jamais providerifié.
- **`retry: pasDeRetry` sur TOUTE création de portée** : le retry automatique de
  Riverpod 3 (10 essais) rejouerait des requêtes qu'aucun comportement n'attend.
- La **durée de vie est EXPLICITE et ARGUMENTÉE** : `@Riverpod(keepAlive: true)`
  pour les porteurs de processus, `@riverpod` nu (autoDispose) pour les états
  jetables. Aucun lint ne garde cette opposition — elle relève des tests et de la
  revue.
- **DEUX MOULES, nommés** : `Notifier<Etat…>` pour les porteurs à sémantique
  propre (session, rôles) ; `AsyncNotifier` pour les chargements de liste
  (adresses, appareils). **Ne JAMAIS uniformiser derrière `AsyncValue`** : cela
  détruirait les deux sémantiques opposées de chargement (un écran de démarrage
  qui ne réapparaît pas / un squelette qui réapparaît).
- L'analyse statique passe par **`dart analyze`** (JAMAIS `flutter analyze`, qui
  ne charge pas le plugin `analysis_server_plugin`) ; `riverpod_lint` est actif,
  ses 3 règles INFO escaladées en `error`.

## Non-régression à vérifier (prérequis, pas livrable d'US6)

- TRX-08 (P1) présent dans `docs/user-stories-v2.md`, module « Transverse &
  infrastructure ».
- Tableau §0.6 de `docs/user-stories-v2.md` inchangé par ce cycle.
