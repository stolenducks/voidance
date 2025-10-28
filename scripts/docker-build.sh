#!/bin/bash
# Build Voidance ISO using Docker
# Usage: ./scripts/docker-build.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

info "Building Docker image..."
docker compose build

info "Starting container and building ISO..."
docker compose run --rm voidance-builder sh -c '
    set -e
    echo "===> Installing void-mklive if needed..."
    xbps-install -Syu void-mklive
    
    echo "===> Building ISO..."
    cd /workspace/scripts
    sh build-iso.sh
'

if [[ -f "$PROJECT_ROOT/voidance.iso" ]]; then
    info "✓ Build complete!"
    info "ISO location: $PROJECT_ROOT/voidance.iso"
    info "Size: $(du -h "$PROJECT_ROOT/voidance.iso" | cut -f1)"
    echo ""
    info "Next steps:"
    echo "  1. Test with QEMU: ./scripts/test-iso.sh"
    echo "  2. Flash to USB: sudo dd if=voidance.iso of=/dev/diskX bs=4m status=progress"
else
    warn "ISO file not found. Check build output for errors."
    exit 1
fi
