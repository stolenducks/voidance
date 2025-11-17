# Voidance Linux Installation Guide

## Overview

Voidance Linux is a minimal Wayland-based Linux distribution built on Void Linux. This guide will walk you through the installation process from ISO creation to system setup.

## System Requirements

### Minimum Requirements
- **Processor**: 64-bit x86_64 CPU (Intel or AMD)
- **Memory**: 2GB RAM (4GB recommended)
- **Storage**: 20GB free disk space (30GB recommended)
- **Graphics**: Any GPU with Wayland support

### Recommended Requirements
- **Processor**: Modern 64-bit multi-core CPU
- **Memory**: 8GB RAM or more
- **Storage**: 50GB+ SSD storage
- **Graphics**: Modern GPU with good Wayland support (Intel, AMD, NVIDIA)

## Installation Methods

### Method 1: Live ISO Installation

1. **Download or Create the ISO**
   ```bash
   # Build the ISO from source
   ./scripts/void-mklive-integration.sh
   ```

2. **Create Bootable Media**
   ```bash
   # For USB drive (replace /dev/sdX with your device)
   dd if=voidance-live-*.iso of=/dev/sdX bs=4M status=progress
   ```

3. **Boot from the ISO**
   - Insert the bootable media
   - Boot from USB/CD in your computer's BIOS/UEFI
   - Select "Voidance Linux Live" from the boot menu

4. **Run the Installer**
   ```bash
   # Start the text-based installer
   sudo ./scripts/voidance-installer.sh
   ```

### Method 2: Manual Installation

1. **Prepare the System**
   ```bash
   # Boot into a Void Linux live environment
   # Connect to network
   sudo dhcpcd eth0  # or wlan0 for wireless
   ```

2. **Partition the Disk**
   ```bash
   # Example partitioning scheme
   sudo fdisk /dev/sda
   # Create: EFI System Partition (512MB), Root Partition (remaining space)
   ```

3. **Create Filesystems**
   ```bash
   sudo mkfs.vfat -F32 /dev/sda1  # EFI partition
   sudo mkfs.ext4 /dev/sda2       # Root partition
   ```

4. **Mount Filesystems**
   ```bash
   sudo mount /dev/sda2 /mnt
   sudo mkdir -p /mnt/boot/efi
   sudo mount /dev/sda1 /mnt/boot/efi
   ```

5. **Install Base System**
   ```bash
   # Install Voidance packages
   ./scripts/system-installation.sh
   ```

6. **Install Bootloader**
   ```bash
   # Install GRUB bootloader
   ./scripts/bootloader-installation.sh
   ```

## Installation Steps

### Step 1: Welcome Screen
- Read the introduction to Voidance Linux
- Press Enter to continue

### Step 2: Language Selection
- Select your preferred system language
- This sets locale and keyboard layout

### Step 3: Keyboard Layout
- Choose your keyboard layout
- Test the layout to ensure it works correctly

### Step 4: Disk Configuration
Choose from several partitioning options:

#### Automatic Partitioning (Recommended)
- Automatically partitions the entire disk
- Creates EFI system partition and root partition
- Suitable for most users

#### LVM Partitioning
- Creates LVM volume group
- Allows flexible disk management
- Good for advanced users

#### Encrypted Partitioning
- Encrypts the root partition with LUKS
- Requires password at boot
- Provides data security

#### Manual Partitioning
- Full control over partition layout
- For advanced users only
- Requires knowledge of partitioning

### Step 5: User Account Creation
- Create your main user account
- Set a strong password (minimum 8 characters)
- Choose user groups and permissions

### Step 6: Network Configuration
- Configure wired or wireless network
- Set up Wi-Fi connections if needed
- Test network connectivity

### Step 7: Software Selection
Choose from predefined software sets:

#### Full Desktop (Recommended)
- Complete desktop environment
- Development tools
- Multimedia applications
- System utilities

#### Minimal Desktop
- Basic desktop environment only
- Essential applications
- For minimal installations

#### Development Workstation
- Development tools and libraries
- Programming languages
- Version control systems

