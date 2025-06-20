#!/bin/bash
# HyprSupreme-Builder - NVIDIA Installation Module

# Set strict error handling
set -o errexit  # Exit on error
set -o pipefail # Exit if any command in a pipe fails
set -o nounset  # Exit on undefined variables

# Define error codes
readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_PERMISSION=2
readonly E_DEPENDENCY=3
readonly E_SERVICE=4
readonly E_DIRECTORY=5
readonly E_CONFIG=6
readonly E_NVIDIA=7    # NVIDIA-specific errors
readonly E_WAYLAND=8   # Wayland-specific errors
readonly E_DRIVER=9    # Driver-specific errors
readonly E_KERNEL=10   # Kernel-related errors

# Path to the script
readonly SCRIPT_PATH="$(readlink -f "$0")"
readonly SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
readonly CONFIG_DIR="$HOME/.config/hypr"
readonly BACKUP_DIR="$HOME/.config/nvidia-backup-$(date +%Y%m%d-%H%M%S)"
readonly LOG_FILE="/tmp/nvidia-install-$(date +%Y%m%d-%H%M%S).log"

# Source common functions
if [[ ! -f "${SCRIPT_DIR}/../common/functions.sh" ]]; then
    echo "ERROR: Required file not found: ${SCRIPT_DIR}/../common/functions.sh"
    exit $E_DEPENDENCY
fi

source "${SCRIPT_DIR}/../common/functions.sh"

# Create log file
touch "$LOG_FILE" || true

# Error handling function
handle_error() {
    local exit_code=$1
    local error_message="${2:-Unknown error}"
    local error_source="${3:-$SCRIPT_PATH}"
    
    log_error "Error in $error_source: $error_message (code: $exit_code)"
    log_error "Check log file for details: $LOG_FILE"
    
    # Write error to log file
    echo "[ERROR] $(date): $error_message (code: $exit_code) in $error_source" >> "$LOG_FILE"
    
    # Return the exit code
    return $exit_code
}

# NVIDIA-specific error handler
handle_nvidia_error() {
    local error_type="$1"
    local error_message="$2"
    
    case "$error_type" in
        "driver")
            log_error "NVIDIA driver error: $error_message"
            echo "[ERROR] $(date): NVIDIA driver error: $error_message" >> "$LOG_FILE"
            return $E_DRIVER
            ;;
        "config")
            log_error "NVIDIA configuration error: $error_message"
            echo "[ERROR] $(date): NVIDIA configuration error: $error_message" >> "$LOG_FILE"
            return $E_CONFIG
            ;;
        "wayland")
            log_error "NVIDIA Wayland error: $error_message"
            echo "[ERROR] $(date): NVIDIA Wayland error: $error_message" >> "$LOG_FILE"
            return $E_WAYLAND
            ;;
        "kernel")
            log_error "Kernel configuration error: $error_message"
            echo "[ERROR] $(date): Kernel configuration error: $error_message" >> "$LOG_FILE"
            return $E_KERNEL
            ;;
        *)
            log_error "Unknown NVIDIA error: $error_message"
            echo "[ERROR] $(date): Unknown NVIDIA error: $error_message" >> "$LOG_FILE"
            return $E_NVIDIA
            ;;
    esac
}

# Trap errors
trap 'handle_error $? "Script interrupted" "$BASH_SOURCE:$LINENO"' ERR
trap 'log_warn "Script received SIGINT - operation canceled"; exit $E_GENERAL' INT
trap 'log_warn "Script received SIGTERM - operation canceled"; exit $E_GENERAL' TERM

detect_nvidia_gpu() {
    log_info "Detecting NVIDIA GPU..."
    
    # Check using lspci
    if lspci | grep -qi "NVIDIA"; then
        local gpu_info=$(lspci | grep -i "NVIDIA" | head -1)
        log_success "NVIDIA GPU detected: $gpu_info"
        echo "[INFO] $(date): NVIDIA GPU detected: $gpu_info" >> "$LOG_FILE"
        
        # Get more detailed info if nvidia-smi is available
        if command -v nvidia-smi &> /dev/null; then
            local gpu_model=$(nvidia-smi --query-gpu=name --format=csv,noheader)
            local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
            log_info "GPU Model: $gpu_model"
            log_info "Driver Version: $driver_version"
            echo "[INFO] $(date): GPU Model: $gpu_model, Driver Version: $driver_version" >> "$LOG_FILE"
        fi
        
        return 0
    else
        log_warn "No NVIDIA GPU detected in system"
        echo "[WARN] $(date): No NVIDIA GPU detected in system" >> "$LOG_FILE"
        return 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies for NVIDIA installation..."
    
    # Check for required packages
    local required_deps=(
        "linux-headers"    # Kernel headers for driver compilation
        "dkms"             # Dynamic Kernel Module Support
        "mesa"             # OpenGL implementation
        "xorg-server"      # X server
    )
    
    local missing_deps=()
    
    for dep in "${required_deps[@]}"; do
        if ! pacman -Q "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing_deps[*]}"
        log_info "Installing missing dependencies..."
        if ! install_packages "${missing_deps[@]}"; then
            log_error "Failed to install dependencies"
            return $E_DEPENDENCY
        fi
    fi
    
    # Check kernel version
    local kernel_version=$(uname -r)
    log_info "Current kernel version: $kernel_version"
    echo "[INFO] $(date): Current kernel version: $kernel_version" >> "$LOG_FILE"
    
    # Check for linux-headers matching current kernel
    local kernel_name=$(echo "$kernel_version" | cut -d'-' -f1)
    if ! pacman -Q "linux-headers" &> /dev/null && ! pacman -Q "${kernel_name}-headers" &> /dev/null; then
        log_warn "Kernel headers not found for $kernel_version"
        log_info "Installing kernel headers..."
        if ! install_packages "linux-headers"; then
            log_error "Failed to install kernel headers"
            return $E_DEPENDENCY
        fi
    fi
    
    return $E_SUCCESS
}

