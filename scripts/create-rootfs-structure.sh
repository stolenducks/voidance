#!/bin/bash
# Voidance Root Filesystem Structure and Permissions
# This script defines and creates the complete root filesystem structure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[ROOTFS]${NC} $1"
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

# Function to create directory with proper permissions
create_dir() {
    local path="$1"
    local mode="${2:-755}"
    local owner="${3:-root}"
    local group="${4:-root}"
    
    if [[ ! -d "$path" ]]; then
        mkdir -p "$path"
        chmod "$mode" "$path"
        chown "$owner:$group" "$path"
        log "Created directory: $path ($mode $owner:$group)"
    fi
}

# Function to create file with proper permissions
create_file() {
    local path="$1"
    local content="$2"
    local mode="${3:-644}"
    local owner="${4:-root}"
    local group="${5:-root}"
    
    mkdir -p "$(dirname "$path")"
    echo "$content" > "$path"
    chmod "$mode" "$path"
    chown "$owner:$group" "$path"
    log "Created file: $path ($mode $owner:$group)"
}

# Function to create symlink
create_symlink() {
    local target="$1"
    local link_path="$2"
    
    mkdir -p "$(dirname "$link_path")"
    ln -sf "$target" "$link_path"
    log "Created symlink: $link_path -> $target"
}

