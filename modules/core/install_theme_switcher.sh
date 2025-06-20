#!/bin/bash
# HyprSupreme-Builder - Theme Switcher Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_theme_switcher() {
    log_info "Installing theme switcher system..."
    
    # Install theme tools
    install_theme_tools
    
    # Configure theme integration
    configure_theme_integration
    
    log_success "Theme switcher system installation completed"
}

install_theme_tools() {
    log_info "Installing theme switching tools..."
    
    local packages=(
        # Theme management
        "python-pywal"
        "imagemagick"
        "feh"
        "nitrogen"
        
        # Color tools
        "python-colorthief"
        "python-pillow"
        
        # GTK theme tools
        "lxappearance"
        "qt5ct"
        "kvantum"
        
        # Icon tools
        "papirus-icon-theme"
        "arc-icon-theme"
        "breeze-icons"
    )
    
    install_packages "${packages[@]}"
    
    log_success "Theme tools installed"
}

configure_theme_integration() {
    log_info "Configuring theme switcher integration..."
    
    # Create theme scripts directory
    local scripts_dir="$HOME/.config/hypr/scripts"
    mkdir -p "$scripts_dir"
    
    # Create theme directories
    create_theme_directories
    
    # Create theme switcher script
    create_theme_switcher_script
    
    # Create wallpaper theme script
    create_wallpaper_theme_script
    
    # Create auto theme script
    create_auto_theme_script
    
    # Create theme manager script
    create_theme_manager_script
    
    log_success "Theme switcher integration configured"
}

create_theme_directories() {
    log_info "Creating theme directories..."
    
    # Create theme structure
    mkdir -p "$HOME/.config/hypr/themes"
    mkdir -p "$HOME/.config/hypr/wallpapers"
    mkdir -p "$HOME/.local/share/themes"
    mkdir -p "$HOME/.local/share/icons"
    
    # Create default themes
    create_default_themes
}

create_default_themes() {
    local themes_dir="$HOME/.config/hypr/themes"
    
    # Catppuccin Mocha theme
    cat > "$themes_dir/catppuccin-mocha.conf" << 'EOF'
# Catppuccin Mocha Theme for HyprSupreme

$base = 0x1e1e2e
$mantle = 0x181825
$crust = 0x11111b

$text = 0xcdd6f4
$subtext0 = 0xa6adc8
$subtext1 = 0xbac2de

$surface0 = 0x313244
$surface1 = 0x45475a
$surface2 = 0x585b70

$overlay0 = 0x6c7086
$overlay1 = 0x7f849c
$overlay2 = 0x9399b2

$blue = 0x89b4fa
$lavender = 0xb4befe
$sapphire = 0x74c7ec
$sky = 0x89dceb
$teal = 0x94e2d5
$green = 0xa6e3a1
$yellow = 0xf9e2af
$peach = 0xfab387
$maroon = 0xeba0ac
$red = 0xf38ba8
$mauve = 0xcba6f7
$pink = 0xf5c2e7
$flamingo = 0xf2cdcd
$rosewater = 0xf5e0dc

general {
    col.active_border = rgb($blue) rgb($mauve) 45deg
    col.inactive_border = rgb($surface0)
}

decoration {
    col.shadow = rgba($crust, 0.5)
}
EOF
    
    # Nord theme
    cat > "$themes_dir/nord.conf" << 'EOF'
# Nord Theme for HyprSupreme

$nord0 = 0x2e3440
$nord1 = 0x3b4252
$nord2 = 0x434c5e
$nord3 = 0x4c566a

$nord4 = 0xd8dee9
$nord5 = 0xe5e9f0
$nord6 = 0xeceff4

$nord7 = 0x8fbcbb
$nord8 = 0x88c0d0
$nord9 = 0x81a1c1
$nord10 = 0x5e81ac
$nord11 = 0xbf616a
$nord12 = 0xd08770
$nord13 = 0xebcb8b
$nord14 = 0xa3be8c
$nord15 = 0xb48ead

general {
    col.active_border = rgb($nord8) rgb($nord9) 45deg
    col.inactive_border = rgb($nord1)
}

decoration {
    col.shadow = rgba($nord0, 0.5)
}
EOF
    
    # Dracula theme
    cat > "$themes_dir/dracula.conf" << 'EOF'
# Dracula Theme for HyprSupreme

$background = 0x282a36
$current_line = 0x44475a
$selection = 0x44475a
$foreground = 0xf8f8f2
$comment = 0x6272a4
$cyan = 0x8be9fd
$green = 0x50fa7b
$orange = 0xffb86c
$pink = 0xff79c6
$purple = 0xbd93f9
$red = 0xff5555
$yellow = 0xf1fa8c

general {
    col.active_border = rgb($purple) rgb($pink) 45deg
    col.inactive_border = rgb($current_line)
}

decoration {
    col.shadow = rgba($background, 0.5)
}
EOF
}

