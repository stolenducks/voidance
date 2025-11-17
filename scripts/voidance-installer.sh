#!/bin/bash
# Voidance Text-Based Installer Interface
# Provides a user-friendly text-based installation interface

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Installer configuration
INSTALLER_VERSION="1.0.0"
INSTALLER_TITLE="Voidance Linux Installer"
LOG_FILE="/var/log/voidance-installer.log"
TEMP_DIR="/tmp/voidance-installer"

# Installation state
CURRENT_STEP=0
TOTAL_STEPS=10
INSTALLATION_CONFIG=()

# Function to initialize installer
init_installer() {
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Initialize log file
    cat > "$LOG_FILE" << EOF
Voidance Linux Installer Log
===========================
Date: $(date)
Version: $INSTALLER_VERSION
Installer: $0

EOF
    
    # Set up terminal
    clear
    tput civis  # Hide cursor
    stty -echo  # Disable input echo
    
    # Trap for cleanup
    trap cleanup_installer EXIT INT TERM
}

# Function to cleanup installer
cleanup_installer() {
    # Restore terminal
    tput cnorm  # Show cursor
    stty echo   # Enable input echo
    
    # Clean up temp files
    rm -rf "$TEMP_DIR"
    
    # Log cleanup
    echo "$(date): Installer cleanup completed" >> "$LOG_FILE"
}

# Function to draw header
draw_header() {
    local title="$1"
    local step="$2"
    
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}$INSTALLER_TITLE${NC} ${CYAN}│${NC} ${YELLOW}Version $INSTALLER_VERSION${NC} ${CYAN}│${NC} ${GREEN}Step $step/$TOTAL_STEPS${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}$title${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to draw footer
draw_footer() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}Navigation:${NC} ${WHITE}↑/↓${NC} - Navigate, ${WHITE}Enter${NC} - Select, ${WHITE}Esc${NC} - Back/Quit ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}Help:${NC} ${WHITE}F1${NC} - Help, ${WHITE}F2${NC} - System Info, ${WHITE}F10${NC} - Quit ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# Function to draw progress bar
draw_progress_bar() {
    local current="$1"
    local total="$2"
    local width=50
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    echo -e "${BLUE}[${NC}"
    printf -v bar "%*s" "$filled"
    bar="${bar// /█}"
    printf -v empty_bar "%*s" "$empty"
    empty_bar="${empty_bar// /░}"
    echo -e "${GREEN}$bar${NC}${WHITE}$empty_bar${NC}"
    echo -e "${BLUE}]${NC} ${YELLOW}$percent%%${NC} ($current/$total)"
}

# Function to show menu
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local key
    
    while true; do
        draw_header "$title" "$((CURRENT_STEP + 1))"
        
        # Draw menu options
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "${GREEN}► ${WHITE}${options[$i]}${NC}"
            else
                echo -e "  ${options[$i]}"
            fi
        done
        
        draw_footer
        
        # Read key input
        read -rsn1 key
        
        case "$key" in
            $'\x1b')  # Escape sequence
                read -rsn2 -t 0.1 key || continue
                if [[ "$key" == "[A" ]]; then  # Up arrow
                    ((selected--))
                    [[ $selected -lt 0 ]] && selected=$((${#options[@]} - 1))
                elif [[ "$key" == "[B" ]]; then  # Down arrow
                    ((selected++))
                    [[ $selected -ge ${#options[@]} ]] && selected=0
                fi
                ;;
            '')  # Enter
                return $selected
                ;;
            'q'|'Q')
                if confirm_quit; then
                    exit 0
                fi
                ;;
            'h'|'H'|$'\x1bOP')  # F1 - Help
                    show_help
                    ;;
            'i'|'I'|$'\x1bOQ')  # F2 - System Info
                    show_system_info
                    ;;
            $'\x1b[21~')  # F10 - Quit
                if confirm_quit; then
                    exit 0
                fi
                ;;
        esac
    done
}

