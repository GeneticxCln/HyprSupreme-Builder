#!/bin/bash
# HyprSupreme-Builder - Network Management Installation Module

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
readonly E_NETWORK=7  # Network-specific errors

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
    
    # Clean up any temporary resources if needed
    
    # Return the exit code
    return $exit_code
}

# Network-specific error handler
handle_network_error() {
    local error_type="$1"
    local error_message="$2"
    
    case "$error_type" in
        "connection")
            log_error "Network connection error: $error_message"
            return $E_NETWORK
            ;;
        "dns")
            log_error "DNS resolution error: $error_message"
            return $E_NETWORK
            ;;
        "service")
            log_error "Network service error: $error_message"
            return $E_SERVICE
            ;;
        "config")
            log_error "Network configuration error: $error_message"
            return $E_CONFIG
            ;;
        *)
            log_error "Unknown network error: $error_message"
            return $E_GENERAL
            ;;
    esac
}

# Test network connectivity
test_connectivity() {
    log_info "Testing network connectivity..."
    
    # Test internet connectivity (Google DNS)
    if ! ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        log_warn "Internet connectivity test failed"
        return 1
    fi
    
    # Test DNS resolution
    if ! nslookup google.com &> /dev/null; then
        log_warn "DNS resolution test failed"
        return 2
    fi
    
    log_success "Network connectivity tests passed"
    return 0
}

# Trap errors
trap 'handle_error $? "Script interrupted" "$BASH_SOURCE:$LINENO"' ERR
trap 'log_warn "Script received SIGINT - operation canceled"; exit $E_GENERAL' INT
trap 'log_warn "Script received SIGTERM - operation canceled"; exit $E_GENERAL' TERM

install_network() {
    log_info "Installing network management system..."
    
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
    
    # Install NetworkManager and tools
    if ! install_network_manager; then
        log_error "Failed to install NetworkManager"
        return $E_GENERAL
    fi
    
    # Install WiFi tools and drivers
    if ! install_wifi_tools; then
        log_error "Failed to install WiFi tools"
        return $E_GENERAL
    fi
    
    # Install network GUI tools
    if ! install_network_gui; then
        log_error "Failed to install network GUI tools"
        return $E_GENERAL
    fi
    
    # Configure network integration
    if ! configure_network_integration; then
        log_error "Failed to configure network integration"
        return $E_GENERAL
    fi
    
    # Test network functionality if services are running
    if systemctl is-active --quiet NetworkManager.service; then
        log_info "Testing network functionality..."
        if ! test_connectivity; then
            log_warn "Network connectivity tests failed, but installation completed"
            # Don't return error - network might not be available during installation
        else
            log_success "Network connectivity tests passed"
        fi
    fi
    
    log_success "Network management system installation completed"
    return $E_SUCCESS
}

install_network_manager() {
    log_info "Installing NetworkManager and core network tools..."
    
    local packages=(
        # Core NetworkManager
        "networkmanager"
        "networkmanager-wifi"
        "networkmanager-bluetooth"
        "networkmanager-pptp"
        "networkmanager-openvpn"
        
        # DNS and DHCP
        "dnsmasq"
        "dhcpcd"
        "systemd-resolvconf"
        
        # Network utilities
        "iw"
        "wireless_tools"
        "wpa_supplicant"
        "netctl"
        
        # Network monitoring
        "iftop"
        "nethogs"
        "nmap"
        "traceroute"
        "wget"
        "curl"
    )
    
    # Install packages with error handling
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install NetworkManager packages"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v nmcli &> /dev/null; then
        log_error "NetworkManager installation failed: nmcli command not found"
        return $E_DEPENDENCY
    fi
    
    log_info "Enabling NetworkManager service..."
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to enable NetworkManager service"
    fi
    
    # Enable NetworkManager service with error handling
    if ! sudo systemctl enable NetworkManager.service &>/dev/null; then
        log_error "Failed to enable NetworkManager service"
        return $E_SERVICE
    fi
    
    # Start NetworkManager service
    if ! sudo systemctl start NetworkManager.service &>/dev/null; then
        log_warn "Could not start NetworkManager service (may need reboot)"
        # Continue anyway as this isn't critical - service will start on next boot
    fi
    
    # Verify service is enabled
    if ! systemctl is-enabled NetworkManager.service &>/dev/null; then
        log_warn "NetworkManager service is not enabled properly"
    fi
    
    # Disable conflicting services with error handling
    log_info "Disabling conflicting network services..."
    
    if systemctl is-active --quiet dhcpcd.service; then
        if ! sudo systemctl disable dhcpcd.service &>/dev/null; then
            log_warn "Failed to disable dhcpcd service"
        fi
        
        if ! sudo systemctl stop dhcpcd.service &>/dev/null; then
            log_warn "Failed to stop dhcpcd service"
        fi
    fi
    
    log_success "NetworkManager installation completed"
    return $E_SUCCESS
}

