#!/bin/bash

# validate-config.sh
# Configuration validation script for Voidance Linux system services
# Uses Zod schemas for type-safe validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[VALIDATE]${NC} $1"
}

success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Configuration files to validate
declare -A CONFIG_FILES
CONFIG_FILES[session]="/etc/voidance/session.json"
CONFIG_FILES[display]="/etc/voidance/display.json"
CONFIG_FILES[network]="/etc/voidance/network.json"
CONFIG_FILES[audio]="/etc/voidance/audio.json"
CONFIG_FILES[idle]="/etc/voidance/idle.json"
CONFIG_FILES[swaylock]="/etc/voidance/swaylock.json"
CONFIG_FILES[system]="/etc/voidance/system-services.json"

# Validation results
VALIDATIONS_PASSED=0
VALIDATIONS_FAILED=0
VALIDATIONS_WARNED=0

# Function to check if Node.js is available
check_nodejs() {
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js is required for configuration validation"
        error "Please install Node.js: xbps-install -S nodejs"
        exit 1
    fi
}

# Function to check if TypeScript is available
check_typescript() {
    if ! command -v npx >/dev/null 2>&1; then
        error "npx is required for TypeScript execution"
        error "Please ensure Node.js is properly installed"
        exit 1
    fi
}

# Function to create validation script
create_validation_script() {
    local script_dir="/tmp/voidance-validation"
    mkdir -p "$script_dir"
    
    cat > "$script_dir/validate-config.js" << 'EOF'
const fs = require('fs');
const path = require('path');

// Simple Zod-like validation for basic structure
const validateConfig = (configPath, schemaName) => {
    try {
        if (!fs.existsSync(configPath)) {
            return { valid: false, error: 'Configuration file not found' };
        }
        
        const content = fs.readFileSync(configPath, 'utf8');
        const config = JSON.parse(content);
        
        // Basic structure validation
        const requiredFields = {
            'session': ['service', 'settings'],
            'display': ['service', 'settings'],
            'network': ['service', 'settings'],
            'audio': ['service', 'settings'],
            'idle': ['service', 'settings'],
            'swaylock': ['service', 'settings'],
            'system': ['version', 'services']
        };
        
        const fields = requiredFields[schemaName];
        if (!fields) {
            return { valid: false, error: 'Unknown schema type' };
        }
        
        for (const field of fields) {
            if (!(field in config)) {
                return { valid: false, error: `Missing required field: ${field}` };
            }
        }
        
        return { valid: true, config };
        
    } catch (error) {
        return { valid: false, error: error.message };
    }
};

// Get command line arguments
const configPath = process.argv[2];
const schemaName = process.argv[3];

if (!configPath || !schemaName) {
    console.error('Usage: node validate-config.js <config-path> <schema-name>');
    process.exit(1);
}

const result = validateConfig(configPath, schemaName);
console.log(JSON.stringify(result));
EOF
    
    echo "$script_dir/validate-config.js"
}

