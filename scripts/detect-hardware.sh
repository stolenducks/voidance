#!/bin/bash

# Hardware Detection Script for Voidance Linux
# Detects GPU, monitor, input devices and optimizes desktop environment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration paths
CONFIG_DIR="/etc/voidance"
HARDWARE_CONFIG="$CONFIG_DIR/hardware.json"
DESKTOP_CONFIG="$CONFIG_DIR/desktop"

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

# Function to detect GPU
detect_gpu() {
    print_status "INFO" "Detecting GPU hardware..."
    
    local gpu_info=""
    local gpu_type=""
    local gpu_driver=""
    
    # Check for NVIDIA GPUs
    if lspci | grep -qi "nvidia"; then
        gpu_type="nvidia"
        gpu_driver="nvidia"
        gpu_info=$(lspci | grep -i nvidia | head -1)
        print_status "OK" "NVIDIA GPU detected: $gpu_info"
        
    # Check for AMD GPUs
    elif lspci | grep -qi "amd\|radeon"; then
        gpu_type="amd"
        gpu_driver="amdgpu"
        gpu_info=$(lspci | grep -i -e "amd" -e "radeon" | head -1)
        print_status "OK" "AMD GPU detected: $gpu_info"
        
    # Check for Intel GPUs
    elif lspci | grep -qi "intel.*vga\|intel.*display"; then
        gpu_type="intel"
        gpu_driver="i915"
        gpu_info=$(lspci | grep -i "intel.*vga\|intel.*display" | head -1)
        print_status "OK" "Intel GPU detected: $gpu_info"
        
    # Check for other GPUs
    elif lspci | grep -qi "vga\|display"; then
        gpu_type="unknown"
        gpu_driver="modesetting"
        gpu_info=$(lspci | grep -i "vga\|display" | head -1)
        print_status "WARN" "Unknown GPU detected: $gpu_info"
        
    else
        gpu_type="none"
        gpu_driver="software"
        print_status "WARN" "No GPU detected, using software rendering"
    fi
    
    # Export GPU information
    export DETECTED_GPU_TYPE="$gpu_type"
    export DETECTED_GPU_DRIVER="$gpu_driver"
    export DETECTED_GPU_INFO="$gpu_info"
}

