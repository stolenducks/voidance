#!/bin/bash
# Voidance User Account Management System
# Comprehensive user account creation and management

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/iso/config.sh"

# User management configuration
USER_MGMT_LOG="/var/log/voidance-user-mgmt.log"
MIN_PASSWORD_LENGTH=8
DEFAULT_GROUPS="wheel,audio,video,input,storage,network,lp,scanner,users"

# Function to validate username
validate_username() {
    local username="$1"
    
    # Check if username is empty
    if [[ -z "$username" ]]; then
        log_message "ERROR" "Username cannot be empty"
        return 1
    fi
    
    # Check username length
    if [[ ${#username} -lt 3 ]] || [[ ${#username} -gt 32 ]]; then
        log_message "ERROR" "Username must be between 3 and 32 characters"
        return 1
    fi
    
    # Check username format
    if [[ ! "$username" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        log_message "ERROR" "Username must start with lowercase letter and contain only lowercase letters, numbers, hyphens, and underscores"
        return 1
    fi
    
    # Check for reserved usernames
    local reserved_names=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "systemd-network" "systemd-resolve" "syslog" "messagebus" "uuidd" "dnsmasq" "usbmux" "rtkit" "pulse" "speech-dispatcher" "avahi" "saned" "colord" "hplip" "geoclue" "gnome-initial-setup" "gdm")
    
    for reserved in "${reserved_names[@]}"; do
        if [[ "$username" == "$reserved" ]]; then
            log_message "ERROR" "Username '$username' is reserved"
            return 1
        fi
    done
    
    log_message "INFO" "Username '$username' is valid"
    return 0
}

# Function to validate password
validate_password() {
    local password="$1"
    local username="$2"
    
    # Check password length
    if [[ ${#password} -lt $MIN_PASSWORD_LENGTH ]]; then
        log_message "ERROR" "Password must be at least $MIN_PASSWORD_LENGTH characters long"
        return 1
    fi
    
    # Check if password contains username
    if [[ "$password" == *"$username"* ]]; then
        log_message "ERROR" "Password cannot contain username"
        return 1
    fi
    
    # Check password complexity
    local has_upper=false
    local has_lower=false
    local has_digit=false
    local has_special=false
    
    for ((i=0; i<${#password}; i++)); do
        local char="${password:$i:1}"
        case "$char" in
            [A-Z]) has_upper=true ;;
            [a-z]) has_lower=true ;;
            [0-9]) has_digit=true ;;
            [!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]) has_special=true ;;
        esac
    done
    
    local complexity_score=0
    [[ $has_upper == true ]] && ((complexity_score++))
    [[ $has_lower == true ]] && ((complexity_score++))
    [[ $has_digit == true ]] && ((complexity_score++))
    [[ $has_special == true ]] && ((complexity_score++))
    
    if [[ $complexity_score -lt 3 ]]; then
        log_message "WARNING" "Password is weak (score: $complexity_score/4)"
        log_message "INFO" "Consider using uppercase, lowercase, numbers, and special characters"
    fi
    
    log_message "INFO" "Password validation completed"
    return 0
}

# Function to create user account
create_user_account() {
    local username="$1"
    local password="$2"
    local full_name="${3:-}"
    local user_groups="${4:-$DEFAULT_GROUPS}"
    
    log_message "INFO" "Creating user account: $username"
    
    # Validate inputs
    validate_username "$username" || return 1
    validate_password "$password" "$username" || return 1
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        log_message "ERROR" "User '$username' already exists"
        return 1
    fi
    
    # Create user account
    useradd -m -s /bin/bash -G "$user_groups" "$username"
    
    # Set password
    echo "$username:$password" | chpasswd
    
    # Set full name (GECOS field)
    if [[ -n "$full_name" ]]; then
        chfn -f "$full_name" "$username"
    fi
    
    # Create user directories
    setup_user_directories "$username"
    
    # Configure user environment
    configure_user_environment "$username"
    
    log_message "INFO" "User account '$username' created successfully"
}

# Function to setup user directories
setup_user_directories() {
    local username="$1"
    local home_dir="/home/$username"
    
    log_message "INFO" "Setting up directories for user: $username"
    
    # Create standard directories
    mkdir -p "$home_dir"/{Desktop,Documents,Downloads,Music,Pictures,Videos,Templates,Public,.local/{share,bin,state},.config}
    
    # Create Voidance-specific directories
    mkdir -p "$home_dir"/.config/{niri,sway,waybar,wofi,mako,ghostty,thunar}
    mkdir -p "$home_dir"/.local/{share/applications,share/icons,state/wayland}
    
    # Set ownership and permissions
    chown -R "$username:$username" "$home_dir"
    chmod 755 "$home_dir"
    chmod 700 "$home_dir/.config"
    chmod 755 "$home_dir/Desktop" "$home_dir/Documents" "$home_dir/Downloads"
    chmod 755 "$home_dir/Music" "$home_dir/Pictures" "$home_dir/Videos"
    
    log_message "INFO" "User directories created for: $username"
}

# Function to configure user environment
configure_user_environment() {
    local username="$1"
    local home_dir="/home/$username"
    
    log_message "INFO" "Configuring environment for user: $username"
    
    # Create .bashrc
    cat > "$home_dir/.bashrc" << 'EOF'
# Voidance Linux .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Basic settings
export EDITOR=nano
export BROWSER=firefox
export TERMINAL=foot

# Wayland environment variables
export XDG_CURRENT_DESKTOP=Voidance
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export GTK_THEME=Adwaita:dark

# Path additions
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -la'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Welcome message
if [[ -f /etc/motd ]]; then
    cat /etc/motd
fi
EOF
    
    # Create .profile
    cat > "$home_dir/.profile" << 'EOF'
# Voidance Linux .profile

# Set up Wayland session
if [[ -z "$DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=Voidance
    exec niri
fi
EOF
    
    # Create user-specific configuration files
    create_user_configs "$username"
    
    # Set ownership
    chown -R "$username:$username" "$home_dir"/.bashrc "$home_dir"/.profile "$home_dir"/.config
    
    log_message "INFO" "Environment configured for user: $username"
}

# Function to create user-specific configurations
create_user_configs() {
    local username="$1"
    local home_dir="/home/$username"
    
    # Create user-specific Niri config
    cat > "$home_dir/.config/niri/config.kdl" << 'EOF'
// User-specific Niri configuration
// This file extends the system configuration

input {
    keyboard {
        repeat-delay 200
        repeat-rate 25
    }
    
    touchpad {
        tap
        natural-scroll
    }
}

// User-defined workspaces
workspace 1 {
    // Primary workspace
}

workspace 2 {
    // Secondary workspace
}

// User-specific rules
window-rule {
    match app-id="firefox"
    open-on-workspace 2
}
EOF
    
    # Create user-specific Waybar config
    cat > "$home_dir/.config/waybar/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 24,
    "modules-left": ["niri/workspaces", "niri/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],
    
    "niri/workspaces": {
        "format": "{name}",
        "on-click": "activate"
    },
    
    "clock": {
        "format": "%Y-%m-%d %H:%M:%S",
        "tooltip-format": "{:%Y-%m-%d | %H:%M:%S}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "🔇",
        "format-icons": {
            "headphone": "🎧",
            "default": ["🔈", "🔉", "🔊"]
        }
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) 📶",
        "format-ethernet": "{ifname} 🌐",
        "format-disconnected": "Disconnected ⚠"
    },
    
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["🔋", "🔋", "🔋", "🔋", "🔋"]
    }
}
EOF
    
    # Create user-specific Mako config
    cat > "$home_dir/.config/mako/config" << 'EOF'
# User-specific Mako configuration

# General appearance
background-color=#1a1a1a
text-color=#ffffff
border-color=#00ff00
border-radius=5

# Default notification settings
default-timeout=5000
layer=overlay
anchor=top-right

# Progress bar
progress-color=over #00ff00

# Button styling
button-background-color=#333333
button-text-color=#ffffff
button-border-color=#666666

# Grouping
group-by=app-name
EOF
    
    log_message "INFO" "User-specific configurations created for: $username"
}

# Function to delete user account
delete_user_account() {
    local username="$1"
    local backup_home="${2:-false}"
    
    log_message "INFO" "Deleting user account: $username"
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        log_message "ERROR" "User '$username' does not exist"
        return 1
    fi
    
    # Don't allow deletion of system users
    if [[ "$username" == "root" ]] || [[ $(id -u "$username") -lt 1000 ]]; then
        log_message "ERROR" "Cannot delete system user '$username'"
        return 1
    fi
    
    # Backup home directory if requested
    if [[ "$backup_home" == "true" ]]; then
        local backup_dir="/home/${username}.backup.$(date +%Y%m%d-%H%M%S)"
        cp -a "/home/$username" "$backup_dir"
        log_message "INFO" "Home directory backed up to: $backup_dir"
    fi
    
    # Kill user processes
    pkill -u "$username" || true
    
    # Delete user and home directory
    userdel -r "$username"
    
    log_message "INFO" "User account '$username' deleted successfully"
}

# Function to modify user account
modify_user_account() {
    local username="$1"
    local action="$2"
    local value="$3"
    
    log_message "INFO" "Modifying user account: $username ($action)"
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        log_message "ERROR" "User '$username' does not exist"
        return 1
    fi
    
    case "$action" in
        "password")
            echo "$username:$value" | chpasswd
            log_message "INFO" "Password changed for user: $username"
            ;;
        "groups")
            usermod -G "$value" "$username"
            log_message "INFO" "Groups changed for user: $username"
            ;;
        "shell")
            usermod -s "$value" "$username"
            log_message "INFO" "Shell changed for user: $username"
            ;;
        "full-name")
            chfn -f "$value" "$username"
            log_message "INFO" "Full name changed for user: $username"
            ;;
        *)
            log_message "ERROR" "Unknown modification action: $action"
            return 1
            ;;
    esac
}

# Function to list user accounts
list_user_accounts() {
    log_message "INFO" "Listing user accounts"
    
    echo "User Accounts on System:"
    echo "======================="
    printf "%-15s %-8s %-20s %-30s\n" "Username" "UID" "Groups" "Full Name"
    printf "%-15s %-8s %-20s %-30s\n" "---------------" "--------" "--------------------" "------------------------------"
    
    # Get all users with UID >= 1000 (regular users)
    while IFS=: read -r username _ uid _ _ home shell; do
        if [[ $uid -ge 1000 ]] && [[ "$username" != "nobody" ]]; then
            local groups=$(id -nG "$username" | tr ' ' ',')
            local full_name=$(getent passwd "$username" | cut -d: -f5 | cut -d, -f1)
            printf "%-15s %-8s %-20s %-30s\n" "$username" "$uid" "$groups" "$full_name"
        fi
    done < /etc/passwd
    
    echo ""
}

# Function to check user account security
check_user_security() {
    local username="$1"
    
    log_message "INFO" "Checking security for user: $username"
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        log_message "ERROR" "User '$username' does not exist"
        return 1
    fi
    
    echo "Security Report for User: $username"
    echo "=================================="
    
    # Check password age
    local password_age=$(chage -l "$username" | grep "Last password change" | cut -d: -f2 | xargs)
    echo "Last password change: $password_age"
    
    # Check password expiration
    local password_expires=$(chage -l "$username" | grep "Password expires" | cut -d: -f2 | xargs)
    echo "Password expires: $password_expires"
    
    # Check account expiration
    local account_expires=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | xargs)
    echo "Account expires: $account_expires"
    
    # Check groups
    local groups=$(id -nG "$username")
    echo "Groups: $groups"
    
    # Check for sudo access
    if groups "$username" | grep -q wheel; then
        echo "Sudo access: Yes"
    else
        echo "Sudo access: No"
    fi
    
    # Check home directory permissions
    local home_dir="/home/$username"
    if [[ -d "$home_dir" ]]; then
        local home_perms=$(stat -c "%a" "$home_dir")
        echo "Home directory permissions: $home_perms"
        
        if [[ "$home_perms" != "755" ]] && [[ "$home_perms" != "750" ]]; then
            echo "WARNING: Home directory has unusual permissions"
        fi
    else
        echo "WARNING: Home directory does not exist"
    fi
    
    echo ""
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$USER_MGMT_LOG"
}

