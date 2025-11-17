#!/bin/bash

# Hardware Detection and Optimization Script for Voidance Linux
# Detects hardware and applies appropriate optimizations for desktop environment

set -euo pipefail

# Configuration paths
SCRIPT_DIR="$(dirname "$0")"
CONFIG_DIR="$(dirname "$0")/../config"
HARDWARE_CONFIG_DIR="$CONFIG_DIR/hardware"
NIRI_CONFIG_DIR="$CONFIG_DIR/desktop/niri"
WAYBAR_CONFIG_DIR="$CONFIG_DIR/desktop/waybar"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Hardware detection functions
detect_gpu() {
    log_info "Detecting GPU hardware..."
    
    local gpu_info=""
    local gpu_vendor=""
    local gpu_driver=""
    
    # Try to get GPU information from various sources
    if command -v lspci >/dev/null 2>&1; then
        gpu_info=$(lspci -nn | grep -i vga || lspci -nn | grep -i display || echo "")
    fi
    
    if command -v lshw >/dev/null 2>&1; then
        gpu_info=$(lshw -c display 2>/dev/null | grep -A5 "product:" || echo "$gpu_info")
    fi
    
    # Determine GPU vendor
    if echo "$gpu_info" | grep -iq "intel\|intel corporation"; then
        gpu_vendor="intel"
        gpu_driver="i915"
    elif echo "$gpu_info" | grep -iq "nvidia\|nvidia corporation"; then
        gpu_vendor="nvidia"
        gpu_driver="nvidia"
    elif echo "$gpu_info" | grep -iq "amd\|advanced micro devices\|radeon"; then
        gpu_vendor="amd"
        gpu_driver="amdgpu"
    else
        gpu_vendor="unknown"
        gpu_driver="generic"
    fi
    
    log_success "GPU detected: $gpu_vendor ($gpu_driver)"
    echo "$gpu_vendor"
}

detect_cpu() {
    log_info "Detecting CPU hardware..."
    
    local cpu_vendor=""
    local cpu_cores=""
    local cpu_threads=""
    
    if [ -f /proc/cpuinfo ]; then
        cpu_vendor=$(grep "vendor_id" /proc/cpuinfo | head -1 | cut -d: -f2 | tr -d ' ' || echo "unknown")
        cpu_cores=$(grep "cpu cores" /proc/cpuinfo | head -1 | cut -d: -f2 | tr -d ' ' || echo "0")
        cpu_threads=$(grep "processor" /proc/cpuinfo | wc -l || echo "0")
    fi
    
    # Normalize vendor names
    case "$cpu_vendor" in
        "GenuineIntel")
            cpu_vendor="intel"
            ;;
        "AuthenticAMD")
            cpu_vendor="amd"
            ;;
        *)
            cpu_vendor="unknown"
            ;;
    esac
    
    log_success "CPU detected: $cpu_vendor ($cpu_cores cores, $cpu_threads threads)"
    echo "$cpu_vendor"
}

detect_memory() {
    log_info "Detecting memory configuration..."
    
    local total_memory="0"
    
    if [ -f /proc/meminfo ]; then
        total_memory=$(grep "MemTotal" /proc/meminfo | awk '{print int($2/1024/1024)}' || echo "0")
    fi
    
    log_success "Memory detected: ${total_memory}GB"
    echo "$total_memory"
}

detect_monitors() {
    log_info "Detecting monitor configuration..."
    
    local monitor_count=0
    local primary_monitor=""
    
    # Try to detect connected monitors
    if command -v wlr-randr >/dev/null 2>&1; then
        monitor_count=$(wlr-randr 2>/dev/null | grep -c "Enabled" || echo "0")
        primary_monitor=$(wlr-randr 2>/dev/null | grep "Enabled" | head -1 | cut -d: -f1 | tr -d ' ' || echo "")
    elif [ -d /sys/class/drm ]; then
        monitor_count=$(find /sys/class/drm -name "card*-*" -name "*-*" | wc -l || echo "0")
        primary_monitor=$(find /sys/class/drm -name "card*-*" -name "*-*" | head -1 | xargs basename 2>/dev/null || echo "")
    fi
    
    log_success "Monitors detected: $monitor_count (primary: $primary_monitor)"
    echo "$monitor_count:$primary_monitor"
}

