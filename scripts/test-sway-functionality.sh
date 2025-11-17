#!/bin/bash
# Sway functionality test script for Voidance desktop environment
# Tests basic Sway installation and configuration

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

# Test Sway installation
test_sway_installation() {
    log "Testing Sway installation..."
    
    if command -v sway >/dev/null 2>&1; then
        local version=$(sway --version 2>/dev/null | head -n1 || echo "unknown")
        log_success "Sway is installed ($version)"
        return 0
    else
        log_error "Sway is not installed or not in PATH"
        return 1
    fi
}

# Test Sway dependencies
test_sway_dependencies() {
    log "Testing Sway dependencies..."
    
    local deps=("swaybg" "swayidle" "swaylock" "waybar" "wofi")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            log_success "$dep is available"
        else
            log_warning "$dep is missing"
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        log_success "All Sway dependencies are available"
        return 0
    else
        log_warning "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
}

# Test Sway configuration syntax
test_sway_config() {
    log "Testing Sway configuration syntax..."
    
    local config_file="/home/stolenducks/Projects/Voidance/config/desktop/sway/config"
    
    if [ ! -f "$config_file" ]; then
        log_error "Sway configuration file not found: $config_file"
        return 1
    fi
    
    # Test configuration syntax (dry run)
    if sway -c "$config_file" --validate 2>/dev/null; then
        log_success "Sway configuration syntax is valid"
        return 0
    else
        log_error "Sway configuration has syntax errors"
        sway -c "$config_file" --validate 2>&1 | head -10
        return 1
    fi
}

# Test Sway session file
test_sway_session() {
    log "Testing Sway session file..."
    
    local session_file="/home/stolenducks/Projects/Voidance/config/wayland-sessions/sway.desktop"
    
    if [ ! -f "$session_file" ]; then
        log_error "Sway session file not found: $session_file"
        return 1
    fi
    
    # Check session file format
    if grep -q "Exec=sway" "$session_file" && \
       grep -q "Name=" "$session_file" && \
       grep -q "Type=Application" "$session_file"; then
        log_success "Sway session file is properly formatted"
        return 0
    else
        log_error "Sway session file is missing required fields"
        return 1
    fi
}

# Test Wayland support
test_wayland_support() {
    log "Testing Wayland support..."
    
    # Check if we're running in a Wayland session
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        log_success "Wayland display is available: $WAYLAND_DISPLAY"
    else
        log_warning "Not currently running in Wayland session"
    fi
    
    # Check for Wayland libraries
    if ldconfig -p | grep -q "libwayland"; then
        log_success "Wayland libraries are available"
    else
        log_warning "Wayland libraries not found"
    fi
    
    return 0
}

# Test Xwayland support
test_xwayland_support() {
    log "Testing Xwayland support..."
    
    if command -v Xwayland >/dev/null 2>&1; then
        log_success "Xwayland is available"
        return 0
    else
        log_warning "Xwayland is not available (X11 applications may not work)"
        return 1
    fi
}

# Test input device detection
test_input_devices() {
    log "Testing input device detection..."
    
    # Check for common input devices
    local devices_found=0
    
    # Keyboard
    if [ -d /dev/input/by-path ] && ls /dev/input/by-path/*kbd* >/dev/null 2>&1; then
        log_success "Keyboard devices found"
        ((devices_found++))
    fi
    
    # Mouse/Touchpad
    if [ -d /dev/input/by-path ] && ls /dev/input/by-path/*mouse* /dev/input/by-path/*-event-mouse* >/dev/null 2>&1; then
        log_success "Mouse/touchpad devices found"
        ((devices_found++))
    fi
    
    if [ $devices_found -gt 0 ]; then
        log_success "Input devices are available ($devices_found types found)"
        return 0
    else
        log_warning "No input devices detected"
        return 1
    fi
}

# Test GPU support
test_gpu_support() {
    log "Testing GPU support..."
    
    # Check for GPU devices
    if lspci | grep -qi "vga\|3d\|display"; then
        log_success "GPU devices detected"
        
        # Check for specific GPU vendors
        if lspci | grep -qi "intel"; then
            log_success "Intel GPU detected"
        fi
        if lspci | grep -qi "amd\|radeon"; then
            log_success "AMD GPU detected"
        fi
        if lspci | grep -qi "nvidia"; then
            log_warning "NVIDIA GPU detected (may require proprietary drivers)"
        fi
        
        return 0
    else
        log_error "No GPU devices detected"
        return 1
    fi
}

# Test display server support
test_display_server() {
    log "Testing display server support..."
    
    # Check for required display server components
    local components=("seatd" "libinput")
    local missing_components=()
    
    for component in "${components[@]}"; do
        if command -v "$component" >/dev/null 2>&1 || ldconfig -p | grep -q "$component"; then
            log_success "$component is available"
        else
            log_warning "$component is not available"
            missing_components+=("$component")
        fi
    done
    
    if [ ${#missing_components[@]} -eq 0 ]; then
        log_success "All display server components are available"
        return 0
    else
        log_warning "Missing components: ${missing_components[*]}"
        return 1
    fi
}

# Performance test
test_performance() {
    log "Testing Sway performance..."
    
    # Test configuration loading time
    local start_time=$(date +%s%N)
    if sway -c "/home/stolenducks/Projects/Voidance/config/desktop/sway/config" --get-config >/dev/null 2>&1; then
        local end_time=$(date +%s%N)
        local load_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        log_success "Configuration loaded in ${load_time}ms"
        
        if [ $load_time -lt 100 ]; then
            log_success "Configuration loading is fast"
        else
            log_warning "Configuration loading is slow"
        fi
    else
        log_error "Failed to load configuration for performance test"
        return 1
    fi
    
    return 0
}

# Main test function
main() {
    log "Starting Sway functionality and performance tests"
    
    local tests=(
        "test_sway_installation"
        "test_sway_dependencies"
        "test_sway_config"
        "test_sway_session"
        "test_wayland_support"
        "test_xwayland_support"
        "test_input_devices"
        "test_gpu_support"
        "test_display_server"
        "test_performance"
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
    log "Sway test summary:"
    log_success "Passed: $passed"
    log_error "Failed: $failed"
    
    if [ $failed -eq 0 ]; then
        log_success "All Sway tests passed! ✓"
        return 0
    else
        log_error "Some Sway tests failed. Please check the installation."
        return 1
    fi
}

# Run main function
main "$@"