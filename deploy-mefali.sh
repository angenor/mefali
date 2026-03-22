#!/bin/bash

# ===========================================
# Mefali Deployment Script
# Deploiement sur VPS partage (cohabitation UAfricas)
# ===========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Configuration
REMOTE_USER="root"
REMOTE_HOST="161.97.92.63"
REMOTE_DIR="/opt/mefali"
REPO_URL="https://github.com/angenor/mefali.git"

echo -e "${GREEN}=== Mefali Deployment ===${NC}"
echo -e "Serveur: ${BLUE}${REMOTE_USER}@${REMOTE_HOST}${NC}"

ssh_cmd() {
    ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "$@"
}

scp_cmd() {
    scp -o StrictHostKeyChecking=no "$@"
}

ssh_heredoc() {
    ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}"
}

# ========================================
# SETUP - Installation initiale
# ========================================
setup() {
    echo -e "${GREEN}[1/5] Verification de la connexion SSH...${NC}"
    ssh_cmd "echo 'Connexion SSH reussie !'"

    echo -e "${GREEN}[2/5] Verification de Docker...${NC}"
    ssh_heredoc << 'ENDSSH'
        if ! command -v docker &> /dev/null; then
            echo "ERREUR: Docker n'est pas installe !"
            echo "Docker devrait deja etre installe par UAfricas."
            exit 1
        fi
        echo "Docker: $(docker --version)"
        echo "Docker Compose: $(docker compose version)"
ENDSSH

    echo -e "${GREEN}[3/5] Creation du repertoire projet...${NC}"
    ssh_cmd "mkdir -p ${REMOTE_DIR}"

    echo -e "${GREEN}[4/5] Clonage du repository...${NC}"
    ssh_heredoc << ENDSSH
        cd ${REMOTE_DIR}
        if [ ! -d ".git" ]; then
            echo "Clonage du repository..."
            cd /opt
            rm -rf mefali
            git clone ${REPO_URL}
        else
            echo "Repository deja present, mise a jour..."
            git fetch origin
            git reset --hard origin/main || git reset --hard origin/master
        fi
ENDSSH

    echo -e "${GREEN}[5/5] Generation du .env production...${NC}"
    ssh_heredoc << 'ENDSSH'
        cd /opt/mefali
        if [ -f ".env" ]; then
            echo "Fichier .env existant conserve."
        else
            JWT_SECRET=$(openssl rand -hex 32)
            POSTGRES_PWD=$(openssl rand -hex 16)
            MINIO_PWD=$(openssl rand -hex 16)

            cat > .env << ENVEOF
# === PostgreSQL ===
POSTGRES_USER=mefali
POSTGRES_PASSWORD=${POSTGRES_PWD}
POSTGRES_DB=mefali
PG_PORT=5433

# === Redis ===
REDIS_PORT=6380

# === MinIO ===
MINIO_ROOT_USER=mefali
MINIO_ROOT_PASSWORD=${MINIO_PWD}
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
MINIO_BUCKET=mefali-files

# === API ===
API_PORT=8090

# === URLs internes Docker ===
DATABASE_URL=postgres://mefali:${POSTGRES_PWD}@postgres:5432/mefali
REDIS_URL=redis://redis:6379
MINIO_ENDPOINT=http://minio:9000
MINIO_ACCESS_KEY=mefali
MINIO_SECRET_KEY=${MINIO_PWD}

# === JWT ===
JWT_SECRET=${JWT_SECRET}
JWT_ACCESS_EXPIRY=900
JWT_REFRESH_EXPIRY=604800

# === Logging ===
RUST_LOG=info
ENVEOF

            echo ""
            echo "Secrets generes et sauvegardes dans .env"
            echo "  POSTGRES_PASSWORD: $POSTGRES_PWD"
            echo "  JWT_SECRET: $JWT_SECRET"
            echo "  MINIO_PASSWORD: $MINIO_PWD"
            echo ""
            echo "Sauvegardez ces valeurs !"
        fi
ENDSSH

    echo ""
    echo -e "${GREEN}=== Setup termine ! ===${NC}"
    echo ""
    echo -e "${YELLOW}Prochaine etape:${NC}"
    echo "  1. Ajouter le bloc Nginx pour api.mefali.com (voir nginx-mefali.conf)"
    echo "  2. ./deploy-mefali.sh deploy"
}

