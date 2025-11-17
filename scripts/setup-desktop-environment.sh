#!/bin/bash

# Desktop Environment Installation Script for Voidance Linux
# Installs and configures Niri, Waybar, wofi and supporting components

set -euo pipefail

# Source package configuration
SCRIPT_DIR="$(dirname "$0")"
PACKAGE_CONFIG="$SCRIPT_DIR/../packages/desktop-environment.sh"

if [ ! -f "$PACKAGE_CONFIG" ]; then
    echo "Error: Package configuration not found: $PACKAGE_CONFIG"
    exit 1
fi

# shellcheck source=../packages/desktop-environment.sh
source "$PACKAGE_CONFIG"

# Configuration paths
CONFIG_DIR="$(dirname "$0")/../config"
DESKTOP_CONFIG_DIR="$CONFIG_DIR/desktop"
NIRI_CONFIG_DIR="$DESKTOP_CONFIG_DIR/niri"
WAYBAR_CONFIG_DIR="$DESKTOP_CONFIG_DIR/waybar"
WOFI_CONFIG_DIR="$DESKTOP_CONFIG_DIR/wofi"

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This script must be run as root for system-wide installation"
        echo "For user-specific installation, run with --user flag"
        exit 1
    fi
}

# Function to check if user exists
check_user() {
    local username="$1"
    if id "$username" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to install desktop environment packages
install_packages() {
    echo "Installing desktop environment packages..."
    
    # Update package database
    echo "Updating package database..."
    xbps-install -S
    
    # Install desktop packages
    install_desktop_packages
    
    # Verify installation
    if verify_desktop_packages; then
        echo "✓ All desktop packages installed successfully"
    else
        echo "⚠ Some packages failed to install"
        return 1
    fi
}

# Function to create system-wide configuration directories
create_system_config_dirs() {
    echo "Creating system-wide configuration directories..."
    
    local directories=(
        "/etc/skel/.config/niri"
        "/etc/skel/.config/waybar"
        "/etc/skel/.config/wofi"
        "/etc/skel/.local/share/applications"
        "/etc/skel/.local/bin"
        "/usr/share/wayland-sessions"
        "/usr/share/backgrounds/voidance"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "✓ Created $dir"
        else
            echo "✓ Directory $dir already exists"
        fi
    done
}

# Function to install desktop environment configurations
install_configurations() {
    echo "Installing desktop environment configurations..."
    
    # Install Niri configuration
    if [ -d "$NIRI_CONFIG_DIR" ]; then
        cp -r "$NIRI_CONFIG_DIR"/* "/etc/skel/.config/niri/"
        echo "✓ Installed Niri configuration"
    else
        echo "⚠ Niri configuration directory not found: $NIRI_CONFIG_DIR"
    fi
    
    # Install Waybar configuration
    if [ -d "$WAYBAR_CONFIG_DIR" ]; then
        cp -r "$WAYBAR_CONFIG_DIR"/* "/etc/skel/.config/waybar/"
        echo "✓ Installed Waybar configuration"
    else
        echo "⚠ Waybar configuration directory not found: $WAYBAR_CONFIG_DIR"
    fi
    
    # Install wofi configuration
    if [ -d "$WOFI_CONFIG_DIR" ]; then
        cp -r "$WOFI_CONFIG_DIR"/* "/etc/skel/.config/wofi/"
        echo "✓ Installed wofi configuration"
    else
        echo "⚠ wofi configuration directory not found: $WOFI_CONFIG_DIR"
    fi
}

# Function to create Wayland session file
create_wayland_session() {
    echo "Creating Niri Wayland session..."
    
    local session_file="/usr/share/wayland-sessions/niri.desktop"
    
    cat > "$session_file" << 'EOF'
[Desktop Entry]
Name=Niri
Comment=Scrollable tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
Keywords=wayland;compositor;tiling;
EOF
    
    chmod 644 "$session_file"
    echo "✓ Created Niri Wayland session"
}

# Function to create niri-session wrapper script
create_niri_session_script() {
    echo "Creating niri-session wrapper script..."
    
    local session_script="/usr/bin/niri-session"
    
    cat > "$session_script" << 'EOF'
#!/bin/bash

# Niri session wrapper for Voidance Linux
# Sets up environment and starts Niri with proper integration

# Export environment variables
export XDG_CURRENT_DESKTOP=niri
export XDG_SESSION_DESKTOP=niri
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export GTK_USE_PORTAL=1
export NIXOS_OZONE_WL=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland

# Set cursor theme
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24

# Ensure XDG_RUNTIME_DIR is set
if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
    export XDG_RUNTIME_DIR="/tmp/xdg-runtime-$(id -u)"
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
fi

# Start background services
# Start Waybar if available
if command -v waybar >/dev/null 2>&1; then
    waybar &
fi

# Start Niri
exec niri "$@"
EOF
    
    chmod 755 "$session_script"
    echo "✓ Created niri-session wrapper script"
}

# Function to setup desktop environment for existing user
setup_user_desktop() {
    local username="$1"
    local user_home="/home/$username"
    
    echo "Setting up desktop environment for user: $username"
    
    if ! check_user "$username"; then
        echo "Error: User $username does not exist"
        return 1
    fi
    
    # Copy skeleton configurations to user home
    if [ -d "/etc/skel/.config" ]; then
        cp -r /etc/skel/.config "$user_home/"
        chown -R "$username:$username" "$user_home/.config"
        echo "✓ Copied configuration to $username"
    fi
    
    # Create user directories
    create_desktop_directories "$username"
    
    echo "✓ Desktop environment setup complete for $username"
}

# Function to verify desktop environment installation
verify_installation() {
    echo "Verifying desktop environment installation..."
    
    local verification_failed=0
    
    # Check packages
    if ! verify_desktop_packages; then
        verification_failed=1
    fi
    
    # Check session file
    if [ -f "/usr/share/wayland-sessions/niri.desktop" ]; then
        echo "✓ Niri session file exists"
    else
        echo "✗ Niri session file missing"
        verification_failed=1
    fi
    
    # Check session script
    if [ -f "/usr/bin/niri-session" ]; then
        echo "✓ Niri session script exists"
    else
        echo "✗ Niri session script missing"
        verification_failed=1
    fi
    
    # Check skeleton configs
    if [ -d "/etc/skel/.config/niri" ]; then
        echo "✓ Skeleton Niri configuration exists"
    else
        echo "✗ Skeleton Niri configuration missing"
        verification_failed=1
    fi
    
    if [ $verification_failed -eq 0 ]; then
        echo "✓ Desktop environment installation verified successfully"
        return 0
    else
        echo "✗ Desktop environment installation verification failed"
        return 1
    fi
}

# Function to show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] COMMAND

Commands:
    install         Install desktop environment (system-wide)
    user <name>     Setup desktop environment for existing user
    verify          Verify installation
    help            Show this help message

Options:
    --user          Run in user mode (no root required)
    --dry-run       Show what would be done without executing

Examples:
    $0 install                    # Install system-wide
    $0 user alice                 # Setup for user alice
    $0 verify                     # Verify installation
    $0 --user install             # Install for current user only

EOF
}

# Main function
main() {
    local action="${1:-install}"
    local user_mode="${USER_MODE:-false}"
    local dry_run="${DRY_RUN:-false}"
    
    case "$action" in
        "install")
            if [ "$user_mode" = "false" ]; then
                check_root
            fi
            
            if [ "$dry_run" = "false" ]; then
                install_packages
                create_system_config_dirs
                install_configurations
                create_wayland_session
                create_niri_session_script
                verify_installation
                
                echo ""
                echo "Desktop environment installation completed successfully!"
                echo "Users can now select 'Niri' from the SDDM login screen"
            else
                echo "DRY RUN: Would install desktop environment packages and configurations"
            fi
            ;;
        "user")
            local username="${2:-}"
            if [ -z "$username" ]; then
                echo "Error: Username required for user setup"
                echo "Usage: $0 user <username>"
                exit 1
            fi
            
            if [ "$dry_run" = "false" ]; then
                setup_user_desktop "$username"
            else
                echo "DRY RUN: Would setup desktop environment for user: $username"
            fi
            ;;
        "verify")
            verify_installation
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            echo "Error: Unknown command '$action'"
            show_usage
            exit 1
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            export USER_MODE=true
            shift
            ;;
        --dry-run)
            export DRY_RUN=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Run main function with remaining arguments
main "$@"