detect_laptop() {
    log_info "Detecting if this is a laptop..."
    
    local is_laptop=false
    
    # Check for laptop indicators
    if [ -d /sys/class/power_supply/BAT* ] 2>/dev/null; then
        is_laptop=true
    elif [ -f /sys/class/dmi/id/chassis_type ]; then
        chassis_type=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "0")
        # Chassis type 8, 9, 10, 14 are portable/laptop types
        case "$chassis_type" in
            8|9|10|14)
                is_laptop=true
                ;;
        esac
    fi
    
    if [ "$is_laptop" = true ]; then
        log_success "Laptop detected"
    else
        log_success "Desktop detected"
    fi
    
    if [ "$is_laptop" = true ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Optimization functions
optimize_niri_config() {
    local gpu_vendor="$1"
    local is_laptop="$2"
    local monitor_info="$3"
    local monitor_count=$(echo "$monitor_info" | cut -d: -f1)
    local primary_monitor=$(echo "$monitor_info" | cut -d: -f2)
    
    log_info "Optimizing Niri configuration for $gpu_vendor GPU..."
    
    local config_file="$NIRI_CONFIG_DIR/config.kdl"
    local optimized_config="$HARDWARE_CONFIG_DIR/niri-optimized.kdl"
    
    if [ ! -f "$config_file" ]; then
        log_warning "Niri configuration file not found: $config_file"
        return 1
    fi
    
    # Create hardware-specific optimizations
    mkdir -p "$HARDWARE_CONFIG_DIR"
    
    # Start with base configuration
    cp "$config_file" "$optimized_config"
    
    # Apply GPU-specific optimizations
    case "$gpu_vendor" in
        "intel")
            # Intel GPU optimizations
            cat >> "$optimized_config" << 'EOF'

// Intel GPU optimizations
output "eDP-1" {
    adaptive-sync true
}
EOF
            ;;
        "nvidia")
            # NVIDIA GPU optimizations
            cat >> "$optimized_config" << 'EOF'

// NVIDIA GPU optimizations
environment {
    __GLX_GSYNC_ALLOWED "0"
    __GL_VRR_ALLOWED "0"
    vblank_mode "0"
}
EOF
            ;;
        "amd")
            # AMD GPU optimizations
            cat >> "$optimized_config" << 'EOF'

// AMD GPU optimizations
environment {
    RADV_PERFTEST "sam"
}
EOF
            ;;
    esac
    
    # Apply laptop-specific optimizations
    if [ "$is_laptop" = "true" ]; then
        cat >> "$optimized_config" << 'EOF'

// Laptop-specific optimizations
input {
    touchpad {
        natural-scroll true
        tap-to-click true
        disable-while-typing true
        middle-emulation true
    }
}

// Power saving optimizations
environment {
    VBLANK_MODE "0"
}
EOF
    fi
    
    # Apply multi-monitor optimizations
    if [ "$monitor_count" -gt 1 ]; then
        cat >> "$optimized_config" << 'EOF'

// Multi-monitor optimizations
layout {
    gaps 12
}
EOF
    fi
    
    log_success "Niri configuration optimized: $optimized_config"
}

optimize_waybar_config() {
    local is_laptop="$1"
    
    log_info "Optimizing Waybar configuration..."
    
    local config_file="$WAYBAR_CONFIG_DIR/config"
    local optimized_config="$HARDWARE_CONFIG_DIR/waybar-optimized.json"
    
    if [ ! -f "$config_file" ]; then
        log_warning "Waybar configuration file not found: $config_file"
        return 1
    fi
    
    # Create optimized configuration
    mkdir -p "$HARDWARE_CONFIG_DIR"
    cp "$config_file" "$optimized_config"
    
    # Apply laptop-specific optimizations (add battery module if not present)
    if [ "$is_laptop" = "true" ]; then
        # Check if battery module is already in modules_right
        if ! grep -q '"battery"' "$optimized_config"; then
            # Add battery module to modules_right
            sed -i 's/"tray"/"battery",\n        "tray"/' "$optimized_config"
            log_success "Added battery module to Waybar configuration"
        fi
    fi
    
    log_success "Waybar configuration optimized: $optimized_config"
}

