#!/bin/bash
# Voidance void-mklive Integration Script
# Integrates custom Voidance configuration with void-mklive build system

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/iso/config.sh"
source "$SCRIPT_DIR/../config/iso/repositories.conf"
source "$SCRIPT_DIR/../config/iso/kernel-config.sh"

# Build configuration
BUILD_DIR="/tmp/voidance-build"
MKLIVE_DIR="$BUILD_DIR/void-mklive"
OUTPUT_DIR="$SCRIPT_DIR/../output"
INTEGRATION_LOG="/var/log/voidance-integration.log"

# Function to initialize build environment
init_build_environment() {
    log_message "INFO" "Initializing void-mklive build environment"
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    # Clone or update void-mklive
    if [[ -d "$MKLIVE_DIR/.git" ]]; then
        log_message "INFO" "Updating void-mklive repository"
        cd "$MKLIVE_DIR"
        git pull origin master
    else
        log_message "INFO" "Cloning void-mklive repository"
        git clone https://github.com/void-linux/void-mklive.git "$MKLIVE_DIR"
    fi
    
    # Install build dependencies
    xbps-install -Sy \
        xorriso \
        grub-i386-efi \
        grub-x86_64-efi \
        squashfs-tools \
        libisoburn \
        libisofs \
        libburn \
        cdrtools
    
    log_message "INFO" "Build environment initialized"
}

