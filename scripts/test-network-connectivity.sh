#!/bin/bash

# test-network-connectivity.sh
# Test network connectivity and NetworkManager service status
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

log "Starting network connectivity tests..."
echo

# Test 1: Check if NetworkManager package is installed
run_test "NetworkManager package installation" "xbps-query -S NetworkManager"

# Test 2: Check if NetworkManager service script exists
run_test "NetworkManager service script exists" "test -x /etc/sv/NetworkManager/run"

# Test 3: Check if NetworkManager service is enabled
run_warning_test "NetworkManager service enabled" "test -L /var/service/NetworkManager"

# Test 4: Check if NetworkManager service is running
run_warning_test "NetworkManager service running" "sv status NetworkManager | grep -q 'run:'"

# Test 5: Check if NetworkManager binary exists
run_test "NetworkManager binary exists" "command -v NetworkManager"

# Test 6: Check if nmcli binary exists
run_test "nmcli binary exists" "command -v nmcli"

# Test 7: Check if network groups exist
run_test "Network group exists" "getent group network >/dev/null"
run_test "Netdev group exists" "getent group netdev >/dev/null"

# Test 8: Check if NetworkManager configuration exists
run_test "NetworkManager configuration exists" "test -f /etc/NetworkManager/NetworkManager.conf"

# Test 9: Check if polkit rules exist
run_test "NetworkManager polkit rules exist" "test -f /etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager.rules"

# Test 10: Check if udev rules exist
run_test "Network udev rules exist" "test -f /etc/udev/rules.d/99-network.rules"

# Test 11: Check NetworkManager connectivity (if running)
if sv status NetworkManager 2>/dev/null | grep -q 'run:'; then
    run_test "NetworkManager connectivity check" "nmcli -t -f GENERAL.STATE device status | grep -q 'connected'"
    
    # Test 12: Check if any network devices are available
    run_warning_test "Network devices available" "nmcli device status | grep -q 'ethernet\\|wifi'"
    
    # Test 13: Test DNS resolution
    run_warning_test "DNS resolution working" "nslookup google.com >/dev/null 2>&1 || getent hosts google.com >/dev/null"
    
    # Test 14: Test internet connectivity
    run_warning_test "Internet connectivity" "ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1"
else
    warning "NetworkManager not running - skipping connectivity tests"
    ((TESTS_WARNED++))
fi

# Test 15: Check if required directories exist with proper permissions
run_test "NetworkManager config directory exists" "test -d /etc/NetworkManager"
run_test "NetworkManager system connections directory exists" "test -d /etc/NetworkManager/system-connections"
run_test "NetworkManager run directory exists" "test -d /var/run/NetworkManager"

# Test 16: Check directory permissions
run_test "System connections directory permissions" "test -rwx /etc/NetworkManager/system-connections"

echo
log "Network connectivity test summary:"
echo "=============================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests warned: ${YELLOW}$TESTS_WARNED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "=============================="

# Show network status if NetworkManager is running
if sv status NetworkManager 2>/dev/null | grep -q 'run:'; then
    echo
    log "Current network status:"
    echo "------------------------"
    if command -v nmcli >/dev/null 2>&1; then
        echo "Device Status:"
        nmcli device status 2>/dev/null || echo "  Unable to get device status"
        echo
        echo "Connection Status:"
        nmcli -t -f NAME,TYPE,DEVICE connection show 2>/dev/null || echo "  Unable to get connection status"
    fi
fi

# Overall result
if [ $TESTS_FAILED -eq 0 ]; then
    if [ $TESTS_WARNED -eq 0 ]; then
        success "All network tests passed! ✓"
        echo
        log "Network services are ready for use."
        log "You can now manage network connections with:"
        log "  nmcli device wifi list    # List WiFi networks"
        log "  nmcli device wifi connect <SSID>  # Connect to WiFi"
        log "  nmtui                    # Text interface"
        exit 0
    else
        warning "Some tests passed with warnings. Network may need additional configuration."
        echo
        log "Common issues:"
        log "  - Start NetworkManager: sv up NetworkManager"
        log "  - Enable NetworkManager: ln -s /etc/sv/NetworkManager /var/service/"
        log "  - Check device status: nmcli device status"
        log "  - Connect to network: nmcli device wifi connect <SSID>"
        exit 1
    fi
else
    error "Some tests failed. Please check the configuration."
    echo
    log "Common issues:"
    log "  - Install NetworkManager: xbps-install -S NetworkManager"
    log "  - Run setup script: ./scripts/setup-network-permissions.sh"
    log "  - Enable service: ln -s /etc/sv/NetworkManager /var/service/"
    log "  - Start service: sv up NetworkManager"
    exit 1
fi