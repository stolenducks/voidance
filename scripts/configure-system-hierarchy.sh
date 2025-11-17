#!/bin/bash
# Voidance System Directories and Hierarchy Configuration
# This script configures the complete system directory hierarchy

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[SYS-HIERARCHY]${NC} $1"
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

# Function to create directory with metadata
create_directory() {
    local path="$1"
    local mode="${2:-755}"
    local owner="${3:-root}"
    local group="${4:-root}"
    local description="${5:-System directory}"
    
    mkdir -p "$path"
    chmod "$mode" "$path"
    chown "$owner:$group" "$path"
    
    # Create .directory_info file for documentation
    cat > "$path/.directory_info" << EOF
# Voidance Directory Information
# Path: $path
# Purpose: $description
# Permissions: $mode
# Owner: $owner:$group
# Created: $(date)
EOF
    
    log "Created directory: $path ($description)"
}

# Function to create hierarchy configuration
create_hierarchy_config() {
    local config_file="$1"
    
    cat > "$config_file" << 'EOF'
# Voidance System Directory Hierarchy Configuration
# This file defines the complete directory structure and metadata

# Directory hierarchy follows FHS (Filesystem Hierarchy Standard)
# with Voidance-specific additions for desktop environment

# ============================================================================
# ESSENTIAL DIRECTORIES (FHS 3.0)
# ============================================================================

# Root directory - root of the entire filesystem
/ 755 root root "Root filesystem"

# Essential user binaries - contains executables needed for booting
/bin 755 root root "Essential user binaries"

# Boot loader files - contains boot loader configuration and files
/boot 750 root root "Boot loader files"

# Device files - contains device nodes (created by kernel)
/dev 755 root root "Device files"

# Configuration files - host-specific system-wide configuration files
/etc 755 root root "Configuration files"

# Home directories - user home directories
/home 755 root root "User home directories"

# Essential shared libraries - libraries needed by binaries in /bin and /sbin
/lib 755 root root "Essential shared libraries"

# 64-bit libraries - 64-bit shared libraries (on x86_64 systems)
/lib64 755 root root "64-bit shared libraries"

# Media mount points - mount point for removable media
/media 755 root root "Media mount points"

# Temporary mount points - temporary mount directory
/mnt 755 root root "Temporary mount points"

# Optional software - add-on application software packages
/opt 755 root root "Optional software"

# Process information - kernel and process information virtual filesystem
/proc 555 root root "Process information"

# Root home directory - root user's home directory
/root 700 root root "Root home directory"

# Run-time data - run-time variable data
/run 755 root root "Run-time data"

# System binaries - essential system binaries
/sbin 755 root root "System binaries"

# Service data - site-specific data served by this system
/srv 755 root root "Service data"

# Temporary files - temporary files
/tmp 1777 root root "Temporary files"

# User programs - secondary hierarchy for user data and programs
/usr 755 root root "User programs"

# Variable data - variable data files
/var 755 root root "Variable data"

# ============================================================================
# USER PROGRAM HIERARCHY (/usr)
# ============================================================================

# User binaries - majority of user programs
/usr/bin 755 root root "User binaries"

# Header files - C header files
/usr/include 755 root root "Header files"

# Libraries - programming libraries
/usr/lib 755 root root "Libraries"

# 64-bit libraries - 64-bit programming libraries
/usr/lib64 755 root root "64-bit libraries"

# Local binaries - local binaries
/usr/local/bin 755 root root "Local binaries"

# Local libraries - local libraries
/usr/local/lib 755 root root "Local libraries"

# Local 64-bit libraries - local 64-bit libraries
/usr/local/lib64 755 root root "Local 64-bit libraries"

# System binaries - non-essential system binaries
/usr/sbin 755 root root "System binaries"

# Architecture-independent data - architecture-independent data
/usr/share 755 root root "Architecture-independent data"

# Source code - source code
/usr/src 755 root root "Source code"

# ============================================================================
# VARIABLE DATA HIERARCHY (/var)
# ============================================================================

# Application cache data - application cache data
/var/cache 755 root root "Application cache data"

# Variable database files - variable database files
/var/db 755 root root "Variable database files"

# Empty directory - secure empty directory for unprivileged processes
/var/empty 755 root root "Empty directory"

# Game variable data - game variable data
/var/games 755 root root "Game variable data"

# Variable state information - variable state information
/var/lib 755 root root "Variable state information"

# Local variable data - local variable data
/var/local 755 root root "Local variable data"

# Log files - log files
/var/log 755 root root "Log files"

# Mail spool - mail spool
/var/mail 1777 root root "Mail spool"

# Optional variable data - optional variable data
/var/opt 755 root root "Optional variable data"

# Process PID files - process PID files
/var/run 755 root root "Process PID files"

# Printer spool - printer spool
/var/spool 755 root root "Printer spool"

# Temporary files - temporary files preserved between reboots
/var/tmp 1777 root root "Temporary files"

# ============================================================================
# VOIDANCE-SPECIFIC DIRECTORIES
# ============================================================================

# Voidance configuration - Voidance-specific configuration
/etc/voidance 755 root root "Voidance configuration"

# Voidance scripts - Voidance management scripts
/etc/voidance/scripts 755 root root "Voidance scripts"

# Voidance templates - Voidance configuration templates
/etc/voidance/templates 755 root root "Voidance templates"

# Voidance state - Voidance state information
/var/lib/voidance 755 root root "Voidance state"

# Voidance logs - Voidance-specific logs
/var/log/voidance 755 root root "Voidance logs"

# ============================================================================
# DESKTOP ENVIRONMENT DIRECTORIES
# ============================================================================

# X11 configuration - X Window System configuration
/etc/X11 755 root root "X11 configuration"

# XDG configuration - XDG Base Directory specification
/etc/xdg 755 root root "XDG configuration"

# User skeleton - skeleton for new user home directories
/etc/skel 755 root root "User skeleton"

# Desktop applications - desktop application files
/usr/share/applications 755 root root "Desktop applications"

# Desktop directories - desktop directory definitions
/usr/share/desktop-directories 755 root root "Desktop directories"

# Icons - icon files
/usr/share/icons 755 root root "Icons"

# Themes - theme files
/usr/share/themes 755 root root "Themes"

# Fonts - font files
/usr/share/fonts 755 root root "Fonts"

# Wayland sessions - Wayland session files
/usr/share/wayland-sessions 755 root root "Wayland sessions"

# ============================================================================
# SYSTEM SERVICE DIRECTORIES
# ============================================================================

# Runit services - Runit service definitions
/etc/sv 755 root root "Runit services"

# Active services - currently active services
/var/service 755 root root "Active services"

# Service state - service state information
/var/lib/sv 755 root root "Service state"

# ============================================================================
# SECURITY DIRECTORIES
# ============================================================================

# Security configuration - security-related configuration
/etc/security 755 root root "Security configuration"

# PAM configuration - Pluggable Authentication Modules
/etc/pam.d 755 root root "PAM configuration"

# ============================================================================
# HARDWARE DIRECTORIES
# ============================================================================

# Kernel modules - kernel module configuration
/etc/modprobe.d 755 root root "Kernel modules"

# Module loading - module loading configuration
/etc/modules-load.d 755 root root "Module loading"

# Udev rules - udev device rules
/etc/udev/rules.d 755 root root "Udev rules"

# ============================================================================
# NETWORK DIRECTORIES
# ============================================================================

# Network configuration - network configuration
/etc/network 755 root root "Network configuration"

# Network interfaces - network interface configuration
/etc/network/interfaces.d 755 root root "Network interfaces"

# ============================================================================
# FONT DIRECTORIES
# ============================================================================

# Font configuration - font configuration
/etc/fonts 755 root root "Font configuration"

# Font cache - font cache directory
/var/cache/fontconfig 755 root root "Font cache"

# ============================================================================
# DOCUMENTATION DIRECTORIES
# ============================================================================

# Manual pages - manual pages
/usr/share/man 755 root root "Manual pages"

# Info pages - info documentation
/usr/share/info 755 root root "Info pages"

# Documentation - package documentation
/usr/share/doc 755 root root "Documentation"

# ============================================================================
# DEVELOPMENT DIRECTORIES
# ============================================================================

# Local source - local source code
/usr/local/src 755 root root "Local source"

# Include files - C/C++ header files
/usr/include 755 root root "Include files"

# Local include - local C/C++ header files
/usr/local/include 755 root root "Local include"

# ============================================================================
# MULTIMEDIA DIRECTORIES
# ============================================================================

# Sounds - system sounds
/usr/share/sounds 755 root root "Sounds"

# Backgrounds - desktop backgrounds
/usr/share/backgrounds 755 root root "Backgrounds"

# MIME types - MIME type definitions
/usr/share/mime 755 root root "MIME types"

# ============================================================================
# VIRTUALIZATION DIRECTORIES
# ============================================================================

# Virtual machines - virtual machine images
/var/lib/libvirt 755 root root "Virtual machines"

# Container images - container images
/var/lib/containers 755 root root "Container images"

# ============================================================================
# LOGGING DIRECTORIES
# ============================================================================

# Journal logs - systemd journal logs
/var/log/journal 755 root root "Journal logs"

# Application logs - application-specific logs
/var/log/apps 755 root root "Application logs"

# ============================================================================
# CACHE DIRECTORIES
# ============================================================================

# Package cache - package download cache
/var/cache/xbps 755 root root "Package cache"

# Font cache - font configuration cache
/var/cache/fontconfig 755 root root "Font cache"

# Thumbnail cache - thumbnail cache
/var/cache/thumbnails 755 root root "Thumbnail cache"

# ============================================================================
# LOCK DIRECTORIES
# ============================================================================

# Lock files - lock files
/var/lock 1777 root root "Lock files"

# Run locks - runtime lock files
/run/lock 1777 root root "Run locks"

# ============================================================================
# TEMPORARY DIRECTORIES
# ============================================================================

# User runtime - user runtime directories
/run/user 1777 root root "User runtime"

# Shared memory - shared memory files
/run/shm 1777 root root "Shared memory"

# ============================================================================
# BACKUP DIRECTORIES
# ============================================================================

# Local backups - local backup storage
/var/local/backups 755 root root "Local backups"

# System backups - system backup storage
/var/backups 755 root root "System backups"

# ============================================================================
# MONITORING DIRECTORIES
# ============================================================================

# Performance data - performance monitoring data
/var/lib/performance 755 root root "Performance data"

# System metrics - system metrics storage
/var/lib/metrics 755 root root "System metrics"

# ============================================================================
# PROFILE DIRECTORIES
# ============================================================================

# User profiles - user configuration profiles
/etc/voidance/profiles 755 root root "User profiles"

# Hardware profiles - hardware-specific profiles
/var/lib/voidance/hardware 755 root root "Hardware profiles"

# ============================================================================
# STATE DIRECTORIES
# ============================================================================

# System state - system state information
/var/lib/voidance/state 755 root root "System state"

# Application state - application state information
/var/lib/state 755 root root "Application state"
EOF
    
    success "Hierarchy configuration created: $config_file"
}

