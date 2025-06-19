#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme-Builder - Scripts Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_scripts() {
    log_info "Installing utility scripts..."
    
    # Create scripts directory
    local scripts_dir="$HOME/.config/hypr/scripts"
    local bin_dir="$HOME/.local/bin"
    
    mkdir -p "$scripts_dir" "$bin_dir"
    
    # Install various utility scripts
    install_system_scripts
    install_media_scripts
    install_window_management_scripts
    install_notification_scripts
    install_theme_scripts
    
    # Install hyprsupreme management tools
    install_management_tools
    
    # Make sure scripts are executable
    chmod +x "$scripts_dir"/*.sh "$bin_dir"/hyprsupreme-* 2>/dev/null || true
    
    log_success "Scripts installation completed"
}

install_system_scripts() {
    log_info "Installing system utility scripts..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    # Power menu script
    local power_menu_script="$scripts_dir/power-menu.sh"
    
    cat > "$power_menu_script" << 'EOF'
#!/bin/bash
# Power Menu Script for HyprSupreme

# Rofi power menu
selected=$(echo -e "Lock\nLogout\nReboot\nShutdown\nSuspend\nHibernate" | rofi -dmenu -p "Power Menu" -theme-str 'window {width: 20%;}')

case $selected in
    "Lock")
        hyprlock
        ;;
    "Logout")
        hyprctl dispatch exit
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Hibernate")
        systemctl hibernate
        ;;
esac
EOF

    # System info script
    local system_info_script="$scripts_dir/system-info.sh"
    
    cat > "$system_info_script" << 'EOF'
#!/bin/bash
# System Info Script for HyprSupreme

# Get system information
hostname=$(hostname)
kernel=$(uname -r)
uptime=$(uptime -p)
memory=$(free -h | awk '/^Mem:/ {print $3"/"$2}')
cpu=$(lscpu | grep "Model name" | sed 's/Model name: *//')
gpu=$(lspci | grep -E "VGA|3D" | cut -d: -f3)

# Display using rofi
info="Hostname: $hostname
Kernel: $kernel
Uptime: $uptime
Memory: $memory
CPU: $cpu
GPU: $gpu"

echo "$info" | rofi -dmenu -p "System Info" -theme-str 'window {width: 50%;} listview {lines: 6;}'
EOF

    # Screenshot script
    local screenshot_script="$scripts_dir/screenshot.sh"
    
    cat > "$screenshot_script" << 'EOF'
#!/bin/bash
# Screenshot Script for HyprSupreme

screenshot_dir="$HOME/Pictures/Screenshots"
mkdir -p "$screenshot_dir"

case "$1" in
    "full")
        filename="$screenshot_dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
        grim "$filename"
        notify-send "Screenshot" "Saved to $filename"
        ;;
    "area")
        filename="$screenshot_dir/screenshot-area-$(date +%Y%m%d-%H%M%S).png"
        grim -g "$(slurp)" "$filename"
        notify-send "Screenshot" "Area saved to $filename"
        ;;
    "window")
        filename="$screenshot_dir/screenshot-window-$(date +%Y%m%d-%H%M%S).png"
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$filename"
        notify-send "Screenshot" "Window saved to $filename"
        ;;
    *)
        echo "Usage: $0 {full|area|window}"
        ;;
esac
EOF

    # Quick settings script
    local quick_settings_script="$scripts_dir/quick-settings.sh"
    
    cat > "$quick_settings_script" << 'EOF'
#!/bin/bash
# Quick Settings Script for HyprSupreme

# Get current states
wifi_status=$(nmcli -t -f WIFI general)
bluetooth_status=$(bluetoothctl show | grep "Powered: yes" >/dev/null && echo "on" || echo "off")
dnd_status="off"  # TODO: implement DND status check

# Create menu
menu="󰖩 WiFi ($wifi_status)
󰂯 Bluetooth ($bluetooth_status)
󰂚 Do Not Disturb ($dnd_status)
󰻠 Night Light
󰢻 Blue Light Filter
󰍹 Display Settings
󰍃 Audio Settings
󰂔 Network Settings"

selected=$(echo "$menu" | rofi -dmenu -p "Quick Settings" -theme-str 'window {width: 30%;}')

