#!/bin/bash

# Desktop Environment Testing Script for Voidance Linux
# Tests desktop environment components and functionality

set -euo pipefail

# Configuration paths
SCRIPT_DIR="$(dirname "$0")"
CONFIG_DIR="$(dirname "$0")/../config"
TEST_RESULTS_DIR="/tmp/voidance-desktop-tests"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((TESTS_SKIPPED++))
}

# Test helper functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    
    ((TESTS_TOTAL++))
    log_test "Running: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name"
        return 1
    fi
}

check_file_exists() {
    local file_path="$1"
    local description="$2"
    
    ((TESTS_TOTAL++))
    log_test "Checking: $description"
    
    if [ -f "$file_path" ]; then
        log_pass "$description exists: $file_path"
        return 0
    else
        log_fail "$description missing: $file_path"
        return 1
    fi
}

check_command_exists() {
    local command="$1"
    local description="$2"
    
    ((TESTS_TOTAL++))
    log_test "Checking: $description"
    
    if command -v "$command" >/dev/null 2>&1; then
        log_pass "$description available: $command"
        return 0
    else
        log_fail "$description missing: $command"
        return 1
    fi
}

check_service_running() {
    local service="$1"
    local description="$2"
    
    ((TESTS_TOTAL++))
    log_test "Checking: $description"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        log_pass "$description is running: $service"
        return 0
    else
        log_fail "$description is not running: $service"
        return 1
    fi
}

# Package installation tests
test_package_installation() {
    log_info "=== Testing Package Installation ==="
    
    local packages=(
        "niri:Niri compositor"
        "waybar:Waybar status bar"
        "wofi:wofi launcher"
        "ghostty:Ghostty terminal"
        "wl-clipboard:Wayland clipboard"
        "grim:Screenshot tool"
        "slurp:Screen selection"
        "wf-recorder:Screen recorder"
        "swayidle:Idle manager"
        "swaylock:Screen lock"
    )
    
    for package_info in "${packages[@]}"; do
        local package=$(echo "$package_info" | cut -d: -f1)
        local description=$(echo "$package_info" | cut -d: -f2)
        
        if xbps-query - "$package" >/dev/null 2>&1; then
            log_pass "$description is installed: $package"
            ((TESTS_PASSED++))
        else
            log_fail "$description is not installed: $package"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))
    done
}

# Configuration file tests
test_configuration_files() {
    log_info "=== Testing Configuration Files ==="
    
    # System configuration files
    check_file_exists "/etc/xdg/niri/config.kdl" "Niri system configuration"
    check_file_exists "/etc/xdg/waybar/config" "Waybar system configuration"
    check_file_exists "/etc/xdg/waybar/style.css" "Waybar system style"
    check_file_exists "/etc/xdg/wofi/config" "wofi system configuration"
    check_file_exists "/etc/xdg/wofi/style.css" "wofi system style"
    check_file_exists "/etc/xdg/voidance/desktop-environment.json" "Desktop environment configuration"
    
    # Session files
    check_file_exists "/usr/share/wayland-sessions/niri.desktop" "Niri Wayland session"
    check_file_exists "/usr/bin/niri-session" "Niri session script"
    
    # Environment files
    check_file_exists "/etc/environment.d/voidance-desktop.conf" "System environment file"
    
    # User configuration files (if user exists)
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        local user_home="/home/$SUDO_USER"
        check_file_exists "$user_home/.config/niri/config.kdl" "User Niri configuration"
        check_file_exists "$user_home/.config/waybar/config" "User Waybar configuration"
        check_file_exists "$user_home/.config/wofi/config" "User wofi configuration"
        check_file_exists "$user_home/.config/voidance/environment" "User environment file"
    fi
}

# Command availability tests
test_command_availability() {
    log_info "=== Testing Command Availability ==="
    
    local commands=(
        "niri:Niri compositor"
        "niri-msg:Niri control utility"
        "waybar:Waybar status bar"
        "wofi:wofi launcher"
        "ghostty:Ghostty terminal"
        "wl-copy:Wayland clipboard copy"
        "wl-paste:Wayland clipboard paste"
        "grim:Screenshot tool"
        "slurp:Screen selection"
        "wf-recorder:Screen recorder"
        "swayidle:Idle manager"
        "swaylock:Screen lock"
        "pactl:Audio control"
        "pamixer:Audio mixer"
        "brightnessctl:Brightness control"
        "playerctl:Media control"
    )
    
    for command_info in "${commands[@]}"; do
        local command=$(echo "$command_info" | cut -d: -f1)
        local description=$(echo "$command_info" | cut -d: -f2)
        check_command_exists "$command" "$description"
    done
}

