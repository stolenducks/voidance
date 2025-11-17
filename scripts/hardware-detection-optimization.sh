#!/bin/bash
# Voidance Hardware Detection and Optimization
# Comprehensive hardware detection and system optimization

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/iso/config.sh"

# Hardware detection configuration
HARDWARE_LOG="/var/log/voidance-hardware.log"
HARDWARE_PROFILE_DIR="/etc/voidance/hardware-profiles"
OPTIMIZATION_DIR="/etc/voidance/optimizations"

# Function to detect CPU information
detect_cpu() {
    log_message "INFO" "Detecting CPU information"
    
    local cpu_model=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local cpu_cores=$(nproc)
    local cpu_threads=$(grep -c processor /proc/cpuinfo)
    local cpu_vendor=$(grep 'vendor_id' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local cpu_family=$(grep 'cpu family' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local cpu_stepping=$(grep 'stepping' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    
    # Detect CPU features
    local cpu_features=$(grep 'flags' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    
    # Detect virtualization support
    local virt_support=""
    if echo "$cpu_features" | grep -q "vmx\|svm"; then
        virt_support="Yes"
    else
        virt_support="No"
    fi
    
    # Create CPU profile
    cat > "$HARDWARE_PROFILE_DIR/cpu.conf" << EOF
# CPU Hardware Profile
cpu_model="$cpu_model"
cpu_vendor="$cpu_vendor"
cpu_family="$cpu_family"
cpu_cores="$cpu_cores"
cpu_threads="$cpu_threads"
cpu_stepping="$cpu_stepping"
virtualization_support="$virt_support"
cpu_features="$cpu_features"
detection_date="$(date)"
EOF
    
    echo "CPU Information:"
    echo "  Model: $cpu_model"
    echo "  Vendor: $cpu_vendor"
    echo "  Cores: $cpu_cores"
    echo "  Threads: $cpu_threads"
    echo "  Virtualization: $virt_support"
    
    log_message "INFO" "CPU detection completed: $cpu_model"
}

# Function to detect GPU information
detect_gpu() {
    log_message "INFO" "Detecting GPU information"
    
    local gpu_info=""
    local gpu_driver=""
    local gpu_memory=""
    local gpu_vendor=""
    
    # Get GPU information from lspci
    while IFS= read -r line; do
        if echo "$line" | grep -qi "vga\|3d\|display"; then
            gpu_info="$line"
            
            # Determine GPU vendor
            if echo "$line" | grep -qi nvidia; then
                gpu_vendor="nvidia"
                gpu_driver="nvidia"
            elif echo "$line" | grep -qi "intel"; then
                gpu_vendor="intel"
                gpu_driver="i915"
            elif echo "$line" | grep -qi "amd\|radeon"; then
                gpu_vendor="amd"
                gpu_driver="amdgpu"
            elif echo "$line" | grep -qi "vmware"; then
                gpu_vendor="vmware"
                gpu_driver="vmwgfx"
            else
                gpu_vendor="unknown"
                gpu_driver="vesa"
            fi
        fi
    done < <(lspci)
    
    # Get GPU memory information
    if [[ "$gpu_vendor" == "nvidia" ]] && command -v nvidia-smi >/dev/null 2>&1; then
        gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
    elif [[ -d /sys/class/drm ]]; then
        # Try to get memory info from DRM
        local drm_card=$(ls /sys/class/drm/ | grep "^card[0-9]" | head -1)
        if [[ -n "$drm_card" ]] && [[ -f "/sys/class/drm/$drm_card/memory_size" ]]; then
            gpu_memory=$(cat "/sys/class/drm/$drm_card/memory_size")
        fi
    fi
    
    # Create GPU profile
    cat > "$HARDWARE_PROFILE_DIR/gpu.conf" << EOF
# GPU Hardware Profile
gpu_info="$gpu_info"
gpu_vendor="$gpu_vendor"
gpu_driver="$gpu_driver"
gpu_memory="$gpu_memory"
detection_date="$(date)"
EOF
    
    echo "GPU Information:"
    echo "  Vendor: $gpu_vendor"
    echo "  Driver: $gpu_driver"
    echo "  Memory: ${gpu_memory:-"Unknown"}"
    echo "  Details: $gpu_info"
    
    log_message "INFO" "GPU detection completed: $gpu_vendor"
}

# Function to detect memory information
detect_memory() {
    log_message "INFO" "Detecting memory information"
    
    local total_memory=$(free -h | awk '/^Mem:/ {print $2}')
    local available_memory=$(free -h | awk '/^Mem:/ {print $7}')
    local memory_speed=""
    local memory_type=""
    
    # Get detailed memory information
    if command -v dmidecode >/dev/null 2>&1; then
        memory_speed=$(dmidecode -t memory | grep "Speed:" | head -1 | cut -d: -f2 | xargs)
        memory_type=$(dmidecode -t memory | grep "Type:" | head -1 | cut -d: -f2 | xargs)
    fi
    
    # Create memory profile
    cat > "$HARDWARE_PROFILE_DIR/memory.conf" << EOF
# Memory Hardware Profile
total_memory="$total_memory"
available_memory="$available_memory"
memory_speed="$memory_speed"
memory_type="$memory_type"
detection_date="$(date)"
EOF
    
    echo "Memory Information:"
    echo "  Total: $total_memory"
    echo "  Available: $available_memory"
    echo "  Type: ${memory_type:-"Unknown"}"
    echo "  Speed: ${memory_speed:-"Unknown"}"
    
    log_message "INFO" "Memory detection completed: $total_memory"
}

# Function to detect storage information
detect_storage() {
    log_message "INFO" "Detecting storage information"
    
    # Get block devices
    local storage_devices=()
    while IFS= read -r device; do
        if [[ -b "$device" ]] && [[ ! "$device" =~ *[0-9] ]]; then
            storage_devices+=("$device")
        fi
    done < <(lsblk -no NAME,TYPE | grep disk | awk '{print "/dev/"$1}')
    
    # Create storage profile
    cat > "$HARDWARE_PROFILE_DIR/storage.conf" << EOF
# Storage Hardware Profile
storage_devices=($(printf '"%s" ' "${storage_devices[@]}"))
detection_date="$(date)"
EOF
    
    echo "Storage Information:"
    for device in "${storage_devices[@]}"; do
        local size=$(lsblk -no SIZE "$device" | head -1)
        local model=$(lsblk -no MODEL "$device" | head -1)
        local type=$(lsblk -no TYPE "$device" | head -1)
        
        echo "  Device: $device"
        echo "    Size: $size"
        echo "    Model: ${model:-"Unknown"}"
        echo "    Type: $type"
        
        # Get partition information
        lsblk -no NAME,SIZE,FSTYPE "$device" | grep -E "${device##*/}[0-9]" | while read -r part_info; do
            echo "    Partition: $part_info"
        done
        echo ""
    done
    
    log_message "INFO" "Storage detection completed: ${#storage_devices[@]} devices"
}

# Function to detect network information
detect_network() {
    log_message "INFO" "Detecting network information"
    
    local network_interfaces=()
    local wireless_interfaces=()
    local wired_interfaces=()
    
    # Get network interfaces
    while IFS= read -r interface; do
        if [[ -d "/sys/class/net/$interface" ]] && [[ "$interface" != "lo" ]]; then
            network_interfaces+=("$interface")
            
            # Check if wireless
            if [[ -d "/sys/class/net/$interface/wireless" ]] || iwconfig "$interface" 2>/dev/null | grep -q "IEEE 802.11"; then
                wireless_interfaces+=("$interface")
            else
                wired_interfaces+=("$interface")
            fi
        fi
    done < <(ls /sys/class/net/)
    
    # Create network profile
    cat > "$HARDWARE_PROFILE_DIR/network.conf" << EOF
# Network Hardware Profile
network_interfaces=($(printf '"%s" ' "${network_interfaces[@]}"))
wired_interfaces=($(printf '"%s" ' "${wired_interfaces[@]}"))
wireless_interfaces=($(printf '"%s" ' "${wireless_interfaces[@]}"))
detection_date="$(date)"
EOF
    
    echo "Network Information:"
    echo "  Total interfaces: ${#network_interfaces[@]}"
    echo "  Wired interfaces: ${#wired_interfaces[@]}"
    echo "  Wireless interfaces: ${#wireless_interfaces[@]}"
    echo ""
    
    for interface in "${network_interfaces[@]}"; do
        local mac=$(cat "/sys/class/net/$interface/address" 2>/dev/null || echo "Unknown")
        local status=$(cat "/sys/class/net/$interface/operstate" 2>/dev/null || echo "Unknown")
        local speed=$(cat "/sys/class/net/$interface/speed" 2>/dev/null || echo "Unknown")
        
        echo "  Interface: $interface"
        echo "    MAC: $mac"
        echo "    Status: $status"
        echo "    Speed: ${speed}Mbps"
        
        if [[ " ${wireless_interfaces[*]} " =~ " $interface " ]]; then
            echo "    Type: Wireless"
        else
            echo "    Type: Wired"
        fi
        echo ""
    done
    
    log_message "INFO" "Network detection completed: ${#network_interfaces[@]} interfaces"
}

# Function to detect audio information
detect_audio() {
    log_message "INFO" "Detecting audio information"
    
    local audio_devices=()
    
    # Get audio devices from ALSA
    if command -v aplay >/dev/null 2>&1; then
        while IFS= read -r line; do
            if echo "$line" | grep -q "card [0-9]"; then
                local card=$(echo "$line" | grep -o "card [0-9]*" | cut -d' ' -f2)
                local device=$(echo "$line" | grep -o "device [0-9]*" | cut -d' ' -f2)
                local name=$(echo "$line" | cut -d: -f2 | xargs)
                
                audio_devices+=("card$card:$device:$name")
            fi
        done < <(aplay -l)
    fi
    
    # Create audio profile
    cat > "$HARDWARE_PROFILE_DIR/audio.conf" << EOF
# Audio Hardware Profile
audio_devices=($(printf '"%s" ' "${audio_devices[@]}"))
detection_date="$(date)"
EOF
    
    echo "Audio Information:"
    echo "  Audio devices: ${#audio_devices[@]}"
    for device in "${audio_devices[@]}"; do
        IFS=':' read -r card device_num name <<< "$device"
        echo "  Device: $card:$device_num"
        echo "    Name: $name"
    done
    
    log_message "INFO" "Audio detection completed: ${#audio_devices[@]} devices"
}

# Function to detect system form factor
detect_form_factor() {
    log_message "INFO" "Detecting system form factor"
    
    local form_factor="unknown"
    local chassis_type="unknown"
    
    # Try to detect from DMI
    if command -v dmidecode >/dev/null 2>&1; then
        chassis_type=$(dmidecode -s chassis-type 2>/dev/null || echo "unknown")
        
        case "$chassis_type" in
            "Notebook"|"Laptop"|"Portable")
                form_factor="laptop"
                ;;
            "Desktop"|"Tower"|"Low Profile Desktop")
                form_factor="desktop"
                ;;
            "Server"|"Rack Mount Chassis"|"Blade")
                form_factor="server"
                ;;
            "Tablet"|"Convertible"|"Detachable")
                form_factor="tablet"
                ;;
            *)
                form_factor="unknown"
                ;;
        esac
    fi
    
    # Check for battery as laptop indicator
    if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
        form_factor="laptop"
    fi
    
    # Create form factor profile
    cat > "$HARDWARE_PROFILE_DIR/form-factor.conf" << EOF
