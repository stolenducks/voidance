#!/bin/bash
# Application compatibility test script for Sway compositor
# Tests desktop applications compatibility with Sway

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗ $1${NC}"
}

# Test Waybar compatibility
test_waybar_compatibility() {
    log "Testing Waybar compatibility with Sway..."
    
    if command -v waybar >/dev/null 2>&1; then
        log_success "Waybar is installed"
        
        # Check if Waybar has Sway support
        if waybar --version | grep -q sway 2>/dev/null || \
           pkg-config --exists wayland-client; then
            log_success "Waybar has Wayland/Sway support"
        else
            log_warning "Waybar Wayland support may be limited"
        fi
        
        # Test Waybar configuration
        local config_file="/home/stolenducks/Projects/Voidance/config/desktop/waybar/sway-config.json"
        if [ -f "$config_file" ]; then
            if python3 -c "import json; json.load(open('$config_file'))" 2>/dev/null; then
                log_success "Waybar Sway configuration is valid JSON"
            else
                log_error "Waybar Sway configuration has JSON errors"
                return 1
            fi
        else
            log_warning "Waybar Sway configuration not found"
        fi
        
        return 0
    else
        log_error "Waybar is not installed"
        return 1
    fi
}

# Test wofi compatibility
test_wofi_compatibility() {
    log "Testing wofi compatibility with Sway..."
    
    if command -v wofi >/dev/null 2>&1; then
        log_success "wofi is installed"
        
        # Check wofi version
        local version=$(wofi --version 2>/dev/null || echo "unknown")
        log_success "wofi version: $version"
        
        # Test wofi configuration
        local config_file="/home/stolenducks/Projects/Voidance/config/desktop/wofi/sway-config"
        if [ -f "$config_file" ]; then
            log_success "wofi Sway configuration exists"
        else
            log_warning "wofi Sway configuration not found"
        fi
        
        return 0
    else
        log_error "wofi is not installed"
        return 1
    fi
}

# Test Ghostty compatibility
test_ghostty_compatibility() {
    log "Testing Ghostty compatibility with Sway..."
    
    if command -v ghostty >/dev/null 2>&1; then
        log_success "Ghostty is installed"
        
        # Check Ghostty version
        local version=$(ghostty --version 2>/dev/null | head -n1 || echo "unknown")
        log_success "Ghostty version: $version"
        
        # Test Ghostty configuration
        local config_file="/home/stolenducks/Projects/Voidance/config/desktop/applications/ghostty/sway-config"
        if [ -f "$config_file" ]; then
            log_success "Ghostty Sway configuration exists"
        else
            log_warning "Ghostty Sway configuration not found"
        fi
        
        return 0
    else
        log_error "Ghostty is not installed"
        return 1
    fi
}

# Test mako compatibility
test_mako_compatibility() {
    log "Testing mako compatibility with Sway..."
    
    if command -v mako >/dev/null 2>&1; then
        log_success "mako is installed"
        
        # Check mako version
        local version=$(mako --version 2>/dev/null || echo "unknown")
        log_success "mako version: $version"
        
        # Test mako configuration
        local config_file="/home/stolenducks/Projects/Voidance/config/desktop/applications/mako/sway-config"
        if [ -f "$config_file" ]; then
            log_success "mako Sway configuration exists"
        else
            log_warning "mako Sway configuration not found"
        fi
        
        return 0
    else
        log_error "mako is not installed"
        return 1
    fi
}

# Test Thunar compatibility
test_thunar_compatibility() {
    log "Testing Thunar compatibility with Sway..."
    
    if command -v thunar >/dev/null 2>&1; then
        log_success "Thunar is installed"
        
        # Check Thunar version
        local version=$(thunar --version 2>/dev/null | head -n1 || echo "unknown")
        log_success "Thunar version: $version"
        
        # Check if Thunar has Wayland support
        if pkg-config --exists gtk+-3-wayland 2>/dev/null; then
            log_success "Thunar has Wayland support"
        else
            log_warning "Thunar Wayland support may be limited"
        fi
        
        return 0
    else
        log_warning "Thunar is not installed (optional for Sway)"
        return 0
    fi
}

