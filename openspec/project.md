# Project Context

## Purpose
Voidance is a minimalist Linux distribution project that combines Void Linux's principles with modern, user-friendly design. It aims to provide a clean, streamlined experience while serving as an educational platform for users learning Linux system internals.

## Tech Stack
- **Runtime**: Bun (JavaScript/TypeScript runtime)
- **Package Manager**: Bun
- **Core Dependencies**:
  - `@opencode-ai/plugin` (v1.0.57) - Main plugin framework
  - `@opencode-ai/sdk` (v1.0.57) - SDK for OpenCode integration
  - `zod` (v4.1.8) - Schema validation and type safety
- **Language**: JavaScript/TypeScript
- **Base System**: Void Linux with xbps package manager
- **C Library**: glibc (default), with musl as optional alternative

## Project Conventions

### Code Style
- **Minimalism**: Keep the system as clean as possible, avoiding unnecessary dependencies (Void Linux principles)
- **Schema Validation**: All configurations use schema validation (Zod) to ensure correctness and prevent configuration errors
- **Modular Design**: Follow modular and simple design patterns for service management, configuration files, and UI components

### Architecture Patterns
- **Plugin-based Architecture**: Extend functionality through plugins, similar to OpenCode's modular architecture
- **Command-oriented Design**: Focus on minimal set of commands that are easy to use, extend, and modify
- **SDK-based Integration**: Use Void Linux's existing toolchains and packages to integrate with OpenCode SDK
- **Schema-driven Development**: Leverage Zod for schema validation ensuring configuration files follow required formats

### Testing Strategy
- **Unit Tests**: For each service or component (networking, window management, Wayland compositor setup)
- **Integration Tests**: Ensure system services work together seamlessly (networking with Wayland, Hyprland integration)
- **Manual Testing**: Important for user-friendliness, especially for installation process and first boot on various hardware

**Testing Infrastructure Setup**:
- **Development Environment**: Mac for continued development and ISO building
- **Target Hardware**: ThinkPad X1 Carbon 8th Gen as primary testing device
- **Hardware Detection**: Implement comprehensive hardware detection to ensure compatibility across multiple devices
- **ISO Testing Pipeline**: 
  1. Build Voidance ISO with custom configurations
  2. Test ISO installation on ThinkPad X1 Carbon
  3. Verify hardware detection and driver compatibility
  4. Validate system services post-installation
  5. Document hardware-specific configurations for broader device support

**Multi-Device Testing Approach**:
- Use ThinkPad X1 Carbon as baseline for hardware compatibility testing
- Implement hardware detection scripts to identify system components
- Create hardware profile database for common laptop/desktop configurations
- Test both glibc and musl variants on target hardware
- Validate Wayland/Hyprland performance on different GPU configurations

### Git Workflow
**Branch Strategy**:
- **main**: Stable production code, always deployable
- **develop**: Integration branch for features, next release candidate
- **feature/***: Individual features (e.g., "feature/hyprland-config", "feature/network-manager")
- **bugfix/***: Bug fixes for issues in production or develop
- **hotfix/***: Critical fixes that need immediate deployment to production

**Workflow Process**:
1. **New Features**: Create `feature/branch-name` from `develop`
2. **Bug Fixes**: Create `bugfix/branch-name` from `develop` (or `main` for production issues)
3. **Development**: Work on feature branches, commit regularly with conventional commits
4. **Testing**: Ensure all tests pass before merging
5. **Merge**: Pull requests to `develop` (features) or `main` (hotfixes)
6. **Release**: Merge `develop` to `main` with version tag for releases

**Commit Conventions**:
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting, no functional changes
- `refactor`: Code refactoring, no functional changes
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependency updates
- `config`: Configuration changes
- `iso`: ISO/build related changes

**Examples**:
- `feat(wm): add Hyprland default configuration`
- `fix(network): resolve DHCP client timeout issue`
- `docs(installation): update partitioning guide`
- `iso: add hardware detection scripts to build`
- `test(hardware): add ThinkPad X1 Carbon compatibility tests`

## Domain Context
Voidance caters to Linux users who prefer minimalism and simplicity but require a modern, easy-to-use system optimized for both performance and usability. The system should work out of the box with common features such as networking, window management, and menu launchers.

**Voidance as a Learning Platform**: The project aims to be educational for users who want to learn how a Linux-based system works under the hood, without sacrificing ease of use. It provides a clean, streamlined experience while allowing users to experiment and customize their setup.

## Important Constraints
- **Compatibility**: Must maintain compatibility with both glibc and musl, offering users choice based on needs
- **Minimalism**: Must remain as lightweight as possible, avoiding unnecessary bloat or excessive dependencies
- **User-Friendliness**: While minimalist, must be easy to install and configure, especially for less experienced Linux users

## External Dependencies
- **OpenCode Platform**: Core platform supporting integration of plugins and system management tools
- **@opencode-ai/sdk**: SDK for platform integration
- **Zod**: Schema validation and type safety across configurations and settings
- **Void Linux Repositories**: Primary sources for software packages using xbps package manager
