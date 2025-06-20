#!/bin/bash
# HyprSupreme-Builder - Notification System Installation Module

# Set strict error handling
set -o errexit  # Exit on error
set -o pipefail # Exit if any command in a pipe fails
set -o nounset  # Exit on undefined variables

# Define error codes
readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_PERMISSION=2
readonly E_DEPENDENCY=3
readonly E_SERVICE=4
readonly E_DIRECTORY=5
readonly E_CONFIG=6
readonly E_NOTIFICATION=7  # Notification-specific errors

# Path to the script
readonly SCRIPT_PATH="$(readlink -f "$0")"
readonly SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
readonly CONFIG_DIR="$HOME/.config"
readonly BACKUP_DIR="$HOME/.config/notification-backup-$(date +%Y%m%d-%H%M%S)"

# Source common functions
if [[ ! -f "${SCRIPT_DIR}/../common/functions.sh" ]]; then
    echo "ERROR: Required file not found: ${SCRIPT_DIR}/../common/functions.sh"
    exit $E_DEPENDENCY
fi

source "${SCRIPT_DIR}/../common/functions.sh"

# Error handling function
handle_error() {
    local exit_code=$1
    local error_message="${2:-Unknown error}"
    local error_source="${3:-$SCRIPT_PATH}"
    
    log_error "Error in $error_source: $error_message (code: $exit_code)"
    
    # Clean up any temporary resources
    cleanup_temp_resources
    
    # Return the exit code
    return $exit_code
}

# Function to clean up temporary resources
cleanup_temp_resources() {
    # Kill any running notification test processes
    pkill -f "notification-test.sh" 2>/dev/null || true
    
    # Remove any temporary notification files
    rm -f "/tmp/notification-test-*.log" 2>/dev/null || true
    
    # Stop notification daemons in test mode if any
    pkill -f "mako --test" 2>/dev/null || true
    pkill -f "dunst --test" 2>/dev/null || true
}

# Notification-specific error handler
handle_notification_error() {
    local error_type="$1"
    local error_message="$2"
    
    case "$error_type" in
        "daemon")
            log_error "Notification daemon error: $error_message"
            return $E_SERVICE
            ;;
        "config")
            log_error "Configuration error: $error_message"
            return $E_CONFIG
            ;;
        "test")
            log_error "Notification test error: $error_message"
            return $E_NOTIFICATION
            ;;
        *)
            log_error "Unknown notification error: $error_message"
            return $E_GENERAL
            ;;
    esac
}

# Trap errors
trap 'handle_error $? "Script interrupted" "$BASH_SOURCE:$LINENO"' ERR
trap 'log_warn "Script received SIGINT - operation canceled"; exit $E_GENERAL' INT
trap 'log_warn "Script received SIGTERM - operation canceled"; exit $E_GENERAL' TERM

# Backup existing configuration
backup_config() {
    if [[ -d "$CONFIG_DIR/mako" ]] || [[ -d "$CONFIG_DIR/dunst" ]]; then
        log_info "Backing up existing notification configuration..."
        
        # Create backup directory
        if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
            log_error "Failed to create backup directory: $BACKUP_DIR"
            return $E_DIRECTORY
        fi
        
        # Backup mako config if it exists
        if [[ -d "$CONFIG_DIR/mako" ]]; then
            if ! cp -r "$CONFIG_DIR/mako" "$BACKUP_DIR/" 2>/dev/null; then
                log_warn "Failed to backup mako configuration"
            else
                log_info "Backed up mako configuration"
            fi
        fi
        
        # Backup dunst config if it exists
        if [[ -d "$CONFIG_DIR/dunst" ]]; then
            if ! cp -r "$CONFIG_DIR/dunst" "$BACKUP_DIR/" 2>/dev/null; then
                log_warn "Failed to backup dunst configuration"
            else
                log_info "Backed up dunst configuration"
            fi
        fi
        
        log_success "Configuration backup completed to $BACKUP_DIR"
    fi
    
    return $E_SUCCESS
}