# System Form Factor Profile
form_factor="$form_factor"
chassis_type="$chassis_type"
detection_date="$(date)"
EOF
    
    echo "System Form Factor:"
    echo "  Type: $form_factor"
    echo "  Chassis: $chassis_type"
    
    log_message "INFO" "Form factor detection completed: $form_factor"
}

# Function to apply hardware optimizations
apply_hardware_optimizations() {
    log_message "INFO" "Applying hardware optimizations"
    
    # Load hardware profiles
    local cpu_vendor=""
    local gpu_vendor=""
    local form_factor=""
    
    if [[ -f "$HARDWARE_PROFILE_DIR/cpu.conf" ]]; then
        source "$HARDWARE_PROFILE_DIR/cpu.conf"
        cpu_vendor="$cpu_vendor"
    fi
    
    if [[ -f "$HARDWARE_PROFILE_DIR/gpu.conf" ]]; then
        source "$HARDWARE_PROFILE_DIR/gpu.conf"
        gpu_vendor="$gpu_vendor"
    fi
    
    if [[ -f "$HARDWARE_PROFILE_DIR/form-factor.conf" ]]; then
        source "$HARDWARE_PROFILE_DIR/form-factor.conf"
        form_factor="$form_factor"
    fi
    
    # Apply CPU optimizations
    apply_cpu_optimizations "$cpu_vendor"
    
    # Apply GPU optimizations
    apply_gpu_optimizations "$gpu_vendor"
    
    # Apply form factor optimizations
    apply_form_factor_optimizations "$form_factor"
    
    log_message "INFO" "Hardware optimizations applied"
}

