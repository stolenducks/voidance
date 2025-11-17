# Voidance Desktop Environment User Guide

## Overview

Voidance Linux provides a minimalist yet functional desktop environment built around modern Wayland technologies. The desktop environment consists of:

- **Niri**: A scrollable tiling Wayland compositor
- **Waybar**: A highly configurable status bar
- **wofi**: A Wayland-native application launcher
- **Foot**: A fast, lightweight terminal emulator

## Getting Started

### First Login

1. After installation, select "Niri" from the SDDM login screen
2. You'll be greeted with a minimal desktop environment
3. Press `Super + D` to open the application launcher
4. Press `Super + Return` to open a terminal

### Basic Navigation

The desktop uses tiling window management, which automatically arranges windows in a grid layout:

- **Super + Arrow Keys**: Navigate between windows
- **Super + Shift + Arrow Keys**: Move windows between positions
- **Super + 1-9**: Switch between workspaces
- **Super + Shift + 1-9**: Move focused window to workspace

## Keyboard Shortcuts

### Window Management

| Shortcut | Action |
|-----------|--------|
| `Super + Return` | Open terminal |
| `Super + D` | Open application launcher |
| `Super + R` | Open run command |
| `Super + Q` | Close focused window |
| `Super + Shift + Q` | Force close focused window |
| `Super + F` | Toggle fullscreen for focused window |
| `Super + Shift + F` | Toggle fullscreen for column |

### Navigation

| Shortcut | Action |
|-----------|--------|
| `Super + Left/Right` | Focus left/right column |
| `Super + Up/Down` | Focus up/down window |
| `Super + Shift + Left/Right` | Move column left/right |
| `Super + Shift + Up/Down` | Move window up/down |

### Workspace Management

| Shortcut | Action |
|-----------|--------|
| `Super + 1-9` | Switch to workspace 1-9 |
| `Super + Shift + 1-9` | Move window to workspace 1-9 |
| `Super + Shift + 1-9` | Consume window into column 1-9 |

### Layout Management

| Shortcut | Action |
|-----------|--------|
| `Super + S` | Switch to spiral layout |
| `Super + T` | Switch to stack layout |
| `Super + Y` | Switch to horizontal layout |
| `Super + Shift + S` | Switch to vertical layout |
| `Super + Shift + T` | Switch to monocle layout |

### Column/Window Sizing

| Shortcut | Action |
|-----------|--------|
| `Super + Ctrl + Left/Right` | Decrease/increase column width |
| `Super + Ctrl + Up/Down` | Decrease/increase window height |
| `Super + Home/End` | Focus first/last column |
| `Super + Ctrl + Home/End` | Focus first/last window |

### Application Management

| Shortcut | Action |
|-----------|--------|
| `Super + Comma` | Consume or expel window left |
| `Super + Period` | Consume or expel window right |
| `Super + Space` | Focus first or last window in column |
| `Super + Shift + Space` | Toggle column tabbed display |

### Screenshots and Recording

| Shortcut | Action |
|-----------|--------|
| `Super + Print` | Screenshot entire screen to clipboard |
| `Super + Shift + Print` | Screenshot selected region to clipboard |
| `Super + Ctrl + Print` | Start screen recording |

### System Control

| Shortcut | Action |
|-----------|--------|
| `Super + L` | Lock screen |
| `Super + Shift + E` | Exit compositor |
| `Super + Ctrl + R` | Reload configuration |

### Media Keys

| Shortcut | Action |
|-----------|--------|
| `XF86AudioRaiseVolume` | Increase volume |
| `XF86AudioLowerVolume` | Decrease volume |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle microphone mute |
| `XF86MonBrightnessUp` | Increase brightness |
| `XF86MonBrightnessDown` | Decrease brightness |
| `XF86AudioPlay` | Play/pause media |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |

## Status Bar (Waybar)

The status bar at the top of the screen provides:

- **Workspaces**: Shows numbered workspaces (一, 二, 三, etc.)
- **Clock**: Current time and date
- **Volume**: Audio volume control (click to open pavucontrol)
- **Network**: Network status and connection info
- **Battery**: Battery level and status (on laptops)
- **System Tray**: System tray icons

### Waybar Interactions

- **Click volume**: Open audio control panel
- **Click network**: Open network connection editor
- **Scroll on volume**: Adjust volume
- **Click clock**: Toggle calendar view

## Application Launcher (wofi)

The application launcher provides quick access to installed applications:

### Using the Launcher

1. Press `Super + D` to open the launcher
2. Start typing to filter applications
3. Use arrow keys to navigate
4. Press `Enter` to launch selected application
5. Press `Escape` to cancel

### Launcher Features

- **Fuzzy search**: Find applications by typing partial names
- **Icons**: Shows application icons when available
- **Categories**: Applications are grouped by category
- **Recent apps**: Frequently used apps appear first

### Run Command

Press `Super + R` to open the run command dialog for executing shell commands.

## Terminal (Foot)

Foot is a fast, lightweight terminal emulator with Wayland native support.

### Terminal Features

- **Copy/Paste**: Use standard terminal shortcuts or mouse selection
- **Tabs**: Create new terminal tabs
- **Scrolling**: Mouse wheel or key combinations
- **Unicode**: Full Unicode and emoji support

### Common Terminal Commands

```bash
# Update system
sudo xbps-install -Su

# Install packages
sudo xbps-install package_name

# Search packages
xbps-query -Rs search_term

# Remove packages
sudo xbps-remove package_name

# System information
neofetch
```

## Session Management

### Lock Screen

- Press `Super + L` to lock the screen
- Or use the session manager: `session-manager lock`

### Logout/Shutdown

Use the session manager for system control:

```bash
# Show interactive menu
session-manager menu

# Direct commands
session-manager logout
session-manager reboot
session-manager shutdown
```

### Session Menu

The session menu provides options for:
- Logout from current session
- Lock screen
- Suspend system
- Hibernate system
- Reboot system
- Shutdown system

## Configuration

### Configuration Files

Desktop environment configurations are stored in:

- `~/.config/niri/config.kdl` - Niri compositor settings
- `~/.config/waybar/config` - Status bar configuration
- `~/.config/wofi/config` - Launcher settings
- `~/.config/wofi/style.css` - Launcher styling

### Reloading Configuration

After making changes to configuration files:

- **Niri**: Press `Super + Ctrl + R` or run `niri msg reload-config`
- **Waybar**: Restart with `pkill waybar && waybar &`
- **wofi**: Changes apply on next launch

### Hardware Detection

The system automatically detects hardware and applies optimizations:

```bash
# Run hardware detection
sudo detect-hardware.sh apply

# Show current hardware profile
detect-hardware.sh summary
```

## Customization

### Themes

The desktop uses the Voidance dark theme with colors:
- Background: `#282828`
- Foreground: `#ebdbb2`
- Accent: `#458588`
- Border: `#665c54`

### Custom Keybindings

Edit `~/.config/niri/config.kdl` to add custom keybindings:

```kdl
bind Mod+YourKey { spawn "your-command" }
```

### Custom Applications

Add desktop entry files to `~/.local/share/applications/` for custom applications.

## Troubleshooting

### Common Issues

**Application won't start**
- Check if application is Wayland native
- Try running from terminal to see error messages
- Verify application is installed: `xbps-query application_name`

**Screen resolution wrong**
- Run hardware detection: `sudo detect-hardware.sh apply`
- Manually configure in `~/.config/niri/config.kdl`

**No sound**
- Check audio services: `sudo sv status pipewire pipewire-pulse`
- Restart audio services: `sudo sv restart pipewire pipewire-pulse`

**Network not working**
- Check NetworkManager: `sudo sv status NetworkManager`
- Restart network: `sudo sv restart NetworkManager`

**Performance issues**
- Check system resources: `htop`
- Run hardware detection for optimizations
- Disable animations in Niri config

### Getting Help

- Check logs: `journalctl -xe`
- Validate configuration: `validate-desktop-config.sh all`
- Hardware status: `detect-hardware.sh summary`

## Educational Aspects

The Voidance desktop environment is designed to be educational:

### Understanding Wayland

- Learn about modern display server technology
- Understand protocol-based window management
- Explore Wayland vs X11 differences

### Tiling Window Management

- Master efficient window organization
- Learn keyboard-driven workflow
- Understand layout algorithms

### System Configuration

- Study configuration file formats (KDL, JSON, CSS)
- Learn about hardware detection and optimization
- Understand desktop environment integration

### Shell and Scripting

- Practice command-line interface usage
- Learn shell scripting for automation
- Understand system service management

## Advanced Usage

### Multiple Monitors

The desktop automatically detects multiple monitors and configures them appropriately. Manual configuration is available in the Niri config file.

### Touchpad Gestures

Touchpad gestures are supported for navigation and scrolling. Configure touchpad settings in the Niri input configuration.

### Performance Profiles

Hardware detection automatically applies performance profiles based on system capabilities:
- **High**: 8+ cores, 16GB+ RAM
- **Medium**: 4+ cores, 8GB+ RAM  
- **Low**: Less than medium specs

### Development Environment

The desktop is optimized for development with:
- Fast terminal emulator
- Efficient window management
- Quick application launching
- Minimal resource usage

## Resources

- **Niri Documentation**: https://github.com/YaLTeR/niri
- **Waybar Documentation**: https://github.com/Alexays/Waybar
- **wofi Documentation**: https://hg.sr.ht/~scoopta/wofi
- **Ghostty Terminal**: https://github.com/mitchellh/ghostty
- **Void Linux Documentation**: https://docs.voidlinux.org/

## Support

For Voidance-specific issues:
1. Check this guide first
2. Run validation: `validate-desktop-config.sh all`
3. Check hardware detection: `detect-hardware.sh summary`
4. Review system logs: `journalctl -xe`

Remember that Voidance is designed to be minimal and educational. Learning to configure and troubleshoot the system is part of the experience!