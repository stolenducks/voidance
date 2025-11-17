#!/bin/bash
# ISO Build System for Voidance
# Installs and configures void-mklive for building custom Void Linux ISOs

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[ISO-BUILD]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root for package installation"
fi

# Install void-mklive and dependencies
log "Installing void-mklive and build dependencies..."

# Install required packages for ISO building
xbps-install -Sy \
    void-mklive \
    squashfs-tools \
    libisoburn \
    grub-x86_64-efi \
    grub-i386-efi \
    efibootmgr \
    dosfstools \
    mtools \
    xorriso \
    syslinux

success "void-mklive and dependencies installed successfully"

# Create ISO build directory structure
log "Creating ISO build directory structure..."

BUILD_DIR="/opt/voidance-iso"
mkdir -p "$BUILD_DIR"/{work,cache,output,config,packages}

# Set proper permissions
chmod 755 "$BUILD_DIR"
chown -R root:root "$BUILD_DIR"

success "ISO build directory structure created at $BUILD_DIR"

# Create void-mklive configuration directory
log "Setting up void-mklive configuration..."

mkdir -p /etc/void-mklive
mkdir -p /usr/share/void-mklive

success "void-mklive configuration directories created"

# Create build script template
log "Creating build script template..."

cat > "$BUILD_DIR/build-voidance.sh" << 'EOF'
#!/bin/bash
# Voidance ISO Build Script
# This script builds the complete Voidance ISO

set -euo pipefail

# Configuration
ISO_NAME="voidance"
ISO_VERSION="$(date +%Y.%m.%d)"
BUILD_DIR="/opt/voidance-iso"
OUTPUT_DIR="$BUILD_DIR/output"
WORK_DIR="$BUILD_DIR/work"
CACHE_DIR="$BUILD_DIR/cache"
CONFIG_DIR="$BUILD_DIR/config"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[BUILD]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Clean previous build
log "Cleaning previous build..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# Build the ISO
log "Building Voidance ISO..."
void-mklive \
    -r "$CONFIG_DIR/repositories.conf" \
    -p "$CONFIG_DIR/packages.txt" \
    -C "$CONFIG_DIR/config.sh" \
    -o "$OUTPUT_DIR/${ISO_NAME}-${ISO_VERSION}-x86_64.iso" \
    -t "$WORK_DIR" \
    -c "$CACHE_DIR" \
    -n "$ISO_NAME" \
    -v "$ISO_VERSION"

success "ISO build completed: $OUTPUT_DIR/${ISO_NAME}-${ISO_VERSION}-x86_64.iso"

# Generate checksum
log "Generating checksum..."
cd "$OUTPUT_DIR"
sha256sum "${ISO_NAME}-${ISO_VERSION}-x86_64.iso" > "${ISO_NAME}-${ISO_VERSION}-x86_64.iso.sha256"

success "Build process completed successfully"
EOF

chmod +x "$BUILD_DIR/build-voidance.sh"

success "Build script template created"

# Create environment setup script
log "Creating environment setup script..."

cat > "$BUILD_DIR/setup-environment.sh" << 'EOF'
#!/bin/bash
# ISO Build Environment Setup
# Sets up the environment for building Voidance ISOs

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Set up environment variables
export ISO_BUILD_DIR="/opt/voidance-iso"
export ISO_OUTPUT_DIR="$ISO_BUILD_DIR/output"
export ISO_WORK_DIR="$ISO_BUILD_DIR/work"
export ISO_CACHE_DIR="$ISO_BUILD_DIR/cache"
export ISO_CONFIG_DIR="$ISO_BUILD_DIR/config"

# Add to PATH if not already there
if ! echo "$PATH" | grep -q "/opt/voidance-iso"; then
    export PATH="$ISO_BUILD_DIR:$PATH"
fi

log "ISO build environment configured"
log "Build directory: $ISO_BUILD_DIR"
log "Output directory: $ISO_OUTPUT_DIR"

success "Environment setup completed"
EOF

chmod +x "$BUILD_DIR/setup-environment.sh"

success "Environment setup script created"

# Create validation script
log "Creating validation script..."

cat > "$BUILD_DIR/validate-environment.sh" << 'EOF'
#!/bin/bash
# ISO Build Environment Validation
# Validates that all required tools and dependencies are available

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[VALIDATE]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check required commands
log "Checking required commands..."

REQUIRED_COMMANDS=(
    "void-mklive"
    "mksquashfs"
    "xorriso"
    "grub-mkrescue"
    "efibootmgr"
    "mkfs.fat"
    "mcopy"
)

MISSING_COMMANDS=()

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_COMMANDS+=("$cmd")
    else
        success "Found: $cmd"
    fi
done

if [[ ${#MISSING_COMMANDS[@]} -gt 0 ]]; then
    error "Missing required commands: ${MISSING_COMMANDS[*]}"
    exit 1
fi

# Check directories
log "Checking directory structure..."

BUILD_DIR="/opt/voidance-iso"
REQUIRED_DIRS=(
    "$BUILD_DIR"
    "$BUILD_DIR/work"
    "$BUILD_DIR/cache"
    "$BUILD_DIR/output"
    "$BUILD_DIR/config"
    "$BUILD_DIR/packages"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        success "Directory exists: $dir"
    else
        error "Missing directory: $dir"
        exit 1
    fi
done

# Check permissions
log "Checking permissions..."

if [[ -w "$BUILD_DIR" ]]; then
    success "Build directory is writable"
else
    error "Build directory is not writable"
    exit 1
fi

success "Environment validation completed successfully"
EOF

chmod +x "$BUILD_DIR/validate-environment.sh"

success "Validation script created"

log "Creating ISO build system summary..."

cat > "$BUILD_DIR/README.md" << 'EOF'
# Voidance ISO Build System

This directory contains the complete ISO build system for Voidance.

## Directory Structure

- `work/` - Temporary build files
- `cache/` - Package cache for faster builds
- `output/` - Final ISO files
- `config/` - Configuration files for void-mklive
- `packages/` - Custom packages and modifications

## Scripts

- `build-voidance.sh` - Main ISO build script
- `setup-environment.sh` - Environment setup
- `validate-environment.sh` - Validate build environment

## Usage

1. Set up the environment:
   ```bash
   source /opt/voidance-iso/setup-environment.sh
   ```

2. Validate the environment:
   ```bash
   /opt/voidance-iso/validate-environment.sh
   ```

3. Build the ISO:
   ```bash
   /opt/voidance-iso/build-voidance.sh
   ```

## Requirements

- void-mklive
- squashfs-tools
- libisoburn
- grub-x86_64-efi
- grub-i386-efi
- efibootmgr
- dosfstools
- mtools
- xorriso
- syslinux

## Configuration

Configuration files are located in `config/`:
- `repositories.conf` - Package repositories
- `packages.txt` - Package list
- `config.sh` - void-mklive configuration
EOF

success "ISO build system setup completed"

log "Running environment validation..."

if "$BUILD_DIR/validate-environment.sh"; then
    success "void-mklive installation and configuration completed successfully"
    log "ISO build system is ready at $BUILD_DIR"
    log "Run 'source $BUILD_DIR/setup-environment.sh' to set up your environment"
else
    error "Environment validation failed"
    exit 1
fi