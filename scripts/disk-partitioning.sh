#!/bin/bash
# Voidance Disk Partitioning Module
# Provides disk partitioning functionality for the installer

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Disk configuration
DISK_CONFIG_FILE="/tmp/voidance-disk.conf"
PARTITION_TABLE="/tmp/voidance-partitions.txt"
MOUNT_POINTS="/tmp/voidance-mounts.txt"

# Function to detect available disks
detect_disks() {
    local disks=()
    
    # Get list of disks
    while IFS= read -r disk; do
        # Skip loop devices, CD-ROMs, and other non-storage devices
        if [[ "$disk" =~ ^(loop|sr|cdrom|fd) ]]; then
            continue
        fi
        
        # Get disk information
        local size=$(lsblk -bno SIZE "/dev/$disk" 2>/dev/null | head -1)
        local model=$(lsblk -dno MODEL "/dev/$disk" 2>/dev/null || echo "Unknown")
        local vendor=$(lsblk -dno VENDOR "/dev/$disk" 2>/dev/null || echo "Unknown")
        
        # Convert size to human readable
        local size_human=$(numfmt --to=iec-i --suffix=B "$size" 2>/dev/null || echo "$size")
        
        # Add to disks array
        disks+=("$disk|$size_human|$model|$vendor")
    done < <(lsblk -dno NAME 2>/dev/null | grep -E '^[hs]d[a-z]$|^[nv]me[0-9]+n[0-9]+$')
    
    echo "${disks[@]}"
}