case "$selected" in
    *"WiFi"*)
        if [ "$wifi_status" = "enabled" ]; then
            nmcli radio wifi off
            notify-send "WiFi" "Disabled"
        else
            nmcli radio wifi on
            notify-send "WiFi" "Enabled"
        fi
        ;;
    *"Bluetooth"*)
        if [ "$bluetooth_status" = "on" ]; then
            bluetoothctl power off
            notify-send "Bluetooth" "Disabled"
        else
            bluetoothctl power on
            notify-send "Bluetooth" "Enabled"
        fi
        ;;
    *"Display Settings"*)
        hyprctl dispatch exec 'nwg-displays'
        ;;
    *"Audio Settings"*)
        hyprctl dispatch exec 'pavucontrol'
        ;;
    *"Network Settings"*)
        hyprctl dispatch exec 'nm-connection-editor'
        ;;
esac
EOF

    log_success "System utility scripts installed"
}

install_media_scripts() {
    log_info "Installing media control scripts..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    # Media control script
    local media_script="$scripts_dir/media-control.sh"
    
    cat > "$media_script" << 'EOF'
#!/bin/bash
# Media Control Script for HyprSupreme

case "$1" in
    "play-pause")
        playerctl play-pause
        ;;
    "next")
        playerctl next
        ;;
    "previous")
        playerctl previous
        ;;
    "stop")
        playerctl stop
        ;;
    "volume-up")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    "volume-down")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    "volume-mute")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        echo "Usage: $0 {play-pause|next|previous|stop|volume-up|volume-down|volume-mute}"
        ;;
esac

# Show OSD notification
if command -v dunstify >/dev/null; then
    case "$1" in
        "volume-up"|"volume-down"|"volume-mute")
            volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
            muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o MUTED)
            if [ "$muted" = "MUTED" ]; then
                dunstify -u low -r 2593 -h int:value:0 "Audio" "Muted"
            else
                dunstify -u low -r 2593 -h int:value:$volume "Audio" "Volume: $volume%"
            fi
            ;;
        "play-pause"|"next"|"previous"|"stop")
            status=$(playerctl status 2>/dev/null || echo "No player")
            title=$(playerctl metadata title 2>/dev/null || echo "Unknown")
            artist=$(playerctl metadata artist 2>/dev/null || echo "Unknown")
            dunstify -u low -r 2594 "Media" "$status\n$artist - $title"
            ;;
    esac
fi
EOF

    # Brightness control script
    local brightness_script="$scripts_dir/brightness-control.sh"
    
    cat > "$brightness_script" << 'EOF'
#!/bin/bash
# Brightness Control Script for HyprSupreme

case "$1" in
    "up")
        brightnessctl set 10%+
        ;;
    "down")
        brightnessctl set 10%-
        ;;
    *)
        echo "Usage: $0 {up|down}"
        ;;
esac

# Show OSD notification
if command -v dunstify >/dev/null; then
    brightness=$(brightnessctl get)
    max_brightness=$(brightnessctl max)
    percentage=$((brightness * 100 / max_brightness))
    dunstify -u low -r 2595 -h int:value:$percentage "Brightness" "Brightness: $percentage%"
fi
EOF

    log_success "Media control scripts installed"
}

install_window_management_scripts() {
    log_info "Installing window management scripts..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    # Window switcher script
    local window_switcher_script="$scripts_dir/window-switcher.sh"
    
    cat > "$window_switcher_script" << 'EOF'
#!/bin/bash
# Window Switcher Script for HyprSupreme

# Get window list
windows=$(hyprctl clients -j | jq -r '.[] | "\(.class) - \(.title) (\(.workspace.name)) [\(.address)]"')

if [ -z "$windows" ]; then
    notify-send "Window Switcher" "No windows found"
    exit 0
fi

# Show window selection
selected=$(echo "$windows" | rofi -dmenu -p "Switch to Window" -theme-str 'window {width: 60%;}')

if [ -n "$selected" ]; then
    # Extract window address
    address=$(echo "$selected" | grep -o '\[0x[^]]*\]' | tr -d '[]')
    
    if [ -n "$address" ]; then
        hyprctl dispatch focuswindow "address:$address"
    fi
fi
EOF

    # Workspace manager script
    local workspace_script="$scripts_dir/workspace-manager.sh"
    
    cat > "$workspace_script" << 'EOF'
#!/bin/bash
# Workspace Manager Script for HyprSupreme

case "$1" in
    "list")
        workspaces=$(hyprctl workspaces -j | jq -r '.[] | "Workspace \(.id): \(.windows) windows"')
        echo "$workspaces" | rofi -dmenu -p "Workspaces" -theme-str 'window {width: 40%;}'
        ;;
    "switch")
        workspace=$(seq 1 10 | rofi -dmenu -p "Switch to Workspace")
        if [ -n "$workspace" ]; then
            hyprctl dispatch workspace "$workspace"
        fi
        ;;
    "move")
        workspace=$(seq 1 10 | rofi -dmenu -p "Move Window to Workspace")
        if [ -n "$workspace" ]; then
            hyprctl dispatch movetoworkspace "$workspace"
        fi
        ;;
    *)
        echo "Usage: $0 {list|switch|move}"
        ;;
