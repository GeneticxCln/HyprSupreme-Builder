# 🔒 Security & Prerequisites Guide

## ⚠️ Security Notice

**IMPORTANT**: This installation script requires administrative privileges and modifies your system. Please review the following security considerations before proceeding.

### 🛡️ Security Features

Our enhanced build script includes several security measures:

- ✅ **Checksum Verification**: Downloads are verified when checksums are available
- ✅ **HTTPS-Only Downloads**: Non-HTTPS downloads require explicit user approval
- ✅ **Root Prevention**: Script refuses to run as root for security
- ✅ **Sudo Timeout**: Limited sudo access with timeout protection
- ✅ **Input Validation**: All user inputs are validated
- ✅ **Error Handling**: Comprehensive error handling and cleanup
- ✅ **Logging**: All operations are logged for audit purposes

### ⚠️ Security Warnings

- **Never run unknown scripts as root**: This script is designed to run as a regular user with sudo privileges
- **Review the code**: We encourage you to examine the script before execution
- **Internet required**: The script downloads packages and configurations from the internet
- **Backup important data**: Always backup your system before major changes

## 📋 Prerequisites

### 🖥️ System Requirements

| Requirement | Minimum | Recommended | Notes |
|-------------|---------|-------------|-------|
| **OS** | Arch-based Linux | CachyOS, EndeavourOS | Script designed for Arch derivatives |
| **RAM** | 4GB | 8GB+ | For smooth Hyprland operation |
| **Storage** | 2GB free | 10GB+ free | For packages and configurations |
| **Internet** | Required | Broadband | For package downloads |
| **User** | Non-root with sudo | Regular user | Script validates this automatically |

### 🔧 Required Dependencies

The script will automatically check and install these if missing:

#### Critical Dependencies
- **bash** (4.0+) - Shell interpreter
- **sudo** - Administrative privileges
- **git** - Version control system
- **curl** - Download utility
- **systemctl** - Service management

#### Optional Dependencies (auto-installed)
- **wget** - Alternative download tool
- **whiptail** - Enhanced dialogs
- **python3** - Python scripts support
- **pip3** - Python package manager

### 🎯 Supported Distributions

| Distribution | Status | Notes |
|--------------|--------|-------|
| **Arch Linux** | ✅ Fully Supported | Native support |
| **CachyOS** | ✅ Fully Supported | Optimized experience |
| **EndeavourOS** | ✅ Fully Supported | Well tested |
| **Manjaro** | ✅ Supported | May require manual intervention |
| **Garuda** | ✅ Supported | Works with most variants |

## 🚀 Installation Methods

### Method 1: Enhanced Build Script (Recommended)

```bash
# Download and review the enhanced build script
git clone https://github.com/GeneticxCln/HyprSupreme-Builder.git
cd HyprSupreme-Builder

# Review the script (recommended)
less build.sh

# Run with enhanced security features
./build.sh
```

### Method 2: Standard Installation

```bash
# Standard installation (existing method)
./install.sh
```

### Method 3: One-Line Installation

```bash
# ⚠️ WARNING: Only use if you trust the source
curl -fsSL https://raw.githubusercontent.com/GeneticxCln/HyprSupreme-Builder/main/install.sh | bash
```

### Method 4: Secure One-Line (Enhanced)

```bash
# More secure: download first, then execute
wget https://raw.githubusercontent.com/GeneticxCln/HyprSupreme-Builder/main/build.sh
chmod +x build.sh
./build.sh
```

## 🔧 Usage Options

### Interactive Mode (Default)
```bash
./build.sh
# Prompts for user confirmation at each step
```

### Unattended Mode
```bash
./build.sh --unattended
# Automated installation with default settings
```

### Dry Run Mode
```bash
./build.sh --dry-run
# Shows what would be done without making changes
```

### Verbose Mode
```bash
./build.sh --verbose
# Detailed output and logging
```

### Force Reinstall
```bash
./build.sh --force
# Reinstalls even if already present
```

### Combined Options
```bash
./build.sh --verbose --dry-run     # See what would happen
./build.sh --unattended --force    # Automated reinstall
```

## 🔍 Verification Steps

### Before Installation
1. **Verify Script Integrity**:
   ```bash
   # Check script size and basic content
   wc -l build.sh
   head -20 build.sh
   ```

2. **Check Dependencies**:
   ```bash
   ./build.sh --dry-run
   ```

3. **Review Logs**:
   ```bash
   # Logs are saved to logs/ directory
   ls -la logs/
   ```

### After Installation
1. **Verify Installation**:
   ```bash
   # Check if Hyprland is installed
   which hyprland
   hyprland --version
   ```

2. **Check Configuration**:
   ```bash
   # Verify config files
   ls -la ~/.config/hypr/
   ```

## 🛠️ Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Make sure script is executable
chmod +x build.sh
```

#### Missing Dependencies
```bash
# Install manually if auto-install fails
sudo pacman -S git curl wget
```

#### Network Issues
```bash
# Test connectivity
ping -c 3 github.com
```

#### Insufficient Permissions
```bash
# Verify sudo access
sudo -v
```

### Log Analysis
```bash
# View latest log
tail -f logs/build-*.log

# Search for errors
grep -i error logs/build-*.log
```

## 📞 Support

If you encounter issues:

1. **Check the logs** in the `logs/` directory
2. **Search existing issues** on GitHub
3. **Create a new issue** with:
   - Your distribution and version
   - Complete error logs
   - Steps to reproduce

## 🤝 Contributing Security Improvements

We welcome security improvements! Please:

1. **Report security issues privately** via GitHub Security tab
2. **Propose improvements** via pull requests
3. **Follow security best practices** in contributions

---

## 🏆 Security Acknowledgments

This enhanced build script implements security best practices including:
- Input validation and sanitization
- Secure download procedures
- Comprehensive logging and error handling
- Prevention of common security pitfalls

**Remember**: No script is 100% secure. Always review code before execution and maintain system backups.

