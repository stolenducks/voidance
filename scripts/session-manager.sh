#!/bin/bash

# Session Management Script for Voidance Linux
# Provides logout, reboot, shutdown, and lock functionality

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        "OK")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
}

# Function to confirm action
confirm_action() {
    local action="$1"
    local timeout="${2:-30}"
    
    print_status "WARN" "Are you sure you want to $action? (y/N)"
    print_status "INFO" "Auto-canceling in $timeout seconds..."
    
    # Countdown with timeout
    for ((i=$timeout; i>0; i--)); do
        echo -ne "\r${YELLOW}$i${NC} seconds remaining... "
        read -t 1 -n 1 response 2>/dev/null || true
        
        if [[ $response =~ ^[Yy]$ ]]; then
            echo ""
            return 0
        elif [[ $response =~ ^[Nn]$ ]] || [[ -n $response ]]; then
            echo ""
            print_status "INFO" "Action cancelled"
            return 1
        fi
    done
    
    echo ""
    print_status "INFO" "Action cancelled (timeout)"
    return 1
}

# Function to logout from session
logout_session() {
    print_status "INFO" "Logging out from current session..."
    
    # Try different logout methods based on the current session
    if [ -n "${XDG_SESSION_TYPE:-}" ] && [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        # Wayland session
        if command -v niri >/dev/null 2>&1 && pgrep -x niri >/dev/null; then
            print_status "INFO" "Logging out from Niri session..."
            niri msg quit
        elif command -v sway >/dev/null 2>&1 && pgrep -x sway >/dev/null; then
            print_status "INFO" "Logging out from Sway session..."
            swaymsg exit
        elif command -v hyprland >/dev/null 2>&1 && pgrep -x Hyprland >/dev/null; then
            print_status "INFO" "Logging out from Hyprland session..."
            hyprctl dispatch exit
        else
            print_status "WARN" "Unknown Wayland compositor, trying generic logout..."
            loginctl terminate-session "$XDG_SESSION_ID" 2>/dev/null || pkill -x "$XDG_CURRENT_DESKTOP" 2>/dev/null || true
        fi
    else
        # X11 or other session
        if command -v i3 >/dev/null 2>&1 && pgrep -x i3 >/dev/null; then
            print_status "INFO" "Logging out from i3 session..."
            i3-msg exit
        elif [ -n "${DISPLAY:-}" ]; then
            print_status "INFO" "Logging out from X11 session..."
            pkill -x "$XDG_CURRENT_DESKTOP" 2>/dev/null || loginctl terminate-session "$XDG_SESSION_ID" 2>/dev/null || true
        else
            print_status "INFO" "Logging out from TTY session..."
            exit 0
        fi
    fi
}

# Function to reboot system
reboot_system() {
    print_status "INFO" "Rebooting system..."
    
    if command -v systemctl >/dev/null 2>&1; then
        systemctl reboot
    elif command -v shutdown >/dev/null 2>&1; then
        shutdown -r now
    elif command -v reboot >/dev/null 2>&1; then
        reboot
    else
        print_status "FAIL" "No reboot command found"
        exit 1
    fi
}

# Function to shutdown system
shutdown_system() {
    print_status "INFO" "Shutting down system..."
    
    if command -v systemctl >/dev/null 2>&1; then
        systemctl poweroff
    elif command -v shutdown >/dev/null 2>&1; then
        shutdown -h now
    elif command -v poweroff >/dev/null 2>&1; then
        poweroff
    else
        print_status "FAIL" "No shutdown command found"
        exit 1
    fi
}

# Function to suspend system
suspend_system() {
    print_status "INFO" "Suspending system..."
    
    if command -v systemctl >/dev/null 2>&1; then
        systemctl suspend
    elif command -v pm-suspend >/dev/null 2>&1; then
        pm-suspend
    else
        print_status "FAIL" "No suspend command found"
        exit 1
    fi
}

# Function to hibernate system
hibernate_system() {
    print_status "INFO" "Hibernating system..."
    
    if command -v systemctl >/dev/null 2>&1; then
        systemctl hibernate
    elif command -v pm-hibernate >/dev/null 2>&1; then
        pm-hibernate
    else
        print_status "FAIL" "No hibernate command found"
        exit 1
    fi
}

# Function to lock screen
lock_screen() {
    print_status "INFO" "Locking screen..."
    
    # Try different lock methods based on available tools
    if command -v swaylock >/dev/null 2>&1; then
        swaylock -f -c 000000
    elif command -v gtklock >/dev/null 2>&1; then
        gtklock
    elif command -v physlock >/dev/null 2>&1; then
        physlock
    elif command -v slock >/dev/null 2>&1; then
        slock
    elif command -v xlock >/dev/null 2>&1; then
        xlock
    else
        print_status "WARN" "No screen locker found, installing swaylock..."
        if command -v xbps-install >/dev/null 2>&1; then
            xbps-install -y swaylock
            swaylock -f -c 000000
        else
            print_status "FAIL" "Cannot install screen locker"
            exit 1
        fi
    fi
}

# Function to show session menu
show_menu() {
    local action=""
    
    # Use wofi if available, otherwise fall back to basic menu
    if command -v wofi >/dev/null 2>&1; then
        action=$(echo -e "Logout\nLock\nSuspend\nHibernate\nReboot\nShutdown\nCancel" | wofi --dmenu --prompt "Session:")
    else
        echo "Session Management Menu:"
        echo "1) Logout"
        echo "2) Lock"
        echo "3) Suspend"
        echo "4) Hibernate"
        echo "5) Reboot"
        echo "6) Shutdown"
        echo "7) Cancel"
        echo -n "Select action [1-7]: "
        read -r choice
        
        case "$choice" in
            1) action="Logout" ;;
            2) action="Lock" ;;
            3) action="Suspend" ;;
            4) action="Hibernate" ;;
            5) action="Reboot" ;;
            6) action="Shutdown" ;;
            7) action="Cancel" ;;
            *) action="Cancel" ;;
        esac
    fi
    
    case "$action" in
        "Logout")
            logout_session
            ;;
        "Lock")
            lock_screen
            ;;
        "Suspend")
            if confirm_action "suspend the system" 15; then
                suspend_system
            fi
            ;;
        "Hibernate")
            if confirm_action "hibernate the system" 15; then
                hibernate_system
            fi
            ;;
        "Reboot")
            if confirm_action "reboot the system" 15; then
                reboot_system
            fi
            ;;
        "Shutdown")
            if confirm_action "shutdown the system" 15; then
                shutdown_system
            fi
            ;;
        "Cancel")
            print_status "INFO" "Action cancelled"
            ;;
        *)
            print_status "WARN" "Unknown action: $action"
            ;;
    esac
}

