#!/bin/bash
# Mako Notification System Integration Script
# Configures mako notification daemon integration with Voidance desktop environment

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
    exit 1
}

# Function to setup mako environment
setup_environment() {
    log "Setting up mako environment variables"
    
    local env_file="$CONFIG_DIR/desktop/environment"
    
    # Add mako-specific environment variables
    cat >> "$env_file" << 'EOF'

# Mako Notification Daemon Environment Variables
# These variables ensure proper integration with desktop environment

# Set default notification daemon
export NOTIFICATION_DAEMON=mako

# Enable Wayland integration
export GDK_BACKEND=wayland

# Set notification server
export XDG_NOTIFICATION_DESKTOP=mako

# Configure notification behavior
export MAKO_DEFAULT_TIMEOUT=5000
export MAKO_MAX_VISIBLE=5

# Enable notification history
export MAKO_HISTORY=true
EOF
    
    log "✓ Environment variables configured"
}

# Function to configure desktop integration
setup_desktop_integration() {
    log "Setting up desktop integration for mako"
    
    # Update desktop environment configuration
    local desktop_config="$CONFIG_DIR/desktop/desktop-environment.json"
    
    if [ -f "$desktop_config" ]; then
        # Add mako to applications list
        jq '.applications += {"notifications": "mako"}' "$desktop_config" > "${desktop_config}.tmp"
        mv "${desktop_config}.tmp" "$desktop_config"
        
        # Update default applications
        jq '.default_applications.notification_daemon = "mako.desktop"' "$desktop_config" > "${desktop_config}.tmp"
        mv "${desktop_config}.tmp" "$desktop_config"
        
        # Add notification capabilities
        jq '.capabilities += ["notifications", "critical_notifications", "notification_history", "notification_actions"]' "$desktop_config" > "${desktop_config}.tmp"
        mv "${desktop_config}.tmp" "$desktop_config"
        
        log "✓ Desktop environment configuration updated"
    else
        log "⚠ Desktop environment configuration not found, skipping integration"
    fi
}

# Function to create mako desktop entry
create_desktop_entry() {
    log "Creating mako desktop entry"
    
    local desktop_file="$CONFIG_DIR/desktop/applications/mako.desktop"
    
    cat > "$desktop_file" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Notification Daemon
Name[en]=Notification Daemon
Comment=Display notifications
Comment[en]=Display notifications
GenericName=Notification Daemon
GenericName[en]=Notification Daemon
Exec=mako
Terminal=false
NoDisplay=true
Icon=dialog-information
StartupNotify=false
Categories=System;Utility;GTK;
Keywords=notification;daemon;alert;popup;
X-GNOME-AutoRestart=true
X-GNOME-Autostart-Phase=Initialization
EOF
    
    log "✓ Mako desktop entry created"
}

# Function to create autostart entry
create_autostart_entry() {
    log "Creating mako autostart entry"
    
    local autostart_dir="$CONFIG_DIR/desktop/autostart"
    mkdir -p "$autostart_dir"
    
    local autostart_file="$autostart_dir/mako.desktop"
    
    cat > "$autostart_file" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Mako Notification Daemon
Name[en]=Mako Notification Daemon
Comment=Display notifications
Comment[en]=Display notifications
Exec=mako
Terminal=false
NoDisplay=true
Icon=dialog-information
StartupNotify=false
X-GNOME-AutoRestart=true
X-GNOME-Autostart-Phase=Initialization
X-KDE-autostart-after=panel
EOF
    
    log "✓ Mako autostart entry created"
}

