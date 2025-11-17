#!/bin/bash
# Voidance User Permissions and Groups Configuration
# Manages user groups, permissions, and security policies

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/iso/config.sh"

# Permissions configuration
PERMISSIONS_LOG="/var/log/voidance-permissions.log"

# Define system groups and their purposes
declare -A SYSTEM_GROUPS=(
    ["wheel"]="Administrative access (sudo)"
    ["audio"]="Audio device access"
    ["video"]="Video device access"
    ["input"]="Input device access (keyboard, mouse, touchpad)"
    ["storage"]="Storage device access (USB drives, external disks)"
    ["network"]="Network configuration access"
    ["lp"]="Printer access"
    ["scanner"]="Scanner access"
    ["cdrom"]="CD/DVD drive access"
    ["floppy"]="Floppy drive access"
    ["dialout"]="Modem and serial port access"
    ["plugdev"]="Plugable device access"
    ["users"]="Standard user group"
    ["games"]="Game access"
    ["rfkill"]="RF kill switch control"
    ["systemd-journal"]="Systemd journal access"
    ["adm"]="System administration files access"
    ["tty"]="Terminal device access"
)

# Define special purpose groups
declare -A SPECIAL_GROUPS=(
    ["docker"]="Docker container management"
    ["libvirt"]="Virtual machine management"
    ["kvm"]="Kernel virtual machine access"
    ["vboxusers"]="VirtualBox access"
    ["wireshark"]="Network capture with Wireshark"
    ["tor"]="Tor anonymous network access"
)

# Function to create system groups
create_system_groups() {
    log_message "INFO" "Creating system groups"
    
    for group in "${!SYSTEM_GROUPS[@]}"; do
        if ! getent group "$group" &>/dev/null; then
            groupadd "$group"
            log_message "INFO" "Created group: $group (${SYSTEM_GROUPS[$group]})"
        else
            log_message "INFO" "Group already exists: $group"
        fi
    done
    
    log_message "INFO" "System groups creation completed"
}

# Function to create special purpose groups
create_special_groups() {
    log_message "INFO" "Creating special purpose groups"
    
    for group in "${!SPECIAL_GROUPS[@]}"; do
        if ! getent group "$group" &>/dev/null; then
            groupadd "$group"
            log_message "INFO" "Created special group: $group (${SPECIAL_GROUPS[$group]})"
        else
            log_message "INFO" "Special group already exists: $group"
        fi
    done
    
    log_message "INFO" "Special groups creation completed"
}

# Function to configure default user groups
configure_default_user_groups() {
    local username="$1"
    local user_type="${2:-standard}"
    
    log_message "INFO" "Configuring groups for user: $username (type: $user_type)"
    
    case "$user_type" in
        "standard")
            local groups="wheel,audio,video,input,storage,network,lp,scanner,users,systemd-journal"
            ;;
        "developer")
            local groups="wheel,audio,video,input,storage,network,lp,scanner,users,systemd-journal,docker,libvirt,kvm"
            ;;
        "admin")
            local groups="wheel,audio,video,input,storage,network,lp,scanner,users,systemd-journal,adm,docker,libvirt,kvm"
            ;;
        "minimal")
            local groups="audio,video,input,users"
            ;;
        *)
            log_message "ERROR" "Unknown user type: $user_type"
            return 1
            ;;
    esac
    
    # Add user to groups
    usermod -G "$groups" "$username"
    log_message "INFO" "User '$username' added to groups: $groups"
}

# Function to configure sudo access
configure_sudo_access() {
    local username="$1"
    local sudo_level="${2:-standard}"
    
    log_message "INFO" "Configuring sudo access for user: $username (level: $sudo_level)"
    
    local sudo_file="/etc/sudoers.d/voidance-$username"
    
    case "$sudo_level" in
        "full")
            # Full sudo access without password
            cat > "$sudo_file" << EOF
# Full sudo access for $username
$username ALL=(ALL) NOPASSWD: ALL
EOF
            ;;
        "standard")
            # Standard sudo access with password
            cat > "$sudo_file" << EOF
# Standard sudo access for $username
$username ALL=(ALL) ALL
EOF
            ;;
        "limited")
            # Limited sudo access for specific commands
            cat > "$sudo_file" << EOF
