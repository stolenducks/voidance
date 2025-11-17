#!/bin/bash
# Voidance System Installation and Package Extraction
# Handles the actual system installation process

set -euo pipefail

# Source configuration and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/iso/config.sh"
source "$SCRIPT_DIR/disk-partitioning.sh"
source "$SCRIPT_DIR/filesystem-creation.sh"

# Installation configuration
INSTALL_ROOT="/mnt/voidance"
PACKAGES_CACHE="/var/cache/voidance-packages"
INSTALL_LOG="/var/log/voidance-install.log"

# Function to initialize installation environment
init_installation_environment() {
    log_message "INFO" "Initializing installation environment"
    
    # Create installation root directory
    mkdir -p "$INSTALL_ROOT"
    mkdir -p "$PACKAGES_CACHE"
    
    # Mount filesystems
    mount_filesystems
    
    # Create installation log
    cat > "$INSTALL_LOG" << EOF
Voidance Linux Installation Log
===============================
Date: $(date)
Target: $INSTALL_ROOT
Package Cache: $PACKAGES_CACHE

EOF
    
    log_message "INFO" "Installation environment initialized"
}

# Function to install base system packages
install_base_system() {
    log_message "INFO" "Installing base system packages"
    
    # Install base packages using XBPS
    xbps-install -Sy -r "$INSTALL_ROOT" -R "$REPOSITORY_URL" \
        base-system \
        base-files \
        coreutils \
        util-linux \
        findutils \
        grep \
        sed \
        awk \
        gawk \
        bash \
        dash \
        shadow \
        passwd \
        login \
        sudo \
        runit \
        void-artwork \
        void-repo-nonfree \
        void-repo-multilib \
        void-repo-multilib-nonfree
    
    log_message "INFO" "Base system packages installed"
}

# Function to install kernel and drivers
install_kernel_drivers() {
    log_message "INFO" "Installing kernel and drivers"
    
    # Install kernel
    xbps-install -Sy -r "$INSTALL_ROOT" -R "$REPOSITORY_URL" \
        linux6.6 \
        linux6.6-headers \
        linux-firmware \
        linux-firmware-amd \
        linux-firmware-intel \
        linux-firmware-nvidia \
        linux-firmware-network \
        dracut \
        e2fsprogs \
        dosfstools \
        xfsprogs \
        btrfs-progs \
        lvm2 \
        cryptsetup
    
    log_message "INFO" "Kernel and drivers installed"
}

# Function to install networking packages
install_networking() {
    log_message "INFO" "Installing networking packages"
    
    xbps-install -Sy -r "$INSTALL_ROOT" -R "$REPOSITORY_URL" \
        NetworkManager \
        network-manager-applet \
        wpa_supplicant \
        wireless_tools \
        iw \
        dhcp \
        dhcpcd \
        iproute2 \
        iputils \
        net-tools \
        curl \
        wget \
        rsync \
        openssh \
        sshfs \
        nfs-utils \
        cifs-utils
    
    log_message "INFO" "Networking packages installed"
}

# Function to install desktop environment
install_desktop_environment() {
    log_message "INFO" "Installing desktop environment"
    
    # Install Wayland and Niri
    xbps-install -Sy -r "$INSTALL_ROOT" -R "$REPOSITORY_URL" \
        niri \
        wayland \
        wayland-protocols \
        wayland-utils \
        seatd \
        elogind \
        polkit \
        dbus \
        xdg-desktop-portal \
        xdg-desktop-portal-wlr \
        xdg-desktop-portal-gtk
    
    # Install desktop applications
    xbps-install -Sy -r "$INSTALL_ROOT" -R "$REPOSITORY_URL" \
        foot \
        fuzzel \
        mako \
        swaybg \
        swaylock \
        swayidle \
        grim \
        slurp \
        wf-recorder \
        wlsunset \
        kanshi \
        wdisplays \
        nwg-look
    
    # Install GTK and Qt themes
    xbps-install -Sy -r "$INSTALL_ROOT" -R "$REPOSITORY_URL" \
        gtk-engine-murrine \
        gtk-engines \
        adwaita-icon-theme \
        papirus-icon-theme \
        qt6ct \
        qt5ct \
        kvantum
    
    log_message "INFO" "Desktop environment installed"
}

