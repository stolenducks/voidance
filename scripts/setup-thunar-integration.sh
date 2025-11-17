#!/bin/bash
# Thunar System Integration Script
# Configures Thunar integration with Voidance system services

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
    exit 1
}

# Function to setup Thunar environment variables
setup_environment() {
    log "Setting up Thunar environment variables"
    
    local env_file="$CONFIG_DIR/desktop/environment"
    
    # Add Thunar-specific environment variables
    cat >> "$env_file" << 'EOF'

# Thunar File Manager Environment Variables
# These variables ensure proper integration with the desktop environment

# Set default file manager
export FILE_MANAGER=thunar

# Enable GVFS integration for remote filesystems
export GIO_USE_VFS=local

# Configure thumbnail generation
export GIO_USE_VOLUME_MONITOR=unix

# Set up trash directory
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

# Enable file manager integration with desktop
export THUNAR_LEGACY_PANEL=1
EOF
    
    log "✓ Environment variables configured"
}

# Function to configure GVFS services
configure_gvfs_services() {
    log "Configuring GVFS services for Thunar"
    
    # Create GVFS configuration directory
    local gvfs_config_dir="$CONFIG_DIR/desktop/gvfs"
    mkdir -p "$gvfs_config_dir"
    
    # Create GVFS configuration
    cat > "$gvfs_config_dir/gvfs.conf" << 'EOF'
# GVFS Configuration for Thunar
# Enables virtual filesystem support for remote and removable media

[gvfs]
# Enable GVFS daemon
enabled=true

# Enable volume monitoring
volume_monitor=true

# Enable trash support
trash=true

# Enable network protocols
network_protocols=smb,sftp,ftp,http,https

# Enable removable media support
removable_media=true

# Enable MTP support (Android devices)
mtp=true

# Enable GPhoto2 support (cameras)
gphoto2=true

# Enable administrative access
admin=true
EOF
    
    log "✓ GVFS services configured"
}

# Function to setup desktop integration
setup_desktop_integration() {
    log "Setting up desktop integration for Thunar"
    
    # Update desktop environment configuration
    local desktop_config="$CONFIG_DIR/desktop/desktop-environment.json"
    
    if [ -f "$desktop_config" ]; then
        # Add Thunar to applications list
        jq '.applications += {"file_manager": "thunar"}' "$desktop_config" > "${desktop_config}.tmp"
        mv "${desktop_config}.tmp" "$desktop_config"
        
        # Update default applications
        jq '.default_applications.file_manager = "thunar.desktop"' "$desktop_config" > "${desktop_config}.tmp"
        mv "${desktop_config}.tmp" "$desktop_config"
        
        # Add file manager capabilities
        jq '.capabilities += ["file_management", "volume_management", "network_protocols", "trash_support"]' "$desktop_config" > "${desktop_config}.tmp"
        mv "${desktop_config}.tmp" "$desktop_config"
        
        log "✓ Desktop environment configuration updated"
    else
        log "⚠ Desktop environment configuration not found, skipping integration"
    fi
}

# Function to configure volume management
configure_volume_management() {
    log "Configuring volume management for Thunar"
    
    # Create volume management configuration
    local volume_config="$CONFIG_DIR/desktop/volume-management.conf"
    
    cat > "$volume_config" << 'EOF'
# Volume Management Configuration for Thunar
# Handles removable media and network volumes

[automount]
# Enable automatic mounting of removable media
enabled=true

# Mount options for removable media
mount_options=noexec,nosuid,nodev,relatime

# Mount options for internal drives
internal_mount_options=relatime

# Auto-open mounted media
auto_open=false

# Auto-open removable media
auto_open_removable=false

[mount_notification]
# Show notifications when mounting
enabled=true

# Show notifications for removable media
removable=true

# Show notifications for network volumes
network=true

[trash]
# Enable trash support
enabled=true

# Trash location
trash_path=$XDG_DATA_HOME/Trash

# Maximum trash size (in MB)
max_size=1024

# Empty trash on logout
empty_on_logout=false
EOF
    
    log "✓ Volume management configured"
}

