#!/bin/bash
# Voidance Package Groups Configuration
# This script defines and manages package groups for different use cases

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[PKG-GROUPS]${NC} $1"
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

# Package groups definition
declare -A PACKAGE_GROUPS=(
    # ============================================================================
    # CORE SYSTEM GROUPS
    # ============================================================================
    
    ["minimal"]="base-system linux linux-firmware e2fsprogs dosfstools xbps curl"
    
    ["base"]="base-system linux linux-firmware dracut e2fsprogs dosfstools btrfs-progs xfsprogs f2fs-tools xbps curl wget rsync tar unzip zip p7zip util-linux coreutils findutils grep sed awk gawk diffutils patch file which tree htop iotop lsof strace ltrace"
    
    ["standard"]="base network-manager audio-system display-manager desktop-applications system-utilities development-tools multimedia-codecs hardware-support security-tools documentation themes-appearance"
    
    ["complete"]="base network-manager audio-system display-manager desktop-applications system-utilities development-tools multimedia-codecs hardware-support security-tools documentation themes-appearance accessibility virtualization gaming office custom-voidance"
    
    # ============================================================================
    # SYSTEM COMPONENT GROUPS
    # ============================================================================
    
    ["network-manager"]="NetworkManager nmcli network-manager-applet iw wpa_supplicant dhcpcd openssh wget curl"
    
    ["audio-system"]="pipewire pipewire-pulse wireplumber pamixer pulsemixer alsa-utils pavucontrol helvum"
    
    ["display-manager"]="sddm sddm-themes seatd polkit elogind"
    
    ["desktop-applications"]="firefox firefox-wayland ghostty vim vim-x11 neovim thunar thunar-volman thunar-archive-plugin file-roller unar p7zip zip unzip imv feh evince evince-wayland mpv mpv-wayland audacious btop htop"
    
    ["system-utilities"]="tlp powertop acpi acpid lm_sensors xsensors gparted testdisk photorec rsync borgbackup"
    
    ["development-tools"]="git git-lfs make gcc gcc-c++ pkg-config autoconf automake libtool cmake ninja python3 python3-pip nodejs npm rust cargo gdb valgrind strace ltrace perf linux-tools nmap wireshark-cli tcpdump"
    
    ["multimedia-codecs"]="ffmpeg gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad gstreamer1-plugins-ugly libpng libjpeg-turbo libwebp libtiff"
    
    ["hardware-support"]="mesa-dri vulkan-loader vulkan-tools intel-media-driver libva-intel-driver mesa-vulkan-radeon libva-amdgpu-driver nvidia nvidia-settings nvidia-smi linux-firmware-intel linux-firmware-realtek linux-firmware-atheros bluez bluez-utils cups cups-filters system-config-printer"
    
    ["security-tools"]="ufw gufw pam gnupg2 fail2ban rkhunter chkrootkit"
    
    ["documentation"]="man-pages man-pages-posix info texinfo"
    
    ["themes-appearance"]="adwaita-icon-theme gnome-themes-extra qt5ct qt6ct papirus-icon-theme breeze-cursors fontconfig freetype noto-fonts-ttf noto-fonts-emoji jetbrains-mono-ttf font-awesome-ttf"
    
    ["accessibility"]="espeak-ng at-spi2-core at-spi2-atk"
    
    ["virtualization"]="qemu qemu-system-x86_64 libvirt virt-manager virt-install podman docker docker-compose"
    
    ["gaming"]="steam steam-wayland lutris heroic-games-launcher gamemode gamescope"
    
    ["office"]="libreoffice libreoffice-i18n pdfarranger pdfmod"
    
    ["custom-voidance"]="niri sway swaybg swaylock waybar wofi mako libnotify dunstify tmux screen jq json-c fontconfig freetype noto-fonts-ttf noto-fonts-emoji jetbrains-mono-ttf font-awesome-ttf swaylock swayidle brightnessctl wayland wayland-protocols wayland-utils i3status i3blocks rofi-wayland"
    
    # ============================================================================
    # DESKTOP ENVIRONMENT GROUPS
    # ============================================================================
    
    ["wayland-niri"]="niri wayland wayland-protocols seatd polkit elogind waybar wofi mako ghostty swaylock swayidle brightnessctl"
    
    ["wayland-sway"]="sway swaybg swaylock wayland wayland-protocols seatd polkit elogind waybar wofi mako ghostty i3status i3blocks rofi-wayland"
    
    ["terminal-focused"]="ghostty tmux screen vim neovim htop btop iotop lsof strace ltrace tree jq json-c"
    
    ["multimedia"]="ffmpeg gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad gstreamer1-plugins-ugly mpv mpv-wayland audacious vlc imv feh evince evince-wayland"
    
    ["web-development"]="git make gcc gcc-c++ pkg-config autoconf automake libtool cmake ninja python3 python3-pip nodejs npm rust cargo firefox firefox-wayland curl wget rsync"
    
    ["system-administration"]="NetworkManager nmcli network-manager-applet bluez bluez-utils cups cups-filters system-config-printer gparted testdisk photorec rsync borgbackup ufw gufw fail2ban rkhunter chkrootkit nmap wireshark-cli tcpdump"
    
    # ============================================================================
    # HARDWARE-SPECIFIC GROUPS
    # ============================================================================
    
    ["laptop"]="tlp powertop acpi acpid lm_sensors xsensors brightnessctl bluez bluez-utils"
    
    ["desktop"]="nvidia nvidia-settings nvidia-smi mesa-dri vulkan-loader vulkan-tools intel-media-driver libva-intel-driver mesa-vulkan-radeon libva-amdgpu-driver"
    
    ["server"]="openssh rsync borgbackup ufw fail2ban rkhunter chkrootkit nmap tcpdump docker podman libvirt qemu"
    
    ["virtual-machine"]="qemu qemu-system-x86_64 libvirt virt-manager virt-install ovmf seabios"
    
    ["gaming-rig"]="steam steam-wayland lutris heroic-games-launcher gamemode gamescope nvidia nvidia-settings nvidia-smi mesa-vulkan-radeon vulkan-loader vulkan-tools"
    
    ["development-workstation"]="git make gcc gcc-c++ pkg-config autoconf automake libtool cmake ninja python3 python3-pip nodejs npm rust cargo gdb valgrind strace ltrace perf linux-tools docker docker-compose podman"
    
    # ============================================================================
    # SIZE-OPTIMIZED GROUPS
    # ============================================================================
    
    ["tiny"]="base-system linux linux-firmware e2fsprogs xbps curl vim tmux"
    
    ["small"]="minimal network-manager audio-system display-manager terminal-focused"
    
    ["medium"]="small desktop-applications system-utilities development-tools multimedia-codecs"
    
    ["large"]="medium hardware-support security-tools documentation themes-appearance"
    
    ["huge"]="large accessibility virtualization gaming office custom-voidance"
    
    # ============================================================================
    # SPECIALIZED GROUPS
    # ============================================================================
    
    ["privacy-focused"]="firefox ufw gnupg2 fail2ban rkhunter chkrootkit tor torsocks"
    
    ["lightweight"]="i3-wm i3status i3blocks rofi dunst picom feh sxhkd"
    
    ["accessibility"]="espeak-ng at-spi2-core at-spi2-atk orca"
    
    ["multilingual"]="glibc-locales libreoffice-i18n firefox-i18n"
    
    ["scientific"]="python3-numpy python3-scipy python3-matplotlib R octave sage"
    
    ["graphics-design"]="gimp inkscape krita blender darktable"
    
    ["audio-production"]="audacity ardour lmms reaper carla"
    
    ["video-production"]="kdenlive shotcut obs-studio blender"
    
    ["3d-modeling"]="blender freecad openscad"
    
    ["embedded-development"]="avr-gcc avr-libc arm-none-eabi-gcc openocd"
    
    ["reverse-engineering"]="ghidra radare2 cutter ida-free"
    
    ["forensics"]="autopsy sleuthkit volatility3"
    
    ["penetration-testing"]="metasploit nmap wireshark aircrack-ng john hashcat burpsuite"
)

