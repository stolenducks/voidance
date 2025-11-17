#!/bin/bash
# Voidance System Services and Startup Configuration
# This script configures all system services and startup processes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[SERVICES]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Root filesystem base directory
ROOTFS_BASE="${1:-/opt/voidance-iso/work/rootfs}"

# Function to create runit service
create_runit_service() {
    local service_name="$1"
    local run_content="$2"
    local finish_content="${3:-}"
    local log_content="${4:-}"
    
    local service_dir="$ROOTFS_BASE/etc/sv/$service_name"
    
    # Create service directory
    mkdir -p "$service_dir"
    
    # Create run script
    cat > "$service_dir/run" << EOF
#!/bin/bash
# Voidance Runit Service: $service_name
$run_content
EOF
    chmod +x "$service_dir/run"
    
    # Create finish script if provided
    if [[ -n "$finish_content" ]]; then
        cat > "$service_dir/finish" << EOF
#!/bin/bash
# Voidance Runit Service Finish: $service_name
$finish_content
EOF
        chmod +x "$service_dir/finish"
    fi
    
    # Create log directory and script if provided
    if [[ -n "$log_content" ]]; then
        mkdir -p "$service_dir/log"
        cat > "$service_dir/log/run" << EOF
#!/bin/bash
# Voidance Runit Service Log: $service_name
$log_content
EOF
        chmod +x "$service_dir/log/run"
    fi
    
    log "Created runit service: $service_name"
}

# Function to create essential system services
create_essential_services() {
    log "Creating essential system services..."
    
    # Getty service for TTY1
    create_runit_service "getty-1" \
        "exec /sbin/agetty --noclear --login-pause tty1 38400 linux" \
        "" \
        "exec svlogd -tt /var/log/getty-1"
    
    # Getty service for TTY2
    create_runit_service "getty-2" \
        "exec /sbin/agetty --noclear --login-pause tty2 38400 linux" \
        "" \
        "exec svlogd -tt /var/log/getty-2"
    
    # Getty service for TTY3
    create_runit_service "getty-3" \
        "exec /sbin/agetty --noclear --login-pause tty3 38400 linux" \
        "" \
        "exec svlogd -tt /var/log/getty-3"
    
    # Getty service for TTY4
    create_runit_service "getty-4" \
        "exec /sbin/agetty --noclear --login-pause tty4 38400 linux" \
        "" \
        "exec svlogd -tt /var/log/getty-4"
    
    # Getty service for TTY5
    create_runit_service "getty-5" \
        "exec /sbin/agetty --noclear --login-pause tty5 38400 linux" \
        "" \
        "exec svlogd -tt /var/log/getty-5"
    
    # Getty service for TTY6
    create_runit_service "getty-6" \
        "exec /sbin/agetty --noclear --login-pause tty6 38400 linux" \
        "" \
        "exec svlogd -tt /var/log/getty-6"
    
    # Sulogin service for single user mode
    create_runit_service "sulogin" \
        "exec /sbin/sulogin /dev/console" \
        "" \
        "exec svlogd -tt /var/log/sulogin"
    
    success "Essential system services created"
}

# Function to create network services
create_network_services() {
    log "Creating network services..."
    
    # NetworkManager service
    create_runit_service "NetworkManager" \
        "exec /usr/sbin/NetworkManager --no-daemon" \
        "killall NetworkManager 2>/dev/null || true" \
        "exec svlogd -tt /var/log/NetworkManager"
    
    # dhcpcd service (fallback)
    create_runit_service "dhcpcd" \
        "exec /usr/sbin/dhcpcd -B" \
        "killall dhcpcd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/dhcpcd"
    
    # sshd service
    create_runit_service "sshd" \
        "exec /usr/sbin/sshd -D" \
        "killall sshd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/sshd"
    
    # udev service
    create_runit_service "udevd" \
        "exec /usr/sbin/udevd --daemon" \
        "killall udevd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/udevd"
    
    success "Network services created"
}

# Function to create audio services
create_audio_services() {
    log "Creating audio services..."
    
    # PipeWire service
    create_runit_service "pipewire" \
        "exec /usr/bin/pipewire" \
        "killall pipewire 2>/dev/null || true" \
        "exec svlogd -tt /var/log/pipewire"
    
    # PipeWire Pulse service
    create_runit_service "pipewire-pulse" \
        "exec /usr/bin/pipewire-pulse" \
        "killall pipewire-pulse 2>/dev/null || true" \
        "exec svlogd -tt /var/log/pipewire-pulse"
    
    # WirePlumber service
    create_runit_service "wireplumber" \
        "exec /usr/bin/wireplumber" \
        "killall wireplumber 2>/dev/null || true" \
        "exec svlogd -tt /var/log/wireplumber"
    
    success "Audio services created"
}

