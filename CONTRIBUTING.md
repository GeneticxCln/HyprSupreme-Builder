# Contributing to HyprSupreme-Builder

Thank you for your interest in contributing to HyprSupreme-Builder! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### 1. Fork and Clone
```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/HyprSupreme-Builder.git
cd HyprSupreme-Builder
```

### 2. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 3. Make Your Changes
- Follow the existing code style and structure
- Test your changes thoroughly
- Update documentation if needed

### 4. Commit and Push
```bash
git add .
git commit -m "Add your descriptive commit message"
git push origin feature/your-feature-name
```

### 5. Create a Pull Request
- Go to GitHub and create a pull request
- Provide a clear description of your changes
- Reference any related issues

## 📋 Contribution Areas

### 🔧 Code Contributions
- **Installation Modules**: Add support for new components
- **Configuration Integrations**: Port configs from other popular setups
- **Theme Systems**: Improve theming and customization
- **Performance Optimizations**: Enhance speed and efficiency
- **Bug Fixes**: Fix existing issues

### 📚 Documentation
- **README improvements**: Enhance project documentation
- **Module Documentation**: Document new modules and features
- **Tutorials**: Create setup and customization guides
- **Translation**: Translate documentation to other languages

### 🎨 Themes and Configs
- **New Themes**: Add new theme collections
- **Preset Configurations**: Create new preset combinations
- **Wallpaper Collections**: Add curated wallpaper sets
- **Icon Themes**: Integrate new icon packages

### 🧪 Testing
- **Cross-Distribution Testing**: Test on different Arch-based distros
- **Hardware Testing**: Test on different GPU configurations
- **Feature Testing**: Validate new features work correctly
- **Regression Testing**: Ensure changes don't break existing functionality

## 🗂️ Project Structure

```
HyprSupreme-Builder/
├── 📄 install.sh               # Main installer script
├── 📁 modules/                 # Installation modules
│   ├── 📁 core/               # Core component installers
│   ├── 📁 themes/             # Theme management
│   ├── 📁 widgets/            # Widget systems (AGS, etc.)
│   ├── 📁 scripts/            # Utility scripts
│   └── 📁 common/             # Shared functions
├── 📁 configs/                # Configuration templates
│   ├── 📁 jakoolit/          # JaKooLit integration
│   ├── 📁 ml4w/              # ML4W integration
│   ├── 📁 hyde/              # HyDE integration
│   ├── 📁 end4/              # End-4 integration
│   └── 📁 prasanta/          # Prasanta integration
├── 📁 presets/               # Preset configurations
├── 📁 tools/                 # Management utilities
└── 📁 sources/               # Downloaded source configs
```

## 📝 Coding Guidelines

### Shell Script Style
- Use `#!/bin/bash` for all shell scripts
- Follow Google Shell Style Guide
- Use meaningful variable names
- Add comments for complex logic
- Include error handling

### Function Structure
```bash
# Function description
function_name() {
    local param1="$1"
    local param2="$2"
    
    # Function logic here
    log_info "Starting operation..."
    
    # Error handling
    if ! command; then
        log_error "Operation failed"
        return 1
    fi
    
    log_success "Operation completed"
    return 0
}
```

### Logging
Always use the provided logging functions:
```bash
log_info "Information message"
log_success "Success message"
log_error "Error message"
log_warn "Warning message"
log_note "Note message"
```

### Configuration Management
- Use the common functions for config file operations
- Always backup existing configurations
- Validate configurations before applying
- Use the merge system for combining configs

## 🧪 Testing Guidelines

### Before Submitting
1. **Test Locally**: Ensure your changes work on your system
2. **Test Multiple Scenarios**: Try different preset combinations
3. **Check Compatibility**: Verify compatibility with different distros
4. **Validate Configs**: Ensure configuration files are valid
5. **Test Rollback**: Verify backup and rollback functionality

### Test Scenarios
- Fresh installation on clean system
- Installation over existing Hyprland setup
- Different GPU configurations (NVIDIA, AMD, Intel)
- Various preset configurations
- Component selection combinations

## 📋 Issue Guidelines

### Reporting Bugs
- Use the bug report template
- Include system information
- Provide reproduction steps
- Include log files
- Add screenshots if relevant

### Feature Requests
- Use the feature request template
- Explain the use case
- Provide implementation suggestions
- Consider backward compatibility

### Configuration Requests
- Specify the source configuration
- Explain integration benefits
- Provide links to original projects
- Consider licensing compatibility

## 🎯 Integration Guidelines

### Adding New Configurations
When integrating a new Hyprland configuration:

1. **Research**: Study the source configuration thoroughly
2. **Permissions**: Ensure proper attribution and licensing
3. **Modularize**: Break down into reusable components
4. **Test**: Verify integration works with existing systems
5. **Document**: Add documentation for the new integration

### Module Structure
```bash
modules/
├── core/
│   └── install_newcomponent.sh    # Installation script
├── themes/
│   └── newcomponent_themes.sh     # Theme integration
└── configs/
    └── newcomponent/
        ├── hyprland.conf          # Config templates
        ├── waybar/                # Component configs
        └── scripts/               # Helper scripts
```

## 🏆 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- Special mentions for major integrations

## 📄 License

By contributing to HyprSupreme-Builder, you agree that your contributions will be licensed under the same license as the project (GPL-3.0).

## 💬 Communication

- **Issues**: Use GitHub issues for bug reports and feature requests
- **Discussions**: Use GitHub discussions for general questions
- **Pull Requests**: Use PR comments for code review discussions

## 🙏 Acknowledgments

Special thanks to all the original configuration creators:
- [JaKooLit](https://github.com/JaKooLit) - Comprehensive Arch-Hyprland setup
- [ML4W](https://github.com/mylinuxforwork) - Professional workflow tools
- [HyDE Team](https://github.com/prasanthrangan) - Dynamic theming system
- [End-4](https://github.com/end-4) - Modern widget development
- [Prasanta](https://github.com/prasanthrangan) - Beautiful theme designs

---

**Happy Contributing! 🚀**