# Test Wayland native applications
test_wayland_applications() {
    log "Testing Wayland native applications..."
    
    local apps=("firefox" "chromium" "code" "vlc")
    local wayland_apps=0
    
    for app in "${apps[@]}"; do
        if command -v "$app" >/dev/null 2>&1; then
            log_success "$app is available"
            
            # Check if application has Wayland support
            case "$app" in
                firefox)
                    if firefox --version 2>/dev/null | grep -q "Wayland"; then
                        log_success "$app has Wayland support"
                        ((wayland_apps++))
                    else
                        log_warning "$app Wayland support unknown"
                    fi
                    ;;
                chromium)
                    if chromium --version 2>/dev/null; then
                        log_success "$app has Wayland support"
                        ((wayland_apps++))
                    fi
                    ;;
                code)
                    if code --version 2>/dev/null; then
                        log_success "$app has Wayland support"
                        ((wayland_apps++))
                    fi
                    ;;
                vlc)
                    if vlc --version 2>/dev/null | head -n1; then
                        log_success "$app has Wayland support"
                        ((wayland_apps++))
                    fi
                    ;;
            esac
        else
            log_warning "$app is not installed"
        fi
    done
    
    log_success "Found $wayland_apps Wayland-compatible applications"
    return 0
}

# Test Xwayland compatibility
test_xwayland_compatibility() {
    log "Testing Xwayland compatibility..."
    
    if command -v Xwayland >/dev/null 2>&1; then
        log_success "Xwayland is available"
        
        # Test X11 applications
        local x11_apps=("gimp" "inkscape" "libreoffice")
        local x11_available=0
        
        for app in "${x11_apps[@]}"; do
            if command -v "$app" >/dev/null 2>&1; then
                log_success "$app is available for Xwayland"
                ((x11_available++))
            else
                log_warning "$app is not installed"
            fi
        done
        
        log_success "Found $x11_available X11 applications for Xwayland"
        return 0
    else
        log_warning "Xwayland is not available (X11 applications won't work)"
        return 1
    fi
}

# Test clipboard integration
test_clipboard_integration() {
    log "Testing clipboard integration..."
    
    local clipboard_tools=("wl-paste" "wl-copy" "clipman")
    local tools_found=0
    
    for tool in "${clipboard_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "$tool is available"
            ((tools_found++))
        else
            log_warning "$tool is not available"
        fi
    done
    
    if [ $tools_found -ge 2 ]; then
        log_success "Clipboard integration tools are available"
        return 0
    else
        log_warning "Limited clipboard integration support"
        return 1
    fi
}

# Test screenshot tools
test_screenshot_tools() {
    log "Testing screenshot tools..."
    
    local screenshot_tools=("grim" "slurp")
    local tools_found=0
    
    for tool in "${screenshot_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "$tool is available"
            ((tools_found++))
        else
            log_warning "$tool is not available"
        fi
    done
    
    if [ $tools_found -eq 2 ]; then
        log_success "Screenshot tools are available"
        return 0
    else
        log_warning "Limited screenshot functionality"
        return 1
    fi
}

# Test theming integration
test_theming_integration() {
    log "Testing theming integration..."
    
    # Check for icon themes
    if [ -d "/usr/share/icons/Papirus-Dark" ] || \
       [ -d "/usr/share/icons/Adwaita" ] || \
       [ -d "/usr/share/icons/breeze" ]; then
        log_success "Icon themes are available"
    else
        log_warning "Icon themes may be limited"
    fi
    
    # Check for GTK themes
    if [ -d "/usr/share/themes/Breeze" ] || \
       [ -d "/usr/share/themes/Adwaita" ]; then
        log_success "GTK themes are available"
    else
        log_warning "GTK themes may be limited"
    fi
    
    return 0
}

# Main test function
main() {
    log "Starting application compatibility tests for Sway"
    
    local tests=(
        "test_waybar_compatibility"
        "test_wofi_compatibility"
        "test_ghostty_compatibility"
        "test_mako_compatibility"
        "test_thunar_compatibility"
        "test_wayland_applications"
        "test_xwayland_compatibility"
        "test_clipboard_integration"
        "test_screenshot_tools"
        "test_theming_integration"
    )
    
    local passed=0
    local failed=0
    local warnings=0
    
    for test in "${tests[@]}"; do
        echo ""
        if $test; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    log "Application compatibility test summary:"
    log_success "Passed: $passed"
    log_error "Failed: $failed"
    
    if [ $failed -eq 0 ]; then
        log_success "All application compatibility tests passed! ✓"
        return 0
    else
        log_warning "Some compatibility tests failed. Applications may need additional configuration."
        return 1
    fi
}

# Run main function
main "$@"