#!/bin/bash
# Voidance Bootloader Recovery and Repair
# Provides tools for bootloader recovery and repair

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/bootloader-installation.sh"

# Recovery configuration
RECOVERY_LOG="/var/log/voidance-bootloader-recovery.log"
RECOVERY_DIR="/tmp/voidance-bootloader-recovery"

# Function to initialize recovery environment
init_recovery_environment() {
    log_message "INFO" "Initializing bootloader recovery environment"
    
    # Create recovery directory
    mkdir -p "$RECOVERY_DIR"
    
    # Initialize recovery log
    cat > "$RECOVERY_LOG" << EOF
Voidance Bootloader Recovery Log
===============================
Date: $(date)
Recovery Directory: $RECOVERY_DIR

EOF
    
    log_message "INFO" "Recovery environment initialized"
}

# Function to detect bootloader problems
detect_bootloader_problems() {
    log_message "INFO" "Detecting bootloader problems"
    
    local problems=()
    
    # Check if GRUB is installed
    if ! command -v grub-install >/dev/null 2>&1; then
        problems+=("GRUB not installed")
    fi
    
    # Check if GRUB configuration exists
    if [[ ! -f "/boot/grub/grub.cfg" ]]; then
        problems+=("GRUB configuration missing")
    fi
    
    # Check if EFI partition is mounted (UEFI systems)
    if [[ -d "/sys/firmware/efi" ]] && ! mountpoint -q "/boot/efi" 2>/dev/null; then
        problems+=("EFI partition not mounted")
    fi
    
    # Check if GRUB configuration is valid
    if command -v grub-script-check >/dev/null 2>&1 && [[ -f "/boot/grub/grub.cfg" ]]; then
        if ! grub-script-check "/boot/grub/grub.cfg" 2>/dev/null; then
            problems+=("GRUB configuration invalid")
        fi
    fi
    
    # Check for missing kernel
    if [[ ! -f "/boot/vmlinuz" ]] && ! ls /boot/vmlinuz-* 2>/dev/null; then
        problems+=("No kernel found")
    fi
    
    # Check for missing initramfs
    if [[ ! -f "/boot/initramfs.img" ]] && ! ls /boot/initramfs-* 2>/dev/null; then
        problems+=("No initramfs found")
    fi
    
    # Report problems
    if [[ ${#problems[@]} -eq 0 ]]; then
        log_message "INFO" "No bootloader problems detected"
        return 0
    else
        log_message "WARNING" "Bootloader problems detected:"
        for problem in "${problems[@]}"; do
            log_message "WARNING" "  - $problem"
        done
        return 1
    fi
}

# Function to repair GRUB installation
repair_grub_installation() {
    log_message "INFO" "Repairing GRUB installation"
    
    local firmware_type=$(detect_firmware_type)
    local boot_device=""
    local efi_partition=""
    
    # Detect boot device and EFI partition
    if [[ "$firmware_type" == "UEFI" ]]; then
        # Find EFI partition
        efi_partition=$(lsblk -no NAME,FSTYPE,MOUNTPOINT | grep -i vfat | grep -i efi | awk '{print "/dev/"$1}')
        if [[ -z "$efi_partition" ]]; then
            log_message "ERROR" "Could not find EFI partition"
            return 1
        fi
        
        # Find boot device
        boot_device=$(lsblk -no PKNAME "$efi_partition")
        boot_device="/dev/$boot_device"
    else
        # Find boot device for BIOS
        boot_device=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /) | head -1)
        boot_device="/dev/$boot_device"
    fi
    
    log_message "INFO" "Boot device: $boot_device"
    [[ -n "$efi_partition" ]] && log_message "INFO" "EFI partition: $efi_partition"
    
    # Reinstall GRUB
    case "$firmware_type" in
        "UEFI")
            # Mount EFI partition
            mkdir -p /boot/efi
            mount "$efi_partition" /boot/efi
            
            # Install GRUB for UEFI
            grub-install \
                --target=x86_64-efi \
                --efi-directory=/boot/efi \
                --bootloader-id="Voidance" \
                --recheck \
                --removable
            ;;
        "BIOS")
            # Install GRUB for BIOS
            grub-install \
                --target=i386-pc \
                --recheck \
                "$boot_device"
            ;;
    esac
    
    log_message "INFO" "GRUB installation repaired"
}

# Function to regenerate GRUB configuration
regenerate_grub_config() {
    log_message "INFO" "Regenerating GRUB configuration"
    
    # Update GRUB configuration
    grub-mkconfig -o /boot/grub/grub.cfg
    
    # Verify configuration
    if grub-script-check /boot/grub/grub.cfg; then
        log_message "INFO" "GRUB configuration regenerated successfully"
    else
        log_message "ERROR" "Generated GRUB configuration is invalid"
        return 1
    fi
}

