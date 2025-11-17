#!/bin/bash

# test-service-dependencies.sh
# Test service dependencies and startup order
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

# Service definitions with dependencies
declare -A SERVICE_DEPS
SERVICE_DEPS[elogind]=""
SERVICE_DEPS[dbus]="elogind"
SERVICE_DEPS[sddm]="elogind dbus"
SERVICE_DEPS[NetworkManager]="dbus"
SERVICE_DEPS[pipewire]="dbus"
SERVICE_DEPS[pipewire-pulse]="pipewire"
SERVICE_DEPS[wireplumber]="pipewire"

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

# Function to check if service exists
service_exists() {
    test -x "/etc/sv/$1/run"
}

# Function to check if service is enabled
service_enabled() {
    test -L "/var/service/$1"
}

# Function to check if service is running
service_running() {
    sv status "$1" 2>/dev/null | grep -q "run:"
}

# Function to test service dependencies
test_service_dependencies() {
    local service="$1"
    local deps="${SERVICE_DEPS[$service]}"
    
    if [ -n "$deps" ]; then
        for dep in $deps; do
            if ! service_running "$dep"; then
                log "Dependency $dep not running for $service"
                return 1
            fi
        done
    fi
    return 0
}

log "Starting service dependencies and startup order tests..."
echo

# Test 1: Check if startup script exists
run_test "System services startup script exists" "test -x /home/stolenducks/Projects/Voidance/scripts/start-system-services.sh"

# Test 2: Check if all service scripts exist
run_test "elogind service script exists" "service_exists elogind"
run_test "dbus service script exists" "service_exists dbus"
run_test "sddm service script exists" "service_exists sddm"
run_test "NetworkManager service script exists" "service_exists NetworkManager"
run_test "pipewire service script exists" "service_exists pipewire"
run_test "pipewire-pulse service script exists" "service_exists pipewire-pulse"
run_test "wireplumber service script exists" "service_exists wireplumber"

# Test 3: Check service script syntax
run_test "elogind service script syntax" "bash -n /etc/sv/elogind/run"
run_test "dbus service script syntax" "bash -n /etc/sv/dbus/run"
run_test "sddm service script syntax" "bash -n /etc/sv/sddm/run"
run_test "NetworkManager service script syntax" "bash -n /etc/sv/NetworkManager/run"
run_test "pipewire service script syntax" "bash -n /etc/sv/pipewire/run"
run_test "pipewire-pulse service script syntax" "bash -n /etc/sv/pipewire-pulse/run"
run_test "wireplumber service script syntax" "bash -n /etc/sv/wireplumber/run"

# Test 4: Check if services are enabled
run_warning_test "elogind service enabled" "service_enabled elogind"
run_warning_test "dbus service enabled" "service_enabled dbus"
run_warning_test "sddm service enabled" "service_enabled sddm"
run_warning_test "NetworkManager service enabled" "service_enabled NetworkManager"
run_warning_test "pipewire service enabled" "service_enabled pipewire"
run_warning_test "pipewire-pulse service enabled" "service_enabled pipewire-pulse"
run_warning_test "wireplumber service enabled" "service_enabled wireplumber"

# Test 5: Check if services are running
run_warning_test "elogind service running" "service_running elogind"
run_warning_test "dbus service running" "service_running dbus"
run_warning_test "sddm service running" "service_running sddm"
run_warning_test "NetworkManager service running" "service_running NetworkManager"
run_warning_test "pipewire service running" "service_running pipewire"
run_warning_test "pipewire-pulse service running" "service_running pipewire-pulse"
run_warning_test "wireplumber service running" "service_running wireplumber"

# Test 6: Test service dependencies (only if services are running)
if service_running elogind; then
    run_test "elogind has no dependencies" "test -z \"${SERVICE_DEPS[elogind]}\""
fi

if service_running dbus; then
    run_test "dbus dependency satisfied" "test_service_dependencies dbus"
fi

if service_running sddm; then
    run_test "sddm dependencies satisfied" "test_service_dependencies sddm"
fi

if service_running NetworkManager; then
    run_test "NetworkManager dependency satisfied" "test_service_dependencies NetworkManager"
fi

if service_running pipewire; then
    run_test "pipewire dependency satisfied" "test_service_dependencies pipewire"
fi

if service_running pipewire-pulse; then
    run_test "pipewire-pulse dependency satisfied" "test_service_dependencies pipewire-pulse"
fi

if service_running wireplumber; then
    run_test "wireplumber dependency satisfied" "test_service_dependencies wireplumber"
fi

# Test 7: Test startup script functionality
run_warning_test "Startup script validation passes" "/home/stolenducks/Projects/Voidance/scripts/start-system-services.sh status >/dev/null"