# ========================================
# DEPLOY - Deploiement complet
# ========================================
deploy() {
    echo -e "${GREEN}[1/4] Pull du code depuis GitHub...${NC}"
    ssh_heredoc << ENDSSH
        cd ${REMOTE_DIR}
        git fetch origin
        git reset --hard origin/main || git reset --hard origin/master
ENDSSH

    echo -e "${GREEN}[2/4] Verification des ports...${NC}"
    ssh_heredoc << 'ENDSSH'
        echo "Verification des ports mefali..."
        for port in 5433 6380 8090 9000 9001; do
            if ss -tlnp | grep -q ":${port} "; then
                echo "ATTENTION: Port ${port} deja utilise !"
                ss -tlnp | grep ":${port} "
            else
                echo "Port ${port}: libre"
            fi
        done
ENDSSH

    echo -e "${GREEN}[3/4] Build et demarrage des containers...${NC}"
    ssh_heredoc << ENDSSH
        cd ${REMOTE_DIR}

        if [ ! -f ".env" ]; then
            echo "ERREUR: Fichier .env introuvable !"
            echo "Executez d'abord: ./deploy-mefali.sh setup"
            exit 1
        fi

        docker compose -f docker-compose.yml -f docker-compose.prod.yml down || true
        docker compose -f docker-compose.yml -f docker-compose.prod.yml build
        docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
        docker image prune -f
ENDSSH

    echo -e "${GREEN}[4/4] Verification du deploiement...${NC}"
    ssh_heredoc << 'ENDSSH'
        cd /opt/mefali
        echo "Etat des containers:"
        docker compose -f docker-compose.yml -f docker-compose.prod.yml ps

        echo ""
        echo "Attente du demarrage des services..."
        sleep 15

        echo ""
        echo "Health check API:"
        curl -sf http://localhost:8090/api/v1/health && echo " - API OK" || echo " - API pas encore pret"
ENDSSH

    echo ""
    echo -e "${GREEN}=== Deploiement termine ! ===${NC}"
    echo -e "API accessible sur: ${BLUE}https://api.mefali.com${NC}"
}

# ========================================
# UPDATE - Mise a jour rapide
# ========================================
update() {
    echo -e "${GREEN}Mise a jour rapide...${NC}"
    ssh_heredoc << ENDSSH
        cd ${REMOTE_DIR}
        git pull origin main || git pull origin master
        docker compose -f docker-compose.yml -f docker-compose.prod.yml build api
        docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d api
        echo ""
        echo "Etat des containers:"
        docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
ENDSSH
    echo -e "${GREEN}Mise a jour terminee !${NC}"
}

# ========================================
# LOGS
# ========================================
logs() {
    SERVICE="${2:-}"
    if [ -n "$SERVICE" ]; then
        ssh_cmd "cd ${REMOTE_DIR} && docker compose logs -f --tail=100 ${SERVICE}"
    else
        ssh_cmd "cd ${REMOTE_DIR} && docker compose logs -f --tail=100"
    fi
}

# ========================================
# RESTART
# ========================================
restart() {
    SERVICE="${2:-}"
    if [ -n "$SERVICE" ]; then
        echo -e "${GREEN}Redemarrage de ${SERVICE}...${NC}"
        ssh_cmd "cd ${REMOTE_DIR} && docker compose restart ${SERVICE}"
    else
        echo -e "${GREEN}Redemarrage de tous les services...${NC}"
        ssh_cmd "cd ${REMOTE_DIR} && docker compose restart"
    fi
    echo -e "${GREEN}Redemarrage effectue !${NC}"
}

# ========================================
# STOP
# ========================================
stop() {
    echo -e "${YELLOW}Arret de tous les services mefali...${NC}"
    ssh_cmd "cd ${REMOTE_DIR} && docker compose -f docker-compose.yml -f docker-compose.prod.yml down"
    echo -e "${GREEN}Services mefali arretes.${NC}"
}

# ========================================
# STATUS
# ========================================
status() {
    ssh_heredoc << 'ENDSSH'
        cd /opt/mefali
        echo "=== Containers mefali ==="
        docker compose ps

        echo ""
        echo "=== Dernier commit ==="
        git log -1 --oneline

        echo ""
        echo "=== Espace disque ==="
        df -h / | tail -1

        echo ""
        echo "=== Memoire ==="
        free -h | head -2

        echo ""
        echo "=== Health check ==="
        curl -sf http://localhost:8090/api/v1/health && echo " - API OK" || echo " - API KO"
ENDSSH
}

