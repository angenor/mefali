#!/bin/bash

# ===========================================
# UAfricas Deployment Script
# Deploiement sur VPS via SSH + Docker
# ===========================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Repertoire du script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Configuration
REMOTE_USER="root"
REMOTE_HOST="161.97.92.63"
REMOTE_DIR="/opt/uafricas"
REPO_URL="https://github.com/angenor/uafricas.git"

echo -e "${GREEN}=== UAfricas Deployment ===${NC}"
echo -e "Serveur: ${BLUE}${REMOTE_USER}@${REMOTE_HOST}${NC}"

# Fonctions SSH (auth par cle SSH)
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
# SETUP - Installation initiale du serveur
# ========================================
setup() {
    echo -e "${GREEN}[1/6] Verification de la connexion SSH...${NC}"
    ssh_cmd "echo 'Connexion SSH reussie !'"

    echo -e "${GREEN}[2/6] Installation de Docker et Git...${NC}"
    ssh_heredoc << 'ENDSSH'
        # Installer Docker si absent
        if ! command -v docker &> /dev/null; then
            echo "Installation de Docker..."
            curl -fsSL https://get.docker.com | sh
            systemctl enable docker
            systemctl start docker
        fi

        # Installer Docker Compose plugin si absent
        if ! docker compose version &> /dev/null; then
            echo "Installation de Docker Compose..."
            apt-get update
            apt-get install -y docker-compose-plugin
        fi

        # Installer Git et sshpass si absents
        apt-get update
        apt-get install -y git curl

        echo "Docker: $(docker --version)"
        echo "Docker Compose: $(docker compose version)"
        echo "Git: $(git --version)"
ENDSSH

    echo -e "${GREEN}[3/6] Creation du repertoire projet...${NC}"
    ssh_cmd "mkdir -p ${REMOTE_DIR}"

    echo -e "${GREEN}[4/6] Clonage du repository...${NC}"
    ssh_heredoc << ENDSSH
        cd ${REMOTE_DIR}

        # Cloner si pas encore fait
        if [ ! -d ".git" ]; then
            echo "Clonage du repository..."
            cd /opt
            rm -rf uafricas
            git clone ${REPO_URL}
        else
            echo "Repository deja present, mise a jour..."
            git fetch origin
            git reset --hard origin/main || git reset --hard origin/master
        fi
ENDSSH

    echo -e "${GREEN}[5/6] Upload de la configuration Nginx...${NC}"
    ssh_cmd "mkdir -p ${REMOTE_DIR}/nginx/ssl"
    scp_cmd "${SCRIPT_DIR}/nginx/nginx.conf" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/nginx/"

    echo -e "${GREEN}[6/6] Generation des secrets et creation du .env...${NC}"
    ssh_heredoc << 'ENDSSH'
        cd /opt/uafricas

        if [ -f ".env" ]; then
            echo "Fichier .env existant conserve."
        else
            # Generer des secrets securises
            JWT_SECRET=$(openssl rand -hex 32)
            POSTGRES_PWD=$(openssl rand -hex 16)
            LIVEKIT_KEY=$(openssl rand -hex 8)
            LIVEKIT_SECRET=$(openssl rand -hex 16)

            # Creer le .env directement
            cat > .env << ENVEOF
# PostgreSQL
POSTGRES_DB=africans_db
POSTGRES_USER=uafricas
POSTGRES_PASSWORD=${POSTGRES_PWD}

# Backend
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRATION_MINUTES=15
REFRESH_EXPIRATION_DAYS=7
RUST_LOG=info

# Frontend
FRONTEND_URL=https://www.africans-world.org
NUXT_PUBLIC_API_BASE_URL=/api

# LiveKit (visioconference WebRTC)
LIVEKIT_URL=ws://livekit:7880
LIVEKIT_API_KEY=${LIVEKIT_KEY}
LIVEKIT_API_SECRET=${LIVEKIT_SECRET}

# SMTP (envoi d'emails)
SMTP_HOST=mail77.lwspanel.com
SMTP_PORT=587
SMTP_USERNAME=contact@africans-world.org
SMTP_PASSWORD=CHANGEZ_MOI
SMTP_FROM_EMAIL=contact@africans-world.org
SMTP_FROM_NAME=UAfricas
EMAIL_VERIFICATION_EXPIRATION_HOURS=24
ENVEOF

            echo ""
            echo "Secrets generes et sauvegardes dans .env"
            echo ""
            echo "  POSTGRES_PASSWORD: $POSTGRES_PWD"
            echo "  JWT_SECRET: $JWT_SECRET"
            echo "  LIVEKIT_API_KEY: $LIVEKIT_KEY"
            echo "  LIVEKIT_API_SECRET: $LIVEKIT_SECRET"
            echo ""
            echo "Sauvegardez ces valeurs !"
        fi
ENDSSH

    echo ""
    echo -e "${GREEN}=== Setup termine ! ===${NC}"
    echo ""
    echo -e "${YELLOW}Prochaine etape:${NC}"
    echo "  ./deploy.sh deploy"
    echo ""
    echo -e "${YELLOW}Optionnel - Modifier le .env:${NC}"
    echo "  ./deploy.sh connect"
    echo "  nano .env"
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

    echo -e "${GREEN}[2/4] Upload de la configuration Nginx...${NC}"
    scp_cmd "${SCRIPT_DIR}/nginx/nginx.conf" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/nginx/"

    echo -e "${GREEN}[3/4] Build et demarrage des containers...${NC}"
    ssh_heredoc << ENDSSH
        cd ${REMOTE_DIR}

        if [ ! -f ".env" ]; then
            echo "ERREUR: Fichier .env introuvable !"
            echo "Executez d'abord: ./deploy.sh setup"
            exit 1
        fi

        # Arreter les containers existants
        docker compose -f docker-compose.prod.yml down || true

        # Build et demarrage
        docker compose -f docker-compose.prod.yml build
        docker compose -f docker-compose.prod.yml up -d

        # Nettoyage des anciennes images
        docker image prune -f
ENDSSH

    echo -e "${GREEN}[4/4] Verification du deploiement...${NC}"
    ssh_heredoc << 'ENDSSH'
        cd /opt/uafricas
        echo "Etat des containers:"
        docker compose -f docker-compose.prod.yml ps

        echo ""
        echo "Attente du demarrage des services..."
        sleep 20

        echo ""
        echo "Health checks:"
        curl -sf http://localhost/health && echo " - Nginx OK" || echo " - Nginx pas encore pret"
        curl -sf http://localhost/api/health && echo " - Backend OK" || echo " - Backend pas encore pret"
ENDSSH

    echo ""
    echo -e "${GREEN}=== Deploiement termine ! ===${NC}"
    echo -e "Site accessible sur: ${BLUE}https://www.africans-world.org${NC}"
}

