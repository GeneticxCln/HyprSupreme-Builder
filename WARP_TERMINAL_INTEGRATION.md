# 🚀 Warp Terminal Integration

## Overview

HyprSupreme-Builder now uses **Warp Terminal** as the default terminal emulator, providing a modern, AI-powered terminal experience with enhanced productivity features.

## ✨ Features

### 🤖 **AI-Powered Assistance**
- Intelligent command suggestions
- Natural language to command translation
- Context-aware completions
- Error explanation and fixes

### ⚡ **Modern Interface**
- Block-based command organization
- Real-time collaboration
- Customizable themes and layouts
- Lightning-fast performance

### 🎯 **Developer Productivity**
- Workflow automation
- Command history search
- Multi-session management
- Integration with development tools

## 🛠️ Installation & Configuration

### Automatic Setup
Warp terminal is automatically installed and configured when using HyprSupreme-Builder:

```bash
# During installation, Warp is selected by default
./install.sh

# Manual setup (if needed)
./setup_warp_default.sh
```

### Manual Installation
If you need to install Warp manually:

```bash
# Run the Warp installation module
./modules/core/install_warp.sh install

# Configure Warp as default
./modules/core/install_warp.sh configure
```

## 🎮 **Keybindings**

| Key Combination | Action | Description |
|----------------|--------|-------------|
| `Super + Return` | Open Warp Terminal | Primary terminal launcher |
| `Super + Shift + Return` | Floating Terminal | Open Warp in floating mode |
| `Super + T` | New Tab | Open new tab in Warp |
| `Ctrl + Shift + T` | New Terminal | System shortcut for new terminal |

## ⚙️ **Configuration**

### User Preferences
Warp preferences are stored in `~/.warp/user_preferences.json`:

```json
{
  "appearance": {
    "theme": "base16_dark",
    "font_size": 13,
    "opacity": 0.95,
    "background_blur": true
  },
  "terminal": {
    "shell": "/bin/zsh",
    "working_directory": "home",
    "cursor_style": "block"
  },
  "features": {
    "ai_suggestions": true,
    "blocks": true,
    "workflows": true
  }
}
```

### Custom Theme
A custom HyprSupreme theme is included:

**Location**: `~/.warp/themes/hyprland_dark.yaml`

```yaml
name: "Hyprland Dark"
author: "HyprSupreme"
description: "Dark theme optimized for Hyprland"
background: "#1e1e2e"
foreground: "#cdd6f4"
# ... (Catppuccin-inspired color scheme)
```

## 🏗️ **Build Integration**

### Preset Configuration
All HyprSupreme presets now include Warp by default:

- **Showcase**: Full Warp feature set
- **Gaming**: Performance-optimized Warp
- **Work**: Productivity-focused Warp
- **Minimal**: Lightweight Warp setup
- **Hybrid**: Balanced Warp configuration

### Installation Components
Warp is now the primary terminal in component selection:

```bash
# Component list includes:
"warp" "Warp Terminal (Modern AI Terminal)" "ON"
"kitty" "Kitty Terminal (Fallback)" "OFF"
```

## 🔧 **Troubleshooting**

### Common Issues

#### Warp Not Found
```bash
# Check if Warp is installed
which warp-terminal

# Reinstall if needed
./modules/core/install_warp.sh install
```

#### Keybinding Not Working
```bash
# Reload Hyprland configuration
hyprctl reload

# Check terminal setting
grep "term" ~/.config/hypr/UserConfigs/01-UserDefaults.conf
```

#### Warp Won't Launch
```bash
# Check Warp installation
warp-terminal --version

# Try launching manually
warp-terminal
```

### Fallback to Kitty
If Warp is unavailable, the system will fall back to Kitty:

```bash
# Enable Kitty as fallback
./modules/core/install_kitty.sh

# Switch back to Kitty temporarily
sed -i 's/warp-terminal/kitty/' ~/.config/hypr/UserConfigs/01-UserDefaults.conf
```

## 🌟 **Warp Features for Developers**

### Workflows
Create custom workflows for common development tasks:

1. **Project Setup**: Automated project initialization
2. **Git Operations**: Streamlined git workflows
3. **Build Processes**: One-click build and deploy
4. **Testing**: Automated test execution

### AI Assistant
Use Warp's AI features:

- **Natural Language**: "show me large files in this directory"
- **Error Fixing**: AI suggests fixes for command errors
- **Command Discovery**: Find commands you didn't know existed
- **Documentation**: Inline help and explanations

### Collaboration
- Share terminal sessions
- Collaborative debugging
- Team workflow sharing
- Real-time assistance

## 📚 **Additional Resources**

- [Warp Official Documentation](https://docs.warp.dev/)
- [Warp Themes](https://github.com/warpdotdev/themes)
- [Warp Workflows](https://github.com/warpdotdev/workflows)
- [HyprSupreme Keybindings](KEYBINDINGS_REFERENCE.md)

## 🤝 **Contributing**

To contribute Warp-related improvements:

1. **Themes**: Submit custom Warp themes
2. **Workflows**: Create productivity workflows
3. **Configurations**: Optimize Warp settings
4. **Documentation**: Improve this guide

## 📝 **Changelog**

### v2.0.0
- ✅ Warp terminal as default
- ✅ Custom HyprSupreme theme
- ✅ AI integration enabled
- ✅ Automatic installation
- ✅ Fallback to Kitty support
- ✅ Updated all presets
- ✅ Comprehensive documentation

---

**Made with ❤️ for the modern terminal experience**

*Warp Terminal + HyprSupreme = Ultimate productivity*

