#!/bin/sh
set -e

INIT=${INIT:=false}
P_PATH=${P_PATH:=/home/plakar/.plakar}

if [ "${INIT}" = "true" ]; then
  echo "[plakar-init] Creating local repository at ${P_PATH}"
  mkdir -p "$(dirname "$P_PATH")"

  # Create the local repository
  /usr/local/bin/plakar at "${P_PATH}" create

  # Configure rclone for S3 sync if credentials provided
  if [ -n "$S3_ACCESS_KEY_ID" ] && [ -n "$S3_SECRET_ACCESS_KEY" ] && [ -n "$S3_BUCKET" ] && [ -n "$S3_ENDPOINT" ]; then
    echo "[plakar-init] Configuring rclone for S3..."
    mkdir -p /home/plakar/.config/rclone

    # Create rclone config for Infomaniak S3
    cat > /home/plakar/.config/rclone/rclone.conf << RCLONEEOF
[infomaniak]
type = s3
provider = Other
access_key_id = ${S3_ACCESS_KEY_ID}
secret_access_key = ${S3_SECRET_ACCESS_KEY}
endpoint = https://${S3_ENDPOINT}
RCLONEEOF

    echo "[plakar-init] rclone configured for S3 sync"
    echo "[plakar-init] Use: rclone sync ${P_PATH}/packfiles infomaniak:${S3_BUCKET}/packfiles"
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