create_theme_switcher_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/theme-switcher.sh" << 'EOF'
#!/bin/bash
# Theme Switcher Script for HyprSupreme

THEMES_DIR="$HOME/.config/hypr/themes"
WALLPAPERS_DIR="$HOME/.config/hypr/wallpapers"
CURRENT_THEME_FILE="$HOME/.config/hypr/current-theme"

show_theme_menu() {
    local themes=""
    local current_theme=""
    
    # Get current theme
    if [ -f "$CURRENT_THEME_FILE" ]; then
        current_theme=$(cat "$CURRENT_THEME_FILE")
    fi
    
    # List available themes
    for theme_file in "$THEMES_DIR"/*.conf; do
        if [ -f "$theme_file" ]; then
            local theme_name=$(basename "$theme_file" .conf)
            local display_name=$(echo "$theme_name" | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
            
            if [ "$theme_name" = "$current_theme" ]; then
                themes+="✓ $display_name ($theme_name)\n"
            else
                themes+="  $display_name ($theme_name)\n"
            fi
        fi
    done
    
    # Add special options
    themes+="\n🎨 Generate from Wallpaper\n"
    themes+="🔄 Auto Theme (Time-based)\n"
    themes+="⚙️ Theme Manager\n"
    
    local selection=$(echo -e "$themes" | rofi -dmenu -p "Select Theme" -theme-str 'window {width: 50%;}')
    
    if [ -n "$selection" ]; then
        case "$selection" in
            *"Generate from Wallpaper"*)
                "$HOME/.config/hypr/scripts/wallpaper-theme.sh" generate
                ;;
            *"Auto Theme"*)
                "$HOME/.config/hypr/scripts/auto-theme.sh" toggle
                ;;
            *"Theme Manager"*)
                "$HOME/.config/hypr/scripts/theme-manager.sh" menu
                ;;
            *)
                # Extract theme name from selection
                local theme_name=$(echo "$selection" | grep -o '([^)]*)' | tr -d '()')
                if [ -n "$theme_name" ]; then
                    apply_theme "$theme_name"
                fi
                ;;
        esac
    fi
}

apply_theme() {
    local theme_name="$1"
    local theme_file="$THEMES_DIR/${theme_name}.conf"
    
    if [ ! -f "$theme_file" ]; then
        notify-send "Theme Switcher" "Theme not found: $theme_name" --icon=dialog-error
        return 1
    fi
    
    notify-send "Theme Switcher" "Applying theme: $theme_name" --icon=preferences-desktop-theme
    
    # Save current theme
    echo "$theme_name" > "$CURRENT_THEME_FILE"
    
    # Apply Hyprland theme
    apply_hyprland_theme "$theme_file"
    
    # Apply GTK theme
    apply_gtk_theme "$theme_name"
    
    # Apply Waybar theme
    apply_waybar_theme "$theme_name"
    
    # Apply Rofi theme
    apply_rofi_theme "$theme_name"
    
    # Reload Hyprland configuration
    hyprctl reload
    
    notify-send "Theme Switcher" "Theme applied: $theme_name" --icon=preferences-desktop-theme
}

apply_hyprland_theme() {
    local theme_file="$1"
    local hypr_config="$HOME/.config/hypr/hyprland.conf"
    
    # Remove old theme import
    sed -i '/# Theme import/,/^$/d' "$hypr_config"
    
    # Add new theme import
    echo "" >> "$hypr_config"
    echo "# Theme import" >> "$hypr_config"
    echo "source = $theme_file" >> "$hypr_config"
}

apply_gtk_theme() {
    local theme_name="$1"
    
    # Map themes to GTK themes
    case "$theme_name" in
        "catppuccin-mocha")
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
            gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
            ;;
        "nord")
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
            gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
            ;;
        "dracula")
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
            gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
            ;;
        *)
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
            gsettings set org.gnome.desktop.interface icon-theme "Papirus"
            ;;
    esac
}

apply_waybar_theme() {
    local theme_name="$1"
    local waybar_config="$HOME/.config/waybar"
    
    # Apply waybar theme if available
    if [ -f "$waybar_config/themes/${theme_name}.css" ]; then
        cp "$waybar_config/themes/${theme_name}.css" "$waybar_config/style.css"
        killall waybar 2> /dev/null
        waybar &
    fi
}

apply_rofi_theme() {
    local theme_name="$1"
    local rofi_config="$HOME/.config/rofi"
    
    # Apply rofi theme if available
    if [ -f "$rofi_config/themes/${theme_name}.rasi" ]; then
        echo "@theme \"themes/${theme_name}.rasi\"" > "$rofi_config/config.rasi"
    fi
}

get_current_theme() {
    if [ -f "$CURRENT_THEME_FILE" ]; then
        cat "$CURRENT_THEME_FILE"
    else
        echo "default"
    fi
}

list_themes() {
    for theme_file in "$THEMES_DIR"/*.conf; do
        if [ -f "$theme_file" ]; then
            basename "$theme_file" .conf
        fi
    done
}

case "$1" in
    "menu")
        show_theme_menu
        ;;
    "apply")
        if [ -n "$2" ]; then
            apply_theme "$2"
        else
            echo "Usage: $0 apply <theme_name>"
            exit 1
        fi
        ;;
    "current")
        get_current_theme
        ;;
    "list")
        list_themes
        ;;
    *)
        echo "Usage: $0 {menu|apply|current|list}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/theme-switcher.sh"
}

create_wallpaper_theme_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/wallpaper-theme.sh" << 'EOF'
#!/bin/bash
# Wallpaper Theme Generator for HyprSupreme

WALLPAPERS_DIR="$HOME/.config/hypr/wallpapers"
THEMES_DIR="$HOME/.config/hypr/themes"

generate_theme_from_wallpaper() {
    # Select wallpaper
    local wallpaper_files=""
    for img in "$WALLPAPERS_DIR"/*.{jpg,jpeg,png,webp}; do
        if [ -f "$img" ]; then
            wallpaper_files+="$(basename "$img")\n"
        fi
    done
    
    if [ -z "$wallpaper_files" ]; then
        notify-send "Wallpaper Theme" "No wallpapers found in $WALLPAPERS_DIR" --icon=dialog-warning
        return 1
    fi
    
    local selected_wallpaper=$(echo -e "$wallpaper_files" | rofi -dmenu -p "Select Wallpaper")
    
    if [ -z "$selected_wallpaper" ]; then
        return 0
    fi
    
    local wallpaper_path="$WALLPAPERS_DIR/$selected_wallpaper"
    
    notify-send "Wallpaper Theme" "Generating theme from wallpaper..." --icon=preferences-desktop-wallpaper
    
    # Generate colors with pywal
    if command -v wal &> /dev/null; then
        wal -i "$wallpaper_path" -n
        
        # Create theme file from pywal colors
        create_theme_from_pywal "$selected_wallpaper"
        
        # Set wallpaper
        set_wallpaper "$wallpaper_path"
        
        notify-send "Wallpaper Theme" "Theme generated and applied!" --icon=preferences-desktop-wallpaper
    else
        notify-send "Wallpaper Theme" "pywal not installed" --icon=dialog-error
    fi
}

create_theme_from_pywal() {
    local wallpaper_name="$1"
    local theme_name="wallpaper-$(echo "$wallpaper_name" | sed 's/\.[^.]*$//')"
    local theme_file="$THEMES_DIR/${theme_name}.conf"
    local colors_file="$HOME/.cache/wal/colors"
    
    if [ ! -f "$colors_file" ]; then
        return 1
    fi
    
    # Read pywal colors
    local colors=($(cat "$colors_file"))
    
    # Create theme file
    cat > "$theme_file" << 'THEME_EOF'
# Generated theme from wallpaper: $wallpaper_name

\$background = 0x${colors[0]#?}
\$foreground = 0x${colors[7]#?}
\$color1 = 0x${colors[1]#?}
\$color2 = 0x${colors[2]#?}
\$color3 = 0x${colors[3]#?}
\$color4 = 0x${colors[4]#?}
\$color5 = 0x${colors[5]#?}
\$color6 = 0x${colors[6]#?}
\$color8 = 0x${colors[8]#?}
\$color9 = 0x${colors[9]#?}
\$color10 = 0x${colors[10]#?}
\$color11 = 0x${colors[11]#?}
\$color12 = 0x${colors[12]#?}
\$color13 = 0x${colors[13]#?}
\$color14 = 0x${colors[14]#?}
\$color15 = 0x${colors[15]#?}

general {
    col.active_border = rgb(\$color4) rgb(\$color5) 45deg
    col.inactive_border = rgb(\$color8)
}

decoration {
    col.shadow = rgba(\$background, 0.5)
}
THEME_EOF
    
    # Apply the generated theme
    "$HOME/.config/hypr/scripts/theme-switcher.sh" apply "$theme_name"
}

set_wallpaper() {
    local wallpaper_path="$1"
    
    # Set with hyprpaper if available
    if command -v hyprpaper &> /dev/null; then
        echo "wallpaper = ,$wallpaper_path" > "$HOME/.config/hypr/hyprpaper.conf"
        echo "splash = false" >> "$HOME/.config/hypr/hyprpaper.conf"
        killall hyprpaper 2> /dev/null
        hyprpaper &
    elif command -v feh &> /dev/null; then
        feh --bg-fill "$wallpaper_path"
    elif command -v nitrogen &> /dev/null; then
        nitrogen --set-zoom-fill "$wallpaper_path"
    fi
}

case "$1" in
    "generate")
        generate_theme_from_wallpaper
        ;;
    *)
        echo "Usage: $0 {generate}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/wallpaper-theme.sh"
}

create_auto_theme_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/auto-theme.sh" << 'EOF'
#!/bin/bash
# Auto Theme Script for HyprSupreme

AUTO_THEME_CONFIG="$HOME/.config/hypr/auto-theme.conf"

toggle_auto_theme() {
    if is_auto_theme_enabled; then
        disable_auto_theme
    else
        enable_auto_theme
    fi
}

enable_auto_theme() {
    # Create auto theme config
    cat > "\$AUTO_THEME_CONFIG" << AUTOEOF
# Auto Theme Configuration
ENABLED=true
LIGHT_THEME=catppuccin-latte
DARK_THEME=catppuccin-mocha
LIGHT_START=06:00
DARK_START=18:00
AUTOEOF
    
    # Start auto theme service
    start_auto_theme_service
    
    notify-send "Auto Theme" "Auto theme switching enabled" --icon=preferences-desktop-theme
}

disable_auto_theme() {
    echo "ENABLED=false" > "$AUTO_THEME_CONFIG"
    stop_auto_theme_service
    notify-send "Auto Theme" "Auto theme switching disabled" --icon=preferences-desktop-theme
}

start_auto_theme_service() {
    # Kill existing auto theme process
    pkill -f "auto-theme-monitor"
    
    # Start new auto theme monitor
    nohup bash -c '
        while true; do
            if [ -f "'$AUTO_THEME_CONFIG'" ]; then
                source "'$AUTO_THEME_CONFIG'"
                if [ "$ENABLED" = "true" ]; then
                    current_hour=$(date +%H)
                    light_hour=${LIGHT_START%:*}
                    dark_hour=${DARK_START%:*}
                    
                    if [ $current_hour -ge $light_hour ] && [ $current_hour -lt $dark_hour ]; then
                        # Light theme time
                        current_theme=$("'$HOME'/.config/hypr/scripts/theme-switcher.sh" current)
                        if [ "$current_theme" != "$LIGHT_THEME" ]; then
                            "'$HOME'/.config/hypr/scripts/theme-switcher.sh" apply "$LIGHT_THEME"
                        fi
                    else
                        # Dark theme time
                        current_theme=$("'$HOME'/.config/hypr/scripts/theme-switcher.sh" current)
                        if [ "$current_theme" != "$DARK_THEME" ]; then
                            "'$HOME'/.config/hypr/scripts/theme-switcher.sh" apply "$DARK_THEME"
                        fi
                    fi
                fi
            fi
            sleep 300  # Check every 5 minutes
        done
    ' > /dev/null 2>&1 &
    
    echo $! > "$HOME/.cache/auto-theme-monitor.pid"
}

stop_auto_theme_service() {
    if [ -f "$HOME/.cache/auto-theme-monitor.pid" ]; then
        local pid=$(cat "$HOME/.cache/auto-theme-monitor.pid")
        kill "$pid" 2> /dev/null
        rm -f "$HOME/.cache/auto-theme-monitor.pid"
    fi
    pkill -f "auto-theme-monitor"
}

is_auto_theme_enabled() {
    if [ -f "$AUTO_THEME_CONFIG" ]; then
        source "$AUTO_THEME_CONFIG"
        [ "$ENABLED" = "true" ]
    else
        false
    fi
}

case "$1" in
    "toggle")
        toggle_auto_theme
        ;;
    "enable")
        enable_auto_theme
        ;;
    "disable")
        disable_auto_theme
        ;;
    "status")
        if is_auto_theme_enabled; then
            echo "enabled"
        else
            echo "disabled"
        fi
        ;;
    *)
        echo "Usage: $0 {toggle|enable|disable|status}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/auto-theme.sh"
}

create_theme_manager_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/theme-manager.sh" << 'EOF'
#!/bin/bash
# Theme Manager Script for HyprSupreme

THEMES_DIR="$HOME/.config/hypr/themes"
WALLPAPERS_DIR="$HOME/.config/hypr/wallpapers"

show_manager_menu() {
    local menu="🎨 Theme Gallery
🖼️ Wallpaper Gallery
⏰ Schedule Auto Theme
🔄 Import Theme
📥 Export Theme
⚙️ Theme Settings"
    
    local selection=$(echo "$menu" | rofi -dmenu -p "Theme Manager" -theme-str 'window {width: 40%;}')
    
    case "$selection" in
        *"Theme Gallery"*)
            show_theme_gallery
            ;;
        *"Wallpaper Gallery"*)
            show_wallpaper_gallery
            ;;
        *"Schedule Auto Theme"*)
            configure_auto_theme
            ;;
        *"Import Theme"*)
            import_theme
            ;;
        *"Export Theme"*)
            export_theme
            ;;
        *"Theme Settings"*)
            show_theme_settings
            ;;
    esac
}

show_theme_gallery() {
    local themes=""
    for theme_file in "$THEMES_DIR"/*.conf; do
        if [ -f "$theme_file" ]; then
            local theme_name=$(basename "$theme_file" .conf)
            themes+="$theme_name\n"
        fi
    done
    
    local selected=$(echo -e "$themes" | rofi -dmenu -p "Theme Gallery")
    if [ -n "$selected" ]; then
        "$HOME/.config/hypr/scripts/theme-switcher.sh" apply "$selected"
    fi
}

show_wallpaper_gallery() {
    local wallpapers=""
    for img in "$WALLPAPERS_DIR"/*.{jpg,jpeg,png,webp}; do
        if [ -f "$img" ]; then
            wallpapers+="$(basename "$img")\n"
        fi
    done
    
    local selected=$(echo -e "$wallpapers" | rofi -dmenu -p "Wallpaper Gallery")
    if [ -n "$selected" ]; then
        "$HOME/.config/hypr/scripts/wallpaper-theme.sh" generate
    fi
}

configure_auto_theme() {
    notify-send "Theme Manager" "Auto theme configuration" --icon=preferences-desktop-theme
    # This could open a more detailed configuration dialog
    "$HOME/.config/hypr/scripts/auto-theme.sh" toggle
}

case "$1" in
    "menu")
        show_manager_menu
        ;;
    *)
        echo "Usage: $0 {menu}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/theme-manager.sh"
}

# Test theme switcher installation
test_theme_switcher() {
    log_info "Testing theme switcher system..."
    
    # Check if pywal is available
    if command -v wal &> /dev/null; then
        log_success "✅ Pywal theme generator available"
    else
        log_warn "⚠️  Pywal not available for wallpaper themes"
    fi
    
    # Check if theme directories exist
    if [ -d "$HOME/.config/hypr/themes" ]; then
        log_success "✅ Theme directories created"
    else
        log_error "❌ Theme directories not found"
        return 1
    fi
    
    # Check if default themes exist
    local theme_count=$(ls "$HOME/.config/hypr/themes"/*.conf 2> /dev/null | wc -l)
    if [ "$theme_count" -gt 0 ]; then
        log_success "✅ Default themes available ($theme_count themes)"
    else
        log_warn "⚠️  No themes found"
    fi
    
    return 0
}

# Main execution
case "${1:-install}" in
    "install")
        install_theme_switcher
        ;;
    "tools")
        install_theme_tools
        ;;
    "configure")
        configure_theme_integration
        ;;
    "test")
        test_theme_switcher
        ;;
    *)
        echo "Usage: $0 {install|tools|configure|test}"
        exit 1
        ;;
esac