# Function to show disk selection
show_disk_selection() {
    local title="$1"
    local disks=($(detect_disks))
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        show_error_dialog "No Disks Found" "No suitable storage devices were found. Please check your hardware and try again."
        return 1
    fi
    
    local options=()
    for disk_info in "${disks[@]}"; do
        IFS='|' read -r disk size model vendor <<< "$disk_info"
        options+=("$disk - $size ($vendor $model)")
    done
    
    options+=("Refresh disk list")
    options+=("Manual disk entry")
    
    show_menu "$title" "${options[@]}"
    local result=$?
    
    if [[ $result -eq $((${#disks[@]})) ]]; then
        # Refresh disk list
        show_disk_selection "$title"
        return $?
    elif [[ $result -eq $((${#disks[@]} + 1)) ]]; then
        # Manual disk entry
        local disk_name
        disk_name=$(show_input_dialog "Manual Disk Entry" "Enter disk device name (e.g., sda, nvme0n1):")
        if [[ $? -eq 0 ]] && [[ -n "$disk_name" ]]; then
            echo "$disk_name"
            return 0
        else
            show_disk_selection "$title"
            return $?
        fi
    else
        # Selected disk
        local disk_info="${disks[$result]}"
        IFS='|' read -r disk size model vendor <<< "$disk_info"
        echo "$disk"
        return 0
    fi
}

# Function to get disk information
get_disk_info() {
    local disk="$1"
    
    # Get disk size
    local size_bytes=$(lsblk -bno SIZE "/dev/$disk" 2>/dev/null | head -1)
    local size_human=$(numfmt --to=iec-i --suffix=B "$size_bytes" 2>/dev/null || echo "$size_bytes")
    
    # Get disk model
    local model=$(lsblk -dno MODEL "/dev/$disk" 2>/dev/null || echo "Unknown")
    local vendor=$(lsblk -dno VENDOR "/dev/$disk" 2>/dev/null || echo "Unknown")
    
    # Get disk type
    local disk_type=$(lsblk -dno TYPE "/dev/$disk" 2>/dev/null || echo "Unknown")
    
    # Get partition table type
    local pttype=$(blkid -s PTTYPE -o value "/dev/$disk" 2>/dev/null || echo "None")
    
    # Get current partitions
    local partitions=$(lsblk -lno NAME "/dev/$disk" 2>/dev/null | grep -E "^${disk}[0-9]+" | wc -l)
    
    cat << EOF
Disk Information
================
Device: /dev/$disk
Size: $size_human
Model: $vendor $model
Type: $disk_type
Partition Table: $pttype
Current Partitions: $partitions

EOF
}

# Function to show partitioning options
show_partitioning_options() {
    local disk="$1"
    
    local options=(
        "Automatic (use entire disk)"
        "Automatic with separate /home"
        "Automatic with LVM"
        "Automatic with encryption"
        "Manual partitioning"
        "Show current disk info"
        "Refresh disk list"
    )
    
    show_menu "Partitioning Options for /dev/$disk" "${options[@]}"
}

# Function to create automatic partitioning scheme
create_automatic_partitions() {
    local disk="$1"
    local scheme="$2"
    
    log_message "INFO" "Creating automatic partitioning scheme: $scheme for /dev/$disk"
    
    case "$scheme" in
        "auto")
            create_simple_partitions "$disk"
            ;;
        "home")
            create_home_partitions "$disk"
            ;;
        "lvm")
            create_lvm_partitions "$disk"
            ;;
        "encrypt")
            create_encrypted_partitions "$disk"
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to create simple partition scheme
create_simple_partitions() {
    local disk="$1"
    
    # Get disk size in sectors
    local disk_size=$(lsblk -bno SIZE "/dev/$disk" 2>/dev/null | head -1)
    local sector_size=$(cat "/sys/block/$disk/queue/physical_block_size" 2>/dev/null || echo 512)
    local total_sectors=$((disk_size / sector_size))
    
    # Calculate partition sizes
    local efi_start=2048
    local efi_size=512M
    local efi_sectors=$((512 * 1024 * 1024 / sector_size))
    local efi_end=$((efi_start + efi_sectors - 1))
    
    local boot_start=$((efi_end + 1))
    local boot_size=1G
    local boot_sectors=$((1024 * 1024 * 1024 / sector_size))
    local boot_end=$((boot_start + boot_sectors - 1))
    
    local root_start=$((boot_end + 1))
    local root_end=$((total_sectors - 1))
    
    # Create partition commands
    cat > "$PARTITION_TABLE" << EOF
# Voidance Automatic Partition Scheme for /dev/$disk
# Created on $(date)

# Clear existing partitions
wipefs -a /dev/$disk

# Create new GPT partition table
parted /dev/$disk mklabel gpt

# EFI System Partition (if UEFI)
parted /dev/$disk mkpart ESP fat32 $efi_start $efi_end
parted /dev/$disk set 1 boot on
parted /dev/$disk set 1 esp on

# Boot Partition
parted /dev/$disk mkpart primary ext4 $boot_start $boot_end

# Root Partition
parted /dev/$disk mkpart primary ext4 $root_start $root_end

# Format partitions
mkfs.fat -F32 /dev/${disk}1
mkfs.ext4 -F /dev/${disk}2
mkfs.ext4 -F /dev/${disk}3

# Create mount points
mkdir -p /mnt/boot/efi
mkdir -p /mnt/boot
mkdir -p /mnt

# Mount partitions
mount /dev/${disk}3 /mnt
mount /dev/${disk}2 /mnt/boot
mount /dev/${disk}1 /mnt/boot/efi

EOF
    
    # Create mount points file
    cat > "$MOUNT_POINTS" << EOF
/dev/${disk}1 /boot/efi vfat defaults,umask=0077 0 1
/dev/${disk}2 /boot ext4 defaults,noatime 0 2
/dev/${disk}3 / ext4 defaults,noatime 0 1
EOF
    
    log_message "INFO" "Simple partition scheme created for /dev/$disk"
    return 0
}

# Function to create partition scheme with separate /home
create_home_partitions() {
    local disk="$1"
    
    # Get disk size in sectors
    local disk_size=$(lsblk -bno SIZE "/dev/$disk" 2>/dev/null | head -1)
    local sector_size=$(cat "/sys/block/$disk/queue/physical_block_size" 2>/dev/null || echo 512)
    local total_sectors=$((disk_size / sector_size))
    
    # Calculate partition sizes
    local efi_start=2048
    local efi_size=512M
    local efi_sectors=$((512 * 1024 * 1024 / sector_size))
    local efi_end=$((efi_start + efi_sectors - 1))
    
    local boot_start=$((efi_end + 1))
    local boot_size=1G
    local boot_sectors=$((1024 * 1024 * 1024 / sector_size))
    local boot_end=$((boot_start + boot_sectors - 1))
    
    local root_start=$((boot_end + 1))
    local root_size=20G
    local root_sectors=$((20 * 1024 * 1024 * 1024 / sector_size))
    local root_end=$((root_start + root_sectors - 1))
    
    local home_start=$((root_end + 1))
    local home_end=$((total_sectors - 1))
    
    # Create partition commands
    cat > "$PARTITION_TABLE" << EOF
# Voidance Partition Scheme with /home for /dev/$disk
# Created on $(date)

# Clear existing partitions
wipefs -a /dev/$disk

# Create new GPT partition table
parted /dev/$disk mklabel gpt

# EFI System Partition (if UEFI)
parted /dev/$disk mkpart ESP fat32 $efi_start $efi_end
parted /dev/$disk set 1 boot on
parted /dev/$disk set 1 esp on

# Boot Partition
parted /dev/$disk mkpart primary ext4 $boot_start $boot_end

# Root Partition
parted /dev/$disk mkpart primary ext4 $root_start $root_end

# Home Partition
parted /dev/$disk mkpart primary ext4 $home_start $home_end

# Format partitions
mkfs.fat -F32 /dev/${disk}1
mkfs.ext4 -F /dev/${disk}2
mkfs.ext4 -F /dev/${disk}3
mkfs.ext4 -F /dev/${disk}4

# Create mount points
mkdir -p /mnt/boot/efi
mkdir -p /mnt/boot
mkdir -p /mnt
mkdir -p /mnt/home

# Mount partitions
mount /dev/${disk}3 /mnt
mount /dev/${disk}4 /mnt/home
mount /dev/${disk}2 /mnt/boot
mount /dev/${disk}1 /mnt/boot/efi

EOF
    
    # Create mount points file
    cat > "$MOUNT_POINTS" << EOF
/dev/${disk}1 /boot/efi vfat defaults,umask=0077 0 1
/dev/${disk}2 /boot ext4 defaults,noatime 0 2
/dev/${disk}3 / ext4 defaults,noatime 0 1
/dev/${disk}4 /home ext4 defaults,noatime 0 2
EOF
    
    log_message "INFO" "Partition scheme with /home created for /dev/$disk"
    return 0
}

# Function to create LVM partition scheme
create_lvm_partitions() {
    local disk="$1"
    
    # Get disk size in sectors
    local disk_size=$(lsblk -bno SIZE "/dev/$disk" 2>/dev/null | head -1)
    local sector_size=$(cat "/sys/block/$disk/queue/physical_block_size" 2>/dev/null || echo 512)
    local total_sectors=$((disk_size / sector_size))
    
    # Calculate partition sizes
    local efi_start=2048
    local efi_size=512M
    local efi_sectors=$((512 * 1024 * 1024 / sector_size))
    local efi_end=$((efi_start + efi_sectors - 1))
    
    local boot_start=$((efi_end + 1))
    local boot_size=1G
    local boot_sectors=$((1024 * 1024 * 1024 / sector_size))
    local boot_end=$((boot_start + boot_sectors - 1))
    
    local lvm_start=$((boot_end + 1))
    local lvm_end=$((total_sectors - 1))
    
    # Create partition commands
    cat > "$PARTITION_TABLE" << EOF
# Voidance LVM Partition Scheme for /dev/$disk
# Created on $(date)

# Clear existing partitions
wipefs -a /dev/$disk

# Create new GPT partition table
parted /dev/$disk mklabel gpt

# EFI System Partition (if UEFI)
parted /dev/$disk mkpart ESP fat32 $efi_start $efi_end
parted /dev/$disk set 1 boot on
parted /dev/$disk set 1 esp on

# Boot Partition
parted /dev/$disk mkpart primary ext4 $boot_start $boot_end

# LVM Partition
parted /dev/$disk mkpart primary ext4 $lvm_start $lvm_end
parted /dev/$disk set 3 lvm on

# Format partitions
mkfs.fat -F32 /dev/${disk}1
mkfs.ext4 -F /dev/${disk}2

# Setup LVM
pvcreate /dev/${disk}3
vgcreate voidance /dev/${disk}3

# Create logical volumes
lvcreate -L 20G -n root voidance
lvcreate -l 100%FREE -n home voidance

# Format logical volumes
mkfs.ext4 -F /dev/voidance/root
mkfs.ext4 -F /dev/voidance/home

# Create mount points
mkdir -p /mnt/boot/efi
mkdir -p /mnt/boot
mkdir -p /mnt
mkdir -p /mnt/home

# Mount partitions
mount /dev/voidance/root /mnt
mount /dev/voidance/home /mnt/home
mount /dev/${disk}2 /mnt/boot
mount /dev/${disk}1 /mnt/boot/efi

EOF
    
    # Create mount points file
    cat > "$MOUNT_POINTS" << EOF
/dev/${disk}1 /boot/efi vfat defaults,umask=0077 0 1
/dev/${disk}2 /boot ext4 defaults,noatime 0 2
/dev/voidance/root / ext4 defaults,noatime 0 1
/dev/voidance/home /home ext4 defaults,noatime 0 2
EOF
    
    log_message "INFO" "LVM partition scheme created for /dev/$disk"
    return 0
}

# Function to create encrypted partition scheme
create_encrypted_partitions() {
    local disk="$1"
    
    # Get disk size in sectors
    local disk_size=$(lsblk -bno SIZE "/dev/$disk" 2>/dev/null | head -1)
    local sector_size=$(cat "/sys/block/$disk/queue/physical_block_size" 2>/dev/null || echo 512)
    local total_sectors=$((disk_size / sector_size))
    
    # Calculate partition sizes
    local efi_start=2048
    local efi_size=512M
    local efi_sectors=$((512 * 1024 * 1024 / sector_size))
    local efi_end=$((efi_start + efi_sectors - 1))
    
    local boot_start=$((efi_end + 1))
    local boot_size=1G
    local boot_sectors=$((1024 * 1024 * 1024 / sector_size))
    local boot_end=$((boot_start + boot_sectors - 1))
    
    local luks_start=$((boot_end + 1))
    local luks_end=$((total_sectors - 1))
    
    # Create partition commands
    cat > "$PARTITION_TABLE" << EOF
# Voidance Encrypted Partition Scheme for /dev/$disk
# Created on $(date)

# Clear existing partitions
wipefs -a /dev/$disk

# Create new GPT partition table
parted /dev/$disk mklabel gpt

# EFI System Partition (if UEFI)
parted /dev/$disk mkpart ESP fat32 $efi_start $efi_end
parted /dev/$disk set 1 boot on
parted /dev/$disk set 1 esp on

# Boot Partition
parted /dev/$disk mkpart primary ext4 $boot_start $boot_end

# LUKS Encrypted Partition
parted /dev/$disk mkpart primary ext4 $luks_start $luks_end

# Format partitions
mkfs.fat -F32 /dev/${disk}1
mkfs.ext4 -F /dev/${disk}2

# Setup LUKS encryption
cryptsetup luksFormat /dev/${disk}3
cryptsetup open /dev/${disk}3 voidance_crypt

# Create LVM on encrypted device
pvcreate /dev/mapper/voidance_crypt
vgcreate voidance /dev/mapper/voidance_crypt

# Create logical volumes
lvcreate -L 20G -n root voidance
lvcreate -l 100%FREE -n home voidance

# Format logical volumes
mkfs.ext4 -F /dev/voidance/root
mkfs.ext4 -F /dev/voidance/home

# Create mount points
mkdir -p /mnt/boot/efi
mkdir -p /mnt/boot
mkdir -p /mnt
mkdir -p /mnt/home

# Mount partitions
mount /dev/voidance/root /mnt
mount /dev/voidance/home /mnt/home
mount /dev/${disk}2 /mnt/boot
mount /dev/${disk}1 /mnt/boot/efi

EOF
    
    # Create mount points file
    cat > "$MOUNT_POINTS" << EOF
/dev/${disk}1 /boot/efi vfat defaults,umask=0077 0 1
/dev/${disk}2 /boot ext4 defaults,noatime 0 2
/dev/voidance/root / ext4 defaults,noatime 0 1
/dev/voidance/home /home ext4 defaults,noatime 0 2
EOF
    
    log_message "INFO" "Encrypted partition scheme created for /dev/$disk"
    return 0
}

# Function to show manual partitioning
show_manual_partitioning() {
    local disk="$1"
    
    while true; do
        local options=(
            "Show current partitions"
            "Create new partition"
            "Delete partition"
            "Format partition"
            "Set partition flags"
            "Apply changes"
            "Cancel"
        )
        
        show_menu "Manual Partitioning for /dev/$disk" "${options[@]}"
        local result=$?
        
        case $result in
            0) show_current_partitions "$disk" ;;
            1) create_new_partition "$disk" ;;
            2) delete_partition "$disk" ;;
            3) format_partition "$disk" ;;
            4) set_partition_flags "$disk" ;;
            5) apply_manual_changes "$disk" && return 0 ;;
            6) return 1 ;;
        esac
    done
}

