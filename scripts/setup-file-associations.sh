#!/bin/bash
# File Type Associations Setup Script
# Configures default applications and MIME type associations

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

# Function to install MIME type associations
install_mime_associations() {
    log "Installing MIME type associations"
    
    local defaults_file="$CONFIG_DIR/desktop/applications/defaults.list"
    local system_apps_dir="/usr/share/applications"
    local local_apps_dir="$HOME/.local/share/applications"
    
    # Determine target directory
    local target_dir="$local_apps_dir"
    if [ -w "/usr/share/applications" ]; then
        target_dir="/usr/share/applications"
        log "Installing to system applications directory"
    else
        log "Installing to user applications directory"
    fi
    
    # Create target directory if needed
    mkdir -p "$target_dir"
    
    # Copy defaults file
    if [ -f "$defaults_file" ]; then
        cp "$defaults_file" "$target_dir/defaults.list"
        log "✓ MIME type associations installed"
    else
        error "Defaults file not found: $defaults_file"
    fi
    
    # Update MIME database
    if command -v update-mime-database >/dev/null 2>&1; then
        update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
        log "✓ MIME database updated"
    fi
}

# Function to setup default applications
setup_default_applications() {
    log "Setting up default applications"
    
    # Create default applications configuration
    local apps_config="$CONFIG_DIR/desktop/default-applications.json"
    
    cat > "$apps_config" << 'EOF'
{
  "default_applications": {
    "text/plain": "ghostty.desktop",
    "text/x-shellscript": "ghostty.desktop",
    "text/x-python": "ghostty.desktop",
    "text/x-java": "ghostty.desktop",
    "text/x-c": "ghostty.desktop",
    "text/x-c++": "ghostty.desktop",
    "text/html": "ghostty.desktop",
    "text/css": "ghostty.desktop",
    "application/json": "ghostty.desktop",
    "application/xml": "ghostty.desktop",
    "application/javascript": "ghostty.desktop",
    "inode/directory": "thunar.desktop",
    "image/jpeg": "org.gnome.eog.desktop",
    "image/png": "org.gnome.eog.desktop",
    "image/gif": "org.gnome.eog.desktop",
    "audio/mpeg": "org.gnome.Rhythmbox3.desktop",
    "audio/mp3": "org.gnome.Rhythmbox3.desktop",
    "audio/ogg": "org.gnome.Rhythmbox3.desktop",
    "video/mp4": "org.gnome.Totem.desktop",
    "video/mpeg": "org.gnome.Totem.desktop",
    "application/pdf": "org.gnome.Evince.desktop",
    "application/zip": "engrampa.desktop",
    "application/x-rar": "engrampa.desktop",
    "application/x-7z-compressed": "engrampa.desktop",
    "x-scheme-handler/http": "firefox.desktop",
    "x-scheme-handler/https": "firefox.desktop",
    "x-scheme-handler/mailto": "thunderbird.desktop"
  },
  "fallback_applications": {
    "text/*": "ghostty.desktop",
    "image/*": "org.gnome.eog.desktop",
    "audio/*": "org.gnome.Rhythmbox3.desktop",
    "video/*": "org.gnome.Totem.desktop",
    "application/*pdf": "org.gnome.Evince.desktop",
    "application/*zip": "engrampa.desktop",
    "application/*archive": "engrampa.desktop"
  },
  "educational_notes": {
    "text_files": "Open in terminal to encourage command-line usage",
    "directories": "Use Thunar for graphical file management",
    "media_files": "Open in appropriate media viewers",
    "archives": "Extract with archive manager",
    "web_content": "Open in web browser",
    "development": "Edit in terminal for coding workflows"
  }
}
EOF
    
    log "✓ Default applications configuration created"
}

# Function to create desktop entries for missing applications
create_missing_desktop_entries() {
    log "Creating desktop entries for missing applications"
    
    local desktop_dir="$CONFIG_DIR/desktop/applications"
    
    # Create fallback text editor entry
    cat > "$desktop_dir/ghostty-text-editor.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Text Editor (Terminal)
Name[en]=Text Editor (Terminal)
Comment=Edit text files in terminal
Comment[en]=Edit text files in terminal
GenericName=Text Editor
GenericName[en]=Text Editor
Exec=ghostty -e nano %F
Terminal=true
Icon=accessories-text-editor
StartupNotify=true
Categories=Utility;TextEditor;GTK;
Keywords=text;editor;terminal;nano;
MimeType=text/plain;text/x-log;text/x-readme;text/x-shellscript;text/x-python;text/x-java;text/x-c;text/x-c++;text/html;text/css;application/json;application/xml;
EOF
    
    # Create fallback image viewer entry
    cat > "$desktop_dir/fallback-image-viewer.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Image Viewer
Name[en]=Image Viewer
Comment=View images
Comment[en]=View images
GenericName=Image Viewer
GenericName[en]=Image Viewer
Exec=ghostty -e "file %F"
Terminal=true
Icon=image-viewer
StartupNotify=true
Categories=Graphics;Viewer;GTK;
Keywords=image;viewer;picture;photo;
MimeType=image/jpeg;image/png;image/gif;image/bmp;image/tiff;image/webp;image/svg+xml;
EOF
    
    # Create fallback archive manager entry
    cat > "$desktop_dir/fallback-archive-manager.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Archive Manager
Name[en]=Archive Manager
Comment=Create and extract archives
Comment[en]=Create and extract archives
GenericName=Archive Manager
GenericName[en]=Archive Manager
Exec=ghostty -e "tar -tzf %F" 2>/dev/null || echo "Not an archive"
Terminal=true
Icon=archive-manager
StartupNotify=true
Categories=System;Archiving;GTK;
Keywords=archive;compress;extract;tar;zip;
MimeType=application/zip;application/x-zip;application/x-zip-compressed;application/x-rar;application/x-7z-compressed;application/x-tar;application/x-tar-gz;application/gzip;application/x-bzip2;application/x-tar-bz2;
EOF
    
    log "✓ Fallback desktop entries created"
}

