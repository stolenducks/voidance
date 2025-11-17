#!/bin/bash
# Font Configuration Script
# Configures fonts for Voidance desktop environment

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

# Function to setup font directories
setup_font_directories() {
    log "Setting up font directories"
    
    local font_dirs=(
        "$HOME/.local/share/fonts"
        "$HOME/.config/fontconfig"
        "$HOME/.config/fontconfig/conf.d"
    )
    
    for dir in "${font_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log "✓ Created font directory: $dir"
        else
            log "✓ Font directory exists: $dir"
        fi
    done
}

# Function to install font configuration
install_font_config() {
    log "Installing font configuration"
    
    local config_file="$CONFIG_DIR/desktop/fontconfig/fonts.conf"
    local target_file="$HOME/.config/fontconfig/fonts.conf"
    
    if [ -f "$config_file" ]; then
        cp "$config_file" "$target_file"
        log "✓ Font configuration installed"
    else
        error "Font configuration file not found: $config_file"
    fi
}

# Function to create font symlinks
create_font_symlinks() {
    log "Creating font configuration symlinks"
    
    local conf_d_dir="$HOME/.config/fontconfig/conf.d"
    local config_file="$CONFIG_DIR/desktop/fontconfig/fonts.conf"
    
    # Create symlink in conf.d for system-wide recognition
    if [ -f "$config_file" ]; then
        ln -sf "$config_file" "$conf_d_dir/99-voidance-fonts.conf"
        log "✓ Font configuration symlink created"
    else
        error "Font configuration file not found: $config_file"
    fi
}

# Function to configure application-specific fonts
configure_application_fonts() {
    log "Configuring application-specific fonts"
    
    # Create application font configuration
    local app_fonts_config="$CONFIG_DIR/desktop/application-fonts.json"
    
    cat > "$app_fonts_config" << 'EOF'
{
  "application_fonts": {
    "terminal": {
      "font_family": "Inconsolata",
      "font_size": 12,
      "font_weight": "400",
      "line_height": 1.2,
      "letter_spacing": 0,
      "antialias": true,
      "hinting": "hintmedium"
    },
    "ui": {
      "font_family": "Montserrat",
      "font_size": 10,
      "font_weight": "400",
      "line_height": 1.4,
      "letter_spacing": 0,
      "antialias": true,
      "hinting": "hintslight"
    },
    "notifications": {
      "font_family": "Montserrat",
      "font_size": 10,
      "font_weight": "400",
      "line_height": 1.3,
      "antialias": true,
      "hinting": "hintslight"
    },
    "file_manager": {
      "font_family": "Montserrat",
      "font_size": 10,
      "font_weight": "400",
      "line_height": 1.3,
      "antialias": true,
      "hinting": "hintslight"
    }
  },
  "font_substitutions": {
    "sans-serif": ["Montserrat", "Noto Sans", "DejaVu Sans"],
    "serif": ["Noto Serif", "DejaVu Serif", "Times New Roman"],
    "monospace": ["Inconsolata", "JetBrains Mono", "DejaVu Sans Mono"],
    "cursive": ["Comic Sans MS", "Apple Chancery"],
    "fantasy": ["Impact", "Western"]
  },
  "rendering_settings": {
    "antialias": true,
    "hinting": true,
    "hintstyle": "hintslight",
    "rgba": "rgb",
    "autohint": true,
    "lcdfilter": "lcddefault"
  },
  "educational_notes": {
    "terminal_fonts": "Inconsolata provides excellent readability for code and terminal use",
    "ui_fonts": "Montserrat offers clean, modern typography for user interfaces",
    "rendering": "Balanced settings provide good readability across different displays",
    "substitutions": "Ensure consistent text appearance when preferred fonts are unavailable"
  }
}
EOF
    
    log "✓ Application font configuration created"
}

# Function to update font cache
update_font_cache() {
    log "Updating font cache"
    
    # Update user font cache
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -fv "$HOME/.local/share/fonts" 2>/dev/null || true
        log "✓ User font cache updated"
    else
        log "⚠ fc-cache not available, cannot update font cache"
    fi
    
    # Update system font cache (if possible)
    if command -v fc-cache >/dev/null 2>&1 && [ -w "/usr/share/fonts" ]; then
        sudo fc-cache -fv 2>/dev/null || true
        log "✓ System font cache updated"
    else
        log "⚠ Cannot update system font cache (permission denied)"
    fi
}

