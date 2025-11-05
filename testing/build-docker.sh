#!/bin/bash
# Helper script to build Voidance ISO using Docker

set -e

echo "🚀 Building Voidance ISO in Docker..."

# Start interactive container
docker run --platform linux/amd64 -it --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  ghcr.io/void-linux/void-glibc:latest \
  sh -c "
    echo '📦 Installing dependencies...'
    xbps-install -Syu || echo 'Repo sync failed, trying with cached packages...'
    xbps-install -y void-mklive bash || echo 'Some packages may be missing'
    
    if [ -x /bin/bash ] || [ -x /usr/bin/bash ]; then
      echo '🔨 Building ISO with bash...'
      bash ./scripts/build-iso.sh
    else
      echo '🔨 Building ISO with sh...'
      sh ./scripts/build-iso.sh
    fi
  "

echo "✅ Build complete! ISO should be at ./voidance.iso"
