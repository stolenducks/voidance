#!/bin/bash
# Complete Desktop Applications Integration Script
# Integrates all desktop applications with Voidance desktop environment

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

# Function to create comprehensive desktop environment configuration
create_desktop_environment_config() {
    log "Creating comprehensive desktop environment configuration"
    
    local desktop_config="$CONFIG_DIR/desktop/desktop-environment.json"
    
    cat > "$desktop_config" << 'EOF'
{
  "version": "1.0",
  "name": "Voidance Desktop Environment",
  "description": "Minimalist Wayland desktop environment with essential applications",
  
  "applications": {
    "terminal": "ghostty",
    "file_manager": "thunar",
    "notifications": "mako",
    "compositor": "niri",
    "status_bar": "waybar",
    "launcher": "wofi"
  },
  
  "default_applications": {
    "terminal": "ghostty.desktop",
    "file_manager": "thunar.desktop",
    "notification_daemon": "mako.desktop",
    "web_browser": "firefox.desktop",
    "text_editor": "ghostty.desktop",
    "image_viewer": "org.gnome.eog.desktop",
    "video_player": "org.gnome.Totem.desktop",
    "audio_player": "org.gnome.Rhythmbox3.desktop"
  },
  
  "capabilities": [
    "wayland_native",
    "gpu_acceleration",
    "notifications",
    "file_management",
    "volume_management",
    "network_protocols",
    "trash_support",
    "font_rendering",
    "theme_integration",
    "keyboard_shortcuts",
    "custom_actions"
  ],
  
  "environment": {
    "TERMINAL": "ghostty",
    "FILE_MANAGER": "thunar",
    "NOTIFICATION_DAEMON": "mako",
    "GHOSTTY_ENABLE_WAYLAND": "1",
    "GIO_USE_VFS": "local",
    "MAKO_DEFAULT_TIMEOUT": "5000",
    "XDG_NOTIFICATION_DESKTOP": "mako"
  },
  
  "fonts": {
    "ui": {
      "family": "Montserrat",
      "size": 10,
      "weight": "400"
    },
    "terminal": {
      "family": "Inconsolata",
      "size": 12,
      "weight": "400"
    },
    "notifications": {
      "family": "Montserrat",
      "size": 10,
      "weight": "400"
    }
  },
  
  "themes": {
    "colors": {
      "primary": "#88c0d0",
      "secondary": "#5e81ac",
      "background": "#2e3440",
      "foreground": "#eceff4",
      "urgent": "#bf616a",
      "warning": "#ebcb8b",
      "success": "#a3be8c"
    },
    "fonts": {
      "sans_serif": "Montserrat",
      "monospace": "Inconsolata",
      "serif": "Noto Serif"
    }
  },
  
  "shortcuts": {
    "terminal": "Super+Enter",
    "file_manager": "Super+E",
    "launcher": "Super+Space",
    "notifications": "Super+N",
    "quit": "Super+Shift+Q",
    "reload": "Super+Shift+R"
  },
  
  "autostart": [
    "mako",
    "waybar",
    "thunar --daemon"
  ],
  
  "educational_notes": {
    "terminal": "Ghostty provides modern GPU-accelerated terminal with Wayland support",
    "file_manager": "Thunar offers clean GTK interface with excellent keyboard navigation",
    "notifications": "Mako delivers lightweight Wayland-native notifications",
    "fonts": "Montserrat and Inconsolata provide optimal readability for UI and terminal",
    "integration": "All applications work seamlessly with Wayland and Niri compositor"
  }
}
EOF
    
    log "✓ Desktop environment configuration created"
}

# Function to create comprehensive test suite
create_comprehensive_test_suite() {
    log "Creating comprehensive test suite"
    
    local test_script="$CONFIG_DIR/desktop/test-all-applications.sh"
    
    cat > "$test_script" << 'EOF'
#!/bin/bash
# Comprehensive Desktop Applications Test Suite
# Tests all desktop applications and their integration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $*"
    ((TESTS_PASSED++))
}

failure() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ $*"
    ((TESTS_FAILED++))
}

skip() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $*"
    ((TESTS_SKIPPED++))
}

# Test all applications
test_all_applications() {
    log "Testing all desktop applications"
    
    # Test terminal
    if command -v ghostty >/dev/null 2>&1; then
        success "Ghostty terminal is available"
    else
        failure "Ghostty terminal not found"
    fi
    
    # Test file manager
    if command -v thunar >/dev/null 2>&1; then
        success "Thunar file manager is available"
    else
        failure "Thunar file manager not found"
    fi
    
    # Test notification daemon
    if command -v mako >/dev/null 2>&1; then
        success "Mako notification daemon is available"
    else
        failure "Mako notification daemon not found"
    fi
    
    # Test font utilities
    if command -v fc-match >/dev/null 2>&1; then
        success "Font utilities are available"
    else
        failure "Font utilities not found"
    fi
}

