#!/bin/bash

# test-graphical-login.sh
# Test script for graphical login functionality
# Part of Voidance Linux system services

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    log "Running: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        success "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        error "$test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Warning test function
run_warning_test() {
    local test_name="$1"
    local test_command="$2"
    
    log "Running: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        success "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        warning "$test_name"
        ((TESTS_WARNED++))
        return 1
    fi
}

log "Starting graphical login functionality tests..."
echo

# Test 1: Check if SDDM is installed
run_test "SDDM package installation" "xbps-query -S sddm"

# Test 2: Check if SDDM service exists
run_test "SDDM service script exists" "test -x /etc/sv/sddm/run"

# Test 3: Check if SDDM service is enabled
run_warning_test "SDDM service enabled" "test -L /var/service/sddm"

# Test 4: Check if SDDM configuration exists
run_test "SDDM configuration file exists" "test -f /etc/sddm.conf.d/voidance.conf"

# Test 5: Check if Wayland session directory exists
run_test "Wayland sessions directory exists" "test -d /usr/share/wayland-sessions"

# Test 6: Check if niri session file exists
run_test "Niri Wayland session exists" "test -f /usr/share/wayland-sessions/niri.desktop"

# Test 7: Check if SDDM theme is installed
run_warning_test "SDDM theme installed" "xbps-query -S sddm-theme-breeze"

# Test 8: Check if elogind is running (required for session management)
run_warning_test "Elogind service running" "sv status elogind | grep -q 'run:'"

# Test 9: Check if dbus is running (required for session management)
run_warning_test "D-Bus service running" "sv status dbus | grep -q 'run:'"

# Test 10: Check if PAM configurations are in place
run_test "PAM system-session config exists" "test -f /etc/pam.d/system-session"
run_test "PAM SDDM config exists" "test -f /etc/pam.d/sddm"

# Test 11: Check if display manager group exists
run_test "Display manager group exists" "getent group sddm >/dev/null"

# Test 12: Check if SDDM configuration is valid
run_test "SDDM configuration syntax valid" "sddm --test-config"

# Test 13: Check if Wayland session file is valid
run_test "Niri session file syntax valid" "grep -q 'Name=Niri' /usr/share/wayland-sessions/niri.desktop"

# Test 14: Check if required directories exist
run_test "SDDM runtime directory exists" "test -d /var/lib/sddm"
run_test "SDDM state directory exists" "test -d /var/lib/sddm/.local/state/sddm"

echo
log "Graphical login test summary:"
echo "=============================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests warned: ${YELLOW}$TESTS_WARNED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "=============================="

# Overall result
if [ $TESTS_FAILED -eq 0 ]; then
    if [ $TESTS_WARNED -eq 0 ]; then
        success "All graphical login tests passed! ✓"
        echo
        log "Graphical login is ready for use."
        log "You can now enable SDDM with: ln -s /etc/sv/sddm /var/service/"
        log "Then reboot to see the graphical login screen."
        exit 0
    else
        warning "Some tests passed with warnings. System may need additional configuration."
        echo
        log "Check the warnings above and ensure services are running:"
        log "  sv status elogind"
        log "  sv status dbus"
        log "  sv status sddm"
        exit 1
    fi
else
    error "Some tests failed. Please check the configuration."
    echo
    log "Common issues:"
    log "  - Install missing packages: xbps-install -S sddm sddm-theme-breeze"
    log "  - Enable services: ln -s /etc/sv/sddm /var/service/"
    log "  - Start services: sv up elogind dbus sddm"
    log "  - Run setup scripts: ./scripts/setup-sddm.sh"
    exit 1
fi