# Function to show session status
show_status() {
    print_status "INFO" "Session Status"
    echo "=================="
    
    # Session information
    echo "Session Type: ${XDG_SESSION_TYPE:-unknown}"
    echo "Session Desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
    echo "Session ID: ${XDG_SESSION_ID:-unknown}"
    
    # Display information
    if [ -n "${DISPLAY:-}" ]; then
        echo "Display: $DISPLAY"
    else
        echo "Display: Wayland/TTY"
    fi
    
    # Running processes
    echo ""
    echo "Running Desktop Processes:"
    if pgrep -x niri >/dev/null; then
        echo "  ✓ Niri (PID: $(pgrep -x niri))"
    fi
    if pgrep -x sway >/dev/null; then
        echo "  ✓ Sway (PID: $(pgrep -x sway))"
    fi
    if pgrep -x waybar >/dev/null; then
        echo "  ✓ Waybar (PID: $(pgrep -x waybar))"
    fi
    if pgrep -x sddm >/dev/null; then
        echo "  ✓ SDDM (PID: $(pgrep -x sddm))"
    fi
    
    # System information
    echo ""
    echo "System Status:"
    if command -v systemctl >/dev/null 2>&1; then
        echo "  Systemd: $(systemctl is-system-running 2>/dev/null || echo "unknown")"
    fi
    echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "  Users: $(users)"
    echo "=================="
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] COMMAND

Commands:
    logout          Logout from current session
    lock            Lock the screen
    suspend         Suspend the system
    hibernate       Hibernate the system
    reboot          Reboot the system
    shutdown        Shutdown the system
    menu            Show interactive session menu
    status          Show session status
    help            Show this help message

Options:
    --no-confirm    Skip confirmation prompts
    --force         Force action without checks
    --dry-run       Show what would be done without executing

Examples:
    $0 logout                       # Logout from session
    $0 reboot                       # Reboot with confirmation
    $0 --no-confirm shutdown        # Shutdown without confirmation
    $0 menu                         # Show interactive menu
    $0 status                       # Show session status

EOF
}

# Main function
main() {
    local action="${1:-menu}"
    local no_confirm="${NO_CONFIRM:-false}"
    local force="${FORCE:-false}"
    local dry_run="${DRY_RUN:-false}"
    
    case "$action" in
        "logout")
            if [ "$dry_run" = "true" ]; then
                print_status "INFO" "DRY RUN: Would logout from session"
            else
                logout_session
            fi
            ;;
        "lock")
            if [ "$dry_run" = "true" ]; then
                print_status "INFO" "DRY RUN: Would lock screen"
            else
                lock_screen
            fi
            ;;
        "suspend")
            if [ "$dry_run" = "true" ]; then
                print_status "INFO" "DRY RUN: Would suspend system"
            elif [ "$no_confirm" = "true" ] || confirm_action "suspend the system" 15; then
                suspend_system
            fi
            ;;
        "hibernate")
            if [ "$dry_run" = "true" ]; then
                print_status "INFO" "DRY RUN: Would hibernate system"
            elif [ "$no_confirm" = "true" ] || confirm_action "hibernate the system" 15; then
                hibernate_system
            fi
            ;;
        "reboot")
            if [ "$dry_run" = "true" ]; then
                print_status "INFO" "DRY RUN: Would reboot system"
            elif [ "$no_confirm" = "true" ] || confirm_action "reboot the system" 15; then
                reboot_system
            fi
            ;;
        "shutdown")
            if [ "$dry_run" = "true" ]; then
                print_status "INFO" "DRY RUN: Would shutdown system"
            elif [ "$no_confirm" = "true" ] || confirm_action "shutdown the system" 15; then
                shutdown_system
            fi
            ;;
        "menu")
            show_menu
            ;;
        "status")
            show_status
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_status "FAIL" "Unknown command: $action"
            show_usage
            exit 1
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-confirm)
            export NO_CONFIRM=true
            shift
            ;;
        --force)
            export FORCE=true
            shift
            ;;
        --dry-run)
            export DRY_RUN=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Run main function with remaining arguments
main "$@"