backup_existing_config() {
    log_info "Backing up existing NVIDIA configuration..."
    
    # Create backup directory
    if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
        log_error "Failed to create backup directory: $BACKUP_DIR"
        return $E_DIRECTORY
    fi
    
    # Back up existing NVIDIA configuration files
    if [[ -f "/etc/modprobe.d/nvidia.conf" ]]; then
        if ! sudo cp "/etc/modprobe.d/nvidia.conf" "$BACKUP_DIR/" 2>/dev/null; then
            log_warn "Failed to backup /etc/modprobe.d/nvidia.conf"
        else
            log_info "Backed up /etc/modprobe.d/nvidia.conf"
        fi
    fi
    
    # Back up mkinitcpio.conf
    if [[ -f "/etc/mkinitcpio.conf" ]]; then
        if ! sudo cp "/etc/mkinitcpio.conf" "$BACKUP_DIR/" 2>/dev/null; then
            log_warn "Failed to backup /etc/mkinitcpio.conf"
        else
            log_info "Backed up /etc/mkinitcpio.conf"
        fi
    fi
    
    # Back up Hyprland config if it exists
    if [[ -d "$CONFIG_DIR" ]]; then
        # Create config backup dir
        mkdir -p "$BACKUP_DIR/hypr" 2>/dev/null
        
        # Copy relevant configuration files
        for config_file in "$CONFIG_DIR/nvidia.conf" "$CONFIG_DIR/nvidia-rules.conf"; do
            if [[ -f "$config_file" ]]; then
                if ! cp "$config_file" "$BACKUP_DIR/hypr/" 2>/dev/null; then
                    log_warn "Failed to backup $config_file"
                else
                    log_info "Backed up $config_file"
                fi
            fi
        done
    fi
    
    log_success "Configuration backup completed to $BACKUP_DIR"
    echo "[INFO] $(date): Configuration backup completed to $BACKUP_DIR" >> "$LOG_FILE"
    
    return $E_SUCCESS
}

restore_config() {
    local backup_path="$1"
    
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup directory not found: $backup_path"
        return $E_DIRECTORY
    fi
    
    log_info "Restoring NVIDIA configuration from backup..."
    
    # Restore modprobe config
    if [[ -f "$backup_path/nvidia.conf" ]]; then
        if ! sudo cp "$backup_path/nvidia.conf" "/etc/modprobe.d/nvidia.conf" 2>/dev/null; then
            log_error "Failed to restore /etc/modprobe.d/nvidia.conf"
            return $E_GENERAL
        fi
        log_info "Restored /etc/modprobe.d/nvidia.conf"
    fi
    
    # Restore mkinitcpio.conf
    if [[ -f "$backup_path/mkinitcpio.conf" ]]; then
        if ! sudo cp "$backup_path/mkinitcpio.conf" "/etc/mkinitcpio.conf" 2>/dev/null; then
            log_error "Failed to restore /etc/mkinitcpio.conf"
            return $E_GENERAL
        fi
        log_info "Restored /etc/mkinitcpio.conf"
        
        # Regenerate initramfs
        sudo mkinitcpio -P || log_warn "Failed to regenerate initramfs"
    fi
    
    # Restore Hyprland config
    if [[ -d "$backup_path/hypr" ]]; then
        for config_file in "$backup_path/hypr/"*; do
            if [[ -f "$config_file" ]]; then
                local dest_file="$CONFIG_DIR/$(basename "$config_file")"
                if ! cp "$config_file" "$dest_file" 2>/dev/null; then
                    log_warn "Failed to restore $(basename "$config_file")"
                else
                    log_info "Restored $(basename "$config_file")"
                fi
            fi
        done
    fi
    
    log_success "Configuration restore completed from $backup_path"
    return $E_SUCCESS
}

check_wayland_compatibility() {
    log_info "Checking NVIDIA Wayland compatibility..."
    
    # Check for minimum driver version for Wayland support (470.x+)
    if command -v nvidia-smi &> /dev/null; then
        local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | cut -d'.' -f1)
        if [[ -n "$driver_version" && "$driver_version" -lt 470 ]]; then
            log_warn "NVIDIA driver version $driver_version detected - Wayland requires 470.x or newer"
            echo "[WARN] $(date): NVIDIA driver version $driver_version is below recommended minimum for Wayland" >> "$LOG_FILE"
            return 1
        else
            log_success "NVIDIA driver version $driver_version is compatible with Wayland"
            echo "[INFO] $(date): NVIDIA driver version $driver_version is compatible with Wayland" >> "$LOG_FILE"
        fi
    else
        log_warn "Unable to determine NVIDIA driver version"
        echo "[WARN] $(date): Unable to determine NVIDIA driver version" >> "$LOG_FILE"
        return 1
    fi
    
    # Check for egl-wayland package
    if ! pacman -Q "egl-wayland" &> /dev/null; then
        log_warn "egl-wayland package not installed - required for NVIDIA Wayland support"
        return 1
    fi
    
    return 0
}

