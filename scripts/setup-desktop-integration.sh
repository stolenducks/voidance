#!/bin/bash

# Desktop Environment Integration Script for Voidance Linux
# Sets up session files, startup scripts, and environment variables

set -euo pipefail

# Configuration paths
SCRIPT_DIR="$(dirname "$0")"
CONFIG_DIR="$(dirname "$0")/../config"
DESKTOP_CONFIG_DIR="$CONFIG_DIR/desktop"
SYSTEM_CONFIG_DIR="/etc/xdg"
USER_CONFIG_BASE="$HOME/.config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root for system-wide installation
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This operation requires root privileges for system-wide installation"
        log_info "Use --user flag for user-specific installation"
        exit 1
    fi
}

# Function to create system-wide configuration directories
create_system_directories() {
    log_info "Creating system-wide configuration directories..."
    
    local directories=(
        "/etc/xdg/niri"
        "/etc/xdg/waybar"
        "/etc/xdg/wofi"
        "/etc/xdg/voidance"
        "/usr/share/wayland-sessions"
        "/usr/share/backgrounds/voidance"
        "/usr/share/icons/voidance"
        "/usr/share/themes/voidance"
        "/etc/environment.d"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "Created $dir"
        else
            log_info "Directory $dir already exists"
        fi
    done
}

# Function to create user configuration directories
create_user_directories() {
    local username="${1:-$USER}"
    local user_home="/home/$username"
    
    log_info "Creating user configuration directories for $username..."
    
    local directories=(
        "$user_home/.config/niri"
        "$user_home/.config/waybar"
        "$user_home/.config/wofi"
        "$user_home/.config/voidance"
        "$user_home/.local/share/applications"
        "$user_home/.local/bin"
        "$user_home/.local/share/backgrounds"
        "$user_home/.local/share/icons"
        "$user_home/.local/share/themes"
        "$user_home/Desktop"
        "$user_home/Documents"
        "$user_home/Downloads"
        "$user_home/Music"
        "$user_home/Pictures"
        "$user_home/Videos"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            chown "$username:$username" "$dir"
            log_success "Created $dir"
        else
            log_info "Directory $dir already exists"
        fi
    done
}

# Function to install system-wide configuration files
install_system_configs() {
    log_info "Installing system-wide configuration files..."
    
    # Install Niri configuration
    if [ -f "$DESKTOP_CONFIG_DIR/niri/config.kdl" ]; then
        cp "$DESKTOP_CONFIG_DIR/niri/config.kdl" "/etc/xdg/niri/config.kdl"
        log_success "Installed Niri system configuration"
    else
        log_warning "Niri configuration not found at $DESKTOP_CONFIG_DIR/niri/config.kdl"
    fi
    
    # Install Waybar configuration
    if [ -f "$DESKTOP_CONFIG_DIR/waybar/config" ]; then
        cp "$DESKTOP_CONFIG_DIR/waybar/config" "/etc/xdg/waybar/config"
        log_success "Installed Waybar system configuration"
    else
        log_warning "Waybar configuration not found at $DESKTOP_CONFIG_DIR/waybar/config"
    fi
    
    if [ -f "$DESKTOP_CONFIG_DIR/waybar/style.css" ]; then
        cp "$DESKTOP_CONFIG_DIR/waybar/style.css" "/etc/xdg/waybar/style.css"
        log_success "Installed Waybar system style"
    else
        log_warning "Waybar style not found at $DESKTOP_CONFIG_DIR/waybar/style.css"
    fi
    
    # Install wofi configuration
    if [ -f "$DESKTOP_CONFIG_DIR/wofi/config" ]; then
        cp "$DESKTOP_CONFIG_DIR/wofi/config" "/etc/xdg/wofi/config"
        log_success "Installed wofi system configuration"
    else
        log_warning "wofi configuration not found at $DESKTOP_CONFIG_DIR/wofi/config"
    fi
    
    if [ -f "$DESKTOP_CONFIG_DIR/wofi/style.css" ]; then
        cp "$DESKTOP_CONFIG_DIR/wofi/style.css" "/etc/xdg/wofi/style.css"
        log_success "Installed wofi system style"
    else
        log_warning "wofi style not found at $DESKTOP_CONFIG_DIR/wofi/style.css"
    fi
    
    # Install desktop environment configuration
    if [ -f "$DESKTOP_CONFIG_DIR/desktop-environment.json" ]; then
        cp "$DESKTOP_CONFIG_DIR/desktop-environment.json" "/etc/xdg/voidance/desktop-environment.json"
        log_success "Installed desktop environment configuration"
    else
        log_warning "Desktop environment configuration not found"
    fi
}

# Function to install user configuration files
install_user_configs() {
    local username="${1:-$USER}"
    local user_home="/home/$username"
    
    log_info "Installing user configuration files for $username..."
    
    # Install Niri configuration
    if [ ! -f "$user_home/.config/niri/config.kdl" ]; then
        if [ -f "$DESKTOP_CONFIG_DIR/niri/config.kdl" ]; then
            cp "$DESKTOP_CONFIG_DIR/niri/config.kdl" "$user_home/.config/niri/config.kdl"
            chown "$username:$username" "$user_home/.config/niri/config.kdl"
            log_success "Installed Niri user configuration"
        else
            log_warning "Niri configuration not found"
        fi
    else
        log_info "Niri user configuration already exists"
    fi
    
    # Install Waybar configuration
    if [ ! -f "$user_home/.config/waybar/config" ]; then
        if [ -f "$DESKTOP_CONFIG_DIR/waybar/config" ]; then
            cp "$DESKTOP_CONFIG_DIR/waybar/config" "$user_home/.config/waybar/config"
            chown "$username:$username" "$user_home/.config/waybar/config"
            log_success "Installed Waybar user configuration"
        else
            log_warning "Waybar configuration not found"
        fi
    else
        log_info "Waybar user configuration already exists"
    fi
    
    if [ ! -f "$user_home/.config/waybar/style.css" ]; then
        if [ -f "$DESKTOP_CONFIG_DIR/waybar/style.css" ]; then
            cp "$DESKTOP_CONFIG_DIR/waybar/style.css" "$user_home/.config/waybar/style.css"
            chown "$username:$username" "$user_home/.config/waybar/style.css"
            log_success "Installed Waybar user style"
        else
            log_warning "Waybar style not found"
        fi
    else
        log_info "Waybar user style already exists"
    fi
    
    # Install wofi configuration
    if [ ! -f "$user_home/.config/wofi/config" ]; then
        if [ -f "$DESKTOP_CONFIG_DIR/wofi/config" ]; then
            cp "$DESKTOP_CONFIG_DIR/wofi/config" "$user_home/.config/wofi/config"
            chown "$username:$username" "$user_home/.config/wofi/config"
            log_success "Installed wofi user configuration"
        else
            log_warning "wofi configuration not found"
        fi
    else
        log_info "wofi user configuration already exists"
    fi
    
    if [ ! -f "$user_home/.config/wofi/style.css" ]; then
        if [ -f "$DESKTOP_CONFIG_DIR/wofi/style.css" ]; then
            cp "$DESKTOP_CONFIG_DIR/wofi/style.css" "$user_home/.config/wofi/style.css"
            chown "$username:$username" "$user_home/.config/wofi/style.css"
            log_success "Installed wofi user style"
        else
            log_warning "wofi style not found"
        fi
    else
        log_info "wofi user style already exists"
    fi
    
    # Install desktop environment configuration
    if [ ! -f "$user_home/.config/voidance/desktop-environment.json" ]; then
        if [ -f "$DESKTOP_CONFIG_DIR/desktop-environment.json" ]; then
            cp "$DESKTOP_CONFIG_DIR/desktop-environment.json" "$user_home/.config/voidance/desktop-environment.json"
            chown "$username:$username" "$user_home/.config/voidance/desktop-environment.json"
            log_success "Installed desktop environment user configuration"
        else
            log_warning "Desktop environment configuration not found"
        fi
    else
        log_info "Desktop environment user configuration already exists"
    fi
}

# Function to create Wayland session files
create_wayland_sessions() {
    log_info "Creating Wayland session files..."
    
    local session_file="/usr/share/wayland-sessions/niri.desktop"
    
    cat > "$session_file" << 'EOF'
[Desktop Entry]
Name=Niri
Comment=Scrollable tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
Keywords=wayland;compositor;tiling;
X-DesktopNames=niri
X-Purism-FormFactor=Workstation;Mobile;
X-GNOME-Gettext-Domain=niri
X-GNOME-Autostart-Phase=WindowManager
X-KDE-Wayland-Interface=niri
EOF
    
    chmod 644 "$session_file"
    log_success "Created Niri Wayland session file"
}

# Function to create niri-session wrapper script
create_niri_session_script() {
    log_info "Creating niri-session wrapper script..."
    
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

# Load user-specific environment
if [ -f "$HOME/.config/voidance/environment" ]; then
    source "$HOME/.config/voidance/environment"
fi

# Start background services
# Start Waybar if available
if command -v waybar >/dev/null 2>&1; then
    waybar &
fi

# Start network applet if available
if command -v nm-applet >/dev/null 2>&1; then
    nm-applet --indicator &
fi

# Start Bluetooth applet if available
if command -v blueman-applet >/dev/null 2>&1; then
    blueman-applet &
fi

# Start user autostart applications
if [ -d "$HOME/.config/autostart" ]; then
    for desktop_file in "$HOME/.config/autostart"/*.desktop; do
        if [ -f "$desktop_file" ]; then
            grep -q "Hidden=true" "$desktop_file" || gtk-launch "$(basename "$desktop_file" .desktop)" &
        fi
    done
fi

# Start Niri
exec niri "$@"
EOF
    
    chmod 755 "$session_script"
    log_success "Created niri-session wrapper script"
}

# Function to create environment variables file
create_environment_file() {
    local username="${1:-$USER}"
    local user_home="/home/$username"
    
    log_info "Creating environment variables file for $username..."
    
    local env_file="$user_home/.config/voidance/environment"
    
    cat > "$env_file" << 'EOF'
# Voidance Desktop Environment Variables
# This file is sourced by niri-session

# Wayland-specific variables
export XDG_CURRENT_DESKTOP=niri
export XDG_SESSION_DESKTOP=niri
export XDG_SESSION_TYPE=wayland

# Application Wayland support
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export GTK_USE_PORTAL=1
export NIXOS_OZONE_WL=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland

# Cursor and theme
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24

# Font configuration
export FONTCONFIG_PATH=/etc/fonts
export GDK_SCALE=1
export GDK_DPI_SCALE=1

# Terminal
export TERMINAL=ghostty

# Editor
export EDITOR=nano
export VISUAL=nano

# Browser
export BROWSER=firefox

# File manager
export FILE_MANAGER=thunar

# Application launcher
export LAUNCHER=wofi

# Screenshot tool
export SCREENSHOT="grim -g \"\$(slurp)\" - | wl-copy"

# Screen recorder
export SCREENRECORDER="wf-recorder -f \$HOME/Videos/recording-\$(date +%Y%m%d-%H%M%S).mp4"

# Lock screen
export LOCK_SCREEN="swaylock -f -c 000000"

# Logout dialog
export LOGOUT_DIALOG="wlogout"

# Performance settings
export __GLX_GSYNC_ALLOWED=0
export __GL_VRR_ALLOWED=0
export vblank_mode=0

# Hardware acceleration
export LIBVA_DRIVER_NAME=iHD
export VDPAU_DRIVER=va_gl

# Audio
export PIPEWIRE_LATENCY="128/48000"

# Development
export GOPATH="$HOME/go"
export PATH="$PATH:$HOME/go/bin:$HOME/.local/bin"
EOF
    
    chown "$username:$username" "$env_file"
    chmod 644 "$env_file"
    log_success "Created environment variables file"
}

# Function to create desktop entry files
create_desktop_entries() {
    local username="${1:-$USER}"
    local user_home="/home/$username"
    
    log_info "Creating desktop entry files for $username..."
    
    local apps_dir="$user_home/.local/share/applications"
    
    # Create application launcher desktop entry
    cat > "$apps_dir/wofi.desktop" << 'EOF'
[Desktop Entry]
Name=Application Launcher
Comment=Launch applications
Exec=wofi --show drun
Icon=applications-other
Terminal=false
Type=Application
Categories=System;
Keywords=launcher;apps;run;
EOF
    
    # Create run dialog desktop entry
    cat > "$apps_dir/wofi-run.desktop" << 'EOF'
[Desktop Entry]
Name=Run Command
Comment=Run a command
Exec=wofi --show run
Icon=system-run
Terminal=false
Type=Application
Categories=System;
Keywords=run;command;execute;
EOF
    
    # Create logout dialog desktop entry
    cat > "$apps_dir/logout.desktop" << 'EOF'
[Desktop Entry]
Name=Logout
Comment=Logout from the current session
Exec=niri msg quit
Icon=system-log-out
Terminal=false
Type=Application
Categories=System;
Keywords=logout;exit;quit;
EOF
    
    # Create lock screen desktop entry
    cat > "$apps_dir/lock-screen.desktop" << 'EOF'
[Desktop Entry]
Name=Lock Screen
Comment=Lock the screen
Exec=swaylock -f -c 000000
Icon=system-lock-screen
Terminal=false
Type=Application
Categories=System;
Keywords=lock;security;
EOF
    
    # Create screenshot desktop entry
    cat > "$apps_dir/screenshot.desktop" << 'EOF'
[Desktop Entry]
Name=Screenshot
Comment=Take a screenshot
Exec=grim -g "$(slurp)" - | wl-copy
Icon=camera-photo
Terminal=false
Type=Application
Categories=Graphics;
Keywords=screenshot;capture;
EOF
    
    # Set proper ownership and permissions
    chown -R "$username:$username" "$apps_dir"
    chmod 644 "$apps_dir"/*.desktop
    
    log_success "Created desktop entry files"
}

# Function to create system environment file
create_system_environment() {
    log_info "Creating system environment file..."
    
    local env_file="/etc/environment.d/voidance-desktop.conf"
    
    cat > "$env_file" << 'EOF'
# Voidance Desktop Environment System Variables
# These variables are available system-wide

# Wayland defaults
export XDG_CURRENT_DESKTOP=niri
export XDG_SESSION_DESKTOP=niri
export XDG_SESSION_TYPE=wayland

# Application Wayland support
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export GTK_USE_PORTAL=1
export NIXOS_OZONE_WL=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland

# Cursor theme
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24

# Default applications
export TERMINAL=ghostty
export EDITOR=nano
export VISUAL=nano
export BROWSER=firefox
export FILE_MANAGER=thunar
export LAUNCHER=wofi
EOF
    
    log_success "Created system environment file"
}

# Function to create autostart directory and entries
create_autostart_entries() {
    local username="${1:-$USER}"
    local user_home="/home/$username"
    
    log_info "Creating autostart entries for $username..."
    
    local autostart_dir="$user_home/.config/autostart"
    mkdir -p "$autostart_dir"
    
    # Create Waybar autostart entry
    cat > "$autostart_dir/waybar.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Waybar
Comment=Highly customizable Wayland bar
Exec=waybar
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
    
    # Create NetworkManager applet autostart entry
    cat > "$autostart_dir/nm-applet.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=NetworkManager Applet
Comment=NetworkManager applet for managing network connections
Exec=nm-applet --indicator
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
    
    # Create Bluetooth applet autostart entry
    cat > "$autostart_dir/blueman.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Blueman Applet
Comment=Blueman Bluetooth applet
Exec=blueman-applet
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
    
    # Set proper ownership and permissions
    chown -R "$username:$username" "$autostart_dir"
    chmod 644 "$autostart_dir"/*.desktop
    
    log_success "Created autostart entries"
}

# Function to verify desktop integration
verify_integration() {
    log_info "Verifying desktop integration..."
    
    local verification_failed=0
    
    # Check session file
    if [ -f "/usr/share/wayland-sessions/niri.desktop" ]; then
        log_success "✓ Niri session file exists"
    else
        log_error "✗ Niri session file missing"
        verification_failed=1
    fi
    
    # Check session script
    if [ -f "/usr/bin/niri-session" ]; then
        log_success "✓ Niri session script exists"
    else
        log_error "✗ Niri session script missing"
        verification_failed=1
    fi
    
    # Check system configs
    if [ -f "/etc/xdg/niri/config.kdl" ]; then
        log_success "✓ Niri system configuration exists"
    else
        log_warning "⚠ Niri system configuration missing"
    fi
    
    if [ -f "/etc/xdg/waybar/config" ]; then
        log_success "✓ Waybar system configuration exists"
    else
        log_warning "⚠ Waybar system configuration missing"
    fi
    
    if [ -f "/etc/xdg/wofi/config" ]; then
        log_success "✓ wofi system configuration exists"
    else
        log_warning "⚠ wofi system configuration missing"
    fi
    
    # Check system environment
    if [ -f "/etc/environment.d/voidance-desktop.conf" ]; then
        log_success "✓ System environment file exists"
    else
        log_warning "⚠ System environment file missing"
    fi
    
    if [ $verification_failed -eq 0 ]; then
        log_success "✓ Desktop integration verification passed"
        return 0
    else
        log_error "✗ Desktop integration verification failed"
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
                create_system_directories
                install_system_configs
                create_wayland_sessions
                create_niri_session_script
                create_system_environment
                verify_integration
                
                log_success ""
                log_success "Desktop environment integration completed successfully!"
                log_info "Users can now select 'Niri' from the SDDM login screen"
                log_info "Run '$0 user <username>' to setup for existing users"
            else
                log_info "DRY RUN: Would install desktop environment integration"
            fi
            ;;
        "user")
            local username="${2:-}"
            if [ -z "$username" ]; then
                log_error "Username required for user setup"
                log_info "Usage: $0 user <username>"
                exit 1
            fi
            
            if [ "$dry_run" = "false" ]; then
                create_user_directories "$username"
                install_user_configs "$username"
                create_environment_file "$username"
                create_desktop_entries "$username"
                create_autostart_entries "$username"
                
                log_success ""
                log_success "Desktop environment setup completed for user: $username"
            else
                log_info "DRY RUN: Would setup desktop environment for user: $username"
            fi
            ;;
        "verify")
            verify_integration
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command '$action'"
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