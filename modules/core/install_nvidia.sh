#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme-Builder - NVIDIA Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_nvidia() {
    log_info "Installing NVIDIA drivers and optimizations..."
    
    # Check if NVIDIA GPU is present
    if ! is_nvidia_gpu; then
        log_warn "No NVIDIA GPU detected. Skipping NVIDIA installation."
        return 0
    fi
    
    # NVIDIA packages
    local packages=(
        "nvidia"
        "nvidia-utils"
        "nvidia-settings"
        "lib32-nvidia-utils"
        "egl-wayland"
        "libva-nvidia-driver"
    )
    
    install_packages "${packages[@]}"
    
    # Configure NVIDIA for Wayland
    configure_nvidia_wayland
    
    # Create NVIDIA environment variables
    create_nvidia_env
    
    # Configure Hyprland for NVIDIA
    configure_hyprland_nvidia
    
    log_success "NVIDIA installation and configuration completed"
    log_warn "Please reboot your system for NVIDIA changes to take effect"
}

configure_nvidia_wayland() {
    log_info "Configuring NVIDIA for Wayland..."
    
    # Enable DRM kernel mode setting
    local modprobe_file="/etc/modprobe.d/nvidia.conf"
    
    sudo tee "$modprobe_file" > /dev/null << 'EOF'
# Enable DRM kernel mode setting
options nvidia-drm modeset=1

# Enable GSP firmware (RTX 30 series and newer)
options nvidia NVreg_EnableGpuFirmware=1

# Preserve video memory allocations
options nvidia NVreg_PreserveVideoMemoryAllocations=1

# Disable logo
options nvidia NVreg_EnableMSI=1
EOF

    # Add nvidia modules to initramfs
    local mkinitcpio_file="/etc/mkinitcpio.conf"
    
    if grep -q "^MODULES=" "$mkinitcpio_file"; then
        sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkinitcpio_file"
    else
        echo "MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)" | sudo tee -a "$mkinitcpio_file"
    fi
    
    # Regenerate initramfs
    sudo mkinitcpio -P
    
    log_success "NVIDIA Wayland configuration completed"
}

create_nvidia_env() {
    log_info "Creating NVIDIA environment variables..."
    
    local env_file="$HOME/.config/hypr/nvidia.conf"
    
    cat > "$env_file" << 'EOF'
# NVIDIA Environment Variables for Hyprland
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_RENDERER_ALLOW_SOFTWARE,1
env = CLUTTER_BACKEND,wayland
env = WLR_RENDERER,vulkan

# NVIDIA-specific optimizations
env = __GL_GSYNC_ALLOWED,1
env = __GL_VRR_ALLOWED,1
env = WLR_DRM_NO_ATOMIC,1

# Electron apps
env = ELECTRON_OZONE_PLATFORM_HINT,wayland

# Firefox
env = MOZ_ENABLE_WAYLAND,1
EOF

    log_success "NVIDIA environment variables created"
}

configure_hyprland_nvidia() {
    log_info "Configuring Hyprland for NVIDIA..."
    
    local nvidia_config="$HOME/.config/hypr/nvidia-rules.conf"
    
    cat > "$nvidia_config" << 'EOF'
# Hyprland NVIDIA Optimizations

# Cursor settings for NVIDIA
cursor {
    no_hardware_cursors = true
}

# OpenGL settings
opengl {
    nvidia_anti_flicker = true
}

# Rendering settings
render {
    explicit_sync = 2
    explicit_sync_kms = 2
}

# General NVIDIA optimizations
general {
    no_cursor_warps = true
}

# Window rules for better NVIDIA performance
windowrulev2 = immediate, class:^(cs2)$
windowrulev2 = immediate, class:^(steam_app).*$
windowrulev2 = immediate, class:^(gamescope)$
windowrulev2 = immediate, class:^(obs)$
windowrulev2 = immediate, title:^(.*)(OpenGL|Vulkan|DirectX)(.*)$

# Workspace rules for gaming
workspace = special:gaming, gapsin:0, gapsout:0, rounding:false, decorate:false, shadow:false
EOF

    # Create a script to apply NVIDIA-specific settings
    local nvidia_script="$HOME/.config/hypr/scripts/nvidia-setup.sh"
    mkdir -p "$(dirname "$nvidia_script")"
    
    cat > "$nvidia_script" << 'EOF'
#!/bin/bash
# NVIDIA Setup Script for HyprSupreme

# Set NVIDIA power management
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi -pm 1 2>/dev/null
    nvidia-smi -pl 350 2>/dev/null  # Adjust power limit as needed
fi

# Enable G-SYNC if available
if command -v nvidia-settings &> /dev/null; then
    nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" 2>/dev/null
    nvidia-settings -a "[gpu:0]/GPUMemoryTransferRateOffset[3]=1000" 2>/dev/null
    nvidia-settings -a "[gpu:0]/GPUGraphicsClockOffset[3]=100" 2>/dev/null
fi
EOF

    chmod +x "$nvidia_script"
    
    log_success "Hyprland NVIDIA configuration completed"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nvidia
fi

