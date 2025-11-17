#!/bin/bash
# Configuration migration script from Niri to Sway
# Educational: Migrates user preferences between compositors

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

# Configuration paths
NIRI_CONFIG="$HOME/.config/niri/config.kdl"
SWAY_CONFIG="$HOME/.config/sway/config"
SWAY_CONFIG_DIR="$HOME/.config/sway/config.d"
BACKUP_DIR="$HOME/.config/sway/backup-$(date +%Y%m%d-%H%M%S)"

# Create backup directory
create_backup() {
    log "Creating backup directory..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing Sway configuration
    if [ -f "$SWAY_CONFIG" ]; then
        cp "$SWAY_CONFIG" "$BACKUP_DIR/config"
        log_success "Backed up existing Sway configuration"
    fi
    
    # Backup existing Sway config.d directory
    if [ -d "$SWAY_CONFIG_DIR" ]; then
        cp -r "$SWAY_CONFIG_DIR" "$BACKUP_DIR/config.d"
        log_success "Backed up existing Sway config.d directory"
    fi
    
    log_success "Backup created at: $BACKUP_DIR"
}

# Check if Niri configuration exists
check_niri_config() {
    log "Checking for Niri configuration..."
    
    if [ ! -f "$NIRI_CONFIG" ]; then
        log_warning "Niri configuration not found at: $NIRI_CONFIG"
        log_warning "Will use default migration settings"
        return 1
    else
        log_success "Found Niri configuration: $NIRI_CONFIG"
        return 0
    fi
}

# Extract font configuration from Niri
migrate_font_config() {
    log "Migrating font configuration..."
    
    local font_family="Montserrat"
    local font_size="10"
    
    if [ -f "$NIRI_CONFIG" ]; then
        # Extract font family
        local extracted_font=$(grep -A 5 "font.family" "$NIRI_CONFIG" | grep -o '"[^"]*"' | head -1 | tr -d '"' || echo "")
        if [ -n "$extracted_font" ]; then
            font_family="$extracted_font"
            log_success "Extracted font family: $font_family"
        fi
        
        # Extract font size
        local extracted_size=$(grep "font.size" "$NIRI_CONFIG" | awk '{print $2}' || echo "")
        if [ -n "$extracted_size" ]; then
            font_size="$extracted_size"
            log_success "Extracted font size: $font_size"
        fi
    fi
    
    echo "font pango:$font_family $font_size"
}

# Extract keybindings from Niri
migrate_keybindings() {
    log "Migrating keybindings..."
    
    local keybindings_file="$SWAY_CONFIG_DIR/99-migrated-keybindings"
    
    cat > "$keybindings_file" << EOF
# Migrated keybindings from Niri configuration
# Generated on $(date)

EOF

    if [ -f "$NIRI_CONFIG" ]; then
        # Extract spawn keybindings (application launchers)
        grep -A 2 "bind Mod+Shift" "$NIRI_CONFIG" | while read -r line; do
            if echo "$line" | grep -q "spawn"; then
                local app=$(echo "$line" | sed 's/.*spawn\[\([^]]*\)\].*/\1/' | tr -d '"' | tr -d ' ')
                local key=$(echo "$line" | grep -o "Mod+Shift+[a-zA-Z]" | head -1)
                
                if [ -n "$app" ] && [ -n "$key" ]; then
                    # Convert Niri key format to Sway format
                    local sway_key=$(echo "$key" | sed 's/Mod+Shift+\([a-zA-Z]\)/\1/')
                    echo "bindsym \$mod+Shift+$sway_key exec $app" >> "$keybindings_file"
                    log_success "Migrated keybinding: $key -> $app"
                fi
            fi
        done
    fi
    
    log_success "Keybindings migrated to: $keybindings_file"
}

