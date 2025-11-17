# Voidance Linux

A minimalist Linux distribution built on Void Linux with Wayland-first approach, focusing on simplicity, performance, and modern desktop experience.

## Overview

Voidance Linux is a curated Linux distribution that provides a clean, minimal foundation for desktop computing. Built on the robust Void Linux base, it emphasizes:

- **Minimalism**: Only essential components included by default
- **Wayland-First**: Native Wayland support with XWayland compatibility
- **Modern Stack**: Latest desktop technologies and protocols
- **Performance**: Optimized for speed and resource efficiency
- **Simplicity**: Easy to understand and configure

## Features

### System Services

Voidance Linux includes a comprehensive set of system services for desktop functionality:

#### Session Management
- **elogind**: User session management and power control
- **dbus**: System message bus for inter-process communication
- **PAM**: Pluggable authentication modules for session security

#### Display Management
- **SDDM**: Modern display manager with Wayland-first approach
- **niri**: Wayland compositor (default)
- **Theme Support**: Multiple SDDM themes included

#### Network Services
- **NetworkManager**: Network connection management
- **WiFi Support**: Full wireless network support
- **Mobile Broadband**: Cellular network support
- **VPN Integration**: NetworkManager VPN plugin support

#### Audio Services
- **PipeWire**: Modern audio server
- **WirePlumber**: Session manager for PipeWire
- **PulseAudio Compatibility**: Full PulseAudio API compatibility
- **Bluetooth Audio**: Support for Bluetooth audio devices

#### Idle Management
- **swayidle**: Idle detection and management
- **swaylock**: Screen locking with customization
- **Battery Awareness**: Different timeouts on battery power
- **Power Management**: Automatic suspend and screen power management

### Desktop Environment

#### Wayland Support
- Native Wayland compositor (niri)
- XWayland compatibility for legacy applications
- Hardware acceleration via EGL
- Multi-monitor support

#### Application Support
- GTK and Qt application support
- Gaming with Steam and Lutris
- Development tools and IDEs
- Media playback and creation

## Installation

### System Requirements

**Minimum:**
- x86_64 processor
- 2GB RAM
- 10GB storage
- VESA-compatible graphics

**Recommended:**
- Modern x86_64 processor (2010+)
- 4GB+ RAM
- 20GB+ storage (SSD recommended)
- Modern GPU with proper drivers

### Quick Start

1. **Download Voidance Linux ISO**
   ```bash
   # Get the latest ISO from releases
   wget https://github.com/voidance/voidance/releases/latest/voidance-linux.iso
   ```

2. **Create Bootable Media**
   ```bash
   # For USB drives
   dd if=voidance-linux.iso of=/dev/sdX bs=4M status=progress
   ```

3. **Boot and Install**
   - Boot from the USB drive
   - Follow the installation wizard
   - Configure user accounts and settings

### Post-Installation Setup

After installation, run the system services setup:

```bash
# Install system services
sudo ./packages/system-services.sh install

# Configure services
sudo ./scripts/setup-pam.sh
sudo ./scripts/setup-network-permissions.sh
sudo ./scripts/setup-audio-permissions.sh
sudo ./scripts/setup-idle-management.sh

# Start all services
sudo ./scripts/start-system-services.sh start
```

## Configuration

### Service Management

Voidance Linux uses runit as the init system. Services can be managed with the provided scripts:

```bash
# Start all system services
sudo ./scripts/start-system-services.sh start

# Check service status
./scripts/system-status-monitor.sh status

# Enable/disable individual services
sudo ./scripts/start-system-services.sh enable sddm
sudo ./scripts/start-system-services.sh disable sddm
```

### Configuration Files

Service configurations are stored in `/etc/voidance/`:

```bash
# Main configuration directory
/etc/voidance/
├── session.json          # Session management settings
├── display.json          # Display manager settings
├── network.json          # Network service settings
├── audio.json           # Audio service settings
├── idle.json            # Idle management settings
└── system-services.json  # Global system settings
```

### Validation

Configuration files can be validated with the provided scripts:

```bash
# Validate all configurations
./scripts/validate-config.sh validate

# Generate default configurations
./scripts/validate-config.sh generate

# Check JSON syntax
./scripts/validate-config.sh check-json /etc/voidance/
```

