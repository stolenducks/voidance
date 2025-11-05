# Void Linux XFCE - AI Edition

🚀 **Stock Void Linux XFCE** with a built-in, removable **AI helper** for troubleshooting.

Get a clean XFCE experience with an offline AI assistant that helps you learn Linux:
- 🖥️ **Stock XFCE desktop** - exactly like the official Void ISO
- 🤖 **droid AI helper** - offline assistant with Void Linux knowledge
- 📚 **Embedded docs** - Void Linux documentation built-in
- 🔌 **Works offline** - no internet required after installation  
- 🧹 **Easy removal** - `droid uninstall` to go lightweight (~2-3GB freed)
- 💻 **Device-agnostic** - works on modern laptops and desktops

---

## 🎯 Project Goals

1. **Provide stock Void Linux XFCE** with zero modifications
2. **Include a helpful AI assistant** for beginners learning Linux
3. **Work completely offline** after first boot
4. **Easy to remove** when you don't need help anymore
5. **Stay minimal** - the AI is optional, not required

---

## 🤖 The droid AI Helper

**droid** is a command-line AI assistant that helps you troubleshoot Void Linux:

```bash
# Ask anything about Void Linux
$ droid "how do I install firefox"
To install Firefox on Void Linux:
  sudo xbps-install -S firefox

This will:
- Update package cache
- Install Firefox and dependencies

# Get help with commands
$ droid "what is the command to restart NetworkManager"
sudo sv restart NetworkManager

# Check AI status
$ droid status
=== Droid AI Helper Status ===
✓ ollama: installed
✓ ollama service: running
✓ model: void-qwen (ready)
✓ void docs: 15M

# Remove AI when you're comfortable
$ droid uninstall
Disk space to be reclaimed: ~2.3GB
Continue? (y/N): y
```

**Features:**
- Uses Qwen 2.5 Coder 3B (lightweight, fast)
- Knows xbps package management
- Knows runit service management
- Augments responses with Void Linux documentation
- Works offline - no data sent to internet
- Easy to remove completely

---

## 📦 What's Included

| Component | Purpose | Removable? |
|-----------|---------|------------|
| **XFCE4** | Desktop environment | No (core) |
| **NetworkManager** | Network management | No (core) |
| **lightdm** | Display manager | No (core) |
| **droid CLI** | AI helper | Yes |
| **Qwen 2.5 Coder 3B** | AI model (~2GB) | Yes |
| **Void docs** | Offline documentation | Yes |
| **ripgrep, jq** | AI helper utilities | Yes |
| **tlp** | Power management (optional) | Yes |
| **fwupd** | Firmware updates (optional) | Yes |

**Total ISO size:** ~3.5-4GB (including AI model)  
**After `droid uninstall`:** Near-stock Void Linux (~600MB RAM usage)

---

## 🚀 Installation

### Quick Start (Recommended)

1. **Download the ISO** (not yet released - build from source below)
   
2. **Flash to USB**
   ```bash
   # macOS
   sudo dd if=void-xfce-ai-YYYYMMDD.iso of=/dev/diskX bs=4m
   
   # Linux
   sudo dd if=void-xfce-ai-YYYYMMDD.iso of=/dev/sdX bs=4M status=progress
   ```

3. **Boot from USB**
   - Login: `root` / `voidlinux`
   - Follow installer prompts

4. **First boot**
   - The droid AI helper initializes automatically
   - Try: `droid "your question"`

---

## 🛠️ Building from Source

### On macOS (via Docker)

```bash
# Clone the repository
git clone https://github.com/stolenducks/voidance.git
cd voidance
git checkout xfce-ai-stock

# Build using Docker
cd testing
./build-in-docker.sh

# Output: dist/void-xfce-ai-YYYYMMDD.iso
```

### On Void Linux (native build)

```bash
# Install dependencies
sudo xbps-install -S void-mklive git wget curl

# Clone repository
git clone https://github.com/stolenducks/voidance.git
cd voidance
git checkout xfce-ai-stock

# Build ISO
sudo ./scripts/build-iso.sh

# Output: dist/void-xfce-ai-YYYYMMDD.iso
```

**Build time:** 15-30 minutes depending on your system and connection speed.

---

## 💡 Usage Examples

### After Installation