# Function to configure xdg utilities
configure_xdg_utilities() {
    log "Configuring XDG utilities"
    
    # Create XDG configuration directory
    local xdg_config_dir="$HOME/.config"
    mkdir -p "$xdg_config_dir"
    
    # Create XDG user directories file
    local user_dirs_file="$xdg_config_dir/user-dirs.dirs"
    
    cat > "$user_dirs_file" << 'EOF'
# XDG User Directories Configuration
# Defines standard user directories for Voidance desktop

# Desktop directory
XDG_DESKTOP_DIR="$HOME/Desktop"

# Documents directory
XDG_DOCUMENTS_DIR="$HOME/Documents"

# Downloads directory
XDG_DOWNLOAD_DIR="$HOME/Downloads"

# Music directory
XDG_MUSIC_DIR="$HOME/Music"

# Pictures directory
XDG_PICTURES_DIR="$HOME/Pictures"

# Videos directory
XDG_VIDEOS_DIR="$HOME/Videos"

# Public directory
XDG_PUBLICSHARE_DIR="$HOME/Public"

# Templates directory
XDG_TEMPLATES_DIR="$HOME/Templates"
EOF
    
    # Create XDG MIME applications file
    local mimeapps_file="$xdg_config_dir/mimeapps.list"
    
    cat > "$mimeapps_file" << 'EOF'
[Default Applications]
text/plain=ghostty.desktop
text/x-shellscript=ghostty.desktop
text/x-python=ghostty.desktop
text/x-java=ghostty.desktop
text/x-c=ghostty.desktop
text/x-c++=ghostty.desktop
text/html=ghostty.desktop
text/css=ghostty.desktop
application/json=ghostty.desktop
application/xml=ghostty.desktop
application/javascript=ghostty.desktop
inode/directory=thunar.desktop
image/jpeg=ghostty-text-editor.desktop
image/png=ghostty-text-editor.desktop
image/gif=ghostty-text-editor.desktop
audio/mpeg=ghostty-text-editor.desktop
audio/mp3=ghostty-text-editor.desktop
audio/ogg=ghostty-text-editor.desktop
video/mp4=ghostty-text-editor.desktop
video/mpeg=ghostty-text-editor.desktop
application/pdf=ghostty-text-editor.desktop
application/zip=fallback-archive-manager.desktop
application/x-rar=fallback-archive-manager.desktop
application/x-7z-compressed=fallback-archive-manager.desktop
x-scheme-handler/http=ghostty-text-editor.desktop
x-scheme-handler/https=ghostty-text-editor.desktop
x-scheme-handler/mailto=ghostty-text-editor.desktop

[Added Associations]
text/plain=ghostty.desktop;ghostty-text-editor.desktop;
text/x-shellscript=ghostty.desktop;ghostty-text-editor.desktop;
inode/directory=thunar.desktop;
image/jpeg=ghostty-text-editor.desktop;
image/png=ghostty-text-editor.desktop;
application/zip=fallback-archive-manager.desktop;
EOF
    
    log "✓ XDG utilities configured"
}

# Function to verify associations
verify_associations() {
    log "Verifying file type associations"
    
    # Check if defaults file exists
    local defaults_file="$HOME/.local/share/applications/defaults.list"
    if [ -f "$defaults_file" ]; then
        log "✓ MIME type associations file exists"
    else
        log "⚠ MIME type associations file not found"
    fi
    
    # Check if mimeapps.list exists
    local mimeapps_file="$HOME/.config/mimeapps.list"
    if [ -f "$mimeapps_file" ]; then
        log "✓ XDG MIME applications file exists"
    else
        log "⚠ XDG MIME applications file not found"
    fi
    
    # Test some associations
    if command -v xdg-mime >/dev/null 2>&1; then
        local text_default=$(xdg-mime query default text/plain 2>/dev/null || echo "not set")
        log "✓ Default for text/plain: $text_default"
        
        local dir_default=$(xdg-mime query default inode/directory 2>/dev/null || echo "not set")
        log "✓ Default for inode/directory: $dir_default"
    else
        log "⚠ xdg-mime not available for testing"
    fi
    
    log "✓ Association verification completed"
}

# Function to create user directories
create_user_directories() {
    log "Creating user directories"
    
    local directories=(
        "$HOME/Desktop"
        "$HOME/Documents"
        "$HOME/Downloads"
        "$HOME/Music"
        "$HOME/Pictures"
        "$HOME/Videos"
        "$HOME/Public"
        "$HOME/Templates"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log "✓ Created directory: $dir"
        else
            log "✓ Directory exists: $dir"
        fi
    done
    
    log "✓ User directories created"
}

# Main setup function
main() {
    log "Starting file type associations setup"
    
    install_mime_associations
    setup_default_applications
    create_missing_desktop_entries
    configure_xdg_utilities
    create_user_directories
    verify_associations
    
    log "✓ File type associations setup completed successfully"
}

# Handle script arguments
case "${1:-}" in
    "mime")
        install_mime_associations
        ;;
    "defaults")
        setup_default_applications
        ;;
    "desktop")
        create_missing_desktop_entries
        ;;
    "xdg")
        configure_xdg_utilities
        ;;
    "directories")
        create_user_directories
        ;;
    "verify")
        verify_associations
        ;;
    *)
        main
        ;;
esac