# Function to create root filesystem structure
create_rootfs_structure() {
    log "Creating root filesystem structure in $ROOTFS_BASE..."
    
    # ============================================================================
    # BASIC DIRECTORY STRUCTURE (FHS compliant)
    # ============================================================================
    
    # Root directory
    create_dir "$ROOTFS_BASE" 755 root root
    
    # Essential binaries
    create_dir "$ROOTFS_BASE/bin" 755 root root
    
    # Boot loader files
    create_dir "$ROOTFS_BASE/boot" 750 root root
    create_dir "$ROOTFS_BASE/boot/grub" 750 root root
    create_dir "$ROOTFS_BASE/boot/efi" 750 root root
    
    # Device files
    create_dir "$ROOTFS_BASE/dev" 755 root root
    
    # Configuration files
    create_dir "$ROOTFS_BASE/etc" 755 root root
    create_dir "$ROOTFS_BASE/etc/opt" 755 root root
    create_dir "$ROOTFS_BASE/etc/sgml" 755 root root
    create_dir "$ROOTFS_BASE/etc/xml" 755 root root
    create_dir "$ROOTFS_BASE/etc/X11" 755 root root
    create_dir "$ROOTFS_BASE/etc/X11/applnk" 755 root root
    create_dir "$ROOTFS_BASE/etc/X11/fontpath.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/X11/xinit" 755 root root
    create_dir "$ROOTFS_BASE/etc/X11/xinit/xinitrc.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/X11/xorg.conf.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/xdg" 755 root root
    create_dir "$ROOTFS_BASE/etc/xdg/autostart" 755 root root
    create_dir "$ROOTFS_BASE/etc/xdg/menus" 755 root root
    
    # Home directories
    create_dir "$ROOTFS_BASE/home" 755 root root
    
    # Libraries
    create_dir "$ROOTFS_BASE/lib" 755 root root
    create_dir "$ROOTFS_BASE/lib64" 755 root root
    
    # Media mount points
    create_dir "$ROOTFS_BASE/media" 755 root root
    create_dir "$ROOTFS_BASE/media/cdrom" 755 root root
    create_dir "$ROOTFS_BASE/media/floppy" 755 root root
    create_dir "$ROOTFS_BASE/media/usb" 755 root root
    
    # Mount point for temporarily mounted filesystems
    create_dir "$ROOTFS_BASE/mnt" 755 root root
    create_dir "$ROOTFS_BASE/mnt/cdrom" 755 root root
    create_dir "$ROOTFS_BASE/mnt/floppy" 755 root root
    create_dir "$ROOTFS_BASE/mnt/usb" 755 root root
    
    # Optional application software packages
    create_dir "$ROOTFS_BASE/opt" 755 root root
    
    # Process information
    create_dir "$ROOTFS_BASE/proc" 555 root root
    
    # Root home directory
    create_dir "$ROOTFS_BASE/root" 700 root root
    
    # Run-time variable data
    create_dir "$ROOTFS_BASE/run" 755 root root
    create_dir "$ROOTFS_BASE/run/lock" 1777 root root
    create_dir "$ROOTFS_BASE/run/shm" 1777 root root
    create_dir "$ROOTFS_BASE/run/user" 755 root root
    
    # System binaries
    create_dir "$ROOTFS_BASE/sbin" 755 root root
    
    # Service data
    create_dir "$ROOTFS_BASE/srv" 755 root root
    
    # Temporary files
    create_dir "$ROOTFS_BASE/tmp" 1777 root root
    
    # User programs
    create_dir "$ROOTFS_BASE/usr" 755 root root
    create_dir "$ROOTFS_BASE/usr/bin" 755 root root
    create_dir "$ROOTFS_BASE/usr/include" 755 root root
    create_dir "$ROOTFS_BASE/usr/lib" 755 root root
    create_dir "$ROOTFS_BASE/usr/lib64" 755 root root
    create_dir "$ROOTFS_BASE/usr/libexec" 755 root root
    create_dir "$ROOTFS_BASE/usr/local" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/bin" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/etc" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/games" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/include" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/lib" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/lib64" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/libexec" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/man" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/sbin" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/share" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/src" 755 root root
    create_dir "$ROOTFS_BASE/usr/sbin" 755 root root
    create_dir "$ROOTFS_BASE/usr/share" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/dict" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/doc" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/games" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/info" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/locale" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/misc" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/sgml" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/xml" 755 root root
    create_dir "$ROOTFS_BASE/usr/src" 755 root root
    
    # Variable data
    create_dir "$ROOTFS_BASE/var" 755 root root
    create_dir "$ROOTFS_BASE/var/cache" 755 root root
    create_dir "$ROOTFS_BASE/var/db" 755 root root
    create_dir "$ROOTFS_BASE/var/empty" 755 root root
    create_dir "$ROOTFS_BASE/var/games" 755 root root
    create_dir "$ROOTFS_BASE/var/lib" 755 root root
    create_dir "$ROOTFS_BASE/var/lib/misc" 755 root root
    create_dir "$ROOTFS_BASE/var/lib/rpm" 755 root root
    create_dir "$ROOTFS_BASE/var/local" 755 root root
    create_dir "$ROOTFS_BASE/var/lock" 1777 root root
    create_dir "$ROOTFS_BASE/var/log" 755 root root
    create_dir "$ROOTFS_BASE/var/mail" 1777 root root
    create_dir "$ROOTFS_BASE/var/opt" 755 root root
    create_dir "$ROOTFS_BASE/var/run" 755 root root
    create_dir "$ROOTFS_BASE/var/spool" 755 root root
    create_dir "$ROOTFS_BASE/var/spool/cron" 755 root root
    create_dir "$ROOTFS_BASE/var/spool/lpd" 755 root root
    create_dir "$ROOTFS_BASE/var/spool/mail" 1777 root root
    create_dir "$ROOTFS_BASE/var/tmp" 1777 root root
    create_dir "$ROOTFS_BASE/var/yp" 755 root root
    
    # ============================================================================
    # VOIDANCE-SPECIFIC DIRECTORIES
    # ============================================================================
    
    # Voidance configuration
    create_dir "$ROOTFS_BASE/etc/voidance" 755 root root
    create_dir "$ROOTFS_BASE/etc/voidance/config" 755 root root
    create_dir "$ROOTFS_BASE/etc/voidance/scripts" 755 root root
    create_dir "$ROOTFS_BASE/etc/voidance/templates" 755 root root
    
    # Voidance user data
    create_dir "$ROOTFS_BASE/var/lib/voidance" 755 root root
    create_dir "$ROOTFS_BASE/var/lib/voidance/hardware" 755 root root
    create_dir "$ROOTFS_BASE/var/lib/voidance/profiles" 755 root root
    create_dir "$ROOTFS_BASE/var/lib/voidance/state" 755 root root
    
    # Voidance logs
    create_dir "$ROOTFS_BASE/var/log/voidance" 755 root root
    create_dir "$ROOTFS_BASE/var/log/voidance/install" 755 root root
    create_dir "$ROOTFS_BASE/var/log/voidance/setup" 755 root root
    
    # ============================================================================
    # DESKTOP ENVIRONMENT DIRECTORIES
    # ============================================================================
    
    # Desktop configuration
    create_dir "$ROOTFS_BASE/etc/xdg/voidance" 755 root root
    create_dir "$ROOTFS_BASE/etc/xdg/voidance/autostart" 755 root root
    create_dir "$ROOTFS_BASE/etc/xdg/voidance/menus" 755 root root
    
    # User desktop directories (template)
    create_dir "$ROOTFS_BASE/etc/skel" 755 root root
    create_dir "$ROOTFS_BASE/etc/skel/Desktop" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/Documents" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/Downloads" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/Music" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/Pictures" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/Public" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/Templates" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/Videos" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/.config" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/.local" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/.local/share" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/.local/state" 700 root root
    create_dir "$ROOTFS_BASE/etc/skel/.cache" 700 root root
    
    # ============================================================================
    # WAYLAND SPECIFIC DIRECTORIES
    # ============================================================================
    
    # Wayland runtime
    create_dir "$ROOTFS_BASE/run/user" 1777 root root
    
    # Wayland configuration
    create_dir "$ROOTFS_BASE/etc/xdg/wayland-sessions" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/wayland-sessions" 755 root root
    
    # ============================================================================
    # SYSTEM SERVICE DIRECTORIES
    # ============================================================================
    
    # Runit services
    create_dir "$ROOTFS_BASE/etc/runit" 755 root root
    create_dir "$ROOTFS_BASE/etc/sv" 755 root root
    create_dir "$ROOTFS_BASE/etc/sv/getty-1" 755 root root
    create_dir "$ROOTFS_BASE/etc/sv/getty-2" 755 root root
    create_dir "$ROOTFS_BASE/etc/sv/getty-3" 755 root root
    create_dir "$ROOTFS_BASE/etc/sv/getty-4" 755 root root
    create_dir "$ROOTFS_BASE/etc/sv/getty-5" 755 root root
    create_dir "$ROOTFS_BASE/etc/sv/getty-6" 755 root root
    create_dir "$ROOTFS_BASE/etc/sv/sulogin" 755 root root
    
    # Service runtime
    create_dir "$ROOTFS_BASE/var/service" 755 root root
    create_dir "$ROOTFS_BASE/var/lib/sv" 755 root root
    
    # ============================================================================
    # SECURITY DIRECTORIES
    # ============================================================================
    
    # Security
    create_dir "$ROOTFS_BASE/etc/security" 755 root root
    create_dir "$ROOTFS_BASE/etc/security/limits.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/security/pam.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/security/console.apps" 755 root root
    create_dir "$ROOTFS_BASE/etc/security/console.perms" 755 root root
    create_dir "$ROOTFS_BASE/etc/security/console.perms.d" 755 root root
    
    # PAM
    create_dir "$ROOTFS_BASE/etc/pam.d" 755 root root
    
    # ============================================================================
    # HARDWARE DIRECTORIES
    # ============================================================================
    
    # Hardware
    create_dir "$ROOTFS_BASE/etc/modprobe.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/modules-load.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/udev" 755 root root
    create_dir "$ROOTFS_BASE/etc/udev/rules.d" 755 root root
    create_dir "$ROOTFS_BASE/lib/udev" 755 root root
    create_dir "$ROOTFS_BASE/lib/udev/rules.d" 755 root root
    
    # ============================================================================
    # NETWORK DIRECTORIES
    # ============================================================================
    
    # Network configuration
    create_dir "$ROOTFS_BASE/etc/network" 755 root root
    create_dir "$ROOTFS_BASE/etc/network/if-down.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/network/if-post-down.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/network/if-pre-up.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/network/if-up.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/network/interfaces.d" 755 root root
    
    # ============================================================================
    # FONT DIRECTORIES
    # ============================================================================
    
    # Fonts
    create_dir "$ROOTFS_BASE/usr/share/fonts" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/fonts/TTF" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/fonts/OTF" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/fonts/Type1" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/fonts/encodings" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/fonts/util" 755 root root
    
    # Font configuration
    create_dir "$ROOTFS_BASE/etc/fonts" 755 root root
    create_dir "$ROOTFS_BASE/etc/fonts/conf.d" 755 root root
    create_dir "$ROOTFS_BASE/etc/fonts/conf.avail" 755 root root
    
    # ============================================================================
    # APPLICATION DIRECTORIES
    # ============================================================================
    
    # Applications
    create_dir "$ROOTFS_BASE/usr/share/applications" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/desktop-directories" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/mime" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/mime/packages" 755 root root
    
    # Icons
    create_dir "$ROOTFS_BASE/usr/share/icons" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/pixmaps" 755 root root
    
    # Sounds
    create_dir "$ROOTFS_BASE/usr/share/sounds" 755 root root
    
    # Themes
    create_dir "$ROOTFS_BASE/usr/share/themes" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/backgrounds" 755 root root
    
    # ============================================================================
    # DEVELOPMENT DIRECTORIES
    # ============================================================================
    
    # Development
    create_dir "$ROOTFS_BASE/usr/include" 755 root root
    create_dir "$ROOTFS_BASE/usr/src" 755 root root
    create_dir "$ROOTFS_BASE/usr/local/src" 755 root root
    
    # ============================================================================
    # DOCUMENTATION DIRECTORIES
    # ============================================================================
    
    # Documentation
    create_dir "$ROOTFS_BASE/usr/share/doc" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/info" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man/man1" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man/man2" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man/man3" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man/man4" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man/man5" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man/man6" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man/man7" 755 root root
    create_dir "$ROOTFS_BASE/usr/share/man/man8" 755 root root
    
    success "Root filesystem structure created"
}

