# Change: Add System Services

## Why
Voidance needs a robust foundation of system services to support the desktop environment and provide essential functionality like session management, networking, audio, and user authentication. These services are prerequisites for a functional desktop experience and must work reliably across different hardware configurations.

## What Changes
- Add elogind + dbus for session management and runtime directory handling
- Add SDDM as graphical display manager for user login
- Add NetworkManager + network-manager-applet for reliable network connectivity
- Add PipeWire + WirePlumber + rtkit for modern low-latency audio
- Add swayidle + swaylock for screen locking and idle management
- Create runit service configurations for all components
- Implement schema validation for service configurations

## Impact
- **Affected specs**: New capabilities for session-management, display-manager, network-services, audio-services, idle-lock
- **Affected code**: ISO build process, runit service configurations, system startup scripts
- **User experience**: Reliable login, network, audio, and session management out-of-the-box
- **Testing**: Requires validation of service startup, dependencies, and hardware compatibility
- **Dependencies**: Foundation for desktop environment stack and application integration