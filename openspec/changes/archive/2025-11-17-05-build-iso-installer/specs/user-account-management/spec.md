# User Account Management

## Overview
Creates and configures the default user account and system groups for Voidance Linux, ensuring proper permissions and security defaults while maintaining the "Feels Smooth" user experience.

## ADDED Requirements

### Requirement: Default User Account Creation
The system SHALL create default `voidance` user account during installation.

#### Scenario: During ISO installation, the system creates a default user account named "voidance" with UID 1000, GID 1000, and membership in required groups for desktop functionality

### Requirement: User Groups Configuration
The system SHALL configure proper user groups for desktop functionality.

#### Scenario: The voidance user is automatically added to groups wheel, audio, video, input, disk, lp, scanner, kvm, render, and users to enable full desktop functionality

### Requirement: Sudo Access Configuration
The system SHALL set up sudo access with password authentication.

#### Scenario: Users in the wheel group can execute any command with sudo, and specific administrative commands like reboot and poweroff work without password for convenience

### Requirement: User Directories Creation
The system SHALL create user directories with correct permissions.

#### Scenario: The user's home directory contains standard XDG directories (Documents, Downloads, Pictures, etc.) with proper ownership (voidance:voidance) and permissions (755)

### Requirement: User Shell and Environment Configuration
The system SHALL configure user shell and environment.

#### Scenario: The user's .bashrc includes Voidance-specific environment variables for EDITOR, BROWSER, TERMINAL, and Wayland-specific settings

### Requirement: Optional User Creation Support
The system SHALL support optional user creation during first boot.

#### Scenario: During the welcome screen, users can create additional user accounts or modify the default voidance account settings

### Requirement: Security Best Practices
The system SHALL follow security best practices for user permissions.

#### Scenario: The default password must be changed on first login, and sudo access requires password authentication except for specific safe commands

### Requirement: Wayland/Niri Compatibility
The system SHALL maintain compatibility with Wayland/Niri desktop.

#### Scenario: User groups and permissions are configured to allow proper access to Wayland session management and Niri compositor functionality

### Requirement: File Ownership and Permissions
The system SHALL ensure proper file ownership and permissions.

#### Scenario: All user files and directories are owned by the voidance user with appropriate permissions that prevent unauthorized access

### Requirement: Automatic and Interactive User Creation
The system SHALL support both automatic and interactive user creation.

#### Scenario: The system can automatically create the default user during installation or allow interactive configuration through the welcome screen

### Requirement: Linux Filesystem Standards Compliance
The system SHALL comply with Linux filesystem hierarchy standards.

#### Scenario: User directories follow XDG Base Directory Specification with .config for configurations and .local for user data
- Create default `voidance` user account during installation
  #### Scenario: During ISO installation, the system creates a default user account named "voidance" with UID 1000, GID 1000, and membership in required groups for desktop functionality
- Configure proper user groups for desktop functionality
  #### Scenario: The voidance user is automatically added to groups wheel, audio, video, input, disk, lp, scanner, kvm, render, and users to enable full desktop functionality
- Set up sudo access with password authentication
  #### Scenario: Users in the wheel group can execute any command with sudo, and specific administrative commands like reboot and poweroff work without password for convenience
- Create user directories with correct permissions
  #### Scenario: The user's home directory contains standard XDG directories (Documents, Downloads, Pictures, etc.) with proper ownership (voidance:voidance) and permissions (755)
- Configure user shell and environment
  #### Scenario: The user's .bashrc includes Voidance-specific environment variables for EDITOR, BROWSER, TERMINAL, and Wayland-specific settings
- Support optional user creation during first boot
  #### Scenario: During the welcome screen, users can create additional user accounts or modify the default voidance account settings

### ADDED Non-Functional Requirements
- Follow security best practices for user permissions
  #### Scenario: The default password must be changed on first login, and sudo access requires password authentication except for specific safe commands
