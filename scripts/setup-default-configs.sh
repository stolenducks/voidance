#!/bin/bash
# Voidance Default Configuration Files Setup
# This script sets up all default configuration files for the system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[CONFIG-SETUP]${NC} $1"
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

# Function to create configuration file
create_config() {
    local path="$1"
    local content="$2"
    local mode="${3:-644}"
    local owner="${4:-root}"
    local group="${5:-root}"
    
    mkdir -p "$(dirname "$path")"
    echo "$content" > "$path"
    chmod "$mode" "$path"
    chown "$owner:$group" "$path"
    log "Created config: $path"
}

# Function to create system configuration files
create_system_configs() {
    log "Creating system configuration files..."
    
    # System release information
    create_config "$ROOTFS_BASE/etc/os-release" "# Voidance Linux OS Release
NAME=\"Voidance Linux\"
VERSION=\"$(date +%Y.%m.%d)\"
ID=voidance
ID_LIKE=void
PRETTY_NAME=\"Voidance Linux\"
VERSION_ID=\"$(date +%Y.%m.%d)\"
HOME_URL=\"https://voidance.org\"
SUPPORT_URL=\"https://voidance.org/support\"
BUG_REPORT_URL=\"https://voidance.org/bugs\"
PRIVACY_POLICY_URL=\"https://voidance.org/privacy\"
LOGO=distributor-logo-voidance
" 644 root root
    
    # LSB release information
    create_config "$ROOTFS_BASE/etc/lsb-release" "# Voidance LSB Release
DISTRIB_ID=Voidance
DISTRIB_DESCRIPTION=\"Voidance Linux\"
DISTRIB_RELEASE=\"$(date +%Y.%m.%d)\"
DISTRIB_CODENAME=\"void\"
" 644 root root
    
    # System issue file
    create_config "$ROOTFS_BASE/etc/issue" "Voidance Linux \\n \\l

" 644 root root
    
    # System issue.net file
    create_config "$ROOTFS_BASE/etc/issue.net" "Voidance Linux

" 644 root root
    
    # Motd file
    create_config "$ROOTFS_BASE/etc/motd" "# Welcome to Voidance Linux!

# System Information:
# - Distribution: Voidance Linux
# - Version: $(date +%Y.%m.%d)
# - Architecture: $(uname -m)
# - Kernel: $(uname -r)

# Getting Started:
# 1. Update packages: xbps-install -Su
# 2. Install software: xbps-install <package>
# 3. Configure system: /etc/voidance/
# 4. User guide: /usr/share/doc/voidance/

# Support:
# - Documentation: https://voidance.org/docs
# - Community: https://voidance.org/community
# - Issues: https://voidance.org/issues

# Enjoy your Voidance Linux experience!
" 644 root root
    
    # Shell configuration
    create_config "$ROOTFS_BASE/etc/profile" "# Voidance System Profile
# System-wide environment and startup programs

# Path setup
PATH=\"/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin\"
export PATH

# Default editor
export EDITOR=vim
export VISUAL=vim

# Default pager
export PAGER=less

# Default browser
export BROWSER=firefox

# Locale settings
export LANG=en_US.UTF-8
export LC_COLLATE=C

# History settings
export HISTSIZE=1000
export HISTFILESIZE=2000
export HISTCONTROL=ignoreboth

# Prompt setup
if [[ \$EUID -eq 0 ]]; then
    PS1='\\[\\e[31m\\]\\u\\[\\e[0m\\]@\\[\\e[32m\\]\\h\\[\\e[0m\\]:\\[\\e[34m\\]\\w\\[\\e[0m\\]# '
else
    PS1='\\[\\e[36m\\]\\u\\[\\e[0m\\]@\\[\\e[32m\\]\\h\\[\\e[0m\\]:\\[\\e[34m\\]\\w\\[\\e[0m\\]\\$ '
fi

# Voidance specific
if [[ -f /etc/voidance/voidance.conf ]]; then
    source /etc/voidance/voidance.conf
fi
" 644 root root
    
    # Bash configuration
    create_config "$ROOTFS_BASE/etc/bash.bashrc" "# Voidance Bash Configuration
# System-wide bash configuration

# If not running interactively, don't do anything
[[ \$- != *i* ]] && return

# History settings
shopt -s histappend
HISTCONTROL=ignoreboth

# Window size
shopt -s checkwinsize

# Completion
if [[ -f /etc/bash_completion ]]; then
    source /etc/bash_completion
fi

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -pv'
alias wget='wget -c'
alias histg='history | grep'

# Voidance aliases
alias void-update='xbps-install -Su'
alias void-install='xbps-install'
alias void-remove='xbps-remove'
alias void-search='xbps-query -Rs'
alias void-info='xbps-query -S'
alias void-files='xbps-query -f'
" 644 root root
    
    # Inputrc configuration
    create_config "$ROOTFS_BASE/etc/inputrc" "# Voidance Input Configuration
# Readline configuration

set bell-style none
set meta-flag on
set input-meta on
set convert-meta off
set output-meta on
set completion-ignore-case on
set show-all-if-ambiguous on
\"\\e[A\": history-search-backward
\"\\e[B\": history-search-forward
" 644 root root
    
    success "System configuration files created"
}

