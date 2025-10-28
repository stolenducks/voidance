# Voidance

🚀 **Voidance** — a beginner-friendly, modern Void Linux remix inspired by **Omarchy (Arch-based)**, focused on simplicity, aesthetics, and developer productivity.

Voidance brings the minimal power of Void Linux with the curated, plug-and-play experience of Omarchy:
- 🪟 **Hyprland** tiling window manager
- ⚙️ **Waybar**, **Walker**, **Mako**, and other Wayland essentials
- 🎨 Pre-themed look & feel out of the box
- 💻 Dev-ready tools, browsers, and web-app wrappers (ChatGPT, Figma, Notion, etc.)
- 🔐 Secure defaults (LUKS encryption optional)
- 🧰 Streamlined ISO & install script powered by `void-mklive`

---

## 🧩 Project Goals

1. Deliver a **ready-to-use Void Linux ISO** that’s beginner-friendly.  
2. Provide an **Omarchy-like developer environment** with Hyprland.  
3. Include **curated apps, themes, and usability enhancements**.  
4. Teach Linux concepts gently while staying polished and fast.  
5. Remain fully transparent, open source, and community-driven.

---

## 🧠 Inspiration

Voidance is **inspired by** [Omarchy](https://github.com/basecamp/omarchy) but adapted for Void Linux. We're a spiritual successor, not a direct port.

📖 **Read**: [Architectural Differences](docs/ArchitecturalDifferences.md) to understand why Voidance differs from Omarchy.

**Key Influences:**
- [Omarchy (Arch)](https://github.com/basecamp/omarchy) — The vision
- [Void Linux](https://voidlinux.org) — The foundation
- [Hyprland](https://hyprland.org) — The beauty
- [Catppuccin Theme](https://github.com/catppuccin/catppuccin) — The colors

---

## 📦 Core Components

| Component | Purpose |
|------------|----------|
| `Hyprland` | Window manager (tiling + animations) |
| `Waybar` | Status bar (system info, network, audio, clock) |
| `Walker` | App launcher (Alt + D) |
| `Mako` | Notification daemon |
| `PipeWire` + `WirePlumber` | Audio & mic |
| `Thunar` | File manager |
| `Firefox` | Browser w/ web-app wrappers (ChatGPT, Figma, Notion) |
| `Alacritty` | Terminal |
| `Neovim` | Developer editor |
| `runit` | Init system (Void default) |

---

## 🚀 Installation

### Method 1: Automated Installer (Easiest) ⭐

**Zero configuration required!** Just boot the Void ISO and run one command:

1. **Download Void Linux ISO** ([Download](https://voidlinux.org/download/))
   - Use the **base** live image (glibc)

2. **Boot from USB and login**
   - Username: `root`
   - Password: `voidlinux`

3. **Run the auto-installer**
   ```bash
curl -L https://raw.githubusercontent.com/stolenducks/voidance/main/scripts/auto-install.sh | bash
   ```

4. **Follow the prompts**
   - Select disk
   - Create username/password
   - Wait ~15-20 minutes
   - Reboot!

Hyprland starts automatically on login. Done! 🎉

---

### Method 2: Transform Existing Void Installation

Already have Void Linux installed? Transform it:

```bash
curl -L https://raw.githubusercontent.com/stolenducks/voidance/main/install.sh | sh
```

---

**What you get:**
- ✅ Hyprland tiling window manager
- ✅ Pre-configured Waybar, Walker, Mako
- ✅ Developer tools (Neovim, Git, Node, Go, Python)
- ✅ Catppuccin theme out of the box
- ✅ 120+ curated packages
- ✅ Auto-partitioning, bootloader, everything!

### Advanced Options

**Custom Installation**
- Full disk encryption (LUKS)
- Custom partitioning (LVM, RAID)
- See: [Manual Installation Guide](docs/ManualInstallation.md)

**Existing Void Installation?**
```bash
# Transform your current Void setup
curl -L https://raw.githubusercontent.com/dolandstutts/voidance/main/install.sh | sh
```

---

## 🛠️ Development & Building

### Build Your Own ISO

```bash
# Clone the project
git clone https://github.com/YOURUSERNAME/voidance.git
cd voidance

# Build ISO (on Linux)
sudo ./scripts/build-iso.sh

# Build ISO (on macOS with Docker)
docker run -it --rm -v $(pwd):/workspace -w /workspace ghcr.io/void-linux/void-linux:latest bash
xbps-install -S void-mklive git
./scripts/build-iso.sh
```

### Test in Virtual Machine

```bash
qemu-system-x86_64 -boot d -cdrom voidance.iso -m 4096 -enable-kvm
```

### Development Commands

- **Update installed system**: `sudo ./scripts/update.sh`
- **Clean build cache**: `sudo rm -rf iso-builder/tmp`
- **Edit Hyprland config**: `nano config/hypr/hyprland.conf`
- **Update package list**: `nano packages/packages.txt`

---

## 📚 Documentation

- [Getting Started](docs/GettingStarted.md) — Detailed installation guide
- [Architectural Differences](docs/ArchitecturalDifferences.md) — Why Voidance differs from Omarchy
- [Keyboard Shortcuts](docs/KeyboardShortcuts.md) — Hyprland keybindings
- [Troubleshooting](docs/Troubleshooting.md) — Common issues & fixes
- [Contributing](docs/Contributing.md) — How to contribute

---

## 🚀 Releasing

```bash
git tag -a v0.1-beta -m "First beta"
git push origin v0.1-beta
```

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 🤝 Governance & Contributing

- **Philosophy**: Read [GOVERNANCE.md](GOVERNANCE.md) to understand our beginner-first approach
- **Contributing**: See [docs/Contributing.md](docs/Contributing.md) for how to help
- **Contributors**: Check [CONTRIBUTORS.md](CONTRIBUTORS.md) for our awesome community

Voidance is built **by beginners, for beginners**. If you're learning Linux, you're our target user!

---

## 🙏 Credits

Built with love for the Void Linux community, inspired by Omarchy's vision of a polished developer-first experience.

**Inspiration & Thanks:**
- [Omarchy](https://github.com/basecamp/omarchy) - The vision
- [Void Linux](https://voidlinux.org) - The foundation
- [Hyprland](https://hyprland.org) - The beauty
- [Catppuccin](https://github.com/catppuccin/catppuccin) - The colors
