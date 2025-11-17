#!/bin/bash

# SDDM Configuration Setup Script for Voidance Linux
# Configures SDDM display manager with Voidance theme and settings

set -euo pipefail

SDDM_CONFIG_DIR="/etc/sddm.conf.d"
SDDM_CONFIG_FILE="$SDDM_CONFIG_DIR/voidance.conf"
CONFIG_SOURCE="$(dirname "$0")/../config/sddm.conf.d/voidance.conf"

# Function to backup existing SDDM configuration
backup_sddm_config() {
    if [ -f "/etc/sddm.conf" ]; then
        local backup_file="/etc/sddm.conf.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Backing up existing SDDM configuration to $backup_file"
        cp "/etc/sddm.conf" "$backup_file"
    fi
    
    if [ -f "$SDDM_CONFIG_FILE" ]; then
        local backup_file="$SDDM_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Backing up existing Voidance SDDM config to $backup_file"
        cp "$SDDM_CONFIG_FILE" "$backup_file"
    fi
}

# Function to install SDDM configuration
install_sddm_config() {
    echo "Installing SDDM configuration for Voidance Linux..."
    
    # Create configuration directory
    if [ ! -d "$SDDM_CONFIG_DIR" ]; then
        echo "Creating SDDM configuration directory: $SDDM_CONFIG_DIR"
        mkdir -p "$SDDM_CONFIG_DIR"
    fi
    
    # Install configuration
    if [ -f "$CONFIG_SOURCE" ]; then
        cp "$CONFIG_SOURCE" "$SDDM_CONFIG_FILE"
        echo "✓ Installed SDDM configuration"
    else
        echo "✗ SDDM configuration source not found: $CONFIG_SOURCE"
        return 1
    fi
    
    # Set proper permissions
    chmod 644 "$SDDM_CONFIG_FILE"
    echo "✓ Set SDDM configuration permissions"
}

# Function to verify SDDM configuration
verify_sddm_config() {
    echo "Verifying SDDM configuration..."
    
    if [ -f "$SDDM_CONFIG_FILE" ]; then
        # Check key configuration options
        if grep -q "DisplayServer=wayland" "$SDDM_CONFIG_FILE"; then
            echo "✓ Wayland display server configured"
        else
            echo "⚠ Wayland display server not configured"
        fi
        
        if grep -q "Current=breeze" "$SDDM_CONFIG_FILE"; then
            echo "✓ Breeze theme configured"
        else
            echo "⚠ Breeze theme not configured"
        fi
        
        if grep -q "MaximumUid=60000" "$SDDM_CONFIG_FILE"; then
            echo "✓ User UID range configured"
        else
            echo "⚠ User UID range not configured"
        fi
    else
        echo "✗ SDDM configuration file not found"
        return 1
    fi
}

# Function to create SDDM autologin configuration (optional)
create_autologin_config() {
    local username="${1:-}"
    
    if [ -n "$username" ]; then
        echo "Creating autologin configuration for user: $username"
        
        cat > "$SDDM_CONFIG_DIR/autologin.conf" << EOF
[Autologin]
User=$username
Session=wayland-niri
EOF
        
        echo "✓ Created autologin configuration"
        echo "⚠ Autologin enabled - remove $SDDM_CONFIG_DIR/autologin.conf to disable"
    else
        echo "No username provided for autologin"
    fi
}

# Function to setup SDDM PAM integration
setup_sddm_pam() {
    echo "Setting up SDDM PAM integration..."
    
    # Ensure PAM configuration exists
    if [ ! -f "/etc/pam.d/sddm" ]; then
        echo "⚠ SDDM PAM configuration not found"
        echo "Run setup-pam.sh to create PAM configurations"
    else
        echo "✓ SDDM PAM configuration exists"
    fi
}

# Function to create Wayland session directory
create_wayland_sessions() {
    echo "Creating Wayland session directory structure..."
    
    local session_dir="/usr/share/wayland-sessions"
    
    if [ ! -d "$session_dir" ]; then
        echo "Creating Wayland sessions directory: $session_dir"
        mkdir -p "$session_dir"
    fi
    
    echo "✓ Wayland session directory ready"
}

# Main installation function
main() {
    local action="${1:-install}"
    local autologin_user="${2:-}"
    
    echo "Configuring SDDM for Voidance Linux..."
    
    case "$action" in
        "install")
            backup_sddm_config
            install_sddm_config
            setup_sddm_pam
            create_wayland_sessions
            verify_sddm_config
            
            echo ""
            echo "SDDM configuration completed successfully"
            echo "Note: Restart SDDM service for changes to take effect"
            ;;
        "autologin")
            if [ -n "$autologin_user" ]; then
                create_autologin_config "$autologin_user"
            else
                echo "Usage: $0 autologin <username>"
                exit 1
            fi
            ;;
        "verify")
            verify_sddm_config
            ;;
        *)
            echo "Usage: $0 {install|autologin <username>|verify}"
            exit 1
            ;;
    esac
}

# Script usage
case "${1:-install}" in
    "install"|"verify")
        main "$@"
        ;;
    "autologin")
        if [ -n "${2:-}" ]; then
            main "$@"
        else
            echo "Error: Username required for autologin"
            echo "Usage: $0 autologin <username>"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {install|autologin <username>|verify}"
        exit 1
        ;;
esac