# Function to setup file operations
setup_file_operations() {
    log "Setting up file operations for Thunar"
    
    # Create file operations configuration
    local file_ops_config="$CONFIG_DIR/desktop/file-operations.conf"
    
    cat > "$file_ops_config" << 'EOF'
# File Operations Configuration for Thunar
# Configures default behavior for file operations

[copy]
# Preserve permissions when copying
preserve_permissions=true

# Preserve timestamps when copying
preserve_timestamps=true

# Follow symlinks when copying
follow_symlinks=false

# Show progress dialog
show_progress=true

# Verify copied files
verify=false

[delete]
# Move to trash instead of deleting
use_trash=true

# Confirm before moving to trash
confirm_trash=true

# Confirm before permanent deletion
confirm_delete=true

# Show delete confirmation dialog
show_confirmation=true

[rename]
# Show rename dialog
show_dialog=true

# Highlight filename extension
highlight_extension=true

# Allow empty filenames
allow_empty=false

[compression]
# Default compression format
default_format=tar.gz

# Compression level (1-9)
compression_level=6

# Create archive in source directory
same_directory=true

# Show compression progress
show_progress=true
EOF
    
    log "✓ File operations configured"
}

# Function to create Thunar wrapper script
create_wrapper_script() {
    log "Creating Thunar wrapper script"
    
    local wrapper_dir="/usr/local/bin"
    local wrapper_file="$wrapper_dir/thunar-wrapper"
    
    # Create wrapper script with proper environment
    sudo tee "$wrapper_file" > /dev/null << 'EOF'
#!/bin/bash
# Thunar wrapper script for Voidance desktop environment
# Ensures proper environment setup and integration

# Source desktop environment
if [ -f /etc/voidance/desktop-environment ]; then
    source /etc/voidance/desktop-environment
fi

# Set Thunar-specific environment
export FILE_MANAGER=thunar
export GIO_USE_VFS=local

# Launch Thunar with configuration
exec thunar "$@"
EOF
    
    # Make wrapper executable
    sudo chmod +x "$wrapper_file"
    
    log "✓ Thunar wrapper script created"
}

# Function to configure desktop services
configure_desktop_services() {
    log "Configuring desktop services for Thunar"
    
    # Create desktop services configuration
    local services_config="$CONFIG_DIR/desktop/services.json"
    
    cat > "$services_config" << 'EOF'
{
  "services": {
    "file_manager": {
      "name": "Thunar",
      "executable": "thunar",
      "desktop_file": "thunar.desktop",
      "capabilities": [
        "local_filesystem",
        "remote_filesystem",
        "removable_media",
        "network_protocols",
        "trash_support",
        "file_operations",
        "search",
        "bookmarks",
        "custom_actions"
      ],
      "dependencies": [
        "gvfs",
        "thunar-volman",
        "thunar-archive-plugin"
      ],
      "environment": {
        "FILE_MANAGER": "thunar",
        "GIO_USE_VFS": "local"
      }
    }
  },
  "integration": {
    "desktop_environment": {
      "default_file_manager": "thunar",
      "show_desktop_icons": false,
      "home_directory_link": true,
      "trash_icon": true,
      "network_volumes": true,
      "removable_media": true
    },
    "system_services": {
      "gvfs_daemon": true,
      "volume_monitoring": true,
      "trash_management": true,
      "network_protocols": true
    }
  }
}
EOF
    
    log "✓ Desktop services configured"
}

# Function to verify integration
verify_integration() {
    log "Verifying Thunar integration"
    
    # Check if Thunar is available
    if command -v thunar >/dev/null 2>&1; then
        log "✓ Thunar is installed and available"
    else
        error "Thunar is not installed or not in PATH"
    fi
    
    # Check if configuration directory exists
    if [ -d "$CONFIG_DIR/applications/thunar" ]; then
        log "✓ Thunar configuration directory exists"
    else
        error "Thunar configuration directory not found"
    fi
    
    # Check if GVFS is available
    if command -v gvfs-mount >/dev/null 2>&1; then
        log "✓ GVFS is available for virtual filesystem support"
    else
        log "⚠ GVFS not found - some features may not work"
    fi
    
    # Check if wrapper script exists
    if [ -f "/usr/local/bin/thunar-wrapper" ]; then
        log "✓ Thunar wrapper script is installed"
    else
        log "⚠ Thunar wrapper script not found (may not be needed)"
    fi
    
    log "✓ Integration verification completed"
}

# Main integration function
main() {
    log "Starting Thunar system integration"
    
    setup_environment
    configure_gvfs_services
    setup_desktop_integration
    configure_volume_management
    setup_file_operations
    create_wrapper_script
    configure_desktop_services
    verify_integration
    
    log "✓ Thunar system integration completed successfully"
}

# Handle script arguments
case "${1:-}" in
    "environment")
        setup_environment
        ;;
    "gvfs")
        configure_gvfs_services
        ;;
    "desktop")
        setup_desktop_integration
        ;;
    "volume")
        configure_volume_management
        ;;
    "file-ops")
        setup_file_operations
        ;;
    "wrapper")
        create_wrapper_script
        ;;
    "services")
        configure_desktop_services
        ;;
    "verify")
        verify_integration
        ;;
    *)
        main
        ;;
esac