# Limited sudo access for $username
$username ALL=(ALL) /usr/bin/systemctl, /usr/bin/xbps-install, /usr/bin/xbps-remove, /usr/bin/reboot, /usr/bin/poweroff
EOF
            ;;
        "none")
            # No sudo access
            rm -f "$sudo_file" 2>/dev/null || true
            ;;
        *)
            log_message "ERROR" "Unknown sudo level: $sudo_level"
            return 1
            ;;
    esac
    
    # Set proper permissions
    if [[ -f "$sudo_file" ]]; then
        chmod 440 "$sudo_file"
        log_message "INFO" "Sudo configuration created: $sudo_file"
    fi
}

# Function to configure file permissions
configure_file_permissions() {
    local username="$1"
    local home_dir="/home/$username"
    
    log_message "INFO" "Configuring file permissions for user: $username"
    
    # Set home directory permissions
    chmod 755 "$home_dir"
    chown "$username:$username" "$home_dir"
    
    # Set config directory permissions
    find "$home_dir/.config" -type d -exec chmod 700 {} \;
    find "$home_dir/.config" -type f -exec chmod 600 {} \;
    chown -R "$username:$username" "$home_dir/.config"
    
    # Set local directory permissions
    find "$home_dir/.local" -type d -exec chmod 755 {} \;
    find "$home_dir/.local" -type f -exec chmod 644 {} \;
    chown -R "$username:$username" "$home_dir/.local"
    
    # Set standard directory permissions
    for dir in Desktop Documents Downloads Music Pictures Videos Templates Public; do
        if [[ -d "$home_dir/$dir" ]]; then
            chmod 755 "$home_dir/$dir"
            chown "$username:$username" "$home_dir/$dir"
        fi
    done
    
    log_message "INFO" "File permissions configured for user: $username"
}

# Function to configure device permissions
configure_device_permissions() {
    log_message "INFO" "Configuring device permissions"
    
    # Create udev rules for common devices
    local udev_rules_dir="/etc/udev/rules.d"
    mkdir -p "$udev_rules_dir"
    
    # USB device permissions
    cat > "$udev_rules_dir/99-voidance-usb.rules" << 'EOF'
# USB device permissions for Voidance users
SUBSYSTEM=="usb", MODE="0664", GROUP="plugdev"
SUBSYSTEM=="usb_device", MODE="0664", GROUP="plugdev"
EOF
    
    # Input device permissions
    cat > "$udev_rules_dir/99-voidance-input.rules" << 'EOF'
# Input device permissions for Voidance users
KERNEL=="event[0-9]*", SUBSYSTEM=="input", MODE="0660", GROUP="input"
KERNEL=="mouse[0-9]*", SUBSYSTEM=="input", MODE="0660", GROUP="input"
KERNEL=="ts[0-9]*", SUBSYSTEM=="input", MODE="0660", GROUP="input"
EOF
    
    # Audio device permissions
    cat > "$udev_rules_dir/99-voidance-audio.rules" << 'EOF'
# Audio device permissions for Voidance users
SUBSYSTEM=="sound", MODE="0660", GROUP="audio"
SUBSYSTEM=="snd", MODE="0660", GROUP="audio"
EOF
    
    # Video device permissions
    cat > "$udev_rules_dir/99-voidance-video.rules" << 'EOF'
# Video device permissions for Voidance users
SUBSYSTEM=="video4linux", MODE="0660", GROUP="video"
SUBSYSTEM=="drm", MODE="0660", GROUP="video"
EOF
    
    # Reload udev rules
    udevadm control --reload-rules
    udevadm trigger
    
    log_message "INFO" "Device permissions configured"
}