# Function to verify font installation
verify_font_installation() {
    log "Verifying font installation"
    
    # Check if Montserrat is available
    if fc-match -s "Montserrat" >/dev/null 2>&1; then
        local montserrat_info=$(fc-match "Montserrat" 2>/dev/null || echo "not found")
        log "✓ Montserrat font available: $montserrat_info"
    else
        log "⚠ Montserrat font not found"
    fi
    
    # Check if Inconsolata is available
    if fc-match -s "Inconsolata" >/dev/null 2>&1; then
        local inconsolata_info=$(fc-match "Inconsolata" 2>/dev/null || echo "not found")
        log "✓ Inconsolata font available: $inconsolata_info"
    else
        log "⚠ Inconsolata font not found"
    fi
    
    # Check font configuration
    if [ -f "$HOME/.config/fontconfig/fonts.conf" ]; then
        log "✓ Font configuration file exists"
    else
        log "⚠ Font configuration file not found"
    fi
    
    # Test font matching
    if command -v fc-match >/dev/null 2>&1; then
        local sans_match=$(fc-match "sans-serif" 2>/dev/null | head -n1 || echo "failed")
        local mono_match=$(fc-match "monospace" 2>/dev/null | head -n1 || echo "failed")
        
        log "✓ Sans-serif match: $sans_match"
        log "✓ Monospace match: $mono_match"
    else
        log "⚠ fc-match not available for testing"
    fi
}

# Function to create font utilities
create_font_utilities() {
    log "Creating font utilities"
    
    local utils_dir="$CONFIG_DIR/desktop/utils"
    mkdir -p "$utils_dir"
    
    # Create font test script
    cat > "$utils_dir/test-fonts.sh" << 'EOF'
#!/bin/bash
# Font Test Script
# Tests font rendering and configuration

echo "Testing font configuration..."

echo ""
echo "=== Font Matching Tests ==="
echo "Sans-serif font:"
fc-match "sans-serif"
echo ""
echo "Monospace font:"
fc-match "monospace"
echo ""
echo "Serif font:"
fc-match "serif"

echo ""
echo "=== Available Fonts ==="
echo "Montserrat fonts:"
fc-list :family=Montserrat
echo ""
echo "Inconsolata fonts:"
fc-list :family=Inconsolata

echo ""
echo "=== Font Configuration ==="
echo "Configuration file:"
cat "$HOME/.config/fontconfig/fonts.conf" 2>/dev/null || echo "Not found"

echo ""
echo "Font cache status:"
fc-cache -sv 2>/dev/null || echo "Cannot update cache"
EOF
    
    chmod +x "$utils_dir/test-fonts.sh"
    
    # Create font info script
    cat > "$utils_dir/font-info.sh" << 'EOF'
#!/bin/bash
# Font Information Script
# Displays detailed font information

if [ $# -eq 0 ]; then
    echo "Usage: $0 <font-family>"
    echo "Example: $0 Montserrat"
    exit 1
fi

font_family="$1"

echo "=== Font Information for: $font_family ==="
echo ""

echo "Font match:"
fc-match "$font_family"
echo ""

echo "Available styles:"
fc-list :family="$font_family" :style | sort -u
echo ""

echo "Font files:"
fc-list :family="$font_family" file | sort -u
echo ""

echo "Character coverage:"
fc-query "$font_family" 2>/dev/null || echo "Cannot query font information"
EOF
    
    chmod +x "$utils_dir/font-info.sh"
    
    log "✓ Font utilities created"
}

# Function to configure font rendering for different displays
configure_display_settings() {
    log "Configuring font rendering for different displays"
    
    # Create display-specific configurations
    local display_config_dir="$CONFIG_DIR/desktop/fontconfig/conf.d"
    mkdir -p "$display_config_dir"
    
    # LCD display configuration
    cat > "$display_config_dir/10-lcd.conf" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- LCD display optimization -->
  <match target="font">
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
    <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
  </match>
</fontconfig>
EOF
    
    # HiDPI display configuration
    cat > "$display_config_dir/20-hidpi.conf" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- HiDPI display optimization -->
  <match target="font">
    <test name="pixelsize" compare="less_eq"><double>12</double></test>
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
    <edit name="hinting" mode="assign"><bool>false</bool></edit>
  </match>
</fontconfig>
EOF
    
    log "✓ Display-specific configurations created"
}

# Main configuration function
main() {
    log "Starting font configuration"
    
    setup_font_directories
    install_font_config
    create_font_symlinks
    configure_application_fonts
    configure_display_settings
    update_font_cache
    create_font_utilities
    verify_font_installation
    
    log "✓ Font configuration completed successfully"
}

# Handle script arguments
case "${1:-}" in
    "directories")
        setup_font_directories
        ;;
    "config")
        install_font_config
        ;;
    "cache")
        update_font_cache
        ;;
    "verify")
        verify_font_installation
        ;;
    "utilities")
        create_font_utilities
        ;;
    *)
        main
        ;;
esac