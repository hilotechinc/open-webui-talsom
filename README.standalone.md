# Open WebUI Standalone - Déploiement Sans Ollama

Ce guide explique comment déployer Open WebUI en mode standalone, **sans Ollama**, pour utiliser uniquement des APIs externes (OpenAI, Azure OpenAI, Anthropic, etc.).

## 📋 Prérequis

- Docker Desktop installé et démarré
- Git Bash ou terminal Linux/Mac
- Au moins 4 GB de RAM disponible
- 5 GB d'espace disque
- **Clés API** pour les services LLM externes (OpenAI, Azure, etc.)

## 🎯 Différence avec le déploiement standard

| Fonctionnalité | Standard | Standalone |
|----------------|----------|------------|
| Ollama inclus | ✅ Oui | ❌ Non |
| Modèles locaux | ✅ Oui (Llama, Mistral, etc.) | ❌ Non |
| APIs externes | ✅ Optionnel | ✅ Requis |
| GPU nécessaire | ⚠️ Recommandé | ❌ Non |
| RAM requise | 16+ GB | 4 GB |
| Espace disque | 20+ GB | 5 GB |
| Temps de démarrage | 5-10 min | 1-2 min |

## 🚀 Déploiement rapide

### Utiliser le script tout-en-un

```bash
cd /c/dev/workspace/open_webui-sync_fork/open-webui
./deploy-standalone.sh
```

**Ce script va:**
1. Vérifier Docker
2. Arrêter les conteneurs existants
3. Builder l'image (sans Ollama, sans CUDA)
4. Démarrer le conteneur
5. Vérifier la santé du service

**Temps estimé:** 10-15 minutes (premier build)

## ⚙️ Configuration des APIs externes

### Méthode 1: Fichier .env (RECOMMANDÉ)

Créez ou modifiez le fichier `c:/dev/workspace/open_webui-sync_fork/.env`:

```bash
# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_API_BASE_URL=https://api.openai.com/v1

# Azure OpenAI
AZURE_OPENAI_API_KEY=...
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# Autres variables
WEBUI_NAME=Mon Open WebUI
DO_NOT_TRACK=true
```

Ensuite, relancez le déploiement:

```bash
./deploy-standalone.sh
```

### Méthode 2: Configuration via l'interface web

1. Accédez à `http://localhost:8080`
2. Créez un compte administrateur
3. Allez dans **Settings** → **Connections**
4. Configurez vos APIs:
   - **OpenAI API:** Ajoutez votre clé API
   - **Azure OpenAI:** Endpoint + clé + version
   - **Anthropic:** Clé API Claude

## 🌐 Accès à l'application

Une fois déployé, Open WebUI est accessible sur:

**http://localhost:8080**

### Premier lancement

1. Créez un compte administrateur (premier utilisateur = admin)
2. Configurez vos connexions API dans Settings
3. Commencez à utiliser les modèles externes

## 📁 Structure des données

Les données sont stockées dans un volume Docker:

- **Volume:** `open-webui-data`
- **Contenu:** Base de données SQLite, uploads, paramètres

### Voir les volumes

```bash
docker volume ls | grep open-webui
```

### Inspecter le volume

```bash
docker volume inspect open-webui-data
```

### Sauvegarder les données

```bash
# Créer une sauvegarde
docker run --rm -v open-webui-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/open-webui-backup.tar.gz -C /data .

# Restaurer une sauvegarde
docker run --rm -v open-webui-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/open-webui-backup.tar.gz -C /data
```

## 🔧 Commandes utiles

### Voir les logs en temps réel

```bash
docker logs -f open-webui-standalone
```

### Arrêter le conteneur

```bash
docker stop open-webui-standalone
```

### Redémarrer le conteneur

```bash
docker restart open-webui-standalone
```

### Voir le statut

```bash
docker ps --filter "name=open-webui-standalone"
```

### Entrer dans le conteneur

```bash
docker exec -it open-webui-standalone bash
```

### Supprimer complètement

```bash
# Arrêter et supprimer le conteneur
docker rm -f open-webui-standalone

# Supprimer l'image
docker rmi open-webui-standalone:latest

# Supprimer les données (⚠️ ATTENTION: perte définitive)
docker volume rm open-webui-data
```

### Rebuild complet

```bash
# Supprimer le conteneur existant
docker rm -f open-webui-standalone

# Supprimer l'ancienne image
docker rmi open-webui-standalone:latest

# Rebuild et redéployer
./deploy-standalone.sh
```

## 🐛 Dépannage

### Le conteneur redémarre en boucle

Vérifiez les logs:

```bash
docker logs open-webui-standalone --tail=100
```

Causes communes:
- Clé API invalide (vérifiez dans les logs)
- Mémoire insuffisante (augmentez à 4GB minimum)
- Port 8080 déjà utilisé

### Port 8080 déjà utilisé

Modifiez le port dans `deploy-standalone.sh`:

```bash
PORT="3000"  # Changez 8080 en 3000 (ou autre)
```

Puis relancez le script. Accès via `http://localhost:3000`

### Erreur "Cannot connect to APIs"

1. Vérifiez vos clés API dans le fichier `.env`
2. Vérifiez les logs pour voir les erreurs d'authentification:
   ```bash
   docker logs open-webui-standalone | grep -i "error\|api"
   ```
3. Testez vos clés API manuellement:
   ```bash
   curl https://api.openai.com/v1/models \
     -H "Authorization: Bearer $OPENAI_API_KEY"
   ```

