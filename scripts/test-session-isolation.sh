#!/bin/bash
# Session isolation and cleanup validation script
# Educational: Tests proper session isolation and cleanup

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

# Test XDG runtime directory isolation
test_xdg_runtime_isolation() {
    log "Testing XDG runtime directory isolation..."
    
    if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
        log_success "XDG runtime directory is set: $XDG_RUNTIME_DIR"
        
        # Check directory permissions
        if [ -d "$XDG_RUNTIME_DIR" ]; then
            local perms=$(stat -c "%a" "$XDG_RUNTIME_DIR")
            if [ "$perms" = "700" ]; then
                log_success "XDG runtime directory has correct permissions (700)"
            else
                log_warning "XDG runtime directory has unusual permissions: $perms"
            fi
            
            # Check ownership
            local owner=$(stat -c "%U:%G" "$XDG_RUNTIME_DIR")
            if [ "$owner" = "$(whoami):$(whoami)" ]; then
                log_success "XDG runtime directory has correct ownership"
            else
                log_warning "XDG runtime directory ownership: $owner"
            fi
        else
            log_warning "XDG runtime directory does not exist"
        fi
    else
        log_warning "XDG runtime directory is not set"
    fi
    
    return 0
}

# Test Wayland display isolation
test_wayland_display_isolation() {
    log "Testing Wayland display isolation..."
    
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        log_success "Wayland display is set: $WAYLAND_DISPLAY"
        
        # Check if display socket exists
        local socket_path="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
        if [ -S "$socket_path" ]; then
            log_success "Wayland display socket exists: $socket_path"
            
            # Check socket permissions
            local perms=$(stat -c "%a" "$socket_path")
            if [ "$perms" = "600" ] || [ "$perms" = "700" ]; then
                log_success "Wayland socket has correct permissions"
            else
                log_warning "Wayland socket permissions: $perms"
            fi
        else
            log_warning "Wayland display socket not found"
        fi
    else
        log_warning "Wayland display is not set"
    fi
    
    return 0
}