# Function to apply CPU optimizations
apply_cpu_optimizations() {
    local cpu_vendor="$1"
    
    log_message "INFO" "Applying CPU optimizations for: $cpu_vendor"
    
    case "$cpu_vendor" in
        "GenuineIntel")
            # Intel-specific optimizations
            echo "options i915 enable_fbc=1 enable_psr=1" >> /etc/modprobe.d/i915.conf
            echo "options snd_hda_intel power_save=1" >> /etc/modprobe.d/audio.conf
            ;;
        "AuthenticAMD")
            # AMD-specific optimizations
            echo "options amdgpu si_support=1" >> /etc/modprobe.d/amdgpu.conf
            echo "options radeon si_support=1" >> /etc/modprobe.d/radeon.conf
            ;;
    esac
    
    # General CPU optimizations
    if command -v cpupower >/dev/null 2>&1; then
        # Set CPU governor
        cpupower frequency-set -g ondemand
    fi
    
    # Create CPU optimization script
    cat > "$OPTIMIZATION_DIR/cpu-optimizations.sh" << 'EOF'
#!/bin/bash
# CPU Optimization Script

# Set CPU governor to ondemand for balanced performance
if command -v cpupower >/dev/null 2>&1; then
    cpupower frequency-set -g ondemand
fi

