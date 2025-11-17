#!/bin/bash

# test-hardware-compatibility.sh
# Hardware compatibility testing for Voidance Linux system services
# Tests services on different hardware configurations

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
    echo -e "${BLUE}[HW-TEST]${NC} $1"
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

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

# Hardware information
HW_INFO=""

# Function to collect hardware information
collect_hardware_info() {
    log "Collecting hardware information..."
    
    # System information
    HW_INFO+="=== System Information ===\n"
    HW_INFO+="Kernel: $(uname -r)\n"
    HW_INFO+="Architecture: $(uname -m)\n"
    HW_INFO+="Hostname: $(hostname)\n"
    HW_INFO+="Uptime: $(uptime -p 2>/dev/null || uptime)\n\n"
    
    # CPU information
    HW_INFO+="=== CPU Information ===\n"
    if [ -f /proc/cpuinfo ]; then
        local cpu_model=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//')
        local cpu_cores=$(grep -c '^processor' /proc/cpuinfo)
        HW_INFO+="Model: $cpu_model\n"
        HW_INFO+="Cores: $cpu_cores\n"
    fi
    HW_INFO+="\n"
    
    # Memory information
    HW_INFO+="=== Memory Information ===\n"
    if [ -f /proc/meminfo ]; then
        local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        local mem_gb=$((mem_total / 1024 / 1024))
        HW_INFO+="Total Memory: ${mem_gb}GB\n"
    fi
    HW_INFO+="\n"
    
    # Graphics information
    HW_INFO+="=== Graphics Information ===\n"
    if command -v lspci >/dev/null 2>&1; then
        local gpu_info=$(lspci | grep -i 'vga\|3d\|display' | head -3)
        if [ -n "$gpu_info" ]; then
            echo "$gpu_info" | while read -r line; do
                HW_INFO+="$line\n"
            done
        else
            HW_INFO+="No GPU information found\n"
        fi
    fi
    HW_INFO+="\n"
    
    # Audio information
    HW_INFO+="=== Audio Information ===\n"
    if command -v lspci >/dev/null 2>&1; then
        local audio_info=$(lspci | grep -i 'audio' | head -3)
        if [ -n "$audio_info" ]; then
            echo "$audio_info" | while read -r line; do
                HW_INFO+="$line\n"
            done
        else
            HW_INFO+="No audio devices found\n"
        fi
    fi
    HW_INFO+="\n"
    
    # Network information
    HW_INFO+="=== Network Information ===\n"
    if command -v lspci >/dev/null 2>&1; then
        local net_info=$(lspci | grep -i 'network\|ethernet' | head -3)
        if [ -n "$net_info" ]; then
            echo "$net_info" | while read -r line; do
                HW_INFO+="$line\n"
            done
        else
            HW_INFO+="No network devices found\n"
        fi
    fi
    HW_INFO+="\n"
    
    # Storage information
    HW_INFO+="=== Storage Information ===\n"
    if command -v lsblk >/dev/null 2>&1; then
        local storage_info=$(lsblk -d -o NAME,SIZE,MODEL | grep -v 'loop' | head -5)
        if [ -n "$storage_info" ]; then
            echo "$storage_info" | while read -r line; do
                HW_INFO+="$line\n"
            done
        fi
    fi
    HW_INFO+="\n"
    
    # USB information
    HW_INFO+="=== USB Information ===\n"
    if command -v lsusb >/dev/null 2>&1; then
        local usb_info=$(lsusb | head -5)
        if [ -n "$usb_info" ]; then
            echo "$usb_info" | while read -r line; do
                HW_INFO+="$line\n"
            done
        else
            HW_INFO+="No USB devices found\n"
        fi
    fi
    HW_INFO+="\n"
}

# Function to test session management on hardware
test_session_hardware() {
    log "Testing session management hardware compatibility..."
    
    # Test elogind hardware support
    if command -v loginctl >/dev/null 2>&1; then
        local sessions
        sessions=$(loginctl list-sessions 2>/dev/null | wc -l)
        if [ "$sessions" -gt 0 ]; then
            success "elogind sessions detected: $sessions"
            ((TESTS_PASSED++))
        else
            warning "No elogind sessions found"
            ((TESTS_WARNED++))
        fi
        
        # Test seat support
        local seats
        seats=$(loginctl list-seats 2>/dev/null | wc -l)
        if [ "$seats" -gt 0 ]; then
            success "elogind seats detected: $seats"
            ((TESTS_PASSED++))
        else
            warning "No elogind seats found"
            ((TESTS_WARNED++))
        fi
    else
        error "loginctl not available"
        ((TESTS_FAILED++))
    fi
    
    # Test D-Bus hardware integration
    if command -v dbus-send >/dev/null 2>&1; then
        if dbus-send --system --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
            success "D-Bus system communication working"
            ((TESTS_PASSED++))
        else
            error "D-Bus system communication failed"
            ((TESTS_FAILED++))
        fi
    else
        error "dbus-send not available"
        ((TESTS_FAILED++))
    fi
}

# Function to test display manager hardware compatibility
test_display_hardware() {
    log "Testing display manager hardware compatibility..."
    
    # Test GPU detection
    if command -v lspci >/dev/null 2>&1; then
        local gpu_count=$(lspci | grep -i 'vga\|3d\|display' | wc -l)
        if [ "$gpu_count" -gt 0 ]; then
            success "GPU detected: $gpu_count device(s)"
            ((TESTS_PASSED++))
            
            # Test for specific GPU vendors
            if lspci | grep -qi 'nvidia'; then
                info "NVIDIA GPU detected"
                if lsmod | grep -q 'nvidia'; then
                    success "NVIDIA driver loaded"
                    ((TESTS_PASSED++))
                else
                    warning "NVIDIA driver not loaded"
                    ((TESTS_WARNED++))
                fi
            fi
            
            if lspci | grep -qi 'amd\|radeon'; then
                info "AMD GPU detected"
                if lsmod | grep -q 'amdgpu\|radeon'; then
                    success "AMD driver loaded"
                    ((TESTS_PASSED++))
                else
                    warning "AMD driver not loaded"
                    ((TESTS_WARNED++))
                fi
            fi
            
            if lspci | grep -qi 'intel'; then
                info "Intel GPU detected"
                if lsmod | grep -q 'i915'; then
                    success "Intel driver loaded"
                    ((TESTS_PASSED++))
                else
                    warning "Intel driver not loaded"
                    ((TESTS_WARNED++))
                fi
            fi
        else
            error "No GPU detected"
            ((TESTS_FAILED++))
        fi
    fi
    
    # Test display server support
    if [ -n "${DISPLAY:-}" ]; then
        success "X11 display available: $DISPLAY"
        ((TESTS_PASSED++))
    else
        warning "X11 display not available"
        ((TESTS_WARNED++))
    fi
    
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        success "Wayland display available: $WAYLAND_DISPLAY"
        ((TESTS_PASSED++))
    else
        warning "Wayland display not available"
        ((TESTS_WARNED++))
    fi
    
    # Test SDDM hardware compatibility
    if command -v sddm >/dev/null 2>&1; then
        if sddm --test-config >/dev/null 2>&1; then
            success "SDDM configuration valid"
            ((TESTS_PASSED++))
        else
            error "SDDM configuration invalid"
            ((TESTS_FAILED++))
        fi
    fi
}

