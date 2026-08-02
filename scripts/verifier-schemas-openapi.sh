#!/usr/bin/env bash
# Unicité MÉCANIQUE des noms de schéma OpenAPI déclarés par utoipa.
#
# ── Ce que ce script défend ────────────────────────────────────────────────
#
# Un type annoté `ToSchema` occupe un nom dans `components.schemas` de
# `openapi.json` : celui de son `#[schema(as = …)]`, ou à défaut son nom Rust.
# Quand DEUX types revendiquent le même nom, utoipa n'en garde qu'un. Le
# contrat décrit alors une forme, et la route en rend une autre.
#
# Ce n'est pas une hypothèse. Au cycle PAY 011, `vendeur_http::OffreLivraisonDto`
# et l'entrée de calcul de `admin_tarification_http` déclaraient tous deux
# `#[schema(as = OffreLivraisonVendeur)]` pour des formes sans rapport
# (`{offre, seuil_unites, message_cle}` contre `{toujours, au_dela}`). Le client
# Dart généré désérialisait la réponse avec le mauvais modèle : le vendeur
# lisait « Impossible de charger la boutique » sur un réglage POURTANT
# enregistré en base.
#
# Ce qui rend cette faute redoutable, c'est qu'aucun garde-fou existant ne la
# voit : `git diff --exit-code clients/` était VIDE et la CI verte. La spec
# était cohérente avec elle-même — elle décrivait simplement autre chose que ce
# que la route rendait. Elle a été trouvée à la main, sur un émulateur.
#
# ── Ce qu'il NE peut pas défendre ─────────────────────────────────────────
#
# Il lit du TEXTE, pas la sortie du macro-expanseur. Il ne verra pas un nom
# construit par macro, ni un schéma déclaré hors de `backend/api/src` et
# `backend/crates`. Il ne dit rien de la JUSTESSE d'un schéma : un type unique
# mais faux passe, et c'est le rôle des tests.
#
# Il ne remplace pas non plus la régénération des clients : il vérifie que deux
# types ne se disputent pas un nom, pas que `openapi.json` est à jour.
#
# Usage  : ./scripts/verifier-schemas-openapi.sh
# Sortie : 0 si chaque nom est unique et exposé, 1 sinon (emplacements nommés).

set -euo pipefail

# Racine du dépôt = parent de scripts/ (robuste au working-directory, comme
# verifier-accord-locks.sh : la CI lance ce script depuis `backend/`).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SOURCES=(backend/api/src backend/crates)
CONTRAT="openapi.json"

echo "Unicité des noms de schéma OpenAPI (utoipa)"
echo "  sources : ${SOURCES[*]}"
echo

fautes=0

# ── Relevé des noms DÉCLARÉS ──────────────────────────────────────────────
#
# Le nom qui compte est le nom EFFECTIF : `as = …` s'il existe, sinon le nom du
# type Rust. Ne regarder que les `as` laisserait passer la moitié des types —
# deux `pub struct Reglage` dans deux modules entrent en collision exactement
# comme deux `as` identiques, sans qu'aucun `as` ne soit écrit.
#
# Le relevé sort trois colonnes : nom effectif, emplacement, nom du type Rust.
# Le troisième sert au contrôle 2, qui doit reconnaître un type employé en
# `inline(...)` — l'`inline` cite le nom RUST, jamais l'alias.
releve="$(
  find "${SOURCES[@]}" -name '*.rs' -not -path '*/target/*' -print0 \
    | xargs -0 awk '
        # Un nouveau fichier remet le relevé à zéro : un `derive` inachevé ne
        # doit pas capturer la première déclaration du fichier suivant.
        FNR == 1 { attente = 0; alias = "" }

        # Début du bloc `#[derive(… ToSchema …)]`. On retient la ligne, qui
        # sera le point rapporté.
        /#\[derive\(/ && /ToSchema/ { attente = 1; alias = ""; ligne = FNR; next }

        attente && match($0, /#\[schema\(.*as[[:space:]]*=[[:space:]]*[A-Za-z0-9_]+/) {
          s = substr($0, RSTART, RLENGTH)
          sub(/.*=[[:space:]]*/, "", s)
          alias = s
          next
        }

        # La déclaration close le bloc : on émet, puis on oublie.
        attente && match($0, /pub[[:space:]]+(struct|enum)[[:space:]]+[A-Za-z0-9_]+/) {
          s = substr($0, RSTART, RLENGTH)
          sub(/pub[[:space:]]+(struct|enum)[[:space:]]+/, "", s)
          nom = (alias != "" ? alias : s)
          printf "%s\t%s:%d\t%s\n", nom, FILENAME, ligne, s
          attente = 0; alias = ""
          next
        }

        # Une ligne vide entre le derive et la déclaration : le bloc ne mène à
        # rien d’exploitable, on relâche plutôt que de capturer au hasard.
        attente && /^[[:space:]]*$/ { attente = 0; alias = "" }
      ' \
    | sort
)"

