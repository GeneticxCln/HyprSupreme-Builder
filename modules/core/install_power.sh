#!/bin/bash
# HyprSupreme-Builder - Power Management Installation Module

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
readonly E_POWER=7  # Power-specific errors

# Path to the script
readonly SCRIPT_PATH="$(readlink -f "$0")"
readonly SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
readonly CONFIG_DIR="$HOME/.config"
readonly BACKUP_DIR="$HOME/.config/power-backup-$(date +%Y%m%d-%H%M%S)"

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
    # Kill any running power test processes
    pkill -f "power-test.sh" 2>/dev/null || true
    
    # Remove any temporary files
    rm -f "/tmp/power_test_*.log" 2>/dev/null || true
}

# Power-specific error handler
handle_power_error() {
    local error_type="$1"
    local error_message="$2"
    
    case "$error_type" in
        "service")
            log_error "Power service error: $error_message"
            return $E_SERVICE
            ;;
        "config")
            log_error "Power configuration error: $error_message"
            return $E_CONFIG
            ;;
        "test")
            log_error "Power test error: $error_message"
            return $E_POWER
            ;;
        *)
            log_error "Unknown power error: $error_message"
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
    if [[ -d "$CONFIG_DIR/power" ]]; then
        log_info "Backing up existing power management configuration..."
        
        # Create backup directory
        if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
            log_error "Failed to create backup directory: $BACKUP_DIR"
            return $E_DIRECTORY
        fi
        
        # Backup power config if it exists
        if ! cp -r "$CONFIG_DIR/power" "$BACKUP_DIR/" 2>/dev/null; then
            log_warn "Failed to backup power configuration"
        else
            log_info "Backed up power configuration"
        fi
        
        # Backup TLP config if it exists
        if [[ -f "/etc/tlp.conf" ]]; then
            if ! sudo cp "/etc/tlp.conf" "$BACKUP_DIR/" 2>/dev/null; then
                log_warn "Failed to backup TLP configuration"
            else
                log_info "Backed up TLP configuration"
            fi
        fi
        
        log_success "Configuration backup completed to $BACKUP_DIR"
    fi
    
    return $E_SUCCESS
}

install_power() {
    log_info "Installing power management system..."
    
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
    backup_config || log_warn "Backup failed, continuing anyway"
    
    # Detect laptop/desktop
    if [[ -f "/sys/class/power_supply/BAT0" ]] || [[ -f "/sys/class/power_supply/BAT1" ]]; then
        log_info "Laptop system detected - configuring laptop power management"
        export IS_LAPTOP=true
    else
        log_info "Desktop system detected - configuring desktop power management"
        export IS_LAPTOP=false
    fi
    
    # Install power management tools
    if ! install_power_tools; then
        handle_power_error "service" "Failed to install power management tools"
        return $E_DEPENDENCY
    fi
    
    # Install power GUI tools
    if ! install_power_gui; then
        log_warn "Failed to install power GUI tools - continuing with core functionality"
    fi
    
    # Configure power integration
    if ! configure_power_integration; then
        handle_power_error "config" "Failed to configure power integration"
        return $E_CONFIG
    fi
    
    # Run final validation
    if ! test_power; then
        log_warn "Power management system installed but some tests failed"
    fi
    
    log_success "Power management system installation completed"
    return $E_SUCCESS
}