# Function to create essential device files
create_device_files() {
    log "Creating essential device files..."
    
    # Create basic device nodes
    create_symlink "/proc/self/fd" "$ROOTFS_BASE/dev/fd"
    create_symlink "/proc/self/fd/0" "$ROOTFS_BASE/dev/stdin"
    create_symlink "/proc/self/fd/1" "$ROOTFS_BASE/dev/stdout"
    create_symlink "/proc/self/fd/2" "$ROOTFS_BASE/dev/stderr"
    
    # Create console device (will be created by kernel)
    # mknod "$ROOTFS_BASE/dev/console" c 5 1
    # chmod 600 "$ROOTFS_BASE/dev/console"
    
    # Create null device (will be created by kernel)
    # mknod "$ROOTFS_BASE/dev/null" c 1 3
    # chmod 666 "$ROOTFS_BASE/dev/null"
    
    # Create zero device (will be created by kernel)
    # mknod "$ROOTFS_BASE/dev/zero" c 1 5
    # chmod 666 "$ROOTFS_BASE/dev/zero"
    
    # Create random devices (will be created by kernel)
    # mknod "$ROOTFS_BASE/dev/random" c 1 8
    # chmod 666 "$ROOTFS_BASE/dev/random"
    # mknod "$ROOTFS_BASE/dev/urandom" c 1 9
    # chmod 666 "$ROOTFS_BASE/dev/urandom"
    
    # Create tty devices (will be created by kernel)
    # mknod "$ROOTFS_BASE/dev/tty" c 5 0
    # chmod 666 "$ROOTFS_BASE/dev/tty"
    
    success "Essential device files created"
}

