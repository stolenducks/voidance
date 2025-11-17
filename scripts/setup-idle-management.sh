#!/bin/bash

# setup-idle-management.sh
# Configure idle management and screen locking for Voidance Linux
# Part of system services setup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log "Configuring idle management and screen locking..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
    exit 1
fi

# Create configuration directory
log "Creating idle management configuration directory..."
mkdir -p /etc/voidance/idle
mkdir -p /usr/share/voidance/idle
success "Configuration directories created"

# Create default idle configuration
log "Creating default idle configuration..."
cat > /etc/voidance/idle/config << 'EOF'
# Voidance Linux idle management configuration
# Default settings for screen locking and power management

# Idle timeouts (in seconds)
IDLE_TIMEOUT=300                    # 5 minutes before screen lock
LOCK_TIMEOUT=600                    # 10 minutes before screen off
SUSPEND_TIMEOUT=1800                # 30 minutes before suspend

# Screen lock settings
LOCK_ENABLED=true
LOCK_COMMAND="swaylock -f -c 000000"

# Screen off settings
SCREEN_OFF_ENABLED=true
SCREEN_OFF_COMMAND="swaymsg 'output * power off'"

# Suspend settings
SUSPEND_ENABLED=true
SUSPEND_COMMAND="systemctl suspend"

# Resume settings
RESUME_COMMAND="swaymsg 'output * power on'"

# Notification settings
NOTIFY_ENABLED=true
NOTIFY_BEFORE_LOCK=30               # Notify 30 seconds before lock
NOTIFY_LOCK_MESSAGE="Screen will lock in 30 seconds"
NOTIFY_LOCK_ICON="dialog-information"

# Battery-based idle management
BATTERY_IDLE_ENABLED=true
BATTERY_IDLE_TIMEOUT=180            # 3 minutes on battery
BATTERY_LOCK_TIMEOUT=300            # 5 minutes on battery
BATTERY_SUSPEND_TIMEOUT=900         # 15 minutes on battery
EOF

chown root:root /etc/voidance/idle/config
chmod 644 /etc/voidance/idle/config
success "Default idle configuration created"

# Create swayidle configuration script
log "Creating swayidle configuration script..."
cat > /usr/share/voidance/idle/swayidle-config.sh << 'EOF'
#!/bin/bash

# swayidle configuration script for Voidance Linux
# Generates swayidle command based on configuration

# Source configuration
if [ -f /etc/voidance/idle/config ]; then
    . /etc/voidance/idle/config
else
    echo "Error: Configuration file not found"
    exit 1
fi

# Check if on battery power
on_battery() {
    if command -v upower >/dev/null 2>&1; then
        upower -i $(upower -e | grep BAT) | grep -q "state.*discharging"
    elif [ -f /sys/class/power_supply/BAT0/status ]; then
        grep -q "Discharging" /sys/class/power_supply/BAT0/status
    else
        return 1
    fi
}

# Determine timeouts based on power source
if [ "$BATTERY_IDLE_ENABLED" = true ] && on_battery; then
    IDLE_TIMEOUT=$BATTERY_IDLE_TIMEOUT
    LOCK_TIMEOUT=$BATTERY_LOCK_TIMEOUT
    SUSPEND_TIMEOUT=$BATTERY_SUSPEND_TIMEOUT
fi

# Build swayidle command
SWAYIDLE_CMD="swayidle -w"

# Add idle timeout
if [ "$LOCK_ENABLED" = true ]; then
    SWAYIDLE_CMD="$SWAYIDLE_CMD timeout $IDLE_TIMEOUT '$LOCK_COMMAND'"
fi

# Add lock timeout
if [ "$SCREEN_OFF_ENABLED" = true ]; then
    SWAYIDLE_CMD="$SWAYIDLE_CMD timeout $LOCK_TIMEOUT '$SCREEN_OFF_COMMAND'"
fi

# Add suspend timeout
if [ "$SUSPEND_ENABLED" = true ]; then
    SWAYIDLE_CMD="$SWAYIDLE_CMD timeout $SUSPEND_TIMEOUT '$SUSPEND_COMMAND'"
fi

# Add resume command
if [ -n "$RESUME_COMMAND" ]; then
    SWAYIDLE_CMD="$SWAYIDLE_CMD resume '$RESUME_COMMAND'"
fi

# Add before-sleep hook
if [ "$LOCK_ENABLED" = true ]; then
    SWAYIDLE_CMD="$SWAYIDLE_CMD before-sleep '$LOCK_COMMAND'"
fi

echo "$SWAYIDLE_CMD"
EOF

chown root:root /usr/share/voidance/idle/swayidle-config.sh
chmod 755 /usr/share/voidance/idle/swayidle-config.sh
success "swayidle configuration script created"

# Create idle management startup script
log "Creating idle management startup script..."
cat > /usr/share/voidance/idle/start-idle.sh << 'EOF'
#!/bin/bash

# Idle management startup script for Voidance Linux
# Starts swayidle with proper configuration

# Source configuration
if [ -f /etc/voidance/idle/config ]; then
    . /etc/voidance/idle/config
else
    echo "Error: Configuration file not found"
    exit 1
fi

# Check if swayidle is available
if ! command -v swayidle >/dev/null 2>&1; then
    echo "Error: swayidle not found"
    exit 1
fi

# Check if swaylock is available
if [ "$LOCK_ENABLED" = true ] && ! command -v swaylock >/dev/null 2>&1; then
    echo "Warning: swaylock not found, screen locking disabled"
    LOCK_ENABLED=false
fi

# Generate swayidle command
SWAYIDLE_CMD=$(/usr/share/voidance/idle/swayidle-config.sh)