install_power_tools() {
    log_info "Installing power management tools..."
    
    # Define core packages for all systems
    local core_packages=(
        # Core power management
        "acpi"
        "acpid"
        "power-profiles-daemon"
        "upower"
        
        # System monitoring
        "powertop"
        "htop"
        "iotop"
        
        # Suspend/hibernate
        "systemd"
    )
    
    # Define laptop-specific packages
    local laptop_packages=(
        # Laptop power management
        "acpi_call"
        "tlp"
        "tlp-rdw"
        
        # CPU frequency scaling
        "cpupower"
        "auto-cpufreq"
    )
    
    # Combine packages based on system type
    local packages=("${core_packages[@]}")
    if [[ "${IS_LAPTOP:-false}" == "true" ]]; then
        packages+=("${laptop_packages[@]}")
    fi
    
    # Install packages with error handling
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install power management packages"
        return $E_DEPENDENCY
    fi
    
    # Verify installation of critical components
    if ! command -v acpi &> /dev/null; then
        log_error "Critical power management tool (acpi) installation failed"
        return $E_DEPENDENCY
    fi
    
    # Enable and start acpid service with error handling
    log_info "Enabling ACPI daemon service..."
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to enable power services"
    fi
    
    if ! sudo systemctl enable acpid.service &>/dev/null; then
        log_warn "Failed to enable acpid.service, trying alternative method..."
        # Try alternative methods
        if ! sudo update-rc.d acpid defaults &>/dev/null && ! sudo chkconfig acpid on &>/dev/null; then
            log_warn "Failed to enable acpid service using alternative methods"
            # Continue anyway as this isn't critical for basic functionality
        fi
    else
        log_success "Successfully enabled acpid service"
    fi
    
    # Start acpid service
    if ! sudo systemctl start acpid.service &>/dev/null; then
        log_warn "Could not start acpid service (may need reboot)"
        # Try alternative approach to start the service
        log_info "Attempting alternative method to start acpid service..."
        if ! sudo /etc/init.d/acpid start 2>/dev/null && ! sudo service acpid start 2>/dev/null; then
            log_warn "Alternative methods also failed to start acpid service"
            log_info "This is not critical - service will start on next boot"
        else
            log_success "Successfully started acpid service using alternative method"
        fi
    } else {
        log_success "Successfully started acpid service"
    }
    
    # Configure TLP for laptop power management
    if [[ "${IS_LAPTOP:-false}" == "true" ]]; then
        log_info "Configuring TLP for laptop power management..."
        
        # Enable TLP service
        if ! sudo systemctl enable tlp.service &>/dev/null; then
            log_warn "Failed to enable TLP service, trying alternative method..."
            if ! sudo update-rc.d tlp defaults &>/dev/null && ! sudo chkconfig tlp on &>/dev/null; then
                log_warn "Failed to enable TLP service using alternative methods"
            fi
        else
            log_success "Successfully enabled TLP service"
        fi
        
        # Start TLP service
        if ! sudo systemctl start tlp.service &>/dev/null; then
            log_warn "Could not start TLP service (may need reboot)"
            # Try alternative methods
            if ! sudo /etc/init.d/tlp start 2>/dev/null && ! sudo service tlp start 2>/dev/null; then
                log_warn "Alternative methods also failed to start TLP service"
            } else {
                log_success "Successfully started TLP service using alternative method"
            }
        } else {
            log_success "Successfully started TLP service"
        }
        
        # Configure CPU frequency scaling if available
        if command -v cpupower &> /dev/null; then
            log_info "Configuring CPU frequency scaling..."
            # Set initial CPU governor based on power state
            if cat /sys/class/power_supply/*/status 2>/dev/null | grep -q "Discharging"; then
                sudo cpupower frequency-set -g powersave &>/dev/null || log_warn "Failed to set CPU governor to powersave"
            else
                sudo cpupower frequency-set -g performance &>/dev/null || log_warn "Failed to set CPU governor to performance"
            fi
        fi
    fi
    
    # Verify services are enabled
    local service_errors=0
    if ! systemctl is-enabled acpid.service &>/dev/null; then
        log_warn "acpid service is not enabled properly"
        ((service_errors++))
    fi
    
    if [[ "${IS_LAPTOP:-false}" == "true" ]] && ! systemctl is-enabled tlp.service &>/dev/null; then
        log_warn "TLP service is not enabled properly"
        ((service_errors++))
    fi
    
    if [[ $service_errors -gt 0 ]]; then
        log_warn "Some power services could not be enabled ($service_errors errors)"
    }
    
    log_success "Power management tools installed"
    return $E_SUCCESS
}

install_power_gui() {
    log_info "Installing power management GUI tools..."
    
    local gui_tools=()
    local selection=""
    
    # Check user preference for power GUI if whiptail is available
    if command -v whiptail &> /dev/null; then
        log_info "Presenting GUI tool selection dialog..."
        
        # Use a subshell to prevent script exit on dialog cancel
        selection=$(whiptail --title "Power Management GUI" \
            --checklist "Choose power management GUI tools:" 15 70 5 \
            "xfce4-power-manager" "XFCE Power Manager (recommended)" ON \
            "gnome-power-manager" "GNOME Power Manager" OFF \
            "powertop" "Intel PowerTOP (monitoring)" ON \
            "cpu-x" "System information tool" OFF \
            3>&1 1>&2 2>&3) || selection=""
        
        if [[ $selection == *"xfce4-power-manager"* ]]; then
            gui_tools+=("xfce4-power-manager")
        fi
        
        if [[ $selection == *"gnome-power-manager"* ]]; then
            gui_tools+=("gnome-power-manager")
        fi
        
        if [[ $selection == *"powertop"* ]]; then
            gui_tools+=("powertop")
        fi
        
        if [[ $selection == *"cpu-x"* ]]; then
            gui_tools+=("cpu-x")
        fi
    else
        # Default selection if whiptail is not available
        log_warn "whiptail not found, using default selection"
        gui_tools=("xfce4-power-manager" "powertop")
    fi
    
    # Install selected GUI tools
    if [[ ${#gui_tools[@]} -gt 0 ]]; then
        log_info "Installing selected power management GUI tools: ${gui_tools[*]}"
        
        if ! install_packages "${gui_tools[@]}"; then
            log_warn "Failed to install some power management GUI tools"
            # Continue anyway as these are optional
        } else {
            log_success "Power management GUI tools installed"
        }
    else
        log_warn "No power management GUI tools selected"
    fi
    
    # Verify at least one tool is installed if any were requested
    if [[ ${#gui_tools[@]} -gt 0 ]] && ! command -v xfce4-power-manager &> /dev/null && 
       ! command -v gnome-power-manager &> /dev/null && ! command -v cpu-x &> /dev/null; then
        log_warn "No power management GUI tools were successfully installed"
    fi
    
    return $E_SUCCESS
}

configure_power_integration() {
    log_info "Configuring power management integration..."
    
    # Create power scripts directory with error handling
    local scripts_dir="$HOME/.config/hypr/scripts"
    if [[ ! -d "$scripts_dir" ]]; then
        log_info "Creating scripts directory: $scripts_dir"
        if ! mkdir -p "$scripts_dir" 2>/dev/null; then
            log_error "Failed to create scripts directory: $scripts_dir"
            return $E_DIRECTORY
        fi
    } else {
        log_info "Scripts directory already exists: $scripts_dir"
    }
    
    # Check write permissions
    if [[ ! -w "$scripts_dir" ]]; then
        log_error "No write permission for scripts directory: $scripts_dir"
        return $E_PERMISSION
    fi
    
    # Create power control script
    if ! create_power_control_script; then
        log_error "Failed to create power control script"
        return $E_CONFIG
    fi
    
    # Create power profiles script
    if ! create_power_profiles_script; then
        log_error "Failed to create power profiles script"
        return $E_CONFIG
    fi
    
    # Create battery monitor script for laptops
    if [[ "${IS_LAPTOP:-false}" == "true" ]]; then
        if ! create_battery_monitor_script; then
            log_error "Failed to create battery monitor script"
            return $E_CONFIG
        fi
    }
    
    # Configure power settings
    if ! configure_power_settings; then
        log_error "Failed to configure power settings"
        return $E_CONFIG
    fi
    
    # Add autostart configuration for Hyprland
    if [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
        log_info "Adding power management autostart to Hyprland configuration..."
        
        # Check if autostart is already configured
        if ! grep -q "power-autostart.sh" "$HOME/.config/hypr/hyprland.conf"; then
            # Backup the file
            cp "$HOME/.config/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf.bak"
            
            # Add autostart line
            if ! echo '# Power management autostart' >> "$HOME/.config/hypr/hyprland.conf" ||
               ! echo 'exec-once = ~/.config/hypr/scripts/power-autostart.sh' >> "$HOME/.config/hypr/hyprland.conf"; then
                log_warn "Failed to add power management autostart to Hyprland configuration"
                log_info "Please add the following line to your Hyprland configuration:"
                log_info "exec-once = ~/.config/hypr/scripts/power-autostart.sh"
            } else {
                log_success "Added power management autostart to Hyprland configuration"
            }
        } else {
            log_info "Power management autostart already configured in Hyprland"
        }
    }
    
    log_success "Power management integration configured"
    return $E_SUCCESS
}

create_power_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/power-control.sh"
    
    log_info "Creating power control script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
#!/bin/bash
# Power Control Script for HyprSupreme

show_power_menu() {
    local battery_info=""
    local power_profile=""
    
    # Get battery info if available
    if [ -f "/sys/class/power_supply/BAT0/capacity" ]; then
        local battery_level=$(cat /sys/class/power_supply/BAT0/capacity)
        local battery_status=$(cat /sys/class/power_supply/BAT0/status)
        battery_info="🔋 Battery: ${battery_level}% (${battery_status})"
    else
        battery_info="🔌 AC Power"
    fi
    
    # Get current power profile
    if command -v powerprofilesctl &> /dev/null; then
        power_profile=$(powerprofilesctl get)
        power_profile="⚡ Profile: ${power_profile}"
    else
        power_profile="⚡ Power Profiles: Not Available"
    fi
    
    local menu="${battery_info}
${power_profile}
🔋 Power Profiles
📊 Battery Monitor
⚙️ Power Settings
💻 System Monitor
🌙 Suspend
🔄 Restart
⏻ Shutdown"
    
    local selection=$(echo "$menu" | rofi -dmenu -p "Power Control" -theme-str 'window {width: 40%;}')
    
    case "$selection" in
        *"Power Profiles"*)
            "$HOME/.config/hypr/scripts/power-profiles.sh" menu
            ;;
        *"Battery Monitor"*)
            "$HOME/.config/hypr/scripts/battery-monitor.sh" info
            ;;
        *"Power Settings"*)
            if command -v xfce4-power-manager-settings &> /dev/null; then
                xfce4-power-manager-settings
            elif command -v gnome-power-statistics &> /dev/null; then
                gnome-power-statistics
            else
                notify-send "Power" "No power settings GUI available"
            fi
            ;;
        *"System Monitor"*)
            if command -v powertop &> /dev/null; then
                warp-terminal -e sudo powertop
            else
                warp-terminal -e htop
            fi
            ;;
        *"Suspend"*)
            confirm_action "Suspend system?" && systemctl suspend
            ;;
        *"Restart"*)
            confirm_action "Restart system?" && systemctl reboot
            ;;
        *"Shutdown"*)
            confirm_action "Shutdown system?" && systemctl poweroff
            ;;
    esac
}

confirm_action() {
    local message="$1"
    local choice=$(echo -e "Yes\nNo" | rofi -dmenu -p "$message")
    [ "$choice" = "Yes" ]
}

# Quick power actions
suspend_system() {
    notify-send "Power" "Suspending system..." --icon=system-suspend
    systemctl suspend
}

restart_system() {
    if confirm_action "Restart system?"; then
        notify-send "Power" "Restarting system..." --icon=system-reboot
        systemctl reboot
    fi
}

shutdown_system() {
    if confirm_action "Shutdown system?"; then
        notify-send "Power" "Shutting down system..." --icon=system-shutdown
        systemctl poweroff
    fi
}

# Battery status
show_battery_status() {
    if [ -f "/sys/class/power_supply/BAT0/capacity" ]; then
        local battery_level=$(cat /sys/class/power_supply/BAT0/capacity)
        local battery_status=$(cat /sys/class/power_supply/BAT0/status)
        local time_remaining=""
        
        if command -v acpi &> /dev/null; then
            time_remaining=$(acpi -b | grep -o '[0-9][0-9]:[0-9][0-9]:[0-9][0-9]' | head -1)
        fi
        
        local message="Battery: ${battery_level}% (${battery_status})"
        if [ -n "$time_remaining" ]; then
            message="$message\nTime remaining: $time_remaining"
        fi
        
        notify-send "Battery Status" "$message" --icon=battery
    else
        notify-send "Power" "No battery detected - AC Power" --icon=ac-adapter
    fi
}

case "$1" in
    "menu")
        show_power_menu
        ;;
    "suspend")
        suspend_system
        ;;
    "restart")
        restart_system
        ;;
    "shutdown")
        shutdown_system
        ;;
    "battery")
        show_battery_status
        ;;
    *)
        echo "Usage: $0 {menu|suspend|restart|shutdown|battery}"
        exit 1
        ;;
esac
EOF
    then
        log_error "Failed to write power control script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make power control script executable"
        return $E_PERMISSION
    fi
    
    log_info "Power control script created successfully"
    return $E_SUCCESS
}

create_power_profiles_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/power-profiles.sh"
    
    log_info "Creating power profiles script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
#!/bin/bash
# Power Profiles Script for HyprSupreme

show_profiles_menu() {
    if ! command -v powerprofilesctl &> /dev/null; then
        notify-send "Power Profiles" "power-profiles-daemon not available"
        return 1
    fi
    
    local current_profile=$(powerprofilesctl get)
    local profiles="⚡ Performance
🔋 Balanced
🍃 Power Saver"
    
    # Mark current profile
    profiles=$(echo "$profiles" | sed "s/.*${current_profile}.*/✓ &/")
    
    local selection=$(echo "$profiles" | rofi -dmenu -p "Power Profile (Current: $current_profile)")
    
    case "$selection" in
        *"Performance"*)
            set_power_profile "performance"
            ;;
        *"Balanced"*)
            set_power_profile "balanced"
            ;;
        *"Power Saver"*)
            set_power_profile "power-saver"
            ;;
    esac
}

