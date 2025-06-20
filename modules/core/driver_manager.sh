#!/bin/bash

# HyprSupreme-Builder - Driver Manager Module
# Automatic hardware detection and driver installation

set -euo pipefail

# Use readlink to get the absolute path of this script
readonly SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
readonly FUNCTIONS_PATH="${SCRIPT_DIR}/../common/functions.sh"

# Check if functions.sh exists before sourcing
if [[ ! -f "${FUNCTIONS_PATH}" ]]; then
    echo "Error: Required file functions.sh not found at ${FUNCTIONS_PATH}"
    echo "Please make sure you're running this script from the correct directory"
    exit 1
fi

source "${FUNCTIONS_PATH}"

# Driver manager configuration
DRIVER_LOG="/var/log/hyprsupreme-driver-manager.log"
DRIVER_CONFIG_DIR="/etc/hyprsupreme/drivers"
BACKUP_DIR="/var/backups/hyprsupreme-drivers"

# Initialize driver manager
init_driver_manager() {
    log_info "Initializing HyprSupreme Driver Manager..."
    
    # Create necessary directories
    sudo mkdir -p "$DRIVER_CONFIG_DIR"
    sudo mkdir -p "$BACKUP_DIR"
    sudo mkdir -p "$(dirname "$DRIVER_LOG")"
    
    # Create driver log
    sudo touch "$DRIVER_LOG"
    sudo chmod 644 "$DRIVER_LOG"
    
    log_success "Driver Manager initialized"
}

# Detect GPU and install appropriate drivers
detect_and_install_gpu_drivers() {
    log_info "Detecting GPU hardware..."
    
    local gpu_info=$(lspci | grep -i "vga\|3d\|display")
    log_info "Found GPU(s): $gpu_info"
    
    if echo "$gpu_info" | grep -qi "nvidia"; then
        install_nvidia_drivers
    elif echo "$gpu_info" | grep -qi "amd\|ati"; then
        install_amd_drivers
    elif echo "$gpu_info" | grep -qi "intel"; then
        install_intel_drivers
    else
        log_warn "Unknown GPU detected, installing generic drivers"
        install_generic_gpu_drivers
    fi
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    log_info "Installing NVIDIA drivers..."
    
    local packages=(
        "nvidia-dkms"
        "nvidia-utils"
        "lib32-nvidia-utils"
        "nvidia-settings"
        "opencl-nvidia"
        "cuda-tools"
        "vulkan-headers"
        "vulkan-validation-layers"
    )
    
    # Check if proprietary drivers are already installed
    if lsmod | grep -q "nvidia"; then
        log_success "NVIDIA drivers already loaded"
        return 0
    fi
    
    install_packages "${packages[@]}"
    
    # Enable early loading of nvidia modules
    echo "nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm" | sudo tee /etc/modules-load.d/nvidia.conf > /dev/null
    
    # Configure nvidia-drm with modeset
    echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
    
    # Regenerate initramfs
    sudo mkinitcpio -P
    
    log_success "NVIDIA drivers installed successfully"
    log_warn "Reboot required to activate NVIDIA drivers"
}

# Install AMD drivers
install_amd_drivers() {
    log_info "Installing AMD drivers..."
    
    local packages=(
        "mesa"
        "lib32-mesa"
        "xf86-video-amdgpu"
        "vulkan-radeon"
        "lib32-vulkan-radeon"
        "libva-mesa-driver"
        "lib32-libva-mesa-driver"
        "mesa-vdpau"
        "lib32-mesa-vdpau"
        "opencl-mesa"
        "rocm-opencl-runtime"
    )
    
    install_packages "${packages[@]}"
    
    # Enable early loading of amdgpu
    echo "amdgpu" | sudo tee /etc/modules-load.d/amdgpu.conf > /dev/null
    
    log_success "AMD drivers installed successfully"
}

