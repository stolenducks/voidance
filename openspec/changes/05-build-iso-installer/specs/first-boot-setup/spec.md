# First Boot Setup

## Overview
Provides a welcoming and intuitive first-boot experience for Voidance Linux users, guiding them through initial system configuration while maintaining the "Feels Smooth" philosophy of the distribution.

## ADDED Requirements

### Requirement: Welcome Screen Display
The system SHALL display a welcome screen on first login.

#### Scenario: When a user first logs into Voidance, a welcome application automatically launches and provides an introduction to the system

### Requirement: Initial Configuration Guidance
The system SHALL guide users through essential initial configuration.

#### Scenario: The welcome screen walks users through password change, theme selection, wallpaper choice, and other basic system settings

### Requirement: User Preference Collection
The system SHALL collect user preferences and system settings.

#### Scenario: Users can select their preferred theme (light/dark/auto), choose wallpapers, configure autologin, and set other personalization options

### Requirement: Desktop Environment Setup
The system SHALL set up personalized desktop environment.

#### Scenario: User selections are applied to Niri configuration, Waybar settings, and system theme configurations to create a personalized desktop

### Requirement: System Information and Resources
The system SHALL provide system information and getting started resources.

#### Scenario: The welcome screen includes keyboard shortcuts, application overviews, and links to documentation and help resources

### Requirement: Interactive and Automated Setup Modes
The system SHALL support both interactive and automated setup modes.

#### Scenario: Users can either go through the interactive setup or skip it to use default configurations, with options to run it later

### Requirement: Smooth User Experience
The system SHALL maintain smooth, responsive user experience.

#### Scenario: The welcome application launches quickly, responds immediately to user interactions, and provides smooth transitions between setup steps

### Requirement: Modern Desktop Design
The system SHALL follow modern desktop application design patterns.

#### Scenario: The interface uses GTK4/libadwaita components with consistent styling, proper spacing, and intuitive navigation patterns

### Requirement: Accessibility and Usability
The system SHALL ensure accessibility and usability for all users.

#### Scenario: The application supports keyboard navigation, screen readers, and follows accessibility guidelines for users with disabilities

### Requirement: Clear Instructions and Guidance
The system SHALL provide clear, concise instructions and guidance.

#### Scenario: Each setup step includes clear explanations, helpful descriptions, and contextual help text to guide users through the process

### Requirement: Multi-language Support
The system SHALL support multiple languages where possible.

#### Scenario: The welcome application uses standard internationalization practices and can be localized for different language regions
- Display welcome screen on first login
  #### Scenario: When a user first logs into Voidance, a welcome application automatically launches and provides an introduction to the system
- Guide users through essential initial configuration
  #### Scenario: The welcome screen walks users through password change, theme selection, wallpaper choice, and other basic system settings
- Collect user preferences and system settings
  #### Scenario: Users can select their preferred theme (light/dark/auto), choose wallpapers, configure autologin, and set other personalization options
- Set up personalized desktop environment
  #### Scenario: User selections are applied to Niri configuration, Waybar settings, and system theme configurations to create a personalized desktop
- Provide system information and getting started resources
  #### Scenario: The welcome screen includes keyboard shortcuts, application overviews, and links to documentation and help resources
- Support both interactive and automated setup modes
  #### Scenario: Users can either go through the interactive setup or skip it to use default configurations, with options to run it later

### ADDED Non-Functional Requirements
- Maintain smooth, responsive user experience
  #### Scenario: The welcome application launches quickly, responds immediately to user interactions, and provides smooth transitions between setup steps
- Follow modern desktop application design patterns
  #### Scenario: The interface uses GTK4/libadwaita components with consistent styling, proper spacing, and intuitive navigation patterns
- Ensure accessibility and usability for all users
  #### Scenario: The application supports keyboard navigation, screen readers, and follows accessibility guidelines for users with disabilities
- Provide clear, concise instructions and guidance
  #### Scenario: Each setup step includes clear explanations, helpful descriptions, and contextual help text to guide users through the process
- Support multiple languages where possible
  #### Scenario: The welcome application uses standard internationalization practices and can be localized for different language regions

## Design

### Welcome Screen Features