# Disable CPU idle states that cause latency
echo 1 > /sys/devices/system/cpu/cpuidle/low_power_idle_cpu_residency_us 2>/dev/null || true

# Set CPU affinity for interrupts
for irq in /proc/irq/*/smp_affinity; do
    echo 1 > "$irq" 2>/dev/null || true
done
EOF
    
    chmod +x "$OPTIMIZATION_DIR/cpu-optimizations.sh"
}

# Function to apply GPU optimizations
apply_gpu_optimizations() {
    local gpu_vendor="$1"
    
    log_message "INFO" "Applying GPU optimizations for: $gpu_vendor"
    
    case "$gpu_vendor" in
        "nvidia")
            # NVIDIA optimizations
            cat > /etc/X11/xorg.conf.d/20-nvidia-optimizations.conf << 'EOF'
Section "Device"
    Identifier "NVIDIA Card"
    Driver "nvidia"
    Option "TripleBuffer" "true"
    Option "AllowGLXWithComposite" "true"
    Option "Coolbits" "28"
    Option "RegistryDwords" "PowerMizerEnable=1x1"
EndSection
EOF
            ;;
        "intel")
            # Intel optimizations
            cat > /etc/X11/xorg.conf.d/20-intel-optimizations.conf << 'EOF'
Section "Device"
    Identifier "Intel Card"
    Driver "intel"
    Option "TearFree" "true"
    Option "DRI" "3"
    Option "AccelMethod" "sna"
EndSection
EOF
            ;;
        "amd")
            # AMD optimizations
            cat > /etc/X11/xorg.conf.d/20-amd-optimizations.conf << 'EOF'
Section "Device"
    Identifier "AMD Card"
    Driver "amdgpu"
    Option "TearFree" "true"
    Option "DRI" "3"
EndSection
EOF
            ;;
    esac
    
    # Create GPU optimization script
    cat > "$OPTIMIZATION_DIR/gpu-optimizations.sh" << 'EOF'
#!/bin/bash
# GPU Optimization Script

# Enable GPU performance mode
if [[ -f /sys/class/drm/*/device/power_dpm_state ]]; then
    echo performance > /sys/class/drm/*/device/power_dpm_state 2>/dev/null || true
fi

# Set GPU frequency scaling
if [[ -f /sys/class/drm/*/device/gpu_clock_freq ]]; then
    echo high > /sys/class/drm/*/device/power_dpm_force_performance_level 2>/dev/null || true
fi
EOF
    
    chmod +x "$OPTIMIZATION_DIR/gpu-optimizations.sh"
}

# Function to apply form factor optimizations
apply_form_factor_optimizations() {
    local form_factor="$1"
    
    log_message "INFO" "Applying optimizations for form factor: $form_factor"
    
    case "$form_factor" in
        "laptop")
            # Laptop-specific optimizations
            cat > "$OPTIMIZATION_DIR/laptop-optimizations.sh" << 'EOF'
#!/bin/bash
# Laptop Optimization Script

# Enable laptop mode
echo 5 > /proc/sys/vm/laptop_mode 2>/dev/null || true

# Enable power saving for storage
echo min_power > /sys/class/scsi_host/host*/link_power_management_policy 2>/dev/null || true

