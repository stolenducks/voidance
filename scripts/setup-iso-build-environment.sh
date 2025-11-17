#!/bin/bash
# ISO Build Environment Setup
# Sets up the complete build environment for Voidance ISO creation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[ENV-SETUP]${NC} $1"
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

# Install additional build dependencies
log "Installing additional build dependencies..."

# Core build tools
xbps-install -Sy \
    git \
    curl \
    wget \
    rsync \
    tar \
    unzip \
    zip \
    p7zip \
    squashfs-tools \
    xorriso \
    libisoburn \
    cdrtools

# Bootloader tools
xbps-install -Sy \
    grub-x86_64-efi \
    grub-i386-efi \
    grub-tools \
    efibootmgr \
    dosfstools \
    mtools \
    syslinux

# Filesystem tools
xbps-install -Sy \
    e2fsprogs \
    btrfs-progs \
    xfsprogs \
    f2fs-tools \
    ntfs-3g \
    exfat-utils

# Compression and archive tools
xbps-install -Sy \
    xz \
    lz4 \
    zstd \
    gzip \
    bzip2 \
    p7zip

# Virtualization tools for testing
xbps-install -Sy \
    qemu \
    qemu-system-x86_64 \
    ovmf \
    seabios

# Development tools
xbps-install -Sy \
    make \
    gcc \
    gcc-c++ \
    pkg-config \
    autoconf \
    automake \
    libtool \
    patch \
    diffutils

success "Build dependencies installed successfully"

# Create comprehensive build directory structure
log "Creating comprehensive build directory structure..."

BUILD_DIR="/opt/voidance-iso"
mkdir -p "$BUILD_DIR"/{work,cache,output,config,packages,custom,overlay,scripts,templates}

# Subdirectories for organization
mkdir -p "$BUILD_DIR/work"/{rootfs,boot,efi,iso}
mkdir -p "$BUILD_DIR/cache"/{packages,templates,images}
mkdir -p "$BUILD_DIR/output"/{iso,logs,checksums}
mkdir -p "$BUILD_DIR/config"/{boot,packages,services,users,hardware}
mkdir -p "$BUILD_DIR/packages"/{custom,patches,mods}
mkdir -p "$BUILD_DIR/custom"/{files,scripts,configs}
mkdir -p "$BUILD_DIR/overlay"/{etc,usr,var,home}
mkdir -p "$BUILD_DIR/scripts"/{build,test,validate,cleanup}
mkdir -p "$BUILD_DIR/templates"/{configs,scripts,docs}

# Set proper permissions
chmod 755 "$BUILD_DIR"
chown -R root:root "$BUILD_DIR"

success "Comprehensive build directory structure created"

# Create build environment configuration
log "Creating build environment configuration..."

cat > "$BUILD_DIR/.env" << 'EOF'
# Voidance ISO Build Environment Configuration
# This file contains environment variables for the build system

# Paths
export VOIDANCE_BUILD_DIR="/opt/voidance-iso"
export VOIDANCE_WORK_DIR="$VOIDANCE_BUILD_DIR/work"
export VOIDANCE_CACHE_DIR="$VOIDANCE_BUILD_DIR/cache"
export VOIDANCE_OUTPUT_DIR="$VOIDANCE_BUILD_DIR/output"
export VOIDANCE_CONFIG_DIR="$VOIDANCE_BUILD_DIR/config"
export VOIDANCE_PACKAGES_DIR="$VOIDANCE_BUILD_DIR/packages"
export VOIDANCE_CUSTOM_DIR="$VOIDANCE_BUILD_DIR/custom"
export VOIDANCE_OVERLAY_DIR="$VOIDANCE_BUILD_DIR/overlay"
export VOIDANCE_SCRIPTS_DIR="$VOIDANCE_BUILD_DIR/scripts"
export VOIDANCE_TEMPLATES_DIR="$VOIDANCE_BUILD_DIR/templates"

# Build Configuration
export VOIDANCE_ISO_NAME="voidance"
export VOIDANCE_VERSION="$(date +%Y.%m.%d)"
export VOIDANCE_ARCH="x86_64"
export VOIDANCE_DISTRIBUTION="void-linux"

# Package Configuration
export VOIDANCE_REPO_CONF="$VOIDANCE_CONFIG_DIR/repositories.conf"
export VOIDANCE_PACKAGE_LIST="$VOIDANCE_CONFIG_DIR/packages.txt"
export VOIDANCE_CUSTOM_PACKAGES="$VOIDANCE_PACKAGES_DIR/custom"

# Kernel Configuration
export VOIDANCE_KERNEL_VERSION="latest"
export VOIDANCE_KERNEL_CMDLINE="loglevel=4 quiet splash"