#### Main Welcome Interface
```bash
# Welcome screen sections
1. Welcome Message
   - Voidance Linux introduction
   - Key features and philosophy
   - Quick start overview

2. Initial Setup Steps
   - User account configuration
   - Network setup
   - Desktop preferences
   - System settings

3. Personalization
   - Theme selection
   - Wallpaper choice
   - Panel configuration
   - Application preferences

4. Getting Started
   - System overview
   - Useful applications
   - Keyboard shortcuts
   - Help resources
```

#### Configuration Options
```bash
# User configuration options
- Password change
- User avatar selection
- Shell preference
- Autologin option

# Desktop configuration options
- Theme selection (light/dark/auto)
- Wallpaper selection
- Panel position and style
- Application launcher preferences

# System configuration options
- Network connection setup
- Time zone and date/time
- Language and region settings
- Privacy and security preferences
```

### Welcome Application Architecture

#### Frontend Interface
```bash
# Technology stack
- GUI Framework: GTK4/libadwaita
- Language: Rust or Python
- Backend: System configuration scripts
- Integration: systemd user services
```

#### Backend Services
```bash
# Configuration management
- System settings API
- User preference storage
- Desktop environment integration
- Service management interface
```

## Implementation

### Welcome Application
```rust
// src/welcome.rs (Rust implementation)

use gtk4 as gtk;
use libadwaita as adw;
use std::process::Command;

pub struct WelcomeApp {
    app: gtk::Application,
    window: adw::ApplicationWindow,
    stack: gtk::Stack,
    current_step: u32,
}

impl WelcomeApp {
    pub fn new() -> Self {
        let app = gtk::Application::new(Some("com.voidance.welcome"), Default::default());
        
        app.connect_activate(|app| {
            let window = adw::ApplicationWindow::builder()
                .application(app)
                .title("Welcome to Voidance Linux")
                .default_width(800)
                .default_height(600)
                .build();
            
            let welcome_app = WelcomeApp {
                app: app.clone(),
                window: window.clone(),
                stack: gtk::Stack::new(),
                current_step: 0,
            };
            
            welcome_app.setup_ui();
            welcome_app.show();
        });
        
        Self { app, window: adw::ApplicationWindow::new(), stack: gtk::Stack::new(), current_step: 0 }
    }
    
    fn setup_ui(&self) {
        // Create main layout
        let header_bar = adw::HeaderBar::new();
        self.window.set_titlebar(Some(&header_bar));
        
        // Create welcome stack
        self.create_welcome_page();
        self.create_user_setup_page();
        self.create_desktop_setup_page();
        self.create_final_page();
        
        // Navigation buttons
        let nav_box = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        let back_btn = gtk::Button::with_label("Back");
        let next_btn = gtk::Button::with_label("Next");
        let finish_btn = gtk::Button::with_label("Finish");
        
        back_btn.connect_clicked(|_| {
            // Navigate to previous page
        });
        
        next_btn.connect_clicked(|_| {
            // Navigate to next page
        });
        
        finish_btn.connect_clicked(|_| {
            // Complete setup
            self.complete_setup();
        });
        
        nav_box.append(&back_btn);
        nav_box.append(&gtk::Box::new(gtk::Orientation::Horizontal, 0)); // Spacer
        nav_box.append(&next_btn);
        nav_box.append(&finish_btn);
        
        // Main layout
        let main_box = gtk::Box::new(gtk::Orientation::Vertical, 10);
        main_box.append(&self.stack);
        main_box.append(&nav_box);
        
        self.window.set_content(Some(&main_box));
    }
    
    fn create_welcome_page(&self) {
        let page = adw::PreferencesPage::new();
        
        let welcome_group = adw::PreferencesGroup::new();
        welcome_group.set_title("Welcome to Voidance Linux");
        
        let welcome_label = gtk::Label::new(Some(
            "Voidance Linux is a minimalist, user-friendly distribution \
             that provides a smooth, modern desktop experience with the \
             Niri Wayland compositor. This setup will help you configure \
             your system for the best experience."
        ));
        welcome_label.set_wrap(true);
        welcome_label.set_margin_top(10);
        welcome_label.set_margin_bottom(10);
        
        welcome_group.add(&welcome_label);
        page.add(&welcome_group);
        
        self.stack.add_titled(&page, Some("welcome"), "Welcome");
    }
    
    fn create_user_setup_page(&self) {
        let page = adw::PreferencesPage::new();
        
        // User account setup
        let user_group = adw::PreferencesGroup::new();
        user_group.set_title("User Account");
        
        let password_row = adw::ActionRow::new();
        password_row.set_title("Password");
        password_row.set_subtitle("Change your user password");
        let password_btn = gtk::Button::with_label("Change");
        password_btn.connect_clicked(|_| {
            // Open password change dialog
        });
        password_row.add_suffix(&password_btn);
        
        user_group.add(&password_row);
        page.add(&user_group);
        
        // Desktop preferences
        let desktop_group = adw::PreferencesGroup::new();
        desktop_group.set_title("Desktop Preferences");
        
        let theme_row = adw::ActionRow::new();
        theme_row.set_title("Theme");
        theme_row.set_subtitle("Choose your preferred theme");
        let theme_combo = gtk::ComboBoxText::new();
        theme_combo.append_text("Light");
        theme_combo.append_text("Dark");
        theme_combo.append_text("Auto");
        theme_combo.set_active(Some(2)); // Auto
        theme_row.add_suffix(&theme_combo);
        
        desktop_group.add(&theme_row);
        page.add(&desktop_group);
        
        self.stack.add_titled(&page, Some("user"), "User Setup");
    }
    
    fn create_desktop_setup_page(&self) {
        let page = adw::PreferencesPage::new();
        
        let wallpaper_group = adw::PreferencesGroup::new();
        wallpaper_group.set_title("Wallpaper");
        
        // Wallpaper selection grid
        let wallpaper_grid = gtk::Grid::new();
        wallpaper_grid.set_row_spacing(10);
        wallpaper_grid.set_column_spacing(10);
        
        // Add wallpaper previews
        for i in 0..6 {
            let wallpaper_btn = gtk::Button::new();
            let wallpaper_image = gtk::Image::from_file(format!("/usr/share/backgrounds/voidance/wallpaper{}.jpg", i));
            wallpaper_image.set_pixel_size(120);
            wallpaper_btn.set_child(Some(&wallpaper_image));
            
            let row = i / 3;
            let col = i % 3;
            wallpaper_grid.attach(&wallpaper_btn, col, row, 1, 1);
        }
        
        wallpaper_group.add(&wallpaper_grid);
        page.add(&wallpaper_group);
        
        self.stack.add_titled(&page, Some("desktop"), "Desktop Setup");
    }
    
    fn create_final_page(&self) {
        let page = adw::PreferencesPage::new();
        
        let complete_group = adw::PreferencesGroup::new();
        complete_group.set_title("Setup Complete!");
        
        let complete_label = gtk::Label::new(Some(
            "Your Voidance Linux system is now configured and ready to use. \
             Enjoy your smooth, minimalist desktop experience!"
        ));
        complete_label.set_wrap(true);
        complete_label.set_margin_top(10);
        complete_label.set_margin_bottom(10);
        
        complete_group.add(&complete_label);
        page.add(&complete_group);
        
        // Getting started resources
        let resources_group = adw::PreferencesGroup::new();
        resources_group.set_title("Getting Started");
        
        let shortcuts_row = adw::ActionRow::new();
        shortcuts_row.set_title("Keyboard Shortcuts");
        shortcuts_row.set_subtitle("View useful keyboard shortcuts");
        let shortcuts_btn = gtk::Button::with_label("View");
        shortcuts_btn.connect_clicked(|_| {
            // Open shortcuts viewer
        });
        shortcuts_row.add_suffix(&shortcuts_btn);
        
        resources_group.add(&shortcuts_row);
        page.add(&resources_group);
        
        self.stack.add_titled(&page, Some("complete"), "Complete");
    }
    
    fn complete_setup(&self) {
        // Apply all configurations
        self.apply_configurations();
        
        // Mark setup as complete
        std::fs::write("/home/voidance/.config/voidance/setup-complete", "true").unwrap();
        
        // Remove autostart entry
        std::fs::remove_file("/home/voidance/.config/autostart/voidance-welcome.desktop").unwrap_or(());
        
        // Close welcome window
        self.window.close();
    }
    
    fn apply_configurations(&self) {
        // Apply theme settings
        // Apply wallpaper settings
        // Apply user preferences
        // Configure system settings
    }
    
    fn show(&self) {
        self.window.present();
    }
}

fn main() {
    let app = WelcomeApp::new();
    app.app.run();
}
```

