#!/bin/bash
# Voidance Filesystem Integrity and Permissions Validation
# This script validates the complete filesystem structure and permissions

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[FS-VALIDATE]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Root filesystem base directory
ROOTFS_BASE="${1:-/opt/voidance-iso/work/rootfs}"
VALIDATION_LOG="/opt/voidance-iso/output/logs/filesystem-validation.log"

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Function to increment counters
increment_counters() {
    local result="$1"
    ((TOTAL_CHECKS++))
    
    case "$result" in
        "pass")
            ((PASSED_CHECKS++))
            ;;
        "fail")
            ((FAILED_CHECKS++))
            ;;
        "warn")
            ((WARNING_CHECKS++))
            ;;
    esac
}

# Function to check directory exists and has correct permissions
check_directory() {
    local path="$1"
    local expected_mode="$2"
    local expected_owner="$3"
    local expected_group="$4"
    local description="$5"
    
    log "Checking directory: $path ($description)"
    
    if [[ ! -d "$ROOTFS_BASE$path" ]]; then
        error "Directory missing: $path"
        echo "FAIL: Directory missing: $path ($description)" >> "$VALIDATION_LOG"
        increment_counters "fail"
        return 1
    fi
    
    local actual_mode=$(stat -c "%a" "$ROOTFS_BASE$path")
    local actual_owner=$(stat -c "%U" "$ROOTFS_BASE$path")
    local actual_group=$(stat -c "%G" "$ROOTFS_BASE$path")
    
    local issues=()
    
    if [[ "$actual_mode" != "$expected_mode" ]]; then
        issues+=("mode: $actual_mode (expected $expected_mode)")
    fi
    
    if [[ "$actual_owner" != "$expected_owner" ]]; then
        issues+=("owner: $actual_owner (expected $expected_owner)")
    fi
    
    if [[ "$actual_group" != "$expected_group" ]]; then
        issues+=("group: $actual_group (expected $expected_group)")
    fi
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        success "  ✓ Directory OK: $path"
        echo "PASS: Directory OK: $path ($description)" >> "$VALIDATION_LOG"
        increment_counters "pass"
        return 0
    else
        error "  ✗ Directory issues: $path - ${issues[*]}"
        echo "FAIL: Directory issues: $path - ${issues[*]} ($description)" >> "$VALIDATION_LOG"
        increment_counters "fail"
        return 1
    fi
}

# Function to check file exists and has correct permissions
check_file() {
    local path="$1"
    local expected_mode="$2"
    local expected_owner="$3"
    local expected_group="$4"
    local description="$5"
    
    log "Checking file: $path ($description)"
    
    if [[ ! -f "$ROOTFS_BASE$path" ]]; then
        error "File missing: $path"
        echo "FAIL: File missing: $path ($description)" >> "$VALIDATION_LOG"
        increment_counters "fail"
        return 1
    fi
    
    local actual_mode=$(stat -c "%a" "$ROOTFS_BASE$path")
    local actual_owner=$(stat -c "%U" "$ROOTFS_BASE$path")
    local actual_group=$(stat -c "%G" "$ROOTFS_BASE$path")
    
    local issues=()
    
    if [[ "$actual_mode" != "$expected_mode" ]]; then
        issues+=("mode: $actual_mode (expected $expected_mode)")
    fi
    
    if [[ "$actual_owner" != "$expected_owner" ]]; then
        issues+=("owner: $actual_owner (expected $expected_owner)")
    fi
    
    if [[ "$actual_group" != "$expected_group" ]]; then
        issues+=("group: $actual_group (expected $expected_group)")
    fi
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        success "  ✓ File OK: $path"
        echo "PASS: File OK: $path ($description)" >> "$VALIDATION_LOG"
        increment_counters "pass"
        return 0
    else
        error "  ✗ File issues: $path - ${issues[*]}"
        echo "FAIL: File issues: $path - ${issues[*]} ($description)" >> "$VALIDATION_LOG"
        increment_counters "fail"
        return 1
    fi
}

