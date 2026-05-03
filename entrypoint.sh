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

# Setup rclone cron job for sync (if configured)
if [ -n "$S3_ACCESS_KEY_ID" ] && [ -n "$S3_SECRET_ACCESS_KEY" ] && [ -n "$S3_BUCKET" ]; then
  echo "[plakar-init] Setting up rclone sync cron job..."
  mkdir -p /home/plakar/.config/rclone

  # Create rclone config
  cat > /home/plakar/.config/rclone/rclone.conf << RCLONEEOF
[infomaniak]
type = s3
provider = Other
access_key_id = ${S3_ACCESS_KEY_ID}
secret_access_key = ${S3_SECRET_ACCESS_KEY}
endpoint = https://${S3_ENDPOINT}
RCLONEEOF

  # Create cron job for hourly sync
  mkdir -p /etc/cron.hourly
  cat > /etc/cron.hourly/plakar-sync << CRONEOF
#!/bin/sh
/usr/bin/rclone sync /home/plakar/.plakar/packfiles infomaniak:${S3_BUCKET}/plakar-backup/packfiles -q 2>&1 | logger -t plakar-sync
CRONEOF
  chmod +x /etc/cron.hourly/plakar-sync
  echo "[plakar-init] rclone sync configured for hourly execution"
fi

# If no command provided, run agent or keep alive
if [ $# -eq 0 ]; then
  # Start crond daemon if it exists
  if command -v crond >/dev/null 2>&1; then
    echo "[plakar-entrypoint] Starting cron daemon..."
    crond -f &
    CROND_PID=$!
  fi

  # If SCHEDULER_FILE exists, run plakar agent
  if [ -f "$SCHEDULER_FILE" ]; then
    echo "[plakar-entrypoint] Starting plakar agent with scheduler..."
    exec /usr/local/bin/plakar agent -tasks "$SCHEDULER_FILE"
  else
    # No scheduler, just keep alive
    echo "[plakar-entrypoint] No scheduler configured, keeping container alive..."
    exec sleep infinity
  fi
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
else
  # For non-plakar commands, execute directly
  exec "$@"
fi