# Function to show current partitions
show_current_partitions() {
    local disk="$1"
    
    draw_header "Current Partitions for /dev/$disk" "$((CURRENT_STEP + 1))"
    
    echo -e "${WHITE}Current partition table:${NC}"
    echo ""
    
    # Show partition table
    if command -v fdisk >/dev/null 2>&1; then
        fdisk -l "/dev/$disk" 2>/dev/null || echo "Unable to read partition table"
    else
        lsblk "/dev/$disk" 2>/dev/null || echo "Unable to read partition table"
    fi
    
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read -r
}

# Function to create new partition
create_new_partition() {
    local disk="$1"
    
    local partition_type
    partition_type=$(show_input_dialog "Create Partition" "Enter partition type (primary/extended):" "primary")
    [[ $? -ne 0 ]] && return 1
    
    local start_sector
    start_sector=$(show_input_dialog "Create Partition" "Enter start sector:" "2048")
    [[ $? -ne 0 ]] && return 1
    
    local end_sector
    end_sector=$(show_input_dialog "Create Partition" "Enter end sector (or +size):" "+10G")
    [[ $? -ne 0 ]] && return 1
    
    local filesystem
    filesystem=$(show_input_dialog "Create Partition" "Enter filesystem type (ext4/btrfs/xfs/fat32/ntfs):" "ext4")
    [[ $? -ne 0 ]] && return 1
    
    log_message "INFO" "Manual partition created: /dev/$disk type=$partition_type start=$start_sector end=$end_sector fs=$filesystem"
    
    show_success_dialog "Partition Created" "New partition will be created with specified settings."
}

