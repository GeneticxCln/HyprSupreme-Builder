#!/bin/bash
# HyprSupreme-Builder - Notification System Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_notifications() {
    log_info "Installing notification system..."
    
    # Check user preference for notification daemon
    local notification_daemon
    if command -v whiptail &> /dev/null; then
        notification_daemon=$(whiptail --title "Notification Daemon" \
            --menu "Choose notification daemon:" 15 60 3 \
            "mako" "Modern Wayland notification daemon (recommended)" \
            "dunst" "Traditional notification daemon" \
            "both" "Install both (mako as default)" \
            3>&1 1>&2 2>&3)
    else
        notification_daemon="mako"
        log_info "Using default notification daemon: mako"
    fi
    
    case "$notification_daemon" in
        "mako")
            install_mako
            ;;
        "dunst") 
            install_dunst
            ;;
        "both")
            install_mako
            install_dunst
            ;;
        *)
            log_error "Invalid notification daemon selection"
            return 1
            ;;
    esac
    
    # Configure notification integration
    configure_notification_integration
    
    log_success "Notification system installation completed"
}

install_mako() {
    log_info "Installing Mako notification daemon..."
    
    local packages=(
        "mako"
        "libnotify"  # notify-send command
    )
    
    install_packages "${packages[@]}"
    
    # Create mako config directory
    mkdir -p "$HOME/.config/mako"
    
    # Create mako configuration
    create_mako_config
    
    log_success "Mako installation completed"
}

install_dunst() {
    log_info "Installing Dunst notification daemon..."
    
    local packages=(
        "dunst"
        "libnotify"  # notify-send command
    )
    
    install_packages "${packages[@]}"
    
    # Create dunst config directory
    mkdir -p "$HOME/.config/dunst"
    
    # Create dunst configuration
    create_dunst_config
    
    log_success "Dunst installation completed"
}

create_mako_config() {
    local config_file="$HOME/.config/mako/config"
    
    log_info "Creating Mako configuration..."
    
    cat > "$config_file" << 'EOF'
# Mako Configuration for HyprSupreme
# Modern Wayland notification daemon

# Appearance
font=JetBrains Mono 11
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#89b4fa
border-size=2
border-radius=10

# Layout
width=350
height=150
margin=10
padding=15

# Behavior
default-timeout=5000
ignore-timeout=1
max-visible=5

# Positioning
anchor=top-right
layer=overlay

# Icons
icons=1
max-icon-size=48
icon-path=/usr/share/icons/Papirus-Dark

# Actions
actions=1

# Grouping
group-by=app-name

# Progress bar
progress-color=#a6e3a1

# Urgency levels
[urgency=low]
border-color=#a6adc8
default-timeout=3000

[urgency=normal]
border-color=#89b4fa
default-timeout=5000

[urgency=high]
border-color=#f38ba8
default-timeout=0

# App-specific settings
[app-name=Firefox]
border-color=#ff7f00

[app-name=Discord]
border-color=#5865f2

[app-name=Spotify]
border-color=#1db954
EOF
    
    log_success "Mako configuration created"
}