install_wifi_tools() {
    log_info "Installing WiFi tools and drivers..."
    
    local wifi_packages=(
        # WiFi drivers and firmware
        "linux-firmware"
        "wireless-regdb"
        
        # Common WiFi drivers
        "broadcom-wl"
        "broadcom-wl-dkms"
        
        # WiFi utilities
        "iwgtk"
        "wifi-menu"
        "iwd"
    )
    
    local install_errors=0
    local installed_pkgs=0
    
    # Install WiFi packages (some may not be available)
    for pkg in "${wifi_packages[@]}"; do
        # Check if package exists in repositories
        if pacman -Si "$pkg" &> /dev/null; then
            if install_packages "$pkg"; then
                ((installed_pkgs++))
                log_info "Successfully installed: $pkg"
            else
                log_warn "Could not install $pkg"
                ((install_errors++))
            fi
        else
            log_warn "Package $pkg not available in repositories"
        fi
    done
    
    # Check for specific WiFi hardware and install drivers
    if ! detect_wifi_hardware; then
        log_warn "WiFi hardware detection had issues"
    fi
    
    # Verify we have basic WiFi utilities
    if ! command -v iw &> /dev/null; then
        log_warn "Basic WiFi utility 'iw' not found"
    fi
    
    # Check if we installed any packages
    if [[ $installed_pkgs -eq 0 ]]; then
        log_warn "No WiFi packages were installed"
        # Continue anyway as this isn't critical
    fi
    
    log_success "WiFi tools installation completed"
    return $E_SUCCESS
}

detect_wifi_hardware() {
    log_info "Detecting WiFi hardware..."
    local driver_install_errors=0
    
    # Get WiFi device info - use lspci if available, otherwise try ip link
    local wifi_devices=""
    
    if command -v lspci &> /dev/null; then
        wifi_devices=$(lspci | grep -i "network\|wifi\|wireless" || true)
    fi
    
    # If lspci didn't find anything, try ip link for wireless interfaces
    if [[ -z "$wifi_devices" ]] && command -v ip &> /dev/null; then
        wifi_devices=$(ip link | grep -i "wlan\|wireless" || true)
    fi
    
    if [[ -n "$wifi_devices" ]]; then
        log_info "Detected WiFi hardware:"
        echo "$wifi_devices" | while read -r line; do
            log_info "  $line"
        done
        
        # Install specific drivers based on detected hardware
        if echo "$wifi_devices" | grep -qi "broadcom"; then
            log_info "Broadcom WiFi detected, ensuring drivers are installed..."
            if ! install_packages "broadcom-wl"; then
                log_warn "Could not install Broadcom drivers"
                ((driver_install_errors++))
            fi
        fi
        
        if echo "$wifi_devices" | grep -qi "realtek"; then
            log_info "Realtek WiFi detected, ensuring firmware is installed..."
            # Realtek drivers usually work out of box with linux-firmware
            if ! install_packages "linux-firmware"; then
                log_warn "Could not install Realtek firmware"
                ((driver_install_errors++))
            fi
        fi
        
        if echo "$wifi_devices" | grep -qi "intel"; then
            log_info "Intel WiFi detected, ensuring firmware is installed..."
            if ! install_packages "linux-firmware"; then
                log_warn "Could not install Intel firmware"
                ((driver_install_errors++))
            fi
        fi
        
        if echo "$wifi_devices" | grep -qi "atheros"; then
            log_info "Atheros WiFi detected, ensuring firmware is installed..."
            if ! install_packages "linux-firmware"; then
                log_warn "Could not install Atheros firmware"
                ((driver_install_errors++))
            fi
        fi
        
        # Verify WiFi drivers are loaded
        if command -v lsmod &> /dev/null; then
            local wifi_modules=$(lsmod | grep -i "iwl\|rtw\|ath\|wl\|brcm" || true)
            if [[ -n "$wifi_modules" ]]; then
                log_info "WiFi kernel modules loaded:"
                echo "$wifi_modules" | while read -r line; do
                    log_info "  $line"
                done
            else
                log_warn "No WiFi kernel modules detected"
            fi
        fi
    else
        log_warn "No WiFi hardware detected or WiFi hardware info unavailable"
        return 1
    fi
    
    if [[ $driver_install_errors -gt 0 ]]; then
        log_warn "Some WiFi drivers could not be installed ($driver_install_errors errors)"
        return 1
    fi
    
    return $E_SUCCESS
}