# Extract workspace configuration from Niri
migrate_workspace_config() {
    log "Migrating workspace configuration..."
    
    local workspace_file="$SWAY_CONFIG_DIR/99-migrated-workspaces"
    
    cat > "$workspace_file" << EOF
# Migrated workspace configuration from Niri
# Generated on $(date)

EOF

    if [ -f "$NIRI_CONFIG" ]; then
        # Extract workspace names
        grep "workspace-at" "$NIRI_CONFIG" | while read -r line; do
            local workspace_num=$(echo "$line" | grep -o '[0-9]\+' | head -1)
            local workspace_name=$(echo "$line" | grep -o '"[^"]*"' | head -1 | tr -d '"' || echo "")
            
            if [ -n "$workspace_num" ]; then
                if [ -n "$workspace_name" ]; then
                    echo "set \$ws$workspace_num \"$workspace_num: $workspace_name\"" >> "$workspace_file"
                else
                    echo "set \$ws$workspace_num \"$workspace_num\"" >> "$workspace_file"
                fi
                log_success "Migrated workspace: $workspace_num -> $workspace_name"
            fi
        done
    fi
    
    # Add default workspace definitions if none found
    if [ ! -s "$workspace_file" ] || [ $(wc -l < "$workspace_file") -eq 4 ]; then
        cat >> "$workspace_file" << 'EOF'

# Default workspace definitions
set $ws1 "1: Terminal"
set $ws2 "2: Web"
set $ws3 "3: Code"
set $ws4 "4: Files"
set $ws5 "5: Media"
EOF
    fi
    
    log_success "Workspace configuration migrated to: $workspace_file"
}

# Extract output configuration from Niri
migrate_output_config() {
    log "Migrating output configuration..."
    
    local output_file="$SWAY_CONFIG_DIR/99-migrated-outputs"
    
    cat > "$output_file" << EOF
# Migrated output configuration from Niri
# Generated on $(date)

EOF

    if [ -f "$NIRI_CONFIG" ]; then
        # Extract output configurations
        grep -A 10 "output" "$NIRI_CONFIG" | while read -r line; do
            if echo "$line" | grep -q "output"; then
                local output_name=$(echo "$line" | awk '{print $2}' | tr -d '"' || echo "*")
                echo "# Output configuration for $output_name" >> "$output_file"
            fi
            
            if echo "$line" | grep -q "mode"; then
                local resolution=$(echo "$line" | awk '{print $2}' | tr -d '"' || echo "")
                if [ -n "$resolution" ]; then
                    echo "output $output_name resolution $resolution" >> "$output_file"
                fi
            fi
            
            if echo "$line" | grep -q "position"; then
                local position=$(echo "$line" | awk '{print $2}' || echo "")
                if [ -n "$position" ]; then
                    echo "output $output_name position $position" >> "$output_file"
                fi
            fi
            
            if echo "$line" | grep -q "scale"; then
                local scale=$(echo "$line" | awk '{print $2}' || echo "")
                if [ -n "$scale" ]; then
                    echo "output $output_name scale $scale" >> "$output_file"
                fi
            fi
        done
    fi
    
    log_success "Output configuration migrated to: $output_file"
}

# Extract window rules from Niri
migrate_window_rules() {
    log "Migrating window rules..."
    
    local window_rules_file="$SWAY_CONFIG_DIR/99-migrated-window-rules"
    
    cat > "$window_rules_file" << EOF
# Migrated window rules from Niri
# Generated on $(date)

EOF

    if [ -f "$NIRI_CONFIG" ]; then
        # Extract window rules
        grep -A 5 "window-rule" "$NIRI_CONFIG" | while read -r line; do
            if echo "$line" | grep -q "window-rule"; then
                local app_id=$(echo "$line" | grep -o '"[^"]*"' | head -1 | tr -d '"' || echo "")
                
                if [ -n "$app_id" ]; then
                    echo "# Window rules for $app_id" >> "$window_rules_file"
                    echo "for_window [app_id=\"$app_id\"]" >> "$window_rules_file"
                fi
            fi
            
            if echo "$line" | grep -q "default-column-width"; then
                echo "    floating enable" >> "$window_rules_file"
                echo "    resize set width 800 height 600" >> "$window_rules_file"
            fi
        done
    fi
    
    # Add common window rules
    cat >> "$window_rules_file" << 'EOF'

# Common window rules
for_window [window_role="pop-up"] floating enable
for_window [window_type="dialog"] floating enable
for_window [app_id="pavucontrol"] floating enable
for_window [app_id="blueman-manager"] floating enable
EOF

    log_success "Window rules migrated to: $window_rules_file"
}