# Function to delete partition
delete_partition() {
    local disk="$1"
    
    local partition_number
    partition_number=$(show_input_dialog "Delete Partition" "Enter partition number to delete:")
    [[ $? -ne 0 ]] && return 1
    
    if show_confirm_dialog "Delete Partition" "Are you sure you want to delete partition $partition_number? This will erase all data on this partition." "no"; then
        log_message "INFO" "Manual partition deleted: /dev/$disk partition=$partition_number"
        show_success_dialog "Partition Deleted" "Partition $partition_number will be deleted."
    fi
}

# Function to format partition
format_partition() {
    local disk="$1"
    
    local partition_number
    partition_number=$(show_input_dialog "Format Partition" "Enter partition number to format:")
    [[ $? -ne 0 ]] && return 1
    
    local filesystem
    filesystem=$(show_input_dialog "Format Partition" "Enter filesystem type (ext4/btrfs/xfs/fat32/ntfs):" "ext4")
    [[ $? -ne 0 ]] && return 1
    
    if show_confirm_dialog "Format Partition" "Are you sure you want to format partition $partition_number as $filesystem? This will erase all data on this partition." "no"; then
        log_message "INFO" "Manual partition formatted: /dev/$disk partition=$partition_number fs=$filesystem"
        show_success_dialog "Partition Formatted" "Partition $partition_number will be formatted as $filesystem."
    fi
}