## Hardware Compatibility

Voidance Linux supports a wide range of hardware:

### Supported Components

- **Graphics**: NVIDIA, AMD, Intel GPUs (with proper drivers)
- **Audio**: Intel HDA, AMD/ATI, NVIDIA HDMI, USB audio
- **Network**: Intel, Realtek, Atheros, Broadcom Ethernet/WiFi
- **Input**: USB, PS/2, Bluetooth keyboards and mice
- **Storage**: SATA, NVMe, USB storage devices

### Hardware Testing

Test your hardware compatibility:

```bash
# Run full hardware compatibility test
./scripts/test-hardware-compatibility.sh test

# Generate hardware report
./scripts/test-hardware-compatibility.sh report
```

For detailed compatibility information, see [docs/hardware-compatibility.md](docs/hardware-compatibility.md).

## Development

### Project Structure

```
voidance/
├── packages/              # Package installation scripts
├── services/              # Service configurations
│   └── runit/sv/        # runit service scripts
├── config/                # Configuration files
├── scripts/               # Management and testing scripts
├── docs/                  # Documentation
└── config/schemas/        # Configuration schemas
```

### Building from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/voidance/voidance.git
   cd voidance
   ```

2. **Install dependencies**
   ```bash
   # On Void Linux
   xbps-install -S base-devel
   ```

3. **Build packages**
   ```bash
   # Build system services
   ./packages/system-services.sh install
   ```

4. **Configure and test**
   ```bash
   # Run all setup scripts
   sudo ./scripts/setup-*.sh
   
   # Test services
   ./scripts/test-*.sh
   ```

### Contributing

Contributions are welcome! Please follow these guidelines:

1. **Code Style**: Follow existing code conventions
2. **Testing**: Include tests for new features
3. **Documentation**: Update documentation for changes
4. **Commits**: Use conventional commit messages

## Troubleshooting

### Common Issues

**Services not starting:**
```bash
# Check service status
./scripts/system-status-monitor.sh status

# Check dependencies
./scripts/test-service-dependencies.sh
```

**Hardware not detected:**
```bash
# Run hardware test
./scripts/test-hardware-compatibility.sh test

# Check system logs
journalctl -xe
```

**Configuration errors:**
```bash
# Validate configurations
./scripts/validate-config.sh validate

# Check syntax
./scripts/validate-config.sh check-json /etc/voidance/
```

### Getting Help

- **Documentation**: Check the `docs/` directory
- **Issues**: Report bugs on GitHub Issues
- **Community**: Join our community forums
- **Logs**: Use `journalctl` for system logs

## Scripts Reference

### Management Scripts

- `start-system-services.sh` - Master service control
- `system-status-monitor.sh` - System health monitoring
- `validate-config.sh` - Configuration validation

### Setup Scripts

- `setup-pam.sh` - PAM configuration
- `setup-sddm.sh` - Display manager setup
- `setup-network-permissions.sh` - Network configuration
- `setup-audio-permissions.sh` - Audio configuration
- `setup-idle-management.sh` - Idle management setup

### Testing Scripts

- `test-xdg-runtime.sh` - XDG runtime testing
- `test-graphical-login.sh` - Display manager testing
- `test-network-connectivity.sh` - Network testing
- `test-audio-functionality.sh` - Audio testing
- `test-idle-lock-functionality.sh` - Idle management testing
- `test-service-dependencies.sh` - Service dependency testing
- `test-hardware-compatibility.sh` - Hardware compatibility testing

## License

Voidance Linux is released under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- **Void Linux**: Base distribution and package management
- **runit**: Init system and service supervision
- **SDDM**: Display manager
- **PipeWire**: Audio server
- **NetworkManager**: Network management
- **niri**: Wayland compositor
- **swayidle/swaylock**: Idle management and screen locking

## Contact

- **Website**: https://voidance.io
- **GitHub**: https://github.com/voidance/voidance
- **Community**: https://community.voidance.io
- **Documentation**: https://docs.voidance.io

---

**Voidance Linux** - Minimal, Modern, Linux Desktop