set_power_profile() {
    local profile="$1"
    
    if powerprofilesctl set "$profile"; then
        notify-send "Power Profile" "Set to: $profile" --icon=preferences-system-power
        
        # Apply additional optimizations based on profile
        case "$profile" in
            "performance")
                # Set CPU governor to performance if available
                if command -v cpupower &> /dev/null; then
                    sudo cpupower frequency-set -g performance 2> /dev/null || true
                fi
                ;;
            "power-saver")
                # Set CPU governor to powersave if available
                if command -v cpupower &> /dev/null; then
                    sudo cpupower frequency-set -g powersave 2> /dev/null || true
                fi
                ;;
        esac
    else
        notify-send "Power Profile" "Failed to set profile: $profile" --icon=dialog-error
    fi
}

# Get current profile info
show_profile_info() {
    if command -v powerprofilesctl &> /dev/null; then
        local current=$(powerprofilesctl get)
        local info="Current profile: $current"
        
        # Add CPU frequency info if available
        if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq" ]; then
            local freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
            freq=$((freq / 1000))
            info="$info\nCPU frequency: ${freq} MHz"
        fi
        
        notify-send "Power Profile" "$info" --icon=preferences-system-power
    else
        notify-send "Power Profile" "Power profiles not available" --icon=dialog-warning
    fi
}