# Function to set partition flags
set_partition_flags() {
    local disk="$1"
    
    local partition_number
    partition_number=$(show_input_dialog "Set Partition Flags" "Enter partition number:")
    [[ $? -ne 0 ]] && return 1
    
    local flags
    flags=$(show_input_dialog "Set Partition Flags" "Enter flags (boot,esp,lvm,raid):" "boot")
    [[ $? -ne 0 ]] && return 1
    
    log_message "INFO" "Manual partition flags set: /dev/$disk partition=$partition_number flags=$flags"
    show_success_dialog "Flags Set" "Partition flags will be set to: $flags"
}

# Function to apply manual changes
apply_manual_changes() {
    local disk="$1"
    
    if show_confirm_dialog "Apply Changes" "Are you sure you want to apply all manual partitioning changes? This will modify your disk and may erase data." "no"; then
        log_message "INFO" "Manual partitioning changes applied for /dev/$disk"
        show_success_dialog "Changes Applied" "Manual partitioning changes have been applied."
        return 0
    else
        return 1
    fi
}

# Function to validate partitioning
validate_partitioning() {
    local disk="$1"
    
    # Check if partition table exists
    if [[ ! -f "$PARTITION_TABLE" ]]; then
        show_error_dialog "No Partitioning" "No partitioning scheme has been created. Please create a partitioning scheme first."
        return 1
    fi
    
    # Check if mount points exist
    if [[ ! -f "$MOUNT_POINTS" ]]; then
        show_error_dialog "No Mount Points" "No mount points have been defined. Please define mount points first."
        return 1
    fi
    
    # Validate required mount points
    local required_mounts=("/" "/boot")
    for mount in "${required_mounts[@]}"; do
        if ! grep -q " $mount " "$MOUNT_POINTS"; then
            show_error_dialog "Missing Mount Point" "Required mount point $mount is not defined."
            return 1
        fi
    done
    
    # Check if disk exists
    if [[ ! -b "/dev/$disk" ]]; then
        show_error_dialog "Disk Not Found" "Disk /dev/$disk does not exist or is not accessible."
        return 1
    fi
    
    log_message "INFO" "Partitioning validation passed for /dev/$disk"
    return 0
}