# Install Intel drivers
install_intel_drivers() {
    log_info "Installing Intel drivers..."
    
    local packages=(
        "mesa"
        "lib32-mesa"
        "intel-media-driver"
        "vulkan-intel"
        "lib32-vulkan-intel"
        "libva-intel-driver"
        "intel-gpu-tools"
    )
    
    install_packages "${packages[@]}"
    
    log_success "Intel drivers installed successfully"
}

# Install generic GPU drivers
install_generic_gpu_drivers() {
    log_info "Installing generic GPU drivers..."
    
    local packages=(
        "mesa"
        "lib32-mesa"
        "xf86-video-vesa"
    )
    
    install_packages "${packages[@]}"
    
    log_success "Generic GPU drivers installed"
}

# Detect and configure audio drivers
detect_and_install_audio_drivers() {
    log_info "Detecting audio hardware..."
    
    local audio_info=$(lspci | grep -i "audio\|sound")
    log_info "Found audio device(s): $audio_info"
    
    local packages=(
        "alsa-utils"
        "alsa-plugins"
        "pulseaudio"
        "pulseaudio-alsa"
        "pavucontrol"
        "sof-firmware"
        "alsa-firmware"
        "pipewire"
        "pipewire-alsa"
        "pipewire-pulse"
        "wireplumber"
    )
    
    install_packages "${packages[@]}"
    
    # Configure audio
    systemctl --user enable --now pipewire.service
    systemctl --user enable --now pipewire-pulse.service
    systemctl --user enable --now wireplumber.service
    
    log_success "Audio drivers and PipeWire configured"
}

# Detect and install network drivers
detect_and_install_network_drivers() {
    log_info "Detecting network hardware..."
    
    local network_info=$(lspci | grep -i "network\|ethernet\|wifi\|wireless")
    log_info "Found network device(s): $network_info"
    
    local packages=(
        "networkmanager"
        "network-manager-applet"
        "wireless_tools"
        "wpa_supplicant"
        "linux-firmware"
        "intel-ucode"
    )
    
    # Check for specific wireless chipsets
    if echo "$network_info" | grep -qi "realtek"; then
        packages+=("rtl8821ce-dkms-git" "rtw89-dkms-git")
    fi
    
    if echo "$network_info" | grep -qi "broadcom"; then
        packages+=("broadcom-wl" "broadcom-wl-dkms")
    fi
    
    if echo "$network_info" | grep -qi "intel"; then
        packages+=("iwlwifi-firmware")
    fi
    
    install_packages "${packages[@]}"
    
    # Enable NetworkManager
    enable_service "NetworkManager"
    
    log_success "Network drivers installed and configured"
}

# Detect and install Bluetooth drivers
detect_and_install_bluetooth_drivers() {
    log_info "Detecting Bluetooth hardware..."
    
    if lsusb | grep -qi "bluetooth\|0a5c\|8087"; then
        log_info "Bluetooth hardware detected"
        
        local packages=(
            "bluez"
            "bluez-utils"
            "blueman"
            "pulseaudio-bluetooth"
        )
        
        install_packages "${packages[@]}"
        
        # Enable Bluetooth service
        enable_service "bluetooth"
        
        # Auto-power on Bluetooth
        echo "AutoEnable=true" | sudo tee -a /etc/bluetooth/main.conf > /dev/null
        
        log_success "Bluetooth drivers installed and configured"
    else
        log_info "No Bluetooth hardware detected"
    fi
}

# Detect and install camera drivers
detect_and_install_camera_drivers() {
    log_info "Detecting camera hardware..."
    
    if lsusb | grep -qi "camera\|webcam\|046d"; then
        log_info "Camera hardware detected"
        
        local packages=(
            "v4l-utils"
            "guvcview"
            "cheese"
            "obs-studio"
        )
        
        install_packages "${packages[@]}"
        
        # Load UVC module
        sudo modprobe uvcvideo
        echo "uvcvideo" | sudo tee /etc/modules-load.d/camera.conf > /dev/null
        
        log_success "Camera drivers installed"
    else
        log_info "No camera hardware detected"
    fi
}

