#!/usr/bin/env bash
# Test de restauration (TRX-04, plan T8). Récupère la dernière archive chiffrée,
# la déchiffre (age), la restaure dans un Postgres JETABLE et vérifie le schéma.
# Automatisable en local contre le compose dev. La clé PRIVÉE age est fournie via
# BACKUP_AGE_KEY_FILE (jamais commitée, jamais sur le VPS de prod).
set -euo pipefail

: "${BACKUP_S3_ENDPOINT:?}"
: "${BACKUP_S3_BUCKET:?}"
: "${BACKUP_S3_ACCESS_KEY:?}"
: "${BACKUP_S3_SECRET_KEY:?}"
: "${BACKUP_AGE_KEY_FILE:?clé privée age (hors VPS)}"

export AWS_ACCESS_KEY_ID="$BACKUP_S3_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$BACKUP_S3_SECRET_KEY"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"; docker rm -f mefali-restore-test >/dev/null 2>&1 || true' EXIT

# 1. Dernière archive.
LAST="$(aws s3 ls --endpoint-url "$BACKUP_S3_ENDPOINT" "s3://${BACKUP_S3_BUCKET}/postgres/" \
  | sort | tail -1 | awk '{print $4}')"
[ -n "$LAST" ] || { echo "aucune archive trouvée" >&2; exit 1; }
aws s3 cp --endpoint-url "$BACKUP_S3_ENDPOINT" \
  "s3://${BACKUP_S3_BUCKET}/postgres/${LAST}" "$WORK/dump.sql.age"

# 2. Déchiffrement age.
age -d -i "$BACKUP_AGE_KEY_FILE" -o "$WORK/dump.sql" "$WORK/dump.sql.age"

# 3. Postgres jetable.
docker run -d --name mefali-restore-test -e POSTGRES_PASSWORD=test -p 5544:5432 postgres:18.4 >/dev/null
until docker exec mefali-restore-test pg_isready -U postgres >/dev/null 2>&1; do sleep 1; done
docker exec -i mefali-restore-test createdb -U postgres mefali_restore

# 4. Restauration + vérification du schéma.
docker exec -i mefali-restore-test pg_restore -U postgres -d mefali_restore < "$WORK/dump.sql"
docker exec -i mefali-restore-test psql -U postgres -d mefali_restore -c "\dn" \
  | grep -q outbox && echo "✓ restauration vérifiée (schéma outbox présent)"
