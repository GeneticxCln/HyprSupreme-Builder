#!/bin/bash
# HyprSupreme-Builder - Hyprland Installation Module

source "$(dirname "$0")/../common/functions.sh"

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