# Function to create desktop services
create_desktop_services() {
    log "Creating desktop services..."
    
    # SDDM service
    create_runit_service "sddm" \
        "exec /usr/bin/sddm" \
        "killall sddm 2>/dev/null || true" \
        "exec svlogd -tt /var/log/sddm"
    
    # D-Bus service
    create_runit_service "dbus" \
        "exec /usr/bin/dbus-daemon --system --nofork" \
        "killall dbus-daemon 2>/dev/null || true" \
        "exec svlogd -tt /var/log/dbus"
    
    # Polkit service
    create_runit_service "polkitd" \
        "exec /usr/lib/polkit-1/polkitd --no-debug" \
        "killall polkitd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/polkitd"
    
    # Seatd service
    create_runit_service "seatd" \
        "exec /usr/sbin/seatd -g video" \
        "killall seatd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/seatd"
    
    # Elogind service
    create_runit_service "elogind" \
        "exec /usr/lib/elogind/elogind" \
        "killall elogind 2>/dev/null || true" \
        "exec svlogd -tt /var/log/elogind"
    
    success "Desktop services created"
}

# Function to create hardware services
create_hardware_services() {
    log "Creating hardware services..."
    
    # Bluetooth service
    create_runit_service "bluetooth" \
        "exec /usr/lib/bluetooth/bluetoothd" \
        "killall bluetoothd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/bluetooth"
    
    # CUPS service
    create_runit_service "cupsd" \
        "exec /usr/sbin/cupsd -f" \
        "killall cupsd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/cupsd"
    
    # TLP service (laptop power management)
    create_runit_service "tlp" \
        "exec /usr/sbin/tlp start" \
        "/usr/sbin/tlp stop" \
        "exec svlogd -tt /var/log/tlp"
    
    # Thermald service (thermal management)
    create_runit_service "thermald" \
        "exec /usr/sbin/thermald --no-daemon" \
        "killall thermald 2>/dev/null || true" \
        "exec svlogd -tt /var/log/thermald"
    
    success "Hardware services created"
}

# Function to create security services
create_security_services() {
    log "Creating security services..."
    
    # UFW service
    create_runit_service "ufw" \
        "exec /usr/sbin/ufw --force enable" \
        "/usr/sbin/ufw disable" \
        "exec svlogd -tt /var/log/ufw"
    
    # Fail2ban service
    create_runit_service "fail2ban" \
        "exec /usr/bin/fail2ban-server -xf start" \
        "/usr/bin/fail2ban-client stop" \
        "exec svlogd -tt /var/log/fail2ban"
    
    # rkhunter service
    create_runit_service "rkhunter" \
        "exec /usr/bin/rkhunter --check --skip-keypress --report-warnings-only" \
        "" \
        "exec svlogd -tt /var/log/rkhunter"
    
    success "Security services created"
}

# Function to create system maintenance services
create_maintenance_services() {
    log "Creating system maintenance services..."
    
    # Log rotation service
    create_runit_service "logrotate" \
        "exec /usr/sbin/logrotate -f /etc/logrotate.conf" \
        "" \
        "exec svlogd -tt /var/log/logrotate"
    
    # Package cache cleanup service
    create_runit_service "pkg-cleanup" \
        "exec /usr/sbin/xbps-remove -O" \
        "" \
        "exec svlogd -tt /var/log/pkg-cleanup"
    
    # System update service
    create_runit_service "sys-update" \
        "exec /usr/sbin/xbps-install -Syu" \
        "" \
        "exec svlogd -tt /var/log/sys-update"
    
    # Filesystem check service
    create_runit_service "fsck" \
        "exec /sbin/fsck -A -R -T" \
        "" \
        "exec svlogd -tt /var/log/fsck"
    
    success "System maintenance services created"
}

# Function to create virtualization services
create_virtualization_services() {
    log "Creating virtualization services..."
    
    # Libvirt service
    create_runit_service "libvirtd" \
        "exec /usr/sbin/libvirtd --daemon" \
        "killall libvirtd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/libvirtd"
    
    # Virtlogd service
    create_runit_service "virtlogd" \
        "exec /usr/sbin/virtlogd --daemon" \
        "killall virtlogd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/virtlogd"
    
    # Docker service
    create_runit_service "docker" \
        "exec /usr/bin/dockerd" \
        "killall dockerd 2>/dev/null || true" \
        "exec svlogd -tt /var/log/docker"
    
    # Podman service
    create_runit_service "podman" \
        "exec /usr/bin/podman system service --time=0" \
        "killall podman 2>/dev/null || true" \
        "exec svlogd -tt /var/log/podman"
    
    success "Virtualization services created"
}