# Function to check symlink exists and points to correct target
check_symlink() {
    local path="$1"
    local expected_target="$2"
    local description="$3"
    
    log "Checking symlink: $path ($description)"
    
    if [[ ! -L "$ROOTFS_BASE$path" ]]; then
        error "Symlink missing: $path"
        echo "FAIL: Symlink missing: $path ($description)" >> "$VALIDATION_LOG"
        increment_counters "fail"
        return 1
    fi
    
    local actual_target=$(readlink "$ROOTFS_BASE$path")
    
    if [[ "$actual_target" == "$expected_target" ]]; then
        success "  ✓ Symlink OK: $path -> $actual_target"
        echo "PASS: Symlink OK: $path -> $actual_target ($description)" >> "$VALIDATION_LOG"
        increment_counters "pass"
        return 0
    else
        error "  ✗ Symlink target mismatch: $path -> $actual_target (expected $expected_target)"
        echo "FAIL: Symlink target mismatch: $path -> $actual_target (expected $expected_target) ($description)" >> "$VALIDATION_LOG"
        increment_counters "fail"
        return 1
    fi
}

# Function to validate essential directories
validate_essential_directories() {
    log "Validating essential directories..."
    
    local essential_dirs=(
        "/:755:root:root:Root directory"
        "/bin:755:root:root:Essential user binaries"
        "/boot:750:root:root:Boot loader files"
        "/dev:755:root:root:Device files"
        "/etc:755:root:root:Configuration files"
        "/home:755:root:root:User home directories"
        "/lib:755:root:root:Essential shared libraries"
        "/lib64:755:root:root:64-bit shared libraries"
        "/media:755:root:root:Media mount points"
        "/mnt:755:root:root:Temporary mount points"
        "/opt:755:root:root:Optional software"
        "/proc:555:root:root:Process information"
        "/root:700:root:root:Root home directory"
        "/run:755:root:root:Run-time data"
        "/sbin:755:root:root:System binaries"
        "/srv:755:root:root:Service data"
        "/sys:555:root:root:System information"
        "/tmp:1777:root:root:Temporary files"
        "/usr:755:root:root:User programs"
        "/var:755:root:root:Variable data"
    )
    
    for dir_info in "${essential_dirs[@]}"; do
        IFS=':' read -r path mode owner group description <<< "$dir_info"
        check_directory "$path" "$mode" "$owner" "$group" "$description"
    done
}

# Function to validate user program directories
validate_user_program_directories() {
    log "Validating user program directories..."
    
    local user_dirs=(
        "/usr/bin:755:root:root:User binaries"
        "/usr/include:755:root:root:Header files"
        "/usr/lib:755:root:root:Libraries"
        "/usr/lib64:755:root:root:64-bit libraries"
        "/usr/local:755:root:root:Local software"
        "/usr/local/bin:755:root:root:Local binaries"
        "/usr/local/include:755:root:root:Local headers"
        "/usr/local/lib:755:root:root:Local libraries"
        "/usr/local/lib64:755:root:root:Local 64-bit libraries"
        "/usr/sbin:755:root:root:System binaries"
        "/usr/share:755:root:root:Architecture-independent data"
        "/usr/src:755:root:root:Source code"
    )
    
    for dir_info in "${user_dirs[@]}"; do
        IFS=':' read -r path mode owner group description <<< "$dir_info"
        check_directory "$path" "$mode" "$owner" "$group" "$description"
    done
}

# Function to validate variable data directories
validate_variable_directories() {
    log "Validating variable data directories..."
    
    local var_dirs=(
        "/var/cache:755:root:root:Application cache"
        "/var/db:755:root:root:Variable database files"
        "/var/empty:755:root:root:Secure empty directory"
        "/var/games:755:root:root:Game variable data"
        "/var/lib:755:root:root:Variable state information"
        "/var/local:755:root:root:Local variable data"
        "/var/lock:1777:root:root:Lock files"
        "/var/log:755:root:root:Log files"
        "/var/mail:1777:root:root:Mail spool"
        "/var/opt:755:root:root:Optional variable data"
        "/var/run:755:root:root:Process PID files"
        "/var/spool:755:root:root:Printer spool"
        "/var/tmp:1777:root:root:Temporary files preserved"
    )
    
    for dir_info in "${var_dirs[@]}"; do
        IFS=':' read -r path mode owner group description <<< "$dir_info"
        check_directory "$path" "$mode" "$owner" "$group" "$description"
    done
}

