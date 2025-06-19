# 📖 HyprSupreme-Builder Installation Guide

*Complete setup instructions for the Ultimate Hyprland Configuration Suite*

---

## 📋 Prerequisites

### 🖥️ **System Requirements**

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Linux (64-bit) | Arch Linux, CachyOS, EndeavourOS |
| **RAM** | 4GB | 8GB+ |
| **Storage** | 8GB free space | 20GB+ (for full setup) |
| **GPU** | Any | NVIDIA GTX 1060+, AMD RX 580+, Intel Iris+ |
| **Network** | Stable internet | Broadband (for downloads) |

### 🐧 **Supported Distributions**

#### ✅ **Fully Supported (Tier 1)**
- **Arch Linux** - Primary platform
- **CachyOS** - Optimized performance
- **EndeavourOS** - User-friendly Arch
- **Manjaro** - Stable Arch derivative
- **Garuda Linux** - Gaming-focused

#### ⚠️ **Limited Support (Tier 2)**
- **Ubuntu 22.04+** - Some manual compilation required
- **Debian 11+** - Limited package availability
- **Fedora 35+** - COPR repositories needed
- **openSUSE Leap/Tumbleweed** - Community packages

#### 🧪 **Experimental (Tier 3)**
- **Void Linux** - Advanced users only
- **Gentoo** - Manual compilation required
- **NixOS** - Custom derivations needed

### 🔧 **Required Tools & Dependencies**

#### **Essential System Tools**
```bash
# Core utilities (usually pre-installed)
sudo, bash (5.0+), coreutils, findutils, grep, sed, awk

# Development tools
git, curl, wget, unzip, base-devel (or build-essential)

# Package managers
pacman (Arch-based), apt (Debian-based), dnf (Fedora), zypper (openSUSE)
```

#### **Hardware Dependencies**
```bash
# Display server
wayland, wayland-protocols

# Graphics drivers (one of the following)
mesa                    # Open-source drivers
nvidia-dkms            # NVIDIA proprietary
amdgpu-pro             # AMD proprietary (optional)

# Audio system
pipewire, pipewire-pulse, wireplumber
# OR
pulseaudio, pulseaudio-alsa
```

#### **Optional but Recommended**
```bash
# Terminal emulators
warp-terminal (recommended), kitty, alacritty

# AUR helper (Arch-based systems)
yay, paru

# Development tools
python3 (3.8+), python-pip, nodejs, npm

# Multimedia
gstreamer, ffmpeg, imagemagick
```

---

## 🚀 Installation Methods

### 🎯 **Method 1: Quick Install (Recommended)**

**For most users - automated one-command setup:**

```bash
# Download and run installer
curl -fsSL https://raw.githubusercontent.com/GeneticxCln/HyprSupreme-Builder/main/install.sh | bash
```

**What this does:**
- Automatically detects your distribution
- Installs all required dependencies
- Sets up Hyprland with default configuration
- Configures basic theming and keybindings
- Takes approximately 10-15 minutes

---

### 🔧 **Method 2: Manual Installation (Advanced)**

**For users who want control over the process:**

#### **Step 1: Clone Repository**
```bash
# Create installation directory
mkdir -p ~/Software
cd ~/Software

# Clone the repository
git clone https://github.com/GeneticxCln/HyprSupreme-Builder.git
cd HyprSupreme-Builder

# Make scripts executable
chmod +x install.sh hyprsupreme
```

#### **Step 2: Pre-Installation Checks**
```bash
# Check system compatibility
./check_system.sh

# Verify prerequisites
./tools/verify_prerequisites.sh
```

#### **Step 3: Configure Installation**
```bash
# View available options
./install.sh --help

# Run installer with options
./install.sh --preset minimal     # Minimal installation
./install.sh --preset gaming      # Gaming-optimized
./install.sh --preset work        # Productivity-focused
./install.sh --preset developer   # Development environment
```

#### **Step 4: Launch Application**
```bash
# Start the main application
./hyprsupreme

# Or use specific tools
./hyprsupreme --theme-manager
./hyprsupreme --resolution-setup
./hyprsupreme --keybinding-test
```

---

### 🤖 **Method 3: Unattended Installation**

**For automation and CI/CD pipelines:**

```bash
# Silent installation with preset
./install.sh --unattended --preset gaming --no-confirm

# With custom configuration
./install.sh --unattended \
  --preset custom \
  --theme catppuccin \
  --resolution 2560x1440 \
  --gpu nvidia \
  --audio pipewire
```

