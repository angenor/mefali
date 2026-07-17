#!/usr/bin/env bash
# Accord mécanique des dépendances des 3 paquets Flutter (SC-008, cycle 004).
#
# Deux vérifications, aucun réseau :
#   1. Toute dépendance présente dans PLUSIEURS des 3 pubspec.lock y est figée à
#      la MÊME version (riverpod: 3.3.2 compris). La résolution fraîche dérive
#      (uuid 4.5.3 → 4.6.0) et casserait l'accord ; la CI ne fait que
#      `flutter pub get` (respecte le lock), ce script le prouve.
#   2. Le pin riverpod_lint est IDENTIQUE dans les 3 analysis_options.yaml.
#      riverpod_lint est un plugin de l'outil d'analyse déclaré HORS pubspec :
#      il n'apparaît dans AUCUN lockfile (grep -c riverpod_lint pubspec.lock → 0),
#      ce script est son SEUL gel (R1, contracts/ci-apps.md règle 9).
#
# Un désaccord NOMME le coupable et sort non-nul. Aucun réglage de confort ne le
# contourne : le seul geste autorisé est de ré-accorder les versions.
set -euo pipefail

# Racine du dépôt = parent du répertoire scripts/ (robuste au working-directory).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LOCKS=(
  "apps/packages/mefali_core/pubspec.lock"
  "apps/mefali_pro/pubspec.lock"
  "apps/mefali_client/pubspec.lock"
)
OPTS=(
  "apps/packages/mefali_core/analysis_options.yaml"
  "apps/mefali_pro/analysis_options.yaml"
  "apps/mefali_client/analysis_options.yaml"
)
PIN_ATTENDU="3.1.4"   # riverpod_lint — pin EXACT, gel hors lockfile

echec=0

# ── 1. Accord des versions communes aux lockfiles ───────────────────────────
# awk : en-tête de paquet = 2 espaces + nom + ':' + fin de ligne (ancré, pour ne
# JAMAIS confondre avec une sous-clé de description à 6 espaces) ; version = ligne
# 'version:' à 4 espaces qui suit. Émet des lignes « <paquet> <version> <lock> ».
extraire() {
  awk -v lock="$1" '
    /^  [a-z0-9_]+:[ \t]*$/ { pkg=$1; sub(/:$/,"",pkg); next }
    /^    version:/ && pkg!="" {
      v=$2; gsub(/"/,"",v); print pkg" "v" "lock; pkg=""
    }
  ' "$ROOT/$1"
}

tous=""
for lock in "${LOCKS[@]}"; do
  tous+="$(extraire "$lock")"$'\n'
done

# Pour chaque paquet, toutes les versions vues doivent être identiques.
desaccords="$(printf '%s' "$tous" | awk '
  NF==3 { versions[$1]=versions[$1] $2 " " ; sources[$1]=sources[$1] $3 "(" $2 ") " ; if (!seen[$1 SUBSEP $2]++) distinct[$1]++ }
  END {
    for (p in distinct) if (distinct[p] > 1) printf "  %-28s %s\n", p, sources[p]
  }
' | sort)"

if [ -n "$desaccords" ]; then
  echo "✗ DÉSACCORD de versions entre lockfiles (SC-008) :"
  echo "$desaccords"
  echec=1
else
  n="$(printf '%s' "$tous" | awk 'NF==3{print $1}' | sort -u | wc -l | tr -d ' ')"
  echo "✓ Versions accordées entre les 3 lockfiles ($n paquets, 0 désaccord)."
fi

# ── 2. Pin riverpod_lint identique dans les 3 analysis_options.yaml ─────────
pins=""
for opt in "${OPTS[@]}"; do
  # La ligne 'version:' du bloc riverpod_lint (sous plugins:).
  pin="$(awk '
    /^  riverpod_lint:/ { f=1; next }
    f && /version:/ { v=$2; gsub(/"/,"",v); print v; exit }
    /^[a-z]/ && f { f=0 }
  ' "$ROOT/$opt")"
  printf "    %-45s riverpod_lint = %s\n" "$opt" "${pin:-ABSENT}"
  pins+="$pin"$'\n'
  if [ "$pin" != "$PIN_ATTENDU" ]; then
    echo "✗ $opt : pin riverpod_lint = '${pin:-ABSENT}', attendu $PIN_ATTENDU."
    echec=1
  fi
done
distinct_pins="$(printf '%s' "$pins" | sort -u | grep -c .)"
if [ "$distinct_pins" = "1" ] && [ "$echec" = "0" ]; then
  echo "✓ Pin riverpod_lint identique ($PIN_ATTENDU) dans les 3 analysis_options.yaml."
fi

if [ "$echec" != "0" ]; then
  echo ""
  echo "Ré-accorder les versions (flutter pub add incrémental, JAMAIS pub upgrade)"
  echo "ou aligner le pin riverpod_lint. Ne PAS contourner (FR-032, SC-008)."
  exit 1
fi
echo ""
echo "Accord des locks : OK."
