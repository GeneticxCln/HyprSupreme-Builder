#!/bin/bash
# HyprSupreme-Builder - System Utilities Installation Module
# File Manager, Package Manager GUI, Volume Control Tools

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
readonly E_UTILITIES=7  # System utilities specific errors

# Path to the script
readonly SCRIPT_PATH="$(readlink -f "$0")"
readonly SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
readonly CONFIG_DIR="$HOME/.config"
readonly BACKUP_DIR="$HOME/.config/system-utils-backup-$(date +%Y%m%d-%H%M%S)"

# Source common functions
if [[ ! -f "${SCRIPT_DIR}/../common/functions.sh" ]]; then
    echo "ERROR: Required file not found: ${SCRIPT_DIR}/../common/functions.sh"
    exit $E_DEPENDENCY
fi

source "${SCRIPT_DIR}/../common/functions.sh"

# Error handling function
handle_error() {
    local exit_code=$1
    local error_message="${2:-Unknown error}"
    local error_source="${3:-$SCRIPT_PATH}"
    
    log_error "Error in $error_source: $error_message (code: $exit_code)"
    
    # Clean up any temporary resources if needed
    
    # Return the exit code
    return $exit_code
}

# System utilities specific error handler
handle_utilities_error() {
    local error_type="$1"
    local error_message="$2"
    
    case "$error_type" in
        "file_manager")
            log_error "File manager error: $error_message"
            return $E_UTILITIES
            ;;
        "package_manager")
            log_error "Package manager error: $error_message"
            return $E_UTILITIES
            ;;
        "volume_control")
            log_error "Volume control error: $error_message"
            return $E_UTILITIES
            ;;
        "monitoring")
            log_error "System monitoring error: $error_message"
            return $E_UTILITIES
            ;;
        *)
            log_error "Unknown system utilities error: $error_message"
            return $E_GENERAL
            ;;
    esac
}

# Trap errors
trap 'handle_error $? "Script interrupted" "$BASH_SOURCE:$LINENO"' ERR
trap 'log_warn "Script received SIGINT - operation canceled"; exit $E_GENERAL' INT
trap 'log_warn "Script received SIGTERM - operation canceled"; exit $E_GENERAL' TERM

# Backup existing configuration
backup_config() {
    local configs_to_backup=(
        "$HOME/.config/mimeapps.list"
        "$HOME/.config/Thunar"
        "$HOME/.config/pcmanfm"
        "$HOME/.config/nautilus"
        "$HOME/.local/share/applications"
    )
    
    log_info "Backing up system utilities configuration..."
    
    # Create backup directory
    if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
        log_error "Failed to create backup directory: $BACKUP_DIR"
        return $E_DIRECTORY
    fi
    
    # Backup each configuration if it exists
    for config in "${configs_to_backup[@]}"; do
        if [[ -e "$config" ]]; then
            local backup_path="$BACKUP_DIR/$(basename "$config")"
            if ! cp -r "$config" "$backup_path" 2>/dev/null; then
                log_warn "Failed to backup: $config"
            else
                log_info "Backed up: $config"
            fi
        fi
    done
    
    log_success "Configuration backup completed to $BACKUP_DIR"
    return $E_SUCCESS
}

install_system_utilities() {
    log_info "Installing system utilities (file manager, package manager, volume control)..."
    
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
    
    # Backup existing configuration
    backup_config
    
    # Install components with error handling
    if ! install_file_managers; then
        handle_utilities_error "file_manager" "Failed to install file managers"
        return $E_UTILITIES
    fi
    
    if ! install_package_managers; then
        log_warn "Failed to install some package managers, continuing..."
    fi
    
    if ! install_volume_control; then
        handle_utilities_error "volume_control" "Failed to install volume control"
        return $E_UTILITIES
    fi
    
    if ! install_monitoring_tools; then
        log_warn "Failed to install some monitoring tools, continuing..."
    fi
    
    # Configure system defaults
    if ! configure_system_defaults; then
        handle_utilities_error "config" "Failed to configure system defaults"
        return $E_CONFIG
    fi
    
    log_success "System utilities installation completed"
    return $E_SUCCESS
}