# ========================================
# BACKUP
# ========================================
backup() {
    BACKUP_DIR="${SCRIPT_DIR}/backups"
    mkdir -p "${BACKUP_DIR}"
    BACKUP_FILE="${BACKUP_DIR}/backup_mefali_$(date +%Y%m%d_%H%M%S).sql"

    echo -e "${GREEN}Sauvegarde de la base de donnees...${NC}"
    ssh_cmd "docker exec mefali-postgres-1 pg_dump -U mefali mefali" > "${BACKUP_FILE}"
    echo -e "${GREEN}Sauvegarde: ${BACKUP_FILE}${NC}"
    echo "Taille: $(du -h "${BACKUP_FILE}" | cut -f1)"
}

# ========================================
# CONNECT
# ========================================
connect() {
    echo -e "${GREEN}Connexion au serveur...${NC}"
    ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" -t "cd ${REMOTE_DIR} && bash"
}

# ========================================
# REBUILD
# ========================================
rebuild() {
    echo -e "${YELLOW}Rebuild complet sans cache...${NC}"
    ssh_heredoc << ENDSSH
        cd ${REMOTE_DIR}
        docker compose -f docker-compose.yml -f docker-compose.prod.yml down
        docker compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache
        docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
        docker image prune -f
        echo ""
        echo "Etat des containers:"
        docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
ENDSSH
    echo -e "${GREEN}Rebuild termine !${NC}"
}

# ========================================
# NGINX - Afficher la config a ajouter dans UAfricas Nginx
# ========================================
nginx_conf() {
    echo -e "${GREEN}Bloc a ajouter dans le Nginx d'UAfricas:${NC}"
    echo ""
    cat << 'EOF'
# === Mefali API (ajouter dans nginx.conf d'UAfricas) ===
server {
    listen 80;
    server_name api.mefali.com;

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name api.mefali.com;

    ssl_certificate /etc/letsencrypt/live/api.mefali.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mefali.com/privkey.pem;

    location / {
        proxy_pass http://host.docker.internal:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
    echo ""
    echo -e "${YELLOW}Note: host.docker.internal fonctionne si Nginx tourne dans Docker.${NC}"
    echo -e "${YELLOW}Si Nginx est sur l'hote, utilisez 127.0.0.1:8090 a la place.${NC}"
}

# ========================================
# MENU PRINCIPAL
# ========================================
case "$1" in
    setup)    setup ;;
    deploy)   deploy ;;
    update)   update ;;
    logs)     logs "$@" ;;
    restart)  restart "$@" ;;
    stop)     stop ;;
    status)   status ;;
    backup)   backup ;;
    connect)  connect ;;
    rebuild)  rebuild ;;
    nginx)    nginx_conf ;;
    *)
        echo -e "${GREEN}Mefali Deployment Script${NC}"
        echo -e "Cohabitation avec UAfricas sur ${BLUE}${REMOTE_HOST}${NC}"
        echo ""
        echo "Usage: $0 {commande} [options]"
        echo ""
        echo -e "${BLUE}Installation:${NC}"
        echo "  setup              Installation initiale (clone, .env)"
        echo ""
        echo -e "${BLUE}Deploiement:${NC}"
        echo "  deploy             Deploiement complet (pull + build + start)"
        echo "  update             Mise a jour rapide (pull + rebuild api)"
        echo "  rebuild            Rebuild sans cache"
        echo ""
        echo -e "${BLUE}Gestion:${NC}"
        echo "  status             Etat des containers et ressources"
        echo "  logs [service]     Voir les logs (api, postgres, redis, minio)"
        echo "  restart [service]  Redemarrer les services"
        echo "  stop               Arreter tous les services mefali"
        echo ""
        echo -e "${BLUE}Autres:${NC}"
        echo "  nginx              Afficher la config Nginx a ajouter dans UAfricas"
        echo "  backup             Sauvegarder la base de donnees"
        echo "  connect            SSH direct vers le serveur"
        echo ""
        echo -e "${BLUE}Exemples:${NC}"
        echo "  $0 setup                     # Premiere installation"
        echo "  $0 deploy                    # Deployer"
        echo "  $0 logs api                  # Logs du backend Rust"
        echo "  $0 nginx                     # Voir config Nginx a ajouter"
        exit 1
        ;;
esac