# Start swayidle
echo "Starting idle management..."
echo "Command: $SWAYIDLE_CMD"
exec $SWAYIDLE_CMD
EOF

chown root:root /usr/share/voidance/idle/start-idle.sh
chmod 755 /usr/share/voidance/idle/start-idle.sh
success "Idle management startup script created"

# Create idle notification script
log "Creating idle notification script..."
cat > /usr/share/voidance/idle/notify-lock.sh << 'EOF'
#!/bin/bash

# Idle notification script for Voidance Linux
# Shows notification before screen lock

# Source configuration
if [ -f /etc/voidance/idle/config ]; then
    . /etc/voidance/idle/config
else
    echo "Error: Configuration file not found"
    exit 1
fi

# Check if notifications are enabled
if [ "$NOTIFY_ENABLED" != true ]; then
    exit 0
fi

# Check if notify-send is available
if ! command -v notify-send >/dev/null 2>&1; then
    echo "Warning: notify-send not found, notifications disabled"
    exit 0
fi

# Show notification
if [ -n "$NOTIFY_LOCK_MESSAGE" ]; then
    notify-send -u normal -t 10000 -i "$NOTIFY_LOCK_ICON" \
        "Screen Lock" "$NOTIFY_LOCK_MESSAGE"
fi
EOF

chown root:root /usr/share/voidance/idle/notify-lock.sh
chmod 755 /usr/share/voidance/idle/notify-lock.sh
success "Idle notification script created"

# Create swaylock configuration
log "Creating swaylock configuration..."
mkdir -p /etc/swaylock

cat > /etc/swaylock/config << 'EOF'
# swaylock configuration for Voidance Linux
# Screen lock settings

# Colors
color=000000ff
bs-color=000000ff
inside-color=00000088
ring-color=458588ff
line-color=458588ff
text-color=ebdbb2ff
text-clear-color=ebdbb2ff
text-caps-lock-color=fabd2fff
text-ver-color=8ec07cff
text-wrong-color=fb4934ff

# Ring colors
inside-clear-color=00000000
inside-ver-color=45858888
inside-wrong-color=cc241d88
ring-clear-color=8ec07cff
ring-ver-color=8ec07cff
ring-wrong-color=fb4934ff

# Key handling
ignore-empty-password
show-keyboard-layout
show-failed-attempts

# Screens
screenshots
effect-blur=7x5
effect-vignette=0.5:0.5
fade-in=0.2

# Clock
clock
timestr=%H:%M:%S
datestr=%Y-%m-%d

# Font
font=monospace

# Indicator
indicator
indicator-radius=100
indicator-thickness=20
EOF

chown root:root /etc/swaylock/config
chmod 644 /etc/swaylock/config
success "swaylock configuration created"

# Create systemd user service for idle management (for compatibility)
log "Creating systemd user service for idle management..."
mkdir -p /usr/lib/systemd/user

cat > /usr/lib/systemd/user/voidance-idle.service << 'EOF'
[Unit]
Description=Voidance Linux Idle Management
Documentation=man:swayidle(1)
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/share/voidance/idle/start-idle.sh
ExecReload=/bin/kill -USR1 $MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

chown root:root /usr/lib/systemd/user/voidance-idle.service
chmod 644 /usr/lib/systemd/user/voidance-idle.service
success "Systemd user service created"

# Create desktop integration script
log "Creating desktop integration script..."
cat > /usr/share/voidance/idle/desktop-integration.sh << 'EOF'
#!/bin/bash

# Desktop integration script for Voidance Linux idle management
# Integrates idle management with desktop environments

# Source configuration
if [ -f /etc/voidance/idle/config ]; then
    . /etc/voidance/idle/config
fi

# Function to start idle management in Wayland
start_wayland_idle() {
    if [ -n "$WAYLAND_DISPLAY" ]; then
        # Check if swayidle is already running
        if ! pgrep -x swayidle >/dev/null; then
            /usr/share/voidance/idle/start-idle.sh &
        fi
    fi
}

# Function to start idle management in X11
start_x11_idle() {
    if [ -n "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        # Use xautolock for X11 if available
        if command -v xautolock >/dev/null 2>&1; then
            xautolock -time 10 -locker "swaylock -f -c 000000" &
        fi
    fi
}

# Start appropriate idle management
case "${1:-auto}" in
    "wayland")
        start_wayland_idle
        ;;
    "x11")
        start_x11_idle
        ;;
    "auto"|*)
        if [ -n "$WAYLAND_DISPLAY" ]; then
            start_wayland_idle
        elif [ -n "$DISPLAY" ]; then
            start_x11_idle
        fi
        ;;
esac
EOF

chown root:root /usr/share/voidance/idle/desktop-integration.sh
chmod 755 /usr/share/voidance/idle/desktop-integration.sh
success "Desktop integration script created"

log "Idle management and screen locking configuration completed!"
echo
success "Idle management is ready for use."
echo
log "Configuration files:"
log "  /etc/voidance/idle/config - Main configuration"
log "  /etc/swaylock/config - Screen lock appearance"
echo
log "Usage:"
log "  /usr/share/voidance/idle/start-idle.sh - Start idle management"
log "  /usr/share/voidance/idle/desktop-integration.sh - Desktop integration"
log "  swaylock -f -c 000000 - Manual screen lock"
echo
log "Integration with desktop environments:"
log "  Add to niri config: exec-on-startup = /usr/share/voidance/idle/desktop-integration.sh"
log "  Enable systemd service: systemctl --user enable voidance-idle.service"
log "  Test idle: swayidle -w timeout 10 'echo \"Idle detected\"'"