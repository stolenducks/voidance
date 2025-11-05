# Docker Development Guide

⚠️ **Note**: Docker files have moved to `testing/` directory. This guide is for building Voidance on non-Void systems (macOS, Windows).

📖 **See [testing/README.md](testing/README.md) for complete testing documentation.**

---

Quick guide for building and testing Voidance on macOS using Docker.

## Prerequisites

```bash
# Install Docker Desktop for Mac
brew install --cask docker

# Install QEMU for testing
brew install qemu
```

## Build the ISO

```bash
# Navigate to testing directory
cd testing

# One-command build
./docker-build.sh
```

This will:
1. Build the Docker image with Void Linux
2. Install `void-mklive` 
3. Build the ISO with your package list
4. Output `voidance.iso` in project root

**First build takes 10-30 minutes** depending on packages.

## Test the ISO

```bash
# Test in QEMU virtual machine (from testing directory)
./test-iso.sh

# Or from project root
./testing/test-iso.sh
```

This launches QEMU with:
- 4GB RAM
- 2 CPU cores
- Hardware acceleration (HVF on macOS)
- Proper graphics drivers

## Manual Docker Commands

If you want more control:

```bash
# Navigate to testing directory
cd testing

# Build image
docker compose build

# Start interactive container
docker compose run --rm voidance-builder

# Inside container:
xbps-install -Syu void-mklive
cd /workspace/scripts
bash build-iso.sh
```

## Troubleshooting

### Build fails with "package not found"

Check if package exists in Void repos:
```bash
docker compose run --rm voidance-builder xbps-query -Rs <package-name>
```

### ISO boots but Hyprland doesn't start

Check package list has all required packages:
- `hyprland`
- `xdg-desktop-portal-hyprland`
- GPU drivers (mesa, vulkan, etc.)

### QEMU is slow

Make sure HVF acceleration is enabled:
```bash
qemu-system-x86_64 -accel hvf
```

## Cleanup

```bash
# Remove built ISO
rm voidance.iso

# Clean Docker cache
docker compose down -v

# Remove Docker image
docker rmi voidance-builder:latest
```

## Next Steps

Once ISO works in QEMU:
1. Flash to USB: `sudo dd if=voidance.iso of=/dev/diskX bs=4m`
2. Boot on real hardware (ThinkPad X1 Carbon)
3. Follow installer

See [README.md](README.md) for more details.