create_performance_profile() {
    local gpu_vendor="$1"
    local cpu_vendor="$2"
    local memory_gb="$3"
    local is_laptop="$4"
    
    log_info "Creating performance profile..."
    
    local profile_file="$HARDWARE_CONFIG_DIR/performance-profile.conf"
    local performance_level="balanced"
    
    # Determine performance level based on hardware
    if [ "$memory_gb" -ge 16 ] && [ "$cpu_vendor" != "unknown" ]; then
        performance_level="high"
    elif [ "$memory_gb" -lt 4 ]; then
        performance_level="low"
    fi
    
    if [ "$is_laptop" = "true" ]; then
        performance_level="${performance_level}-power"
    fi
    
    cat > "$profile_file" << EOF
# Hardware Performance Profile for Voidance Linux
# Generated on $(date)

# Hardware Information
GPU_VENDOR="$gpu_vendor"
CPU_VENDOR="$cpu_vendor"
MEMORY_GB="$memory_gb"
IS_LAPTOP="$is_laptop"
PERFORMANCE_LEVEL="$performance_level"

# Performance Settings
EOF
    
    # Add performance settings based on level
    case "$performance_level" in
        "high"|"high-power")
            cat >> "$profile_file" << 'EOF'
# High performance settings
export VBLANK_MODE=0
export __GLX_GSYNC_ALLOWED=0
export __GL_VRR_ALLOWED=0
export RADV_PERFTEST=sam
export MESA_GL_VERSION_OVERRIDE=4.6
EOF
            ;;
        "low"|"low-power")
            cat >> "$profile_file" << 'EOF'
# Low performance settings (power saving)
export VBLANK_MODE=1
export MESA_GL_VERSION_OVERRIDE=3.3
EOF
            ;;
        *)
            cat >> "$profile_file" << 'EOF'
# Balanced performance settings
export VBLANK_MODE=0
EOF
            ;;
    esac
    
    # Add laptop-specific settings
    if [ "$is_laptop" = "true" ]; then
        cat >> "$profile_file" << 'EOF'

# Laptop power management
export POWER_SUPPLY_ON_AC=1
export POWER_SUPPLY_ON_BATTERY=0
EOF
    fi
    
    # Add GPU-specific settings
    case "$gpu_vendor" in
        "intel")
            cat >> "$profile_file" << 'EOF'

# Intel GPU settings
export INTEL_DEBUG=bat
EOF
            ;;
        "nvidia")
            cat >> "$profile_file" << 'EOF'

# NVIDIA GPU settings
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
EOF
            ;;
        "amd")
            cat >> "$profile_file" << 'EOF'

# AMD GPU settings
export RADV_DEBUG=nomeshshaders
EOF
            ;;
    esac
    
    log_success "Performance profile created: $profile_file"
}

create_hardware_report() {
    local gpu_vendor="$1"
    local cpu_vendor="$2"
    local memory_gb="$3"
    local monitor_info="$4"
    local is_laptop="$5"
    local monitor_count=$(echo "$monitor_info" | cut -d: -f1)
    local primary_monitor=$(echo "$monitor_info" | cut -d: -f2)
    
    log_info "Creating hardware report..."
    
    local report_file="$HARDWARE_CONFIG_DIR/hardware-report.txt"
    
    cat > "$report_file" << EOF
Voidance Linux Hardware Report
Generated on: $(date)

========================================
SYSTEM INFORMATION
========================================

GPU Vendor: $gpu_vendor
CPU Vendor: $cpu_vendor
Total Memory: ${memory_gb}GB
System Type: $([ "$is_laptop" = "true" ] && echo "Laptop" || echo "Desktop")
Monitor Count: $monitor_count
Primary Monitor: $primary_monitor

========================================
DETECTED HARDWARE
========================================

EOF
    
    # Add detailed hardware information
    if command -v lspci >/dev/null 2>&1; then
        echo "PCI Devices:" >> "$report_file"
        lspci -nn >> "$report_file" 2>&1
        echo "" >> "$report_file"
    fi
    
    if command -v lsusb >/dev/null 2>&1; then
        echo "USB Devices:" >> "$report_file"
        lsusb >> "$report_file" 2>&1
        echo "" >> "$report_file"
    fi
    
    if [ -f /proc/cpuinfo ]; then
        echo "CPU Information:" >> "$report_file"
        grep -E "(model name|processor|cpu MHz)" /proc/cpuinfo | head -10 >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    if [ -f /proc/meminfo ]; then
        echo "Memory Information:" >> "$report_file"
        grep -E "(MemTotal|MemAvailable|SwapTotal)" /proc/meminfo >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

========================================
OPTIMIZATIONS APPLIED
========================================

GPU Optimizations: $gpu_vendor
CPU Optimizations: $cpu_vendor
Memory Optimizations: Based on ${memory_gb}GB
System Type Optimizations: $([ "$is_laptop" = "true" ] && echo "Laptop" || echo "Desktop")
Monitor Optimizations: $monitor_count monitor(s)

========================================
RECOMMENDATIONS
========================================

EOF
    
    # Add recommendations based on hardware
    if [ "$memory_gb" -lt 4 ]; then
        echo "- Consider upgrading memory for better performance" >> "$report_file"
    fi
    
    if [ "$gpu_vendor" = "unknown" ]; then
        echo "- GPU detection failed, manual configuration may be required" >> "$report_file"
    fi
    
    if [ "$is_laptop" = "true" ]; then
        echo "- Enable power saving features for better battery life" >> "$report_file"
        echo "- Consider installing TLP for advanced power management" >> "$report_file"
    fi
    
    if [ "$monitor_count" -gt 1 ]; then
        echo "- Multi-monitor setup detected, configure display layout in Niri" >> "$report_file"
    fi
    
    log_success "Hardware report created: $report_file"
}

