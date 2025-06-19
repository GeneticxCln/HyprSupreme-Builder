#!/bin/bash
# HyprSupreme-Builder - Workspace and Time Management Module

source "$(dirname "$0")/../common/functions.sh"

install_workspace_time() {
    log_info "Installing workspace and time management..."
    
    # Configure workspace integration
    configure_workspace_integration
    
    # Configure time/date integration
    configure_time_integration
    
    log_success "Workspace and time management installation completed"
}

configure_workspace_integration() {
    log_info "Configuring workspace management..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    mkdir -p "$scripts_dir"
    
    # Create workspace management script
    cat > "$scripts_dir/workspace-manager.sh" << 'EOF'
#!/bin/bash
# Workspace Manager for HyprSupreme

show_workspace_menu() {
    local current_workspace=$(hyprctl activeworkspace | grep "workspace ID" | awk '{print $3}')
    local workspaces="1️⃣ Workspace 1 (Main)
2️⃣ Workspace 2 (Web)
3️⃣ Workspace 3 (Code)
4️⃣ Workspace 4 (Files)
5️⃣ Workspace 5 (Media)
6️⃣ Workspace 6 (Chat)
7️⃣ Workspace 7 (Games)
8️⃣ Workspace 8 (VM)
9️⃣ Workspace 9 (System)
🔟 Workspace 10 (Temp)"
    
    # Mark current workspace
    workspaces=$(echo "$workspaces" | sed "${current_workspace}s/^/✓ /")
    
    local selection=$(echo "$workspaces" | rofi -dmenu -p "Switch to Workspace")
    
    if [ -n "$selection" ]; then
        local workspace_num=$(echo "$selection" | grep -o '[0-9][0-9]*')
        if [ -n "$workspace_num" ]; then
            hyprctl dispatch workspace "$workspace_num"
        fi
    fi
}

move_to_workspace() {
    local workspaces="1️⃣ Workspace 1 (Main)
2️⃣ Workspace 2 (Web)
3️⃣ Workspace 3 (Code)
4️⃣ Workspace 4 (Files)
5️⃣ Workspace 5 (Media)
6️⃣ Workspace 6 (Chat)
7️⃣ Workspace 7 (Games)
8️⃣ Workspace 8 (VM)
9️⃣ Workspace 9 (System)
🔟 Workspace 10 (Temp)"
    
    local selection=$(echo "$workspaces" | rofi -dmenu -p "Move Window to Workspace")
    
    if [ -n "$selection" ]; then
        local workspace_num=$(echo "$selection" | grep -o '[0-9][0-9]*')
        if [ -n "$workspace_num" ]; then
            hyprctl dispatch movetoworkspace "$workspace_num"
        fi
    fi
}

workspace_overview() {
    local overview=""
    for i in {1..10}; do
        local windows=$(hyprctl workspaces | grep -A 5 "workspace ID $i" | grep "windows:" | awk '{print $2}')
        if [ -z "$windows" ]; then
            windows="0"
        fi
        overview+="Workspace $i: $windows windows\n"
    done
    
    echo -e "$overview" | rofi -dmenu -p "Workspace Overview" -theme-str 'window {width: 40%;}'
}

case "$1" in
    "menu")
        show_workspace_menu
        ;;
    "move")
        move_to_workspace
        ;;
    "overview")
        workspace_overview
        ;;
    *)
        echo "Usage: $0 {menu|move|overview}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/workspace-manager.sh"
}

configure_time_integration() {
    log_info "Configuring time and date management..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    # Create time/date display script
    cat > "$scripts_dir/time-date.sh" << 'EOF'
#!/bin/bash
# Time and Date Manager for HyprSupreme

show_time_menu() {
    local current_time=$(date '+%H:%M:%S')
    local current_date=$(date '+%A, %B %d, %Y')
    local timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
    local uptime=$(uptime -p)
    
    local menu="🕐 Current Time: $current_time
📅 Current Date: $current_date
🌍 Timezone: $timezone
⏱️ Uptime: $uptime

⚙️ Time Settings
🌐 Timezone Settings
⏰ Set Alarm
🗓️ Calendar"
    
    local selection=$(echo "$menu" | rofi -dmenu -p "Time & Date" -theme-str 'window {width: 50%;}')
    
    case "$selection" in
        *"Time Settings"*)
            if command -v gnome-control-center &> /dev/null; then
                gnome-control-center datetime
            else
                warp-terminal -e sudo timedatectl
            fi
            ;;
        *"Timezone Settings"*)
            show_timezone_menu
            ;;
        *"Set Alarm"*)
            set_alarm
            ;;
        *"Calendar"*)
            if command -v gnome-calendar &> /dev/null; then
                gnome-calendar
            elif command -v cal &> /dev/null; then
                warp-terminal -e cal
            fi
            ;;
    esac
}

