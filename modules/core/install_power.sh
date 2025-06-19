#!/bin/bash
# HyprSupreme-Builder - Power Management Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_power() {
    log_info "Installing power management system..."
    
    # Install power management tools
    install_power_tools
    
    # Install power GUI tools
    install_power_gui
    
    # Configure power integration
    configure_power_integration
    
    log_success "Power management system installation completed"
}

install_power_tools() {
    log_info "Installing power management tools..."
    
    local packages=(
        # Core power management
        "acpi"
        "acpi_call"
        "acpid"
        "power-profiles-daemon"
        "upower"
        
        # CPU frequency scaling
        "cpupower"
        "auto-cpufreq"
        
        # Battery management
        "tlp"
        "tlp-rdw"
        
        # System monitoring
        "powertop"
        "htop"
        "iotop"
        
        # Suspend/hibernate
        "systemd"
        "pm-utils"
    )
    
    install_packages "${packages[@]}"
    
    # Enable power services
    sudo systemctl enable acpid.service
    sudo systemctl start acpid.service || log_warn "Could not start acpid service"
    
    # Enable TLP for laptop power management
    if [ -f "/sys/class/power_supply/BAT0" ] || [ -f "/sys/class/power_supply/BAT1" ]; then
        log_info "Laptop detected, enabling TLP..."
        sudo systemctl enable tlp.service
        sudo systemctl start tlp.service || log_warn "Could not start TLP service"
    fi
    
    log_success "Power management tools installed"
}

install_power_gui() {
    log_info "Installing power management GUI tools..."
    
    local gui_tools=()
    
    # Check user preference for power GUI
    if command -v whiptail &> /dev/null; then
        local selection=$(whiptail --title "Power Management GUI" \
            --checklist "Choose power management GUI tools:" 15 70 5 \
            "xfce4-power-manager" "XFCE Power Manager (recommended)" ON \
            "gnome-power-manager" "GNOME Power Manager" OFF \
            "powertop" "Intel PowerTOP (monitoring)" ON \
            "cpu-x" "System information tool" OFF \
            3>&1 1>&2 2>&3)
        
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
        # Default selection
        gui_tools=("xfce4-power-manager" "powertop")
    fi
    
    if [ ${#gui_tools[@]} -gt 0 ]; then
        install_packages "${gui_tools[@]}"
        log_success "Power management GUI tools installed"
    fi
}

configure_power_integration() {
    log_info "Configuring power management integration..."
    
    # Create power scripts directory
    local scripts_dir="$HOME/.config/hypr/scripts"
    mkdir -p "$scripts_dir"
    
    # Create power control script
    create_power_control_script
    
    # Create power profiles script
    create_power_profiles_script
    
    # Create battery monitor script
    create_battery_monitor_script
    
    # Configure power settings
    configure_power_settings
    
    log_success "Power management integration configured"
}

create_power_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/power-control.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/power-control.sh"
}

create_power_profiles_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/power-profiles.sh" << 'EOF'
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
                    sudo cpupower frequency-set -g performance 2>/dev/null || true
                fi
                ;;
            "power-saver")
                # Set CPU governor to powersave if available
                if command -v cpupower &> /dev/null; then
                    sudo cpupower frequency-set -g powersave 2>/dev/null || true
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
    
    chmod +x "$scripts_dir/power-profiles.sh"
}

create_battery_monitor_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/battery-monitor.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/battery-monitor.sh"
}

configure_power_settings() {
    log_info "Configuring power settings..."
    
    # Create TLP configuration for laptops
    if [ -f "/sys/class/power_supply/BAT0" ] || [ -f "/sys/class/power_supply/BAT1" ]; then
        sudo mkdir -p /etc/tlp.d
        
        sudo tee /etc/tlp.d/99-hyprsupreme.conf > /dev/null << 'EOF'
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
    fi
    
    # Create power management autostart
    local scripts_dir="$HOME/.config/hypr/scripts"
    cat > "$scripts_dir/power-autostart.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/power-autostart.sh"
    
    log_success "Power settings configured"
}

# Test power installation
test_power() {
    log_info "Testing power management system..."
    
    # Check if acpi is available
    if command -v acpi &> /dev/null; then
        log_success "✅ ACPI tools available"
    else
        log_error "❌ ACPI tools not found"
        return 1
    fi
    
    # Check if power profiles daemon is available
    if command -v powerprofilesctl &> /dev/null; then
        log_success "✅ Power profiles daemon available"
    else
        log_warn "⚠️  Power profiles daemon not available"
    fi
    
    # Check if TLP is available for laptops
    if [ -f "/sys/class/power_supply/BAT0" ]; then
        if command -v tlp &> /dev/null; then
            log_success "✅ TLP laptop power management available"
        else
            log_warn "⚠️  TLP not available for laptop power management"
        fi
    fi
    
    # Check if power GUI is available
    if command -v xfce4-power-manager &> /dev/null; then
        log_success "✅ XFCE Power Manager available"
    elif command -v gnome-power-manager &> /dev/null; then
        log_success "✅ GNOME Power Manager available"
    else
        log_warn "⚠️  No power management GUI found"
    fi
    
    return 0
}

# Main execution
case "${1:-install}" in
    "install")
        install_power
        ;;
    "tools")
        install_power_tools
        ;;
    "gui")
        install_power_gui
        ;;
    "configure")
        configure_power_integration
        ;;
    "test")
        test_power
        ;;
    *)
        echo "Usage: $0 {install|tools|gui|configure|test}"
        exit 1
        ;;
esac

