#!/bin/bash
# Desktop Applications Setup Script
# Installs and configures Ghostty, Thunar, mako, and fonts

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$(dirname "$SCRIPT_DIR")/packages"

# Source package configurations
source "$PACKAGES_DIR/desktop-applications.sh"

# Configuration paths
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="${XDG_DATA_HOME:-$HOME/.local}/bin"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
    exit 1
}

# Function to create directories
create_directories() {
    log "Creating configuration directories"
    
    local dirs=(
        "$CONFIG_DIR/ghostty"
        "$CONFIG_DIR/thunar"
        "$CONFIG_DIR/mako"
        "$CONFIG_DIR/fontconfig"
        "$CONFIG_DIR/fontconfig/conf.d"
        "$HOME/.local/share/applications"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log "Created directory: $dir"
    done
}

# Function to install terminal packages
install_terminal() {
    log "Installing terminal emulator (Ghostty)"
    
    # Install main terminal package
    if ! "$PACKAGES_DIR/desktop-applications.sh" install terminal; then
        error "Failed to install terminal packages"
    fi
    
    # Install terminal dependencies
    if ! "$PACKAGES_DIR/desktop-applications.sh" install terminal_deps; then
        error "Failed to install terminal dependencies"
    fi
    
    log "✓ Terminal installation completed"
}

# Function to install file manager packages
install_file_manager() {
    log "Installing file manager (Thunar)"
    
    # Install file manager packages
    if ! "$PACKAGES_DIR/desktop-applications.sh" install file_manager; then
        error "Failed to install file manager packages"
    fi
    
    # Install file manager dependencies
    if ! "$PACKAGES_DIR/desktop-applications.sh" install file_manager_deps; then
        error "Failed to install file manager dependencies"
    fi
    
    log "✓ File manager installation completed"
}

# Function to install notification system
install_notifications() {
    log "Installing notification system (mako)"
    
    # Install notification packages
    if ! "$PACKAGES_DIR/desktop-applications.sh" install notifications; then
        error "Failed to install notification packages"
    fi
    
    # Install notification dependencies
    if ! "$PACKAGES_DIR/desktop-applications.sh" install notification_deps; then
        error "Failed to install notification dependencies"
    fi
    
    log "✓ Notification system installation completed"
}

# Function to install fonts
install_fonts() {
    log "Installing fonts (Montserrat, Inconsolata)"
    
    # Install font packages
    if ! "$PACKAGES_DIR/desktop-applications.sh" install fonts; then
        error "Failed to install font packages"
    fi
    
    log "✓ Font installation completed"
}

# Function to verify installations
verify_installations() {
    log "Verifying installations"
    
    local packages=(
        "ghostty"
        "thunar"
        "mako"
        "ttf-montserrat"
        "ttf-inconsolata"
    )
    
    for package in "${packages[@]}"; do
        if pacman -Qi "$package" >/dev/null 2>&1; then
            log "✓ $package is installed"
        else
            error "Package $package is not installed"
        fi
    done
}

# Function to update font cache
update_font_cache() {
    log "Updating font cache"
    if fc-cache -fv; then
        log "✓ Font cache updated"
    else
        error "Failed to update font cache"
    fi
}

# Main installation function
main() {
    log "Starting desktop applications installation"
    
    # Create necessary directories
    create_directories
    
    # Install package groups
    install_terminal
    install_file_manager
    install_notifications
    install_fonts
    
    # Update font cache
    update_font_cache
    
    # Verify installations
    verify_installations
    
    log "✓ Desktop applications installation completed successfully"
}

# Handle script arguments
case "${1:-}" in
    "terminal")
        create_directories
        install_terminal
        ;;
    "file-manager")
        create_directories
        install_file_manager
        ;;
    "notifications")
        create_directories
        install_notifications
        ;;
    "fonts")
        create_directories
        install_fonts
        ;;
    "verify")
        verify_installations
        ;;
    *)
        main
        ;;
esac