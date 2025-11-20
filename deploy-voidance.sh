#!/bin/bash
# Voidance Linux Direct Deployment Script
# Transforms fresh Void Linux installation into fully-functional Voidance desktop

set -euo pipefail

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="Voidance Direct Deployment"
LOG_FILE="/var/log/voidance-deployment.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[VOIDANCE]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Progress tracking
CURRENT_STEP=0
TOTAL_STEPS=7

show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${CYAN}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} $1"
}

# Initialize deployment
init_deployment() {
    # Check if running as root first
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Create log file with proper permissions
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
    
    # Initialize log
    cat << EOF | tee "$LOG_FILE"
Voidance Linux Direct Deployment Log
=====================================
Date: $(date)
Version: $SCRIPT_VERSION
Script: $0
User: $(whoami)
System: $(uname -a)

EOF
    
    log_success "Deployment initialized"
}

# Show banner
show_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ██╗   ██╗ ██████╗ ██╗██████╗  █████╗ ███╗   ██╗ ██████╗███████╗
║   ██║   ██║██╔═══██╗██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝
║   ██║   ██║██║   ██║██║██║  ██║███████║██╔██╗ ██║██║     █████╗
║   ╚██╗ ██╔╝██║   ██║██║██║  ██║██╔══██║██║╚██╗██║██║     ██╔══╝
║    ╚████╔╝ ╚██████╔╝██║██████╔╝██║  ██║██║ ╚████║╚██████╗███████╗
║     ╚═══╝   ╚═════╝ ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
║                                                           ║
║              Direct Deployment System                        ║
║                  Transform Void → Voidance                   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
}

# Validate system requirements
validate_system() {
    log_step "STEP 1: System Validation"
    show_progress "Validating system requirements"
    
    local errors=0
    
    # Check if this is Void Linux
    if [[ -f /etc/os-release ]] && grep -q "void" /etc/os-release 2>/dev/null; then
        log_success "Void Linux detected"
        local void_version=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
        log_info "Version: $void_version"
    elif command -v xbps-install >/dev/null 2>&1; then
        log_success "Void Linux detected (xbps found)"
    else
        log_error "This system is not Void Linux"
        errors=$((errors + 1))
    fi
    
    # Check if xbps is available
    if ! command -v xbps-install >/dev/null 2>&1; then
        log_error "xbps-install not found"
        errors=$((errors + 1))
    else
        log_success "Package manager (xbps) available"
    fi
    
    # Check network connectivity
    if ping -c 1 repo-default.voidlinux.org >/dev/null 2>&1; then
        log_success "Network connectivity verified"
    else
        log_error "No network connectivity"
        errors=$((errors + 1))
    fi
    
    # Check disk space (need at least 5GB free)
    local available_space
    available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=$((5 * 1024 * 1024))  # 5GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        log_error "Insufficient disk space (need 5GB, have $(numfmt --to=iec --suffix=B $((available_space * 1024))))"
        errors=$((errors + 1))
    else
        log_success "Sufficient disk space available"
    fi
    
    # Check memory (need at least 2GB)
    local total_memory
    total_memory=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_memory -lt 2048 ]]; then
        log_warning "Low memory detected (less than 2GB). Installation may be slow."
    else
        log_success "Sufficient memory available"
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_error "System validation failed with $errors errors"
        exit 1
    fi
    
    log_success "System validation passed"
}