# Service status tests
test_service_status() {
    log_info "=== Testing Service Status ==="
    
    local services=(
        "elogind:Session management"
        "dbus:System message bus"
        "NetworkManager:Network management"
        "pipewire:Audio server"
        "pipewire-pulse:PulseAudio compatibility"
        "wireplumber:Audio session manager"
        "sddm:Display manager"
    )
    
    for service_info in "${services[@]}"; do
        local service=$(echo "$service_info" | cut -d: -f1)
        local description=$(echo "$service_info" | cut -d: -f2)
        check_service_running "$service" "$description"
    done
}

# Hardware compatibility tests
test_hardware_compatibility() {
    log_info "=== Testing Hardware Compatibility ==="
    
    # GPU detection
    ((TESTS_TOTAL++))
    log_test "Testing GPU detection"
    
    if lspci | grep -qi "vga\|display\|3d"; then
        log_pass "GPU detected"
        ((TESTS_PASSED++))
    else
        log_fail "No GPU detected"
        ((TESTS_FAILED++))
    fi
    
    # Input devices
    ((TESTS_TOTAL++))
    log_test "Testing input device detection"
    
    if [ -d /dev/input ] && [ "$(find /dev/input -name "event*" | wc -l)" -gt 0 ]; then
        log_pass "Input devices detected"
        ((TESTS_PASSED++))
    else
        log_fail "No input devices detected"
        ((TESTS_FAILED++))
    fi
    
    # Display detection
    ((TESTS_TOTAL++))
    log_test "Testing display detection"
    
    if [ -d /sys/class/drm ] && [ "$(find /sys/class/drm -name "card*" | wc -l)" -gt 0 ]; then
        log_pass "Display devices detected"
        ((TESTS_PASSED++))
    else
        log_fail "No display devices detected"
        ((TESTS_FAILED++))
    fi
    
    # Audio devices
    ((TESTS_TOTAL++))
    log_test "Testing audio device detection"
    
    if [ -d /dev/snd ] && [ "$(find /dev/snd -name "pcm*" | wc -l)" -gt 0 ]; then
        log_pass "Audio devices detected"
        ((TESTS_PASSED++))
    else
        log_fail "No audio devices detected"
        ((TESTS_FAILED++))
    fi
}

# Wayland compatibility tests
test_wayland_compatibility() {
    log_info "=== Testing Wayland Compatibility ==="
    
    # Check if running in Wayland session
    ((TESTS_TOTAL++))
    log_test "Testing Wayland session"
    
    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ "${WAYLAND_DISPLAY:-}" ]; then
        log_pass "Running in Wayland session"
        ((TESTS_PASSED++))
        
        # Test Wayland-specific functionality
        run_test "Wayland clipboard (wl-copy)" "echo 'test' | wl-copy"
        run_test "Wayland clipboard (wl-paste)" "wl-paste"
        run_test "Screenshot tool (grim)" "grim -t png /tmp/test-screenshot.png"
        run_test "Screen selection (slurp)" "echo 'test' | slurp -f '%f'"
        
        # Clean up test screenshot
        rm -f /tmp/test-screenshot.png
        
    else
        log_skip "Not running in Wayland session - skipping Wayland-specific tests"
        ((TESTS_SKIPPED++))
    fi
}

