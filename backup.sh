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

# Run backup
echo "Starting backup of $BACKUP_SOURCE..."
docker-compose exec -T plakar /usr/local/bin/plakar -disable-security-check backup "$BACKUP_SOURCE"
echo "Backup completed successfully!"

# List snapshots
echo ""
echo "Recent snapshots:"
docker-compose exec -T plakar /usr/local/bin/plakar ls
