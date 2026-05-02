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

  # Ensure directory exists - no chown/chmod for mounted volumes
  mkdir -p "$PLAKAR_HOME"

  # Initialize as root (with security check disabled for root)
  # Plakar flags should come first, then 'at /path', then command
  $PLAKAR_BIN -disable-security-check at "$PLAKAR_HOME" create
fi

# Execute: if command is from docker-compose (sh -c sleep), keep container alive
# Otherwise execute plakar with the given arguments
if [ $# -eq 0 ] || [ "$1" = "sh" ] || [ "$1" = "bash" ]; then
  exec sleep infinity
else
  exec $PLAKAR_BIN -disable-security-check "$@"
fi
