#!/bin/bash
# Voidance void-mklive Configuration
# This file contains the main configuration for building the Voidance ISO

# ISO Configuration
ISO_NAME="voidance"
ISO_LABEL="Voidance Linux"
ISO_PUBLISHER="Voidance Project"
ISO_APPLICATION="Voidance Linux Live/Install ISO"

# Build Configuration
ARCH="x86_64"
OUTPUT_DIR="/opt/voidance-iso/output"
WORK_DIR="/opt/voidance-iso/work"
CACHE_DIR="/opt/voidance-iso/cache"

# Boot Configuration
BOOTLOADER="grub"
EFI_MODE="yes"
LEGACY_MODE="yes"

# Kernel Configuration
KERNEL_VERSION="latest"
KERNEL_CMDLINE="loglevel=4 quiet splash"

# Locale and Keyboard
LOCALE="en_US.UTF-8"
KEYMAP="us"
TIMEZONE="UTC"

# Root filesystem configuration
ROOTFS_SIZE="4G"
SQUASHFS_COMPRESSION="xz"
SQUASHFS_OPTS="-Xbcj x86 -b 1M -Xdict-size 1M"

# Package configuration
PACKAGE_LIST="/opt/voidance-iso/config/packages.txt"
REPO_CONF="/opt/voidance-iso/config/repositories.conf"

# Post-configuration scripts
POST_INSTALL_SCRIPT="/opt/voidance-iso/config/post-install.sh"
LIVE_CONFIG_SCRIPT="/opt/voidance-iso/config/live-config.sh"

# Custom files and directories
CUSTOM_FILES_DIR="/opt/voidance-iso/config/custom-files"
OVERLAY_DIR="/opt/voidance-iso/config/overlay"

# Debug and logging
VERBOSE="yes"
LOG_FILE="/opt/voidance-iso/build.log"

# Function to log messages
log() {
    if [[ "$VERBOSE" == "yes" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
    fi
}

# Function to validate configuration
validate_config() {
    log "Validating configuration..."
    
    # Check required directories
    local required_dirs=("$OUTPUT_DIR" "$WORK_DIR" "$CACHE_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log "Created directory: $dir"
        fi
    done
    
    # Check required files
    local required_files=("$PACKAGE_LIST" "$REPO_CONF")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log "Warning: Missing file $file"
        fi
    done
    
    log "Configuration validation completed"
}

# Function to set up build environment
setup_environment() {
    log "Setting up build environment..."
    
    # Set environment variables
    export ISO_NAME ISO_LABEL ISO_PUBLISHER ISO_APPLICATION
    export ARCH OUTPUT_DIR WORK_DIR CACHE_DIR
    export BOOTLOADER EFI_MODE LEGACY_MODE
    export KERNEL_VERSION KERNEL_CMDLINE
    export LOCALE KEYMAP TIMEZONE
    export ROOTFS_SIZE SQUASHFS_COMPRESSION SQUASHFS_OPTS
    export PACKAGE_LIST REPO_CONF
    export POST_INSTALL_SCRIPT LIVE_CONFIG_SCRIPT
    export CUSTOM_FILES_DIR OVERLAY_DIR
    export VERBOSE LOG_FILE
    
    log "Build environment configured"
}

# Function to generate void-mklive command
generate_mklive_command() {
    local cmd="void-mklive"
    
    # Basic options
    cmd+=" -r $REPO_CONF"
    cmd+=" -p $PACKAGE_LIST"
    cmd+=" -C $0"  # This config file
    cmd+=" -o $OUTPUT_DIR/${ISO_NAME}-$(date +%Y.%m.%d)-${ARCH}.iso"
    cmd+=" -t $WORK_DIR"
    cmd+=" -c $CACHE_DIR"
    cmd+=" -n $ISO_NAME"
    cmd+=" -v $(date +%Y.%m.%d)"
    
    # Boot options
    if [[ "$EFI_MODE" == "yes" ]]; then
        cmd+=" -e"
    fi
    
    if [[ "$LEGACY_MODE" == "yes" ]]; then
        cmd+=" -l"
    fi
    
    # Kernel options
    cmd+=" -k $KERNEL_VERSION"
    cmd+=" -K '$KERNEL_CMDLINE'"
    
    # Compression options
    cmd+=" -s $SQUASHFS_COMPRESSION"
    cmd+=" -S '$SQUASHFS_OPTS'"
    
    # Custom files
    if [[ -d "$CUSTOM_FILES_DIR" ]]; then
        cmd+=" -x $CUSTOM_FILES_DIR"
    fi
    
    if [[ -d "$OVERLAY_DIR" ]]; then
        cmd+=" -o $OVERLAY_DIR"
    fi
    
    # Post-install scripts
    if [[ -f "$POST_INSTALL_SCRIPT" ]]; then
        cmd+=" -P $POST_INSTALL_SCRIPT"
    fi
    
    if [[ -f "$LIVE_CONFIG_SCRIPT" ]]; then
        cmd+=" -L $LIVE_CONFIG_SCRIPT"
    fi
    
    echo "$cmd"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate_config
    setup_environment
    
    log "Configuration loaded successfully"
    log "Build command: $(generate_mklive_command)"
fi