install_network_gui() {
    log_info "Installing network GUI tools..."
    
    local gui_tools=()
    local selection=""
    
    # Check user preference for network GUI if whiptail is available
    if command -v whiptail &> /dev/null; then
        log_info "Presenting GUI tool selection dialog..."
        
        # Use a subshell to prevent script exit on dialog cancel
        selection=$(whiptail --title "Network GUI Tools" \
            --checklist "Choose network management GUI tools:" 15 70 6 \
            "nm-applet" "NetworkManager system tray applet (recommended)" ON \
            "nm-connection-editor" "NetworkManager connection editor" ON \
            "iwgtk" "Lightweight WiFi GUI" OFF \
            "connman-gtk" "ConnMan GTK frontend" OFF \
            "wicd-gtk" "Alternative network manager" OFF \
            3>&1 1>&2 2>&3 || echo "")
        
        if [[ $selection == *"nm-applet"* ]]; then
            gui_tools+=("network-manager-applet")
        fi
        
        if [[ $selection == *"nm-connection-editor"* ]]; then
            gui_tools+=("nm-connection-editor")
        fi
        
        if [[ $selection == *"iwgtk"* ]]; then
            gui_tools+=("iwgtk")
        fi
        
        if [[ $selection == *"connman-gtk"* ]]; then
            gui_tools+=("connman-gtk")
        fi
        
        if [[ $selection == *"wicd-gtk"* ]]; then
            gui_tools+=("wicd-gtk")
        fi
    else
        # Default selection if whiptail is not available
        log_warn "whiptail not found, using default selection"
        gui_tools=("network-manager-applet" "nm-connection-editor")
    fi
    
    # Install selected GUI tools
    if [ ${#gui_tools[@]} -gt 0 ]; then
        log_info "Installing selected network GUI tools: ${gui_tools[*]}"
        
        if ! install_packages "${gui_tools[@]}"; then
            log_warn "Failed to install some network GUI tools"
            # Continue anyway as these are optional
        else
            log_success "Network GUI tools installed"
        fi
    else
        log_warn "No network GUI tools selected"
    fi
    
    # Verify at least one tool is installed if any were requested
    if [ ${#gui_tools[@]} -gt 0 ] && ! command -v nm-applet &> /dev/null && ! command -v nm-connection-editor &> /dev/null; then
        log_warn "No network GUI tools were successfully installed"
    fi
    
    return $E_SUCCESS
}

configure_network_integration() {
    log_info "Configuring network integration..."
    
    # Create network scripts directory with error handling
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
    
    # Create network control script
    if ! create_network_control_script; then
        log_error "Failed to create network control script"
        return $E_CONFIG
    fi
    
    # Create WiFi manager script
    if ! create_wifi_manager_script; then
        log_error "Failed to create WiFi manager script"
        return $E_CONFIG
    fi
    
    # Create network monitoring script
    if ! create_network_monitor_script; then
        log_error "Failed to create network monitoring script"
        return $E_CONFIG
    fi
    
    # Configure NetworkManager
    if ! configure_network_manager; then
        log_error "Failed to configure NetworkManager"
        return $E_CONFIG
    fi
    
    log_success "Network integration configured"
    return $E_SUCCESS
}

create_network_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/network-control.sh"
    
    log_info "Creating network control script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
#!/bin/bash
# Network Control Script for HyprSupreme

show_network_menu() {
    local wifi_status=$(nmcli radio wifi)
    local wifi_text="Enable WiFi"
    local wifi_icon="📶"
    
    if [ "$wifi_status" = "enabled" ]; then
        wifi_text="Disable WiFi"
        wifi_icon="📵"
    fi
    
    local ethernet_status=$(nmcli device status | grep ethernet | awk '{print $3}' | head -1)
    local eth_icon="🌐"
    local eth_text="Ethernet: $ethernet_status"
    
    local menu="${wifi_icon} ${wifi_text}
${eth_icon} ${eth_text}
📋 Available WiFi Networks
⚙️ Network Settings
📊 Network Monitor
🔧 Connection Editor
📱 Mobile Hotspot"
    
    local selection=$(echo "$menu" | rofi -dmenu -p "Network Control" -theme-str 'window {width: 40%;}')
    
    case "$selection" in
        *"Enable WiFi"*)
            nmcli radio wifi on
            notify-send "Network" "WiFi enabled" --icon=network-wireless
            ;;
        *"Disable WiFi"*)
            nmcli radio wifi off
            notify-send "Network" "WiFi disabled" --icon=network-wireless-disabled
            ;;
        *"Available WiFi"*)
            show_wifi_networks
            ;;
        *"Network Settings"*)
            if command -v nm-connection-editor &> /dev/null; then
                nm-connection-editor
            else
                notify-send "Network" "Network manager not available"
            fi
            ;;
        *"Network Monitor"*)
            "$HOME/.config/hypr/scripts/network-monitor.sh"
            ;;
        *"Connection Editor"*)
            if command -v nm-connection-editor &> /dev/null; then
                nm-connection-editor
            else
                notify-send "Network" "Connection editor not available"
            fi
            ;;
        *"Mobile Hotspot"*)
            toggle_hotspot
            ;;
    esac
}

