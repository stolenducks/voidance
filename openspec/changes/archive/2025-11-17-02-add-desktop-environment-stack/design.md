## Context
Voidance aims to provide a minimalist yet functional Linux distribution. The desktop environment is a critical component that balances user-friendliness with the project's minimalist principles. We need to choose components that work well together, support modern hardware, and maintain educational value for users learning Linux internals.

## Goals / Non-Goals
**Goals**:
- Provide a complete, working desktop environment out-of-the-box
- Maintain minimalist principles with minimal dependencies
- Ensure Wayland-native support for modern hardware and security
- Create educational value through transparent configuration
- Support both glibc and musl compatibility
- Enable easy customization and learning opportunities

**Non-Goals**:
- Support for legacy X11 applications (focus on Wayland-native)
- Multiple desktop environment options (single, well-integrated stack)
- Complex theming systems (simple, functional defaults)
- Advanced desktop effects or animations (performance-focused)

## Decisions

### Decision: Niri as Wayland Compositor
**Why**: Niri provides scrollable-tiling window management, modern Wayland support, and a fluid user experience while remaining lightweight. It's designed for smooth interactions and is actively maintained with a focus on user experience.
**Alternatives considered**: 
- Hyprland (more complex, dynamic tiling)
- Sway (i3-compatible but less modern feel)
- River (minimalist but steeper learning curve)

### Decision: Waybar for Status Bar
**Why**: Waybar is highly configurable, Wayland-native, and integrates well with Niri. It provides essential system information without excessive resource usage.
**Alternatives considered**:
- Polybar (X11-focused, requires compatibility layer)
- Eww (more complex, overkill for minimal setup)
- Custom solution (development overhead)

### Decision: wofi as Application Launcher
**Why**: wofi is Wayland-native, lightweight, and provides a simple, effective application launcher with good keyboard-driven workflow. It's well-tested and integrates seamlessly with Wayland compositors.
**Alternatives considered**:
- Walker (more complex, additional dependencies)
- Rofi (X11-focused, though Wayland fork exists)
- Fuzzel (minimalist, less discoverable)

### Decision: Schema-Driven Configuration
**Why**: Using Zod schemas ensures configuration correctness, prevents user errors, and enables automatic validation. This aligns with Voidance's schema validation principles.
**Alternatives considered**:
- Manual configuration files (error-prone)
- Shell script validation (less robust)
- No validation (poor user experience)

## Risks / Trade-offs

**Risk**: Wayland compatibility issues with some applications
**Mitigation**: Focus on Wayland-native applications, document known limitations, provide Xwayland fallback where necessary

**Risk**: Hardware-specific configuration complexity
**Mitigation**: Implement hardware detection scripts, create hardware profiles, test on ThinkPad X1 Carbon baseline

**Trade-off**: Single desktop environment vs user choice
**Rationale**: Aligns with minimalist principles, ensures better integration, reduces maintenance overhead

**Trade-off**: Modern features vs resource usage
**Rationale**: Chosen components balance functionality with performance, all are relatively lightweight

## Migration Plan

**Phase 1**: Core Components
1. Install and configure Niri with basic settings
2. Add Waybar with essential modules
3. Implement wofi with basic application database

**Phase 2**: Integration and Polish
1. Create desktop integration scripts
2. Add hardware-aware configuration
3. Implement schema validation for all configs

**Phase 3**: Testing and Documentation
1. Comprehensive testing on target hardware
2. User documentation and customization guides
3. Performance optimization and tuning

## Open Questions
- Should we include default wallpaper and theme, or keep minimal defaults?
- How should we handle user configuration overrides while maintaining system defaults?
- What level of desktop customization should be exposed in the initial installer?
- Should we include screenshot tools and other utilities by default?