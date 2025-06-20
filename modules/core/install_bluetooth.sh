#!/bin/bash
# HyprSupreme-Builder - Bluetooth System Installation Module

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

# Path to the script
readonly SCRIPT_PATH="$(readlink -f "$0")"
readonly SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

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
    # Kill any background scan processes
    pkill -f "bluetoothctl scan" 2>/dev/null || true
    
    # Remove any temporary files
    rm -f "/tmp/bluetooth_scan_*.log" 2>/dev/null || true
    rm -f "/tmp/bluetooth_devices_*.txt" 2>/dev/null || true
}

# Trap errors
trap 'handle_error $? "Script interrupted" "$BASH_SOURCE:$LINENO"' ERR
trap 'log_warn "Script received SIGINT - operation canceled"; exit $E_GENERAL' INT
trap 'log_warn "Script received SIGTERM - operation canceled"; exit $E_GENERAL' TERM

install_bluetooth() {
    log_info "Installing Bluetooth system..."
    
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
    
    # Install Bluetooth stack
    if ! install_bluetooth_stack; then
        log_error "Failed to install Bluetooth stack"
        return $E_GENERAL
    fi
    
    # Install Bluetooth GUI tools
    if ! install_bluetooth_gui; then
        log_error "Failed to install Bluetooth GUI tools"
        return $E_GENERAL
    fi
    
    # Configure Bluetooth integration
    if ! configure_bluetooth_integration; then
        log_error "Failed to configure Bluetooth integration"
        return $E_GENERAL
    fi
    
    log_success "Bluetooth system installation completed"
    return $E_SUCCESS
}

install_bluetooth_stack() {
    log_info "Installing Bluetooth stack..."
    
    # Check for existing Bluetooth modules
    if lsmod | grep -q "bluetooth"; then
        log_info "Bluetooth kernel modules already loaded"
    else
        log_info "Loading Bluetooth kernel modules..."
        sudo modprobe bluetooth 2>/dev/null || log_warn "Failed to load bluetooth module"
        sudo modprobe btusb 2>/dev/null || log_warn "Failed to load btusb module"
    fi
    
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
    
    # Install packages with error handling
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install Bluetooth packages"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v bluetoothctl &> /dev/null; then
        log_error "Bluetooth installation failed: bluetoothctl command not found"
        return $E_DEPENDENCY
    fi
    
    log_info "Enabling Bluetooth service..."
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to enable Bluetooth service"
    fi
    
    # Enable Bluetooth service with enhanced error handling
    if ! sudo systemctl enable bluetooth.service &>/dev/null; then
        log_error "Failed to enable Bluetooth service using systemctl"
        
        # Try alternative methods
        log_info "Attempting alternative method to enable Bluetooth service..."
        if sudo update-rc.d bluetooth defaults 2>/dev/null || sudo chkconfig bluetooth on 2>/dev/null; then
            log_success "Successfully enabled Bluetooth service using alternative method"
        else
            log_error "All methods to enable Bluetooth service failed"
            return $E_SERVICE
        fi
    fi
    
    # Start Bluetooth service with improved error handling
    if ! sudo systemctl start bluetooth.service &>/dev/null; then
        log_warn "Could not start bluetooth service (may need reboot)"
        # Try alternative approach to start the service
        log_info "Attempting alternative method to start bluetooth service..."
        if ! sudo /etc/init.d/bluetooth start 2>/dev/null && ! sudo service bluetooth start 2>/dev/null; then
            log_warn "Alternative methods also failed to start bluetooth service"
            log_info "This is not critical - service will start on next boot"
        else
            log_success "Successfully started bluetooth service using alternative method"
        fi
    fi
    
    # Restart bluetooth service to ensure proper initialization
    log_info "Restarting bluetooth service to ensure proper initialization..."
    sudo systemctl restart bluetooth.service &>/dev/null || true
    
    # Verify service is enabled
    if ! systemctl is-enabled bluetooth.service &>/dev/null; then
        log_warn "Bluetooth service is not enabled properly"
    fi
    
    log_success "Bluetooth stack installed"
    return $E_SUCCESS
}