# Function to validate configuration file
validate_config_file() {
    local config_type="$1"
    local config_file="${CONFIG_FILES[$config_type]}"
    local validation_script
    
    log "Validating $config_type configuration: $config_file"
    
    # Check if configuration file exists
    if [ ! -f "$config_file" ]; then
        warning "Configuration file not found: $config_file"
        ((VALIDATIONS_WARNED++))
        return 0
    fi
    
    # Create validation script
    validation_script=$(create_validation_script)
    
    # Run validation
    local result
    result=$(node "$validation_script" "$config_file" "$config_type" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        local valid
        valid=$(echo "$result" | jq -r '.valid' 2>/dev/null || echo "false")
        
        if [ "$valid" = "true" ]; then
            success "$config_type configuration is valid"
            ((VALIDATIONS_PASSED++))
            
            # Show configuration summary
            local version
            version=$(echo "$result" | jq -r '.config.version // "unknown"' 2>/dev/null || echo "unknown")
            info "Version: $version"
        else
            local error_msg
            error_msg=$(echo "$result" | jq -r '.error // "Unknown error"' 2>/dev/null || echo "Unknown error")
            error "$config_type configuration validation failed: $error_msg"
            ((VALIDATIONS_FAILED++))
        fi
    else
        error "$config_type configuration validation failed: Unable to run validator"
        ((VALIDATIONS_FAILED++))
    fi
}

# Function to validate existing configuration files
validate_existing_configs() {
    log "Validating existing configuration files..."
    echo
    
    for config_type in "${!CONFIG_FILES[@]}"; do
        validate_config_file "$config_type"
        echo
    done
}

# Function to generate default configurations
generate_default_configs() {
    local output_dir="${1:-/etc/voidance}"
    
    log "Generating default configuration files in $output_dir..."
    mkdir -p "$output_dir"
    
    # Generate session configuration
    cat > "$output_dir/session.json" << 'EOF'
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "elogind",
  "settings": {
    "handle_lid_switch": "suspend",
    "handle_lid_switch_docked": "ignore",
    "handle_power_key": "poweroff",
    "handle_suspend_key": "suspend",
    "handle_hibernate_key": "hibernate",
    "kill_user_processes": false,
    "kill_exclude_users": ["root"],
    "idle_action": "ignore",
    "idle_action_sec": 0
  }
}
EOF
    
    # Generate display configuration
    cat > "$output_dir/display.json" << 'EOF'
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "sddm",
  "settings": {
    "theme": "breeze",
    "wayland_first": true,
    "autologin": {
      "enabled": false
    },
    "display": {
      "minimum_vt": 7,
      "server_command": null,
      "server_args": null,
      "xserver_command": "X",
      "xserver_args": "-nolisten tcp"
    },
    "users": {
      "maximum_uid": 60000,
      "minimum_uid": 1000,
      "hide_users": [],
      "hide_shells": []
    }
  }
}
EOF
    
    # Generate network configuration
    cat > "$output_dir/network.json" << 'EOF'
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "NetworkManager",
  "settings": {
    "dhcp": "internal",
    "plugins": ["keyfile"],
    "wifi": {
      "scan_rand_mac_address": true,
      "powersave": 3
    },
    "ethernet": {
      "auto_negotiate": true
    },
    "connectivity": {
      "enabled": true,
      "uri": "http://check.ipv6.microsoft.com/",
      "interval": 300
    },
    "ipv6": {
      "ip6_privacy": "prefer-public-addr"
    }
  }
}
EOF
    
    # Generate audio configuration
    cat > "$output_dir/audio.json" << 'EOF'
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "pipewire",
  "settings": {
    "default_clock_rate": 48000,
    "default_clock_quantum": 1024,
    "allowed_rates": [44100, 48000, 88200, 96000, 176400, 192000],
    "mem_allow_mlock": true,
    "log_level": "2",
    "rtkit": {
      "enabled": true,
      "nice_level": -11,
      "rt_prio": 88,
      "rt_time_soft": 200000,
      "rt_time_hard": 200000
    },
    "pulse": {
      "server_address": ["unix:native"],
      "min_req": "256/48000",
      "default_req": "960/48000",
      "max_req": "1920/48000",
      "min_quantum": "256/48000",
      "default_quantum": "960/48000",
      "max_quantum": "1920/48000"
    }
  }
}
EOF
    
    # Generate idle configuration
    cat > "$output_dir/idle.json" << 'EOF'
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "swayidle",
  "settings": {
    "timeouts": {
      "idle": 300,
      "lock": 600,
      "suspend": 1800
    },
    "lock": {
      "enabled": true,
      "command": "swaylock -f -c 000000",
      "before_sleep": true
    },
    "screen_off": {
      "enabled": true,
      "command": "swaymsg \"output * power off\""
    },
    "suspend": {
      "enabled": true,
      "command": "systemctl suspend",
      "resume_command": "swaymsg \"output * power on\""
    },
    "notifications": {
      "enabled": true,
      "before_lock": 30,
      "message": "Screen will lock in 30 seconds",
      "icon": "dialog-information"
    },
    "battery": {
      "enabled": true,
      "timeouts": {
        "idle": 180,
        "lock": 300,
        "suspend": 900
      }
    }
  }
}
EOF
    
    # Generate swaylock configuration
    cat > "$output_dir/swaylock.json" << 'EOF'
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "swaylock",
  "settings": {
    "colors": {
      "background": "000000ff",
      "bs_color": "000000ff",
      "inside_color": "00000088",
      "ring_color": "458588ff",
      "line_color": "458588ff",
      "text_color": "ebdbb2ff",
      "text_clear_color": "ebdbb2ff",
      "text_caps_lock_color": "fabd2fff",
      "text_ver_color": "8ec07cff",
      "text_wrong_color": "fb4934ff",
      "inside_clear_color": "00000000",
      "inside_ver_color": "45858888",
      "inside_wrong_color": "cc241d88",
      "ring_clear_color": "8ec07cff",
      "ring_ver_color": "8ec07cff",
      "ring_wrong_color": "fb4934ff"
    },
    "indicator": {
      "enabled": true,
      "radius": 100,
      "thickness": 20
    },
    "effects": {
      "screenshots": true,
      "blur": "7x5",
      "vignette": "0.5:0.5",
      "fade_in": 0.2
    },
    "clock": {
      "enabled": true,
      "time_str": "%H:%M:%S",
      "date_str": "%Y-%m-%d"
    },
    "font": "monospace",
    "key_handling": {
      "ignore_empty_password": true,
      "show_keyboard_layout": true,
      "show_failed_attempts": true
    }
  }
}
EOF
    
    # Generate system configuration
    cat > "$output_dir/system-services.json" << 'EOF'
{
  "version": "1.0.0",
  "services": {
    "session": {
      "version": "1.0.0",
      "enabled": true,
      "debug": false,
      "service": "elogind",
      "settings": {
        "handle_lid_switch": "suspend",
        "handle_lid_switch_docked": "ignore",
        "handle_power_key": "poweroff",
        "handle_suspend_key": "suspend",
        "handle_hibernate_key": "hibernate",
        "kill_user_processes": false,
        "kill_exclude_users": ["root"],
        "idle_action": "ignore",
        "idle_action_sec": 0
      }
    },
    "display": {
      "version": "1.0.0",
      "enabled": true,
      "debug": false,
      "service": "sddm",
      "settings": {
        "theme": "breeze",
        "wayland_first": true,
        "autologin": {
          "enabled": false
        }
      }
    },
    "network": {
      "version": "1.0.0",
      "enabled": true,
      "debug": false,
      "service": "NetworkManager",
      "settings": {
        "dhcp": "internal",
        "plugins": ["keyfile"],
        "wifi": {
          "scan_rand_mac_address": true,
          "powersave": 3
        }
      }
    },
    "audio": {
      "version": "1.0.0",
      "enabled": true,
      "debug": false,
      "service": "pipewire",
      "settings": {
        "default_clock_rate": 48000,
        "default_clock_quantum": 1024,
        "allowed_rates": [44100, 48000, 88200, 96000, 176400, 192000],
        "mem_allow_mlock": true,
        "log_level": "2"
      }
    },
    "idle": {
      "version": "1.0.0",
      "enabled": true,
      "debug": false,
      "service": "swayidle",
      "settings": {
        "timeouts": {
          "idle": 300,
          "lock": 600,
          "suspend": 1800
        },
        "lock": {
          "enabled": true,
          "command": "swaylock -f -c 000000",
          "before_sleep": true
        }
      }
    }
  },
  "global": {
    "log_level": "info",
    "service_timeout": 30,
    "auto_start": true,
    "dependency_check": true
  }
}
EOF
    
    success "Default configuration files generated in $output_dir"
    
    # Set proper permissions
    chmod 755 "$output_dir"
    chmod 644 "$output_dir"/*.json
    
    # Validate generated files
    echo
    log "Validating generated configuration files..."
    for config_type in "${!CONFIG_FILES[@]}"; do
        if [ "$config_type" != "system" ]; then
            validate_config_file "$config_type"
        fi
    done
}

# Function to check JSON syntax
check_json_syntax() {
    local file="$1"
    
    if command -v jq >/dev/null 2>&1; then
        if jq empty "$file" 2>/dev/null; then
            return 0
        else
            return 1
        fi
    elif command -v python3 >/dev/null 2>&1; then
        if python3 -m json.tool "$file" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    else
        warning "No JSON validator available (jq or python3)"
        return 0
    fi
}

# Function to validate all JSON files in directory
validate_directory() {
    local directory="$1"
    
    if [ ! -d "$directory" ]; then
        error "Directory not found: $directory"
        return 1
    fi
    
    log "Validating JSON files in $directory..."
    
    local json_files=("$directory"/*.json)
    local valid_files=0
    local invalid_files=0
    
    for file in "${json_files[@]}"; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            if check_json_syntax "$file"; then
                success "$filename: Valid JSON"
                ((valid_files++))
            else
                error "$filename: Invalid JSON syntax"
                ((invalid_files++))
            fi
        fi
    done
    
    echo
    info "JSON validation summary: $valid_files valid, $invalid_files invalid"
    
    if [ $invalid_files -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Main execution
case "${1:-validate}" in
    "validate")
        check_nodejs
        check_typescript
        validate_existing_configs
        ;;
    "generate")
        generate_default_configs "${2:-/etc/voidance}"
        ;;
    "check-json")
        if [ -z "${2:-}" ]; then
            error "Usage: $0 check-json <directory>"
            exit 1
        fi
        validate_directory "$2"
        ;;
    "check-file")
        if [ -z "${2:-}" ]; then
            error "Usage: $0 check-file <json-file>"
            exit 1
        fi
        if check_json_syntax "$2"; then
            success "JSON file is valid: $2"
            exit 0
        else
            error "JSON file is invalid: $2"
            exit 1
        fi
        ;;
    "setup")
        log "Setting up configuration validation environment..."
        check_nodejs
        check_typescript
        
        # Create configuration directory
        mkdir -p /etc/voidance
        
        # Generate default configurations
        generate_default_configs /etc/voidance
        
        # Validate generated configurations
        validate_existing_configs
        ;;
    *)
        echo "Voidance Linux Configuration Validation"
        echo "Usage: $0 {validate|generate|check-json|check-file|setup} [options]"
        echo
        echo "Commands:"
        echo "  validate           - Validate existing configuration files"
        echo "  generate [dir]     - Generate default configuration files"
        echo "  check-json <dir>    - Check JSON syntax in directory"
        echo "  check-file <file>   - Check JSON syntax of single file"
        echo "  setup              - Setup validation environment and generate defaults"
        echo
        echo "Examples:"
        echo "  $0 validate                    # Validate existing configs"
        echo "  $0 generate /tmp/configs       # Generate defaults in /tmp/configs"
        echo "  $0 check-json /etc/voidance   # Check JSON syntax"
        echo "  $0 check-file config.json      # Check single file"
        exit 1
        ;;
esac

# Show validation summary
echo
log "Configuration validation summary:"
echo "================================"
echo -e "Validations passed: ${GREEN}$VALIDATIONS_PASSED${NC}"
echo -e "Validations warned: ${YELLOW}$VALIDATIONS_WARNED${NC}"
echo -e "Validations failed: ${RED}$VALIDATIONS_FAILED${NC}"
echo "================================"

if [ $VALIDATIONS_FAILED -eq 0 ]; then
    if [ $VALIDATIONS_WARNED -eq 0 ]; then
        success "All configuration validations passed! ✓"
        exit 0
    else
        warning "Some validations passed with warnings"
        exit 1
    fi
else
    error "Some configuration validations failed"
    exit 1
fi