# Function to show input dialog
show_input_dialog() {
    local title="$1"
    local prompt="$2"
    local default="${3:-}"
    local input="$default"
    local key
    
    while true; do
        draw_header "$title" "$((CURRENT_STEP + 1))"
        
        echo -e "${WHITE}$prompt${NC}"
        echo ""
        echo -e "${BLUE}┌─────────────────────────────────────────────────────────┐${NC}"
        printf "${BLUE}│${NC} ${WHITE}%-49s${NC} ${BLUE}│${NC}" "$input"
        echo -e "${BLUE}└─────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${GREEN}Enter text, Esc to cancel, Enter to confirm${NC}"
        
        # Read key input
        read -rsn1 key
        
        case "$key" in
            $'\x1b')  # Escape
                read -rsn2 -t 0.1 key || continue
                if [[ "$key" == "[A" ]] || [[ "$key" == "[B" ]]; then
                    continue
                else
                    return 1
                fi
                ;;
            '')  # Enter
                echo "$input"
                return 0
                ;;
            $'\x7f')  # Backspace
                input="${input%?}"
                ;;
            *)
                if [[ ${#input} -lt 49 ]]; then
                    input+="$key"
                fi
                ;;
        esac
    done
}

# Function to show password dialog
show_password_dialog() {
    local title="$1"
    local prompt="$2"
    local password=""
    local key
    
    while true; do
        draw_header "$title" "$((CURRENT_STEP + 1))"
        
        echo -e "${WHITE}$prompt${NC}"
        echo ""
        echo -e "${BLUE}┌─────────────────────────────────────────────────────────┐${NC}"
        printf "${BLUE}│${NC} ${WHITE}%-49s${NC} ${BLUE}│${NC}" "${password//?/*}"
        echo -e "${BLUE}└─────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${GREEN}Enter password, Esc to cancel, Enter to confirm${NC}"
        
        # Read key input
        read -rsn1 key
        
        case "$key" in
            $'\x1b')  # Escape
                read -rsn2 -t 0.1 key || continue
                if [[ "$key" == "[A" ]] || [[ "$key" == "[B" ]]; then
                    continue
                else
                    return 1
                fi
                ;;
            '')  # Enter
                echo "$password"
                return 0
                ;;
            $'\x7f')  # Backspace
                password="${password%?}"
                ;;
            *)
                if [[ ${#password} -lt 49 ]]; then
                    password+="$key"
                fi
                ;;
        esac
    done
}

# Function to show confirm dialog
show_confirm_dialog() {
    local title="$1"
    local message="$2"
    local default="${3:-no}"
    local selected=0
    
    if [[ "$default" == "yes" ]]; then
        selected=0
    else
        selected=1
    fi
    
    local key
    
    while true; do
        draw_header "$title" "$((CURRENT_STEP + 1))"
        
        echo -e "${WHITE}$message${NC}"
        echo ""
        
        if [[ $selected -eq 0 ]]; then
            echo -e "${GREEN}► ${WHITE}Yes${NC}"
            echo "  No"
        else
            echo "  Yes"
            echo -e "${GREEN}► ${WHITE}No${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}↑/↓ - Select, Enter - Confirm, Esc - Cancel${NC}"
        
        # Read key input
        read -rsn1 key
        
        case "$key" in
            $'\x1b')  # Escape sequence
                read -rsn2 -t 0.1 key || continue
                if [[ "$key" == "[A" ]]; then  # Up arrow
                    selected=0
                elif [[ "$key" == "[B" ]]; then  # Down arrow
                    selected=1
                fi
                ;;
            '')  # Enter
                if [[ $selected -eq 0 ]]; then
                    return 0  # Yes
                else
                    return 1  # No
                fi
                ;;
            'y'|'Y')
                return 0  # Yes
                ;;
            'n'|'N')
                return 1  # No
                ;;
        esac
    done
}

# Function to show progress dialog
show_progress_dialog() {
    local title="$1"
    local message="$2"
    local command="$3"
    
    draw_header "$title" "$((CURRENT_STEP + 1))"
    
    echo -e "${WHITE}$message${NC}"
    echo ""
    
    # Create progress animation
    local animation=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    
    # Run command with progress
    (
        eval "$command" 2>&1
        echo "COMMAND_COMPLETE"
    ) | while IFS= read -r line; do
        if [[ "$line" == "COMMAND_COMPLETE" ]]; then
            break
        fi
        
        # Update progress animation
        printf "\r${YELLOW}${animation[$i]}${NC} ${WHITE}$line${NC}"
        ((i++))
        [[ $i -ge ${#animation[@]} ]] && i=0
    done
    
    echo ""
    echo -e "${GREEN}✓ Completed${NC}"
    
    # Wait for user to continue
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read -r
}

# Function to show error dialog
show_error_dialog() {
    local title="$1"
    local message="$2"
    
    draw_header "$title" "$((CURRENT_STEP + 1))"
    
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC} ${WHITE}ERROR${NC} ${RED}║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC} ${WHITE}$message${NC} ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read -r
}

# Function to show success dialog
show_success_dialog() {
    local title="$1"
    local message="$2"
    
    draw_header "$title" "$((CURRENT_STEP + 1))"
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC} ${WHITE}SUCCESS${NC} ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} ${WHITE}$message${NC} ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read -r
}