# Group descriptions
declare -A GROUP_DESCRIPTIONS=(
    ["minimal"]="Absolute minimum system for basic functionality"
    ["base"]="Complete base system with essential utilities"
    ["standard"]="Standard desktop system with common applications"
    ["complete"]="Complete system with all features and applications"
    ["network-manager"]="Network management and connectivity tools"
    ["audio-system"]="Audio system with PipeWire and PulseAudio compatibility"
    ["display-manager"]="Display manager with SDDM and session management"
    ["desktop-applications"]="Common desktop applications for daily use"
    ["system-utilities"]="System administration and maintenance utilities"
    ["development-tools"]="Complete development environment with multiple languages"
    ["multimedia-codecs"]="Audio and video codec support"
    ["hardware-support"]="Drivers and support for various hardware"
    ["security-tools"]="Security and privacy tools"
    ["documentation"]="System documentation and manual pages"
    ["themes-appearance"]="Themes, icons, and appearance customization"
    ["accessibility"]="Accessibility tools and screen readers"
    ["virtualization"]="Virtualization and container tools"
    ["gaming"]="Gaming platform and tools"
    ["office"]="Office productivity suite"
    ["custom-voidance"]="Voidance-specific packages and configurations"
    ["wayland-niri"]="Niri Wayland compositor environment"
    ["wayland-sway"]="Sway Wayland compositor environment"
    ["terminal-focused"]="Terminal-focused workflow tools"
    ["multimedia"]="Multimedia creation and consumption tools"
    ["web-development"]="Web development environment"
    ["system-administration"]="System administration tools"
    ["laptop"]="Laptop-specific optimizations and tools"
    ["desktop"]="Desktop hardware support and drivers"
    ["server"]="Server administration and services"
    ["virtual-machine"]="Virtual machine management"
    ["gaming-rig"]="Gaming-optimized system"
    ["development-workstation"]="Development-optimized system"
    ["tiny"]="Minimal system for embedded or specialized use"
    ["small"]="Small system with basic desktop functionality"
    ["medium"]="Medium system with standard desktop features"
    ["large"]="Large system with extensive features"
    ["huge"]="Maximum system with all available features"
    ["privacy-focused"]="Privacy and security-focused configuration"
    ["lightweight"]="Lightweight desktop environment"
    ["accessibility"]="Enhanced accessibility support"
    ["multilingual"]="Multi-language support"
    ["scientific"]="Scientific computing tools"
    ["graphics-design"]="Graphics and design applications"
    ["audio-production"]="Audio production and editing tools"
    ["video-production"]="Video production and editing tools"
    ["3d-modeling"]="3D modeling and CAD applications"
    ["embedded-development"]="Embedded systems development"
    ["reverse-engineering"]="Reverse engineering tools"
    ["forensics"]="Digital forensics tools"
    ["penetration-testing"]="Penetration testing and security assessment"
)

