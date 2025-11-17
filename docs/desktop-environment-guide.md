# Voidance Linux Desktop Environment Guide

## Overview

Voidance Linux provides a modern, minimalist desktop environment built around the Niri Wayland compositor. This guide covers the setup, configuration, and usage of the desktop environment components.

## Components

### Niri - Wayland Compositor
Niri is a scrollable tiling Wayland compositor that provides a modern, fluid window management experience with excellent performance and visual appeal.

### Waybar - Status Bar
A highly configurable status bar that displays system information, workspaces, and provides quick access to system controls.

### wofi - Application Launcher
A Wayland-native application launcher with fuzzy search, icons, and keyboard-driven workflow.

## Installation

### System-wide Installation
```bash
# Install desktop environment packages and system configuration
sudo ./scripts/setup-desktop-environment.sh install

# Set up desktop integration
sudo ./scripts/setup-desktop-integration.sh install

# Detect hardware and apply optimizations
sudo ./scripts/hardware-detection.sh optimize
```

### User-specific Installation
```bash
# Install for current user only
./scripts/setup-desktop-environment.sh --user install

# Set up user configuration
./scripts/setup-desktop-integration.sh --user install

# Apply user-specific optimizations
./scripts/hardware-detection.sh --user optimize
```

### Setup for Existing Users
```bash
# Set up desktop environment for a specific user
sudo ./scripts/setup-desktop-integration.sh user <username>

# Apply optimizations for the user
sudo ./scripts/setup-desktop-integration.sh user <username>
```

## Configuration

### Configuration Files Location

#### System-wide Configuration
- Niri: `/etc/xdg/niri/config.kdl`
- Waybar: `/etc/xdg/waybar/config` and `/etc/xdg/waybar/style.css`
- wofi: `/etc/xdg/wofi/config` and `/etc/xdg/wofi/style.css`
- Desktop Environment: `/etc/xdg/voidance/desktop-environment.json`

#### User Configuration
- Niri: `~/.config/niri/config.kdl`
- Waybar: `~/.config/waybar/config` and `~/.config/waybar/style.css`
- wofi: `~/.config/wofi/config` and `~/.config/wofi/style.css`
- Desktop Environment: `~/.config/voidance/desktop-environment.json`

### Niri Configuration

#### Basic Layout
```kdl
layout {
    gaps 8
    default-width 800
    default-height 600
}
```

#### Keybindings
```kdl
// Mod = Super (Windows key)
bind Mod+Return { spawn "ghostty" }
bind Mod+D { spawn "wofi" --show drun }
bind Mod+Q { close-window }
```

#### Output Configuration
```kdl
output "eDP-1" {
    mode 1920x1080@60.0
    scale 1.25
    position x=0 y=0
}
```

### Waybar Configuration

#### Modules Configuration
```json
{
    "modules-left": ["niri/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"]
}
```

#### Custom Styling
```css
window#waybar {
    background-color: #282828;
    color: #ebdbb2;
    border-bottom: 2px solid #458588;
}
```

### wofi Configuration

#### Basic Configuration
```json
{
    "mode": "drun",
    "width": "50%",
    "height": "40%",
    "location": "center",
    "allow_images": true
}
```

## Usage

### Starting the Desktop Environment

#### Via Display Manager (SDDM)
1. Log out of your current session
2. Select "Niri" from the session selector
3. Enter your credentials to log in

#### Manual Start
```bash
# Start Niri directly
niri-session

# Or start with custom configuration
niri -c ~/.config/niri/config.kdl
```

### Basic Window Management

#### Navigation
- `Mod + Arrow Keys`: Navigate between windows
- `Mod + 1-9`: Switch to workspace
- `Mod + Shift + Arrow Keys`: Move windows
- `Mod + Shift + 1-9`: Move window to workspace

#### Window Operations
- `Mod + Q`: Close focused window
- `Mod + F`: Toggle fullscreen
- `Mod + Space`: Focus column first/last
- `Mod + Comma`: Consume window to left
- `Mod + Period`: Consume window to right

#### Layout Management
- `Mod + S`: Spiral layout
- `Mod + T`: Stack layout
- `Mod + Y`: Horizontal layout
- `Mod + Shift + S`: Vertical layout
- `Mod + Shift + T`: Monocle layout

### Application Management

#### Launching Applications
- `Mod + D`: Open application launcher (wofi)
- `Mod + R`: Open run dialog
- Right-click on desktop: Open application menu

#### Common Applications
- Terminal: `Mod + Enter` or `ghostty`
- File Manager: `thunar`
- Text Editor: `nano` or `vim`
- Web Browser: `firefox`

### System Controls

#### Volume Control
- `XF86AudioRaiseVolume`: Increase volume
- `XF86AudioLowerVolume`: Decrease volume
- `XF86AudioMute`: Toggle mute

#### Brightness Control
- `XF86MonBrightnessUp`: Increase brightness
- `XF86MonBrightnessDown`: Decrease brightness

#### Media Control
- `XF86AudioPlay`: Play/pause
- `XF86AudioNext`: Next track
- `XF86AudioPrev`: Previous track

#### System Actions
- `Mod + L`: Lock screen
- `Mod + Shift + E`: Exit session
- `Mod + Print`: Screenshot
- `Mod + Shift + Print`: Area screenshot

## Customization

### Themes

#### Color Scheme
The desktop environment uses the Gruvbox color scheme by default. You can customize colors in:

- Niri: `background-color` in output configuration
- Waybar: CSS color variables in `style.css`
- wofi: Color settings in configuration

#### Fonts
Default font is "Fira Code Nerd Font". Change in:
- Waybar: `font-family` in CSS
- wofi: `font-family` in CSS
- Terminal: Configure in Ghostty settings

### Custom Keybindings

Add custom keybindings to `~/.config/niri/config.kdl`:

```kdl
bind Mod+Ctrl+B { spawn "firefox" }
bind Mod+Ctrl+F { spawn "thunar" }
bind Mod+Ctrl+T { spawn "ghostty" }
```

### Startup Applications

Add applications to start automatically in `~/.config/niri/config.kdl`:

```kdl
spawn-at-startup "firefox"
spawn-at-startup "thunar"
spawn-at-startup "discord"
```

### Window Rules

Define how specific applications should behave:

```kdl
window-rule {
    app_id "firefox"
    default-width 1200
    default-height 800
}

window-rule {
    app_id "pavucontrol"
    floating true
}
```

## Hardware Optimization

### GPU-Specific Settings

#### Intel Graphics
```kdl
output "eDP-1" {
    adaptive-sync true
}
```

#### NVIDIA Graphics
```kdl
environment {
    __GLX_GSYNC_ALLOWED "0"
    __GL_VRR_ALLOWED "0"
}
```

#### AMD Graphics
```kdl
environment {
    RADV_PERFTEST "sam"
}
```

### Performance Profiles

Run hardware detection to apply optimizations:
```bash
sudo ./scripts/hardware-detection.sh optimize
```

This creates a performance profile at `/etc/voidance/hardware/performance-profile.conf`.

### Multi-Monitor Setup

Configure multiple displays in Niri:
```kdl
output "eDP-1" {
    position x=0 y=0
    scale 1.25
}

output "HDMI-A-1" {
    position x=1920 y=0
    scale 1.0
}
```

## Troubleshooting

### Common Issues

#### Niri Won't Start
1. Check configuration syntax: `niri --verify-config`
2. Verify Wayland session: `echo $XDG_SESSION_TYPE`
3. Check GPU drivers: `lspci -k | grep -A2 -i vga`

#### Waybar Not Appearing
1. Check configuration: `waybar --config ~/.config/waybar/config --validate`
2. Verify modules: Check for syntax errors in configuration
3. Check dependencies: Ensure all required modules are installed

#### wofi Not Launching
1. Check installation: `xbps-query -s wofi`
2. Verify configuration: Check JSON syntax
3. Test manually: `wofi --show drun`

#### Application Windows Not Appearing
1. Check Wayland compatibility: Try with `GDK_BACKEND=wayland`
2. Verify Xwayland: Ensure Xwayland is running
3. Check application logs: Run from terminal to see errors

### Performance Issues

#### High CPU Usage
1. Check running processes: `ps aux | grep niri`
2. Monitor with `htop` or `btop`
3. Disable animations and effects

#### Memory Usage
1. Monitor with `free -h`
2. Check for memory leaks in applications
3. Adjust workspace and window limits

#### Graphics Performance
1. Update GPU drivers
2. Check for hardware acceleration
3. Verify compositor settings

### Getting Help

#### Logs and Debugging
```bash
# Niri logs
journalctl -u niri-session -f

# Waybar logs
waybar --log-level debug

# System logs
journalctl -xe
```

#### Configuration Validation
```bash
# Validate Niri configuration
niri --verify-config

# Validate Waybar configuration
waybar --config ~/.config/waybar/config --validate

# Validate desktop environment configuration
node ./scripts/validate-desktop-config.js validate
```

#### Hardware Testing
```bash
# Run comprehensive tests
sudo ./scripts/test-desktop-environment.sh all

# Test specific components
sudo ./scripts/test-desktop-environment.sh hardware
sudo ./scripts/test-desktop-environment.sh wayland
```

## Advanced Usage

### Scripting and Automation

#### Custom Scripts
Create custom scripts in `~/.local/bin/` and make them executable:

```bash
#!/bin/bash
# ~/.local/bin/lock-screen
swaylock -f -c 000000
```

#### Session Management
Create custom session scripts for different workflows:

```bash
#!/bin/bash
# ~/.local/bin/work-session
niri-session &
firefox &
thunar &
discord &
```

### Development Environment

#### Development Tools
Install development packages:
```bash
xbps-install -S git vim code node rust cargo
```

#### Terminal Multiplexing
Use terminal multiplexers for development:
```bash
# Install tmux
xbps-install -S tmux

# Configure in Niri
bind Mod+Ctrl+T { spawn "tmux" new-session }
```

### Security

#### Screen Locking
Configure secure screen locking:
```kdl
bind Mod+L { spawn "swaylock" -f -c 000000 -i ~/Pictures/wallpaper.jpg }
```

#### Privacy Settings
Disable telemetry and tracking:
```kdl
environment {
    MOZ_TELEMETRY_REPORTING "0"
    QT_AUTO_SCREEN_SCALE_FACTOR "0"
}
```

## Resources

### Documentation
- [Niri Documentation](https://github.com/YaLTeR/niri)
- [Waybar Documentation](https://github.com/Alexays/Waybar)
- [wofi Documentation](https://hg.sr.ht/~scoopta/wofi)

### Community
- [Void Linux Forums](https://forum.voidlinux.org/)
- [Wayland Discourse](https://discourse.wayland.org/)
- [Niri GitHub](https://github.com/YaLTeR/niri)

### Configuration Examples
- [Niri Configuration Examples](https://github.com/YaLTeR/niri/wiki)
- [Waybar Configuration](https://github.com/Alexays/Waybar/wiki)
- [wofi Styles](https://github.com/scoopta/wofi/wiki)

---

This guide covers the essential aspects of using and customizing the Voidance Linux desktop environment. For more advanced configuration and troubleshooting, refer to the individual component documentation and community resources.