**Environment variables for automation:**
```bash
export HYPRSUPREME_PRESET="gaming"
export HYPRSUPREME_THEME="catppuccin-mocha"
export HYPRSUPREME_GPU="nvidia"
export HYPRSUPREME_AUDIO="pipewire"
export HYPRSUPREME_UNATTENDED="true"
./install.sh
```

---

### 🐳 **Method 4: Docker Installation**

**For testing and development:**

```bash
# Using Docker Compose
git clone https://github.com/GeneticxCln/HyprSupreme-Builder.git
cd HyprSupreme-Builder
docker-compose up -d

# Access web interface
open http://localhost:5000

# Manual Docker run
docker run -it --name hyprsupreme \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  geneticxcln/hyprsupreme-builder:latest
```

---

## ⚙️ Configuration Options

### 🎨 **Available Presets**

| Preset | Description | Target Users | Install Time |
|--------|-------------|--------------|--------------|
| **minimal** | Essential components only | New users, low-end hardware | 5-8 min |
| **gaming** | Gaming optimizations | Gamers, high-performance | 15-20 min |
| **work** | Productivity tools | Professionals, developers | 12-18 min |
| **developer** | Full development stack | Programmers, DevOps | 20-25 min |
| **custom** | User-defined configuration | Advanced users | Variable |

### 🖼️ **Theme Selection**

```bash
# Available themes
- catppuccin (mocha, latte, frappe, macchiato)
- gruvbox (dark, light)
- nord
- tokyo-night
- dracula
- rose-pine
- custom (user-provided)

# Theme selection during install
./install.sh --theme catppuccin-mocha
```

### 🎮 **GPU Configuration**

```bash
# Automatic detection (recommended)
./install.sh --gpu auto

# Manual specification
./install.sh --gpu nvidia     # NVIDIA proprietary
./install.sh --gpu amd        # AMD open-source
./install.sh --gpu intel      # Intel integrated
./install.sh --gpu hybrid     # Laptop with dual GPU
```

---

## 📝 Post-Installation Setup

### 🔧 **Essential Configuration**

#### **1. Set Up Display Resolution**
```bash
# Launch resolution manager
./hyprsupreme --resolution-setup

# Or manually configure
./tools/resolution_manager.sh --configure
```

#### **2. Configure Multiple Monitors**
```bash
# Auto-detect and configure
./demo_resolutions.sh

# Manual multi-monitor setup
./tools/resolution_manager.sh --monitors auto
```

#### **3. Test Keybindings**
```bash
# Comprehensive keybinding test
./test_keybindings.sh

# Test specific categories
./test_keybindings.sh --category window-management
./test_keybindings.sh --category applications
```

#### **4. Set Up Themes**
```bash
# Launch theme manager
./hyprsupreme --theme-manager

# Apply specific theme
./hyprsupreme --apply-theme catppuccin-mocha

# Preview themes
./hyprsupreme --preview-theme gruvbox-dark
```

### 🎮 **Gaming Optimization (Gaming Preset)**

```bash
# Enable gaming mode
./hyprsupreme --gaming-mode enable

# Configure GPU performance
./tools/gpu_optimizer.sh --gaming

# Set up game-specific profiles
./hyprsupreme --game-profiles setup
```

### 💼 **Productivity Setup (Work Preset)**

```bash
# Configure workspaces
./hyprsupreme --workspace-setup productivity

# Set up virtual desktops
./tools/workspace_manager.sh --layout work

# Configure productivity apps
./hyprsupreme --install-apps productivity
```

### 🖥️ **Terminal Integration**

#### **Warp Terminal (Recommended)**
```bash
# Install Warp Terminal integration
./setup_warp_default.sh

# Configure Warp-specific features
./hyprsupreme --warp-setup
```

#### **Other Terminals**
```bash
# Kitty terminal setup
./modules/core/install_kitty.sh

# Alacritty configuration
./modules/core/install_alacritty.sh
```

---

## 🌐 Community Features

### 🎨 **Theme Sharing Platform**

#### **Start Web Interface**
```bash
# Launch community platform
./launch_web.sh

# Access at http://localhost:5000
# Features: Browse themes, rate, share, download
```

#### **CLI Theme Management**
```bash
# Discover community themes
./community_venv/bin/python tools/hyprsupreme-community.py discover

# Search for themes
./community_venv/bin/python tools/hyprsupreme-community.py search "dark minimal"

# Download and install
./community_venv/bin/python tools/hyprsupreme-community.py download catppuccin-supreme
./community_venv/bin/python tools/hyprsupreme-community.py install catppuccin-supreme

# Upload your theme
./community_venv/bin/python tools/hyprsupreme-community.py upload my-custom-theme
```