install_notifications() {
    log_info "Installing notification system..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        return $E_PERMISSION
    fi
    
    # Check for essential dependencies
    if ! command -v pacman &> /dev/null; then
        log_error "Package manager not found (pacman is required)"
        return $E_DEPENDENCY
    fi
    
    # Backup existing configuration
    backup_config
    
    # Check user preference for notification daemon
    local notification_daemon
    if command -v whiptail &> /dev/null; then
        notification_daemon=$(whiptail --title "Notification Daemon" \
            --menu "Choose notification daemon:" 15 60 3 \
            "mako" "Modern Wayland notification daemon (recommended)" \
            "dunst" "Traditional notification daemon" \
            "both" "Install both (mako as default)" \
            3>&1 1>&2 2>&3) || notification_daemon="mako"
    else
        notification_daemon="mako"
        log_info "Using default notification daemon: mako"
    fi
    
    case "$notification_daemon" in
        "mako")
            if ! install_mako; then
                handle_notification_error "daemon" "Failed to install mako"
                return $E_GENERAL
            fi
            ;;
        "dunst") 
            if ! install_dunst; then
                handle_notification_error "daemon" "Failed to install dunst"
                return $E_GENERAL
            fi
            ;;
        "both")
            if ! install_mako; then
                log_warn "Failed to install mako, trying dunst..."
            fi
            if ! install_dunst; then
                if ! command -v mako &> /dev/null; then
                    handle_notification_error "daemon" "Failed to install both notification daemons"
                    return $E_GENERAL
                fi
            fi
            ;;
        *)
            handle_notification_error "daemon" "Invalid notification daemon selection"
            return $E_GENERAL
            ;;
    esac
    
    # Configure notification integration
    if ! configure_notification_integration; then
        handle_notification_error "config" "Failed to configure notification integration"
        return $E_CONFIG
    fi
    
    log_success "Notification system installation completed"
    return $E_SUCCESS
}

install_mako() {
    log_info "Installing Mako notification daemon..."
    
    # Check for conflicting notification daemons
    if pgrep -x "dunst" > /dev/null; then
        log_warn "Dunst notification daemon is currently running"
        log_info "Both notification daemons can be installed, but only one should run at a time"
    fi
    
    local packages=(
        "mako"
        "libnotify"  # notify-send command
    )
    
    # Install packages with error handling
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install Mako packages"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v mako &> /dev/null; then
        log_error "Mako installation failed: mako command not found"
        return $E_DEPENDENCY
    fi
    
    # Create mako config directory with error handling
    local mako_dir="$HOME/.config/mako"
    if [[ ! -d "$mako_dir" ]]; then
        if ! mkdir -p "$mako_dir" 2>/dev/null; then
            log_error "Failed to create Mako config directory: $mako_dir"
            return $E_DIRECTORY
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$mako_dir" ]]; then
        log_error "No write permission for Mako config directory: $mako_dir"
        return $E_PERMISSION
    fi
    
    # Create mako configuration
    if ! create_mako_config; then
        log_error "Failed to create Mako configuration"
        return $E_CONFIG
    fi
    
    log_success "Mako installation completed"
    return $E_SUCCESS
}

install_dunst() {
    log_info "Installing Dunst notification daemon..."
    
    # Check for conflicting notification daemons
    if pgrep -x "mako" > /dev/null; then
        log_warn "Mako notification daemon is currently running"
        log_info "Both notification daemons can be installed, but only one should run at a time"
    fi
    
    local packages=(
        "dunst"
        "libnotify"  # notify-send command
    )
    
    # Install packages with error handling
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install Dunst packages"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v dunst &> /dev/null; then
        log_error "Dunst installation failed: dunst command not found"
        return $E_DEPENDENCY
    fi
    
    # Create dunst config directory with error handling
    local dunst_dir="$HOME/.config/dunst"
    if [[ ! -d "$dunst_dir" ]]; then
        if ! mkdir -p "$dunst_dir" 2>/dev/null; then
            log_error "Failed to create Dunst config directory: $dunst_dir"
            return $E_DIRECTORY
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$dunst_dir" ]]; then
        log_error "No write permission for Dunst config directory: $dunst_dir"
        return $E_PERMISSION
    fi
    
    # Create dunst configuration
    if ! create_dunst_config; then
        log_error "Failed to create Dunst configuration"
        return $E_CONFIG
    fi
    
    log_success "Dunst installation completed"
    return $E_SUCCESS
}

