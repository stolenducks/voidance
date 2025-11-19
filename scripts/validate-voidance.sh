#!/bin/bash
# Voidance Installation Validation Script
# Validates that Voidance installation is working correctly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[VALIDATE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    log_info "Testing: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Validate package installation
validate_packages() {
    log_info "Validating critical packages..."
    
    local critical_packages=(
        "niri"           # Wayland compositor
        "sddm"            # Display manager
        "NetworkManager"   # Network management
        "pipewire"         # Audio server
        "waybar"           # Status bar
        "wofi"             # Application launcher
        "thunar"           # File manager
        "ghostty"          # Terminal emulator
    )
    
    for package in "${critical_packages[@]}"; do
        run_test "Package: $package" "xbps-query $package"
    done
}

# Validate services
validate_services() {
    log_info "Validating system services..."
    
    local critical_services=(
        "dbus"             # System message bus
        "elogind"          # Session management
        "NetworkManager"    # Network management
    )
    
    for service in "${critical_services[@]}"; do
        run_test "Service: $service" "sv status $service"
    done
}

# Validate desktop environment
validate_desktop() {
    log_info "Validating desktop environment..."
    
    # Check if display manager is enabled
    run_test "SDDM enabled" "test -L /var/service/sddm"
    
    # Check if niri is available
    run_test "Niri compositor available" "command -v niri"
    
    # Check if Wayland utilities are available
    run_test "Wayland utilities" "command -v waybar && command -v wofi"
    
    # Check if basic desktop apps are available
    run_test "Desktop applications" "command -v thunar && command -v ghostty"
}

# Validate audio system
validate_audio() {
    log_info "Validating audio system..."
    
    # Check if PipeWire is running
    run_test "PipeWire running" "pactl info >/dev/null 2>&1"
    
    # Check if audio devices are available
    run_test "Audio devices available" "pactl list sinks >/dev/null 2>&1"
}

# Validate network connectivity
validate_network() {
    log_info "Validating network connectivity..."
    
    # Check if NetworkManager is working
    run_test "NetworkManager working" "nmcli general status >/dev/null 2>&1"
    
    # Check internet connectivity
    run_test "Internet connectivity" "ping -c 1 repo-default.voidlinux.org"
}

# Validate user environment
validate_user_env() {
    log_info "Validating user environment..."
    
    # Check if user directories exist
    local user_dirs=(
        ".config"
        ".local/share"
        "Desktop"
        "Documents"
        "Downloads"
    )
    
    for dir in "${user_dirs[@]}"; do
        run_test "User directory: $dir" "test -d ~/$dir"
    done
    
    # Check if XDG directories are set
    run_test "XDG runtime directory" "test -n \"\$XDG_RUNTIME_DIR\""
}

# Show validation summary
show_summary() {
    echo ""
    echo "==================================="
    echo "       Validation Summary"
    echo "==================================="
    echo ""
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Voidance is working correctly.${NC}"
        echo ""
        echo "Your Voidance installation is ready to use."
        echo "You can now reboot and enjoy your new desktop environment."
        return 0
    else
        echo -e "${RED}❌ Some tests failed. Please check the issues above.${NC}"
        echo ""
        echo "Common fixes:"
        echo "• Reboot the system to start all services"
        echo "• Check service status with: sv status [service-name]"
        echo "• Check package installation with: xbps-query [package-name]"
        echo "• Review installation log: /var/log/voidance-deployment.log"
        return 1
    fi
}

# Main validation function
main() {
    echo "Voidance Installation Validation"
    echo "=============================="
    echo ""
    
    validate_packages
    validate_services
    validate_desktop
    validate_audio
    validate_network
    validate_user_env
    
    show_summary
}

# Handle script arguments
case "${1:-full}" in
    "full"|"")
        main
        ;;
    "packages")
        validate_packages
        ;;
    "services")
        validate_services
        ;;
    "desktop")
        validate_desktop
        ;;
    "audio")
        validate_audio
        ;;
    "network")
        validate_network
        ;;
    "user")
        validate_user_env
        ;;
    "help"|"-h"|"--help")
        cat << EOF
Usage: $0 [full|packages|services|desktop|audio|network|user|help]

Commands:
  full      Run all validation tests (default)
  packages  Validate package installation
  services  Validate system services
  desktop   Validate desktop environment
  audio     Validate audio system
  network   Validate network connectivity
  user      Validate user environment
  help      Show this help message

EOF
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac