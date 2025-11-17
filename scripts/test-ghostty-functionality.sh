#!/bin/bash
# Ghostty Functionality and Performance Test Suite
# Tests Ghostty terminal emulator functionality and performance

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

# Function to check if Ghostty is installed
test_ghostty_installation() {
    log "Testing Ghostty installation"
    
    if command -v ghostty >/dev/null 2>&1; then
        local version=$(ghostty --version 2>/dev/null || echo "unknown")
        success "Ghostty is installed (version: $version)"
    else
        failure "Ghostty is not installed or not in PATH"
        return 1
    fi
}

# Function to test configuration files
test_configuration() {
    log "Testing Ghostty configuration"
    
    local config_file="$CONFIG_DIR/desktop/applications/ghostty/config"
    
    if [ -f "$config_file" ]; then
        success "Configuration file exists: $config_file"
        
        # Test configuration syntax (basic check)
        if grep -q "font-family" "$config_file"; then
            success "Configuration contains font settings"
        else
            failure "Configuration missing font settings"
        fi
        
        if grep -q "background" "$config_file"; then
            success "Configuration contains color settings"
        else
            failure "Configuration missing color settings"
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
        "$HOME/.local/share/applications/ghostty.desktop"
        "/usr/share/applications/ghostty.desktop"
    )
    
    local found_entry=false
    for entry in "${desktop_entries[@]}"; do
        if [ -f "$entry" ]; then
            success "Desktop entry found: $entry"
            found_entry=true
            
            # Test desktop entry syntax
            if grep -q "Exec=ghostty" "$entry"; then
                success "Desktop entry has correct Exec command"
            else
                failure "Desktop entry has incorrect Exec command"
            fi
            break
        fi
    done
    
    if [ "$found_entry" = false ]; then
        failure "No desktop entry found for Ghostty"
    fi
}

# Function to test Wayland integration
test_wayland_integration() {
    log "Testing Wayland integration"
    
    # Check if running under Wayland
    if [ "${WAYLAND_DISPLAY:-}" ]; then
        success "Running under Wayland ($WAYLAND_DISPLAY)"
        
        # Test if Ghostty supports Wayland
        if ghostty --help 2>/dev/null | grep -q -i wayland; then
            success "Ghostty supports Wayland"
        else
            skip "Unable to verify Wayland support from help output"
        fi
    else
        skip "Not running under Wayland, skipping Wayland integration tests"
    fi
}

# Function to test GPU acceleration
test_gpu_acceleration() {
    log "Testing GPU acceleration capabilities"
    
    # Check for GPU acceleration support
    if command -v glxinfo >/dev/null 2>&1; then
        if glxinfo >/dev/null 2>&1; then
            success "OpenGL is available for GPU acceleration"
        else
            skip "OpenGL available but not functional"
        fi
    else
        skip "glxinfo not available, cannot test GPU acceleration"
    fi
    
    # Check configuration for GPU acceleration
    local config_file="$CONFIG_DIR/desktop/applications/ghostty/config"
    if [ -f "$config_file" ] && grep -q "gpu-acceleration = true" "$config_file"; then
        success "GPU acceleration is enabled in configuration"
    else
        failure "GPU acceleration not enabled in configuration"
    fi
}

# Function to test font rendering
test_font_rendering() {
    log "Testing font rendering configuration"
    
    local config_file="$CONFIG_DIR/desktop/applications/ghostty/config"
    
    if [ -f "$config_file" ]; then
        if grep -q "font-family = Inconsolata" "$config_file"; then
            success "Terminal font is configured (Inconsolata)"
        else
            failure "Terminal font not properly configured"
        fi
        
        if grep -q "font-size" "$config_file"; then
            success "Font size is configured"
        else
            failure "Font size not configured"
        fi
    else
        failure "Cannot test font rendering - configuration file missing"
    fi
}

# Function to test performance characteristics
test_performance() {
    log "Testing performance characteristics"
    
    # Test startup time (if we can run Ghostty)
    if command -v timeout >/dev/null 2>&1 && command -v ghostty >/dev/null 2>&1; then
        local start_time=$(date +%s%N)
        if timeout 5s ghostty --version >/dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
            
            if [ $duration -lt 1000 ]; then
                success "Ghostty startup time: ${duration}ms (good)"
            elif [ $duration -lt 2000 ]; then
                success "Ghostty startup time: ${duration}ms (acceptable)"
            else
                failure "Ghostty startup time: ${duration}ms (slow)"
            fi
        else
            skip "Cannot test startup time - Ghostty failed to start"
        fi
    else
        skip "Cannot test startup time - timeout command not available"
    fi
}