### Configuration Scripts
```bash
#!/bin/bash
# scripts/apply-welcome-config.sh

set -euo pipefail

apply_theme_settings() {
    local theme="$1"
    local home_dir="/home/voidance"
    
    case "$theme" in
        "light")
            # Configure light theme
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
            gsettings set org.gnome.desktop.interface icon-theme "Adwaita"
            ;;
        "dark")
            # Configure dark theme
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
            gsettings set org.gnome.desktop.interface icon-theme "Adwaita"
            ;;
        "auto")
            # Configure auto theme (follows system)
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
            gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
            ;;
    esac
    
    # Apply to Niri configuration
    sed -i "s/prefer-dark-theme = false/prefer-dark-theme = $(if [ "$theme" = "dark" ]; then echo "true"; else echo "false"; fi)/" "$home_dir/.config/niri/config.kdl"
}

apply_wallpaper() {
    local wallpaper_path="$1"
    local home_dir="/home/voidance"
    
    # Update Niri configuration
    sed -i "s|output.*{.*background.*}|output { background url(\"$wallpaper_path\") }|" "$home_dir/.config/niri/config.kdl"
    
    # Update Waybar configuration if needed
    # Update other desktop components
}

configure_autostart() {
    local enable_autologin="$1"
    
    if [ "$enable_autologin" = "true" ]; then
        # Configure SDDM autologin
        cat > /etc/sddm.conf.d/autologin.conf << 'EOF'
[Autologin]
User=voidance
Session=plasma
EOF
    fi
}

main() {
    local theme="${1:-auto}"
    local wallpaper="${2:-/usr/share/backgrounds/voidance/default.jpg}"
    local autologin="${3:-false}"
    
    apply_theme_settings "$theme"
    apply_wallpaper "$wallpaper"
    configure_autostart "$autologin"
    
    echo "Welcome configuration applied successfully"
}

main "$@"
```