# Function to validate Voidance-specific directories
validate_voidance_directories() {
    log "Validating Voidance-specific directories..."
    
    local voidance_dirs=(
        "/etc/voidance:755:root:root:Voidance configuration"
        "/etc/voidance/config:755:root:root:Voidance config files"
        "/etc/voidance/scripts:755:root:root:Voidance scripts"
        "/etc/voidance/templates:755:root:root:Voidance templates"
        "/var/lib/voidance:755:root:root:Voidance state"
        "/var/lib/voidance/hardware:755:root:root:Hardware profiles"
        "/var/lib/voidance/profiles:755:root:root:User profiles"
        "/var/lib/voidance/state:755:root:root:System state"
        "/var/log/voidance:755:root:root:Voidance logs"
        "/var/log/voidance/install:755:root:root:Install logs"
        "/var/log/voidance/setup:755:root:root:Setup logs"
    )
    
    for dir_info in "${voidance_dirs[@]}"; do
        IFS=':' read -r path mode owner group description <<< "$dir_info"
        check_directory "$path" "$mode" "$owner" "$group" "$description"
    done
}

# Function to validate desktop environment directories
validate_desktop_directories() {
    log "Validating desktop environment directories..."
    
    local desktop_dirs=(
        "/etc/X11:755:root:root:X11 configuration"
        "/etc/xdg:755:root:root:XDG configuration"
        "/etc/skel:755:root:root:User skeleton"
        "/usr/share/applications:755:root:root:Desktop applications"
        "/usr/share/desktop-directories:755:root:root:Desktop directories"
        "/usr/share/icons:755:root:root:Icons"
        "/usr/share/pixmaps:755:root:root:Pixmaps"
        "/usr/share/themes:755:root:root:Themes"
        "/usr/share/backgrounds:755:root:root:Backgrounds"
        "/usr/share/fonts:755:root:root:Fonts"
        "/usr/share/sounds:755:root:root:Sounds"
        "/usr/share/mime:755:root:root:MIME types"
        "/usr/share/wayland-sessions:755:root:root:Wayland sessions"
    )
    
    for dir_info in "${desktop_dirs[@]}"; do
        IFS=':' read -r path mode owner group description <<< "$dir_info"
        check_directory "$path" "$mode" "$owner" "$group" "$description"
    done
}

# Function to validate system service directories
validate_service_directories() {
    log "Validating system service directories..."
    
    local service_dirs=(
        "/etc/runit:755:root:root:Runit configuration"
        "/etc/sv:755:root:root:Runit services"
        "/var/service:755:root:root:Active services"
        "/var/lib/sv:755:root:root:Service state"
        "/etc/security:755:root:root:Security configuration"
        "/etc/security/limits.d:755:root:root:Security limits"
        "/etc/security/pam.d:755:root:root:PAM configuration"
        "/etc/pam.d:755:root:root:PAM configuration"
        "/etc/modprobe.d:755:root:root:Kernel modules"
        "/etc/modules-load.d:755:root:root:Module loading"
        "/etc/udev:755:root:root:Udev configuration"
        "/etc/udev/rules.d:755:root:root:Udev rules"
        "/lib/udev:755:root:root:Udev helpers"
        "/lib/udev/rules.d:755:root:root:Udev rules"
    )
    
    for dir_info in "${service_dirs[@]}"; do
        IFS=':' read -r path mode owner group description <<< "$dir_info"
        check_directory "$path" "$mode" "$owner" "$group" "$description"
    done
}

# Function to validate essential configuration files
validate_essential_files() {
    log "Validating essential configuration files..."
    
    local essential_files=(
        "/etc/fstab:644:root:root:Filesystem table"
        "/etc/hostname:644:root:root:Hostname configuration"
        "/etc/hosts:644:root:root:Hosts file"
        "/etc/resolv.conf:644:root:root:DNS configuration"
        "/etc/passwd:644:root:root:User database"
        "/etc/shadow:640:root:shadow:Password database"
        "/etc/group:644:root:root:Group database"
        "/etc/gshadow:640:root:shadow:Group passwords"
        "/etc/profile:644:root:root:System profile"
        "/etc/bash.bashrc:644:root:root:Bash configuration"
        "/etc/os-release:644:root:root:OS release information"
        "/etc/lsb-release:644:root:root:LSB release information"
        "/etc/issue:644:root:root:Login message"
        "/etc/motd:644:root:root:Message of the day"
        "/etc/locale.conf:644:root:root:Locale configuration"
        "/etc/timezone:644:root:root:Timezone configuration"
        "/etc/machine-id:644:root:root:Machine ID"
    )
    
    for file_info in "${essential_files[@]}"; do
        IFS=':' read -r path mode owner group description <<< "$file_info"
        check_file "$path" "$mode" "$owner" "$group" "$description"
    done
}

