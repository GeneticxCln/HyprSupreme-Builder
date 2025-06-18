#!/bin/bash
# HyprSupreme-Builder - Themes Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_themes() {
    log_info "Installing GTK and icon themes..."
    
    # Theme packages
    local packages=(
        "gtk-engine-murrine"
        "gtk-engines"
        "sassc"
        "papirus-icon-theme"
        "archcraft-icons-git"
        "breeze-icons"
        "candy-icons-git"
        "tela-icon-theme"
        "colloid-icon-theme-git"
        "catppuccin-gtk-theme-mocha"
        "nordic-theme"
        "dracula-gtk-theme"
        "materia-gtk-theme"
        "arc-gtk-theme"
        "adwaita-dark"
        "gnome-themes-extra"
    )
    
    install_packages "${packages[@]}"
    
    # Install cursor themes
    install_cursor_themes
    
    # Configure GTK themes
    configure_gtk_themes
    
    # Install custom themes
    install_custom_themes
    
    log_success "Themes installation completed"
}

install_cursor_themes() {
    log_info "Installing cursor themes..."
    
    local cursor_packages=(
        "capitaine-cursors"
        "oreo-cursors-git"
        "phinger-cursors"
        "volantes-cursors"
        "catppuccin-cursors-mocha"
        "bibata-cursor-theme"
    )
    
    for cursor in "${cursor_packages[@]}"; do
        if [[ -n "$AUR_HELPER" ]]; then
            log_info "Installing $cursor..."
            $AUR_HELPER -S --noconfirm "$cursor" 2>/dev/null || log_warn "Failed to install $cursor"
        fi
    done
    
    log_success "Cursor themes installed"
}

configure_gtk_themes() {
    log_info "Configuring GTK themes..."
    
    # Create GTK config directories
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    
    # GTK-3 configuration
    local gtk3_config="$HOME/.config/gtk-3.0/settings.ini"
    
    cat > "$gtk3_config" << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Catppuccin-Mocha-Standard-Blue-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter 11
gtk-cursor-theme-name=catppuccin-mocha-blue-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-decoration-layout=close,minimize,maximize:
gtk-enable-primary-paste=false
EOF

    # GTK-4 configuration
    local gtk4_config="$HOME/.config/gtk-4.0/settings.ini"
    
    cat > "$gtk4_config" << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Catppuccin-Mocha-Standard-Blue-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter 11
gtk-cursor-theme-name=catppuccin-mocha-blue-cursors
gtk-cursor-theme-size=24
gtk-enable-primary-paste=false
gtk-decoration-layout=close,minimize,maximize:
EOF

    # Create .gtkrc-2.0 for GTK2 apps
    local gtk2_config="$HOME/.gtkrc-2.0"
    
    cat > "$gtk2_config" << 'EOF'
# GTK2 Configuration
gtk-theme-name="Catppuccin-Mocha-Standard-Blue-Dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Inter 11"
gtk-cursor-theme-name="catppuccin-mocha-blue-cursors"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
include "/home/alex/.gtkrc-2.0.mine"
EOF

    log_success "GTK themes configured"
}

install_custom_themes() {
    log_info "Installing custom themes..."
    
    # Install Catppuccin themes
    install_catppuccin_themes
    
    # Install Nordic themes
    install_nordic_themes
    
    # Install WhiteSur themes
    install_whitesur_themes
    
    log_success "Custom themes installed"
}

install_catppuccin_themes() {
    log_info "Installing Catppuccin themes..."
    
    local themes_dir="$HOME/.themes"
    local icons_dir="$HOME/.icons"
    
    mkdir -p "$themes_dir" "$icons_dir"
    
    # Install Catppuccin GTK theme
    if [[ ! -d "$themes_dir/Catppuccin-Mocha-Standard-Blue-Dark" ]]; then
        local temp_dir="/tmp/catppuccin-gtk"
        git clone https://github.com/catppuccin/gtk.git "$temp_dir" 2>/dev/null || {
            log_warn "Failed to download Catppuccin GTK theme"
            return
        }
        
        cp -r "$temp_dir/releases/Catppuccin-Mocha-Standard-Blue-Dark" "$themes_dir/"
        rm -rf "$temp_dir"
        
        log_success "Catppuccin GTK theme installed"
    fi
    
    # Install Catppuccin icon theme
    if [[ ! -d "$icons_dir/Catppuccin-Mocha" ]]; then
        local temp_dir="/tmp/catppuccin-icons"
        git clone https://github.com/catppuccin/papirus-folders.git "$temp_dir" 2>/dev/null || {
            log_warn "Failed to download Catppuccin icon theme"
            return
        }
        
        # Apply catppuccin colors to papirus
        if command -v papirus-folders &> /dev/null; then
            papirus-folders -C cat-mocha-blue 2>/dev/null
        fi
        
        rm -rf "$temp_dir"
        log_success "Catppuccin icon theme applied"
    fi
}

install_nordic_themes() {
    log_info "Installing Nordic themes..."
    
    local themes_dir="$HOME/.themes"
    
    if [[ ! -d "$themes_dir/Nordic" ]]; then
        local temp_dir="/tmp/nordic-theme"
        git clone https://github.com/EliverLara/Nordic.git "$temp_dir" 2>/dev/null || {
            log_warn "Failed to download Nordic theme"
            return
        }
        
        cp -r "$temp_dir" "$themes_dir/Nordic"
        rm -rf "$temp_dir"
        
        log_success "Nordic theme installed"
    fi
}

install_whitesur_themes() {
    log_info "Installing WhiteSur themes..."
    
    local temp_dir="/tmp/whitesur-theme"
    
    if git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$temp_dir" 2>/dev/null; then
        cd "$temp_dir"
        
        # Install WhiteSur theme
        ./install.sh -d "$HOME/.themes" -t all -c Dark -N glassy --silent 2>/dev/null || {
            log_warn "Failed to install WhiteSur theme"
            cd - && rm -rf "$temp_dir"
            return
        }
        
        cd - && rm -rf "$temp_dir"
        log_success "WhiteSur theme installed"
    else
        log_warn "Failed to download WhiteSur theme"
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_themes
fi

