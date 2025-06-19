# ⭐ HyprSupreme-Builder

The ultimate Hyprland configuration suite with advanced community features, automated setup, and professional theming capabilities.

![HyprSupreme-Builder](https://img.shields.io/badge/HyprSupreme-Builder-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-2.1.0-purple?style=for-the-badge)
![Release](https://img.shields.io/github/v/release/GeneticxCln/HyprSupreme-Builder?style=for-the-badge&label=⭐%20LATEST%20RELEASE)

## 🎉 **LATEST RELEASE v2.1.0 - NOW AVAILABLE!** ⭐

✨ **[Download v2.1.0](https://github.com/GeneticxCln/HyprSupreme-Builder/releases/tag/v2.1.0)** - Our biggest release yet!

### 🚀 **New in v2.1.0:**
- 🤖 **AI Update Manager** - Intelligent system management
- 🔧 **Enhanced Installation** - Unattended mode & better conflict resolution
- ⚡ **GPU Optimization** - Advanced driver detection & hardware-specific optimizations
- 💾 **Smart Backups** - Point-in-time recovery & automated cleanup
- 🌐 **Community Platform** - Web interface & collaborative development
- 🖥️ **Warp Terminal** - Full AI terminal integration
- 🐳 **Docker Support** - Containerized deployment
- 🧪 **Testing Framework** - Comprehensive automated testing

## ✨ Features

### 🏗️ **Core System**
- **Automated Installation**: One-command setup for complete Hyprland environment
- **Advanced Resolution Management**: Support for multiple monitors, fractional scaling
- **Dependency Management**: Automatic dependency resolution and installation
- **Backup & Restore**: Safe configuration management with rollback support

### 🎨 **Theming & Customization**
- **Professional Themes**: Curated collection of high-quality themes
- **Theme Engine**: Advanced theming system with live preview
- **Wallpaper Management**: Dynamic wallpaper handling with effects
- **Color Schemes**: Automated color palette generation

### 🌐 **Community Platform**
- **Theme Sharing**: Upload and share custom themes
- **Community Discovery**: Browse thousands of community themes
- **Rating System**: Rate and review themes
- **User Profiles**: Track contributions and favorites
- **Web Interface**: Full-featured web platform at localhost:5000

### 🎮 **Keybinding System**
- **145+ Keybindings**: Comprehensive keyboard shortcuts
- **Testing Suite**: Automated keybinding validation
- **Customization**: Easy keybinding modification
- **Reference Guide**: Complete keybinding documentation

### 🔧 **Developer Tools**
- **CLI Interface**: Powerful command-line tools
- **GUI Application**: User-friendly graphical interface
- **API Integration**: RESTful API for external integrations
- **Testing Framework**: Comprehensive test suite

## 🚀 Quick Start

### 📦 **Automatic Installation**
```bash
# Clone the repository
git clone https://github.com/yourusername/HyprSupreme-Builder.git
cd HyprSupreme-Builder

# Run the installer
chmod +x install.sh
./install.sh

# Launch the application
./hyprsupreme
```

### 🌐 **Community Platform**
```bash
# Start the community web interface
./launch_web.sh

# Visit: http://localhost:5000
```

### 🎮 **Test Keybindings**
```bash
# Validate all keybindings
./test_keybindings.sh
```

## 📚 Documentation

### 📖 **Comprehensive Guides**
- **[Keybindings Reference](KEYBINDINGS_REFERENCE.md)** - Complete keyboard shortcuts guide
- **[Community Commands](COMMUNITY_COMMANDS.md)** - CLI and web interface usage
- **[Resolution Functions](RESOLUTION_FUNCTIONS.md)** - Multi-monitor setup guide
- **[Fractional Scaling](FRACTIONAL_SCALING.md)** - High-DPI display support
- **[Flatpak Integration](FLATPAK_INTEGRATION.md)** - Application management

### 🛠️ **Technical Documentation**
- **[Fix Summary](FIX_SUMMARY.md)** - Common issues and solutions
- **[Syntax Fix Summary](SYNTAX_FIX_SUMMARY.md)** - Code fixes and improvements

## 🎯 **Usage Examples**

### 🖥️ **CLI Commands**
```bash
# Discover community themes
./community_venv/bin/python tools/hyprsupreme-community.py discover

# Search for themes
./community_venv/bin/python tools/hyprsupreme-community.py search "minimal"

# Get community statistics
./community_venv/bin/python tools/hyprsupreme-community.py stats --global

# Manage themes
./community_venv/bin/python tools/hyprsupreme-community.py download catppuccin-supreme
./community_venv/bin/python tools/hyprsupreme-community.py install catppuccin-supreme
```

### 🌐 **Web Interface**
1. Start the web server: `./launch_web.sh`
2. Open browser: http://localhost:5000
3. Browse themes, user profiles, and community features
4. Rate and review themes
5. Manage your favorites

### 🎮 **Keybinding Examples**
- **`SUPER + Return`** - Open terminal
- **`SUPER + D`** - Application launcher
- **`SUPER + H`** - Show keybinding hints
- **`SUPER + Print`** - Take screenshot
- **`SUPER + 1-0`** - Switch workspaces

## 🏗️ **Project Structure**

```
HyprSupreme-Builder/
├── 🚀 hyprsupreme              # Main executable
├── 📦 install.sh               # Installation script
├── 🌐 community/               # Community platform
│   ├── web_interface.py        # Flask web application
│   ├── community_platform.py  # Core platform logic
│   └── templates/              # HTML templates
├── 🛠️ tools/                   # CLI tools
│   ├── hyprsupreme-community.py
│   ├── hyprsupreme-cloud.py
│   └── hyprsupreme-migrate.py
├── 🎨 gui/                     # GUI application
├── 📁 sources/                 # Theme sources
├── 🧪 tests/                   # Test suite
├── 📚 docs/                    # Documentation
└── 🔧 Scripts & Tools          # Utility scripts
```

## 🎯 **Key Features**

### ✅ **Validated & Tested**
- **100% Keybinding Coverage**: All 145+ keybindings tested and verified
- **Cross-Platform**: Works on Arch, Ubuntu, Fedora, and derivatives
- **Dependency Management**: Automatic resolution of all dependencies
- **Backup Safety**: Automatic backups before any changes

### 🌟 **Community-Driven**
- **5+ Featured Themes**: Professionally curated themes
- **11 Categories**: Organized theme discovery
- **Rating System**: Community-driven quality assurance
- **User Profiles**: Track contributions and reputation

### 🚀 **Performance Optimized**
- **Fast Installation**: Optimized dependency installation
- **Efficient Resource Usage**: Minimal system overhead
- **Smart Caching**: Cached theme and user data
- **Background Processing**: Non-blocking operations

## 🛠️ **Requirements**

### 📋 **System Requirements**
- **OS**: Linux (Arch, Ubuntu 20.04+, Fedora 35+)
- **Desktop**: Wayland-compatible
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 2GB free space

### 📦 **Dependencies**
- Python 3.8+
- Hyprland 0.35+
- Waybar, Rofi, Warp Terminal
- Git, Curl, Wget

## 🤝 **Contributing**

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### 🌟 **Ways to Contribute**
- 🎨 Submit themes
- 🐛 Report bugs
- 📝 Improve documentation
- 💻 Add features
- 🧪 Write tests

## 📄 **License**

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## 🙏 **Acknowledgments**

- **JaKooLit** - Original Hyprland configurations
- **Hyprland Community** - Inspiration and feedback
- **Contributors** - All amazing contributors
- **Users** - Community feedback and testing

## 📞 **Support**

- 📚 **Documentation**: Check the docs/ directory
- 🐛 **Issues**: GitHub Issues
- 💬 **Discussions**: GitHub Discussions
- 🌐 **Community**: Discord server

---

**Made with ❤️ for the Linux community**

*HyprSupreme-Builder - Building the ultimate Hyprland experience*