# Test desktop integration
test_desktop_integration() {
    log "Testing desktop integration"
    
    local desktop_config="$CONFIG_DIR/desktop/desktop-environment.json"
    if [ -f "$desktop_config" ]; then
        success "Desktop environment configuration exists"
        
        if jq -e '.applications' "$desktop_config" >/dev/null 2>&1; then
            success "Applications are configured"
        else
            failure "Applications not configured"
        fi
        
        if jq -e '.default_applications' "$desktop_config" >/dev/null 2>&1; then
            success "Default applications are configured"
        else
            failure "Default applications not configured"
        fi
    else
        failure "Desktop environment configuration not found"
    fi
}

# Test font configuration
test_font_configuration() {
    log "Testing font configuration"
    
    if fc-match "Montserrat" >/dev/null 2>&1; then
        success "Montserrat font is available"
    else
        failure "Montserrat font not found"
    fi
    
    if fc-match "Inconsolata" >/dev/null 2>&1; then
        success "Inconsolata font is available"
    else
        failure "Inconsolata font not found"
    fi
}

# Test Wayland integration
test_wayland_integration() {
    log "Testing Wayland integration"
    
    if [ "${WAYLAND_DISPLAY:-}" ]; then
        success "Running under Wayland"
    else
        skip "Not running under Wayland"
    fi
}

# Generate report
generate_report() {
    log "Generating comprehensive test report"
    
    echo ""
    echo "=========================================="
    echo "Desktop Applications Test Report"
    echo "=========================================="
    echo "Tests Passed:  $TESTS_PASSED"
    echo "Tests Failed:  $TESTS_FAILED"
    echo "Tests Skipped: $TESTS_SKIPPED"
    echo "Total Tests:   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✓ All tests passed! Desktop applications are ready."
        return 0
    else
        echo "✗ Some tests failed. Please review the issues above."
        return 1
    fi
}

# Main function
main() {
    log "Starting comprehensive desktop applications test"
    
    test_all_applications
    test_desktop_integration
    test_font_configuration
    test_wayland_integration
    
    generate_report
}

main "$@"
EOF
    
    chmod +x "$test_script"
    log "✓ Comprehensive test suite created"
}

# Function to create installation summary
create_installation_summary() {
    log "Creating installation summary"
    
    local summary_file="$CONFIG_DIR/desktop/installation-summary.md"
    
    cat > "$summary_file" << 'EOF'
# Voidance Desktop Applications Installation Summary

## Overview
This document summarizes the desktop applications installed and configured for the Voidance desktop environment.

## Applications Installed

### Terminal Emulator
- **Application**: Ghostty
- **Purpose**: GPU-accelerated terminal emulator with Wayland support
- **Configuration**: `~/.config/ghostty/config`
- **Features**: Tabs, splits, GPU acceleration, Wayland native
- **Font**: Inconsolata 12pt

### File Manager
- **Application**: Thunar
- **Purpose**: Modern GTK file manager with excellent keyboard support
- **Configuration**: `~/.config/Thunar/thunarrc`
- **Features**: Volume management, custom actions, keyboard shortcuts
- **Plugins**: Archive plugin, volume manager

### Notification System
- **Application**: Mako
- **Purpose**: Wayland-native notification daemon
- **Configuration**: `~/.config/mako/config`
- **Features**: Grouping, urgency levels, custom styling
- **Font**: Montserrat 10pt

### Font Configuration
- **UI Font**: Montserrat (clean, modern sans-serif)
- **Terminal Font**: Inconsolata (readable monospace)
- **Configuration**: `~/.config/fontconfig/fonts.conf`
- **Features**: Antialiasing, hinting, subpixel rendering

## Configuration Files

### Application Configurations
- `~/.config/ghostty/config` - Ghostty terminal configuration
- `~/.config/Thunar/thunarrc` - Thunar file manager settings
- `~/.config/Thunar/accels.scm` - Thunar keyboard shortcuts
- `~/.config/Thunar/uca.xml` - Thunar custom actions
- `~/.config/mako/config` - Mako notification settings

### Font Configuration
- `~/.config/fontconfig/fonts.conf` - Font rendering settings
- `~/.config/fontconfig/conf.d/99-voidance-fonts.conf` - Font configuration symlink

### Desktop Integration
- `~/.local/share/applications/` - Desktop entry files
- `~/.config/autostart/` - Autostart applications
- `~/.config/mimeapps.list` - File type associations
- `~/.config/defaults.list` - Default applications

## Utilities and Scripts

### Test Scripts
- `test-ghostty-functionality.sh` - Ghostty functionality tests
- `test-thunar-functionality.sh` - Thunar functionality tests
- `test-mako-functionality.sh` - Mako functionality tests
- `test-fonts.sh` - Font configuration tests
- `test-all-applications.sh` - Comprehensive test suite

### Setup Scripts
- `setup-desktop-applications.sh` - Install all applications
- `setup-ghostty-integration.sh` - Ghostty integration
- `setup-thunar-integration.sh` - Thunar integration
- `setup-mako-integration.sh` - Mako integration
- `setup-fonts.sh` - Font configuration

### Utility Scripts
- `setup-file-associations.sh` - File type associations
- `notification-control.sh` - Mako notification control
- `test-fonts.sh` - Font testing utilities

## Educational Features

### Configuration Comments
All configuration files include detailed comments explaining:
- Purpose of each setting
- Reasoning behind chosen values
- Customization options
- Learning tips

### Transparency
- Clear file organization
- Comprehensive documentation
- Educational comments in configurations
- Testing utilities for validation

### Customization Guidance
- Examples for common modifications
- Performance optimization tips
- Accessibility considerations
- Troubleshooting guidance

## Performance Optimizations

### Terminal (Ghostty)
- GPU acceleration enabled
- Optimized font rendering
- Efficient tab management
- Wayland native performance

### File Manager (Thunar)
- Lightweight GTK interface
- Efficient file operations
- Optimized thumbnail generation
- Fast startup times

### Notifications (Mako)
- Minimal resource usage
- Efficient notification grouping
- Fast rendering
- Low memory footprint

### Font Rendering
- Optimized hinting settings
- Efficient caching
- Balanced antialiasing
- Display-specific optimizations

## Integration Features

### Wayland Support
- All applications are Wayland-native
- Proper protocol support
- Efficient compositing
- Modern input handling

### Desktop Environment
- Seamless integration with Niri compositor
- Consistent theming
- Unified keyboard shortcuts
- Coordinated startup

### File Associations
- Comprehensive MIME type support
- Intelligent fallback handling
- User-friendly defaults
- Easy customization

## Troubleshooting

### Common Issues
1. **Applications not starting**: Check if packages are installed
2. **Fonts not rendering**: Update font cache with `fc-cache -fv`
3. **Notifications not showing**: Check if mako is running
4. **File associations broken**: Update MIME database

### Testing
Run the comprehensive test suite:
```bash
./test-all-applications.sh
```

### Logs and Debugging
- Check application logs for errors
- Use test scripts to identify issues
- Review configuration files for syntax errors
- Verify package installations

## Next Steps

1. Run the comprehensive test suite to verify installation
2. Customize configurations to your preferences
3. Install additional applications as needed
4. Set up your preferred themes and wallpapers
5. Configure additional input devices and peripherals

## Support

For issues and questions:
- Review the educational comments in configuration files
- Run the appropriate test scripts for diagnostics
- Check the troubleshooting guides in documentation
- Refer to the application-specific documentation
EOF
    
    log "✓ Installation summary created"
}

