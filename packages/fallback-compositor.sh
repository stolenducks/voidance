# Fallback Compositor Package Configuration for Voidance Linux
# Defines packages for Sway fallback compositor and supporting components

# Fallback compositor packages
FALLBACK_COMPOSITOR_PACKAGES=(
    # Fallback Window Manager
    "sway"                    # i3-compatible Wayland compositor
    "swaybg"                  # Wallpaper tool for Sway
    "swayidle"                # Idle management for Sway
    "swaylock"                # Screen locking for Sway
    
    # Sway utilities and tools
    "i3status"                # Status bar generator (compatible with Sway)
    "i3blocks"                # Status bar with customizable blocks
    "dmenu"                   # Application menu (fallback for wofi)
    "rofi"                    # Alternative application launcher
    
    # Additional Wayland utilities for Sway
    "foot"                    # Fast terminal emulator (fallback for Ghostty)
    "mako"                    # Notification daemon (already installed but listed for completeness)
    
    # Compatibility and integration
    "xwayland"                # X11 compatibility layer for Wayland
    "qt5-wayland"             # Qt5 Wayland integration
    "gtk+3-wayland"           # GTK3 Wayland integration
    "xdg-desktop-portal-wlr"  # Wayland-specific portal implementation
    
    # Input and display tools
    "libinput"                # Input device handling
    "seatd"                   # Seat management for Wayland
)

# Development and debugging packages (optional)
FALLBACK_COMPOSITOR_DEV_PACKAGES=(
    "sway-debug"              # Debug symbols for sway (if available)
)

# Package version constraints (if needed)
FALLBACK_PACKAGE_VERSIONS=(
    "sway>=1.8.0"             # Minimum sway version for stability
    "swaybg>=1.0.0"           # Minimum swaybg version
    "swayidle>=1.7.0"         # Minimum swayidle version
    "swaylock>=1.7.0"         # Minimum swaylock version
)

# Function to check fallback compositor package availability
check_fallback_package_availability() {
    local pkg="$1"
    if xbps-query -R "$pkg" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to install fallback compositor packages
install_fallback_compositor_packages() {
    echo "Installing fallback compositor packages..."
    
    local failed_packages=()
    
    for pkg in "${FALLBACK_COMPOSITOR_PACKAGES[@]}"; do
        if check_fallback_package_availability "$pkg"; then
            echo "Installing $pkg..."
            if xbps-install -Sy "$pkg"; then
                echo "✓ Installed $pkg"
            else
                echo "✗ Failed to install $pkg"
                failed_packages+=("$pkg")
            fi
        else
            echo "⚠ Package $pkg not found in repositories"
            failed_packages+=("$pkg")
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        echo ""
        echo "Warning: The following packages failed to install:"
        printf '  %s\n' "${failed_packages[@]}"
        echo ""
        echo "These may need to be installed manually or from source"
    fi
}

# Function to verify fallback compositor package installation
verify_fallback_compositor_packages() {
    echo "Verifying fallback compositor packages..."
    
    local missing_packages=()
    
    for pkg in "${FALLBACK_COMPOSITOR_PACKAGES[@]}"; do
        if xbps-query - "$pkg" >/dev/null 2>&1; then
            echo "✓ $pkg is installed"
        else
            echo "✗ $pkg is missing"
            missing_packages+=("$pkg")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        echo "✓ All fallback compositor packages are installed"
        return 0
    else
        echo "✗ Missing packages: ${missing_packages[*]}"
        return 1
    fi
}

# Function to create fallback compositor user directories
create_fallback_compositor_directories() {
    local username="${1:-$USER}"
    local user_home="/home/$username"
    
    echo "Creating fallback compositor directories for user: $username"
    
    # Create Sway-specific directories
    local directories=(
        ".config/sway"
        ".config/sway/config.d"
        ".config/i3status"
        ".config/i3status"
        ".config/rofi"
        ".config/foot"
        ".local/share/backgrounds"
    )
    
    for dir in "${directories[@]}"; do
        local full_path="$user_home/$dir"
        if [ ! -d "$full_path" ]; then
            mkdir -p "$full_path"
            chown "$username:$username" "$full_path"
            echo "✓ Created $full_path"
        else
            echo "✓ Directory $full_path already exists"
        fi
    done
}

# Export functions for use in other scripts
export -f check_fallback_package_availability
export -f install_fallback_compositor_packages
export -f verify_fallback_compositor_packages
export -f create_fallback_compositor_directories