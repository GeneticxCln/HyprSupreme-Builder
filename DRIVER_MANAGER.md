# 🔧 HyprSupreme Driver Manager

Comprehensive hardware detection and driver management for HyprSupreme-Builder.

## ✨ Features

- **🔍 Automatic Hardware Detection**: Scans your system for all hardware components
- **🎮 GPU Driver Support**: NVIDIA, AMD, and Intel graphics drivers
- **🔊 Audio System**: PipeWire/PulseAudio configuration with SOF firmware
- **🌐 Network Management**: WiFi, Ethernet, and specific chipset drivers
- **📶 Bluetooth**: Complete Bluetooth stack setup
- **📷 Camera Support**: USB Video Class (UVC) and webcam drivers
- **🖨️ Printer Support**: CUPS with various printer drivers
- **🎯 Gaming Optimization**: GameMode, Steam, Lutris, and performance tools
- **📊 Status Monitoring**: Real-time driver status checking
- **💾 Backup System**: Configuration backup and restore
- **🖥️ GUI Interface**: User-friendly graphical interface

## 🚀 Quick Start

### Command Line Interface

```bash
# Quick status check
./hyprsupreme-drivers quick

# Launch GUI
./hyprsupreme-drivers gui

# Install all drivers
./hyprsupreme-drivers install

# Install with gaming support
./hyprsupreme-drivers install-gaming

# Check detailed status
./hyprsupreme-drivers status

# Generate hardware report
./hyprsupreme-drivers report
```

### GUI Interface

Launch the graphical interface for an easy-to-use experience:

```bash
./hyprsupreme-drivers gui
```

## 📋 Supported Hardware

### Graphics Cards
- **NVIDIA**: RTX 40/30/20/10 series, GTX series, Quadro, Tesla
- **AMD**: RX 7000/6000/5000 series, Vega, Polaris, RDNA/RDNA2/RDNA3
- **Intel**: Arc series, Iris Xe, UHD Graphics, HD Graphics

### Audio Devices
- Intel HDA (High Definition Audio)
- NVIDIA HDMI Audio
- USB Audio devices
- Creative Sound cards
- SOF (Sound Open Firmware) devices

### Network Controllers
- Intel WiFi (iwlwifi)
- Realtek (rtw89, rtl8821ce)
- Broadcom WiFi
- All major Ethernet controllers

### Other Hardware
- USB Cameras (UVC compatible)
- Bluetooth controllers
- Printers (HP, Canon, Epson, Brother)
- Gaming peripherals

## 🛠️ Installation Options

### Full Installation
Installs all drivers and optimizations:
```bash
./hyprsupreme-drivers install
```

### Gaming Setup
Includes gaming optimizations:
```bash
./hyprsupreme-drivers install-gaming
```

### Specific Components
```bash
./hyprsupreme-drivers install-gpu      # GPU drivers only
./hyprsupreme-drivers install-audio    # Audio system only
./hyprsupreme-drivers install-network  # Network drivers only
```

## 📊 Status and Monitoring

### Quick Status
```bash
./hyprsupreme-drivers quick
```
Shows:
- GPU driver status
- Audio system status
- Network manager status
- Bluetooth status
- Camera detection

### Detailed Status
```bash
./hyprsupreme-drivers status
```
Provides comprehensive information about all drivers and services.

### Hardware Report
```bash
./hyprsupreme-drivers report
```
Generates a detailed hardware and driver report saved to `/tmp/hyprsupreme-driver-report.txt`.

## 🔧 Advanced Features

### Backup and Restore
```bash
# Backup current configuration
./hyprsupreme-drivers backup

# Backups are stored in /var/backups/hyprsupreme-drivers/
```

### NVIDIA Driver Management
```bash
# Remove NVIDIA drivers (if needed)
./hyprsupreme-drivers uninstall-nvidia
```

### Gaming Optimization
The gaming installation includes:
- **GameMode**: Performance optimization for games
- **Steam**: Valve's gaming platform
- **Lutris**: Open gaming platform
- **Wine**: Windows compatibility layer
- **DXVK**: DirectX to Vulkan translation
- **MangoHUD**: Performance overlay

## 📁 File Structure

```
modules/core/driver_manager.sh     # Main driver manager
gui/driver_manager_gui.sh          # GUI interface
hyprsupreme-drivers               # CLI wrapper
hyprsupreme-driver-manager.desktop # Desktop entry
```

## 🔧 Configuration

### Driver Logs
- Location: `/var/log/hyprsupreme-driver-manager.log`
- Configuration: `/etc/hyprsupreme/drivers/`
- Backups: `/var/backups/hyprsupreme-drivers/`

### Kernel Modules
The driver manager automatically configures kernel module loading:
- `/etc/modules-load.d/nvidia.conf` (NVIDIA)
- `/etc/modules-load.d/amdgpu.conf` (AMD)
- `/etc/modules-load.d/camera.conf` (Camera)

## 🐛 Troubleshooting

### Common Issues

**GPU drivers not loading:**
```bash
# Check if modules are loaded
lsmod | grep -E "(nvidia|amdgpu|i915)"

# Regenerate initramfs
sudo mkinitcpio -P

# Reboot required after driver installation
```

**Audio not working:**
```bash
# Check audio services
systemctl --user status pipewire
systemctl --user status wireplumber

# Restart audio services
systemctl --user restart pipewire
```

**Network issues:**
```bash
# Check NetworkManager
systemctl status NetworkManager

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

### Logs and Debugging
```bash
# View driver installation logs
tail -f /var/log/hyprsupreme-driver-manager.log

# Check system logs
journalctl -f

# Hardware detection
lspci -k    # PCI devices with drivers
lsusb       # USB devices
lsmod       # Loaded kernel modules
```

## 🔄 Integration

The driver manager is fully integrated with HyprSupreme-Builder:

1. **Installation**: Included in component selection
2. **CLI Access**: `./hyprsupreme-drivers` command
3. **GUI Access**: Desktop entry and application menu
4. **Automatic**: Runs during main installation if selected

## 💡 Tips

1. **Run as regular user**: Never run as root
2. **Reboot after GPU drivers**: Required for proper initialization
3. **Gaming setup**: Use `install-gaming` for optimal game performance
4. **Regular checks**: Use `quick` command to monitor driver status
5. **Backup first**: Always backup before making changes

## 🤝 Contributing

Report issues and contribute to the driver manager at:
https://github.com/GeneticxCln/HyprSupreme-Builder

## 📄 License

Part of HyprSupreme-Builder project. See main repository for license information.

---

**Happy computing with perfectly configured drivers! 🚀**

