#!/usr/bin/env bash
# Régénère openapi.json puis les clients Dart et TypeScript de façon
# DÉTERMINISTE (TRX-01). Deux exécutions successives = zéro diff (contrôlé en CI
# par le job contrat-clients).
#
# Prérequis : Rust (backend), Java >= 11 (openapi-generator CLI pour Dart),
# Flutter/Dart (build_runner pour les .g.dart built_value du client Dart),
# Node + npx (openapi-typescript pour TS).
#
#   ./scripts/generate-clients.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Versions figées (research.md R3).
OPENAPI_GENERATOR_VERSION="7.23.0"
OPENAPI_TYPESCRIPT_VERSION="7.13.0"

echo "→ 1/4 openapi.json (source de vérité, utoipa)"
( cd backend && cargo run -q -p api --bin export-openapi )

echo "→ 2/4 client Dart (openapi-generator ${OPENAPI_GENERATOR_VERSION}, dart-dio)"
# Version du générateur épinglée par openapitools.json ; hideGenerationTimestamp
# = condition du déterminisme (pas d'horodatage dans la sortie).
npx --yes "@openapitools/openapi-generator-cli@2" generate \
  --generator-name dart-dio \
  --input-spec openapi.json \
  --output clients/dart \
  --additional-properties=hideGenerationTimestamp=true,pubName=mefali_api_client,pubAuthor=Mefali \
  >/dev/null

echo "→ 3/4 codegen built_value du client Dart (build_runner → .g.dart)"
# dart-dio produit des modèles built_value ; leurs sérialiseurs .g.dart sont
# générés par build_runner. Requis pour que les apps compilent le client
# (constitution I : jamais d'appel HTTP artisanal). Déterministe (built_value).
( cd clients/dart && flutter pub get >/dev/null && dart run build_runner build >/dev/null )

echo "→ 4/4 client TypeScript (openapi-typescript ${OPENAPI_TYPESCRIPT_VERSION})"
mkdir -p clients/ts
npx --yes "openapi-typescript@${OPENAPI_TYPESCRIPT_VERSION}" openapi.json \
  --output clients/ts/schema.d.ts

echo "✓ Contrat + clients régénérés (openapi.json, clients/dart + .g.dart, clients/ts)."
echo "  Le job CI contrat-clients échoue si un diff subsiste (dérive interdite)."
