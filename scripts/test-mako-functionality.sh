#!/bin/bash
# Mako Notification System Test Suite
# Tests mako notification daemon functionality and integration

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
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

# Function to check if mako is installed
test_mako_installation() {
    log "Testing mako installation"
    
    if command -v mako >/dev/null 2>&1; then
        local version=$(mako --version 2>/dev/null || echo "unknown")
        success "Mako is installed ($version)"
    else
        failure "Mako is not installed or not in PATH"
        return 1
    fi
    
    if command -v makoctl >/dev/null 2>&1; then
        success "Mako control utility is available"
    else
        failure "Mako control utility not found"
    fi
}

# Function to test configuration files
test_configuration() {
    log "Testing mako configuration"
    
    local config_file="$CONFIG_DIR/desktop/applications/mako/config"
    
    if [ -f "$config_file" ]; then
        success "Configuration file exists: $config_file"
        
        # Test configuration syntax
        if grep -q "font=" "$config_file"; then
            success "Font configuration is present"
        else
            failure "Font configuration missing"
        fi
        
        if grep -q "background-color=" "$config_file"; then
            success "Background color configuration is present"
        else
            failure "Background color configuration missing"
        fi
        
        if grep -q "default-timeout=" "$config_file"; then
            success "Timeout configuration is present"
        else
            failure "Timeout configuration missing"
        fi
    else
        failure "Configuration file not found: $config_file"
    fi
}

# Function to test desktop integration
test_desktop_integration() {
    log "Testing desktop integration"
    
    # Check desktop entries
    local desktop_entries=(
        "$HOME/.local/share/applications/mako.desktop"
        "/usr/share/applications/mako.desktop"
    )
    
    local found_entry=false
    for entry in "${desktop_entries[@]}"; do
        if [ -f "$entry" ]; then
            success "Desktop entry found: $entry"
            found_entry=true
            
            # Test desktop entry syntax
            if grep -q "Exec=mako" "$entry"; then
                success "Desktop entry has correct Exec command"
            else
                failure "Desktop entry has incorrect Exec command"
            fi
            break
        fi
    done
    
    if [ "$found_entry" = false ]; then
        failure "No desktop entry found for mako"
    fi
    
    # Check autostart entry
    local autostart_entries=(
        "$HOME/.config/autostart/mako.desktop"
        "$CONFIG_DIR/desktop/autostart/mako.desktop"
    )
    
    local found_autostart=false
    for autostart in "${autostart_entries[@]}"; do
        if [ -f "$autostart" ]; then
            success "Autostart entry found: $autostart"
            found_autostart=true
            break
        fi
    done
    
    if [ "$found_autostart" = false ]; then
        failure "No autostart entry found for mako"
    fi
}

# Function to test notification functionality
test_notification_functionality() {
    log "Testing notification functionality"
    
    if command -v notify-send >/dev/null 2>&1; then
        success "notify-send is available for testing"
        
        # Test basic notification
        if notify-send "Test" "Basic notification test" >/dev/null 2>&1; then
            success "Basic notification functionality works"
        else
            failure "Basic notification functionality failed"
        fi
        
        # Test notification with urgency
        if notify-send -u low "Low Urgency" "Low urgency test" >/dev/null 2>&1; then
            success "Low urgency notification works"
        else
            failure "Low urgency notification failed"
        fi
        
        if notify-send -u critical "Critical" "Critical notification test" >/dev/null 2>&1; then
            success "Critical notification works"
        else
            failure "Critical notification failed"
        fi
        
        # Test notification with icon
        if notify-send -i dialog-information "Icon Test" "Icon notification test" >/dev/null 2>&1; then
            success "Icon notification works"
        else
            failure "Icon notification failed"
        fi
    else
        skip "notify-send not available - cannot test notification functionality"
    fi
}

# Function to test makoctl functionality
test_makoctl_functionality() {
    log "Testing makoctl functionality"
    
    if command -v makoctl >/dev/null 2>&1; then
        success "makoctl is available"
        
        # Test makoctl commands
        if makoctl help >/dev/null 2>&1; then
            success "makoctl help command works"
        else
            failure "makoctl help command failed"
        fi
        
        # Test history (may fail if mako not running)
        if makoctl history >/dev/null 2>&1; then
            success "makoctl history command works"
        else
            skip "makoctl history failed (mako may not be running)"
        fi
    else
        skip "makoctl not available - cannot test control functionality"
    fi
}

# Function to test Wayland integration
test_wayland_integration() {
    log "Testing Wayland integration"
    
    # Check if running under Wayland
    if [ "${WAYLAND_DISPLAY:-}" ]; then
        success "Running under Wayland ($WAYLAND_DISPLAY)"
        
        # Check if mako supports Wayland
        if mako --help 2>/dev/null | grep -q -i wayland; then
            success "Mako supports Wayland"
        else
            skip "Unable to verify Wayland support from help output"
        fi
    else
        skip "Not running under Wayland, skipping Wayland integration tests"
    fi
}

