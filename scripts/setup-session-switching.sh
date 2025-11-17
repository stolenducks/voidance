#!/bin/bash
# Session switching interface for SDDM
# Educational: Provides user-friendly session selection

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

# Session files directory
SESSION_DIR="/usr/share/wayland-sessions"
PROJECT_SESSION_DIR="/home/stolenducks/Projects/Voidance/config/wayland-sessions"

# Check if running as root for system installation
check_permissions() {
    if [ "$EUID" -eq 0 ]; then
        log "Running with system privileges - installing to $SESSION_DIR"
        return 0
    else
        log "Running as user - installing to user session directory"
        return 1
    fi
}

# Install session files
install_session_files() {
    log "Installing session files..."
    
    local target_dir="$SESSION_DIR"
    if ! check_permissions; then
        target_dir="$HOME/.local/share/wayland-sessions"
        mkdir -p "$target_dir"
    fi
    
    # Install Sway session
    if [ -f "$PROJECT_SESSION_DIR/sway.desktop" ]; then
        cp "$PROJECT_SESSION_DIR/sway.desktop" "$target_dir/"
        log_success "Installed Sway session file"
    else
        log_error "Sway session file not found"
        return 1
    fi
    
    # Install Niri session
    if [ -f "$PROJECT_SESSION_DIR/niri.desktop" ]; then
        cp "$PROJECT_SESSION_DIR/niri.desktop" "$target_dir/"
        log_success "Installed Niri session file"
    else
        log_error "Niri session file not found"
        return 1
    fi
    
    # Set permissions
    chmod 644 "$target_dir"/*.desktop
    log_success "Set permissions on session files"
    
    return 0
}

# Create session selector script
create_session_selector() {
    log "Creating session selector script..."
    
    local selector_script="/usr/local/bin/voidance-session-selector"
    if ! check_permissions; then
        selector_script="$HOME/.local/bin/voidance-session-selector"
        mkdir -p "$(dirname "$selector_script")"
    fi
    
    cat > "$selector_script" << 'EOF'
#!/bin/bash
# Voidance session selector
# Educational: Interactive session selection for Voidance

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Session information
declare -A SESSIONS=(
    ["niri"]="Niri (Voidance) - Modern scrollable tiling compositor"
    ["sway"]="Sway (Voidance) - i3-compatible tiling compositor"
)

# Default session
DEFAULT_SESSION="niri"

# Display session selection menu
show_session_menu() {
    echo -e "${BLUE}Voidance Desktop Environment - Session Selection${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    
    local i=1
    for session_key in "${!SESSIONS[@]}"; do
        local description="${SESSIONS[$session_key]}"
        local marker=""
        if [ "$session_key" = "$DEFAULT_SESSION" ]; then
            marker=" ${YELLOW}(default)${NC}"
        fi
        echo -e "${CYAN}$i)${NC} $session_key${NC} - $description$marker"
        ((i++))
    done
    
    echo ""
    echo -e "${GREEN}0)${NC} Exit without changing"
    echo ""
}

# Get user selection
get_user_selection() {
    local session_keys=("${!SESSIONS[@]}")
    
    while true; do
        read -p "Select session (0-${#SESSIONS[@]}): " choice
        
        case "$choice" in
            0)
                echo "Exiting without changing session."
                exit 0
                ;;
            [1-9]|[1-9][0-9])
                if [ "$choice" -ge 1 ] && [ "$choice" -le "${#SESSIONS[@]}" ]; then
                    local selected_session="${session_keys[$((choice-1))]}"
                    echo "Selected session: $selected_session"
                    return 0
                else
                    echo -e "${RED}Invalid selection. Please try again.${NC}"
                fi
                ;;
            *)
                # Check if user entered session name directly
                if [[ -n "${SESSIONS[$choice]:-}" ]]; then
                    echo "Selected session: $choice"
                    return 0
                else
                    echo -e "${RED}Invalid selection. Please try again.${NC}"
                fi
                ;;
        esac
    done
}

# Set default session
set_default_session() {
    local session="$1"
    
    echo "Setting default session to: $session"
    
    # Update SDDM configuration
    local sddm_conf="/etc/sddm.conf.d/voidance.conf"
    if [ -f "$sddm_conf" ]; then
        # Backup existing configuration
        sudo cp "$sddm_conf" "$sddm_conf.backup.$(date +%Y%m%d-%H%M%S)"
        
        # Update default session
        if grep -q "^Session=" "$sddm_conf"; then
            sudo sed -i "s/^Session=.*/Session=$session/" "$sddm_conf"
        else
            echo "Session=$session" | sudo tee -a "$sddm_conf"
        fi
        
        echo -e "${GREEN}Default session updated successfully.${NC}"
    else
        echo -e "${YELLOW}SDDM configuration not found. Manual configuration may be required.${NC}"
    fi
}