# Function to create notification utilities
create_notification_utilities() {
    log "Creating notification utilities"
    
    local utils_dir="$CONFIG_DIR/desktop/utils"
    mkdir -p "$utils_dir"
    
    # Create notification test script
    cat > "$utils_dir/test-notifications.sh" << 'EOF'
#!/bin/bash
# Notification Test Script
# Tests mako notification functionality

echo "Testing mako notifications..."

# Test basic notification
notify-send "Basic Test" "This is a basic notification"
sleep 2

# Test notification with icon
notify-send -i dialog-information "Icon Test" "This notification has an icon"
sleep 2

# Test low urgency notification
notify-send -u low "Low Urgency" "This is a low urgency notification"
sleep 2

# Test high urgency notification
notify-send -u high "High Urgency" "This is a high urgency notification"
sleep 2

# Test critical notification
notify-send -u critical "Critical Alert" "This is a critical notification!"
sleep 2

# Test notification with action
notify-send -a "Test App" "Action Test" "This notification has actions" -A "Action1=Do Something" -A "Action2=Do Something Else"
sleep 2

# Test notification with progress
for i in {1..5}; do
    notify-send -t 1000 "Progress" "Step $i of 5"
    sleep 1
done

echo "Notification tests completed!"
EOF
    
    chmod +x "$utils_dir/test-notifications.sh"
    
    # Create notification control script
    cat > "$utils_dir/notification-control.sh" << 'EOF'
#!/bin/bash
# Notification Control Script
# Control mako notification daemon

case "${1:-}" in
    "start")
        echo "Starting mako notification daemon..."
        mako &
        echo "Mako started with PID $!"
        ;;
    "stop")
        echo "Stopping mako notification daemon..."
        pkill mako
        echo "Mako stopped"
        ;;
    "restart")
        echo "Restarting mako notification daemon..."
        pkill mako
        sleep 1
        mako &
        echo "Mako restarted with PID $!"
        ;;
    "status")
        if pgrep -x mako >/dev/null; then
            echo "Mako is running (PID: $(pgrep -x mako))"
        else
            echo "Mako is not running"
        fi
        ;;
    "config")
        echo "Reloading mako configuration..."
        pkill -SIGUSR1 mako
        echo "Configuration reloaded"
        ;;
    "history")
        echo "Notification history:"
        makoctl history
        ;;
    "dismiss")
        echo "Dismissing all notifications..."
        makoctl dismiss
        echo "All notifications dismissed"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|config|history|dismiss}"
        echo ""
        echo "Commands:"
        echo "  start    - Start mako daemon"
        echo "  stop     - Stop mako daemon"
        echo "  restart  - Restart mako daemon"
        echo "  status   - Show mako status"
        echo "  config   - Reload configuration"
        echo "  history  - Show notification history"
        echo "  dismiss  - Dismiss all notifications"
        ;;
esac
EOF
    
    chmod +x "$utils_dir/notification-control.sh"
    
    log "✓ Notification utilities created"
}

# Function to configure notification rules
configure_notification_rules() {
    log "Configuring notification rules"
    
    local rules_config="$CONFIG_DIR/desktop/notification-rules.conf"
    
    cat > "$rules_config" << 'EOF'
# Mako Notification Rules
# Define rules for different types of notifications

# System notifications
[app-name="systemd"]
default-timeout=10000
background-color=#4c566aee
text-color=#eceff4

# Network notifications
[app-name="NetworkManager"]
default-timeout=5000
background-color=#5e81accc
text-color=#eceff4

# Volume notifications
[app-name="pamixer"]
default-timeout=3000
background-color=#a3be8ccc
text-color=#2e3440

# Battery notifications
[app-name="upower"]
default-timeout=8000
background-color=#ebcb8bcc
text-color=#2e3440

# Email notifications
[category="email"]
default-timeout=0
background-color=#b48eadcc
text-color=#eceff4

# Instant messaging
[category="im.received"]
default-timeout=0
background-color=#88c0d0cc
text-color=#2e3440

# File transfer notifications
[category="transfer"]
default-timeout=0
background-color=#8fbcbbcc
text-color=#2e3440

# Error notifications
[urgency="critical"]
default-timeout=0
background-color=#bf616aff
text-color=#eceff4
border-color=#d08770

# Progress notifications
[category="progress"]
default-timeout=0
background-color=#434c5ecc
text-color=#eceff4
EOF
    
    log "✓ Notification rules configured"
}

# Function to verify integration
verify_integration() {
    log "Verifying mako integration"
    
    # Check if mako is available
    if command -v mako >/dev/null 2>&1; then
        local version=$(mako --version 2>/dev/null || echo "unknown")
        log "✓ Mako is installed ($version)"
    else
        error "Mako is not installed or not in PATH"
    fi
    
    # Check if makoctl is available
    if command -v makoctl >/dev/null 2>&1; then
        log "✓ Mako control utility is available"
    else
        log "⚠ Mako control utility not found"
    fi
    
    # Check if configuration directory exists
    if [ -d "$CONFIG_DIR/applications/mako" ]; then
        log "✓ Mako configuration directory exists"
    else
        error "Mako configuration directory not found"
    fi
    
    # Check if notify-send is available
    if command -v notify-send >/dev/null 2>&1; then
        log "✓ notify-send is available for testing"
    else
        log "⚠ notify-send not found - notification testing limited"
    fi
    
    log "✓ Integration verification completed"
}

# Main integration function
main() {
    log "Starting mako notification system integration"
    
    setup_environment
    setup_desktop_integration
    create_desktop_entry
    create_autostart_entry
    create_notification_utilities
    configure_notification_rules
    verify_integration
    
    log "✓ Mako notification system integration completed successfully"
}

# Handle script arguments
case "${1:-}" in
    "environment")
        setup_environment
        ;;
    "desktop")
        setup_desktop_integration
        ;;
    "autostart")
        create_autostart_entry
        ;;
    "utilities")
        create_notification_utilities
        ;;
    "rules")
        configure_notification_rules
        ;;
    "verify")
        verify_integration
        ;;
    *)
        main
        ;;
esac