install_nvidia() {
    log_info "Installing NVIDIA drivers and optimizations..."
    echo "[INFO] $(date): Starting NVIDIA installation" >> "$LOG_FILE"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        return $E_PERMISSION
    fi
    
    # Check for essential dependencies
    if ! command -v pacman &> /dev/null; then
        log_error "Package manager not found (pacman is required)"
        return $E_DEPENDENCY
    fi
    
    # Check if NVIDIA GPU is present
    if ! detect_nvidia_gpu; then
        log_warn "No NVIDIA GPU detected. Skipping NVIDIA installation."
        return $E_SUCCESS
    fi
    
    # Check and install dependencies
    if ! check_dependencies; then
        log_error "Failed to check/install dependencies"
        return $E_DEPENDENCY
    fi
    
    # Backup existing configuration
    backup_existing_config
    
    # NVIDIA packages
    local packages=(
        # Core NVIDIA packages
        "nvidia"
        "nvidia-utils"
        "nvidia-settings"
        "lib32-nvidia-utils"  # 32-bit support
        
        # Wayland support
        "egl-wayland"
        "libva-nvidia-driver"
        
        # Additional utilities
        "nvidia-prime"        # GPU switching support
        "vulkan-icd-loader"   # Vulkan support
        "opencl-nvidia"       # OpenCL support
    )
    
    log_info "Installing NVIDIA packages..."
    echo "[INFO] $(date): Installing NVIDIA packages: ${packages[*]}" >> "$LOG_FILE"
    
    # Install packages with error handling
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install NVIDIA packages"
        echo "[ERROR] $(date): Failed to install NVIDIA packages" >> "$LOG_FILE"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v nvidia-smi &> /dev/null; then
        log_error "NVIDIA installation failed: nvidia-smi command not found"
        echo "[ERROR] $(date): NVIDIA installation failed: nvidia-smi command not found" >> "$LOG_FILE"
        return $E_DEPENDENCY
    fi
    
    # Configure NVIDIA for Wayland
    if ! configure_nvidia_wayland; then
        log_error "Failed to configure NVIDIA for Wayland"
        echo "[ERROR] $(date): Failed to configure NVIDIA for Wayland" >> "$LOG_FILE"
        return $E_CONFIG
    fi
    
    # Create NVIDIA environment variables
    if ! create_nvidia_env; then
        log_error "Failed to create NVIDIA environment variables"
        echo "[ERROR] $(date): Failed to create NVIDIA environment variables" >> "$LOG_FILE"
        return $E_CONFIG
    fi
    
    # Configure Hyprland for NVIDIA
    if ! configure_hyprland_nvidia; then
        log_error "Failed to configure Hyprland for NVIDIA"
        echo "[ERROR] $(date): Failed to configure Hyprland for NVIDIA" >> "$LOG_FILE"
        return $E_CONFIG
    fi
    
    # Check Wayland compatibility
    check_wayland_compatibility
    
    log_success "NVIDIA installation and configuration completed"
    log_warn "Please reboot your system for NVIDIA changes to take effect"
    echo "[SUCCESS] $(date): NVIDIA installation and configuration completed" >> "$LOG_FILE"
    
    return $E_SUCCESS
}