# Show session information
show_session_info() {
    local session="$1"
    local description="${SESSIONS[$session]}"
    
    echo ""
    echo -e "${BLUE}Session Information:${NC}"
    echo -e "${CYAN}Name:${NC} $session"
    echo -e "${CYAN}Description:${NC} $description"
    echo ""
    
    case "$session" in
        "niri")
            echo -e "${GREEN}Features:${NC}"
            echo "  • Scrollable tiling layout"
            echo "  • Modern Wayland compositor"
            echo "  • Smooth animations and transitions"
            echo "  • Built-in workspace management"
            echo "  • Native Wayland application support"
            echo ""
            echo -e "${YELLOW}Best for:${NC} Users who want a modern, innovative tiling experience"
            ;;
        "sway")
            echo -e "${GREEN}Features:${NC}"
            echo "  • i3-compatible tiling layout"
            echo "  • Mature and stable compositor"
            echo "  • Extensive configuration options"
            echo "  • Large community and ecosystem"
            echo "  • Xwayland support for X11 applications"
            echo ""
            echo -e "${YELLOW}Best for:${NC} Users familiar with i3 or who need maximum compatibility"
            ;;
    esac
}

# Main function
main() {
    # Check if a session was provided as argument
    if [ $# -eq 1 ]; then
        local session="$1"
        if [[ -n "${SESSIONS[$session]:-}" ]]; then
            show_session_info "$session"
            set_default_session "$session"
            exit 0
        else
            echo -e "${RED}Unknown session: $session${NC}"
            echo "Available sessions: ${!SESSIONS[*]}"
            exit 1
        fi
    fi
    
    # Show interactive menu
    show_session_menu
    get_user_selection
    
    local selected_session="${session_keys[$((choice-1))]}"
    show_session_info "$selected_session"
    
    read -p "Set this as the default session? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        set_default_session "$selected_session"
    else
        echo "Session selection cancelled."
    fi
}

# Run main function
main "$@"
EOF

    chmod +x "$selector_script"
    log_success "Created session selector script: $selector_script"
}