# Function to verify complete integration
verify_complete_integration() {
    log "Verifying complete desktop applications integration"
    
    # Check all configuration files
    local config_files=(
        "$CONFIG_DIR/desktop/desktop-environment.json"
        "$CONFIG_DIR/desktop/applications/ghostty/config"
        "$CONFIG_DIR/desktop/applications/thunar/thunarrc"
        "$CONFIG_DIR/desktop/applications/mako/config"
        "$CONFIG_DIR/desktop/fontconfig/fonts.conf"
    )
    
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            success "Configuration file exists: $(basename "$config_file")"
        else
            failure "Configuration file missing: $(basename "$config_file")"
        fi
    done
    
    # Check all test scripts
    local test_scripts=(
        "$CONFIG_DIR/desktop/test-all-applications.sh"
        "$SCRIPT_DIR/test-ghostty-functionality.sh"
        "$SCRIPT_DIR/test-thunar-functionality.sh"
        "$SCRIPT_DIR/test-mako-functionality.sh"
        "$SCRIPT_DIR/test-fonts.sh"
    )
    
    for test_script in "${test_scripts[@]}"; do
        if [ -f "$test_script" ] && [ -x "$test_script" ]; then
            success "Test script available: $(basename "$test_script")"
        else
            failure "Test script missing or not executable: $(basename "$test_script")"
        fi
    done
    
    # Check all setup scripts
    local setup_scripts=(
        "$SCRIPT_DIR/setup-desktop-applications.sh"
        "$SCRIPT_DIR/setup-ghostty-integration.sh"
        "$SCRIPT_DIR/setup-thunar-integration.sh"
        "$SCRIPT_DIR/setup-mako-integration.sh"
        "$SCRIPT_DIR/setup-fonts.sh"
    )
    
    for setup_script in "${setup_scripts[@]}"; do
        if [ -f "$setup_script" ] && [ -x "$setup_script" ]; then
            success "Setup script available: $(basename "$setup_script")"
        else
            failure "Setup script missing or not executable: $(basename "$setup_script")"
        fi
    done
}

# Main integration function
main() {
    log "Starting complete desktop applications integration"
    
    create_desktop_environment_config
    create_comprehensive_test_suite
    create_installation_summary
    verify_complete_integration
    
    log "✓ Complete desktop applications integration finished successfully"
    log ""
    log "Next steps:"
    log "1. Run './test-all-applications.sh' to verify installation"
    log "2. Review 'installation-summary.md' for detailed information"
    log "3. Customize configurations as needed"
    log "4. Start using your Voidance desktop environment!"
}

# Handle script arguments
case "${1:-}" in
    "config")
        create_desktop_environment_config
        ;;
    "tests")
        create_comprehensive_test_suite
        ;;
    "summary")
        create_installation_summary
        ;;
    "verify")
        verify_complete_integration
        ;;
    *)
        main
        ;;
esac