configure_nvidia_wayland() {
    log_info "Configuring NVIDIA for Wayland..."
    echo "[INFO] $(date): Configuring NVIDIA for Wayland" >> "$LOG_FILE"
    
    # Check if we have sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to configure NVIDIA"
        # Continue anyway, will prompt for password
    fi
    
    # Create modprobe directory if it doesn't exist
    if ! sudo test -d "/etc/modprobe.d" 2>/dev/null; then
        log_info "Creating modprobe.d directory..."
        if ! sudo mkdir -p "/etc/modprobe.d" 2>/dev/null; then
            handle_nvidia_error "config" "Failed to create modprobe.d directory"
            return $E_DIRECTORY
        fi
    fi
    
    # Enable DRM kernel mode setting
    local modprobe_file="/etc/modprobe.d/nvidia.conf"
    log_info "Creating NVIDIA modprobe configuration: $modprobe_file"
    
    if ! sudo tee "$modprobe_file" > /dev/null << 'EOF'
# Enable DRM kernel mode setting
options nvidia-drm modeset=1

# Enable GSP firmware (RTX 30 series and newer)
options nvidia NVreg_EnableGpuFirmware=1

# Preserve video memory allocations
options nvidia NVreg_PreserveVideoMemoryAllocations=1

# Disable logo
options nvidia NVreg_EnableMSI=1

# Power management options
options nvidia NVreg_DynamicPowerManagement=0x02

# Frame pacing for smoother gameplay
options nvidia NVreg_UsePageAttributeTable=1
EOF
    then
        handle_nvidia_error "config" "Failed to create NVIDIA modprobe configuration"
        return $E_CONFIG
    fi
    
    # Verify modprobe configuration
    if ! sudo test -f "$modprobe_file" 2>/dev/null; then
        handle_nvidia_error "config" "NVIDIA modprobe configuration file not created"
        return $E_CONFIG
    fi
    
    # Add nvidia modules to initramfs
    local mkinitcpio_file="/etc/mkinitcpio.conf"
    
    # Check if mkinitcpio.conf exists
    if ! sudo test -f "$mkinitcpio_file" 2>/dev/null; then
        log_warn "mkinitcpio.conf not found, this may not be a mkinitcpio-based system"
        echo "[WARN] $(date): mkinitcpio.conf not found at $mkinitcpio_file" >> "$LOG_FILE"
        # Skip this step but continue with the rest
    else
        log_info "Adding NVIDIA modules to initramfs..."
        
        # Backup original mkinitcpio.conf if not already backed up
        if [[ ! -f "$BACKUP_DIR/mkinitcpio.conf" ]]; then
            sudo cp "$mkinitcpio_file" "$BACKUP_DIR/mkinitcpio.conf" 2>/dev/null || true
        fi
        
        # Add NVIDIA modules to mkinitcpio.conf
        if grep -q "^MODULES=" "$mkinitcpio_file"; then
            # Check if nvidia modules are already in the MODULES array
            if ! grep -q "nvidia_drm" "$mkinitcpio_file"; then
                if ! sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkinitcpio_file"; then
                    handle_nvidia_error "config" "Failed to update MODULES in mkinitcpio.conf"
                    return $E_CONFIG
                fi
            else
                log_info "NVIDIA modules already in mkinitcpio.conf"
            fi
        else
            if ! echo "MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)" | sudo tee -a "$mkinitcpio_file" > /dev/null; then
                handle_nvidia_error "config" "Failed to add MODULES to mkinitcpio.conf"
                return $E_CONFIG
            fi
        fi
        
        # Regenerate initramfs
        log_info "Regenerating initramfs..."
        if ! sudo mkinitcpio -P; then
            handle_nvidia_error "kernel" "Failed to regenerate initramfs"
            return $E_KERNEL
        fi
    fi
    
    # Ensure NVIDIA modules are loaded
    log_info "Loading NVIDIA kernel modules..."
    if ! sudo modprobe -a nvidia nvidia_modeset nvidia_uvm nvidia_drm 2>/dev/null; then
        log_warn "Failed to load NVIDIA modules - they will be loaded on next boot"
        echo "[WARN] $(date): Failed to load NVIDIA modules - they will be loaded on next boot" >> "$LOG_FILE"
        # Continue anyway - modules will be loaded on next boot
    fi
    
    # Create blacklist file for nouveau
    local blacklist_file="/etc/modprobe.d/blacklist-nouveau.conf"
    log_info "Blacklisting nouveau driver..."
    
    if ! sudo tee "$blacklist_file" > /dev/null << 'EOF'
# Blacklist nouveau driver to avoid conflicts
blacklist nouveau
options nouveau modeset=0
EOF
    then
        log_warn "Failed to create nouveau blacklist file"
        echo "[WARN] $(date): Failed to create nouveau blacklist file" >> "$LOG_FILE"
        # Continue anyway
    fi
    
    log_success "NVIDIA Wayland configuration completed"
    echo "[SUCCESS] $(date): NVIDIA Wayland configuration completed" >> "$LOG_FILE"
    return $E_SUCCESS
}

create_nvidia_env() {
    log_info "Creating NVIDIA environment variables..."
    echo "[INFO] $(date): Creating NVIDIA environment variables" >> "$LOG_FILE"
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$CONFIG_DIR" ]]; then
        log_info "Creating Hyprland config directory..."
        if ! mkdir -p "$CONFIG_DIR" 2>/dev/null; then
            handle_nvidia_error "config" "Failed to create Hyprland config directory"
            return $E_DIRECTORY
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$CONFIG_DIR" ]]; then
        handle_nvidia_error "config" "No write permission for Hyprland config directory"
        return $E_PERMISSION
    fi
    
    local env_file="$CONFIG_DIR/nvidia.conf"
    
    # Backup existing file if it exists
    if [[ -f "$env_file" ]]; then
        log_info "Backing up existing NVIDIA environment file..."
        cp "$env_file" "$env_file.backup-$(date +%Y%m%d)" 2>/dev/null || true
    fi
    
    log_info "Writing NVIDIA environment variables to $env_file"
    
    if ! cat > "$env_file" << 'EOF'
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
env = __GL_MaxFramesAllowed,1
env = LIBVA_DRIVER_NAME,nvidia
env = __GL_SYNC_TO_VBLANK,0

# Electron apps
env = ELECTRON_OZONE_PLATFORM_HINT,wayland

# Firefox
env = MOZ_ENABLE_WAYLAND,1

# QT/GTK
env = QT_QPA_PLATFORM,wayland
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_BACKEND,wayland,x11
EOF
    then
        handle_nvidia_error "config" "Failed to create NVIDIA environment variables file"
        return $E_CONFIG
    fi
    
    # Verify file was created
    if [[ ! -f "$env_file" ]]; then
        handle_nvidia_error "config" "NVIDIA environment variables file not created"
        return $E_CONFIG
    fi
    
    # Update hyprland.conf to include nvidia.conf if it exists
    local hyprland_conf="$CONFIG_DIR/hyprland.conf"
    if [[ -f "$hyprland_conf" ]]; then
        log_info "Updating Hyprland configuration to include NVIDIA settings..."
        
        # Check if the file already includes nvidia.conf
        if ! grep -q "source = ./nvidia.conf" "$hyprland_conf"; then
            # Add include line at the top of the file
            if ! sed -i '1s/^/source = ~\/.config\/hypr\/nvidia.conf\n/' "$hyprland_conf"; then
                log_warn "Failed to update Hyprland configuration to include NVIDIA settings"
                echo "[WARN] $(date): Failed to update Hyprland configuration to include NVIDIA settings" >> "$LOG_FILE"
                # Continue anyway
            fi
        else
            log_info "Hyprland configuration already includes NVIDIA settings"
        fi
    fi
    
    log_success "NVIDIA environment variables created"
    echo "[SUCCESS] $(date): NVIDIA environment variables created" >> "$LOG_FILE"
    return $E_SUCCESS
}

