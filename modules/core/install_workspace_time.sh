#!/bin/bash
# HyprSupreme-Builder - Workspace and Time Management Module
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failures

# Define a trap to handle script termination
trap 'echo "ERROR: Script terminated unexpectedly"; exit 1' ERR

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_FUNCTIONS="${SCRIPT_DIR}/../common/functions.sh"

if [[ ! -f "${COMMON_FUNCTIONS}" ]]; then
    echo "Error: Common functions file not found at ${COMMON_FUNCTIONS}"
    exit 1
fi
source "${COMMON_FUNCTIONS}"

# Set log prefix for better identification
LOG_PREFIX="[Workspace-Time]"

install_workspace_time() {
    log_info "${LOG_PREFIX} Installing workspace and time management..."
    
    # Validate environment before proceeding
    if ! validate_environment; then
        log_error "${LOG_PREFIX} Environment validation failed. Aborting installation."
        return 1
    fi
    
    # Configure workspace integration with error handling
    if ! configure_workspace_integration; then
        log_error "${LOG_PREFIX} Workspace integration configuration failed"
        return 1
    fi
    
    # Configure time/date integration with error handling
    if ! configure_time_integration; then
        log_error "${LOG_PREFIX} Time/date integration configuration failed"
        return 1
    fi
    
    # Run tests if installation was successful
    log_info "${LOG_PREFIX} Running installation tests..."
    if ! test_workspace_time; then
        log_warn "${LOG_PREFIX} Some tests failed. Installation may not be fully functional."
    fi
    
    log_success "${LOG_PREFIX} Workspace and time management installation completed"
    return 0
}

