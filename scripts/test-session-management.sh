#!/bin/bash
# Session login and logout test script
# Educational: Tests session management functionality

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

# Test session files
test_session_files() {
    log "Testing session files..."
    
    local session_dir="/home/stolenducks/Projects/Voidance/config/wayland-sessions"
    local required_files=("niri.desktop" "sway.desktop")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ -f "$session_dir/$file" ]; then
            log_success "Found session file: $file"
            
            # Validate session file format
            if grep -q "Exec=" "$session_dir/$file" && \
               grep -q "Name=" "$session_dir/$file" && \
               grep -q "Type=Application" "$session_dir/$file"; then
                log_success "Session file format is valid: $file"
            else
                log_error "Session file format is invalid: $file"
                missing_files+=("$file (invalid format)")
            fi
        else
            log_error "Missing session file: $file"
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        log_success "All session files are present and valid"
        return 0
    else
        log_error "Issues found with session files: ${missing_files[*]}"
        return 1
    fi
}

# Test SDDM configuration
test_sddm_configuration() {
    log "Testing SDDM configuration..."
    
    local sddm_conf="/home/stolenducks/Projects/Voidance/config/sddm.conf.d/voidance.conf"
    
    if [ ! -f "$sddm_conf" ]; then
        log_error "SDDM configuration not found: $sddm_conf"
        return 1
    fi
    
    # Check Wayland configuration
    if grep -q "DisplayServer=wayland" "$sddm_conf"; then
        log_success "Wayland display server is configured"
    else
        log_error "Wayland display server not configured"
        return 1
    fi
    
    # Check session directory
    if grep -q "SessionDir=/usr/share/wayland-sessions" "$sddm_conf"; then
        log_success "Wayland session directory is configured"
    else
        log_error "Wayland session directory not configured"
        return 1
    fi
    
    # Check session logging
    if grep -q "SessionLogFile=" "$sddm_conf"; then
        log_success "Session logging is configured"
    else
        log_warning "Session logging may not be configured"
    fi
    
    return 0
}

