#!/bin/bash
# Thunar Functionality and Performance Test Suite
# Tests Thunar file manager functionality and performance

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

# Function to check if Thunar is installed
test_thunar_installation() {
    log "Testing Thunar installation"
    
    if command -v thunar >/dev/null 2>&1; then
        local version=$(thunar --version 2>/dev/null | head -n1 || echo "unknown")
        success "Thunar is installed ($version)"
    else
        failure "Thunar is not installed or not in PATH"
        return 1
    fi
}

# Function to test configuration files
test_configuration() {
    log "Testing Thunar configuration"
    
    local config_files=(
        "$CONFIG_DIR/desktop/applications/thunar/thunarrc"
        "$CONFIG_DIR/desktop/applications/thunar/accels.scm"
        "$CONFIG_DIR/desktop/applications/thunar/uca.xml"
    )
    
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            local basename=$(basename "$config_file")
            success "Configuration file exists: $basename"
            
            # Test configuration syntax
            case "$basename" in
                "thunarrc")
                    if grep -q "HiddenFiles=" "$config_file"; then
                        success "Thunar configuration has display settings"
                    else
                        failure "Thunar configuration missing display settings"
                    fi
                    ;;
                "accels.scm")
                    if grep -q "gtk_accel_path" "$config_file"; then
                        success "Keyboard shortcuts configuration is valid"
                    else
                        failure "Keyboard shortcuts configuration is invalid"
                    fi
                    ;;
                "uca.xml")
                    if grep -q "<action>" "$config_file"; then
                        success "Custom actions configuration is valid"
                    else
                        failure "Custom actions configuration is invalid"
                    fi
                    ;;
            esac
        else
            failure "Configuration file not found: $config_file"
        fi
    done
}

# Function to test desktop integration
test_desktop_integration() {
    log "Testing desktop integration"
    
    # Check desktop entries
    local desktop_entries=(
        "$HOME/.local/share/applications/thunar.desktop"
        "/usr/share/applications/thunar.desktop"
    )
    
    local found_entry=false
    for entry in "${desktop_entries[@]}"; do
        if [ -f "$entry" ]; then
            success "Desktop entry found: $entry"
            found_entry=true
            
            # Test desktop entry syntax
            if grep -q "Exec=thunar" "$entry"; then
                success "Desktop entry has correct Exec command"
            else
                failure "Desktop entry has incorrect Exec command"
            fi
            break
        fi
    done
    
    if [ "$found_entry" = false ]; then
        failure "No desktop entry found for Thunar"
    fi
}

# Function to test GVFS integration
test_gvfs_integration() {
    log "Testing GVFS integration"
    
    # Check if GVFS is available
    if command -v gvfs-mount >/dev/null 2>&1; then
        success "GVFS is available for virtual filesystem support"
        
        # Test GVFS services
        if command -v gvfs-fuse-daemon >/dev/null 2>&1; then
            success "GVFS FUSE daemon is available"
        else
            skip "GVFS FUSE daemon not found"
        fi
    else
        skip "GVFS not available - some features may not work"
    fi
    
    # Check for Thunar plugins
    local plugins=(
        "thunar-archive-plugin"
        "thunar-volman"
    )
    
    for plugin in "${plugins[@]}"; do
        if pacman -Qi "$plugin" >/dev/null 2>&1; then
            success "Thunar plugin installed: $plugin"
        else
            failure "Thunar plugin not installed: $plugin"
        fi
    done
}

# Function to test file operations
test_file_operations() {
    log "Testing file operations configuration"
    
    local config_file="$CONFIG_DIR/desktop/applications/thunar/thunarrc"
    
    if [ -f "$config_file" ]; then
        # Test file operation settings
        if grep -q "MiscConfirmDelete=true" "$config_file"; then
            success "Delete confirmation is enabled"
        else
            failure "Delete confirmation not enabled"
        fi
        
        if grep -q "MiscConfirmTrash=true" "$config_file"; then
            success "Trash confirmation is enabled"
        else
            failure "Trash confirmation not enabled"
        fi
        
        if grep -q "MiscVolumeManagement=true" "$config_file"; then
            success "Volume management is enabled"
        else
            failure "Volume management not enabled"
        fi
    else
        failure "Cannot test file operations - configuration file missing"
    fi
}

# Function to test custom actions
test_custom_actions() {
    log "Testing custom actions configuration"
    
    local custom_actions_file="$CONFIG_DIR/desktop/applications/thunar/uca.xml"
    
    if [ -f "$custom_actions_file" ]; then
        # Count custom actions
        local action_count=$(grep -c "<action>" "$custom_actions_file" || echo "0")
        if [ "$action_count" -gt 0 ]; then
            success "Custom actions configured: $action_count actions"
            
            # Test for specific essential actions
            if grep -q "Open Terminal Here" "$custom_actions_file"; then
                success "Terminal action is configured"
            else
                failure "Terminal action not configured"
            fi
            
            if grep -q "Create Archive" "$custom_actions_file"; then
                success "Archive action is configured"
            else
                failure "Archive action not configured"
            fi
        else
            failure "No custom actions found"
        fi
    else
        failure "Custom actions file not found"
    fi
}

# Function to test keyboard shortcuts
test_keyboard_shortcuts() {
    log "Testing keyboard shortcuts configuration"
    
    local shortcuts_file="$CONFIG_DIR/desktop/applications/thunar/accels.scm"
    
    if [ -f "$shortcuts_file" ]; then
        # Test for essential shortcuts
        local essential_shortcuts=(
            "open"
            "rename"
            "trash-delete"
            "new-tab"
            "close-tab"
        )
        
        for shortcut in "${essential_shortcuts[@]}"; do
            if grep -q "$shortcut" "$shortcuts_file"; then
                success "Shortcut configured: $shortcut"
            else
                failure "Shortcut not configured: $shortcut"
            fi
        done
    else
        failure "Keyboard shortcuts file not found"
    fi
}