esac
EOF

    log_success "Window management scripts installed"
}

install_notification_scripts() {
    log_info "Installing notification scripts..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    # Notification center script
    local notification_script="$scripts_dir/notification-center.sh"
    
    cat > "$notification_script" << 'EOF'
#!/bin/bash
# Notification Center Script for HyprSupreme

case "$1" in
    "clear")
        dunstctl close-all
        notify-send "Notifications" "All notifications cleared"
        ;;
    "toggle")
        if dunstctl is-paused | grep -q "false"; then
            dunstctl set-paused true
            notify-send "Do Not Disturb" "Enabled"
        else
            dunstctl set-paused false
            notify-send "Do Not Disturb" "Disabled"
        fi
        ;;
    "history")
        dunstctl history
        ;;
    *)
        echo "Usage: $0 {clear|toggle|history}"
        ;;
esac
EOF

    log_success "Notification scripts installed"
}

install_theme_scripts() {
    log_info "Installing theme management scripts..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    # Theme switcher script
    local theme_script="$scripts_dir/theme-switcher.sh"
    
    cat > "$theme_script" << 'EOF'
#!/bin/bash
# Theme Switcher Script for HyprSupreme

themes_dir="$HOME/.themes"
current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")

# Get available themes
themes=$(find "$themes_dir" /usr/share/themes -maxdepth 1 -type d -name "*" -exec basename {} \; 2>/dev/null | sort | uniq | grep -v "^themes$")

if [ -z "$themes" ]; then
    notify-send "Theme Switcher" "No themes found"
    exit 0
fi

# Show theme selection with current theme highlighted
selected=$(echo "$themes" | rofi -dmenu -p "Current: $current_theme" -theme-str 'window {width: 40%;}')

if [ -n "$selected" ] && [ "$selected" != "$current_theme" ]; then
    # Apply GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "$selected"
    gsettings set org.gnome.desktop.wm.preferences theme "$selected"
    
    notify-send "Theme Switcher" "Changed theme to: $selected"
fi
EOF

    # Icon theme switcher script
    local icon_theme_script="$scripts_dir/icon-theme-switcher.sh"
    
    cat > "$icon_theme_script" << 'EOF'
#!/bin/bash
# Icon Theme Switcher Script for HyprSupreme

icons_dir="$HOME/.icons"
current_icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")

# Get available icon themes
icon_themes=$(find "$icons_dir" /usr/share/icons -maxdepth 1 -type d -name "*" -exec basename {} \; 2>/dev/null | sort | uniq | grep -v "^icons$")

if [ -z "$icon_themes" ]; then
    notify-send "Icon Theme Switcher" "No icon themes found"
    exit 0
fi

# Show icon theme selection
selected=$(echo "$icon_themes" | rofi -dmenu -p "Current Icons: $current_icon_theme" -theme-str 'window {width: 40%;}')

if [ -n "$selected" ] && [ "$selected" != "$current_icon_theme" ]; then
    # Apply icon theme
    gsettings set org.gnome.desktop.interface icon-theme "$selected"
    
    notify-send "Icon Theme Switcher" "Changed icons to: $selected"
fi
EOF

    log_success "Theme management scripts installed"
}

