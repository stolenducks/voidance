# Voidance Linux Service Configuration Guide

This guide provides detailed information about configuring system services in Voidance Linux.

## Table of Contents

1. [Overview](#overview)
2. [Session Management](#session-management)
3. [Display Management](#display-management)
4. [Network Services](#network-services)
5. [Audio Services](#audio-services)
6. [Idle Management](#idle-management)
7. [Service Integration](#service-integration)
8. [Troubleshooting](#troubleshooting)

## Overview

Voidance Linux uses a modular service architecture with runit as the init system. Each service is independently configurable and can be enabled/disabled as needed.

### Service Architecture

```
runit (init system)
├── elogind (session management)
├── dbus (message bus)
├── sddm (display manager)
├── NetworkManager (network management)
├── pipewire (audio server)
├── pipewire-pulse (PulseAudio compatibility)
├── wireplumber (audio session manager)
└── swayidle (idle management)
```

### Configuration Locations

- **Service Scripts**: `/etc/sv/<service>/run`
- **Configuration Files**: `/etc/voidance/`
- **System Configs**: `/etc/<service>/`
- **Logs**: `/var/log/sv/<service>/`

## Session Management

### elogind Configuration

elogind provides user session management and power control.

#### Configuration File: `/etc/elogind/logind.conf`

```ini
[Login]
# Handle laptop lid switch
HandleLidSwitch=suspend
HandleLidSwitchDocked=ignore

# Handle power button
HandlePowerKey=poweroff
HandleSuspendKey=suspend
HandleHibernateKey=hibernate

# Kill user processes on logout
KillUserProcesses=false
KillExcludeUsers=root

# Idle action
IdleAction=ignore
IdleActionSec=0

# Remove IPC when user logs out
RemoveIPC=yes
```

#### JSON Configuration: `/etc/voidance/session.json`

```json
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "elogind",
  "settings": {
    "handle_lid_switch": "suspend",
    "handle_lid_switch_docked": "ignore",
    "handle_power_key": "poweroff",
    "handle_suspend_key": "suspend",
    "handle_hibernate_key": "hibernate",
    "kill_user_processes": false,
    "kill_exclude_users": ["root"],
    "idle_action": "ignore",
    "idle_action_sec": 0
  }
}
```

#### Common Settings

| Setting | Values | Description |
|----------|---------|-------------|
| `handle_lid_switch` | `suspend`, `hibernate`, `ignore`, `poweroff` | Action when laptop lid closes |
| `handle_power_key` | `poweroff`, `reboot`, `ignore`, `suspend`, `hibernate` | Action when power button pressed |
| `kill_user_processes` | `true`, `false` | Kill user processes on logout |
| `idle_action` | `ignore`, `suspend`, `hibernate`, `poweroff` | Action when system is idle |

#### Management Commands

```bash
# View active sessions
loginctl list-sessions

# View session details
loginctl session-status <session-id>

# View active seats
loginctl list-seats

# Lock session
loginctl lock-sessions

# Unlock session
loginctl unlock-sessions

# Suspend system
loginctl suspend

# Hibernate system
loginctl hibernate
```

### D-Bus Configuration

D-Bus provides inter-process communication.

#### Configuration File: `/etc/dbus-1/system.conf`

```xml
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <user>messagebus</user>
  <type>system</type>
  <listen>unix:path=/var/run/dbus/system_bus_socket</listen>
  <policy context="default">
    <allow user="*"/>
    <allow own="*"/>
    <allow send_type="method_call"/>
    <allow send_type="signal"/>
    <allow send_type="method_return"/>
    <allow send_type="error"/>
    <allow receive_type="method_call"/>
    <allow receive_type="signal"/>
    <allow receive_type="method_return"/>
    <allow receive_type="error"/>
  </policy>
</busconfig>
```

#### Management Commands

```bash
# Send message to service
dbus-send --system --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames

# Monitor D-Bus traffic
dbus-monitor --system

# Service status
systemctl status dbus
```

## Display Management

### SDDM Configuration

SDDM provides the graphical login interface.

#### Configuration File: `/etc/sddm.conf.d/voidance.conf`

```ini
[General]
# Display manager settings
HaltCommand=/usr/bin/poweroff
RebootCommand=/usr/bin/reboot
Numlock=on

# Theme configuration
Theme=breeze
Current=breeze

# Wayland first approach
DisplayServer=wayland

[Autologin]
# Autologin settings (disabled by default)
Relogin=false
Session=
User=

[X11]
# X11 server settings
DisplayCommand=/etc/sddm/Xsetup
DisplayStopCommand=/etc/sddm/Xstop
ServerPath=/usr/bin/X
ServerArguments=-nolisten tcp
XauthPath=/usr/bin/xauth

[Users]
# User settings
MaximumUid=60000
MinimumUid=1000
HideUsers=
HideShells=
```

#### JSON Configuration: `/etc/voidance/display.json`

```json
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "sddm",
  "settings": {
    "theme": "breeze",
    "wayland_first": true,
    "autologin": {
      "enabled": false,
      "user": "",
      "session": ""
    },
    "display": {
      "minimum_vt": 7,
      "server_command": null,
      "server_args": null,
      "xserver_command": "X",
      "xserver_args": "-nolisten tcp"
    },
    "users": {
      "maximum_uid": 60000,
      "minimum_uid": 1000,
      "hide_users": [],
      "hide_shells": []
    }
  }
}
```

#### Wayland Sessions

Wayland sessions are defined in `/usr/share/wayland-sessions/`:

```desktop
[Desktop Entry]
Name=Niri
Comment=Wayland compositor
Exec=niri
Type=Application
DesktopNames=niri
Keywords=wayland;compositor;
```

#### Management Commands

```bash
# Test SDDM configuration
sddm --test-config

# Start SDDM manually
sddm

# Check SDDM status
sv status sddm

# Restart SDDM
sv restart sddm
```

## Network Services

### NetworkManager Configuration

NetworkManager manages network connections.

#### Configuration File: `/etc/NetworkManager/NetworkManager.conf`

```ini
[main]
# DHCP client
dhcp=internal

# Plugins to load
plugins=keyfile

# Don't load ifupdown plugin
no-auto-default=*

[logging]
# Logging level
level=INFO
backend=journal

[connection]
# IPv6 privacy
ipv6.ip6-privacy=1

# Connectivity checking
connectivity.uri=http://check.ipv6.microsoft.com/
connectivity.interval=300

[device]
# WiFi settings
wifi.scan-rand-mac-address=yes

# Ethernet settings
ethernet.auto-negotiate=yes

[ifupdown]
# Disable ifupdown integration
managed=false
```

#### JSON Configuration: `/etc/voidance/network.json`

```json
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "NetworkManager",
  "settings": {
    "dhcp": "internal",
    "plugins": ["keyfile"],
    "wifi": {
      "scan_rand_mac_address": true,
      "powersave": 3
    },
    "ethernet": {
      "auto_negotiate": true
    },
    "connectivity": {
      "enabled": true,
      "uri": "http://check.ipv6.microsoft.com/",
      "interval": 300
    },
    "ipv6": {
      "ip6_privacy": "prefer-public-addr"
    }
  }
}
```

#### Network Connections

Connection profiles are stored in `/etc/NetworkManager/system-connections/`:

```ini
[connection]
id=MyWiFi
type=wifi
interface-name=wlan0

[wifi]
mode=infrastructure
ssid=MyWiFi

[wifi-security]
key-mgmt=wpa-psk
psk=your-password

[ipv4]
method=auto

[ipv6]
method=auto
```

#### Management Commands

```bash
# Network management
nmcli device status
nmcli connection show
nmcli device wifi list
nmcli device wifi connect "SSID" password "password"

# Connection management
nmcli connection up "MyWiFi"
nmcli connection down "MyWiFi"
nmcli connection edit "MyWiFi"

# Device management
nmcli device set wlan0 autoconnect yes
nmcli radio wifi on
nmcli radio wifi off

# Monitor connections
nmcli monitor
nmcli device monitor
```

## Audio Services

### PipeWire Configuration

PipeWire provides modern audio services.

#### Configuration File: `/etc/pipewire/pipewire.conf.d/voidance-desktop.conf`

```ini
context.properties = {
    # Default clock settings
    default.clock.quantum = 1024
    default.clock.rate = 48000
    default.clock.allowed-rates = [ 44100, 48000, 88200, 96000, 176400, 192000 ]
    
    # Memory settings
    mem.allow-mlock = true
    
    # Logging
    log.level = 2
}

context.modules = [
    { name = libpipewire-module-rt
        args = {
            nice.level   = -11
            rt.prio      = 88
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
    
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-metadata }
]

stream.properties = {
    node.latency = "1024/48000"
    node.autoconnect = true
    node.dont-reconnect = false
}
```

#### JSON Configuration: `/etc/voidance/audio.json`

```json
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "pipewire",
  "settings": {
    "default_clock_rate": 48000,
    "default_clock_quantum": 1024,
    "allowed_rates": [44100, 48000, 88200, 96000, 176400, 192000],
    "mem_allow_mlock": true,
    "log_level": "2",
    "rtkit": {
      "enabled": true,
      "nice_level": -11,
      "rt_prio": 88,
      "rt_time_soft": 200000,
      "rt_time_hard": 200000
    },
    "pulse": {
      "server_address": ["unix:native"],
      "min_req": "256/48000",
      "default_req": "960/48000",
      "max_req": "1920/48000",
      "min_quantum": "256/48000",
      "default_quantum": "960/48000",
      "max_quantum": "1920/48000"
    }
  }
}
```

#### WirePlumber Configuration

WirePlumber manages audio devices and sessions.

#### Configuration File: `/etc/wireplumber/wireplumber.conf`

```ini
context.properties = {
    library.name.system = "libwireplumber-system"
    connection.id = "wireplumber"
}

context.spa-libs = {
    audio.convert.* = audioconvert/libspa-audioconvert
    support.*       = support/libspa-support
}

context.modules = [
    { name = libpipewire-module-rtkit
        args = {
            nice.level   = -11
            rt.prio      = 88
            rt.time.soft = -1
            rt.time.hard = -1
        }
        flags = [ ifexists nofail ]
    }
    
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-metadata }
]

wireplumber.components = [
    { name = libwireplumber-module-rtkit, provides = [ "rtkit" ] }
    { name = libwireplumber-module-spa-device-factory, provides = [ "spa-device-factory" ] }
    { name = libwireplumber-module-spa-node-factory, provides = [ "spa-node-factory" ] }
    { name = libwireplumber-module-access-default, provides = [ "access-default" ] }
    { name = libwireplumber-module-api-alsa-monitor, provides = [ "api-alsa-monitor" ] }
    { name = libwireplumber-module-default-nodes, provides = [ "default-nodes" ] }
    { name = libwireplumber-module-device-activation, provides = [ "device-activation" ] }
    { name = libwireplumber-module-link-factory, provides = [ "link-factory" ] }
    { name = libwireplumber-module-session-manager, provides = [ "session-manager" ] }
]
```

#### Management Commands

```bash
# PipeWire control
wpctl status
wpctl sinks
wpctl sources
wpctl devices

# Volume control
wpctl set-volume @DEFAULT_SINK@ 50%
wpctl set-mute @DEFAULT_SINK@ toggle

# Device management
wpctl set-default <sink-id>
wpctl inspect <object-id>

# PulseAudio compatibility
pactl info
pactl list sinks
pactl list sources
pavucontrol  # GUI control
```

## Idle Management

### swayidle Configuration

swayidle manages idle detection and actions.

#### Configuration File: `/etc/voidance/idle/config`

```bash
# Idle timeouts (in seconds)
IDLE_TIMEOUT=300                    # 5 minutes before screen lock
LOCK_TIMEOUT=600                    # 10 minutes before screen off
SUSPEND_TIMEOUT=1800                # 30 minutes before suspend

# Screen lock settings
LOCK_ENABLED=true
LOCK_COMMAND="swaylock -f -c 000000"

# Screen off settings
SCREEN_OFF_ENABLED=true
SCREEN_OFF_COMMAND="swaymsg 'output * power off'"

# Suspend settings
SUSPEND_ENABLED=true
SUSPEND_COMMAND="systemctl suspend"

# Resume settings
RESUME_COMMAND="swaymsg 'output * power on'"

# Notification settings
NOTIFY_ENABLED=true
NOTIFY_BEFORE_LOCK=30               # Notify 30 seconds before lock
NOTIFY_LOCK_MESSAGE="Screen will lock in 30 seconds"
NOTIFY_LOCK_ICON="dialog-information"

# Battery-based idle management
BATTERY_IDLE_ENABLED=true
BATTERY_IDLE_TIMEOUT=180            # 3 minutes on battery
BATTERY_LOCK_TIMEOUT=300            # 5 minutes on battery
BATTERY_SUSPEND_TIMEOUT=900         # 15 minutes on battery
```

#### JSON Configuration: `/etc/voidance/idle.json`

```json
{
  "version": "1.0.0",
  "enabled": true,
  "debug": false,
  "service": "swayidle",
  "settings": {
    "timeouts": {
      "idle": 300,
      "lock": 600,
      "suspend": 1800
    },
    "lock": {
      "enabled": true,
      "command": "swaylock -f -c 000000",
      "before_sleep": true
    },
    "screen_off": {
      "enabled": true,
      "command": "swaymsg \"output * power off\""
    },
    "suspend": {
      "enabled": true,
      "command": "systemctl suspend",
      "resume_command": "swaymsg \"output * power on\""
    },
    "notifications": {
      "enabled": true,
      "before_lock": 30,
      "message": "Screen will lock in 30 seconds",
      "icon": "dialog-information"
    },
    "battery": {
      "enabled": true,
      "timeouts": {
        "idle": 180,
        "lock": 300,
        "suspend": 900
      }
    }
  }
}
```

#### swaylock Configuration

swaylock provides screen locking functionality.

#### Configuration File: `/etc/swaylock/config`

```
# Colors
color=000000ff
bs-color=000000ff
inside-color=00000088
ring-color=458588ff
line-color=458588ff
text-color=ebdbb2ff
text-clear-color=ebdbb2ff
text-caps-lock-color=fabd2fff
text-ver-color=8ec07cff
text-wrong-color=fb4934ff

# Ring colors
inside-clear-color=00000000
inside-ver-color=45858888
inside-wrong-color=cc241d88
ring-clear-color=8ec07cff
ring-ver-color=8ec07cff
ring-wrong-color=fb4934ff

# Key handling
ignore-empty-password
show-keyboard-layout
show-failed-attempts

# Screens
screenshots
effect-blur=7x5
effect-vignette=0.5:0.5
fade-in=0.2

# Clock
clock
timestr=%H:%M:%S
datestr=%Y-%m-%d

# Font
font=monospace

# Indicator
indicator
indicator-radius=100
indicator-thickness=20
```

#### Management Commands

```bash
# Start idle management
/usr/share/voidance/idle/start-idle.sh

# Manual screen lock
swaylock -f -c 000000

# Test idle detection
swayidle -w timeout 10 'echo "Idle detected"'

# Desktop integration
/usr/share/voidance/idle/desktop-integration.sh
```

## Service Integration

### Service Dependencies

Services have specific dependencies that must be satisfied:

```
elogind (no dependencies)
    ↓
dbus (depends on elogind)
    ↓
NetworkManager (depends on dbus)
pipewire (depends on dbus)
    ↓
pipewire-pulse (depends on pipewire)
wireplumber (depends on pipewire)
    ↓
sddm (depends on elogind, dbus)
```

### Service Management

#### Master Control Script

```bash
# Start all services
sudo ./scripts/start-system-services.sh start

# Stop all services
sudo ./scripts/start-system-services.sh stop

# Restart all services
sudo ./scripts/start-system-services.sh restart

# Show service status
./scripts/start-system-services.sh status

# Enable/disable individual services
sudo ./scripts/start-system-services.sh enable sddm
sudo ./scripts/start-system-services.sh disable sddm
```

#### Individual Service Control

```bash
# Enable service
sudo ln -s /etc/sv/sddm /var/service/

# Disable service
sudo rm /var/service/sddm

# Start service
sudo sv up sddm

# Stop service
sudo sv down sddm

# Restart service
sudo sv restart sddm

# Check status
sv status sddm
```

### System Monitoring

#### Status Monitor

```bash
# Full system status
./scripts/system-status-monitor.sh status

# Service health only
./scripts/system-status-monitor.sh services

# System resources
./scripts/system-status-monitor.sh resources

# Network status
./scripts/system-status-monitor.sh network

# Audio status
./scripts/system-status-monitor.sh audio

# Display status
./scripts/system-status-monitor.sh display

# Session status
./scripts/system-status-monitor.sh session

# Continuous monitoring
./scripts/system-status-monitor.sh watch
```

#### Health Reports

```bash
# Generate health report
./scripts/system-status-monitor.sh report

# View recent logs
./scripts/system-status-monitor.sh logs
```

## Troubleshooting

### Common Issues

#### Services Not Starting

1. **Check service status**
   ```bash
   sv status <service>
   ```

2. **Check service logs**
   ```bash
   cat /var/log/sv/<service>/current
   ```

3. **Check dependencies**
   ```bash
   ./scripts/test-service-dependencies.sh
   ```

4. **Validate configuration**
   ```bash
   ./scripts/validate-config.sh validate
   ```

#### Configuration Errors

1. **Check JSON syntax**
   ```bash
   ./scripts/validate-config.sh check-json /etc/voidance/
   ```

2. **Test individual files**
   ```bash
   ./scripts/validate-config.sh check-file /etc/voidance/session.json
   ```

3. **Generate default configs**
   ```bash
   ./scripts/validate-config.sh generate
   ```

#### Hardware Issues

1. **Run hardware test**
   ```bash
   ./scripts/test-hardware-compatibility.sh test
   ```

2. **Generate hardware report**
   ```bash
   ./scripts/test-hardware-compatibility.sh report
   ```

3. **Check system logs**
   ```bash
   journalctl -xe
   ```

### Debug Mode

Enable debug mode for services:

```bash
# Enable debug in configuration
echo "debug=true" >> /etc/voidance/session.json

# Restart service with debug
sv restart elogind

# Monitor debug logs
tail -f /var/log/sv/elogind/current
```

### Recovery

#### Service Recovery

```bash
# Reset service configuration
sudo ./scripts/validate-config.sh generate

# Restart all services
sudo ./scripts/start-system-services.sh restart

# Check system health
./scripts/system-status-monitor.sh status
```

#### Configuration Recovery

```bash
# Backup current configuration
sudo cp -r /etc/voidance /etc/voidance.backup

# Generate fresh configuration
sudo ./scripts/validate-config.sh generate

# Test new configuration
./scripts/validate-config.sh validate
```

### Getting Help

1. **Check documentation**
   - README.md for overview
   - docs/hardware-compatibility.md for hardware info
   - Individual man pages for services

2. **Use provided scripts**
   - All test scripts provide detailed output
   - Status monitor shows current system state
   - Validation scripts check configuration

3. **Check system logs**
   ```bash
   # System logs
   journalctl -xe
   
   # Service logs
   sv status <service>
   cat /var/log/sv/<service>/current
   ```

4. **Community support**
   - GitHub Issues for bug reports
   - Community forums for general help
   - Documentation for reference

---

This guide covers the essential aspects of configuring Voidance Linux system services. For more detailed information, refer to the individual service documentation and man pages.