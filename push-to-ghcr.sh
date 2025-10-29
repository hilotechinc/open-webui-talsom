#!/bin/bash

# Script pour publier l'image Docker sur GitHub Container Registry
# Usage: ./push-to-ghcr.sh

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Push to GitHub Container Registry${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Configuration par défaut
LOCAL_IMAGE="open-webui-standalone:latest"
DEFAULT_USERNAME="TalsomMtl"
DEFAULT_IMAGE_NAME="open-webui"
DEFAULT_TAG="latest"

# Vérifier que l'image locale existe
echo -e "${YELLOW}[1/5] Vérification de l'image locale...${NC}"
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${LOCAL_IMAGE}$"; then
    echo -e "${RED}Erreur: Image ${LOCAL_IMAGE} introuvable${NC}"
    echo -e "${YELLOW}Images disponibles:${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
    exit 1
fi

IMAGE_SIZE=$(docker images --format "{{.Size}}" "${LOCAL_IMAGE}")
echo -e "${GREEN}✓ Image trouvée: ${LOCAL_IMAGE} (${IMAGE_SIZE})${NC}"
echo ""

# Demander les informations
echo -e "${YELLOW}[2/5] Configuration du registre...${NC}"
echo ""

read -p "Username/Organisation GitHub [${DEFAULT_USERNAME}]: " GITHUB_USERNAME
GITHUB_USERNAME=${GITHUB_USERNAME:-$DEFAULT_USERNAME}

read -p "Nom de l'image sur GHCR [${DEFAULT_IMAGE_NAME}]: " IMAGE_NAME
IMAGE_NAME=${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}

read -p "Tag de l'image [${DEFAULT_TAG}]: " IMAGE_TAG
IMAGE_TAG=${IMAGE_TAG:-$DEFAULT_TAG}

GHCR_IMAGE="ghcr.io/${GITHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

echo ""
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Image locale:  ${GREEN}${LOCAL_IMAGE}${NC}"
echo -e "  Image GHCR:    ${GREEN}${GHCR_IMAGE}${NC}"
echo ""

# Vérifier la connexion à GHCR
echo -e "${YELLOW}[3/5] Vérification de l'authentification...${NC}"
if ! docker info 2>/dev/null | grep -q "ghcr.io"; then
    echo -e "${YELLOW}Vous devez être connecté à ghcr.io${NC}"
    echo ""
    echo -e "${BLUE}Options de connexion:${NC}"
    echo -e "  1. Via Docker Desktop: Settings > Sign in"
    echo -e "  2. Via ligne de commande: docker login ghcr.io${NC}"
    echo ""
    read -p "Voulez-vous vous connecter maintenant? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}Connectez-vous avec votre username GitHub et un Personal Access Token${NC}"
        echo -e "${YELLOW}(Le token doit avoir les permissions 'write:packages')${NC}"
        echo ""
        docker login ghcr.io
    else
        echo -e "${RED}Connexion annulée${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Authentification vérifiée${NC}"
echo ""

# Tag l'image
echo -e "${YELLOW}[4/5] Tag de l'image...${NC}"
docker tag "${LOCAL_IMAGE}" "${GHCR_IMAGE}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Image taguée: ${GHCR_IMAGE}${NC}"
else
    echo -e "${RED}✗ Erreur lors du tag${NC}"
    exit 1
fi
echo ""

# Push l'image
echo -e "${YELLOW}[5/5] Push vers GitHub Container Registry...${NC}"
echo -e "${BLUE}Cela peut prendre plusieurs minutes selon la taille de l'image...${NC}"
echo ""

docker push "${GHCR_IMAGE}"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  Push réussi!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo -e "${BLUE}Image publiée:${NC}"
    echo -e "  ${GREEN}${GHCR_IMAGE}${NC}"
    echo ""
    echo -e "${BLUE}Pour rendre le package public:${NC}"
    echo -e "  1. Allez sur https://github.com/${GITHUB_USERNAME}?tab=packages"
    echo -e "  2. Cliquez sur le package '${IMAGE_NAME}'"
    echo -e "  3. Package settings > Change visibility > Public"
    echo ""
    echo -e "${BLUE}Pour pull l'image:${NC}"
    echo -e "  ${YELLOW}docker pull ${GHCR_IMAGE}${NC}"
    echo ""
    echo -e "${BLUE}Pour déployer:${NC}"
    echo -e "  ${YELLOW}docker run -d -p 8080:8080 \\"
    echo -e "    -v open-webui-data:/app/backend/data \\"
    echo -e "    --env-file .env \\"
    echo -e "    --restart unless-stopped \\"
    echo -e "    ${GHCR_IMAGE}${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}==========================================${NC}"
    echo -e "${RED}  Push échoué!${NC}"
    echo -e "${RED}==========================================${NC}"
    echo ""
    echo -e "${YELLOW}Vérifiez:${NC}"
    echo -e "  - Votre connexion à ghcr.io (docker login ghcr.io)"
    echo -e "  - Que votre token a les permissions 'write:packages'"
    echo -e "  - Que le nom de l'organisation/username est correct"
    echo ""
    exit 1
fi
