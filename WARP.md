# Warp AI Project Rules

This file contains project-specific instructions for AI assistants working on Voidance.

## Project Context

Voidance is a Void Linux remix focused on:
- Beginner-friendly experience
- Hyprland tiling window manager
- Developer productivity
- Minimalism and performance
- Inspired by Omarchy (Arch-based distro)

## Build Environment

- **Target**: Void Linux (musl or glibc)
- **Build tool**: `void-mklive`
- **Development**: macOS via Docker or native Void Linux
- **Init system**: runit (Void default)
- **Package manager**: xbps

## Code Guidelines

### Shell Scripts
- Use `#!/bin/bash` shebang
- Follow shellcheck recommendations
- Add error handling (`set -e`, `set -u`)
- Include descriptive comments
- Use functions for reusability

### Configuration Files
- 2-space indentation for most configs
- Tab indentation for Makefile-style configs
- Comment complex configurations
- Follow upstream conventions (e.g., Hyprland syntax)

### Package Management
- Use xbps package names (not Arch/Debian equivalents)
- Test package availability in Void repos first
- Document any custom builds in `iso-builder/`

## File Organization

```
voidance/
├── config/         # User-facing configs (Hyprland, Waybar, etc.)
├── packages/       # Package lists for ISO
├── scripts/        # Build and utility scripts
├── iso-builder/    # void-mklive configuration
├── themes/         # Wallpapers, GTK themes, icons
└── docs/           # User documentation
```

## When Suggesting Changes

1. **Check Void Linux compatibility** - Not all packages from Arch/Ubuntu exist in Void
2. **Consider runit services** - Services use `sv` command, not `systemctl`
3. **Respect xbps syntax** - Package management differs from apt/pacman
4. **Test in Docker** - Suggest Docker testing workflow for macOS development
5. **Document thoroughly** - This is a learning-focused distro

## Common Commands Reference

### Package Management
```bash
# Install package
sudo xbps-install <package>

# Update system
sudo xbps-install -Su

# Search packages
xbps-query -Rs <keyword>

# Remove package
sudo xbps-remove <package>
```

### Service Management (runit)
```bash
# Start service
sudo sv start <service>

# Stop service
sudo sv stop <service>

# Enable service (create symlink)
sudo ln -s /etc/sv/<service> /var/service/

# Check status
sudo sv status <service>
```

## Key Differences from Other Distros

| Feature | Void Linux | Arch | Ubuntu/Debian |
|---------|-----------|------|---------------|
| Init | runit | systemd | systemd |
| Package Manager | xbps | pacman | apt |
| Package Format | xbps | .pkg.tar.zst | .deb |
| Libc | musl or glibc | glibc | glibc |
| Service Command | `sv` | `systemctl` | `systemctl` |

## Documentation Standards

- Use Markdown for all docs
- Include code examples with proper syntax highlighting
- Add warnings for destructive commands
- Assume beginner-level knowledge
- Link to official Void/Hyprland docs when appropriate

## Testing Checklist

Before suggesting changes are complete:
- [ ] ISO builds successfully
- [ ] Boots in VM (QEMU/VirtualBox)
- [ ] Hyprland starts
- [ ] Basic keybindings work
- [ ] Package installations succeed
- [ ] Documentation updated

## External Resources

- [Void Linux Handbook](https://docs.voidlinux.org/)
- [void-mklive Guide](https://github.com/void-linux/void-mklive)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [runit Documentation](http://smarden.org/runit/)