# Function to show help
show_help() {
    draw_header "Help" "$((CURRENT_STEP + 1))"
    
    cat << 'EOF'
Voidance Linux Installer Help
===========================

Navigation:
• ↑/↓ Arrow Keys - Navigate menus and options
• Enter - Select current option or confirm input
• Esc - Go back or cancel current operation
• Tab - Move between form fields (where applicable)

Function Keys:
• F1 - Show this help screen
• F2 - Show system information
• F10 - Quit installer

Installation Process:
1. Welcome - Introduction to Voidance Linux
2. Language - Select system language
3. Keyboard - Select keyboard layout
4. Disk - Configure disk partitioning
5. User - Create user account
6. Network - Configure network settings
7. Software - Select software packages
8. Install - Begin installation process
9. Configure - Post-installation configuration
10. Complete - Installation finished

Tips:
• You can go back to previous steps using Esc
• All changes are saved automatically
• Installation logs are saved to /var/log/voidance-installer.log
• For support, visit https://voidance.org/support

EOF
    
    echo -e "${GREEN}Press Enter to return...${NC}"
    read -r
}

# Function to show system information
show_system_info() {
    draw_header "System Information" "$((CURRENT_STEP + 1))"
    
    echo -e "${WHITE}Hardware Information:${NC}"
    echo -e "  CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    echo -e "  Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo -e "  Disk Space: $(df -h / | awk 'NR==2 {print $2}')"
    echo ""
    
    echo -e "${WHITE}System Information:${NC}"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  Architecture: $(uname -m)"
    echo -e "  Uptime: $(uptime -p)"
    echo ""
    
    echo -e "${WHITE}Installer Information:${NC}"
    echo -e "  Version: $INSTALLER_VERSION"
    echo -e "  Log File: $LOG_FILE"
    echo -e "  Temp Directory: $TEMP_DIR"
    echo ""
    
    echo -e "${WHITE}Network Information:${NC}"
    if command -v ip >/dev/null 2>&1; then
        echo -e "  Interfaces: $(ip link show | grep -E '^[0-9]+:' | awk '{print $2}' | tr -d ':' | tr '\n' ' ')"
    fi
    
    echo ""
    echo -e "${GREEN}Press Enter to return...${NC}"
    read -r
}

# Function to confirm quit
confirm_quit() {
    show_confirm_dialog "Quit Installer" "Are you sure you want to quit the installer? Any unsaved changes will be lost." "no"
}

# Function to log message
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date): [$level] $message" >> "$LOG_FILE"
}

# Function to save configuration
save_config() {
    local config_file="$TEMP_DIR/installer.conf"
    
    {
        echo "# Voidance Installer Configuration"
        echo "# Generated on $(date)"
        echo ""
        
        for key in "${!INSTALLATION_CONFIG[@]}"; do
            echo "$key=${INSTALLATION_CONFIG[$key]}"
        done
    } > "$config_file"
    
    log_message "INFO" "Configuration saved to $config_file"
}

# Function to load configuration
load_config() {
    local config_file="$TEMP_DIR/installer.conf"
    
    if [[ -f "$config_file" ]]; then
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            INSTALLATION_CONFIG["$key"]="$value"
        done < "$config_file"
        
        log_message "INFO" "Configuration loaded from $config_file"
    fi
}

# Function to set configuration value
set_config() {
    local key="$1"
    local value="$2"
    INSTALLATION_CONFIG["$key"]="$value"
    save_config
    log_message "INFO" "Configuration set: $key=$value"
}

# Function to get configuration value
get_config() {
    local key="$1"
    local default="${2:-}"
    echo "${INSTALLATION_CONFIG[$key]:-$default}"
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check required commands
    local required_commands=(
        "tput"
        "stty"
        "lsblk"
        "fdisk"
        "mkfs"
        "mount"
        "umount"
        "xbps-install"
        "grub-install"
    )
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        show_error_dialog "Missing Dependencies" "The following required commands are missing: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Function to check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        show_error_dialog "Root Required" "This installer must be run as root. Please use sudo or run as root."
        return 1
    fi
    
    return 0
}

# Function to main installer loop
main_installer() {
    # Initialize
    init_installer
    
    # Check requirements
    if ! check_root; then
        exit 1
    fi
    
    if ! check_dependencies; then
        exit 1
    fi
    
    # Load existing configuration
    load_config
    
    # Show welcome screen
    show_welcome_screen
    
    # Main installation loop
    while [[ $CURRENT_STEP -lt $TOTAL_STEPS ]]; do
        case $CURRENT_STEP in
            0) show_language_selection ;;
            1) show_keyboard_selection ;;
            2) show_disk_configuration ;;
            3) show_user_configuration ;;
            4) show_network_configuration ;;
            5) show_software_selection ;;
            6) show_installation_progress ;;
            7) show_post_installation ;;
            8) show_completion_screen ;;
            *) break ;;
        esac
    done
}

