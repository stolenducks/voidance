# Voidance Kernel Configuration
# This file defines kernel parameters and boot options for the Voidance ISO

# Kernel version and configuration
KERNEL_VERSION="latest"
KERNEL_FLAVOR="generic"

# Basic kernel parameters for live system
KERNEL_CMDLINE_BASE="loglevel=4 quiet splash"

# Hardware-specific parameters
KERNEL_CMDLINE_HARDWARE="pci=nomsi acpi_osi=! acpi_osi=\"Windows 2009\""

# Filesystem parameters
KERNEL_CMDLINE_FS="root=live:CDLABEL=Voidance rootflags=ro"

# Display parameters
KERNEL_CMDLINE_DISPLAY="video=efifb:off"

# Network parameters
KERNEL_CMDLINE_NET="net.ifnames=0 biosdevname=0"

# Security parameters
KERNEL_CMDLINE_SECURITY="selinux=0 apparmor=0"

# Performance parameters
KERNEL_CMDLINE_PERF="mitigations=off"

# Debug parameters (disabled by default)
KERNEL_CMDLINE_DEBUG=""

# Complete kernel command line
KERNEL_CMDLINE="${KERNEL_CMDLINE_BASE} ${KERNEL_CMDLINE_HARDWARE} ${KERNEL_CMDLINE_FS} ${KERNEL_CMDLINE_DISPLAY} ${KERNEL_CMDLINE_NET} ${KERNEL_CMDLINE_SECURITY} ${KERNEL_CMDLINE_PERF}"

# UEFI boot configuration
EFI_BOOTLOADER="grub"
EFI_STANDALONE="yes"
EFI_ARCH="x86_64"

# Legacy BIOS boot configuration
BIOS_BOOTLOADER="syslinux"
BIOS_ARCH="i386"

# Boot timeout configuration
BOOT_TIMEOUT="5"
BOOT_DEFAULT="voidance"

# Boot menu entries
BOOT_ENTRIES=(
    "voidance:Start Voidance Live"
    "voidance-nomodeset:Start Voidance (Safe Mode)"
    "voidance-debug:Start Voidance (Debug Mode)"
    "voidance-failsafe:Start Voidance (Failsafe)"
)

# Safe mode kernel parameters
SAFE_MODE_CMDLINE="${KERNEL_CMDLINE_BASE} nomodeset xforcevesa noapic noacpi"

# Debug mode kernel parameters
DEBUG_MODE_CMDLINE="${KERNEL_CMDLINE_BASE} debug systemd.log_level=debug"

# Failsafe mode kernel parameters
FAILSAFE_CMDLINE="init=/bin/bash ${KERNEL_CMDLINE_BASE}"

# Hardware-specific boot options
declare -A HARDWARE_BOOT_OPTS
HARDWARE_BOOT_OPTS["nvidia"]="nvidia-drm.modeset=1"
HARDWARE_BOOT_OPTS["amd"]="amdgpu.dc=1"
HARDWARE_BOOT_OPTS["intel"]="i915.modeset=1"
HARDWARE_BOOT_OPTS["virtualbox"]="vboxvideo"

# Memory requirements
MIN_MEMORY="1024"
RECOMMENDED_MEMORY="2048"

# Storage requirements
MIN_STORAGE="8"
RECOMMENDED_STORAGE="20"

# Supported architectures
SUPPORTED_ARCHS=("x86_64")

# Boot loader themes
BOOT_THEME="voidance"
BOOT_RESOLUTION="1920x1080"

# GRUB configuration
GRUB_TIMEOUT_STYLE="menu"
GRUB_DISTRIBUTOR="Voidance"
GRUB_CMDLINE_LINUX_DEFAULT="${KERNEL_CMDLINE}"
GRUB_CMDLINE_LINUX=""

# Syslinux configuration
SYSLINUX_TIMEOUT="50"
SYSLINUX_PROMPT="1"
SYSLINUX_DEFAULT="voidance"

# EFI stub configuration
EFI_STUB_CMDLINE="${KERNEL_CMDLINE}"
EFI_STUB_INITRD="initrd.img"

# Secure boot configuration
SECURE_BOOT="no"
SECURE_BOOT_ENROLL_KEYS="no"

# Boot splash configuration
SPLASH_IMAGE="voidance-splash.png"
SPLASH_THEME="voidance"