# Function to detect monitors
detect_monitors() {
    print_status "INFO" "Detecting monitor configuration..."
    
    local monitors=()
    local primary_monitor=""
    
    # Use xrandr if available, otherwise try other methods
    if command -v xrandr >/dev/null 2>&1; then
        while IFS= read -r line; do
            if [[ $line =~ ^[[:space:]]*([A-Za-z0-9\-]+)[[:space:]]+connected ]]; then
                local monitor_name="${BASH_REMATCH[1]}"
                monitors+=("$monitor_name")
                
                if [[ $line =~ primary ]]; then
                    primary_monitor="$monitor_name"
                fi
                
                print_status "OK" "Monitor detected: $monitor_name"
            fi
        done < <(xrandr --query 2>/dev/null || true)
    fi
    
    # Fallback to /sys/class/drm for Wayland
    if [ ${#monitors[@]} -eq 0 ]; then
        for drm_device in /sys/class/drm/card*/card*-*; do
            if [ -e "$drm_device/status" ] && [ "$(cat "$drm_device/status")" = "connected" ]; then
                local monitor_name=$(basename "$drm_device")
                monitors+=("$monitor_name")
                print_status "OK" "Monitor detected: $monitor_name"
            fi
        done
    fi
    
    # Set primary monitor if not detected
    if [ -z "$primary_monitor" ] && [ ${#monitors[@]} -gt 0 ]; then
        primary_monitor="${monitors[0]}"
    fi
    
    export DETECTED_MONITORS=$(IFS=','; echo "${monitors[*]}")
    export DETECTED_PRIMARY_MONITOR="$primary_monitor"
    export DETECTED_MONITOR_COUNT=${#monitors[@]}
}

# Function to detect input devices
detect_input_devices() {
    print_status "INFO" "Detecting input devices..."
    
    local keyboards=()
    local mice=()
    local touchpads=()
    local touchscreens=()
    
    # Parse input devices
    while IFS= read -r line; do
        if [[ $line =~ ^[Nn]ame:[[:space:]]*\"([^\"]+)\" ]]; then
            local device_name="${BASH_REMATCH[1]}"
            local device_type=""
            
            # Determine device type based on name
            if [[ $device_name =~ [Kk]eyboard|[Kk]eypad ]]; then
                keyboards+=("$device_name")
                device_type="keyboard"
            elif [[ $device_name =~ [Mm]ouse|[Pp]ointer ]]; then
                mice+=("$device_name")
                device_type="mouse"
            elif [[ $device_name =~ [Tt]ouchpad ]]; then
                touchpads+=("$device_name")
                device_type="touchpad"
            elif [[ $device_name =~ [Tt]ouchscreen ]]; then
                touchscreens+=("$device_name")
                device_type="touchscreen"
            fi
            
            if [ -n "$device_type" ]; then
                print_status "OK" "$device_type detected: $device_name"
            fi
        fi
    done < <(xinput list 2>/dev/null || libinput list-devices 2>/dev/null || echo "")
    
    export DETECTED_KEYBOARDS=$(IFS=','; echo "${keyboards[*]}")
    export DETECTED_MICE=$(IFS=','; echo "${mice[*]}")
    export DETECTED_TOUCHPADS=$(IFS=','; echo "${touchpads[*]}")
    export DETECTED_TOUCHSCREENS=$(IFS=','; echo "${touchscreens[*]}")
}

# Function to detect system performance class
detect_performance_class() {
    print_status "INFO" "Detecting system performance class..."
    
    local cpu_cores=$(nproc)
    local memory_gb=$(free -g | awk '/^Mem:/{print $2}')
    local performance_class="low"
    
    # Determine performance class based on hardware
    if [ "$cpu_cores" -ge 8 ] && [ "$memory_gb" -ge 16 ]; then
        performance_class="high"
        print_status "OK" "High performance system detected ($cpu_cores cores, ${memory_gb}GB RAM)"
    elif [ "$cpu_cores" -ge 4 ] && [ "$memory_gb" -ge 8 ]; then
        performance_class="medium"
        print_status "OK" "Medium performance system detected ($cpu_cores cores, ${memory_gb}GB RAM)"
    else
        performance_class="low"
        print_status "OK" "Low performance system detected ($cpu_cores cores, ${memory_gb}GB RAM)"
    fi
    
    export DETECTED_PERFORMANCE_CLASS="$performance_class"
}

# Function to generate hardware-specific Niri configuration
generate_niri_config() {
    print_status "INFO" "Generating hardware-specific Niri configuration..."
    
    local config_file="$DESKTOP_CONFIG/niri/hardware.kdl"
    local temp_config="/tmp/niri-hardware.kdl"
    
    cat > "$temp_config" << EOF
// Hardware-specific Niri configuration
// Generated by hardware detection script on $(date)

// Output configuration based on detected monitors
EOF
    
    # Add monitor configurations
    IFS=',' read -ra MONITOR_ARRAY <<< "$DETECTED_MONITORS"
    for monitor in "${MONITOR_ARRAY[@]}"; do
        if [ -n "$monitor" ]; then
            cat >> "$temp_config" << EOF
output "$monitor" {
    // Auto-configure detected monitor
    scale 1.0
    position x=0 y=0
    adaptive_sync false
    background-color "#24273a"
}

EOF
        fi
    done
    
    # Add GPU-specific optimizations
    case "$DETECTED_GPU_TYPE" in
        "nvidia")
            cat >> "$temp_config" << EOF
// NVIDIA-specific optimizations
environment {
    __GLX_VENDOR_LIBRARY_NAME "nvidia"
    __NV_PRIME_RENDER_OFFLOAD "1"
    __VK_LAYER_NV_optimus "NVIDIA_only"
}

EOF
            ;;
        "amd")
            cat >> "$temp_config" << EOF
// AMD-specific optimizations
environment {
    AMD_VULKAN_ICD "RADV"
    VK_ICD_FILENAMES "/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
}

EOF
            ;;
        "intel")
            cat >> "$temp_config" << EOF
// Intel-specific optimizations
environment {
    INTEL_VK_ICD_FILENAMES "/usr/share/vulkan/icd.d/intel_icd.x86_64.json"
}

EOF
            ;;
    esac
    
    # Add performance-specific settings
    case "$DETECTED_PERFORMANCE_CLASS" in
        "high")
            cat >> "$temp_config" << EOF
// High performance settings
layout {
    animations-enabled true
    render-timer true
}

EOF
            ;;
        "low")
            cat >> "$temp_config" << EOF
// Low performance settings
layout {
    animations-enabled false
    render-timer false
}

EOF
            ;;
    esac
    
    # Install the configuration
    mkdir -p "$(dirname "$config_file")"
    mv "$temp_config" "$config_file"
    print_status "OK" "Hardware-specific Niri configuration generated: $config_file"
}

# Function to generate hardware-specific Waybar configuration
generate_waybar_config() {
    print_status "INFO" "Generating hardware-specific Waybar configuration..."
    
    local config_file="$DESKTOP_CONFIG/waybar/hardware.json"
    local temp_config="/tmp/waybar-hardware.json"
    
    # Start with basic configuration
    cat > "$temp_config" << EOF
{
    "modules-right": [
EOF
    
    # Add battery module for laptops
    if [ -d /sys/class/power_supply/BAT* ] 2>/dev/null; then
        echo '        "battery",' >> "$temp_config"
        print_status "OK" "Battery detected, adding battery module"
    fi
    
    # Add backlight module for laptops with backlight control
    if [ -d /sys/class/backlight ] && [ "$(ls -A /sys/class/backlight)" ]; then
        echo '        "backlight",' >> "$temp_config"
        print_status "OK" "Backlight control detected, adding backlight module"
    fi
    
    # Add temperature module if sensors are available
    if command -v sensors >/dev/null 2>&1 && sensors >/dev/null 2>&1; then
        echo '        "temperature",' >> "$temp_config"
        print_status "OK" "Temperature sensors detected, adding temperature module"
    fi
    
    # Complete the configuration
    cat >> "$temp_config" << EOF
        "pulseaudio",
        "network",
        "tray"
    ]
}
EOF
    
    # Install the configuration
    mkdir -p "$(dirname "$config_file")"
    mv "$temp_config" "$config_file"
    print_status "OK" "Hardware-specific Waybar configuration generated: $config_file"
}

# Function to create hardware profile JSON
create_hardware_profile() {
    print_status "INFO" "Creating hardware profile..."
    
    mkdir -p "$(dirname "$HARDWARE_CONFIG")"
    
    cat > "$HARDWARE_CONFIG" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system": {
        "hostname": "$(hostname)",
        "kernel": "$(uname -r)",
        "architecture": "$(uname -m)"
    },
    "hardware": {
        "gpu": {
            "type": "$DETECTED_GPU_TYPE",
            "driver": "$DETECTED_GPU_DRIVER",
            "info": "$DETECTED_GPU_INFO"
        },
        "monitors": {
            "count": $DETECTED_MONITOR_COUNT,
            "primary": "$DETECTED_PRIMARY_MONITOR",
            "all": "$DETECTED_MONITORS"
        },
        "input": {
            "keyboards": "$DETECTED_KEYBOARDS",
            "mice": "$DETECTED_MICE",
            "touchpads": "$DETECTED_TOUCHPADS",
            "touchscreens": "$DETECTED_TOUCHSCREENS"
        },
        "performance": {
            "class": "$DETECTED_PERFORMANCE_CLASS",
            "cpu_cores": $(nproc),
            "memory_gb": $(free -g | awk '/^Mem:/{print $2}')
        }
    },
    "optimizations": {
        "niri_config": "$DESKTOP_CONFIG/niri/hardware.kdl",
        "waybar_config": "$DESKTOP_CONFIG/waybar/hardware.json"
    }
}
EOF
    
    print_status "OK" "Hardware profile created: $HARDWARE_CONFIG"
}

