#!/bin/bash
# Voidance Bootloader Installation and Configuration
# Handles GRUB installation for UEFI and BIOS systems

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/iso/config.sh"
source "$SCRIPT_DIR/disk-partitioning.sh"

# Bootloader configuration
INSTALL_ROOT="/mnt/voidance"
BOOTLOADER_LOG="/var/log/voidance-bootloader.log"
EFI_DIR="/boot/efi"
GRUB_DIR="/boot/grub"

# Function to detect firmware type
detect_firmware_type() {
    log_message "INFO" "Detecting firmware type"
    
    if [[ -d "/sys/firmware/efi" ]]; then
        echo "UEFI"
    else
        echo "BIOS"
    fi
}

# Function to install bootloader dependencies
install_bootloader_deps() {
    log_message "INFO" "Installing bootloader dependencies"
    
    # Install GRUB and related packages
    xbps-install -Sy -r "$INSTALL_ROOT" \
        grub \
        grub-i386-efi \
        grub-x86_64-efi \
        efibootmgr \
        os-prober \
        shim \
        mokutil
    
    log_message "INFO" "Bootloader dependencies installed"
}

# Function to configure UEFI bootloader
configure_uefi_bootloader() {
    log_message "INFO" "Configuring UEFI bootloader"
    
    local efi_partition=$(get_config "efi_partition")
    local boot_device=$(get_config "boot_device")
    
    if [[ -z "$efi_partition" ]]; then
        log_message "ERROR" "EFI partition not specified"
        return 1
    fi
    
    # Mount EFI partition
    mkdir -p "$INSTALL_ROOT$EFI_DIR"
    mount "$efi_partition" "$INSTALL_ROOT$EFI_DIR"
    
    # Install GRUB for UEFI
    chroot "$INSTALL_ROOT" grub-install \
        --target=x86_64-efi \
        --efi-directory="$EFI_DIR" \
        --bootloader-id="Voidance" \
        --recheck \
        --no-nvram
    
    # Create EFI boot entry
    chroot "$INSTALL_ROOT" efibootmgr \
        --create \
        --disk "$boot_device" \
        --part "$(echo "$efi_partition" | sed 's/[^0-9]//g')" \
        --label "Voidance Linux" \
        --loader "\\EFI\\Voidance\\grubx64.efi"
    
    log_message "INFO" "UEFI bootloader configured"
}

# Function to configure BIOS bootloader
configure_bios_bootloader() {
    log_message "INFO" "Configuring BIOS bootloader"
    
    local boot_device=$(get_config "boot_device")
    local root_partition=$(get_config "root_partition")
    
    if [[ -z "$boot_device" ]]; then
        log_message "ERROR" "Boot device not specified"
        return 1
    fi
    
    # Install GRUB for BIOS
    chroot "$INSTALL_ROOT" grub-install \
        --target=i386-pc \
        --recheck \
        "$boot_device"
    
    log_message "INFO" "BIOS bootloader configured"
}

# Function to create GRUB configuration
create_grub_config() {
    log_message "INFO" "Creating GRUB configuration"
    
    # Create GRUB default configuration
    cat > "$INSTALL_ROOT/etc/default/grub" << 'EOF'
# GRUB bootloader configuration

# Boot menu timeout
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=menu

# Default boot entry
GRUB_DEFAULT=0

# Graphics and display
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_TERMINAL_OUTPUT=gfxterm

# Kernel parameters
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash rw"
GRUB_CMDLINE_LINUX=""

# Enable OS detection
GRUB_DISABLE_OS_PROBER=false

# Enable recovery mode
GRUB_DISABLE_RECOVERY=false

# Enable submenu
GRUB_DISABLE_SUBMENU=false

# Use UUID for root filesystem
GRUB_DISABLE_LINUX_UUID=false

# Enable savedefault
GRUB_SAVEDEFAULT=true

# Enable initramfs detection
GRUB_ENABLE_CRYPTODISK=y

# Color scheme
GRUB_COLOR_NORMAL="light-gray/black"
GRUB_COLOR_HIGHLIGHT="green/black"
GRUB_COLOR_MENU="light-gray/black"
GRUB_COLOR_HIGHLIGHT_MENU="green/black"

# Background image (if available)
# GRUB_BACKGROUND="/boot/grub/themes/voidance/background.png"

# Theme
# GRUB_THEME="/boot/grub/themes/voidance/theme.txt"

EOF
    
    # Create custom GRUB configuration
    mkdir -p "$INSTALL_ROOT/etc/grub.d"
    
    # Create custom Voidance GRUB entry
    cat > "$INSTALL_ROOT/etc/grub.d/40_custom_voidance" << 'EOF'
#!/bin/sh
exec tail -n +3 $0
# Voidance Linux custom GRUB entries

menuentry "Voidance Linux (Advanced)" {
    search --no-floppy --fs-uuid --set=root $UUID
    linux /boot/vmlinuz root=UUID=$UUID rw quiet splash init=/sbin/init
    initrd /boot/initramfs.img
}

menuentry "Voidance Linux (Recovery Mode)" {
    search --no-floppy --fs-uuid --set=root $UUID
    linux /boot/vmlinuz root=UUID=$UUID rw single
    initrd /boot/initramfs.img
}

menuentry "Voidance Linux (Failsafe)" {
    search --no-floppy --fs-uuid --set=root $UUID
    linux /boot/vmlinuz root=UUID=$UUID rw nomodeset xdriver=vesa
    initrd /boot/initramfs.img
}

menuentry "Voidance Linux (Memory Test)" {
    linux16 /boot/memtest86+.bin
}

EOF
    
    chmod +x "$INSTALL_ROOT/etc/grub.d/40_custom_voidance"
    
    log_message "INFO" "GRUB configuration created"
}

