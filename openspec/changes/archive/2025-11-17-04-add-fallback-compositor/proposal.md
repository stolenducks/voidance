# Change: Add Fallback Compositor

## Why
Voidance needs a fallback Wayland compositor to ensure desktop functionality when Niri encounters compatibility issues with specific hardware or user preferences. Sway provides a mature, i3-compatible tiling compositor that serves as a reliable fallback while maintaining the same desktop environment integration.

## What Changes
- Add Sway as fallback Wayland compositor with i3-compatible tiling
- Create Sway session files for display manager selection
- Configure Sway to use same desktop applications (Waybar, wofi, etc.)
- Implement session switching between Niri and Sway
- Create hardware-aware configuration for Sway
- Add schema validation for Sway configurations
- Ensure seamless application compatibility between compositors

## Impact
- **Affected specs**: New capabilities for sway-compositor, session-switching
- **Affected code**: ISO build process, display manager configuration, session management
- **User experience**: Reliable desktop functionality with compositor choice at login
- **Testing**: Requires validation of both compositors and session switching
- **Dependencies**: Builds on system services and desktop applications