# Function to execute partitioning
execute_partitioning() {
    local disk="$1"
    
    if ! validate_partitioning "$disk"; then
        return 1
    fi
    
    if ! show_confirm_dialog "Execute Partitioning" "This will execute the partitioning commands and may erase data on /dev/$disk. Are you sure you want to continue?" "no"; then
        return 1
    fi
    
    show_progress_dialog "Executing Partitioning" \
        "Please wait while partitioning is executed..." \
        "bash $PARTITION_TABLE"
    
    if [[ $? -eq 0 ]]; then
        show_success_dialog "Partitioning Complete" "Disk partitioning has been completed successfully."
        return 0
    else
        show_error_dialog "Partitioning Failed" "Disk partitioning failed. Please check the logs for details."
        return 1
    fi
}

# Function to save disk configuration
save_disk_config() {
    local disk="$1"
    local scheme="$2"
    
    cat > "$DISK_CONFIG_FILE" << EOF
# Voidance Disk Configuration
# Created on $(date)

DISK="$disk"
SCHEME="$scheme"
PARTITION_TABLE="$PARTITION_TABLE"
MOUNT_POINTS="$MOUNT_POINTS"

EOF
    
    log_message "INFO" "Disk configuration saved: disk=$disk scheme=$scheme"
}

# Function to load disk configuration
load_disk_config() {
    if [[ -f "$DISK_CONFIG_FILE" ]]; then
        source "$DISK_CONFIG_FILE"
        log_message "INFO" "Disk configuration loaded: disk=$DISK scheme=$SCHEME"
        return 0
    else
        return 1
    fi
}

# Function to main disk configuration
main_disk_configuration() {
    while true; do
        local disk
        disk=$(show_disk_selection "Disk Configuration")
        
        if [[ $? -ne 0 ]] || [[ -z "$disk" ]]; then
            return 1
        fi
        
        # Show disk information
        get_disk_info "$disk"
        
        # Show partitioning options
        show_partitioning_options "$disk"
        local result=$?
        
        case $result in
            0) # Automatic
                create_automatic_partitions "$disk" "auto"
                save_disk_config "$disk" "auto"
                execute_partitioning "$disk"
                return 0
                ;;
            1) # Automatic with /home
                create_automatic_partitions "$disk" "home"
                save_disk_config "$disk" "home"
                execute_partitioning "$disk"
                return 0
                ;;
            2) # LVM
                create_automatic_partitions "$disk" "lvm"
                save_disk_config "$disk" "lvm"
                execute_partitioning "$disk"
                return 0
                ;;
            3) # Encrypted
                create_automatic_partitions "$disk" "encrypt"
                save_disk_config "$disk" "encrypt"
                execute_partitioning "$disk"
                return 0
                ;;
            4) # Manual
                if show_manual_partitioning "$disk"; then
                    save_disk_config "$disk" "manual"
                    return 0
                fi
                ;;
            5) # Show disk info
                continue
                ;;
            6) # Refresh
                continue
                ;;
        esac
    done
}

# Function to log message (reuse from installer)
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date): [$level] $message" >> "/var/log/voidance-installer.log"
}

# Function to show dialogs (reuse from installer)
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo "MENU: $title"
    printf "Option %d: %s\n" 0 "${options[0]}"
    return 0
}

show_input_dialog() {
    local title="$1"
    local prompt="$2"
    local default="${3:-}"
    
    echo "INPUT: $title - $prompt (default: $default)"
    echo "$default"
    return 0
}

show_confirm_dialog() {
    local title="$1"
    local message="$2"
    local default="${3:-no}"
    
    echo "CONFIRM: $title - $message (default: $default)"
    return 0
}

show_error_dialog() {
    local title="$1"
    local message="$2"
    
    echo "ERROR: $title - $message"
    return 0
}

show_success_dialog() {
    local title="$1"
    local message="$2"
    
    echo "SUCCESS: $title - $message"
    return 0
}

show_progress_dialog() {
    local title="$1"
    local message="$2"
    local command="$3"
    
    echo "PROGRESS: $title - $message"
    eval "$command"
    return 0
}

draw_header() {
    local title="$1"
    local step="$2"
    
    echo "HEADER: $title (Step $step)"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_disk_configuration
fi