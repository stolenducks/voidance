# Voidance Project Structure

Quick reference for navigating the Voidance codebase.

## 📂 Directory Layout

```
voidance/
├── config/              # User-facing configurations
│   ├── hypr/           # Hyprland window manager config
│   ├── waybar/         # Status bar config
│   ├── mako/           # Notification daemon config
│   └── walker/         # App launcher config
│
├── packages/           # Package definitions
│   └── packages.txt    # List of packages for ISO build
│
├── scripts/            # Production scripts
│   ├── build-iso.sh    # Build Voidance ISO (native)
│   ├── auto-install.sh # Automated installation script
│   ├── transform.sh    # Transform existing Void to Voidance
│   ├── installer.sh    # Post-install configuration
│   └── update.sh       # System update utility
│
├── testing/            # Development & testing tools
│   ├── README.md       # Testing documentation
│   ├── docker-*.sh     # Docker build scripts
│   ├── test-*.sh       # QEMU testing scripts
│   ├── run-vm.sh       # VM launcher
│   └── Dockerfile*     # Docker configurations
│
├── iso-builder/        # ISO build configuration
│   └── mkimage-void.conf
│
├── docs/               # User documentation
│   ├── GettingStarted.md
│   ├── Troubleshooting.md
│   ├── KeyboardShortcuts.md
│   └── ...
│
├── themes/             # Visual themes
│   └── wallpapers/
│
├── shared/             # VM shared folder (gitignored)
│
├── install.sh          # Remote one-line installer
├── README.md           # Project overview
├── CLEANUP_2025.md     # Cleanup documentation
└── PROJECT_STRUCTURE.md # This file
```

## 🎯 What Goes Where

### Production Code (For End Users)
**Location**: Root, `scripts/`, `config/`, `packages/`

- Installation scripts
- Configuration files
- Package lists
- ISO build scripts
- System utilities

### Development Tools (For Contributors)
**Location**: `testing/`

- Docker configurations
- VM testing scripts
- QEMU launch scripts
- Development utilities

### Documentation
**Location**: `docs/`, root markdown files

- User guides
- Troubleshooting
- Architecture docs
- Project governance

## 🚀 Common Tasks

### For End Users

**Install Voidance:**
```bash
curl -L https://raw.githubusercontent.com/stolenducks/voidance/main/install.sh | sh
```

**Build ISO (on Void Linux):**
```bash
sudo ./scripts/build-iso.sh
```

### For Developers

**Build ISO (on macOS/Windows):**
```bash
cd testing
./docker-build.sh
```

**Test ISO in VM:**
```bash
cd testing
./test-iso.sh
```

**Run VM with ISO:**
```bash
cd testing
./run-vm.sh ../voidance.iso
```

## 📝 File Naming Conventions

### Scripts
- `*.sh` - Shell scripts (Bash)
- Executable permissions set
- Clear, descriptive names

### Configs
- `*.conf` - Configuration files
- `*.txt` - Text lists (packages, etc.)
- Lowercase with hyphens

### Documentation
- `*.md` - Markdown documentation
- UPPERCASE for root-level docs (README.md, LICENSE)
- Title case for guides (GettingStarted.md)

## 🔍 Finding Things

### "Where do I find...?"

**Hyprland keybindings?**  
→ `config/hypr/hyprland.conf`

**Package list?**  
→ `packages/packages.txt`

**Build the ISO?**  
→ `scripts/build-iso.sh` (native) or `testing/docker-build.sh` (Docker)

**Test in VM?**  
→ `testing/test-iso.sh`

**Install on existing Void?**  
→ `install.sh` or `scripts/transform.sh`

**Troubleshooting guide?**  
→ `docs/Troubleshooting.md`

**Testing documentation?**  
→ `testing/README.md`

## 🚫 What NOT to Commit

Automatically excluded by `.gitignore`:

- `*.iso` - Built ISO files
- `*.qcow2` - VM disk images
- `iso-builder/tmp/` - Build artifacts
- `*.log` - Log files
- `.DS_Store` - macOS files
- `shared/*` - VM shared folder contents

## 🔗 Quick Links

- [Main README](README.md) - Project overview
- [Getting Started](docs/GettingStarted.md) - Installation guide
- [Testing Guide](testing/README.md) - Development & testing
- [Troubleshooting](docs/Troubleshooting.md) - Common issues
- [Contributing](docs/Contributing.md) - How to contribute
- [Cleanup Log](CLEANUP_2025.md) - Recent reorganization

## 📊 Component Organization

### Window Manager Stack
```
Hyprland (compositor)
├── Waybar (status bar)
├── Walker (launcher)
├── Mako (notifications)
├── Hyprpaper (wallpaper)
├── Hyprlock (screen lock)
└── Hypridle (idle management)
```

### Audio Stack
```
PipeWire (audio server)
└── WirePlumber (session manager)
    └── PulseAudio compatibility
```

### System Services (runit)
```
/etc/sv/              # Service definitions
└── /var/service/     # Enabled services (symlinks)
```

## 🎨 Configuration Hierarchy

User configs are organized by purpose:

```
~/.config/
├── hypr/           # Window manager
├── waybar/         # Status bar
├── mako/           # Notifications
├── walker/         # Launcher
├── alacritty/      # Terminal
└── ...
```

## 🔧 Maintenance

### Keep Clean
- Run builds in `iso-builder/tmp/` (auto-cleaned)
- Test VMs create disks in root (gitignored)
- Logs go to `/tmp` or user home (gitignored)

### Regular Tasks
- Update package list: `vim packages/packages.txt`
- Update configs: `vim config/hypr/hyprland.conf`
- Clean build cache: `sudo rm -rf iso-builder/tmp`

## 💡 Design Principles

1. **Separation of Concerns**: Testing tools isolated from production
2. **Beginner Friendly**: Clear structure, good documentation
3. **Real Hardware First**: No VM-specific compromises
4. **Void Linux Native**: Follows Void conventions (runit, xbps)
5. **Transparent**: All code readable and documented

---

Last Updated: 2025-01-29  
See: [CLEANUP_2025.md](CLEANUP_2025.md) for reorganization details