install_bluetooth_gui() {
    log_info "Installing Bluetooth GUI tools..."
    
    local gui_tools=()
    local selection=""
    
    # Check user preference for Bluetooth GUI if whiptail is available
    if command -v whiptail &> /dev/null; then
        log_info "Presenting GUI tool selection dialog..."
        
        # Use a subshell to prevent script exit on dialog cancel
        selection=$(whiptail --title "Bluetooth GUI Tools" \
            --checklist "Choose Bluetooth GUI tools:" 15 70 5 \
            "blueman" "Full-featured Bluetooth manager (recommended)" ON \
            "blueberry" "Simple Bluetooth manager" OFF \
            "bluetooth-autoconnect" "Auto-connect utility" ON \
            3>&1 1>&2 2>&3 || echo "")
        
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
        # Default selection if whiptail is not available
        log_warn "whiptail not found, using default selection"
        gui_tools=("blueman" "bluetooth-autoconnect")
    fi
    
    # Install selected GUI tools
    if [ ${#gui_tools[@]} -gt 0 ]; then
        log_info "Installing selected Bluetooth GUI tools: ${gui_tools[*]}"
        
        if ! install_packages "${gui_tools[@]}"; then
            log_warn "Failed to install some Bluetooth GUI tools"
            # Continue anyway as these are optional
        else
            log_success "Bluetooth GUI tools installed"
        fi
    else
        log_warn "No Bluetooth GUI tools selected"
    fi
    
    # Verify at least one tool is installed if any were requested
    if [ ${#gui_tools[@]} -gt 0 ] && ! command -v blueman-manager &> /dev/null && ! command -v blueberry &> /dev/null; then
        log_warn "No Bluetooth GUI tools were successfully installed"
    fi
    
    return $E_SUCCESS
}

configure_bluetooth_integration() {
    log_info "Configuring Bluetooth integration..."
    
    # Create Bluetooth scripts directory with error handling
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
    
    # Create Bluetooth control script
    if ! create_bluetooth_control_script; then
        log_error "Failed to create Bluetooth control script"
        return $E_CONFIG
    fi
    
    # Create Bluetooth device manager
    if ! create_bluetooth_device_script; then
        log_error "Failed to create Bluetooth device manager script"
        return $E_CONFIG
    fi
    
    # Configure Bluetooth settings
    if ! configure_bluetooth_settings; then
        log_error "Failed to configure Bluetooth settings"
        return $E_CONFIG
    fi
    
    log_success "Bluetooth integration configured"
    return $E_SUCCESS
}

create_bluetooth_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/bluetooth-control.sh"
    
    log_info "Creating Bluetooth control script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
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
    then
        log_error "Failed to write Bluetooth control script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make Bluetooth control script executable"
        return $E_PERMISSION
    fi
    
    log_info "Bluetooth control script created successfully"
    return $E_SUCCESS
}

create_bluetooth_device_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/bluetooth-devices.sh"
    
    log_info "Creating Bluetooth device manager script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
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
    then
        log_error "Failed to write Bluetooth device manager script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make Bluetooth device manager script executable"
        return $E_PERMISSION
    fi
    
    log_info "Bluetooth device manager script created successfully"
    return $E_SUCCESS
}

configure_bluetooth_settings() {
    log_info "Configuring Bluetooth settings..."
    
    # Check if any Bluetooth adapters are present
    if ! lsusb | grep -qi "bluetooth" && ! lspci | grep -qi "bluetooth" && ! hciconfig -a 2>/dev/null | grep -q "hci"; then
        log_warn "No Bluetooth adapters detected on this system"
        log_info "Configuration will proceed, but Bluetooth might not work without hardware"
    fi
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to configure Bluetooth settings"
    fi
    
    # Create Bluetooth configuration directory with error handling
    if ! sudo mkdir -p /etc/bluetooth 2>/dev/null; then
        log_error "Failed to create Bluetooth configuration directory"
        return $E_DIRECTORY
    fi
    
    # Configure Bluetooth main settings
    if [[ -f "/etc/bluetooth/main.conf" ]]; then
        # Check if we can write to the file (via sudo)
        if ! sudo test -w "/etc/bluetooth/main.conf" 2>/dev/null; then
            log_error "Cannot write to Bluetooth configuration file"
            return $E_PERMISSION
        fi
        
        # Backup original config
        local backup_file="/etc/bluetooth/main.conf.backup-$(date +%Y%m%d)"
        if ! sudo cp "/etc/bluetooth/main.conf" "$backup_file" 2>/dev/null; then
            log_warn "Failed to create backup of Bluetooth configuration"
            # Continue anyway
        else
            log_info "Created backup of Bluetooth configuration: $backup_file"
        fi
        
        # Enable auto-power on
        if ! sudo sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf 2>/dev/null; then
            log_warn "Failed to set AutoEnable in Bluetooth configuration"
        fi
        
        # Enable fast connectable
        if ! sudo sed -i 's/#FastConnectable=false/FastConnectable=true/' /etc/bluetooth/main.conf 2>/dev/null; then
            log_warn "Failed to set FastConnectable in Bluetooth configuration"
        fi
        
        log_success "Bluetooth configuration updated"
    else
        log_warn "Bluetooth main configuration file not found"
    fi
    
    # Create Bluetooth restart script
    local scripts_dir="$HOME/.config/hypr/scripts"
    local restart_script="$scripts_dir/bluetooth-restart.sh"
    
    log_info "Creating Bluetooth restart script..."
    
    # Check if scripts directory exists
    if [[ ! -d "$scripts_dir" ]]; then
        if ! mkdir -p "$scripts_dir" 2>/dev/null; then
            log_error "Failed to create scripts directory: $scripts_dir"
            return $E_DIRECTORY
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$scripts_dir" ]]; then
        log_error "No write permission for scripts directory: $scripts_dir"
        return $E_PERMISSION
    fi
    
    # Create restart script with error handling
    if ! cat > "$restart_script" << 'EOF'
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
    then
        log_error "Failed to write Bluetooth restart script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$restart_script" 2>/dev/null; then
        log_error "Failed to make Bluetooth restart script executable"
        return $E_PERMISSION
    fi
    
    log_info "Bluetooth restart script created successfully"
    return $E_SUCCESS
}

# Test Bluetooth installation
test_bluetooth() {
    log_info "Testing Bluetooth system..."
    local errors=0
    local warnings=0
    
    # Create test log
    local test_log="/tmp/bluetooth_test_$(date +%Y%m%d_%H%M%S).log"
    
    {
        echo "==== HyprSupreme Bluetooth System Test ===="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "System: $(uname -a)"
        echo "======================================="
        echo ""
    } > "${test_log}"
    
    # Check if bluetoothctl is available with version information
    if command -v bluetoothctl &> /dev/null; then
        local bt_version
        bt_version=$(bluetoothctl --version 2>/dev/null || echo "Unknown version")
        log_success "✅ Bluetooth control utility available (${bt_version})"
        echo "Bluetooth control: ${bt_version}" >> "${test_log}"
    else
        log_error "❌ Bluetooth control utility not found"
        echo "ERROR: Bluetooth control utility not found" >> "${test_log}"
        ((errors++))
    fi
    
    # Check if Bluetooth service is active
    if systemctl is-active --quiet bluetooth.service; then
        log_success "✅ Bluetooth service is active"
        
    # Try to get adapter info with enhanced detection
    local adapter_info
    adapter_info=$(bluetoothctl list 2>/dev/null) || adapter_info=""
    
    if [[ -n "${adapter_info}" ]]; then
        # Count and log the detected adapters
        local adapter_count
        adapter_count=$(echo "${adapter_info}" | wc -l)
        
        log_success "✅ Bluetooth adapter(s) detected: ${adapter_count}"
        
        # Show adapter details
        echo "${adapter_info}" | while read -r line; do
            local adapter_name
            adapter_name=$(echo "${line}" | cut -d' ' -f2-)
            log_info "   Adapter: ${adapter_name}"
        done
    else
        log_warn "⚠️  No Bluetooth adapters detected"
        
        # Check for hardware issues
        if ! lsusb | grep -qi "bluetooth" && ! lspci | grep -qi "bluetooth"; then
            log_warn "   No Bluetooth hardware found on USB or PCI bus"
            log_info "   If your device has Bluetooth, check if it's disabled in BIOS/UEFI"
        elif ! rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: no"; then
            log_warn "   Bluetooth adapter is blocked by rfkill"
            log_info "   Try running: rfkill unblock bluetooth"
        fi
        
        ((warnings++))
    fi
        
        # Check if Bluetooth is powered on with enhanced detection
        local power_status
        power_status=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
        
        if [[ "${power_status}" == "yes" ]]; then
            log_success "✅ Bluetooth is powered on"
            
            # Check if discoverable and pairable
            local discoverable
            discoverable=$(bluetoothctl show | grep "Discoverable:" | awk '{print $2}')
            
            local pairable
            pairable=$(bluetoothctl show | grep "Pairable:" | awk '{print $2}')
            
            if [[ "${discoverable}" == "yes" ]]; then
                log_success "✅ Bluetooth is discoverable"
            else
                log_info "ℹ️  Bluetooth is not discoverable"
            fi
            
            if [[ "${pairable}" == "yes" ]]; then
                log_success "✅ Bluetooth is pairable"
            else
                log_info "ℹ️  Bluetooth is not pairable"
            fi
        else
            log_warn "⚠️  Bluetooth is not powered on"
            log_info "   You can power it on with: bluetoothctl power on"
            ((warnings++))
        fi
    else
        log_warn "⚠️  Bluetooth service not active (may need to be started)"
        ((warnings++))
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
        ((warnings++))
    fi
    
    # Check script files
    local scripts_dir="$HOME/.config/hypr/scripts"
    local required_scripts=("bluetooth-control.sh" "bluetooth-devices.sh" "bluetooth-restart.sh")
    
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
    
    # Check Bluetooth configuration
    if [[ -f "/etc/bluetooth/main.conf" ]]; then
        log_success "✅ Bluetooth configuration exists"
        
    # Check if auto-enable is configured with enhanced validation
    if grep -q "AutoEnable=true" /etc/bluetooth/main.conf; then
        log_success "✅ Bluetooth auto-enable is configured"
    else
        log_warn "⚠️  Bluetooth auto-enable is not configured"
        
        # Check if we can modify the file
        if sudo test -w "/etc/bluetooth/main.conf" 2>/dev/null; then
            log_info "   Auto-enable could be configured with: sudo sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf"
        fi
        
        ((warnings++))
    fi
    
    # Check for other important Bluetooth settings
    echo "Bluetooth Configuration Settings:" >> "${test_log}"
    grep -v "^#" /etc/bluetooth/main.conf | grep -v "^$" >> "${test_log}" 2>/dev/null || echo "  No active settings found" >> "${test_log}"
    else
        log_warn "⚠️  Bluetooth configuration file is missing"
        ((warnings++))
    fi
    
    # Check for paired devices
    local paired_devices
    paired_devices=$(bluetoothctl paired-devices 2>/dev/null)
    
    if [[ -n "${paired_devices}" ]]; then
        local device_count
        device_count=$(echo "${paired_devices}" | wc -l)
        log_success "✅ Found ${device_count} paired Bluetooth devices"
        echo "Paired devices (${device_count}):" >> "${test_log}"
        echo "${paired_devices}" >> "${test_log}"
    else
        log_info "ℹ️  No paired Bluetooth devices found"
        echo "No paired Bluetooth devices" >> "${test_log}"
    fi
    
    # Attempt to check system Bluetooth capabilities
    if command -v btmgmt &> /dev/null; then
        log_info "Checking Bluetooth capabilities..."
        btmgmt info &>> "${test_log}" || true
    fi
    
    # Report summary
    if [[ $errors -gt 0 ]]; then
        log_error "Bluetooth system test completed with $errors errors and $warnings warnings"
        echo "TEST RESULT: FAILED with $errors errors and $warnings warnings" >> "${test_log}"
        log_info "Detailed test log saved to: ${test_log}"
        return $E_GENERAL
    elif [[ $warnings -gt 0 ]]; then
        log_warn "Bluetooth system test completed with $warnings warnings"
        echo "TEST RESULT: PASSED with $warnings warnings" >> "${test_log}"
        log_info "Detailed test log saved to: ${test_log}"
        return $E_SUCCESS
    else
        log_success "Bluetooth system test completed successfully"
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
            install_bluetooth
            exit_code=$?
            ;;
        "stack")
            install_bluetooth_stack
            exit_code=$?
            ;;
        "gui")
            install_bluetooth_gui
            exit_code=$?
            ;;
        "configure")
            configure_bluetooth_integration
            exit_code=$?
            ;;
        "test")
            test_bluetooth
            exit_code=$?
            ;;
        "help")
            echo "Usage: $0 {install|stack|gui|configure|test|help}"
            echo ""
            echo "Operations:"
            echo "  install    - Install the complete Bluetooth system (default)"
            echo "  stack      - Install only Bluetooth stack"
            echo "  gui        - Install Bluetooth GUI tools"
            echo "  configure  - Configure Bluetooth integration"
            echo "  test       - Test Bluetooth installation"
            echo "  help       - Show this help message"
            exit_code=$E_SUCCESS
            ;;
        *)
            log_error "Invalid operation: $operation"
            echo "Usage: $0 {install|stack|gui|configure|test|help}"
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

