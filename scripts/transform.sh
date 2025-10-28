#!/bin/bash

# Voidance Transformation Script
# Transforms a base Void Linux installation into Voidance
# Similar to Omarchy's boot.sh

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ASCII Art
VOIDANCE_ART='
██╗   ██╗ ██████╗ ██╗██████╗  █████╗ ███╗   ██╗ ██████╗███████╗
██║   ██║██╔═══██╗██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝
██║   ██║██║   ██║██║██║  ██║███████║██╔██╗ ██║██║     █████╗  
╚██╗ ██╔╝██║   ██║██║██║  ██║██╔══██║██║╚██╗██║██║     ██╔══╝  
 ╚████╔╝ ╚██████╔╝██║██████╔╝██║  ██║██║ ╚████║╚██████╗███████╗
  ╚═══╝   ╚═════╝ ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
                                                                 
  A Void Linux remix inspired by Omarchy
'

# Configuration
VOIDANCE_DIR="$HOME/.local/share/voidance"
VOIDANCE_REPO="${VOIDANCE_REPO:-dolandstutts/voidance}"
VOIDANCE_BRANCH="${VOIDANCE_BRANCH:-main}"
HEADLESS_MODE=false
LOG_FILE="/tmp/voidance-install.log"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --headless)
            HEADLESS_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Functions
print_header() {
    clear
    echo -e "${BLUE}${VOIDANCE_ART}${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_void_linux() {
    if [ ! -f /etc/os-release ]; then
        print_error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi
    
    if ! grep -q "ID=void" /etc/os-release; then
        print_error "This script only works on Void Linux!"
        print_info "Detected OS: $(grep '^PRETTY_NAME' /etc/os-release | cut -d'"' -f2)"
        exit 1
    fi
    
    print_success "Void Linux detected!"
}

check_requirements() {
    print_info "Checking requirements..."
    
    # Check if running as regular user
    if [ "$EUID" -eq 0 ]; then
        print_error "Please run this script as a regular user (not root)."
        print_info "The script will ask for sudo when needed."
        exit 1
    fi
    
    # Check for sudo access
    if ! sudo -v; then
        print_error "This script requires sudo access."
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        print_warning "No internet connection detected."
        print_info "Please connect to the internet and try again."
        exit 1
    fi
    
    print_success "All requirements met!"
}

update_system() {
    print_info "Updating system packages..."
    sudo xbps-install -Suy
    print_success "System updated!"
}

install_base_tools() {
    print_info "Installing base tools..."
    sudo xbps-install -Sy \
        git \
        curl \
        wget \
        base-devel \
        || print_error "Failed to install base tools"
    print_success "Base tools installed!"
}

clone_voidance() {
    print_info "Cloning Voidance repository..."
    
    # Remove old installation
    if [ -d "$VOIDANCE_DIR" ]; then
        print_warning "Existing Voidance installation found. Backing up..."
        mv "$VOIDANCE_DIR" "${VOIDANCE_DIR}.backup.$(date +%s)"
    fi
    
    # Clone repository
    git clone "https://github.com/${VOIDANCE_REPO}.git" "$VOIDANCE_DIR" &> /dev/null
    
    # Checkout specific branch if specified
    if [ "$VOIDANCE_BRANCH" != "main" ]; then
        print_info "Switching to branch: $VOIDANCE_BRANCH"
        cd "$VOIDANCE_DIR"
        git checkout "$VOIDANCE_BRANCH"
        cd - > /dev/null
    fi
    
    # Save version
    cd "$VOIDANCE_DIR"
    git describe --tags --always > "$VOIDANCE_DIR/version"
    cd - > /dev/null
    
    print_success "Voidance cloned to $VOIDANCE_DIR"
}

install_packages() {
    print_info "Installing Voidance packages..."
    print_warning "This may take 10-20 minutes depending on your internet speed."
    
    # Read package lists
    PACKAGE_FILE="$VOIDANCE_DIR/packages/packages.txt"
    
    if [ ! -f "$PACKAGE_FILE" ]; then
        print_error "Package list not found: $PACKAGE_FILE"
        exit 1
    fi
    
    # Create array of packages
    mapfile -t PACKAGES < <(grep -v '^#' "$PACKAGE_FILE" | grep -v '^$')
    
    print_info "Found ${#PACKAGES[@]} packages to install"
    
    # Try batch install first (much faster)
    print_info "Attempting batch installation..."
    if sudo xbps-install -y "${PACKAGES[@]}" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "All packages installed successfully!"
    else
        print_warning "Batch install failed, trying individual packages..."
        # Install individually if batch fails
        for package in "${PACKAGES[@]}"; do
            print_info "Installing: $package"
            if ! sudo xbps-install -y "$package" 2>&1 | tee -a "$LOG_FILE"; then
                print_warning "Failed to install: $package (continuing...)"
                echo "$package" >> "$HOME/.voidance-failed-packages"
            fi
        done
    fi
    
    print_success "Package installation complete!"
    if [ -f "$HOME/.voidance-failed-packages" ]; then
        print_warning "Some packages failed to install. See: $HOME/.voidance-failed-packages"
    fi
}