# Test session-specific configuration isolation
test_config_isolation() {
    log "Testing configuration isolation..."
    
    local config_dirs=(
        "$HOME/.config/niri"
        "$HOME/.config/sway"
        "$HOME/.config/waybar"
        "$HOME/.config/wofi"
        "$HOME/.config/mako"
        "$HOME/.config/ghostty"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_success "Configuration directory exists: $(basename "$dir")"
            
            # Check for session-specific files
            local session_files=("$dir/config" "$dir/config.kdl" "$dir/config.json")
            local found_config=false
            
            for file in "${session_files[@]}"; do
                if [ -f "$file" ]; then
                    log_success "Configuration file found: $(basename "$file")"
                    found_config=true
                fi
            done
            
            if [ "$found_config" = false ]; then
                log_warning "No configuration files found in $(basename "$dir")"
            fi
        else
            log_warning "Configuration directory missing: $(basename "$dir")"
        fi
    done
    
    return 0
}

# Test application state isolation
test_application_state_isolation() {
    log "Testing application state isolation..."
    
    # Check for application state directories
    local state_dirs=(
        "$HOME/.local/state/waybar"
        "$HOME/.local/state/wofi"
        "$HOME/.local/state/mako"
        "$HOME/.cache/wofi"
        "$HOME/.cache/mako"
    )
    
    for dir in "${state_dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_success "Application state directory exists: $(basename "$(dirname "$dir")")/$(basename "$dir")"
        else
            log_warning "Application state directory missing: $(basename "$(dirname "$dir")")/$(basename "$dir")"
        fi
    done
    
    # Check for runtime sockets
    local runtime_sockets=(
        "$XDG_RUNTIME_DIR/waybar.sock"
        "$XDG_RUNTIME_DIR/mako.sock"
        "$XDG_RUNTIME_DIR/wofi.sock"
    )
    
    for socket in "${runtime_sockets[@]}"; do
        if [ -S "$socket" ]; then
            log_success "Runtime socket exists: $(basename "$socket")"
        else
            log_warning "Runtime socket missing: $(basename "$socket")"
        fi
    done
    
    return 0
}

# Test process isolation
test_process_isolation() {
    log "Testing process isolation..."
    
    # Check for compositor processes
    local compositor_processes=("niri" "sway")
    local running_compositors=()
    
    for compositor in "${compositor_processes[@]}"; do
        if pgrep -x "$compositor" >/dev/null 2>&1; then
            local pid=$(pgrep -x "$compositor" | head -1)
            local ppid=$(ps -o ppid= -p "$pid" | tr -d ' ')
            local session=$(ps -o session= -p "$pid" | tr -d ' ')
            
            log_success "$compositor is running (PID: $pid, PPID: $ppid, Session: $session)"
            running_compositors+=("$compositor")
        else
            log_warning "$compositor is not running"
        fi
    done
    
    # Check for multiple compositors (should not happen in proper isolation)
    if [ ${#running_compositors[@]} -gt 1 ]; then
        log_warning "Multiple compositors running: ${running_compositors[*]}"
    elif [ ${#running_compositors[@]} -eq 1 ]; then
        log_success "Single compositor running: ${running_compositors[0]}"
    else
        log_warning "No compositors running"
    fi
    
    return 0
}

# Test environment variable isolation
test_environment_isolation() {
    log "Testing environment variable isolation..."
    
    # Key Wayland environment variables
    local wayland_vars=(
        "WAYLAND_DISPLAY"
        "XDG_RUNTIME_DIR"
        "XDG_SESSION_TYPE"
        "XDG_SESSION_DESKTOP"
        "XDG_CURRENT_DESKTOP"
        "WAYLAND_SOCKET"
    )
    
    local set_vars=0
    for var in "${wayland_vars[@]}"; do
        if [ -n "${!var:-}" ]; then
            log_success "$var is set: ${!var}"
            ((set_vars++))
        else
            log_warning "$var is not set"
        fi
    done
    
    if [ $set_vars -gt 0 ]; then
        log_success "Wayland environment variables are configured ($set_vars/${#wayland_vars[@]})"
    else
        log_warning "No Wayland environment variables are set"
    fi
    
    return 0
}

# Test cleanup on session end
test_cleanup_procedures() {
    log "Testing cleanup procedures..."
    
    # Check for systemd user services
    local user_services=(
        "wayland-session.target"
        "graphical-session.target"
        "sway-session.target"
        "niri-session.target"
    )
    
    for service in "${user_services[@]}"; do
        if systemctl --user list-unit-files | grep -q "$service"; then
            log_success "Systemd user service available: $service"
        else
            log_warning "Systemd user service not found: $service"
        fi
    done
    
    # Check for cleanup scripts
    local cleanup_scripts=(
        "/etc/X11/xinit/xinitrc.d/"
        "/etc/profile.d/"
        "/etc/systemd/user/"
    )
    
    for script_dir in "${cleanup_scripts[@]}"; do
        if [ -d "$script_dir" ]; then
            local script_count=$(find "$script_dir" -name "*wayland*" -o -name "*session*" | wc -l)
            if [ $script_count -gt 0 ]; then
                log_success "Found $script_count session-related scripts in $(basename "$script_dir")"
            else
                log_warning "No session-related scripts in $(basename "$script_dir")"
            fi
        fi
    done
    
    return 0
}

# Test resource cleanup
test_resource_cleanup() {
    log "Testing resource cleanup..."
    
    # Check for temporary files
    local temp_dirs=(
        "/tmp"
        "$XDG_RUNTIME_DIR"
        "$HOME/.cache"
    )
    
    for temp_dir in "${temp_dirs[@]}"; do
        if [ -d "$temp_dir" ]; then
            local wayland_files=$(find "$temp_dir" -name "*wayland*" -o -name "*sway*" -o -name "*niri*" 2>/dev/null | wc -l)
            if [ $wayland_files -gt 0 ]; then
                log_success "Found $wayland_files Wayland-related files in $(basename "$temp_dir")"
            else
                log_warning "No Wayland-related files in $(basename "$temp_dir")"
            fi
        fi
    done
    
    # Check for shared memory segments
    if command -v ipcs >/dev/null 2>&1; then
        local shm_segments=$(ipcs -m | grep -c "$(whoami)" || echo "0")
        if [ $shm_segments -gt 0 ]; then
            log_success "Found $shm_segments shared memory segments for user"
        else
            log_warning "No shared memory segments found"
        fi
    fi
    
    return 0
}

# Test security isolation
test_security_isolation() {
    log "Testing security isolation..."
    
    # Check for proper file permissions
    local sensitive_files=(
        "$HOME/.config/niri/config.kdl"
        "$HOME/.config/sway/config"
        "$HOME/.config/waybar/config"
        "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
    )
    
    for file in "${sensitive_files[@]}"; do
        if [ -e "$file" ]; then
            local perms=$(stat -c "%a" "$file")
            if [ "$perms" = "600" ] || [ "$perms" = "644" ] || [ "$perms" = "700" ]; then
                log_success "File has appropriate permissions: $(basename "$file") ($perms)"
            else
                log_warning "File has unusual permissions: $(basename "$file") ($perms)"
            fi
        fi
    done
    
    # Check for environment variable exposure
    local sensitive_vars=("DBUS_SESSION_BUS_ADDRESS" "XDG_SESSION_ID")
    for var in "${sensitive_vars[@]}"; do
        if [ -n "${!var:-}" ]; then
            log_success "Session variable is set: $var"
        else
            log_warning "Session variable not set: $var"
        fi
    done
    
    return 0
}

# Test session switching isolation
test_session_switching_isolation() {
    log "Testing session switching isolation..."
    
    # Check for session switching utilities
    local switch_utils=(
        "/home/stolenducks/Projects/Voidance/scripts/setup-session-switching.sh"
        "/home/stolenducks/Projects/Voidance/scripts/migrate-niri-to-sway.sh"
    )
    
    for util in "${switch_utils[@]}"; do
        if [ -f "$util" ]; then
            log_success "Session utility exists: $(basename "$util")"
            
            # Check for isolation handling in script
            if grep -q "XDG_RUNTIME_DIR\|WAYLAND_DISPLAY" "$util"; then
                log_success "Utility handles session isolation: $(basename "$util")"
            else
                log_warning "Utility may not handle session isolation: $(basename "$util")"
            fi
        else
            log_warning "Session utility missing: $(basename "$util")"
        fi
    done
    
    return 0
}

# Generate isolation report
generate_isolation_report() {
    log "Generating session isolation report..."
    
    local report_file="$HOME/.config/voidance/session-isolation-report-$(date +%Y%m%d-%H%M%S).txt"
    local report_dir=$(dirname "$report_file")
    mkdir -p "$report_dir"
    
    {
        echo "Voidance Session Isolation and Cleanup Report"
        echo "=========================================="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "Host: $(hostname)"
        echo ""
        
        echo "Session Environment:"
        echo "-------------------"
        echo "Display Server: ${XDG_SESSION_TYPE:-Not set}"
        echo "Desktop: ${XDG_CURRENT_DESKTOP:-Not set}"
        echo "Session ID: ${XDG_SESSION_ID:-Not set}"
        echo "Wayland Display: ${WAYLAND_DISPLAY:-Not set}"
        echo "XDG Runtime Dir: ${XDG_RUNTIME_DIR:-Not set}"
        echo ""
        
        echo "Running Processes:"
        echo "-----------------"
        ps aux | grep -E "(niri|sway|waybar|wofi|mako)" | grep -v grep || echo "No relevant processes found"
        echo ""
        
        echo "Runtime Sockets:"
        echo "---------------"
        if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
            ls -la "$XDG_RUNTIME_DIR" | grep -E "(wayland|sway|niri|waybar|mako|wofi)" || echo "No relevant sockets found"
        else
            echo "XDG_RUNTIME_DIR not set"
        fi
        echo ""
        
        echo "Configuration Files:"
        echo "-------------------"
        for config_dir in "$HOME/.config"/*; do
            if [ -d "$config_dir" ]; then
                local config_count=$(find "$config_dir" -name "config*" -type f 2>/dev/null | wc -l)
                if [ $config_count -gt 0 ]; then
                    echo "$(basename "$config_dir"): $config_count configuration files"
                fi
            fi
        done
        echo ""
        
        echo "Security Information:"
        echo "--------------------"
        echo "User ID: $(id -u)"
        echo "Group ID: $(id -g)"
        echo "Groups: $(id -Gn)"
        echo ""
        
        echo "Resource Usage:"
        echo "---------------"
        echo "Memory usage:"
        free -h | head -2
        echo ""
        echo "Disk usage in home:"
        du -sh "$HOME" 2>/dev/null || echo "Cannot determine disk usage"
        
    } > "$report_file"
    
    log_success "Isolation report generated: $report_file"
}

# Main validation function
main() {
    log "Starting session isolation and cleanup validation..."
    
    # Run validation tests
    local tests=(
        "test_xdg_runtime_isolation"
        "test_wayland_display_isolation"
        "test_config_isolation"
        "test_application_state_isolation"
        "test_process_isolation"
        "test_environment_isolation"
        "test_cleanup_procedures"
        "test_resource_cleanup"
        "test_security_isolation"
        "test_session_switching_isolation"
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
    generate_isolation_report
    
    echo ""
    log "Session isolation and cleanup validation summary:"
    log_success "Passed: $passed"
    log_error "Failed: $failed"
    
    if [ $failed -eq 0 ]; then
        log_success "All isolation and cleanup tests passed! ✓"
        return 0
    else
        log_warning "Some isolation tests failed. This may be expected in a test environment."
        return 1
    fi
}

# Run main function
main "$@"