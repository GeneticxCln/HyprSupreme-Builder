#!/bin/bash
# HyprSupreme-Builder - Configuration Application Module

source "$(dirname "$0")/../common/functions.sh"

apply_config() {
    local config_name="$1"
    
    log_info "Applying configuration: $config_name"
    
    case "$config_name" in
        "jakoolit")
            apply_jakoolit_config
            ;;
        "ml4w")
            apply_ml4w_config
            ;;
        "hyde")
            apply_hyde_config
            ;;
        "end4")
            apply_end4_config
            ;;
        "prasanta")
            apply_prasanta_config
            ;;
        *)
            log_error "Unknown configuration: $config_name"
            return 1
            ;;
    esac
}

apply_jakoolit_config() {
    log_info "Applying JaKooLit configuration..."
    
    local source_dir="sources/jakoolit-dots"
    local config_dir="$HOME/.config"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "JaKooLit source not found: $source_dir"
        return 1
    fi
    
    # Copy Hyprland configuration
    if [[ -d "$source_dir/config/hypr" ]]; then
        copy_config "$source_dir/config/hypr" "$config_dir/hypr"
        log_success "Applied JaKooLit Hyprland config"
    fi
    
    # Copy Waybar configuration
    if [[ -d "$source_dir/config/waybar" ]]; then
        copy_config "$source_dir/config/waybar" "$config_dir/waybar"
        log_success "Applied JaKooLit Waybar config"
    fi
    
    # Copy Rofi configuration
    if [[ -d "$source_dir/config/rofi" ]]; then
        copy_config "$source_dir/config/rofi" "$config_dir/rofi"
        log_success "Applied JaKooLit Rofi config"
    fi
    
    # Copy AGS configuration
    if [[ -d "$source_dir/config/ags" ]]; then
        copy_config "$source_dir/config/ags" "$config_dir/ags"
        log_success "Applied JaKooLit AGS config"
    fi
    
    # Copy Kitty configuration
    if [[ -d "$source_dir/config/kitty" ]]; then
        copy_config "$source_dir/config/kitty" "$config_dir/kitty"
        log_success "Applied JaKooLit Kitty config"
    fi
    
    # Apply JaKooLit specific settings
    apply_jakoolit_settings
    
    log_success "JaKooLit configuration applied successfully"
}

apply_jakoolit_settings() {
    log_info "Applying JaKooLit specific settings..."
    
    # Create JaKooLit specific directories
    mkdir -p "$HOME/.config/hypr/UserConfigs"
    mkdir -p "$HOME/.config/hypr/scripts"
    
    # Set JaKooLit specific environment variables
    local env_file="$HOME/.config/hypr/UserConfigs/ENVariables.conf"
    
    cat > "$env_file" << 'EOF'
# JaKooLit Environment Variables
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = GTK_THEME,Adwaita:dark
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
EOF
    
    log_success "JaKooLit settings applied"
}

apply_ml4w_config() {
    log_info "Applying ML4W configuration..."
    
    local source_dir="sources/ml4w"
    local config_dir="$HOME/.config"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "ML4W source not found: $source_dir"
        return 1
    fi
    
    # Apply ML4W productivity settings
    apply_ml4w_productivity_settings
    
    log_success "ML4W configuration applied successfully"
}

apply_ml4w_productivity_settings() {
    log_info "Applying ML4W productivity settings..."
    
    # Create ML4W workspace rules
    local workspace_file="$HOME/.config/hypr/UserConfigs/WorkspaceRules.conf"
    
    cat > "$workspace_file" << 'EOF'
# ML4W Productivity Workspace Rules
workspace = 1, monitor:DP-1, default:true
workspace = 2, monitor:DP-1
workspace = 3, monitor:DP-1
workspace = 4, monitor:DP-1
workspace = 5, monitor:DP-1

# Application workspace assignments
windowrulev2 = workspace 1, class:(firefox)
windowrulev2 = workspace 2, class:(code)
windowrulev2 = workspace 3, class:(kitty)
windowrulev2 = workspace 4, class:(nautilus)
windowrulev2 = workspace 5, class:(discord)
EOF
    
    log_success "ML4W productivity settings applied"
}