# Function to create GRUB theme
create_grub_theme() {
    log_message "INFO" "Creating GRUB theme"
    
    local theme_dir="$INSTALL_ROOT$GRUB_DIR/themes/voidance"
    mkdir -p "$theme_dir"
    
    # Create theme configuration
    cat > "$theme_dir/theme.txt" << 'EOF'
# Voidance GRUB Theme

# Global properties
desktop-image: "background.png"
desktop-color: "#1a1a1a"
title-text: ""
title-font: "DejaVu Sans 16"
title-color: "#ffffff"

# Menu properties
menu-font: "DejaVu Sans 14"
menu-color-normal: "#ffffff"
menu-color-highlight: "#00ff00"
menu-pixmap-style: "center=0"
menu-width = "400"
menu-height = "200"
menu-border-style = "none"

# Item properties
item-font = "DejaVu Sans 12"
item-color = "#ffffff"
item-selected-color = "#000000"
item-pixmap-style = "center=0"
item-height = "25"
item-padding = "5 5 5 5"

# Progress bar
+ progress_bar {
    id = "__progress_bar__"
    left = "20%"
    top = "90%"
    width = "60%"
    height = "20"
    text_color = "#ffffff"
    bar_style = "progress_bar_*.png"
    highlight_style = "progress_bar_hl_*.png"
}

# Timeout
+ timeout {
    left = "20%"
    top = "95%"
    width = "60%"
    height = "20"
    text_color = "#ffffff"
    font = "DejaVu Sans 12"
}

EOF
    
    # Create a simple background image (placeholder)
    # In a real implementation, you would copy an actual image file
    log_message "INFO" "GRUB theme created (background image needed)"
}

# Function to generate GRUB configuration
generate_grub_config() {
    log_message "INFO" "Generating GRUB configuration"
    
    # Mount virtual filesystems
    mount -t proc /proc "$INSTALL_ROOT/proc"
    mount -t sysfs /sys "$INSTALL_ROOT/sys"
    mount -t devtmpfs /dev "$INSTALL_ROOT/dev"
    mount -t devpts /dev/pts "$INSTALL_ROOT/dev/pts"
    
    # Generate GRUB configuration
    chroot "$INSTALL_ROOT" grub-mkconfig -o "$GRUB_DIR/grub.cfg"
    
    # Unmount virtual filesystems
    umount "$INSTALL_ROOT/dev/pts" || true
    umount "$INSTALL_ROOT/dev" || true
    umount "$INSTALL_ROOT/sys" || true
    umount "$INSTALL_ROOT/proc" || true
    
    log_message "INFO" "GRUB configuration generated"
}

# Function to configure secure boot (UEFI only)
configure_secure_boot() {
    log_message "INFO" "Configuring Secure Boot"
    
    # Check if Secure Boot is supported
    if ! chroot "$INSTALL_ROOT" mokutil --sb-state 2>/dev/null; then
        log_message "INFO" "Secure Boot not supported or not enabled"
        return 0
    fi
    
    # Create Machine Owner Key (MOK)
    chroot "$INSTALL_ROOT" mokutil --import "$GRUB_DIR/voidance.mok" 2>/dev/null || {
        log_message "WARNING" "Failed to import MOK, Secure Boot may not work"
    }
    
    # Enroll GRUB with Secure Boot
    chroot "$INSTALL_ROOT" grub-install \
        --target=x86_64-efi \
        --efi-directory="$EFI_DIR" \
        --bootloader-id="Voidance" \
        --recheck \
        --no-nvram \
        --sbat
    
    log_message "INFO" "Secure Boot configuration completed"
}

