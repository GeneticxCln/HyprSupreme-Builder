# 📖 HyprSupreme-Builder Installation Guide

*Complete setup instructions for the Ultimate Hyprland Configuration Suite*

---

## 📋 Prerequisites

### 🖥️ **System Requirements**

| Component | Minimum | Recommended | Optimal |
|-----------|---------|-------------|---------|
| **OS** | Linux (64-bit) | Arch Linux, CachyOS, EndeavourOS | Latest Arch-based distros |
| **RAM** | 4GB | 8GB+ | 16GB+ |
| **Storage** | 8GB free space | 20GB+ (for full setup) | 40GB+ SSD |
| **CPU** | Dual-core | Quad-core 3.0GHz+ | 8+ cores 4.0GHz+ |
| **GPU** | Any | NVIDIA GTX 1060+, AMD RX 580+, Intel Iris+ | RTX 3060+, RX 6600 XT+, Arc A750+ |
| **Network** | Stable internet | Broadband (for downloads) | Gigabit ethernet/WiFi 6 |
| **Display** | 1080p | 1440p | 4K or ultrawide with high refresh rate |

### 🐧 **Supported Distributions**

#### ✅ **Fully Supported (Tier 1)**
- **Arch Linux** - Primary platform
- **CachyOS** - Optimized performance
- **EndeavourOS** - User-friendly Arch
- **Manjaro** - Stable Arch derivative
- **Garuda Linux** - Gaming-focused
- **ArcoLinux** - Full native support *(New in v2.2.0)*
- **Artix Linux** - Full native support *(New in v2.2.0)*
- **BlackArch** - Full native support *(New in v2.2.0)*

#### ⚠️ **Limited Support (Tier 2)**
- **Ubuntu 22.04+** - Some manual compilation required
- **Debian 12+** - Improved package availability *(Updated in v2.2.0)*
- **Fedora 39+** - Better COPR repositories integration *(Updated in v2.2.0)*
- **Fedora 38** - Good support *(Updated in v2.2.0)*
- **openSUSE Leap/Tumbleweed** - Community packages
- **Nobara 39+** - Good support *(New in v2.2.0)*
- **Pop!_OS** - Good support *(New in v2.2.0)*

#### 🧪 **Experimental (Tier 3)**
- **Void Linux** - Advanced users only
- **Gentoo** - Manual compilation required
- **NixOS** - Custom derivations needed
- **Alpine Linux** - Experimental support *(New in v2.2.0)*
- **FreeBSD 13+** - Basic compatibility *(New in v2.2.0)*

### 🔧 **Required Tools & Dependencies**

#### **Essential System Tools**
```bash
# Core utilities (usually pre-installed)
sudo, bash (5.0+), coreutils, findutils, grep, sed, awk

# Development tools
git, curl, wget, unzip, base-devel (or build-essential)

# Package managers
pacman (Arch-based), apt (Debian-based), dnf (Fedora), zypper (openSUSE)

# System utilities (new in v2.2.0)
systemd (or compatible init), cron/systemd-timers, dbus
```

#### **Hardware Dependencies**
```bash
# Display server
wayland, wayland-protocols

# Graphics drivers (one of the following)
mesa                    # Open-source drivers
nvidia-dkms            # NVIDIA proprietary
amdgpu-pro             # AMD proprietary (optional)
intel-media-driver     # Intel specific (new in v2.2.0)

# Audio system
pipewire, pipewire-pulse, wireplumber  # Recommended (v2.2.0 optimized)
# OR
pulseaudio, pulseaudio-alsa            # Legacy support

# Network components (new in v2.2.0)
networkmanager         # Required for network management
iw, wireless_tools     # WiFi utilities
bluez, bluez-utils     # Bluetooth support
```

