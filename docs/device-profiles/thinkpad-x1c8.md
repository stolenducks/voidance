# ThinkPad X1 Carbon 8th Gen - Device Profile

## Overview

The Lenovo ThinkPad X1 Carbon 8th Generation (2020) works excellently with Void Linux out of the box. This document provides optional optimizations and notes specific to this hardware.

## Hardware Specifications

- **CPU**: Intel Core i5/i7 10th Gen (Comet Lake)
- **GPU**: Intel UHD Graphics
- **RAM**: 8GB-32GB LPDDR3
- **Storage**: NVMe SSD
- **Display**: 14" FHD/UHD
- **WiFi**: Intel Wi-Fi 6 AX201
- **Audio**: Intel HDA (sof-firmware)
- **Touchpad**: Synaptics

## What Works Out of the Box

✅ **Everything** works with stock Void Linux kernel and firmware:

- WiFi (Intel AX201)
- Bluetooth
- Audio (speakers, microphone, headphone jack)
- Touchpad (including multi-touch gestures)
- TrackPoint
- Brightness control
- Function keys
- Suspend/resume
- USB-C ports and charging
- Thunderbolt 3 (with `thunderbolt` package)
- Webcam (with privacy shutter)

## Recommended Packages

These are already included in the XFCE-AI Edition ISO:

```bash
# Already installed:
intel-ucode      # CPU microcode updates
tlp              # Power management
fwupd            # Firmware updates
NetworkManager   # Network management
```

## Optional Optimizations

### 1. Battery Life Improvements

TLP is pre-installed. To enable it:

```bash
# Enable TLP service
sudo ln -sf /etc/sv/tlp /var/service/

# Check status
sudo sv status tlp

# View battery info
sudo tlp-stat -b
```

**TLP Configuration** (`/etc/tlp.conf`):

```bash
# Recommended settings for X1 Carbon
START_CHARGE_THRESH_BAT0=75  # Start charging at 75%
STOP_CHARGE_THRESH_BAT0=80   # Stop charging at 80% (extends battery life)

# CPU settings
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# Intel GPU power management
INTEL_GPU_MIN_FREQ_ON_AC=300
INTEL_GPU_MIN_FREQ_ON_BAT=300
INTEL_GPU_BOOST_FREQ_ON_AC=1150
INTEL_GPU_BOOST_FREQ_ON_BAT=800
```

### 2. Firmware Updates

Keep your firmware up to date with fwupd:

```bash
# Refresh firmware database
sudo fwupdmgr refresh

# Check for updates
sudo fwupdmgr get-updates

# Apply updates
sudo fwupdmgr update
```

### 3. Thunderbolt Support

If you use Thunderbolt devices:

```bash
# Install thunderbolt package
sudo xbps-install -S thunderbolt

# Enable service
sudo ln -sf /etc/sv/thunderbolt /var/service/

# Check connected devices
boltctl list
```

### 4. Touchpad Tuning (Optional)

If you want to customize touchpad behavior, create `/etc/X11/xorg.conf.d/30-touchpad.conf`:

```conf
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "DisableWhileTyping" "true"
    Option "AccelSpeed" "0.3"
EndSection
```

### 5. Intel Graphics Optimization

For better performance, create `/etc/modprobe.d/i915.conf`:

```bash
# Enable GuC/HuC firmware loading
options i915 enable_guc=3
```

Then regenerate initramfs:

```bash
sudo xbps-reconfigure -f linux
```

## Known Issues

### None!

The X1 Carbon 8th Gen has excellent Linux support. No workarounds or kernel parameters needed.

## Power Management Tips

- **Suspend works perfectly**: Close the lid and it just works
- **Hibernate**: Requires swap partition/file setup
- **Expected battery life**: 6-10 hours depending on usage
- **TLP**: Automatically manages power profiles (AC vs battery)

## BIOS Settings

Recommended BIOS settings (optional, defaults work fine):

- **Secure Boot**: Can be enabled (Void supports it)
- **Thunderbolt Security**: User authorization recommended
- **SATA Mode**: AHCI (default)
- **Intel AMT**: Disable unless needed
- **Virtualization**: Enable if using VMs/containers

## Troubleshooting

### WiFi Not Working

```bash
# Check if driver is loaded
lsmod | grep iwlwifi

# Restart NetworkManager
sudo sv restart NetworkManager

# Check for firmware issues
dmesg | grep iwlwifi
```

### Audio Issues

```bash
# Install sound firmware (should already be installed)
sudo xbps-install -S sof-firmware alsa-firmware

# Restart pipewire
sudo sv restart pipewire
```

### Touchpad Not Working

```bash
# Check if libinput is installed
xbps-query -l | grep libinput

# Test touchpad detection
libinput list-devices
```

## Performance

With Void Linux and XFCE, expect:

- **Boot time**: 5-10 seconds to desktop
- **Memory usage**: ~400-600MB idle (XFCE + minimal services)
- **CPU usage**: <5% idle
- **Fan noise**: Minimal (often silent)
- **Battery drain**: ~5-10% per hour with light use

## Resources

- [ThinkWiki X1 Carbon 8th Gen](https://www.thinkwiki.org/wiki/Category:X1_Carbon_8th_Gen)
- [Arch Wiki: Lenovo ThinkPad X1 Carbon (Gen 8)](https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Carbon_(Gen_8))
- [Void Linux Handbook](https://docs.voidlinux.org/)

## Notes

- This device profile is included for reference only
- The base ISO works perfectly without any modifications
- These optimizations are **optional** and focused on power efficiency
- All settings can be reverted easily

---

**Last Updated**: 2025-01-05  
**Tested With**: Void Linux glibc, kernel 6.6+  
**Hardware**: ThinkPad X1 Carbon Gen 8 (20U9, 20UA)