configure_services() {
    print_info "Configuring runit services..."
    
    # Enable essential services
    SERVICES=(
        "dbus"
        "elogind"
        "NetworkManager"
        "bluetoothd"
    )
    
    for service in "${SERVICES[@]}"; do
        if [ -d "/etc/sv/$service" ]; then
            print_info "Enabling service: $service"
            sudo ln -sf "/etc/sv/$service" /var/service/ || true
        fi
    done
    
    print_success "Services configured!"
}

install_configs() {
    print_info "Installing configuration files..."
    
    # Backup existing configs
    BACKUP_DIR="$HOME/.config.backup.$(date +%s)"
    if [ -d "$HOME/.config" ]; then
        print_info "Backing up existing configs to $BACKUP_DIR"
        cp -r "$HOME/.config" "$BACKUP_DIR"
    fi
    
    # Copy configs
    mkdir -p "$HOME/.config"
    cp -r "$VOIDANCE_DIR/config/"* "$HOME/.config/"
    
    # Copy themes
    mkdir -p "$HOME/.local/share/themes"
    if [ -d "$VOIDANCE_DIR/themes" ]; then
        cp -r "$VOIDANCE_DIR/themes/"* "$HOME/.local/share/themes/"
    fi
    
    # Copy scripts to user bin
    mkdir -p "$HOME/.local/bin"
    if [ -d "$VOIDANCE_DIR/scripts" ]; then
        cp "$VOIDANCE_DIR/scripts/"*.sh "$HOME/.local/bin/" || true
        chmod +x "$HOME/.local/bin/"*.sh || true
    fi
    
    print_success "Configs installed!"
}

configure_display_manager() {
    print_info "Configuring auto-start for Hyprland..."
    
    # Add Hyprland auto-start to .bash_profile
    if ! grep -q "Hyprland" "$HOME/.bash_profile" 2>/dev/null; then
        cat >> "$HOME/.bash_profile" << 'EOF'

# Auto-start Hyprland on TTY1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec Hyprland
fi
EOF
        print_success "Hyprland auto-start configured!"
    else
        print_info "Hyprland auto-start already configured."
    fi
    
    # Also add to .zprofile if zsh is the shell
    if [ -n "$ZSH_VERSION" ] || command -v zsh &>/dev/null; then
        if ! grep -q "Hyprland" "$HOME/.zprofile" 2>/dev/null; then
            cat >> "$HOME/.zprofile" << 'EOF'

# Auto-start Hyprland on TTY1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec Hyprland
fi
EOF
            print_success "Hyprland auto-start configured for zsh!"
        fi
    fi
}

finalize() {
    print_header
    print_success "Voidance transformation complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Reboot your system: sudo reboot"
    echo "  2. Login to your user account"
    echo "  3. Hyprland should start automatically"
    echo ""
    print_info "Keyboard shortcuts:"
    echo "  Super + Return → Open terminal"
    echo "  Super + D → App launcher"
    echo "  Super + Q → Close window"
    echo "  Super + M → Exit Hyprland"
    echo ""
    print_info "Documentation:"
    echo "  ~/.local/share/voidance/docs/"
    echo ""
    print_warning "If you encounter issues, check the logs:"
    echo "  ~/.local/share/hyprland/hyprland.log"
    echo ""
}

# Main execution
main() {
    print_header
    
    print_info "Starting Voidance transformation..."
    echo ""
    
    check_void_linux
    check_requirements
    
    echo ""
    print_warning "This script will transform your Void Linux installation into Voidance."
    print_warning "Make sure you have backed up any important data."
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Transformation cancelled."
        exit 0
    fi
    
    echo ""
    
    # Execute transformation steps
    update_system
    install_base_tools
    clone_voidance
    
    if [ "$HEADLESS_MODE" = false ]; then
        install_packages
        configure_services
        install_configs
        configure_display_manager
    else
        print_info "Headless mode: Skipping GUI components"
        # TODO: Install headless packages only
    fi
    
    finalize
}

# Run main function
main "$@"