# Function to install development tools
install_development_tools() {
    log_message "INFO" "Installing development tools"
    
    xbps-install -Sy -r "$INSTALL_ROOT" -R "$REPOSITORY_URL" \
        git \
        git-lfs \
        vim \
        neovim \
        emacs \
        nano \
        code \
        make \
        gcc \
        gcc-c++ \
        clang \
        rust \
        cargo \
        go \
        nodejs \
        npm \
        python3 \
        python3-pip \
        python3-devel \
        pkg-config \
        autoconf \
        automake \
        libtool \
        cmake \
        meson \
        ninja
    
    log_message "INFO" "Development tools installed"
}

# Function to install multimedia packages
install_multimedia() {
    log_message "INFO" "Installing multimedia packages"
    
    xbps-install -Sy -r "$INSTALL_ROOT" -R "$REPOSITORY_URL" \
        pipewire \
        pipewire-pulse \
        wireplumber \
        pamixer \
        pavucontrol \
        mpv \
        vlc \
        ffmpeg \
        imagemagick \
        gimp \
        inkscape \
        obs-studio \
        audacity
    
    log_message "INFO" "Multimedia packages installed"
}

# Function to install system utilities
install_system_utilities() {
    log_message "INFO" "Installing system utilities"
    
    xbps-install -Sy -r "$INSTALL_ROOT" -R "$REPOSITORY_URL" \
        htop \
        btop \
        neofetch \
        screenfetch \
        tree \
        ripgrep \
        fd \
        bat \
        exa \
        dust \
        gdu \
        procs \
        bandwhich \
        tldr \
        man-pages \
        info \
        docs
    
    log_message "INFO" "System utilities installed"
}

# Function to configure system settings
configure_system_settings() {
    log_message "INFO" "Configuring system settings"
    
    # Create essential directories
    mkdir -p "$INSTALL_ROOT"/{dev,proc,sys,run}
    
    # Mount virtual filesystems
    mount -t proc /proc "$INSTALL_ROOT/proc"
    mount -t sysfs /sys "$INSTALL_ROOT/sys"
    mount -t devtmpfs /dev "$INSTALL_ROOT/dev"
    mount -t devpts /dev/pts "$INSTALL_ROOT/dev/pts"
    mount -t tmpfs /run "$INSTALL_ROOT/run"
    
    # Generate fstab
    generate_fstab
    
    # Configure hostname
    echo "voidance" > "$INSTALL_ROOT/etc/hostname"
    
    # Configure hosts file
    cat > "$INSTALL_ROOT/etc/hosts" << EOF
127.0.0.1   localhost
127.0.1.1   voidance.localdomain voidance
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF
    
    # Configure locale
    echo "en_US.UTF-8 UTF-8" > "$INSTALL_ROOT/etc/default/libc-locales"
    chroot "$INSTALL_ROOT" xbps-reconfigure -f glibc-locales
    
    # Configure timezone
    chroot "$INSTALL_ROOT" ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    
    # Configure keymap
    echo "KEYMAP=us" > "$INSTALL_ROOT/etc/vconsole.conf
    
    log_message "INFO" "System settings configured"
}

