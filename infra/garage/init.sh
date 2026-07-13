#!/usr/bin/env bash
# Initialisation Garage mono-nœud (dev) — research.md R5.
#
# L'image Garage officielle est « FROM scratch » (aucun shell) : ce script tourne
# côté HÔTE et pilote le binaire via `docker compose exec`. Idempotent : ré-exécutable.
#
# Usage : infra/garage/init.sh   (depuis la racine du dépôt)
# Produit : layout mono-nœud appliqué, bucket applicatif, 2 clés d'accès
# (backend rw, backup ro). Recopier les clés affichées dans `.env`.
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-infra/docker-compose.yml}"
GARAGE=(docker compose -f "$COMPOSE_FILE" exec -T garage /garage)

echo "→ Attente du nœud Garage…"
until "${GARAGE[@]}" status >/dev/null 2>&1; do sleep 1; done

NODE_ID="$("${GARAGE[@]}" node id -q | cut -d@ -f1)"
echo "→ Nœud : $NODE_ID"

# Layout mono-nœud assigné EXPLICITEMENT (pas d'auto-layout).
if ! "${GARAGE[@]}" layout show 2>/dev/null | grep -q "$NODE_ID"; then
  "${GARAGE[@]}" layout assign -z dc1 -c 1G "$NODE_ID"
  "${GARAGE[@]}" layout apply --version 1
fi

# Bucket applicatif.
"${GARAGE[@]}" bucket create mefali 2>/dev/null || true

# Clé backend : lecture + écriture (URLs présignées d'upload photos).
if ! "${GARAGE[@]}" key info mefali-backend >/dev/null 2>&1; then
  "${GARAGE[@]}" key create mefali-backend
fi
"${GARAGE[@]}" bucket allow --read --write mefali --key mefali-backend

# Clé backup : lecture seule (sync Garage → B2 par rclone).
if ! "${GARAGE[@]}" key info mefali-backup >/dev/null 2>&1; then
  "${GARAGE[@]}" key create mefali-backup
fi
"${GARAGE[@]}" bucket allow --read mefali --key mefali-backup

echo
echo "=== Clés à recopier dans .env (S3_* = backend ; BACKUP_GARAGE_* = backup) ==="
"${GARAGE[@]}" key info mefali-backend --show-secret
"${GARAGE[@]}" key info mefali-backup --show-secret