# Function to get package group
get_package_group() {
    local group="$1"
    echo "${PACKAGE_GROUPS[$group]:-}"
}

# Function to get group description
get_group_description() {
    local group="$1"
    echo "${GROUP_DESCRIPTIONS[$group]:-No description available}"
}

# Function to list all groups
list_groups() {
    log "Available package groups:"
    for group in "${!PACKAGE_GROUPS[@]}"; do
        printf "  %-25s - %s\n" "$group" "${GROUP_DESCRIPTIONS[$group]}"
    done
}

# Function to show group details
show_group_details() {
    local group="$1"
    
    if [[ -z "${PACKAGE_GROUPS[$group]:-}" ]]; then
        error "Package group not found: $group"
    fi
    
    log "Package Group: $group"
    log "Description: ${GROUP_DESCRIPTIONS[$group]}"
    log "Packages: ${PACKAGE_GROUPS[$group]}"
}

# Function to expand group dependencies
expand_group_dependencies() {
    local groups="$@"
    local expanded_packages=""
    
    for group in "$groups"; do
        local group_packages="${PACKAGE_GROUPS[$group]:-}"
        
        if [[ -z "$group_packages" ]]; then
            warning "Unknown package group: $group"
            continue
        fi
        
        # Check if group contains other groups (recursive expansion)
        for package in $group_packages; do
            if [[ -n "${PACKAGE_GROUPS[$package]:-}" ]]; then
                # This is another group, expand it recursively
                local sub_packages=$(expand_group_dependencies "$package")
                expanded_packages="$expanded_packages $sub_packages"
            else
                # This is a package, add it
                expanded_packages="$expanded_packages $package"
            fi
        done
    done
    
    # Remove duplicates and sort
    echo "$expanded_packages" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Function to generate package list from groups
generate_package_list() {
    local groups="$@"
    local output_file="${!#}"  # Last argument is output file
    local groups_list=("${@:1:$#-1}")  # All arguments except last
    
    log "Generating package list from groups: ${groups_list[*]}"
    
    local packages=$(expand_group_dependencies "${groups_list[@]}")
    
    > "$output_file"
    
    # Add header
    cat > "$output_file" << EOF
# Voidance Package List
# Generated from groups: ${groups_list[*]}
# Generated on: $(date)

EOF
    
    # Add packages
    for package in $packages; do
        echo "$package" >> "$output_file"
    done
    
    success "Package list generated: $output_file"
    log "Total packages: $(echo "$packages" | wc -w)"
}

# Function to validate group dependencies
validate_group_dependencies() {
    local group="$1"
    local group_packages="${PACKAGE_GROUPS[$group]:-}"
    
    if [[ -z "$group_packages" ]]; then
        error "Package group not found: $group"
    fi
    
    log "Validating dependencies for group: $group"
    
    for package in $group_packages; do
        if [[ -n "${PACKAGE_GROUPS[$package]:-}" ]]; then
            log "  Found sub-group: $package"
            validate_group_dependencies "$package"
        else
            if xbps-query "$package" &>/dev/null; then
                log "  ✓ Package available: $package"
            else
                warning "  ✗ Package not found: $package"
            fi
        fi
    done
}

# Function to create group-based ISO configurations
create_group_configs() {
    local config_dir="$1"
    
    log "Creating group-based ISO configurations in $config_dir"
    
    mkdir -p "$config_dir"
    
    # Create configurations for common use cases
    local configs=(
        "minimal:minimal"
        "desktop:standard"
        "developer:standard development-workstation"
        "gaming:standard gaming-rig"
        "server:base server"
        "complete:complete"
    )
    
    for config in "${configs[@]}"; do
        local name=$(echo "$config" | cut -d: -f1)
        local groups=$(echo "$config" | cut -d: -f2)
        local output_file="$config_dir/${name}-packages.txt"
        
        generate_package_list $groups "$output_file"
        
        # Create configuration file
        cat > "$config_dir/${name}-config.sh" << EOF
#!/bin/bash
# Voidance ISO Configuration: $name
# Generated from groups: $groups

ISO_NAME="voidance-$name"
ISO_LABEL="Voidance Linux ($name)"
ISO_VERSION="\$(date +%Y.%m.%d)"

PACKAGE_LIST="$output_file"
REPO_CONF="/opt/voidance-iso/config/repositories.conf"

# Additional configuration can be added here
EOF
        
        chmod +x "$config_dir/${name}-config.sh"
        
        success "Created configuration: $name"
    done
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-list}" in
        "list")
            list_groups
            ;;
        "show")
            if [[ -n "${2:-}" ]]; then
                show_group_details "$2"
            else
                error "Group name required"
            fi
            ;;
        "expand")
            shift
            if [[ $# -gt 0 ]]; then
                expand_group_dependencies "$@"
            else
                error "At least one group name required"
            fi
            ;;
        "generate")
            shift
            if [[ $# -ge 2 ]]; then
                generate_package_list "$@"
            else
                error "Groups and output file required"
            fi
            ;;
        "validate")
            if [[ -n "${2:-}" ]]; then
                validate_group_dependencies "$2"
            else
                error "Group name required"
            fi
            ;;
        "create-configs")
            if [[ -n "${2:-}" ]]; then
                create_group_configs "$2"
            else
                error "Configuration directory required"
            fi
            ;;
        *)
            echo "Usage: $0 {list|show|expand|generate|validate|create-configs} [args...]"
            echo ""
            echo "Examples:"
            echo "  $0 list                    # List all groups"
            echo "  $0 show base              # Show base group details"
            echo "  $0 expand base standard    # Expand groups to packages"
            echo "  $0 generate base standard /tmp/packages.txt  # Generate package list"
            echo "  $0 validate base           # Validate group dependencies"
            echo "  $0 create-configs /tmp/configs  # Create group configurations"
            exit 1
            ;;
    esac
fi