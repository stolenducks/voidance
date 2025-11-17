#!/bin/bash

# setup-network-permissions.sh
# Configure network permissions and groups for Voidance Linux
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

log "Configuring network permissions and groups..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
    exit 1
fi

# Create network group if it doesn't exist
if ! getent group network >/dev/null 2>&1; then
    log "Creating network group..."
    groupadd -r network
    success "Network group created"
else
    success "Network group already exists"
fi

# Create netdev group if it doesn't exist (for network device access)
if ! getent group netdev >/dev/null 2>&1; then
    log "Creating netdev group..."
    groupadd -r netdev
    success "Netdev group created"
else
    success "Netdev group already exists"
fi

# Add current user to network groups if not root
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    log "Adding user $SUDO_USER to network groups..."
    
    # Add to network group
    if ! groups "$SUDO_USER" | grep -q '\bnetwork\b'; then
        usermod -aG network "$SUDO_USER"
        success "Added $SUDO_USER to network group"
    else
        success "$SUDO_USER already in network group"
    fi
    
    # Add to netdev group
    if ! groups "$SUDO_USER" | grep -q '\bnetdev\b'; then
        usermod -aG netdev "$SUDO_USER"
        success "Added $SUDO_USER to netdev group"
    else
        success "$SUDO_USER already in netdev group"
    fi
fi

# Create NetworkManager configuration directory
mkdir -p /etc/NetworkManager/conf.d
mkdir -p /etc/NetworkManager/system-connections

# Set proper permissions for NetworkManager directories
log "Setting directory permissions..."
chmod 755 /etc/NetworkManager
chmod 755 /etc/NetworkManager/conf.d
chmod 700 /etc/NetworkManager/system-connections
chown root:root /etc/NetworkManager/system-connections
success "Directory permissions set"

# Install NetworkManager configuration
if [ -f /home/stolenducks/Projects/Voidance/config/NetworkManager.conf ]; then
    log "Installing NetworkManager configuration..."
    cp /home/stolenducks/Projects/Voidance/config/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf
    chown root:root /etc/NetworkManager/NetworkManager.conf
    chmod 644 /etc/NetworkManager/NetworkManager.conf
    success "NetworkManager configuration installed"
else
    warning "NetworkManager configuration not found"
fi

# Create NetworkManager system connection directory
mkdir -p /etc/NetworkManager/system-connections
chmod 700 /etc/NetworkManager/system-connections
chown root:root /etc/NetworkManager/system-connections

# Create polkit rules for network management
log "Creating polkit rules for network management..."
mkdir -p /etc/polkit-1/rules.d

cat > /etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager.rules << 'EOF'
// NetworkManager polkit rules for Voidance Linux
// Allow users in network group to control network connections

polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 && 
        subject.isInGroup("network")) {
        return polkit.Result.YES;
    }
});
EOF

chown root:root /etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager.rules
chmod 644 /etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager.rules
success "Polkit rules created"

# Create NetworkManager configuration for better desktop integration
log "Creating desktop integration configuration..."
cat > /etc/NetworkManager/conf.d/voidance-desktop.conf << 'EOF'
# Voidance Linux desktop integration
# Optimized settings for desktop use

[main]
# Enable Wi-Fi randomization for privacy
wifi.scan-rand-mac-address=yes

[connection]
# Enable IPv6 privacy
ipv6.ip6-privacy=1

[device]
# Enable Wi-Fi power saving
wifi.powersave=3

# Enable autoconnect for wired connections
ethernet.auto-negotiate=yes
EOF

chown root:root /etc/NetworkManager/conf.d/voidance-desktop.conf
chmod 644 /etc/NetworkManager/conf.d/voidance-desktop.conf
success "Desktop integration configuration created"

# Create udev rules for network devices
log "Creating udev rules for network devices..."
mkdir -p /etc/udev/rules.d

cat > /etc/udev/rules.d/99-network.rules << 'EOF'
# Network device permissions for Voidance Linux
# Allow users in netdev group to access network devices

# Ethernet devices
KERNEL=="eth*", GROUP="netdev", MODE="0660"
# Wireless devices
KERNEL=="wlan*", GROUP="netdev", MODE="0660"
# Generic network devices
KERNEL=="net*", GROUP="netdev", MODE="0660"
EOF

chown root:root /etc/udev/rules.d/99-network.rules
chmod 644 /etc/udev/rules.d/99-network.rules
success "Udev rules created"

# Reload udev rules
if command -v udevadm >/dev/null 2>&1; then
    log "Reloading udev rules..."
    udevadm control --reload-rules
    udevadm trigger
    success "Udev rules reloaded"
fi

log "Network permissions and groups configuration completed!"
echo
success "Network setup is ready for use."
echo
log "Next steps:"
log "1. Enable NetworkManager service: ln -s /etc/sv/NetworkManager /var/service/"
log "2. Start NetworkManager: sv up NetworkManager"
log "3. Use nmcli or nmtui to configure network connections"
log "4. Add users to network and netdev groups for GUI control"
echo
log "Network management tools:"
log "  nmcli - Command line interface"
log "  nmtui - Text user interface"
log "  nm-connection-editor - GUI connection editor"
log "  network-manager-applet - System tray applet"