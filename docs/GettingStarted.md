# Getting Started

## Prerequisites

- **For building**: Docker (on macOS/Linux) or Void Linux system
- **For testing**: QEMU/KVM or VirtualBox
- **For installation**: USB drive (8GB+) or target machine

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/YOURUSERNAME/voidance.git
cd voidance
```

---

## Step 2: Build the ISO

### On macOS (Docker method)

```bash
# Start Void Linux container
docker run -it --rm -v $(pwd):/workspace -w /workspace ghcr.io/void-linux/void-linux:latest bash

# Inside container - install build tools
xbps-install -S void-mklive git

# Build the ISO
./scripts/build-iso.sh
```

### On Void Linux (native)

```bash
# Install build tools
sudo xbps-install -S void-mklive git

# Build the ISO
sudo ./scripts/build-iso.sh
```

---

## Step 3: Test the ISO

### Using QEMU

```bash
qemu-system-x86_64 -boot d -cdrom voidance.iso -m 4096 -enable-kvm
```

### Using VirtualBox

1. Create new VM (Linux, Other 64-bit)
2. Allocate 4GB+ RAM
3. Mount `voidance.iso` as optical drive
4. Boot and test

---

## Step 4: Install to USB or Hard Drive

### Flash to USB (Live USB)

```bash
# Find your USB device (e.g., /dev/sdb)
lsblk

# Flash the ISO
sudo dd if=voidance.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

⚠️ **Warning**: Replace `/dev/sdX` with your actual USB device. This will erase all data!

### Install to Hard Drive

Boot from the ISO and follow the Void Linux installation prompts. The installer will guide you through:

1. Disk partitioning
2. LUKS encryption (optional)
3. User creation
4. Bootloader installation

---

## Step 5: First Boot

After installation:

1. Remove installation media
2. Reboot
3. Log in with your credentials
4. Hyprland should start automatically
5. Press `Super + Return` for terminal
6. Press `Alt + D` for app launcher

---

## Next Steps

- Read [Keyboard Shortcuts](KeyboardShortcuts.md)
- Customize your setup in `~/.config/hypr/hyprland.conf`
- Install additional packages with `xbps-install`

