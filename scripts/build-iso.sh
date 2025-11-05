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

# Step 2: Build llama.cpp
info "Step 2/5: Building llama.cpp..."
LLAMA_BUILD_DIR="${BUILD_DIR}/llama.cpp"

# Ensure build dependencies are available
if ! command -v gcc &>/dev/null || ! command -v g++ &>/dev/null; then
    error "GCC/G++ not found. Installing build dependencies..."
    if [[ -f /.dockerenv ]] || [[ $EUID -eq 0 ]]; then
        xbps-install -y gcc make git
    else
        error "Please install: sudo xbps-install -S gcc make git"
        exit 1
    fi
fi

if [[ ! -f "${LLAMA_BUILD_DIR}/llama-server" ]]; then
    info "Cloning llama.cpp repository..."
    rm -rf "${LLAMA_BUILD_DIR}"
    git clone --depth 1 https://github.com/ggerganov/llama.cpp "${LLAMA_BUILD_DIR}"
    
    info "Building llama-server (this may take 5-10 minutes)..."
    cd "${LLAMA_BUILD_DIR}"
    
    # Detect CPU cores (fallback to 4 if nproc not available)
    NCORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    info "Building with ${NCORES} cores..."
    
    make -j${NCORES} llama-server
    
    if [[ ! -f "llama-server" ]]; then
        error "Failed to build llama-server"
        exit 1
    fi
    
    info "llama-server built successfully"
else
    info "llama-server already built, skipping"
fi

cd "${PROJECT_ROOT}"

# Step 3: Prepare rootfs overlay
info "Step 3/5: Preparing rootfs overlay..."
rm -rf "${ROOTFS_OVERLAY}"
mkdir -p "${ROOTFS_OVERLAY}"

# Copy llama-server binary
info "Copying llama-server binary..."
mkdir -p "${ROOTFS_OVERLAY}/usr/local/bin"
cp "${LLAMA_BUILD_DIR}/llama-server" "${ROOTFS_OVERLAY}/usr/local/bin/"
chmod +x "${ROOTFS_OVERLAY}/usr/local/bin/llama-server"

# Copy droid CLI
info "Copying droid CLI..."
cp "${PROJECT_ROOT}/rootfs/usr/local/bin/droid" "${ROOTFS_OVERLAY}/usr/local/bin/"
chmod +x "${ROOTFS_OVERLAY}/usr/local/bin/droid"

# Copy llama-server service
info "Copying llama-server service..."
mkdir -p "${ROOTFS_OVERLAY}/etc/sv/llama-server"
cp "${PROJECT_ROOT}/rootfs/etc/sv/llama-server/run" "${ROOTFS_OVERLAY}/etc/sv/llama-server/"
chmod +x "${ROOTFS_OVERLAY}/etc/sv/llama-server/run"

# Copy droid-firstboot service
info "Copying first-boot service..."
mkdir -p "${ROOTFS_OVERLAY}/etc/sv/droid-firstboot"
cp "${PROJECT_ROOT}/rootfs/etc/sv/droid-firstboot/run" "${ROOTFS_OVERLAY}/etc/sv/droid-firstboot/"
chmod +x "${ROOTFS_OVERLAY}/etc/sv/droid-firstboot/run"

# Enable droid-firstboot in the ISO (will run once on first boot)
mkdir -p "${ROOTFS_OVERLAY}/etc/runit/runsvdir/default"
ln -sf /etc/sv/droid-firstboot "${ROOTFS_OVERLAY}/etc/runit/runsvdir/default/droid-firstboot"

# Copy AI model
info "Copying AI model..."
mkdir -p "${ROOTFS_OVERLAY}/opt/droid/models"

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

# Step 4: Prepare package list
info "Step 4/5: Preparing package list..."
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

# Step 5: Build ISO with void-mklive
info "Step 5/5: Building ISO with void-mklive..."
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