# Plymouth configuration
PLYMOUTH_THEME="voidance"
PLYMOUTH_DELAY="5"

# Function to generate kernel command line for specific mode
generate_kernel_cmdline() {
    local mode=${1:-"normal"}
    
    case "$mode" in
        "safe")
            echo "$SAFE_MODE_CMDLINE"
            ;;
        "debug")
            echo "$DEBUG_MODE_CMDLINE"
            ;;
        "failsafe")
            echo "$FAILSAFE_CMDLINE"
            ;;
        "normal"|*)
            echo "$KERNEL_CMDLINE"
            ;;
    esac
}

# Function to add hardware-specific options
add_hardware_opts() {
    local hardware=${1:-""}
    local base_cmdline=${2:-"$KERNEL_CMDLINE"}
    
    if [[ -n "${HARDWARE_BOOT_OPTS[$hardware]:-}" ]]; then
        echo "${base_cmdline} ${HARDWARE_BOOT_OPTS[$hardware]}"
    else
        echo "$base_cmdline"
    fi
}

# Function to validate kernel parameters
validate_kernel_cmdline() {
    local cmdline="$1"
    
    # Check for required parameters
    if [[ ! "$cmdline" =~ root= ]]; then
        echo "Warning: Missing root parameter"
        return 1
    fi
    
    if [[ ! "$cmdline" =~ loglevel= ]]; then
        echo "Warning: Missing loglevel parameter"
        return 1
    fi
    
    return 0
}

# Function to generate GRUB configuration
generate_grub_config() {
    local output_file="$1"
    
    cat > "$output_file" << EOF
# Voidance GRUB Configuration
set timeout=${BOOT_TIMEOUT}
set default=${BOOT_DEFAULT}
set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

# Menu entries
EOF

    for entry in "${BOOT_ENTRIES[@]}"; do
        local name=$(echo "$entry" | cut -d: -f1)
        local desc=$(echo "$entry" | cut -d: -f2)
        local cmdline
        
        case "$name" in
            "voidance-nomodeset")
                cmdline=$(generate_kernel_cmdline "safe")
                ;;
            "voidance-debug")
                cmdline=$(generate_kernel_cmdline "debug")
                ;;
            "voidance-failsafe")
                cmdline=$(generate_kernel_cmdline "failsafe")
                ;;
            *)
                cmdline="$KERNEL_CMDLINE"
                ;;
        esac
        
        cat >> "$output_file" << EOF
menuentry "${desc}" {
    linux /boot/vmlinuz-${KERNEL_VERSION} ${cmdline}
    initrd /boot/initramfs-${KERNEL_VERSION}.img
}

EOF
    done
}

# Function to generate Syslinux configuration
generate_syslinux_config() {
    local output_file="$1"
    
    cat > "$output_file" << EOF
# Voidance Syslinux Configuration
DEFAULT ${BOOT_DEFAULT}
PROMPT ${SYSLINUX_PROMPT}
TIMEOUT ${SYSLINUX_TIMEOUT}
LABEL voidance
    MENU LABEL Start Voidance Live
    KERNEL /boot/vmlinuz-${KERNEL_VERSION}
    APPEND ${KERNEL_CMDLINE}
    INITRD /boot/initramfs-${KERNEL_VERSION}.img

LABEL voidance-nomodeset
    MENU LABEL Start Voidance (Safe Mode)
    KERNEL /boot/vmlinuz-${KERNEL_VERSION}
    APPEND ${SAFE_MODE_CMDLINE}
    INITRD /boot/initramfs-${KERNEL_VERSION}.img

LABEL voidance-debug
    MENU LABEL Start Voidance (Debug Mode)
    KERNEL /boot/vmlinuz-${KERNEL_VERSION}
    APPEND ${DEBUG_MODE_CMDLINE}
    INITRD /boot/initramfs-${KERNEL_VERSION}.img

LABEL voidance-failsafe
    MENU LABEL Start Voidance (Failsafe)
    KERNEL /boot/vmlinuz-${KERNEL_VERSION}
    APPEND ${FAILSAFE_CMDLINE}
    INITRD /boot/initramfs-${KERNEL_VERSION}.img
EOF
}

# Export functions for use in other scripts
export -f generate_kernel_cmdline add_hardware_opts validate_kernel_cmdline
export -f generate_grub_config generate_syslinux_config