#!/bin/bash
# Install Desktop Entries for Ghostty
# Installs desktop entries and shortcuts for Ghostty terminal

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

# System directories
SYSTEM_APPS_DIR="/usr/share/applications"
LOCAL_APPS_DIR="$HOME/.local/share/applications"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
    exit 1
}

# Function to install desktop entries
install_desktop_entries() {
    log "Installing Ghostty desktop entries"
    
    local entries=(
        "$CONFIG_DIR/desktop/applications/ghostty.desktop"
        "$CONFIG_DIR/desktop/applications/voidance-terminal.desktop"
    )
    
    # Install to system directory if possible, otherwise local
    local target_dir="$LOCAL_APPS_DIR"
    if [ -w "$SYSTEM_APPS_DIR" ]; then
        target_dir="$SYSTEM_APPS_DIR"
        log "Installing to system applications directory"
    else
        log "Installing to user applications directory"
    fi
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Copy desktop entries
    for entry in "${entries[@]}"; do
        if [ -f "$entry" ]; then
            local basename=$(basename "$entry")
            cp "$entry" "$target_dir/$basename"
            log "✓ Installed $basename"
        else
            log "⚠ Desktop entry not found: $entry"
        fi
    done
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$target_dir"
        log "✓ Updated desktop database"
    fi
    
    log "✓ Desktop entries installation completed"
}

# Function to create keyboard shortcuts
create_keyboard_shortcuts() {
    log "Creating keyboard shortcuts for Ghostty"
    
    # Create shortcuts configuration for desktop environment
    local shortcuts_config="$CONFIG_DIR/desktop/shortcuts.json"
    
    cat > "$shortcuts_config" << 'EOF'
{
  "shortcuts": {
    "terminal": {
      "launch": "Super+Enter",
      "new_window": "Super+Shift+Enter",
      "new_tab": "Ctrl+Shift+T",
      "close_tab": "Ctrl+Shift+W",
      "copy": "Ctrl+Shift+C",
      "paste": "Ctrl+Shift+V",
      "zoom_in": "Ctrl+Plus",
      "zoom_out": "Ctrl+Minus",
      "reset_zoom": "Ctrl+0"
    }
  },
  "applications": {
    "ghostty": {
      "exec": "ghostty",
      "desktop_file": "ghostty.desktop",
      "category": "System",
      "mimetypes": [
        "text/plain",
        "text/x-shellscript",
        "text/x-python",
        "text/x-java",
        "text/x-c",
        "text/x-c++",
        "application/x-shellscript"
      ]
    }
  }
}
EOF
    
    log "✓ Keyboard shortcuts configuration created"
}

# Function to setup default applications
setup_default_applications() {
    log "Setting up Ghostty as default terminal application"
    
    # Create default applications configuration
    local defaults_config="$CONFIG_DIR/desktop/defaults.list"
    
    cat > "$defaults_config" << 'EOF'
[Default Applications]
text/plain=ghostty.desktop
text/x-shellscript=ghostty.desktop
text/x-python=ghostty.desktop
text/x-java=ghostty.desktop
text/x-c=ghostty.desktop
text/x-c++=ghostty.desktop
application/x-shellscript=ghostty.desktop

[Added Associations]
text/plain=ghostty.desktop;
text/x-shellscript=ghostty.desktop;
text/x-python=ghostty.desktop;
text/x-java=ghostty.desktop;
text/x-c=ghostty.desktop;
text/x-c++=ghostty.desktop;
application/x-shellscript=ghostty.desktop;
EOF
    
    log "✓ Default applications configuration created"
}

# Function to create launcher shortcuts
create_launcher_shortcuts() {
    log "Creating launcher shortcuts"
    
    # Create launcher configuration for wofi
    local launcher_config="$CONFIG_DIR/desktop/wofi/ghostty-launcher"
    
    mkdir -p "$(dirname "$launcher_config")"
    
    cat > "$launcher_config" << 'EOF'
#!/bin/bash
# Ghostty launcher for wofi
# Provides quick access to Ghostty terminal actions

ACTIONS="New Window\nNew Tab\nSettings\nAbout"

SELECTED=$(echo -e "$ACTIONS" | wofi --dmenu --prompt="Ghostty:")

case "$SELECTED" in
    "New Window")
        ghostty
        ;;
    "New Tab")
        ghostty --new-tab
        ;;
    "Settings")
        ghostty --config
        ;;
    "About")
        ghostty --version
        ;;
esac
EOF
    
    chmod +x "$launcher_config"
    log "✓ Ghostty launcher shortcut created"
}

# Function to verify installation
verify_installation() {
    log "Verifying desktop entries installation"
    
    local target_dir="$LOCAL_APPS_DIR"
    if [ -w "$SYSTEM_APPS_DIR" ]; then
        target_dir="$SYSTEM_APPS_DIR"
    fi
    
    # Check if desktop entries exist
    local entries=(
        "ghostty.desktop"
        "voidance-terminal.desktop"
    )
    
    for entry in "${entries[@]}"; do
        if [ -f "$target_dir/$entry" ]; then
            log "✓ $entry is installed"
        else
            log "⚠ $entry not found in $target_dir"
        fi
    done
    
    # Check if Ghostty is in PATH
    if command -v ghostty >/dev/null 2>&1; then
        log "✓ Ghostty is available in PATH"
    else
        log "⚠ Ghostty not found in PATH"
    fi
    
    log "✓ Installation verification completed"
}

# Main installation function
main() {
    log "Starting Ghostty desktop entries installation"
    
    install_desktop_entries
    create_keyboard_shortcuts
    setup_default_applications
    create_launcher_shortcuts
    verify_installation
    
    log "✓ Ghostty desktop entries installation completed successfully"
}

# Handle script arguments
case "${1:-}" in
    "entries")
        install_desktop_entries
        ;;
    "shortcuts")
        create_keyboard_shortcuts
        ;;
    "defaults")
        setup_default_applications
        ;;
    "launcher")
        create_launcher_shortcuts
        ;;
    "verify")
        verify_installation
        ;;
    *)
        main
        ;;
esac