# Function to create network configuration files
create_network_configs() {
    log "Creating network configuration files..."
    
    # NetworkManager configuration
    create_config "$ROOTFS_BASE/etc/NetworkManager/NetworkManager.conf" "# Voidance NetworkManager Configuration
[main]
plugins=keyfile
dhcp=dhclient

[logging]
level=INFO

[device]
wifi.scan-rand-mac-address=no

[connection]
wifi.powersave=3
" 644 root root
    
    # Hosts file
    create_config "$ROOTFS_BASE/etc/hosts" "# Voidance Hosts File
127.0.0.1   localhost
127.0.1.1   voidance.localdomain voidance

# IPv6
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
" 644 root root
    
    # Resolv.conf template
    create_config "$ROOTFS_BASE/etc/resolv.conf" "# Voidance DNS Configuration
# This file is managed by NetworkManager
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
options edns0
" 644 root root
    
    # NTP configuration
    create_config "$ROOTFS_BASE/etc/ntp.conf" "# Voidance NTP Configuration
# Use public servers from the pool.ntp.org project
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Local clock
server 127.127.1.0
fudge  127.127.1.0 stratum 10

# Drift file
driftfile /var/lib/ntp/drift

# Log file
logfile /var/log/ntp.log
" 644 root root
    
    success "Network configuration files created"
}

# Function to create security configuration files
create_security_configs() {
    log "Creating security configuration files..."
    
    # Login.defs
    create_config "$ROOTFS_BASE/etc/login.defs" "# Voidance Login Configuration
MAIL_DIR        /var/spool/mail
MAIL_FILE       .mail
HUSHLOGIN_FILE  .hushlogins
FAILLOG_ENAB    yes
LOG_UNKFAIL_ENAB no
LOG_OK_LOGINS   no
SYSLOG_SU_ENAB  yes
SYSLOG_SG_ENAB  yes
FTMP_FILE       /var/log/btmp
SU_NAME         su
CONSOLE_GROUPS  floppy:audio:video:cdrom:optical:plugdev:wheel
DEFAULT_HOME    yes
USERGROUPS_ENAB yes
PASS_MAX_DAYS   99999
PASS_MIN_DAYS   0
PASS_WARN_AGE   7
UID_MIN                  1000
UID_MAX                 60000
SYS_UID_MIN               101
SYS_UID_MAX               999
GID_MIN                  1000
GID_MAX                 60000
SYS_GID_MIN               101
SYS_GID_MAX               999
CREATE_HOME     yes
UMASK           077
USERGROUPS_ENAB yes
ENCRYPT_METHOD SHA512
" 644 root root
    
    # Limits configuration
    create_config "$ROOTFS_BASE/etc/security/limits.conf" "# Voidance Limits Configuration
#<domain>      <type>  <item>         <value>
#
#*               soft    core            0
#*               hard    rss             10000
#@student        hard    nproc           20
#@faculty        soft    nproc           20
#@faculty        hard    nproc           50
#ftp             hard    nproc           0
#@student        -       maxlogins       4

# End of file
*               soft    nofile          65536
*               hard    nofile          65536
*               soft    nproc           32768
*               hard    nproc           32768
" 644 root root
    
    # PAM configuration
    create_config "$ROOTFS_BASE/etc/pam.d/system-auth" "# Voidance PAM System Authentication
auth       required     pam_shells.so
auth       requisite    pam_nologin.so
auth       include      system-auth
auth       optional     pam_gnome_keyring.so
account    required     pam_nologin.so
account    include      system-account
password   include      system-password
session    required     pam_limits.so
session    required     pam_unix.so
session    optional     pam_gnome_keyring.so auto_start
" 644 root root
    
    success "Security configuration files created"
}

