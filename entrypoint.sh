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

  # Ensure directory exists and has correct permissions
  mkdir -p "$PLAKAR_HOME"
  chown plakar:plakar "$PLAKAR_HOME"
  chmod 700 "$PLAKAR_HOME"

  # Run as plakar user for initialization
  su - plakar -c "$PLAKAR_BIN create"

  # Configure S3 store if variables are set
  if [ -n "$S3_ACCESS_KEY_ID" ] && [ -n "$S3_SECRET_ACCESS_KEY" ] && [ -n "$S3_BUCKET" ] && [ -n "$S3_ENDPOINT" ]; then
    echo "Configuring S3 store..."
    su - plakar -c "$PLAKAR_BIN store add s3-store location=\"s3://${S3_ACCESS_KEY_ID}:${S3_SECRET_ACCESS_KEY}@${S3_ENDPOINT}/${S3_BUCKET}\""
  fi

  # Ensure correct permissions after initialization
  chown -R plakar:plakar "$PLAKAR_HOME"
  chmod 700 "$PLAKAR_HOME"
fi

# Execute the command passed to the container as plakar user
if [ $# -gt 0 ]; then
  exec su - plakar -c "$PLAKAR_BIN $*"
else
  exec su - plakar -c "$PLAKAR_BIN"
fi
