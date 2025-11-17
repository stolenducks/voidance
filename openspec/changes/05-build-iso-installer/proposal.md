# Change: Build ISO Installer

## Why
Voidance needs a complete ISO building and installation system to transform all configured components into a bootable, installable operating system. This change provides the build process, user setup, and first-boot experience that makes Voidance feel like a polished, user-friendly distribution similar to mainstream Linux distributions while maintaining minimalist principles.

## What Changes
- Create void-mklive configuration for building custom Voidance ISO
- Set up root filesystem structure with proper permissions and organization
- Implement user account creation with sensible defaults and groups
- Define complete package manifest including all desktop components
- Create first-boot setup script for welcome experience and initial configuration
- Develop installation scripts for automated post-install configuration
- Integrate hardware detection with system setup
- Ensure all services and applications work correctly after installation
- Create Omarchy-like user-friendly installation experience

## Impact
- **Affected specs**: New capabilities for iso-build-system, root-filesystem-setup, user-account-management, package-manifest, first-boot-setup, installation-scripts
- **Affected code**: ISO build process, installation scripts, system configuration files
- **User experience**: Complete, polished installation experience with working desktop out-of-the-box
- **Testing**: Requires ISO testing in VMs and bare metal, installation validation
- **Dependencies**: Depends on completion of all 4 previous changes (services, desktop, applications, fallback)