# Install printer drivers
install_printer_drivers() {
    log_info "Installing printer drivers..."
    
    local packages=(
        "cups"
        "cups-pdf"
        "system-config-printer"
        "hplip"
        "gutenprint"
        "ghostscript"
        "gsfonts"
    )
    
    install_packages "${packages[@]}"
    
    # Enable CUPS service
    enable_service "cups"
    
    # Add user to lp group
    sudo usermod -a -G lp "$USER"
    
    log_success "Printer drivers installed"
}

# Gaming hardware drivers
install_gaming_drivers() {
    log_info "Installing gaming hardware drivers..."
    
    local packages=(
        "gamemode"
        "lib32-gamemode"
        "steam"
        "lutris"
        "wine"
        "winetricks"
        "dxvk"
        "lib32-vulkan-icd-loader"
        "mangohud"
        "lib32-mangohud"
    )
    
    install_packages "${packages[@]}"
    
    # Add user to gamemode group
    sudo usermod -a -G gamemode "$USER"
    
    log_success "Gaming drivers installed"
}

# Backup current driver configuration
backup_driver_config() {
    log_info "Backing up current driver configuration..."
    
    local backup_file="$BACKUP_DIR/driver-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    sudo tar -czf "$backup_file" \
        /etc/modules-load.d/ \
        /etc/modprobe.d/ \
        /etc/X11/xorg.conf.d/ \
        2>/dev/null || true
    
    log_success "Driver configuration backed up to: $backup_file"
}

# Generate driver report
generate_driver_report() {
    log_info "Generating driver report..."
    
    local report_file="/tmp/hyprsupreme-driver-report.txt"
    
    {
        echo "HyprSupreme Driver Report - $(date)"
        echo "========================================"
        echo ""
        echo "System Information:"
        echo "- OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "- Kernel: $(uname -r)"
        echo "- Architecture: $(uname -m)"
        echo ""
        echo "Hardware Detection:"
        echo "==================="
        echo ""
        echo "GPU Information:"
        lspci | grep -i "vga\|3d\|display" || echo "No GPU detected"
        echo ""
        echo "Audio Information:"
        lspci | grep -i "audio\|sound" || echo "No audio devices detected"
        echo ""
        echo "Network Information:"
        lspci | grep -i "network\|ethernet\|wifi" || echo "No network devices detected"
        echo ""
        echo "USB Devices:"
        lsusb
        echo ""
        echo "Loaded Modules:"
        echo "==============="
        lsmod | head -20
        echo ""
        echo "Driver Status:"
        echo "=============="
        echo "Graphics: $(lsmod | grep -E '(nvidia|amdgpu|i915)' | wc -l) driver(s) loaded"
        echo "Audio: $(lsmod | grep -E '(snd_|audio)' | wc -l) driver(s) loaded"
        echo "Network: $(lsmod | grep -E '(wifi|wireless|ethernet|e1000|r8169)' | wc -l) driver(s) loaded"
        echo "Bluetooth: $(lsmod | grep bluetooth | wc -l) driver(s) loaded"
        echo "Camera: $(lsmod | grep uvcvideo | wc -l) driver(s) loaded"
    } > "$report_file"
    
    cat "$report_file"
    log_success "Driver report saved to: $report_file"
}

# Main driver installation function
install_all_drivers() {
    log_info "Starting comprehensive driver installation..."
    
    backup_driver_config
    
    detect_and_install_gpu_drivers
    detect_and_install_audio_drivers
    detect_and_install_network_drivers
    detect_and_install_bluetooth_drivers
    detect_and_install_camera_drivers
    install_printer_drivers
    
    # Install gaming drivers if requested
    if [[ "${1:-}" == "--gaming" ]]; then
        install_gaming_drivers
    fi
    
    generate_driver_report
    
    log_success "Driver installation completed!"
    log_info "Please reboot your system to ensure all drivers are properly loaded"
}

