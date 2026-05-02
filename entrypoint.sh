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

# Detect plakar command by looking for 'at' keyword (possibly after flags)
is_plakar_cmd=false
for arg in "$@"; do
  if [ "$arg" = "at" ]; then
    is_plakar_cmd=true
    break
  elif [ "${arg%%-*}" != "" ] && [ "${arg#-}" = "$arg" ]; then
    # Non-flag positional arg, stop looking
    break
  fi
done

if [ "$is_plakar_cmd" = "true" ]; then
  exec /usr/local/bin/plakar "$@"
elif [ $# -eq 0 ]; then
  exec sleep infinity
else
  # For non-plakar commands, execute directly
  exec "$@"
fi