# Function to create desktop configuration files
create_desktop_configs() {
    log "Creating desktop configuration files..."
    
    # XDG user directories
    create_config "$ROOTFS_BASE/etc/xdg/user-dirs.defaults" "# Voidance XDG User Directories
DESKTOP=Desktop
DOWNLOAD=Downloads
TEMPLATES=Templates
PUBLIC=Public
DOCUMENTS=Documents
MUSIC=Music
PICTURES=Pictures
VIDEOS=Videos
" 644 root root
    
    # XDG user dirs configuration
    create_config "$ROOTFS_BASE/etc/xdg/user-dirs.conf" "# Voidance User Directories Configuration
enabled=True
filename_encoding=UTF-8
" 644 root root
    
    # MIME types
    create_config "$ROOTFS_BASE/etc/mime.types" "# Voidance MIME Types
# This file contains common MIME types

# Text
text/plain txt
text/html html htm
text/css css
text/javascript js
text/xml xml
text/csv csv

# Images
image/jpeg jpeg jpg
image/png png
image/gif gif
image/svg+xml svg
image/webp webp

# Audio
audio/mpeg mp3
audio/ogg ogg
audio/wav wav
audio/flac flac
audio/mp4 m4a

# Video
video/mp4 mp4
video/webm webm
video/quicktime mov
video/x-msvideo avi
video/x-matroska mkv

# Applications
application/pdf pdf
application/zip zip
application/x-tar tar
application/x-gzip gz
application/x-bzip2 bz2
application/x-7z-compressed 7z
" 644 root root
    
    # GTK configuration
    create_config "$ROOTFS_BASE/etc/gtk-3.0/settings.ini" "[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
gtk-font-name=JetBrains Mono 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
" 644 root root
    
    success "Desktop configuration files created"
}

# Function to create font configuration files
create_font_configs() {
    log "Creating font configuration files..."
    
    # Font configuration
    create_config "$ROOTFS_BASE/etc/fonts/fonts.conf" "<?xml version=\"1.0\"?>
<!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">
<fontconfig>
<!-- Voidance Font Configuration -->

<!-- Font directories -->
<dir>/usr/share/fonts</dir>
<dir>/usr/local/share/fonts</dir>
<dir>~/.fonts</dir>
<dir>~/.local/share/fonts</dir>

<!-- Font cache -->
<cachedir>/var/cache/fontconfig</cachedir>
<cachedir>~/.fontconfig</cachedir>

<!-- Font substitution -->
<alias>
  <family>serif</family>
  <prefer>
    <family>Noto Serif</family>
    <family>DejaVu Serif</family>
  </prefer>
</alias>

<alias>
  <family>sans-serif</family>
  <prefer>
    <family>Noto Sans</family>
    <family>DejaVu Sans</family>
  </prefer>
</alias>

<alias>
  <family>monospace</family>
  <prefer>
    <family>JetBrains Mono</family>
    <family>DejaVu Sans Mono</family>
  </prefer>
</alias>

<!-- Font rendering -->
<match target=\"font\">
  <edit name=\"antialias\" mode=\"assign\">
    <bool>true</bool>
  </edit>
  <edit name=\"hinting\" mode=\"assign\">
    <bool>true</bool>
  </edit>
  <edit name=\"hintstyle\" mode=\"assign\">
    <const>hintfull</const>
  </edit>
  <edit name=\"rgba\" mode=\"assign\">
    <const>rgb</const>
  </edit>
  <edit name=\"lcdfilter\" mode=\"assign\">
    <const>lcddefault</const>
  </edit>
</match>

</fontconfig>
" 644 root root
    
    # Font local configuration
    create_config "$ROOTFS_BASE/etc/fonts/conf.d/99-voidance.conf" "<?xml version=\"1.0\"?>
<!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">
<fontconfig>
<!-- Voidance Local Font Configuration -->

<!-- Enable subpixel rendering -->
<match target=\"font\">
  <edit name=\"rgba\" mode=\"assign\">
    <const>rgb</const>
  </edit>
</match>

<!-- Enable LCD filter -->
<match target=\"font\">
  <edit name=\"lcdfilter\" mode=\"assign\">
    <const>lcddefault</const>
  </edit>
</match>

<!-- Prefer bitmap fonts for small sizes -->
<match target=\"font\">
  <test name=\"pixelsize\" compare=\"less_eq\">
    <double>12</double>
  </test>
  <edit name=\"antialias\" mode=\"assign\">
    <bool>false</bool>
  </edit>
</match>

</fontconfig>
" 644 root root
    
    success "Font configuration files created"
}

