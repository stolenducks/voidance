#!/bin/bash
# Test Voidance ISO using QEMU
# Usage: ./scripts/test-iso.sh

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_PATH="$PROJECT_ROOT/voidance.iso"

# Check if ISO exists
if [[ ! -f "$ISO_PATH" ]]; then
    error "ISO not found at: $ISO_PATH"
    error "Build it first with: ./scripts/docker-build.sh"
    exit 1
fi

# Check if QEMU is installed
if ! command -v qemu-system-x86_64 &> /dev/null; then
    error "QEMU not installed. Install with: brew install qemu"
    exit 1
fi

info "Starting QEMU with Voidance ISO..."
info "ISO: $ISO_PATH"
echo ""
info "Tips:"
echo "  - Press Ctrl+Alt+G to release mouse"
echo "  - Press Ctrl+Alt+F to toggle fullscreen"
echo "  - Close window to exit"
echo ""

# Run QEMU with reasonable settings
qemu-system-x86_64 \
    -boot d \
    -cdrom "$ISO_PATH" \
    -m 4096 \
    -smp 2 \
    -cpu host \
    -machine type=q35,accel=hvf \
    -display cocoa \
    -device virtio-vga-gl \
    -display default,show-cursor=on \
    -usb \
    -device usb-tablet

info "QEMU session ended."
