# Voidance Desktop Environment - Quick Reference

## Essential Keybindings

### Window Management
| Keybinding | Action |
|-----------|--------|
| `Mod + Enter` | Open terminal |
| `Mod + D` | Application launcher |
| `Mod + Q` | Close window |
| `Mod + F` | Toggle fullscreen |
| `Mod + L` | Lock screen |

### Navigation
| Keybinding | Action |
|-----------|--------|
| `Mod + ←/→` | Navigate windows |
| `Mod + ↑/↓` | Navigate windows |
| `Mod + 1-9` | Switch workspace |
| `Mod + Shift + ←/→` | Move windows |
| `Mod + Shift + 1-9` | Move to workspace |

### Layouts
| Keybinding | Action |
|-----------|--------|
| `Mod + S` | Spiral layout |
| `Mod + T` | Stack layout |
| `Mod + Y` | Horizontal layout |
| `Mod + Shift + S` | Vertical layout |
| `Mod + Shift + T` | Monocle layout |

### System Controls
| Keybinding | Action |
|-----------|--------|
| `Mod + Print` | Screenshot |
| `Mod + Shift + Print` | Area screenshot |
| `Mod + Shift + E` | Exit session |
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Toggle mute |

## Configuration Files

### Locations
- **Niri**: `~/.config/niri/config.kdl`
- **Waybar**: `~/.config/waybar/config` + `style.css`
- **wofi**: `~/.config/wofi/config` + `style.css`
- **Environment**: `~/.config/voidance/environment`

### Quick Niri Config
```kdl
layout {
    gaps 8
    default-width 800
    default-height 600
}

bind Mod+Return { spawn "ghostty" }
bind Mod+D { spawn "wofi" --show drun }
```

## Common Commands

### Desktop Management
```bash
# Start desktop
niri-session

# Reload configuration
niri msg reload

# Exit session
niri msg quit

# Lock screen
swaylock -f -c 000000

# Screenshot
grim - | wl-copy

# Area screenshot
grim -g "$(slurp)" - | wl-copy
```

### Application Management
```bash
# Launch apps
wofi --show drun
wofi --show run

# Audio control
pactl set-sink-volume @DEFAULT_SINK@ +5%
pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brightness
brightnessctl set +10%
brightnessctl set 10%-
```

## Troubleshooting

### Quick Fixes
```bash
# Check Niri config
niri --verify-config

# Check Waybar config
waybar --config ~/.config/waybar/config --validate

# Restart Waybar
pkill waybar; waybar &

# Check services
systemctl --user status waybar
systemctl status sddm
```

### Common Issues
- **Niri won't start**: Check config syntax with `niri --verify-config`
- **Waybar missing**: Install with `xbps-install -S waybar`
- **wofi not working**: Ensure Wayland session: `echo $XDG_SESSION_TYPE`
- **No sound**: Check PipeWire: `systemctl --user status pipewire`

## Hardware Optimization

### Auto-detect and optimize
```bash
sudo ./scripts/hardware-detection.sh optimize
```

### Manual GPU settings
```kdl
// Intel
output "eDP-1" { adaptive-sync true }

// NVIDIA
environment { __GLX_GSYNC_ALLOWED "0" }

// AMD
environment { RADV_PERFTEST "sam" }
```

## Testing

### Run all tests
```bash
sudo ./scripts/test-desktop-environment.sh all
```

### Test specific areas
```bash
sudo ./scripts/test-desktop-environment.sh packages
sudo ./scripts/test-desktop-environment.sh hardware
sudo ./scripts/test-desktop-environment.sh wayland
```

## File Locations

### System-wide
- `/etc/xdg/niri/config.kdl`
- `/etc/xdg/waybar/`
- `/etc/xdg/wofi/`
- `/usr/share/wayland-sessions/niri.desktop`

### User-specific
- `~/.config/niri/`
- `~/.config/waybar/`
- `~/.config/wofi/`
- `~/.config/voidance/`

## Environment Variables

### Key Variables
```bash
XDG_CURRENT_DESKTOP=niri
XDG_SESSION_TYPE=wayland
MOZ_ENABLE_WAYLAND=1
QT_QPA_PLATFORM=wayland
TERMINAL=ghostty
BROWSER=firefox
```

### Set in `~/.config/voidance/environment`

## Default Applications

| Category | Application | Command |
|----------|-------------|---------|
| Terminal | Ghostty | `ghostty` |
| Browser | Firefox | `firefox` |
| File Manager | Thunar | `thunar` |
| Text Editor | Nano | `nano` |
| Launcher | wofi | `wofi --show drun` |
| Screenshot | Grim | `grim` |
| Screen Lock | Swaylock | `swaylock` |

## Performance Tips

1. **Enable hardware acceleration** in applications
2. **Use adaptive sync** for supported displays
3. **Disable animations** on low-end hardware
4. **Optimize GPU settings** for your hardware
5. **Monitor resource usage** with `htop` or `btop`

## Getting Help

### Commands
```bash
# Niri help
niri --help
niri-msg --help

# Waybar help
waybar --help

# wofi help
wofi --help
```

### Logs
```bash
# System logs
journalctl -xe

# User session logs
journalctl --user -xe

# Niri logs
journalctl -u niri-session -f
```

---

*Mod = Super (Windows) key*