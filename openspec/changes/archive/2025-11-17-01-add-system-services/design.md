## Context
System services form the foundational layer that enables desktop functionality in Voidance. These services must work together seamlessly to provide user sessions, hardware access, network connectivity, and audio capabilities. The choices must align with Void Linux's runit-based init system while maintaining minimalist principles.

## Goals / Non-Goals
**Goals**:
- Provide reliable session management with proper XDG runtime directory handling
- Enable graphical login with Wayland session support
- Ensure network connectivity works out-of-the-box with both wired and wireless
- Deliver modern, low-latency audio with minimal configuration
- Implement secure screen locking with idle detection
- Maintain compatibility with both glibc and musl
- Keep service configurations minimal and well-documented

**Non-Goals**:
- Support for multiple display managers (SDDM as single choice)
- Complex network configurations (focus on common use cases)
- Advanced audio routing or processing (basic functionality)
- Multiple authentication methods (standard PAM only)
- Power management beyond basic idle/lock functionality

## Decisions

### Decision: elogind + dbus for Session Management
**Why**: elogind provides the session management functionality needed for Wayland without requiring full systemd. dbus enables inter-process communication essential for modern desktop environments.
**Alternatives considered**:
- ConsoleKit2 (less maintained, fewer features)
- No session management (breaks Wayland applications)
- Full systemd (violates Void Linux principles)

### Decision: SDDM as Display Manager
**Why**: SDDM provides excellent Wayland support, modern theming, and reliable session management. It integrates well with elogind and supports multiple desktop sessions.
**Alternatives considered**:
- LightDM (simpler but less Wayland-native)
- GDM (GNOME dependencies, too heavy)
- Ly (minimalist but lacks graphical polish)

### Decision: NetworkManager for Network Services
**Why**: NetworkManager provides reliable network management with good hardware support, GUI applet integration, and seamless switching between wired/wireless connections.
**Alternatives considered**:
- connman (lighter but less hardware support)
- wpa_supplicant + dhcpcd (manual configuration, less user-friendly)
- ifupdown (static configuration only)

### Decision: PipeWire + WirePlumber for Audio
**Why**: PipeWire provides modern low-latency audio with PulseAudio compatibility and better sandboxing. WirePlumber offers flexible session management.
**Alternatives considered**:
- PulseAudio (older architecture, more issues)
- ALSA only (no per-application volume control)
- JACK (professional focus, overkill for desktop)

### Decision: swayidle + swaylock for Idle/Lock
**Why**: swayidle provides Wayland-native idle detection and swaylock offers secure screen locking. Both are lightweight and integrate well with Wayland compositors.
**Alternatives considered**:
- xautolock + xscreensaver (X11-only)
- Custom scripts (more maintenance, less reliable)

## Risks / Trade-offs

**Risk**: Service dependency conflicts in runit environment
**Mitigation**: Careful service ordering, proper dependency documentation, thorough testing

**Risk**: Hardware compatibility issues (network cards, audio devices)
**Mitigation**: Hardware detection scripts, fallback configurations, extensive testing on ThinkPad X1 Carbon

**Trade-off**: Service complexity vs functionality
**Rationale**: Chosen services provide essential functionality while remaining relatively lightweight

**Trade-off**: Automatic configuration vs user control
**Rationale**: Sensible defaults with easy customization paths maintain user-friendliness

## Migration Plan

**Phase 1**: Core Session Services
1. Install and configure elogind + dbus
2. Set up PAM authentication
3. Create runit service configurations
4. Test XDG runtime directory creation

**Phase 2**: Display and Network Services
1. Install and configure SDDM
2. Set up NetworkManager + applet
3. Create Wayland session files
4. Test graphical login and network connectivity

**Phase 3**: Audio and Idle Services
1. Install PipeWire + WirePlumber + rtkit
2. Configure swayidle + swaylock
3. Set up audio permissions and groups
4. Test audio output and screen locking

**Phase 4**: Integration and Testing
1. Validate service startup order
2. Test service interdependencies
3. Verify hardware compatibility
4. Document configuration and troubleshooting

## Open Questions
- Should we include VPN support in NetworkManager configuration?
- How should we handle audio device selection and configuration?
- What level of logging should be enabled by default for troubleshooting?
- Should we include automatic network connection to known networks?