# Function to configure security policies
configure_security_policies() {
    log_message "INFO" "Configuring security policies"
    
    # Configure login.defs
    local login_defs="/etc/login.defs"
    if [[ -f "$login_defs" ]]; then
        # Backup original
        cp "$login_defs" "$login_defs.backup"
        
        # Update security settings
        sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' "$login_defs"
        sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' "$login_defs"
        sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' "$login_defs"
        sed -i 's/^LOGIN_RETRIES.*/LOGIN_RETRIES 3/' "$login_defs"
        sed -i 's/^LOGIN_TIMEOUT.*/LOGIN_TIMEOUT 60/' "$login_defs"
        
        log_message "INFO" "Login security policies updated"
    fi
    
    # Configure common-password (PAM)
    local pam_password="/etc/pam.d/system-password"
    if [[ -f "$pam_password" ]]; then
        # Add password strength requirements
        if ! grep -q "pam_pwquality.so" "$pam_password"; then
            sed -i '/^password.*pam_unix.so/i password    required     pam_pwquality.so retry=3 minlen=8 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1' "$pam_password"
            log_message "INFO" "Password strength requirements added"
        fi
    fi
    
    # Configure common-session (PAM)
    local pam_session="/etc/pam.d/system-session"
    if [[ -f "$pam_session" ]]; then
        # Add session limits
        if ! grep -q "pam_limits.so" "$pam_session"; then
            echo "session    required     pam_limits.so" >> "$pam_session"
            log_message "INFO" "Session limits configured"
        fi
    fi
    
    # Configure security limits
    local limits_conf="/etc/security/limits.conf"
    if [[ -f "$limits_conf" ]]; then
        # Add user limits
        cat >> "$limits_conf" << 'EOF'

# Voidance user limits
@users           soft    nproc           4096
@users           hard    nproc           8192
@users           soft    nofile          4096
@users           hard    nofile          8192
@users           soft    fsize           unlimited
@users           hard    fsize           unlimited
EOF
        log_message "INFO" "User limits configured"
    fi
    
    log_message "INFO" "Security policies configuration completed"
}

# Function to validate user permissions
validate_user_permissions() {
    local username="$1"
    
    log_message "INFO" "Validating permissions for user: $username"
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        log_message "ERROR" "User '$username' does not exist"
        return 1
    fi
    
    echo "Permission Validation Report for: $username"
    echo "=========================================="
    
    # Check user groups
    local user_groups=$(id -nG "$username")
    echo "User groups: $user_groups"
    
    # Check sudo access
    if sudo -n -l -U "$username" 2>/dev/null | grep -q "NOPASSWD"; then
        echo "Sudo access: Full (no password)"
    elif sudo -n -l -U "$username" 2>/dev/null | grep -q "ALL"; then
        echo "Sudo access: Standard (password required)"
    else
        echo "Sudo access: None or limited"
    fi
    
    # Check home directory permissions
    local home_dir="/home/$username"
    if [[ -d "$home_dir" ]]; then
        local home_perms=$(stat -c "%a" "$home_dir")
        local home_owner=$(stat -c "%U:%G" "$home_dir")
        echo "Home directory: $home_perms ($home_owner)"
        
        # Check for permission issues
        if [[ "$home_owner" != "$username:$username" ]]; then
            echo "WARNING: Home directory ownership issue"
        fi
        
        if [[ "$home_perms" != "755" ]] && [[ "$home_perms" != "750" ]]; then
            echo "WARNING: Unusual home directory permissions"
        fi
    else
        echo "ERROR: Home directory does not exist"
    fi
    
    # Check config directory permissions
    if [[ -d "$home_dir/.config" ]]; then
        local config_perms=$(stat -c "%a" "$home_dir/.config")
        echo "Config directory: $config_perms"
        
        if [[ "$config_perms" != "700" ]]; then
            echo "WARNING: Config directory should be 700"
        fi
    fi
    
    # Check group membership for common access
    local required_groups=("audio" "video" "input")
    for group in "${required_groups[@]}"; do
        if groups "$username" | grep -q "$group"; then
            echo "✓ $group access: Available"
        else
            echo "✗ $group access: Missing"
        fi
    done
    
    echo ""
}

