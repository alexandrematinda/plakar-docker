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
  $PLAKAR_BIN -disable-security-check create

  # Configure S3 store if variables are set (with proper endpoint handling)
  if [ -n "$S3_ACCESS_KEY_ID" ] && [ -n "$S3_SECRET_ACCESS_KEY" ] && [ -n "$S3_BUCKET" ] && [ -n "$S3_ENDPOINT" ]; then
    echo "Configuring S3 store..."
    # Remove https:// prefix from endpoint if present (plakar doesn't expect it in the location URI)
    ENDPOINT_HOST="${S3_ENDPOINT#https://}"
    ENDPOINT_HOST="${ENDPOINT_HOST#http://}"
    $PLAKAR_BIN -disable-security-check store add s3-store \
      location="s3://${S3_ACCESS_KEY_ID}:${S3_SECRET_ACCESS_KEY}@${ENDPOINT_HOST}:443/${S3_BUCKET}"
  fi

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