### First Boot Service
```ini
# /etc/systemd/user/voidance-welcome.service

[Unit]
Description=Voidance Welcome Screen
Description=Launch welcome screen on first login
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/voidance-welcome
RemainAfterExit=yes
ConditionPathExists=!/home/voidance/.config/voidance/setup-complete

[Install]
WantedBy=default.target
```

## Integration

### Desktop Environment Integration
- Integrates with Niri Wayland compositor
- Works with GTK4/libadwaita applications
- Supports Waybar and wofi configuration
- Maintains consistent visual design

### System Integration
- Integrates with systemd user services
- Works with user account management
- Supports system configuration changes
- Maintains system security and permissions

### Application Integration
- Configures default applications
- Sets up file associations
- Integrates with desktop portals
- Supports application preferences

## Testing

### User Interface Tests
- Welcome screen display and navigation
- Configuration option functionality
- Theme and wallpaper application
- User preference persistence

### System Integration Tests
- Service startup and execution
- Configuration script functionality
- System setting application
- User permission handling

### Usability Tests
- User workflow testing
- Accessibility compliance
- Error handling and recovery
- Performance and responsiveness

## Performance Considerations

### Startup Performance
- Minimal resource usage
- Fast application launch
- Efficient configuration application
- Smooth user interface

### Resource Usage
- Lightweight application design
- Minimal memory footprint
- Efficient file operations
- Optimized rendering

## Security Considerations

### User Privacy
- Minimal data collection
- Secure configuration storage
- Proper permission handling
- Privacy-respecting defaults

### System Security
- Secure configuration changes
- Proper privilege escalation
- Safe script execution
- Protection against malicious configuration

## Monitoring and Maintenance

### User Experience
- Track setup completion rates
- Monitor user satisfaction
- Collect feedback and suggestions
- Analyze usage patterns

### System Health
- Monitor service performance
- Track configuration success
- Handle error conditions
- Maintain system stability

## Future Enhancements

### Advanced Features
- Multi-language support
- Accessibility improvements
- Advanced customization options
- Integration with online services

### User Experience
- Interactive tutorials
- Guided system tours
- Contextual help system
- Progressive disclosure of features

### Customization
- Theme creation tools
- Wallpaper management
- Application recommendations
- Personalization suggestions