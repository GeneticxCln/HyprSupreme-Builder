#!/bin/bash
# HyprSupreme-Builder - Feature Application Module

source "$(dirname "$0")/../common/functions.sh"

apply_feature() {
    local feature_name="$1"
    
    log_info "Applying feature: $feature_name"
    
    # Create features directory
    mkdir -p "$HOME/.config/hypr/features"
    mkdir -p "$HOME/.config/hypr/UserConfigs"
    
    case "$feature_name" in
        "animations")
            enable_animations
            ;;
        "blur")
            enable_blur
            ;;
        "shadows")
            enable_shadows
            ;;
        "rounded")
            enable_rounded_corners
            ;;
        "transparency")
            enable_transparency
            ;;
        "workspace_swipe")
            enable_workspace_swipe
            ;;
        "auto_theme")
            enable_auto_theme
            ;;
        "performance")
            enable_performance_optimizations
            ;;
        *)
            log_error "Unknown feature: $feature_name"
            return 1
            ;;
    esac
    
    # Mark feature as enabled
    touch "$HOME/.config/hypr/features/$feature_name.enabled"
    log_success "Feature '$feature_name' enabled"
}

enable_animations() {
    log_info "Enabling advanced animations..."
    
    local animations_file="$HOME/.config/hypr/UserConfigs/Animations.conf"
    
    cat > "$animations_file" << 'EOF'
# HyprSupreme Advanced Animations
animations {
    enabled = true
    
    # Bezier curves for smooth animations
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1  
    bezier = winOut, 0.3, -0.3, 0, 1
    bezier = liner, 1, 1, 1, 1
    bezier = linear, 0.0, 0.0, 1.0, 1.0
    bezier = overshot, 0.13, 0.99, 0.29, 1.1
    bezier = bounce, 1, 1.6, 0.1, 0.85
    
    # Window animations
    animation = windows, 1, 6, wind, slide
    animation = windowsIn, 1, 6, winIn, slide
    animation = windowsOut, 1, 5, winOut, slide
    animation = windowsMove, 1, 5, wind, slide
    
    # Border animations
    animation = border, 1, 10, linear
    animation = borderangle, 1, 8, linear
    
    # Fade animations
    animation = fade, 1, 10, overshot
    animation = fadeIn, 1, 10, overshot
    animation = fadeOut, 1, 5, overshot
    
    # Workspace animations
    animation = workspaces, 1, 6, wind
    animation = specialWorkspace, 1, 6, wind, slidevert
    
    # Layer animations  
    animation = layers, 1, 5, overshot, popin
    animation = layersIn, 1, 5, overshot, slide
    animation = layersOut, 1, 5, overshot, slide
}
EOF
    
    log_success "Advanced animations enabled"
}

enable_blur() {
    log_info "Enabling background blur effects..."
    
    local blur_file="$HOME/.config/hypr/UserConfigs/Blur.conf"
    
    cat > "$blur_file" << 'EOF'
# HyprSupreme Blur Effects
decoration {
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        xray = true
        ignore_opacity = true
        noise = 0.0117
        contrast = 1.3000
        brightness = 1.0000
        vibrancy = 0.2100
        vibrancy_darkness = 0.0
        special = false
        popups = true
        popups_ignorealpha = 0.2
    }
}
EOF
    
    log_success "Background blur effects enabled"
}

enable_shadows() {
    log_info "Enabling window shadows..."
    
    local shadows_file="$HOME/.config/hypr/UserConfigs/Shadows.conf"
    
    cat > "$shadows_file" << 'EOF'
# HyprSupreme Window Shadows
decoration {
    drop_shadow = true
    shadow_range = 30
    shadow_render_power = 3
    shadow_offset = 0 0
    col.shadow = 0x66000000
    col.shadow_inactive = 0x66000000
    
    # Shadow scaling
    shadow_scale = 1.0
    
    # Advanced shadow settings
    shadow_ignore_window = true
}
EOF
    
    log_success "Window shadows enabled"
}

enable_rounded_corners() {
    log_info "Enabling rounded corners..."
    
    local rounded_file="$HOME/.config/hypr/UserConfigs/Rounded.conf"
    
    cat > "$rounded_file" << 'EOF'
# HyprSupreme Rounded Corners
decoration {
    rounding = 12
    
    # Rounded corner exclusions for specific apps
}

# Window rules for rounded corners
windowrulev2 = rounding 0, class:(firefox), title:(.*Firefox.*)
windowrulev2 = rounding 8, class:(kitty)
windowrulev2 = rounding 15, class:(rofi)
windowrulev2 = rounding 0, class:(.*[Pp]icture.*[Ii]n.*[Pp]icture.*)
windowrulev2 = rounding 0, fullscreen:1
EOF
    
    log_success "Rounded corners enabled"
}

enable_transparency() {
    log_info "Enabling window transparency..."
    
    local transparency_file="$HOME/.config/hypr/UserConfigs/Transparency.conf"
    
    cat > "$transparency_file" << 'EOF'
# HyprSupreme Window Transparency
decoration {
    active_opacity = 1.0
    inactive_opacity = 0.9
    fullscreen_opacity = 1.0
    
    # Dim inactive windows
    dim_inactive = true
    dim_strength = 0.1
    dim_special = 0.8
}

# Transparency rules for specific applications
windowrulev2 = opacity 0.85 0.85, class:(kitty)
windowrulev2 = opacity 0.90 0.90, class:(thunar)
windowrulev2 = opacity 0.95 0.95, class:(code)
windowrulev2 = opacity 1.0 1.0, class:(firefox)
windowrulev2 = opacity 1.0 1.0, class:(chromium)
windowrulev2 = opacity 0.88 0.88, class:(discord)
EOF
    
    log_success "Window transparency enabled"
}

