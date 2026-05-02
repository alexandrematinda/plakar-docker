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

  # Configure S3 store if variables are set
  if [ -n "$S3_ACCESS_KEY_ID" ] && [ -n "$S3_SECRET_ACCESS_KEY" ] && [ -n "$S3_BUCKET" ] && [ -n "$S3_ENDPOINT" ]; then
    echo "Configuring S3 store..."
    plakar store add s3-store \
      location="s3://${S3_ACCESS_KEY_ID}:${S3_SECRET_ACCESS_KEY}@${S3_ENDPOINT}/${S3_BUCKET}"
  fi
fi

# Execute the command passed to the container
# Prepend "plakar" if the first argument is a subcommand (agent, ui, etc.)
if [ $# -gt 0 ]; then
  exec plakar "$@"
else
  exec plakar
fi
