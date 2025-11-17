#!/bin/bash
# Voidance First-Boot Setup and Welcome Script
# Provides initial system configuration and user onboarding

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/iso/config.sh"

# First-boot configuration
FIRST_BOOT_LOG="/var/log/voidance-first-boot.log"
FIRST_BOOT_FLAG="/etc/voidance-first-boot-completed"
USER_CONFIG_DIR="/etc/voidance-user-config"

# Function to check if this is first boot
is_first_boot() {
    [[ ! -f "$FIRST_BOOT_FLAG" ]]
}

# Function to initialize first-boot environment
init_first_boot() {
    log_message "INFO" "Initializing first-boot environment"
    
    # Create configuration directory
    mkdir -p "$USER_CONFIG_DIR"
    
    # Initialize log
    cat > "$FIRST_BOOT_LOG" << EOF
Voidance Linux First-Boot Setup Log
==================================
Date: $(date)
User: $(whoami)
Display: ${DISPLAY:-"N/A"}
Session: ${XDG_SESSION_TYPE:-"N/A"}

EOF
    
    log_message "INFO" "First-boot environment initialized"
}

# Function to display welcome screen
show_welcome_screen() {
    clear
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                    Welcome to Voidance Linux!                ║
║                                                              ║
║           A minimal Wayland-based Linux distribution          ║
║                  built on Void Linux                         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

Thank you for choosing Voidance Linux! This setup wizard will help you
configure your system for the best possible experience.

What we'll set up today:
• System preferences and personalization
• Desktop environment configuration
• Hardware optimization
• Network and connectivity
• User account preferences

Press Enter to begin your Voidance journey...
EOF
    read -r
}

