#!/usr/bin/env bash
# Provisionnement du VPS de production Mefali (US7). À exécuter en root sur un
# Debian/Ubuntu neuf. Docker Engine 29 + compose, utilisateur deploy, UFW,
# /srv/mefali + .env hors Git. Idempotent.
set -euo pipefail

# --- Docker Engine + plugin compose ---
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi

# --- Utilisateur de déploiement (non-root, membre du groupe docker) ---
id deploy >/dev/null 2>&1 || useradd -m -s /bin/bash deploy
usermod -aG docker deploy

# --- Pare-feu : uniquement SSH + HTTP(S) ---
if command -v ufw >/dev/null; then
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
fi

# --- Arborescence de déploiement ---
install -d -o deploy -g deploy /srv/mefali
if [ ! -f /srv/mefali/.env ]; then
  install -o deploy -g deploy -m 600 /dev/null /srv/mefali/.env
  echo "→ Renseigner /srv/mefali/.env (contrat : infra/.env.example ; APP_ENV=production)."
fi

echo "✓ VPS provisionné."
echo "  Étapes suivantes :"
echo "   1. Copier infra/vps/compose.prod.yml et infra/vps/Caddyfile dans /srv/mefali/."
echo "   2. Renseigner /srv/mefali/.env (secrets forts, DOMAIN, GHCR_IMAGE)."
echo "   3. Pointer le DNS du domaine API vers ce VPS."
echo "   4. Le workflow deploy.yml prend le relais à chaque push sur main."
