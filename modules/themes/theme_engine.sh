#!/bin/bash
# HyprSupreme-Builder - Unified Theme Engine

source "$(dirname "$0")/../common/functions.sh"

THEME_DIR="$HOME/.config/hypr/themes"
THEME_CACHE_DIR="$HOME/.cache/hyprsupreme/themes"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Initialize theme engine
init_theme_engine() {
    log_info "Initializing HyprSupreme Theme Engine..."
    
    # Create necessary directories
    mkdir -p "$THEME_DIR"
    mkdir -p "$THEME_CACHE_DIR"
    mkdir -p "$WALLPAPER_DIR"
    mkdir -p "$HOME/.config/hypr/scripts"
    
    # Install theme dependencies
    install_theme_dependencies
    
    # Create built-in themes
    create_builtin_themes
    
    # Install theme management tools
    install_theme_tools
    
    log_success "Theme engine initialized"
}

install_theme_dependencies() {
    log_info "Installing theme dependencies..."
    
    local packages=(
        "imagemagick"          # For color extraction
        "python-pillow"        # For image processing
        "python-colorthief"    # For dominant color extraction
        "swww"                 # For wallpaper management
        "hyprpaper"           # Alternative wallpaper tool
        "matugen"             # Material You color generation
        "pywal"               # Color scheme generation
    )
    
    install_packages "${packages[@]}"
}

create_builtin_themes() {
    log_info "Creating built-in themes..."
    
    # Catppuccin Mocha
    create_catppuccin_mocha_theme
    
    # Catppuccin Latte
    create_catppuccin_latte_theme
    
    # Nord theme
    create_nord_theme
    
    # Dracula theme
    create_dracula_theme
    
    # Gruvbox theme
    create_gruvbox_theme
    
    # Tokyo Night theme
    create_tokyo_night_theme
}

create_catppuccin_mocha_theme() {
    local theme_file="$THEME_DIR/catppuccin-mocha.conf"
    
    cat > "$theme_file" << 'EOF'
# Catppuccin Mocha Theme
$rosewater = 0xfff5e0dc
$flamingo = 0xfff2cdcd
$pink = 0xfff5c2e7
$mauve = 0xffcba6f7
$red = 0xfff38ba8
$maroon = 0xffeba0ac
$peach = 0xfffab387
$yellow = 0xfff9e2af
$green = 0xffa6e3a1
$teal = 0xff94e2d5
$sky = 0xff89dceb
$sapphire = 0xff74c7ec
$blue = 0xff89b4fa
$lavender = 0xffb4befe
$text = 0xffcdd6f4
$subtext1 = 0xffbac2de
$subtext0 = 0xffa6adc8
$overlay2 = 0xff9399b2
$overlay1 = 0xff7f849c
$overlay0 = 0xff6c7086
$surface2 = 0xff585b70
$surface1 = 0xff45475a
$surface0 = 0xff313244
$base = 0xff1e1e2e
$mantle = 0xff181825
$crust = 0xff11111b

general {
    col.active_border = $blue $mauve 45deg
    col.inactive_border = $surface0
}

decoration {
    col.shadow = $crust
}

# Window rules with theme colors
windowrulev2 = bordercolor $red, class:(firefox)
windowrulev2 = bordercolor $green, class:(kitty)
windowrulev2 = bordercolor $blue, class:(code)
EOF
}

create_catppuccin_latte_theme() {
    local theme_file="$THEME_DIR/catppuccin-latte.conf"
    
    cat > "$theme_file" << 'EOF'
# Catppuccin Latte Theme
$rosewater = 0xffdc8a78
$flamingo = 0xffdd7878
$pink = 0xffea76cb
$mauve = 0xff8839ef
$red = 0xffd20f39
$maroon = 0xffe64553
$peach = 0xfffe640b
$yellow = 0xffdf8e1d
$green = 0xff40a02b
$teal = 0xff179299
$sky = 0xff04a5e5
$sapphire = 0xff209fb5
$blue = 0xff1e66f5
$lavender = 0xff7287fd
$text = 0xff4c4f69
$subtext1 = 0xff5c5f77
$subtext0 = 0xff6c6f85
$overlay2 = 0xff7c7f93
$overlay1 = 0xff8c8fa1
$overlay0 = 0xff9ca0b0
$surface2 = 0xffacb0be
$surface1 = 0xffbcc0cc
$surface0 = 0xffccd0da
$base = 0xffeff1f5
$mantle = 0xffe6e9ef
$crust = 0xffdce0e8

general {
    col.active_border = $blue $mauve 45deg
    col.inactive_border = $surface2
}

decoration {
    col.shadow = $crust
}
EOF
}