# Function to create essential configuration files
create_config_files() {
    log "Creating essential configuration files..."
    
    # FSTAB template
    create_file "$ROOTFS_BASE/etc/fstab" "# Voidance FSTAB Template
# This file will be configured during installation

# <file system> <dir>         <type>    <options>             <dump> <pass>
/dev/sda1        /boot         ext4      defaults              0     2
/dev/sda2        /             ext4      defaults              0     1
/dev/sda3        /home         ext4      defaults              0     2
/dev/sda4        swap          swap      defaults              0     0

# Virtual filesystems
proc             /proc         proc      nosuid,noexec,nodev    0     0
sysfs            /sys          sysfs     nosuid,noexec,nodev    0     0
devtmpfs         /dev          devtmpfs  mode=0755,nosuid       0     0
tmpfs            /run          tmpfs     nosuid,nodev,mode=0755 0     0
tmpfs            /tmp          tmpfs     nosuid,nodev           0     0
" 644 root root
    
    # Hostname template
    create_file "$ROOTFS_BASE/etc/hostname" "voidance" 644 root root
    
    # Hosts template
    create_file "$ROOTFS_BASE/etc/hosts" "# Voidance Hosts File
127.0.0.1   localhost
127.0.1.1   voidance.localdomain voidance

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
" 644 root root
    
    # Resolv.conf template
    create_file "$ROOTFS_BASE/etc/resolv.conf" "# Voidance DNS Configuration
# This file will be configured by NetworkManager
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
" 644 root root
    
    # Machine ID
    create_file "$ROOTFS_BASE/etc/machine-id" "" 644 root root
    
    # Locale configuration
    create_file "$ROOTFS_BASE/etc/locale.conf" "# Voidance Locale Configuration
LANG=en_US.UTF-8
LC_COLLATE=C
" 644 root root
    
    # Timezone configuration
    create_file "$ROOTFS_BASE/etc/timezone" "UTC" 644 root root
    
    # Default shell
    create_symlink "/bin/bash" "$ROOTFS_BASE/bin/sh"
    
    success "Essential configuration files created"
}