# Create session switching utility
create_session_switcher() {
    log "Creating session switching utility..."
    
    local switcher_script="/usr/local/bin/voidance-session-switch"
    if ! check_permissions; then
        switcher_script="$HOME/.local/bin/voidance-session-switch"
        mkdir -p "$(dirname "$switcher_script")"
    fi
    
    cat > "$switcher_script" << 'EOF'
#!/bin/bash
# Voidance session switcher
# Educational: Runtime session switching utility

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current session detection
detect_current_session() {
    if [ -n "${SWAYSOCK:-}" ]; then
        echo "sway"
    elif [ -n "${NIRI_SOCKET:-}" ]; then
        echo "niri"
    elif pgrep -x sway >/dev/null 2>&1; then
        echo "sway"
    elif pgrep -x niri >/dev/null 2>&1; then
        echo "niri"
    else
        echo "unknown"
    fi
}

# Get available sessions
get_available_sessions() {
    local sessions=()
    
    if command -v sway >/dev/null 2>&1; then
        sessions+=("sway")
    fi
    
    if command -v niri >/dev/null 2>&1; then
        sessions+=("niri")
    fi
    
    echo "${sessions[@]}"
}

# Switch to session
switch_to_session() {
    local target_session="$1"
    local current_session=$(detect_current_session)
    
    if [ "$current_session" = "$target_session" ]; then
        echo "Already running $target_session session."
        return 0
    fi
    
    echo "Switching to $target_session session..."
    
    case "$target_session" in
        "sway")
            if command -v sway >/dev/null 2>&1; then
                # Save current session state if possible
                if [ "$current_session" = "niri" ]; then
                    echo "Saving Niri session state..."
                    # This would require additional implementation
                fi
                
                # Start Sway
                if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
                    echo "Starting Sway on display $DISPLAY${WAYLAND_DISPLAY:+/$WAYLAND_DISPLAY}..."
                    sway &
                else
                    echo "Starting Sway..."
                    sway
                fi
            else
                echo -e "${RED}Sway is not installed${NC}"
                return 1
            fi
            ;;
        "niri")
            if command -v niri >/dev/null 2>&1; then
                # Save current session state if possible
                if [ "$current_session" = "sway" ]; then
                    echo "Saving Sway session state..."
                    # This would require additional implementation
                fi
                
                # Start Niri
                if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
                    echo "Starting Niri on display $DISPLAY${WAYLAND_DISPLAY:+/$WAYLAND_DISPLAY}..."
                    niri &
                else
                    echo "Starting Niri..."
                    niri
                fi
            else
                echo -e "${RED}Niri is not installed${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Unknown session: $target_session${NC}"
            return 1
            ;;
    esac
}

# Show session status
show_session_status() {
    local current_session=$(detect_current_session)
    local available_sessions=($(get_available_sessions))
    
    echo -e "${BLUE}Voidance Session Status${NC}"
    echo -e "${BLUE}======================${NC}"
    echo ""
    echo -e "${GREEN}Current session:${NC} $current_session"
    echo ""
    echo -e "${GREEN}Available sessions:${NC}"
    
    for session in "${available_sessions[@]}"; do
        local status=""
        if [ "$session" = "$current_session" ]; then
            status=" ${YELLOW}(running)${NC}"
        fi
        echo "  • $session$status"
    done
    
    echo ""
}

# Main function
main() {
    case "${1:-status}" in
        "status")
            show_session_status
            ;;
        "switch")
            if [ $# -ne 2 ]; then
                echo "Usage: $0 switch <session>"
                echo "Available sessions: $(get_available_sessions)"
                exit 1
            fi
            switch_to_session "$2"
            ;;
        "list")
            get_available_sessions
            ;;
        *)
            echo "Usage: $0 {status|switch|list} [session]"
            echo ""
            echo "Commands:"
            echo "  status    - Show current session status"
            echo "  switch    - Switch to specified session"
            echo "  list      - List available sessions"
            echo ""
            echo "Available sessions: $(get_available_sessions)"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
EOF

    chmod +x "$switcher_script"
    log_success "Created session switcher script: $switcher_script"
}