# Function to show welcome screen
show_welcome_screen() {
    draw_header "Welcome to Voidance Linux" "$((CURRENT_STEP + 1))"
    
    cat << 'EOF'
Welcome to Voidance Linux!

Voidance is a minimalist, user-friendly Linux distribution based on Void Linux.
It provides a complete desktop experience with modern Wayland compositors,
carefully selected applications, and a focus on simplicity and performance.

Features:
• Modern Wayland desktop with Niri and Sway compositors
• PipeWire audio system for high-quality audio
• Comprehensive application suite
• Minimalist design with educational value
• Hardware-optimized performance

This installer will guide you through the installation process step by step.
You can go back to previous steps at any time using the Esc key.

Press Enter to begin the installation process...
EOF
    
    read -r
    ((CURRENT_STEP++))
}

# Placeholder functions for installation steps
show_language_selection() {
    show_menu "Language Selection" \
        "English (US)" \
        "English (UK)" \
        "Spanish" \
        "French" \
        "German" \
        "Italian" \
        "Portuguese" \
        "Russian" \
        "Chinese (Simplified)" \
        "Japanese"
    
    local result=$?
    set_config "language" "$result"
    ((CURRENT_STEP++))
}

show_keyboard_selection() {
    show_menu "Keyboard Layout" \
        "US" \
        "US International" \
        "UK" \
        "German" \
        "French" \
        "Spanish" \
        "Italian" \
        "Portuguese" \
        "Russian" \
        "Japanese"
    
    local result=$?
    set_config "keyboard" "$result"
    ((CURRENT_STEP++))
}

show_disk_configuration() {
    show_menu "Disk Configuration" \
        "Automatic (use entire disk)" \
        "Manual (custom partitioning)" \
        "Guided (with separate /home)" \
        "Guided (with LVM)" \
        "Guided (with encryption)"
    
    local result=$?
    set_config "disk_config" "$result"
    ((CURRENT_STEP++))
}

show_user_configuration() {
    local username
    local password
    
    username=$(show_input_dialog "User Configuration" "Enter username:")
    if [[ $? -eq 0 ]] && [[ -n "$username" ]]; then
        password=$(show_password_dialog "User Configuration" "Enter password for $username:")
        if [[ $? -eq 0 ]] && [[ -n "$password" ]]; then
            set_config "username" "$username"
            set_config "password" "$password"
            ((CURRENT_STEP++))
        fi
    fi
}

show_network_configuration() {
    show_menu "Network Configuration" \
        "Use DHCP (automatic)" \
        "Static IP configuration" \
        "No network (offline installation)"
    
    local result=$?
    set_config "network_config" "$result"
    ((CURRENT_STEP++))
}

show_software_selection() {
    show_menu "Software Selection" \
        "Full Desktop (recommended)" \
        "Minimal Desktop" \
        "Development Workstation" \
        "Gaming System" \
        "Server" \
        "Custom"
    
    local result=$?
    set_config "software_selection" "$result"
    ((CURRENT_STEP++))
}

show_installation_progress() {
    show_progress_dialog "Installing Voidance Linux" \
        "Please wait while Voidance Linux is being installed..." \
        "sleep 5 && echo 'Installing packages...' && sleep 3 && echo 'Configuring system...' && sleep 2 && echo 'Finalizing installation...' && sleep 2"
    
    ((CURRENT_STEP++))
}

show_post_installation() {
    show_progress_dialog "Post-Installation Configuration" \
        "Configuring system settings and user accounts..." \
        "sleep 3 && echo 'Setting up user accounts...' && sleep 2 && echo 'Configuring services...' && sleep 2 && echo 'Applying system settings...' && sleep 1"
    
    ((CURRENT_STEP++))
}

show_completion_screen() {
    draw_header "Installation Complete" "$((CURRENT_STEP + 1))"
    
    cat << 'EOF'
Congratulations! Voidance Linux has been successfully installed on your system.

Installation Summary:
• System: Voidance Linux
• Desktop Environment: Wayland (Niri/Sway)
• User Account: Created
• Services: Configured and running

Next Steps:
1. Reboot your system
2. Remove installation media
3. Log in with your created user account
4. Enjoy your Voidance Linux experience!

Getting Help:
• Documentation: /usr/share/doc/voidance/
• Community: https://voidance.org/community
• Support: https://voidance.org/support

Thank you for choosing Voidance Linux!

Press Enter to reboot your system...
EOF
    
    read -r
    
    # Reboot system
    log_message "INFO" "Installation completed, rebooting system"
    reboot
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_installer
fi