#!/bin/bash
set -e

# Load environment variables
source "$(dirname "$0")/.env"

# Validate required variables
if [ -z "$PLAKAR_PASSPHRASE" ]; then
  echo "ERROR: PLAKAR_PASSPHRASE not set in .env"
  exit 1
fi

if [ -z "$BACKUP_SOURCE" ]; then
  echo "ERROR: BACKUP_SOURCE not set in .env"
  exit 1
fi

if [ -z "$PLAKAR_HOME" ]; then
  echo "ERROR: PLAKAR_HOME not set in .env"
  exit 1
fi

# Find docker-compose: try 'docker compose' first (Docker 20.10+), then 'docker-compose'
if command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE="docker-compose"
elif /usr/local/bin/docker compose version &> /dev/null 2>&1; then
  DOCKER_COMPOSE="/usr/local/bin/docker compose"
else
  DOCKER_COMPOSE="docker-compose"
fi

# Run backup
echo "Starting backup of $BACKUP_SOURCE..."
$DOCKER_COMPOSE exec -T plakar /usr/local/bin/plakar -disable-security-check backup "$BACKUP_SOURCE"
echo "Backup completed successfully!"

# List snapshots
echo ""
echo "Recent snapshots:"
$DOCKER_COMPOSE exec -T plakar /usr/local/bin/plakar -disable-security-check ls