# Function to apply hardware optimizations
apply_optimizations() {
    print_status "INFO" "Applying hardware optimizations..."
    
    # Generate configurations
    generate_niri_config
    generate_waybar_config
    
    # Create hardware profile
    create_hardware_profile
    
    # Set appropriate environment variables
    local env_file="/etc/environment.d/voidance-hardware.conf"
    mkdir -p "$(dirname "$env_file")"
    
    cat > "$env_file" << EOF
# Hardware-specific environment variables for Voidance Linux
# Generated by hardware detection script

GPU_TYPE=$DETECTED_GPU_TYPE
GPU_DRIVER=$DETECTED_GPU_DRIVER
PERFORMANCE_CLASS=$DETECTED_PERFORMANCE_CLASS
PRIMARY_MONITOR=$DETECTED_PRIMARY_MONITOR
EOF
    
    print_status "OK" "Hardware optimizations applied successfully"
}

# Function to show hardware summary
show_summary() {
    print_status "INFO" "Hardware Detection Summary"
    echo "=================================="
    echo "GPU Type: $DETECTED_GPU_TYPE"
    echo "GPU Driver: $DETECTED_GPU_DRIVER"
    echo "GPU Info: $DETECTED_GPU_INFO"
    echo ""
    echo "Monitor Count: $DETECTED_MONITOR_COUNT"
    echo "Primary Monitor: $DETECTED_PRIMARY_MONITOR"
    echo "All Monitors: $DETECTED_MONITORS"
    echo ""
    echo "Performance Class: $DETECTED_PERFORMANCE_CLASS"
    echo "CPU Cores: $(nproc)"
    echo "Memory: $(free -h | awk '/^Mem:/{print $2}')"
    echo ""
    echo "Keyboards: $DETECTED_KEYBOARDS"
    echo "Mice: $DETECTED_MICE"
    echo "Touchpads: $DETECTED_TOUCHPADS"
    echo "Touchscreens: $DETECTED_TOUCHSCREENS"
    echo "=================================="
}