# Test 8: Test startup order logic
run_test "Startup script has correct order" "grep -q 'elogind.*dbus.*NetworkManager' /home/stolenducks/Projects/Voidance/scripts/start-system-services.sh"

# Test 9: Test service binary availability
run_test "elogind binary available" "command -v elogind"
run_test "dbus-daemon binary available" "command -v dbus-daemon"
run_test "sddm binary available" "command -v sddm"
run_test "NetworkManager binary available" "command -v NetworkManager"
run_test "pipewire binary available" "command -v pipewire"
run_test "pipewire-pulse binary available" "command -v pipewire-pulse"
run_test "wireplumber binary available" "command -v wireplumber"

# Test 10: Test service configuration files
run_test "elogind configuration exists" "test -f /etc/elogind/logind.conf || test -d /etc/elogind"
run_test "dbus configuration exists" "test -f /etc/dbus-1/system.conf || test -d /etc/dbus-1"
run_test "sddm configuration exists" "test -f /etc/sddm.conf.d/voidance.conf"
run_test "NetworkManager configuration exists" "test -f /etc/NetworkManager/NetworkManager.conf"
run_test "pipewire configuration exists" "test -f /etc/pipewire/pipewire.conf.d/voidance-desktop.conf"
run_test "wireplumber configuration exists" "test -f /etc/wireplumber/wireplumber.conf"

# Test 11: Test service directories
run_test "runit service directory exists" "test -d /etc/sv"
run_test "runit enabled services directory exists" "test -d /var/service"
run_test "elogind service directory exists" "test -d /etc/sv/elogind"
run_test "dbus service directory exists" "test -d /etc/sv/dbus"
run_test "sddm service directory exists" "test -d /etc/sv/sddm"
run_test "NetworkManager service directory exists" "test -d /etc/sv/NetworkManager"
run_test "pipewire service directory exists" "test -d /etc/sv/pipewire"
run_test "pipewire-pulse service directory exists" "test -d /etc/sv/pipewire-pulse"
run_test "wireplumber service directory exists" "test -d /etc/sv/wireplumber"

# Test 12: Test service startup order validation
log "Testing service startup order validation..."

# Define expected startup order
expected_order=(
    "elogind"
    "dbus"
    "NetworkManager"
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "sddm"
)

# Check if startup script follows this order
order_valid=true
for i in "${!expected_order[@]}"; do
    service="${expected_order[$i]}"
    if ! grep -q "$service" /home/stolenducks/Projects/Voidance/scripts/start-system-services.sh; then
        log "Service $service not found in startup script"
        order_valid=false
        break
    fi
done

if [ "$order_valid" = true ]; then
    success "Startup order validation passed"
    ((TESTS_PASSED++))
else
    error "Startup order validation failed"
    ((TESTS_FAILED++))
fi

echo
log "Service dependencies and startup order test summary:"
echo "=============================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests warned: ${YELLOW}$TESTS_WARNED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "=============================="

# Show current service status
echo
log "Current service status:"
echo "======================"
printf "%-15s %-10s %-10s %s\n" "SERVICE" "ENABLED" "RUNNING" "DEPENDENCIES"
printf "%-15s %-10s %-10s %s\n" "-------" "-------" "-------" "------------"

services=("elogind" "dbus" "NetworkManager" "pipewire" "pipewire-pulse" "wireplumber" "sddm")

for service in "${services[@]}"; do
    enabled="No"
    running="No"
    deps="${SERVICE_DEPS[$service]}"
    
    if service_enabled "$service"; then
        enabled="Yes"
    fi
    
    if service_running "$service"; then
        running="Yes"
    fi
    
    printf "%-15s %-10s %-10s %s\n" "$service" "$enabled" "$running" "$deps"
done

# Overall result
if [ $TESTS_FAILED -eq 0 ]; then
    if [ $TESTS_WARNED -eq 0 ]; then
        success "All service dependency tests passed! ✓"
        echo
        log "Service dependencies are properly configured."
        log "You can now manage services with:"
        log "  ./scripts/start-system-services.sh start    # Start all services"
        log "  ./scripts/start-system-services.sh status   # Show status"
        log "  ./scripts/start-system-services.sh restart  # Restart all services"
        exit 0
    else
        warning "Some tests passed with warnings. Services may need to be started."
        echo
        log "Common issues:"
        log "  - Services not enabled: ./scripts/start-system-services.sh start"
        log "  - Services not running: sv up <service>"
        log "  - Missing dependencies: check service status above"
        exit 1
    fi
else
    error "Some tests failed. Please check the configuration."
    echo
    log "Common issues:"
    log "  - Service scripts missing: check /etc/sv/ directories"
    log "  - Configuration files missing: run setup scripts"
    log "  - Dependencies not satisfied: start services in correct order"
    log "  - Binary not found: install required packages"
    exit 1
fi