# Function to create Voidance-specific services
create_voidance_services() {
    log "Creating Voidance-specific services..."
    
    # Voidance hardware detection service
    create_runit_service "voidance-hw-detect" \
        "exec /usr/lib/voidance/scripts/hardware-detection.sh" \
        "" \
        "exec svlogd -tt /var/log/voidance-hw-detect"
    
    # Voidance system tuning service
    create_runit_service "voidance-tuning" \
        "exec /usr/lib/voidance/scripts/system-tuning.sh" \
        "" \
        "exec svlogd -tt /var/log/voidance-tuning"
    
    # Voidance user setup service
    create_runit_service "voidance-user-setup" \
        "exec /usr/lib/voidance/scripts/user-setup.sh" \
        "" \
        "exec svlogd -tt /var/log/voidance-user-setup"
    
    # Voidance first boot service
    create_runit_service "voidance-firstboot" \
        "exec /usr/lib/voidance/scripts/first-boot.sh" \
        "" \
        "exec svlogd -tt /var/log/voidance-firstboot"
    
    # Voidance session manager
    create_runit_service "voidance-session" \
        "exec /usr/lib/voidance/scripts/session-manager.sh" \
        "" \
        "exec svlogd -tt /var/log/voidance-session"
    
    success "Voidance-specific services created"
}

