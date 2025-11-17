# Change: Update Desktop Environment Stack - Replace Foot with Ghostty

## Why
The current desktop environment uses Foot as the default terminal emulator. Ghostty is a modern, fast, and feature-rich terminal emulator that offers better performance, more features, and improved user experience while maintaining the minimalist principles of Voidance. Ghostty provides better GPU acceleration, more customization options, and enhanced font rendering compared to Foot.

## What Changes
- Replace Foot terminal emulator with Ghostty across all configurations
- Update package dependencies to include Ghostty instead of Foot
- Modify default keybindings to use Ghostty
- Update documentation and user guides to reference Ghostty
- Ensure Ghostty configuration schema validation
- Update installation scripts and hardware detection
- Maintain backward compatibility where possible

## Impact
- **Affected specs**: terminal-replacement capability
- **Affected code**: Package configurations, Niri keybindings, documentation, schemas
- **User experience**: Improved terminal performance and features
- **Testing**: Requires validation of Ghostty installation and configuration
- **Migration**: Existing Foot configurations will need migration to Ghostty format