show_timezone_menu() {
    local timezones="🇺🇸 America/New_York (EST)
🇺🇸 America/Chicago (CST)
🇺🇸 America/Denver (MST)
🇺🇸 America/Los_Angeles (PST)
🇬🇧 Europe/London (GMT)
🇩🇪 Europe/Berlin (CET)
🇯🇵 Asia/Tokyo (JST)
🇨🇳 Asia/Shanghai (CST)
🇦🇺 Australia/Sydney (AEST)
🇮🇳 Asia/Kolkata (IST)"
    
    local selection=$(echo "$timezones" | rofi -dmenu -p "Select Timezone")
    
    if [ -n "$selection" ]; then
        local tz=$(echo "$selection" | grep -o '[A-Z][a-z_]*/[A-Z][a-z_]*')
        if [ -n "$tz" ]; then
            sudo timedatectl set-timezone "$tz"
            notify-send "Timezone" "Timezone set to: $tz" --icon=preferences-system-time
        fi
    fi
}

set_alarm() {
    local time_input=$(rofi -dmenu -p "Set alarm time (HH:MM):")
    
    if [[ $time_input =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        local message_input=$(rofi -dmenu -p "Alarm message (optional):")
        local message=${message_input:-"Alarm"}
        
        # Schedule alarm using at command
        if command -v at &> /dev/null; then
            echo "notify-send 'Alarm' '$message' --icon=alarm-clock --urgency=critical" | at "$time_input"
            notify-send "Alarm Set" "Alarm scheduled for $time_input: $message" --icon=alarm-clock
        else
            notify-send "Alarm" "at command not available for scheduling alarms" --icon=dialog-error
        fi
    else
        notify-send "Alarm" "Invalid time format. Use HH:MM" --icon=dialog-warning
    fi
}

show_world_clock() {
    local clocks="🇺🇸 New York: $(TZ='America/New_York' date '+%H:%M')
🇬🇧 London: $(TZ='Europe/London' date '+%H:%M')
🇩🇪 Berlin: $(TZ='Europe/Berlin' date '+%H:%M')
🇯🇵 Tokyo: $(TZ='Asia/Tokyo' date '+%H:%M')
🇨🇳 Shanghai: $(TZ='Asia/Shanghai' date '+%H:%M')
🇦🇺 Sydney: $(TZ='Australia/Sydney' date '+%H:%M')
🇮🇳 Mumbai: $(TZ='Asia/Kolkata' date '+%H:%M')"
    
    echo "$clocks" | rofi -dmenu -p "World Clock" -theme-str 'window {width: 40%;}'
}

case "$1" in
    "menu")
        show_time_menu
        ;;
    "world")
        show_world_clock
        ;;
    "alarm")
        set_alarm
        ;;
    *)
        echo "Usage: $0 {menu|world|alarm}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/time-date.sh"
}

# Test installation
test_workspace_time() {
    log_info "Testing workspace and time management..."
    
    # Check if hyprctl is available
    if command -v hyprctl &> /dev/null; then
        log_success "✅ Hyprland control available"
    else
        log_error "❌ Hyprland control not found"
        return 1
    fi
    
    # Check if date/time tools are available
    if command -v timedatectl &> /dev/null; then
        log_success "✅ System time control available"
    else
        log_warn "⚠️  System time control not available"
    fi
    
    return 0
}

# Main execution
case "${1:-install}" in
    "install")
        install_workspace_time
        ;;
    "configure")
        configure_workspace_integration
        configure_time_integration
        ;;
    "test")
        test_workspace_time
        ;;
    *)
        echo "Usage: $0 {install|configure|test}"
        exit 1
        ;;
esac