create_nord_theme() {
    local theme_file="$THEME_DIR/nord.conf"
    
    cat > "$theme_file" << 'EOF'
# Nord Theme
$nord0 = 0xff2e3440
$nord1 = 0xff3b4252
$nord2 = 0xff434c5e
$nord3 = 0xff4c566a
$nord4 = 0xffd8dee9
$nord5 = 0xffe5e9f0
$nord6 = 0xffeceff4
$nord7 = 0xff8fbcbb
$nord8 = 0xff88c0d0
$nord9 = 0xff81a1c1
$nord10 = 0xff5e81ac
$nord11 = 0xffbf616a
$nord12 = 0xffd08770
$nord13 = 0xffebcb8b
$nord14 = 0xffa3be8c
$nord15 = 0xffb48ead

general {
    col.active_border = $nord8 $nord9 45deg
    col.inactive_border = $nord3
}

decoration {
    col.shadow = $nord0
}
EOF
}

create_dracula_theme() {
    local theme_file="$THEME_DIR/dracula.conf"
    
    cat > "$theme_file" << 'EOF'
# Dracula Theme
$background = 0xff282a36
$current_line = 0xff44475a
$foreground = 0xfff8f8f2
$comment = 0xff6272a4
$cyan = 0xff8be9fd
$green = 0xff50fa7b
$orange = 0xffffb86c
$pink = 0xffff79c6
$purple = 0xffbd93f9
$red = 0xffff5555
$yellow = 0xfff1fa8c

general {
    col.active_border = $purple $pink 45deg
    col.inactive_border = $current_line
}

decoration {
    col.shadow = $background
}
EOF
}

create_gruvbox_theme() {
    local theme_file="$THEME_DIR/gruvbox.conf"
    
    cat > "$theme_file" << 'EOF'
# Gruvbox Theme
$bg = 0xff282828
$bg1 = 0xff3c3836
$bg2 = 0xff504945
$bg3 = 0xff665c54
$bg4 = 0xff7c6f64
$fg = 0xffebdbb2
$fg2 = 0xffd5c4a1
$fg3 = 0xffbdae93
$fg4 = 0xffa89984
$red = 0xffcc241d
$green = 0xff98971a
$yellow = 0xffd79921
$blue = 0xff458588
$purple = 0xffb16286
$aqua = 0xff689d6a
$orange = 0xffd65d0e

general {
    col.active_border = $yellow $orange 45deg
    col.inactive_border = $bg3
}

decoration {
    col.shadow = $bg
}
EOF
}

create_tokyo_night_theme() {
    local theme_file="$THEME_DIR/tokyo-night.conf"
    
    cat > "$theme_file" << 'EOF'
# Tokyo Night Theme
$bg = 0xff1a1b26
$bg_dark = 0xff16161e
$bg_highlight = 0xff292e42
$terminal_black = 0xff414868
$fg = 0xffc0caf5
$fg_dark = 0xffa9b1d6
$fg_gutter = 0xff3b4261
$dark3 = 0xff545c7e
$comment = 0xff565f89
$dark5 = 0xff737aa2
$blue0 = 0xff3d59a1
$blue = 0xff7aa2f7
$cyan = 0xff7dcfff
$blue1 = 0xff2ac3de
$blue2 = 0xff0db9d7
$blue5 = 0xff89ddff
$blue6 = 0xffb4f9f8
$blue7 = 0xff394b70
$purple = 0xff9d7cd8
$magenta = 0xffbb9af7
$magenta2 = 0xffff007c
$red = 0xfff7768e
$red1 = 0xffdb4b4b
$orange = 0xffff9e64
$yellow = 0xffe0af68
$green = 0xff9ece6a
$green1 = 0xff73daca
$green2 = 0xff41a6b5
$teal = 0xff1abc9c

general {
    col.active_border = $blue $purple 45deg
    col.inactive_border = $bg_highlight
}

decoration {
    col.shadow = $bg_dark
}
EOF
}

