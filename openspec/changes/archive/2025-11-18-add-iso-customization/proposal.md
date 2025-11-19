# Change: Add ISO Customization System

## Why
Enable users to create a single bootable USB that contains both Void Linux base system and all Voidance desktop environment features pre-installed, eliminating the need for post-installation configuration.

## What Changes
- Add ISO customization capability to extract, modify, and repack Void Linux ISOs
- Integrate all 14 existing Voidance specifications into ISO build process
- Create automated USB creation tools for macOS and Linux
- **BREAKING**: Changes installation workflow from post-install setup to pre-built ISO

## Impact
- Affected specs: All 14 existing specs (audio-services, desktop-integration, display-manager, file-manager, font-theming, idle-lock, network-services, niri-compositor, notification-system, session-management, session-switching, sway-compositor, terminal-emulator, waybar-status-bar, wofi-launcher)
- Affected code: packages/iso-build-system.sh, scripts/setup-iso-build-environment.sh
- New capability: iso-customization
- Build system integration: Requires void-mklive and ISO manipulation tools