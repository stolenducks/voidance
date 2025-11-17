#!/bin/bash

# setup-audio-permissions.sh
# Configure audio permissions and groups for Voidance Linux
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

log "Configuring audio permissions and groups..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
    exit 1
fi

# Create audio group if it doesn't exist
if ! getent group audio >/dev/null 2>&1; then
    log "Creating audio group..."
    groupadd -r audio
    success "Audio group created"
else
    success "Audio group already exists"
fi

# Add current user to audio group if not root
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    log "Adding user $SUDO_USER to audio group..."
    
    if ! groups "$SUDO_USER" | grep -q '\baudio\b'; then
        usermod -aG audio "$SUDO_USER"
        success "Added $SUDO_USER to audio group"
    else
        success "$SUDO_USER already in audio group"
    fi
fi

# Create PipeWire configuration directories
log "Creating PipeWire configuration directories..."
mkdir -p /etc/pipewire/pipewire.conf.d
mkdir -p /etc/pipewire/pipewire-pulse.conf.d
mkdir -p /etc/wireplumber
mkdir -p /etc/wireplumber/bluetooth
mkdir -p /etc/wireplumber/main
mkdir -p /var/run/pipewire

# Set proper permissions for PipeWire directories
log "Setting directory permissions..."
chmod 755 /etc/pipewire
chmod 755 /etc/pipewire/pipewire.conf.d
chmod 755 /etc/pipewire/pipewire-pulse.conf.d
chmod 755 /etc/wireplumber
chmod 755 /etc/wireplumber/bluetooth
chmod 755 /etc/wireplumber/main
chmod 755 /var/run/pipewire
success "Directory permissions set"

# Create PipeWire configuration for better desktop integration
log "Creating PipeWire desktop configuration..."
cat > /etc/pipewire/pipewire.conf.d/voidance-desktop.conf << 'EOF'
# Voidance Linux PipeWire desktop configuration
# Optimized settings for desktop audio

context.properties = {
    # Default clock quantum
    default.clock.quantum = 1024
    
    # Default clock rate
    default.clock.rate = 48000
    
    # Default allowed sample rates
    default.clock.allowed-rates = [ 44100, 48000, 88200, 96000, 176400, 192000 ]
    
    # Enable memfd support
    mem.allow-mlock = true
    
    # Enable log level
    log.level = 2
}

