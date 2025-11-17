#!/bin/bash

# test-idle-lock-functionality.sh
# Test idle management and screen locking functionality
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

log "Starting idle and lock functionality tests..."
echo

# Test 1: Check if idle packages are installed
run_test "swayidle package installation" "xbps-query -S swayidle"
run_test "swaylock package installation" "xbps-query -S swaylock"

# Test 2: Check if idle binaries exist
run_test "swayidle binary exists" "command -v swayidle"
run_test "swaylock binary exists" "command -v swaylock"

# Test 3: Check if configuration files exist
run_test "Idle management configuration exists" "test -f /etc/voidance/idle/config"
run_test "swaylock configuration exists" "test -f /etc/swaylock/config"

# Test 4: Check if configuration scripts exist
run_test "swayidle configuration script exists" "test -x /usr/share/voidance/idle/swayidle-config.sh"
run_test "Idle management startup script exists" "test -x /usr/share/voidance/idle/start-idle.sh"
run_test "Idle notification script exists" "test -x /usr/share/voidance/idle/notify-lock.sh"
run_test "Desktop integration script exists" "test -x /usr/share/voidance/idle/desktop-integration.sh"

# Test 5: Check if systemd user service exists
run_test "Systemd user service exists" "test -f /usr/lib/systemd/user/voidance-idle.service"

# Test 6: Check if required directories exist
run_test "Idle configuration directory exists" "test -d /etc/voidance/idle"
run_test "Idle scripts directory exists" "test -d /usr/share/voidance/idle"
run_test "swaylock configuration directory exists" "test -d /etc/swaylock"

# Test 7: Test configuration file syntax
run_test "Idle configuration syntax valid" "source /etc/voidance/idle/config && test -n \"\$IDLE_TIMEOUT\""
run_test "swaylock configuration syntax valid" "grep -q 'color=' /etc/swaylock/config"

# Test 8: Test script functionality
run_warning_test "swayidle configuration script works" "/usr/share/voidance/idle/swayidle-config.sh | grep -q 'swayidle'"
run_warning_test "Desktop integration script works" "/usr/share/voidance/idle/desktop-integration.sh --help >/dev/null 2>&1 || /usr/share/voidance/idle/desktop-integration.sh auto >/dev/null 2>&1"

# Test 9: Check if notification system is available
run_warning_test "notify-send available" "command -v notify-send"

# Test 10: Test swayidle functionality (if running in graphical session)
if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
    # Test swayidle help
    run_warning_test "swayidle help works" "swayidle --help >/dev/null 2>&1"
    
    # Test swaylock help
    run_warning_test "swaylock help works" "swaylock --help >/dev/null 2>&1"
    
    # Test if swayidle is already running
    run_warning_test "swayidle not already running" "! pgrep -x swayidle >/dev/null"
    
    # Test swayidle configuration generation
    if [ -f /etc/voidance/idle/config ]; then
        source /etc/voidance/idle/config
        run_warning_test "swayidle command generation" "/usr/share/voidance/idle/swayidle-config.sh | grep -q 'timeout $IDLE_TIMEOUT'"
    fi
else
    warning "No graphical session detected - skipping graphical tests"
    ((TESTS_WARNED++))
fi

# Test 11: Check power management integration
run_warning_test "upower available for battery detection" "command -v upower"
run_warning_test "Battery status readable" "test -r /sys/class/power_supply/BAT0/status || upower -e >/dev/null 2>&1"

# Test 12: Test configuration values
if [ -f /etc/voidance/idle/config ]; then
    source /etc/voidance/idle/config
    
    # Test required variables are set
    run_test "IDLE_TIMEOUT configured" "test -n \"\$IDLE_TIMEOUT\""
    run_test "LOCK_TIMEOUT configured" "test -n \"\$LOCK_TIMEOUT\""
    run_test "LOCK_COMMAND configured" "test -n \"\$LOCK_COMMAND\""
    
    # Test timeout values are reasonable
    run_warning_test "IDLE_TIMEOUT reasonable" "[ \"$IDLE_TIMEOUT\" -gt 60 ]"
    run_warning_test "LOCK_TIMEOUT reasonable" "[ \"$LOCK_TIMEOUT\" -gt \"$IDLE_TIMEOUT\" ]"
fi

# Test 13: Test swaylock configuration
if [ -f /etc/swaylock/config ]; then
    run_test "swaylock has color configured" "grep -q '^color=' /etc/swaylock/config"
    run_test "swaylock has font configured" "grep -q '^font=' /etc/swaylock/config"
    run_warning_test "swaylock has indicator enabled" "grep -q '^indicator$' /etc/swaylock/config"
fi

echo
log "Idle and lock functionality test summary:"
echo "=============================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests warned: ${YELLOW}$TESTS_WARNED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "=============================="

# Show configuration summary
if [ -f /etc/voidance/idle/config ]; then
    echo
    log "Current idle configuration:"
    echo "---------------------------"
    source /etc/voidance/idle/config
    echo "Idle timeout: ${IDLE_TIMEOUT}s ($(($IDLE_TIMEOUT / 60)) minutes)"
    echo "Lock timeout: ${LOCK_TIMEOUT}s ($(($LOCK_TIMEOUT / 60)) minutes)"
    echo "Lock enabled: $LOCK_ENABLED"
    echo "Screen off enabled: $SCREEN_OFF_ENABLED"
    echo "Suspend enabled: $SUSPEND_ENABLED"
    echo "Notifications enabled: $NOTIFY_ENABLED"
    if [ "$BATTERY_IDLE_ENABLED" = true ]; then
        echo "Battery idle management: enabled"
        echo "Battery idle timeout: ${BATTERY_IDLE_TIMEOUT}s ($(($BATTERY_IDLE_TIMEOUT / 60)) minutes)"
    fi
fi

# Overall result
if [ $TESTS_FAILED -eq 0 ]; then
    if [ $TESTS_WARNED -eq 0 ]; then
        success "All idle and lock tests passed! ✓"
        echo
        log "Idle management is ready for use."
        log "You can now:"
        log "  Start idle management: /usr/share/voidance/idle/start-idle.sh"
        log "  Lock screen manually: swaylock -f -c 000000"
        log "  Test idle detection: swayidle -w timeout 10 'echo \"Idle detected\"'"
        log "  Enable systemd service: systemctl --user enable voidance-idle.service"
        exit 0
    else
        warning "Some tests passed with warnings. Idle management may need additional configuration."
        echo
        log "Common issues:"
        log "  - Install notification daemon: xbps-install -S dunstify"
        log "  - Install power management: xbps-install -S upower"
        log "  - Start in graphical session: ensure WAYLAND_DISPLAY or DISPLAY is set"
        log "  - Test manually: swayidle -w timeout 10 'echo test'"
        exit 1
    fi
else
    error "Some tests failed. Please check the configuration."
    echo
    log "Common issues:"
    log "  - Install packages: xbps-install -S swayidle swaylock"
    log "  - Run setup script: ./scripts/setup-idle-management.sh"
    log "  - Check configuration: /etc/voidance/idle/config"
    log "  - Check permissions: ls -la /usr/share/voidance/idle/"
    exit 1
fi