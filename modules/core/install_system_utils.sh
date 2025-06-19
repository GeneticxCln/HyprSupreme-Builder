#!/bin/bash
# HyprSupreme-Builder - System Utilities Installation Module
# File Manager, Package Manager GUI, Volume Control Tools

source "$(dirname "$0")/../common/functions.sh"

install_system_utilities() {
    log_info "Installing system utilities (file manager, package manager, volume control)..."
    
    # File Manager options
    install_file_managers
    
    # Package Manager GUIs
    install_package_managers
    
    # Volume Control tools
    install_volume_control
    
    # System monitoring tools
    install_monitoring_tools
    
    # Configure default applications
    configure_system_defaults
    
    log_success "System utilities installation completed"
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
    
    # Install primary file manager (Thunar)
    install_packages "${file_managers[@]}"
    
    # Ask user for additional file managers
    if whiptail --yesno "Install additional file managers (Nautilus, PCManFM, Nemo)?" 10 60; then
        install_packages "${optional_managers[@]}"
        log_info "Additional file managers installed"
    fi
    
    log_success "File managers installed"
}

install_package_managers() {
    log_info "Installing GUI package managers..."
    
    local package_managers=()
    
    # Check distribution and install appropriate GUI package managers
    if command -v pacman &> /dev/null; then
        # Arch-based systems
        local arch_managers=(
            "pamac-gtk"          # Pamac GUI for pacman/AUR
            "octopi"             # Alternative GUI package manager
        )
        
        # Check if pamac is available
        if yay -Ss pamac-gtk &> /dev/null || paru -Ss pamac-gtk &> /dev/null; then
            package_managers+=("pamac-gtk")
        fi
        
        # Octopi is usually available
        package_managers+=("octopi")
        
        # Ask user which package managers to install
        local selection=$(whiptail --title "Package Manager Selection" \
            --checklist "Choose GUI package managers to install:" \
            15 80 10 \
            "pamac" "Pamac - Modern GUI for pacman/AUR" ON \
            "octopi" "Octopi - Qt-based package manager" ON \
            "bauh" "Bauh - Universal package manager" OFF \
            3>&1 1>&2 2>&3)
        
        if [[ $selection == *"pamac"* ]]; then
            if command -v yay &> /dev/null; then
                yay -S --noconfirm pamac-gtk || log_warn "Failed to install pamac-gtk"
            elif command -v paru &> /dev/null; then
                paru -S --noconfirm pamac-gtk || log_warn "Failed to install pamac-gtk"
            fi
        fi
        
        if [[ $selection == *"octopi"* ]]; then
            install_packages "octopi"
        fi
        
        if [[ $selection == *"bauh"* ]]; then
            if command -v yay &> /dev/null; then
                yay -S --noconfirm bauh || log_warn "Failed to install bauh"
            elif command -v paru &> /dev/null; then
                paru -S --noconfirm bauh || log_warn "Failed to install bauh"
            fi
        fi
    fi
    
    log_success "GUI package managers installed"
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
    
    # Install primary tools
    install_packages "${volume_tools[@]}"
    
    # Ask for advanced tools
    if whiptail --yesno "Install advanced audio tools (PulseMixer, EasyEffects, qpwgraph)?" 10 70; then
        install_packages "${advanced_tools[@]}"
        log_info "Advanced audio tools installed"
    fi
    
    log_success "Volume control applications installed"
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
    
    # Install primary monitoring tools
    install_packages "${monitoring_tools[@]}"
    
    # Ask for GUI monitoring tools
    if whiptail --yesno "Install GUI system monitoring tools?" 10 50; then
        local selection=$(whiptail --title "System Monitor Selection" \
            --checklist "Choose GUI monitoring tools:" \
            15 80 10 \
            "gnome" "GNOME System Monitor" ON \
            "xfce" "XFCE Task Manager (lightweight)" ON \
            "kde" "KDE System Guard" OFF \
            3>&1 1>&2 2>&3)
        
        if [[ $selection == *"gnome"* ]]; then
            install_packages "gnome-system-monitor"
        fi
        
        if [[ $selection == *"xfce"* ]]; then
            install_packages "xfce4-taskmanager"
        fi
        
        if [[ $selection == *"kde"* ]]; then
            install_packages "ksysguard"
        fi
    fi
    
    log_success "System monitoring tools installed"
}

configure_system_defaults() {
    log_info "Configuring system defaults..."
    
    # Update MIME types for file manager
    if command -v thunar &> /dev/null; then
        # Set Thunar as default file manager
        xdg-mime default thunar.desktop inode/directory
        xdg-mime default thunar.desktop application/x-gnome-saved-search
        
        # Create desktop entry for file manager shortcut
        create_file_manager_shortcuts
    fi
    
    # Create quick access scripts
    create_system_scripts
    
    log_success "System defaults configured"
}

create_file_manager_shortcuts() {
    log_info "Creating file manager shortcuts..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    mkdir -p "$scripts_dir"
    
    # File manager launcher script
    cat > "$scripts_dir/file-manager.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/file-manager.sh"
    
    # Quick access script for common locations
    cat > "$scripts_dir/quick-access.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/quick-access.sh"
}

create_system_scripts() {
    log_info "Creating system utility scripts..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    # Package manager launcher
    cat > "$scripts_dir/package-manager.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/package-manager.sh"
    
    # Volume control launcher
    cat > "$scripts_dir/volume-control.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/volume-control.sh"
    
    # System monitor launcher
    cat > "$scripts_dir/system-monitor.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/system-monitor.sh"
}

# Test system utilities installation
test_system_utilities() {
    log_info "Testing system utilities installation..."
    
    # Test file manager
    if command -v thunar &> /dev/null; then
        log_success "✅ File manager (Thunar) is available"
    else
        log_error "❌ File manager not found"
        return 1
    fi
    
    # Test volume control
    if command -v pavucontrol &> /dev/null; then
        log_success "✅ Volume control (PulseAudio) is available"
    else
        log_warn "⚠️  GUI volume control not found"
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
    fi
    
    return 0
}

# Main execution
case "${1:-install}" in
    "install")
        install_system_utilities
        ;;
    "file-managers")
        install_file_managers
        ;;
    "package-managers")
        install_package_managers
        ;;
    "volume-control")
        install_volume_control
        ;;
    "monitoring")
        install_monitoring_tools
        ;;
    "configure")
        configure_system_defaults
        ;;
    "test")
        test_system_utilities
        ;;
    *)
        echo "Usage: $0 {install|file-managers|package-managers|volume-control|monitoring|configure|test}"
        exit 1
        ;;
esac