# Boot Configuration
export VOIDANCE_BOOTLOADER="grub"
export VOIDANCE_EFI_MODE="yes"
export VOIDANCE_LEGACY_MODE="yes"

# Compression Configuration
export VOIDANCE_COMPRESSION="xz"
export VOIDANCE_COMPRESSION_OPTS="-Xbcj x86 -b 1M -Xdict-size 1M"

# Logging
export VOIDANCE_LOG_LEVEL="info"
export VOIDANCE_LOG_FILE="$VOIDANCE_OUTPUT_DIR/logs/build.log"

# Testing
export VOIDANCE_TEST_VM="yes"
export VOIDANCE_TEST_MEMORY="2048"
export VOIDANCE_TEST_DISK="8G"

# Development
export VOIDANCE_DEBUG="no"
export VOIDANCE_VERBOSE="yes"
EOF

success "Build environment configuration created"

# Create build helper functions
log "Creating build helper functions..."

cat > "$BUILD_DIR/scripts/build-helpers.sh" << 'EOF'
#!/bin/bash
# Voidance ISO Build Helper Functions
# Common functions used throughout the build process

# Source environment
source /opt/voidance-iso/.env

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$VOIDANCE_LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$VOIDANCE_LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$VOIDANCE_LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$VOIDANCE_LOG_FILE"
}

