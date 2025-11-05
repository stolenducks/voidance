#!/bin/bash
# build-in-docker.sh - Build Void XFCE-AI ISO on macOS using Docker
# Uses a pinned Void Linux container for reproducible builds

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[docker-build]${NC} $*"; }
error() { echo -e "${RED}[docker-build]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[docker-build]${NC} $*"; }

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VOID_IMAGE="ghcr.io/void-linux/void-glibc:latest"  # Pinned image
DATE=$(date +%Y%m%d)

info "Building Void Linux XFCE - AI Edition ISO on macOS"
info "Using Docker container: $VOID_IMAGE"
echo ""

# Check if Docker is running
if ! docker info &>/dev/null; then
    error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Pull Void Linux image
info "Pulling Void Linux container image..."
docker pull "$VOID_IMAGE"

# Build ISO inside container
info "Starting ISO build in Docker container..."
info "This may take 20-40 minutes depending on your system..."
echo ""

# Run build with SOURCE_DATE_EPOCH for reproducibility
docker run --rm \
    --privileged \
    -v "$PROJECT_ROOT:/workspace" \
    -w /workspace \
    -e SOURCE_DATE_EPOCH="$(date +%s)" \
    -e TZ=UTC \
    "$VOID_IMAGE" \
    bash -c "
        set -euo pipefail
        
        # Update package cache
        echo '[docker] Updating package cache...'
        xbps-install -Suy xbps
        
        # Install build dependencies
        echo '[docker] Installing build dependencies...'
        xbps-install -y void-mklive git wget curl
        
        # Run the build script
        echo '[docker] Running build-iso.sh...'
        bash /workspace/scripts/build-iso.sh
    "

# Check if ISO was created
ISO_PATH="$PROJECT_ROOT/dist/void-xfce-ai-${DATE}.iso"
if [[ -f "$ISO_PATH" ]]; then
    echo ""
    info "✓ Docker build successful!"
    info "Output: $ISO_PATH"
    info "Size: $(du -h "$ISO_PATH" | cut -f1)"
    echo ""
    info "Next steps:"
    echo "  1. Test in VM: cd testing && ./test-iso.sh"
    echo "  2. Flash to USB: sudo dd if=$ISO_PATH of=/dev/diskX bs=4m"
    echo ""
else
    error "ISO build failed. Check output above for errors."
    exit 1
fi