# Function to set proper permissions
set_permissions() {
    log "Setting proper permissions..."
    
    # Set special permissions
    chmod 1777 "$ROOTFS_BASE/tmp"
    chmod 1777 "$ROOTFS_BASE/var/tmp"
    chmod 1777 "$ROOTFS_BASE/var/lock"
    chmod 1777 "$ROOTFS_BASE/run/lock"
    chmod 1777 "$ROOTFS_BASE/run/shm"
    chmod 1777 "$ROOTFS_BASE/run/user"
    chmod 1777 "$ROOTFS_BASE/var/mail"
    
    # Set secure permissions
    chmod 700 "$ROOTFS_BASE/root"
    chmod 755 "$ROOTFS_BASE/home"
    chmod 755 "$ROOTFS_BASE/etc/skel"
    
    # Set user directory permissions
    find "$ROOTFS_BASE/etc/skel" -type d -exec chmod 700 {} \;
    find "$ROOTFS_BASE/etc/skel" -type f -exec chmod 600 {} \;
    
    # Set system directory permissions
    chmod 755 "$ROOTFS_BASE/bin"
    chmod 755 "$ROOTFS_BASE/sbin"
    chmod 755 "$ROOTFS_BASE/usr/bin"
    chmod 755 "$ROOTFS_BASE/usr/sbin"
    chmod 755 "$ROOTFS_BASE/usr/local/bin"
    chmod 755 "$ROOTFS_BASE/usr/local/sbin"
    
    success "Proper permissions set"
}

# Function to validate filesystem structure
validate_filesystem() {
    log "Validating filesystem structure..."
    
    local errors=0
    
    # Check essential directories
    local essential_dirs=(
        "/bin"
        "/etc"
        "/home"
        "/lib"
        "/opt"
        "/proc"
        "/root"
        "/run"
        "/sbin"
        "/srv"
        "/sys"
        "/tmp"
        "/usr"
        "/var"
    )
    
    for dir in "${essential_dirs[@]}"; do
        if [[ ! -d "$ROOTFS_BASE$dir" ]]; then
            error "Missing essential directory: $dir"
            ((errors++))
        fi
    done
    
    # Check essential configuration files
    local essential_files=(
        "/etc/fstab"
        "/etc/hostname"
        "/etc/hosts"
        "/etc/resolv.conf"
        "/etc/locale.conf"
    )
    
    for file in "${essential_files[@]}"; do
        if [[ ! -f "$ROOTFS_BASE$file" ]]; then
            error "Missing essential file: $file"
            ((errors++))
        fi
    done
    
    # Check permissions
    if [[ "$(stat -c %a "$ROOTFS_BASE/tmp")" != "1777" ]]; then
        error "Incorrect permissions on /tmp"
        ((errors++))
    fi
    
    if [[ "$(stat -c %a "$ROOTFS_BASE/root")" != "700" ]]; then
        error "Incorrect permissions on /root"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        success "Filesystem structure validation passed"
        return 0
    else
        error "Filesystem structure validation failed with $errors errors"
        return 1
    fi
}

# Main function
main() {
    log "Creating Voidance root filesystem structure..."
    
    # Create base directory
    mkdir -p "$ROOTFS_BASE"
    
    # Create filesystem structure
    create_rootfs_structure
    
    # Create device files
    create_device_files
    
    # Create configuration files
    create_config_files
    
    # Set permissions
    set_permissions
    
    # Validate structure
    validate_filesystem
    
    success "Root filesystem structure completed successfully"
    log "Root filesystem created at: $ROOTFS_BASE"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi