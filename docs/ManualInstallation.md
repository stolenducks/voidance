# Manual Installation Guide

This guide is for **advanced users** who want to install base Void Linux first, then transform it into Voidance.

## Who Should Use This Method?

Use the manual installation if you:
- 🔧 Need custom partitioning (RAID, LVM, ZFS, etc.)
- 🔒 Require specific encryption setups beyond standard LUKS
- 💾 Have unusual hardware that needs special configuration
- 🎓 Want to learn Void Linux internals deeply
- 🔄 Have an existing Void installation to transform
- 🌐 Need dual-boot with complex configurations

**For beginners**: Use the [Voidance ISO](../README.md#method-1-voidance-iso-recommended-for-beginners) instead!

---

## Prerequisites

- ✅ Familiarity with Linux command line
- ✅ Understanding of partitioning and filesystems
- ✅ Knowledge of bootloaders (GRUB/UEFI)
- ✅ Void Linux installation experience (recommended)

---

## Installation Steps

### Step 1: Install Base Void Linux

Follow the official Void Linux installation guide:
📖 https://docs.voidlinux.org/installation/

**Key decisions:**
- **Architecture**: Choose `x86_64` (glibc recommended for desktop)
- **Filesystem**: `ext4` or `btrfs` recommended
- **Encryption**: LUKS optional (Voidance supports it)
- **Desktop**: Install **without** a desktop environment (we'll add Hyprland)

**Minimal installation example:**
```bash
# Boot Void live ISO
# Follow installer prompts
# Select "Base system only" (no desktop)
# Set hostname: voidance
# Create user account
# Install bootloader
```

### Step 2: Boot Into Fresh Void System

After installation completes:
```bash
# Remove installation media
# Reboot
# Login with your user account
```

### Step 3: Update System

```bash
# Sync package repositories
sudo xbps-install -S

# Update all packages
sudo xbps-install -u xbps
sudo xbps-install -u

# Reboot if kernel was updated
sudo reboot
```

### Step 4: Install Network Tools

Ensure you have internet connectivity:

```bash
# For wired connections (usually automatic)
sudo sv status dhcpcd

# For WiFi
sudo xbps-install -S iwd NetworkManager
sudo ln -s /etc/sv/NetworkManager /var/service/
sudo sv up NetworkManager

# Connect to WiFi
nmtui
```

### Step 5: Download Voidance Transformation Script

```bash
# Install curl if needed
sudo xbps-install -S curl

# Download transformation script
curl -o ~/transform.sh https://raw.githubusercontent.com/YOURUSERNAME/voidance/main/scripts/transform.sh

# Make executable
chmod +x ~/transform.sh
```

### Step 6: Run Transformation

```bash
# Run the script
bash ~/transform.sh

# Follow prompts
# Script will:
# - Install Hyprland and Wayland components
# - Install dev tools, browsers, and apps
# - Apply Voidance themes and configs
# - Configure runit services
# - Set up user dotfiles
```

**Estimated time**: 15-30 minutes depending on internet speed

### Step 7: Reboot

```bash
# After transformation completes
sudo reboot
```

Your system should now boot into Hyprland with the full Voidance experience!

---

## Post-Installation

### First Login

1. **Login screen**: Use your user credentials from Step 1
2. **Hyprland starts automatically**
3. Press `Super + Return` to open terminal
4. Press `Super + D` to open app launcher

### Verify Installation

```bash
# Check Voidance version
cat ~/.local/share/voidance/version

# Test Wayland
echo $WAYLAND_DISPLAY

# Check services
sv status dbus
sv status elogind
```

### Optional: Install Additional Software

```bash
# Install from official repos
sudo xbps-install -S <package-name>

# Example: Install Docker
sudo xbps-install -S docker
sudo ln -s /etc/sv/docker /var/service/
sudo usermod -aG docker $USER
```

---

## Troubleshooting

### Graphics Drivers

If Hyprland won't start, you may need GPU drivers:

**NVIDIA:**
```bash
sudo xbps-install -S nvidia nvidia-libs-32bit
sudo reboot
```

**AMD:**
```bash
sudo xbps-install -S mesa-dri vulkan-loader mesa-vulkan-radeon
```

**Intel:**
```bash
sudo xbps-install -S mesa-dri vulkan-loader mesa-vulkan-intel
```

### Network Issues

If WiFi doesn't work after reboot:
```bash
sudo sv restart NetworkManager
nmcli device wifi list
nmcli device wifi connect "SSID" password "password"
```

### Sound Not Working

```bash
# Ensure PipeWire is running
sv status pipewire
sv status wireplumber

# Restart if needed
sv restart pipewire
```

### Hyprland Crashes

Check logs:
```bash
cat ~/.local/share/hyprland/hyprland.log
```

Common fixes:
```bash
# Reinstall Hyprland
sudo xbps-install -f hyprland

# Reset Hyprland config
mv ~/.config/hypr ~/.config/hypr.backup
cp -r ~/.local/share/voidance/config/hypr ~/.config/
```

---

## Advanced Customization

### Custom Partitioning Schemes

Voidance transformation script works with any partition layout:
- ✅ Standard ext4 partition
- ✅ LVM logical volumes
- ✅ Btrfs subvolumes
- ✅ ZFS datasets
- ✅ LUKS encrypted partitions
- ✅ RAID arrays

No special configuration needed!

### Dual Boot Setup

Voidance works alongside:
- Windows (use GRUB to dual-boot)
- macOS (rEFInd recommended)
- Other Linux distros

The transformation script won't touch your bootloader.

### Server/Headless Installation

Want Voidance configs on a server?
```bash
# Run transformation with --headless flag
bash transform.sh --headless

# Installs:
# - Terminal-only environment
# - Dev tools (neovim, git, docker)
# - Dotfiles (bash, starship, etc.)
# - No GUI/Wayland components
```

---

## Uninstalling

To revert to base Void:

```bash
# Remove Voidance packages
sudo xbps-remove -R hyprland waybar walker mako

# Remove configs
rm -rf ~/.config/hypr ~/.config/waybar ~/.config/walker
rm -rf ~/.local/share/voidance

# Restore original dotfiles (if you backed them up)
```

---

## Comparison: ISO vs Manual

| Feature | Voidance ISO | Manual Install |
|---------|--------------|----------------|
| **Difficulty** | Easy | Advanced |
| **Time Required** | 10 minutes | 60+ minutes |
| **Customization** | Limited | Full control |
| **Partitioning** | Standard only | Any scheme |
| **Encryption** | Standard LUKS | Any method |
| **Dual Boot** | Difficult | Easy |
| **Learning** | Minimal | Deep |

---

## Getting Help

- 📖 [Troubleshooting Guide](Troubleshooting.md)
- 💬 [Community Discussions](https://github.com/YOURUSERNAME/voidance/discussions)
- 🐛 [Report Issues](https://github.com/YOURUSERNAME/voidance/issues)
- 📚 [Void Linux Handbook](https://docs.voidlinux.org)

---

## Contributing

Found issues with manual installation? Help improve this guide:
- [Contributing Guidelines](Contributing.md)
- [Submit corrections via PR](https://github.com/YOURUSERNAME/voidance/pulls)

---

**Next Steps**: After successful installation, check out the [Keyboard Shortcuts](KeyboardShortcuts.md) to get productive!
