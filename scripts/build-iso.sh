#!/bin/bash
# Voidance ISO Build Script
# Builds a custom Void Linux ISO with Hyprland and curated packages

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if running as root (skip in Docker)
if [[ $EUID -ne 0 ]] && [[ ! -f /.dockerenv ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

# Check if void-mklive is installed
if ! command -v mklive.sh &> /dev/null; then
    error "void-mklive not found. Install it with: xbps-install -S void-mklive"
    exit 1
fi

# Variables
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/iso-builder"
PACKAGE_LIST="${PROJECT_ROOT}/packages/packages.txt"
OUTPUT_ISO="${PROJECT_ROOT}/voidance.iso"
ARCH="x86_64"  # Target architecture
VARIANT="glibc" # Use glibc for better compatibility (musl as alternative)

info "Starting Voidance ISO build..."
info "Project root: ${PROJECT_ROOT}"
info "Architecture: ${ARCH}"
info "Variant: ${VARIANT}"

# Clean previous build artifacts
if [[ -d "${BUILD_DIR}/tmp" ]]; then
    warn "Cleaning previous build artifacts..."
    rm -rf "${BUILD_DIR}/tmp"
fi

# Prepare package list (remove comments and empty lines)
info "Preparing package list..."
PKG_ARGS=""
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    PKG_ARGS="${PKG_ARGS} -p ${line}"
done < "${PACKAGE_LIST}"

info "Building ISO with void-mklive..."
info "This may take 10-30 minutes depending on your system..."

# Build the ISO
# Note: Adjust options as needed
# -a: architecture
# -o: output ISO name
# -p: package to include (repeated for each package)
cd "${BUILD_DIR}"

mklive.sh \
    -a "${ARCH}" \
    -o "${OUTPUT_ISO}" \
    -T "Voidance - Void Linux with Hyprland" \
    ${PKG_ARGS}

# Check if ISO was created
if [[ -f "${OUTPUT_ISO}" ]]; then
    info "✓ ISO build successful!"
    info "Output: ${OUTPUT_ISO}"
    info "Size: $(du -h "${OUTPUT_ISO}" | cut -f1)"
    echo ""
    info "Next steps:"
    echo "  1. Test in VM: qemu-system-x86_64 -boot d -cdrom voidance.iso -m 4096 -enable-kvm"
    echo "  2. Flash to USB: sudo dd if=voidance.iso of=/dev/sdX bs=4M status=progress"
    echo ""
else
    error "ISO build failed. Check output above for errors."
    exit 1
fi