show_wifi_networks() {
    notify-send "Network" "Scanning for WiFi networks..." --icon=network-wireless
    
    # Scan for networks
    nmcli device wifi rescan 2>/dev/null
    sleep 2
    
    # Get available networks
    local networks=$(nmcli device wifi list | tail -n +2 | awk '{print $2 " (" $7 ")"}' | head -20)
    
    if [ -n "$networks" ]; then
        local selected=$(echo "$networks" | rofi -dmenu -p "Select WiFi Network" -theme-str 'window {width: 50%;}')
        
        if [ -n "$selected" ]; then
            local ssid=$(echo "$selected" | sed 's/ (.*//')
            connect_to_wifi "$ssid"
        fi
    else
        notify-send "Network" "No WiFi networks found" --icon=network-wireless-disabled
    fi
}

connect_to_wifi() {
    local ssid="$1"
    
    # Check if network requires password
    local security=$(nmcli device wifi list | grep "$ssid" | awk '{print $8}')
    
    if [[ "$security" == "--" ]]; then
        # Open network
        nmcli device wifi connect "$ssid"
        notify-send "Network" "Connected to $ssid" --icon=network-wireless
    else
        # Network requires password
        local password=$(rofi -dmenu -p "Enter password for $ssid:" -password)
        
        if [ -n "$password" ]; then
            if nmcli device wifi connect "$ssid" password "$password"; then
                notify-send "Network" "Connected to $ssid" --icon=network-wireless
            else
                notify-send "Network" "Failed to connect to $ssid" --icon=network-wireless-disabled
            fi
        fi
    fi
}

