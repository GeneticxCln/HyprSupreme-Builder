#!/bin/bash
# HyprSupreme-Builder - Bluetooth System Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_bluetooth() {
    log_info "Installing Bluetooth system..."
    
    # Install Bluetooth stack
    install_bluetooth_stack
    
    # Install Bluetooth GUI tools
    install_bluetooth_gui
    
    # Configure Bluetooth integration
    configure_bluetooth_integration
    
    log_success "Bluetooth system installation completed"
}

install_bluetooth_stack() {
    log_info "Installing Bluetooth stack..."
    
    local packages=(
        # Core Bluetooth
        "bluez"
        "bluez-utils"
        "bluez-plugins"
        
        # Audio support
        "pipewire-pulse"
        "libldac"
        "sbc"
        
        # Additional protocols
        "bluez-cups"
        "bluez-hid2hci"
    )
    
    install_packages "${packages[@]}"
    
    # Enable Bluetooth service
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service || log_warn "Could not start bluetooth service (may need reboot)"
    
    log_success "Bluetooth stack installed"
}

install_bluetooth_gui() {
    log_info "Installing Bluetooth GUI tools..."
    
    local gui_tools=()
    
    # Check user preference for Bluetooth GUI
    if command -v whiptail &> /dev/null; then
        local selection=$(whiptail --title "Bluetooth GUI Tools" \
            --checklist "Choose Bluetooth GUI tools:" 15 70 5 \
            "blueman" "Full-featured Bluetooth manager (recommended)" ON \
            "blueberry" "Simple Bluetooth manager" OFF \
            "bluetooth-autoconnect" "Auto-connect utility" ON \
            3>&1 1>&2 2>&3)
        
        if [[ $selection == *"blueman"* ]]; then
            gui_tools+=("blueman")
        fi
        
        if [[ $selection == *"blueberry"* ]]; then
            gui_tools+=("blueberry")
        fi
        
        if [[ $selection == *"bluetooth-autoconnect"* ]]; then
            gui_tools+=("bluetooth-autoconnect")
        fi
    else
        # Default selection
        gui_tools=("blueman" "bluetooth-autoconnect")
    fi
    
    if [ ${#gui_tools[@]} -gt 0 ]; then
        install_packages "${gui_tools[@]}"
        log_success "Bluetooth GUI tools installed"
    fi
}

configure_bluetooth_integration() {
    log_info "Configuring Bluetooth integration..."
    
    # Create Bluetooth scripts directory
    local scripts_dir="$HOME/.config/hypr/scripts"
    mkdir -p "$scripts_dir"
    
    # Create Bluetooth control script
    create_bluetooth_control_script
    
    # Create Bluetooth device manager
    create_bluetooth_device_script
    
    # Configure Bluetooth settings
    configure_bluetooth_settings
    
    log_success "Bluetooth integration configured"
}

create_bluetooth_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/bluetooth-control.sh" << 'EOF'
#!/bin/bash
# Bluetooth Control Script for HyprSupreme

show_bluetooth_menu() {
    local bluetooth_status=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
    local power_text="Turn On"
    local power_icon="🔴"
    
    if [ "$bluetooth_status" = "yes" ]; then
        power_text="Turn Off"
        power_icon="🔵"
    fi
    
    local menu="${power_icon} ${power_text} Bluetooth
📱 Bluetooth Manager
🔍 Scan for Devices
📋 Connected Devices
⚙️ Bluetooth Settings"
    
    local selection=$(echo "$menu" | rofi -dmenu -p "Bluetooth Control" -theme-str 'window {width: 40%;}')
    
    case "$selection" in
        *"Turn On"*)
            bluetoothctl power on
            notify-send "Bluetooth" "Bluetooth enabled" --icon=bluetooth-active
            ;;
        *"Turn Off"*)
            bluetoothctl power off
            notify-send "Bluetooth" "Bluetooth disabled" --icon=bluetooth-disabled
            ;;
        *"Bluetooth Manager"*)
            if command -v blueman-manager &> /dev/null; then
                blueman-manager
            elif command -v blueberry &> /dev/null; then
                blueberry
            else
                notify-send "Bluetooth" "No Bluetooth manager installed"
            fi
            ;;
        *"Scan for Devices"*)
            scan_bluetooth_devices
            ;;
        *"Connected Devices"*)
            show_connected_devices
            ;;
        *"Bluetooth Settings"*)
            if command -v blueman-manager &> /dev/null; then
                blueman-manager
            else
                notify-send "Bluetooth" "Install blueman for advanced settings"
            fi
            ;;
    esac
}