create_mako_config() {
    local config_file="$HOME/.config/mako/config"
    
    log_info "Creating Mako configuration..."
    
    # Check if file exists and is writable
    if [[ -f "$config_file" && ! -w "$config_file" ]]; then
        log_error "Cannot write to existing file: $config_file"
        return $E_PERMISSION
    fi
    
    # Create the configuration with error handling
    if ! cat > "$config_file" << 'EOF'
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
    then
        log_error "Failed to write Mako configuration"
        return $E_CONFIG
    fi
    
    log_success "Mako configuration created"
    return $E_SUCCESS
}

create_dunst_config() {
    local config_file="$HOME/.config/dunst/dunstrc"
    
    log_info "Creating Dunst configuration..."
    
    # Check if file exists and is writable
    if [[ -f "$config_file" && ! -w "$config_file" ]]; then
        log_error "Cannot write to existing file: $config_file"
        return $E_PERMISSION
    fi
    
    # Create the configuration with error handling
    if ! cat > "$config_file" << 'EOF'
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
    then
        log_error "Failed to write Dunst configuration"
        return $E_CONFIG
    fi
    
    log_success "Dunst configuration created"
    return $E_SUCCESS
}

configure_notification_integration() {
    log_info "Configuring notification integration..."
    
    # Create notification scripts directory with error handling
    local scripts_dir="$HOME/.config/hypr/scripts"
    if [[ ! -d "$scripts_dir" ]]; then
        log_info "Creating scripts directory: $scripts_dir"
        if ! mkdir -p "$scripts_dir" 2>/dev/null; then
            log_error "Failed to create scripts directory: $scripts_dir"
            return $E_DIRECTORY
        fi
    else
        log_info "Scripts directory already exists: $scripts_dir"
    fi
    
    # Check write permissions
    if [[ ! -w "$scripts_dir" ]]; then
        log_error "No write permission for scripts directory: $scripts_dir"
        return $E_PERMISSION
    fi
    
    # Create notification test script
    local test_script="$scripts_dir/notification-test.sh"
    log_info "Creating notification test script..."
    
    # Check if file exists and is writable
    if [[ -f "$test_script" && ! -w "$test_script" ]]; then
        log_error "Cannot write to existing file: $test_script"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$test_script" << 'EOF'
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
    then
        log_error "Failed to write notification test script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$test_script" 2>/dev/null; then
        log_error "Failed to make notification test script executable"
        return $E_PERMISSION
    fi
    
    # Create notification settings script
    local settings_script="$scripts_dir/notification-settings.sh"
    log_info "Creating notification settings script..."
    
    # Check if file exists and is writable
    if [[ -f "$settings_script" && ! -w "$settings_script" ]]; then
        log_error "Cannot write to existing file: $settings_script"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$settings_script" << 'EOF'
#!/bin/bash
# Notification Settings Script for HyprSupreme

# Function to restart notification daemon
restart_notifications() {
    if pgrep -x "mako" > /dev/null; then
        # Get current Mako PID for verification
        local old_pid=$(pgrep -x "mako")
        
        # Kill Mako with error handling
        if ! killall mako 2>/dev/null; then
            notify-send "Error" "Failed to stop Mako" --icon=dialog-error
            return 1
        fi
        
        # Wait for process to end
        local wait_count=0
        while pgrep -x "mako" > /dev/null && [ $wait_count -lt 10 ]; do
            sleep 0.5
            ((wait_count++))
        done
        
        # Start Mako with error handling
        if ! mako & then
            notify-send "Error" "Failed to start Mako" --icon=dialog-error
            return 1
        fi
        
        # Verify Mako started with new PID
        sleep 1
        local new_pid=$(pgrep -x "mako")
        if [ -z "$new_pid" ]; then
            notify-send "Error" "Mako failed to start" --icon=dialog-error
            return 1
        elif [ "$old_pid" = "$new_pid" ]; then
            notify-send "Warning" "Mako may not have properly restarted" --icon=dialog-warning
        else
            notify-send "Notifications" "Mako restarted successfully" --icon=dialog-information
        fi
    elif pgrep -x "dunst" > /dev/null; then
        # Get current Dunst PID for verification
        local old_pid=$(pgrep -x "dunst")
        
        # Kill Dunst with error handling
        if ! killall dunst 2>/dev/null; then
            notify-send "Error" "Failed to stop Dunst" --icon=dialog-error
            return 1
        fi
        
        # Wait for process to end
        local wait_count=0
        while pgrep -x "dunst" > /dev/null && [ $wait_count -lt 10 ]; do
            sleep 0.5
            ((wait_count++))
        done
        
        # Start Dunst with error handling
        if ! dunst & then
            notify-send "Error" "Failed to start Dunst" --icon=dialog-error
            return 1
        fi
        
        # Verify Dunst started with new PID
        sleep 1
        local new_pid=$(pgrep -x "dunst")
        if [ -z "$new_pid" ]; then
            notify-send "Error" "Dunst failed to start" --icon=dialog-error
            return 1
        elif [ "$old_pid" = "$new_pid" ]; then
            notify-send "Warning" "Dunst may not have properly restarted" --icon=dialog-warning
        else
            notify-send "Notifications" "Dunst restarted successfully" --icon=dialog-information
        fi
    else
        # Try to start a notification daemon if none is running
        if command -v mako &> /dev/null; then
            mako &
            sleep 1
            if pgrep -x "mako" > /dev/null; then
                notify-send "Notifications" "Mako started" --icon=dialog-information
            else
                notify-send "Error" "Failed to start notification daemon" --icon=dialog-error
                return 1
            fi
        elif command -v dunst &> /dev/null; then
            dunst &
            sleep 1
            if pgrep -x "dunst" > /dev/null; then
                notify-send "Notifications" "Dunst started" --icon=dialog-information
            else
                notify-send "Error" "Failed to start notification daemon" --icon=dialog-error
                return 1
            fi
        else
            notify-send "Error" "No notification daemon available" --icon=dialog-error
            return 1
        fi
    fi
    
    return 0
}

# Function to toggle notifications
toggle_notifications() {
    if pgrep -x "mako" > /dev/null; then
        if command -v makoctl &> /dev/null; then
            # Properly handle makoctl errors
            local current_mode
            current_mode=$(makoctl mode 2>/dev/null) || {
                notify-send "Error" "Failed to get Mako mode" --icon=dialog-error
                return 1
            }
            
            if echo "$current_mode" | grep -q "do-not-disturb"; then
                if ! makoctl mode -r do-not-disturb 2>/dev/null; then
                    notify-send "Error" "Failed to enable notifications" --icon=dialog-error
                    return 1
                fi
                notify-send "Notifications" "Notifications enabled" --icon=dialog-information
            else
                if ! makoctl mode -a do-not-disturb 2>/dev/null; then
                    notify-send "Error" "Failed to enable Do Not Disturb mode" --icon=dialog-error
                    return 1
                fi
                notify-send "Notifications" "Do not disturb enabled" --icon=dialog-warning
            fi
        else
            notify-send "Error" "makoctl command not found" --icon=dialog-error
            return 1
        fi
    elif pgrep -x "dunst" > /dev/null; then
        # Dunst lacks a built-in DND mode like mako, but we can simulate it
        if [ -f "/tmp/dunst_dnd_active" ]; then
            # Re-enable notifications by resuming dunst
            if ! killall -SIGUSR2 dunst 2>/dev/null; then
                notify-send "Error" "Failed to resume notifications" --icon=dialog-error
                return 1
            fi
            rm -f "/tmp/dunst_dnd_active"
            notify-send "Notifications" "Notifications enabled" --icon=dialog-information
        else
            # Pause notifications
            if ! killall -SIGUSR1 dunst 2>/dev/null; then
                notify-send "Error" "Failed to pause notifications" --icon=dialog-error
                return 1
            fi
            touch "/tmp/dunst_dnd_active"
            notify-send "Notifications" "Do not disturb enabled" --icon=dialog-warning
        fi
    else
        notify-send "Error" "No notification daemon running" --icon=dialog-error
        return 1
    fi
    
    return 0
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
    then
        log_error "Failed to write notification settings script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$settings_script" 2>/dev/null; then
        log_error "Failed to make notification settings script executable"
        return $E_PERMISSION
    fi
    
    log_success "Notification integration configured"
    return $E_SUCCESS
}

# Test notification installation
test_notifications() {
    log_info "Testing notification system..."
    local errors=0
    local warnings=0
    
    # Create test log
    local test_log="/tmp/notification-test-$(date +%Y%m%d-%H%M%S).log"
    
    {
        echo "==== HyprSupreme Notification System Test ===="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "System: $(uname -a)"
        echo "======================================="
        echo ""
    } > "${test_log}"
    
    # Check if notification daemon is installed with enhanced detection
    local daemon_found=false
    
    if command -v mako &> /dev/null; then
        local mako_version
        mako_version=$(mako --version 2>/dev/null || echo "Unknown version")
        log_success "✅ Mako notification daemon is available (${mako_version})"
        echo "Notification daemon: Mako ${mako_version}" >> "${test_log}"
        daemon_found=true
        
        # Check mako configuration with validation
        local mako_config="$HOME/.config/mako/config"
        if [[ -f "${mako_config}" ]]; then
            log_success "✅ Mako configuration exists"
            
            # Validate critical config settings
            local config_issues=0
            if ! grep -q "background-color" "${mako_config}"; then
                log_warn "⚠️  Mako configuration missing 'background-color' setting"
                ((config_issues++))
            fi
            
            if ! grep -q "border-color" "${mako_config}"; then
                log_warn "⚠️  Mako configuration missing 'border-color' setting"
                ((config_issues++))
            fi
            
            if [[ ${config_issues} -eq 0 ]]; then
                log_success "✅ Mako configuration appears valid"
            else
                log_warn "⚠️  Mako configuration has potential issues"
                ((warnings++))
            fi
            
            # Log config
            echo "Mako Configuration:" >> "${test_log}"
            cat "${mako_config}" >> "${test_log}"
        else
            log_warn "⚠️  Mako configuration is missing"
            echo "WARNING: Mako configuration is missing" >> "${test_log}"
            ((warnings++))
        fi
        
        # Check if mako process is running
        if pgrep -x "mako" > /dev/null; then
            log_success "✅ Mako daemon is running"
            echo "Mako process is running (PID: $(pgrep -x mako))" >> "${test_log}"
        else
            log_warn "⚠️  Mako daemon is not running"
            echo "WARNING: Mako daemon is not running" >> "${test_log}"
            ((warnings++))
        fi
    fi
    
    if command -v dunst &> /dev/null; then
        local dunst_version
        dunst_version=$(dunst --version 2>/dev/null || echo "Unknown version")
        log_success "✅ Dunst notification daemon is available (${dunst_version})"
        echo "Notification daemon: Dunst ${dunst_version}" >> "${test_log}"
        daemon_found=true
        
        # Check dunst configuration with validation
        local dunst_config="$HOME/.config/dunst/dunstrc"
        if [[ -f "${dunst_config}" ]]; then
            log_success "✅ Dunst configuration exists"
            
            # Validate critical config settings
            local config_issues=0
            if ! grep -q "\[global\]" "${dunst_config}"; then
                log_warn "⚠️  Dunst configuration missing '[global]' section"
                ((config_issues++))
            fi
            
            if ! grep -q "\[urgency_" "${dunst_config}"; then
                log_warn "⚠️  Dunst configuration missing urgency sections"
                ((config_issues++))
            fi
            
            if [[ ${config_issues} -eq 0 ]]; then
                log_success "✅ Dunst configuration appears valid"
            else
                log_warn "⚠️  Dunst configuration has potential issues"
                ((warnings++))
            fi
            
            # Log config
            echo "Dunst Configuration:" >> "${test_log}"
            cat "${dunst_config}" >> "${test_log}"
        else
            log_warn "⚠️  Dunst configuration is missing"
            echo "WARNING: Dunst configuration is missing" >> "${test_log}"
            ((warnings++))
        fi
        
        # Check if dunst process is running
        if pgrep -x "dunst" > /dev/null; then
            log_success "✅ Dunst daemon is running"
            echo "Dunst process is running (PID: $(pgrep -x dunst))" >> "${test_log}"
        else
            log_warn "⚠️  Dunst daemon is not running"
            echo "WARNING: Dunst daemon is not running" >> "${test_log}"
            ((warnings++))
        fi
    fi
    
    if ! $daemon_found; then
        log_error "❌ No notification daemon found"
        ((errors++))
    fi
    
    # Check if libnotify is available with version info
    if command -v notify-send &> /dev/null; then
        local libnotify_version
        libnotify_version=$(notify-send --version 2>/dev/null || echo "Unknown version")
        log_success "✅ notify-send command is available (${libnotify_version})"
        echo "Notification command: notify-send ${libnotify_version}" >> "${test_log}"
        
        # Check if pkill is available for stopping notification daemons
        if ! command -v pkill &> /dev/null; then
            log_warn "⚠️  pkill command not found, some daemon control operations may fail"
            ((warnings++))
        fi
        
        # Check if dbus is running (required for notifications)
        if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
            log_warn "⚠️  DBUS_SESSION_BUS_ADDRESS is not set, notifications may not work"
            echo "WARNING: DBUS_SESSION_BUS_ADDRESS not set" >> "${test_log}"
            ((warnings++))
        else
            log_success "✅ D-Bus session available"
            echo "D-Bus session: ${DBUS_SESSION_BUS_ADDRESS}" >> "${test_log}"
        fi
    else
        log_error "❌ notify-send command not found"
        echo "ERROR: notify-send command not found" >> "${test_log}"
        ((errors++))
    fi
    
    # Check script files
    local scripts_dir="$HOME/.config/hypr/scripts"
    local required_scripts=("notification-test.sh" "notification-settings.sh")
    
    for script in "${required_scripts[@]}"; do
        if [[ -x "$scripts_dir/$script" ]]; then
            log_success "✅ Script $script is available and executable"
        elif [[ -f "$scripts_dir/$script" ]]; then
            log_warn "⚠️  Script $script exists but is not executable"
            ((warnings++))
        else
            log_error "❌ Script $script is missing"
            ((errors++))
        fi
    done
    
    # Run enhanced notification tests
    log_info "Running notification tests..."
    
    # Make sure a notification daemon is running for testing
    local daemon_started=false
    if ! pgrep -x "mako" > /dev/null && ! pgrep -x "dunst" > /dev/null; then
        log_info "Starting notification daemon for testing..."
        
        if command -v mako &> /dev/null; then
            mako --test &>/dev/null &
            daemon_started=true
            sleep 1
        elif command -v dunst &> /dev/null; then
            dunst --test &>/dev/null &
            daemon_started=true
            sleep 1
        else
            log_warn "⚠️  No notification daemon available for testing"
        fi
    fi
    
    # Basic notification test
    log_info "Sending basic test notification..."
    if ! notify-send "HyprSupreme" "Notification system test" \
        --icon=dialog-information &> /dev/null; then
        log_warn "⚠️  Could not send basic test notification"
        echo "WARNING: Basic notification test failed" >> "${test_log}"
        ((warnings++))
    else
        log_success "✅ Basic notification sending works"
        echo "Basic notification test successful" >> "${test_log}"
    fi
    
    # Urgent notification test
    log_info "Sending urgent test notification..."
    if ! notify-send "HyprSupreme" "Urgent notification test" \
        --icon=dialog-warning \
        --urgency=critical &> /dev/null; then
        log_warn "⚠️  Could not send urgent test notification"
        echo "WARNING: Urgent notification test failed" >> "${test_log}"
        ((warnings++))
    else
        log_success "✅ Urgent notification sending works"
        echo "Urgent notification test successful" >> "${test_log}"
    fi
    
    # Stop test daemon if we started one
    if ${daemon_started}; then
        log_info "Stopping test notification daemon..."
        pkill -f "mako --test" 2>/dev/null || pkill -f "dunst --test" 2>/dev/null || true
    fi
    
    # Test notification daemon autostart capability
    if command -v hyprctl &> /dev/null; then
        if grep -q "exec-once.*mako" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null || \
           grep -q "exec-once.*dunst" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
            log_success "✅ Notification daemon autostart configured in Hyprland"
            echo "Notification daemon autostart configured in Hyprland" >> "${test_log}"
        else
            log_warn "⚠️  Notification daemon autostart not configured in Hyprland"
            echo "WARNING: Add 'exec-once = mako' or 'exec-once = dunst' to your hyprland.conf" >> "${test_log}"
            ((warnings++))
        fi
    fi
    
    # Report summary
    if [[ $errors -gt 0 ]]; then
        log_error "Notification system test completed with $errors errors and $warnings warnings"
        echo "TEST RESULT: FAILED with $errors errors and $warnings warnings" >> "${test_log}"
        log_info "Detailed test log saved to: ${test_log}"
        return $E_NOTIFICATION
    elif [[ $warnings -gt 0 ]]; then
        log_warn "Notification system test completed with $warnings warnings"
        echo "TEST RESULT: PASSED with $warnings warnings" >> "${test_log}"
        log_info "Detailed test log saved to: ${test_log}"
        return $E_SUCCESS
    else
        log_success "Notification system test completed successfully"
        echo "TEST RESULT: PASSED with no issues" >> "${test_log}"
        log_info "Detailed test log saved to: ${test_log}"
        return $E_SUCCESS
    fi
}

# Verify user is not root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        return $E_PERMISSION
    fi
    return $E_SUCCESS
}