# Function to validate Voidance configuration files
validate_voidance_files() {
    log "Validating Voidance configuration files..."
    
    local voidance_files=(
        "/etc/voidance/voidance.conf:644:root:root:Voidance main configuration"
        "/etc/voidance/environment:644:root:root:Voidance environment"
        "/etc/voidance/directory-hierarchy.md:644:root:root:Directory documentation"
        "/etc/voidance/service-deps:644:root:root:Service dependencies"
        "/etc/voidance/service-order:644:root:root:Service startup order"
    )
    
    for file_info in "${voidance_files[@]}"; do
        IFS=':' read -r path mode owner group description <<< "$file_info"
        check_file "$path" "$mode" "$owner" "$group" "$description"
    done
}

# Function to validate user skeleton files
validate_skeleton_files() {
    log "Validating user skeleton files..."
    
    local skeleton_files=(
        "/etc/skel/.bashrc:600:root:root:User bash configuration"
        "/etc/skel/.profile:600:root:root:User profile"
        "/etc/skel/.gitconfig:600:root:root:Git configuration"
        "/etc/skel/.config/user-dirs.dirs:600:root:root:User directories"
        "/etc/skel/Desktop:700:root:root:Desktop directory"
        "/etc/skel/Documents:700:root:root:Documents directory"
        "/etc/skel/Downloads:700:root:root:Downloads directory"
        "/etc/skel/Music:700:root:root:Music directory"
        "/etc/skel/Pictures:700:root:root:Pictures directory"
        "/etc/skel/Public:700:root:root:Public directory"
        "/etc/skel/Templates:700:root:root:Templates directory"
        "/etc/skel/Videos:700:root:root:Videos directory"
        "/etc/skel/.config:700:root:root:Config directory"
        "/etc/skel/.local:700:root:root:Local directory"
        "/etc/skel/.local/share:700:root:root:Local share"
        "/etc/skel/.local/state:700:root:root:Local state"
        "/etc/skel/.cache:700:root:root:Cache directory"
    )
    
    for file_info in "${skeleton_files[@]}"; do
        IFS=':' read -r path mode owner group description <<< "$file_info"
        check_file "$path" "$mode" "$owner" "$group" "$description"
    done
}

# Function to validate system symlinks
validate_system_symlinks() {
    log "Validating system symlinks..."
    
    local system_symlinks=(
        "/bin/sh:/bin/bash:Shell symlink"
        "/usr/bin:/bin:User binaries symlink"
        "/usr/sbin:/sbin:System binaries symlink"
        "/usr/lib:/lib:Libraries symlink"
        "/usr/lib64:/lib64:64-bit libraries symlink"
        "/var/run:/run:Run directory symlink"
        "/run/lock:/var/lock:Lock directory symlink"
        "/dev/fd:/proc/self/fd:File descriptor symlink"
        "/dev/stdin:/proc/self/fd/0:Standard input symlink"
        "/dev/stdout:/proc/self/fd/1:Standard output symlink"
        "/dev/stderr:/proc/self/fd/2:Standard error symlink"
    )
    
    for symlink_info in "${system_symlinks[@]}"; do
        IFS=':' read -r path target description <<< "$symlink_info"
        check_symlink "$path" "$target" "$description"
    done
}

