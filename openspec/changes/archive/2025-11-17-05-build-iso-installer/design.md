## Context
The ISO installer is the critical final step that transforms all our carefully configured components into a cohesive, installable operating system. This process must create a seamless user experience from boot media to first desktop session, similar to polished distributions like Omarchy while maintaining Voidance's minimalist principles.

## Goals / Non-Goals
**Goals**:
- Create bootable ISO that installs complete Voidance system
- Provide user-friendly installation experience with clear guidance
- Ensure all components work correctly after installation
- Implement sensible user account and permission setup
- Create first-boot welcome and configuration experience
- Integrate hardware detection with installation process
- Maintain educational value throughout setup process
- Support both UEFI and legacy boot systems

**Non-Goals**:
- Graphical installer with complex options (keep it simple)
- Multiple desktop environment choices during install (pre-configured)
- Advanced partitioning tools (keep it straightforward)
- Custom package selection during install (predefined manifest)
- Complex user configuration during install (post-install setup)

## Decisions

### Decision: void-mklive for ISO Building
**Why**: void-mklive is Void Linux's official ISO building tool, providing proper integration with xbps package management and Void-specific configurations.
**Alternatives considered**:
- Custom build scripts (more maintenance, less integration)
- Archiso-style tools (not Void-specific)
- Debian live-build (wrong distribution foundation)

### Decision: Text-Based Installer with Guidance
**Why**: Text-based installer is reliable, lightweight, and educational while providing clear guidance for new users.
**Alternatives considered**:
- Calamares (heavy, complex dependencies)
- Custom GUI installer (development overhead)
- Manual installation only (not user-friendly)

### Decision: First-Boot Setup Script
**Why**: First-boot configuration allows users to personalize their system while ensuring all services work correctly.
**Alternatives considered**:
- All configuration during install (complex, time-consuming)
- No first-boot setup (less personalized)
- Configuration only through manual editing (not user-friendly)

### Decision: Predefined Package Manifest
**Why**: Predefined package list ensures all components work together and reduces installation complexity.
**Alternatives considered**:
- Package selection during install (complex, dependency issues)
- Minimal base only (incomplete experience)
- Post-install package installation (requires network, more steps)

## Risks / Trade-offs

**Risk**: Hardware compatibility issues during installation
**Mitigation**: Comprehensive hardware detection, fallback drivers, extensive testing

**Risk**: Installation complexity overwhelming new users
**Mitigation**: Clear guidance, simple questions, default options, progress indication

**Trade-off**: Installation simplicity vs customization options
**Rationale**: Pre-configured system ensures reliability while allowing post-install customization

**Trade-off**: Automation vs user control
**Rationale**: Automated setup ensures working system while maintaining educational transparency

## Migration Plan

**Phase 1**: ISO Build System
1. Set up void-mklive configuration and build environment
2. Create package manifest with all components
3. Configure kernel and boot parameters
4. Test ISO creation and basic boot functionality

**Phase 2**: Installation Process
1. Create text-based installer with clear guidance
2. Implement disk partitioning and filesystem setup
3. Set up system installation and package extraction
4. Configure bootloader installation

**Phase 3**: User and System Setup
1. Implement user account creation and group management
2. Set up default system configurations
3. Create first-boot welcome and setup script
4. Configure service startup and integration

**Phase 4**: Testing and Polish
1. Test installation in VMs and bare metal
2. Validate first-boot experience and configuration
3. Test hardware detection and compatibility
4. Create installation documentation and troubleshooting

## Open Questions
- Should we include automatic partitioning or require manual setup?
- What level of user customization should be available during install?
- How should we handle dual-boot scenarios?
- Should we include system recovery tools in the ISO?