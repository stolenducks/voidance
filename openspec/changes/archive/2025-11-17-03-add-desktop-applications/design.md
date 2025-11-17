## Context
Desktop applications provide the essential user-facing tools that make Voidance usable as a daily driver. These applications must be carefully chosen to balance functionality, performance, and educational value while maintaining the project's minimalist principles.

## Goals / Non-Goals
**Goals**:
- Provide a fast, modern terminal emulator with GPU acceleration
- Include an intuitive file manager with good keyboard support
- Deliver a clean notification system that integrates with desktop
- Establish consistent, readable typography across the system
- Ensure all applications work well with Wayland and Niri
- Maintain lightweight resource usage and fast startup times
- Provide educational value through transparent configuration

**Non-Goals**:
- Include multiple alternatives for each application type
- Add complex office suites or creative applications
- Support for legacy toolkits or frameworks
- Advanced theming or customization systems
- Package management within applications

## Decisions

### Decision: Ghostty as Terminal Emulator
**Why**: Ghostty provides GPU acceleration, excellent performance, modern features (tabs, splits), and native Wayland support. It has a modern architecture, simple configuration, and is actively maintained with a focus on performance and simplicity.
**Alternatives considered**:
- WezTerm (more complex Lua configuration)
- Alacritty (GPU-accelerated but fewer features)
- Kitty (GPU-accelerated but complex configuration)
- st (minimalist but lacks modern features)

### Decision: Thunar as File Manager
**Why**: Thunar provides a clean, modern GTK interface with good performance, excellent keyboard navigation, and volume management integration. It's lightweight and well-maintained.
**Alternatives considered**:
- PCManFM (lighter but less modern interface)
- Nautilus (GNOME dependencies, too heavy)
- Dolphin (KDE dependencies, overkill)
- Ranger (terminal-only, not suitable for all users)

### Decision: mako as Notification System
**Why**: mako is Wayland-native, lightweight, and integrates well with desktop environments. It provides essential notification functionality without complexity.
**Alternatives considered**:
- dunst (X11-focused, though Wayland fork exists)
- notify-send only (no visual notification daemon)
- Custom solution (development overhead)

### Decision: Font Selection (Montserrat + Inconsolata)
**Why**: Montserrat provides clean, modern UI typography while Inconsolata offers excellent readability for terminal use. Both are well-designed and widely available.
**Alternatives considered**:
- Inter + JetBrains Mono (modern but heavier)
- Roboto + Source Code Pro (Google fonts, good alternative)
- System fonts only (less distinctive look)

## Risks / Trade-offs

**Risk**: Application compatibility issues with Wayland
**Mitigation**: Choose Wayland-native applications, test thoroughly, provide fallbacks

**Risk**: Performance impact on older hardware
**Mitigation**: GPU acceleration in Ghostty, lightweight choices for other apps, configurable performance settings

**Trade-off**: Feature completeness vs simplicity
**Rationale**: Chosen applications provide essential functionality without overwhelming users

**Trade-off**: Modern UI vs resource usage
**Rationale**: Modern toolkits provide better integration and accessibility while remaining efficient

## Migration Plan

**Phase 1**: Core Applications
1. Install Ghostty with basic configuration
2. Install Thunar with essential plugins
3. Set up mako notification daemon
4. Install and configure fonts

**Phase 2**: Integration and Configuration
1. Create application desktop files
2. Configure application integration with desktop environment
3. Set up default applications for file types
4. Implement schema validation for configurations

**Phase 3**: Theming and Polish
1. Apply consistent theming across applications
2. Configure font rendering and hinting
3. Set up notification appearance and behavior
4. Create keyboard shortcuts and integration

**Phase 4**: Testing and Documentation
1. Test application functionality and integration
2. Validate performance on target hardware
3. Create user documentation and guides
4. Document customization and troubleshooting

## Open Questions
- Should we include additional terminal fonts beyond Inconsolata?
- What level of Thunar plugins should be included by default?
- Should mako notifications be grouped or stacked?
- How should we handle application updates and configuration migration?