apply_optimizations() {
    local gpu_vendor="$1"
    local cpu_vendor="$2"
    local memory_gb="$3"
    local monitor_info="$4"
    local is_laptop="$5"
    
    log_info "Applying hardware optimizations..."
    
    # Create hardware config directory
    mkdir -p "$HARDWARE_CONFIG_DIR"
    
    # Optimize configurations
    optimize_niri_config "$gpu_vendor" "$is_laptop" "$monitor_info"
    optimize_waybar_config "$is_laptop"
    
    # Create performance profile
    create_performance_profile "$gpu_vendor" "$cpu_vendor" "$memory_gb" "$is_laptop"
    
    # Create hardware report
    create_hardware_report "$gpu_vendor" "$cpu_vendor" "$memory_gb" "$monitor_info" "$is_laptop"
    
    log_success "Hardware optimizations applied successfully"
}

# Function to show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] COMMAND

Commands:
    detect          Detect hardware and show information
    optimize        Apply hardware optimizations
    report          Generate hardware report
    profile         Show current performance profile
    help            Show this help message

Options:
    --user          Apply optimizations for current user only
    --dry-run       Show what would be done without executing

Examples:
    $0 detect                       # Detect hardware
    $0 optimize                     # Apply optimizations
    $0 report                       # Generate report
    $0 --user optimize              # Apply user optimizations only

EOF
}

# Main function
main() {
    local action="${1:-detect}"
    local user_mode="${USER_MODE:-false}"
    local dry_run="${DRY_RUN:-false}"
    
    # Detect hardware
    local gpu_vendor=$(detect_gpu)
    local cpu_vendor=$(detect_cpu)
    local memory_gb=$(detect_memory)
    local monitor_info=$(detect_monitors)
    local is_laptop=$(detect_laptop)
    
    case "$action" in
        "detect")
            echo ""
            log_info "=== Hardware Detection Results ==="
            log_info "GPU: $gpu_vendor"
            log_info "CPU: $cpu_vendor"
            log_info "Memory: ${memory_gb}GB"
            log_info "System Type: $([ "$is_laptop" = "true" ] && echo "Laptop" || echo "Desktop")"
            log_info "Monitors: $(echo "$monitor_info" | cut -d: -f1)"
            echo ""
            ;;
        "optimize")
            if [ "$dry_run" = "false" ]; then
                apply_optimizations "$gpu_vendor" "$cpu_vendor" "$memory_gb" "$monitor_info" "$is_laptop"
                log_success ""
                log_success "Hardware optimization completed!"
                log_info "Optimized configurations are available in: $HARDWARE_CONFIG_DIR"
            else
                log_info "DRY RUN: Would apply optimizations for $gpu_vendor GPU, $cpu_vendor CPU, ${memory_gb}GB memory"
            fi
            ;;
        "report")
            create_hardware_report "$gpu_vendor" "$cpu_vendor" "$memory_gb" "$monitor_info" "$is_laptop"
            log_success "Hardware report generated: $HARDWARE_CONFIG_DIR/hardware-report.txt"
            ;;
        "profile")
            if [ -f "$HARDWARE_CONFIG_DIR/performance-profile.conf" ]; then
                log_info "Current performance profile:"
                cat "$HARDWARE_CONFIG_DIR/performance-profile.conf"
            else
                log_warning "Performance profile not found. Run '$0 optimize' to create one."
            fi
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command '$action'"
            show_usage
            exit 1
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            export USER_MODE=true
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