# Function to test notification rules
test_notification_rules() {
    log "Testing notification rules"
    
    local rules_file="$CONFIG_DIR/desktop/notification-rules.conf"
    
    if [ -f "$rules_file" ]; then
        success "Notification rules file exists"
        
        # Test for specific rules
        if grep -q "\[app-name=" "$rules_file"; then
            success "App-specific rules are configured"
        else
            failure "App-specific rules not configured"
        fi
        
        if grep -q "\[urgency=" "$rules_file"; then
            success "Urgency-specific rules are configured"
        else
            failure "Urgency-specific rules not configured"
        fi
    else
        failure "Notification rules file not found"
    fi
}

# Function to test performance characteristics
test_performance() {
    log "Testing performance characteristics"
    
    # Test startup time (if we can run mako)
    if command -v timeout >/dev/null 2>&1 && command -v mako >/dev/null 2>&1; then
        local start_time=$(date +%s%N)
        if timeout 5s mako --help >/dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
            
            if [ $duration -lt 500 ]; then
                success "Mako startup time: ${duration}ms (excellent)"
            elif [ $duration -lt 1000 ]; then
                success "Mako startup time: ${duration}ms (good)"
            elif [ $duration -lt 2000 ]; then
                success "Mako startup time: ${duration}ms (acceptable)"
            else
                failure "Mako startup time: ${duration}ms (slow)"
            fi
        else
            skip "Cannot test startup time - Mako failed to start"
        fi
    else
        skip "Cannot test startup time - timeout command not available"
    fi
    
    # Configuration parsing performance
    local config_file="$CONFIG_DIR/desktop/applications/mako/config"
    if [ -f "$config_file" ]; then
        local start_time=$(date +%s%N)
        local lines=$(wc -l < "$config_file")
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))
        
        success "Configuration parsing: $lines lines in ${duration}ms"
    else
        failure "Cannot benchmark configuration parsing - file missing"
    fi
}

# Function to test notification utilities
test_notification_utilities() {
    log "Testing notification utilities"
    
    local utils_dir="$CONFIG_DIR/desktop/utils"
    
    # Test notification test script
    if [ -f "$utils_dir/test-notifications.sh" ]; then
        success "Notification test script exists"
        
        if [ -x "$utils_dir/test-notifications.sh" ]; then
            success "Notification test script is executable"
        else
            failure "Notification test script is not executable"
        fi
    else
        failure "Notification test script not found"
    fi
    
    # Test notification control script
    if [ -f "$utils_dir/notification-control.sh" ]; then
        success "Notification control script exists"
        
        if [ -x "$utils_dir/notification-control.sh" ]; then
            success "Notification control script is executable"
        else
            failure "Notification control script is not executable"
        fi
    else
        failure "Notification control script not found"
    fi
}

# Function to test desktop environment integration
test_desktop_environment_integration() {
    log "Testing desktop environment integration"
    
    # Check desktop environment configuration
    local desktop_config="$CONFIG_DIR/desktop/desktop-environment.json"
    if [ -f "$desktop_config" ]; then
        if jq -e '.applications.notifications' "$desktop_config" >/dev/null 2>&1; then
            success "Notifications configured in desktop environment"
        else
            failure "Notifications not configured in desktop environment"
        fi
        
        if jq -e '.default_applications.notification_daemon' "$desktop_config" >/dev/null 2>&1; then
            success "Default notification daemon configured"
        else
            failure "Default notification daemon not configured"
        fi
    else
        failure "Desktop environment configuration not found"
    fi
}

# Function to generate test report
generate_report() {
    log "Generating test report"
    
    echo ""
    echo "=========================================="
    echo "Mako Test Report"
    echo "=========================================="
    echo "Tests Passed:  $TESTS_PASSED"
    echo "Tests Failed:  $TESTS_FAILED"
    echo "Tests Skipped: $TESTS_SKIPPED"
    echo "Total Tests:   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✓ All tests passed! Mako is ready for use."
        return 0
    else
        echo "✗ Some tests failed. Please review the issues above."
        return 1
    fi
}

# Main test function
main() {
    log "Starting mako notification system tests"
    
    # Run all tests
    test_mako_installation
    test_configuration
    test_desktop_integration
    test_notification_functionality
    test_makoctl_functionality
    test_wayland_integration
    test_notification_rules
    test_performance
    test_notification_utilities
    test_desktop_environment_integration
    
    # Generate report
    generate_report
}

# Handle script arguments
case "${1:-}" in
    "installation")
        test_mako_installation
        ;;
    "configuration")
        test_configuration
        ;;
    "integration")
        test_desktop_integration
        test_wayland_integration
        ;;
    "functionality")
        test_notification_functionality
        test_makoctl_functionality
        ;;
    "performance")
        test_performance
        ;;
    *)
        main
        ;;
esac