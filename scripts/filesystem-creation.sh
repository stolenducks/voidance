#!/bin/bash
# Voidance Filesystem Creation and Mounting Module
# Provides filesystem creation and mounting functionality for installer

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Filesystem configuration
FS_CONFIG_FILE="/tmp/voidance-filesystem.conf"
MOUNT_CONFIG_FILE="/tmp/voidance-mounts.conf"
CRYPTTAB_FILE="/tmp/voidance-crypttab"

# Supported filesystems
declare -A FILESYSTEMS=(
    ["ext4"]="mkfs.ext4 -F"
    ["ext3"]="mkfs.ext3 -F"
    ["ext2"]="mkfs.ext2 -F"
    ["btrfs"]="mkfs.btrfs -f"
    ["xfs"]="mkfs.xfs -f"
    ["f2fs"]="mkfs.f2fs"
    ["fat32"]="mkfs.fat -F32"
    ["fat16"]="mkfs.fat -F16"
    ["ntfs"]="mkfs.ntfs -f"
    ["swap"]="mkswap"
)

# Filesystem options
declare -A FS_OPTIONS=(
    ["ext4"]="-E lazy_itable_init=1,lazy_journal_init=1"
    ["ext3"]="-E lazy_itable_init=1,lazy_journal_init=1"
    ["ext2"]="-E lazy_itable_init=1"
    ["btrfs"]="-f"
    ["xfs"]="-f"
    ["f2fs"]=""
    ["fat32"]="-F32"
    ["fat16"]="-F16"
    ["ntfs"]="-f"
    ["swap"]="-f"
)

# Mount options
declare -A MOUNT_OPTIONS=(
    ["/"]="defaults,noatime,errors=remount-ro"
    ["/boot"]="defaults,noatime"
    ["/boot/efi"]="defaults,umask=0077,shortname=winnt"
    ["/home"]="defaults,noatime,nodev,nosuid"
    ["/var"]="defaults,noatime,nodev,nosuid"
    ["/tmp"]="defaults,noatime,nodev,nosuid,mode=1777"
    ["/usr"]="defaults,ro,noatime"
    ["/opt"]="defaults,noatime,nodev"
    ["/srv"]="defaults,noatime,nodev,nosuid"
    ["/swap"]="swap"
)

# Function to detect available filesystem tools
detect_filesystem_tools() {
    local available_tools=()
    
    for fs in "${!FILESYSTEMS[@]}"; do
        local tool="${FILESYSTEMS[$fs]%% *}"
        if command -v "$tool" >/dev/null 2>&1; then
            available_tools+=("$fs")
        fi
    done
    
    echo "${available_tools[@]}"
}

# Function to create filesystem
create_filesystem() {
    local device="$1"
    local filesystem="$2"
    local label="${3:-}"
    local options="${4:-}"
    
    log_message "INFO" "Creating $filesystem filesystem on $device"
    
    # Check if device exists
    if [[ ! -b "$device" ]]; then
        log_message "ERROR" "Device $device does not exist"
        return 1
    fi
    
    # Check if filesystem is supported
    if [[ -z "${FILESYSTEMS[$filesystem]:-}" ]]; then
        log_message "ERROR" "Filesystem $filesystem is not supported"
        return 1
    fi
    
    # Check if filesystem tool is available
    local tool="${FILESYSTEMS[$filesystem]%% *}"
    if ! command -v "$tool" >/dev/null 2>&1; then
        log_message "ERROR" "Filesystem tool $tool is not available"
        return 1
    fi
    
    # Wipe existing filesystem signatures
    log_message "INFO" "Wiping existing filesystem signatures on $device"
    wipefs -a "$device" || {
        log_message "WARNING" "Failed to wipe filesystem signatures on $device"
    }
    
    # Build filesystem creation command
    local cmd="${FILESYSTEMS[$filesystem]}"
    
    # Add label if specified
    if [[ -n "$label" ]]; then
        case "$filesystem" in
            "ext4"|"ext3"|"ext2")
                cmd+=" -L $label"
                ;;
            "btrfs")
                cmd+=" -L $label"
                ;;
            "xfs")
                cmd+=" -L $label"
                ;;
            "fat32"|"fat16")
                cmd+=" -n $label"
                ;;
            "ntfs")
                cmd+=" -L $label"
                ;;
        esac
    fi
    
    # Add filesystem-specific options
    if [[ -n "${FS_OPTIONS[$filesystem]:-}" ]]; then
        cmd+=" ${FS_OPTIONS[$filesystem]}"
    fi
    
    # Add custom options
    if [[ -n "$options" ]]; then
        cmd+=" $options"
    fi
    
    # Add device
    cmd+=" $device"
    
    log_message "INFO" "Executing: $cmd"
    
    # Execute filesystem creation
    if eval "$cmd"; then
        log_message "INFO" "Successfully created $filesystem filesystem on $device"
        
        # Update filesystem configuration
        update_filesystem_config "$device" "$filesystem" "$label" "$options"
        
        return 0
    else
        log_message "ERROR" "Failed to create $filesystem filesystem on $device"
        return 1
    fi
}