# Function to create hardware configuration files
create_hardware_configs() {
    log "Creating hardware configuration files..."
    
    # Modprobe configuration
    create_config "$ROOTFS_BASE/etc/modprobe.d/voidance.conf" "# Voidance Kernel Module Configuration
# Audio
options snd-hda-intel index=1,0
options snd-usb-audio index=1

# Graphics
options i915 modeset=1
options amdgpu modeset=1
options nvidia-drm modeset=1

# Network
options cfg80211 ieee80211_regdom=US

# USB
options usbcore autosuspend=2

# Power management
options thinkpad_acpi fan_control=1
" 644 root root
    
    # Module loading configuration
    create_config "$ROOTFS_BASE/etc/modules-load.d/voidance.conf" "# Voidance Module Loading Configuration
# Audio modules
snd-hda-intel
snd-usb-audio

# Graphics modules
i915
amdgpu
nvidia-drm

# Network modules
cfg80211
mac80211

# Filesystem modules
vfat
ntfs
exfat

# USB modules
usb-storage
uhci_hcd
ehci_hcd
xhci_hcd
" 644 root root
    
    # Udev rules
    create_config "$ROOTFS_BASE/etc/udev/rules.d/99-voidance.rules" "# Voidance Udev Rules

# USB devices
SUBSYSTEM==\"usb\", MODE=\"0666\"

# Input devices
SUBSYSTEM==\"input\", MODE=\"0666\"

# Audio devices
SUBSYSTEM==\"sound\", MODE=\"0666\"

# Video devices
SUBSYSTEM==\"video4linux\", MODE=\"0666\"

# DRI devices
SUBSYSTEM==\"drm\", MODE=\"0666\"

# TTY devices
KERNEL==\"tty[0-9]*\", MODE=\"0666\"

# HID devices
SUBSYSTEM==\"hidraw\", MODE=\"0666\"
" 644 root root
    
    success "Hardware configuration files created"
}