# Progress indicator
progress() {
    local current=$1
    local total=$2
    local desc=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${BLUE}[PROGRESS]${NC} %3d%% [" "$percent"
    printf "%*s" "$filled" | tr ' ' '='
    printf "%*s" "$empty" | tr ' ' '-'
    printf "] %s" "$desc"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Check disk space
check_disk_space() {
    local required_gb=${1:-5}
    local path=${2:-$VOIDANCE_WORK_DIR}
    
    local available_kb=$(df "$path" | awk 'NR==2 {print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [[ $available_gb -lt $required_gb ]]; then
        log_error "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb}GB"
        return 1
    fi
    
    log_info "Disk space check passed: ${available_gb}GB available"
}

# Check memory
check_memory() {
    local required_mb=${1:-2048}
    
    local available_mb=$(free -m | awk 'NR==2{print $7}')
    
    if [[ $available_mb -lt $required_mb ]]; then
        log_warning "Low memory. Recommended: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi
    
    log_info "Memory check passed: ${available_mb}MB available"
}

# Validate package
validate_package() {
    local package=$1
    
    if xbps-query -R "$VOIDANCE_REPO_CONF" "$package" &>/dev/null; then
        log_info "Package found: $package"
        return 0
    else
        log_warning "Package not found: $package"
        return 1
    fi
}

# Create timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Clean build directory
clean_build() {
    log_info "Cleaning build directory..."
    rm -rf "$VOIDANCE_WORK_DIR"/*
    log_success "Build directory cleaned"
}

# Clean cache
clean_cache() {
    log_info "Cleaning cache directory..."
    rm -rf "$VOIDANCE_CACHE_DIR"/*
    log_success "Cache directory cleaned"
}

# Generate checksum
generate_checksum() {
    local file=$1
    local algorithm=${2:-sha256}
    
    if [[ -f "$file" ]]; then
        "${algorithm}sum" "$file" > "${file}.${algorithm}"
        log_success "Generated ${algorithm} checksum for $file"
    else
        log_error "File not found: $file"
        return 1
    fi
}

# Verify checksum
verify_checksum() {
    local file=$1
    local algorithm=${2:-sha256}
    
    if [[ -f "${file}.${algorithm}" ]]; then
        "${algorithm}sum" -c "${file}.${algorithm}"
        log_success "Checksum verified for $file"
    else
        log_error "Checksum file not found: ${file}.${algorithm}"
        return 1
    fi
}

# Export functions
export -f log_info log_success log_warning log_error
export -f progress check_disk_space check_memory
export -f validate_package timestamp
export -f clean_build clean_cache
export -f generate_checksum verify_checksum
EOF

chmod +x "$BUILD_DIR/scripts/build-helpers.sh"

success "Build helper functions created"

# Create build validation script
log "Creating build validation script..."

cat > "$BUILD_DIR/scripts/validate-build-env.sh" << 'EOF'
#!/bin/bash
# Build Environment Validation Script
# Validates that the build environment is properly configured

set -euo pipefail

# Source environment and helpers
source /opt/voidance-iso/.env
source /opt/voidance-iso/scripts/build-helpers.sh

log_info "Starting build environment validation..."

# Check environment variables
log_info "Validating environment variables..."
required_vars=(
    "VOIDANCE_BUILD_DIR"
    "VOIDANCE_WORK_DIR"
    "VOIDANCE_CACHE_DIR"
    "VOIDANCE_OUTPUT_DIR"
    "VOIDANCE_CONFIG_DIR"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    log_error "Missing environment variables: ${missing_vars[*]}"
    exit 1
fi

log_success "Environment variables validated"

# Check directories
log_info "Validating directory structure..."
required_dirs=(
    "$VOIDANCE_BUILD_DIR"
    "$VOIDANCE_WORK_DIR"
    "$VOIDANCE_CACHE_DIR"
    "$VOIDANCE_OUTPUT_DIR"
    "$VOIDANCE_CONFIG_DIR"
    "$VOIDANCE_PACKAGES_DIR"
    "$VOIDANCE_CUSTOM_DIR"
    "$VOIDANCE_OVERLAY_DIR"
    "$VOIDANCE_SCRIPTS_DIR"
    "$VOIDANCE_TEMPLATES_DIR"
)

missing_dirs=()
for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
        missing_dirs+=("$dir")
    fi
done

if [[ ${#missing_dirs[@]} -gt 0 ]]; then
    log_error "Missing directories: ${missing_dirs[*]}"
    exit 1
fi

log_success "Directory structure validated"

# Check required commands
log_info "Validating required commands..."
required_commands=(
    "void-mklive"
    "mksquashfs"
    "xorriso"
    "grub-mkrescue"
    "efibootmgr"
    "mkfs.fat"
    "mcopy"
    "qemu-system-x86_64"
)

missing_commands=()
for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        missing_commands+=("$cmd")
    fi
done

if [[ ${#missing_commands[@]} -gt 0 ]]; then
    log_error "Missing required commands: ${missing_commands[*]}"
    exit 1
fi

log_success "Required commands validated"

# Check system resources
log_info "Validating system resources..."

if ! check_disk_space 5 "$VOIDANCE_BUILD_DIR"; then
    log_error "Insufficient disk space"
    exit 1
fi

if ! check_memory 2048; then
    log_warning "Low memory detected"
fi

log_success "System resources validated"

# Check configuration files
log_info "Validating configuration files..."
config_files=(
    "$VOIDANCE_REPO_CONF"
    "$VOIDANCE_PACKAGE_LIST"
    "$VOIDANCE_CONFIG_DIR/config.sh"
)

missing_configs=()
for file in "${config_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        missing_configs+=("$file")
    fi
done

if [[ ${#missing_configs[@]} -gt 0 ]]; then
    log_warning "Missing configuration files: ${missing_configs[*]}"
else
    log_success "Configuration files validated"
fi

# Test void-mklive
log_info "Testing void-mklive functionality..."
if void-mklive -h &>/dev/null; then
    log_success "void-mklive is functional"
else
    log_error "void-mklive is not functional"
    exit 1
fi

log_success "Build environment validation completed successfully"
EOF

chmod +x "$BUILD_DIR/scripts/validate-build-env.sh"

success "Build validation script created"

# Create environment setup script
log "Creating environment setup script..."

cat > "$BUILD_DIR/scripts/setup-build-env.sh" << 'EOF'
#!/bin/bash
# Build Environment Setup Script
# Sets up the environment for building Voidance ISOs

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Source environment
source /opt/voidance-iso/.env

# Add to PATH
if ! echo "$PATH" | grep -q "/opt/voidance-iso/scripts"; then
    export PATH="$VOIDANCE_SCRIPTS_DIR:$PATH"
fi

# Create log directory
mkdir -p "$VOIDANCE_OUTPUT_DIR/logs"

# Set up build environment
log "Setting up build environment..."
log "Build directory: $VOIDANCE_BUILD_DIR"
log "Work directory: $VOIDANCE_WORK_DIR"
log "Cache directory: $VOIDANCE_CACHE_DIR"
log "Output directory: $VOIDANCE_OUTPUT_DIR"
log "Config directory: $VOIDANCE_CONFIG_DIR"

# Validate environment
log "Validating build environment..."
if /opt/voidance-iso/scripts/validate-build-env.sh; then
    success "Build environment setup completed successfully"
else
    echo "Build environment setup failed"
    exit 1
fi
EOF

chmod +x "$BUILD_DIR/scripts/setup-build-env.sh"

success "Environment setup script created"

log "Running build environment validation..."

if "$BUILD_DIR/scripts/validate-build-env.sh"; then
    success "Build environment setup and validation completed successfully"
    log "ISO build environment is ready at $BUILD_DIR"
    log "Run 'source $BUILD_DIR/scripts/setup-build-env.sh' to set up your environment"
else
    error "Build environment validation failed"
    exit 1
fi