install_file_managers() {
    log_info "Installing file managers..."
    
    local file_managers=(
        "thunar"                    # Primary - GTK file manager
        "thunar-volman"            # Volume management for Thunar
        "tumbler"                  # Thumbnail support
        "thunar-archive-plugin"    # Archive support
        "thunar-media-tags-plugin" # Media tag support
    )
    
    # Optional alternative file managers
    local optional_managers=(
        "nautilus"                 # GNOME file manager
        "pcmanfm-gtk3"            # Lightweight alternative
        "nemo"                     # Cinnamon file manager
    )
    
    # Install primary file manager (Thunar) with error handling
    if ! install_packages "${file_managers[@]}"; then
        log_error "Failed to install primary file manager"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v thunar &> /dev/null; then
        log_error "Thunar installation failed: thunar command not found"
        return $E_DEPENDENCY
    fi
    
    # Ask user for additional file managers if whiptail is available
    if command -v whiptail &> /dev/null; then
        if whiptail --yesno "Install additional file managers (Nautilus, PCManFM, Nemo)?" 10 60; then
            if ! install_packages "${optional_managers[@]}"; then
                log_warn "Failed to install some additional file managers"
                # Continue anyway as these are optional
            else
                log_info "Additional file managers installed"
            fi
        fi
    else
        log_info "Whiptail not available, skipping additional file managers"
    fi
    
    log_success "File managers installed"
    return $E_SUCCESS
}

install_package_managers() {
    log_info "Installing GUI package managers..."
    
    local package_managers=()
    local install_success=false
    
    # Check distribution and install appropriate GUI package managers
    if command -v pacman &> /dev/null; then
        # Arch-based systems
        local arch_managers=(
            "pamac-gtk"          # Pamac GUI for pacman/AUR
            "octopi"             # Alternative GUI package manager
        )
        
        # Verify AUR helper is available
        local aur_helper=""
        if command -v yay &> /dev/null; then
            aur_helper="yay"
        elif command -v paru &> /dev/null; then
            aur_helper="paru"
        fi
        
        # Check if whiptail is available for user selection
        if command -v whiptail &> /dev/null; then
            # Ask user which package managers to install
            local selection=$(whiptail --title "Package Manager Selection" \
                --checklist "Choose GUI package managers to install:" \
                15 80 10 \
                "pamac" "Pamac - Modern GUI for pacman/AUR" ON \
                "octopi" "Octopi - Qt-based package manager" ON \
                "bauh" "Bauh - Universal package manager" OFF \
                3>&1 1>&2 2>&3) || selection=""
            
            if [[ $selection == *"pamac"* ]]; then
                if [[ -n "$aur_helper" ]]; then
                    log_info "Installing pamac-gtk using $aur_helper..."
                    if "$aur_helper" -S --noconfirm pamac-gtk; then
                        log_success "Installed pamac-gtk"
                        install_success=true
                    else
                        log_warn "Failed to install pamac-gtk"
                    fi
                else
                    log_warn "Cannot install pamac-gtk: No AUR helper found"
                fi
            fi
            
            if [[ $selection == *"octopi"* ]]; then
                if install_packages "octopi"; then
                    log_success "Installed octopi"
                    install_success=true
                else
                    log_warn "Failed to install octopi"
                fi
            fi
            
            if [[ $selection == *"bauh"* ]]; then
                if [[ -n "$aur_helper" ]]; then
                    log_info "Installing bauh using $aur_helper..."
                    if "$aur_helper" -S --noconfirm bauh; then
                        log_success "Installed bauh"
                        install_success=true
                    else
                        log_warn "Failed to install bauh"
                    fi
                else
                    log_warn "Cannot install bauh: No AUR helper found"
                fi
            fi
        else
            # No whiptail - default to installing octopi
            log_info "Whiptail not available, installing octopi by default"
            if install_packages "octopi"; then
                log_success "Installed octopi"
                install_success=true
            else
                log_warn "Failed to install octopi"
            fi
        fi
    else
        log_warn "Not running on an Arch-based system, skipping package manager installation"
    fi
    
    if $install_success; then
        log_success "GUI package managers installed"
        return $E_SUCCESS
    else
        log_warn "No GUI package managers were successfully installed"
        return $E_UTILITIES
    fi
}