install_theme_tools() {
    log_info "Installing theme management tools..."
    
    # Create main theme manager script
    create_theme_manager
    
    # Create color extraction script
    create_color_extractor
    
    # Create wallpaper manager
    create_wallpaper_manager
    
    # Create theme preview tool
    create_theme_preview
}

create_theme_manager() {
    local script_file="$HOME/.config/hypr/scripts/theme-manager.sh"
    
    cat > "$script_file" << 'EOF'
#!/bin/bash
# HyprSupreme Theme Manager

THEME_DIR="$HOME/.config/hypr/themes"
CURRENT_THEME_FILE="$HOME/.config/hypr/.current_theme"
CONFIG_DIR="$HOME/.config"

apply_theme() {
    local theme_name="$1"
    local theme_file="$THEME_DIR/$theme_name.conf"
    
    if [[ ! -f "$theme_file" ]]; then
        notify-send "Theme Error" "Theme '$theme_name' not found"
        return 1
    fi
    
    # Update Hyprland theme
    echo "source = $theme_file" > "$HOME/.config/hypr/UserConfigs/Theme.conf"
    
    # Update Waybar theme if applicable
    if [[ -f "$THEME_DIR/waybar-$theme_name.css" ]]; then
        cp "$THEME_DIR/waybar-$theme_name.css" "$CONFIG_DIR/waybar/style.css"
    fi
    
    # Update Rofi theme if applicable
    if [[ -f "$THEME_DIR/rofi-$theme_name.rasi" ]]; then
        echo "@theme \"$THEME_DIR/rofi-$theme_name.rasi\"" > "$CONFIG_DIR/rofi/config.rasi"
    fi
    
    # Update Kitty theme if applicable
    if [[ -f "$THEME_DIR/kitty-$theme_name.conf" ]]; then
        echo "include $THEME_DIR/kitty-$theme_name.conf" > "$CONFIG_DIR/kitty/theme.conf"
    fi
    
    # Save current theme
    echo "$theme_name" > "$CURRENT_THEME_FILE"
    
    # Reload Hyprland
    hyprctl reload
    
    # Restart Waybar
    killall waybar
    waybar &
    
    notify-send "Theme Applied" "Successfully switched to '$theme_name' theme"
}

list_themes() {
    find "$THEME_DIR" -name "*.conf" -exec basename {} .conf \;
}

get_current_theme() {
    if [[ -f "$CURRENT_THEME_FILE" ]]; then
        cat "$CURRENT_THEME_FILE"
    else
        echo "default"
    fi
}

case "$1" in
    "apply")
        apply_theme "$2"
        ;;
    "list")
        list_themes
        ;;
    "current")
        get_current_theme
        ;;
    *)
        echo "Usage: $0 {apply|list|current} [theme_name]"
        ;;
esac
EOF
    
    chmod +x "$script_file"
}

