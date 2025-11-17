## ADDED Requirements

### Requirement: Ghostty as default terminal emulator
The system SHALL provide Ghostty as the default terminal emulator instead of Foot, offering improved performance and features while maintaining minimalist principles.
#### Scenario: User installs Voidance desktop environment and expects modern terminal emulator
When the desktop environment is installed, Ghostty SHALL be configured as the default terminal emulator with appropriate settings for Voidance's minimalist design.

### Requirement: Ghostty keybinding integration
The system SHALL launch Ghostty terminal when the default terminal keybinding is used, preserving existing user muscle memory and workflows.
#### Scenario: User presses Super+Return to open terminal
When the user presses Super+Return, the system SHALL launch Ghostty instead of Foot, maintaining the same keybinding behavior.

### Requirement: Ghostty configuration validation
The system SHALL provide Zod schema validation for Ghostty configuration files, ensuring type safety and preventing configuration errors.
#### Scenario: System validates terminal configuration
When configuration validation runs, Ghostty settings SHALL be validated against a Zod schema to ensure correctness.

### Requirement: Ghostty migration support
The system SHALL provide clear documentation and migration path for users transitioning from Foot to Ghostty configurations.
#### Scenario: User migrates from Foot to Ghostty
When upgrading from a previous version, users SHALL have access to migration documentation to transition their Foot configurations to Ghostty.

### Requirement: Ghostty package inclusion
The system SHALL include Ghostty in the desktop environment package list instead of Foot, with proper dependency management and version constraints.
#### Scenario: Package manager installs desktop environment
When the desktop environment packages are installed, Ghostty SHALL be included in the package list while Foot SHALL be removed.

### Requirement: Ghostty hardware optimization
The system SHALL detect hardware capabilities and apply Ghostty-specific optimizations for GPU acceleration and performance.
#### Scenario: Hardware detection optimizes terminal settings
When hardware detection runs, Ghostty-specific optimizations SHALL be applied based on the detected GPU and system capabilities.

## MODIFIED Requirements

### Requirement: Application launcher integration
The system SHALL display Ghostty in the application launcher (wofi) and documentation as the default terminal option.
#### Scenario: User accesses terminal through application launcher
When the user opens the application launcher, Ghostty SHALL be listed as the default terminal emulator.

### Requirement: Validation procedures update
The system SHALL validate Ghostty installation and configuration instead of Foot during desktop environment validation procedures.
#### Scenario: System runs validation checks
When desktop environment validation runs, it SHALL check for Ghostty installation and proper configuration.

### Requirement: Documentation consistency
The system SHALL consistently reference Ghostty instead of Foot across all user guides, troubleshooting documentation, and keyboard shortcut references.
#### Scenario: User references terminal in documentation
When users read documentation, all terminal references SHALL point to Ghostty instead of Foot.

## REMOVED Requirements

### Requirement: Foot terminal emulator removal
The system SHALL no longer include Foot as the default terminal emulator in package configurations, keybindings, or documentation.
#### Scenario: System provides Foot terminal emulator
When the desktop environment is installed or configured, Foot SHALL NOT be included as a default package or referenced in configurations.