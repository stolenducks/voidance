#!/bin/bash
# Font Configuration Test Suite
# Tests font installation, configuration, and rendering

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

# Function to test font installation
test_font_installation() {
    log "Testing font installation"
    
    # Check if Montserrat is installed
    if fc-list | grep -i "Montserrat" >/dev/null 2>&1; then
        success "Montserrat font is installed"
    else
        failure "Montserrat font not found"
    fi
    
    # Check if Inconsolata is installed
    if fc-list | grep -i "Inconsolata" >/dev/null 2>&1; then
        success "Inconsolata font is installed"
    else
        failure "Inconsolata font not found"
    fi
    
    # Check font packages
    local font_packages=(
        "ttf-montserrat"
        "ttf-inconsolata"
    )
    
    for package in "${font_packages[@]}"; do
        if pacman -Qi "$package" >/dev/null 2>&1; then
            success "Font package installed: $package"
        else
            failure "Font package not installed: $package"
        fi
    done
}

# Function to test font configuration
test_font_configuration() {
    log "Testing font configuration"
    
    local config_file="$HOME/.config/fontconfig/fonts.conf"
    
    if [ -f "$config_file" ]; then
        success "Font configuration file exists"
        
        # Test configuration syntax
        if grep -q "Montserrat" "$config_file"; then
            success "Montserrat font configured"
        else
            failure "Montserrat font not configured"
        fi
        
        if grep -q "Inconsolata" "$config_file"; then
            success "Inconsolata font configured"
        else
            failure "Inconsolata font not configured"
        fi
        
        if grep -q "antialias" "$config_file"; then
            success "Antialiasing configured"
        else
            failure "Antialiasing not configured"
        fi
        
        if grep -q "hinting" "$config_file"; then
            success "Font hinting configured"
        else
            failure "Font hinting not configured"
        fi
    else
        failure "Font configuration file not found"
    fi
    
    # Check conf.d directory
    local conf_d_dir="$HOME/.config/fontconfig/conf.d"
    if [ -d "$conf_d_dir" ]; then
        success "Font configuration conf.d directory exists"
        
        # Check for symlink
        if [ -L "$conf_d_dir/99-voidance-fonts.conf" ]; then
            success "Font configuration symlink exists"
        else
            failure "Font configuration symlink not found"
        fi
    else
        failure "Font configuration conf.d directory not found"
    fi
}

# Function to test font matching
test_font_matching() {
    log "Testing font matching"
    
    if command -v fc-match >/dev/null 2>&1; then
        # Test sans-serif matching
        local sans_match=$(fc-match "sans-serif" 2>/dev/null | head -n1 || echo "failed")
        if [[ "$sans_match" == *"Montserrat"* ]] || [[ "$sans_match" == *"montserrat"* ]]; then
            success "Sans-serif matches Montserrat: $sans_match"
        else
            failure "Sans-serif doesn't match Montserrat: $sans_match"
        fi
        
        # Test monospace matching
        local mono_match=$(fc-match "monospace" 2>/dev/null | head -n1 || echo "failed")
        if [[ "$mono_match" == *"Inconsolata"* ]] || [[ "$mono_match" == *"inconsolata"* ]]; then
            success "Monospace matches Inconsolata: $mono_match"
        else
            failure "Monospace doesn't match Inconsolata: $mono_match"
        fi
        
        # Test serif matching
        local serif_match=$(fc-match "serif" 2>/dev/null | head -n1 || echo "failed")
        success "Serif match: $serif_match"
    else
        skip "fc-match not available - cannot test font matching"
    fi
}

# Function to test font directories
test_font_directories() {
    log "Testing font directories"
    
    local font_dirs=(
        "$HOME/.local/share/fonts"
        "$HOME/.config/fontconfig"
        "$HOME/.config/fontconfig/conf.d"
    )
    
    for dir in "${font_dirs[@]}"; do
        if [ -d "$dir" ]; then
            success "Font directory exists: $dir"
        else
            failure "Font directory missing: $dir"
        fi
    done
}

# Function to test font cache
test_font_cache() {
    log "Testing font cache"
    
    if command -v fc-cache >/dev/null 2>&1; then
        # Test cache update
        if fc-cache -fv >/dev/null 2>&1; then
            success "Font cache can be updated"
        else
            failure "Font cache update failed"
        fi
        
        # Check cache status
        local cache_dir="$HOME/.cache/fontconfig"
        if [ -d "$cache_dir" ]; then
            success "Font cache directory exists"
            
            # Check for cache files
            local cache_files=$(find "$cache_dir" -name "*.cache-*" 2>/dev/null | wc -l)
            if [ "$cache_files" -gt 0 ]; then
                success "Font cache files exist ($cache_files files)"
            else
                failure "No font cache files found"
            fi
        else
            failure "Font cache directory not found"
        fi
    else
        skip "fc-cache not available - cannot test font cache"
    fi
}

# Function to test application font settings
test_application_fonts() {
    log "Testing application font settings"
    
    # Test Ghostty font configuration
    local ghostty_config="$CONFIG_DIR/desktop/applications/ghostty/config"
    if [ -f "$ghostty_config" ]; then
        if grep -q "font-family = Inconsolata" "$ghostty_config"; then
            success "Ghostty configured with Inconsolata"
        else
            failure "Ghostty not configured with Inconsolata"
        fi
    else
        failure "Ghostty configuration not found"
    fi
    
    # Test mako font configuration
    local mako_config="$CONFIG_DIR/desktop/applications/mako/config"
    if [ -f "$mako_config" ]; then
        if grep -q "font=Montserrat" "$mako_config"; then
            success "Mako configured with Montserrat"
        else
            failure "Mako not configured with Montserrat"
        fi
    else
        failure "Mako configuration not found"
    fi
}