# Uninstall specific drivers
uninstall_nvidia_drivers() {
    log_info "Uninstalling NVIDIA drivers..."
    
    local packages=(
        "nvidia-dkms"
        "nvidia-utils"
        "lib32-nvidia-utils"
        "nvidia-settings"
        "opencl-nvidia"
        "cuda-tools"
    )
    
    for package in "${packages[@]}"; do
        if pacman -Qi "$package" &>/dev/null; then
            sudo pacman -Rns "$package" --noconfirm || true
        fi
    done
    
    # Remove nvidia configuration files
    sudo rm -f /etc/modules-load.d/nvidia.conf
    sudo rm -f /etc/modprobe.d/nvidia.conf
    
    # Regenerate initramfs
    sudo mkinitcpio -P
    
    log_success "NVIDIA drivers uninstalled"
    log_warn "Reboot required"
}

# Check driver status
check_driver_status() {
    log_info "Checking driver status..."
    
    echo "=== Driver Status Report ==="
    echo ""
    
    # GPU Status
    echo "GPU Drivers:"
    if lsmod | grep -q nvidia; then
        echo "  ✓ NVIDIA driver loaded"
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || true
    elif lsmod | grep -q amdgpu; then
        echo "  ✓ AMD driver loaded"
    elif lsmod | grep -q i915; then
        echo "  ✓ Intel driver loaded"
    else
        echo "  ⚠ No GPU driver detected"
    fi
    
    echo ""
    
    # Audio Status
    echo "Audio Drivers:"
    if systemctl --user is-active --quiet pipewire; then
        echo "  ✓ PipeWire running"
    elif systemctl --user is-active --quiet pulseaudio; then
        echo "  ✓ PulseAudio running"
    else
        echo "  ⚠ No audio system detected"
    fi
    
    echo ""
    
    # Network Status
    echo "Network Drivers:"
    if systemctl is-active --quiet NetworkManager; then
        echo "  ✓ NetworkManager running"
        nmcli device status | head -5
    else
        echo "  ⚠ NetworkManager not running"
    fi
    
    echo ""
    
    # Bluetooth Status
    echo "Bluetooth:"
    if systemctl is-active --quiet bluetooth; then
        echo "  ✓ Bluetooth service running"
        bluetoothctl show 2>/dev/null | grep "Powered" || true
    else
        echo "  ⚠ Bluetooth service not running"
    fi
    
    echo ""
    
    # Camera Status
    echo "Camera:"
    if v4l2-ctl --list-devices &>/dev/null; then
        echo "  ✓ Camera devices detected:"
        v4l2-ctl --list-devices | grep -E "(/dev/video|:)" | head -5
    else
        echo "  ⚠ No camera devices detected"
    fi
}

# Command line interface
case "${1:-help}" in
    "install")
        init_driver_manager
        install_all_drivers "${2:-}"
        ;;
    "install-gaming")
        init_driver_manager
        install_all_drivers "--gaming"
        ;;
    "install-gpu")
        detect_and_install_gpu_drivers
        ;;
    "install-audio")
        detect_and_install_audio_drivers
        ;;
    "install-network")
        detect_and_install_network_drivers
        ;;
    "uninstall-nvidia")
        uninstall_nvidia_drivers
        ;;
    "status")
        check_driver_status
        ;;
    "report")
        generate_driver_report
        ;;
    "backup")
        backup_driver_config
        ;;
    "help"|*)
        echo "HyprSupreme Driver Manager"
        echo "========================="
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  install           - Install all drivers automatically"
        echo "  install-gaming    - Install all drivers + gaming support"
        echo "  install-gpu       - Install GPU drivers only"
        echo "  install-audio     - Install audio drivers only"
        echo "  install-network   - Install network drivers only"
        echo "  uninstall-nvidia  - Remove NVIDIA drivers"
        echo "  status           - Check current driver status"
        echo "  report           - Generate detailed driver report"
        echo "  backup           - Backup current driver configuration"
        echo "  help             - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 install         # Install all drivers"
        echo "  $0 status          # Check driver status"
        echo "  $0 install-gaming  # Install with gaming support"
        ;;
esac

