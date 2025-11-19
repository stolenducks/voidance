# Voidance Installation Guide

## Quick Start: One-Command Deployment

The easiest way to install Voidance is with our one-command deployment system.

### Prerequisites

- **Fresh Void Linux installation** (any recent version)
- **Internet connectivity**
- **5GB+ free disk space**
- **2GB+ RAM** (4GB+ recommended)
- **Root/sudo access**

### Installation

1. **Boot into your fresh Void Linux system**

2. **Run the deployment command**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/voidance/voidance/main/deploy-voidance.sh | sudo bash
   ```

3. **Wait for installation to complete**
   - The script will install 93 packages
   - Configure all system services
   - Set up desktop environment
   - Validate installation
   - Usually takes 15-30 minutes

4. **Reboot your system**
   ```bash
   sudo reboot
   ```

5. **Welcome to Voidance!**
   - Log in at the graphical login screen
   - Your desktop environment is ready to use

## What Gets Installed

### Core System
- **Session Management**: elogind, dbus, PAM
- **Display Manager**: SDDM with themes
- **Network Services**: NetworkManager with WiFi support
- **Audio System**: PipeWire with WirePlumber

### Desktop Environment
- **Wayland Compositor**: Niri (scrollable tiling)
- **Status Bar**: Waybar with system info
- **Application Launcher**: Wofi (Wayland-native)
- **File Manager**: Thunar with plugins
- **Terminal**: Ghostty (fast, GPU-accelerated)
- **Notifications**: Mako notification daemon

### Applications & Tools
- **Wayland Utilities**: wl-clipboard, grim, slurp, wf-recorder
- **Fonts**: Noto, DejaVu, Liberation, Fira Code
- **Themes**: Breeze and Adwaita icon themes
- **Development Tools**: Basic development environment

### Fallback Options
- **Fallback Compositor**: Sway (i3-compatible)
- **Fallback Terminal**: Foot (if Ghostty fails)
- **Fallback Launcher**: Rofi/dmenu (if Wofi fails)

## First Steps

### Basic Navigation
- **Super + Enter**: Open application launcher
- **Super + Shift + Q**: Logout
- **Super + Shift + R**: Restart compositor
- **Super + Arrow keys**: Navigate workspaces
- **Super + Mouse drag**: Move windows

### Configuration Files
- **Niri config**: `~/.config/niri/config`
- **Waybar config**: `~/.config/waybar/config`
- **Wofi config**: `~/.config/wofi/config`
- **SDDM config**: `/etc/sddm.conf`

### Getting Help
- **Installation log**: `/var/log/voidance-deployment.log`
- **Validation script**: `./scripts/validate-voidance.sh`
- **Service status**: `sv status [service-name]`
- **Package info**: `xbps-query [package-name]`

## Troubleshooting

### Common Issues

**Installation fails with network error:**
```bash
# Check internet connection
ping repo-default.voidlinux.org

# If needed, configure network manually
sudo dhcpcd eth0  # or wlan0 for WiFi
```

**Services not starting after reboot:**
```bash
# Check service status
sudo sv status dbus
sudo sv status elogind
sudo sv status NetworkManager
sudo sv status sddm

# Start services manually
sudo sv up dbus
sudo sv up elogind
sudo sv up NetworkManager
sudo sv up sddm
```

**Desktop doesn't start:**
```bash
# Check if niri is installed
which niri

# Check if display manager is running
ps aux | grep sddm

# Validate installation
sudo ./scripts/validate-voidance.sh
```

**Audio not working:**
```bash
# Check if PipeWire is running
pactl info

# Restart audio services
sudo sv restart pipewire
sudo sv restart wireplumber
```

### Getting Support

- **GitHub Issues**: https://github.com/voidance/voidance/issues
- **Documentation**: Check the `docs/` directory in this repository
- **Installation Log**: `/var/log/voidance-deployment.log`
- **Validation**: Run `./scripts/validate-voidance.sh` for system health check

### Recovery

If something goes wrong during installation:

1. **Don't panic** - the script includes rollback mechanisms
2. **Check the log** at `/var/log/voidance-deployment.log`
3. **Run validation** with `./scripts/validate-voidance.sh`
4. **Reboot and retry** if needed
5. **Reinstall Void Linux** as last resort (worst case)

## Manual Installation (Advanced)

If you prefer manual installation or want to customize the process:

1. **Clone repository**
   ```bash
   git clone https://github.com/voidance/voidance.git
   cd voidance
   ```

2. **Run deployment script locally**
   ```bash
   sudo ./deploy-voidance.sh
   ```

3. **Validate installation**
   ```bash
   sudo ./scripts/validate-voidance.sh
   ```

This gives you more control and allows for customization of the installation process.

## Contributing

Found an issue or want to improve the installation?

1. **Check existing issues** on GitHub
2. **Create detailed bug report** with:
   - System information
   - Installation log
   - Error messages
   - Steps to reproduce
3. **Submit pull request** for improvements

Thank you for using Voidance! 🎉