#### **Optional but Recommended**
```bash
# Terminal emulators
warp-terminal (recommended), kitty, alacritty

# AUR helper (Arch-based systems)
yay, paru

# Development tools
python3 (3.9+), python-pip, nodejs, npm  # Note: Now requires Python 3.9+

# Multimedia
gstreamer, ffmpeg, imagemagick

# Enhanced functionality (new in v2.2.0)
flatpak                # Application management
docker                 # Container support
gamemode               # Gaming optimizations
```

---

## 🚀 Installation Methods

### 🎯 **Method 1: Quick Install (Recommended)**

**For most users - automated one-command setup:**

```bash
# Download and run installer
curl -fsSL https://raw.githubusercontent.com/GeneticxCln/HyprSupreme-Builder/main/install.sh | bash

# OR use the new enhanced installer (v2.2.0+)
curl -fsSL https://raw.githubusercontent.com/GeneticxCln/HyprSupreme-Builder/main/install_enhanced.sh | bash
```

**What this does:**
- Automatically detects your distribution
- Installs all required dependencies
- Sets up Hyprland with default configuration
- Configures basic theming and keybindings
- Takes approximately 10-15 minutes

**New in v2.2.0:**
- Enhanced error handling with recovery mechanisms
- Detailed progress reporting during installation
- Improved dependency validation
- Installation state tracking for resumable operations
- System compatibility verification

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
chmod +x install.sh install_enhanced.sh hyprsupreme
```

#### **Step 2: Pre-Installation Checks**
```bash
# Enhanced system compatibility check (new in v2.2.0)
./check_system.sh --verbose

# Verify prerequisites with detailed reporting
./tools/verify_prerequisites.sh

# Test network connectivity (new in v2.2.0)
./modules/core/install_network.sh test
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

# New v2.2.0 options:
./install.sh --debug              # Verbose installation with detailed logs
./install.sh --validate-deps      # Comprehensive dependency validation
./install.sh --resume             # Resume interrupted installation
./install.sh --skip-network       # Skip network configuration
./install.sh --custom-config=/path/to/config.yaml  # Use custom configuration
```

#### **Step 4: Launch Application**
```bash
# Start the main application
./hyprsupreme

# Or use specific tools
./hyprsupreme --theme-manager
./hyprsupreme --resolution-setup
./hyprsupreme --keybinding-test

# New v2.2.0 tools:
./hyprsupreme --network-manager   # Network management interface
./hyprsupreme --audio-control     # Audio device and control panel
./hyprsupreme --verify-install    # Verify installation integrity
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

# New v2.2.0 unattended options:
./install.sh --unattended \
  --preset gaming \
  --error-recovery=auto \         # Automatically recover from errors
  --hardware-detection=enhanced \ # Better hardware detection
  --log-level=detailed \          # Detailed logging
  --validate-install=true         # Validate after installation
```

**Environment variables for automation (expanded in v2.2.0):**
```bash
# Basic configuration
export HYPRSUPREME_PRESET="gaming"
export HYPRSUPREME_THEME="catppuccin-mocha"
export HYPRSUPREME_GPU="nvidia"
export HYPRSUPREME_AUDIO="pipewire"
export HYPRSUPREME_UNATTENDED="true"

# New v2.2.0 environment variables
export HYPRSUPREME_ERROR_RECOVERY="auto"    # auto, manual, none
export HYPRSUPREME_LOG_LEVEL="detailed"     # minimal, normal, detailed, debug
export HYPRSUPREME_HARDWARE_DETECTION="enhanced"  # basic, standard, enhanced
export HYPRSUPREME_NETWORK_CONFIG="auto"    # auto, manual, skip
export HYPRSUPREME_VALIDATE_INSTALL="true"  # true, false
export HYPRSUPREME_STATE_TRACKING="enabled" # enabled, disabled

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
  
# New v2.2.0 Docker features:
# Run with GPU acceleration (NVIDIA)
docker run --runtime=nvidia --gpus all \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  -e HYPRSUPREME_PRESET="gaming" \
  -v "$HOME/.config/hyprsupreme:/app/config" \
  geneticxcln/hyprsupreme-builder:2.2.0