- Maintain compatibility with Wayland/Niri desktop
  #### Scenario: User groups and permissions are configured to allow proper access to Wayland session management and Niri compositor functionality
- Ensure proper file ownership and permissions
  #### Scenario: All user files and directories are owned by the voidance user with appropriate permissions that prevent unauthorized access
- Support both automatic and interactive user creation
  #### Scenario: The system can automatically create the default user during installation or allow interactive configuration through the welcome screen
- Comply with Linux filesystem hierarchy standards
  #### Scenario: User directories follow XDG Base Directory Specification with .config for configurations and .local for user data

## Design

### Default User Configuration
```bash
# Default user details
Username: voidance
UID: 1000
GID: 1000
Shell: /bin/bash
Home: /home/voidance
Groups: voidance,wheel,audio,video,input,disk,lp,scanner,kvm,render,users
```

### System Groups Structure
```bash
# Primary groups
voidance (1000) - Main user group
wheel (10) - Administrative sudo access
users (100) - Standard user group

# Access groups
audio - Audio device access
video - Video device access
input - Input device access
disk - Disk management access
lp - Printer access
scanner - Scanner access
kvm - Virtualization access
render - GPU rendering access
```

### User Directory Structure
```
/home/voidance/
├── .config/           # Application configurations
├── .local/           # Local data and applications
│   ├── bin/          # User scripts
│   ├── share/        # User data
│   └── state/        # State files
├── Documents/        # User documents
├── Downloads/        # Downloaded files
├── Pictures/         # Image files
├── Videos/           # Video files
├── Music/            # Audio files
├── Desktop/          # Desktop files
├── Templates/        # Document templates
├── Public/           # Public share directory
└── .bashrc          # Shell configuration
```

## Implementation

### User Creation Script
```bash
#!/bin/bash
# scripts/create-user.sh

set -euo pipefail

DEFAULT_USER="voidance"
DEFAULT_UID="1000"
DEFAULT_SHELL="/bin/bash"

create_user() {
    local username="${1:-$DEFAULT_USER}"
    local uid="${2:-$DEFAULT_UID}"
    local shell="${3:-$DEFAULT_SHELL}"
    
    # Create user group
    if ! getent group "$username" >/dev/null; then
        groupadd -g "$uid" "$username"
    fi
    
    # Create user account
    if ! id "$username" >/dev/null 2>&1; then
        useradd -m -u "$uid" -g "$username" -G "wheel,audio,video,input,disk,lp,scanner,kvm,render,users" -s "$shell" "$username"
    fi
    
    # Set password (will be changed on first login)
    echo "$username:voidance" | chpasswd
    chage -d 0 "$username"  # Force password change on first login
}

setup_user_directories() {
    local username="$1"
    local home_dir="/home/$username"
    
    # Create standard directories
    mkdir -p "$home_dir"/{Documents,Downloads,Pictures,Videos,Music,Desktop,Templates,Public}
    mkdir -p "$home_dir/.config"
    mkdir -p "$home_dir/.local"/{bin,share,state}
    
    # Set ownership
    chown -R "$username:$username" "$home_dir"
    chmod 755 "$home_dir"
}

configure_shell() {
    local username="$1"
    local home_dir="/home/$username"
    
    # Copy default bashrc
    cp /etc/skel/.bashrc "$home_dir/.bashrc"
    
    # Add Voidance-specific configurations
    cat >> "$home_dir/.bashrc" << 'EOF'

# Voidance Linux configuration
export EDITOR=nano
export BROWSER=firefox
export TERMINAL=wezterm

# Wayland/Niri specific
if [ -n "$WAYLAND_DISPLAY" ]; then
    export MOZ_ENABLE_WAYLAND=1
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland
fi

# Custom prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
    
    chown "$username:$username" "$home_dir/.bashrc"
}

main() {
    local username="${1:-$DEFAULT_USER}"
    
    echo "Creating user account: $username"
    create_user "$username"
    setup_user_directories "$username"
    configure_shell "$username"
    
    echo "User account created successfully"
    echo "Default password: voidance (change on first login)"
}

main "$@"
```