configure_hyprland_nvidia() {
    log_info "Configuring Hyprland for NVIDIA..."
    echo "[INFO] $(date): Configuring Hyprland for NVIDIA" >> "$LOG_FILE"
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$CONFIG_DIR" ]]; then
        log_info "Creating Hyprland config directory..."
        if ! mkdir -p "$CONFIG_DIR" 2>/dev/null; then
            handle_nvidia_error "config" "Failed to create Hyprland config directory"
            return $E_DIRECTORY
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$CONFIG_DIR" ]]; then
        handle_nvidia_error "config" "No write permission for Hyprland config directory"
        return $E_PERMISSION
    fi
    
    local nvidia_config="$CONFIG_DIR/nvidia-rules.conf"
    
    # Backup existing file if it exists
    if [[ -f "$nvidia_config" ]]; then
        log_info "Backing up existing NVIDIA rules file..."
        cp "$nvidia_config" "$nvidia_config.backup-$(date +%Y%m%d)" 2>/dev/null || true
    fi
    
    log_info "Writing NVIDIA optimization rules to $nvidia_config"
    
    if ! cat > "$nvidia_config" << 'EOF'
# Hyprland NVIDIA Optimizations

# Cursor settings for NVIDIA
cursor {
    no_hardware_cursors = true
}

# OpenGL settings
opengl {
    nvidia_anti_flicker = true
    force_intrinsic_sync = 1
}

# Rendering settings
render {
    explicit_sync = 2
    explicit_sync_kms = 2
    use_frame_pacing = 1
    vfr_throttle_nanoseconds = 2000
    max_fps = 240
}

# General NVIDIA optimizations
general {
    no_cursor_warps = true
    allow_tearing = 1
    no_vfr = true
}

# Window rules for better NVIDIA performance
windowrulev2 = immediate, class:^(cs2)$
windowrulev2 = immediate, class:^(steam_app).*$
windowrulev2 = immediate, class:^(gamescope)$
windowrulev2 = immediate, class:^(obs)$
windowrulev2 = immediate, title:^(.*)(OpenGL|Vulkan|DirectX)(.*)$

# Workspace rules for gaming
workspace = special:gaming, gapsin:0, gapsout:0, rounding:false, decorate:false, shadow:false, border:0
EOF
    then
        handle_nvidia_error "config" "Failed to create NVIDIA rules configuration"
        return $E_CONFIG
    fi
    
    # Verify file was created
    if [[ ! -f "$nvidia_config" ]]; then
        handle_nvidia_error "config" "NVIDIA rules file not created"
        return $E_CONFIG
    fi
    
    # Update hyprland.conf to include nvidia-rules.conf if it exists
    local hyprland_conf="$CONFIG_DIR/hyprland.conf"
    if [[ -f "$hyprland_conf" ]]; then
        log_info "Updating Hyprland configuration to include NVIDIA rules..."
        
        # Check if the file already includes nvidia-rules.conf
        if ! grep -q "source = ./nvidia-rules.conf" "$hyprland_conf"; then
            # Add include line after the nvidia.conf include or at the top of the file
            if grep -q "source = ./nvidia.conf" "$hyprland_conf"; then
                if ! sed -i '/source = .*nvidia.conf/a source = ~\/.config\/hypr\/nvidia-rules.conf' "$hyprland_conf"; then
                    log_warn "Failed to update Hyprland configuration to include NVIDIA rules"
                    echo "[WARN] $(date): Failed to update Hyprland configuration to include NVIDIA rules" >> "$LOG_FILE"
                    # Continue anyway
                fi
            else
                if ! sed -i '1s/^/source = ~\/.config\/hypr\/nvidia-rules.conf\n/' "$hyprland_conf"; then
                    log_warn "Failed to update Hyprland configuration to include NVIDIA rules"
                    echo "[WARN] $(date): Failed to update Hyprland configuration to include NVIDIA rules" >> "$LOG_FILE"
                    # Continue anyway
                fi
            fi
        else
            log_info "Hyprland configuration already includes NVIDIA rules"
        fi
    fi
    
    # Create scripts directory if it doesn't exist
    local scripts_dir="$CONFIG_DIR/scripts"
    if [[ ! -d "$scripts_dir" ]]; then
        log_info "Creating scripts directory..."
        if ! mkdir -p "$scripts_dir" 2>/dev/null; then
            handle_nvidia_error "config" "Failed to create scripts directory"
            return $E_DIRECTORY
        fi
    fi
    
    # Create a script to apply NVIDIA-specific settings
    local nvidia_script="$scripts_dir/nvidia-setup.sh"
    
    log_info "Creating NVIDIA setup script at $nvidia_script"
    
    if ! cat > "$nvidia_script" << 'EOF'
#!/bin/bash
# NVIDIA Setup Script for HyprSupreme

# Log file for diagnostic information
LOG_FILE="/tmp/nvidia-setup-$(date +%Y%m%d).log"
touch "$LOG_FILE"

echo "$(date): Starting NVIDIA setup script" >> "$LOG_FILE"

# Check if we have sudo rights
if sudo -n true 2>/dev/null; then
    echo "$(date): Sudo access available without password" >> "$LOG_FILE"
else
    echo "$(date): Sudo may require password for some operations" >> "$LOG_FILE"
fi

# Load NVIDIA kernel modules if not loaded
if ! lsmod | grep -q nvidia; then
    echo "$(date): Loading NVIDIA kernel modules" >> "$LOG_FILE"
    sudo modprobe -a nvidia nvidia_modeset nvidia_uvm nvidia_drm &>> "$LOG_FILE"
fi

# Set NVIDIA power management
if command -v nvidia-smi &> /dev/null; then
    echo "$(date): Setting NVIDIA power management" >> "$LOG_FILE"
    
    # Set persistence mode
    sudo nvidia-smi -pm 1 &>> "$LOG_FILE"
    
    # Detect GPU model to set appropriate power limit
    GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader)
    echo "$(date): Detected GPU: $GPU_MODEL" >> "$LOG_FILE"
    
    # Adjust power limit based on GPU model
    if [[ "$GPU_MODEL" == *"3090"* ]]; then
        POWER_LIMIT=350
    elif [[ "$GPU_MODEL" == *"3080"* ]]; then
        POWER_LIMIT=320
    elif [[ "$GPU_MODEL" == *"3070"* ]]; then
        POWER_LIMIT=220
    elif [[ "$GPU_MODEL" == *"3060"* ]]; then
        POWER_LIMIT=170
    elif [[ "$GPU_MODEL" == *"4090"* ]]; then
        POWER_LIMIT=450
    elif [[ "$GPU_MODEL" == *"4080"* ]]; then
        POWER_LIMIT=320
    elif [[ "$GPU_MODEL" == *"4070"* ]]; then
        POWER_LIMIT=200
    elif [[ "$GPU_MODEL" == *"4060"* ]]; then
        POWER_LIMIT=170
    else
        # Default fallback
        POWER_LIMIT=250
    fi
    
    echo "$(date): Setting power limit to $POWER_LIMIT W" >> "$LOG_FILE"
    sudo nvidia-smi -pl $POWER_LIMIT &>> "$LOG_FILE"
    
    # Set performance level
    sudo nvidia-smi --auto-boost-default=0 &>> "$LOG_FILE" || true
    
    # Set graphics clock
    sudo nvidia-smi --lock-gpu-clocks=1200,1800 &>> "$LOG_FILE" || true