install_management_tools() {
    log_info "Installing HyprSupreme management tools..."
    
    local bin_dir="$HOME/.local/bin"
    
    # Main configuration tool
    local config_tool="$bin_dir/hyprsupreme-config"
    
    cat > "$config_tool" << 'EOF'
#!/bin/bash
# HyprSupreme Configuration Tool

HYPRSUPREME_DIR="$HOME/.config/hypr"

show_menu() {
    echo "🚀 HyprSupreme Configuration Tool"
    echo ""
    echo "1. Theme Management"
    echo "2. Wallpaper Management"
    echo "3. System Information"
    echo "4. Update HyprSupreme"
    echo "5. Backup Configuration"
    echo "6. Restore Configuration"
    echo "7. Reset to Defaults"
    echo "8. Exit"
    echo ""
    read -p "Select option [1-8]: " choice
}

theme_menu() {
    echo "Theme Management:"
    echo "1. Change GTK Theme"
    echo "2. Change Icon Theme"
    echo "3. Change Cursor Theme"
    echo "4. Change Wallpaper"
    echo "5. Back to Main Menu"
    read -p "Select option [1-5]: " theme_choice
    
    case $theme_choice in
        1) "$HYPRSUPREME_DIR/scripts/theme-switcher.sh" ;;
        2) "$HYPRSUPREME_DIR/scripts/icon-theme-switcher.sh" ;;
        3) lxappearance ;;
        4) "$HYPRSUPREME_DIR/scripts/wallpaper-selector.sh" ;;
        5) return ;;
    esac
}

wallpaper_menu() {
    echo "Wallpaper Management:"
    echo "1. Select Wallpaper"
    echo "2. Random Wallpaper"
    echo "3. Time-based Wallpaper"
    echo "4. Back to Main Menu"
    read -p "Select option [1-4]: " wall_choice
    
    case $wall_choice in
        1) "$HYPRSUPREME_DIR/scripts/wallpaper-selector.sh" ;;
        2) "$HYPRSUPREME_DIR/scripts/random-wallpaper.sh" ;;
        3) "$HYPRSUPREME_DIR/scripts/time-wallpaper.sh" ;;
        4) return ;;
    esac
}

while true; do
    clear
    show_menu
    
    case $choice in
        1) theme_menu ;;
        2) wallpaper_menu ;;
        3) "$HYPRSUPREME_DIR/scripts/system-info.sh" ;;
        4) echo "Update feature coming soon..." ;;
        5) echo "Backup feature coming soon..." ;;
        6) echo "Restore feature coming soon..." ;;
        7) echo "Reset feature coming soon..." ;;
        8) exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
EOF

    # Status tool
    local status_tool="$bin_dir/hyprsupreme-status"
    
    cat > "$status_tool" << 'EOF'
#!/bin/bash
# HyprSupreme Status Tool

echo "🚀 HyprSupreme Status"
echo "===================="

# Check Hyprland
if pgrep -x "Hyprland" > /dev/null; then
    echo "✅ Hyprland is running"
else
    echo "❌ Hyprland is not running"
fi

# Check Waybar
if pgrep -x "waybar" > /dev/null; then
    echo "✅ Waybar is running"
else
    echo "❌ Waybar is not running"
fi

# Check AGS
if pgrep -x "ags" > /dev/null; then
    echo "✅ AGS is running"
else
    echo "⚠️  AGS is not running (optional)"
fi

# Check Hyprpaper
if pgrep -x "hyprpaper" > /dev/null; then
    echo "✅ Hyprpaper is running"
else
    echo "❌ Hyprpaper is not running"
fi

# Check configuration files
config_files=(
    "$HOME/.config/hypr/hyprland.conf"
    "$HOME/.config/waybar/config.jsonc"
    "$HOME/.config/rofi/config.rasi"
    "$HOME/.config/kitty/kitty.conf"
)

echo ""
echo "Configuration Files:"
for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $(basename "$file")"
    else
        echo "❌ $(basename "$file")"
    fi
done

echo ""
echo "System Info:"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "GPU: $(lspci | grep -E "VGA|3D" | cut -d: -f3 | head -1)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
EOF

    # Update script template
    local update_tool="$bin_dir/hyprsupreme-update"
    
    cat > "$update_tool" << 'EOF'
#!/bin/bash
# HyprSupreme Update Tool

echo "🚀 HyprSupreme Update Tool"
echo "========================="

echo "This feature will be implemented to:"
echo "- Check for HyprSupreme updates"
echo "- Update configuration files"
echo "- Backup before updating"
echo "- Merge new features"

echo ""
echo "Coming soon in a future release!"
EOF

    log_success "HyprSupreme management tools installed"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_scripts
fi