# ========================================
# UPDATE - Mise a jour rapide
# ========================================
update() {
    echo -e "${GREEN}Mise a jour rapide...${NC}"
    ssh_heredoc << ENDSSH
        cd ${REMOTE_DIR}
        git pull origin main || git pull origin master

        docker compose -f docker-compose.prod.yml build
        docker compose -f docker-compose.prod.yml up -d

        echo ""
        echo "Etat des containers:"
        docker compose -f docker-compose.prod.yml ps
ENDSSH
    echo -e "${GREEN}Mise a jour terminee !${NC}"
    echo -e "Site: ${BLUE}https://www.africans-world.org${NC}"
}

# ========================================
# LOGS - Voir les logs
# ========================================
logs() {
    SERVICE="${2:-}"
    if [ -n "$SERVICE" ]; then
        ssh_cmd "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml logs -f --tail=100 ${SERVICE}"
    else
        ssh_cmd "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml logs -f --tail=100"
    fi
}

# ========================================
# RESTART - Redemarrer les services
# ========================================
restart() {
    SERVICE="${2:-}"
    if [ -n "$SERVICE" ]; then
        echo -e "${GREEN}Redemarrage de ${SERVICE}...${NC}"
        ssh_cmd "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml restart ${SERVICE}"
    else
        echo -e "${GREEN}Redemarrage de tous les services...${NC}"
        ssh_cmd "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml restart"
    fi
    echo -e "${GREEN}Redemarrage effectue !${NC}"
}

# ========================================
# STOP - Arreter les services
# ========================================
stop() {
    echo -e "${YELLOW}Arret de tous les services...${NC}"
    ssh_cmd "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml down"
    echo -e "${GREEN}Services arretes.${NC}"
}

# ========================================
# STATUS - Etat des services
# ========================================
status() {
    ssh_heredoc << 'ENDSSH'
        cd /opt/uafricas
        echo "=== Etat des containers ==="
        docker compose -f docker-compose.prod.yml ps

        echo ""
        echo "=== Dernier commit Git ==="
        git log -1 --oneline

        echo ""
        echo "=== Espace disque ==="
        df -h / | tail -1

        echo ""
        echo "=== Memoire ==="
        free -h | head -2

        echo ""
        echo "=== Health checks ==="
        curl -sf http://localhost/health && echo " - Nginx OK" || echo " - Nginx KO"
        curl -sf http://localhost/api/health && echo " - Backend OK" || echo " - Backend KO"
ENDSSH
}