fi

# Enable G-SYNC if available
if command -v nvidia-settings &> /dev/null; then
    echo "$(date): Configuring NVIDIA settings" >> "$LOG_FILE"
    
    # Create NVIDIA settings directory if it doesn't exist
    mkdir -p "$HOME/.config/nvidia" &>> "$LOG_FILE"
    
    # Set power mizer mode to maximum performance
    nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" &>> "$LOG_FILE"
    
    # Enable G-SYNC if available
    nvidia-settings -a "AllowGSYNCCompatible=1" &>> "$LOG_FILE" || true
    
    # Set preferred refresh rate
    nvidia-settings -a "[gpu:0]/RefreshRateOverrideHint=2" &>> "$LOG_FILE" || true
    
    # Check if we're running in Wayland
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        echo "$(date): Running in Wayland session" >> "$LOG_FILE"
        
        # Enable DRM modeset if not already enabled
        if ! grep -q "options nvidia-drm modeset=1" /etc/modprobe.d/nvidia.conf 2>/dev/null; then
            echo "$(date): DRM modeset not enabled in modprobe config, may need to update configuration" >> "$LOG_FILE"
        fi
    fi
fi

echo "$(date): NVIDIA setup script completed" >> "$LOG_FILE"
EOF
    then
        handle_nvidia_error "config" "Failed to create NVIDIA setup script"
        return $E_CONFIG
    fi
    
    # Make script executable
    log_info "Making NVIDIA setup script executable..."
    if ! chmod +x "$nvidia_script" 2>/dev/null; then
        handle_nvidia_error "config" "Failed to make NVIDIA setup script executable"
        return $E_PERMISSION
    fi
    
    # Update hyprland.conf to execute the NVIDIA setup script at startup if it exists
    if [[ -f "$hyprland_conf" ]]; then
        log_info "Updating Hyprland configuration to run NVIDIA setup script at startup..."
        
        # Check if the script is already in the autostart
        if ! grep -q "exec-once = .*nvidia-setup.sh" "$hyprland_conf"; then
            # Add the script to exec-once section or add a new exec-once line
            if grep -q "^exec-once = " "$hyprland_conf"; then
                # Append after the first exec-once line
                if ! sed -i '/^exec-once = /a exec-once = ~/.config/hypr/scripts/nvidia-setup.sh' "$hyprland_conf"; then
                    log_warn "Failed to add NVIDIA setup script to Hyprland autostart"
                    echo "[WARN] $(date): Failed to add NVIDIA setup script to Hyprland autostart" >> "$LOG_FILE"
                    # Continue anyway
                fi
            else
                # Add as a new exec-once line
                if ! echo "exec-once = ~/.config/hypr/scripts/nvidia-setup.sh" >> "$hyprland_conf"; then
                    log_warn "Failed to add NVIDIA setup script to Hyprland configuration"
                    echo "[WARN] $(date): Failed to add NVIDIA setup script to Hyprland configuration" >> "$LOG_FILE"
                    # Continue anyway
                fi
            fi
        else
            log_info "NVIDIA setup script already in Hyprland autostart"
        fi
    fi
    
    log_success "Hyprland NVIDIA configuration completed"
    echo "[SUCCESS] $(date): Hyprland NVIDIA configuration completed" >> "$LOG_FILE"
    return $E_SUCCESS
}

