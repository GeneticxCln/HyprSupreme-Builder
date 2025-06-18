#!/bin/bash
# HyprSupreme-Builder - SDDM Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_sddm() {
    log_info "Installing SDDM display manager..."
    
    # SDDM and dependencies
    local packages=(
        "sddm"
        "qt5-graphicaleffects"
        "qt5-quickcontrols2"
        "qt5-svg"
    )
    
    install_packages "${packages[@]}"
    
    # Configure SDDM
    configure_sddm
    
    # Install SDDM theme
    install_sddm_theme
    
    # Enable SDDM service
    enable_service "sddm"
    
    log_success "SDDM installation completed"
}

configure_sddm() {
    log_info "Configuring SDDM..."
    
    local config_file="/etc/sddm.conf"
    
    # Create SDDM configuration
    sudo tee "$config_file" > /dev/null << 'EOF'
[Autologin]
# Whether sddm should automatically log back into sessions when they exit
Relogin=false

# Name of session file for autologin session (if empty try last logged in)
Session=

# Username for autologin session
User=

[General]
# Halt command
HaltCommand=/usr/bin/systemctl poweroff

# Input method module
InputMethod=

# Comma-separated list of Linux namespaces for user session to enter
Namespaces=

# Maximum number of concurrent sessions
NumSessions=3

# Reboot command
RebootCommand=/usr/bin/systemctl reboot

# Current theme name
Current=catppuccin-mocha

[Theme]
# Current theme name
Current=catppuccin-mocha

# Cursor theme used in the greeter
CursorTheme=

# Number of users to use as threshold
DisableAvatarsThreshold=7

# Enable Qt's automatic high-DPI scaling
EnableAvatars=true

# Face icon directory path
FacesDir=/usr/share/sddm/faces

# Theme directory path
ThemeDir=/usr/share/sddm/themes

[Users]
# Default $PATH for logged in users
DefaultPath=/usr/local/sbin:/usr/local/bin:/usr/bin

# Comma-separated list of shells users listed in sddm
DefaultShell=/bin/bash

# Hide shells for users listed
HideShells=

# Hide users from list
HideUsers=

# Maximum user id for displayed users
MaximumUid=60513

# Minimum user id for displayed users
MinimumUid=1000

# Remember the session of the last successfully logged in user
RememberLastSession=true

# Remember the last successfully logged in user
RememberLastUser=true

[Wayland]
# Path to a script to execute when starting the desktop session
SessionCommand=/usr/share/sddm/scripts/wayland-session

# Directory containing available Wayland sessions
SessionDir=/usr/share/wayland-sessions

# Path to the user session log file
SessionLogFile=.local/share/sddm/wayland-session.log

[X11]
# Path to a script to execute when starting the display server
DisplayCommand=/usr/share/sddm/scripts/Xsetup

# Path to a script to execute when stopping the display server
DisplayStopCommand=/usr/share/sddm/scripts/Xstop

# Minimum VT for X servers
MinimumVT=1

# Arguments passed to the X server invocation
ServerArguments=-nolisten tcp

# Path to X server binary
ServerPath=/usr/bin/X

# Path to a script to execute when starting the desktop session
SessionCommand=/usr/share/sddm/scripts/Xsession

# Directory containing available X sessions
SessionDir=/usr/share/xsessions

# Path to the user session log file
SessionLogFile=.local/share/sddm/xorg-session.log

# Path to the Xauthority file
UserAuthFile=.Xauthority

# Path to xauth binary
XauthPath=/usr/bin/xauth

# Path to Xephyr binary
XephyrPath=/usr/bin/Xephyr
EOF
    
    log_success "SDDM configured"
}

install_sddm_theme() {
    log_info "Installing SDDM Catppuccin theme..."
    
    # Clone and install catppuccin theme
    local theme_dir="/usr/share/sddm/themes/catppuccin-mocha"
    
    if [[ ! -d "$theme_dir" ]]; then
        sudo mkdir -p "$theme_dir"
        
        # Download theme files
        local temp_dir="/tmp/sddm-catppuccin"
        git clone https://github.com/catppuccin/sddm.git "$temp_dir" 2>/dev/null || {
            log_warn "Failed to download Catppuccin SDDM theme, creating basic theme"
            create_basic_sddm_theme
            return
        }
        
        # Copy theme files
        sudo cp -r "$temp_dir/src/catppuccin-mocha/." "$theme_dir/"
        
        # Clean up
        rm -rf "$temp_dir"
        
        log_success "Catppuccin SDDM theme installed"
    else
        log_info "SDDM theme already exists"
    fi
}

create_basic_sddm_theme() {
    log_info "Creating basic SDDM theme..."
    
    local theme_dir="/usr/share/sddm/themes/catppuccin-mocha"
    sudo mkdir -p "$theme_dir"
    
    # Create theme.conf
    sudo tee "$theme_dir/theme.conf" > /dev/null << 'EOF'
[General]
type=color

color=#1e1e2e
fontSize=24
font=JetBrainsMono Nerd Font

[Input]
color=#89b4fa
borderColor=#89b4fa
borderWidth=2
borderRadius=8

[ComboBox]
color=#89b4fa
borderColor=#89b4fa
borderWidth=2
borderRadius=8
EOF

    # Create metadata.desktop
    sudo tee "$theme_dir/metadata.desktop" > /dev/null << 'EOF'
[SddmGreeterTheme]
Name=Catppuccin Mocha
Description=Catppuccin Mocha theme for SDDM
Author=HyprSupreme-Builder
Copyright=(c) 2024
License=MIT
Type=sddm-theme
Version=1.0
Website=https://github.com/GeneticxCln/HyprSupreme-Builder
MainScript=Main.qml
ConfigFile=theme.conf
TranslationsDirectory=translations
Theme-Id=catppuccin-mocha
Theme-API=2.0
EOF

    # Create basic Main.qml
    sudo tee "$theme_dir/Main.qml" > /dev/null << 'EOF'
import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    width: 640
    height: 480
    color: "#1e1e2e"

    Clock {
        id: clock
        anchors.centerIn: parent
        color: "#cdd6f4"
        timeFont.family: "JetBrainsMono Nerd Font"
        timeFont.pointSize: 48
    }

    LoginFrame {
        id: frame
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 100
    }
}
EOF

    log_success "Basic SDDM theme created"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_sddm
fi