# Function to run full detection
run_detection() {
    print_status "INFO" "Starting hardware detection for Voidance Linux..."
    
    detect_gpu
    detect_monitors
    detect_input_devices
    detect_performance_class
    
    if [ "${1:-apply}" = "apply" ]; then
        apply_optimizations
    fi
    
    show_summary
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] COMMAND

Commands:
    detect          Run hardware detection only
    apply           Run detection and apply optimizations (default)
    summary         Show current hardware profile
    help            Show this help message

Options:
    --dry-run       Show what would be done without applying changes
    --force         Force re-detection even if profile exists

Examples:
    $0 detect                      # Run detection only
    $0 apply                       # Run detection and apply optimizations
    $0 summary                     # Show current hardware profile
    $0 --dry-run apply             # Preview optimizations without applying

EOF
}

# Main function
main() {
    local action="${1:-apply}"
    local dry_run="${DRY_RUN:-false}"
    local force="${FORCE:-false}"
    
    # Check if running as root for system-wide changes
    if [ "$action" = "apply" ] && [ "$EUID" -ne 0 ]; then
        print_status "FAIL" "Hardware optimization requires root privileges"
        exit 1
    fi
    
    case "$action" in
        "detect")
            run_detection "detect-only"
            ;;
        "apply")
            if [ "$dry_run" = "true" ]; then
                print_status "INFO" "DRY RUN: Would detect hardware and apply optimizations"
                run_detection "detect-only"
            else
                run_detection "apply"
            fi
            ;;
        "summary")
            if [ -f "$HARDWARE_CONFIG" ]; then
                print_status "INFO" "Current hardware profile:"
                cat "$HARDWARE_CONFIG" | jq '.' 2>/dev/null || cat "$HARDWARE_CONFIG"
            else
                print_status "WARN" "No hardware profile found. Run '$0 apply' first."
            fi
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
        --dry-run)
            export DRY_RUN=true
            shift
            ;;
        --force)
            export FORCE=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Run main function with remaining arguments
main "$@"