toggle_hotspot() {
    local hotspot_status=$(nmcli connection show --active | grep -i hotspot)
    
    if [ -n "$hotspot_status" ]; then
        # Disable hotspot
        nmcli connection down Hotspot 2>/dev/null || true
        notify-send "Network" "Mobile hotspot disabled" --icon=network-wireless
    else
        # Enable hotspot
        local ssid="HyprSupreme-$(whoami)"
        local password=$(rofi -dmenu -p "Enter hotspot password (min 8 chars):" -password)
        
        if [ ${#password} -ge 8 ]; then
            nmcli device wifi hotspot ifname wlan0 ssid "$ssid" password "$password"
            notify-send "Network" "Hotspot enabled: $ssid" --icon=network-wireless
        else
            notify-send "Network" "Password too short (min 8 characters)" --icon=dialog-warning
        fi
    fi
}

# Quick toggle functions
toggle_wifi() {
    local wifi_status=$(nmcli radio wifi)
    
    if [ "$wifi_status" = "enabled" ]; then
        nmcli radio wifi off
        notify-send "Network" "WiFi disabled" --icon=network-wireless-disabled
    else
        nmcli radio wifi on
        notify-send "Network" "WiFi enabled" --icon=network-wireless
    fi
}

case "$1" in
    "menu")
        show_network_menu
        ;;
    "wifi-toggle")
        toggle_wifi
        ;;
    "wifi-scan")
        show_wifi_networks
        ;;
    "hotspot")
        toggle_hotspot
        ;;
    *)
        echo "Usage: $0 {menu|wifi-toggle|wifi-scan|hotspot}"
        exit 1
        ;;
esac
EOF
    then
        log_error "Failed to write network control script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make network control script executable"
        return $E_PERMISSION
    fi
    
    log_info "Network control script created successfully"
    return $E_SUCCESS
}

create_wifi_manager_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/wifi-manager.sh"
    
    log_info "Creating WiFi manager script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
#!/bin/bash
# WiFi Manager Script for HyprSupreme

# Get current WiFi status
get_wifi_status() {
    local status=$(nmcli radio wifi)
    local connected=$(nmcli connection show --active | grep wifi | awk '{print $1}')
    
    if [ "$status" = "enabled" ]; then
        if [ -n "$connected" ]; then
            echo "Connected to: $connected"
        else
            echo "WiFi enabled, not connected"
        fi
    else
        echo "WiFi disabled"
    fi
}

# Show WiFi info notification
show_wifi_info() {
    local info=$(get_wifi_status)
    local signal_strength=""
    
    # Get signal strength if connected
    local connected_wifi=$(nmcli connection show --active | grep wifi | awk '{print $1}')
    if [ -n "$connected_wifi" ]; then
        signal_strength=$(nmcli device wifi list | grep "^\*" | awk '{print $7}')
        info="$info (Signal: $signal_strength)"
    fi
    
    notify-send "WiFi Status" "$info" --icon=network-wireless
}

# Forget WiFi network
forget_network() {
    local networks=$(nmcli connection show | grep wifi | awk '{print $1}')
    
    if [ -n "$networks" ]; then
        local selected=$(echo "$networks" | rofi -dmenu -p "Forget WiFi Network:")
        
        if [ -n "$selected" ]; then
            nmcli connection delete "$selected"
            notify-send "WiFi" "Forgot network: $selected" --icon=network-wireless
        fi
    else
        notify-send "WiFi" "No saved networks found" --icon=network-wireless-disabled
    fi
}

# Show saved networks
show_saved_networks() {
    local saved_networks=$(nmcli connection show | grep wifi | awk '{print $1}')
    
    if [ -n "$saved_networks" ]; then
        echo "$saved_networks" | rofi -dmenu -p "Saved WiFi Networks" -theme-str 'window {width: 50%;}'
    else
        notify-send "WiFi" "No saved networks found" --icon=network-wireless-disabled
    fi
}