install_volume_control() {
    log_info "Installing volume control applications..."
    
    local volume_tools=(
        "pavucontrol"             # Primary - PulseAudio volume control
        "alsa-utils"              # ALSA utilities (includes alsamixer)
        "pulseaudio-alsa"         # ALSA support for PulseAudio
        "pipewire-pulse"          # PipeWire PulseAudio compatibility
    )
    
    # Optional advanced tools
    local advanced_tools=(
        "pulsemixer"              # Terminal-based mixer
        "easyeffects"             # Audio effects and enhancement
        "qpwgraph"                # PipeWire graph manager
    )
    
    # Install primary tools with error handling
    if ! install_packages "${volume_tools[@]}"; then
        log_error "Failed to install primary volume control tools"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v pavucontrol &> /dev/null || ! command -v alsamixer &> /dev/null; then
        log_error "Volume control tools installation failed: critical commands not found"
        return $E_DEPENDENCY
    fi
    
    # Ask for advanced tools if whiptail is available
    if command -v whiptail &> /dev/null; then
        if whiptail --yesno "Install advanced audio tools (PulseMixer, EasyEffects, qpwgraph)?" 10 70; then
            if ! install_packages "${advanced_tools[@]}"; then
                log_warn "Failed to install some advanced audio tools"
                # Continue anyway as these are optional
            else
                log_info "Advanced audio tools installed"
            fi
        fi
    else
        log_info "Whiptail not available, skipping advanced audio tools"
    fi
    
    log_success "Volume control applications installed"
    return $E_SUCCESS
}

install_monitoring_tools() {
    log_info "Installing system monitoring tools..."
    
    local monitoring_tools=(
        "htop"                    # Process monitor
        "btop"                    # Modern resource monitor
        "neofetch"               # System information
        "inxi"                   # Hardware information
        "lm_sensors"             # Hardware sensors
        "hardinfo"               # System profiler and benchmark
    )
    
    # Optional GUI monitoring tools
    local gui_monitoring=(
        "gnome-system-monitor"    # GNOME system monitor
        "ksysguard"              # KDE system monitor
        "xfce4-taskmanager"      # XFCE task manager
    )
    
    # Install primary monitoring tools with error handling
    if ! install_packages "${monitoring_tools[@]}"; then
        log_warn "Failed to install some monitoring tools"
        # Try to install critical ones individually
        local critical_tools=("htop" "neofetch" "inxi")
        for tool in "${critical_tools[@]}"; do
            if ! install_packages "$tool"; then
                log_warn "Failed to install $tool"
            fi
        done
    fi
    
    # Verify at least one monitoring tool is installed
    local tool_found=false
    for tool in "htop" "btop" "neofetch"; do
        if command -v "$tool" &> /dev/null; then
            tool_found=true
            break
        fi
    done
    
    if ! $tool_found; then
        log_error "Failed to install any monitoring tools"
        return $E_DEPENDENCY
    fi
    
    # Ask for GUI monitoring tools if whiptail is available
    if command -v whiptail &> /dev/null; then
        if whiptail --yesno "Install GUI system monitoring tools?" 10 50; then
            local selection=$(whiptail --title "System Monitor Selection" \
                --checklist "Choose GUI monitoring tools:" \
                15 80 10 \
                "gnome" "GNOME System Monitor" ON \
                "xfce" "XFCE Task Manager (lightweight)" ON \
                "kde" "KDE System Guard" OFF \
                3>&1 1>&2 2>&3) || selection=""
            
            if [[ $selection == *"gnome"* ]]; then
                if ! install_packages "gnome-system-monitor"; then
                    log_warn "Failed to install GNOME System Monitor"
                fi
            fi
            
            if [[ $selection == *"xfce"* ]]; then
                if ! install_packages "xfce4-taskmanager"; then
                    log_warn "Failed to install XFCE Task Manager"
                fi
            fi
            
            if [[ $selection == *"kde"* ]]; then
                if ! install_packages "ksysguard"; then
                    log_warn "Failed to install KDE System Guard"
                fi
            fi
        fi
    else
        log_info "Whiptail not available, skipping GUI monitoring tools"
    fi
    
    log_success "System monitoring tools installed"
    return $E_SUCCESS
}

configure_system_defaults() {
    log_info "Configuring system defaults..."
    
    # Update MIME types for file manager if xdg-mime is available
    if command -v thunar &> /dev/null && command -v xdg-mime &> /dev/null; then
        log_info "Setting Thunar as default file manager..."
        # Set Thunar as default file manager
        if ! xdg-mime default thunar.desktop inode/directory 2>/dev/null; then
            log_warn "Failed to set Thunar as default file manager for directories"
        fi
        
        if ! xdg-mime default thunar.desktop application/x-gnome-saved-search 2>/dev/null; then
            log_warn "Failed to set Thunar as default search handler"
        fi
        
        # Create desktop entry for file manager shortcut
        if ! create_file_manager_shortcuts; then
            log_warn "Failed to create file manager shortcuts"
        fi
    else
        log_warn "Thunar or xdg-mime not found, skipping default file manager configuration"
    fi
    
    # Create quick access scripts
    if ! create_system_scripts; then
        log_error "Failed to create system scripts"
        return $E_CONFIG
    fi
    
    log_success "System defaults configured"
    return $E_SUCCESS
}

create_file_manager_shortcuts() {
    log_info "Creating file manager shortcuts..."
    
    # Create scripts directory with error handling
    local scripts_dir="$HOME/.config/hypr/scripts"
    if [[ ! -d "$scripts_dir" ]]; then
        log_info "Creating scripts directory: $scripts_dir"
        if ! mkdir -p "$scripts_dir" 2>/dev/null; then
            log_error "Failed to create scripts directory: $scripts_dir"
            return $E_DIRECTORY
        fi
    else
        log_info "Scripts directory already exists: $scripts_dir"
    fi
    
    # Check write permissions
    if [[ ! -w "$scripts_dir" ]]; then
        log_error "No write permission for scripts directory: $scripts_dir"
        return $E_PERMISSION
    fi
    
    # File manager launcher script
    local launcher_script="$scripts_dir/file-manager.sh"
    log_info "Creating file manager launcher script..."
    
    # Check if file exists and is writable
    if [[ -f "$launcher_script" && ! -w "$launcher_script" ]]; then
        log_error "Cannot write to existing file: $launcher_script"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$launcher_script" << 'EOF'
#!/bin/bash
# File Manager Launcher for HyprSupreme

# Check for available file managers and launch the best one
if command -v thunar &> /dev/null; then
    thunar "$@"
elif command -v nautilus &> /dev/null; then
    nautilus "$@"
elif command -v pcmanfm &> /dev/null; then
    pcmanfm "$@"
elif command -v nemo &> /dev/null; then
    nemo "$@"
else
    notify-send "File Manager" "No file manager found"
fi
EOF
    then
        log_error "Failed to write file manager launcher script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$launcher_script" 2>/dev/null; then
        log_error "Failed to make file manager launcher script executable"
        return $E_PERMISSION
    fi
    
    # Quick access script for common locations
    local quick_access_script="$scripts_dir/quick-access.sh"
    log_info "Creating quick access script..."
    
    # Check if file exists and is writable
    if [[ -f "$quick_access_script" && ! -w "$quick_access_script" ]]; then
        log_error "Cannot write to existing file: $quick_access_script"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$quick_access_script" << 'EOF'
#!/bin/bash
# Quick Access Menu for File Manager

locations="🏠 Home
📁 Documents  
📥 Downloads
🖼️ Pictures
🎵 Music
🎬 Videos
⚙️ .config
🗂️ /tmp
💾 /mnt
🖥️ /usr"

selected=$(echo "$locations" | rofi -dmenu -p "Quick Access" -theme-str 'window {width: 30%;}')

case "$selected" in
    *"Home"*)
        thunar "$HOME"
        ;;
    *"Documents"*)
        thunar "$HOME/Documents"
        ;;
    *"Downloads"*)
        thunar "$HOME/Downloads"
        ;;
    *"Pictures"*)
        thunar "$HOME/Pictures"
        ;;
    *"Music"*)
        thunar "$HOME/Music"
        ;;
    *"Videos"*)
        thunar "$HOME/Videos"
        ;;
    *".config"*)
        thunar "$HOME/.config"
        ;;
    *"/tmp"*)
        thunar "/tmp"
        ;;
    *"/mnt"*)
        thunar "/mnt"
        ;;
    *"/usr"*)
        thunar "/usr"
        ;;
esac
EOF
    then
        log_error "Failed to write quick access script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$quick_access_script" 2>/dev/null; then
        log_error "Failed to make quick access script executable"
        return $E_PERMISSION
    fi
    
    log_success "File manager shortcuts created"
    return $E_SUCCESS
}

create_system_scripts() {
    log_info "Creating system utility scripts..."
    
    # Create scripts directory with error handling
    local scripts_dir="$HOME/.config/hypr/scripts"
    if [[ ! -d "$scripts_dir" ]]; then
        log_info "Creating scripts directory: $scripts_dir"
        if ! mkdir -p "$scripts_dir" 2>/dev/null; then
            log_error "Failed to create scripts directory: $scripts_dir"
            return $E_DIRECTORY
        fi
    else
        log_info "Scripts directory already exists: $scripts_dir"
    fi
    
    # Check write permissions
    if [[ ! -w "$scripts_dir" ]]; then
        log_error "No write permission for scripts directory: $scripts_dir"
        return $E_PERMISSION
    fi
    
    # Package manager launcher
    local package_script="$scripts_dir/package-manager.sh"
    log_info "Creating package manager launcher script..."
    
    # Check if file exists and is writable
    if [[ -f "$package_script" && ! -w "$package_script" ]]; then
        log_error "Cannot write to existing file: $package_script"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$package_script" << 'EOF'
#!/bin/bash
# Package Manager Launcher for HyprSupreme

# Create menu for available package managers
menu=""

if command -v pamac-manager &> /dev/null; then
    menu+="📦 Pamac - Modern Package Manager\n"
fi

if command -v octopi &> /dev/null; then
    menu+="🐙 Octopi - Qt Package Manager\n"
fi

if command -v bauh &> /dev/null; then
    menu+="🔧 Bauh - Universal Package Manager\n"
fi

# Fallback to terminal-based managers
menu+="💻 Terminal Package Manager (yay/paru)\n"
menu+="⚙️ System Package Manager (pacman)\n"

selected=$(echo -e "$menu" | rofi -dmenu -p "Package Manager" -theme-str 'window {width: 40%;}')

case "$selected" in
    *"Pamac"*)
        pamac-manager
        ;;
    *"Octopi"*)
        octopi
        ;;
    *"Bauh"*)
        bauh
        ;;
    *"Terminal"*)
        if command -v yay &> /dev/null; then
            warp-terminal -e yay
        elif command -v paru &> /dev/null; then
            warp-terminal -e paru
        fi
        ;;
    *"System"*)
        warp-terminal -e sudo pacman -Syu
        ;;
esac
EOF
    then
        log_error "Failed to write package manager launcher script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$package_script" 2>/dev/null; then
        log_error "Failed to make package manager launcher script executable"
        return $E_PERMISSION
    fi
    
    # Volume control launcher
    local volume_script="$scripts_dir/volume-control.sh"
    log_info "Creating volume control launcher script..."
    
    # Check if file exists and is writable
    if [[ -f "$volume_script" && ! -w "$volume_script" ]]; then
        log_error "Cannot write to existing file: $volume_script"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$volume_script" << 'EOF'
#!/bin/bash
# Volume Control Launcher for HyprSupreme

menu="🔊 PulseAudio Volume Control
🎛️ ALSA Mixer
🎚️ Terminal Mixer (if available)
🎵 Audio Effects (if available)"

selected=$(echo "$menu" | rofi -dmenu -p "Audio Control" -theme-str 'window {width: 40%;}')

case "$selected" in
    *"PulseAudio"*)
        pavucontrol
        ;;
    *"ALSA"*)
        warp-terminal -e alsamixer
        ;;
    *"Terminal"*)
        if command -v pulsemixer &> /dev/null; then
            warp-terminal -e pulsemixer
        else
            notify-send "Audio" "PulseMixer not installed"
        fi
        ;;
    *"Effects"*)
        if command -v easyeffects &> /dev/null; then
            easyeffects
        else
            notify-send "Audio" "EasyEffects not installed"
        fi
        ;;
esac
EOF
    then
        log_error "Failed to write volume control launcher script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$volume_script" 2>/dev/null; then
        log_error "Failed to make volume control launcher script executable"
        return $E_PERMISSION
    fi
    
    # System monitor launcher
    local monitor_script="$scripts_dir/system-monitor.sh"
    log_info "Creating system monitor launcher script..."
    
    # Check if file exists and is writable
    if [[ -f "$monitor_script" && ! -w "$monitor_script" ]]; then
        log_error "Cannot write to existing file: $monitor_script"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$monitor_script" << 'EOF'
#!/bin/bash
# System Monitor Launcher for HyprSupreme

menu="📊 System Monitor (GUI)
💻 Resource Monitor (Terminal)
📈 Hardware Info
🔧 Task Manager"

selected=$(echo "$menu" | rofi -dmenu -p "System Monitor" -theme-str 'window {width: 40%;}')

case "$selected" in
    *"System Monitor"*)
        if command -v gnome-system-monitor &> /dev/null; then
            gnome-system-monitor
        elif command -v ksysguard &> /dev/null; then
            ksysguard
        elif command -v xfce4-taskmanager &> /dev/null; then
            xfce4-taskmanager
        else
            notify-send "System Monitor" "No GUI system monitor found"
        fi
        ;;
    *"Resource Monitor"*)
        if command -v btop &> /dev/null; then
            warp-terminal -e btop
        elif command -v htop &> /dev/null; then
            warp-terminal -e htop
        else
            warp-terminal -e top
        fi
        ;;
    *"Hardware Info"*)
        if command -v hardinfo &> /dev/null; then
            hardinfo
        else
            warp-terminal -e inxi -Fxz
        fi
        ;;
    *"Task Manager"*)
        if command -v xfce4-taskmanager &> /dev/null; then
            xfce4-taskmanager
        else
            warp-terminal -e htop
        fi
        ;;
esac
EOF
    then
        log_error "Failed to write system monitor launcher script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$monitor_script" 2>/dev/null; then
        log_error "Failed to make system monitor launcher script executable"
        return $E_PERMISSION
    fi
    
    log_success "System utility scripts created"
    return $E_SUCCESS
}

# Test system utilities installation with enhanced error reporting
test_system_utilities() {
    log_info "Testing system utilities installation..."
    local errors=0
    local warnings=0
    
    # Test file manager
    if command -v thunar &> /dev/null; then
        log_success "✅ File manager (Thunar) is available"
        
        # Check Thunar configuration
        if [[ -d "$HOME/.config/Thunar" ]]; then
            log_success "✅ Thunar configuration exists"
        else
            log_warn "⚠️  Thunar configuration is missing"
            ((warnings++))
        fi
    else
        log_error "❌ Primary file manager not found"
        ((errors++))
    fi
    
    # Test volume control
    if command -v pavucontrol &> /dev/null; then
        log_success "✅ Volume control (PulseAudio) is available"
    else
        log_warn "⚠️  GUI volume control not found"
        ((warnings++))
    fi
    
    # Test package managers
    local pkg_mgr_found=false
    if command -v pamac-manager &> /dev/null; then
        log_success "✅ GUI package manager (Pamac) is available"
        pkg_mgr_found=true
    fi
    
    if command -v octopi &> /dev/null; then
        log_success "✅ GUI package manager (Octopi) is available"
        pkg_mgr_found=true
    fi
    
    if ! $pkg_mgr_found; then
        log_warn "⚠️  No GUI package manager found"
        ((warnings++))
    fi
    
    # Test monitoring tools
    local monitoring_tools=("htop" "btop" "neofetch" "inxi")
    local monitoring_found=false
    
    for tool in "${monitoring_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "✅ Monitoring tool $tool is available"
            monitoring_found=true
        fi
    done
    
    if ! $monitoring_found; then
        log_warn "⚠️  No system monitoring tools found"
        ((warnings++))
    fi
    
    # Check scripts
    local scripts_dir="$HOME/.config/hypr/scripts"
    local required_scripts=(
        "file-manager.sh"
        "quick-access.sh"
        "package-manager.sh"
        "volume-control.sh"
        "system-monitor.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [[ -x "$scripts_dir/$script" ]]; then
            log_success "✅ Script $script is available and executable"
        elif [[ -f "$scripts_dir/$script" ]]; then
            log_warn "⚠️  Script $script exists but is not executable"
            ((warnings++))
        else
            log_error "❌ Script $script is missing"
            ((errors++))
        fi
    done
    
    # Report summary
    if [[ $errors -gt 0 ]]; then
        log_error "System utilities test completed with $errors errors and $warnings warnings"
        return $E_UTILITIES
    elif [[ $warnings -gt 0 ]]; then
        log_warn "System utilities test completed with $warnings warnings"
        return $E_SUCCESS
    else
        log_success "System utilities test completed successfully"
        return $E_SUCCESS
    fi
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
            install_system_utilities
            exit_code=$?
            ;;
        "file-managers")
            install_file_managers
            exit_code=$?
            ;;
        "package-managers")
            install_package_managers
            exit_code=$?
            ;;
        "volume-control")
            install_volume_control
            exit_code=$?
            ;;
        "monitoring")
            install_monitoring_tools
            exit_code=$?
            ;;
        "configure")
            configure_system_defaults
            exit_code=$?
            ;;
        "test")
            test_system_utilities
            exit_code=$?
            ;;
        "help")
            echo "Usage: $0 {install|file-managers|package-managers|volume-control|monitoring|configure|test|help}"
            echo ""
            echo "Operations:"
            echo "  install           - Install all system utilities (default)"
            echo "  file-managers     - Install only file managers"
            echo "  package-managers  - Install only package managers"
            echo "  volume-control    - Install only volume control"
            echo "  monitoring        - Install only monitoring tools"
            echo "  configure         - Configure system defaults"
            echo "  test              - Test system utilities installation"
            echo "  help              - Show this help message"
            exit_code=$E_SUCCESS
            ;;
        *)
            log_error "Invalid operation: $operation"
            echo "Usage: $0 {install|file-managers|package-managers|volume-control|monitoring|configure|test|help}"
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

# Run main function
main "$@"
exit $?

