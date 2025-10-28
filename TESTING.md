# Testing Voidance

## Prerequisites

- QEMU installed: `brew install qemu`
- Official Void Linux ISO downloaded

## Download Void Linux ISO

```bash
cd ~/voidance
curl -L -o void-base-live.iso \
  "https://repo-fastly.voidlinux.org/live/current/void-live-x86_64-20250202-base.iso"
```

## Test in QEMU

### Basic Test (2GB RAM)
```bash
qemu-system-x86_64 \
  -boot d \
  -cdrom void-base-live.iso \
  -m 2048 \
  -display cocoa
```

### Full Test (4GB RAM, 2 CPUs)
```bash
qemu-system-x86_64 \
  -boot d \
  -cdrom void-base-live.iso \
  -m 4096 \
  -smp 2 \
  -display cocoa
```

### Test with Disk (Persistent Installation)
```bash
# Create virtual disk
qemu-img create -f qcow2 voidance-test.qcow2 20G

# Boot with disk
qemu-system-x86_64 \
  -boot d \
  -cdrom void-base-live.iso \
  -hda voidance-test.qcow2 \
  -m 4096 \
  -smp 2 \
  -display cocoa
```

## Installation Steps in QEMU

1. **Boot the ISO**
   - QEMU window opens
   - Void Linux boots to login prompt
   - Login: `root` / `voidlinux`

2. **Install Void**
   ```bash
   void-installer
   ```
   - Follow the installer prompts
   - Choose keyboard, timezone, etc.
   - Create your user account
   - Install to disk

3. **Reboot**
   - Close QEMU
   - Remove `-boot d -cdrom` flags
   - Boot from disk:
   ```bash
   qemu-system-x86_64 \
     -hda voidance-test.qcow2 \
     -m 4096 \
     -smp 2 \
     -display cocoa
   ```

4. **Transform to Voidance**
   ```bash
   # Login as your user
   curl -L https://raw.githubusercontent.com/dolandstutts/voidance/main/install.sh | sh
   ```

5. **Test Hyprland**
   - Reboot
   - Login
   - Hyprland should auto-start
   - Test keyboard shortcuts:
     - `Super + Return` → Terminal
     - `Super + D` → Launcher
     - `Super + Q` → Close window

## Testing on Real Hardware (ThinkPad)

### Create Bootable USB

**macOS:**
```bash
# Find USB device
diskutil list

# Unmount it
diskutil unmountDisk /dev/diskX

# Flash ISO
sudo dd if=void-base-live.iso of=/dev/rdiskX bs=1m status=progress

# Eject
diskutil eject /dev/diskX
```

**Or use Balena Etcher (GUI):**
- Download: https://www.balena.io/etcher/
- Select ISO
- Select USB drive
- Flash!

### Boot on ThinkPad

1. Insert USB drive
2. Power on and press **F12** (boot menu)
3. Select USB drive
4. Follow installation steps above
5. Install to internal SSD
6. Remove USB and reboot
7. Run transform script

## Tips

- **QEMU keyboard shortcuts:**
  - `Ctrl + Alt + G` → Release mouse
  - `Cmd + Q` → Quit QEMU

- **Void installer keyboard:**
  - `Tab` → Navigate fields
  - `Space` → Select options
  - `Enter` → Confirm

- **If network doesn't work in QEMU:**
  Add `-netdev user,id=net0 -device e1000,netdev=net0`

## Troubleshooting

### Hyprland doesn't start
- Check logs: `~/.local/share/hyprland/hyprland.log`
- Ensure GPU drivers installed (mesa, vulkan)

### Transform script fails
- Check: `/tmp/voidance-install.log`
- Failed packages: `~/.voidance-failed-packages`

### No internet in live ISO
```bash
# Check interfaces
ip link

# Start DHCP
sudo dhcpcd
```

## Next Steps

Once Voidance works in QEMU:
1. Test all keyboard shortcuts
2. Verify all apps launch
3. Check themes look correct
4. Test on real hardware
5. Document any issues