# Function to create bootloader backup
create_bootloader_backup() {
    log_message "INFO" "Creating bootloader backup"
    
    local backup_dir="/boot/grub-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$INSTALL_ROOT$backup_dir"
    
    # Backup GRUB configuration
    cp -r "$INSTALL_ROOT$GRUB_DIR"/* "$INSTALL_ROOT$backup_dir/"
    
    # Backup EFI entries (UEFI only)
    if [[ "$(detect_firmware_type)" == "UEFI" ]]; then
        chroot "$INSTALL_ROOT" efibootmgr -v > "$INSTALL_ROOT$backup_dir/efi-entries.txt"
    fi
    
    # Backup MBR (BIOS only)
    if [[ "$(detect_firmware_type)" == "BIOS" ]]; then
        local boot_device=$(get_config "boot_device")
        dd if="$boot_device" of="$INSTALL_ROOT$backup_dir/mbr-backup.bin" bs=512 count=1
    fi
    
    log_message "INFO" "Bootloader backup created: $backup_dir"
}

# Function to validate bootloader installation
validate_bootloader() {
    log_message "INFO" "Validating bootloader installation"
    
    local firmware_type=$(detect_firmware_type)
    
    # Check GRUB files exist
    local grub_files=(
        "$INSTALL_ROOT$GRUB_DIR/grub.cfg"
        "$INSTALL_ROOT$GRUB_DIR/grubenv"
        "$INSTALL_ROOT$GRUB_DIR/x86_64-efi"
        "$INSTALL_ROOT$GRUB_DIR/i386-pc"
    )
    
    for file in "${grub_files[@]}"; do
        if [[ -e "$file" ]]; then
            log_message "INFO" "GRUB file found: $file"
        else
            log_message "WARNING" "GRUB file missing: $file"
        fi
    done
    
    # Check EFI files (UEFI only)
    if [[ "$firmware_type" == "UEFI" ]]; then
        local efi_files=(
            "$INSTALL_ROOT$EFI_DIR/EFI/Voidance/grubx64.efi"
            "$INSTALL_ROOT$EFI_DIR/EFI/BOOT/BOOTX64.EFI"
        )
        
        for file in "${efi_files[@]}"; do
            if [[ -e "$file" ]]; then
                log_message "INFO" "EFI file found: $file"
            else
                log_message "WARNING" "EFI file missing: $file"
            fi
        done
    fi
    
    # Test GRUB configuration
    if chroot "$INSTALL_ROOT" grub-script-check "$GRUB_DIR/grub.cfg" 2>/dev/null; then
        log_message "INFO" "GRUB configuration is valid"
    else
        log_message "ERROR" "GRUB configuration is invalid"
        return 1
    fi
    
    log_message "INFO" "Bootloader validation completed"
}

# Function to cleanup bootloader installation
cleanup_bootloader() {
    log_message "INFO" "Cleaning up bootloader installation"
    
    # Unmount EFI partition if mounted
    if mountpoint -q "$INSTALL_ROOT$EFI_DIR" 2>/dev/null; then
        umount "$INSTALL_ROOT$EFI_DIR"
    fi
    
    # Remove temporary files
    rm -f "$INSTALL_ROOT$GRUB_DIR/grub.cfg.new"
    rm -f "$INSTALL_ROOT$GRUB_DIR/device.map"
    
    log_message "INFO" "Bootloader cleanup completed"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$BOOTLOADER_LOG"
}

# Main bootloader installation function
main_bootloader() {
    log_message "INFO" "Starting Voidance bootloader installation"
    
    local firmware_type=$(detect_firmware_type)
    log_message "INFO" "Detected firmware type: $firmware_type"
    
    install_bootloader_deps
    
    case "$firmware_type" in
        "UEFI")
            configure_uefi_bootloader
            configure_secure_boot
            ;;
        "BIOS")
            configure_bios_bootloader
            ;;
    esac
    
    create_grub_config
    create_grub_theme
    generate_grub_config
    create_bootloader_backup
    validate_bootloader
    cleanup_bootloader
    
    log_message "INFO" "Voidance bootloader installation completed successfully"
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_bootloader "$@"
fi