# Function to validate service scripts
validate_service_scripts() {
    log "Validating service scripts..."
    
    # Check if service directory exists
    if [[ ! -d "$ROOTFS_BASE/etc/sv" ]]; then
        error "Service directory missing: /etc/sv"
        echo "FAIL: Service directory missing: /etc/sv" >> "$VALIDATION_LOG"
        increment_counters "fail"
        return 1
    fi
    
    # Check essential services
    local essential_services=(
        "getty-1"
        "getty-2"
        "getty-3"
        "getty-4"
        "getty-5"
        "getty-6"
        "sulogin"
        "udevd"
        "dbus"
        "elogind"
    )
    
    for service in "${essential_services[@]}"; do
        local service_path="/etc/sv/$service/run"
        
        if [[ -f "$ROOTFS_BASE$service_path" ]]; then
            if [[ -x "$ROOTFS_BASE$service_path" ]]; then
                success "  ✓ Service script OK: $service"
                echo "PASS: Service script OK: $service" >> "$VALIDATION_LOG"
                increment_counters "pass"
            else
                error "  ✗ Service script not executable: $service"
                echo "FAIL: Service script not executable: $service" >> "$VALIDATION_LOG"
                increment_counters "fail"
            fi
        else
            error "  ✗ Service script missing: $service"
            echo "FAIL: Service script missing: $service" >> "$VALIDATION_LOG"
            increment_counters "fail"
        fi
    done
}

# Function to validate filesystem structure compliance
validate_fhs_compliance() {
    log "Validating FHS compliance..."
    
    # Check FHS required directories
    local fhs_required=(
        "/bin"
        "/boot"
        "/dev"
        "/etc"
        "/home"
        "/lib"
        "/media"
        "/mnt"
        "/opt"
        "/proc"
        "/root"
        "/run"
        "/sbin"
        "/srv"
        "/sys"
        "/tmp"
        "/usr"
        "/var"
    )
    
    for dir in "${fhs_required[@]}"; do
        if [[ -d "$ROOTFS_BASE$dir" ]]; then
            success "  ✓ FHS directory present: $dir"
            echo "PASS: FHS directory present: $dir" >> "$VALIDATION_LOG"
            increment_counters "pass"
        else
            error "  ✗ FHS directory missing: $dir"
            echo "FAIL: FHS directory missing: $dir" >> "$VALIDATION_LOG"
            increment_counters "fail"
        fi
    done
    
    # Check for FHS violations (common mistakes)
    local fhs_violations=(
        "/usr/tmp"
        "/usr/var"
        "/etc/tmp"
        "/bin/var"
        "/lib/tmp"
    )
    
    for violation in "${fhs_violations[@]}"; do
        if [[ -e "$ROOTFS_BASE$violation" ]]; then
            warning "  ⚠ Potential FHS violation: $violation"
            echo "WARN: Potential FHS violation: $violation" >> "$VALIDATION_LOG"
            increment_counters "warn"
        fi
    done
}

# Function to validate security permissions
validate_security_permissions() {
    log "Validating security permissions..."
    
    # Check sensitive file permissions
    local sensitive_files=(
        "/etc/shadow:640"
        "/etc/gshadow:640"
        "/etc/passwd:644"
        "/etc/group:644"
        "/etc/sudoers:440"
        "/root:700"
        "/tmp:1777"
        "/var/tmp:1777"
        "/var/lock:1777"
        "/run/lock:1777"
    )
    
    for file_info in "${sensitive_files[@]}"; do
        IFS=':' read -r path expected_mode <<< "$file_info"
        
        if [[ -e "$ROOTFS_BASE$path" ]]; then
            local actual_mode
            if [[ -d "$ROOTFS_BASE$path" ]]; then
                actual_mode=$(stat -c "%a" "$ROOTFS_BASE$path")
            else
                actual_mode=$(stat -c "%a" "$ROOTFS_BASE$path")
            fi
            
            if [[ "$actual_mode" == "$expected_mode" ]]; then
                success "  ✓ Security permissions OK: $path ($actual_mode)"
                echo "PASS: Security permissions OK: $path ($actual_mode)" >> "$VALIDATION_LOG"
                increment_counters "pass"
            else
                warning "  ⚠ Security permissions issue: $path ($actual_mode, expected $expected_mode)"
                echo "WARN: Security permissions issue: $path ($actual_mode, expected $expected_mode)" >> "$VALIDATION_LOG"
                increment_counters "warn"
            fi
        else
            error "  ✗ Sensitive file missing: $path"
            echo "FAIL: Sensitive file missing: $path" >> "$VALIDATION_LOG"
            increment_counters "fail"
        fi
    done
}

