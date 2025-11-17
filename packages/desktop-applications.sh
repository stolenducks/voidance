#!/bin/bash
# Desktop Applications Package Configuration
# Defines all packages needed for desktop applications

set -euo pipefail

# Main package groups
declare -A PACKAGE_GROUPS=(
    ["terminal"]="ghostty"
    ["file_manager"]="thunar thunar-archive-plugin thunar-volman"
    ["notifications"]="mako"
    ["fonts"]="ttf-montserrat ttf-inconsolata"
    ["terminal_deps"]="glu mesa libglvnd"
    ["file_manager_deps"]="gvfs gvfs-mtp gvfs-gphoto2 ffmpegthumbnailer"
    ["notification_deps"]="libnotify"
)

# Function to get packages by group
get_packages() {
    local group="$1"
    if [[ -n "${PACKAGE_GROUPS[$group]:-}" ]]; then
        echo "${PACKAGE_GROUPS[$group]}"
    else
        echo "Unknown package group: $group" >&2
        return 1
    fi
}

# Function to get all packages
get_all_packages() {
    local all_packages=""
    for group in "${!PACKAGE_GROUPS[@]}"; do
        all_packages="$all_packages ${PACKAGE_GROUPS[$group]}"
    done
    echo "$all_packages" | xargs -n1 | sort -u | xargs
}

# Function to check if packages are installed
check_packages() {
    local group="$1"
    local packages
    packages=$(get_packages "$group")
    
    echo "Checking packages for group: $group"
    for package in $packages; do
        if pacman -Qi "$package" >/dev/null 2>&1; then
            echo "  ✓ $package"
        else
            echo "  ✗ $package (missing)"
        fi
    done
}

# Function to install packages for a group
install_packages() {
    local group="$1"
    local packages
    packages=$(get_packages "$group")
    
    echo "Installing packages for group: $group"
    if sudo pacman -S --needed $packages; then
        echo "  ✓ Successfully installed $group packages"
    else
        echo "  ✗ Failed to install $group packages"
        return 1
    fi
}

# Main execution
case "${1:-}" in
    "get")
        get_packages "${2:-all}"
        ;;
    "all")
        get_all_packages
        ;;
    "check")
        check_packages "${2:-all}"
        ;;
    "install")
        install_packages "${2:-all}"
        ;;
    "list-groups")
        for group in "${!PACKAGE_GROUPS[@]}"; do
            echo "$group: ${PACKAGE_GROUPS[$group]}"
        done
        ;;
    *)
        echo "Usage: $0 {get|all|check|install|list-groups} [group]"
        echo "Available groups: terminal, file_manager, notifications, fonts"
        exit 1
        ;;
esac