# Run with GPU acceleration (AMD/Intel)
docker run --device=/dev/dri \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  -v "$HOME/.config/hyprsupreme:/app/config" \
  geneticxcln/hyprsupreme-builder:2.2.0
```

**Docker Tags (v2.2.0):**
- `latest`: Always points to the latest stable release
- `2.2.0`: This specific version
- `2.2.0-slim`: Minimal installation without development tools
- `2.2.0-nvidia`: NVIDIA optimized image
- `2.2.0-amd`: AMD optimized image
- `edge`: Development version (unstable)

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

# New v2.2.0: Enhanced DPI handling
./tools/resolution_manager.sh --dpi auto
./tools/resolution_manager.sh --scale 1.25
```

#### **2. Configure Multiple Monitors**
```bash
# Auto-detect and configure
./demo_resolutions.sh

# Manual multi-monitor setup
./tools/resolution_manager.sh --monitors auto

# New v2.2.0: Per-monitor refresh rate
./tools/resolution_manager.sh --refresh-rate primary=144 secondary=60

# New v2.2.0: Per-monitor scaling
./tools/resolution_manager.sh --scale primary=1.0 secondary=1.5
```

#### **3. Test Keybindings**
```bash
# Comprehensive keybinding test
./test_keybindings.sh

# Test specific categories
./test_keybindings.sh --category window-management
./test_keybindings.sh --category applications

# New v2.2.0: Interactive keybinding tester
./test_keybindings.sh --interactive

# New v2.2.0: Keybinding conflict detector
./test_keybindings.sh --detect-conflicts
```

#### **4. Set Up Themes**
```bash
# Launch theme manager
./hyprsupreme --theme-manager

# Apply specific theme
./hyprsupreme --apply-theme catppuccin-mocha

# Preview themes
./hyprsupreme --preview-theme gruvbox-dark

# New v2.2.0: Theme integration checker
./hyprsupreme --verify-theme catppuccin-mocha

# New v2.2.0: Global vs. per-app themes
./hyprsupreme --set-app-theme kitty nord
```

#### **5. Network Configuration (New in v2.2.0)**
```bash
# Configure network connections
./hyprsupreme --network-setup

# Set up WiFi
./modules/core/install_network.sh configure

# Configure Bluetooth
./modules/core/install_bluetooth.sh configure

# Test network connectivity
./modules/core/install_network.sh test
```

#### **6. Audio System Configuration (New in v2.2.0)**
```bash
# Configure audio devices
./hyprsupreme --audio-setup

# Test audio output
./modules/core/install_audio.sh test

# Set up media controls
./hyprsupreme --configure-media-keys
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

# New v2.2.0: Update with state preservation
./hyprsupreme --update --preserve-state

# New v2.2.0: Update with dependency validation
./hyprsupreme --update --validate-deps

# New v2.2.0: Update with automatic backup
./hyprsupreme --update --auto-backup
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

# New v2.2.0: System health check
./hyprsupreme --health-check

# New v2.2.0: Repair installation
./hyprsupreme --repair

# New v2.2.0: Debug mode
./hyprsupreme --debug-mode
```

### 🔍 **Installation Verification (New in v2.2.0)**

```bash
# Verify complete installation
./hyprsupreme --verify-install

# Test core components
./hyprsupreme --test-core

# Validate configuration files
./hyprsupreme --validate-config

# Check for common issues
./hyprsupreme --diagnostic

# Generate system report
./hyprsupreme --system-report
```

---

## 📚 Next Steps

After successful installation:

1. **📖 Read the Documentation**
   - [Keybindings Reference](KEYBINDINGS_REFERENCE.md)
   - [Community Commands](COMMUNITY_COMMANDS.md)
   - [Resolution Functions](RESOLUTION_FUNCTIONS.md)
   - [Release Notes v2.2.0](RELEASE_NOTES_v2.2.0.md) - New features and improvements