# Function to create custom void-mklive configuration
create_mklive_configuration() {
    log_message "INFO" "Creating custom void-mklive configuration"
    
    # Create custom mklive.sh script
    cat > "$MKLIVE_DIR/mklive-voidance.sh" << 'EOF'
#!/bin/bash
# Voidance Custom void-mklive Build Script

# Source original mklive functions
. ./mklive.sh

# Voidance-specific configuration
VOIDANCE_PKGS="
base-system
linux6.6
linux-firmware
NetworkManager
niri
foot
fuzzel
mako
swaybg
swaylock
swayidle
grim
slurp
wf-recorder
wlsunset
kanshi
wdisplays
nwg-look
pipewire
pipewire-pulse
wireplumber
pamixer
pavucontrol
mpv
firefox
thunar
gvfs
gvfs-mtp
gvfs-smb
polkit
seatd
elogind
dbus
xdg-desktop-portal
xdg-desktop-portal-wlr
xdg-desktop-portal-gtk
gtk-engine-murrine
adwaita-icon-theme
papirus-icon-theme
qt6ct
kvantum
htop
btop
neofetch
tree
ripgrep
fd
bat
exa
dust
gdu
procs
bandwhich
tldr
man-pages
"

# Voidance-specific repositories
VOIDANCE_REPOS="
--repository=https://repo-default.voidlinux.org/current
--repository=https://repo-default.voidlinux.org/current/multilib
--repository=https://repo-default.voidlinux.org/current/nonfree
--repository=https://repo-default.voidlinux.org/current/multilib/nonfree
"

# Override build function for Voidance
build_voidance_iso() {
    local arch=$(uname -m)
    local output_dir="$1"
    local iso_name="voidance-live-${arch}-$(date +%Y%m%d).iso"
    
    # Create temporary build directory
    local tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" RETURN
    
    # Create rootfs
    mkdir -p "$tmpdir/rootfs"
    
    # Install packages
    XBPS_ARCH=$arch xbps-install -Sy -r "$tmpdir/rootfs" \
        $VOIDANCE_REPOS \
        $VOIDANCE_PKGS
    
    # Configure system
    configure_voidance_system "$tmpdir/rootfs"
    
    # Create boot configuration
    create_voidance_boot_config "$tmpdir/rootfs"
    
    # Create squashfs
    mksquashfs "$tmpdir/rootfs" "$tmpdir/LiveOS/rootfs.squashfs" \
        -comp xz -Xbcj x86 -b 1M -Xdict-size 1M
    
    # Create ISO
    create_voidance_iso "$tmpdir" "$output_dir/$iso_name"
    
    echo "Voidance ISO created: $output_dir/$iso_name"
}

# Configure Voidance system
configure_voidance_system() {
    local rootfs="$1"
    
    # Create essential directories
    mkdir -p "$rootfs"/{dev,proc,sys,run,tmp}
    
    # Configure hostname
    echo "voidance-live" > "$rootfs/etc/hostname"
    
    # Configure hosts
    cat > "$rootfs/etc/hosts" << HOSTS
127.0.0.1   localhost
127.0.1.1   voidance-live.localdomain voidance-live
::1         localhost ip6-localhost ip6-loopback
HOSTS
    
    # Configure locale
    echo "en_US.UTF-8 UTF-8" > "$rootfs/etc/default/libc-locales"
    
    # Create live user
    chroot "$rootfs" useradd -m -s /bin/bash -G audio,video,input,storage,wheel voidance
    echo "voidance:voidance" | chroot "$rootfs" chpasswd
    
    # Configure sudo
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > "$rootfs/etc/sudoers.d/wheel"
    
    # Enable services
    mkdir -p "$rootfs/etc/runit/runsvdir/default"
    chroot "$rootfs" ln -sf /etc/sv/NetworkManager /etc/runit/runsvdir/default/
    chroot "$rootfs" ln -sf /etc/sv/seatd /etc/runit/runsvdir/default/
    chroot "$rootfs" ln -sf /etc/sv/polkitd /etc/runit/runsvdir/default/
    chroot "$rootfs" ln -sf /etc/sv/dbus /etc/runit/runsvdir/default/
    chroot "$rootfs" ln -sf /etc/sv/elogind /etc/runit/runsvdir/default/
    
    # Configure display manager
    create_voidance_display_config "$rootfs"
}

# Create Voidance display configuration
create_voidance_display_config() {
    local rootfs="$1"
    
    # Create greetd configuration
    mkdir -p "$rootfs/etc/greetd"
    cat > "$rootfs/etc/greetd/config.toml" << GREETER
[terminal]
vt = 1

[default_session]
command = "agreety --cmd niri"
user = "greeter"
GREETER
    
    # Create wayland session
    mkdir -p "$rootfs/usr/share/wayland-sessions"
    cat > "$rootfs/usr/share/wayland-sessions/niri.desktop" << DESKTOP
[Desktop Entry]
Name=Niri
Comment=Niri Wayland Compositor
Exec=niri
Type=Application
Desktop
EOF
    
    # Enable greetd service
    chroot "$rootfs" ln -sf /etc/sv/greetd /etc/runit/runsvdir/default/
}

# Create Voidance boot configuration
create_voidance_boot_config() {
    local rootfs="$1"
    
    # Create GRUB configuration
    mkdir -p "$rootfs/boot/grub"
    cat > "$rootfs/boot/grub/grub.cfg" << GRUB
set default="0"
set timeout=5

menuentry "Voidance Linux Live" {
    linux /boot/vmlinuz root=live:CDLABEL=VoidanceLive rw quiet splash
    initrd /boot/initramfs.img
}

menuentry "Voidance Linux Live (Failsafe)" {
    linux /boot/vmlinuz root=live:CDLABEL=VoidanceLive rw nomodeset
    initrd /boot/initramfs.img
}
GRUB
}

# Create Voidance ISO
create_voidance_iso() {
    local tmpdir="$1"
    local iso_output="$2"
    
    # Create ISO using xorriso
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "VoidanceLive" \
        -appid "Voidance Linux Live" \
        -publisher "Voidance Linux Project" \
        -preparer "void-mklive" \
        -eltorito-boot boot/grub/i386-pc/eltorito.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -output "$iso_output" \
        "$tmpdir"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    output_dir="${1:-./output}"
    mkdir -p "$output_dir"
    build_voidance_iso "$output_dir"
fi
EOF
    
    chmod +x "$MKLIVE_DIR/mklive-voidance.sh"
    
    log_message "INFO" "Custom void-mklive configuration created"
}

# Function to build Voidance ISO
build_voidance_iso() {
    log_message "INFO" "Building Voidance ISO with void-mklive"
    
    cd "$MKLIVE_DIR"
    
    # Run custom build script
    ./mklive-voidance.sh "$OUTPUT_DIR"
    
    # Verify ISO was created
    local iso_files=("$OUTPUT_DIR"/voidance-live-*.iso)
    if [[ ${#iso_files[@]} -eq 0 ]]; then
        log_message "ERROR" "No ISO file was created"
        return 1
    fi
    
    local iso_file="${iso_files[0]}"
    log_message "INFO" "Voidance ISO created: $iso_file"
    
    # Generate checksum
    cd "$OUTPUT_DIR"
    sha256sum "$(basename "$iso_file")" > "$(basename "$iso_file").sha256"
    
    log_message "INFO" "ISO checksum generated"
}

# Function to test ISO functionality
test_iso_functionality() {
    log_message "INFO" "Testing ISO functionality"
    
    local iso_files=("$OUTPUT_DIR"/voidance-live-*.iso)
    local iso_file="${iso_files[0]}"
    
    # Check ISO file size
    local iso_size=$(stat -c%s "$iso_file")
    if [[ $iso_size -lt 500000000 ]]; then  # Less than 500MB
        log_message "WARNING" "ISO file seems too small: $iso_size bytes"
    fi
    
    # Verify ISO structure
    if command -v isoinfo >/dev/null 2>&1; then
        log_message "INFO" "Verifying ISO structure"
        isoinfo -l -i "$iso_file" | head -20
    fi
    
    # Test ISO mountability
    local test_mount="/tmp/voidance-iso-test"
    mkdir -p "$test_mount"
    
    if mount -o loop,ro "$iso_file" "$test_mount" 2>/dev/null; then
        log_message "INFO" "ISO mounts successfully"
        
        # Check essential files
        local essential_files=(
            "boot/grub/grub.cfg"
            "LiveOS/rootfs.squashfs"
        )
        
        for file in "${essential_files[@]}"; do
            if [[ -f "$test_mount/$file" ]]; then
                log_message "INFO" "Essential file found: $file"
            else
                log_message "ERROR" "Essential file missing: $file"
            fi
        done
        
        umount "$test_mount"
        rmdir "$test_mount"
    else
        log_message "ERROR" "ISO failed to mount"
    fi
    
    log_message "INFO" "ISO functionality testing completed"
}

# Function to cleanup build environment
cleanup_build_environment() {
    log_message "INFO" "Cleaning up build environment"
    
    # Remove build directory
    rm -rf "$BUILD_DIR"
    
    log_message "INFO" "Build environment cleanup completed"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$INTEGRATION_LOG"
}

# Main integration function
main_integration() {
    log_message "INFO" "Starting Voidance void-mklive integration"
    
    init_build_environment
    create_mklive_configuration
    build_voidance_iso
    test_iso_functionality
    cleanup_build_environment
    
    log_message "INFO" "Voidance void-mklive integration completed successfully"
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_integration "$@"
fi