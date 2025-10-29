#!/bin/bash

# Script de déploiement tout-en-un pour Open WebUI Standalone (sans Ollama)
# Usage: ./deploy-standalone.sh

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CONTAINER_NAME="open-webui-standalone"
IMAGE_NAME="open-webui-standalone"
PORT="8080"
VOLUME_NAME="open-webui-data"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Open WebUI Standalone Deployment${NC}"
echo -e "${BLUE}  (Sans Ollama - APIs externes)${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Vérifier Docker
echo -e "${YELLOW}[1/5] Vérification de Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Erreur: Docker n'est pas installé${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Erreur: Docker daemon n'est pas démarré${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker est opérationnel${NC}"
echo ""

# Vérifier Dockerfile
echo -e "${YELLOW}[2/5] Vérification des fichiers...${NC}"
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}Erreur: Dockerfile introuvable${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Dockerfile trouvé${NC}"
echo ""

# Arrêter conteneur existant
echo -e "${YELLOW}[3/5] Arrêt du conteneur existant...${NC}"
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
    echo -e "${GREEN}✓ Conteneur existant arrêté et supprimé${NC}"
else
    echo -e "${BLUE}Aucun conteneur existant${NC}"
fi
echo ""

# Build de l'image
echo -e "${YELLOW}[4/5] Build de l'image Docker...${NC}"
echo -e "${BLUE}Cela peut prendre 10-15 minutes (premier build)...${NC}"
echo ""

docker build \
  --build-arg USE_OLLAMA=false \
  --build-arg USE_CUDA=false \
  --build-arg USE_SLIM=false \
  -t "${IMAGE_NAME}:latest" \
  -f Dockerfile \
  .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Image buildée avec succès${NC}"
else
    echo ""
    echo -e "${RED}✗ Erreur lors du build${NC}"
    exit 1
fi
echo ""

# Créer le volume si nécessaire
if ! docker volume ls | grep -q "^${VOLUME_NAME}$"; then
    docker volume create "${VOLUME_NAME}"
    echo -e "${GREEN}✓ Volume créé: ${VOLUME_NAME}${NC}"
fi

# Démarrer le conteneur
echo -e "${YELLOW}[5/5] Démarrage du conteneur...${NC}"

# Charger les variables d'environnement depuis .env s'il existe
ENV_FILE=".env"

if [ -f "$ENV_FILE" ]; then
    echo -e "${BLUE}Chargement de toutes les variables depuis ${ENV_FILE}${NC}"
else
    echo -e "${YELLOW}Aucun fichier .env trouvé - utilisation des valeurs par défaut${NC}"
fi

# Démarrer le conteneur avec --env-file pour charger automatiquement toutes les variables
# Cela inclut: CLIENT_LOGO_URL, CHAT_LOGO_URL, OPENAI_API_KEY, etc.
DOCKER_RUN_CMD="docker run -d \
  --name \"${CONTAINER_NAME}\" \
  -p \"${PORT}:8080\" \
  -v \"${VOLUME_NAME}:/app/backend/data\""

# Ajouter --env-file si le fichier .env existe
if [ -f "$ENV_FILE" ]; then
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD \
  --env-file \"${ENV_FILE}\""
fi

# Variables d'environnement de base (peuvent être overridées par .env)
DOCKER_RUN_CMD="$DOCKER_RUN_CMD \
  -e PORT=8080 \
  -e ENV=prod \
  -e WEBUI_NAME=\"Open WebUI\" \
  -e ENABLE_OLLAMA_API=false \
  -e DO_NOT_TRACK=true \
  -e SCARF_NO_ANALYTICS=true \
  -e ANONYMIZED_TELEMETRY=false \
  --restart unless-stopped \
  \"${IMAGE_NAME}:latest\""

# Exécuter la commande
eval $DOCKER_RUN_CMD

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Conteneur démarré${NC}"
else
    echo -e "${RED}✗ Erreur lors du démarrage${NC}"
    exit 1
fi
echo ""

# Attendre le démarrage
echo -e "${YELLOW}Attente du démarrage du service...${NC}"
sleep 10

# Vérifier le statut
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "not found")

if [ "$CONTAINER_STATUS" = "running" ]; then
    echo -e "${GREEN}✓ Conteneur en cours d'exécution${NC}"
    echo ""

    # Attendre que le service réponde
    echo -e "${YELLOW}Vérification de la disponibilité du service...${NC}"
    for i in {1..30}; do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT} 2>/dev/null || echo "000")
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "307" ]; then
            echo -e "${GREEN}✓ Service accessible!${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""

    # Afficher les logs récents
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  Logs récents${NC}"
    echo -e "${BLUE}==========================================${NC}"
    docker logs --tail=20 "${CONTAINER_NAME}"
    echo ""

    # Statut du conteneur
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  Statut du conteneur${NC}"
    echo -e "${BLUE}==========================================${NC}"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""

    # Succès
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  Déploiement réussi!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo -e "${BLUE}Open WebUI est accessible sur:${NC}"
    echo -e "  ${GREEN}http://localhost:${PORT}${NC}"
    echo ""
    echo -e "${BLUE}Commandes utiles:${NC}"
    echo -e "  Voir les logs:   ${YELLOW}docker logs -f ${CONTAINER_NAME}${NC}"
    echo -e "  Arrêter:         ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
    echo -e "  Redémarrer:      ${YELLOW}docker restart ${CONTAINER_NAME}${NC}"
    echo -e "  Supprimer:       ${YELLOW}docker rm -f ${CONTAINER_NAME}${NC}"
    echo ""
    echo -e "${BLUE}Configuration des APIs:${NC}"
    echo -e "  Connectez-vous sur http://localhost:${PORT}"
    echo -e "  Allez dans Settings > Connections"
    echo -e "  Configurez OpenAI, Azure, Anthropic, etc."
    echo ""

else
    echo -e "${RED}✗ Le conteneur n'a pas démarré correctement${NC}"
    echo ""
    echo -e "${YELLOW}Logs d'erreur:${NC}"
    docker logs --tail=50 "${CONTAINER_NAME}"
    exit 1
fi
