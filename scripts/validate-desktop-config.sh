#!/bin/bash

# Desktop Configuration Validation Script for Voidance Linux
# Validates desktop environment configuration and dependencies

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration paths
SCRIPT_DIR="$(dirname "$0")"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
DESKTOP_CONFIG_DIR="$CONFIG_DIR/desktop"
SCHEMA_FILE="$CONFIG_DIR/schemas/desktop-environment.ts"

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
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate package installation
validate_packages() {
    print_status "INFO" "Validating desktop environment packages..."
    
    local required_packages=(
        "niri"
        "waybar"
        "wofi"
        "wl-clipboard"
        "wtype"
        "grim"
        "slurp"
        "ghostty"
        "xdg-utils"
        "xdg-desktop-portal"
        "xdg-desktop-portal-wlr"
    )
    
    local optional_packages=(
        "wf-recorder"
        "font-firacode-nerd-font"
        "font-dejavu"
        "font-liberation"
        "breeze"
        "breeze-icons"
        "adwaita-icon-theme"
    )
    
    local missing_required=()
    local missing_optional=()
    
    # Check required packages
    for pkg in "${required_packages[@]}"; do
        if command_exists "$pkg" || xbps-query "$pkg" >/dev/null 2>&1; then
            print_status "OK" "Required package available: $pkg"
        else
            print_status "FAIL" "Required package missing: $pkg"
            missing_required+=("$pkg")
        fi
    done
    
    # Check optional packages
    for pkg in "${optional_packages[@]}"; do
        if command_exists "$pkg" || xbps-query "$pkg" >/dev/null 2>&1; then
            print_status "OK" "Optional package available: $pkg"
        else
            print_status "WARN" "Optional package missing: $pkg"
            missing_optional+=("$pkg")
        fi
    done
    
    if [ ${#missing_required[@]} -eq 0 ]; then
        print_status "OK" "All required packages are available"
        return 0
    else
        print_status "FAIL" "Missing required packages: ${missing_required[*]}"
        return 1
    fi
}

# Function to validate configuration files
validate_config_files() {
    print_status "INFO" "Validating configuration files..."
    
    local config_files=(
        "$DESKTOP_CONFIG_DIR/niri/config.kdl"
        "$DESKTOP_CONFIG_DIR/waybar/config"
        "$DESKTOP_CONFIG_DIR/wofi/config"
        "$DESKTOP_CONFIG_DIR/wofi/style.css"
    )
    
    local missing_configs=()
    
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            print_status "OK" "Configuration file exists: $(basename "$config_file")"
            
            # Basic syntax validation
            case "$config_file" in
                *.kdl)
                    if command -v kdlfmt >/dev/null 2>&1; then
                        if kdlfmt --check "$config_file" >/dev/null 2>&1; then
                            print_status "OK" "KDL syntax valid: $(basename "$config_file")"
                        else
                            print_status "WARN" "KDL syntax may have issues: $(basename "$config_file")"
                        fi
                    fi
                    ;;
                *.json)
                    if command -v jq >/dev/null 2>&1; then
                        if jq . "$config_file" >/dev/null 2>&1; then
                            print_status "OK" "JSON syntax valid: $(basename "$config_file")"
                        else
                            print_status "FAIL" "JSON syntax invalid: $(basename "$config_file")"
                        fi
                    fi
                    ;;
                *.css)
                    # Basic CSS validation
                    if grep -q "^[[:space:]]*}" "$config_file" 2>/dev/null; then
                        print_status "OK" "CSS syntax appears valid: $(basename "$config_file")"
                    else
                        print_status "WARN" "CSS syntax may have issues: $(basename "$config_file")"
                    fi
                    ;;
            esac
        else
            print_status "FAIL" "Configuration file missing: $(basename "$config_file")"
            missing_configs+=("$(basename "$config_file")")
        fi
    done
    
    if [ ${#missing_configs[@]} -eq 0 ]; then
        print_status "OK" "All configuration files exist"
        return 0
    else
        print_status "FAIL" "Missing configuration files: ${missing_configs[*]}"
        return 1
    fi
}

# Function to validate schema files
validate_schemas() {
    print_status "INFO" "Validating schema files..."
    
    if [ -f "$SCHEMA_FILE" ]; then
        print_status "OK" "Schema file exists: desktop-environment.ts"
        
        # Check if TypeScript is available for validation
        if command -v tsc >/dev/null 2>&1; then
            if tsc --noEmit "$SCHEMA_FILE" >/dev/null 2>&1; then
                print_status "OK" "TypeScript schema compilation successful"
            else
                print_status "WARN" "TypeScript schema compilation has issues"
            fi
        else
            print_status "WARN" "TypeScript compiler not available for schema validation"
        fi
        
        # Check if Node.js is available for runtime validation
        if command -v node >/dev/null 2>&1; then
            print_status "OK" "Node.js available for runtime schema validation"
        else
            print_status "WARN" "Node.js not available for runtime schema validation"
        fi
    else
        print_status "FAIL" "Schema file missing: desktop-environment.ts"
        return 1
    fi
}

# Function to validate session files
validate_session_files() {
    print_status "INFO" "Validating session files..."
    
    local session_file="/usr/share/wayland-sessions/niri.desktop"
    local session_script="/usr/bin/niri-session"
    
    if [ -f "$session_file" ]; then
        print_status "OK" "Wayland session file exists: niri.desktop"
        
        # Validate desktop entry format
        if grep -q "Type=Application" "$session_file" && grep -q "Exec=niri-session" "$session_file"; then
            print_status "OK" "Session file format is valid"
        else
            print_status "WARN" "Session file format may have issues"
        fi
    else
        print_status "WARN" "Wayland session file missing: niri.desktop"
    fi
    
    if [ -f "$session_script" ]; then
        print_status "OK" "Session script exists: niri-session"
        
        # Check if script is executable
        if [ -x "$session_script" ]; then
            print_status "OK" "Session script is executable"
        else
            print_status "WARN" "Session script is not executable"
        fi
    else
        print_status "WARN" "Session script missing: niri-session"
    fi
}

# Function to validate desktop entries
validate_desktop_entries() {
    print_status "INFO" "Validating desktop entry files..."
    
    local desktop_dir="$DESKTOP_CONFIG_DIR/applications"
    
    if [ -d "$desktop_dir" ]; then
        local desktop_files=("$desktop_dir"/*.desktop)
        local valid_entries=0
        local total_entries=0
        
        for desktop_file in "${desktop_files[@]}"; do
            if [ -f "$desktop_file" ]; then
                total_entries=$((total_entries + 1))
                local entry_name=$(basename "$desktop_file")
                
                # Validate desktop entry format
                if grep -q "Type=Application" "$desktop_file" && grep -q "Exec=" "$desktop_file"; then
                    print_status "OK" "Desktop entry valid: $entry_name"
                    valid_entries=$((valid_entries + 1))
                else
                    print_status "WARN" "Desktop entry format may have issues: $entry_name"
                fi
            fi
        done
        
        if [ $valid_entries -eq $total_entries ] && [ $total_entries -gt 0 ]; then
            print_status "OK" "All desktop entries are valid ($valid_entries/$total_entries)"
        elif [ $total_entries -gt 0 ]; then
            print_status "WARN" "Some desktop entries have issues ($valid_entries/$total_entries valid)"
        else
            print_status "WARN" "No desktop entry files found"
        fi
    else
        print_status "WARN" "Desktop applications directory not found"
    fi
}

# Function to validate hardware detection
validate_hardware_detection() {
    print_status "INFO" "Validating hardware detection..."
    
    local hardware_script="$SCRIPT_DIR/detect-hardware.sh"
    
    if [ -f "$hardware_script" ]; then
        print_status "OK" "Hardware detection script exists"
        
        if [ -x "$hardware_script" ]; then
            print_status "OK" "Hardware detection script is executable"
        else
            print_status "WARN" "Hardware detection script is not executable"
        fi
        
        # Test hardware detection in dry-run mode
        if "$hardware_script" --dry-run detect >/dev/null 2>&1; then
            print_status "OK" "Hardware detection script runs successfully"
        else
            print_status "WARN" "Hardware detection script may have issues"
        fi
    else
        print_status "WARN" "Hardware detection script missing"
    fi
}

# Function to validate session management
validate_session_management() {
    print_status "INFO" "Validating session management..."
    
    local session_script="$SCRIPT_DIR/session-manager.sh"
    
    if [ -f "$session_script" ]; then
        print_status "OK" "Session management script exists"
        
        if [ -x "$session_script" ]; then
            print_status "OK" "Session management script is executable"
        else
            print_status "WARN" "Session management script is not executable"
        fi
        
        # Test session manager help
        if "$session_script" help >/dev/null 2>&1; then
            print_status "OK" "Session management script runs successfully"
        else
            print_status "WARN" "Session management script may have issues"
        fi
    else
        print_status "WARN" "Session management script missing"
    fi
}

# Function to validate Wayland compatibility
validate_wayland_compatibility() {
    print_status "INFO" "Validating Wayland compatibility..."
    
    # Check if running in Wayland
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        print_status "OK" "Wayland session detected: $WAYLAND_DISPLAY"
    elif [ -n "${DISPLAY:-}" ]; then
        print_status "WARN" "X11 session detected, not Wayland: $DISPLAY"
    else
        print_status "INFO" "No display server detected (TTY mode)"
    fi
    
    # Check Wayland utilities
    local wayland_utils=(
        "wayland-info"
        "wlr-randr"
        "wlsunset"
    )
    
    for util in "${wayland_utils[@]}"; do
        if command_exists "$util"; then
            print_status "OK" "Wayland utility available: $util"
        else
            print_status "WARN" "Wayland utility missing: $util"
        fi
    done
    
    # Check for Xwayland
    if command_exists Xwayland; then
        print_status "OK" "Xwayland available for X11 compatibility"
    else
        print_status "WARN" "Xwayland not available for X11 compatibility"
    fi
}

# Function to run comprehensive validation
run_validation() {
    print_status "INFO" "Starting comprehensive desktop environment validation..."
    echo ""
    
    local validation_failed=0
    
    # Run all validation checks
    validate_packages || validation_failed=1
    echo ""
    
    validate_config_files || validation_failed=1
    echo ""
    
    validate_schemas || validation_failed=1
    echo ""
    
    validate_session_files || validation_failed=1
    echo ""
    
    validate_desktop_entries
    echo ""
    
    validate_hardware_detection
    echo ""
    
    validate_session_management
    echo ""
    
    validate_wayland_compatibility
    echo ""
    
    # Summary
    if [ $validation_failed -eq 0 ]; then
        print_status "OK" "All critical validations passed successfully!"
        print_status "INFO" "Desktop environment is ready for use"
        return 0
    else
        print_status "FAIL" "Some validations failed"
        print_status "INFO" "Please address the issues above before using the desktop environment"
        return 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] COMMAND

Commands:
    packages        Validate package installation
    config          Validate configuration files
    schemas         Validate schema files
    session         Validate session files
    desktop         Validate desktop entries
    hardware        Validate hardware detection
    wayland         Validate Wayland compatibility
    all             Run all validations (default)
    help            Show this help message

Options:
    --verbose       Show detailed output
    --quiet         Show minimal output
    --fix           Attempt to fix common issues

Examples:
    $0 all                          # Run all validations
    $0 packages                      # Validate packages only
    $0 config                        # Validate configuration files
    $0 --fix all                     # Run validations and attempt fixes

EOF
}

# Main function
main() {
    local action="${1:-all}"
    local verbose="${VERBOSE:-false}"
    local quiet="${QUIET:-false}"
    local fix="${FIX:-false}"
    
    case "$action" in
        "packages")
            validate_packages
            ;;
        "config")
            validate_config_files
            ;;
        "schemas")
            validate_schemas
            ;;
        "session")
            validate_session_files
            ;;
        "desktop")
            validate_desktop_entries
            ;;
        "hardware")
            validate_hardware_detection
            ;;
        "wayland")
            validate_wayland_compatibility
            ;;
        "all")
            run_validation
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_status "FAIL" "Unknown command: $action"
            show_usage
            exit 1
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            export VERBOSE=true
            shift
            ;;
        --quiet)
            export QUIET=true
            shift
            ;;
        --fix)
            export FIX=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Run main function with remaining arguments
main "$@"