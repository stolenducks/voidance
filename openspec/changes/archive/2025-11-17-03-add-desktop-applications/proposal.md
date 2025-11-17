# Change: Add Desktop Applications

## Why
Voidance needs essential desktop applications to provide a complete user experience out-of-the-box. Users expect a functional terminal, file manager, notification system, and consistent theming to be available immediately after installation. These applications must work well together and integrate seamlessly with the desktop environment.

## What Changes
- Add Ghostty as the primary GPU-accelerated terminal emulator
- Add Thunar as the modern GTK file manager
- Add mako as the Wayland-native notification daemon
- Add clean, elegant fonts (Montserrat, Inconsolata) for UI and terminal
- Create default configurations for all applications
- Implement schema validation for application configurations
- Ensure proper integration with desktop environment and system services

## Impact
- **Affected specs**: New capabilities for terminal-emulator, file-manager, notification-system, font-theming
- **Affected code**: ISO build process, application configurations, desktop integration scripts
- **User experience**: Complete set of essential applications available immediately after installation
- **Testing**: Requires validation of application functionality, integration, and performance
- **Dependencies**: Builds on system services and desktop environment stack