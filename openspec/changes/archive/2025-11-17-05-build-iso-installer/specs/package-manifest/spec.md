# Package Manifest

## Overview
Defines the complete package list for Voidance Linux ISO, ensuring all necessary components are included for a functional "Feels Smooth" desktop experience while maintaining the minimalist philosophy of the distribution.

## ADDED Requirements

### Requirement: Bootable System Packages
The system SHALL include all packages needed for bootable system.

#### Scenario: The ISO contains base-system, linux6.6 kernel, dracut, filesystem tools, and bootloader packages to create a bootable system

### Requirement: Complete Wayland Desktop Environment
The system SHALL provide complete Wayland desktop environment.

#### Scenario: The package list includes Niri compositor, Waybar, wofi, mako, and all required Wayland support libraries for a functional desktop

### Requirement: Essential System Utilities
The system SHALL include essential system utilities and tools.

#### Scenario: The system includes basic utilities like htop, neofetch, vim, git, curl, and development tools for user productivity

### Requirement: Hardware Detection and Driver Support
The system SHALL support hardware detection and driver loading.

#### Scenario: Linux firmware packages and hardware support libraries are included to detect and configure common hardware components

### Requirement: Network Connectivity and Management
The system SHALL enable network connectivity and management.

#### Scenario: NetworkManager, wpa_supplicant, and related packages provide both wired and wireless network management capabilities

### Requirement: Multimedia and Graphics Support
The system SHALL provide multimedia and graphics support.

#### Scenario: PipeWire audio system, graphics libraries, and multimedia applications like mpv and imv are included for media consumption

### Requirement: Minimal ISO Size
The system SHALL maintain minimal ISO size while ensuring functionality.

#### Scenario: The package selection balances functionality with ISO size, avoiding unnecessary packages while ensuring complete desktop experience

### Requirement: Package Compatibility
The system SHALL ensure package compatibility and dependency resolution.

#### Scenario: All packages in the manifest are compatible with each other and their dependencies are properly resolved during installation

### Requirement: Void Linux Package Conventions
The system SHALL follow Void Linux package management conventions.

#### Scenario: Packages use standard Void Linux naming conventions and are installed using xbps-install with proper repository configuration

### Requirement: Multi-Architecture Support
The system SHALL support both x86_64 and potential ARM architectures.

#### Scenario: The package manifest is structured to support multiple architectures with architecture-specific package variants where needed

### Requirement: Easy Customization
The system SHALL enable easy customization and package selection.

#### Scenario: The manifest is organized by functional categories, making it easy to add/remove packages for different ISO variants
- Include all packages needed for bootable system
  #### Scenario: The ISO contains base-system, linux6.6 kernel, dracut, filesystem tools, and bootloader packages to create a bootable system
- Provide complete Wayland desktop environment
  #### Scenario: The package list includes Niri compositor, Waybar, wofi, mako, and all required Wayland support libraries for a functional desktop
- Include essential system utilities and tools
  #### Scenario: The system includes basic utilities like htop, neofetch, vim, git, curl, and development tools for user productivity
- Support hardware detection and driver loading
  #### Scenario: Linux firmware packages and hardware support libraries are included to detect and configure common hardware components
- Enable network connectivity and management
  #### Scenario: NetworkManager, wpa_supplicant, and related packages provide both wired and wireless network management capabilities
- Provide multimedia and graphics support
  #### Scenario: PipeWire audio system, graphics libraries, and multimedia applications like mpv and imv are included for media consumption

### ADDED Non-Functional Requirements
- Maintain minimal ISO size while ensuring functionality
  #### Scenario: The package selection balances functionality with ISO size, avoiding unnecessary packages while ensuring complete desktop experience
- Ensure package compatibility and dependency resolution
  #### Scenario: All packages in the manifest are compatible with each other and their dependencies are properly resolved during installation
- Follow Void Linux package management conventions
  #### Scenario: Packages use standard Void Linux naming conventions and are installed using xbps-install with proper repository configuration
- Support both x86_64 and potential ARM architectures
  #### Scenario: The package manifest is structured to support multiple architectures with architecture-specific package variants where needed
- Enable easy customization and package selection
  #### Scenario: The manifest is organized by functional categories, making it easy to add/remove packages for different ISO variants

## Design

### Package Categories

#### Base System Packages
```bash
# Core system
base-system
void-repo-nonfree
linux6.6
linux6.6-headers
dracut
e2fsprogs
dosfstools
exfatprogs
ntfs-3g
xfsprogs
btrfs-progs
```

#### Boot and Firmware
```bash
# Bootloaders
grub-i386-efi
grub-x86_64-efi
efibootmgr

# Firmware
linux-firmware
intel-ucode
amd-ucode
```

#### System Services
```bash
# Service management
runit
elogind

# Display management
sddm
seatd

# Network management
NetworkManager
nm-tray
wpa_supplicant
iptables-nft
firewalld

# Audio/PipeWire
pipewire
pipewire-pulse
wireplumber
pipewire-alsa
libpulseaudio

# Hardware support
upower
udisks2
polkit
```

#### Desktop Environment
```bash
# Wayland compositor
niri
niri-session

# Status bar and launcher
waybar
wofi

# Notification system
mako
libnotify

# Desktop integration
xdg-desktop-portal
xdg-desktop-portal-wlr
xdg-user-dirs
xdg-utils

# GTK/Qt integration
gtk3
gtk4
qt6-base
qt6-wayland
adwaita-icon-theme
gnome-themes-extra
```

#### Applications
```bash
# Terminal
wezterm

# File manager
thunar
thunar-volman
thunar-archive-plugin

# Archive tools
unar
p7zip
zip
unzip

# Text editor
mousepad
nano

# Web browser
firefox

# Screenshot tool
grim
slurp

# Clipboard manager
wl-clipboard
cliphist

# Background management
swaybg

# Image viewer
imv

# PDF viewer
evince

# Media player
mpv
```

#### Fonts
```bash
# Core fonts
fontconfig
freetype
harfbuzz

# System fonts
dejavu-fonts-ttf
liberation-fonts-ttf
noto-fonts-ttf
noto-fonts-cjk
noto-fonts-emoji

# Programming fonts
jetbrains-mono
fira-code
```

#### Development Tools
```bash
# Build tools
base-devel
git
curl
wget
vim
```

#### System Utilities
```bash
# System monitoring
htop
btop
neofetch

# Disk utilities
gparted
baobab

# Network tools
nmap
ping
traceroute

# Process management
psmisc
procps-ng
```

## Implementation

### Package Manifest File
```bash
# manifests/voidance-packages.sh

#!/bin/bash

# Voidance Linux Package Manifest
# Complete package list for ISO building

# Base system packages
BASE_PACKAGES=(
    "base-system"
    "void-repo-nonfree"
    "linux6.6"
    "linux6.6-headers"
    "dracut"
    "e2fsprogs"
    "dosfstools"
    "exfatprogs"
    "ntfs-3g"
    "xfsprogs"
    "btrfs-progs"
)

# Boot and firmware
BOOT_PACKAGES=(
    "grub-i386-efi"
    "grub-x86_64-efi"
    "efibootmgr"
    "linux-firmware"
    "intel-ucode"
    "amd-ucode"
)

# System services
SERVICE_PACKAGES=(
    "runit"
    "elogind"
    "sddm"
    "seatd"
    "NetworkManager"
    "nm-tray"
    "wpa_supplicant"
    "iptables-nft"
    "firewalld"
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "pipewire-alsa"
    "libpulseaudio"
    "upower"
    "udisks2"
    "polkit"
)

# Desktop environment
DESKTOP_PACKAGES=(
    "niri"
    "niri-session"
    "waybar"
    "wofi"
    "mako"
    "libnotify"
    "xdg-desktop-portal"
    "xdg-desktop-portal-wlr"
    "xdg-user-dirs"
    "xdg-utils"
    "gtk3"
    "gtk4"
    "qt6-base"
    "qt6-wayland"
    "adwaita-icon-theme"
    "gnome-themes-extra"
)

# Applications
APPLICATION_PACKAGES=(
    "wezterm"
    "thunar"
    "thunar-volman"
    "thunar-archive-plugin"
    "unar"
    "p7zip"
    "zip"
    "unzip"
    "mousepad"
    "nano"
    "firefox"
    "grim"
    "slurp"
    "wl-clipboard"
    "cliphist"
    "swaybg"
    "imv"
    "evince"
    "mpv"
)

# Fonts
FONT_PACKAGES=(
    "fontconfig"
    "freetype"
    "harfbuzz"
    "dejavu-fonts-ttf"
    "liberation-fonts-ttf"
    "noto-fonts-ttf"
    "noto-fonts-cjk"
    "noto-fonts-emoji"
    "jetbrains-mono"
    "fira-code"
)

# Development tools
DEVELOPMENT_PACKAGES=(
    "base-devel"
    "git"
    "curl"
    "wget"
    "vim"
)

# System utilities
UTILITY_PACKAGES=(
    "htop"
    "btop"
    "neofetch"
    "gparted"
    "baobab"
    "nmap"
    "ping"
    "traceroute"
    "psmisc"
    "procps-ng"
)

# All packages combined
ALL_PACKAGES=(
    "${BASE_PACKAGES[@]}"
    "${BOOT_PACKAGES[@]}"
    "${SERVICE_PACKAGES[@]}"
    "${DESKTOP_PACKAGES[@]}"
    "${APPLICATION_PACKAGES[@]}"
    "${FONT_PACKAGES[@]}"
    "${DEVELOPMENT_PACKAGES[@]}"
    "${UTILITY_PACKAGES[@]}"
)

# Package installation function
install_packages() {
    local category="$1"
    shift
    local packages=("$@")
    
    echo "Installing $category packages..."
    xbps-install -Sy "${packages[@]}"
    
    if [ $? -eq 0 ]; then
        echo "Successfully installed $category packages"
    else
        echo "Failed to install $category packages"
        return 1
    fi
}

# Install all packages
install_all_packages() {
    echo "Installing all Voidance packages..."
    
    install_packages "Base System" "${BASE_PACKAGES[@]}"
    install_packages "Boot and Firmware" "${BOOT_PACKAGES[@]}"
    install_packages "System Services" "${SERVICE_PACKAGES[@]}"
    install_packages "Desktop Environment" "${DESKTOP_PACKAGES[@]}"
    install_packages "Applications" "${APPLICATION_PACKAGES[@]}"
    install_packages "Fonts" "${FONT_PACKAGES[@]}"
    install_packages "Development Tools" "${DEVELOPMENT_PACKAGES[@]}"
    install_packages "System Utilities" "${UTILITY_PACKAGES[@]}"
    
    echo "All packages installed successfully"
}

# Package verification
verify_packages() {
    echo "Verifying package installation..."
    
    for package in "${ALL_PACKAGES[@]}"; do
        if xbps-query -r "$ROOTFS" "$package" >/dev/null 2>&1; then
            echo "✓ $package"
        else
            echo "✗ $package (missing)"
        fi
    done
}

# Main execution
case "${1:-install}" in
    "install")
        install_all_packages
        ;;
    "verify")
        verify_packages
        ;;
    "list")
        printf '%s\n' "${ALL_PACKAGES[@]}"
        ;;
    *)
        echo "Usage: $0 {install|verify|list}"
        exit 1
        ;;
esac
```

### Package Configuration Scripts
```bash
# scripts/configure-packages.sh

#!/bin/bash

set -euo pipefail

configure_services() {
    echo "Configuring system services..."
    
    # Enable essential services
    ln -sf /etc/sv/elogind /var/service/
    ln -sf /etc/sv/NetworkManager /var/service/
    ln -sf /etc/sv/udisks2 /var/service/
    ln -sf /etc/sv/polkit /var/service/
    
    # Enable SDDM
    ln -sf /etc/sv/sddm /var/service/
    
    echo "Services configured"
}

configure_desktop() {
    echo "Configuring desktop environment..."
    
    # Set up XDG directories
    xdg-user-dirs-update
    
    # Configure PipeWire as default
    systemctl --user enable pipewire pipewire-pulse wireplumber 2>/dev/null || true
    
    echo "Desktop environment configured"
}

configure_network() {
    echo "Configuring network management..."
    
    # Enable NetworkManager
    systemctl enable NetworkManager 2>/dev/null || true
    
    # Configure firewall
    systemctl enable firewalld 2>/dev/null || true
    
    echo "Network configured"
}

main() {
    configure_services
    configure_desktop
    configure_network
    
    echo "Package configuration completed"
}

main "$@"
```

## Integration

### ISO Build Integration
- Integrated with void-mklive package installation phase
- Works with automated package installation scripts
- Supports custom package selection for different ISO variants

### System Integration
- Ensures proper service enablement
- Configures package interactions and dependencies
- Maintains system consistency and stability

### Desktop Integration
- Provides complete desktop environment
- Ensures proper Wayland support
- Configures application integration

## Testing

### Package Installation Tests
- Verify all packages install correctly
- Check dependency resolution
- Test package removal and reinstallation

### System Integration Tests
- Verify system boots with all packages
- Test service enablement and startup
- Check desktop environment functionality

### Application Tests
- Test application launch and functionality
- Verify Wayland compatibility
- Check integration with system services

## Performance Considerations

### ISO Size Optimization
- Select essential packages only
- Avoid package duplication
- Optimize package selection for size

### Installation Speed
- Parallel package installation
- Efficient dependency resolution
- Minimal post-installation configuration

### Runtime Performance
- Lightweight application selection
- Minimal background services
- Efficient resource usage

## Security Considerations

### Package Security
- Use official Void Linux repositories
- Verify package signatures
- Regular security updates

### System Security
- Minimal attack surface
- Secure default configurations
- Proper permission settings

### Network Security
- Secure network management
- Firewall configuration
- Secure service enablement

## Monitoring and Maintenance

### Package Updates
- Regular package updates
- Security patch management
- Dependency tracking

### System Health
- Monitor package conflicts
- Track system stability
- Performance optimization

## Future Enhancements

### Package Variants
- Minimal ISO variant
- Development ISO variant
- Server ISO variant

### Customization Options
- User-selectable packages
- Theme and appearance packages
- Specialized application bundles

### Architecture Support
- ARM64 package selection
- Multi-architecture ISO support
- Cross-platform compatibility