### Sudo Configuration
```bash
# /etc/sudoers.d/voidance

# Allow wheel group to execute any command
%wheel ALL=(ALL) ALL

# Allow passwordless sudo for specific administrative commands
%wheel NOPASSWD: /usr/bin/reboot, /usr/bin/poweroff, /usr/bin/systemctl suspend
```

### First Boot User Setup
```bash
#!/bin/bash
# scripts/first-boot-user-setup.sh

set -euo pipefail

setup_user_preferences() {
    local username="$1"
    local home_dir="/home/$username"
    
    # Create user configuration directories
    mkdir -p "$home_dir/.config"/{niri,waybar,wofi,mako,wezterm}
    
    # Set up default wallpaper
    mkdir -p "$home_dir/.local/share/backgrounds"
    cp /usr/share/backgrounds/voidance/default.jpg "$home_dir/.local/share/backgrounds/" 2>/dev/null || true
    
    # Create desktop entries
    mkdir -p "$home_dir/.local/share/applications"
    
    # Set proper ownership
    chown -R "$username:$username" "$home_dir/.config" "$home_dir/.local"
}

configure_autostart() {
    local username="$1"
    local home_dir="/home/$username"
    
    # Create autostart directory
    mkdir -p "$home_dir/.config/autostart"
    
    # Add welcome screen autostart (first time only)
    cat > "$home_dir/.config/autostart/voidance-welcome.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Voidance Welcome
Exec=voidance-welcome
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
    
    chown -R "$username:$username" "$home_dir/.config/autostart"
}

main() {
    local username="${1:-voidance}"
    
    if [ ! -d "/home/$username" ]; then
        echo "User $username does not exist"
        exit 1
    fi
    
    setup_user_preferences "$username"
    configure_autostart "$username"
    
    echo "User preferences configured for $username"
}

main "$@"
```

## Integration

### Installation Process Integration
- Called during ISO installation phase
- Integrated with void-mklive post-install scripts
- Works with automated and interactive installation modes

### First Boot Integration
- Triggered by systemd service on first login
- Integrates with welcome screen application
- Supports user customization during initial setup

### Desktop Environment Integration
- Ensures proper group membership for Wayland access
- Configures environment variables for Niri/Waybar
- Sets up autostart applications for desktop session

## Testing

### Unit Tests
- User creation script functionality
- Group assignment verification
- Directory creation and permissions
- Shell configuration validation

### Integration Tests
- Installation process user creation
- First boot setup execution
- Desktop environment access permissions
- Sudo access verification

### Security Tests
- Password policy compliance
- Group permission validation
- File ownership verification
- Sudo configuration security

## Security Considerations

### Password Security
- Force password change on first login
- Use strong password hashing
- Support password complexity requirements

### Group Permissions
- Minimal necessary group assignments
- Regular security audit of group memberships
- Separation of privileged and non-privileged access

### File Security
- Proper home directory permissions (750)
- Secure configuration file ownership
- Protection against privilege escalation

## Performance Considerations

### User Creation Speed
- Efficient user account creation
- Minimal directory structure setup
- Optimized permission setting

### Resource Usage
- Lightweight user configuration
- Minimal startup impact
- Efficient file operations

## Monitoring and Maintenance

### User Account Health
- Monitor user directory permissions
- Track group membership changes
- Audit sudo access logs

### System Integration
- Verify desktop environment compatibility
- Monitor first boot setup success
- Track user preference migrations

## Future Enhancements

### Advanced User Management
- Support for multiple user accounts
- User profile templates
- LDAP/Active Directory integration

### Security Features
- Two-factor authentication support
- Biometric authentication
- Encrypted home directories

### Customization Options
- User-selectable shell options
- Custom directory structures
- Theme and preference presets