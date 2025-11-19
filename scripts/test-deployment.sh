#!/bin/bash
# Test script for Voidance deployment system
# Validates that deployment script is ready for production

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

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

# Test deployment script exists and is executable
test_deployment_script() {
    run_test "Deployment script exists" "test -f deploy-voidance.sh"
    run_test "Deployment script executable" "test -x deploy-voidance.sh"
    run_test "Deployment script has valid syntax" "bash -n deploy-voidance.sh"
}

# Test validation script exists and is executable
test_validation_script() {
    run_test "Validation script exists" "test -f scripts/validate-voidance.sh"
    run_test "Validation script executable" "test -x scripts/validate-voidance.sh"
    run_test "Validation script has valid syntax" "bash -n scripts/validate-voidance.sh"
}

# Test documentation exists
test_documentation() {
    run_test "Installation guide exists" "test -f INSTALL.md"
    run_test "README updated with one-command install" "grep -q 'curl.*deploy-voidance' README.md"
}

# Test package list completeness
test_package_list() {
    log_info "Testing package list completeness..."
    
    # Extract packages from deployment script
    local packages
    packages=$(grep -A 50 "VOIDANCE_PACKAGES=(" deploy-voidance.sh | grep '"' | tr -d '"' | tr -s ' ' '\n' | grep -v '^#' | grep -v '^$' | sort -u)
    
    local package_count
    package_count=$(echo "$packages" | wc -l)
    
    if [[ $package_count -ge 50 ]]; then
        log_success "Package list has $package_count packages (expected 50+)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Package list has only $package_count packages (expected 50+)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Check for critical packages
    local critical_packages=("niri" "sddm" "NetworkManager" "pipewire" "waybar" "wofi" "thunar" "ghostty")
    for package in "${critical_packages[@]}"; do
        if grep -q "\"$package\"" deploy-voidance.sh; then
            log_success "Critical package present: $package"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "Critical package missing: $package"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    done
}

# Test script functionality
test_script_functionality() {
    run_test "Deployment script shows help" "bash deploy-voidance.sh help | grep -q 'Usage:'"
    run_test "Validation script shows help" "bash scripts/validate-voidance.sh help | grep -q 'Usage:'"
}

# Test error handling
test_error_handling() {
    log_info "Testing error handling..."
    
    # Test deployment script with invalid argument
    set +eo pipefail  # Temporarily disable exit on error and pipefail
    if bash deploy-voidance.sh invalid 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -q "Unknown command"; then
        log_success "Deployment script handles invalid arguments"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Deployment script doesn't handle invalid arguments"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    set -eo pipefail  # Re-enable exit on error and pipefail
    
    # Test validation script with invalid argument
    set +eo pipefail  # Temporarily disable exit on error and pipefail
    if bash scripts/validate-voidance.sh invalid 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -q "Unknown command"; then
        log_success "Validation script handles invalid arguments"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Validation script doesn't handle invalid arguments"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    set -eo pipefail  # Re-enable exit on error and pipefail
}

# Show test summary
show_summary() {
    echo ""
    echo "==================================="
    echo "       Test Summary"
    echo "==================================="
    echo ""
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Deployment system is ready.${NC}"
        echo ""
        echo "The direct deployment system is ready for production use."
        return 0
    else
        echo -e "${RED}❌ Some tests failed. Please fix issues before deployment.${NC}"
        return 1
    fi
}

# Main test function
main() {
    echo "Voidance Deployment System Tests"
    echo "==============================="
    echo ""
    
    test_deployment_script
    test_validation_script
    test_documentation
    test_package_list
    test_script_functionality
    test_error_handling
    
    show_summary
}

# Run tests
main "$@"