# Check if the script is sourced
is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

# Main execution
main() {
    # Skip if sourced
    if is_sourced; then
        return $E_SUCCESS
    fi
    
    local operation="${1:-install}"
    local exit_code=$E_SUCCESS
    
    # Check if running as root
    if ! check_not_root; then
        exit $E_PERMISSION
    fi
    
    # Execute requested operation
    case "$operation" in
        "install")
            install_notifications
            exit_code=$?
            ;;
        "mako")
            install_mako
            exit_code=$?
            ;;
        "dunst")
            install_dunst
            exit_code=$?
            ;;
        "configure")
            configure_notification_integration
            exit_code=$?
            ;;
        "test")
            test_notifications
            exit_code=$?
            ;;
        "help")
            echo "Usage: $0 {install|mako|dunst|configure|test|help}"
            echo ""
            echo "Operations:"
            echo "  install    - Install notification system (default)"
            echo "  mako       - Install only mako notification daemon"
            echo "  dunst      - Install only dunst notification daemon"
            echo "  configure  - Configure notification integration"
            echo "  test       - Test notification system"
            echo "  help       - Show this help message"
            exit_code=$E_SUCCESS
            ;;
        *)
            log_error "Invalid operation: $operation"
            echo "Usage: $0 {install|mako|dunst|configure|test|help}"
            exit_code=$E_GENERAL
            ;;
    esac
    
    # Return with appropriate exit code
    if [[ $exit_code -eq $E_SUCCESS ]]; then
        log_success "Operation '$operation' completed successfully"
    else
        log_error "Operation '$operation' failed with code $exit_code"
    fi
    
    return $exit_code
}

# Run main function
main "$@"
exit $?