# Function to create swap filesystem
create_swap() {
    local device="$1"
    local label="${2:-}"
    
    log_message "INFO" "Creating swap filesystem on $device"
    
    # Check if device exists
    if [[ ! -b "$device" ]]; then
        log_message "ERROR" "Device $device does not exist"
        return 1
    fi
    
    # Wipe existing signatures
    wipefs -a "$device" || {
        log_message "WARNING" "Failed to wipe filesystem signatures on $device"
    }
    
    # Create swap
    if mkswap "$device" ${label:+-L "$label"}; then
        log_message "INFO" "Successfully created swap filesystem on $device"
        
        # Update filesystem configuration
        update_filesystem_config "$device" "swap" "$label" ""
        
        return 0
    else
        log_message "ERROR" "Failed to create swap filesystem on $device"
        return 1
    fi
}

# Function to mount filesystem
mount_filesystem() {
    local device="$1"
    local mountpoint="$2"
    local filesystem="${3:-auto}"
    local options="${4:-defaults}"
    local dump="${5:-0}"
    local pass="${6:-0}"
    
    log_message "INFO" "Mounting $device on $mountpoint"
    
    # Check if device exists
    if [[ ! -b "$device" ]] && [[ "$device" != "tmpfs" ]] && [[ ! "$device" =~ ^/dev/mapper/ ]]; then
        log_message "ERROR" "Device $device does not exist"
        return 1
    fi
    
    # Create mount point if it doesn't exist
    if [[ ! -d "$mountpoint" ]]; then
        log_message "INFO" "Creating mount point: $mountpoint"
        mkdir -p "$mountpoint"
    fi
    
    # Check if mount point is already mounted
    if mountpoint -q "$mountpoint" 2>/dev/null; then
        log_message "WARNING" "Mount point $mountpoint is already mounted"
        return 0
    fi
    
    # Determine filesystem type if auto
    if [[ "$filesystem" == "auto" ]]; then
        filesystem=$(blkid -o value -s TYPE "$device" 2>/dev/null || echo "auto")
    fi
    
    # Use default mount options if not specified
    if [[ "$options" == "defaults" ]] && [[ -n "${MOUNT_OPTIONS[$mountpoint]:-}" ]]; then
        options="${MOUNT_OPTIONS[$mountpoint]}"
    fi
    
    # Mount the filesystem
    if mount -t "$filesystem" -o "$options" "$device" "$mountpoint"; then
        log_message "INFO" "Successfully mounted $device on $mountpoint"
        
        # Update mount configuration
        update_mount_config "$device" "$mountpoint" "$filesystem" "$options" "$dump" "$pass"
        
        return 0
    else
        log_message "ERROR" "Failed to mount $device on $mountpoint"
        return 1
    fi
}

# Function to unmount filesystem
unmount_filesystem() {
    local mountpoint="$1"
    
    log_message "INFO" "Unmounting $mountpoint"
    
    # Check if mount point is mounted
    if ! mountpoint -q "$mountpoint" 2>/dev/null; then
        log_message "WARNING" "Mount point $mountpoint is not mounted"
        return 0
    fi
    
    # Unmount the filesystem
    if umount "$mountpoint"; then
        log_message "INFO" "Successfully unmounted $mountpoint"
        return 0
    else
        log_message "ERROR" "Failed to unmount $mountpoint"
        return 1
    fi
}

