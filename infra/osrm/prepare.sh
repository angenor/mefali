#!/usr/bin/env bash
# Préparation des données OSRM pour la Côte d'Ivoire (research.md R5).
#
# Télécharge l'extrait Geofabrik (~80 Mo, maj quotidienne) puis exécute le
# pipeline MLD (extract profil voiture → partition → customize). À lancer AVANT
# de démarrer le service `osrm` du docker-compose. Réexécutable pour rafraîchir.
#
# Usage : infra/osrm/prepare.sh   (depuis la racine du dépôt)
set -euo pipefail

OSRM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PBF_URL="https://download.geofabrik.de/africa/ivory-coast-latest.osm.pbf"
PBF="ivory-coast-latest.osm.pbf"
BASE="ivory-coast-latest.osrm"
IMAGE="ghcr.io/project-osrm/osrm-backend:v26.7.3"

cd "$OSRM_DIR"

if [ ! -f "$PBF" ]; then
  echo "→ Téléchargement de l'extrait Geofabrik…"
  curl -fL -o "$PBF" "$PBF_URL"
fi

RUN=(docker run --rm -v "$OSRM_DIR:/data" "$IMAGE")

echo "→ osrm-extract (profil voiture)…"
"${RUN[@]}" osrm-extract -p /opt/car.lua "/data/$PBF"
echo "→ osrm-partition…"
"${RUN[@]}" osrm-partition "/data/$BASE"
echo "→ osrm-customize…"
"${RUN[@]}" osrm-customize "/data/$BASE"

echo "✓ Données OSRM prêtes ($OSRM_DIR/$BASE). Démarrer le service : docker compose up -d osrm"
