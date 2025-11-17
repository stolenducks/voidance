#!/bin/bash

# test-audio-functionality.sh
# Test audio functionality and device detection
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

log "Starting audio functionality tests..."
echo

# Test 1: Check if PipeWire packages are installed
run_test "PipeWire package installation" "xbps-query -S pipewire"
run_test "PipeWire Pulse package installation" "xbps-query -S pipewire-pulse"
run_test "WirePlumber package installation" "xbps-query -S wireplumber"
run_test "RTKit package installation" "xbps-query -S rtkit"

# Test 2: Check if audio service scripts exist
run_test "PipeWire service script exists" "test -x /etc/sv/pipewire/run"
run_test "PipeWire Pulse service script exists" "test -x /etc/sv/pipewire-pulse/run"
run_test "WirePlumber service script exists" "test -x /etc/sv/wireplumber/run"

# Test 3: Check if audio services are enabled
run_warning_test "PipeWire service enabled" "test -L /var/service/pipewire"
run_warning_test "PipeWire Pulse service enabled" "test -L /var/service/pipewire-pulse"
run_warning_test "WirePlumber service enabled" "test -L /var/service/wireplumber"

# Test 4: Check if audio services are running
run_warning_test "PipeWire service running" "sv status pipewire | grep -q 'run:'"
run_warning_test "PipeWire Pulse service running" "sv status pipewire-pulse | grep -q 'run:'"
run_warning_test "WirePlumber service running" "sv status wireplumber | grep -q 'run:'"

# Test 5: Check if audio binaries exist
run_test "PipeWire binary exists" "command -v pipewire"
run_test "PipeWire Pulse binary exists" "command -v pipewire-pulse"
run_test "WirePlumber binary exists" "command -v wireplumber"
run_test "wpctl binary exists" "command -v wpctl"

# Test 6: Check if audio group exists
run_test "Audio group exists" "getent group audio >/dev/null"

# Test 7: Check if audio configurations exist
run_test "PipeWire configuration exists" "test -f /etc/pipewire/pipewire.conf.d/voidance-desktop.conf"
run_test "PipeWire Pulse configuration exists" "test -f /etc/pipewire/pipewire-pulse.conf.d/voidance-pulse.conf"
run_test "WirePlumber configuration exists" "test -f /etc/wireplumber/wireplumber.conf"

# Test 8: Check if udev rules exist
run_test "Audio udev rules exist" "test -f /etc/udev/rules.d/99-audio.rules"

# Test 9: Check if limits configuration exists
run_test "Audio limits configuration exists" "test -f /etc/security/limits.d/99-audio.conf"

# Test 10: Check if required directories exist
run_test "PipeWire config directory exists" "test -d /etc/pipewire"
run_test "WirePlumber config directory exists" "test -d /etc/wireplumber"
run_test "PipeWire run directory exists" "test -d /var/run/pipewire"

# Test 11: Test audio functionality if services are running
if sv status pipewire 2>/dev/null | grep -q 'run:' && \
   sv status wireplumber 2>/dev/null | grep -q 'run:'; then
    
    # Test PipeWire connectivity
    run_warning_test "PipeWire daemon responding" "wpctl status >/dev/null 2>&1"
    
    # Test for audio devices
    run_warning_test "Audio devices detected" "wpctl status | grep -q 'Audio\\|Sink\\|Source'"
    
    # Test for default sink
    run_warning_test "Default audio sink available" "wpctl status | grep -q '\\*'"
    
    # Test ALSA devices
    run_warning_test "ALSA devices available" "aplay -l >/dev/null 2>&1"
    
    # Test speaker-test if available
    if command -v speaker-test >/dev/null 2>&1; then
        log "Testing audio output (2 seconds)..."
        if timeout 2s speaker-test -c 2 -t sine >/dev/null 2>&1; then
            success "Audio output test passed"
            ((TESTS_PASSED++))
        else
            warning "Audio output test failed (may be normal in headless environment)"
            ((TESTS_WARNED++))
        fi
    fi
else
    warning "Audio services not running - skipping functionality tests"
    ((TESTS_WARNED++))
fi

# Test 12: Check PulseAudio compatibility
if sv status pipewire-pulse 2>/dev/null | grep -q 'run:'; then
    run_warning_test "PulseAudio socket available" "test -S $XDG_RUNTIME_DIR/pulse/native 2>/dev/null || test -S /run/user/$(id -u)/pulse/native 2>/dev/null"
    
    if command -v pactl >/dev/null 2>&1; then
        run_warning_test "PulseAudio client working" "pactl info >/dev/null 2>&1"
    fi
fi

echo
log "Audio functionality test summary:"
echo "=============================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests warned: ${YELLOW}$TESTS_WARNED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "=============================="

# Show audio status if services are running
if sv status pipewire 2>/dev/null | grep -q 'run:'; then
    echo
    log "Current audio status:"
    echo "----------------------"
    if command -v wpctl >/dev/null 2>&1; then
        echo "PipeWire Status:"
        wpctl status 2>/dev/null || echo "  Unable to get PipeWire status"
        echo
        echo "Available Sinks:"
        wpctl sinks 2>/dev/null || echo "  Unable to get sink list"
        echo
        echo "Available Sources:"
        wpctl sources 2>/dev/null || echo "  Unable to get source list"
    fi
fi

# Overall result
if [ $TESTS_FAILED -eq 0 ]; then
    if [ $TESTS_WARNED -eq 0 ]; then
        success "All audio tests passed! ✓"
        echo
        log "Audio services are ready for use."
        log "You can now control audio with:"
        log "  wpctl set-volume @DEFAULT_SINK@ 50%  # Set volume"
        log "  wpctl set-mute @DEFAULT_SINK@ toggle  # Toggle mute"
        log "  pavucontrol  # GUI volume control"
        log "  speaker-test -c 2  # Test audio output"
        exit 0
    else
        warning "Some tests passed with warnings. Audio may need additional configuration."
        echo
        log "Common issues:"
        log "  - Start audio services: sv up pipewire pipewire-pulse wireplumber"
        log "  - Enable services: ln -s /etc/sv/pipewire /var/service/"
        log "  - Check audio devices: wpctl status"
        log "  - Test audio output: speaker-test -c 2"
        exit 1
    fi
else
    error "Some tests failed. Please check the configuration."
    echo
    log "Common issues:"
    log "  - Install audio packages: xbps-install -S pipewire pipewire-pulse wireplumber"
    log "  - Run setup script: ./scripts/setup-audio-permissions.sh"
    log "  - Enable services: ln -s /etc/sv/pipewire /var/service/"
    log "  - Start services: sv up pipewire pipewire-pulse wireplumber"
    log "  - Add user to audio group: usermod -aG audio <username>"
    exit 1
fi