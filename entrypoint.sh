#!/bin/sh
set -e

# Initialize kloset if it doesn't exist
if [ ! -f "/home/plakar/.plakar/CONFIG" ]; then
  echo "Initializing plakar repository..."
  if [ -z "$PLAKAR_PASSPHRASE" ]; then
    echo "ERROR: PLAKAR_PASSPHRASE not set. Cannot initialize repository."
    exit 1
  fi
  plakar create
fi

# Execute the command passed to the container
exec "$@"
