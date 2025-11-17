# Voidance Desktop Environment Troubleshooting Guide

## Table of Contents

- [Installation Issues](#installation-issues)
- [Display & Graphics](#display--graphics)
- [Input & Keyboard](#input--keyboard)
- [Audio & Sound](#audio--sound)
- [Network & Connectivity](#network--connectivity)
- [Application Issues](#application-issues)
- [Performance Problems](#performance-problems)
- [Session Management](#session-management)
- [Configuration Issues](#configuration-issues)
- [Hardware Detection](#hardware-detection)
- [System Services](#system-services)

---

## Installation Issues

### Desktop Environment Not Available in SDDM

**Problem**: "Niri" option doesn't appear in SDDM login screen

**Solutions**:
1. Check session file exists:
   ```bash
   ls -la /usr/share/wayland-sessions/niri.desktop
   ```

2. Verify session file permissions:
   ```bash
   chmod 644 /usr/share/wayland-sessions/niri.desktop
   ```

3. Restart SDDM:
   ```bash
   sudo sv restart sddm
   ```

4. Reinstall desktop environment:
   ```bash
   sudo /path/to/setup-desktop-environment.sh install
   ```

### Missing Packages After Installation

**Problem**: Some desktop components don't work

**Solutions**:
1. Verify package installation:
   ```bash
   /path/to/packages/desktop-environment.sh
   verify_desktop_packages
   ```

2. Install missing packages manually:
   ```bash
   sudo xbps-install -S niri waybar wofi ghostty
   ```

3. Update package database:
   ```bash
   sudo xbps-install -S
   ```

---

## Display & Graphics

### No Display After Login

**Problem**: Black screen after selecting Niri session

**Solutions**:
1. Check GPU drivers:
   ```bash
   lspci | grep -i vga
   ```

2. Run hardware detection:
   ```bash
   sudo detect-hardware.sh apply
   ```

3. Try fallback session:
   - Reboot and select "Wayland (Fallback)" if available
   - Or login to TTY and debug

4. Check Niri logs:
   ```bash
   journalctl -u niri -f
   ```

### Wrong Screen Resolution

**Problem**: Display resolution is incorrect

**Solutions**:
1. Auto-detect monitors:
   ```bash
   sudo detect-hardware.sh apply
   ```

2. Manual configuration in `~/.config/niri/config.kdl`:
   ```kdl
   output "eDP-1" {
       mode 1920x1080@60.0
       scale 1.25
   }
   ```

3. Reload configuration:
   ```bash
   Super + Ctrl + R
   ```

### Multiple Monitor Issues

**Problem**: External monitor not detected or wrong configuration

**Solutions**:
1. Check connected monitors:
   ```bash
   detect-hardware.sh summary
   ```

2. Manual monitor configuration:
   ```kdl
   output "eDP-1" {
       position x=0 y=0
       scale 1.0
   }
   
   output "HDMI-A-1" {
       position x=1920 y=0
       scale 1.0
   }
   ```

3. Test with wlr-randr if available:
   ```bash
   wlr-randr
   ```

### Screen Tearing

**Problem**: Visual tearing when moving windows

**Solutions**:
1. Enable adaptive sync in Niri config:
   ```kdl
   output "eDP-1" {
       adaptive-sync true
   }
   ```

2. Check GPU-specific settings:
   ```bash
   # For NVIDIA
   export __GLX_VENDOR_LIBRARY_NAME=nvidia
   
   # For AMD
   export AMD_VULKAN_ICD=RADV
   ```

---

## Input & Keyboard

### Keyboard Not Working

**Problem**: Keyboard input not recognized

**Solutions**:
1. Check keyboard detection:
   ```bash
   xinput list
   ```

2. Verify keyboard layout in Niri config:
   ```kdl
   input {
       keyboard {
           xkb-layout "us"
           xkb-variant ""
       }
   }
   ```

3. Restart input services:
   ```bash
   sudo sv restart udev
   ```

### Touchpad Not Working

**Problem**: Touchpad input not working or gestures missing

**Solutions**:
1. Check touchpad detection:
   ```bash
   xinput list | grep -i touchpad
   ```

2. Verify touchpad configuration:
   ```kdl
   input {
       touchpad {
           tap-to-click true
           natural-scroll false
           disable-while-typing true
       }
   }
   ```

3. Install libinput drivers:
   ```bash
   sudo xbps-install -S libinput
   ```

### Keybindings Not Working

**Problem**: Custom or default keybindings don't work

**Solutions**:
1. Validate Niri configuration:
   ```bash
   niri msg validate-config
   ```

2. Check for conflicts:
   ```bash
   # Check if another app is using the shortcut
   xev  # Press problematic shortcut
   ```

3. Reload configuration:
   ```bash
   Super + Ctrl + R
   ```

---

## Audio & Sound

### No Sound Output

**Problem**: No audio from speakers or headphones

**Solutions**:
1. Check audio services:
   ```bash
   sudo sv status pipewire pipewire-pulse wireplumber
   ```

2. Restart audio services:
   ```bash
   sudo sv restart pipewire pipewire-pulse wireplumber
   ```

3. Check audio devices:
   ```bash
   pactl list sinks
   ```

4. Set default output:
   ```bash
   pactl set-default-sink <sink_name>
   ```

### Volume Controls Not Working

**Problem**: Volume keys don't change volume

**Solutions**:
1. Check if pactl is working:
   ```bash
   pactl set-sink-volume @DEFAULT_SINK@ +5%
   ```

2. Verify keybindings in Niri config:
   ```kdl
   bind XF86AudioRaiseVolume { spawn "pactl" set-sink-volume @DEFAULT_SINK@ +5% }
   ```

3. Install audio utilities:
   ```bash
   sudo xbps-install -S pulseaudio-utils
   ```

### Microphone Not Working

**Problem**: Microphone input not detected

**Solutions**:
1. Check input devices:
   ```bash
   pactl list sources
   ```

2. Set default input:
   ```bash
   pactl set-default-source <source_name>
   ```

3. Check microphone permissions:
   ```bash
   # Ensure user is in audio group
   groups $USER
   ```

---

## Network & Connectivity

### No Internet Connection

**Problem**: Network not working after login

**Solutions**:
1. Check NetworkManager service:
   ```bash
   sudo sv status NetworkManager
   ```

2. Restart NetworkManager:
   ```bash
   sudo sv restart NetworkManager
   ```

3. Check network interfaces:
   ```bash
   ip addr show
   ```

4. Test connectivity:
   ```bash
   ping -c 3 8.8.8.8
   ```

### WiFi Not Working

**Problem**: WiFi networks not detected or can't connect

**Solutions**:
1. Check WiFi adapter:
   ```bash
   iw dev
   ```

2. Scan for networks:
   ```bash
   iwlist scan
   ```

3. Use nm-applet for GUI management:
   ```bash
   nm-applet &
   ```

4. Connect via command line:
   ```bash
   nmcli dev wifi connect "SSID" password "password"
   ```

---

## Application Issues

### Applications Won't Launch

**Problem**: Clicking applications in wofi doesn't start them

**Solutions**:
1. Check if application is installed:
   ```bash
   which application_name
   ```

2. Verify desktop entry files:
   ```bash
   ls /usr/share/applications/application_name.desktop
   ```

3. Test from terminal:
   ```bash
   application_name
   ```

4. Update application database:
   ```bash
   update-desktop-database ~/.local/share/applications/
   ```

### Wayland Applications Not Working

**Problem**: Applications crash or don't display properly

**Solutions**:
1. Check if application is Wayland native:
   ```bash
   wayland-info
   ```

2. Force Wayland mode:
   ```bash
   export GDK_BACKEND=wayland
   export QT_QPA_PLATFORM=wayland
   application_name
   ```

3. Use Xwayland fallback:
   ```bash
   export GDK_BACKEND=x11
   application_name
   ```

### Terminal Issues

**Problem**: Ghostty terminal not working properly

**Solutions**:
1. Check if ghostty is installed:
   ```bash
   which ghostty
   ```

2. Test alternative terminal:
   ```bash
   # Change in Niri config
   bind Mod+Return { spawn "gnome-terminal" }
   ```

3. Check terminal configuration:
   ```bash
   ghostty --help
   ```

---

## Performance Problems

### System Slow or Laggy

**Problem**: Desktop environment feels sluggish

**Solutions**:
1. Check system resources:
   ```bash
   htop
   ```

2. Run hardware detection for optimizations:
   ```bash
   sudo detect-hardware.sh apply
   ```

3. Disable animations in Niri config:
   ```kdl
   layout {
       animations-enabled false
   }
   ```

4. Check for memory leaks:
   ```bash
   free -h
   ps aux --sort=-%mem | head
   ```

### High CPU Usage

**Problem**: High CPU usage from desktop processes

**Solutions**:
1. Identify consuming processes:
   ```bash
   top
   ```

2. Check Waybar CPU usage:
   ```bash
   ps aux | grep waybar
   ```

3. Reduce Waybar update intervals:
   ```json
   {
       "modules-right": ["network"],
       "network": {
           "interval": 10
       }
   }
   ```

### Memory Usage Too High

**Problem**: Desktop environment using too much RAM

**Solutions**:
1. Check memory usage:
   ```bash
   free -h
   smem -s pss
   ```

2. Restart memory-heavy applications:
   ```bash
   pkill application_name
   ```

3. Optimize Niri configuration:
   ```kdl
   // Reduce workspace memory usage
   layout {
       preset-column-widths {
           proportion 1 2
           proportion 1 1
       }
   }
   ```

---

## Session Management

### Can't Lock Screen

**Problem**: Screen lock doesn't work

**Solutions**:
1. Install screen locker:
   ```bash
   sudo xbps-install -S swaylock
   ```

2. Test screen locker:
   ```bash
   swaylock -f -c 000000
   ```

3. Check keybinding in Niri config:
   ```kdl
   bind Mod+L { spawn "swaylock" -f -c 000000 }
   ```

### Can't Logout or Shutdown

**Problem**: Session management commands don't work

**Solutions**:
1. Use session manager:
   ```bash
   session-manager menu
   ```

2. Check systemd services:
   ```bash
   systemctl --user status
   ```

3. Manual commands:
   ```bash
   # Logout
   niri msg quit
   
   # Reboot
   sudo systemctl reboot
   
   # Shutdown
   sudo systemctl poweroff
   ```

---

## Configuration Issues

### Configuration Not Applied

**Problem**: Changes to config files don't take effect

**Solutions**:
1. Validate configuration syntax:
   ```bash
   # Niri config
   niri msg validate-config
   
   # Waybar config
   jq . ~/.config/waybar/config
   ```

2. Reload configurations:
   ```bash
   # Niri
   Super + Ctrl + R
   
   # Waybar
   pkill waybar && waybar &
   ```

3. Check file permissions:
   ```bash
   ls -la ~/.config/niri/config.kdl
   ```

### Schema Validation Errors

**Problem**: Configuration validation fails

**Solutions**:
1. Run validation script:
   ```bash
   validate-desktop-config.sh all
   ```

2. Check specific component:
   ```bash
   validate-desktop-config.sh config
   ```

3. Fix syntax errors:
   - Check for missing brackets/commas in JSON
   - Verify KDL syntax in Niri config
   - Ensure CSS syntax is correct

---

## Hardware Detection

### Hardware Not Detected

**Problem**: Hardware detection doesn't find components

**Solutions**:
1. Run detection manually:
   ```bash
   sudo detect-hardware.sh detect
   ```

2. Check system logs:
   ```bash
   dmesg | grep -i hardware
   ```

3. Install detection tools:
   ```bash
   sudo xbps-install -S pciutils usbutils
   ```

### Wrong Hardware Profile

**Problem**: Hardware detection creates incorrect profile

**Solutions**:
1. Force re-detection:
   ```bash
   sudo detect-hardware.sh --force apply
   ```

2. Manual hardware configuration:
   ```bash
   # Edit /etc/voidance/hardware.json
   sudo nano /etc/voidance/hardware.json
   ```

3. Override detection:
   ```bash
   export GPU_TYPE=intel
   export PERFORMANCE_CLASS=medium
   ```

---

## System Services

### Services Not Starting

**Problem**: Desktop services fail to start

**Solutions**:
1. Check service status:
   ```bash
   sudo sv status NetworkManager pipewire sddm
   ```

2. Check service logs:
   ```bash
   sudo sv log NetworkManager
   ```

3. Restart services:
   ```bash
   sudo sv restart service_name
   ```

### Permission Issues

**Problem**: Services fail due to permissions

**Solutions**:
1. Check user groups:
   ```bash
   groups $USER
   ```

2. Add user to required groups:
   ```bash
   sudo usermod -a -G audio,video,input,plugdev $USER
   ```

3. Re-login for group changes to take effect

---

## Getting Help

### Diagnostic Commands

When experiencing issues, run these diagnostic commands:

```bash
# System information
neofetch
uname -a

# Desktop environment validation
validate-desktop-config.sh all

# Hardware detection summary
detect-hardware.sh summary

# Service status
sudo sv status

# Recent logs
journalctl -xe --since "1 hour ago"

# Resource usage
htop
free -h
df -h
```

### Log Files

Check these log files for debugging:

```bash
# System logs
journalctl -xe

# Niri logs
journalctl -u niri -f

# Desktop session logs
~/.xsession-errors

# Hardware detection logs
sudo detect-hardware.sh --dry-run apply
```

### Community Support

1. **Check documentation first**:
   - User guide: `docs/desktop-environment-user-guide.md`
   - Keyboard shortcuts: `docs/keyboard-shortcuts.md`

2. **Run validation tools**:
   - `validate-desktop-config.sh all`
   - `detect-hardware.sh summary`

3. **Gather information**:
   - System specs: `neofetch`
   - Error logs: `journalctl -xe`
   - Configuration files

4. **Common fixes to try**:
   - Restart desktop: `Super + Ctrl + R`
   - Reboot system
   - Run hardware detection
   - Validate configuration

---

## Emergency Procedures

### Desktop Completely Unresponsive

1. Switch to TTY: `Ctrl + Alt + F1`
2. Login with username and password
3. Check processes: `ps aux | grep niri`
4. Kill desktop: `pkill niri`
5. Restart services or reboot

### Can't Login Graphically

1. Switch to TTY: `Ctrl + Alt + F1`
2. Login with username and password
3. Check display manager: `sudo sv status sddm`
4. Restart display manager: `sudo sv restart sddm`
5. Check session files: `ls /usr/share/wayland-sessions/`

### Configuration Corruption

1. Backup current config:
   ```bash
   cp -r ~/.config ~/.config.backup
   ```

2. Reset to defaults:
   ```bash
   cp -r /etc/skel/.config ~/
   ```

3. Reboot and reconfigure

---

Remember that Voidance is designed to be educational. Learning to troubleshoot and configure the system is part of the experience!