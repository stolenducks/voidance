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

## Requirements

### Requirement: ISO Build System
Voidance SHALL provide a complete ISO build system using void-mklive.

#### Scenario: ISO Build Process
- **WHEN** running the ISO build script
- **THEN** void-mklive configuration is applied
- **AND** all Voidance components are included
- **AND** bootable ISO image is created
- **AND** build process completes without errors

### Requirement: Root Filesystem Setup
Voidance SHALL create proper root filesystem structure for installation.

#### Scenario: Filesystem Creation
- **WHEN** setting up installation environment
- **THEN** FHS-compliant directory structure is created
- **AND** proper permissions are applied
- **AND** system directories are organized
- **AND** configuration files are placed correctly

### Requirement: User Account Management
Voidance SHALL provide comprehensive user account management system.

#### Scenario: User Creation
- **WHEN** creating user accounts during installation
- **THEN** user accounts are created with proper groups
- **AND** home directories are structured correctly
- **AND** sudo permissions are configured
- **AND** security policies are applied

### Requirement: Package Manifest
Voidance SHALL define complete package manifest for ISO.

#### Scenario: Package Selection
- **WHEN** building the ISO
- **THEN** all desktop components are included
- **AND** system services are packaged
- **AND** dependencies are resolved
- **AND** package versions are specified

### Requirement: First-Boot Setup
Voidance SHALL provide first-boot setup experience.

#### Scenario: Welcome Experience
- **WHEN** user first boots installed system
- **THEN** welcome screen is displayed
- **AND** initial configuration wizard runs
- **AND** user preferences are collected
- **AND** system is personalized

### Requirement: Installation Scripts
Voidance SHALL provide automated installation scripts.

#### Scenario: System Installation
- **WHEN** running installer
- **THEN** disk partitioning is handled
- **AND** filesystems are created
- **AND** packages are installed
- **AND** bootloader is configured

### Requirement: Hardware Detection
Voidance SHALL integrate hardware detection with setup.

#### Scenario: Hardware Optimization
- **WHEN** system boots for first time
- **THEN** hardware is detected automatically
- **AND** appropriate drivers are installed
- **AND** system optimizations are applied
- **AND** hardware profiles are created

### Requirement: User-Friendly Experience
Voidance SHALL provide user-friendly installation experience.

#### Scenario: Installation Workflow
- **WHEN** user runs installer
- **THEN** clear instructions are provided
- **AND** progress is shown throughout
- **AND** errors are handled gracefully
- **AND** recovery options are available

## Impact
- **Affected specs**: New capabilities for iso-build-system, root-filesystem-setup, user-account-management, package-manifest, first-boot-setup, installation-scripts
- **Affected code**: ISO build process, installation scripts, system configuration files
- **User experience**: Complete, polished installation experience with working desktop out-of-the-box
- **Testing**: Requires ISO testing in VMs and bare metal, installation validation
- **Dependencies**: Depends on completion of all 4 previous changes (services, desktop, applications, fallback)