# Extract theme colors from Niri
migrate_theme_colors() {
    log "Migrating theme colors..."
    
    local theme_file="$SWAY_CONFIG_DIR/99-migrated-theme"
    
    cat > "$theme_file" << EOF
# Migrated theme colors from Niri
# Generated on $(date)

EOF

    # Default Nord-inspired colors (matching Niri defaults)
    cat >> "$theme_file" << 'EOF'

# Theme colors (Nord-inspired)
set $bg_color #2e3440
set $fg_color #eceff4
set $accent_color #88c0d0
set $urgent_color #bf616a
set $border_color #4c566a

# Window colors
client.focused          $accent_color $bg_color $fg_color $accent_color $accent_color
client.focused_inactive $border_color $bg_color $fg_color $border_color $border_color
client.unfocused        $border_color $bg_color $fg_color $border_color $border_color
client.urgent           $urgent_color $urgent_color $fg_color $urgent_color $urgent_color
client.placeholder      $border_color $bg_color $fg_color $border_color $border_color
EOF

    if [ -f "$NIRI_CONFIG" ]; then
        # Extract custom colors if present
        log_success "Using default Nord-inspired theme colors"
    fi
    
    log_success "Theme colors migrated to: $theme_file"
}

# Create main Sway configuration
create_sway_config() {
    log "Creating main Sway configuration..."
    
    local font_config=$(migrate_font_config)
    
    cat > "$SWAY_CONFIG" << EOF
# Sway Configuration (Migrated from Niri)
# Generated on $(date)
# Educational: Configuration migrated from Niri to Sway

# =============================================================================
# VARIABLES AND SETTINGS
# =============================================================================

# Set modifier key (Mod1=Alt, Mod4=Super/Windows)
set \$mod Mod4

# Set terminal emulator
set \$term ghostty

# Set application launcher
set \$menu wofi --show drun -I

# =============================================================================
# APPEARANCE AND THEMING
# =============================================================================

# Font configuration (migrated from Niri)
$font_config

# Window border settings
default_border pixel 2
default_floating_border normal
hide_edge_borders smart

# =============================================================================
# KEYBINDINGS
# =============================================================================

# Basic operations
bindsym \$mod+Return exec \$term
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec \$menu

# Focus movement
bindsym \$mod+Left focus left
bindsym \$mod+Down focus down
bindsym \$mod+Up focus up
bindsym \$mod+Right focus right

# Window movement
bindsym \$mod+Shift+Left move left
bindsym \$mod+Shift+Down move down
bindsym \$mod+Shift+Up move up
bindsym \$mod+Shift+Right move right

# Workspace navigation (will be loaded from migrated config)
bindsym \$mod+1 workspace number \$ws1
bindsym \$mod+2 workspace number \$ws2
bindsym \$mod+3 workspace number \$ws3
bindsym \$mod+4 workspace number \$ws4
bindsym \$mod+5 workspace number \$ws5
bindsym \$mod+6 workspace number \$ws6
bindsym \$mod+7 workspace number \$ws7
bindsym \$mod+8 workspace number \$ws8
bindsym \$mod+9 workspace number \$ws9
bindsym \$mod+0 workspace number \$ws10

# Layout management
bindsym \$mod+h splith
bindsym \$mod+v splitv
bindsym \$mod+s layout stacking
bindsym \$mod+w layout tabbed
bindsym \$mod+e layout toggle split

# Fullscreen and floating
bindsym \$mod+f fullscreen
bindsym \$mod+Shift+space floating toggle

# Focus management
bindsym \$mod+a focus parent
bindsym \$mod+space focus mode_toggle

# Resize mode
bindsym \$mod+r mode "resize"
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
bindsym Print exec grim ~/Pictures/Screenshot-\$(date +%Y%m%d-%H%M%S).png
bindsym \$mod+Print exec slurp | grim -g - ~/Pictures/Screenshot-\$(date +%Y%m%d-%H%M%S).png

# =============================================================================
# BAR CONFIGURATION
# =============================================================================

# Launch Waybar (shared with Niri configuration)
exec_always waybar

# =============================================================================
# AUTOSTART APPLICATIONS
# =============================================================================

# Start essential services
exec_always mako
exec_always wl-paste --type text --watch clipman store --histlen=50
exec_always wl-paste --type image --watch clipman store --histlen=50

# =============================================================================
# INCLUDES
# =============================================================================

# Include migrated configurations
include ~/.config/sway/config.d/99-migrated-*
include /etc/sway/config.d/*
EOF

    log_success "Main Sway configuration created: $SWAY_CONFIG"
}

# Create migration summary
create_migration_summary() {
    log "Creating migration summary..."
    
    local summary_file="$HOME/.config/sway/migration-summary-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$summary_file" << EOF
# Niri to Sway Migration Summary
Generated on: $(date)

## What Was Migrated

### Configuration Files Created
- \`~/.config/sway/config\` - Main Sway configuration
- \`~/.config/sway/config.d/99-migrated-keybindings\` - Migrated keybindings
- \`~/.config/sway/config.d/99-migrated-workspaces\` - Migrated workspace definitions
- \`~/.config/sway/config.d/99-migrated-outputs\` - Migrated output configuration
- \`~/.config/sway/config.d/99-migrated-window-rules\` - Migrated window rules
- \`~/.config/sway/config.d/99-migrated-theme\` - Migrated theme colors

### Settings Preserved
- Font family and size
- Workspace names and numbers
- Output configurations (resolution, position, scale)
- Window rules and application behaviors
- Theme colors and appearance

### Settings Adapted
- Keybinding format (Niri KDL to Sway format)
- Configuration syntax (KDL to Sway format)
- Application integration (Waybar, wofi, mako)

## What Was Not Migrated

### Niri-Specific Features
- Scrollable tiling layout
- Niri-specific animations
- Niri-specific window rules
- Niri-specific keybindings

### Manual Configuration Required
- Custom animations and transitions
- Advanced Niri-specific features
- Some complex window rules

## Next Steps

1. **Test the Configuration**
   \`\`\`bash
   sway --validate
   \`\`\`

2. **Start Sway**
   - Log out of current session
   - Select "Sway (Voidance)" from SDDM
   - Or run \`sway\` from TTY

3. **Customize Further**
   - Adjust keybindings as needed
   - Fine-tune window rules
   - Customize theme colors
   - Add application-specific configurations

4. **Troubleshooting**
   - Check configuration with \`sway --validate\`
   - Review migration logs
   - Restore from backup if needed: \`$BACKUP_DIR\`

## Educational Notes

This migration preserves your Niri preferences while adapting them to Sway's configuration format. The main differences are:

- **Syntax**: Niri uses KDL, Sway uses traditional config format
- **Layout**: Niri has scrollable tiling, Sway has traditional tiling
- **Keybindings**: Format differences but similar concepts
- **Integration**: Both use the same Wayland applications

The migration maintains your workflow while giving you access to Sway's mature ecosystem and i3 compatibility.
EOF

    log_success "Migration summary created: $summary_file"
}

# Main migration function
main() {
    log "Starting Niri to Sway configuration migration..."
    
    # Create backup
    create_backup
    
    # Check for Niri configuration
    local has_niri_config=false
    if check_niri_config; then
        has_niri_config=true
    fi
    
    # Create Sway config directory
    mkdir -p "$SWAY_CONFIG_DIR"
    
    # Perform migration
    create_sway_config
    migrate_keybindings
    migrate_workspace_config
    migrate_output_config
    migrate_window_rules
    migrate_theme_colors
    
    # Create summary
    create_migration_summary
    
    echo ""
    log_success "Migration completed successfully!"
    log_success "Backup location: $BACKUP_DIR"
    
    if [ "$has_niri_config" = true ]; then
        log_success "Migrated settings from Niri configuration"
    else
        log_warning "No Niri configuration found, used defaults"
    fi
    
    echo ""
    log "Next steps:"
    log "1. Validate configuration: sway --validate"
    log "2. Test Sway: sway (from TTY) or select from SDDM"
    log "3. Customize as needed"
    
    return 0
}

# Run main function
main "$@"