case "$1" in
    "menu")
        show_profiles_menu
        ;;
    "info")
        show_profile_info
        ;;
    "performance"|"balanced"|"power-saver")
        set_power_profile "$1"
        ;;
    *)
        echo "Usage: $0 {menu|info|performance|balanced|power-saver}"
        exit 1
        ;;
esac
EOF
    then
        log_error "Failed to write power profiles script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make power profiles script executable"
        return $E_PERMISSION
    fi
    
    log_info "Power profiles script created successfully"
    return $E_SUCCESS
}

create_battery_monitor_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/battery-monitor.sh"
    
    log_info "Creating battery monitor script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
#!/bin/bash
# Battery Monitor Script for HyprSupreme

show_battery_info() {
    local info=""
    
    if [ -f "/sys/class/power_supply/BAT0/capacity" ]; then
        local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
        local status=$(cat /sys/class/power_supply/BAT0/status)
        
        info="Battery Information\n"
        info+="==================\n"
        info+="Capacity: ${capacity}%\n"
        info+="Status: ${status}\n\n"
        
        # Get detailed battery info with acpi
        if command -v acpi &> /dev/null; then
            info+="Detailed Information:\n"
            info+="$(acpi -b)\n"
            info+="$(acpi -a)\n\n"
        fi
        
        # Get power consumption info
        if [ -f "/sys/class/power_supply/BAT0/power_now" ]; then
            local power_now=$(cat /sys/class/power_supply/BAT0/power_now)
            power_now=$((power_now / 1000000))
            info+="Power consumption: ${power_now}W\n"
        fi
        
        # Get battery health if available
        if [ -f "/sys/class/power_supply/BAT0/capacity_level" ]; then
            local health=$(cat /sys/class/power_supply/BAT0/capacity_level)
            info+="Battery health: ${health}\n"
        fi
        
    else
        info="No battery detected\nSystem is running on AC power"
    fi
    
    echo -e "$info" | rofi -dmenu -p "Battery Information" -theme-str 'window {width: 50%; height: 40%;}'
}