context.modules = [
    { name = libpipewire-module-rt
        args = {
            nice.level   = -11
            rt.prio      = 88
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
    
    { name = libpipewire-module-protocol-native }
    
    { name = libpipewire-module-client-node }
    
    { name = libpipewire-module-adapter }
    
    { name = libpipewire-module-metadata }
]

stream.properties = {
    # Default node properties
    node.latency = "1024/48000"
    node.autoconnect = true
    node.dont-reconnect = false
}
EOF

chown root:root /etc/pipewire/pipewire.conf.d/voidance-desktop.conf
chmod 644 /etc/pipewire/pipewire.conf.d/voidance-desktop.conf
success "PipeWire desktop configuration created"

# Create PipeWire Pulse Audio configuration
log "Creating PipeWire Pulse Audio configuration..."
cat > /etc/pipewire/pipewire-pulse.conf.d/voidance-pulse.conf << 'EOF'
# Voidance Linux PipeWire Pulse Audio configuration
# Pulse Audio compatibility settings

context.modules = [
    { name = libpipewire-module-protocol-pulse }
]

pulse.properties = {
    # Server address
    server.address = [ "unix:native" ]
    
    # Sample rate
    pulse.min.req = "256/48000"
    pulse.default.req = "960/48000"
    pulse.max.req = "1920/48000"
    
    # Audio rate
    pulse.min.quantum = "256/48000"
    pulse.default.quantum = "960/48000"
    pulse.max.quantum = "1920/48000"
}

stream.rules = [
    {
        matches = [
            { application.name = "pw-cat" }
        ]
        actions = {
            quirks = [ force-s16-info ]
        }
    }
]
EOF

chown root:root /etc/pipewire/pipewire-pulse.conf.d/voidance-pulse.conf
chmod 644 /etc/pipewire/pipewire-pulse.conf.d/voidance-pulse.conf
success "PipeWire Pulse Audio configuration created"

# Create WirePlumber configuration
log "Creating WirePlumber configuration..."
cat > /etc/wireplumber/wireplumber.conf << 'EOF'
# Voidance Linux WirePlumber configuration
# Session manager for PipeWire

context.properties = {
    # Library name
    library.name.system = "libwireplumber-system"
    
    # Connection properties
    connection.id = "wireplumber"
}

context.spa-libs = {
    audio.convert.* = audioconvert/libspa-audioconvert
    support.*       = support/libspa-support
}

context.modules = [
    { name = libpipewire-module-rtkit
        args = {
            nice.level   = -11
            rt.prio      = 88
            rt.time.soft = -1
            rt.time.hard = -1
        }
        flags = [ ifexists nofail ]
    }
    
    { name = libpipewire-module-protocol-native }
    
    { name = libpipewire-module-client-node }
    
    { name = libpipewire-module-adapter }
    
    { name = libpipewire-module-metadata }
]

wireplumber.components = [
    { name = libwireplumber-module-rtkit, provides = [ "rtkit" ] }
    { name = libwireplumber-module-spa-device-factory, provides = [ "spa-device-factory" ] }
    { name = libwireplumber-module-spa-node-factory, provides = [ "spa-node-factory" ] }
    { name = libwireplumber-module-access-default, provides = [ "access-default" ] }
    { name = libwireplumber-module-access-flatpak, provides = [ "access-flatpak" ] }
    { name = libwireplumber-module-api-alsa-monitor, provides = [ "api-alsa-monitor" ] }
    { name = libwireplumber-module-api-bluez5-monitor, provides = [ "api-bluez5-monitor" ] }
    { name = libwireplumber-module-default-nodes, provides = [ "default-nodes" ] }
    { name = libwireplumber-module-default-profile, provides = [ "default-profile" ] }
    { name = libwireplumber-module-device-activation, provides = [ "device-activation" ] }
    { name = libwireplumber-module-rescan-devices, provides = [ "rescan-devices" ] }
    { name = libwireplumber-module-link-factory, provides = [ "link-factory" ] }
    { name = libwireplumber-module-session-manager, provides = [ "session-manager" ] }
]
EOF

chown root:root /etc/wireplumber/wireplumber.conf
chmod 644 /etc/wireplumber/wireplumber.conf
success "WirePlumber configuration created"

# Create udev rules for audio devices
log "Creating udev rules for audio devices..."
mkdir -p /etc/udev/rules.d

cat > /etc/udev/rules.d/99-audio.rules << 'EOF'
# Audio device permissions for Voidance Linux
# Allow users in audio group to access audio devices

# ALSA devices
KERNEL=="controlC[0-9]*", GROUP="audio", MODE="0660"
KERNEL=="hwC[0-9]*", GROUP="audio", MODE="0660"
KERNEL=="pcmC[0-9]*", GROUP="audio", MODE="0660"
KERNEL=="midiC[0-9]*", GROUP="audio", MODE="0660"
KERNEL=="timer", GROUP="audio", MODE="0660"
KERNEL=="seq", GROUP="audio", MODE="0660"

# OSS devices
KERNEL=="dsp*", GROUP="audio", MODE="0660"
KERNEL=="adsp*", GROUP="audio", MODE="0660"
KERNEL=="audio*", GROUP="audio", MODE="0660"
KERNEL=="mixer*", GROUP="audio", MODE="0660"
KERNEL=="sequencer*", GROUP="audio", MODE="0660"

# sndio devices
KERNEL=="sndio*", GROUP="audio", MODE="0660"

# PipeWire socket
RUN+="/bin/chgrp audio /var/run/pipewire"
RUN+="/bin/chmod 775 /var/run/pipewire"
EOF

chown root:root /etc/udev/rules.d/99-audio.rules
chmod 644 /etc/udev/rules.d/99-audio.rules
success "Udev rules created"

# Create limits configuration for audio
log "Creating limits configuration for audio..."
mkdir -p /etc/security/limits.d

cat > /etc/security/limits.d/99-audio.conf << 'EOF'
# Audio limits configuration for Voidance Linux
# Allow real-time scheduling for audio applications

@audio   -  rtprio     95
@audio   -  memlock    unlimited
EOF

chown root:root /etc/security/limits.d/99-audio.conf
chmod 644 /etc/security/limits.d/99-audio.conf
success "Limits configuration created"

# Reload udev rules
if command -v udevadm >/dev/null 2>&1; then
    log "Reloading udev rules..."
    udevadm control --reload-rules
    udevadm trigger
    success "Udev rules reloaded"
fi

log "Audio permissions and groups configuration completed!"
echo
success "Audio setup is ready for use."
echo
log "Next steps:"
log "1. Enable audio services:"
log "   ln -s /etc/sv/pipewire /var/service/"
log "   ln -s /etc/sv/pipewire-pulse /var/service/"
log "   ln -s /etc/sv/wireplumber /var/service/"
log "2. Start audio services:"
log "   sv up pipewire pipewire-pulse wireplumber"
log "3. Add users to audio group for audio access"
log "4. Test audio with: speaker-test -c 2"
echo
log "Audio control tools:"
log "  wpctl - PipeWire command line control"
log "  pavucontrol - PulseAudio volume control (GUI)"
log "  pactl - PulseAudio command line control"
log "  alsamixer - ALSA mixer (text interface)"