# Interactive user management interface
user_management_menu() {
    while true; do
        clear
        echo "Voidance User Account Management"
        echo "==============================="
        echo ""
        echo "1. Create User Account"
        echo "2. Delete User Account"
        echo "3. Modify User Account"
        echo "4. List User Accounts"
        echo "5. Check User Security"
        echo "6. Exit"
        echo ""
        read -p "Select option: " choice
        
        case $choice in
            1)
                echo "Create User Account"
                read -p "Username: " username
                read -s -p "Password: " password
                echo
                read -s -p "Confirm Password: " password_confirm
                echo
                read -p "Full Name (optional): " full_name
                read -p "Groups (comma-separated, default: $DEFAULT_GROUPS): " user_groups
                
                if [[ "$password" != "$password_confirm" ]]; then
                    echo "ERROR: Passwords do not match"
                else
                    create_user_account "$username" "$password" "$full_name" "${user_groups:-$DEFAULT_GROUPS}"
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                echo "Delete User Account"
                list_user_accounts
                read -p "Username to delete: " username
                read -p "Backup home directory? (y/N): " backup
                delete_user_account "$username" "${backup,,}"
                read -p "Press Enter to continue..."
                ;;
            3)
                echo "Modify User Account"
                list_user_accounts
                read -p "Username: " username
                echo "Modification options:"
                echo "1. Change password"
                echo "2. Change groups"
                echo "3. Change shell"
                echo "4. Change full name"
                read -p "Select option: " mod_choice
                
                case $mod_choice in
                    1)
                        read -s -p "New password: " value
                        modify_user_account "$username" "password" "$value"
                        ;;
                    2)
                        read -p "New groups (comma-separated): " value
                        modify_user_account "$username" "groups" "$value"
                        ;;
                    3)
                        read -p "New shell: " value
                        modify_user_account "$username" "shell" "$value"
                        ;;
                    4)
                        read -p "New full name: " value
                        modify_user_account "$username" "full-name" "$value"
                        ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            4)
                list_user_accounts
                read -p "Press Enter to continue..."
                ;;
            5)
                echo "Check User Security"
                list_user_accounts
                read -p "Username: " username
                check_user_security "$username"
                read -p "Press Enter to continue..."
                ;;
            6)
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
        user_management_menu
    elif [[ $# -ge 3 ]]; then
        create_user_account "$1" "$2" "$3" "${4:-$DEFAULT_GROUPS}"
    else
        echo "Usage: $0 <username> <password> [full_name] [groups]"
        echo "       $0 --menu"
        exit 1
    fi
fi