2. **🎨 Explore Themes**
   - Visit the community platform
   - Try different themes
   - Create your own
   - Check out the new theme verification tool

3. **⚙️ Customize Configuration**
   - Adjust keybindings
   - Configure workspaces
   - Set up productivity tools
   - Use the new hardware detection features

4. **🤝 Join the Community**
   - Share your setup
   - Contribute themes
   - Help other users
   - Report installation successes on different hardware

5. **🔧 Optimize Your Setup (New in v2.2.0)**
   - Run the performance optimizer
   - Configure hardware-specific settings
   - Set up automatic maintenance tasks
   - Fine-tune network and audio configurations

---

## 🔄 Migration Guide for v2.1.x Users

If you're upgrading from a previous version (v2.1.x) to v2.2.0, follow these steps for a smooth transition:

### 🔍 **Pre-Upgrade Checks**

```bash
# Check for v2.1.x configuration compatibility
./hyprsupreme --check-compatibility

# Back up your current configuration
./hyprsupreme --backup-all

# Verify system requirements for v2.2.0
./check_system.sh --for-upgrade
```

### 🚀 **Upgrade Process**

```bash
# Method 1: In-place upgrade (recommended)
git fetch --all
git checkout v2.2.0
./install.sh --upgrade

# Method 2: Clean upgrade (if you encounter issues)
cd ..
mv HyprSupreme-Builder HyprSupreme-Builder.backup
git clone https://github.com/GeneticxCln/HyprSupreme-Builder.git
cd HyprSupreme-Builder
./install.sh --migrate-from=/path/to/HyprSupreme-Builder.backup
```

### 🛠️ **Post-Upgrade Tasks**

```bash
# Verify the upgrade was successful
./hyprsupreme --version

# Update configuration format
./hyprsupreme --migrate-config

# Test core functionality
./hyprsupreme --verify-install

# Apply recommended settings for v2.2.0
./hyprsupreme --apply-recommendations
```

### 📋 **Configuration Changes in v2.2.0**

The following configuration files have changed format and will be automatically migrated:

1. `~/.config/hypr/hyprland.conf` - Enhanced syntax for new features
2. `~/.config/waybar/config` - New modules and configuration options
3. `~/.config/hyprsupreme/settings.json` - New configuration parameters

### ⚠️ **Breaking Changes**

- Python 3.9+ is now required (previously 3.8+)
- Some keybindings have been remapped for better consistency
- Theme format has been updated with additional metadata
- Service management approach has changed

See [RELEASE_NOTES_v2.2.0.md](RELEASE_NOTES_v2.2.0.md) for a complete list of changes.

## 🔧 Troubleshooting v2.2.0 Installation

### Common Issues in v2.2.0

#### Installation Interruptions
```bash
# Resume interrupted installation
./install.sh --resume

# If resume fails, try repair mode
./install.sh --repair
```

#### Dependency Conflicts
```bash
# Run enhanced dependency resolver
./install.sh --fix-dependencies

# For specific conflicts
./modules/core/dependency_validator.sh fix [package_name]
```

#### Network Configuration Failures
```bash
# Skip network configuration
./install.sh --skip-network

# Manual network setup
./modules/core/install_network.sh configure
```

#### GPU Detection Issues
```bash
# Force specific GPU type
./install.sh --gpu=nvidia|amd|intel|hybrid

# Run detailed GPU diagnostics
./tools/gpu_diagnostics.sh --verbose
```

#### Audio System Problems
```bash
# Test audio system
./modules/core/install_audio.sh test

# Reset audio configuration
./hyprsupreme --reset-audio
```

See the full [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more solutions.

---

*Happy Hyprland configuration with v2.2.0! 🎉*

**Need help?** Check our [Troubleshooting Guide](TROUBLESHOOTING.md) or ask in the [community forums](https://github.com/GeneticxCln/HyprSupreme-Builder/discussions).