#### Gaming System
- Gaming platforms and tools
- Graphics drivers
- Performance optimizations

#### Server
- Server applications
- Network services
- Minimal desktop

#### Custom
- Select individual packages
- Full control over software

### Step 8: Installation Process
- Review your installation choices
- Begin the installation
- Wait for completion (typically 10-20 minutes)

### Step 9: Post-Installation Configuration
- System services are configured
- User permissions are set
- Hardware detection runs
- System optimizations applied

### Step 10: Completion
- Installation is complete
- Reboot your system
- Remove installation media
- Log in with your created account

## Post-Installation Setup

### First-Boot Configuration
On first boot, the system will run a setup wizard:

1. **Welcome Screen**
   - Introduction to Voidance Linux
   - Overview of setup process

2. **User Information**
   - Confirm or set full name
   - Configure timezone and locale
   - Set email address (optional)

3. **Desktop Environment**
   - Select default Wayland compositor (Niri/Sway)
   - Choose wallpaper and theme
   - Configure desktop preferences

4. **Hardware Optimization**
   - Detect and optimize for your hardware
   - Install appropriate drivers
   - Configure power management

5. **Network Setup**
   - Configure network connections
   - Set up Wi-Fi auto-connect
   - Configure VPN if needed

6. **User Preferences**
   - Choose default applications
   - Configure privacy settings
   - Set up shell and terminal

### System Updates
```bash
# Update system packages
sudo xbps-install -Syu

# Update package database
sudo xbps-install -S
```

### Installing Additional Software
```bash
# Search for packages
xbps-query -Rs <package_name>

# Install packages
sudo xbps-install <package_name>

# Remove packages
sudo xbps-remove <package_name>
```

## Troubleshooting

### Common Installation Issues

#### Boot Issues
- **Problem**: System won't boot from USB
- **Solution**: Check BIOS/UEFI boot order, ensure USB is bootable

#### Partitioning Issues
- **Problem**: Partitioning fails
- **Solution**: Ensure disk is not in use, check for existing partitions

#### Network Issues
- **Problem**: No network connection
- **Solution**: Check cable, try different interface, configure manually

#### Graphics Issues
- **Problem**: No display or poor performance
- **Solution**: Install appropriate graphics drivers, check Wayland support

### Recovery Options

#### Bootloader Recovery
```bash
# Run bootloader recovery
sudo ./scripts/bootloader-recovery.sh --menu
```

#### System Repair
```bash
# Boot from live ISO and chroot into system
sudo mount /dev/sda2 /mnt
sudo chroot /mnt /bin/bash
```

#### Password Reset
```bash
# Reset root password from live ISO
sudo chroot /mnt
passwd root
```

## Getting Help

### Documentation
- **System Documentation**: `/usr/share/doc/voidance/`
- **Manual Pages**: `man <command>`
- **Package Information**: `xbps-query -R <package>`

### Community
- **Website**: https://voidance.org
- **Community Forum**: https://voidance.org/community
- **Support**: https://voidance.org/support
- **Source Code**: https://github.com/stolenducks/voidance

### Reporting Issues
- **Bug Reports**: https://github.com/stolenducks/voidance/issues
- **Feature Requests**: https://github.com/stolenducks/voidance/discussions

## Advanced Topics

### Custom ISO Building
```bash
# Build custom ISO with additional packages
./scripts/void-mklive-integration.sh

# Customize package selection
edit config/iso/packages.txt
```

### System Configuration
- **System Services**: `/etc/sv/`
- **Configuration Files**: `/etc/voidance/`
- **User Configuration**: `~/.config/`

### Development Setup
```bash
# Install development tools
sudo xbps-install -S base-devel

# Set up build environment
mkdir -p ~/voidance-dev
cd ~/voidance-dev
git clone https://github.com/stolenducks/voidance.git
```

## Conclusion

Congratulations on installing Voidance Linux! You now have a minimal, performant Wayland-based Linux distribution. Explore the documentation, join the community, and enjoy your Voidance experience.

For more information and updates, visit https://voidance.org