scan_bluetooth_devices() {
    notify-send "Bluetooth" "Scanning for devices..." --icon=bluetooth-active
    
    bluetoothctl scan on &
    local scan_pid=$!
    
    sleep 10
    kill $scan_pid 2>/dev/null
    bluetoothctl scan off
    
    # Show discovered devices
    local devices=$(bluetoothctl devices | cut -d' ' -f2-)
    if [ -n "$devices" ]; then
        echo "$devices" | rofi -dmenu -p "Discovered Devices" -theme-str 'window {width: 50%;}'
    else
        notify-send "Bluetooth" "No devices found" --icon=bluetooth-disabled
    fi
}

show_connected_devices() {
    local connected_devices=""
    
    # Get connected devices
    while read -r mac name; do
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            connected_devices+="$name ($mac)\n"
        fi
    done < <(bluetoothctl devices | sed 's/Device //' | cut -d' ' -f1,2-)
    
    if [ -n "$connected_devices" ]; then
        echo -e "$connected_devices" | rofi -dmenu -p "Connected Devices" -theme-str 'window {width: 50%;}'
    else
        notify-send "Bluetooth" "No devices connected" --icon=bluetooth-disabled
    fi
}

# Quick toggle function
toggle_bluetooth() {
    local bluetooth_status=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
    
    if [ "$bluetooth_status" = "yes" ]; then
        bluetoothctl power off
        notify-send "Bluetooth" "Bluetooth disabled" --icon=bluetooth-disabled
    else
        bluetoothctl power on
        notify-send "Bluetooth" "Bluetooth enabled" --icon=bluetooth-active
    fi
}

case "$1" in
    "menu")
        show_bluetooth_menu
        ;;
    "toggle")
        toggle_bluetooth
        ;;
    "on")
        bluetoothctl power on
        notify-send "Bluetooth" "Bluetooth enabled" --icon=bluetooth-active
        ;;
    "off")
        bluetoothctl power off
        notify-send "Bluetooth" "Bluetooth disabled" --icon=bluetooth-disabled
        ;;
    "scan")
        scan_bluetooth_devices
        ;;
    *)
        echo "Usage: $0 {menu|toggle|on|off|scan}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/bluetooth-control.sh"
}

create_bluetooth_device_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/bluetooth-devices.sh" << 'EOF'
#!/bin/bash
# Bluetooth Device Manager for HyprSupreme

# Pair and connect to a device
pair_device() {
    local mac_address="$1"
    
    if [ -z "$mac_address" ]; then
        notify-send "Bluetooth" "No device MAC address provided"
        return 1
    fi
    
    notify-send "Bluetooth" "Pairing with device..." --icon=bluetooth-active
    
    # Trust, pair, and connect
    bluetoothctl trust "$mac_address"
    bluetoothctl pair "$mac_address"
    bluetoothctl connect "$mac_address"
    
    # Check if successful
    if bluetoothctl info "$mac_address" | grep -q "Connected: yes"; then
        local device_name=$(bluetoothctl info "$mac_address" | grep "Name:" | cut -d' ' -f2-)
        notify-send "Bluetooth" "Connected to $device_name" --icon=bluetooth-active
    else
        notify-send "Bluetooth" "Failed to connect to device" --icon=bluetooth-disabled
    fi
}

# Disconnect device
disconnect_device() {
    local mac_address="$1"
    
    if [ -z "$mac_address" ]; then
        notify-send "Bluetooth" "No device MAC address provided"
        return 1
    fi
    
    bluetoothctl disconnect "$mac_address"
    local device_name=$(bluetoothctl info "$mac_address" | grep "Name:" | cut -d' ' -f2-)
    notify-send "Bluetooth" "Disconnected from $device_name" --icon=bluetooth-disabled
}

# Remove/forget device
forget_device() {
    local mac_address="$1"
    
    if [ -z "$mac_address" ]; then
        notify-send "Bluetooth" "No device MAC address provided"
        return 1
    fi
    
    local device_name=$(bluetoothctl info "$mac_address" | grep "Name:" | cut -d' ' -f2-)
    bluetoothctl remove "$mac_address"
    notify-send "Bluetooth" "Removed $device_name" --icon=bluetooth-disabled
}

case "$1" in
    "pair")
        pair_device "$2"
        ;;
    "disconnect")
        disconnect_device "$2"
        ;;
    "forget")
        forget_device "$2"
        ;;
    *)
        echo "Usage: $0 {pair|disconnect|forget} <MAC_ADDRESS>"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/bluetooth-devices.sh"
}

configure_bluetooth_settings() {
    log_info "Configuring Bluetooth settings..."
    
    # Create Bluetooth configuration
    sudo mkdir -p /etc/bluetooth
    
    # Configure Bluetooth main settings
    if [ -f "/etc/bluetooth/main.conf" ]; then
        # Backup original config
        sudo cp /etc/bluetooth/main.conf /etc/bluetooth/main.conf.backup-$(date +%Y%m%d)
        
        # Enable auto-power on
        sudo sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf
        
        # Enable fast connectable
        sudo sed -i 's/#FastConnectable=false/FastConnectable=true/' /etc/bluetooth/main.conf
        
        log_success "Bluetooth configuration updated"
    fi
    
    # Create Bluetooth restart script
    local scripts_dir="$HOME/.config/hypr/scripts"
    cat > "$scripts_dir/bluetooth-restart.sh" << 'EOF'
#!/bin/bash
# Bluetooth Restart Script for HyprSupreme

restart_bluetooth() {
    notify-send "Bluetooth" "Restarting Bluetooth service..."
    
    sudo systemctl restart bluetooth.service
    sleep 2
    
    # Re-enable if it was enabled
    bluetoothctl power on
    
    notify-send "Bluetooth" "Bluetooth service restarted" --icon=bluetooth-active
}

case "$1" in
    "restart")
        restart_bluetooth
        ;;
    *)
        restart_bluetooth
        ;;
esac
EOF
    
    chmod +x "$scripts_dir/bluetooth-restart.sh"
}

# Test Bluetooth installation
test_bluetooth() {
    log_info "Testing Bluetooth system..."
    
    # Check if bluetoothctl is available
    if command -v bluetoothctl &> /dev/null; then
        log_success "✅ Bluetooth control utility available"
    else
        log_error "❌ Bluetooth control utility not found"
        return 1
    fi
    
    # Check if Bluetooth service is active
    if systemctl is-active --quiet bluetooth.service; then
        log_success "✅ Bluetooth service is active"
    else
        log_warn "⚠️  Bluetooth service not active (may need to be started)"
    fi
    
    # Check if Bluetooth GUI is available
    local gui_found=false
    if command -v blueman-manager &> /dev/null; then
        log_success "✅ Blueman Bluetooth manager available"
        gui_found=true
    fi
    
    if command -v blueberry &> /dev/null; then
        log_success "✅ Blueberry Bluetooth manager available"
        gui_found=true
    fi
    
    if ! $gui_found; then
        log_warn "⚠️  No Bluetooth GUI manager found"
    fi
    
    return 0
}

# Main execution
case "${1:-install}" in
    "install")
        install_bluetooth
        ;;
    "stack")
        install_bluetooth_stack
        ;;
    "gui")
        install_bluetooth_gui
        ;;
    "configure")
        configure_bluetooth_integration
        ;;
    "test")
        test_bluetooth
        ;;
    *)
        echo "Usage: $0 {install|stack|gui|configure|test}"
        exit 1
        ;;
esac