# Function to create service configuration files
create_service_configs() {
    log "Creating service configuration files..."
    
    # Runit configuration
    create_config "$ROOTFS_BASE/etc/runit/func" "# Voidance Runit Functions
# Common functions for runit scripts

# Function to check if a command exists
command_exists() {
    command -v \"$1\" >/dev/null 2>&1
}

# Function to wait for service
wait_for_service() {
    local timeout=$1
    local service=$2
    
    for i in $(seq 1 $timeout); do
        if sv status \"$service\" >/dev/null 2>&1; then
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
" 644 root root
    
    # Service environment
    create_config "$ROOTFS_BASE/etc/sv/getty-1/conf" "# Voidance Getty Configuration
# Getty service configuration

# TTY device
TTY=tty1

# Baud rate
BAUD=38400

# Terminal type
TERM=linux

# Getty program
GETTY=/sbin/agetty

# Getty options
GETTY_ARGS=\"--noclear --login-pause\"
" 644 root root
    
    success "Service configuration files created"
}

# Function to create user skeleton files
create_skeleton_files() {
    log "Creating user skeleton files..."
    
    # User bashrc
    create_config "$ROOTFS_BASE/etc/skel/.bashrc" "# Voidance User Bash Configuration
# Personal bash configuration

# Source global definitions
if [[ -f /etc/bash.bashrc ]]; then
    source /etc/bash.bashrc
fi

# User aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -pv'
alias wget='wget -c'

# Voidance aliases
alias void-update='xbps-install -Su'
alias void-install='xbps-install'
alias void-remove='xbps-remove'
alias void-search='xbps-query -Rs'

# Custom prompt
if [[ \$EUID -eq 0 ]]; then
    PS1='\\[\\e[31m\\]\\u\\[\\e[0m\\]@\\[\\e[32m\\]\\h\\[\\e[0m\\]:\\[\\e[34m\\]\\w\\[\\e[0m\\]# '
else
    PS1='\\[\\e[36m\\]\\u\\[\\e[0m\\]@\\[\\e[32m\\]\\h\\[\\e[0m\\]:\\[\\e[34m\\]\\w\\[\\e[0m\\]\\$ '
fi

# User functions
mkcd() {
    mkdir -p \"\$1\" && cd \"\$1\"
}

extract() {
    if [[ -f \"\$1\" ]]; then
        case \"\$1\" in
            *.tar.bz2)   tar xjf \"\$1\"     ;;
            *.tar.gz)    tar xzf \"\$1\"     ;;
            *.bz2)       bunzip2 \"\$1\"     ;;
            *.rar)       unrar x \"\$1\"     ;;
            *.gz)        gunzip \"\$1\"      ;;
            *.tar)       tar xf \"\$1\"      ;;
            *.tbz2)      tar xjf \"\$1\"     ;;
            *.tgz)       tar xzf \"\$1\"     ;;
            *.zip)       unzip \"\$1\"       ;;
            *.Z)         uncompress \"\$1\"  ;;
            *.7z)        7z x \"\$1\"        ;;
            *)           echo \"'\$1' cannot be extracted via extract()\" ;;
        esac
    else
        echo \"'\$1' is not a valid file\"
    fi
}
" 600 root root
    
    # User profile
    create_config "$ROOTFS_BASE/etc/skel/.profile" "# Voidance User Profile
# Personal environment configuration