enable_workspace_swipe() {
    log_info "Enabling workspace gesture navigation..."
    
    local gestures_file="$HOME/.config/hypr/UserConfigs/Gestures.conf"
    
    cat > "$gestures_file" << 'EOF'
# HyprSupreme Workspace Gestures
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_invert = true
    workspace_swipe_min_speed_to_force = 30
    workspace_swipe_cancel_ratio = 0.5
    workspace_swipe_create_new = true
    workspace_swipe_direction_lock = true
    workspace_swipe_direction_lock_threshold = 10
    workspace_swipe_forever = false
    workspace_swipe_numbered = false
    workspace_swipe_use_r = false
}

# Touchpad settings for better gestures
input {
    touchpad {
        natural_scroll = true
        disable_while_typing = true
        clickfinger_behavior = true
        middle_button_emulation = false
        tap-to-click = true
        drag_lock = false
        tap-and-drag = false
    }
}
EOF
    
    log_success "Workspace gesture navigation enabled"
}

enable_auto_theme() {
    log_info "Enabling automatic theme switching..."
    
    # Create auto theme service
    local service_file="$HOME/.config/systemd/user/hyprsupreme-auto-theme.service"
    mkdir -p "$(dirname "$service_file")"
    
    cat > "$service_file" << 'EOF'
[Unit]
Description=HyprSupreme Auto Theme Switcher
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=%h/.config/hypr/scripts/theme-switcher.sh auto
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF
    
    # Create auto theme timer
    local timer_file="$HOME/.config/systemd/user/hyprsupreme-auto-theme.timer"
    
    cat > "$timer_file" << 'EOF'
[Unit]
Description=Run HyprSupreme Auto Theme Switcher every hour
Requires=hyprsupreme-auto-theme.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Enable the timer
    systemctl --user daemon-reload
    systemctl --user enable hyprsupreme-auto-theme.timer
    systemctl --user start hyprsupreme-auto-theme.timer
    
    log_success "Automatic theme switching enabled"
}

enable_performance_optimizations() {
    log_info "Enabling performance optimizations..."
    
    local performance_file="$HOME/.config/hypr/UserConfigs/Performance.conf"
    
    cat > "$performance_file" << 'EOF'
# HyprSupreme Performance Optimizations
misc {
    # Performance settings
    vfr = true
    vrr = 1
    focus_on_activate = false
    animate_manual_resizes = false
    animate_mouse_windowdragging = false
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
    
    # Resource management
    suppress_portal_warnings = true
    enable_swallow = true
    swallow_regex = ^(kitty|Alacritty)$
    
    # Layer optimizations
    layers_hog_keyboard_focus = true
    
    # Window management
    new_window_takes_focus = true
    initial_workspace_tracking = 1
    
    # Background optimizations
    background_color = 0x111111
    
    # Memory optimizations
    allow_tearing = false
    close_special_on_empty = true
}

# Render optimizations
render {
    explicit_sync = 2
    explicit_sync_kms = 2
    direct_scanout = true
}

# OpenGL optimizations
opengl {
    nvidia_anti_flicker = true
    force_introspection = 2
}
EOF
    
    # GPU-specific optimizations
    if is_nvidia_gpu; then
        cat >> "$performance_file" << 'EOF'

# NVIDIA-specific optimizations
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_RENDERER_ALLOW_SOFTWARE,1
EOF
    elif is_amd_gpu; then
        cat >> "$performance_file" << 'EOF'

# AMD-specific optimizations  
env = LIBVA_DRIVER_NAME,radeonsi
env = WLR_DRM_DEVICES,/dev/dri/card0
EOF
    elif is_intel_gpu; then
        cat >> "$performance_file" << 'EOF'

# Intel-specific optimizations
env = LIBVA_DRIVER_NAME,iHD
env = WLR_DRM_DEVICES,/dev/dri/card0
EOF
    fi
    
    log_success "Performance optimizations enabled"
}

# Disable feature function
disable_feature() {
    local feature_name="$1"
    
    log_info "Disabling feature: $feature_name"
    
    # Remove feature marker
    rm -f "$HOME/.config/hypr/features/$feature_name.enabled"
    
    # Remove feature-specific config file
    case "$feature_name" in
        "animations")
            rm -f "$HOME/.config/hypr/UserConfigs/Animations.conf"
            ;;
        "blur")
            rm -f "$HOME/.config/hypr/UserConfigs/Blur.conf"
            ;;
        "shadows")
            rm -f "$HOME/.config/hypr/UserConfigs/Shadows.conf"
            ;;
        "rounded")
            rm -f "$HOME/.config/hypr/UserConfigs/Rounded.conf"
            ;;
        "transparency")
            rm -f "$HOME/.config/hypr/UserConfigs/Transparency.conf"
            ;;
        "workspace_swipe")
            rm -f "$HOME/.config/hypr/UserConfigs/Gestures.conf"
            ;;
        "auto_theme")
            systemctl --user stop hyprsupreme-auto-theme.timer
            systemctl --user disable hyprsupreme-auto-theme.timer
            rm -f "$HOME/.config/systemd/user/hyprsupreme-auto-theme.service"
            rm -f "$HOME/.config/systemd/user/hyprsupreme-auto-theme.timer"
            systemctl --user daemon-reload
            ;;
        "performance")
            rm -f "$HOME/.config/hypr/UserConfigs/Performance.conf"
            ;;
    esac
    
    log_success "Feature '$feature_name' disabled"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$1" == "--disable" ]]; then
        disable_feature "$2"
    else
        apply_feature "$1"
    fi
fi