### Erreur de mémoire lors du build

Augmentez la mémoire allouée à Docker Desktop:
- Ouvrir Docker Desktop
- Settings > Resources > Memory
- Augmenter à au moins 4 GB

### Le service ne répond pas

Attendez 1-2 minutes après le démarrage, puis vérifiez:

```bash
# Vérifier si le processus tourne
docker exec open-webui-standalone ps aux | grep python

# Vérifier les connexions réseau
curl -I http://localhost:8080
```

## 📦 Partager l'image avec un collègue

### Option 1: Exporter en fichier TAR

```bash
# Exporter l'image
docker save open-webui-standalone:latest | gzip > open-webui-standalone.tar.gz

# Partager le fichier .tar.gz (environ 2-3 GB)

# Votre collègue importe:
docker load < open-webui-standalone.tar.gz
docker run -d -p 8080:8080 -v open-webui-data:/app/backend/data \
  --name open-webui-standalone open-webui-standalone:latest
```

### Option 2: Pousser vers Docker Hub

```bash
# Login
docker login

# Tag l'image
docker tag open-webui-standalone:latest votre-username/open-webui-standalone:latest

# Push
docker push votre-username/open-webui-standalone:latest

# Votre collègue pull et run:
docker pull votre-username/open-webui-standalone:latest
docker run -d -p 8080:8080 -v open-webui-data:/app/backend/data \
  --name open-webui-standalone votre-username/open-webui-standalone:latest
```

### Option 3: Partager le code source

Partagez simplement ce répertoire avec votre collègue.
Il pourra déployer avec `./deploy-standalone.sh`

## 📊 Ressources système

### Utilisation typique:
- **CPU:** 5-15% (au repos)
- **RAM:** 1-2 GB (sans modèles locaux)
- **Disque:** 3-5 GB (image + données)

### Voir l'utilisation:

```bash
docker stats open-webui-standalone
```

## 🔒 Sécurité

### Générer une clé secrète forte

```bash
# Générer une clé aléatoire
openssl rand -base64 32

# Ajouter dans .env
echo "WEBUI_SECRET_KEY=$(openssl rand -base64 32)" >> ../.env
```

### Activer HTTPS (production)

Pour un déploiement en production, utilisez un reverse proxy (Nginx, Traefik, Caddy) avec SSL.

Exemple avec Caddy:

```caddyfile
your-domain.com {
    reverse_proxy localhost:8080
}
```

## 🌐 APIs supportées

Open WebUI supporte les APIs suivantes en mode standalone:

### OpenAI
- GPT-4, GPT-4 Turbo, GPT-3.5 Turbo
- Configuration: `OPENAI_API_KEY` + `OPENAI_API_BASE_URL`

### Azure OpenAI
- Tous les modèles déployés sur Azure
- Configuration: `AZURE_OPENAI_API_KEY` + `AZURE_OPENAI_ENDPOINT`

### Anthropic
- Claude 3 (Opus, Sonnet, Haiku)
- Configuration: `ANTHROPIC_API_KEY`

### Autres compatibles OpenAI
- Together AI
- Anyscale
- Groq
- Mistral AI
- Perplexity
- Tout service compatible avec l'API OpenAI

## 🔗 Liens utiles

- [Documentation Open WebUI](https://docs.openwebui.com/)
- [GitHub Open WebUI](https://github.com/open-webui/open-webui)
- [Documentation OpenAI API](https://platform.openai.com/docs)
- [Documentation Azure OpenAI](https://learn.microsoft.com/azure/ai-services/openai/)
- [Documentation Anthropic API](https://docs.anthropic.com/)

## ✅ Checklist de déploiement

- [ ] Docker Desktop installé et démarré
- [ ] Clés API obtenues (OpenAI, Azure, ou autre)
- [ ] Fichier `.env` configuré avec les clés API
- [ ] Port 8080 disponible
- [ ] Au moins 4 GB RAM disponible
- [ ] Exécuter `./deploy-standalone.sh`
- [ ] Vérifier http://localhost:8080
- [ ] Créer un compte administrateur
- [ ] Configurer les connexions API dans Settings
- [ ] Tester avec un premier message

## 📝 Notes importantes

- **Base de données:** SQLite (locale, pas de configuration nécessaire)
- **Ollama:** **NON inclus** - utilisez uniquement des APIs externes
- **Pipelines:** NON inclus (pour ajouter Pipelines, voir docker-compose-combined.yml)
- **CUDA/GPU:** Désactivé (pas nécessaire sans modèles locaux)
- **Modèles locaux:** NON supportés dans cette configuration

## 🆘 Support

Si vous rencontrez des problèmes:

1. Vérifiez les logs: `docker logs open-webui-standalone`
2. Vérifiez votre configuration `.env`
3. Consultez la [documentation officielle](https://docs.openwebui.com/)
4. Ouvrez une issue sur [GitHub](https://github.com/open-webui/open-webui/issues)

## 🔄 Mise à jour

Pour mettre à jour vers la dernière version:

```bash
# Arrêter le conteneur actuel
docker stop open-webui-standalone
docker rm open-webui-standalone

# Supprimer l'ancienne image
docker rmi open-webui-standalone:latest

# Rebuild avec la dernière version
cd /c/dev/workspace/open_webui-sync_fork/open-webui
git pull  # Si vous utilisez Git
./deploy-standalone.sh
```

**Note:** Vos données dans le volume `open-webui-data` sont préservées!