case "$1" in
    "status")
        show_wifi_info
        ;;
    "forget")
        forget_network
        ;;
    "saved")
        show_saved_networks
        ;;
    *)
        echo "Usage: $0 {status|forget|saved}"
        exit 1
        ;;
esac
EOF
    then
        log_error "Failed to write WiFi manager script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make WiFi manager script executable"
        return $E_PERMISSION
    fi
    
    log_info "WiFi manager script created successfully"
    return $E_SUCCESS
}

create_network_monitor_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/network-monitor.sh"
    
    log_info "Creating network monitor script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
#!/bin/bash
# Network Monitor Script for HyprSupreme

show_network_info() {
    local info=""
    
    # Get active connections
    info+="=== Active Connections ===\n"
    info+="$(nmcli connection show --active | head -5)\n\n"
    
    # Get device status
    info+="=== Device Status ===\n"
    info+="$(nmcli device status)\n\n"
    
    # Get IP addresses
    info+="=== IP Addresses ===\n"
    info+="$(ip addr show | grep -E 'inet [0-9]' | awk '{print $NF ": " $2}')\n\n"
    
    # Get WiFi networks if available
    if nmcli radio wifi | grep -q enabled; then
        info+="=== Nearby WiFi Networks ===\n"
        info+="$(nmcli device wifi list | head -10)\n"
    fi
    
    echo -e "$info" | rofi -dmenu -p "Network Information" -theme-str 'window {width: 80%; height: 60%;}'
}

show_network_usage() {
    notify-send "Network Monitor" "Starting network usage monitor..." --icon=network-wired
    
    if command -v iftop &> /dev/null; then
        warp-terminal -e sudo iftop
    elif command -v nethogs &> /dev/null; then
        warp-terminal -e sudo nethogs
    else
        warp-terminal -e watch -n 1 'cat /proc/net/dev'
    fi
}

test_connectivity() {
    notify-send "Network Test" "Testing connectivity..." --icon=network-wired
    
    local results=""
    
    # Test local connectivity
    if ping -c 1 8.8.8.8 &> /dev/null; then
        results+="✅ Internet connectivity: OK\n"
    else
        results+="❌ Internet connectivity: FAILED\n"
    fi
    
    # Test DNS resolution
    if nslookup google.com &> /dev/null; then
        results+="✅ DNS resolution: OK\n"
    else
        results+="❌ DNS resolution: FAILED\n"
    fi
    
    # Test local network
    local gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    if [ -n "$gateway" ] && ping -c 1 "$gateway" &> /dev/null; then
        results+="✅ Local network: OK\n"
    else
        results+="❌ Local network: FAILED\n"
    fi
    
    notify-send "Network Test Results" "$results" --icon=network-wired
}

case "$1" in
    "info")
        show_network_info
        ;;
    "usage")
        show_network_usage
        ;;
    "test")
        test_connectivity
        ;;
    *)
        echo "Usage: $0 {info|usage|test}"
        exit 1
        ;;
esac
EOF
    then
        log_error "Failed to write network monitor script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make network monitor script executable"
        return $E_PERMISSION
    fi
    
    log_info "Network monitor script created successfully"
    return $E_SUCCESS
}

