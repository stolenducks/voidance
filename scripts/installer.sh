#!/bin/bash
# Voidance Post-Install Script
# Runs after base system install to set up Hyprland, themes, and user configs

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
ask() { echo -e "${BLUE}[?]${NC} $1"; }

info "Welcome to Voidance post-install setup!"
info "This will configure Hyprland, themes, and applications."
echo ""

# Detect current user
if [[ $EUID -eq 0 ]]; then
    ask "Enter your username (not root):"
    read -r USERNAME
else
    USERNAME="$USER"
fi

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    error "User $USERNAME does not exist"
    exit 1
fi

USER_HOME=$(eval echo ~"$USERNAME")
info "Installing for user: $USERNAME"
info "Home directory: $USER_HOME"
echo ""

# Create config directories
info "Creating config directories..."
mkdir -p "${USER_HOME}/.config/{hypr,waybar,mako,walker,alacritty}"
mkdir -p "${USER_HOME}/.local/share/applications"
mkdir -p "${USER_HOME}/Pictures/Wallpapers"

# Copy configs from repo (assumes we're in voidance repo)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -d "${PROJECT_ROOT}/config" ]]; then
    info "Copying Hyprland configs..."
    cp -r "${PROJECT_ROOT}/config/hypr/"* "${USER_HOME}/.config/hypr/"
    
    info "Copying Waybar configs..."
    cp -r "${PROJECT_ROOT}/config/waybar/"* "${USER_HOME}/.config/waybar/"
    
    info "Copying Mako configs..."
    cp -r "${PROJECT_ROOT}/config/mako/"* "${USER_HOME}/.config/mako/"
    
    info "Copying Walker configs..."
    cp -r "${PROJECT_ROOT}/config/walker/"* "${USER_HOME}/.config/walker/"
else
    warn "Config directory not found, skipping..."
fi

# Copy wallpapers
if [[ -d "${PROJECT_ROOT}/themes/wallpapers" ]]; then
    info "Copying wallpapers..."
    cp -r "${PROJECT_ROOT}/themes/wallpapers/"* "${USER_HOME}/Pictures/Wallpapers/" 2>/dev/null || true
fi

# Set proper ownership
info "Setting file permissions..."
chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.config"
chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.local"
chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/Pictures"

# Enable services
info "Enabling system services..."
ln -sf /etc/sv/dbus /var/service/ 2>/dev/null || true
ln -sf /etc/sv/NetworkManager /var/service/ 2>/dev/null || true
ln -sf /etc/sv/bluetoothd /var/service/ 2>/dev/null || true

info "✓ Voidance setup complete!"
echo ""
info "Next steps:"
echo "  1. Log out and log back in"
echo "  2. Hyprland should start automatically"
echo "  3. Press Super+Return for terminal"
echo "  4. Press Alt+D for app launcher"
echo ""
info "Enjoy Voidance! 🚀"