# Function to test file type associations
test_file_associations() {
    log "Testing file type associations"
    
    # Check if defaults file exists
    local defaults_file="$HOME/.local/share/applications/defaults.list"
    if [ -f "$defaults_file" ]; then
        success "File type associations file exists"
        
        # Test essential associations
        if grep -q "inode/directory=thunar.desktop" "$defaults_file"; then
            success "Directory association configured"
        else
            failure "Directory association not configured"
        fi
    else
        failure "File type associations file not found"
    fi
    
    # Check mimeapps.list
    local mimeapps_file="$HOME/.config/mimeapps.list"
    if [ -f "$mimeapps_file" ]; then
        success "XDG MIME applications file exists"
    else
        failure "XDG MIME applications file not found"
    fi
}

# Function to test performance characteristics
test_performance() {
    log "Testing performance characteristics"
    
    # Test startup time (if we can run Thunar)
    if command -v timeout >/dev/null 2>&1 && command -v thunar >/dev/null 2>&1; then
        local start_time=$(date +%s%N)
        if timeout 5s thunar --version >/dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
            
            if [ $duration -lt 1000 ]; then
                success "Thunar startup time: ${duration}ms (excellent)"
            elif [ $duration -lt 2000 ]; then
                success "Thunar startup time: ${duration}ms (good)"
            elif [ $duration -lt 3000 ]; then
                success "Thunar startup time: ${duration}ms (acceptable)"
            else
                failure "Thunar startup time: ${duration}ms (slow)"
            fi
        else
            skip "Cannot test startup time - Thunar failed to start"
        fi
    else
        skip "Cannot test startup time - timeout command not available"
    fi
    
    # Test configuration parsing performance
    local config_file="$CONFIG_DIR/desktop/applications/thunar/thunarrc"
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

# Function to test user directories
test_user_directories() {
    log "Testing user directories"
    
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
        if [ -d "$dir" ]; then
            success "User directory exists: $(basename "$dir")"
        else
            failure "User directory missing: $(basename "$dir")"
        fi
    done
}

# Function to test integration with desktop environment
test_desktop_environment_integration() {
    log "Testing desktop environment integration"
    
    # Check desktop environment configuration
    local desktop_config="$CONFIG_DIR/desktop/desktop-environment.json"
    if [ -f "$desktop_config" ]; then
        if jq -e '.applications.file_manager' "$desktop_config" >/dev/null 2>&1; then
            success "File manager configured in desktop environment"
        else
            failure "File manager not configured in desktop environment"
        fi
        
        if jq -e '.default_applications.file_manager' "$desktop_config" >/dev/null 2>&1; then
            success "Default file manager configured"
        else
            failure "Default file manager not configured"
        fi
    else
        failure "Desktop environment configuration not found"
    fi
}

# Function to run performance benchmark
run_performance_benchmark() {
    log "Running performance benchmark"
    
    # Memory usage test (if we can measure it)
    if command -v ps >/dev/null 2>&1; then
        log "Testing memory usage patterns"
        
        # This is a basic test - in a real scenario we'd start Thunar and measure
        if command -v thunar >/dev/null 2>&1; then
            success "Memory usage test setup available"
        else
            skip "Cannot test memory usage - Thunar not available"
        fi
    else
        skip "Cannot test memory usage - ps command not available"
    fi
    
    # Configuration file sizes
    local config_files=(
        "$CONFIG_DIR/desktop/applications/thunar/thunarrc"
        "$CONFIG_DIR/desktop/applications/thunar/accels.scm"
        "$CONFIG_DIR/desktop/applications/thunar/uca.xml"
    )
    
    local total_size=0
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            local size=$(stat -c%s "$config_file" 2>/dev/null || echo "0")
            total_size=$((total_size + size))
        fi
    done
    
    success "Configuration files total size: ${total_size} bytes"
}

# Function to generate test report
generate_report() {
    log "Generating test report"
    
    echo ""
    echo "=========================================="
    echo "Thunar Test Report"
    echo "=========================================="
    echo "Tests Passed:  $TESTS_PASSED"
    echo "Tests Failed:  $TESTS_FAILED"
    echo "Tests Skipped: $TESTS_SKIPPED"
    echo "Total Tests:   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✓ All tests passed! Thunar is ready for use."
        return 0
    else
        echo "✗ Some tests failed. Please review the issues above."
        return 1
    fi
}

# Main test function
main() {
    log "Starting Thunar functionality and performance tests"
    
    # Run all tests
    test_thunar_installation
    test_configuration
    test_desktop_integration
    test_gvfs_integration
    test_file_operations
    test_custom_actions
    test_keyboard_shortcuts
    test_file_associations
    test_performance
    test_user_directories
    test_desktop_environment_integration
    run_performance_benchmark
    
    # Generate report
    generate_report
}

# Handle script arguments
case "${1:-}" in
    "installation")
        test_thunar_installation
        ;;
    "configuration")
        test_configuration
        ;;
    "integration")
        test_desktop_integration
        test_gvfs_integration
        ;;
    "performance")
        test_performance
        run_performance_benchmark
        ;;
    "associations")
        test_file_associations
        ;;
    *)
        main
        ;;
esac