test_nvidia_installation() {
    log_info "Testing NVIDIA installation..."
    echo "[INFO] $(date): Testing NVIDIA installation" >> "$LOG_FILE"
    
    local errors=0
    local warnings=0
    
    # Check if NVIDIA GPU is detected
    if lspci | grep -qi "NVIDIA"; then
        log_success "✅ NVIDIA GPU detected"
        
        # Get detailed GPU info
        local gpu_info=$(lspci | grep -i "NVIDIA" | head -1)
        log_info "GPU detected: $gpu_info"
    else
        log_error "❌ No NVIDIA GPU detected in system"
        ((errors++))
        # No point continuing other tests if no GPU is found
        log_error "NVIDIA installation test failed: No NVIDIA GPU detected"
        echo "[ERROR] $(date): NVIDIA installation test failed: No NVIDIA GPU detected" >> "$LOG_FILE"
        return $E_NVIDIA
    fi
    
    # Check if NVIDIA driver is installed
    if command -v nvidia-smi &> /dev/null; then
        log_success "✅ NVIDIA driver is installed"
        
        # Get driver version
        local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null)
        if [[ -n "$driver_version" ]]; then
            log_success "✅ NVIDIA driver version: $driver_version"
            
            # Check if driver version is compatible with Wayland (470.x+)
            local major_version=$(echo "$driver_version" | cut -d'.' -f1)
            if [[ "$major_version" -lt 470 ]]; then
                log_warn "⚠️  NVIDIA driver version $major_version is below recommended minimum (470+) for Wayland"
                ((warnings++))
            else
                log_success "✅ NVIDIA driver version is compatible with Wayland"
            fi
        else
            log_warn "⚠️  Could not determine NVIDIA driver version"
            ((warnings++))
        fi
        
        # Check if NVIDIA GPU is accessible
        if nvidia-smi -L &> /dev/null; then
            log_success "✅ NVIDIA GPU is accessible by driver"
            
            # Get GPU model
            local gpu_model=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
            if [[ -n "$gpu_model" ]]; then
                log_success "✅ GPU model: $gpu_model"
            else
                log_warn "⚠️  Could not determine GPU model"
                ((warnings++))
            fi
        else
            log_error "❌ NVIDIA GPU is not accessible by driver"
            ((errors++))
        fi
    else
        log_error "❌ NVIDIA driver is not installed (nvidia-smi not found)"
        ((errors++))
    fi
    
    # Check if NVIDIA kernel modules are loaded
    if lsmod | grep -q "nvidia"; then
        log_success "✅ NVIDIA kernel modules are loaded"
        
        # Check all required modules
        local required_modules=("nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm")
        for module in "${required_modules[@]}"; do
            if lsmod | grep -q "$module"; then
                log_success "✅ Kernel module $module is loaded"
            else
                log_warn "⚠️  Kernel module $module is not loaded"
                ((warnings++))
            fi
        done
    else
        log_error "❌ NVIDIA kernel modules are not loaded"
        ((errors++))
    fi
    
    # Check if DRM modeset is enabled
    if [[ -f "/etc/modprobe.d/nvidia.conf" ]]; then
        if grep -q "options nvidia-drm modeset=1" "/etc/modprobe.d/nvidia.conf"; then
            log_success "✅ DRM modeset is enabled in NVIDIA configuration"
        else
            log_warn "⚠️  DRM modeset is not enabled in NVIDIA configuration"
            ((warnings++))
        fi
    else
        log_warn "⚠️  NVIDIA modprobe configuration file not found"
        ((warnings++))
    fi
    
    # Check Hyprland configuration
    if [[ -d "$CONFIG_DIR" ]]; then
        # Check if nvidia.conf exists
        if [[ -f "$CONFIG_DIR/nvidia.conf" ]]; then
            log_success "✅ NVIDIA environment configuration exists"
        else
            log_error "❌ NVIDIA environment configuration file is missing"
            ((errors++))
        fi
        
        # Check if nvidia-rules.conf exists
        if [[ -f "$CONFIG_DIR/nvidia-rules.conf" ]]; then
            log_success "✅ NVIDIA rules configuration exists"
        else
            log_error "❌ NVIDIA rules configuration file is missing"
            ((errors++))
        fi
        
        # Check if NVIDIA setup script exists
        if [[ -x "$CONFIG_DIR/scripts/nvidia-setup.sh" ]]; then
            log_success "✅ NVIDIA setup script exists and is executable"
        elif [[ -f "$CONFIG_DIR/scripts/nvidia-setup.sh" ]]; then
            log_warn "⚠️  NVIDIA setup script exists but is not executable"
            ((warnings++))
        else
            log_error "❌ NVIDIA setup script is missing"
            ((errors++))
        fi
        
        # Check if hyprland.conf includes NVIDIA configurations
        if [[ -f "$CONFIG_DIR/hyprland.conf" ]]; then
            if grep -q "nvidia.conf" "$CONFIG_DIR/hyprland.conf" && grep -q "nvidia-rules.conf" "$CONFIG_DIR/hyprland.conf"; then
                log_success "✅ Hyprland configuration includes NVIDIA settings"
            else
                log_warn "⚠️  Hyprland configuration may not include NVIDIA settings"
                ((warnings++))
            fi
        else
            log_warn "⚠️  Hyprland configuration file not found"
            ((warnings++))
        fi
    else
        log_warn "⚠️  Hyprland configuration directory not found"
        ((warnings++))
    fi
    
    # Check for common NVIDIA issues
    if [[ -f "/var/log/Xorg.0.log" ]]; then
        if grep -q "NVIDIA(GPU-0): Failed to initialize the NVIDIA GPU" "/var/log/Xorg.0.log"; then
            log_warn "⚠️  Detected NVIDIA GPU initialization issue in X logs"
            ((warnings++))
        fi
    fi
    
    # Check if blacklist-nouveau.conf exists
    if [[ -f "/etc/modprobe.d/blacklist-nouveau.conf" ]]; then
        log_success "✅ Nouveau driver is blacklisted"
    else
        log_warn "⚠️  Nouveau driver is not blacklisted"
        ((warnings++))
    fi
    
    # Check if NVIDIA packages are installed
    local nvidia_packages=("nvidia" "nvidia-utils" "nvidia-settings" "egl-wayland")
    for pkg in "${nvidia_packages[@]}"; do
        if pacman -Q "$pkg" &> /dev/null; then
            log_success "✅ Package $pkg is installed"
        else
            log_error "❌ Essential package $pkg is missing"
            ((errors++))
        fi
    done
    
    # Report summary
    if [[ $errors -gt 0 ]]; then
        log_error "NVIDIA installation test completed with $errors errors and $warnings warnings"
        echo "[ERROR] $(date): NVIDIA installation test completed with $errors errors and $warnings warnings" >> "$LOG_FILE"
        return $E_GENERAL
    elif [[ $warnings -gt 0 ]]; then
        log_warn "NVIDIA installation test completed with $warnings warnings"
        echo "[WARN] $(date): NVIDIA installation test completed with $warnings warnings" >> "$LOG_FILE"
        return $E_SUCCESS
    else
        log_success "NVIDIA installation test completed successfully"
        echo "[SUCCESS] $(date): NVIDIA installation test completed successfully" >> "$LOG_FILE"
        return $E_SUCCESS
    fi
}