configure_network_manager() {
    log_info "Configuring NetworkManager..."
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to configure NetworkManager settings"
    fi
    
    # Create NetworkManager configuration directory with error handling
    if ! sudo mkdir -p /etc/NetworkManager/conf.d 2>/dev/null; then
        log_error "Failed to create NetworkManager configuration directory"
        return $E_DIRECTORY
    fi
    
    # Configure WiFi backend with error handling
    log_info "Configuring WiFi backend..."
    if ! sudo tee /etc/NetworkManager/conf.d/wifi-backend.conf > /dev/null << 'EOF'
[device]
wifi.backend=wpa_supplicant
EOF
    then
        log_error "Failed to write WiFi backend configuration"
        return $E_CONFIG
    fi
    
    # Configure DNS with error handling
    log_info "Configuring DNS settings..."
    if ! sudo tee /etc/NetworkManager/conf.d/dns.conf > /dev/null << 'EOF'
[main]
dns=systemd-resolved
EOF
    then
        log_error "Failed to write DNS configuration"
        return $E_CONFIG
    fi
    
    # Create network restart script
    local scripts_dir="$HOME/.config/hypr/scripts"
    local restart_script="$scripts_dir/network-restart.sh"
    
    log_info "Creating network restart script..."
    
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
# Network Restart Script for HyprSupreme

restart_network() {
    notify-send "Network" "Restarting network services..."
    
    sudo systemctl restart NetworkManager.service
    sleep 3
    
    # Re-enable WiFi if it was enabled
    nmcli radio wifi on
    
    notify-send "Network" "Network services restarted" --icon=network-wired
}

case "$1" in
    "restart")
        restart_network
        ;;
    *)
        restart_network
        ;;
esac
EOF
    then
        log_error "Failed to write network restart script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$restart_script" 2>/dev/null; then
        log_error "Failed to make network restart script executable"
        return $E_PERMISSION
    fi
    
    # Restart NetworkManager to apply configuration changes
    log_info "Restarting NetworkManager service to apply changes..."
    if ! sudo systemctl restart NetworkManager.service &>/dev/null; then
        log_warn "Failed to restart NetworkManager service"
        # Continue anyway as this isn't critical
    fi
    
    # Verify configuration files exist
    if [[ ! -f "/etc/NetworkManager/conf.d/wifi-backend.conf" ]]; then
        log_warn "WiFi backend configuration file not found"
    fi
    
    if [[ ! -f "/etc/NetworkManager/conf.d/dns.conf" ]]; then
        log_warn "DNS configuration file not found"
    fi
    
    log_success "NetworkManager configuration completed"
    return $E_SUCCESS
}

