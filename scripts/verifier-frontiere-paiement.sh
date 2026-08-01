#!/usr/bin/env bash
# Vérifie MÉCANIQUEMENT la frontière fournisseur du cycle PAY 011.
#
# ── Ce que ce script défend ────────────────────────────────────────────────
#
# Le cadrage §10.7 laisse le choix de l'agrégateur OUVERT, et PAY-05 exige que
# ce choix reste défaisable. La spec en fait une mesure (SC-010, FR-003) : rien
# de ce qui est propre à un agrégateur ne doit franchir
# `backend/crates/paiements/src/fournisseur/`.
#
# Une frontière qu'on se contente d'affirmer se franchit au premier correctif
# pressé — un `if fournisseur == "…"` dans une règle métier, un nom de marque
# dans un message d'erreur, un moyen propriétaire dans une réponse d'API. Chacun
# est invisible en revue, et tous ensemble rendent la bascule impossible.
#
# ── Ce qu'il NE peut pas défendre ─────────────────────────────────────────
#
# Il cherche des CHAÎNES. Il ne verra pas une dépendance implicite à la forme
# d'une réponse, ni un couplage par le comportement. Il attrape la fuite la plus
# fréquente et la moins visible, pas toutes.
#
# Usage : ./scripts/verifier-frontiere-paiement.sh
# Sortie : 0 si la frontière tient, 1 sinon (avec les emplacements fautifs).

set -euo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE"

# Les agrégateurs cités par le cadrage comme candidats. La liste n'a pas à être
# exhaustive : elle nomme ceux qu'on a envisagés, donc ceux qu'un correctif
# pressé écrirait.
AGREGATEURS=(cinetpay paydunya bizao hub2)

# Moyens PROPRIÉTAIRES. Ils ont le droit d'exister dans le vocabulaire du
# DOMAINE — `paiements.moyen_paiement` les nomme, et FR-012 exige de savoir par
# quel moyen un client a payé. Ce qui est interdit, c'est qu'ils apparaissent
# dans le code du FOURNISSEUR hors de sa frontière, c'est-à-dire qu'une règle
# métier branche sur eux.
#
# Le contrôle porte donc sur les agrégateurs partout, et sur les moyens
# uniquement là où ils trahiraient un routage (voir §2).
MOYENS=(wave orange_money mtn_momo moov_money)

# Seul répertoire autorisé à porter le vocabulaire d'un fournisseur.
FRONTIERE="backend/crates/paiements/src/fournisseur"

echo "Frontière fournisseur (PAY-05, SC-010, FR-003)"
echo "  autorisé : $FRONTIERE/"
echo

fautes=0

# ── 1. Aucun nom d'agrégateur, nulle part hors de la frontière ────────────
#
# Y compris dans les tests, les commentaires et la documentation du dépôt : un
# nom de marque dans un commentaire devient un nom de marque dans le code au
# premier copier-coller.
#
# Exclusions, et leur justification :
#   - `specs/` et `docs/` : le cadrage et les documents de recherche CITENT les
#     candidats, c'est précisément leur rôle — ils instruisent un choix, ils ne
#     l'implémentent pas. Les exclure n'affaiblit rien : une décision écrite
#     dans un document ne crée aucun couplage de code.
#   - ce script lui-même, qui doit bien les nommer pour les chercher.
#   - `target/`, `.git/`, les lockfiles et les clients GÉNÉRÉS.
for nom in "${AGREGATEURS[@]}"; do
  trouve=$(grep -ril --binary-files=without-match "$nom" \
    --exclude-dir=.git \
    --exclude-dir=target \
    --exclude-dir=node_modules \
    --exclude-dir=build \
    --exclude-dir=.dart_tool \
    --exclude-dir=specs \
    --exclude-dir=docs \
    --exclude="verifier-frontiere-paiement.sh" \
    --exclude="Cargo.lock" \
    --exclude="pubspec.lock" \
    --exclude="pnpm-lock.yaml" \
    . 2>/dev/null | grep -v "^\./$FRONTIERE/" || true)

  if [ -n "$trouve" ]; then
    echo "✗ « $nom » apparaît hors de la frontière :"
    echo "$trouve" | sed 's/^/    /'
    fautes=$((fautes + 1))
  fi
done

# ── 2. Aucun moyen propriétaire dans une RÈGLE MÉTIER ─────────────────────
#
# Le domaine a le droit de NOMMER les moyens (enum, migration, i18n, réponses
# d'API) : FR-012 l'exige. Ce qui est interdit, c'est de BRANCHER dessus hors de
# la frontière — un `if moyen == Wave` est un routage par moyen, et le routage
# par moyen est explicitement de phase 2+ (FR-043, FR-113).
#
# On cherche donc les moyens dans les fichiers Rust du crate `paiements` HORS
# `fournisseur/`, et hors des endroits où les nommer est légitime :
# `modele.rs` (la définition de l'enum elle-même).
for moyen in "${MOYENS[@]}"; do
  trouve=$(grep -riln --binary-files=without-match "$moyen" \
    backend/crates/paiements/src \
    2>/dev/null \
    | grep -v "^backend/crates/paiements/src/fournisseur/" \
    | grep -v "^backend/crates/paiements/src/modele.rs$" \
    || true)

  if [ -n "$trouve" ]; then
    echo "✗ le moyen « $moyen » apparaît hors de la frontière et hors de modele.rs :"
    echo "$trouve" | sed 's/^/    /'
    echo "    (nommer un moyen est permis ; BRANCHER dessus est du routage —"
    echo "     phase 2+, FR-043)"
    fautes=$((fautes + 1))
  fi
done

# ── 3. La frontière existe toujours ───────────────────────────────────────
#
# Un contrôle qui passe parce que le répertoire a disparu ne contrôle rien.
if [ ! -d "$FRONTIERE" ]; then
  echo "✗ le répertoire de frontière $FRONTIERE n'existe plus"
  fautes=$((fautes + 1))
fi

echo
if [ "$fautes" -eq 0 ]; then
  echo "✓ Frontière fournisseur : OK — aucun nom d'agrégateur hors de $FRONTIERE/"
  exit 0
fi

echo "✗ Frontière fournisseur : $fautes violation(s)."
echo
echo "  Le choix de l'agrégateur doit rester DÉFAISABLE (PAY-05). Tout ce qui"
echo "  lui est propre — nom, vocabulaire, codes d'état, forme de signature —"
echo "  vit dans $FRONTIERE/ et nulle part ailleurs."
exit 1