# Configuration validation tests
test_configuration_validation() {
    log_info "=== Testing Configuration Validation ==="
    
    # Test Niri configuration syntax
    if [ -f "/etc/xdg/niri/config.kdl" ]; then
        run_test "Niri configuration syntax" "niri --verify-config"
    else
        log_skip "Niri configuration not found - skipping syntax test"
        ((TESTS_SKIPPED++))
    fi
    
    # Test Waybar configuration syntax
    if [ -f "/etc/xdg/waybar/config" ]; then
        run_test "Waybar configuration syntax" "waybar --config /etc/xdg/waybar/config --validate"
    else
        log_skip "Waybar configuration not found - skipping syntax test"
        ((TESTS_SKIPPED++))
    fi
    
    # Test desktop environment configuration validation
    if command -v node >/dev/null 2>&1 && [ -f "$SCRIPT_DIR/validate-desktop-config.js" ]; then
        run_test "Desktop environment configuration validation" "node $SCRIPT_DIR/validate-desktop-config.js validate"
    else
        log_skip "Node.js or validation script not available - skipping config validation"
        ((TESTS_SKIPPED++))
    fi
}

# Performance tests
test_performance() {
    log_info "=== Testing Performance ==="
    
    # Test startup time (basic)
    ((TESTS_TOTAL++))
    log_test "Testing Niri startup time"
    
    if command -v niri >/dev/null 2>&1; then
        local start_time=$(date +%s%N)
        timeout 5s niri --help >/dev/null 2>&1 || true
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        
        if [ $duration -lt 3000 ]; then
            log_pass "Niri startup time: ${duration}ms"
            ((TESTS_PASSED++))
        else
            log_fail "Niri startup time too slow: ${duration}ms"
            ((TESTS_FAILED++))
        fi
    else
        log_fail "Niri command not available"
        ((TESTS_FAILED++))
    fi
    
    # Test memory usage (basic)
    ((TESTS_TOTAL++))
    log_test "Testing system memory usage"
    
    if [ -f /proc/meminfo ]; then
        local total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local available_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        local used_percent=$(( (total_mem - available_mem) * 100 / total_mem ))
        
        if [ $used_percent -lt 80 ]; then
            log_pass "Memory usage: ${used_percent}%"
            ((TESTS_PASSED++))
        else
            log_fail "Memory usage too high: ${used_percent}%"
            ((TESTS_FAILED++))
        fi
    else
        log_skip "Memory information not available"
        ((TESTS_SKIPPED++))
    fi
}