total="$(printf '%s\n' "$releve" | grep -c . || true)"
distincts="$(printf '%s\n' "$releve" | cut -f1 | sort -u | grep -c . || true)"

if [ "$total" -eq 0 ]; then
  echo "✗ aucun schéma relevé — le relevé est cassé, pas le dépôt."
  echo "  (chemins déplacés ? attribut ToSchema écrit autrement ?)"
  exit 1
fi

# ── 1. Deux types ne se disputent pas un nom ──────────────────────────────
doublons="$(printf '%s\n' "$releve" | cut -f1 | sort | uniq -d || true)"

if [ -n "$doublons" ]; then
  while IFS= read -r nom; do
    [ -n "$nom" ] || continue
    echo "✗ le nom de schéma « $nom » est revendiqué par plusieurs types :"
    printf '%s\n' "$releve" | awk -F'\t' -v n="$nom" '$1 == n { printf "    %s  (type Rust : %s)\n", $2, $3 }'
    fautes=$((fautes + 1))
  done <<< "$doublons"
  echo
  echo "  utoipa n'en gardera qu'UN dans openapi.json. Le client généré"
  echo "  désérialisera l'autre route avec le mauvais modèle — sans que le"
  echo "  diff des clients ne bouge."
  echo
fi

# ── 2. Un nom déclaré se retrouve dans le contrat ─────────────────────────
#
# Un schéma déclaré mais absent de `openapi.json` signale soit un type mort,
# soit — plus grave — un type ÉCRASÉ par un homonyme que le contrôle 1 n'aurait
# pas vu (nom construit autrement, schéma hors des chemins relevés).
#
# EXCEPTION, et elle est légitime : `inline(...)` demande explicitement à utoipa
# de développer le type SUR PLACE plutôt que de l'exposer comme composant. Deux
# types du dépôt sont dans ce cas (`RoleDecidableDto`, `StatutRoleDto`, tous
# deux dans des paramètres de requête de `comptes_http.rs`). Les compter comme
# fautes ferait crier le contrôle à tort — et un contrôle qui crie à tort cesse
# d'être lu.
if [ ! -f "$CONTRAT" ]; then
  echo "⚠ $CONTRAT absent — contrôle d'exposition ignoré."
  echo "  (lancer ./scripts/generate-clients.sh pour le produire)"
else
  # Tous les types cités en `inline(...)`, y compris sous `Option<…>`.
  inlines="$(
    find "${SOURCES[@]}" -name '*.rs' -not -path '*/target/*' -print0 \
      | xargs -0 grep -hoE 'inline\([[:space:]]*(Option<)?[[:space:]]*[A-Za-z0-9_]+' \
      | sed -E 's/.*[<(][[:space:]]*//' \
      | sort -u || true
  )"

  exposes="$(
    grep -oE '"[A-Za-z0-9_]+":[[:space:]]*\{' "$CONTRAT" \
      | sed -E 's/"([A-Za-z0-9_]+)".*/\1/' \
      | sort -u || true
  )"

  absents=""
  while IFS=$'\t' read -r nom emplacement rust; do
    [ -n "$nom" ] || continue
    printf '%s\n' "$exposes" | grep -qx "$nom" && continue
    printf '%s\n' "$inlines" | grep -qx "$rust" && continue
    absents="${absents}${nom}\t${emplacement}\t${rust}\n"
  done <<< "$releve"

  if [ -n "$absents" ]; then
    echo "✗ nom(s) de schéma déclaré(s) mais ABSENT(s) de $CONTRAT :"
    printf "$absents" | awk -F'\t' '{ printf "    %s  ←  %s  (type Rust : %s)\n", $1, $2, $3 }'
    echo
    echo "  Trois causes possibles, de la plus fréquente à la plus grave :"
    echo "    1. le contrat n'a pas été régénéré depuis ce changement de nom —"
    echo "       lancer ./scripts/generate-clients.sh et relancer ce contrôle ;"
    echo "    2. le type n'est référencé par aucune route : il est mort ;"
    echo "    3. il est ÉCRASÉ par un homonyme que le contrôle 1 n'a pas vu."
    echo "  Un type développé sur place à dessein doit l'être par inline(...),"
    echo "  qui est reconnu ici et ne compte pas pour une faute."
    fautes=$((fautes + 1))
    echo
  fi
fi

if [ "$fautes" -eq 0 ]; then
  echo "✓ Schémas OpenAPI : OK — $total déclaration(s), $distincts nom(s) distinct(s), aucune collision."
  exit 0
fi

echo "✗ Schémas OpenAPI : $fautes problème(s)."
echo
echo "  Sur une COLLISION : deux types ne peuvent pas porter le même nom de"
echo "  schéma. Renommer le plus récent — celui qui arrive cède le nom, pas"
echo "  celui que les clients consomment déjà — puis régénérer les clients."
exit 1