apply_hyde_config() {
    log_info "Applying HyDE configuration..."
    
    local source_dir="sources/hyde"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "HyDE source not found: $source_dir"
        return 1
    fi
    
    # Apply HyDE dynamic theming
    apply_hyde_theming
    
    log_success "HyDE configuration applied successfully"
}

apply_hyde_theming() {
    log_info "Applying HyDE dynamic theming..."
    
    # Create HyDE theme directory
    mkdir -p "$HOME/.config/hypr/themes"
    
    # Create dynamic theme script
    local theme_script="$HOME/.config/hypr/scripts/theme-switcher.sh"
    
    cat > "$theme_script" << 'EOF'
#!/bin/bash
# HyDE Dynamic Theme Switcher

THEME_DIR="$HOME/.config/hypr/themes"
CURRENT_THEME_FILE="$HOME/.config/hypr/.current_theme"

switch_theme() {
    local theme_name="$1"
    local theme_file="$THEME_DIR/$theme_name.conf"
    
    if [[ -f "$theme_file" ]]; then
        echo "$theme_name" > "$CURRENT_THEME_FILE"
        hyprctl reload
        notify-send "Theme switched to: $theme_name"
    else
        notify-send "Theme not found: $theme_name"
    fi
}

# Auto theme based on time
auto_theme() {
    local hour=$(date +%H)
    
    if [[ $hour -ge 6 && $hour -lt 18 ]]; then
        switch_theme "light"
    else
        switch_theme "dark"
    fi
}

case "$1" in
    "auto") auto_theme ;;
    *) switch_theme "$1" ;;
esac
EOF
    
    chmod +x "$theme_script"
    
    log_success "HyDE theming applied"
}

apply_end4_config() {
    log_info "Applying End-4 configuration..."
    
    local source_dir="sources/end4"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "End-4 source not found: $source_dir"
        return 1
    fi
    
    # Apply End-4 modern animations
    apply_end4_animations
    
    log_success "End-4 configuration applied successfully"
}

apply_end4_animations() {
    log_info "Applying End-4 modern animations..."
    
    local animations_file="$HOME/.config/hypr/UserConfigs/Animations.conf"
    
    cat > "$animations_file" << 'EOF'
# End-4 Modern Animations
animations {
    enabled = true
    
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = linear, 0.0, 0.0, 1.0, 1.0
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    bezier = slow, 0, 0.85, 0.3, 1
    bezier = overshot, 0.13, 0.99, 0.29, 1.1
    
    animation = windows, 1, 6, wind, slide
    animation = windowsIn, 1, 6, winIn, slide
    animation = windowsOut, 1, 5, winOut, slide
    animation = windowsMove, 1, 5, wind, slide
    animation = border, 1, 10, linear
    animation = borderangle, 1, 8, linear
    animation = fade, 1, 10, overshot
    animation = workspaces, 1, 6, wind
    animation = specialWorkspace, 1, 6, wind, slidevert
}
EOF
    
    log_success "End-4 animations applied"
}

apply_prasanta_config() {
    log_info "Applying Prasanta configuration..."
    
    local source_dir="sources/prasanta"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Prasanta source not found: $source_dir"
        return 1
    fi
    
    # Apply Prasanta beautiful themes
    apply_prasanta_themes
    
    log_success "Prasanta configuration applied successfully"
}

apply_prasanta_themes() {
    log_info "Applying Prasanta beautiful themes..."
    
    local decorations_file="$HOME/.config/hypr/UserConfigs/Decorations.conf"
    
    cat > "$decorations_file" << 'EOF'
# Prasanta Beautiful Decorations
decoration {
    rounding = 16
    
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        xray = true
        ignore_opacity = false
    }
    
    active_opacity = 1.0
    inactive_opacity = 0.9
    fullscreen_opacity = 1.0
    
    drop_shadow = true
    shadow_range = 30
    shadow_render_power = 3
    col.shadow = 0x66000000
    col.shadow_inactive = 0x66000000
    
    dim_inactive = false
    dim_strength = 0.1
    dim_special = 0.8
}
EOF
    
    log_success "Prasanta themes applied"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    apply_config "$@"
fi

