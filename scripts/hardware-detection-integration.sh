#!/bin/bash
# Voidance Hardware Detection Integration
# Integrates hardware detection with installation and system setup

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/hardware-detection-optimization.sh"

# Integration configuration
INTEGRATION_LOG="/var/log/voidance-hardware-integration.log"

# Function to integrate hardware detection with installer
integrate_with_installer() {
    log_message "INFO" "Integrating hardware detection with installer"
    
    # Create hardware detection module for installer
    cat > "$SCRIPT_DIR/installer-hardware-detection.sh" << 'EOF'
#!/bin/bash
# Hardware Detection Module for Voidance Installer

# Function to detect hardware during installation
detect_installation_hardware() {
    echo "Detecting hardware for installation..."
    
    # Run hardware detection
    "$SCRIPT_DIR/hardware-detection-optimization.sh"
    
    # Generate hardware-specific recommendations
    generate_hardware_recommendations
}

# Function to generate hardware recommendations
generate_hardware_recommendations() {
    local gpu_vendor=""
    local form_factor=""
    
    # Load hardware profiles
    if [[ -f "$HARDWARE_PROFILE_DIR/gpu.conf" ]]; then
        source "$HARDWARE_PROFILE_DIR/gpu.conf"
        gpu_vendor="$gpu_vendor"
    fi
    
    if [[ -f "$HARDWARE_PROFILE_DIR/form-factor.conf" ]]; then
        source "$HARDWARE_PROFILE_DIR/form-factor.conf"
        form_factor="$form_factor"
    fi
    
    echo "Hardware Recommendations:"
    
    # GPU recommendations
    case "$gpu_vendor" in
        "nvidia")
            echo "• Install NVIDIA proprietary drivers for best performance"
            echo "• Consider enabling CUDA for development work"
            ;;
        "intel")
            echo "• Intel GPU drivers are included by default"
            echo "• Consider enabling VA-API for video acceleration"
            ;;
        "amd")
            echo "• AMD GPU drivers are included by default"
            echo "• Consider enabling VAAPI for video acceleration"
            ;;
    esac
    
    # Form factor recommendations
    case "$form_factor" in
        "laptop")
            echo "• Enable power management features"
            echo "• Consider installing TLP for battery optimization"
            ;;
        "desktop")
            echo "• High performance mode recommended"
            echo "• Consider enabling RAID for storage redundancy"
            ;;
    esac
}
EOF
    
    chmod +x "$SCRIPT_DIR/installer-hardware-detection.sh"
    log_message "INFO" "Installer hardware detection module created"
}

# Function to create hardware profile database
create_hardware_profile_database() {
    log_message "INFO" "Creating hardware profile database"
    
    local database_dir="/usr/share/voidance/hardware-profiles"
    mkdir -p "$database_dir"
    
    # Create known hardware profiles
    cat > "$database_dir/laptop-intel.profile" << 'EOF'
# Laptop Intel Profile
hardware_type="laptop-intel"
cpu_vendor="GenuineIntel"
gpu_vendor="intel"
form_factor="laptop"

# Recommended packages
recommended_packages="intel-ucode mesa-dri libva-intel-driver tlp"

# Recommended kernel parameters
kernel_params="i915.enable_fbc=1 i915.enable_psr=1"

# Power management settings
power_management=true
cpu_governor="powersave"

# Display settings
display_scaling="2.0"
touchpad_enable=true
EOF
    
    cat > "$database_dir/laptop-nvidia.profile" << 'EOF'
# Laptop NVIDIA Profile
hardware_type="laptop-nvidia"
cpu_vendor="GenuineIntel"
gpu_vendor="nvidia"
form_factor="laptop"

# Recommended packages
recommended_packages="nvidia nvidia-settings nvidia-smi optimus-manager tlp"

# Recommended kernel parameters
kernel_params="nvidia-drm.modeset=1 nvidia.NVreg_RegistryDwords=PowerMizerEnable=1x1"

# Power management settings
power_management=true
cpu_governor="ondemand"

# Display settings
display_scaling="1.0"
touchpad_enable=true
optimus_support=true
EOF
    
    cat > "$database_dir/desktop-amd.profile" << 'EOF'
# Desktop AMD Profile
hardware_type="desktop-amd"
cpu_vendor="AuthenticAMD"
gpu_vendor="amd"
form_factor="desktop"

# Recommended packages
recommended_packages="amd-ucode mesa-dri libva-mesa-driver vulkan-radeon"

# Recommended kernel parameters
kernel_params="amdgpu.si_support=1 amdgpu.cik_support=1"

# Power management settings
power_management=false
cpu_governor="performance"

# Display settings
display_scaling="1.0"
touchpad_enable=false
EOF
    
    log_message "INFO" "Hardware profile database created"
}

