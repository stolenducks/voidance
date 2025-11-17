#!/bin/bash
# Voidance Package Version and Dependency Configuration
# This script manages package versions, dependencies, and constraints

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[PKG-CONFIG]${NC} $1"
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

# Package version constraints
declare -A PACKAGE_VERSIONS=(
    # Core system
    ["linux"]=">=6.6"
    ["linux-firmware"]=">=20240115"
    ["dracut"]=">=059"
    
    # Audio system
    ["pipewire"]=">=1.0"
    ["wireplumber"]=">=0.5"
    
    # Display manager
    ["sddm"]=">=0.21"
    
    # Compositors
    ["niri"]=">=0.1.5"
    ["sway"]=">=1.9"
    
    # Desktop applications
    ["firefox"]=">=120"
    ["ghostty"]=">=1.0"
    ["thunar"]=">=4.18"
    ["waybar"]=">=0.10"
    ["wofi"]=">=1.4"
    ["mako"]=">=1.8"
    
    # Development tools
    ["gcc"]=">=13"
    ["python3"]=">=3.11"
    ["nodejs"]=">=20"
    ["rust"]=">=1.75"
    
    # Multimedia
    ["ffmpeg"]=">=6.0"
    ["mpv"]=">=0.37"
    
    # Virtualization
    ["qemu"]=">=8.0"
    ["libvirt"]=">=10.0"
)

# Package dependencies
declare -A PACKAGE_DEPS=(
    # Audio dependencies
    ["pipewire"]="pipewire-pulse wireplumber"
    ["pipewire-pulse"]="pipewire"
    ["wireplumber"]="pipewire"
    
    # Display manager dependencies
    ["sddm"]="qt6-qtsvg qt6-qtdeclarative qt6-qtquickcontrols2"
    
    # Compositor dependencies
    ["niri"]="wayland wayland-protocols seatd"
    ["sway"]="wayland wayland-protocols swaybg swaylock"
    
    # Desktop application dependencies
    ["firefox"]="ffmpeg libva libvdpau"
    ["thunar"]="gtk3 gtk-update-icon-cache desktop-file-utils"
    ["waybar"]="json-c gtkmm3 libpulseaudio"
    ["wofi"]="gtk3 wayland"
    ["mako"]="pango libnotify"
    
    # Development dependencies
    ["gcc-c++"]="gcc"
    ["python3-pip"]="python3"
    ["npm"]="nodejs"
    
    # Multimedia dependencies
    ["mpv"]="ffmpeg libass libva"
    
    # Virtualization dependencies
    ["virt-manager"]="libvirt qemu libvirt-glib"
    ["docker"]="containerd runc"
)

# Package conflicts
declare -A PACKAGE_CONFLICTS=(
    # Audio conflicts
    ["pipewire"]="pulseaudio"
    ["pipewire-pulse"]="pulseaudio"
    
    # Display manager conflicts
    ["sddm"]="gdm lightdm lxdm"
    
    # Compositor conflicts
    ["niri"]="sway i3 bspwm"
    
    # Package manager conflicts
    ["apt"]="dnf yum zypper"
    ["yum"]="apt dnf zypper"
    ["dnf"]="apt yum zypper"
)

# Package alternatives
declare -A PACKAGE_ALTERNATIVES=(
    # Text editors
    ["editor"]="vim neovim nano micro"
    
    # File managers
    ["file-manager"]="thunar pcmanfm dolphin nautilus"
    
    # Web browsers
    ["browser"]="firefox chromium brave vivaldi"
    
    # Terminal emulators
    ["terminal"]="ghostty alacritty kitty foot"
    
    # Status bars
    ["status-bar"]="waybar i3status polybar"
    
    # Launchers
    ["launcher"]="wofi rofi dmenu"
    
    # Notification daemons
    ["notifications"]="mako dunst fnott"
)

# Package groups
declare -A PACKAGE_GROUPS=(
    ["base"]="base-system linux linux-firmware dracut e2fsprogs dosfstools"
    ["audio"]="pipewire pipewire-pulse wireplumber pamixer pulsemixer alsa-utils pavucontrol"
    ["network"]="NetworkManager nmcli network-manager-applet iw wpa_supplicant dhcpcd openssh"
    ["desktop"]="sddm seatd polkit elogind"
    ["compositor"]="niri sway wayland wayland-protocols"
    ["applications"]="firefox ghostty thunar waybar wofi mako mpv evince"
    ["development"]="git make gcc gcc-c++ python3 nodejs rust"
    ["multimedia"]="ffmpeg gstreamer1 mpv vlc"
    ["virtualization"]="qemu libvirt virt-manager podman docker"
    ["gaming"]="steam lutris heroic-games-launcher gamemode"
    ["office"]="libreoffice evince pdfarranger"
)

# Architecture-specific packages
declare -A ARCH_PACKAGES=(
    ["x86_64"]="grub-x86_64-efi grub-i386-efi"
    ["i686"]="grub-i386-pc"
    ["aarch64"]="grub-aarch64-efi"
    ["armv7l"]="grub-armv7l-efi"
)

# Function to get package version constraint
get_package_version() {
    local package="$1"
    echo "${PACKAGE_VERSIONS[$package]:-}"
}

# Function to get package dependencies
get_package_deps() {
    local package="$1"
    echo "${PACKAGE_DEPS[$package]:-}"
}

# Function to get package conflicts
get_package_conflicts() {
    local package="$1"
    echo "${PACKAGE_CONFLICTS[$package]:-}"
}

# Function to get package alternatives
get_package_alternatives() {
    local category="$1"
    echo "${PACKAGE_ALTERNATIVES[$category]:-}"
}