# Function to create directory from config
create_directory_from_config() {
    local config_line="$1"
    
    # Skip comments and empty lines
    [[ "$config_line" =~ ^[[:space:]]*# ]] && return
    [[ -z "$config_line" ]] && return
    
    # Parse configuration line
    local path=$(echo "$config_line" | awk '{print $1}')
    local mode=$(echo "$config_line" | awk '{print $2}')
    local owner=$(echo "$config_line" | awk '{print $3}')
    local group=$(echo "$config_line" | awk '{print $4}')
    local description=$(echo "$config_line" | cut -d'"' -f2)
    
    # Create directory
    local full_path="$ROOTFS_BASE$path"
    create_directory "$full_path" "$mode" "$owner" "$group" "$description"
}

# Function to create complete hierarchy
create_complete_hierarchy() {
    log "Creating complete system directory hierarchy..."
    
    # Create hierarchy configuration
    local config_file="/tmp/voidance-hierarchy.conf"
    create_hierarchy_config "$config_file"
    
    # Read configuration and create directories
    while IFS= read -r line; do
        create_directory_from_config "$line"
    done < "$config_file"
    
    # Clean up
    rm -f "$config_file"
    
    success "Complete system directory hierarchy created"
}

# Function to create special symlinks
create_special_symlinks() {
    log "Creating special symlinks..."
    
    # Standard symlinks
    create_symlink "/usr/bin" "$ROOTFS_BASE/bin"
    create_symlink "/usr/sbin" "$ROOTFS_BASE/sbin"
    create_symlink "/usr/lib" "$ROOTFS_BASE/lib"
    create_symlink "/usr/lib64" "$ROOTFS_BASE/lib64"
    
    # Process symlinks
    create_symlink "/proc/self/fd" "$ROOTFS_BASE/dev/fd"
    create_symlink "/proc/self/fd/0" "$ROOTFS_BASE/dev/stdin"
    create_symlink "/proc/self/fd/1" "$ROOTFS_BASE/dev/stdout"
    create_symlink "/proc/self/fd/2" "$ROOTFS_BASE/dev/stderr"
    
    # System symlinks
    create_symlink "/var/run" "$ROOTFS_BASE/run"
    create_symlink "/run/lock" "$ROOTFS_BASE/var/lock"
    
    success "Special symlinks created"
}

# Function to create directory documentation
create_directory_documentation() {
    log "Creating directory documentation..."
    
    local doc_file="$ROOTFS_BASE/etc/voidance/directory-hierarchy.md"
    
    cat > "$doc_file" << 'EOF'
# Voidance Directory Hierarchy Documentation

This document describes the complete directory hierarchy used by Voidance Linux.

## Overview

Voidance follows the Filesystem Hierarchy Standard (FHS) 3.0 with additional
directories for desktop environment and Voidance-specific functionality.

## Essential Directories

### `/` - Root Directory
The root of the entire filesystem hierarchy.

### `/bin` - Essential User Binaries
Contains executables needed for booting and repairing the system.

### `/boot` - Boot Loader Files
Contains boot loader configuration files and the boot loader itself.

### `/dev` - Device Files
Contains device nodes for hardware devices.

### `/etc` - Configuration Files
Contains host-specific system-wide configuration files.

### `/home` - User Home Directories
Contains user home directories.

### `/lib` - Essential Shared Libraries
Contains libraries needed by binaries in `/bin` and `/sbin`.

### `/lib64` - 64-bit Libraries
Contains 64-bit shared libraries on x86_64 systems.

### `/media` - Media Mount Points
Mount point for removable media.

### `/mnt` - Temporary Mount Points
Temporary mount directory for mounting filesystems temporarily.

### `/opt` - Optional Software
Add-on application software packages.

### `/proc` - Process Information
Virtual filesystem with kernel and process information.

### `/root` - Root Home Directory
Home directory for the root user.

### `/run` - Run-time Data
Run-time variable data.

### `/sbin` - System Binaries
Essential system binaries.

### `/srv` - Service Data
Site-specific data served by this system.

### `/tmp` - Temporary Files
Temporary files.

### `/usr` - User Programs
Secondary hierarchy for user data and programs.

### `/var` - Variable Data
Variable data files.

## Voidance-Specific Directories

### `/etc/voidance` - Voidance Configuration
Voidance-specific configuration files.

### `/var/lib/voidance` - Voidance State
Voidance state information and data.

### `/var/log/voidance` - Voidance Logs
Voidance-specific log files.

## Desktop Environment Directories

### `/etc/X11` - X11 Configuration
X Window System configuration files.

### `/etc/xdg` - XDG Configuration
XDG Base Directory specification configuration.

### `/usr/share/applications` - Desktop Applications
Desktop application files.

### `/usr/share/icons` - Icons
Icon files and themes.

### `/usr/share/themes` - Themes
Desktop themes.

### `/usr/share/fonts` - Fonts
Font files.

### `/usr/share/wayland-sessions` - Wayland Sessions
Wayland session files.

## System Service Directories

### `/etc/sv` - Runit Services
Runit service definitions.

### `/var/service` - Active Services
Currently active services.

## Security Directories

### `/etc/security` - Security Configuration
Security-related configuration files.

### `/etc/pam.d` - PAM Configuration
Pluggable Authentication Modules configuration.

## Hardware Directories

### `/etc/modprobe.d` - Kernel Modules
Kernel module configuration.

### `/etc/modules-load.d` - Module Loading
Module loading configuration.

### `/etc/udev/rules.d` - Udev Rules
Udev device rules.

## Network Directories

### `/etc/network` - Network Configuration
Network configuration files.

## Font Directories

### `/etc/fonts` - Font Configuration
Font configuration files.

### `/var/cache/fontconfig` - Font Cache
Font configuration cache.

## Documentation Directories

### `/usr/share/man` - Manual Pages
System manual pages.

### `/usr/share/info` - Info Pages
Info documentation.

### `/usr/share/doc` - Documentation
Package documentation.

## Development Directories

### `/usr/include` - Header Files
C/C++ header files.

### `/usr/src` - Source Code
Source code.

## Multimedia Directories

### `/usr/share/sounds` - Sounds
System sound files.

### `/usr/share/backgrounds` - Backgrounds
Desktop background images.

### `/usr/share/mime` - MIME Types
MIME type definitions.

## Virtualization Directories

### `/var/lib/libvirt` - Virtual Machines
Virtual machine images.

### `/var/lib/containers` - Container Images
Container images.

## Logging Directories

### `/var/log/journal` - Journal Logs
Systemd journal logs.

### `/var/log/apps` - Application Logs
Application-specific logs.

## Cache Directories

### `/var/cache/xbps` - Package Cache
Package download cache.

### `/var/cache/thumbnails` - Thumbnail Cache
Thumbnail cache.

## Lock Directories

### `/var/lock` - Lock Files
Lock files.

### `/run/lock` - Run Locks
Runtime lock files.

## Temporary Directories

### `/run/user` - User Runtime
User runtime directories.

### `/run/shm` - Shared Memory
Shared memory files.

## Backup Directories

### `/var/local/backups` - Local Backups
Local backup storage.

### `/var/backups` - System Backups
System backup storage.

## Monitoring Directories

### `/var/lib/performance` - Performance Data
Performance monitoring data.

### `/var/lib/metrics` - System Metrics
System metrics storage.

## Profile Directories

### `/etc/voidance/profiles` - User Profiles
User configuration profiles.

### `/var/lib/voidance/hardware` - Hardware Profiles
Hardware-specific profiles.

## State Directories

### `/var/lib/voidance/state` - System State
System state information.

### `/var/lib/state` - Application State
Application state information.

## References

- [Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/)
- [Void Linux Documentation](https://docs.voidlinux.org/)
EOF
    
    success "Directory documentation created: $doc_file"
}

# Function to validate hierarchy
validate_hierarchy() {
    log "Validating directory hierarchy..."
    
    local errors=0
    
    # Check essential directories
    local essential_dirs=(
        "/bin"
        "/boot"
        "/dev"
        "/etc"
        "/home"
        "/lib"
        "/lib64"
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
    
    for dir in "${essential_dirs[@]}"; do
        if [[ ! -d "$ROOTFS_BASE$dir" ]]; then
            error "Missing essential directory: $dir"
            ((errors++))
        fi
    done
    
    # Check Voidance-specific directories
    local voidance_dirs=(
        "/etc/voidance"
        "/var/lib/voidance"
        "/var/log/voidance"
    )
    
    for dir in "${voidance_dirs[@]}"; do
        if [[ ! -d "$ROOTFS_BASE$dir" ]]; then
            error "Missing Voidance directory: $dir"
            ((errors++))
        fi
    done
    
    # Check desktop environment directories
    local desktop_dirs=(
        "/etc/X11"
        "/etc/xdg"
        "/usr/share/applications"
        "/usr/share/icons"
        "/usr/share/themes"
        "/usr/share/fonts"
        "/usr/share/wayland-sessions"
    )
    
    for dir in "${desktop_dirs[@]}"; do
        if [[ ! -d "$ROOTFS_BASE$dir" ]]; then
            error "Missing desktop directory: $dir"
            ((errors++))
        fi
    done
    
    # Check symlinks
    local symlinks=(
        "/usr/bin"
        "/usr/sbin"
        "/usr/lib"
        "/usr/lib64"
        "/var/run"
    )
    
    for link in "${symlinks[@]}"; do
        if [[ ! -L "$ROOTFS_BASE$link" ]]; then
            error "Missing symlink: $link"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        success "Directory hierarchy validation passed"
        return 0
    else
        error "Directory hierarchy validation failed with $errors errors"
        return 1
    fi
}

# Main function
main() {
    log "Configuring Voidance system directories and hierarchy..."
    
    # Create complete hierarchy
    create_complete_hierarchy
    
    # Create special symlinks
    create_special_symlinks
    
    # Create documentation
    create_directory_documentation
    
    # Validate hierarchy
    validate_hierarchy
    
    success "System directories and hierarchy configuration completed"
    log "System hierarchy configured at: $ROOTFS_BASE"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi