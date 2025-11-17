#!/bin/bash

# Wayland Session Setup Script for Voidance Linux
# Creates Wayland session directory structure and session files

set -euo pipefail

WAYLAND_SESSIONS_DIR="/usr/share/wayland-sessions"
CONFIG_SOURCE_DIR="$(dirname "$0")/../config/wayland-sessions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
            echo -e "ℹ $message"
            ;;
    esac
}

# Function to create Wayland sessions directory
create_sessions_directory() {
    print_status "INFO" "Creating Wayland sessions directory..."
    
    if [ ! -d "$WAYLAND_SESSIONS_DIR" ]; then
        mkdir -p "$WAYLAND_SESSIONS_DIR"
        print_status "OK" "Created Wayland sessions directory: $WAYLAND_SESSIONS_DIR"
    else
        print_status "OK" "Wayland sessions directory already exists: $WAYLAND_SESSIONS_DIR"
    fi
    
    # Set proper permissions
    chmod 755 "$WAYLAND_SESSIONS_DIR"
    print_status "OK" "Set directory permissions"
}

# Function to install session files
install_session_files() {
    print_status "INFO" "Installing Wayland session files..."
    
    local session_files=(
        "niri.desktop"
    )
    
    for session_file in "${session_files[@]}"; do
        local source_file="$CONFIG_SOURCE_DIR/$session_file"
        local target_file="$WAYLAND_SESSIONS_DIR/$session_file"
        
        if [ -f "$source_file" ]; then
            cp "$source_file" "$target_file"
            chmod 644 "$target_file"
            print_status "OK" "Installed session file: $session_file"
        else
            print_status "WARN" "Session file not found: $source_file"
        fi
    done
}

# Function to verify session files
verify_session_files() {
    print_status "INFO" "Verifying Wayland session files..."
    
    local session_files=(
        "niri.desktop"
    )
    
    for session_file in "${session_files[@]}"; do
        local target_file="$WAYLAND_SESSIONS_DIR/$session_file"
        
        if [ -f "$target_file" ]; then
            # Check file permissions
            local perms=$(stat -c "%a" "$target_file" 2>/dev/null || stat -f "%A" "$target_file" 2>/dev/null)
            if [ "$perms" = "644" ]; then
                print_status "OK" "$session_file has correct permissions"
            else
                print_status "WARN" "$session_file has unexpected permissions: $perms"
            fi
            
            # Check key fields
            if grep -q "Type=Application" "$target_file"; then
                print_status "OK" "$session_file has correct Type"
            else
                print_status "WARN" "$session_file missing Type=Application"
            fi
            
            if grep -q "Exec=niri-session" "$target_file"; then
                print_status "OK" "$session_file has correct Exec command"
            else
                print_status "WARN" "$session_file missing or incorrect Exec command"
            fi
        else
            print_status "FAIL" "$session_file not found"
        fi
    done
}

# Function to create fallback session (if niri not available)
create_fallback_session() {
    print_status "INFO" "Creating fallback Wayland session..."
    
    local fallback_session="$WAYLAND_SESSIONS_DIR/wayland-fallback.desktop"
    
    cat > "$fallback_session_session" << 'EOF'
[Desktop Entry]
Name=Wayland (Fallback)
Comment=Basic Wayland session
Exec=weston-terminal
Type=Application
DesktopNames=weston
Keywords=wayland;shell;
X-DesktopNames=weston
EOF
    
    if [ -f "$fallback_session" ]; then
        chmod 644 "$fallback_session"
        print_status "OK" "Created fallback Wayland session"
    else
        print_status "FAIL" "Failed to create fallback session"
    fi
}

# Function to test session recognition
test_session_recognition() {
    print_status "INFO" "Testing session recognition..."
    
    # Check if SDDM can find sessions
    if command -v sddm-greeter >/dev/null 2>&1; then
        print_status "INFO" "SDDM greeter available"
    else
        print_status "WARN" "SDDM greeter not found"
    fi
    
    # List available sessions
    if [ -d "$WAYLAND_SESSIONS_DIR" ]; then
        local sessions=$(find "$WAYLAND_SESSIONS_DIR" -name "*.desktop" -exec basename {} .desktop \; | tr '\n' ' ')
        print_status "INFO" "Available sessions: $sessions"
    fi
}

# Function to show session file contents
show_session_info() {
    local session_file="${1:-niri.desktop}"
    local target_file="$WAYLAND_SESSIONS_DIR/$session_file"
    
    if [ -f "$target_file" ]; then
        print_status "INFO" "Contents of $session_file:"
        echo "----------------------------------------"
        cat "$target_file"
        echo "----------------------------------------"
    else
        print_status "FAIL" "Session file not found: $session_file"
    fi
}

# Main installation function
main() {
    local action="${1:-install}"
    local session_file="${2:-}"
    
    print_status "INFO" "Wayland Session Setup for Voidance Linux"
    echo ""
    
    case "$action" in
        "install")
            create_sessions_directory
            install_session_files
            verify_session_files
            test_session_recognition
            
            echo ""
            print_status "OK" "Wayland session setup completed successfully"
            print_status "INFO" "Restart SDDM to see new sessions"
            ;;
        "verify")
            verify_session_files
            test_session_recognition
            ;;
        "show")
            show_session_info "$session_file"
            ;;
        "fallback")
            create_fallback_session
            ;;
        *)
            echo "Usage: $0 {install|verify|show [session]|fallback}"
            echo ""
            echo "Actions:"
            echo "  install    - Install Wayland session files"
            echo "  verify     - Verify existing session files"
            echo "  show       - Show contents of a session file"
            echo "  fallback   - Create fallback session"
            echo ""
            echo "Examples:"
            echo "  $0 install"
            echo "  $0 verify"
            echo "  $0 show niri.desktop"
            exit 1
            ;;
    esac
}

# Script usage
case "${1:-install}" in
    "install"|"verify"|"show"|"fallback")
        main "$@"
        ;;
    *)
        echo "Usage: $0 {install|verify|show [session]|fallback}"
        exit 1
        ;;
esac