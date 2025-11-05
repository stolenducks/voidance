#!/bin/bash
# Void Linux XFCE - AI Edition ISO Build Script
# Builds a stock XFCE ISO with embedded AI helper

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[build-iso]${NC} $*"; }
error() { echo -e "${RED}[build-iso]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[build-iso]${NC} $*"; }

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
PACKAGE_LIST="${PROJECT_ROOT}/packages/xfce-base.txt"
DIST_DIR="${PROJECT_ROOT}/dist"
DATE=$(date +%Y%m%d)
OUTPUT_ISO="${DIST_DIR}/void-xfce-ai-${DATE}.iso"
ARCH="x86_64"
VARIANT="glibc"
ROOTFS_OVERLAY="${BUILD_DIR}/rootfs_overlay"

# Reproducibility settings
export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(date +%s)}
export TZ=UTC

info "Building Void Linux XFCE - AI Edition ISO"
info "Project root: ${PROJECT_ROOT}"
info "Architecture: ${ARCH} (${VARIANT})"
info "Output: ${OUTPUT_ISO}"
echo ""

# Step 1: Fetch AI assets
info "Step 1/4: Fetching AI assets..."
if [[ ! -f "${PROJECT_ROOT}/iso-builder/ai-assets/.fetched" ]]; then
    bash "${PROJECT_ROOT}/scripts/fetch-ai-assets.sh"
else
    warn "AI assets already fetched, skipping download"
fi

# Step 2: Prepare rootfs overlay
info "Step 2/4: Preparing rootfs overlay..."
rm -rf "${ROOTFS_OVERLAY}"
mkdir -p "${ROOTFS_OVERLAY}"

# Copy AI helper files
info "Copying droid CLI..."
mkdir -p "${ROOTFS_OVERLAY}/usr/local/bin"
cp "${PROJECT_ROOT}/rootfs/usr/local/bin/droid" "${ROOTFS_OVERLAY}/usr/local/bin/"
chmod +x "${ROOTFS_OVERLAY}/usr/local/bin/droid"

# Copy droid-firstboot service
info "Copying first-boot service..."
mkdir -p "${ROOTFS_OVERLAY}/etc/sv/droid-firstboot"
cp "${PROJECT_ROOT}/rootfs/etc/sv/droid-firstboot/run" "${ROOTFS_OVERLAY}/etc/sv/droid-firstboot/"
chmod +x "${ROOTFS_OVERLAY}/etc/sv/droid-firstboot/run"

# Enable droid-firstboot in the ISO (will run once on first boot)
mkdir -p "${ROOTFS_OVERLAY}/etc/runit/runsvdir/default"
ln -sf /etc/sv/droid-firstboot "${ROOTFS_OVERLAY}/etc/runit/runsvdir/default/droid-firstboot"

# Copy AI assets
info "Copying AI model and docs..."
mkdir -p "${ROOTFS_OVERLAY}/opt/droid/models"
cp "${PROJECT_ROOT}/rootfs/opt/droid/Modelfile" "${ROOTFS_OVERLAY}/opt/droid/"

# Copy model if it exists
if [[ -f "${PROJECT_ROOT}/iso-builder/ai-assets/models/qwen2.5-coder-3b-instruct.Q4_K_M.gguf" ]]; then
    info "Embedding AI model into ISO (~2GB, this may take a minute)..."
    cp "${PROJECT_ROOT}/iso-builder/ai-assets/models/"*.gguf "${ROOTFS_OVERLAY}/opt/droid/models/"
else
    warn "AI model not found, ISO will require manual setup"
fi

# Copy Void docs if they exist
if [[ -d "${PROJECT_ROOT}/iso-builder/ai-assets/void-docs" ]]; then
    info "Embedding Void Linux documentation..."
    mkdir -p "${ROOTFS_OVERLAY}/opt"
    cp -r "${PROJECT_ROOT}/iso-builder/ai-assets/void-docs" "${ROOTFS_OVERLAY}/opt/"
fi

# Step 3: Prepare package list
info "Step 3/4: Preparing package list..."
if [[ ! -f "${PACKAGE_LIST}" ]]; then
    error "Package list not found: ${PACKAGE_LIST}"
    exit 1
fi

PKG_ARGS=""
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    PKG_ARGS="${PKG_ARGS} -p ${line}"
done < "${PACKAGE_LIST}"

# Step 4: Build ISO with void-mklive
info "Step 4/4: Building ISO with void-mklive..."
info "This may take 15-30 minutes depending on your system..."
echo ""

# Clean previous build
if [[ -d "${BUILD_DIR}/tmp" ]]; then
    warn "Cleaning previous build artifacts..."
    rm -rf "${BUILD_DIR}/tmp"
fi

# Create output directory
mkdir -p "${DIST_DIR}"

cd "${BUILD_DIR}"

# Build with XFCE profile
# Note: We use -I to include our rootfs overlay
mklive.sh \
    -a "${ARCH}" \
    -l "${VARIANT}" \
    -o "${OUTPUT_ISO}" \
    -T "Void Linux XFCE - AI Edition" \
    -I "${ROOTFS_OVERLAY}" \
    ${PKG_ARGS}

# Check if ISO was created
if [[ -f "${OUTPUT_ISO}" ]]; then
    info "✓ ISO build successful!"
    echo ""
    info "Output: ${OUTPUT_ISO}"
    info "Size: $(du -h "${OUTPUT_ISO}" | cut -f1)"
    echo ""
    info "Next steps:"
    echo "  1. Test: qemu-system-x86_64 -boot d -cdrom ${OUTPUT_ISO} -m 4096 -enable-kvm"
    echo "  2. Flash: sudo dd if=${OUTPUT_ISO} of=/dev/sdX bs=4M status=progress"
    echo ""
    info "After boot:"
    echo "  - Login and the droid AI helper will initialize automatically"
    echo "  - Try: droid \"how do I install firefox\""
    echo "  - Remove AI: droid uninstall"
    echo ""
else
    error "ISO build failed. Check output above for errors."
    exit 1
fi