# Function to create encrypted filesystem
create_encrypted_filesystem() {
    local device="$1"
    local mapper_name="$2"
    local filesystem="$3"
    local password="$4"
    local label="${5:-}"
    
    log_message "INFO" "Creating encrypted filesystem on $device"
    
    # Check if cryptsetup is available
    if ! command -v cryptsetup >/dev/null 2>&1; then
        log_message "ERROR" "cryptsetup is not available"
        return 1
    fi
    
    # Create LUKS container
    if echo "$password" | cryptsetup luksFormat "$device"; then
        log_message "INFO" "Successfully created LUKS container on $device"
        
        # Open the encrypted container
        if echo "$password" | cryptsetup open "$device" "$mapper_name"; then
            log_message "INFO" "Successfully opened encrypted container"
            
            # Create filesystem on the mapped device
            local mapped_device="/dev/mapper/$mapper_name"
            if create_filesystem "$mapped_device" "$filesystem" "$label"; then
                log_message "INFO" "Successfully created encrypted filesystem"
                
                # Update crypttab configuration
                update_crypttab_config "$device" "$mapper_name" "luks"
                
                return 0
            else
                log_message "ERROR" "Failed to create filesystem on encrypted device"
                cryptsetup close "$mapper_name"
                return 1
            fi
        else
            log_message "ERROR" "Failed to open encrypted container"
            return 1
        fi
    else
        log_message "ERROR" "Failed to create LUKS container"
        return 1
    fi
}

# Function to mount encrypted filesystem
mount_encrypted_filesystem() {
    local device="$1"
    local mapper_name="$2"
    local mountpoint="$3"
    local password="$4"
    local options="${5:-defaults}"
    
    log_message "INFO" "Mounting encrypted filesystem from $device"
    
    # Check if encrypted container is already open
    if [[ -b "/dev/mapper/$mapper_name" ]]; then
        log_message "INFO" "Encrypted container is already open"
    else
        # Open the encrypted container
        if echo "$password" | cryptsetup open "$device" "$mapper_name"; then
            log_message "INFO" "Successfully opened encrypted container"
        else
            log_message "ERROR" "Failed to open encrypted container"
            return 1
        fi
    fi
    
    # Mount the mapped device
    local mapped_device="/dev/mapper/$mapper_name"
    if mount_filesystem "$mapped_device" "$mountpoint" "auto" "$options"; then
        log_message "INFO" "Successfully mounted encrypted filesystem"
        return 0
    else
        log_message "ERROR" "Failed to mount encrypted filesystem"
        cryptsetup close "$mapper_name"
        return 1
    fi
}

# Function to update filesystem configuration
update_filesystem_config() {
    local device="$1"
    local filesystem="$2"
    local label="$3"
    local options="$4"
    
    # Create or update filesystem configuration
    cat >> "$FS_CONFIG_FILE" << EOF
# Filesystem entry for $device
DEVICE="$device"
FILESYSTEM="$filesystem"
LABEL="$label"
OPTIONS="$options"
CREATED="$(date)"

EOF
}

# Function to update mount configuration
update_mount_config() {
    local device="$1"
    local mountpoint="$2"
    local filesystem="$3"
    local options="$4"
    local dump="$5"
    local pass="$6"
    
    # Create or update mount configuration
    cat >> "$MOUNT_CONFIG_FILE" << EOF
# Mount entry for $device on $mountpoint
DEVICE="$device"
MOUNTPOINT="$mountpoint"
FILESYSTEM="$filesystem"
OPTIONS="$options"
DUMP="$dump"
PASS="$pass"
CREATED="$(date)"

EOF
}

# Function to update crypttab configuration
update_crypttab_config() {
    local device="$1"
    local mapper_name="$2"
    local options="${3:-luks}"
    
    # Create or update crypttab configuration
    cat >> "$CRYPTTAB_FILE" << EOF
# Crypttab entry for $device
$mapper_name $device none $options

EOF
}

