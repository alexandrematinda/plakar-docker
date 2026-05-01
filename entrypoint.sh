#!/bin/sh
set -e

# Initialize kloset if it doesn't exist
if [ ! -f "/home/plakar/.plakar/CONFIG" ]; then
  echo "Initializing plakar repository..."
  plakar repository create
fi

# Execute the command passed to the container
exec "$@"