# Test network installation
test_network() {
    log_info "Testing network system..."
    local errors=0
    local warnings=0
    
    # Check if NetworkManager is available
    if command -v nmcli &> /dev/null; then
        log_success "✅ NetworkManager is available"
    else
        log_error "❌ NetworkManager not found"
        ((errors++))
    fi
    
    # Check if NetworkManager service is active
    if systemctl is-active --quiet NetworkManager.service; then
        log_success "✅ NetworkManager service is active"
        
        # Check NetworkManager daemon status
        if nmcli general status &>/dev/null; then
            log_success "✅ NetworkManager daemon is responding"
            
            # Check network connectivity if NetworkManager is running
            local nm_connectivity=$(nmcli networking connectivity 2>/dev/null || echo "unknown")
            if [[ "$nm_connectivity" == "full" ]]; then
                log_success "✅ Network connectivity: full"
            elif [[ "$nm_connectivity" == "limited" ]]; then
                log_warn "⚠️  Network connectivity: limited"
                ((warnings++))
            elif [[ "$nm_connectivity" == "none" || "$nm_connectivity" == "unknown" ]]; then
                log_warn "⚠️  Network connectivity: none/unknown"
                ((warnings++))
            fi
            
            # Check active connections
            local active_connections=$(nmcli connection show --active 2>/dev/null | grep -v "NAME" | wc -l)
            if [[ $active_connections -gt 0 ]]; then
                log_success "✅ Active network connections: $active_connections"
            else
                log_warn "⚠️  No active network connections"
                ((warnings++))
            fi
        else
            log_warn "⚠️  NetworkManager daemon is not responding properly"
            ((warnings++))
        fi
    else
        log_warn "⚠️  NetworkManager service not active (may need to be started)"
        ((warnings++))
    fi
    
    # Check WiFi capability
    if command -v nmcli &> /dev/null && nmcli radio wifi &> /dev/null; then
        local wifi_status=$(nmcli radio wifi 2>/dev/null)
        if [[ "$wifi_status" == "enabled" ]]; then
            log_success "✅ WiFi is enabled"
            
            # Check for WiFi devices
            local wifi_devices=$(nmcli device status 2>/dev/null | grep -c "wifi")
            if [[ $wifi_devices -gt 0 ]]; then
                log_success "✅ WiFi devices detected: $wifi_devices"
            else
                log_warn "⚠️  No WiFi devices detected"
                ((warnings++))
            fi
        else
            log_warn "⚠️  WiFi is disabled"
            ((warnings++))
        fi
    else
        log_warn "⚠️  WiFi capability not available or cannot be checked"
        ((warnings++))
    fi
    
    # Check network GUI tools
    local gui_found=false
    if command -v nm-applet &> /dev/null; then
        log_success "✅ NetworkManager applet available"
        gui_found=true
    fi
    
    if command -v nm-connection-editor &> /dev/null; then
        log_success "✅ NetworkManager connection editor available"
        gui_found=true
    fi
    
    if ! $gui_found; then
        log_warn "⚠️  No network GUI tools found"
        ((warnings++))
    fi
    
    # Check script files
    local scripts_dir="$HOME/.config/hypr/scripts"
    local required_scripts=("network-control.sh" "wifi-manager.sh" "network-monitor.sh" "network-restart.sh")
    
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
    
    # Check NetworkManager configuration
    if [[ -f "/etc/NetworkManager/conf.d/wifi-backend.conf" ]]; then
        log_success "✅ WiFi backend configuration exists"
    else
        log_warn "⚠️  WiFi backend configuration is missing"
        ((warnings++))
    fi
    
    if [[ -f "/etc/NetworkManager/conf.d/dns.conf" ]]; then
        log_success "✅ DNS configuration exists"
    else
        log_warn "⚠️  DNS configuration is missing"
        ((warnings++))
    fi
    
    # Run internet connectivity test if possible
    if command -v ping &> /dev/null && systemctl is-active --quiet NetworkManager.service; then
        log_info "Running connectivity tests..."
        
        # Test internet connectivity (Google DNS)
        if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
            log_success "✅ Internet connectivity test passed"
        else
            log_warn "⚠️  Internet connectivity test failed"
            ((warnings++))
        fi
        
        # Test DNS resolution if nslookup is available
        if command -v nslookup &> /dev/null; then
            if nslookup google.com &> /dev/null; then
                log_success "✅ DNS resolution test passed"
            else
                log_warn "⚠️  DNS resolution test failed"
                ((warnings++))
            fi
        fi
    fi
    
    # Report summary
    if [[ $errors -gt 0 ]]; then
        log_error "Network system test completed with $errors errors and $warnings warnings"
        return $E_GENERAL
    elif [[ $warnings -gt 0 ]]; then
        log_warn "Network system test completed with $warnings warnings"
        return $E_SUCCESS
    else
        log_success "Network system test completed successfully"
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
            install_network
            exit_code=$?
            ;;
        "manager")
            install_network_manager
            exit_code=$?
            ;;
        "wifi")
            install_wifi_tools
            exit_code=$?
            ;;
        "gui")
            install_network_gui
            exit_code=$?
            ;;
        "configure")
            configure_network_integration
            exit_code=$?
            ;;
        "test")
            test_network
            exit_code=$?
            ;;
        "connectivity")
            test_connectivity
            exit_code=$?
            ;;
        "help")
            echo "Usage: $0 {install|manager|wifi|gui|configure|test|connectivity|help}"
            echo ""
            echo "Operations:"
            echo "  install      - Install the complete network management system (default)"
            echo "  manager      - Install only NetworkManager"
            echo "  wifi         - Install WiFi tools and drivers"
            echo "  gui          - Install network GUI tools"
            echo "  configure    - Configure network integration"
            echo "  test         - Test network installation"
            echo "  connectivity - Test network connectivity"
            echo "  help         - Show this help message"
            exit_code=$E_SUCCESS
            ;;
        *)
            log_error "Invalid operation: $operation"
            echo "Usage: $0 {install|manager|wifi|gui|configure|test|connectivity|help}"
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