configure_workspace_integration() {
    log_info "${LOG_PREFIX} Configuring workspace management..."
    
    # Ensure HOME is set and valid
    if [[ -z "${HOME:-}" ]]; then
        log_error "${LOG_PREFIX} HOME environment variable is not set"
        return 1
    fi
    
    local scripts_dir="${HOME}/.config/hypr/scripts"
    log_info "${LOG_PREFIX} Creating scripts directory at: ${scripts_dir}"
    
    # Create directory with more verbose error handling
    if ! mkdir -p "${scripts_dir}" 2>/dev/null; then
        log_error "${LOG_PREFIX} Failed to create scripts directory: ${scripts_dir}"
        log_error "${LOG_PREFIX} Please check permissions and disk space"
        return 1
    fi
    
    # Verify hyprctl is available for workspace management
    if ! command -v hyprctl &> /dev/null; then
        log_warn "${LOG_PREFIX} hyprctl command not found - workspace functionality may be limited"
        log_info "${LOG_PREFIX} Consider installing Hyprland properly for full functionality"
    else
        log_info "${LOG_PREFIX} Found hyprctl: $(which hyprctl)"
    fi
    
    # Check if rofi is installed for menus
    if ! command -v rofi &> /dev/null; then
        log_warn "${LOG_PREFIX} rofi command not found - menu functionality will be broken"
        log_info "${LOG_PREFIX} Consider installing rofi: 'sudo apt install rofi' or equivalent"
    else
        log_info "${LOG_PREFIX} Found rofi: $(which rofi)"
    fi
    
    # Create workspace management script
    log_info "${LOG_PREFIX} Creating workspace manager script..."
    
    # Backup existing script if it exists
    if [[ -f "${scripts_dir}/workspace-manager.sh" ]]; then
        log_info "${LOG_PREFIX} Backing up existing workspace manager script"
        if ! cp "${scripts_dir}/workspace-manager.sh" "${scripts_dir}/workspace-manager.sh.backup-$(date +%Y%m%d%H%M%S)"; then
            log_warn "${LOG_PREFIX} Failed to create backup of existing workspace manager script"
        fi
    fi
    if ! cat > "${scripts_dir}/workspace-manager.sh" << 'EOF'
#!/bin/bash
# Workspace Manager for HyprSupreme

show_workspace_menu() {
    # Get current workspace with error handling
    local current_workspace="1" # Default to workspace 1 if detection fails
    if command -v hyprctl &> /dev/null; then
        current_workspace=$(hyprctl activeworkspace 2>/dev/null | grep "workspace ID" | awk '{print $3}' || echo "1")
    fi
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
    
    # Display menu with error handling
    local selection=""
    if command -v rofi &> /dev/null; then
        selection=$(echo "$workspaces" | rofi -dmenu -p "Switch to Workspace" 2>/dev/null || echo "")
    else
        echo "ERROR: rofi command not found, cannot display workspace menu"
        return 1
    fi
    
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
    
    # Display menu with error handling
    local selection=""
    if command -v rofi &> /dev/null; then
        selection=$(echo "$workspaces" | rofi -dmenu -p "Move Window to Workspace" 2>/dev/null || echo "")
    else
        echo "ERROR: rofi command not found, cannot display workspace menu"
        return 1
    fi
    
    if [ -n "$selection" ]; then
        local workspace_num=$(echo "$selection" | grep -o '[0-9][0-9]*')
        if [ -n "$workspace_num" ]; then
            hyprctl dispatch movetoworkspace "$workspace_num"
        fi
    fi
}

workspace_overview() {
    # Check if hyprctl is available
    if ! command -v hyprctl &> /dev/null; then
        echo "ERROR: hyprctl command not found, cannot display workspace overview"
        notify-send "Workspace Overview" "hyprctl command not found" --icon=dialog-error 2>/dev/null || true
        return 1
    fi
    
    local overview=""
    for i in {1..10}; do
        local windows="0" # Default to 0 if detection fails
        windows=$(hyprctl workspaces 2>/dev/null | grep -A 5 "workspace ID $i" | grep "windows:" | awk '{print $2}' || echo "0")
        if [ -z "$windows" ]; then
            windows="0"
        fi
        overview+="Workspace $i: $windows windows\n"
    done
    
    # Display overview with error handling
    if command -v rofi &> /dev/null; then
        echo -e "$overview" | rofi -dmenu -p "Workspace Overview" -theme-str 'window {width: 40%;}' 2>/dev/null || true
    else
        echo "$overview"
        echo "ERROR: rofi command not found, displaying workspace overview in terminal"
    fi
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
    then
        log_error "${LOG_PREFIX} Failed to create workspace manager script at ${scripts_dir}/workspace-manager.sh"
        log_error "${LOG_PREFIX} Please check permissions and disk space"
        return 1
    fi
    
    # Set executable permissions with more verbose error handling
    if ! chmod +x "${scripts_dir}/workspace-manager.sh"; then
        log_error "${LOG_PREFIX} Failed to set executable permissions on workspace manager script"
        log_error "${LOG_PREFIX} Please check file permissions: ${scripts_dir}/workspace-manager.sh"
        return 1
    fi
    
    # Verify the script was created properly
    if [[ ! -x "${scripts_dir}/workspace-manager.sh" ]]; then
        log_error "${LOG_PREFIX} Workspace manager script exists but is not executable"
        return 1
    fi
    
    log_success "${LOG_PREFIX} Workspace manager script created successfully at ${scripts_dir}/workspace-manager.sh"
}

configure_time_integration() {
    log_info "${LOG_PREFIX} Configuring time and date management..."
    
    # Ensure HOME is set and valid
    if [[ -z "${HOME:-}" ]]; then
        log_error "${LOG_PREFIX} HOME environment variable is not set"
        return 1
    fi
    
    local scripts_dir="${HOME}/.config/hypr/scripts"
    if [[ ! -d "${scripts_dir}" ]]; then
        log_info "${LOG_PREFIX} Creating scripts directory at: ${scripts_dir}"
        if ! mkdir -p "${scripts_dir}" 2>/dev/null; then
            log_error "${LOG_PREFIX} Failed to create scripts directory: ${scripts_dir}"
            log_error "${LOG_PREFIX} Please check permissions and disk space"
            return 1
        fi
    else
        log_info "${LOG_PREFIX} Scripts directory already exists: ${scripts_dir}"
    fi
    
    # Verify time-related commands are available with more detailed feedback
    if ! command -v date &> /dev/null; then
        log_error "${LOG_PREFIX} date command not found - time functionality will be broken"
        log_error "${LOG_PREFIX} This is a critical dependency. Please install coreutils package."
        return 1
    else
        log_info "${LOG_PREFIX} Found date command: $(which date)"
        # Test date command functionality
        if ! date &>/dev/null; then
            log_warn "${LOG_PREFIX} date command exists but doesn't seem to be working properly"
        fi
    fi
    
    if ! command -v timedatectl &> /dev/null; then
        log_warn "${LOG_PREFIX} timedatectl command not found - timezone functionality will be limited"
        log_info "${LOG_PREFIX} Consider installing systemd for full timezone functionality"
    else
        log_info "${LOG_PREFIX} Found timedatectl: $(which timedatectl)"
        # Test timedatectl functionality
        if ! timedatectl status &>/dev/null; then
            log_warn "${LOG_PREFIX} timedatectl exists but may not be working properly"
        fi
    fi
    
    # Check for at command for alarm functionality
    if ! command -v at &> /dev/null; then
        log_warn "${LOG_PREFIX} at command not found - alarm functionality will be limited"
        log_info "${LOG_PREFIX} Consider installing at package: 'sudo apt install at' or equivalent"
    else
        log_info "${LOG_PREFIX} Found at command: $(which at)"
        # Check if atd service is running
        if ! systemctl is-active atd &>/dev/null; then
            log_warn "${LOG_PREFIX} at service (atd) is not running - alarms won't work"
            log_info "${LOG_PREFIX} Consider enabling atd service: 'sudo systemctl enable --now atd'"
        fi
    fi
    
    # Create time/date display script
    log_info "${LOG_PREFIX} Creating time and date manager script..."
    
    # Backup existing script if it exists
    if [[ -f "${scripts_dir}/time-date.sh" ]]; then
        log_info "${LOG_PREFIX} Backing up existing time and date manager script"
        if ! cp "${scripts_dir}/time-date.sh" "${scripts_dir}/time-date.sh.backup-$(date +%Y%m%d%H%M%S)"; then
            log_warn "${LOG_PREFIX} Failed to create backup of existing time and date manager script"
        fi
    fi
    if ! cat > "${scripts_dir}/time-date.sh" << 'EOF'
#!/bin/bash
# Time and Date Manager for HyprSupreme

show_time_menu() {
    local current_time=$(date '+%H:%M:%S')
    local current_date=$(date '+%A, %B %d, %Y')
    # Get timezone with error handling
    local timezone="Unknown"
    if command -v timedatectl &> /dev/null; then
        timezone=$(timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}' || echo "Unknown")
    fi
    local uptime=$(uptime -p)
    
    local menu="🕐 Current Time: $current_time
📅 Current Date: $current_date
🌍 Timezone: $timezone
⏱️ Uptime: $uptime

⚙️ Time Settings
🌐 Timezone Settings
⏰ Set Alarm
🗓️ Calendar"
    
    # Display menu with error handling
    local selection=""
    if ! command -v rofi &> /dev/null; then
        echo "ERROR: rofi command not found, cannot display time menu"
        notify-send "Time Menu" "rofi command not found" --icon=dialog-error 2>/dev/null || true
        return 1
    fi
    
    selection=$(echo "$menu" | rofi -dmenu -p "Time & Date" -theme-str 'window {width: 50%;}' 2>/dev/null || echo "")
    
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
    # Check if timedatectl is available
    if ! command -v timedatectl &> /dev/null; then
        notify-send "Timezone" "timedatectl command not available" --icon=dialog-error
        return 1
    fi
    
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
    
    # Exit if user cancels
    if [[ -z "$selection" ]]; then
        return 0
    fi
    
    local tz=$(echo "$selection" | grep -o '[A-Z][a-z_]*/[A-Z][a-z_]*')
    if [[ -z "$tz" ]]; then
        notify-send "Timezone" "Invalid timezone selection" --icon=dialog-warning
        return 1
    fi
    
    # Verify the timezone is valid
    if ! timedatectl list-timezones | grep -q "^$tz$"; then
        notify-send "Timezone" "Invalid timezone: $tz" --icon=dialog-warning
        return 1
    fi
    
    # Set the timezone with proper error handling
    # Set the timezone with comprehensive error handling
    if ! command -v sudo &> /dev/null; then
        notify-send "Timezone" "sudo command not found - cannot set timezone" --icon=dialog-error 2>/dev/null || true
        echo "ERROR: sudo command not found, cannot set timezone"
        return 1
    fi
    
    if sudo -n true 2>/dev/null; then
        # User has sudo privileges without password
        if sudo timedatectl set-timezone "$tz" 2>/dev/null; then
            notify-send "Timezone" "Timezone set to: $tz" --icon=preferences-system-time 2>/dev/null || true
            echo "SUCCESS: Timezone set to $tz"
        else
            notify-send "Timezone" "Failed to set timezone to: $tz" --icon=dialog-error 2>/dev/null || true
            echo "ERROR: Failed to set timezone to $tz"
            return 1
        fi
    else
        # User needs password for sudo
        notify-send "Timezone" "Setting timezone to $tz requires sudo password" --icon=dialog-password 2>/dev/null || true
        if sudo timedatectl set-timezone "$tz" 2>/dev/null; then
            notify-send "Timezone" "Timezone set to: $tz" --icon=preferences-system-time 2>/dev/null || true
            echo "SUCCESS: Timezone set to $tz"
        else
            notify-send "Timezone" "Failed to set timezone to: $tz" --icon=dialog-error 2>/dev/null || true
            echo "ERROR: Failed to set timezone to $tz"
            return 1
        fi
    fi
    
    return 0
}

set_alarm() {
    # Check for rofi with error handling
    if ! command -v rofi &> /dev/null; then
        echo "ERROR: rofi command not found, cannot set alarm"
        notify-send "Alarm" "rofi command not found" --icon=dialog-error 2>/dev/null || true
        return 1
    fi
    
    local time_input=$(rofi -dmenu -p "Set alarm time (HH:MM):" 2>/dev/null || echo "")
    
    # Exit if user cancels
    if [[ -z "$time_input" ]]; then
        return 0
    fi
    
    # Validate time format
    if [[ ! "$time_input" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        notify-send "Alarm" "Invalid time format. Use HH:MM" --icon=dialog-warning
        return 1
    fi
    
    # Validate hour and minute values
    local hour="${time_input%%:*}"
    local minute="${time_input##*:}"
    
    if ((hour < 0 || hour > 23 || minute < 0 || minute > 59)); then
        notify-send "Alarm" "Invalid time values. Hours: 00-23, Minutes: 00-59" --icon=dialog-warning
        return 1
    fi
    
    local message_input=$(rofi -dmenu -p "Alarm message (optional):" 2>/dev/null || echo "")
    local message="${message_input:-"Alarm"}"
    
    # Schedule alarm using at command
    if ! command -v at &> /dev/null; then
        notify-send "Alarm" "at command not available for scheduling alarms" --icon=dialog-error
        return 1
    fi
    
    # Check if at service is running
    if ! systemctl is-active atd &> /dev/null; then
        notify-send "Alarm" "at service (atd) is not running" --icon=dialog-error
        return 1
    fi
    
    # Check if notify-send is available
    if ! command -v notify-send &> /dev/null; then
        echo "WARNING: notify-send command not found - alarm will be scheduled but notification may not work"
    fi
    
    # Schedule alarm with comprehensive error handling
    local temp_file=$(mktemp)
    if [[ ! -f "$temp_file" ]]; then
        notify-send "Alarm Error" "Failed to create temporary file" --icon=dialog-error 2>/dev/null || true
        echo "ERROR: Failed to create temporary file for alarm scheduling"
        return 1
    fi
    
    echo "notify-send 'Alarm' '$message' --icon=alarm-clock --urgency=critical" > "$temp_file"
    
    if at "$time_input" < "$temp_file" 2>/dev/null; then
        notify-send "Alarm Set" "Alarm scheduled for $time_input: $message" --icon=alarm-clock 2>/dev/null || \
            echo "SUCCESS: Alarm scheduled for $time_input: $message"
        rm -f "$temp_file"
    else
        notify-send "Alarm Error" "Failed to schedule alarm" --icon=dialog-error 2>/dev/null || \
            echo "ERROR: Failed to schedule alarm for $time_input"
        rm -f "$temp_file"
        return 1
    fi
    
    return 0
}

show_world_clock() {
    # Check if date command supports TZ variable
    if ! TZ='UTC' date '+%H:%M' &>/dev/null; then
        notify-send "World Clock" "Your date command doesn't support TZ variable" --icon=dialog-error
        return 1
    fi
    
    local clocks=""
    local timezones=(
        "America/New_York:🇺🇸 New York:"
        "Europe/London:🇬🇧 London:"
        "Europe/Berlin:🇩🇪 Berlin:"
        "Asia/Tokyo:🇯🇵 Tokyo:"
        "Asia/Shanghai:🇨🇳 Shanghai:"
        "Australia/Sydney:🇦🇺 Sydney:"
        "Asia/Kolkata:🇮🇳 Mumbai:"
    )
    
    for tz_entry in "${timezones[@]}"; do
        local timezone="${tz_entry%%:*}"
        local label="${tz_entry#*:}"
        local time
        
        # Try to get time for this timezone with error handling
        if time=$(TZ="$timezone" date '+%H:%M' 2>/dev/null); then
            clocks+="${label} ${time}\n"
        else
            clocks+="${label} Error\n"
        fi
    done
    
    # Remove trailing newline
    clocks="${clocks%\\n}"
    
    echo -e "$clocks" | rofi -dmenu -p "World Clock" -theme-str 'window {width: 40%;}'
    return 0
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
    then
        log_error "${LOG_PREFIX} Failed to create time and date manager script at ${scripts_dir}/time-date.sh"
        log_error "${LOG_PREFIX} Please check permissions and disk space"
        return 1
    fi
    
    # Set executable permissions with more verbose error handling
    if ! chmod +x "${scripts_dir}/time-date.sh"; then
        log_error "${LOG_PREFIX} Failed to set executable permissions on time and date manager script"
        log_error "${LOG_PREFIX} Please check file permissions: ${scripts_dir}/time-date.sh"
        return 1
    fi
    
    # Verify the script was created properly
    if [[ ! -x "${scripts_dir}/time-date.sh" ]]; then
        log_error "${LOG_PREFIX} Time and date manager script exists but is not executable"
        return 1
    fi
    
    log_success "${LOG_PREFIX} Time and date manager script created successfully at ${scripts_dir}/time-date.sh"
}

# Test installation
test_workspace_time() {
    log_info "${LOG_PREFIX} Testing workspace and time management..."
    
    # Create temp log file for test results
    local test_log="/tmp/workspace_time_test_$(date +%Y%m%d%H%M%S).log"
    echo "Workspace and Time Management Test Log - $(date)" > "$test_log"
    echo "-----------------------------------------------" >> "$test_log"
    local errors=0
    local warnings=0
    
    # Check script files
    local scripts_dir="$HOME/.config/hypr/scripts"
    if [[ -d "$scripts_dir" ]]; then
        log_success "${LOG_PREFIX} ✅ Scripts directory exists: ${scripts_dir}"
        echo "PASS: Scripts directory exists: ${scripts_dir}" >> "$test_log"
        
        # Check workspace script
        if [[ -f "$scripts_dir/workspace-manager.sh" ]]; then
            log_success "${LOG_PREFIX} ✅ Workspace manager script found"
            echo "PASS: Workspace manager script found at ${scripts_dir}/workspace-manager.sh" >> "$test_log"
            
            if [[ -x "${scripts_dir}/workspace-manager.sh" ]]; then
                log_success "${LOG_PREFIX} ✅ Workspace manager script is executable"
                echo "PASS: Workspace manager script is executable" >> "$test_log"
                
                # Check if script is valid bash
                if bash -n "${scripts_dir}/workspace-manager.sh" &>/dev/null; then
                    log_success "${LOG_PREFIX} ✅ Workspace manager script syntax is valid"
                    echo "PASS: Workspace manager script syntax is valid" >> "$test_log"
                else
                    log_error "${LOG_PREFIX} ❌ Workspace manager script has syntax errors"
                    echo "FAIL: Workspace manager script has syntax errors" >> "$test_log"
                    ((errors++))
                fi
            else
                log_error "${LOG_PREFIX} ❌ Workspace manager script is not executable"
                echo "FAIL: Workspace manager script is not executable" >> "$test_log"
                ((errors++))
            fi
        else
            log_error "${LOG_PREFIX} ❌ Workspace manager script not found"
            echo "FAIL: Workspace manager script not found at ${scripts_dir}/workspace-manager.sh" >> "$test_log"
            ((errors++))
        fi
        
        # Check time script
        if [[ -f "$scripts_dir/time-date.sh" ]]; then
            log_success "${LOG_PREFIX} ✅ Time and date manager script found"
            echo "PASS: Time and date manager script found at ${scripts_dir}/time-date.sh" >> "$test_log"
            
            if [[ -x "${scripts_dir}/time-date.sh" ]]; then
                log_success "${LOG_PREFIX} ✅ Time and date manager script is executable"
                echo "PASS: Time and date manager script is executable" >> "$test_log"
                
                # Check if script is valid bash
                if bash -n "${scripts_dir}/time-date.sh" &>/dev/null; then
                    log_success "${LOG_PREFIX} ✅ Time and date manager script syntax is valid"
                    echo "PASS: Time and date manager script syntax is valid" >> "$test_log"
                else
                    log_error "${LOG_PREFIX} ❌ Time and date manager script has syntax errors"
                    echo "FAIL: Time and date manager script has syntax errors" >> "$test_log"
                    ((errors++))
                fi
            else
                log_error "${LOG_PREFIX} ❌ Time and date manager script is not executable"
                echo "FAIL: Time and date manager script is not executable" >> "$test_log"
                ((errors++))
            fi
        else
            log_error "${LOG_PREFIX} ❌ Time and date manager script not found"
            echo "FAIL: Time and date manager script not found at ${scripts_dir}/time-date.sh" >> "$test_log"
            ((errors++))
        fi
    else
        log_error "${LOG_PREFIX} ❌ Scripts directory not found: ${scripts_dir}"
        echo "FAIL: Scripts directory not found: ${scripts_dir}" >> "$test_log"
        ((errors++))
    fi
    
    # Check if hyprctl is available
    if command -v hyprctl &> /dev/null; then
        log_success "${LOG_PREFIX} ✅ Hyprland control available: $(which hyprctl)"
        echo "PASS: Hyprland control available: $(which hyprctl)" >> "$test_log"
        
        # Test if hyprctl is working
        if hyprctl version &>/dev/null; then
            log_success "${LOG_PREFIX} ✅ Hyprland control is functioning"
            echo "PASS: Hyprland control is functioning" >> "$test_log"
        else
            log_warn "${LOG_PREFIX} ⚠️  Hyprland control exists but may not be functioning"
            echo "WARN: Hyprland control exists but may not be functioning" >> "$test_log"
            ((warnings++))
        fi
    else
        log_warn "${LOG_PREFIX} ⚠️  Hyprland control not found"
        echo "WARN: Hyprland control not found" >> "$test_log"
        ((warnings++))
    fi
    
    # Check date/time tools
    if command -v date &> /dev/null; then
        log_success "${LOG_PREFIX} ✅ Date command available: $(which date)"
        echo "PASS: Date command available: $(which date)" >> "$test_log"
        
        # Test if date command is working properly
        if date &>/dev/null; then
            log_success "${LOG_PREFIX} ✅ Date command is functioning"
            echo "PASS: Date command is functioning" >> "$test_log"
            
            # Test timezone support in date command
            if TZ="UTC" date &>/dev/null; then
                log_success "${LOG_PREFIX} ✅ Date command has timezone support"
                echo "PASS: Date command has timezone support" >> "$test_log"
            else
                log_warn "${LOG_PREFIX} ⚠️  Date command doesn't support TZ variable"
                echo "WARN: Date command doesn't support TZ variable" >> "$test_log"
                ((warnings++))
            fi
        else
            log_error "${LOG_PREFIX} ❌ Date command exists but is not functioning"
            echo "FAIL: Date command exists but is not functioning" >> "$test_log"
            ((errors++))
        fi
    else
        log_error "${LOG_PREFIX} ❌ Date command not found"
        echo "FAIL: Date command not found" >> "$test_log"
        ((errors++))
    fi
    
    if command -v timedatectl &> /dev/null; then
        log_success "${LOG_PREFIX} ✅ System time control available: $(which timedatectl)"
        echo "PASS: System time control available: $(which timedatectl)" >> "$test_log"
        
        # Test timedatectl status functionality
        if timedatectl status &>/dev/null; then
            log_success "${LOG_PREFIX} ✅ System time status works"
            echo "PASS: System time status works" >> "$test_log"
            
            # Extract current timezone
            current_tz=$(timedatectl status 2>/dev/null | grep "Time zone" | awk '{print $3}' || echo "unknown")
            log_info "${LOG_PREFIX} Current timezone: ${current_tz}"
            echo "INFO: Current timezone: ${current_tz}" >> "$test_log"
        else
            log_warn "${LOG_PREFIX} ⚠️  System time status not working"
            echo "WARN: System time status not working" >> "$test_log"
            ((warnings++))
        fi
        
        # Test timezone list functionality
        if timedatectl list-timezones &>/dev/null; then
            log_success "${LOG_PREFIX} ✅ Timezone listing works"
            echo "PASS: Timezone listing works" >> "$test_log"
            
            # Count available timezones
            tz_count=$(timedatectl list-timezones 2>/dev/null | wc -l || echo "unknown")
            log_info "${LOG_PREFIX} Available timezones: ${tz_count}"
            echo "INFO: Available timezones: ${tz_count}" >> "$test_log"
        else
            log_warn "${LOG_PREFIX} ⚠️  Timezone listing not working"
            echo "WARN: Timezone listing not working" >> "$test_log"
            ((warnings++))
        fi
    else
        log_warn "${LOG_PREFIX} ⚠️  System time control not available"
        echo "WARN: System time control not available" >> "$test_log"
        ((warnings++))
    fi
    
    # Check alarm prerequisites
    if command -v at &> /dev/null; then
        log_success "${LOG_PREFIX} ✅ at command available for alarms: $(which at)"
        echo "PASS: at command available for alarms: $(which at)" >> "$test_log"
        
        # Test if at command works
        if echo "echo test" | at now+1minute 2>/dev/null; then
            log_success "${LOG_PREFIX} ✅ at command is functioning"
            echo "PASS: at command is functioning" >> "$test_log"
        else
            log_warn "${LOG_PREFIX} ⚠️  at command exists but may not be functioning"
            echo "WARN: at command exists but may not be functioning" >> "$test_log"
            ((warnings++))
        fi
        
        # Check if atd service is running
        if command -v systemctl &>/dev/null; then
            if systemctl is-active atd &>/dev/null; then
                log_success "${LOG_PREFIX} ✅ at service (atd) is running"
                echo "PASS: at service (atd) is running" >> "$test_log"
                
                # Check at service status
                atd_status=$(systemctl status atd 2>/dev/null | grep "Active:" || echo "unknown")
                log_info "${LOG_PREFIX} atd service status: ${atd_status}"
                echo "INFO: atd service status: ${atd_status}" >> "$test_log"
            else
                log_warn "${LOG_PREFIX} ⚠️  at service (atd) is not running"
                echo "WARN: at service (atd) is not running" >> "$test_log"
                log_info "${LOG_PREFIX} Enable with: sudo systemctl enable --now atd"
                echo "INFO: Enable with: sudo systemctl enable --now atd" >> "$test_log"
                ((warnings++))
            fi
        else
            log_warn "${LOG_PREFIX} ⚠️  systemctl not available, cannot check atd service"
            echo "WARN: systemctl not available, cannot check atd service" >> "$test_log"
            ((warnings++))
        fi
    else
        log_warn "${LOG_PREFIX} ⚠️  at command not available for alarms"
        echo "WARN: at command not available for alarms" >> "$test_log"
        log_info "${LOG_PREFIX} Install with: sudo apt install at"
        echo "INFO: Install with: sudo apt install at" >> "$test_log"
        ((warnings++))
    fi
    
    # Check notification command
    if command -v notify-send &> /dev/null; then
        log_success "${LOG_PREFIX} ✅ Notification command available: $(which notify-send)"
        echo "PASS: Notification command available: $(which notify-send)" >> "$test_log"
        
        # Test if notifications work
        if notify-send "Test" "This is a test notification from workspace_time module" --icon=info 2>/dev/null; then
            log_success "${LOG_PREFIX} ✅ Notifications are functioning"
            echo "PASS: Notifications are functioning" >> "$test_log"
        else
            log_warn "${LOG_PREFIX} ⚠️  notify-send exists but may not be functioning"
            echo "WARN: notify-send exists but may not be functioning" >> "$test_log"
            ((warnings++))
        fi
    else
        log_warn "${LOG_PREFIX} ⚠️  notify-send command not available"
        echo "WARN: notify-send command not available" >> "$test_log"
        log_info "${LOG_PREFIX} Install with: sudo apt install libnotify-bin"
        echo "INFO: Install with: sudo apt install libnotify-bin" >> "$test_log"
        ((warnings++))
    fi
    
    # Check rofi for menus
    if command -v rofi &> /dev/null; then
        log_success "${LOG_PREFIX} ✅ Rofi available for menus: $(which rofi)"
        echo "PASS: Rofi available for menus: $(which rofi)" >> "$test_log"
        
        # Test if rofi works
        if echo "test" | rofi -dmenu -p "Test" 2>/dev/null; then
            log_success "${LOG_PREFIX} ✅ Rofi is functioning"
            echo "PASS: Rofi is functioning" >> "$test_log"
        else
            log_warn "${LOG_PREFIX} ⚠️  Rofi exists but may not be functioning"
            echo "WARN: Rofi exists but may not be functioning" >> "$test_log"
            ((warnings++))
        fi
    else
        log_warn "${LOG_PREFIX} ⚠️  Rofi not available for menus"
        echo "WARN: Rofi not available for menus" >> "$test_log"
        log_info "${LOG_PREFIX} Install with: sudo apt install rofi"
        echo "INFO: Install with: sudo apt install rofi" >> "$test_log"
        ((warnings++))
    fi
    
    if ((errors > 0)); then
        log_error "${LOG_PREFIX} Test completed with $errors errors and $warnings warnings"
        echo "SUMMARY: Test completed with $errors errors and $warnings warnings" >> "$test_log"
        log_info "${LOG_PREFIX} Test log saved to: $test_log"
        return 1
    elif ((warnings > 0)); then
        log_warn "${LOG_PREFIX} Test completed with $warnings warnings"
        echo "SUMMARY: Test completed with $warnings warnings" >> "$test_log"
        log_info "${LOG_PREFIX} Test log saved to: $test_log"
        return 0
    else
        log_success "${LOG_PREFIX} All tests passed successfully"
        echo "SUMMARY: All tests passed successfully" >> "$test_log"
        log_info "${LOG_PREFIX} Test log saved to: $test_log"
        return 0
    fi
}

# Validate installation environment
validate_environment() {
    log_info "${LOG_PREFIX} Validating environment..."
    local errors=0
    
    # Create validation log
    local validation_log="/tmp/workspace_time_validation_$(date +%Y%m%d%H%M%S).log"
    echo "Workspace and Time Management Validation Log - $(date)" > "$validation_log"
    echo "-----------------------------------------------" >> "$validation_log"
    
    # Check for critical dependencies with detailed output
    if ! command -v mkdir &>/dev/null; then
        log_error "${LOG_PREFIX} mkdir command not found - cannot create directories"
        echo "CRITICAL: mkdir command not found - cannot create directories" >> "$validation_log"
        ((errors++))
    else
        echo "PASS: mkdir command found: $(which mkdir)" >> "$validation_log"
    fi
    
    if ! command -v chmod &>/dev/null; then
        log_error "${LOG_PREFIX} chmod command not found - cannot set permissions"
        echo "CRITICAL: chmod command not found - cannot set permissions" >> "$validation_log"
        ((errors++))
    else
        echo "PASS: chmod command found: $(which chmod)" >> "$validation_log"
    fi
    
    # Check that HOME exists and is valid
    if [[ -z "${HOME:-}" ]]; then
        log_error "${LOG_PREFIX} HOME environment variable not set"
        echo "CRITICAL: HOME environment variable not set" >> "$validation_log"
        ((errors++))
    elif [[ ! -d "$HOME" ]]; then
        log_error "${LOG_PREFIX} HOME directory does not exist: $HOME"
        echo "CRITICAL: HOME directory does not exist: $HOME" >> "$validation_log"
        ((errors++))
    elif [[ ! -w "$HOME" ]]; then
        log_error "${LOG_PREFIX} HOME directory is not writable: $HOME"
        echo "CRITICAL: HOME directory is not writable: $HOME" >> "$validation_log"
        ((errors++))
    else
        echo "PASS: HOME directory exists and is writable: $HOME" >> "$validation_log"
    fi
    
    # Check for critical configuration directories
    if [[ -n "${HOME:-}" ]]; then
        if [[ ! -d "$HOME/.config" ]]; then
            if ! mkdir -p "$HOME/.config" 2>/dev/null; then
                log_error "${LOG_PREFIX} Failed to create .config directory"
                echo "CRITICAL: Failed to create .config directory" >> "$validation_log"
                ((errors++))
            else
                echo "INFO: Created .config directory" >> "$validation_log"
            fi
        else
            echo "PASS: .config directory exists" >> "$validation_log"
        fi
    fi
    
    # Check for non-critical but important dependencies with detailed information
    if ! command -v rofi &>/dev/null; then
        log_warn "${LOG_PREFIX} rofi not found - menu functionality will be broken"
        echo "WARNING: rofi not found - menu functionality will be broken" >> "$validation_log"
        echo "SUGGESTION: Install rofi with 'sudo apt install rofi' or equivalent" >> "$validation_log"
    else
        echo "PASS: rofi found: $(which rofi)" >> "$validation_log"
        
        # Check rofi version
        rofi_version=$(rofi -version 2>/dev/null | head -n 1 || echo "unknown")
        log_info "${LOG_PREFIX} Rofi version: $rofi_version"
        echo "INFO: Rofi version: $rofi_version" >> "$validation_log"
    fi
    
    if ! command -v hyprctl &>/dev/null; then
        log_warn "${LOG_PREFIX} hyprctl not found - workspace functionality will be limited"
        echo "WARNING: hyprctl not found - workspace functionality will be limited" >> "$validation_log"
        echo "SUGGESTION: Ensure Hyprland is properly installed" >> "$validation_log"
    else
        echo "PASS: hyprctl found: $(which hyprctl)" >> "$validation_log"
        
        # Check hyprctl version
        hypr_version=$(hyprctl version 2>/dev/null | head -n 1 || echo "unknown")
        log_info "${LOG_PREFIX} Hyprland version: $hypr_version"
        echo "INFO: Hyprland version: $hypr_version" >> "$validation_log"
    fi
    
    if ! command -v date &>/dev/null; then
        log_warn "${LOG_PREFIX} date command not found - time functionality will be broken"
        echo "WARNING: date command not found - time functionality will be broken" >> "$validation_log"
        echo "SUGGESTION: Install coreutils package" >> "$validation_log"
    else
        echo "PASS: date command found: $(which date)" >> "$validation_log"
    fi
    
    # Check for notification capabilities
    if ! command -v notify-send &>/dev/null; then
        log_warn "${LOG_PREFIX} notify-send not found - notifications will not work"
        echo "WARNING: notify-send not found - notifications will not work" >> "$validation_log"
        echo "SUGGESTION: Install libnotify-bin with 'sudo apt install libnotify-bin' or equivalent" >> "$validation_log"
    else
        echo "PASS: notify-send found: $(which notify-send)" >> "$validation_log"
    fi
    
    # Check for alarm scheduling capabilities
    if ! command -v at &>/dev/null; then
        log_warn "${LOG_PREFIX} at command not found - alarm functionality will not work"
        echo "WARNING: at command not found - alarm functionality will not work" >> "$validation_log"
        echo "SUGGESTION: Install at with 'sudo apt install at' or equivalent" >> "$validation_log"
    else
        echo "PASS: at command found: $(which at)" >> "$validation_log"
        
        # Check atd service status
        if command -v systemctl &>/dev/null; then
            if systemctl is-active atd &>/dev/null; then
                echo "PASS: atd service is running" >> "$validation_log"
            else
                log_warn "${LOG_PREFIX} atd service is not running - alarms won't work"
                echo "WARNING: atd service is not running - alarms won't work" >> "$validation_log"
                echo "SUGGESTION: Enable atd service with 'sudo systemctl enable --now atd'" >> "$validation_log"
            fi
        fi
    fi
    
    if ((errors > 0)); then
    # Check for write permissions in ~/.config/hypr/scripts
    local scripts_dir="${HOME}/.config/hypr/scripts"
    mkdir -p "${scripts_dir}" 2>/dev/null
    if [[ ! -d "${scripts_dir}" ]]; then
        log_warn "${LOG_PREFIX} Could not create scripts directory: ${scripts_dir}"
        echo "WARNING: Could not create scripts directory: ${scripts_dir}" >> "$validation_log"
    elif [[ ! -w "${scripts_dir}" ]]; then
        log_warn "${LOG_PREFIX} Scripts directory is not writable: ${scripts_dir}"
        echo "WARNING: Scripts directory is not writable: ${scripts_dir}" >> "$validation_log"
    else
        echo "PASS: Scripts directory exists and is writable: ${scripts_dir}" >> "$validation_log"
    fi
    
    if ((errors > 0)); then
        log_error "${LOG_PREFIX} Environment validation failed with $errors errors"
        echo "SUMMARY: Environment validation failed with $errors errors" >> "$validation_log"
        log_info "${LOG_PREFIX} Validation log saved to: $validation_log"
        return 1
    fi
    
    log_success "${LOG_PREFIX} Environment validation passed"
    echo "SUMMARY: Environment validation passed" >> "$validation_log"
    log_info "${LOG_PREFIX} Validation log saved to: $validation_log"
    return 0
}

# Main execution
# Function to display version and help information
show_help() {
    cat << EOF
HyprSupreme-Builder - Workspace and Time Management Module
Version: 1.1.0

Usage: $(basename "$0") {install|configure|test|validate|help|version}

Commands:
  install    Install workspace and time management components
  configure  Configure workspace and time management components only
  test       Test the installation
  validate   Validate the environment
  help       Display this help message
  version    Display version information

For more information, visit: https://github.com/yourusername/HyprSupreme-Builder
EOF
}

show_version() {
    echo "HyprSupreme-Builder - Workspace and Time Management Module"
    echo "Version: 1.1.0"
    echo "Copyright (c) $(date +%Y)"
}

# Process command line arguments
case "${1:-install}" in
    "install")
        log_info "${LOG_PREFIX} Starting installation process..."
        if validate_environment; then
            install_workspace_time
            exit_code=$?
            if [[ $exit_code -eq 0 ]]; then
                log_success "${LOG_PREFIX} Installation completed successfully"
            else
                log_error "${LOG_PREFIX} Installation failed with exit code: $exit_code"
                exit 1
            fi
        else
            log_error "${LOG_PREFIX} Installation aborted due to environment validation failure"
            log_info "${LOG_PREFIX} Fix the reported issues and try again"
            exit 1
        fi
        ;;
    "configure")
        log_info "${LOG_PREFIX} Starting configuration process..."
        if validate_environment; then
            # First configure workspace integration
            if ! configure_workspace_integration; then
                log_error "${LOG_PREFIX} Workspace integration configuration failed"
                exit 1
            fi
            
            # Then configure time integration
            if ! configure_time_integration; then
                log_error "${LOG_PREFIX} Time integration configuration failed"
                exit 1
            fi
            
            log_success "${LOG_PREFIX} Configuration completed successfully"
        else
            log_error "${LOG_PREFIX} Configuration aborted due to environment validation failure"
            log_info "${LOG_PREFIX} Fix the reported issues and try again"
            exit 1
        fi
        ;;
    "test")
        log_info "${LOG_PREFIX} Starting test process..."
        test_workspace_time
        exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            log_success "${LOG_PREFIX} Tests completed successfully"
        else
            log_error "${LOG_PREFIX} Tests failed with exit code: $exit_code"
            exit 1
        fi
        ;;
    "validate")
        log_info "${LOG_PREFIX} Starting validation process..."
        validate_environment
        exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            log_success "${LOG_PREFIX} Validation completed successfully"
        else
            log_error "${LOG_PREFIX} Validation failed with exit code: $exit_code"
            exit 1
        fi
        ;;
    "help")
        show_help
        ;;
    "version")
        show_version
        ;;
    *)
        echo "Error: Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