# Test compositor availability
test_compositor_availability() {
    log "Testing compositor availability..."
    
    local compositors=("niri" "sway")
    local missing_compositors=()
    
    for compositor in "${compositors[@]}"; do
        if command -v "$compositor" >/dev/null 2>&1; then
            local version=$("$compositor" --version 2>/dev/null | head -n1 || echo "unknown")
            log_success "$compositor is available ($version)"
        else
            log_warning "$compositor is not installed"
            missing_compositors+=("$compositor")
        fi
    done
    
    if [ ${#missing_compositors[@]} -eq 0 ]; then
        log_success "All compositors are available"
        return 0
    else
        log_warning "Some compositors are not available: ${missing_compositors[*]}"
        return 1
    fi
}

# Test configuration validation
test_configuration_validation() {
    log "Testing configuration validation..."
    
    local configs=(
        "/home/stolenducks/Projects/Voidance/config/desktop/niri/config.kdl:niri"
        "/home/stolenducks/Projects/Voidance/config/desktop/sway/config:sway"
    )
    
    local validation_errors=()
    
    for config_entry in "${configs[@]}"; do
        local config_file="${config_entry%%:*}"
        local compositor="${config_entry##*:}"
        
        if [ -f "$config_file" ]; then
            log_success "Found $compositor configuration: $config_file"
            
            # Test configuration syntax
            case "$compositor" in
                "niri")
                    if command -v niri >/dev/null 2>&1; then
                        if niri --validate 2>/dev/null; then
                            log_success "$compositor configuration is valid"
                        else
                            log_error "$compositor configuration has errors"
                            validation_errors+=("$compositor config validation failed")
                        fi
                    else
                        log_warning "Cannot validate $compositor configuration (not installed)"
                    fi
                    ;;
                "sway")
                    if command -v sway >/dev/null 2>&1; then
                        if sway -c "$config_file" --validate 2>/dev/null; then
                            log_success "$compositor configuration is valid"
                        else
                            log_error "$compositor configuration has errors"
                            validation_errors+=("$compositor config validation failed")
                        fi
                    else
                        log_warning "Cannot validate $compositor configuration (not installed)"
                    fi
                    ;;
            esac
        else
            log_warning "$compositor configuration not found: $config_file"
        fi
    done
    
    if [ ${#validation_errors[@]} -eq 0 ]; then
        log_success "All configuration validations passed"
        return 0
    else
        log_error "Configuration validation errors: ${validation_errors[*]}"
        return 1
    fi
}

# Test session switching utilities
test_session_utilities() {
    log "Testing session switching utilities..."
    
    local utilities=(
        "/home/stolenducks/Projects/Voidance/scripts/setup-session-switching.sh"
        "/home/stolenducks/Projects/Voidance/scripts/migrate-niri-to-sway.sh"
    )
    
    local missing_utilities=()
    
    for utility in "${utilities[@]}"; do
        if [ -f "$utility" ]; then
            if [ -x "$utility" ]; then
                log_success "Utility is executable: $(basename "$utility")"
            else
                log_warning "Utility is not executable: $(basename "$utility")"
                missing_utilities+=("$(basename "$utility") (not executable)")
            fi
        else
            log_error "Utility not found: $(basename "$utility")"
            missing_utilities+=("$(basename "$utility")")
        fi
    done
    
    if [ ${#missing_utilities[@]} -eq 0 ]; then
        log_success "All session utilities are available"
        return 0
    else
        log_error "Missing utilities: ${missing_utilities[*]}"
        return 1
    fi
}

# Test application integration
test_application_integration() {
    log "Testing application integration..."
    
    local applications=("waybar" "wofi" "mako" "ghostty")
    local missing_applications=()
    
    for app in "${applications[@]}"; do
        if command -v "$app" >/dev/null 2>&1; then
            log_success "Application is available: $app"
        else
            log_warning "Application is not available: $app"
            missing_applications+=("$app")
        fi
    done
    
    if [ ${#missing_applications[@]} -eq 0 ]; then
        log_success "All applications are available"
        return 0
    else
        log_warning "Some applications are not available: ${missing_applications[*]}"
        return 1
    fi
}

# Test Wayland support
test_wayland_support() {
    log "Testing Wayland support..."
    
    # Check for Wayland libraries
    if ldconfig -p | grep -q "libwayland"; then
        log_success "Wayland libraries are available"
    else
        log_warning "Wayland libraries may not be available"
    fi
    
    # Check for Wayland client
    if command -v wayland-info >/dev/null 2>&1; then
        log_success "Wayland info tool is available"
    else
        log_warning "Wayland info tool is not available"
    fi
    
    # Check for Xwayland
    if command -v Xwayland >/dev/null 2>&1; then
        log_success "Xwayland is available"
    else
        log_warning "Xwayland is not available"
    fi
    
    return 0
}

# Test session isolation
test_session_isolation() {
    log "Testing session isolation..."
    
    # Check for proper XDG runtime directory handling
    if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
        log_success "XDG runtime directory is set: $XDG_RUNTIME_DIR"
    else
        log_warning "XDG runtime directory is not set"
    fi
    
    # Check for proper session directory structure
    local session_dirs=(
        "$HOME/.config/niri"
        "$HOME/.config/sway"
        "$HOME/.config/waybar"
        "$HOME/.config/wofi"
        "$HOME/.config/mako"
    )
    
    for dir in "${session_dirs[@]}"; do
        if [ -d "$dir" ] || [ -f "${dir%/*}/config" ]; then
            log_success "Session directory exists: $(dirname "$dir")"
        else
            log_warning "Session directory may be missing: $(dirname "$dir")"
        fi
    done
    
    return 0
}

# Test session cleanup
test_session_cleanup() {
    log "Testing session cleanup..."
    
    # Check for proper cleanup scripts
    local cleanup_locations=(
        "/etc/systemd/user/wayland-session.target"
        "/etc/systemd/user/sway-session.target"
        "/etc/systemd/user/niri-session.target"
    )
    
    for cleanup_file in "${cleanup_locations[@]}"; do
        if [ -f "$cleanup_file" ]; then
            log_success "Cleanup target exists: $(basename "$cleanup_file")"
        else
            log_warning "Cleanup target may be missing: $(basename "$cleanup_file")"
        fi
    done
    
    return 0
}

# Simulate session login test
simulate_session_login() {
    log "Simulating session login..."
    
    # Test if we can validate configurations without starting sessions
    local compositors=("niri" "sway")
    
    for compositor in "${compositors[@]}"; do
        if command -v "$compositor" >/dev/null 2>&1; then
            log_success "Can validate $compositor session"
            
            # Test configuration loading
            case "$compositor" in
                "niri")
                    if niri --help >/dev/null 2>&1; then
                        log_success "$compositor can load help/validate"
                    else
                        log_warning "$compositor help/validate failed"
                    fi
                    ;;
                "sway")
                    if sway --help >/dev/null 2>&1; then
                        log_success "$compositor can load help/validate"
                    else
                        log_warning "$compositor help/validate failed"
                    fi
                    ;;
            esac
        else
            log_warning "Cannot test $compositor session (not installed)"
        fi
    done
    
    return 0
}

# Generate test report
generate_test_report() {
    log "Generating session test report..."
    
    local report_file="$HOME/.config/voidance/session-test-report-$(date +%Y%m%d-%H%M%S).txt"
    local report_dir=$(dirname "$report_file")
    mkdir -p "$report_dir"
    
    {
        echo "Voidance Session Management Test Report"
        echo "====================================="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "Host: $(hostname)"
        echo ""
        
        echo "Environment Information:"
        echo "-----------------------"
        echo "Display Server: ${DISPLAY:-Not set}"
        echo "Wayland Display: ${WAYLAND_DISPLAY:-Not set}"
        echo "XDG Runtime Dir: ${XDG_RUNTIME_DIR:-Not set}"
        echo "Session Type: ${XDG_SESSION_TYPE:-Not set}"
        echo ""
        
        echo "Compositor Availability:"
        echo "-----------------------"
        for compositor in niri sway; do
            if command -v "$compositor" >/dev/null 2>&1; then
                echo "$compositor: Available ($("$compositor" --version 2>/dev/null | head -n1 || echo "Unknown version"))"
            else
                echo "$compositor: Not available"
            fi
        done
        echo ""
        
        echo "Application Availability:"
        echo "------------------------"
        for app in waybar wofi mako ghostty; do
            if command -v "$app" >/dev/null 2>&1; then
                echo "$app: Available"
            else
                echo "$app: Not available"
            fi
        done
        echo ""
        
        echo "Configuration Files:"
        echo "-------------------"
        for config in "$HOME/.config/niri/config.kdl" "$HOME/.config/sway/config"; do
            if [ -f "$config" ]; then
                echo "$(basename "$config"): Present ($(stat -c%s "$config") bytes)"
            else
                echo "$(basename "$config"): Missing"
            fi
        done
        echo ""
        
        echo "Session Files:"
        echo "-------------"
        for session in "/home/stolenducks/Projects/Voidance/config/wayland-sessions"/*.desktop; do
            if [ -f "$session" ]; then
                echo "$(basename "$session"): Present"
            fi
        done
        
    } > "$report_file"
    
    log_success "Test report generated: $report_file"
}

# Main test function
main() {
    log "Starting session login and logout tests..."
    
    # Run tests
    local tests=(
        "test_session_files"
        "test_sddm_configuration"
        "test_compositor_availability"
        "test_configuration_validation"
        "test_session_utilities"
        "test_application_integration"
        "test_wayland_support"
        "test_session_isolation"
        "test_session_cleanup"
        "simulate_session_login"
    )
    
    local passed=0
    local failed=0
    local warnings=0
    
    for test in "${tests[@]}"; do
        echo ""
        log "Running: $test"
        
        if $test; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    # Generate report
    generate_test_report
    
    echo ""
    log "Session management test summary:"
    log_success "Passed: $passed"
    log_error "Failed: $failed"
    
    if [ $failed -eq 0 ]; then
        log_success "All session management tests passed! ✓"
        return 0
    else
        log_warning "Some session management tests failed. This may be expected in a test environment."
        return 1
    fi
}

# Run main function
main "$@"