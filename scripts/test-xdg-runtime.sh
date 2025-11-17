#!/bin/bash

# XDG Runtime Directory Test Script
# Tests elogind session management and XDG runtime directory creation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_USER="voidance"
TEST_UID="1000"

# Function to print colored output
print_status() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        "OK")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "INFO")
            echo -e "ℹ $message"
            ;;
    esac
}

# Function to check if service is running
check_service() {
    local service="$1"
    
    if pgrep -f "$service" >/dev/null 2>&1; then
        print_status "OK" "$service is running"
        return 0
    else
        print_status "FAIL" "$service is not running"
        return 1
    fi
}

# Function to test XDG runtime directory
test_xdg_runtime() {
    local user="$1"
    local uid="$2"
    
    print_status "INFO" "Testing XDG runtime directory for user: $user (UID: $uid)"
    
    # Check if XDG_RUNTIME_DIR is set
    if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
        print_status "WARN" "XDG_RUNTIME_DIR not set in current environment"
        
        # Try to determine runtime directory
        local runtime_dir="/run/user/$uid"
        if [ -d "$runtime_dir" ]; then
            export XDG_RUNTIME_DIR="$runtime_dir"
            print_status "INFO" "Using runtime directory: $runtime_dir"
        else
            print_status "FAIL" "Runtime directory does not exist: $runtime_dir"
            return 1
        fi
    fi
    
    # Test runtime directory permissions
    if [ -d "$XDG_RUNTIME_DIR" ]; then
        local perms=$(stat -c "%a" "$XDG_RUNTIME_DIR" 2>/dev/null || stat -f "%A" "$XDG_RUNTIME_DIR" 2>/dev/null)
        if [ "$perms" = "700" ]; then
            print_status "OK" "Runtime directory has correct permissions (700)"
        else
            print_status "WARN" "Runtime directory has unexpected permissions: $perms"
        fi
        
        # Test ownership
        local owner=$(stat -c "%U:%G" "$XDG_RUNTIME_DIR" 2>/dev/null || stat -f "%Su:%Sg" "$XDG_RUNTIME_DIR" 2>/dev/null)
        if [ "$owner" = "$user:$user" ]; then
            print_status "OK" "Runtime directory has correct ownership ($owner)"
        else
            print_status "WARN" "Runtime directory has unexpected ownership: $owner"
        fi
    else
        print_status "FAIL" "Runtime directory does not exist: $XDG_RUNTIME_DIR"
        return 1
    fi
    
    return 0
}

# Function to test session creation
test_session() {
    local user="$1"
    
    print_status "INFO" "Testing session management for user: $user"
    
    # Check if loginctl is available
    if command -v loginctl >/dev/null 2>&1; then
        # List active sessions
        local sessions=$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
        
        if [ -n "$sessions" ]; then
            print_status "OK" "Found active sessions: $sessions"
            
            # Check session details
            for session in $sessions; do
                local session_user=$(loginctl show-session "$session" -p Name --value 2>/dev/null)
                local session_state=$(loginctl show-session "$session" -p State --value 2>/dev/null)
                
                if [ "$session_user" = "$user" ]; then
                    print_status "OK" "Session $session for user $user is $session_state"
                fi
            done
        else
            print_status "WARN" "No active sessions found"
        fi
    else
        print_status "WARN" "loginctl not available, cannot test sessions"
    fi
}

# Function to test elogind functionality
test_elogind() {
    print_status "INFO" "Testing elogind functionality"
    
    # Check if elogind is running
    if ! check_service "elogind"; then
        return 1
    fi
    
    # Check elogind control socket
    if [ -S "/run/systemd/private" ]; then
        print_status "OK" "elogind control socket exists"
    else
        print_status "WARN" "elogind control socket not found"
    fi
    
    # Check if loginctl works
    if command -v loginctl >/dev/null 2>&1; then
        if loginctl --version >/dev/null 2>&1; then
            print_status "OK" "loginctl is functional"
        else
            print_status "FAIL" "loginctl is not functional"
            return 1
        fi
    else
        print_status "FAIL" "loginctl not available"
        return 1
    fi
    
    return 0
}

# Function to test dbus functionality
test_dbus() {
    print_status "INFO" "Testing D-Bus functionality"
    
    # Check if dbus is running
    if ! check_service "dbus-daemon"; then
        return 1
    fi
    
    # Check dbus socket
    if [ -S "/run/dbus/system_bus_socket" ]; then
        print_status "OK" "D-Bus system socket exists"
    else
        print_status "FAIL" "D-Bus system socket not found"
        return 1
    fi
    
    # Test dbus communication
    if command -v dbus-send >/dev/null 2>&1; then
        if timeout 5 dbus-send --system --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
            print_status "OK" "D-Bus communication is working"
        else
            print_status "FAIL" "D-Bus communication failed"
            return 1
        fi
    else
        print_status "WARN" "dbus-send not available, cannot test communication"
    fi
    
    return 0
}

# Function to run all tests
run_all_tests() {
    local test_user="${1:-$TEST_USER}"
    local test_uid="${2:-$TEST_UID}"
    
    print_status "INFO" "Starting XDG runtime directory and session management tests"
    print_status "INFO" "Test user: $test_user, UID: $test_uid"
    echo ""
    
    local failed_tests=0
    
    # Test core services
    if ! test_elogind; then
        ((failed_tests++))
    fi
    echo ""
    
    if ! test_dbus; then
        ((failed_tests++))
    fi
    echo ""
    
    # Test session management
    test_session "$test_user"
    echo ""
    
    # Test XDG runtime directory
    if ! test_xdg_runtime "$test_user" "$test_uid"; then
        ((failed_tests++))
    fi
    echo ""
    
    # Summary
    if [ $failed_tests -eq 0 ]; then
        print_status "OK" "All tests passed successfully!"
        return 0
    else
        print_status "FAIL" "$failed_tests test(s) failed"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [USER] [UID]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo ""
    echo "Arguments:"
    echo "  USER           Test username (default: voidance)"
    echo "  UID            Test user ID (default: 1000)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Test with default user"
    echo "  $0 myuser 1001       # Test with custom user and UID"
    echo "  $0 --verbose          # Enable verbose output"
}

# Main execution
main() {
    local test_user="$TEST_USER"
    local test_uid="$TEST_UID"
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -*)
                echo "Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$test_user" ]; then
                    test_user="$1"
                elif [ -z "$test_uid" ]; then
                    test_uid="$1"
                else
                    echo "Too many arguments" >&2
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Run tests
    if run_all_tests "$test_user" "$test_uid"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function with all arguments
main "$@"