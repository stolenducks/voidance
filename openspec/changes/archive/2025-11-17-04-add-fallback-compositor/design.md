## Context
A fallback compositor ensures Voidance remains functional across diverse hardware configurations and user preferences. While Niri provides a modern, fluid experience, some hardware or user workflows may be better served by a more traditional tiling compositor. Sway offers mature stability and i3 compatibility as a reliable alternative.

## Goals / Non-Goals
**Goals**:
- Provide a reliable fallback when Niri has compatibility issues
- Offer i3-compatible tiling for users familiar with i3 workflow
- Ensure seamless application compatibility between compositors
- Maintain consistent desktop environment integration
- Provide easy session switching at login screen
- Support hardware that may not work optimally with Niri
- Keep configuration simple and well-documented

**Non-Goals**:
- Support for multiple compositors beyond Niri and Sway
- Complex compositor switching within active session
- Different application sets for each compositor
- Advanced compositor-specific features
- X11 fallback (focus on Wayland-only)

## Decisions

### Decision: Sway as Fallback Compositor
**Why**: Sway provides mature, stable Wayland compositor with i3-compatible configuration. It's well-tested, has excellent hardware support, and serves as a reliable fallback when Niri has issues.
**Alternatives considered**:
- River (minimalist but less mature)
- Labwc (traditional stacking, different paradigm)
- Hyprland (more complex, similar issues to Niri)
- No fallback (risk of broken desktop)

### Decision: Shared Desktop Applications
**Why**: Using same applications (Waybar, wofi, WezTerm, etc.) across both compositors ensures consistent user experience and simplifies maintenance.
**Alternatives considered**:
- Different applications per compositor (complex, inconsistent)
- Compositor-specific configurations (maintenance overhead)
- Minimal fallback setup (poor user experience)

### Decision: Session-Level Switching
**Why**: Switching compositors at login screen (via SDDM) is simpler and more reliable than runtime switching. It ensures clean session state and avoids compatibility issues.
**Alternatives considered**:
- Runtime switching (complex, potential for crashes)
- Restart-based switching (disruptive, poor UX)
- User-managed switching (error-prone)

## Risks / Trade-offs

**Risk**: Configuration complexity with two compositors
**Mitigation**: Shared configuration templates, clear documentation, schema validation

**Risk**: Application behavior differences between compositors
**Mitigation**: Use Wayland-native applications, test compatibility, provide compositor-specific tweaks

**Trade-off**: Maintenance overhead vs reliability
**Rationale**: Fallback compositor significantly improves system reliability with manageable maintenance cost

**Trade-off**: Disk space vs user choice
**Rationale**: Additional compositor adds minimal disk space while providing crucial fallback option

## Migration Plan

**Phase 1**: Sway Installation and Configuration
1. Install Sway and required dependencies
2. Create default Sway configuration
3. Configure Sway to use shared desktop applications
4. Set up Sway session files for SDDM

**Phase 2**: Desktop Integration
1. Integrate Sway with Waybar, wofi, and other applications
2. Configure Sway-specific keybindings and workflows
3. Set up hardware-aware configuration for Sway
4. Test application compatibility with Sway

**Phase 3**: Session Management
1. Configure SDDM to show both Niri and Sway sessions
2. Set up session selection interface
3. Test session switching and login functionality
4. Validate session isolation and cleanup

**Phase 4**: Testing and Documentation
1. Test Sway on various hardware configurations
2. Validate session switching reliability
3. Document compositor differences and migration
4. Create user guides for both compositors

## Open Questions
- Should we default to Niri or Sway for first-time users?
- How should we handle compositor-specific configuration files?
- What level of i3 compatibility should we maintain?
- Should we provide compositor migration tools?