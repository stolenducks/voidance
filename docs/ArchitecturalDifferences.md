# Architectural Differences: Voidance vs Omarchy

## Purpose of This Document

Voidance is **inspired by** [Omarchy](https://github.com/basecamp/omarchy), but is **not a direct port**. This document explains the fundamental differences in approach, philosophy, and technical implementation.

---

## Core Philosophy

### Omarchy (Arch Linux)
- **Transform existing installations**: Run `boot.sh` on vanilla Arch
- **Deep system integration**: 100+ utility scripts for ongoing system management
- **Post-install customization**: User installs Arch, then runs Omarchy
- **Opinionated automation**: Scripts handle everything from themes to updates

### Voidance (Void Linux)
- **Pre-built distribution**: Custom ISO ready to install
- **Beginner-first experience**: Works out of the box with minimal setup
- **Installation-focused**: Get users productive immediately
- **Void-native tooling**: Embrace Void's philosophy and tools

---

## Technical Differences

### 1. Distribution Fundamentals

| Aspect | Arch Linux (Omarchy) | Void Linux (Voidance) |
|--------|---------------------|---------------------|
| **Package Manager** | `pacman` + AUR helpers | `xbps` (faster, simpler) |
| **Init System** | `systemd` | `runit` (minimalist) |
| **Installation** | Manual (Arch Wiki) | ISO installer |
| **Philosophy** | DIY, bleeding edge | Stable, independent |
| **C Library** | glibc | glibc or musl |

### 2. Project Structure

#### Omarchy Structure
```
omarchy/
├── boot.sh              # Main transformation script
├── bin/                 # 100+ utility scripts (omarchy-*)
│   ├── omarchy-theme-set
│   ├── omarchy-launch-browser
│   ├── omarchy-update
│   └── ...
├── applications/        # Web app desktop entries & icons
├── install/             # Installation routines
└── config/              # Dotfiles & configurations
```

**Why**: Post-install transformation requires extensive tooling for ongoing management.

#### Voidance Structure
```
voidance/
├── scripts/             # Build & install scripts
│   ├── build-iso.sh
│   ├── installer.sh
│   └── update.sh
├── iso-builder/         # void-mklive integration
├── config/              # Pre-configured dotfiles
├── packages/            # Package lists
├── themes/              # Visual themes
└── docs/                # User documentation
```

**Why**: ISO-first approach focuses on build tooling and initial configuration rather than post-install management.

### 3. Installation Flow

#### Omarchy
1. Install Arch manually (following Arch Wiki)
2. Boot into fresh Arch system
3. Download Omarchy: `curl -o boot.sh https://omarchy.org/boot.sh`
4. Run transformation: `bash boot.sh`
5. System transforms into Omarchy

#### Voidance
1. Build custom ISO: `./scripts/build-iso.sh`
2. Flash ISO to USB or boot in VM
3. Run Voidance installer (guided GUI/TUI)
4. Reboot into fully configured system
5. Done!

### 4. Package Management Examples

#### Omarchy (Arch)
```bash
# Install packages
omarchy-pkg-install firefox
pacman -S firefox
yay -S discord  # AUR

# System updates
omarchy-update
```

#### Voidance (Void)
```bash
# Install packages
sudo xbps-install -S firefox
sudo xbps-install -S discord  # No AUR, only official repos

# System updates
sudo xbps-install -Su
```

### 5. Service Management

#### Omarchy (systemd)
```bash
# Enable/start services
systemctl enable --now bluetooth
systemctl status waybar

# User services
systemctl --user enable pipewire
```

#### Voidance (runit)
```bash
# Enable/start services
sudo ln -s /etc/sv/bluetoothd /var/service/
sudo sv status bluetoothd

# User services (via runsvdir)
mkdir -p ~/.local/service
ln -s /etc/sv/pipewire ~/.local/service/
```

---

## Why Not Port Omarchy Directly?

### 1. **Different Package Ecosystems**
- Arch has AUR (60,000+ packages)
- Void has official repos (~12,000 packages)
- Many Arch-specific packages don't exist on Void
- Requires different solutions for same problems

### 2. **Init System Complexity**
- Omarchy's service management deeply tied to systemd
- runit requires completely different approach
- No direct translation of service files

### 3. **Installation Philosophy**
- Arch users expect manual installation → post-install transformation works
- Void users often want turnkey solutions → ISO distribution works better

### 4. **Maintenance Burden**
- 100+ utility scripts require constant maintenance
- Voidance prioritizes solid defaults over extensive tooling
- Focus energy on polish, not script proliferation

---

## What Voidance Keeps from Omarchy

✅ **Visual aesthetic**: Beautiful, modern, Catppuccin-themed  
✅ **Developer focus**: Pre-configured dev tools, web apps, shortcuts  
✅ **Wayland-first**: Hyprland, Waybar, Walker, Mako  
✅ **Curated experience**: Opinionated choices for batteries-included setup  
✅ **Web app wrappers**: ChatGPT, Figma, Notion as desktop apps  

---

## What Voidance Does Differently

🆕 **ISO distribution**: Ready-to-install experience  
🆕 **Void-native**: Embraces xbps, runit, Void philosophy  
🆕 **Beginner-first**: Less scripting, more "just works"  
🆕 **Minimal tooling**: Focus on solid defaults, not utility scripts  
🆕 **musl option**: Optional musl libc builds for embedded/minimal systems  

---

## Design Decisions

### 1. No `voidance-*` Utility Scripts (Yet)
- **Why**: ISO distribution means most setup happens at install time
- **Exception**: May add utilities later for theme switching, updates
- **Philosophy**: Prefer Void's native tools (`xbps`, `sv`, etc.)

### 2. Pre-Configured vs. Post-Configured
- **Omarchy**: Transform → Configure → Use
- **Voidance**: Configure → Build → Use
- Configurations baked into ISO, not applied after

### 3. Documentation Over Automation
- Teach users Void's native tools
- Don't hide complexity behind custom scripts
- Empower users to understand their system

### 4. Selective Inspiration
We take Omarchy's **spirit** (polished dev experience) but adapt the **implementation** to Void's strengths.

---

## Future Considerations

As Voidance matures, we may:
- Add `voidance-theme-set` for easy theme switching
- Create `voidance-update` wrapper around `xbps-install -Su`
- Build web app installer script
- Add desktop notification helpers

But we'll always prioritize:
1. Void-native solutions first
2. Simplicity over feature creep
3. Teachable moments over magic

---

## Summary

| Aspect | Omarchy | Voidance |
|--------|---------|----------|
| Base | Arch Linux | Void Linux |
| Delivery | Post-install transformation | Pre-built ISO |
| Package Mgmt | pacman + AUR | xbps only |
| Init | systemd | runit |
| Tooling | 100+ scripts | Minimal (build-focused) |
| Philosophy | Transform existing | Install fresh |
| Target User | Arch enthusiasts | Linux beginners |

**Bottom Line**: Voidance is a **spiritual successor**, not a **technical port**. We honor Omarchy's vision while respecting Void's unique strengths and philosophy.

---

## Contributing

When contributing to Voidance:
- ✅ Suggest features that work with Void's ecosystem
- ✅ Use xbps, runit, and Void-native tools
- ✅ Keep beginner accessibility in mind
- ❌ Don't try to replicate Arch/systemd patterns
- ❌ Don't add scripts without clear justification

Questions? See [GOVERNANCE.md](../GOVERNANCE.md) or [Contributing.md](Contributing.md).