```bash
# Get help with package management
$ droid "how do I search for a package"
Use xbps-query to search:
  xbps-query -Rs <keyword>

Example:
  xbps-query -Rs firefox

# Troubleshoot networking
$ droid "my wifi won't connect"
Try these steps:
1. Check NetworkManager status:
   sudo sv status NetworkManager
2. Restart NetworkManager:
   sudo sv restart NetworkManager
3. Connect via CLI:
   nmcli device wifi connect <SSID> password <password>

# Learn about services
$ droid "how do I enable a service in Void Linux"
In Void Linux, services are managed with runit (not systemd).

To enable a service:
  sudo ln -sf /etc/sv/<service> /var/service/

Example:
  sudo ln -sf /etc/sv/tlp /var/service/

Check status:
  sudo sv status <service>
```

### Remove AI When Ready

```bash
$ droid uninstall
This will remove the droid AI helper and reclaim disk space

Disk space to be reclaimed: 2.3GB

Continue? (y/N): y
[droid] Stopping ollama service...
[droid] Removing AI assets...
[droid] Removing ollama data...

Remove ollama package? (y/N): y
[droid] Removing ollama package...
[droid] Uninstall complete! System is now near-stock.
```

---

## 📚 Documentation

- [AI Helper Guide](docs/AIHelper.md) - Complete droid documentation
- [Getting Started](docs/GettingStarted.md) - Void Linux basics
- [Troubleshooting](docs/Troubleshooting.md) - Common issues
- [Contributing](docs/Contributing.md) - How to help
- [Device Profiles](docs/device-profiles/) - Hardware-specific notes (optional)

---

## 🧪 Testing

### Test in VM (QEMU)

```bash
cd testing
./test-iso.sh
```

Or manually:

```bash
qemu-system-x86_64 \
  -boot d \
  -cdrom dist/void-xfce-ai-*.iso \
  -m 4096 \
  -enable-kvm
```

### Compare with Official ISO

Our ISO should be nearly identical to the official Void XFCE ISO, with only these additions:
- ollama
- ripgrep
- jq  
- droid CLI and assets

---

## 🤝 Contributing

We welcome contributions! This project aims to:
- Stay as close to stock Void Linux as possible
- Provide a helpful AI assistant for beginners
- Remain fully transparent and open source

See [CONTRIBUTING.md](docs/Contributing.md) for guidelines.

---

## 🔒 Privacy & Security

**Offline by default:**
- The AI model runs locally (no internet connection needed)
- No data is sent to external servers
- All processing happens on your machine

**The AI helper:**
- Uses Qwen 2.5 Coder 3B (open source model)
- Runs via Ollama (open source inference engine)
- Reads local Void Linux documentation for context
- Can be completely removed with `droid uninstall`

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Credits

**Built on the shoulders of giants:**
- [Void Linux](https://voidlinux.org) - The foundation
- [Qwen 2.5 Coder](https://github.com/QwenLM/Qwen2.5-Coder) - The AI model
- [Ollama](https://ollama.ai) - The inference engine
- [XFCE](https://xfce.org) - The desktop environment

**Inspired by:**
- The original [Voidance](https://github.com/stolenducks/voidance) project (Hyprland-focused)
- The idea that Linux beginners deserve helpful, offline tools

---

## ⚠️ Important Notes

- **This is NOT official Void Linux** - it's a community project
- **The AI can make mistakes** - always verify important commands
- **Internet required for initial build** - to download AI model and docs
- **Works offline after installation** - no internet needed for the AI

---

## 🎓 Learning Resources

Using the droid AI helper is great, but here are official resources too:

- [Void Linux Handbook](https://docs.voidlinux.org/)
- [Void Linux Wiki](https://wiki.voidlinux.org/)
- [Void Linux Reddit](https://reddit.com/r/voidlinux)
- [Void Linux IRC](https://web.libera.chat/#voidlinux)

**Philosophy:** Use droid to learn, but understand what the commands do. The goal is to help you become comfortable with Void Linux, not to make you dependent on AI.

---

## 🗺️ Roadmap

- [x] Stock XFCE ISO builder
- [x] Offline AI helper (droid)
- [x] macOS build support (Docker)
- [x] Device profiles (ThinkPad X1 Carbon)
- [ ] First stable release
- [ ] Pre-built ISO downloads
- [ ] Community testing and feedback
- [ ] Additional device profiles

---

**Status:** Active development (xfce-ai-stock branch)  
**Version:** Pre-release  
**Maintainer:** [@stolenducks](https://github.com/stolenducks)