create_color_extractor() {
    local script_file="$HOME/.config/hypr/scripts/color-extractor.py"
    
    cat > "$script_file" << 'EOF'
#!/usr/bin/env python3
import sys
import os
from PIL import Image
from colorthief import ColorThief
import colorsys

def rgb_to_hex(rgb):
    """Convert RGB tuple to hex string."""
    return f"0xff{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"

def adjust_color(rgb, brightness=1.0, saturation=1.0):
    """Adjust brightness and saturation of RGB color."""
    h, s, v = colorsys.rgb_to_hsv(rgb[0]/255, rgb[1]/255, rgb[2]/255)
    s = min(1.0, s * saturation)
    v = min(1.0, v * brightness)
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return (int(r * 255), int(g * 255), int(b * 255))

def extract_colors(image_path, output_file):
    """Extract color palette from image."""
    try:
        color_thief = ColorThief(image_path)
        
        # Get dominant color
        dominant_color = color_thief.get_color(quality=1)
        
        # Get color palette
        palette = color_thief.get_palette(color_count=8)
        
        # Generate theme colors
        colors = {
            'primary': rgb_to_hex(dominant_color),
            'primary_light': rgb_to_hex(adjust_color(dominant_color, brightness=1.2)),
            'primary_dark': rgb_to_hex(adjust_color(dominant_color, brightness=0.8)),
            'secondary': rgb_to_hex(palette[1] if len(palette) > 1 else dominant_color),
            'background': rgb_to_hex(adjust_color(palette[-1], brightness=0.1)),
            'surface': rgb_to_hex(adjust_color(palette[-1], brightness=0.15)),
            'text': '0xffffffff' if sum(dominant_color) < 384 else '0xff000000',
        }
        
        # Write theme file
        with open(output_file, 'w') as f:
            f.write("# Auto-generated theme from wallpaper\n")
            for name, color in colors.items():
                f.write(f"${name} = {color}\n")
            
            f.write(f"\ngeneral {{\n")
            f.write(f"    col.active_border = {colors['primary']} {colors['secondary']} 45deg\n")
            f.write(f"    col.inactive_border = {colors['surface']}\n")
            f.write(f"}}\n\n")
            
            f.write(f"decoration {{\n")
            f.write(f"    col.shadow = {colors['background']}\n")
            f.write(f"}}\n")
        
        print(f"Theme generated: {output_file}")
        
    except Exception as e:
        print(f"Error extracting colors: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: color-extractor.py <image_path> <output_theme_file>")
        sys.exit(1)
    
    image_path = sys.argv[1]
    output_file = sys.argv[2]
    
    extract_colors(image_path, output_file)
EOF
    
    chmod +x "$script_file"
}

create_wallpaper_manager() {
    local script_file="$HOME/.config/hypr/scripts/wallpaper-manager.sh"
    
    cat > "$script_file" << 'EOF'
#!/bin/bash
# HyprSupreme Wallpaper Manager

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
THEME_DIR="$HOME/.config/hypr/themes"
CURRENT_WALLPAPER_FILE="$HOME/.config/hypr/.current_wallpaper"

set_wallpaper() {
    local wallpaper_path="$1"
    local generate_theme="$2"
    
    if [[ ! -f "$wallpaper_path" ]]; then
        notify-send "Wallpaper Error" "Wallpaper file not found"
        return 1
    fi
    
    # Set wallpaper using swww
    if command -v swww >/dev/null; then
        swww img "$wallpaper_path" --transition-type wipe --transition-duration 2
    elif command -v hyprpaper >/dev/null; then
        # Update hyprpaper config
        echo "preload = $wallpaper_path" > "$HOME/.config/hypr/hyprpaper.conf"
        echo "wallpaper = ,$wallpaper_path" >> "$HOME/.config/hypr/hyprpaper.conf"
        hyprctl hyprpaper wallpaper ",$wallpaper_path"
    fi
    
    # Save current wallpaper
    echo "$wallpaper_path" > "$CURRENT_WALLPAPER_FILE"
    
    # Generate theme from wallpaper if requested
    if [[ "$generate_theme" == "true" ]]; then
        local wallpaper_name=$(basename "$wallpaper_path" | sed 's/\.[^.]*$//')
        local theme_file="$THEME_DIR/auto-$wallpaper_name.conf"
        
        python3 "$HOME/.config/hypr/scripts/color-extractor.py" "$wallpaper_path" "$theme_file"
        
        if [[ $? -eq 0 ]]; then
            # Apply the generated theme
            "$HOME/.config/hypr/scripts/theme-manager.sh" apply "auto-$wallpaper_name"
        fi
    fi
    
    notify-send "Wallpaper Applied" "$(basename "$wallpaper_path")"
}

random_wallpaper() {
    local wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
    
    if [[ -n "$wallpaper" ]]; then
        set_wallpaper "$wallpaper" "$1"
    else
        notify-send "No Wallpapers" "No wallpapers found in $WALLPAPER_DIR"
    fi
}

get_current_wallpaper() {
    if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
        cat "$CURRENT_WALLPAPER_FILE"
    fi
}

case "$1" in
    "set")
        set_wallpaper "$2" "$3"
        ;;
    "random")
        random_wallpaper "$2"
        ;;
    "current")
        get_current_wallpaper
        ;;
    *)
        echo "Usage: $0 {set|random|current} [wallpaper_path] [generate_theme]"
        ;;
esac
EOF
    
    chmod +x "$script_file"
}

