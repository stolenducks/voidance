# Troubleshooting

## Build Issues

### "void-mklive not found"

**Solution**: Install build tools
```bash
sudo xbps-install -S void-mklive git
```

### "Permission denied" when building

**Solution**: Run build script with sudo
```bash
sudo ./scripts/build-iso.sh
```

### Docker container build fails

**Solution**: Ensure Docker has enough resources (4GB+ RAM) and proper volume mounting
```bash
docker run -it --rm -v $(pwd):/workspace -w /workspace ghcr.io/void-linux/void-linux:latest bash
```

---

## Installation Issues

### USB boot not detected

1. Check BIOS boot order
2. Disable Secure Boot
3. Try different USB port (USB 2.0 recommended)
4. Re-flash USB with:
   ```bash
   sudo dd if=voidance.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

### Black screen after boot

**Possible causes**:
- Graphics driver issue
- Missing Wayland support

**Solution**: Boot with fallback parameters
1. At GRUB menu, press `e`
2. Add `nomodeset` to kernel parameters
3. Press `Ctrl+X` to boot

---

## Hyprland Issues

### Hyprland won't start

**Check logs**:
```bash
cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -n 1)/hyprland.log
```

**Common fixes**:
- Ensure GPU supports Wayland
- Update graphics drivers: `sudo xbps-install -Su mesa-dri`

### Screen tearing

Add to `hyprland.conf`:
```conf
misc {
    vrr = 1
}
```

### High CPU usage

Disable animations temporarily:
```conf
animations {
    enabled = false
}
```

---

## Audio Issues

### No sound

```bash
# Check PipeWire status
sv status pipewire

# Restart audio services
sudo sv restart pipewire
sudo sv restart wireplumber
```

### Mic not working

```bash
# List audio devices
pactl list sources

# Set default mic
pactl set-default-source <source-name>
```

---

## Package Management

### Update issues

```bash
# Sync repositories
sudo xbps-install -S

# Force update
sudo xbps-install -Syu
```

### Clean package cache

```bash
sudo rm -rf /var/cache/xbps/*
```

### Broken dependencies

```bash
# Reconfigure all packages
sudo xbps-reconfigure -fa
```

---

## Network Issues

### WiFi not connecting

```bash
# Check NetworkManager status
sudo sv status NetworkManager

# Restart NetworkManager
sudo sv restart NetworkManager

# Connect via CLI
nmcli device wifi connect <SSID> password <password>
```

---

## Clean Build Cache

If you encounter weird build issues:

```bash
sudo rm -rf iso-builder/tmp
```

---

## Getting Help

1. Check [Hyprland Wiki](https://wiki.hyprland.org)
2. Visit [Void Linux docs](https://docs.voidlinux.org)
3. Open an issue on GitHub
4. Join Void Linux IRC/Discord