rollback_installation() {
    local backup_path="${1:-$BACKUP_DIR}"
    
    log_info "Rolling back NVIDIA installation..."
    echo "[INFO] $(date): Rolling back NVIDIA installation" >> "$LOG_FILE"
    
    # Check if backup path exists
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup directory not found: $backup_path"
        echo "[ERROR] $(date): Rollback failed - Backup directory not found: $backup_path" >> "$LOG_FILE"
        return $E_DIRECTORY
    fi
    
    # Restore configuration files
    log_info "Restoring configuration from backup..."
    if ! restore_config "$backup_path"; then
        log_error "Failed to restore configuration"
        echo "[ERROR] $(date): Rollback failed - Failed to restore configuration" >> "$LOG_FILE"
        return $E_GENERAL
    fi
    
    log_info "Attempting to unload NVIDIA kernel modules..."
    # Try to unload NVIDIA modules in the correct order
    sudo rmmod nvidia_drm nvidia_modeset nvidia_uvm nvidia 2>/dev/null || true
    
    log_success "Rollback completed"
    echo "[SUCCESS] $(date): Rollback completed" >> "$LOG_FILE"
    log_warn "You may need to reboot your system for changes to take effect"
    
    return $E_SUCCESS
}

# Verify user is not root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        return $E_PERMISSION
    fi
    return $E_SUCCESS
}

# Check if the script is sourced
is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

# Main execution
main() {
    # Skip if sourced
    if is_sourced; then
        return $E_SUCCESS
    fi
    
    local operation="${1:-install}"
    local exit_code=$E_SUCCESS
    
    # Check if running as root
    if ! check_not_root; then
        exit $E_PERMISSION
    fi
    
    # Execute requested operation
    case "$operation" in
        "install")
            install_nvidia
            exit_code=$?
            ;;
        "test")
            test_nvidia_installation
            exit_code=$?
            ;;
        "detect")
            detect_nvidia_gpu
            exit_code=$?
            ;;
        "wayland")
            configure_nvidia_wayland
            exit_code=$?
            ;;
        "env")
            create_nvidia_env
            exit_code=$?
            ;;
        "hyprland")
            configure_hyprland_nvidia
            exit_code=$?
            ;;
        "backup")
            backup_existing_config
            exit_code=$?
            ;;
        "restore")
            if [[ -n "${2:-}" ]]; then
                restore_config "$2"
                exit_code=$?
            else
                log_error "No backup path specified"
                echo "Usage: $0 restore <backup_path>"
                exit_code=$E_GENERAL
            fi
            ;;
        "rollback")
            if [[ -n "${2:-}" ]]; then
                rollback_installation "$2"
                exit_code=$?
            else
                rollback_installation
                exit_code=$?
            fi
            ;;
        "help")
            echo "Usage: $0 {install|test|detect|wayland|env|hyprland|backup|restore|rollback|help}"
            echo ""
            echo "Operations:"
            echo "  install    - Install NVIDIA drivers and configure (default)"
            echo "  test       - Test NVIDIA installation"
            echo "  detect     - Detect NVIDIA GPU"
            echo "  wayland    - Configure NVIDIA for Wayland"
            echo "  env        - Create NVIDIA environment variables"
            echo "  hyprland   - Configure Hyprland for NVIDIA"
            echo "  backup     - Backup existing configuration"
            echo "  restore    - Restore configuration from backup"
            echo "  rollback   - Rollback installation"
            echo "  help       - Show this help message"
            exit_code=$E_SUCCESS
            ;;
        *)
            log_error "Invalid operation: $operation"
            echo "Usage: $0 {install|test|detect|wayland|env|hyprland|backup|restore|rollback|help}"
            exit_code=$E_GENERAL
            ;;
    esac
    
    # Return with appropriate exit code
    if [[ $exit_code -eq $E_SUCCESS ]]; then
        log_success "Operation '$operation' completed successfully"
    else
        log_error "Operation '$operation' failed with code $exit_code"
    fi
    
    return $exit_code
}

# Run main function if script is executed directly
main "$@"
exit $?

