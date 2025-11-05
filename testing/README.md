# Voidance Testing & Development

This directory contains tools for **testing and development** of Voidance. These scripts are **not needed for production use** on real hardware.

## 🎯 Purpose

These tools help developers:
- Build ISOs in Docker (for macOS/non-Void development)
- Test ISOs in QEMU virtual machines
- Debug installations before deploying to real hardware

## 📁 Contents

### Docker Build Tools
- `docker-compose.yml` - Docker Compose configuration
- `Dockerfile` - Void Linux build container
- `Dockerfile.mklive` - Specialized void-mklive container
- `build-docker.sh` - Wrapper script for Docker builds

### VM Testing Scripts
- `run-vm.sh` - Boot Voidance ISO in QEMU (live environment)
- `boot-installed.sh` - Boot from installed system on virtual disk
- `test-in-vm.sh` - Run component tests inside VM
- `test-iso.sh` - Launch QEMU with built ISO
- `quick-test.sh` - Download official Void ISO for quick testing

## 🚀 Quick Start

### Test on macOS with Docker

```bash
# Build ISO in Docker
cd testing
./build-docker.sh

# Test in QEMU
./test-iso.sh
```

### Test on Linux

```bash
# Build ISO natively
cd ..
sudo ./scripts/build-iso.sh

# Test in QEMU
cd testing
./test-iso.sh
```

### Run Live Environment

```bash
# Boot ISO in VM with 4GB RAM
./run-vm.sh ../void-base-live.iso

# Or use the built Voidance ISO
./run-vm.sh ../voidance.iso
```

### Test Installed System

```bash
# First install to virtual disk (via installer)
./run-vm.sh ../voidance.iso

# Then boot from installed system
./boot-installed.sh
```

## 🔧 Requirements

### For Docker Testing (macOS/Windows)
- Docker Desktop
- 8GB+ RAM available
- 20GB+ free disk space

### For Native Testing (Linux)
- QEMU installed
- Void Linux host (for building)
- Or any Linux distro (for testing only)

### Installing QEMU

**macOS:**
```bash
brew install qemu
```

**Void Linux:**
```bash
sudo xbps-install -S qemu
```

**Debian/Ubuntu:**
```bash
sudo apt install qemu-system-x86
```

## 📝 Important Notes

### Not for Production
These tools are **development aids only**. End users installing on real hardware should:
- Use the automated installer from the main README
- Download pre-built ISOs from releases
- Follow production installation guides in `/docs`

### VM vs Real Hardware
Virtual machines have limitations:
- Graphics acceleration may not work properly
- Some Wayland features disabled in VMs
- Performance is significantly slower
- Hardware detection differs

**Always test on real hardware before releases!**

### Disk Images
Test disk images (`.qcow2`) are stored in project root but gitignored:
- `void-disk.qcow2` - Virtual hard drive for testing
- `voidance-test.qcow2` - Backup test disk

These are automatically created by VM scripts and **should not be committed**.

## 🐛 Troubleshooting

### "QEMU not found"
Install QEMU for your platform (see Requirements above)

### "Cannot access display"
Run from a terminal with X11/Wayland access, not SSH

### "Permission denied"
Make scripts executable:
```bash
chmod +x *.sh
```

### "ISO not found"
Build the ISO first:
```bash
cd ..
sudo ./scripts/build-iso.sh
```

### Docker build fails
Ensure Docker has adequate resources in preferences:
- Memory: 4GB minimum, 8GB recommended
- Disk: 20GB+ available

## 🔗 Related Documentation

- [Main README](../README.md) - Production installation
- [Build Guide](../docs/GettingStarted.md) - Detailed build instructions
- [Docker Guide](../DOCKER.md) - Docker-specific information
- [Testing Guide](../TESTING.md) - Comprehensive testing procedures

## ⚠️ Known Issues

### macOS-Specific
- QEMU display uses Cocoa backend (macOS-specific flags)
- KVM acceleration unavailable (uses Hypervisor.framework instead)
- UEFI firmware path is macOS Homebrew-specific

### Linux-Specific
- Some scripts assume X11/Wayland display
- May need to adjust display backend flags

These issues don't affect production use on real hardware!