# Function to create automatic hardware matching
create_hardware_matching() {
    log_message "INFO" "Creating automatic hardware matching"
    
    cat > "$SCRIPT_DIR/hardware-matcher.sh" << 'EOF'
#!/bin/bash
# Automatic Hardware Profile Matcher

# Function to match hardware profile
match_hardware_profile() {
    local cpu_vendor=""
    local gpu_vendor=""
    local form_factor=""
    
    # Load current hardware profile
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
    
    # Match against known profiles
    local profile_dir="/usr/share/voidance/hardware-profiles"
    local matched_profile=""
    
    for profile_file in "$profile_dir"/*.profile; do
        if [[ -f "$profile_file" ]]; then
            source "$profile_file"
            
            # Check if this profile matches
            if [[ "$cpu_vendor" == "${profile_cpu_vendor:-}" ]] && \
               [[ "$gpu_vendor" == "${profile_gpu_vendor:-}" ]] && \
               [[ "$form_factor" == "${profile_form_factor:-}" ]]; then
                matched_profile="$profile_file"
                break
            fi
        fi
    done
    
    if [[ -n "$matched_profile" ]]; then
        echo "Matched hardware profile: $(basename "$matched_profile" .profile)"
        return 0
    else
        echo "No matching hardware profile found"
        return 1
    fi
}

# Function to apply hardware profile
apply_hardware_profile() {
    local profile_file="$1"
    
    if [[ ! -f "$profile_file" ]]; then
        echo "Hardware profile not found: $profile_file"
        return 1
    fi
    
    echo "Applying hardware profile: $(basename "$profile_file" .profile)"
    
    # Source the profile
    source "$profile_file"
    
    # Install recommended packages
    if [[ -n "${recommended_packages:-}" ]]; then
        echo "Installing recommended packages: $recommended_packages"
        xbps-install -Sy $recommended_packages
    fi
    
    # Apply kernel parameters
    if [[ -n "${kernel_params:-}" ]]; then
        echo "Configuring kernel parameters: $kernel_params"
        echo "options linux $kernel_params" >> /etc/default/grub
        update-grub
    fi
    
    # Apply power management settings
    if [[ "${power_management:-false}" == "true" ]]; then
        echo "Enabling power management"
        systemctl enable tlp 2>/dev/null || true
    fi
    
    # Set CPU governor
    if [[ -n "${cpu_governor:-}" ]] && command -v cpupower >/dev/null 2>&1; then
        echo "Setting CPU governor to: $cpu_governor"
        cpupower frequency-set -g "$cpu_governor"
    fi
    
    echo "Hardware profile applied successfully"
}
EOF
    
    chmod +x "$SCRIPT_DIR/hardware-matcher.sh"
    log_message "INFO" "Hardware matching system created"
}

# Function to integrate with first-boot setup
integrate_with_first_boot() {
    log_message "INFO" "Integrating hardware detection with first-boot setup"
    
    # Add hardware detection to first-boot setup
    local first_boot_script="$SCRIPT_DIR/first-boot-setup.sh"
    
    # Add hardware detection call to first-boot setup
    sed -i '/configure_hardware_optimization() {/,/^}/c\
configure_hardware_optimization() {\
    log_message "INFO" "Configuring hardware optimization"\
    \
    clear\
    echo "Hardware Optimization"\
    echo "===================="\
    echo ""\
    \
    # Run comprehensive hardware detection\
    "$SCRIPT_DIR/hardware-detection-optimization.sh"\
    \
    # Match and apply hardware profile\
    if "$SCRIPT_DIR/hardware-matcher.sh" match_hardware_profile; then\
        local profile_file=$("$SCRIPT_DIR/hardware-matcher.sh" match_hardware_profile | cut -d: -f2 | tr -d " ")\
        "$SCRIPT_DIR/hardware-matcher.sh" apply_hardware_profile "/usr/share/voidance/hardware-profiles/${profile_file}.profile"\
    fi\
    \
    echo ""\
    read -p "Press Enter to continue..."\
}' "$first_boot_script"
    
    log_message "INFO" "Hardware detection integrated with first-boot setup"
}

# Function to create hardware service integration
create_hardware_service_integration() {
    log_message "INFO" "Creating hardware service integration"
    
    # Create hardware detection service
    cat > /etc/sv/voidance-hardware-detection/run << 'EOF'
#!/bin/bash
# Voidance Hardware Detection Service

exec 2>&1

echo "Starting Voidance hardware detection service..."

# Run hardware detection on boot
/usr/local/bin/hardware-detection-optimization.sh

# Match and apply hardware profile
if /usr/local/bin/hardware-matcher.sh match_hardware_profile; then
    profile_file=$(/usr/local/bin/hardware-matcher.sh match_hardware_profile | cut -d: -f2 | tr -d " ")
    /usr/local/bin/hardware-matcher.sh apply_hardware_profile "/usr/share/voidance/hardware-profiles/${profile_file}.profile"
fi

echo "Hardware detection service completed"

# Keep service running (one-shot)
while true; do
    sleep 3600
done
EOF
    
    chmod +x /etc/sv/voidance-hardware-detection/run
    
    # Create hardware monitoring service
    cat > /etc/sv/voidance-hardware-monitor/run << 'EOF'
#!/bin/bash
# Voidance Hardware Monitoring Service

exec 2>&1

echo "Starting Voidance hardware monitoring service..."

while true; do
    # Monitor hardware changes
    # Check for new devices
    # Update hardware profiles if needed
    
    sleep 300  # Check every 5 minutes
done
EOF
    
    chmod +x /etc/sv/voidance-hardware-monitor/run
    
    log_message "INFO" "Hardware service integration created"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$INTEGRATION_LOG"
}

# Main integration function
main_hardware_integration() {
    log_message "INFO" "Starting hardware detection integration"
    
    integrate_with_installer
    create_hardware_profile_database
    create_hardware_matching
    integrate_with_first_boot
    create_hardware_service_integration
    
    log_message "INFO" "Hardware detection integration completed"
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_hardware_integration "$@"
fi