# Monitor battery level and send notifications
monitor_battery() {
    while true; do
        if [ -f "/sys/class/power_supply/BAT0/capacity" ]; then
            local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
            local status=$(cat /sys/class/power_supply/BAT0/status)
            
            # Low battery warning
            if [ "$capacity" -le 15 ] && [ "$status" = "Discharging" ]; then
                notify-send "Low Battery" "Battery level: ${capacity}%" \
                    --icon=battery-low --urgency=critical
            fi
            
            # Critical battery warning
            if [ "$capacity" -le 5 ] && [ "$status" = "Discharging" ]; then
                notify-send "Critical Battery" "System will suspend soon!" \
                    --icon=battery-empty --urgency=critical
                sleep 60
                # Auto-suspend at critical level
                if [ "$(cat /sys/class/power_supply/BAT0/capacity)" -le 3 ]; then
                    systemctl suspend
                fi
            fi
        fi
        
        sleep 60
    done
}

case "$1" in
    "info")
        show_battery_info
        ;;
    "monitor")
        monitor_battery
        ;;
    *)
        echo "Usage: $0 {info|monitor}"
        exit 1
        ;;
esac
EOF
    then
        log_error "Failed to write battery monitor script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make battery monitor script executable"
        return $E_PERMISSION
    fi
    
    log_info "Battery monitor script created successfully"
    return $E_SUCCESS
}