# Function to test font rendering settings
test_rendering_settings() {
    log "Testing font rendering settings"
    
    local config_file="$HOME/.config/fontconfig/fonts.conf"
    
    if [ -f "$config_file" ]; then
        # Test antialiasing
        if grep -q '<edit name="antialias".*<bool>true</bool>' "$config_file"; then
            success "Antialiasing enabled"
        else
            failure "Antialiasing not enabled"
        fi
        
        # Test hinting
        if grep -q '<edit name="hinting".*<bool>true</bool>' "$config_file"; then
            success "Font hinting enabled"
        else
            failure "Font hinting not enabled"
        fi
        
        # Test subpixel rendering
        if grep -q '<edit name="rgba".*<const>rgb</const>' "$config_file"; then
            success "Subpixel rendering (RGB) enabled"
        else
            failure "Subpixel rendering not enabled"
        fi
        
        # Test autohinting
        if grep -q '<edit name="autohint".*<bool>true</bool>' "$config_file"; then
            success "Autohinting enabled"
        else
            failure "Autohinting not enabled"
        fi
    else
        failure "Cannot test rendering settings - configuration file missing"
    fi
}

# Function to test font utilities
test_font_utilities() {
    log "Testing font utilities"
    
    local utils_dir="$CONFIG_DIR/desktop/utils"
    
    # Test font test script
    if [ -f "$utils_dir/test-fonts.sh" ]; then
        success "Font test script exists"
        
        if [ -x "$utils_dir/test-fonts.sh" ]; then
            success "Font test script is executable"
        else
            failure "Font test script is not executable"
        fi
    else
        failure "Font test script not found"
    fi
    
    # Test font info script
    if [ -f "$utils_dir/font-info.sh" ]; then
        success "Font info script exists"
        
        if [ -x "$utils_dir/font-info.sh" ]; then
            success "Font info script is executable"
        else
            failure "Font info script is not executable"
        fi
    else
        failure "Font info script not found"
    fi
}

# Function to test font substitution
test_font_substitution() {
    log "Testing font substitution"
    
    local config_file="$HOME/.config/fontconfig/fonts.conf"
    
    if [ -f "$config_file" ]; then
        # Test Helvetica substitution
        if grep -q '<test name="family"><string>Helvetica</string>' "$config_file"; then
            success "Helvetica substitution configured"
        else
            failure "Helvetica substitution not configured"
        fi
        
        # Test Arial substitution
        if grep -q '<test name="family"><string>Arial</string>' "$config_file"; then
            success "Arial substitution configured"
        else
            failure "Arial substitution not configured"
        fi
        
        # Test Consolas substitution
        if grep -q '<test name="family"><string>Consolas</string>' "$config_file"; then
            success "Consolas substitution configured"
        else
            failure "Consolas substitution not configured"
        fi
    else
        failure "Cannot test font substitution - configuration file missing"
    fi
}

# Function to test performance characteristics
test_performance() {
    log "Testing performance characteristics"
    
    # Test font matching performance
    if command -v fc-match >/dev/null 2>&1; then
        local start_time=$(date +%s%N)
        fc-match "sans-serif" >/dev/null 2>&1
        fc-match "monospace" >/dev/null 2>&1
        fc-match "serif" >/dev/null 2>&1
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        
        if [ $duration -lt 100 ]; then
            success "Font matching performance: ${duration}ms (excellent)"
        elif [ $duration -lt 200 ]; then
            success "Font matching performance: ${duration}ms (good)"
        elif [ $duration -lt 500 ]; then
            success "Font matching performance: ${duration}ms (acceptable)"
        else
            failure "Font matching performance: ${duration}ms (slow)"
        fi
    else
        skip "fc-match not available - cannot test performance"
    fi
    
    # Test configuration file size
    local config_file="$HOME/.config/fontconfig/fonts.conf"
    if [ -f "$config_file" ]; then
        local size=$(stat -c%s "$config_file" 2>/dev/null || echo "0")
        local lines=$(wc -l < "$config_file")
        
        success "Configuration file: $lines lines, $size bytes"
    else
        failure "Cannot test configuration file size - file missing"
    fi
}

# Function to generate test report
generate_report() {
    log "Generating test report"
    
    echo ""
    echo "=========================================="
    echo "Font Configuration Test Report"
    echo "=========================================="
    echo "Tests Passed:  $TESTS_PASSED"
    echo "Tests Failed:  $TESTS_FAILED"
    echo "Tests Skipped: $TESTS_SKIPPED"
    echo "Total Tests:   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✓ All tests passed! Font configuration is ready."
        return 0
    else
        echo "✗ Some tests failed. Please review the issues above."
        return 1
    fi
}

# Main test function
main() {
    log "Starting font configuration tests"
    
    # Run all tests
    test_font_installation
    test_font_configuration
    test_font_matching
    test_font_directories
    test_font_cache
    test_application_fonts
    test_rendering_settings
    test_font_substitution
    test_font_utilities
    test_performance
    
    # Generate report
    generate_report
}

# Handle script arguments
case "${1:-}" in
    "installation")
        test_font_installation
        ;;
    "configuration")
        test_font_configuration
        ;;
    "matching")
        test_font_matching
        ;;
    "cache")
        test_font_cache
        ;;
    "performance")
        test_performance
        ;;
    *)
        main
        ;;
esac