# Set PATH to include user's private bin if it exists
if [[ -d \"\$HOME/bin\" ]]; then
    PATH=\"\$HOME/bin:\$PATH\"
fi

if [[ -d \"\$HOME/.local/bin\" ]]; then
    PATH=\"\$HOME/.local/bin:\$PATH\"
fi

export PATH

# Default editor
export EDITOR=vim
export VISUAL=vim

# Default browser
export BROWSER=firefox

# Go workspace
if command -v go >/dev/null 2>&1; then
    export GOPATH=\"\$HOME/go\"
    export PATH=\"\$GOPATH/bin:\$PATH\"
fi

# Rust cargo
if [[ -d \"\$HOME/.cargo/bin\" ]]; then
    export PATH=\"\$HOME/.cargo/bin:\$PATH\"
fi

# Node.js
if [[ -d \"\$HOME/.npm-global/bin\" ]]; then
    export PATH=\"\$HOME/.npm-global/bin:\$PATH\"
fi
" 600 root root
    
    # User directories
    create_config "$ROOTFS_BASE/etc/skel/.config/user-dirs.dirs" "# Voidance User Directories
XDG_DESKTOP_DIR=\"\$HOME/Desktop\"
XDG_DOWNLOAD_DIR=\"\$HOME/Downloads\"
XDG_TEMPLATES_DIR=\"\$HOME/Templates\"
XDG_PUBLICSHARE_DIR=\"\$HOME/Public\"
XDG_DOCUMENTS_DIR=\"\$HOME/Documents\"
XDG_MUSIC_DIR=\"\$HOME/Music\"
XDG_PICTURES_DIR=\"\$HOME/Pictures\"
XDG_VIDEOS_DIR=\"\$HOME/Videos\"
" 600 root root
    
    # Git configuration
    create_config "$ROOTFS_BASE/etc/skel/.gitconfig" "[user]
    name = Voidance User
    email = user@voidance.local

[core]
    editor = vim
    autocrlf = input

[init]
    defaultBranch = main

[push]
    default = simple

[pull]
    rebase = false
" 600 root root
    
    success "User skeleton files created"
}

# Function to create Voidance-specific configuration
create_voidance_configs() {
    log "Creating Voidance-specific configuration files..."
    
    # Voidance main configuration
    create_config "$ROOTFS_BASE/etc/voidance/voidance.conf" "# Voidance Main Configuration
# This file contains global Voidance settings

# System information
VOIDANCE_VERSION=\"$(date +%Y.%m.%d)\"
VOIDANCE_ARCH=\"$(uname -m)\"
VOIDANCE_KERNEL=\"$(uname -r)\"

# Desktop environment
VOIDANCE_DESKTOP=\"wayland\"
VOIDANCE_COMPOSITOR=\"niri\"
VOIDANCE_FALLBACK_COMPOSITOR=\"sway\"

# Audio system
VOIDANCE_AUDIO=\"pipewire\"

# Display manager
VOIDANCE_DISPLAY_MANAGER=\"sddm\"

# Package management
VOIDANCE_REPO=\"https://repo-default.voidlinux.org/current\"

# Logging
VOIDANCE_LOG_LEVEL=\"info\"
VOIDANCE_LOG_FILE=\"/var/log/voidance/voidance.log\"

# Hardware detection
VOIDANCE_AUTO_DETECT=\"true\"
VOIDANCE_HARDWARE_PROFILE=\"/var/lib/voidance/hardware/profile\"

# User settings
VOIDANCE_DEFAULT_SHELL=\"/bin/bash\"
VOIDANCE_DEFAULT_GROUPS=\"users,audio,video,input,plugdev,wheel\"

# Security
VOIDANCE_AUTO_UPDATES=\"false\"
VOIDANCE_FIREWALL=\"ufw\"

# Performance
VOIDANCE_AUTO_TUNE=\"true\"
VOIDANCE_POWER_PROFILE=\"balanced\"
" 644 root root
    
    # Voidance environment
    create_config "$ROOTFS_BASE/etc/voidance/environment" "# Voidance Environment Variables
# This file sets environment variables for Voidance

# Wayland
export WAYLAND_DISPLAY=wayland-1
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Voidance

# Qt
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# GTK
export GTK_THEME=Adwaita:dark

# Browser
export BROWSER=firefox
export DEFAULT_BROWSER=firefox

# Editor
export EDITOR=vim
export VISUAL=vim

# Terminal
export TERMINAL=ghostty

# File manager
export FILE_MANAGER=thunar

# Audio
export PIPEWIRE_LATENCY=128/48000

# Hardware
export LIBVA_DRIVER_NAME=iHD
export VDPAU_DRIVER=va_gl

# Performance
export MESA_GL_VERSION_OVERRIDE=4.6
" 644 root root
    
    success "Voidance-specific configuration files created"
}

# Function to validate configuration files
validate_configs() {
    log "Validating configuration files..."
    
    local errors=0
    
    # Check essential config files
    local essential_configs=(
        "/etc/os-release"
        "/etc/hostname"
        "/etc/hosts"
        "/etc/fstab"
        "/etc/profile"
        "/etc/bash.bashrc"
        "/etc/voidance/voidance.conf"
    )
    
    for config in "${essential_configs[@]}"; do
        if [[ ! -f "$ROOTFS_BASE$config" ]]; then
            error "Missing essential config: $config"
            ((errors++))
        fi
    done
    
    # Check skeleton files
    local skeleton_files=(
        "/etc/skel/.bashrc"
        "/etc/skel/.profile"
        "/etc/skel/.gitconfig"
        "/etc/skel/.config/user-dirs.dirs"
    )
    
    for file in "${skeleton_files[@]}"; do
        if [[ ! -f "$ROOTFS_BASE$file" ]]; then
            error "Missing skeleton file: $file"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        success "Configuration files validation passed"
        return 0
    else
        error "Configuration files validation failed with $errors errors"
        return 1
    fi
}

# Main function
main() {
    log "Setting up Voidance default configuration files..."
    
    # Create system configurations
    create_system_configs
    
    # Create network configurations
    create_network_configs
    
    # Create security configurations
    create_security_configs
    
    # Create desktop configurations
    create_desktop_configs
    
    # Create font configurations
    create_font_configs
    
    # Create hardware configurations
    create_hardware_configs
    
    # Create service configurations
    create_service_configs
    
    # Create user skeleton files
    create_skeleton_files
    
    # Create Voidance-specific configurations
    create_voidance_configs
    
    # Validate configurations
    validate_configs
    
    success "Default configuration files setup completed"
    log "Configuration files created in: $ROOTFS_BASE"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi