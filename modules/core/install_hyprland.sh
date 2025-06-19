#!/bin/bash
# HyprSupreme-Builder - Hyprland Installation Module

source "$(dirname "$0")/../common/functions.sh"

# Validate sudo access before starting
validate_sudo_access "install_hyprland.sh"

# Error handling
error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Check if common functions exist
FUNCTIONS_FILE="$(dirname "$0")/../common/functions.sh"
if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    error_exit "Common functions file not found: $FUNCTIONS_FILE"
fi

source "$FUNCTIONS_FILE"

install_hyprland() {
    log_info "Installing Hyprland..."
    
    # Install Hyprland and essential packages
    local packages=(
        "hyprland"
        "hyprpaper"
        "hyprlock"
        "hypridle"
        "xdg-desktop-portal-hyprland"
        "qt5-wayland"
        "qt6-wayland"
        "polkit-kde-agent"
        "wl-clipboard"
        "cliphist"
        "grim"
        "slurp"
        "swappy"
    )
    
    install_packages "${packages[@]}"
    
    # Create config directory
    mkdir -p "$HOME/.config/hypr"
    
    log_success "Hyprland installation completed"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_hyprland
fi

