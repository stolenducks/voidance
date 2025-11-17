# display-manager Specification

## Purpose
TBD - created by archiving change 01-add-system-services. Update Purpose after archive.
## Requirements
### Requirement: Graphical Login Management
Voidance SHALL provide SDDM as the graphical display manager for user authentication and session selection.

#### Scenario: Display manager startup
- **WHEN** system boots to graphical target
- **THEN** SDDM starts automatically and displays login screen
- **AND** login screen uses configured theme and branding
- **AND** available desktop sessions are listed for selection

#### Scenario: User authentication
- **WHEN** user enters credentials
- **THEN** SDDM validates username and password
- **AND** successful authentication proceeds to session launch
- **AND** failed attempts provide clear error messages

#### Scenario: Session selection and launch
- **WHEN** user selects a desktop session
- **THEN** SDDM launches the selected session with proper environment
- **AND** Wayland sessions receive necessary environment variables
- **AND** session startup logs are captured for troubleshooting

### Requirement: Wayland Session Support
SDDM SHALL properly support Wayland desktop sessions.

#### Scenario: Wayland session detection
- **WHEN** Wayland compositors are installed
- **THEN** SDDM discovers and lists Wayland session files
- **AND** session files are properly formatted with correct metadata
- **AND** session icons and descriptions are displayed correctly

#### Scenario: Wayland environment setup
- **WHEN** launching Wayland session
- **THEN** SDDM sets required Wayland environment variables
- **AND** XDG_RUNTIME_DIR is properly configured
- **AND** seat and session management work correctly

### Requirement: Theme and Branding Configuration
SDDM SHALL support customizable themes and Voidance branding.

#### Scenario: Theme application
- **WHEN** SDDM starts
- **THEN** Voidance theme is applied automatically
- **AND** branding elements are displayed consistently
- **AND** theme remains functional across different resolutions

#### Scenario: Multi-monitor support
- **WHEN** multiple monitors are connected
- **THEN** SDDM login screen displays correctly on all monitors
- **AND** primary monitor is selected appropriately
- **AND** login dialog is positioned correctly

### Requirement: Service Integration
SDDM SHALL integrate properly with elogind and other system services.

#### Scenario: Service dependencies
- **WHEN** SDDM starts
- **THEN** required services (elogind, dbus) are available
- **AND** service startup order is maintained
- **AND** service failures are handled gracefully

#### Scenario: Session handoff
- **WHEN** user session starts
- **THEN** SDDM properly hands off control to desktop session
- **AND** display manager remains available for session switching
- **AND** logout returns to SDDM login screen