# Function to generate fstab
generate_fstab() {
    local fstab_file="$1"
    
    log_message "INFO" "Generating fstab: $fstab_file"
    
    cat > "$fstab_file" << 'EOF'
# /etc/fstab: static file system information
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <dir>         <type>    <options>             <dump> <pass>

EOF
    
    # Add entries from mount configuration
    if [[ -f "$MOUNT_CONFIG_FILE" ]]; then
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$line" ]] && continue
            
            # Extract mount information
            if [[ "$line" =~ DEVICE=\"([^\"]+)\" ]]; then
                local device="${BASH_REMATCH[1]}"
            fi
            if [[ "$line" =~ MOUNTPOINT=\"([^\"]+)\" ]]; then
                local mountpoint="${BASH_REMATCH[1]}"
            fi
            if [[ "$line" =~ FILESYSTEM=\"([^\"]+)\" ]]; then
                local filesystem="${BASH_REMATCH[1]}"
            fi
            if [[ "$line" =~ OPTIONS=\"([^\"]+)\" ]]; then
                local options="${BASH_REMATCH[1]}"
            fi
            if [[ "$line" =~ DUMP=\"([^\"]+)\" ]]; then
                local dump="${BASH_REMATCH[1]}"
            fi
            if [[ "$line" =~ PASS=\"([^\"]+)\" ]]; then
                local pass="${BASH_REMATCH[1]}"
            fi
            
            # Get UUID for device
            local uuid=""
            if [[ -b "$device" ]]; then
                uuid=$(blkid -s UUID -o value "$device" 2>/dev/null || echo "")
            fi
            
            # Use UUID if available, otherwise use device path
            local device_spec="$device"
            if [[ -n "$uuid" ]]; then
                device_spec="UUID=$uuid"
            fi
            
            # Add to fstab
            printf "%-15s %-15s %-7s %-15s %s %s\n" \
                "$device_spec" "$mountpoint" "$filesystem" "$options" "$dump" "$pass" >> "$fstab_file"
            
        done < "$MOUNT_CONFIG_FILE"
    fi
    
    # Add virtual filesystems
    cat >> "$fstab_file" << 'EOF'

# Virtual filesystems
proc             /proc         proc      nosuid,noexec,nodev    0     0
sysfs            /sys          sysfs     nosuid,noexec,nodev    0     0
devtmpfs         /dev          devtmpfs  mode=0755,nosuid       0     0
tmpfs            /run          tmpfs     nosuid,nodev,mode=0755 0     0
tmpfs            /tmp          tmpfs     nosuid,nodev           0     0
EOF
    
    log_message "INFO" "fstab generated successfully"
}

# Function to generate crypttab
generate_crypttab() {
    local crypttab_file="$1"
    
    log_message "INFO" "Generating crypttab: $crypttab_file"
    
    cat > "$crypttab_file" << 'EOF'
# /etc/crypttab: encrypted block device table
#
# <target name> <source device> <key file> <options>

EOF
    
    # Add entries from crypttab configuration
    if [[ -f "$CRYPTTAB_FILE" ]]; then
        cat "$CRYPTTAB_FILE" >> "$crypttab_file"
    fi
    
    log_message "INFO" "crypttab generated successfully"
}

# Function to validate filesystem
validate_filesystem() {
    local device="$1"
    local filesystem="$2"
    
    log_message "INFO" "Validating filesystem on $device"
    
    # Check if device exists
    if [[ ! -b "$device" ]]; then
        log_message "ERROR" "Device $device does not exist"
        return 1
    fi
    
    # Check filesystem type
    local detected_fs
    detected_fs=$(blkid -o value -s TYPE "$device" 2>/dev/null || echo "")
    
    if [[ -z "$detected_fs" ]]; then
        log_message "ERROR" "No filesystem detected on $device"
        return 1
    fi
    
    if [[ "$detected_fs" != "$filesystem" ]]; then
        log_message "ERROR" "Filesystem mismatch: expected $filesystem, detected $detected_fs"
        return 1
    fi
    
    # Run filesystem check
    case "$filesystem" in
        "ext4"|"ext3"|"ext2")
            if command -v fsck.ext4 >/dev/null 2>&1; then
                fsck -n "$device" || {
                    log_message "WARNING" "Filesystem check failed on $device"
                }
            fi
            ;;
        "btrfs")
            if command -v btrfs >/dev/null 2>&1; then
                btrfs check "$device" || {
                    log_message "WARNING" "Btrfs check failed on $device"
                }
            fi
            ;;
        "xfs")
            if command -v xfs_repair >/dev/null 2>&1; then
                xfs_repair -n "$device" || {
                    log_message "WARNING" "XFS check failed on $device"
                }
            fi
            ;;
    esac
    
    log_message "INFO" "Filesystem validation completed for $device"
    return 0
}

# Function to show filesystem creation dialog
show_filesystem_creation_dialog() {
    local device="$1"
    
    local available_fs=($(detect_filesystem_tools))
    
    if [[ ${#available_fs[@]} -eq 0 ]]; then
        show_error_dialog "No Filesystem Tools" "No filesystem creation tools are available."
        return 1
    fi
    
    local options=()
    for fs in "${available_fs[@]}"; do
        options+=("$fs")
    done
    options+=("Swap")
    options+=("Encrypted")
    
    show_menu "Create Filesystem on $device" "${options[@]}"
    local result=$?
    
    if [[ $result -eq $((${#available_fs[@]})) ]]; then
        # Swap
        local label
        label=$(show_input_dialog "Create Swap" "Enter swap label (optional):")
        if [[ $? -eq 0 ]]; then
            create_swap "$device" "$label"
        fi
    elif [[ $result -eq $((${#available_fs[@]} + 1)) ]]; then
        # Encrypted
        show_encrypted_filesystem_dialog "$device"
    else
        # Regular filesystem
        local filesystem="${available_fs[$result]}"
        local label
        label=$(show_input_dialog "Create $filesystem Filesystem" "Enter filesystem label (optional):")
        if [[ $? -eq 0 ]]; then
            create_filesystem "$device" "$filesystem" "$label"
        fi
    fi
}

# Function to show encrypted filesystem dialog
show_encrypted_filesystem_dialog() {
    local device="$1"
    
    local mapper_name
    mapper_name=$(show_input_dialog "Encrypted Filesystem" "Enter mapper name:" "crypt_$(basename "$device")")
    [[ $? -ne 0 ]] && return 1
    
    local available_fs=($(detect_filesystem_tools))
    local options=()
    for fs in "${available_fs[@]}"; do
        if [[ "$fs" != "swap" ]]; then
            options+=("$fs")
        fi
    done
    
    show_menu "Select Filesystem for Encrypted Volume" "${options[@]}"
    local result=$?
    [[ $result -ne 0 ]] && return 1
    
    local filesystem="${available_fs[$result]}"
    
    local label
    label=$(show_input_dialog "Encrypted $filesystem Filesystem" "Enter filesystem label (optional):")
    [[ $? -ne 0 ]] && return 1
    
    local password
    password=$(show_password_dialog "Encrypted $filesystem Filesystem" "Enter encryption password:")
    [[ $? -ne 0 ]] && return 1
    
    local confirm_password
    confirm_password=$(show_password_dialog "Encrypted $filesystem Filesystem" "Confirm encryption password:")
    [[ $? -ne 0 ]] || [[ "$password" != "$confirm_password" ]] && {
        show_error_dialog "Password Mismatch" "Passwords do not match."
        return 1
    }
    
    create_encrypted_filesystem "$device" "$mapper_name" "$filesystem" "$password" "$label"
}

# Function to show mount dialog
show_mount_dialog() {
    local device="$1"
    
    local mountpoint
    mountpoint=$(show_input_dialog "Mount Filesystem" "Enter mount point:" "/mnt/$(basename "$device")")
    [[ $? -ne 0 ]] && return 1
    
    local filesystem
    filesystem=$(show_input_dialog "Mount Filesystem" "Enter filesystem type (auto for detection):" "auto")
    [[ $? -ne 0 ]] && return 1
    
    local options
    options=$(show_input_dialog "Mount Filesystem" "Enter mount options:" "defaults")
    [[ $? -ne 0 ]] && return 1
    
    mount_filesystem "$device" "$mountpoint" "$filesystem" "$options"
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

show_password_dialog() {
    local title="$1"
    local prompt="$2"
    
    echo "PASSWORD: $title - $prompt"
    echo "password"
    return 0
}

show_error_dialog() {
    local title="$1"
    local message="$2"
    
    echo "ERROR: $title - $message"
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Example usage
    if [[ $# -ge 2 ]]; then
        local device="$1"
        local action="$2"
        
        case "$action" in
            "create")
                show_filesystem_creation_dialog "$device"
                ;;
            "mount")
                show_mount_dialog "$device"
                ;;
            "unmount")
                local mountpoint="$3"
                unmount_filesystem "$mountpoint"
                ;;
            "validate")
                local filesystem="$3"
                validate_filesystem "$device" "$filesystem"
                ;;
            *)
                echo "Usage: $0 <device> {create|mount|unmount|validate} [args...]"
                exit 1
                ;;
        esac
    else
        echo "Usage: $0 <device> <action> [args...]"
        exit 1
    fi
fi