# Function to get package group
get_package_group() {
    local group="$1"
    echo "${PACKAGE_GROUPS[$group]:-}"
}

# Function to get architecture-specific packages
get_arch_packages() {
    local arch="$1"
    echo "${ARCH_PACKAGES[$arch]:-}"
}

# Function to validate package version
validate_package_version() {
    local package="$1"
    local required_version="${PACKAGE_VERSIONS[$package]:-}"
    
    if [[ -z "$required_version" ]]; then
        return 0  # No version constraint
    fi
    
    local installed_version
    installed_version=$(xbps-query "$package" 2>/dev/null | awk '/version/ {print $2}' || echo "")
    
    if [[ -z "$installed_version" ]]; then
        return 0  # Package not installed, will be installed
    fi
    
    # Simple version comparison (can be enhanced with dpkg-style comparison)
    if xbps-uhelper cmpver "$installed_version" "${required_version#>=}"; then
        return 0  # Version is sufficient
    else
        return 1  # Version is insufficient
    fi
}

# Function to check package dependencies
check_package_deps() {
    local package="$1"
    local deps="${PACKAGE_DEPS[$package]:-}"
    
    if [[ -z "$deps" ]]; then
        return 0  # No dependencies
    fi
    
    for dep in $deps; do
        if ! xbps-query "$dep" &>/dev/null; then
            log "Missing dependency for $package: $dep"
            return 1
        fi
    done
    
    return 0
}

# Function to check package conflicts
check_package_conflicts() {
    local package="$1"
    local conflicts="${PACKAGE_CONFLICTS[$package]:-}"
    
    if [[ -z "$conflicts" ]]; then
        return 0  # No conflicts
    fi
    
    for conflict in $conflicts; do
        if xbps-query "$conflict" &>/dev/null; then
            log "Conflict detected: $package conflicts with $conflict"
            return 1
        fi
    done
    
    return 0
}

# Function to resolve package alternatives
resolve_alternatives() {
    local category="$1"
    local preferred="${2:-}"
    local alternatives="${PACKAGE_ALTERNATIVES[$category]:-}"
    
    if [[ -n "$preferred" ]] && [[ "$alternatives" =~ $preferred ]]; then
        echo "$preferred"
        return 0
    fi
    
    # Return first available alternative
    for alt in $alternatives; do
        if xbps-query "$alt" &>/dev/null; then
            echo "$alt"
            return 0
        fi
    done
    
    # Return first alternative if none are installed
    echo "$alternatives" | awk '{print $1}'
}

# Function to generate package list with versions
generate_package_list() {
    local package_file="$1"
    local output_file="$2"
    
    log "Generating package list with version constraints..."
    
    > "$output_file"
    
    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "$package" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$package" ]] && continue
        
        local version_constraint="${PACKAGE_VERSIONS[$package]:-}"
        
        if [[ -n "$version_constraint" ]]; then
            echo "${package}${version_constraint}" >> "$output_file"
        else
            echo "$package" >> "$output_file"
        fi
    done < "$package_file"
    
    success "Package list with versions generated: $output_file"
}

# Function to validate package manifest
validate_package_manifest() {
    local package_file="$1"
    local errors=0
    local warnings=0
    
    log "Validating package manifest..."
    
    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "$package" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$package" ]] && continue
        
        # Extract package name (remove version constraints)
        local package_name="${package%%[<>=!]*}"
        
        # Check if package exists in repository
        if ! xbps-query -R "$VOIDANCE_REPO_CONF" "$package_name" &>/dev/null; then
            error "Package not found in repository: $package_name"
            ((errors++))
            continue
        fi
        
        # Check version constraints
        if ! validate_package_version "$package_name"; then
            warning "Version constraint not satisfied: $package"
            ((warnings++))
        fi
        
        # Check dependencies
        if ! check_package_deps "$package_name"; then
            warning "Missing dependencies for: $package_name"
            ((warnings++))
        fi
        
        # Check conflicts
        if ! check_package_conflicts "$package_name"; then
            error "Package conflicts detected: $package_name"
            ((errors++))
        fi
        
    done < "$package_file"
    
    log "Validation completed: $errors errors, $warnings warnings"
    
    if [[ $errors -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# Function to install package groups
install_package_groups() {
    local groups="$@"
    
    for group in "$groups"; do
        local packages="${PACKAGE_GROUPS[$group]:-}"
        
        if [[ -z "$packages" ]]; then
            warning "Unknown package group: $group"
            continue
        fi
        
        log "Installing package group: $group"
        log "Packages: $packages"
        
        if xbps-install -Sy $packages; then
            success "Package group $group installed successfully"
        else
            error "Failed to install package group: $group"
        fi
    done
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-validate}" in
        "validate")
            if [[ -n "${2:-}" ]]; then
                validate_package_manifest "$2"
            else
                error "Package file required for validation"
            fi
            ;;
        "generate")
            if [[ -n "${2:-}" ]] && [[ -n "${3:-}" ]]; then
                generate_package_list "$2" "$3"
            else
                error "Input and output files required for generation"
            fi
            ;;
        "install-groups")
            shift
            install_package_groups "$@"
            ;;
        "check-deps")
            if [[ -n "${2:-}" ]]; then
                check_package_deps "$2"
            else
                error "Package name required for dependency check"
            fi
            ;;
        "resolve")
            if [[ -n "${2:-}" ]]; then
                resolve_alternatives "$2" "${3:-}"
            else
                error "Category required for alternative resolution"
            fi
            ;;
        *)
            echo "Usage: $0 {validate|generate|install-groups|check-deps|resolve} [args...]"
            exit 1
            ;;
    esac
fi