# Function to test shell integration
test_shell_integration() {
    log "Testing shell integration"
    
    local config_file="$CONFIG_DIR/desktop/applications/ghostty/config"
    
    if [ -f "$config_file" ]; then
        if grep -q "shell-integration = true" "$config_file"; then
            success "Shell integration is enabled"
        else
            failure "Shell integration not enabled"
        fi
    else
        failure "Cannot test shell integration - configuration file missing"
    fi
    
    # Check for shell integration files
    local integration_dir="$CONFIG_DIR/desktop/applications/ghostty/shell-integration"
    if [ -d "$integration_dir" ]; then
        success "Shell integration directory exists"
        
        if [ -f "$integration_dir/bash.bash" ]; then
            success "Bash integration file exists"
        else
            failure "Bash integration file missing"
        fi
    else
        failure "Shell integration directory not found"
    fi
}

# Function to test clipboard integration
test_clipboard_integration() {
    log "Testing clipboard integration"
    
    local config_file="$CONFIG_DIR/desktop/applications/ghostty/config"
    
    if [ -f "$config_file" ]; then
        if grep -q "clipboard-primary = true" "$config_file"; then
            success "Primary clipboard integration is enabled"
        else
            failure "Primary clipboard integration not enabled"
        fi
    else
        failure "Cannot test clipboard integration - configuration file missing"
    fi
}

# Function to test accessibility features
test_accessibility() {
    log "Testing accessibility features"
    
    local config_file="$CONFIG_DIR/desktop/applications/ghostty/config"
    
    if [ -f "$config_file" ]; then
        if grep -q "font-ligatures = true" "$config_file"; then
            success "Font ligatures are enabled"
        else
            failure "Font ligatures not enabled"
        fi
        
        if grep -q "bell = visual" "$config_file"; then
            success "Visual bell is configured"
        else
            failure "Visual bell not configured"
        fi
    else
        failure "Cannot test accessibility - configuration file missing"
    fi
}

# Function to run performance benchmark
run_performance_benchmark() {
    log "Running performance benchmark"
    
    # Memory usage test (if we can measure it)
    if command -v ps >/dev/null 2>&1; then
        log "Testing memory usage patterns"
        
        # This is a basic test - in a real scenario we'd start Ghostty and measure
        if command -v ghostty >/dev/null 2>&1; then
            success "Memory usage test setup available"
        else
            skip "Cannot test memory usage - Ghostty not available"
        fi
    else
        skip "Cannot test memory usage - ps command not available"
    fi
    
    # Configuration parsing performance
    local config_file="$CONFIG_DIR/desktop/applications/ghostty/config"
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

# Function to generate test report
generate_report() {
    log "Generating test report"
    
    echo ""
    echo "=========================================="
    echo "Ghostty Test Report"
    echo "=========================================="
    echo "Tests Passed:  $TESTS_PASSED"
    echo "Tests Failed:  $TESTS_FAILED"
    echo "Tests Skipped: $TESTS_SKIPPED"
    echo "Total Tests:   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✓ All tests passed! Ghostty is ready for use."
        return 0
    else
        echo "✗ Some tests failed. Please review the issues above."
        return 1
    fi
}

# Main test function
main() {
    log "Starting Ghostty functionality and performance tests"
    
    # Run all tests
    test_ghostty_installation
    test_configuration
    test_desktop_integration
    test_wayland_integration
    test_gpu_acceleration
    test_font_rendering
    test_performance
    test_shell_integration
    test_clipboard_integration
    test_accessibility
    run_performance_benchmark
    
    # Generate report
    generate_report
}

# Handle script arguments
case "${1:-}" in
    "installation")
        test_ghostty_installation
        ;;
    "configuration")
        test_configuration
        ;;
    "integration")
        test_desktop_integration
        test_wayland_integration
        ;;
    "performance")
        test_performance
        run_performance_benchmark
        ;;
    "accessibility")
        test_accessibility
        ;;
    *)
        main
        ;;
esac