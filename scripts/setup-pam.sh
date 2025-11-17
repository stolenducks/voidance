#!/bin/bash

# PAM Configuration Setup Script for Voidance Linux
# Configures PAM for elogind session management and SDDM display manager

set -euo pipefail

PAM_DIR="/etc/pam.d"
CONFIG_DIR="$(dirname "$0")/../config/pam.d"

# Function to backup existing PAM configuration
backup_pam_config() {
    local config_file="$1"
    local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$PAM_DIR/$config_file" ]; then
        echo "Backing up existing $config_file to $backup_file"
        cp "$PAM_DIR/$config_file" "$backup_file"
    fi
}

# Function to install PAM configuration
install_pam_config() {
    local config_file="$1"
    
    echo "Installing PAM configuration: $config_file"
    
    # Backup existing configuration
    backup_pam_config "$config_file"
    
    # Install new configuration
    if [ -f "$CONFIG_DIR/$config_file" ]; then
        cp "$CONFIG_DIR/$config_file" "$PAM_DIR/$config_file"
        echo "✓ Installed $config_file"
    else
        echo "✗ Configuration file not found: $CONFIG_DIR/$config_file"
        return 1
    fi
}

# Function to verify PAM configuration
verify_pam_config() {
    local config_file="$1"
    
    echo "Verifying PAM configuration: $config_file"
    
    if [ -f "$PAM_DIR/$config_file" ]; then
        # Basic syntax check
        if grep -q "pam_elogind.so" "$PAM_DIR/$config_file"; then
            echo "✓ $config_file includes elogind support"
        else
            echo "⚠ $config_file missing elogind support"
        fi
        
        if grep -q "pam_unix.so" "$PAM_DIR/$config_file"; then
            echo "✓ $config_file includes unix authentication"
        else
            echo "⚠ $config_file missing unix authentication"
        fi
    else
        echo "✗ $config_file not found"
        return 1
    fi
}

# Main installation function
main() {
    echo "Configuring PAM for Voidance Linux system services..."
    
    # Create PAM directory if it doesn't exist
    if [ ! -d "$PAM_DIR" ]; then
        echo "Creating PAM directory: $PAM_DIR"
        mkdir -p "$PAM_DIR"
    fi
    
    # Install PAM configurations
    install_pam_config "system-session"
    install_pam_config "sddm"
    
    # Verify installations
    echo ""
    echo "Verifying PAM configurations:"
    verify_pam_config "system-session"
    verify_pam_config "sddm"
    
    echo ""
    echo "PAM configuration completed successfully"
    echo "Note: You may need to restart services for changes to take effect"
}

# Script usage
case "${1:-install}" in
    "install")
        main
        ;;
    "verify")
        verify_pam_config "system-session"
        verify_pam_config "sddm"
        ;;
    "backup")
        backup_pam_config "system-session"
        backup_pam_config "sddm"
        ;;
    *)
        echo "Usage: $0 {install|verify|backup}"
        exit 1
        ;;
esac