# Integration tests
test_integration() {
    log_info "=== Testing Integration ==="
    
    # Test session file
    if [ -f "/usr/share/wayland-sessions/niri.desktop" ]; then
        run_test "Niri session file validation" "desktop-file-validate /usr/share/wayland-sessions/niri.desktop"
    else
        log_skip "Niri session file not found"
        ((TESTS_SKIPPED++))
    fi
    
    # Test environment variables
    ((TESTS_TOTAL++))
    log_test "Testing environment variables"
    
    local env_vars=(
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_DESKTOP"
        "XDG_SESSION_TYPE"
    )
    
    local env_found=0
    for var in "${env_vars[@]}"; do
        if [ -n "${!var:-}" ]; then
            ((env_found++))
        fi
    done
    
    if [ $env_found -gt 0 ]; then
        log_pass "Environment variables found: $env_found/${#env_vars[@]}"
        ((TESTS_PASSED++))
    else
        log_fail "No environment variables found"
        ((TESTS_FAILED++))
    fi
    
    # Test desktop entry files
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        local user_home="/home/$SUDO_USER"
        local apps_dir="$user_home/.local/share/applications"
        
        if [ -d "$apps_dir" ]; then
            local desktop_files=("$apps_dir"/*.desktop)
            if [ -f "${desktop_files[0]}" ]; then
                run_test "Desktop entry file validation" "desktop-file-validate ${desktop_files[0]}"
            else
                log_skip "No desktop entry files found"
                ((TESTS_SKIPPED++))
            fi
        else
            log_skip "User applications directory not found"
            ((TESTS_SKIPPED++))
        fi
    fi
}

# Generate test report
generate_test_report() {
    log_info "=== Generating Test Report ==="
    
    mkdir -p "$TEST_RESULTS_DIR"
    local report_file="$TEST_RESULTS_DIR/desktop-test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
Voidance Desktop Environment Test Report
Generated on: $(date)

========================================
TEST SUMMARY
========================================
Total Tests: $TESTS_TOTAL
Passed: $TESTS_PASSED
Failed: $TESTS_FAILED
Skipped: $TESTS_SKIPPED
Success Rate: $(( TESTS_TOTAL > 0 ? (TESTS_PASSED * 100) / TESTS_TOTAL : 0 ))%

========================================
SYSTEM INFORMATION
========================================

EOF
    
    # Add system information
    {
        echo "Operating System: $(uname -s -r)"
        echo "Architecture: $(uname -m)"
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        echo "Session Type: ${XDG_SESSION_TYPE:-unknown}"
        echo "Desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
        echo ""
        
        if command -v lspci >/dev/null 2>&1; then
            echo "PCI Devices:"
            lspci | head -10
            echo ""
        fi
        
        if [ -f /proc/meminfo ]; then
            echo "Memory Information:"
            grep -E "(MemTotal|MemAvailable)" /proc/meminfo
            echo ""
        fi
        
        if command -v xbps-query >/dev/null 2>&1; then
            echo "Installed Desktop Packages:"
            xbps-query -s "niri|waybar|wofi|ghostty" | head -10
            echo ""
        fi
        
    } >> "$report_file"
    
    log_success "Test report generated: $report_file"
    echo "$report_file"
}

# Function to show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] COMMAND

Commands:
    all             Run all tests
    packages        Test package installation
    config          Test configuration files
    commands        Test command availability
    services        Test service status
    hardware        Test hardware compatibility
    wayland         Test Wayland compatibility
    validation      Test configuration validation
    performance     Test performance
    integration     Test integration
    report          Generate test report only
    help            Show this help message

Options:
    --user          Run tests for current user only
    --verbose       Show detailed output
    --quiet         Show minimal output
    --no-report     Skip report generation

Examples:
    $0 all                         # Run all tests
    $0 packages                    # Test package installation only
    $0 --verbose all               # Run all tests with detailed output
    $0 --user config               # Test user configuration only

EOF
}

# Main function
main() {
    local action="${1:-all}"
    local user_mode="${USER_MODE:-false}"
    local verbose="${VERBOSE:-false}"
    local quiet="${QUIET:-false}"
    local no_report="${NO_REPORT:-false}"
    
    # Initialize test counters
    TESTS_TOTAL=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_SKIPPED=0
    
    log_info "Voidance Desktop Environment Testing"
    log_info "=================================="
    
    case "$action" in
        "all")
            test_package_installation
            test_configuration_files
            test_command_availability
            test_service_status
            test_hardware_compatibility
            test_wayland_compatibility
            test_configuration_validation
            test_performance
            test_integration
            ;;
        "packages")
            test_package_installation
            ;;
        "config")
            test_configuration_files
            ;;
        "commands")
            test_command_availability
            ;;
        "services")
            test_service_status
            ;;
        "hardware")
            test_hardware_compatibility
            ;;
        "wayland")
            test_wayland_compatibility
            ;;
        "validation")
            test_configuration_validation
            ;;
        "performance")
            test_performance
            ;;
        "integration")
            test_integration
            ;;
        "report")
            generate_test_report
            exit 0
            ;;
        "help"|"--help"|"-h")
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown command '$action'"
            show_usage
            exit 1
            ;;
    esac
    
    # Show test summary
    echo ""
    log_info "=== Test Summary ==="
    log_info "Total Tests: $TESTS_TOTAL"
    log_success "Passed: $TESTS_PASSED"
    log_error "Failed: $TESTS_FAILED"
    log_warning "Skipped: $TESTS_SKIPPED"
    
    if [ $TESTS_TOTAL -gt 0 ]; then
        local success_rate=$(( (TESTS_PASSED * 100) / TESTS_TOTAL ))
        log_info "Success Rate: ${success_rate}%"
        
        if [ $TESTS_FAILED -eq 0 ]; then
            log_success "All tests passed! ✓"
        else
            log_error "Some tests failed! ✗"
        fi
    fi
    
    # Generate report
    if [ "$no_report" = "false" ]; then
        local report_file=$(generate_test_report)
        log_info "Detailed report: $report_file"
    fi
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            export USER_MODE=true
            shift
            ;;
        --verbose)
            export VERBOSE=true
            shift
            ;;
        --quiet)
            export QUIET=true
            shift
            ;;
        --no-report)
            export NO_REPORT=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Run main function with remaining arguments
main "$@"