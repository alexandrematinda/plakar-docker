#!/bin/sh
set -e

INIT=${INIT:=false}
P_PATH=${P_PATH:=/home/plakar/.plakar}

if [ "${INIT}" = "true" ]; then
  echo "[plakar-init] Creating repository at ${P_PATH}"
  mkdir -p "$(dirname "$P_PATH")"

  # Create the repository
  /usr/local/bin/plakar at "${P_PATH}" create

  # Configure S3 store if credentials provided
  if [ -n "$S3_ACCESS_KEY_ID" ] && [ -n "$S3_SECRET_ACCESS_KEY" ] && [ -n "$S3_BUCKET" ] && [ -n "$S3_ENDPOINT" ]; then
    echo "[plakar-init] Configuring S3 store..."
    # Strip https:// or http:// from endpoint if present
    S3_HOST="${S3_ENDPOINT#https://}"
    S3_HOST="${S3_HOST#http://}"
    S3_LOCATION="s3://${S3_ACCESS_KEY_ID}:${S3_SECRET_ACCESS_KEY}@${S3_HOST}/${S3_BUCKET}"
    /usr/local/bin/plakar -disable-security-check at "${P_PATH}" store add s3-backup "location=${S3_LOCATION}" || true
  fi

  echo "[plakar-init] Repository initialized successfully"
fi

# If no command provided, keep container alive
if [ $# -eq 0 ]; then
  exec sleep infinity
fi

# If first arg is "at", it's a plakar command (e.g., "at /path backup /data")
# Otherwise, treat it as a shell command
if [ "$1" = "at" ]; then
  exec /usr/local/bin/plakar "$@"
else
  # For non-plakar commands, execute directly
  exec "$@"
fi
