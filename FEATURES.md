# Features

## 🎨 Pre-Configured Desktop Environment

### Hyprland Window Manager
- Dynamic tiling with smooth animations
- Blur effects and eye candy
- Workspace management (1-9)
- Touch gesture support
- Multi-monitor ready

### Waybar Status Bar
- System stats (CPU, RAM, disk)
- Network status (WiFi/Ethernet)
- Audio controls
- Clock and calendar
- Workspace indicators
- Catppuccin theme integration

### Walker App Launcher
- Fast fuzzy search
- Application icons
- Recent apps
- Calculator mode
- Custom actions

### Mako Notifications
- Non-intrusive popups
- Action buttons
- Notification history
- Themed to match desktop

---

## 🛠️ Developer Tools

### Terminal & Shell
- **Alacritty**: GPU-accelerated terminal
- **Zsh**: Modern shell with completions
- **Starship**: Minimal, fast prompt

### Text Editors
- **Neovim**: Pre-configured with sensible defaults
- **VS Code** (optional): Full IDE experience

### Development Utilities
- Git with diff-so-fancy
- Node.js & npm
- Python 3
- Go
- Rust
- Docker support

---

## 🌐 Web & Productivity

### Browser Setup
- **Firefox**: Privacy-focused, customized
- **Web app wrappers**:
  - ChatGPT (Super + C)
  - Figma (Super + Shift + F)
  - Notion (Super + N)
  - Linear
  - Slack

### Productivity Apps
- Thunar file manager with bulk rename
- Archive support (zip, tar, 7z)
- Image viewer (imv)
- PDF viewer (zathura)
- Screenshot tool (grimblast)
- Color picker (hyprpicker)

---

## 🎵 Multimedia

### Audio
- **PipeWire**: Low-latency audio server
- **WirePlumber**: Session manager
- **Pavucontrol**: Volume control GUI
- **Bluetooth** audio support

### Media Players
- **mpv**: Minimal video player
- **Spotify** (optional)

---

## 🔒 Security & Privacy

- **LUKS encryption** option during install
- **Firewall** (nftables) pre-configured
- **No telemetry** or tracking
- Minimal attack surface
- Regular security updates via xbps

---

## 🎨 Theming

### Catppuccin Theme Suite
- GTK theme (Mocha variant)
- Icon pack (Papirus-Dark)
- Cursor theme
- Terminal colors
- Application themes (Firefox, Discord, etc.)

### Wallpapers
- Curated collection
- Rotating wallpaper script
- Easy customization

---

## ⚡ Performance

- **Fast boot** with runit init
- **Low RAM usage** (~400MB idle)
- **No bloat**: Only essential packages
- **Optimized builds** for modern CPUs
- **SSD TRIM** enabled by default

---

## 🔧 System Management

### Package Management
- **xbps**: Fast, reliable package manager
- **xbps-src**: Build from source easily
- Automatic update checking

### Service Management
- **runit**: Simple, fast init system
- Easy service enable/disable
- Per-user services support

### Power Management
- Laptop mode tools
- CPU frequency scaling
- Suspend/hibernate support
- Battery status in Waybar

---

## 🌍 Locale & Input

- Multi-language support
- fcitx5 for Asian languages (optional)
- Emoji picker
- US/International keyboard layouts

---

## 📦 Easy Updates

Update script handles:
- System packages
- Config files
- Theme updates
- Kernel updates
- Service restarts

Run: `sudo ./scripts/update.sh`

---

## 🚀 Quick Setup

- **One-command install**: Flash ISO and go
- **Post-install script**: Customize after first boot
- **Dotfiles backup**: Easy to restore settings
- **Documentation**: Clear guides for everything

---

## 🎯 Coming Soon

- [ ] Automated dotfiles sync
- [ ] Custom kernel options
- [ ] Gaming optimizations
- [ ] VPN integration (Mullvad/Tailscale)
- [ ] Backup utility
- [ ] System snapshot tool (btrfs/ZFS)