# Enable SATA link power management
echo med_power_with_dipm > /sys/class/scsi_host/host*/link_power_management_policy 2>/dev/null || true

# Enable USB autosuspend
for device in /sys/bus/usb/devices/*/power/control; do
    echo auto > "$device" 2>/dev/null || true
done
EOF
            ;;
        "desktop")
            # Desktop-specific optimizations
            cat > "$OPTIMIZATION_DIR/desktop-optimizations.sh" << 'EOF'
#!/bin/bash
# Desktop Optimization Script

# Disable laptop mode
echo 0 > /proc/sys/vm/laptop_mode 2>/dev/null || true

# Set swappiness for desktop use
echo 10 > /proc/sys/vm/swappiness 2>/dev/null || true

# Enable high performance for storage
echo max_performance > /sys/class/scsi_host/host*/link_power_management_policy 2>/dev/null || true
EOF
            ;;
    esac
    
    chmod +x "$OPTIMIZATION_DIR/${form_factor}-optimizations.sh" 2>/dev/null || true
}

# Function to create hardware database
create_hardware_database() {
    log_message "INFO" "Creating hardware database"
    
    local database_file="/var/lib/voidance/hardware-database.json"
    mkdir -p "$(dirname "$database_file")"
    
    # Collect all hardware information
    local cpu_info=""
    local gpu_info=""
    local memory_info=""
    local storage_info=""
    local network_info=""
    local audio_info=""
    local form_factor_info=""
    
    [[ -f "$HARDWARE_PROFILE_DIR/cpu.conf" ]] && cpu_info=$(cat "$HARDWARE_PROFILE_DIR/cpu.conf")
    [[ -f "$HARDWARE_PROFILE_DIR/gpu.conf" ]] && gpu_info=$(cat "$HARDWARE_PROFILE_DIR/gpu.conf")
    [[ -f "$HARDWARE_PROFILE_DIR/memory.conf" ]] && memory_info=$(cat "$HARDWARE_PROFILE_DIR/memory.conf")
    [[ -f "$HARDWARE_PROFILE_DIR/storage.conf" ]] && storage_info=$(cat "$HARDWARE_PROFILE_DIR/storage.conf")
    [[ -f "$HARDWARE_PROFILE_DIR/network.conf" ]] && network_info=$(cat "$HARDWARE_PROFILE_DIR/network.conf")
    [[ -f "$HARDWARE_PROFILE_DIR/audio.conf" ]] && audio_info=$(cat "$HARDWARE_PROFILE_DIR/audio.conf")
    [[ -f "$HARDWARE_PROFILE_DIR/form-factor.conf" ]] && form_factor_info=$(cat "$HARDWARE_PROFILE_DIR/form-factor.conf")
    
    # Create JSON database entry
    cat > "$database_file" << EOF
{
  "system_id": "$(hostname)-$(date +%s)",
  "detection_date": "$(date -Iseconds)",
  "hostname": "$(hostname)",
  "kernel": "$(uname -r)",
  "architecture": "$(uname -m)",
  "profiles": {
    "cpu": $cpu_info,
    "gpu": $gpu_info,
    "memory": $memory_info,
    "storage": $storage_info,
    "network": $network_info,
    "audio": $audio_info,
    "form_factor": $form_factor_info
  }
}
EOF
    
    log_message "INFO" "Hardware database created: $database_file"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$HARDWARE_LOG"
}