# ========================================
# SSL - Configurer Let's Encrypt
# ========================================
ssl() {
    DOMAIN="${2:-africans-world.org}"

    echo -e "${GREEN}Configuration SSL pour ${DOMAIN} et www.${DOMAIN}...${NC}"
    ssh_heredoc << ENDSSH
        apt-get update
        apt-get install -y certbot

        # Arreter Nginx temporairement pour liberer le port 80
        docker stop uafricas_nginx || true

        # Obtenir le certificat pour le domaine nu et www
        certbot certonly --standalone -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}

        # Copier les certificats
        mkdir -p ${REMOTE_DIR}/nginx/ssl
        cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ${REMOTE_DIR}/nginx/ssl/
        cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem ${REMOTE_DIR}/nginx/ssl/

        # Redemarrer Nginx
        docker start uafricas_nginx

        # Configurer le renouvellement automatique avec copie des certificats
        (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --pre-hook 'docker stop uafricas_nginx' --post-hook 'cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ${REMOTE_DIR}/nginx/ssl/ && cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem ${REMOTE_DIR}/nginx/ssl/ && docker start uafricas_nginx'") | crontab -

        echo ""
        echo "Certificat SSL installe pour ${DOMAIN} et www.${DOMAIN} !"
        echo "Redemarrez avec: ./deploy.sh restart nginx"
ENDSSH
}

# ========================================
# BACKUP - Sauvegarder la base de donnees
# ========================================
backup() {
    BACKUP_DIR="${SCRIPT_DIR}/backups"
    mkdir -p "${BACKUP_DIR}"
    BACKUP_FILE="${BACKUP_DIR}/backup_uafricas_$(date +%Y%m%d_%H%M%S).sql"

    echo -e "${GREEN}Sauvegarde de la base de donnees...${NC}"
    ssh_cmd "docker exec uafricas_db pg_dump -U uafricas africans_db" > "${BACKUP_FILE}"
    echo -e "${GREEN}Sauvegarde enregistree: ${BACKUP_FILE}${NC}"
    echo "Taille: $(du -h "${BACKUP_FILE}" | cut -f1)"
}

# ========================================
# CONNECT - Connexion SSH directe
# ========================================
connect() {
    echo -e "${GREEN}Connexion au serveur...${NC}"
    if command -v sshpass &> /dev/null && [ -n "$VPS_PASSWORD" ]; then
        sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" -t "cd ${REMOTE_DIR} && bash"
    else
        ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" -t "cd ${REMOTE_DIR} && bash"
    fi
}

# ========================================
# REBUILD - Rebuild complet sans cache
# ========================================
rebuild() {
    echo -e "${YELLOW}Rebuild complet sans cache...${NC}"
    ssh_heredoc << ENDSSH
        cd ${REMOTE_DIR}
        docker compose -f docker-compose.prod.yml down
        docker compose -f docker-compose.prod.yml build --no-cache
        docker compose -f docker-compose.prod.yml up -d
        docker image prune -f

        echo ""
        echo "Etat des containers:"
        docker compose -f docker-compose.prod.yml ps
ENDSSH
    echo -e "${GREEN}Rebuild termine !${NC}"
}

# ========================================
# MENU PRINCIPAL
# ========================================
case "$1" in
    setup)
        setup
        ;;
    deploy)
        deploy
        ;;
    update)
        update
        ;;
    logs)
        logs "$@"
        ;;
    restart)
        restart "$@"
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    ssl)
        ssl "$@"
        ;;
    backup)
        backup
        ;;
    connect)
        connect
        ;;
    rebuild)
        rebuild
        ;;
    *)
        echo -e "${GREEN}UAfricas Deployment Script${NC}"
        echo ""
        echo "Usage: $0 {commande} [options]"
        echo ""
        echo -e "${BLUE}Installation:${NC}"
        echo "  setup              Installation initiale du serveur (Docker, Git, clone)"
        echo ""
        echo -e "${BLUE}Deploiement:${NC}"
        echo "  deploy             Deploiement complet (pull + rebuild + restart)"
        echo "  update             Mise a jour rapide (pull + rebuild)"
        echo "  rebuild            Rebuild sans cache (en cas de probleme)"
        echo ""
        echo -e "${BLUE}Gestion:${NC}"
        echo "  status             Etat des containers et ressources"
        echo "  logs [service]     Voir les logs (backend, frontend, postgres, nginx, livekit)"
        echo "  restart [service]  Redemarrer les services"
        echo "  stop               Arreter tous les services"
        echo ""
        echo -e "${BLUE}Autres:${NC}"
        echo "  ssl                Configurer SSL pour africans-world.org"
        echo "  backup             Sauvegarder la base de donnees"
        echo "  connect            SSH direct vers le serveur"
        echo ""
        echo -e "${BLUE}Exemples:${NC}"
        echo "  $0 setup                     # Premiere installation"
        echo "  $0 deploy                    # Deployer / mettre a jour"
        echo "  $0 logs backend              # Voir les logs du backend"
        echo "  $0 restart frontend          # Redemarrer le frontend"
        echo "  $0 ssl                        # Configurer SSL pour africans-world.org"
        exit 1
        ;;
esac