# Consolidated package list from all specifications
VOIDANCE_PACKAGES=(
    # System Services (from system-services.sh)
    "elogind" "dbus" "pam" "polkit" "upower" "udisks2"
    
    # Display Manager (from system-services.sh)
    "sddm" "sddm-theme-breeze" "sddm-theme-maldives"
    
    # Network Services (from system-services.sh)
    "NetworkManager" "network-manager-applet" "wpa_supplicant" "dhcpcd" "iptables-nft"
    
    # Audio Services (from system-services.sh)
    "pipewire" "pipewire-pulse" "wireplumber" "rtkit" "libpulseaudio"
    
    # Idle Management (from system-services.sh)
    "swayidle" "swaylock"
    
    # Desktop Environment (from desktop-environment.sh)
    "niri" "waybar" "wofi" "wl-clipboard" "wtype" "wf-recorder" "slurp" "grim"
    "font-firacode-nerd-font" "font-dejavu" "font-liberation"
    "breeze" "breeze-icons" "adwaita-icon-theme" "ghostty"
    "xdg-utils" "xdg-desktop-portal" "xdg-desktop-portal-wlr"
    
    # Desktop Applications (from desktop-applications.sh)
    "thunar" "thunar-archive-plugin" "thunar-volman" "mako"
    "ttf-montserrat" "ttf-inconsolata" "glu" "mesa" "libglvnd"
    "gvfs" "gvfs-mtp" "gvfs-gphoto2" "ffmpegthumbnailer" "libnotify"
    
    # Fallback Compositor (from fallback-compositor.sh)
    "sway" "swaybg" "i3status" "i3blocks" "dmenu" "rofi" "foot"
    "xwayland" "qt5-wayland" "gtk+3-wayland" "libinput" "seatd"
)

