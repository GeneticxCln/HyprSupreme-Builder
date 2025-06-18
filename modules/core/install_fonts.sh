#!/bin/bash
# HyprSupreme-Builder - Fonts Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_fonts() {
    log_info "Installing fonts for HyprSupreme..."
    
    # Essential fonts
    local packages=(
        "ttf-jetbrains-mono"
        "ttf-jetbrains-mono-nerd"
        "ttf-font-awesome"
        "ttf-fira-code"
        "ttf-fira-sans"
        "ttf-sourcecodepro-nerd"
        "ttf-meslo-nerd"
        "ttf-hack-nerd"
        "noto-fonts"
        "noto-fonts-emoji"
        "noto-fonts-cjk"
        "adobe-source-code-pro-fonts"
        "adobe-source-sans-fonts"
        "adobe-source-serif-fonts"
        "cantarell-fonts"
        "inter-font"
    )
    
    install_packages "${packages[@]}"
    
    # Install additional Nerd Fonts from AUR
    local aur_fonts=(
        "ttf-ubuntu-nerd"
        "ttf-roboto-mono-nerd"
        "ttf-cascadia-code-nerd"
        "ttf-victor-mono-nerd"
    )
    
    for font in "${aur_fonts[@]}"; do
        if [[ -n "$AUR_HELPER" ]]; then
            log_info "Installing $font from AUR..."
            $AUR_HELPER -S --noconfirm "$font" 2>/dev/null || log_warn "Failed to install $font from AUR"
        fi
    done
    
    # Update font cache
    update_font_cache
    
    log_success "Fonts installation completed"
}

update_font_cache() {
    log_info "Updating font cache..."
    
    # Update system font cache
    sudo fc-cache -fv &>/dev/null
    
    # Update user font cache
    fc-cache -fv &>/dev/null
    
    log_success "Font cache updated"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_fonts
fi

