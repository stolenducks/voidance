# Desktop Environment Package Configuration for Voidance Linux
# Defines packages for Niri, Waybar, wofi and supporting components

# Core desktop environment packages
DESKTOP_PACKAGES=(
    # Window Manager
    "niri"                    # Scrollable tiling Wayland compositor
    
    # Status Bar
    "waybar"                  # Highly configurable Wayland status bar
    
    # Application Launcher
    "wofi"                    # Wayland-native application launcher
    
    # Essential Wayland utilities
    "wl-clipboard"            # Clipboard management for Wayland
    "wtype"                   # Virtual keyboard input for Wayland
    "wf-recorder"             # Screen recording for Wayland
    "slurp"                   # Screen region selection for Wayland
    "grim"                    # Screenshot utility for Wayland
    
    # Font support
    "font-firacode-nerd-font" # Programming font with Nerd Font icons
    "font-dejavu"             # Standard fonts
    "font-liberation"         # Liberation fonts
    
    # Theme and appearance
    "breeze"                  # KDE Breeze theme for Qt/GTK consistency
    "breeze-icons"            # Breeze icon theme
    "adwaita-icon-theme"      # GNOME Adwaita icon theme
    
    # Terminal and tools
    "ghostty"                 # Fast, GPU-accelerated terminal emulator
    "xdg-utils"               # XDG utilities for desktop integration
    "xdg-desktop-portal"      # XDG desktop portal for sandboxing
    "xdg-desktop-portal-wlr"  # Wayland-specific portal implementation
)

# Development and debugging packages (optional)
DESKTOP_DEV_PACKAGES=(
    "niri-debug"              # Debug symbols for niri (if available)
    "waybar-debug"            # Debug symbols for waybar (if available)
)

# Package version constraints (if needed)
PACKAGE_VERSIONS=(
    "niri>=0.1.0"             # Minimum niri version for Wayland support
    "waybar>=0.9.0"           # Minimum waybar version
    "wofi>=1.3.0"             # Minimum wofi version
)

# Function to check package availability
check_package_availability() {
    local pkg="$1"
    if xbps-query -R "$pkg" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to install desktop packages
install_desktop_packages() {
    echo "Installing desktop environment packages..."
    
    local failed_packages=()
    
    for pkg in "${DESKTOP_PACKAGES[@]}"; do
        if check_package_availability "$pkg"; then
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

# Function to verify desktop package installation
verify_desktop_packages() {
    echo "Verifying desktop environment packages..."
    
    local missing_packages=()
    
    for pkg in "${DESKTOP_PACKAGES[@]}"; do
        if xbps-query - "$pkg" >/dev/null 2>&1; then
            echo "✓ $pkg is installed"
        else
            echo "✗ $pkg is missing"
            missing_packages+=("$pkg")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        echo "✓ All desktop environment packages are installed"
        return 0
    else
        echo "✗ Missing packages: ${missing_packages[*]}"
        return 1
    fi
}

# Function to create desktop environment user directories
create_desktop_directories() {
    local username="${1:-$USER}"
    local user_home="/home/$username"
    
    echo "Creating desktop environment directories for user: $username"
    
    # Create standard XDG user directories
    local directories=(
        ".config/niri"
        ".config/waybar"
        ".config/wofi"
        ".local/share/applications"
        ".local/bin"
        "Desktop"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
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
export -f check_package_availability
export -f install_desktop_packages
export -f verify_desktop_packages
export -f create_desktop_directories