configure_power_settings() {
    log_info "Configuring power settings..."
    
    # Create TLP configuration for laptops
    if [[ "${IS_LAPTOP:-false}" == "true" ]]; then
        log_info "Configuring TLP for laptop power management..."
        
        # Check sudo access
        if ! sudo -n true 2>/dev/null; then
            log_warn "Sudo access required to configure TLP"
        fi
        
        # Create TLP config directory with error handling
        if ! sudo mkdir -p /etc/tlp.d 2>/dev/null; then
            log_warn "Failed to create TLP configuration directory, attempting fallback method"
            # Try creating with regular permissions
            if ! mkdir -p "$HOME/.config/tlp" 2>/dev/null; then
                log_error "Failed to create TLP configuration directory"
                return $E_DIRECTORY
            fi
            
            # Create user-level TLP config
            local tlp_conf="$HOME/.config/tlp/tlp.conf"
            log_info "Creating user-level TLP configuration: $tlp_conf"
        } else {
            # Create system-level TLP config
            log_info "Creating system-level TLP configuration"
            
            # Check if config directory exists and is writable
            if ! sudo test -w /etc/tlp.d 2>/dev/null; then
                log_error "No write permission for TLP configuration directory: /etc/tlp.d"
                return $E_PERMISSION
            fi
            
            # Create the configuration with error handling
            if ! sudo tee /etc/tlp.d/99-hyprsupreme.conf > /dev/null << 'EOF'
# HyprSupreme TLP Configuration

# CPU scaling
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU energy/performance policies
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# CPU frequency scaling
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=30

# Platform profile
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# Disk devices
DISK_IDLE_SECS_ON_AC=0
DISK_IDLE_SECS_ON_BAT=2

# WiFi power saving
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on
EOF
            then
                log_error "Failed to write TLP configuration"
                return $E_CONFIG
            }
            
            # Restart TLP service to apply changes
            log_info "Restarting TLP service to apply changes..."
            if ! sudo systemctl restart tlp.service &>/dev/null; then
                log_warn "Failed to restart TLP service (changes will apply on next boot)"
            } else {
                log_success "TLP configuration applied"
            }
        }
    } else {
        log_info "Skipping TLP configuration (not a laptop)"
    }
    
    # Create power management autostart script
    log_info "Creating power management autostart script..."
    local scripts_dir="$HOME/.config/hypr/scripts"
    local autostart_script="$scripts_dir/power-autostart.sh"
    
    # Check if file exists and is writable
    if [[ -f "$autostart_script" && ! -w "$autostart_script" ]]; then
        log_error "Cannot write to existing file: $autostart_script"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$autostart_script" << 'EOF'
#!/bin/bash
# Power Management Autostart for HyprSupreme

# Start battery monitor if on laptop
if [ -f "/sys/class/power_supply/BAT0" ]; then
    "$HOME/.config/hypr/scripts/battery-monitor.sh" monitor &
fi

# Start power management daemon if available
if command -v xfce4-power-manager &> /dev/null; then
    xfce4-power-manager --daemon &