# Function to test network hardware compatibility
test_network_hardware() {
    log "Testing network hardware compatibility..."
    
    # Test network interfaces
    if [ -d /sys/class/net ]; then
        local interface_count=$(find /sys/class/net -name 'lo' -prune -o -type d -print | wc -l)
        if [ "$interface_count" -gt 0 ]; then
            success "Network interfaces detected: $interface_count"
            ((TESTS_PASSED++))
            
            # Test for specific interface types
            for interface in /sys/class/net/*; do
                if [ -d "$interface" ]; then
                    local iface_name=$(basename "$interface")
                    if [ "$iface_name" != "lo" ]; then
                        if [ -f "$interface/type" ]; then
                            local iface_type=$(cat "$interface/type")
                            case "$iface_type" in
                                1)
                                    info "Ethernet interface: $iface_name"
                                    ;;
                                1)
                                    info "Wireless interface: $iface_name"
                                    ;;
                                *)
                                    info "Other interface: $iface_name (type: $iface_type)"
                                    ;;
                            esac
                        fi
                    fi
                fi
            done
        else
            warning "No network interfaces found"
            ((TESTS_WARNED++))
        fi
    fi
    
    # Test NetworkManager hardware support
    if command -v nmcli >/dev/null 2>&1; then
        local nm_devices
        nm_devices=$(nmcli device status 2>/dev/null | wc -l)
        if [ "$nm_devices" -gt 2 ]; then  # Header + at least one device
            success "NetworkManager devices detected: $((nm_devices - 2))"
            ((TESTS_PASSED++))
        else
            warning "No NetworkManager devices found"
            ((TESTS_WARNED++))
        fi
    fi
    
    # Test wireless hardware
    if command -v iw >/dev/null 2>&1; then
        local wifi_interfaces
        wifi_interfaces=$(iw dev 2>/dev/null | grep 'Interface' | wc -l)
        if [ "$wifi_interfaces" -gt 0 ]; then
            success "Wireless interfaces detected: $wifi_interfaces"
            ((TESTS_PASSED++))
        else
            info "No wireless interfaces detected"
        fi
    fi
}

# Function to test audio hardware compatibility
test_audio_hardware() {
    log "Testing audio hardware compatibility..."
    
    # Test ALSA devices
    if [ -d /proc/asound ]; then
        local card_count=$(find /proc/asound -name 'card*' -type d | wc -l)
        if [ "$card_count" -gt 0 ]; then
            success "ALSA cards detected: $card_count"
            ((TESTS_PASSED++))
            
            # List audio cards
            for card in /proc/asound/card*; do
                if [ -d "$card" ]; then
                    local card_num=$(basename "$card" | sed 's/card//')
                    if [ -f "$card/id" ]; then
                        local card_id=$(cat "$card/id")
                        info "Audio card $card_num: $card_id"
                    fi
                fi
            done
        else
            warning "No ALSA cards found"
            ((TESTS_WARNED++))
        fi
    fi
    
    # Test PipeWire hardware support
    if command -v wpctl >/dev/null 2>&1; then
        local sinks
        sinks=$(wpctl status 2>/dev/null | grep -c 'Sink' || echo "0")
        if [ "$sinks" -gt 0 ]; then
            success "PipeWire sinks detected: $sinks"
            ((TESTS_PASSED++))
        else
            warning "No PipeWire sinks found"
            ((TESTS_WARNED++))
        fi
        
        local sources
        sources=$(wpctl status 2>/dev/null | grep -c 'Source' || echo "0")
        if [ "$sources" -gt 0 ]; then
            success "PipeWire sources detected: $sources"
            ((TESTS_PASSED++))
        else
            warning "No PipeWire sources found"
            ((TESTS_WARNED++))
        fi
    fi
    
    # Test audio device permissions
    if [ -d /dev/snd ]; then
        local audio_devices=$(find /dev/snd -type c | wc -l)
        if [ "$audio_devices" -gt 0 ]; then
            success "Audio devices detected: $audio_devices"
            ((TESTS_PASSED++))
            
            # Test device accessibility
            if [ -r /dev/snd/controlC0 ] 2>/dev/null; then
                success "Audio device accessible"
                ((TESTS_PASSED++))
            else
                warning "Audio device not accessible (may need audio group)"
                ((TESTS_WARNED++))
            fi
        else
            error "No audio devices found"
            ((TESTS_FAILED++))
        fi
    fi
}

# Function to test input hardware compatibility
test_input_hardware() {
    log "Testing input hardware compatibility..."
    
    # Test input devices
    if [ -d /dev/input ]; then
        local input_devices=$(find /dev/input -name 'event*' -type c | wc -l)
        if [ "$input_devices" -gt 0 ]; then
            success "Input devices detected: $input_devices"
            ((TESTS_PASSED++))
        else
            warning "No input devices found"
            ((TESTS_WARNED++))
        fi
    fi
    
    # Test USB input devices
    if command -v lsusb >/dev/null 2>&1; then
        local usb_input=$(lsusb | grep -i 'keyboard\|mouse\|touchpad\|tablet' | wc -l)
        if [ "$usb_input" -gt 0 ]; then
            success "USB input devices detected: $usb_input"
            ((TESTS_PASSED++))
        else
            info "No USB input devices detected"
        fi
    fi
    
    # Test evdev support
    if command -v evtest >/dev/null 2>&1; then
        info "evtest available for input testing"
    else
        info "evtest not available (install for input testing)"
    fi
}

# Function to test power management hardware
test_power_hardware() {
    log "Testing power management hardware compatibility..."
    
    # Test battery support
    if [ -d /sys/class/power_supply ]; then
        local batteries=$(find /sys/class/power_supply -name 'BAT*' -type d | wc -l)
        if [ "$batteries" -gt 0 ]; then
            success "Batteries detected: $batteries"
            ((TESTS_PASSED++))
            
            # Test battery status
            for battery in /sys/class/power_supply/BAT*; do
                if [ -f "$battery/status" ]; then
                    local status=$(cat "$battery/status")
                    info "Battery status: $status"
                fi
                if [ -f "$battery/capacity" ]; then
                    local capacity=$(cat "$battery/capacity")
                    info "Battery capacity: ${capacity}%"
                fi
            done
        else
            info "No batteries detected (desktop system)"
        fi
        
        # Test AC adapter
        local ac_adapters=$(find /sys/class/power_supply -name 'AC*' -type d | wc -l)
        if [ "$ac_adapters" -gt 0 ]; then
            success "AC adapters detected: $ac_adapters"
            ((TESTS_PASSED++))
        fi
    fi
    
    # Test suspend/resume support
    if [ -f /sys/power/state ]; then
        local power_states=$(cat /sys/power/state)
        if echo "$power_states" | grep -q 'mem'; then
            success "Suspend (mem) supported"
            ((TESTS_PASSED++))
        else
            warning "Suspend not supported"
            ((TESTS_WARNED++))
        fi
        
        if echo "$power_states" | grep -q 'disk'; then
            success "Hibernate (disk) supported"
            ((TESTS_PASSED++))
        else
            info "Hibernate not supported"
        fi
    fi
    
    # Test CPU frequency scaling
    if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        success "CPU frequency scaling supported"
        ((TESTS_PASSED++))
        
        if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
            local governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
            info "CPU governor: $governor"
        fi
    else
        info "CPU frequency scaling not available"
    fi
}

# Function to generate hardware compatibility report
generate_hardware_report() {
    local report_file="/tmp/voidance-hardware-report-$(date +%Y%m%d-%H%M%S).txt"
    
    log "Generating hardware compatibility report: $report_file"
    
    {
        echo "Voidance Linux Hardware Compatibility Report"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=========================================="
        echo
        
        echo -e "$HW_INFO"
        
        echo "=== Test Results ==="
        echo "Tests Passed: $TESTS_PASSED"
        echo "Tests Warned: $TESTS_WARNED"
        echo "Tests Failed: $TESTS_FAILED"
        echo "Total Tests: $((TESTS_PASSED + TESTS_WARNED + TESTS_FAILED))"
        echo
        
        if [ $TESTS_FAILED -eq 0 ]; then
            echo "Overall Status: COMPATIBLE"
        elif [ $TESTS_FAILED -le 2 ]; then
            echo "Overall Status: MOSTLY COMPATIBLE"
        else
            echo "Overall Status: COMPATIBILITY ISSUES"
        fi
        
        echo
        echo "=== Recommendations ==="
        
        if [ $TESTS_FAILED -eq 0 ]; then
            echo "✓ All hardware components are compatible with Voidance Linux"
            echo "✓ System services should work correctly on this hardware"
        else
            echo "⚠ Some hardware compatibility issues detected:"
            echo "  - Check GPU drivers are properly installed"
            echo "  - Verify audio device permissions"
            echo "  - Ensure network drivers are loaded"
        fi
        
        if [ $TESTS_WARNED -gt 0 ]; then
            echo
            echo "⚠ Warnings detected:"
            echo "  - Some features may not be fully available"
            echo "  - Consider installing additional drivers"
            echo "  - Check user group memberships"
        fi
        
    } > "$report_file"
    
    success "Hardware compatibility report saved to: $report_file"
}

# Main execution
case "${1:-test}" in
    "test")
        log "Starting hardware compatibility testing..."
        echo
        
        collect_hardware_info
        test_session_hardware
        test_display_hardware
        test_network_hardware
        test_audio_hardware
        test_input_hardware
        test_power_hardware
        
        echo
        log "Hardware compatibility test summary:"
        echo "================================"
        echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
        echo -e "Tests warned: ${YELLOW}$TESTS_WARNED${NC}"
        echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
        echo "================================"
        
        # Show hardware information
        echo
        echo -e "$HW_INFO"
        
        # Overall result
        if [ $TESTS_FAILED -eq 0 ]; then
            if [ $TESTS_WARNED -eq 0 ]; then
                success "Hardware is fully compatible! ✓"
                echo
                log "All hardware components are supported by Voidance Linux."
                log "System services should work correctly on this hardware."
                exit 0
            else
                warning "Hardware is mostly compatible with some warnings"
                echo
                log "Most hardware components are supported."
                log "Some features may require additional configuration."
                exit 1
            fi
        else
            error "Hardware compatibility issues detected"
            echo
            log "Some hardware components may not be fully supported."
            log "Consider installing additional drivers or firmware."
            exit 1
        fi
        ;;
    "report")
        collect_hardware_info
        # Run minimal tests for report
        test_session_hardware
        test_display_hardware
        test_network_hardware
        test_audio_hardware
        test_input_hardware
        test_power_hardware
        generate_hardware_report
        ;;
    "info")
        collect_hardware_info
        echo -e "$HW_INFO"
        ;;
    "session")
        collect_hardware_info
        test_session_hardware
        ;;
    "display")
        collect_hardware_info
        test_display_hardware
        ;;
    "network")
        collect_hardware_info
        test_network_hardware
        ;;
    "audio")
        collect_hardware_info
        test_audio_hardware
        ;;
    "input")
        collect_hardware_info
        test_input_hardware
        ;;
    "power")
        collect_hardware_info
        test_power_hardware
        ;;
    *)
        echo "Voidance Linux Hardware Compatibility Testing"
        echo "Usage: $0 {test|report|info|session|display|network|audio|input|power}"
        echo
        echo "Commands:"
        echo "  test     - Run full hardware compatibility test (default)"
        echo "  report   - Generate detailed hardware compatibility report"
        echo "  info     - Show hardware information only"
        echo "  session  - Test session management hardware compatibility"
        echo "  display  - Test display hardware compatibility"
        echo "  network  - Test network hardware compatibility"
        echo "  audio    - Test audio hardware compatibility"
        echo "  input    - Test input hardware compatibility"
        echo "  power    - Test power management hardware compatibility"
        exit 1
        ;;
esac