# Main hardware detection function
main_hardware_detection() {
    log_message "INFO" "Starting comprehensive hardware detection"
    
    # Create directories
    mkdir -p "$HARDWARE_PROFILE_DIR"
    mkdir -p "$OPTIMIZATION_DIR"
    
    # Detect all hardware components
    detect_cpu
    detect_gpu
    detect_memory
    detect_storage
    detect_network
    detect_audio
    detect_form_factor
    
    # Apply optimizations
    apply_hardware_optimizations
    
    # Create database
    create_hardware_database
    
    log_message "INFO" "Hardware detection and optimization completed"
}

# Interactive hardware management interface
hardware_management_menu() {
    while true; do
        clear
        echo "Voidance Hardware Detection and Optimization"
        echo "=========================================="
        echo ""
        echo "1. Run Full Hardware Detection"
        echo "2. Detect CPU Information"
        echo "3. Detect GPU Information"
        echo "4. Detect Memory Information"
        echo "5. Detect Storage Information"
        echo "6. Detect Network Information"
        echo "7. Detect Audio Information"
        echo "8. Apply Hardware Optimizations"
        echo "9. View Hardware Profiles"
        echo "10. Exit"
        echo ""
        read -p "Select option: " choice
        
        case $choice in
            1)
                main_hardware_detection
                read -p "Press Enter to continue..."
                ;;
            2)
                detect_cpu
                read -p "Press Enter to continue..."
                ;;
            3)
                detect_gpu
                read -p "Press Enter to continue..."
                ;;
            4)
                detect_memory
                read -p "Press Enter to continue..."
                ;;
            5)
                detect_storage
                read -p "Press Enter to continue..."
                ;;
            6)
                detect_network
                read -p "Press Enter to continue..."
                ;;
            7)
                detect_audio
                read -p "Press Enter to continue..."
                ;;
            8)
                apply_hardware_optimizations
                read -p "Press Enter to continue..."
                ;;
            9)
                echo "Hardware Profiles:"
                ls -la "$HARDWARE_PROFILE_DIR/"
                read -p "Press Enter to continue..."
                ;;
            10)
                break
                ;;
            *)
                echo "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "${1:-}" == "--menu" ]]; then
        hardware_management_menu
    else
        main_hardware_detection "$@"
    fi
fi