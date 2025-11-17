#!/bin/bash
# Ghostty Desktop Integration Script
# Configures Ghostty integration with Voidance desktop environment

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
    exit 1
}

# Function to setup Ghostty environment variables
setup_environment() {
    log "Setting up Ghostty environment variables"
    
    local env_file="$CONFIG_DIR/desktop/environment"
    
    # Create environment file for Ghostty
    cat > "$env_file" << 'EOF'
# Ghostty Terminal Environment Variables
# These variables ensure proper integration with the desktop environment

# Enable Wayland integration
export GHOSTTY_ENABLE_WAYLAND=1

# Set default terminal for the system
export TERMINAL=ghostty

# Configure Ghostty to use system theme
export GHOSTTY_THEME=auto

# Enable GPU acceleration
export GHOSTTY_GPU_ACCELERATION=1

# Set default shell integration
export GHOSTTY_SHELL_INTEGRATION=bash,zsh,fish

# Configure clipboard integration
export GHOSTTY_CLIPBOARD=wayland

# Set font rendering hints
export GHOSTTY_FONT_HINTING=slight
export GHOSTTY_FONT_ANTIALIAS=1
EOF
    
    log "✓ Environment variables configured"
}

# Function to create Ghostty wrapper script
create_wrapper_script() {
    log "Creating Ghostty wrapper script"
    
    local wrapper_dir="/usr/local/bin"
    local wrapper_file="$wrapper_dir/ghostty-wrapper"
    
    # Create wrapper script with proper environment
    sudo tee "$wrapper_file" > /dev/null << 'EOF'
#!/bin/bash
# Ghostty wrapper script for Voidance desktop environment
# Ensures proper environment setup and integration

# Source desktop environment
if [ -f /etc/voidance/desktop-environment ]; then
    source /etc/voidance/desktop-environment
fi

# Set Ghostty-specific environment
export GHOSTTY_ENABLE_WAYLAND=1
export TERMINAL=ghostty

# Launch Ghostty with configuration
exec ghostty "$@"
EOF
    
    # Make wrapper executable
    sudo chmod +x "$wrapper_file"
    
    log "✓ Ghostty wrapper script created"
}

# Function to configure desktop integration
configure_desktop_integration() {
    log "Configuring desktop integration"
    
    # Update desktop environment configuration to include Ghostty
    local desktop_config="$CONFIG_DIR/desktop/desktop-environment.json"
    
    if [ -f "$desktop_config" ]; then
        # Add Ghostty to applications list if not already present
        if ! jq -e '.applications.terminal' "$desktop_config" >/dev/null 2>&1; then
            jq '.applications += {"terminal": "ghostty"}' "$desktop_config" > "${desktop_config}.tmp"
            mv "${desktop_config}.tmp" "$desktop_config"
        fi
        
        # Update default applications
        jq '.default_applications.terminal = "ghostty.desktop"' "$desktop_config" > "${desktop_config}.tmp"
        mv "${desktop_config}.tmp" "$desktop_config"
        
        log "✓ Desktop environment configuration updated"
    else
        log "⚠ Desktop environment configuration not found, skipping integration"
    fi
}

# Function to setup shell integration
setup_shell_integration() {
    log "Setting up shell integration"
    
    # Create shell integration directory
    local integration_dir="$CONFIG_DIR/ghostty/shell-integration"
    mkdir -p "$integration_dir"
    
    # Create bash integration
    cat > "$integration_dir/bash.bash" << 'EOF'
# Ghostty Bash Integration
# Provides enhanced shell integration for Ghostty terminal

# Set terminal type
export TERM=xterm-256color

# Enable shell integration features
if [[ -n "$GHOSTTY_INTEGRATION" ]]; then
    # Set up command tracking
    export GHOSTTY_SHELL_INTEGRATION=enabled
    
    # Set up prompt integration
    if [[ -n "$PS1" ]]; then
        # Add Ghostty-specific prompt elements if needed
        export PS1="$PS1"
    fi
fi

# Set up aliases for common terminal operations
alias cls='clear'
alias ll='ls -la'
alias la='ls -a'
alias l='ls -CF'
EOF
    
    # Create zsh integration
    cat > "$integration_dir/zsh.zsh" << 'EOF'
# Ghostty Zsh Integration
# Provides enhanced shell integration for Ghostty terminal

# Set terminal type
export TERM=xterm-256color

# Enable shell integration features
if [[ -n "$GHOSTTY_INTEGRATION" ]]; then
    # Set up command tracking
    export GHOSTTY_SHELL_INTEGRATION=enabled
    
    # Set up prompt integration
    autoload -Uz promptinit
    promptinit
fi

# Set up aliases for common terminal operations
alias cls='clear'
alias ll='ls -la'
alias la='ls -a'
alias l='ls -CF'
EOF
    
    log "✓ Shell integration configured"
}

# Function to verify integration
verify_integration() {
    log "Verifying Ghostty integration"
    
    # Check if Ghostty is available
    if command -v ghostty >/dev/null 2>&1; then
        log "✓ Ghostty is installed and available"
    else
        error "Ghostty is not installed or not in PATH"
    fi
    
    # Check if configuration directory exists
    if [ -d "$CONFIG_DIR/applications/ghostty" ]; then
        log "✓ Ghostty configuration directory exists"
    else
        error "Ghostty configuration directory not found"
    fi
    
    # Check if wrapper script exists
    if [ -f "/usr/local/bin/ghostty-wrapper" ]; then
        log "✓ Ghostty wrapper script is installed"
    else
        log "⚠ Ghostty wrapper script not found (may not be needed)"
    fi
    
    log "✓ Integration verification completed"
}

# Main integration function
main() {
    log "Starting Ghostty desktop integration"
    
    setup_environment
    create_wrapper_script
    configure_desktop_integration
    setup_shell_integration
    verify_integration
    
    log "✓ Ghostty desktop integration completed successfully"
}

# Handle script arguments
case "${1:-}" in
    "environment")
        setup_environment
        ;;
    "wrapper")
        create_wrapper_script
        ;;
    "desktop")
        configure_desktop_integration
        ;;
    "shell")
        setup_shell_integration
        ;;
    "verify")
        verify_integration
        ;;
    *)
        main
        ;;
esac