# Function to create service configuration files
create_service_configs() {
    log "Creating service configuration files..."
    
    # Runit configuration
    cat > "$ROOTFS_BASE/etc/runit/func" << 'EOF'
# Voidance Runit Functions
# Common functions for runit scripts

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for service
wait_for_service() {
    local timeout=$1
    local service=$2
    
    for i in $(seq 1 $timeout); do
        if sv status "$service" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# Function to check network
check_network() {
    ip link show >/dev/null 2>&1
}

# Function to check filesystem
check_filesystem() {
    mountpoint -q / && mountpoint -q /usr
}

# Function to load kernel modules
load_modules() {
    local modules_file="$1"
    
    if [[ -f "$modules_file" ]]; then
        while read -r module; do
            [[ "$module" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$module" ]] && continue
            modprobe "$module" 2>/dev/null || true
        done < "$modules_file"
    fi
}

# Function to set sysctl parameters
set_sysctl() {
    local sysctl_file="$1"
    
    if [[ -f "$sysctl_file" ]]; then
        sysctl -p "$sysctl_file" 2>/dev/null || true
    fi
}
EOF
    
    # Service startup order
    cat > "$ROOTFS_BASE/etc/runit/runsvdir-default" << 'EOF'
#!/bin/bash
# Voidance Runit Service Directory
# Default service startup order

# Essential services (must start first)
getty-1
getty-2
getty-3
getty-4
getty-5
getty-6
sulogin

# System services
udevd
dbus
elogind

# Network services
NetworkManager
dhcpcd
sshd

# Hardware services
bluetooth
cupsd
tlp
thermald

# Desktop services
seatd
polkitd
sddm

# Audio services
pipewire
pipewire-pulse
wireplumber

# Security services
ufw
fail2ban

# Virtualization services
libvirtd
virtlogd
docker
podman

# Voidance services
voidance-hw-detect
voidance-tuning
voidance-user-setup
voidance-firstboot
voidance-session

# Maintenance services
logrotate
pkg-cleanup
sys-update
fsck
EOF
    chmod +x "$ROOTFS_BASE/etc/runit/runsvdir-default"
    
    # Service environment
    cat > "$ROOTFS_BASE/etc/runit/env" << 'EOF'
# Voidance Runit Environment
# Environment variables for runit services

# System environment
PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
SHELL="/bin/bash"
USER="root"
HOME="/root"
LOGNAME="root"

# Service-specific environment
SVDIR="/etc/sv"
SVWAIT="7"
SVLOGD_OPTS="-tt"

# Logging
LOGDIR="/var/log"
LOGLEVEL="info"

# Network
NETWORK_WAIT="30"
NETWORK_TIMEOUT="60"

# Hardware
MODULES_LOAD="/etc/modules-load.d"
SYSCTL_CONF="/etc/sysctl.conf"

# Desktop
DISPLAY_MANAGER="sddm"
SESSION_TYPE="wayland"

# Audio
AUDIO_SYSTEM="pipewire"

# Security
FIREWALL="ufw"
FAIL2BAN="yes"

# Virtualization
LIBVIRT="yes"
DOCKER="yes"
PODMAN="yes"
EOF
    
    success "Service configuration files created"
}

# Function to create startup scripts
create_startup_scripts() {
    log "Creating startup scripts..."
    
    # System startup script
    cat > "$ROOTFS_BASE/etc/rc.local" << 'EOF'
#!/bin/bash
# Voidance System Startup Script
# This script runs during system boot

# Source environment
source /etc/runit/env

# Load kernel modules
if [[ -d /etc/modules-load.d ]]; then
    for file in /etc/modules-load.d/*.conf; do
        [[ -f "$file" ]] && load_modules "$file"
    done
fi

# Set sysctl parameters
if [[ -f /etc/sysctl.conf ]]; then
    set_sysctl /etc/sysctl.conf
fi

# Set hostname
if [[ -f /etc/hostname ]]; then
    hostname "$(cat /etc/hostname)"
fi

# Set locale
if [[ -f /etc/locale.conf ]]; then
    source /etc/locale.conf
    export LANG
fi

# Create essential directories
mkdir -p /run/lock /run/shm /run/user
chmod 1777 /run/lock /run/shm /run/user

# Setup virtual filesystems
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true

# Setup device nodes
ln -sf /proc/self/fd /dev/fd 2>/dev/null || true
ln -sf /proc/self/fd/0 /dev/stdin 2>/dev/null || true
ln -sf /proc/self/fd/1 /dev/stdout 2>/dev/null || true
ln -sf /proc/self/fd/2 /dev/stderr 2>/dev/null || true

# Start essential services
if command_exists sv; then
    # Start udev first
    sv start udevd 2>/dev/null || true
    
    # Wait for devices
    sleep 2
    
    # Start system services
    for service in dbus elogind; do
        sv start "$service" 2>/dev/null || true
    done
    
    # Start network services
    for service in NetworkManager dhcpcd; do
        sv start "$service" 2>/dev/null || true
    done
    
    # Start desktop services
    for service in seatd polkitd sddm; do
        sv start "$service" 2>/dev/null || true
    done
    
    # Start audio services
    for service in pipewire pipewire-pulse wireplumber; do
        sv start "$service" 2>/dev/null || true
    done
fi

# Run Voidance startup
if [[ -x /usr/lib/voidance/scripts/system-startup.sh ]]; then
    /usr/lib/voidance/scripts/system-startup.sh
fi

echo "Voidance system startup completed"
EOF
    chmod +x "$ROOTFS_BASE/etc/rc.local"
    
    # Shutdown script
    cat > "$ROOTFS_BASE/etc/rc.shutdown" << 'EOF'
#!/bin/bash
# Voidance System Shutdown Script
# This script runs during system shutdown

# Source environment
source /etc/runit/env

echo "Shutting down Voidance system..."

# Stop services in reverse order
if command_exists sv; then
    # Stop desktop services
    for service in sddm polkitd seatd; do
        sv stop "$service" 2>/dev/null || true
    done
    
    # Stop audio services
    for service in wireplumber pipewire-pulse pipewire; do
        sv stop "$service" 2>/dev/null || true
    done
    
    # Stop network services
    for service in dhcpcd NetworkManager; do
        sv stop "$service" 2>/dev/null || true
    done
    
    # Stop system services
    for service in elogind dbus udevd; do
        sv stop "$service" 2>/dev/null || true
    done
fi

# Run Voidance shutdown
if [[ -x /usr/lib/voidance/scripts/system-shutdown.sh ]]; then
    /usr/lib/voidance/scripts/system-shutdown.sh
fi

# Sync filesystems
sync

echo "Voidance system shutdown completed"
EOF
    chmod +x "$ROOTFS_BASE/etc/rc.shutdown"
    
    success "Startup scripts created"
}

# Function to create service dependencies
create_service_dependencies() {
    log "Creating service dependencies..."
    
    # Service dependency map
    cat > "$ROOTFS_BASE/etc/voidance/service-deps" << 'EOF'
# Voidance Service Dependencies
# This file defines service startup dependencies

# Format: service:dependency1,dependency2,...

# Essential services
getty-1:udevd,dbus
getty-2:udevd,dbus
getty-3:udevd,dbus
getty-4:udevd,dbus
getty-5:udevd,dbus
getty-6:udevd,dbus

# System services
dbus:udevd
elogind:dbus
polkitd:dbus
seatd:udevd

# Network services
NetworkManager:dbus
dhcpcd:udevd
sshd:dbus,NetworkManager

# Desktop services
sddm:dbus,elogind,polkitd,seatd

# Audio services
pipewire:dbus
pipewire-pulse:pipewire
wireplumber:pipewire

# Hardware services
bluetooth:dbus
cupsd:dbus
tlp:udevd
thermald:udevd

# Security services
ufw:NetworkManager
fail2ban:sshd

# Virtualization services
libvirtd:dbus,NetworkManager
virtlogd:dbus
docker:dbus
podman:dbus

# Voidance services
voidance-hw-detect:udevd
voidance-tuning:udevd
voidance-user-setup:dbus,elogind
voidance-firstboot:dbus,elogind,sddm
voidance-session:dbus,elogind,sddm,pipewire

# Maintenance services
logrotate:udevd
pkg-cleanup:NetworkManager
sys-update:NetworkManager
fsck:udevd
EOF
    
    # Service startup order
    cat > "$ROOTFS_BASE/etc/voidance/service-order" << 'EOF'
# Voidance Service Startup Order
# Services are started in this order

# Phase 1: Essential system services
udevd
dbus
elogind

# Phase 2: Hardware services
seatd
bluetooth
cupsd
tlp
thermald

# Phase 3: Network services
NetworkManager
dhcpcd
sshd

# Phase 4: Security services
ufw
fail2ban

# Phase 5: Desktop services
polkitd
sddm

# Phase 6: Audio services
pipewire
pipewire-pulse
wireplumber

# Phase 7: Virtualization services
libvirtd
virtlogd
docker
podman

# Phase 8: Voidance services
voidance-hw-detect
voidance-tuning
voidance-user-setup
voidance-firstboot
voidance-session

# Phase 9: Maintenance services
logrotate
pkg-cleanup
sys-update
fsck

# Phase 10: Login services
getty-1
getty-2
getty-3
getty-4
getty-5
getty-6
EOF
    
    success "Service dependencies created"
}

# Function to validate services
validate_services() {
    log "Validating system services..."
    
    local errors=0
    
    # Check essential services
    local essential_services=(
        "getty-1"
        "getty-2"
        "getty-3"
        "getty-4"
        "getty-5"
        "getty-6"
        "sulogin"
        "udevd"
        "dbus"
        "elogind"
    )
    
    for service in "${essential_services[@]}"; do
        if [[ ! -f "$ROOTFS_BASE/etc/sv/$service/run" ]]; then
            error "Missing essential service: $service"
            ((errors++))
        fi
    done
    
    # Check service scripts are executable
    for service_dir in "$ROOTFS_BASE/etc/sv"/*; do
        if [[ -d "$service_dir" ]]; then
            local service_name=$(basename "$service_dir")
            if [[ -f "$service_dir/run" ]] && [[ ! -x "$service_dir/run" ]]; then
                error "Service run script not executable: $service_name"
                ((errors++))
            fi
        fi
    done
    
    # Check configuration files
    local config_files=(
        "/etc/runit/func"
        "/etc/runit/env"
        "/etc/rc.local"
        "/etc/rc.shutdown"
        "/etc/voidance/service-deps"
        "/etc/voidance/service-order"
    )
    
    for config in "${config_files[@]}"; do
        if [[ ! -f "$ROOTFS_BASE$config" ]]; then
            error "Missing service configuration: $config"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        success "System services validation passed"
        return 0
    else
        error "System services validation failed with $errors errors"
        return 1
    fi
}

# Main function
main() {
    log "Configuring Voidance system services and startup..."
    
    # Create essential services
    create_essential_services
    
    # Create network services
    create_network_services
    
    # Create audio services
    create_audio_services
    
    # Create desktop services
    create_desktop_services
    
    # Create hardware services
    create_hardware_services
    
    # Create security services
    create_security_services
    
    # Create maintenance services
    create_maintenance_services
    
    # Create virtualization services
    create_virtualization_services
    
    # Create Voidance-specific services
    create_voidance_services
    
    # Create service configuration files
    create_service_configs
    
    # Create startup scripts
    create_startup_scripts
    
    # Create service dependencies
    create_service_dependencies
    
    # Validate services
    validate_services
    
    success "System services and startup configuration completed"
    log "Services configured in: $ROOTFS_BASE/etc/sv"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi