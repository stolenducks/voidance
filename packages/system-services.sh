#!/bin/bash

# Voidance Linux System Services Package Manifest
# Essential packages for system services foundation

set -euo pipefail

# Session Management Packages
SESSION_PACKAGES=(
    "elogind"
    "dbus"
    "pam"
)

# Display Manager Packages
DISPLAY_PACKAGES=(
    "sddm"
    "sddm-theme-breeze"
    "sddm-theme-maldives"
)

# Network Management Packages
NETWORK_PACKAGES=(
    "NetworkManager"
    "network-manager-applet"
    "wpa_supplicant"
    "dhcpcd"
    "iptables-nft"
)

# Audio Services Packages
AUDIO_PACKAGES=(
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "rtkit"
    "libpulseaudio"
)

# Idle and Lock Services
IDLE_PACKAGES=(
    "swayidle"
    "swaylock"
)

# Additional Dependencies
DEPS_PACKAGES=(
    "polkit"
    "upower"
    "udisks2"
)

# All packages combined
ALL_PACKAGES=(
    "${SESSION_PACKAGES[@]}"
    "${DISPLAY_PACKAGES[@]}"
    "${NETWORK_PACKAGES[@]}"
    "${AUDIO_PACKAGES[@]}"
    "${IDLE_PACKAGES[@]}"
    "${DEPS_PACKAGES[@]}"
)

# Package installation function
install_packages() {
    local category="$1"
    shift
    local packages=("$@")
    
    echo "Installing $category packages..."
    if command -v xbps-install >/dev/null 2>&1; then
        xbps-install -Sy "${packages[@]}"
    else
        echo "Warning: xbps-install not found, simulating package installation"
        echo "Would install: ${packages[*]}"
    fi
    
    if [ $? -eq 0 ]; then
        echo "Successfully installed $category packages"
    else
        echo "Failed to install $category packages"
        return 1
    fi
}

# Install all packages
install_all_packages() {
    echo "Installing all Voidance system service packages..."
    
    install_packages "Session Management" "${SESSION_PACKAGES[@]}"
    install_packages "Display Manager" "${DISPLAY_PACKAGES[@]}"
    install_packages "Network Management" "${NETWORK_PACKAGES[@]}"
    install_packages "Audio Services" "${AUDIO_PACKAGES[@]}"
    install_packages "Idle and Lock" "${IDLE_PACKAGES[@]}"
    install_packages "Dependencies" "${DEPS_PACKAGES[@]}"
    
    echo "All system service packages installed successfully"
}

# Package verification
verify_packages() {
    echo "Verifying package installation..."
    
    for package in "${ALL_PACKAGES[@]}"; do
        if command -v xbps-query >/dev/null 2>&1; then
            if xbps-query "$package" >/dev/null 2>&1; then
                echo "✓ $package"
            else
                echo "✗ $package (missing)"
            fi
        else
            echo "? $package (verification skipped - no xbps-query)"
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