# Function to list all groups and their members
list_groups_and_members() {
    log_message "INFO" "Listing groups and their members"
    
    echo "System Groups and Members"
    echo "========================="
    printf "%-20s %-30s %-50s\n" "Group" "Members" "Description"
    printf "%-20s %-30s %-50s\n" "--------------------" "------------------------------" "--------------------------------------------------"
    
    # Get all groups
    while IFS=: read -r group_name _ _ _; do
        local group_members=""
        local group_desc=""
        
        # Get group description
        if [[ -n "${SYSTEM_GROUPS[$group_name]:-}" ]]; then
            group_desc="${SYSTEM_GROUPS[$group_name]}"
        elif [[ -n "${SPECIAL_GROUPS[$group_name]:-}" ]]; then
            group_desc="${SPECIAL_GROUPS[$group_name]}"
        fi
        
        # Get group members
        local members=$(getent group "$group_name" | cut -d: -f4)
        if [[ -n "$members" ]]; then
            group_members="$members"
        fi
        
        printf "%-20s %-30s %-50s\n" "$group_name" "$group_members" "$group_desc"
    done < <(getent group | cut -d: -f1 | sort)
    
    echo ""
}

# Function to fix common permission issues
fix_permission_issues() {
    local username="$1"
    
    log_message "INFO" "Fixing permission issues for user: $username"
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        log_message "ERROR" "User '$username' does not exist"
        return 1
    fi
    
    # Fix home directory ownership
    local home_dir="/home/$username"
    if [[ -d "$home_dir" ]]; then
        chown -R "$username:$username" "$home_dir"
        chmod 755 "$home_dir"
        log_message "INFO" "Fixed home directory ownership and permissions"
    fi
    
    # Fix config directory permissions
    if [[ -d "$home_dir/.config" ]]; then
        find "$home_dir/.config" -type d -exec chmod 700 {} \;
        find "$home_dir/.config" -type f -exec chmod 600 {} \;
        chown -R "$username:$username" "$home_dir/.config"
        log_message "INFO" "Fixed config directory permissions"
    fi
    
    # Ensure user is in required groups
    local required_groups=("audio" "video" "input" "users")
    for group in "${required_groups[@]}"; do
        if ! groups "$username" | grep -q "$group"; then
            usermod -aG "$group" "$username"
            log_message "INFO" "Added user to group: $group"
        fi
    done
    
    log_message "INFO" "Permission issues fixed for user: $username"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$PERMISSIONS_LOG"
}

# Interactive permissions management interface
permissions_management_menu() {
    while true; do
        clear
        echo "Voidance Permissions and Groups Management"
        echo "========================================="
        echo ""
        echo "1. Create System Groups"
        echo "2. Create Special Groups"
        echo "3. Configure User Groups"
        echo "4. Configure Sudo Access"
        echo "5. Configure Device Permissions"
        echo "6. Configure Security Policies"
        echo "7. Validate User Permissions"
        echo "8. List Groups and Members"
        echo "9. Fix Permission Issues"
        echo "10. Exit"
        echo ""
        read -p "Select option: " choice
        
        case $choice in
            1)
                create_system_groups
                read -p "Press Enter to continue..."
                ;;
            2)
                create_special_groups
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Username: " username
                echo "User types: standard, developer, admin, minimal"
                read -p "User type (default: standard): " user_type
                configure_default_user_groups "$username" "${user_type:-standard}"
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Username: " username
                echo "Sudo levels: full, standard, limited, none"
                read -p "Sudo level (default: standard): " sudo_level
                configure_sudo_access "$username" "${sudo_level:-standard}"
                read -p "Press Enter to continue..."
                ;;
            5)
                configure_device_permissions
                read -p "Press Enter to continue..."
                ;;
            6)
                configure_security_policies
                read -p "Press Enter to continue..."
                ;;
            7)
                read -p "Username: " username
                validate_user_permissions "$username"
                read -p "Press Enter to continue..."
                ;;
            8)
                list_groups_and_members
                read -p "Press Enter to continue..."
                ;;
            9)
                read -p "Username: " username
                fix_permission_issues "$username"
                read -p "Press Enter to continue..."
                ;;
            10)
                break
                ;;
            *)
                echo "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "${1:-}" == "--menu" ]]; then
        permissions_management_menu
    elif [[ $# -ge 1 ]]; then
        configure_default_user_groups "$1" "${2:-standard}"
    else
        echo "Usage: $0 <username> [user_type]"
        echo "       $0 --menu"
        echo ""
        echo "User types: standard, developer, admin, minimal"
        echo "Sudo levels: full, standard, limited, none"
        exit 1
    fi
fi