# Function to generate validation report
generate_validation_report() {
    log "Generating validation report..."
    
    cat >> "$VALIDATION_LOG" << EOF

===============================================================================
Voidance Filesystem Validation Report
===============================================================================
Date: $(date)
Root Filesystem: $ROOTFS_BASE

Validation Summary:
- Total Checks: $TOTAL_CHECKS
- Passed: $PASSED_CHECKS
- Failed: $FAILED_CHECKS
- Warnings: $WARNING_CHECKS

Success Rate: $(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))%

Validation Status: $([ $FAILED_CHECKS -eq 0 ] && echo "PASSED" || echo "FAILED")

EOF
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        success "Filesystem validation PASSED"
        success "Success rate: $(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))%"
        return 0
    else
        error "Filesystem validation FAILED"
        error "Failed checks: $FAILED_CHECKS"
        error "Success rate: $(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))%"
        return 1
    fi
}

# Function to fix common issues
fix_common_issues() {
    log "Attempting to fix common issues..."
    
    local fixes=0
    
    # Fix missing directories
    local missing_dirs=(
        "/var/lock"
        "/run/lock"
        "/run/shm"
        "/run/user"
    )
    
    for dir in "${missing_dirs[@]}"; do
        if [[ ! -d "$ROOTFS_BASE$dir" ]]; then
            mkdir -p "$ROOTFS_BASE$dir"
            if [[ "$dir" =~ lock|shm|user ]]; then
                chmod 1777 "$ROOTFS_BASE$dir"
            else
                chmod 755 "$ROOTFS_BASE$dir"
            fi
            chown root:root "$ROOTFS_BASE$dir"
            log "Fixed missing directory: $dir"
            ((fixes++))
        fi
    done
    
    # Fix missing symlinks
    local missing_symlinks=(
        "/var/run:/run"
        "/run/lock:/var/lock"
    )
    
    for symlink_info in "${missing_symlinks[@]}"; do
        IFS=':' read -r path target <<< "$symlink_info"
        if [[ ! -L "$ROOTFS_BASE$path" ]]; then
            mkdir -p "$(dirname "$ROOTFS_BASE$path")"
            ln -sf "$target" "$ROOTFS_BASE$path"
            log "Fixed missing symlink: $path -> $target"
            ((fixes++))
        fi
    done
    
    if [[ $fixes -gt 0 ]]; then
        success "Fixed $fixes common issues"
    else
        log "No common issues to fix"
    fi
}

# Main validation function
main() {
    log "Starting Voidance filesystem integrity and permissions validation..."
    
    # Initialize validation log
    mkdir -p "$(dirname "$VALIDATION_LOG")"
    cat > "$VALIDATION_LOG" << EOF
Voidance Filesystem Validation Log
==================================
Date: $(date)
Root Filesystem: $ROOTFS_BASE

EOF
    
    # Check if rootfs exists
    if [[ ! -d "$ROOTFS_BASE" ]]; then
        error "Root filesystem not found: $ROOTFS_BASE"
    fi
    
    # Run all validations
    validate_essential_directories
    validate_user_program_directories
    validate_variable_directories
    validate_voidance_directories
    validate_desktop_directories
    validate_service_directories
    validate_essential_files
    validate_voidance_files
    validate_skeleton_files
    validate_system_symlinks
    validate_service_scripts
    validate_fhs_compliance
    validate_security_permissions
    
    # Generate report
    generate_validation_report
    
    # Print summary
    log "Validation Summary:"
    log "  Total Checks: $TOTAL_CHECKS"
    log "  Passed: $PASSED_CHECKS"
    log "  Failed: $FAILED_CHECKS"
    log "  Warnings: $WARNING_CHECKS"
    log "  Success Rate: $(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))%"
    log "  Log File: $VALIDATION_LOG"
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        success "Filesystem validation completed successfully"
        return 0
    else
        error "Filesystem validation failed with $FAILED_CHECKS errors"
        return 1
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-validate}" in
        "validate")
            main
            ;;
        "fix")
            fix_common_issues
            ;;
        "validate-fix")
            main || {
                log "Attempting to fix issues..."
                fix_common_issues
                log "Re-running validation..."
                main
            }
            ;;
        *)
            echo "Usage: $0 {validate|fix|validate-fix}"
            echo ""
            echo "Commands:"
            echo "  validate     - Validate filesystem integrity and permissions"
            echo "  fix          - Fix common issues"
            echo "  validate-fix - Validate and fix issues automatically"
            exit 1
            ;;
    esac
fi