### 📊 **Community Statistics**
```bash
# Global statistics
./community_venv/bin/python tools/hyprsupreme-community.py stats --global

# User statistics
./community_venv/bin/python tools/hyprsupreme-community.py stats --user
```

---

## 🔧 Advanced Configuration

### 🎛️ **Custom Configuration Files**

#### **Hyprland Configuration**
```bash
# Location: ~/.config/hypr/hyprland.conf
# Backup: ~/HyprSupreme-Backups/

# Edit configuration
./hyprsupreme --edit-config hyprland

# Validate configuration
./hyprsupreme --validate-config
```

#### **Waybar Configuration**
```bash
# Location: ~/.config/waybar/
# Edit waybar
./hyprsupreme --edit-config waybar

# Reload waybar
./hyprsupreme --reload waybar
```

### 🔌 **Plugin System**

```bash
# List available plugins
./hyprsupreme --plugins list

# Install plugin
./hyprsupreme --plugins install window-effects

# Enable/disable plugins
./hyprsupreme --plugins enable blur-effects
./hyprsupreme --plugins disable animations
```

### 🔄 **Backup and Restore**

```bash
# Create backup
./hyprsupreme --backup create "before-theme-change"

# List backups
./hyprsupreme --backup list

# Restore backup
./hyprsupreme --backup restore "before-theme-change"

# Automated backup scheduling
./hyprsupreme --backup schedule daily
```

---

## 🔍 Troubleshooting

### 🚨 **Common Issues**

#### **Installation Fails**
```bash
# Check system requirements
./check_system.sh --verbose

# Check logs
tail -f logs/install-$(date +%Y%m%d)*.log

# Clean install
./hyprsupreme --clean-install
```

#### **Graphics Issues**
```bash
# Check GPU drivers
./tools/gpu_diagnostics.sh

# Reconfigure graphics
./hyprsupreme --reconfigure-gpu

# Switch to software rendering
./hyprsupreme --software-rendering
```

#### **Audio Problems**
```bash
# Check audio system
./tools/audio_diagnostics.sh

# Switch audio backend
./hyprsupreme --audio-backend pipewire
./hyprsupreme --audio-backend pulseaudio
```

#### **Keybinding Conflicts**
```bash
# Test all keybindings
./test_keybindings.sh --verbose

# Reset to defaults
./hyprsupreme --reset-keybindings

# Custom keybinding setup
./hyprsupreme --keybinding-wizard
```

### 📋 **Diagnostic Tools**

```bash
# System health check
./hyprsupreme --health-check

# Performance analysis
./hyprsupreme --performance-check

# Configuration validation
./hyprsupreme --validate-all

# Generate support report
./hyprsupreme --support-report
```

### 🆘 **Getting Help**

- **Documentation**: Check docs/ directory
- **Issues**: [GitHub Issues](https://github.com/GeneticxCln/HyprSupreme-Builder/issues)
- **Discussions**: [GitHub Discussions](https://github.com/GeneticxCln/HyprSupreme-Builder/discussions)
- **Community**: Discord server (link in README)
- **Wiki**: [Project Wiki](https://github.com/GeneticxCln/HyprSupreme-Builder/wiki)

---

## 🔄 Updates and Maintenance

### 🆙 **Updating HyprSupreme-Builder**

```bash
# Check for updates
./hyprsupreme --check-updates

# Update to latest version
./hyprsupreme --update

# Update specific components
./hyprsupreme --update themes
./hyprsupreme --update drivers
./hyprsupreme --update community
```

### 🧹 **Maintenance Tasks**

```bash
# Clean temporary files
./hyprsupreme --cleanup

# Optimize system
./hyprsupreme --optimize

# Verify integrity
./hyprsupreme --verify

# Performance tuning
./hyprsupreme --tune-performance
```

---

## 📚 Next Steps

After successful installation:

1. **📖 Read the Documentation**
   - [Keybindings Reference](KEYBINDINGS_REFERENCE.md)
   - [Community Commands](COMMUNITY_COMMANDS.md)
   - [Resolution Functions](RESOLUTION_FUNCTIONS.md)

2. **🎨 Explore Themes**
   - Visit the community platform
   - Try different themes
   - Create your own

3. **⚙️ Customize Configuration**
   - Adjust keybindings
   - Configure workspaces
   - Set up productivity tools

4. **🤝 Join the Community**
   - Share your setup
   - Contribute themes
   - Help other users

---

*Happy Hyprland configuration! 🎉*

**Need help?** Check our [Troubleshooting Guide](TROUBLESHOOTING.md) or ask in the community.

