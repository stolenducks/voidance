#!/bin/bash
# Sway configuration validation script
# Educational: Validates Sway configuration with detailed error reporting

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗ $1${NC}"
}

# Configuration file path
CONFIG_FILE="${1:-$HOME/.config/sway/config}"
PROJECT_CONFIG="/home/stolenducks/Projects/Voidance/config/desktop/sway/config"

# Check if Sway is installed
check_sway_installation() {
    log "Checking Sway installation..."
    
    if command -v sway >/dev/null 2>&1; then
        local version=$(sway --version 2>/dev/null | head -n1 || echo "unknown")
        log_success "Sway is installed ($version)"
        return 0
    else
        log_error "Sway is not installed"
        return 1
    fi
}

# Validate configuration syntax
validate_syntax() {
    local config_file="$1"
    
    log "Validating configuration syntax for: $config_file"
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Use sway's built-in validation
    if sway -c "$config_file" --validate 2>/dev/null; then
        log_success "Configuration syntax is valid"
        return 0
    else
        log_error "Configuration syntax errors found:"
        sway -c "$config_file" --validate 2>&1 | head -20
        return 1
    fi
}

# Check for required variables
check_required_variables() {
    local config_file="$1"
    
    log "Checking required variables..."
    
    local required_vars=("\$mod" "\$term" "\$menu")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^set $var " "$config_file"; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -eq 0 ]; then
        log_success "All required variables are defined"
        return 0
    else
        log_error "Missing required variables: ${missing_vars[*]}"
        return 1
    fi
}

# Check keybinding conflicts
check_keybinding_conflicts() {
    local config_file="$1"
    
    log "Checking for keybinding conflicts..."
    
    # Extract keybindings
    local keybindings=$(grep "^bindsym" "$config_file" | sed 's/bindsym //' | awk '{print $1, $2}')
    
    # Check for duplicate keybindings
    local duplicates=$(echo "$keybindings" | sort | uniq -d)
    
    if [ -z "$duplicates" ]; then
        log_success "No keybinding conflicts found"
        return 0
    else
        log_warning "Potential keybinding conflicts:"
        echo "$duplicates" | while read -r binding; do
            log_warning "Duplicate: $binding"
        done
        return 1
    fi
}

# Check workspace configuration
check_workspace_configuration() {
    local config_file="$1"
    
    log "Checking workspace configuration..."
    
    # Check for workspace definitions
    if grep -q "^set \$ws[0-9]" "$config_file"; then
        log_success "Workspace variables are defined"
    else
        log_warning "No workspace variables found"
    fi
    
    # Check for workspace assignments
    if grep -q "workspace number" "$config_file"; then
        log_success "Workspace navigation is configured"
    else
        log_warning "No workspace navigation found"
    fi
    
    # Check for workspace assignments
    if grep -q "assign " "$config_file"; then
        log_success "Workspace assignments are configured"
    else
        log_warning "No workspace assignments found"
    fi
    
    return 0
}

# Check application integration
check_application_integration() {
    local config_file="$1"
    
    log "Checking application integration..."
    
    # Check for terminal integration
    if grep -q "exec.*$term" "$config_file" || grep -q "exec.*ghostty" "$config_file"; then
        log_success "Terminal integration is configured"
    else
        log_warning "Terminal integration may be missing"
    fi
    
    # Check for launcher integration
    if grep -q "exec.*$menu" "$config_file" || grep -q "exec.*wofi" "$config_file"; then
        log_success "Application launcher is configured"
    else
        log_warning "Application launcher may be missing"
    fi
    
    # Check for Waybar integration
    if grep -q "exec_always waybar" "$config_file"; then
        log_success "Waybar integration is configured"
    else
        log_warning "Waybar integration may be missing"
    fi
    
    # Check for mako integration
    if grep -q "exec_always mako" "$config_file"; then
        log_success "Mako integration is configured"
    else
        log_warning "Mako integration may be missing"
    fi
    
    return 0
}

# Check input configuration
check_input_configuration() {
    local config_file="$1"
    
    log "Checking input configuration..."
    
    # Check for keyboard configuration
    if grep -q 'input "type:keyboard"' "$config_file"; then
        log_success "Keyboard configuration is present"
    else
        log_warning "Keyboard configuration may be missing"
    fi
    
    # Check for touchpad configuration
    if grep -q 'input "type:touchpad"' "$config_file"; then
        log_success "Touchpad configuration is present"
    else
        log_warning "Touchpad configuration may be missing"
    fi
    
    return 0
}

# Check output configuration
check_output_configuration() {
    local config_file="$1"
    
    log "Checking output configuration..."
    
    # Check for output configuration
    if grep -q "^output " "$config_file"; then
        log_success "Output configuration is present"
    else
        log_warning "Output configuration may be missing"
    fi
    
    return 0
}

# Check window rules
check_window_rules() {
    local config_file="$1"
    
    log "Checking window rules..."
    
    # Check for window rules
    if grep -q "for_window" "$config_file"; then
        local rule_count=$(grep -c "for_window" "$config_file")
        log_success "Window rules are configured ($rule_count rules found)"
    else
        log_warning "No window rules found"
    fi
    
    return 0
}