create_dunst_config() {
    local config_file="$HOME/.config/dunst/dunstrc"
    
    log_info "Creating Dunst configuration..."
    
    cat > "$config_file" << 'EOF'
# Dunst Configuration for HyprSupreme
[global]
    monitor = 0
    follow = mouse
    
    width = 350
    height = 150
    origin = top-right
    offset = 10x10
    scale = 0
    notification_limit = 5
    
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    
    indicate_hidden = yes
    transparency = 0
    separator_height = 2
    padding = 15
    horizontal_padding = 15
    text_icon_padding = 0
    frame_width = 2
    frame_color = "#89b4fa"
    separator_color = frame
    sort = yes
    
    font = JetBrains Mono 11
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    
    icon_position = left
    min_icon_size = 32
    max_icon_size = 48
    icon_path = /usr/share/icons/Papirus-Dark/16x16/status/:/usr/share/icons/Papirus-Dark/16x16/devices/
    
    sticky_history = yes
    history_length = 20
    
    dmenu = /usr/bin/rofi -dmenu -p dunst:
    browser = /usr/bin/firefox -new-tab
    
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 10
    ignore_dbusclose = false
    force_xwayland = false
    force_xinerama = false
    
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[experimental]
    per_monitor_dpi = false

[urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#a6adc8"
    timeout = 3

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#89b4fa"
    timeout = 5

[urgency_critical]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#f38ba8"
    timeout = 0

# App-specific rules
[firefox]
    appname = Firefox
    frame_color = "#ff7f00"
    
[discord]
    appname = Discord
    frame_color = "#5865f2"
    
[spotify]
    appname = Spotify
    frame_color = "#1db954"
EOF
    
    log_success "Dunst configuration created"
}

configure_notification_integration() {
    log_info "Configuring notification integration..."
    
    # Create notification test script
    local scripts_dir="$HOME/.config/hypr/scripts"
    mkdir -p "$scripts_dir"
    
    cat > "$scripts_dir/notification-test.sh" << 'EOF'
#!/bin/bash
# Notification Test Script for HyprSupreme

# Test basic notification
notify-send "HyprSupreme" "Notification system is working!" \
    --icon=dialog-information \
    --urgency=normal

# Test urgent notification
notify-send "System Alert" "This is an urgent notification test" \
    --icon=dialog-warning \
    --urgency=critical

# Test progress notification
for i in {1..10}; do
    notify-send "Progress Test" "Step $i of 10" \
        --hint=int:value:$((i*10)) \
        --urgency=low \
        --replace-id=1234
    sleep 0.5
done

notify-send "Test Complete" "All notification tests finished!" \
    --icon=dialog-information \
    --urgency=normal
EOF
    
    chmod +x "$scripts_dir/notification-test.sh"
    
    # Create notification settings script
    cat > "$scripts_dir/notification-settings.sh" << 'EOF'
#!/bin/bash
# Notification Settings Script for HyprSupreme

# Function to restart notification daemon
restart_notifications() {
    if pgrep -x "mako" > /dev/null; then
        killall mako
        sleep 1
        mako &
        notify-send "Notifications" "Mako restarted"
    elif pgrep -x "dunst" > /dev/null; then
        killall dunst
        sleep 1
        dunst &
        notify-send "Notifications" "Dunst restarted"
    else
        notify-send "Error" "No notification daemon running"
    fi
}

# Function to toggle notifications
toggle_notifications() {
    if pgrep -x "mako" > /dev/null; then
        if makoctl mode | grep -q "do-not-disturb"; then
            makoctl mode -r do-not-disturb
            notify-send "Notifications" "Notifications enabled"
        else
            makoctl mode -a do-not-disturb
            notify-send "Notifications" "Do not disturb enabled"
        fi
    else
        notify-send "Info" "Toggle feature requires Mako"
    fi
}

case "$1" in
    "restart")
        restart_notifications
        ;;
    "toggle")
        toggle_notifications
        ;;
    "test")
        "$HOME/.config/hypr/scripts/notification-test.sh"
        ;;
    *)
        echo "Usage: $0 {restart|toggle|test}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/notification-settings.sh"
    
    log_success "Notification integration configured"
}

# Test notification installation
test_notifications() {
    log_info "Testing notification system..."
    
    # Check if notification daemon is installed
    local daemon_found=false
    
    if command -v mako &> /dev/null; then
        log_success "✅ Mako notification daemon is available"
        daemon_found=true
    fi
    
    if command -v dunst &> /dev/null; then
        log_success "✅ Dunst notification daemon is available"
        daemon_found=true
    fi
    
    if ! $daemon_found; then
        log_error "❌ No notification daemon found"
        return 1
    fi
    
    # Check if libnotify is available
    if command -v notify-send &> /dev/null; then
        log_success "✅ notify-send command is available"
    else
        log_error "❌ notify-send command not found"
        return 1
    fi
    
    # Test notification
    log_info "Sending test notification..."
    notify-send "HyprSupreme" "Notification system test" \
        --icon=dialog-information &> /dev/null || {
        log_warn "⚠️  Could not send test notification (might be normal in headless environment)"
    }
    
    return 0
}

# Main execution
case "${1:-install}" in
    "install")
        install_notifications
        ;;
    "mako")
        install_mako
        ;;
    "dunst")
        install_dunst
        ;;
    "configure")
        configure_notification_integration
        ;;
    "test")
        test_notifications
        ;;
    *)
        echo "Usage: $0 {install|mako|dunst|configure|test}"
        exit 1
        ;;
esac

