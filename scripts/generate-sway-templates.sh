#!/bin/bash
# Sway configuration template generator
# Educational: Generates configuration templates with explanations

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

# Configuration directory
CONFIG_DIR="${1:-$HOME/.config/sway}"
TEMPLATE_DIR="$CONFIG_DIR/templates"

# Create directories
create_directories() {
    log "Creating configuration directories..."
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/config.d"
    mkdir -p "$TEMPLATE_DIR"
    
    log_success "Created directories: $CONFIG_DIR, $CONFIG_DIR/config.d, $TEMPLATE_DIR"
}

# Generate basic configuration template
generate_basic_template() {
    log "Generating basic configuration template..."
    
    cat > "$TEMPLATE_DIR/basic-config" << 'EOF'
# Basic Sway Configuration Template
# Educational: Essential configuration for getting started

# =============================================================================
# VARIABLES
# =============================================================================

# Set modifier key (Mod1=Alt, Mod4=Super/Windows)
set $mod Mod4

# Set terminal emulator
set $term ghostty

# Set application launcher
set $menu wofi --show drun -I

# =============================================================================
# APPEARANCE
# =============================================================================

# Font for window titles and status bar
font pango:Montserrat 10

# Window border settings
default_border pixel 2
default_floating_border normal
hide_edge_borders smart

# =============================================================================
# KEYBINDINGS
# =============================================================================

# Basic operations
bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+d exec $menu

# Focus movement
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Window movement
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Workspace navigation
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5

# Layout management
bindsym $mod+h splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Fullscreen and floating
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle

# =============================================================================
# BAR
# =============================================================================

bar {
    position top
    status_command while date +'%Y-%m-%d %H:%M:%S'; do sleep 1; done
}

# =============================================================================
# INCLUDES
# =============================================================================

include /etc/sway/config.d/*
EOF

    log_success "Generated basic configuration template"
}

# Generate advanced configuration template
generate_advanced_template() {
    log "Generating advanced configuration template..."
    
    cat > "$TEMPLATE_DIR/advanced-config" << 'EOF'
# Advanced Sway Configuration Template
# Educational: Comprehensive configuration with advanced features

# =============================================================================
# VARIABLES AND SETTINGS
# =============================================================================

set $mod Mod4
set $term ghostty
set $menu wofi --show drun -I
set $wallpaper_dir /usr/share/backgrounds

# =============================================================================
# APPEARANCE AND THEMING
# =============================================================================

font pango:Montserrat 10

# Theme colors (Nord-inspired)
set $bg_color #2e3440
set $fg_color #eceff4
set $accent_color #88c0d0
set $urgent_color #bf616a
set $border_color #4c566a

default_border pixel 2
default_floating_border normal
hide_edge_borders smart

# Window colors
client.focused          $accent_color $bg_color $fg_color $accent_color $accent_color
client.focused_inactive $border_color $bg_color $fg_color $border_color $border_color
client.unfocused        $border_color $bg_color $fg_color $border_color $border_color
client.urgent           $urgent_color $urgent_color $fg_color $urgent_color $urgent_color

# =============================================================================
# OUTPUT CONFIGURATION
# =============================================================================

output * bg $wallpaper_dir/voidance-wallpaper.png fill

# Example external display configuration
# output HDMI-A-1 resolution 1920x1080 position 0,0
# output DP-1 resolution 2560x1440 position 1920,0

# =============================================================================
# INPUT CONFIGURATION
# =============================================================================

input "type:keyboard" {
    xkb_layout us
    xkb_options ctrl:nocaps
}

input "type:touchpad" {
    tap enabled
    natural_scroll enabled
    dwt enabled
}

# =============================================================================
# WORKSPACE CONFIGURATION
# =============================================================================

set $ws1 "1: Terminal"
set $ws2 "2: Web"
set $ws3 "3: Code"
set $ws4 "4: Files"
set $ws5 "5: Media"

# Workspace assignments
assign [app_id="firefox"] $ws2
assign [app_id="code"] $ws3
assign [app_id="thunar"] $ws4

# =============================================================================
# WINDOW RULES
# =============================================================================

for_window [window_role="pop-up"] floating enable
for_window [window_type="dialog"] floating enable
for_window [app_id="pavucontrol"] floating enable

# =============================================================================
# KEYBINDINGS
# =============================================================================

# Basic operations
bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+d exec $menu

# Focus movement
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Window movement
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Workspace navigation
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5

# Move window to workspace
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5

# Layout management
bindsym $mod+h splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Fullscreen and floating
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle

# Focus management
bindsym $mod+a focus parent
bindsym $mod+space focus mode_toggle

# Resize mode
bindsym $mod+r mode "resize"
mode "resize" {
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px
    
    bindsym Return mode "default"
    bindsym Escape mode "default"
}

# =============================================================================
# SYSTEM KEYBINDINGS
# =============================================================================

# Volume control
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brightness control
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5-%

# Screenshot
bindsym Print exec grim ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png
bindsym $mod+Print exec slurp | grim -g - ~/Pictures/Screenshot-$(date +%Y%m%d-%H%M%S).png

# =============================================================================
# BAR CONFIGURATION
# =============================================================================

bar {
    position top
    font pango:Montserrat 10
    
    colors {
        background $bg_color
        statusline $fg_color
        separator $border_color
        
        focused_workspace   $accent_color $accent_color $fg_color
        active_workspace    $border_color $border_color $fg_color
        inactive_workspace  $bg_color $bg_color $fg_color
        urgent_workspace    $urgent_color $urgent_color $fg_color
    }
}

# =============================================================================
# AUTOSTART
# =============================================================================

exec_always mako
exec_always waybar

# =============================================================================
# INCLUDES
# =============================================================================

include /etc/sway/config.d/*
include ~/.config/sway/config.d/*
EOF

    log_success "Generated advanced configuration template"
}

# Generate minimal configuration template
generate_minimal_template() {
    log "Generating minimal configuration template..."
    
    cat > "$TEMPLATE_DIR/minimal-config" << 'EOF'
# Minimal Sway Configuration Template
# Educational: Bare minimum configuration for Sway

set $mod Mod4
set $term ghostty

font pango:monospace 10
default_border pixel 2

bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+d exec wofi --show drun

bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3

bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle

include /etc/sway/config.d/*
EOF

    log_success "Generated minimal configuration template"
}

# Generate gaming configuration template
generate_gaming_template() {
    log "Generating gaming configuration template..."
    
    cat > "$TEMPLATE_DIR/gaming-config" << 'EOF'
# Gaming Sway Configuration Template
# Educational: Optimized for gaming performance

set $mod Mod4
set $term ghostty
set $menu wofi --show drun -I

font pango:Montserrat 10

# Performance optimizations
default_border pixel 1
hide_edge_borders smart

# Disable vsync for gaming (uncomment if needed)
# output * max_render_time off

# Gaming workspace assignments
set $ws1 "1: Desktop"
set $ws2 "2: Game"
set $ws3 "3: Chat"
set $ws4 "4: Browser"
set $ws5 "5: Media"

# Assign games to workspace 2
assign [class="Steam"] $ws2
assign [class="Lutris"] $ws2
assign [app_id="minecraft"] $ws2
assign [app_id="heroic"] $ws2

# Window rules for games
for_window [class="Steam"] floating enable
for_window [class="Lutris"] floating enable
for_window [app_id="minecraft"] fullscreen enable

# Keybindings
bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+d exec $menu

# Standard navigation
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Workspace navigation
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5

# Layout management
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle

# Gaming shortcuts
bindsym $mod+g workspace $ws2
bindsym $mod+Shift+g exec steam
bindsym $mod+Shift+l exec lutris

# Performance monitoring
bindsym $mod+Shift+p exec htop
bindsym $mod+Shift+m exec nvidia-smi dmon

# Bar with gaming info
bar {
    position top
    font pango:Montserrat 10
    status_command while date +'%H:%M:%S'; do sleep 1; done
}

# Autostart gaming tools
exec_always mako
exec_always waybar

include /etc/sway/config.d/*
EOF

    log_success "Generated gaming configuration template"
}

# Generate development configuration template
generate_development_template() {
    log "Generating development configuration template..."
    
    cat > "$TEMPLATE_DIR/development-config" << 'EOF'
# Development Sway Configuration Template
# Educational: Optimized for development workflow

set $mod Mod4
set $term ghostty
set $menu wofi --show drun -I

font pango:Montserrat 10
default_border pixel 2
hide_edge_borders smart

# Development workspaces
set $ws1 "1: Terminal"
set $ws2 "2: Editor"
set $ws3 "3: Browser"
set $ws4 "4: Files"
set $ws5 "5: Communication"
set $ws6 "6: Design"
set $ws7 "7: Testing"
set $ws8 "8: Documentation"

# Development workspace assignments
assign [app_id="code"] $ws2
assign [app_id="firefox"] $ws3
assign [app_id="thunar"] $ws4
assign [app_id="discord"] $ws5
assign [app_id="figma"] $ws6
assign [app_id="postman"] $ws7

# Development window rules
for_window [app_id="code"] layout splitv
for_window [app_id="firefox"] layout tabbed
for_window [app_id="thunar"] layout splith
for_window [app_id="discord"] floating enable

# Keybindings
bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+d exec $menu

# Navigation
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Workspace navigation
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8

# Layout management
bindsym $mod+h splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle

# Development shortcuts
bindsym $mod+Shift+e exec code
bindsym $mod+Shift+b exec firefox
bindsym $mod+Shift+f exec thunar
bindsym $mod+Shift+d exec discord

# Terminal layouts
bindsym $mod+Control+1 layout splitv; exec $term
bindsym $mod+Control+2 layout splith; exec $term

# Git shortcuts
bindsym $mod+Control+g exec $term -e git status
bindsym $mod+Control+s exec $term -e git status --short

# Development tools
bindsym $mod+Control+t exec $term -e htop
bindsym $mod+Control+n exec $term -e nmtui

# Bar with development info
bar {
    position top
    font pango:Montserrat 10
    status_command while date +'%H:%M:%S'; do sleep 1; done
}

# Autostart development tools
exec_always mako
exec_always waybar

include /etc/sway/config.d/*
EOF

    log_success "Generated development configuration template"
}

# Generate template selector
generate_template_selector() {
    log "Generating template selector script..."
    
    cat > "$TEMPLATE_DIR/select-template" << 'EOF'
#!/bin/bash
# Sway configuration template selector

TEMPLATE_DIR="$HOME/.config/sway/templates"
CONFIG_DIR="$HOME/.config/sway"

echo "Available Sway configuration templates:"
echo ""
echo "1) basic-config     - Basic configuration for getting started"
echo "2) advanced-config  - Comprehensive configuration with advanced features"
echo "3) minimal-config   - Bare minimum configuration"
echo "4) gaming-config     - Optimized for gaming performance"
echo "5) development-config - Optimized for development workflow"
echo ""
read -p "Select template (1-5): " choice

case $choice in
    1)
        template="basic-config"
        ;;
    2)
        template="advanced-config"
        ;;
    3)
        template="minimal-config"
        ;;
    4)
        template="gaming-config"
        ;;
    5)
        template="development-config"
        ;;
    *)
        echo "Invalid selection"
        exit 1
        ;;
esac

echo "Installing $template template..."

# Backup existing configuration
if [ -f "$CONFIG_DIR/config" ]; then
    cp "$CONFIG_DIR/config" "$CONFIG_DIR/config.backup.$(date +%Y%m%d-%H%M%S)"
    echo "Backed up existing configuration"
fi

# Install template
cp "$TEMPLATE_DIR/$template" "$CONFIG_DIR/config"
echo "Installed $template as ~/.config/sway/config"

echo "Template installed! Restart Sway to apply changes."
EOF

    chmod +x "$TEMPLATE_DIR/select-template"
    log_success "Generated template selector script"
}

# Main function
main() {
    log "Generating Sway configuration templates..."
    
    create_directories
    generate_basic_template
    generate_advanced_template
    generate_minimal_template
    generate_gaming_template
    generate_development_template
    generate_template_selector
    
    echo ""
    log_success "All Sway configuration templates generated!"
    log_success "Templates available in: $TEMPLATE_DIR"
    log_success "Run '$TEMPLATE_DIR/select-template' to install a template"
}

# Run main function
main "$@"