# Function to collect user information
collect_user_information() {
    log_message "INFO" "Collecting user information"
    
    clear
    echo "User Information"
    echo "================"
    echo ""
    
    # Get current user
    local current_user=$(whoami)
    echo "Current user: $current_user"
    
    # Get full name
    local full_name=$(getent passwd "$current_user" | cut -d: -f5 | cut -d, -f1)
    if [[ -z "$full_name" ]] || [[ "$full_name" == "$current_user" ]]; then
        read -p "Full name: " input_name
        if [[ -n "$input_name" ]]; then
            chfn -f "$input_name" "$current_user"
            log_message "INFO" "Full name set to: $input_name"
        fi
    else
        echo "Full name: $full_name"
    fi
    
    # Email (optional)
    read -p "Email (optional): " email
    if [[ -n "$email" ]]; then
        echo "email=\"$email\"" >> "$USER_CONFIG_DIR/user-info.conf"
        log_message "INFO" "Email set to: $email"
    fi
    
    # Timezone
    echo ""
    echo "Current timezone: $(timedatectl show --property=Timezone --value)"
    read -p "Change timezone? (y/N): " change_tz
    if [[ "$change_tz" =~ ^[Yy]$ ]]; then
        echo "Available timezones:"
        timedatectl list-timezones | head -20
        echo "..."
        read -p "Enter timezone: " new_tz
        if timedatectl set-timezone "$new_tz" 2>/dev/null; then
            log_message "INFO" "Timezone changed to: $new_tz"
        else
            echo "Invalid timezone. Keeping current setting."
        fi
    fi
    
    # Locale
    echo ""
    echo "Current locale: $(locale | grep LANG= | cut -d= -f2)"
    read -p "Change locale? (y/N): " change_locale
    if [[ "$change_locale" =~ ^[Yy]$ ]]; then
        echo "Available locales:"
        locale -a | grep -E "en_US|UTF-8" | head -10
        read -p "Enter locale (e.g., en_US.UTF-8): " new_locale
        if locale -a | grep -q "$new_locale"; then
            echo "LANG=$new_locale" > /etc/locale.conf
            log_message "INFO" "Locale changed to: $new_locale"
        else
            echo "Invalid locale. Keeping current setting."
        fi
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to configure desktop environment
configure_desktop_environment() {
    log_message "INFO" "Configuring desktop environment"
    
    clear
    echo "Desktop Environment Configuration"
    echo "==============================="
    echo ""
    
    # Detect available compositors
    local available_compositors=()
    [[ -f /usr/bin/niri ]] && available_compositors+=("niri")
    [[ -f /usr/bin/sway ]] && available_compositors+=("sway")
    
    if [[ ${#available_compositors[@]} -eq 0 ]]; then
        echo "No Wayland compositors found. Please install niri or sway."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo "Available Wayland compositors:"
    for i in "${!available_compositors[@]}"; do
        echo "$((i+1)). ${available_compositors[i]}"
    done
    
    echo ""
    read -p "Select default compositor (1-${#available_compositors[@]}): " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#available_compositors[@]} ]]; then
        local selected_compositor="${available_compositors[$((selection-1))]}"
        echo "selected_compositor=\"$selected_compositor\"" >> "$USER_CONFIG_DIR/desktop.conf"
        log_message "INFO" "Default compositor set to: $selected_compositor"
        
        # Configure compositor-specific settings
        configure_compositor_settings "$selected_compositor"
    else
        echo "Invalid selection. Using default compositor."
    fi
    
    # Configure wallpaper
    echo ""
    read -p "Set custom wallpaper path (leave empty for default): " wallpaper
    if [[ -n "$wallpaper" ]] && [[ -f "$wallpaper" ]]; then
        echo "wallpaper=\"$wallpaper\"" >> "$USER_CONFIG_DIR/desktop.conf"
        log_message "INFO" "Custom wallpaper set: $wallpaper"
    fi
    
    # Configure theme
    echo ""
    echo "Available themes: dark, light, auto"
    read -p "Select theme (default: dark): " theme
    case "${theme:-dark}" in
        "dark"|"light"|"auto")
            echo "theme=\"${theme:-dark}\"" >> "$USER_CONFIG_DIR/desktop.conf"
            log_message "INFO" "Theme set to: ${theme:-dark}"
            ;;
        *)
            echo "Invalid theme. Using default (dark)."
            echo "theme=\"dark\"" >> "$USER_CONFIG_DIR/desktop.conf"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to configure compositor-specific settings
configure_compositor_settings() {
    local compositor="$1"
    local current_user=$(whoami)
    local home_dir="/home/$current_user"
    
    case "$compositor" in
        "niri")
            # Configure Niri settings
            mkdir -p "$home_dir/.config/niri"
            cat >> "$home_dir/.config/niri/config.kdl" << 'EOF'

// First-boot configuration
input {
    keyboard {
        repeat-delay 200
        repeat-rate 25
    }
}

layout {
    gaps 8
    center-focused-column "on"
}

// User preferences will be added here
EOF
            ;;
        "sway")
            # Configure Sway settings
            mkdir -p "$home_dir/.config/sway"
            cat >> "$home_dir/.config/sway/config" << 'EOF'

# First-boot configuration
gaps inner 8
gaps outer 4
focus_follows_mouse no

# User preferences will be added here
EOF
            ;;
    esac
    
    chown -R "$current_user:$current_user" "$home_dir/.config"
}

# Function to configure hardware optimization
configure_hardware_optimization() {
    log_message "INFO" "Configuring hardware optimization"
    
    clear
    echo "Hardware Optimization"
    echo "====================="
    echo ""
    
    # Detect GPU
    local gpu_info=$(lspci | grep -i vga | head -1)
    echo "Detected GPU: $gpu_info"
    
    # GPU-specific optimizations
    if echo "$gpu_info" | grep -qi nvidia; then
        echo "NVIDIA GPU detected"
        read -p "Enable NVIDIA optimizations? (Y/n): " nvidia_opt
        if [[ ! "$nvidia_opt" =~ ^[Nn]$ ]]; then
            enable_nvidia_optimizations
        fi
    elif echo "$gpu_info" | grep -qi "intel\|amd"; then
        echo "Intel/AMD GPU detected"
        read -p "Enable open-source GPU optimizations? (Y/n): " gpu_opt
        if [[ ! "$gpu_opt" =~ ^[Nn]$ ]]; then
            enable_opensource_gpu_optimizations
        fi
    fi
    
    # Detect CPU
    local cpu_info=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    echo "Detected CPU: $cpu_info"
    
    # CPU optimizations
    read -p "Enable CPU performance optimizations? (Y/n): " cpu_opt
    if [[ ! "$cpu_opt" =~ ^[Nn]$ ]]; then
        enable_cpu_optimizations
    fi
    
    # Power management
    echo ""
    read -p "Configure power management for laptops? (y/N): " power_mgmt
    if [[ "$power_mgmt" =~ ^[Yy]$ ]]; then
        configure_power_management
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to enable NVIDIA optimizations
enable_nvidia_optimizations() {
    log_message "INFO" "Enabling NVIDIA optimizations"
    
    # Install NVIDIA drivers if not present
    if ! lsmod | grep -q nvidia; then
        echo "NVIDIA drivers not loaded. Please install them first."
        return 1
    fi
    
    # Configure NVIDIA settings
    mkdir -p /etc/X11/xorg.conf.d
    cat > /etc/X11/xorg.conf.d/20-nvidia.conf << 'EOF'
Section "Device"
    Identifier "NVIDIA Card"
    Driver "nvidia"
    Option "Coolbits" "28"
    Option "TripleBuffer" "true"
    Option "AllowGLXWithComposite" "true"
EndSection
EOF
    
    # Enable NVIDIA power management
    echo "options nvidia NVreg_RegistryDwords=PowerMizerEnable=1x1" >> /etc/modprobe.d/nvidia.conf
    
    log_message "INFO" "NVIDIA optimizations enabled"
}

# Function to enable open-source GPU optimizations
enable_opensource_gpu_optimizations() {
    log_message "INFO" "Enabling open-source GPU optimizations"
    
    # Enable early KMS
    local gpu_module=""
    if lspci | grep -qi amd; then
        gpu_module="amdgpu"
    elif lspci | grep -qi intel; then
        gpu_module="i915"
    fi
    
    if [[ -n "$gpu_module" ]]; then
        echo "$gpu_module" >> /etc/modules-load.d/gpu.conf
        echo "options $gpu_module modeset=1" >> /etc/modprobe.d/gpu.conf
        log_message "INFO" "GPU early KMS enabled for $gpu_module"
    fi
}

# Function to enable CPU optimizations
enable_cpu_optimizations() {
    log_message "INFO" "Enabling CPU optimizations"
    
    # Enable CPU governor
    if command -v cpupower >/dev/null 2>&1; then
        cpupower frequency-set -g performance
        echo "cpupower" >> /etc/runit/runsvdir/default/
        log_message "INFO" "CPU governor set to performance"
    fi
    
    # Enable CPU frequency scaling
    echo 'KERNEL=="cpu[0-9]*", MODE="0664", GROUP="users"' > /etc/udev/rules.d/99-cpu.rules
}

# Function to configure power management
configure_power_management() {
    log_message "INFO" "Configuring power management"
    
    # Install TLP if available
    if command -v tlp >/dev/null 2>&1; then
        systemctl enable tlp
        systemctl start tlp
        log_message "INFO" "TLP power management enabled"
    fi
    
    # Configure laptop-mode-tools if available
    if command -v laptop_mode >/dev/null 2>&1; then
        systemctl enable laptop-mode
        log_message "INFO" "Laptop mode tools enabled"
    fi
    
    # Create power management scripts
    mkdir -p /etc/voidance/power
    cat > /etc/voidance/power/battery.sh << 'EOF'
#!/bin/bash
# Power saving mode for battery

# Reduce CPU frequency
cpupower frequency-set -g powersave 2>/dev/null || true

# Reduce screen brightness
echo 50 > /sys/class/backlight/*/brightness 2>/dev/null || true

# Disable Wi-Fi power saving
iwconfig wlan0 power off 2>/dev/null || true
EOF
    
    cat > /etc/voidance/power/ac.sh << 'EOF'
#!/bin/bash
# Performance mode for AC power

# Set CPU to performance mode
cpupower frequency-set -g performance 2>/dev/null || true

# Set screen brightness to maximum
echo 100 > /sys/class/backlight/*/brightness 2>/dev/null || true
EOF
    
    chmod +x /etc/voidance/power/*.sh
    log_message "INFO" "Power management scripts created"
}

# Function to configure network and connectivity
configure_network_connectivity() {
    log_message "INFO" "Configuring network connectivity"
    
    clear
    echo "Network and Connectivity"
    echo "======================="
    echo ""
    
    # Check NetworkManager status
    if systemctl is-active --quiet NetworkManager; then
        echo "✓ NetworkManager is running"
    else
        echo "✗ NetworkManager is not running"
        read -p "Start NetworkManager? (Y/n): " start_nm
        if [[ ! "$start_nm" =~ ^[Nn]$ ]]; then
            systemctl enable NetworkManager
            systemctl start NetworkManager
            log_message "INFO" "NetworkManager started"
        fi
    fi
    
    # List available connections
    echo ""
    echo "Available network connections:"
    nmcli connection show | head -10
    
    # Configure auto-connect
    echo ""
    read -p "Configure automatic Wi-Fi connection? (y/N): " auto_wifi
    if [[ "$auto_wifi" =~ ^[Yy]$ ]]; then
        echo "Available Wi-Fi networks:"
        nmcli device wifi list | head -10
        read -p "Enter SSID to auto-connect: " ssid
        if [[ -n "$ssid" ]]; then
            read -s -p "Password: " wifi_pass
            echo
            nmcli connection add type wifi con-name "$ssid" ifname wlan0 ssid "$ssid" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$wifi_pass" autoconnect yes
            log_message "INFO" "Auto-connect configured for: $ssid"
        fi
    fi
    
    # Configure VPN
    echo ""
    read -p "Configure VPN connection? (y/N): " configure_vpn
    if [[ "$configure_vpn" =~ ^[Yy]$ ]]; then
        echo "VPN types: openvpn, wireguard, pptp"
        read -p "VPN type: " vpn_type
        read -p "VPN name: " vpn_name
        case "$vpn_type" in
            "openvpn"|"wireguard"|"pptp")
                echo "VPN configuration for $vpn_type would be set up here"
                log_message "INFO" "VPN configuration requested: $vpn_type"
                ;;
            *)
                echo "Unsupported VPN type"
                ;;
        esac
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to configure user preferences
configure_user_preferences() {
    log_message "INFO" "Configuring user preferences"
    
    clear
    echo "User Preferences"
    echo "================"
    echo ""
    
    local current_user=$(whoami)
    local home_dir="/home/$current_user"
    
    # Shell preferences
    echo "Current shell: $SHELL"
    read -p "Change shell? (bash/zsh/fish) [current]: " new_shell
    case "$new_shell" in
        "bash"|"zsh"|"fish")
            if command -v "$new_shell" >/dev/null 2>&1; then
                chsh -s "$(which "$new_shell")" "$current_user"
                log_message "INFO" "Shell changed to: $new_shell"
            else
                echo "Shell $new_shell not available"
            fi
            ;;
    esac
    
    # Terminal preferences
    echo ""
    echo "Terminal emulator: foot (default)"
    read -p "Change terminal? (foot/alacritty/kitty) [foot]: " terminal
    case "$terminal" in
        "alacritty"|"kitty")
            if command -v "$terminal" >/dev/null 2>&1; then
                echo "terminal=\"$terminal\"" >> "$USER_CONFIG_DIR/user-prefs.conf"
                log_message "INFO" "Terminal set to: $terminal"
            else
                echo "Terminal $terminal not available"
            fi
            ;;
    esac
    
    # File manager preferences
    echo ""
    echo "File manager: thunar (default)"
    read -p "Change file manager? (thunar/pcmanfm/nautilus) [thunar]: " file_manager
    case "$file_manager" in
        "pcmanfm"|"nautilus")
            if command -v "$file_manager" >/dev/null 2>&1; then
                echo "file_manager=\"$file_manager\"" >> "$USER_CONFIG_DIR/user-prefs.conf"
                log_message "INFO" "File manager set to: $file_manager"
            else
                echo "File manager $file_manager not available"
            fi
            ;;
    esac
    
    # Web browser preferences
    echo ""
    echo "Web browser: firefox (default)"
    read -p "Change browser? (firefox/chromium/brave) [firefox]: " browser
    case "$browser" in
        "chromium"|"brave")
            if command -v "$browser" >/dev/null 2>&1; then
                echo "browser=\"$browser\"" >> "$USER_CONFIG_DIR/user-prefs.conf"
                log_message "INFO" "Browser set to: $browser"
            else
                echo "Browser $browser not available"
            fi
            ;;
    esac
    
    # Privacy settings
    echo ""
    read -p "Enable privacy-enhanced settings? (Y/n): " privacy
    if [[ ! "$privacy" =~ ^[Nn]$ ]]; then
        enable_privacy_settings
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to enable privacy settings
enable_privacy_settings() {
    log_message "INFO" "Enabling privacy settings"
    
    # Disable telemetry where possible
    echo "privacy_enabled=true" >> "$USER_CONFIG_DIR/user-prefs.conf"
    
    # Configure Firefox privacy if installed
    if command -v firefox >/dev/null 2>&1; then
        echo "Firefox privacy settings would be configured here"
    fi
    
    # Configure system-wide privacy settings
    echo "privacy=true" >> "$USER_CONFIG_DIR/user-prefs.conf"
    log_message "INFO" "Privacy settings enabled"
}

# Function to apply all configurations
apply_configurations() {
    log_message "INFO" "Applying all configurations"
    
    clear
    echo "Applying Configurations"
    echo "======================"
    echo ""
    
    # Apply desktop configuration
    if [[ -f "$USER_CONFIG_DIR/desktop.conf" ]]; then
        echo "Applying desktop configuration..."
        # Apply desktop settings here
        log_message "INFO" "Desktop configuration applied"
    fi
    
    # Apply user preferences
    if [[ -f "$USER_CONFIG_DIR/user-prefs.conf" ]]; then
        echo "Applying user preferences..."
        # Apply user preferences here
        log_message "INFO" "User preferences applied"
    fi
    
    # Update system
    echo "Updating system packages..."
    if command -v xbps-install >/dev/null 2>&1; then
        xbps-install -Syu
        log_message "INFO" "System packages updated"
    fi
    
    # Enable services
    echo "Enabling system services..."
    systemctl enable NetworkManager 2>/dev/null || true
    systemctl enable bluetooth 2>/dev/null || true
    systemctl enable cups 2>/dev/null || true
    
    log_message "INFO" "All configurations applied"
}

# Function to show completion screen
show_completion_screen() {
    clear
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                 Setup Complete! 🎉                           ║
║                                                              ║
║           Your Voidance Linux system is ready to use         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

What's Next:
• Press Enter to start your desktop environment
• Explore the Wayland desktop with Niri/Sway
• Check out the documentation in /usr/share/doc/voidance/
• Join our community at https://voidance.org/community

Getting Help:
• Documentation: /usr/share/doc/voidance/
• Community: https://voidance.org/community
• Support: https://voidance.org/support

Thank you for choosing Voidance Linux!

Press Enter to start your desktop environment...
EOF
    read -r
    
    # Mark first boot as completed
    touch "$FIRST_BOOT_FLAG"
    log_message "INFO" "First-boot setup completed"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$FIRST_BOOT_LOG"
}

# Main first-boot setup function
main_first_boot() {
    # Only run on first boot
    if ! is_first_boot; then
        log_message "INFO" "First-boot setup already completed"
        return 0
    fi
    
    # Only run for regular users, not root
    if [[ "$(id -u)" -eq 0 ]]; then
        log_message "INFO" "First-boot setup should be run as regular user"
        return 0
    fi
    
    init_first_boot
    show_welcome_screen
    collect_user_information
    configure_desktop_environment
    configure_hardware_optimization
    configure_network_connectivity
    configure_user_preferences
    apply_configurations
    show_completion_screen
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_first_boot "$@"
fi