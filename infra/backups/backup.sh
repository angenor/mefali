#!/usr/bin/env bash
# Sauvegarde quotidienne chiffrée (TRX-04).
#   - pg_dump | age → Backblaze B2 (object lock + lifecycle 30 j côté B2) ;
#   - sync stockage objet Garage → B2 (rclone S3→S3, clé Garage dédiée backup).
# Le clair ne touche jamais le disque (streaming). La clé PRIVÉE age reste HORS
# VPS. Variables : infra/.env.example (BACKUP_*). age v1.3.1, rclone.
set -euo pipefail

: "${DATABASE_URL:?}"
: "${S3_ENDPOINT:?}"
: "${S3_BUCKET:?}"
: "${BACKUP_S3_ENDPOINT:?}"
: "${BACKUP_S3_BUCKET:?}"
: "${BACKUP_S3_ACCESS_KEY:?}"
: "${BACKUP_S3_SECRET_KEY:?}"
: "${BACKUP_GARAGE_ACCESS_KEY:?}"
: "${BACKUP_GARAGE_SECRET_KEY:?}"
: "${BACKUP_AGE_RECIPIENT:?}"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DUMP="postgres/mefali-${STAMP}.sql.age"

# --- 1. Dump Postgres chiffré (age) → B2, en streaming ---
export AWS_ACCESS_KEY_ID="$BACKUP_S3_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$BACKUP_S3_SECRET_KEY"
pg_dump "$DATABASE_URL" --format=custom \
  | age -r "$BACKUP_AGE_RECIPIENT" \
  | aws s3 cp --endpoint-url "$BACKUP_S3_ENDPOINT" - "s3://${BACKUP_S3_BUCKET}/${DUMP}"
echo "✓ dump chiffré → s3://${BACKUP_S3_BUCKET}/${DUMP}"

# --- 2. Sync Garage → B2 (rclone S3→S3) ---
export RCLONE_CONFIG_GARAGE_TYPE=s3 RCLONE_CONFIG_GARAGE_PROVIDER=Other
export RCLONE_CONFIG_GARAGE_ENDPOINT="$S3_ENDPOINT"
export RCLONE_CONFIG_GARAGE_ACCESS_KEY_ID="$BACKUP_GARAGE_ACCESS_KEY"
export RCLONE_CONFIG_GARAGE_SECRET_ACCESS_KEY="$BACKUP_GARAGE_SECRET_KEY"
export RCLONE_CONFIG_B2_TYPE=s3 RCLONE_CONFIG_B2_PROVIDER=Other
export RCLONE_CONFIG_B2_ENDPOINT="$BACKUP_S3_ENDPOINT"
export RCLONE_CONFIG_B2_ACCESS_KEY_ID="$BACKUP_S3_ACCESS_KEY"
export RCLONE_CONFIG_B2_SECRET_ACCESS_KEY="$BACKUP_S3_SECRET_KEY"
rclone sync "garage:${S3_BUCKET}" "b2:${BACKUP_S3_BUCKET}/garage" --fast-list
echo "✓ sync Garage → B2 (bucket ${BACKUP_S3_BUCKET}/garage)"

# --- 3. Rétention 30 j ---
# L'immutabilité (object lock) et l'expiration à 30 j sont portées par la RÈGLE
# DE CYCLE DE VIE B2 (jamais côté Garage — research.md R7). Nettoyage best-effort
# complémentaire des dumps antérieurs à la fenêtre glissante :
CUTOFF="$(date -u -d '30 days ago' +%Y%m%dT000000Z 2>/dev/null || date -u -v-30d +%Y%m%dT000000Z)"
aws s3 ls --endpoint-url "$BACKUP_S3_ENDPOINT" "s3://${BACKUP_S3_BUCKET}/postgres/" \
  | awk '{print $4}' | while read -r key; do
      ts="${key#mefali-}"; ts="${ts%.sql.age}"
      [ -n "$ts" ] && [ "$ts" \< "$CUTOFF" ] && \
        aws s3 rm --endpoint-url "$BACKUP_S3_ENDPOINT" "s3://${BACKUP_S3_BUCKET}/postgres/${key}" || true
    done
echo "✓ rétention 30 j appliquée (garantie : lifecycle B2)"