create_theme_preview() {
    local script_file="$HOME/.config/hypr/scripts/theme-preview.sh"
    
    cat > "$script_file" << 'EOF'
#!/bin/bash
# HyprSupreme Theme Preview Tool

THEME_DIR="$HOME/.config/hypr/themes"

preview_theme() {
    local theme_name="$1"
    local theme_file="$THEME_DIR/$theme_name.conf"
    
    if [[ ! -f "$theme_file" ]]; then
        echo "Theme not found: $theme_name"
        return 1
    fi
    
    # Create preview window with theme colors
    local preview_script="/tmp/theme_preview_$theme_name.sh"
    
    cat > "$preview_script" << EOF
#!/bin/bash
source "$theme_file"

# Create a preview window using kitty with theme colors
kitty --hold --title "Theme Preview: $theme_name" --override background=\${bg:-#1e1e2e} --override foreground=\${fg:-#cdd6f4} bash -c "
echo 'Theme Preview: $theme_name'
echo '================================'
echo 'Colors:'
echo 'Primary: \${primary:-N/A}'
echo 'Secondary: \${secondary:-N/A}'
echo 'Background: \${bg:-N/A}'
echo 'Foreground: \${fg:-N/A}'
echo ''
echo 'Press any key to close preview...'
read -n 1
"
EOF
    
    chmod +x "$preview_script"
    "$preview_script" &
}

list_themes_with_preview() {
    echo "Available themes:"
    for theme_file in "$THEME_DIR"/*.conf; do
        if [[ -f "$theme_file" ]]; then
            local theme_name=$(basename "$theme_file" .conf)
            echo "  - $theme_name"
        fi
    done
}

case "$1" in
    "preview")
        preview_theme "$2"
        ;;
    "list")
        list_themes_with_preview
        ;;
    *)
        echo "Usage: $0 {preview|list} [theme_name]"
        ;;
esac
EOF
    
    chmod +x "$script_file"
}

# Auto theme switching based on time/wallpaper
setup_auto_theming() {
    log_info "Setting up automatic theming..."
    
    # Create systemd service for auto theming
    local service_file="$HOME/.config/systemd/user/hyprsupreme-auto-theme.service"
    local timer_file="$HOME/.config/systemd/user/hyprsupreme-auto-theme.timer"
    
    mkdir -p "$(dirname "$service_file")"
    
    cat > "$service_file" << 'EOF'
[Unit]
Description=HyprSupreme Auto Theme Service
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=%h/.config/hypr/scripts/auto-theme.sh
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF
    
    cat > "$timer_file" << 'EOF'
[Unit]
Description=HyprSupreme Auto Theme Timer
Requires=hyprsupreme-auto-theme.service

[Timer]
OnCalendar=*:0/30  # Every 30 minutes
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Create auto theme script
    local auto_script="$HOME/.config/hypr/scripts/auto-theme.sh"
    
    cat > "$auto_script" << 'EOF'
#!/bin/bash
# HyprSupreme Auto Theme Script

hour=$(date +%H)
current_wallpaper=$("$HOME/.config/hypr/scripts/wallpaper-manager.sh" current)

# Time-based theming
if [[ $hour -ge 6 && $hour -lt 12 ]]; then
    # Morning - Light theme
    theme="catppuccin-latte"
elif [[ $hour -ge 12 && $hour -lt 18 ]]; then
    # Afternoon - Neutral theme
    theme="nord"
elif [[ $hour -ge 18 && $hour -lt 22 ]]; then
    # Evening - Warm theme
    theme="gruvbox"
else
    # Night - Dark theme
    theme="catppuccin-mocha"
fi

# Apply theme if different from current
current_theme=$("$HOME/.config/hypr/scripts/theme-manager.sh" current)
if [[ "$theme" != "$current_theme" ]]; then
    "$HOME/.config/hypr/scripts/theme-manager.sh" apply "$theme"
fi
EOF
    
    chmod +x "$auto_script"
    
    # Enable the timer
    systemctl --user daemon-reload
    systemctl --user enable hyprsupreme-auto-theme.timer
    systemctl --user start hyprsupreme-auto-theme.timer
    
    log_success "Auto theming configured"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        "init")
            init_theme_engine
            ;;
        "auto")
            setup_auto_theming
            ;;
        *)
            echo "Usage: $0 {init|auto}"
            ;;
    esac
fi

