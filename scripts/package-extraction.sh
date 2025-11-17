#!/bin/bash
# Voidance Package Extraction and Integration
# Handles package extraction for ISO building and system installation

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/iso/config.sh"
source "$SCRIPT_DIR/../config/iso/packages.txt"
source "$SCRIPT_DIR/../config/iso/package-versions.sh"

# Extraction configuration
EXTRACT_ROOT="/tmp/voidance-extract"
PACKAGE_CACHE="/var/cache/xbps"
ISO_ROOT="/tmp/voidance-iso"
EXTRACT_LOG="/var/log/voidance-extract.log"

# Function to initialize extraction environment
init_extraction_environment() {
    log_message "INFO" "Initializing package extraction environment"
    
    # Create directories
    mkdir -p "$EXTRACT_ROOT"
    mkdir -p "$PACKAGE_CACHE"
    mkdir -p "$ISO_ROOT"
    
    # Clean any existing extraction
    rm -rf "$EXTRACT_ROOT"/*
    rm -rf "$ISO_ROOT"/*
    
    # Initialize extraction log
    cat > "$EXTRACT_LOG" << EOF
Voidance Package Extraction Log
===============================
Date: $(date)
Extract Root: $EXTRACT_ROOT
Package Cache: $PACKAGE_CACHE
ISO Root: $ISO_ROOT

EOF
    
    log_message "INFO" "Extraction environment initialized"
}

# Function to download packages
download_packages() {
    log_message "INFO" "Downloading packages"
    
    # Update package database
    xbps-install -S
    
    # Download all required packages
    local packages=()
    
    # Read packages from manifest
    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "$package" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${package// }" ]] && continue
        
        packages+=("$package")
    done < "$SCRIPT_DIR/../config/iso/packages.txt"
    
    # Download packages
    xbps-install -y -d "${packages[@]}"
    
    log_message "INFO" "Packages downloaded successfully"
}

# Function to extract packages to root filesystem
extract_packages_to_rootfs() {
    log_message "INFO" "Extracting packages to root filesystem"
    
    # Create basic directory structure
    mkdir -p "$EXTRACT_ROOT"/{bin,boot,dev,etc,home,lib,lib64,media,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}
    
    # Extract packages
    local package_files
    mapfile -t package_files < <(find "$PACKAGE_CACHE" -name "*.xbps" -type f)
    
    for package_file in "${package_files[@]}"; do
        log_message "INFO" "Extracting $(basename "$package_file")"
        
        # Extract package
        xbps-uhelper extract "$package_file" -C "$EXTRACT_ROOT"
    done
    
    log_message "INFO" "Packages extracted to root filesystem"
}

# Function to create ISO root structure
create_iso_root_structure() {
    log_message "INFO" "Creating ISO root structure"
    
    # Copy root filesystem to ISO root
    cp -a "$EXTRACT_ROOT"/* "$ISO_ROOT/"
    
    # Create ISO-specific directories
    mkdir -p "$ISO_ROOT"/{boot/grub,isolinux,LiveOS}
    
    # Create boot configuration
    create_boot_configuration
    
    # Create live system configuration
    create_live_system_config
    
    log_message "INFO" "ISO root structure created"
}

# Function to create boot configuration
create_boot_configuration() {
    log_message "INFO" "Creating boot configuration"
    
    # Create GRUB configuration
    cat > "$ISO_ROOT/boot/grub/grub.cfg" << 'EOF'
# Voidance Linux Live ISO GRUB Configuration
set default="0"
set timeout=10

menuentry "Voidance Linux Live" {
    linux /boot/vmlinuz-6.6.x86_64 root=live:CDLABEL=VoidanceLive rw quiet splash
    initrd /boot/initramfs-6.6.x86_64.img
}

menuentry "Voidance Linux Live (Failsafe)" {
    linux /boot/vmlinuz-6.6.x86_64 root=live:CDLABEL=VoidanceLive rw nomodeset xdriver=vesa
    initrd /boot/initramfs-6.6.x86_64.img
}

menuentry "Memory Test (memtest86+)" {
    linux16 /boot/memtest86+.bin
}

menuentry "Boot from first hard disk" {
    set root=(hd0)
    chainloader +1
}
EOF
    
    # Create isolinux configuration
    cat > "$ISO_ROOT/isolinux/isolinux.cfg" << 'EOF'
# Voidance Linux Live ISO ISOLINUX Configuration
default voidance
timeout 100

label voidance
    menu label ^Voidance Linux Live
    kernel /boot/vmlinuz-6.6.x86_64
    append initrd=/boot/initramfs-6.6.x86_64.img root=live:CDLABEL=VoidanceLive rw quiet splash

label failsafe
    menu label Voidance Linux ^Failsafe
    kernel /boot/vmlinuz-6.6.x86_64
    append initrd=/boot/initramfs-6.6.x86_64.img root=live:CDLABEL=VoidanceLive rw nomodeset xdriver=vesa

label memtest
    menu label ^Memory Test
    kernel /boot/memtest86+.bin

label local
    menu label Boot from ^first hard disk
    localboot 0x80
EOF
    
    log_message "INFO" "Boot configuration created"
}

# Function to create live system configuration
create_live_system_config() {
    log_message "INFO" "Creating live system configuration"
    
    # Create live system scripts
    mkdir -p "$ISO_ROOT/usr/lib/voidance-live"
    
    # Create live system startup script
    cat > "$ISO_ROOT/usr/lib/voidance-live/startup.sh" << 'EOF'
#!/bin/bash
# Voidance Live System Startup Script

# Mount essential filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /run

# Start essential services
sv start NetworkManager
sv start seatd
sv start polkitd
sv start dbus
sv start elogind

# Configure display manager
if command -v niri >/dev/null 2>&1; then
    # Set up Niri as default session
    mkdir -p /etc/wayland-sessions
    cat > /etc/wayland-sessions/niri.desktop << DESKTOP
[Desktop Entry]
Name=Niri
Comment=Niri Wayland Compositor
Exec=niri
Type=Application
DESKTOP
fi

# Start display manager if available
if command -v greetd >/dev/null 2>&1; then
    sv start greetd
fi

echo "Voidance Live System started successfully"
EOF
    
    chmod +x "$ISO_ROOT/usr/lib/voidance-live/startup.sh"
    
    # Create live system configuration
    cat > "$ISO_ROOT/etc/voidance-live.conf" << EOF
# Voidance Live System Configuration

# Live system settings
LIVE_USER="voidance"
LIVE_PASSWORD="voidance"
LIVE_HOSTNAME="voidance-live"

# Display settings
AUTOLOGIN="true"
DISPLAY_MANAGER="greetd"
DEFAULT_SESSION="niri"

# Network settings
AUTOCONNECT_NETWORK="true"
NETWORK_SERVICE="NetworkManager"

# Persistence settings
PERSISTENCE="false"
PERSISTENCE_DEVICE=""
PERSISTENCE_MOUNT="/mnt/persistence"

EOF
    
    log_message "INFO" "Live system configuration created"
}

# Function to create squashfs filesystem
create_squashfs() {
    log_message "INFO" "Creating squashfs filesystem"
    
    # Create LiveOS directory
    mkdir -p "$ISO_ROOT/LiveOS"
    
    # Create squashfs image
    mksquashfs "$EXTRACT_ROOT" "$ISO_ROOT/LiveOS/rootfs.squashfs" \
        -comp xz \
        -Xbcj x86 \
        -b 1M \
        -Xdict-size 1M \
        -e boot
    
    log_message "INFO" "Squashfs filesystem created"
}

# Function to create ISO image
create_iso_image() {
    log_message "INFO" "Creating ISO image"
    
    local iso_output="$SCRIPT_DIR/../voidance-live.iso"
    
    # Create ISO using xorriso
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "VoidanceLive" \
        -appid "Voidance Linux Live" \
        -publisher "Voidance Linux Project" \
        -preparer "void-mklive" \
        -eltorito-boot boot/grub/i386-pc/eltorito.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -output "$iso_output" \
        "$ISO_ROOT"
    
    log_message "INFO" "ISO image created: $iso_output"
}

# Function to validate extraction
validate_extraction() {
    log_message "INFO" "Validating package extraction"
    
    # Check essential files exist
    local essential_files=(
        "$ISO_ROOT/bin/bash"
        "$ISO_ROOT/bin/sh"
        "$ISO_ROOT/etc/passwd"
        "$ISO_ROOT/etc/group"
        "$ISO_ROOT/usr/bin/niri"
        "$ISO_ROOT/usr/bin/foot"
    )
    
    for file in "${essential_files[@]}"; do
        if [[ ! -e "$file" ]]; then
            log_message "ERROR" "Essential file missing: $file"
            return 1
        fi
    done
    
    # Check ISO was created
    if [[ ! -f "$SCRIPT_DIR/../voidance-live.iso" ]]; then
        log_message "ERROR" "ISO image not created"
        return 1
    fi
    
    log_message "INFO" "Package extraction validation passed"
}

# Function to cleanup extraction
cleanup_extraction() {
    log_message "INFO" "Cleaning up extraction environment"
    
    # Unmount any mounted filesystems
    umount "$EXTRACT_ROOT/proc" 2>/dev/null || true
    umount "$EXTRACT_ROOT/sys" 2>/dev/null || true
    umount "$EXTRACT_ROOT/dev" 2>/dev/null || true
    
    # Remove temporary directories
    rm -rf "$EXTRACT_ROOT"
    rm -rf "$ISO_ROOT"
    
    log_message "INFO" "Extraction cleanup completed"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$EXTRACT_LOG"
}

# Main extraction function
main_extraction() {
    log_message "INFO" "Starting Voidance package extraction"
    
    init_extraction_environment
    download_packages
    extract_packages_to_rootfs
    create_iso_root_structure
    create_squashfs
    create_iso_image
    validate_extraction
    cleanup_extraction
    
    log_message "INFO" "Voidance package extraction completed successfully"
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_extraction "$@"
fi