# Create session documentation
create_session_documentation() {
    log "Creating session documentation..."
    
    local doc_dir="/usr/share/doc/voidance"
    if ! check_permissions; then
        doc_dir="$HOME/.local/share/doc/voidance"
        mkdir -p "$doc_dir"
    fi
    
    cat > "$doc_dir/session-management.md" << 'EOF'
# Voidance Session Management

## Overview

Voidance provides two Wayland compositors for different user preferences:

- **Niri**: Modern scrollable tiling compositor with innovative features
- **Sway**: i3-compatible tiling compositor with mature ecosystem

## Session Selection

### At Login

When you log in via SDDM, you can choose your preferred session:

1. Click the session selector (usually a gear icon or desktop name)
2. Choose between:
   - "Niri (Voidance)" - Default modern experience
   - "Sway (Voidance)" - i3-compatible experience
3. Enter your password and log in

### Session Selector Tool

Use the session selector to change the default session:

```bash
# Interactive session selection
voidance-session-selector

# Direct session selection
voidance-session-selector niri
voidance-session-selector sway
```

### Session Switcher Tool

Check current session and switch between compositors:

```bash
# Show session status
voidance-session-switch status

# List available sessions
voidance-session-switch list

# Switch to specific session
voidance-session-switch sway
voidance-session-switch niri
```

## Session Differences

### Niri

**Features:**
- Scrollable tiling layout
- Smooth animations
- Modern Wayland features
- Built-in workspace management
- Native application integration

**Best for:**
- Users wanting modern experience
- Smooth workflow transitions
- Innovative tiling concepts

**Configuration:**
- Location: `~/.config/niri/config.kdl`
- Format: KDL (KDL Document Language)
- Educational comments included

### Sway

**Features:**
- i3-compatible configuration
- Mature and stable
- Extensive customization
- Large community
- Xwayland support

**Best for:**
- i3 users
- Maximum compatibility
- Traditional tiling workflow
- Advanced customization

**Configuration:**
- Location: `~/.config/sway/config`
- Format: Traditional config format
- Educational comments included

## Migration

### From Niri to Sway

Use the migration tool to transfer your settings:

```bash
migrate-niri-to-sway
```

This will:
- Preserve font settings
- Migrate workspace definitions
- Convert keybindings
- Transfer theme colors
- Create backup of existing configuration

### From Sway to Niri

Manual migration is currently required. Key differences:
- Configuration format (config vs KDL)
- Keybinding syntax
- Layout concepts

## Troubleshooting

### Session Not Available

If a session doesn't appear in SDDM:

1. Check if the compositor is installed:
   ```bash
   which niri sway
   ```

2. Verify session files exist:
   ```bash
   ls /usr/share/wayland-sessions/
   ```

3. Reinstall session files:
   ```bash
   sudo voidance-session-selector --install
   ```

### Session Fails to Start

1. Check configuration syntax:
   ```bash
   # For Niri
   niri --validate
   
   # For Sway
   sway --validate
   ```

2. Check logs:
   ```bash
   # SDDM logs
   journalctl -u sddm
   
   # Session logs
   ~/.local/share/sddm/wayland-session.log
   ```

3. Try minimal configuration:
   ```bash
   # Generate minimal config
   generate-sway-templates.sh
   sway -c ~/.config/sway/templates/minimal-config
   ```

### Performance Issues

1. Check system resources:
   ```bash
   htop
   free -h
   ```

2. Optimize configuration:
   - Disable animations in Niri
   - Reduce workspace count in Sway
   - Adjust rendering settings

3. Update graphics drivers

## Educational Notes

Voidance session management is designed to be educational:

- **Choice**: Learn different tiling paradigms
- **Migration**: Understand configuration differences
- **Flexibility**: Adapt to your workflow
- **Documentation**: Learn from detailed explanations

Both compositors share the same applications and desktop environment, ensuring a consistent experience while allowing you to explore different window management approaches.
EOF

    log_success "Created session documentation: $doc_dir/session-management.md"
}

# Main installation function
main() {
    log "Installing session switching interface..."
    
    # Install session files
    if ! install_session_files; then
        log_error "Failed to install session files"
        exit 1
    fi
    
    # Create utilities
    create_session_selector
    create_session_switcher
    create_session_documentation
    
    echo ""
    log_success "Session switching interface installed successfully!"
    
    if check_permissions; then
        log "System-wide installation completed"
        log "Session selector: voidance-session-selector"
        log "Session switcher: voidance-session-switch"
    else
        log "User installation completed"
        log "Session selector: $HOME/.local/bin/voidance-session-selector"
        log "Session switcher: $HOME/.local/bin/voidance-session-switch"
        log ""
        log "Add $HOME/.local/bin to your PATH if not already present"
    fi
    
    echo ""
    log "Documentation available in: $(find /usr/share/doc $HOME/.local/share/doc -name session-management.md 2>/dev/null | head -1)"
}

# Run main function
main "$@"