# Function to generate fstab
generate_fstab() {
    log_message "INFO" "Generating fstab"
    
    # Get partition information
    local root_part=$(get_config "root_partition")
    local boot_part=$(get_config "boot_partition")
    local swap_part=$(get_config "swap_partition")
    local root_fs=$(get_config "root_filesystem")
    
    # Create fstab
    cat > "$INSTALL_ROOT/etc/fstab" << EOF
# /etc/fstab: static file system information
#
# <file system> <dir> <type> <options> <dump> <pass>
EOF
    
    # Root filesystem
    if [[ -n "$root_part" ]]; then
        echo "$root_part  /  $root_fs  defaults  0  1" >> "$INSTALL_ROOT/etc/fstab"
    fi
    
    # Boot filesystem
    if [[ -n "$boot_part" ]]; then
        echo "$boot_part  /boot  vfat  defaults,noatime  0  2" >> "$INSTALL_ROOT/etc/fstab"
    fi
    
    # Swap
    if [[ -n "$swap_part" ]]; then
        echo "$swap_part  none  swap  sw  0  0" >> "$INSTALL_ROOT/etc/fstab"
    fi
    
    # Virtual filesystems
    cat >> "$INSTALL_ROOT/etc/fstab" << EOF
proc  /proc  proc  defaults  0  0
sysfs  /sys  sysfs  defaults  0  0
devtmpfs  /dev  devtmpfs  mode=0755,nosuid  0  0
tmpfs  /run  tmpfs  mode=0755,nosuid,nodev  0  0
devpts  /dev/pts  devpts  mode=0620,gid=5  0  0
EOF
    
    log_message "INFO" "fstab generated"
}

# Function to enable system services
enable_system_services() {
    log_message "INFO" "Enabling system services"
    
    # Enable essential services
    chroot "$INSTALL_ROOT" ln -sf /etc/sv/NetworkManager /etc/runit/runsvdir/default/
    chroot "$INSTALL_ROOT" ln -sf /etc/sv/sshd /etc/runit/runsvdir/default/
    chroot "$INSTALL_ROOT" ln -sf /etc/sv/seatd /etc/runit/runsvdir/default/
    chroot "$INSTALL_ROOT" ln -sf /etc/sv/polkitd /etc/runit/runsvdir/default/
    chroot "$INSTALL_ROOT" ln -sf /etc/sv/dbus /etc/runit/runsvdir/default/
    chroot "$INSTALL_ROOT" ln -sf /etc/sv/elogind /etc/runit/runsvdir/default/
    
    # Enable filesystem services
    chroot "$INSTALL_ROOT" ln -sf /etc/sv/cryptsetup /etc/runit/runsvdir/default/ || true
    chroot "$INSTALL_ROOT" ln -sf /etc/sv/lvm2-monitor /etc/runit/runsvdir/default/ || true
    
    log_message "INFO" "System services enabled"
}

# Function to create user accounts
create_user_accounts() {
    log_message "INFO" "Creating user accounts"
    
    local username=$(get_config "username" "voidance")
    local password=$(get_config "password" "voidance")
    
    # Set root password
    echo "root:$password" | chroot "$INSTALL_ROOT" chpasswd
    
    # Create user
    chroot "$INSTALL_ROOT" useradd -m -s /bin/bash -G wheel,audio,video,input,storage,network "$username"
    echo "$username:$password" | chroot "$INSTALL_ROOT" chpasswd
    
    # Configure sudo
    echo "%wheel ALL=(ALL) ALL" > "$INSTALL_ROOT/etc/sudoers.d/wheel"
    
    log_message "INFO" "User accounts created"
}

# Function to cleanup installation
cleanup_installation() {
    log_message "INFO" "Cleaning up installation"
    
    # Unmount virtual filesystems
    umount "$INSTALL_ROOT/dev/pts" || true
    umount "$INSTALL_ROOT/dev" || true
    umount "$INSTALL_ROOT/run" || true
    umount "$INSTALL_ROOT/sys" || true
    umount "$INSTALL_ROOT/proc" || true
    
    # Clean package cache
    chroot "$INSTALL_ROOT" xbps-remove -O
    
    log_message "INFO" "Installation cleanup completed"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$INSTALL_LOG"
}

# Main installation function
main_installation() {
    log_message "INFO" "Starting Voidance Linux installation"
    
    init_installation_environment
    install_base_system
    install_kernel_drivers
    install_networking
    install_desktop_environment
    install_development_tools
    install_multimedia
    install_system_utilities
    configure_system_settings
    enable_system_services
    create_user_accounts
    cleanup_installation
    
    log_message "INFO" "Voidance Linux installation completed successfully"
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_installation "$@"
fi