# Check bar configuration
check_bar_configuration() {
    local config_file="$1"
    
    log "Checking bar configuration..."
    
    # Check for bar configuration
    if grep -q "^bar {" "$config_file"; then
        log_success "Bar configuration is present"
        
        # Check for bar position
        if grep -q "position " "$config_file"; then
            log_success "Bar position is configured"
        else
            log_warning "Bar position may be missing"
        fi
        
        # Check for status command
        if grep -q "status_command" "$config_file"; then
            log_success "Bar status command is configured"
        else
            log_warning "Bar status command may be missing"
        fi
    else
        log_warning "No bar configuration found"
    fi
    
    return 0
}

# Check include statements
check_include_statements() {
    local config_file="$1"
    
    log "Checking include statements..."
    
    # Check for include statements
    if grep -q "^include " "$config_file"; then
        log_success "Include statements are present"
        
        # Check if included files exist
        local includes=$(grep "^include " "$config_file" | sed 's/include //')
        local missing_includes=()
        
        while IFS= read -r include; do
            # Expand environment variables
            expanded_include=$(eval echo "$include")
            
            # Check if file exists (handle wildcards)
            if [ ! -f "$expanded_include" ] && [ ! -d "$(dirname "$expanded_include")" ]; then
                missing_includes+=("$include")
            fi
        done <<< "$includes"
        
        if [ ${#missing_includes[@]} -eq 0 ]; then
            log_success "All included files are accessible"
        else
            log_warning "Some included files may be missing: ${missing_includes[*]}"
        fi
    else
        log_warning "No include statements found"
    fi
    
    return 0
}

# Perform security checks
perform_security_checks() {
    local config_file="$1"
    
    log "Performing security checks..."
    
    # Check for potentially dangerous exec commands
    local dangerous_patterns=(
        "exec.*sudo"
        "exec.*rm.*-rf"
        "exec.*chmod.*777"
        "exec.*curl.*|.*sh"
        "exec.*wget.*|.*sh"
    )
    
    local security_issues=()
    
    for pattern in "${dangerous_patterns[@]}"; do
        if grep -qE "$pattern" "$config_file"; then
            security_issues+=("$pattern")
        fi
    done
    
    if [ ${#security_issues[@]} -eq 0 ]; then
        log_success "No obvious security issues found"
    else
        log_warning "Potential security issues detected:"
        for issue in "${security_issues[@]}"; do
            log_warning "Pattern: $issue"
        done
    fi
    
    return 0
}

# Generate validation report
generate_validation_report() {
    local config_file="$1"
    local results=("$@")
    
    log "Generating validation report..."
    
    local report_file="$HOME/.config/sway/validation-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Sway Configuration Validation Report"
        echo "===================================="
        echo "Date: $(date)"
        echo "Configuration file: $config_file"
        echo ""
        echo "Validation Results:"
        echo "-------------------"
        
        for result in "${results[@]}"; do
            echo "$result"
        done
        
        echo ""
        echo "Configuration Summary:"
        echo "---------------------"
        echo "Lines: $(wc -l < "$config_file")"
        echo "Size: $(du -h "$config_file" | cut -f1)"
        echo "Keybindings: $(grep -c "^bindsym" "$config_file")"
        echo "Window rules: $(grep -c "for_window" "$config_file")"
        echo "Exec commands: $(grep -c "^exec" "$config_file")"
        echo "Exec_always commands: $(grep -c "^exec_always" "$config_file")"
        
    } > "$report_file"
    
    log_success "Validation report saved to: $report_file"
}

# Main validation function
main() {
    local config_file="$CONFIG_FILE"
    
    # Use project config if user config doesn't exist
    if [ ! -f "$config_file" ] && [ -f "$PROJECT_CONFIG" ]; then
        config_file="$PROJECT_CONFIG"
        log "Using project configuration: $config_file"
    fi
    
    log "Starting Sway configuration validation..."
    
    # Check Sway installation
    if ! check_sway_installation; then
        log_error "Cannot validate configuration without Sway installed"
        exit 1
    fi
    
    # Run validation checks
    local tests=(
        "validate_syntax:$config_file"
        "check_required_variables:$config_file"
        "check_keybinding_conflicts:$config_file"
        "check_workspace_configuration:$config_file"
        "check_application_integration:$config_file"
        "check_input_configuration:$config_file"
        "check_output_configuration:$config_file"
        "check_window_rules:$config_file"
        "check_bar_configuration:$config_file"
        "check_include_statements:$config_file"
        "perform_security_checks:$config_file"
    )
    
    local passed=0
    local failed=0
    local warnings=0
    local results=()
    
    for test in "${tests[@]}"; do
        local test_name="${test%%:*}"
        local test_args="${test#*:}"
        
        echo ""
        if $test_name "$test_args"; then
            ((passed++))
            results+=("✓ $test_name: PASSED")
        else
            ((failed++))
            results+=("✗ $test_name: FAILED")
        fi
    done
    
    echo ""
    log "Validation summary:"
    log_success "Passed: $passed"
    log_error "Failed: $failed"
    
    # Generate report
    generate_validation_report "$config_file" "${results[@]}"
    
    if [ $failed -eq 0 ]; then
        log_success "Configuration validation completed successfully! ✓"
        return 0
    else
        log_error "Configuration validation failed. Please fix the issues."
        return 1
    fi
}

# Run main function
main "$@"