fi
EOF
    then
        log_error "Failed to write power autostart script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$autostart_script" 2>/dev/null; then
        log_error "Failed to make power autostart script executable"
        return $E_PERMISSION
    fi
    
    log_success "Power settings configured"
    return $E_SUCCESS
}

# Test power installation
test_power() {
    log_info "Testing power management system..."
    local errors=0
    local warnings=0
    
    # Create test log
    local test_log="/tmp/power_test_$(date +%Y%m%d-%H%M%S).log"
    
    {
        echo "==== HyprSupreme Power Management System Test ===="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "System: $(uname -a)"
        echo "System type: $(if [[ "${IS_LAPTOP:-false}" == "true" ]]; then echo "Laptop"; else echo "Desktop"; fi)"
        echo "======================================="
        echo ""
    } > "${test_log}"
    
    # Check if acpi is available with version information
    if command -v acpi &> /dev/null; then
        local acpi_version
        acpi_version=$(acpi -V 2>/dev/null | head -1 || echo "Unknown version")
        log_success "✅ ACPI tools available"
        echo "ACPI tools: ${acpi_version}" >> "${test_log}"
    else
        log_error "❌ ACPI tools not found"
        echo "ERROR: ACPI tools not found" >> "${test_log}"
        ((errors++))
    fi
    
    # Check if power profiles daemon is available with version info
    if command -v powerprofilesctl &> /dev/null; then
        local ppd_version
        ppd_version=$(powerprofilesctl --version 2>/dev/null || echo "Unknown version")
        log_success "✅ Power profiles daemon available (${ppd_version})"
        echo "Power profiles daemon: ${ppd_version}" >> "${test_log}"
        
        # Check if power profiles are working
        local current_profile
        current_profile=$(powerprofilesctl get 2>/dev/null)
        if [[ -n "${current_profile}" ]]; then
            log_success "✅ Power profiles daemon is working (current profile: ${current_profile})"
            echo "Current power profile: ${current_profile}" >> "${test_log}"
        else
            log_warn "⚠️  Power profiles daemon is installed but may not be working"
            echo "WARNING: Power profiles daemon is not returning profile information" >> "${test_log}"
            ((warnings++))
        fi
    else
        log_warn "⚠️  Power profiles daemon not available"
        echo "WARNING: Power profiles daemon not available" >> "${test_log}"
        ((warnings++))
    fi
    
    # Check ACPI service status
    if systemctl is-active --quiet acpid.service; then
        log_success "✅ ACPI daemon service is running"
        echo "ACPI daemon service: Running" >> "${test_log}"
    else
        log_warn "⚠️  ACPI daemon service is not running"
        echo "WARNING: ACPI daemon service is not running" >> "${test_log}"
        ((warnings++))
    fi
    
    # Check laptop-specific components
    if [[ "${IS_LAPTOP:-false}" == "true" ]]; then
        echo "== Laptop-specific tests ==" >> "${test_log}"
        
        # Check if TLP is available
        if command -v tlp &> /dev/null; then
            local tlp_version
            tlp_version=$(tlp-stat -s 2>/dev/null | grep "TLP" | head -1 || echo "Unknown version")
            log_success "✅ TLP laptop power management available"
            echo "TLP: ${tlp_version}" >> "${test_log}"
            
            # Check TLP service status
            if systemctl is-active --quiet tlp.service; then
                log_success "✅ TLP service is running"
                echo "TLP service: Running" >> "${test_log}"
            else
                log_warn "⚠️  TLP service is not running"
                echo "WARNING: TLP service is not running" >> "${test_log}"
                ((warnings++))
            fi
            
            # Get TLP configuration status
            if [[ -f "/etc/tlp.d/99-hyprsupreme.conf" ]]; then
                log_success "✅ TLP custom configuration exists"
                echo "TLP configuration: Custom configuration found" >> "${test_log}"
            else
                log_warn "⚠️  TLP custom configuration not found"
                echo "WARNING: TLP custom configuration not found" >> "${test_log}"
                ((warnings++))
            fi
        else
            log_warn "⚠️  TLP not available for laptop power management"
            echo "WARNING: TLP not available" >> "${test_log}"
            ((warnings++))
        fi
        
        # Check if CPU frequency scaling is available
        if command -v cpupower &> /dev/null; then
            local cpu_governor
            cpu_governor=$(cpupower frequency-info -p 2>/dev/null | grep "governor" | cut -d'"' -f2 || echo "Unknown")
            log_success "✅ CPU frequency scaling available (governor: ${cpu_governor})"
            echo "CPU frequency scaling: ${cpu_governor}" >> "${test_log}"
        else
            log_warn "⚠️  CPU frequency scaling not available"
            echo "WARNING: CPU frequency scaling not available" >> "${test_log}"
            ((warnings++))
        fi
        
        # Check battery information
        if [[ -f "/sys/class/power_supply/BAT0/capacity" ]]; then
            local battery_level
            battery_level=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "Unknown")
            local battery_status
            battery_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")
            log_success "✅ Battery information available (${battery_level}%, ${battery_status})"
            echo "Battery: ${battery_level}%, ${battery_status}" >> "${test_log}"
        else
            log_warn "⚠️  Battery information not available"
            echo "WARNING: Battery information not available" >> "${test_log}"
            ((warnings++))
        fi
    fi
    
    # Check if power GUI is available
    if command -v xfce4-power-manager &> /dev/null; then
        local xfce_version
        xfce_version=$(xfce4-power-manager --version 2>/dev/null | head -1 || echo "Unknown version")
        log_success "✅ XFCE Power Manager available (${xfce_version})"
        echo "Power GUI: XFCE Power Manager (${xfce_version})" >> "${test_log}"
    elif command -v gnome-power-manager &> /dev/null; then
        local gnome_version
        gnome_version=$(gnome-power-manager --version 2>/dev/null | head -1 || echo "Unknown version")
        log_success "✅ GNOME Power Manager available (${gnome_version})"
        echo "Power GUI: GNOME Power Manager (${gnome_version})" >> "${test_log}"
    else
        log_warn "⚠️  No power management GUI found"
        echo "WARNING: No power management GUI found" >> "${test_log}"
        ((warnings++))
    fi
    
    # Check script files
    local scripts_dir="$HOME/.config/hypr/scripts"
    local required_scripts=("power-control.sh" "power-profiles.sh" "power-autostart.sh")
    
    if [[ "${IS_LAPTOP:-false}" == "true" ]]; then
        required_scripts+=("battery-monitor.sh")
    fi
    
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
    
    # Check Hyprland integration
    if [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
        if grep -q "power-autostart.sh" "$HOME/.config/hypr/hyprland.conf"; then
            log_success "✅ Power management autostart configured in Hyprland"
            echo "Hyprland integration: Configured" >> "${test_log}"
        else
            log_warn "⚠️  Power management autostart not configured in Hyprland"
            echo "WARNING: Add 'exec-once = ~/.config/hypr/scripts/power-autostart.sh' to your hyprland.conf" >> "${test_log}"
            ((warnings++))
        fi
    }
    
    # Report summary
    if [[ $errors -gt 0 ]]; then
        log_error "Power management system test completed with $errors errors and $warnings warnings"
        echo "TEST RESULT: FAILED with $errors errors and $warnings warnings" >> "${test_log}"
        log_info "Detailed test log saved to: ${test_log}"
        return $E_POWER
    elif [[ $warnings -gt 0 ]]; then
        log_warn "Power management system test completed with $warnings warnings"
        echo "TEST RESULT: PASSED with $warnings warnings" >> "${test_log}"
        log_info "Detailed test log saved to: ${test_log}"
        return $E_SUCCESS
    else
        log_success "Power management system test completed successfully"
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
            install_power
            exit_code=$?
            ;;
        "tools")
            install_power_tools
            exit_code=$?
            ;;
        "gui")
            install_power_gui
            exit_code=$?
            ;;
        "configure")
            configure_power_integration
            exit_code=$?
            ;;
        "test")
            test_power
            exit_code=$?
            ;;
        "help")
            echo "Usage: $0 {install|tools|gui|configure|test|help}"
            echo ""
            echo "Operations:"
            echo "  install    - Install the complete power management system (default)"
            echo "  tools      - Install only power management tools"
            echo "  gui        - Install power management GUI tools"
            echo "  configure  - Configure power management integration"
            echo "  test       - Test power management installation"
            echo "  help       - Show this help message"
            exit_code=$E_SUCCESS
            ;;
        *)
            log_error "Invalid operation: $operation"
            echo "Usage: $0 {install|tools|gui|configure|test|help}"
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

# Run main function if script is executed directly
main "$@"
exit $?

