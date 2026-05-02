#!/bin/bash
set -e

PLAKAR_BIN="/usr/local/bin/plakar"
PLAKAR_HOME="/home/plakar/.plakar"

# Initialize kloset if it doesn't exist
if [ ! -f "$PLAKAR_HOME/CONFIG" ]; then
  echo "Initializing plakar repository..."
  if [ -z "$PLAKAR_PASSPHRASE" ]; then
    echo "ERROR: PLAKAR_PASSPHRASE not set. Cannot initialize repository."
    exit 1
  fi

  # Ensure directory exists with correct permissions
  mkdir -p "$PLAKAR_HOME"
  chown plakar:plakar "$PLAKAR_HOME"
  chmod 700 "$PLAKAR_HOME"

  # Initialize as root (with security check disabled for root)
  echo "Running: $PLAKAR_BIN -disable-security-check create"
  $PLAKAR_BIN -disable-security-check create 2>&1 || true
  echo "Create exit code: $?"

  # Note: S3 store configuration is disabled - configure manually via docker-compose exec if needed
  # To add S3 store manually, run:
  # docker-compose exec -T plakar plakar -disable-security-check store add s3-store location="s3://KEY:SECRET@HOST:443/BUCKET"

  # Ensure plakar owns the created files
  chown -R plakar:plakar "$PLAKAR_HOME"
fi

# Execute: if command is from docker-compose (sh -c sleep), keep container alive
# Otherwise execute plakar with the given arguments
if [ $# -eq 0 ] || [ "$1" = "sh" ] || [ "$1" = "bash" ]; then
  exec sleep infinity
else
  exec $PLAKAR_BIN -disable-security-check "$@"
fi