# Function to restore from backup
restore_from_backup() {
    log_message "INFO" "Restoring bootloader from backup"
    
    # Find available backups
    local backups=($(ls -d /boot/grub-backup-* 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_message "ERROR" "No bootloader backups found"
        return 1
    fi
    
    # Select most recent backup
    local latest_backup=$(printf "%s\n" "${backups[@]}" | sort -r | head -1)
    log_message "INFO" "Using backup: $latest_backup"
    
    # Restore GRUB files
    if [[ -d "$latest_backup/grub" ]]; then
        cp -r "$latest_backup/grub"/* /boot/grub/
        log_message "INFO" "GRUB files restored from backup"
    fi
    
    # Restore EFI entries (if available)
    if [[ -f "$latest_backup/efi-entries.txt" ]]; then
        log_message "INFO" "EFI entries backup found, manual restoration may be required"
        cat "$latest_backup/efi-entries.txt"
    fi
    
    # Restore MBR (if available)
    if [[ -f "$latest_backup/mbr-backup.bin" ]]; then
        local boot_device=$(lsblk -no PKNAME $(findmnt -n -o SOURCE /) | head -1)
        boot_device="/dev/$boot_device"
        
        log_message "WARNING" "About to restore MBR on $boot_device"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            dd if="$latest_backup/mbr-backup.bin" of="$boot_device" bs=512 count=1
            log_message "INFO" "MBR restored from backup"
        fi
    fi
}

# Function to create emergency boot media
create_emergency_boot_media() {
    log_message "INFO" "Creating emergency boot media"
    
    # Check for available USB devices
    local usb_devices=()
    while IFS= read -r device; do
        if [[ -b "$device" ]] && [[ $(lsblk -no RM "$device") == "1" ]]; then
            usb_devices+=("$device")
        fi
    done < <(lsblk -no NAME,TYPE | grep disk | awk '{print "/dev/"$1}')
    
    if [[ ${#usb_devices[@]} -eq 0 ]]; then
        log_message "ERROR" "No USB devices found for emergency boot media"
        return 1
    fi
    
    # Select USB device
    echo "Available USB devices:"
    for i in "${!usb_devices[@]}"; do
        echo "$((i+1)). ${usb_devices[i]} ($(lsblk -no MODEL "${usb_devices[i]}"))"
    done
    
    read -p "Select USB device (1-${#usb_devices[@]}): " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#usb_devices[@]} ]]; then
        local selected_device="${usb_devices[$((selection-1))]}"
        log_message "INFO" "Selected USB device: $selected_device"
        
        # Create emergency boot USB
        create_emergency_usb "$selected_device"
    else
        log_message "ERROR" "Invalid selection"
        return 1
    fi
}

# Function to create emergency USB
create_emergency_usb() {
    local usb_device="$1"
    
    log_message "WARNING" "This will erase all data on $usb_device"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "INFO" "Emergency USB creation cancelled"
        return 0
    fi
    
    # Create emergency boot system
    local emergency_dir="$RECOVERY_DIR/emergency"
    mkdir -p "$emergency_dir"
    
    # Install minimal system to USB
    # This is a simplified version - in practice you'd use a proper live USB creation tool
    
    # Partition USB
    wipefs -a "$usb_device"
    sfdisk "$usb_device" << EOF
label: gpt
size=512M, type=EF00
type=8300
EOF
    
    # Format partitions
    local efi_part="${usb_device}1"
    local root_part="${usb_device}2"
    
    mkfs.vfat -F32 "$efi_part"
    mkfs.ext4 "$root_part"
    
    # Mount and install
    mkdir -p "$emergency_dir"/{efi,root}
    mount "$efi_part" "$emergency_dir/efi"
    mount "$root_part" "$emergency_dir/root"
    
    # Install GRUB
    grub-install \
        --target=x86_64-efi \
        --efi-directory="$emergency_dir/efi" \
        --boot-directory="$emergency_dir/root/boot" \
        --bootloader-id="Voidance-Emergency" \
        --removable \
        "$usb_device"
    
    # Create emergency GRUB configuration
    mkdir -p "$emergency_dir/root/boot/grub"
    cat > "$emergency_dir/root/boot/grub/grub.cfg" << 'EOF'
set timeout=10
set default=0

menuentry "Voidance Emergency Recovery" {
    search --no-floppy --fs-uuid --set=root $UUID
    linux /boot/vmlinuz root=UUID=$UUID rw rescue
    initrd /boot/initramfs.img
}

menuentry "Boot from First Hard Disk" {
    set root=(hd0)
    chainloader +1
}

menuentry "Reboot System" {
    reboot
}

menuentry "Shutdown System" {
    halt
}
EOF
    
    # Cleanup
    umount "$emergency_dir/efi"
    umount "$emergency_dir/root"
    
    log_message "INFO" "Emergency boot media created on $usb_device"
}

# Function to run comprehensive diagnostics
run_diagnostics() {
    log_message "INFO" "Running comprehensive bootloader diagnostics"
    
    echo "=== System Information ==="
    echo "Firmware Type: $(detect_firmware_type)"
    echo "Boot Device: $(lsblk -no PKNAME $(findmnt -n -o SOURCE /) | head -1)"
    echo "Root Filesystem: $(findmnt -n -o FSTYPE /)"
    echo ""
    
    echo "=== Partition Information ==="
    lsblk -f
    echo ""
    
    echo "=== GRUB Status ==="
    if command -v grub-install >/dev/null 2>&1; then
        echo "GRUB Version: $(grub-install --version)"
    else
        echo "GRUB: Not installed"
    fi
    
    if [[ -f "/boot/grub/grub.cfg" ]]; then
        echo "GRUB Config: Present"
        if grub-script-check /boot/grub/grub.cfg 2>/dev/null; then
            echo "GRUB Config: Valid"
        else
            echo "GRUB Config: Invalid"
        fi
    else
        echo "GRUB Config: Missing"
    fi
    echo ""
    
    echo "=== EFI Status (UEFI systems) ==="
    if [[ -d "/sys/firmware/efi" ]]; then
        echo "UEFI: Supported"
        if command -v efibootmgr >/dev/null 2>&1; then
            efibootmgr -v
        else
            echo "efibootmgr: Not available"
        fi
    else
        echo "UEFI: Not supported"
    fi
    echo ""
    
    echo "=== Kernel Status ==="
    if ls /boot/vmlinuz-* 2>/dev/null; then
        echo "Kernel: Found"
        ls -la /boot/vmlinuz-* | head -5
    else
        echo "Kernel: Not found"
    fi
    
    if ls /boot/initramfs-* 2>/dev/null; then
        echo "Initramfs: Found"
        ls -la /boot/initramfs-* | head -5
    else
        echo "Initramfs: Not found"
    fi
    
    log_message "INFO" "Diagnostics completed"
}

# Function to cleanup recovery environment
cleanup_recovery() {
    log_message "INFO" "Cleaning up recovery environment"
    
    # Remove recovery directory
    rm -rf "$RECOVERY_DIR"
    
    log_message "INFO" "Recovery cleanup completed"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$RECOVERY_LOG"
}

# Main recovery function
main_recovery() {
    log_message "INFO" "Starting Voidance bootloader recovery"
    
    init_recovery_environment
    
    # Run diagnostics first
    run_diagnostics
    
    # Detect problems
    if detect_bootloader_problems; then
        log_message "INFO" "No recovery needed"
    else
        log_message "INFO" "Attempting automatic recovery"
        
        # Attempt repairs
        repair_grub_installation
        regenerate_grub_config
        
        # Verify repairs
        if detect_bootloader_problems; then
            log_message "INFO" "Recovery completed successfully"
        else
            log_message "WARNING" "Recovery incomplete, manual intervention may be required"
        fi
    fi
    
    cleanup_recovery
}

# Interactive recovery menu
recovery_menu() {
    while true; do
        clear
        echo "Voidance Bootloader Recovery"
        echo "==========================="
        echo ""
        echo "1. Run Diagnostics"
        echo "2. Detect Problems"
        echo "3. Repair GRUB Installation"
        echo "4. Regenerate GRUB Configuration"
        echo "5. Restore from Backup"
        echo "6. Create Emergency Boot Media"
        echo "7. Exit"
        echo ""
        read -p "Select option: " choice
        
        case $choice in
            1) run_diagnostics; read -p "Press Enter to continue..." ;;
            2) detect_bootloader_problems; read -p "Press Enter to continue..." ;;
            3) repair_grub_installation; read -p "Press Enter to continue..." ;;
            4) regenerate_grub_config; read -p "Press Enter to continue..." ;;
            5) restore_from_backup; read -p "Press Enter to continue..." ;;
            6) create_emergency_boot_media; read -p "Press Enter to continue..." ;;
            7) break ;;
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "${1:-}" == "--menu" ]]; then
        recovery_menu
    else
        main_recovery "$@"
    fi
fi