# Contributing

Thank you for considering contributing to Voidance! This project aims to make Void Linux accessible and beautiful.

---

## How to Contribute

### 1. Report Bugs

Open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- System info (hardware, Voidance version)

### 2. Suggest Features

Open an issue tagged `enhancement` with:
- Use case description
- Why it fits Voidance's goals
- Implementation ideas (optional)

### 3. Submit Pull Requests

```bash
# Fork and clone
git clone https://github.com/YOURUSERNAME/voidance.git
cd voidance

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes
# ...

# Commit with clear messages
git commit -m "Add: new feature description"

# Push and open PR
git push origin feature/your-feature-name
```

---

## Development Guidelines

### Code Style

- **Shell scripts**: Use shellcheck, follow bash best practices
- **Config files**: Use consistent indentation (2 spaces)
- **Comments**: Explain "why", not "what"

### Testing

1. Build ISO locally
2. Test in VM (QEMU recommended)
3. Verify core functionality:
   - Boot process
   - Hyprland loads
   - Key shortcuts work
   - Applications launch

### Commit Messages

Follow conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Formatting, theme updates
- `refactor:` Code restructuring
- `test:` Testing changes
- `chore:` Maintenance tasks

Example:
```
feat: add screenshot tool to default packages

Added grimblast for screenshot functionality
Configured keybindings in hyprland.conf
```

---

## Project Structure

```
voidance/
├── config/        # System configurations
├── packages/      # Package lists
├── scripts/       # Build and utility scripts
├── iso-builder/   # ISO build configuration
├── themes/        # Wallpapers, GTK themes, icons
└── docs/          # Documentation
```

### Key Files

- `packages/packages.txt` - Base packages for ISO
- `config/hypr/hyprland.conf` - Hyprland configuration
- `scripts/build-iso.sh` - ISO build script
- `scripts/installer.sh` - Post-install script

---

## Adding Packages

Edit `packages/packages.txt`:

```bash
# Base system packages
base-system
linux
...

# Your new package
your-package-name
```

Rebuild and test:
```bash
sudo ./scripts/build-iso.sh
```

---

## Theme Contributions

We welcome:
- Wallpapers (place in `themes/wallpapers/`)
- GTK themes (place in `themes/gtk-themes/`)
- Icon packs (place in `themes/icons/`)

Ensure assets are:
- High quality
- Properly licensed (CC0, MIT, GPL, etc.)
- Credited in README

---

## Code of Conduct

- Be respectful and inclusive
- Help newcomers learn
- Focus on constructive feedback
- No harassment or discrimination

---

## Questions?

Feel free to:
- Open a discussion on GitHub
- Reach out on project Discord/IRC
- Comment on existing issues

Thanks for making Voidance better! 🚀