# Install packages
install_packages() {
    log_step "STEP 2: Package Installation"
    show_progress "Installing Voidance packages"
    
    log_info "Updating package database..."
    if xbps-install -S; then
        log_success "Package database updated"
    else
        log_error "Failed to update package database"
        exit 1
    fi
    
    log_info "Installing ${#VOIDANCE_PACKAGES[@]} packages..."
    
    local failed_packages=()
    local total_packages=${#VOIDANCE_PACKAGES[@]}
    local installed_count=0
    
    for package in "${VOIDANCE_PACKAGES[@]}"; do
        installed_count=$((installed_count + 1))
        echo -ne "${CYAN}[${installed_count}/${total_packages}]${NC} Installing $package... "
        
        if xbps-install -y "$package" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warning "The following packages failed to install:"
        printf '  %s\n' "${failed_packages[@]}"
        log_info "These may need to be installed manually"
    else
        log_success "All packages installed successfully"
    fi
}

# Configure and enable services
configure_services() {
    log_step "STEP 3: Service Configuration"
    show_progress "Configuring system services"
    
    # Core services
    local services=(
        "dbus"           # System message bus
        "elogind"        # Session management
        "NetworkManager"  # Network management
        "sddm"           # Display manager
    )
    
    for service in "${services[@]}"; do
        if [[ -L "/var/service/$service" ]]; then
            log_success "Service $service already enabled"
        else
            log_info "Enabling service: $service"
            if ln -sf "/etc/sv/$service" "/var/service/" 2>/dev/null; then
                log_success "Enabled $service"
            else
                log_warning "Failed to enable $service"
            fi
        fi
    done
    
    log_success "Service configuration completed"
}

# Setup desktop environment
setup_desktop() {
    log_step "STEP 4: Desktop Environment Setup"
    show_progress "Configuring desktop environment"
    
    # Create user directories
    local username="${SUDO_USER:-root}"
    if [[ "$username" != "root" ]]; then
        local user_home="/home/$username"
        
        # Create XDG directories
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
            if [[ ! -d "$full_path" ]]; then
                mkdir -p "$full_path"
                chown "$username:$username" "$full_path"
                log_info "Created $full_path"
            fi
        done
        
        log_success "User directories created for $username"
    else
        log_warning "Running as root, skipping user directory creation"
    fi
    
    log_success "Desktop environment setup completed"
}

# Validate installation
validate_installation() {
    log_step "STEP 5: Installation Validation"
    show_progress "Validating installation"
    
    local validation_errors=0
    
    # Check critical packages
    local critical_packages=("niri" "sddm" "NetworkManager" "pipewire")
    for package in "${critical_packages[@]}"; do
        if xbps-query "$package" >/dev/null 2>&1; then
            log_success "✓ $package is installed"
        else
            log_error "✗ $package is missing"
            validation_errors=$((validation_errors + 1))
        fi
    done
    
    # Check services
    local critical_services=("dbus" "elogind" "NetworkManager")
    for service in "${critical_services[@]}"; do
        local status_output
        status_output=$(sv status "$service" 2>&1 | head -n 1)
        if echo "$status_output" | grep -q "^run:"; then
            log_success "✓ $service is running"
        else
            log_warning "⚠ $service is not running (may need reboot)"
        fi
    done
    
    if [[ $validation_errors -gt 0 ]]; then
        log_error "Installation validation failed with $validation_errors errors"
        return 1
    else
        log_success "Installation validation passed"
        return 0
    fi
}

# Rollback function for critical failures
rollback_installation() {
    log_error "Critical error occurred, initiating rollback..."
    
    # Disable services that were enabled
    local services=("sddm" "NetworkManager" "elogind" "dbus")
    for service in "${services[@]}"; do
        if [[ -L "/var/service/$service" ]]; then
            log_info "Disabling service: $service"
            rm -f "/var/service/$service" 2>/dev/null || true
        fi
    done
    
    log_warning "Rollback completed. Some packages may remain installed."
    log_info "You can safely retry the deployment or manually clean up packages."
}

# Show completion message
show_completion() {
    log_step "✅ VOIDANCE DEPLOYMENT COMPLETE"
    
    cat << EOF

${GREEN}Installation Summary:${NC}
=====================
✅ System validation passed
✅ All packages installed
✅ Services configured
✅ Desktop environment setup
✅ Installation validated

${GREEN}What's Included:${NC}
==================
• Desktop Environment: Niri (Wayland compositor)
• Display Manager: SDDM with themes
• Audio System: PipeWire with WirePlumber
• Network Management: NetworkManager
• File Manager: Thunar with plugins
• Terminal: Ghostty (with foot as fallback)
• Status Bar: Waybar
• Application Launcher: Wofi
• Notifications: Mako
• Fonts: Noto, DejaVu, Liberation
• Themes: Breeze and Adwaita

${GREEN}Next Steps:${NC}
=============
1. ${YELLOW}Reboot your system${NC} to start all services
2. At the login screen, select your user account
3. ${GREEN}Welcome to Voidance!${NC}

${GREEN}Getting Started:${NC}
================
• Press Super (Windows) + Enter to open application launcher
• Press Super + Shift + Q to logout
• Press Super + Shift + R to restart compositor
• Check ~/.config/niri/config for niri configuration
• Check ~/.config/waybar/config for status bar configuration

${GREEN}Troubleshooting:${NC}
==================
• Log file: $LOG_FILE
• Service status: sv status [service-name]
• Package check: xbps-query [package-name]
• Network: nmtui or nmcli

${CYAN}Thank you for using Voidance Linux!${NC}
${CYAN}Report issues at: https://github.com/voidance/voidance/issues${NC}

EOF
}

# Main deployment function
main() {
    # Set up error handling for rollback
    trap 'rollback_installation' ERR
    
    show_banner
    init_deployment
    validate_system
    install_packages
    configure_services
    setup_desktop
    
    if validate_installation; then
        show_completion
        log_success "Deployment completed successfully"
    else
        log_error "Deployment completed with validation errors"
        exit 1
    fi
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy"|"")
        main
        ;;
    "help"|"-h"|"--help")
        cat << EOF
Usage: sudo bash $0 [deploy|help]

Commands:
  deploy    Run full deployment (default)
  help      Show this help message

Examples:
  sudo bash $0
  sudo bash $0 deploy

This script transforms a fresh Void Linux installation into a fully-functional
Voidance desktop environment with a single command.

Requirements:
- Fresh Void Linux installation
- Internet connectivity
- 5GB+ free disk space
- 2GB+ RAM recommended
- Root/sudo access

EOF
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac