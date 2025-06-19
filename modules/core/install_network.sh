#!/bin/bash
# HyprSupreme-Builder - Network Management Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_network() {
    log_info "Installing network management system..."
    
    # Install NetworkManager and tools
    install_network_manager
    
    # Install WiFi tools and drivers
    install_wifi_tools
    
    # Install network GUI tools
    install_network_gui
    
    # Configure network integration
    configure_network_integration
    
    log_success "Network management system installation completed"
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
    
    install_packages "${packages[@]}"
    
    # Enable NetworkManager service
    sudo systemctl enable NetworkManager.service
    sudo systemctl start NetworkManager.service || log_warn "Could not start NetworkManager (may need reboot)"
    
    # Disable conflicting services
    sudo systemctl disable dhcpcd.service 2>/dev/null || true
    sudo systemctl stop dhcpcd.service 2>/dev/null || true
    
    log_success "NetworkManager installation completed"
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
    
    # Install WiFi packages (some may not be available)
    for pkg in "${wifi_packages[@]}"; do
        if pacman -Si "$pkg" &> /dev/null; then
            install_packages "$pkg" || log_warn "Could not install $pkg"
        else
            log_warn "Package $pkg not available in repositories"
        fi
    done
    
    # Check for specific WiFi hardware and install drivers
    detect_wifi_hardware
    
    log_success "WiFi tools installation completed"
}

detect_wifi_hardware() {
    log_info "Detecting WiFi hardware..."
    
    # Get WiFi device info
    local wifi_devices=$(lspci | grep -i "network\|wifi\|wireless" || true)
    
    if [ -n "$wifi_devices" ]; then
        log_info "Detected WiFi hardware:"
        echo "$wifi_devices" | while read -r line; do
            log_info "  $line"
        done
        
        # Install specific drivers based on detected hardware
        if echo "$wifi_devices" | grep -qi "broadcom"; then
            log_info "Broadcom WiFi detected, ensuring drivers are installed..."
            install_packages "broadcom-wl" || log_warn "Could not install Broadcom drivers"
        fi
        
        if echo "$wifi_devices" | grep -qi "realtek"; then
            log_info "Realtek WiFi detected..."
            # Realtek drivers usually work out of box with linux-firmware
        fi
        
        if echo "$wifi_devices" | grep -qi "intel"; then
            log_info "Intel WiFi detected, ensuring firmware is installed..."
            install_packages "linux-firmware" || log_warn "Could not install Intel firmware"
        fi
    else
        log_warn "No WiFi hardware detected or WiFi hardware info unavailable"
    fi
}

install_network_gui() {
    log_info "Installing network GUI tools..."
    
    local gui_tools=()
    
    # Check user preference for network GUI
    if command -v whiptail &> /dev/null; then
        local selection=$(whiptail --title "Network GUI Tools" \
            --checklist "Choose network management GUI tools:" 15 70 6 \
            "nm-applet" "NetworkManager system tray applet (recommended)" ON \
            "nm-connection-editor" "NetworkManager connection editor" ON \
            "iwgtk" "Lightweight WiFi GUI" OFF \
            "connman-gtk" "ConnMan GTK frontend" OFF \
            "wicd-gtk" "Alternative network manager" OFF \
            3>&1 1>&2 2>&3)
        
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
        # Default selection
        gui_tools=("network-manager-applet" "nm-connection-editor")
    fi
    
    if [ ${#gui_tools[@]} -gt 0 ]; then
        install_packages "${gui_tools[@]}"
        log_success "Network GUI tools installed"
    fi
}

configure_network_integration() {
    log_info "Configuring network integration..."
    
    # Create network scripts directory
    local scripts_dir="$HOME/.config/hypr/scripts"
    mkdir -p "$scripts_dir"
    
    # Create network control script
    create_network_control_script
    
    # Create WiFi manager script
    create_wifi_manager_script
    
    # Create network monitoring script
    create_network_monitor_script
    
    # Configure NetworkManager
    configure_network_manager
    
    log_success "Network integration configured"
}

create_network_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/network-control.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/network-control.sh"
}

create_wifi_manager_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/wifi-manager.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/wifi-manager.sh"
}

create_network_monitor_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/network-monitor.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/network-monitor.sh"
}

configure_network_manager() {
    log_info "Configuring NetworkManager..."
    
    # Create NetworkManager configuration
    sudo mkdir -p /etc/NetworkManager/conf.d
    
    # Configure WiFi backend
    sudo tee /etc/NetworkManager/conf.d/wifi-backend.conf > /dev/null << 'EOF'
[device]
wifi.backend=wpa_supplicant
EOF
    
    # Configure DNS
    sudo tee /etc/NetworkManager/conf.d/dns.conf > /dev/null << 'EOF'
[main]
dns=systemd-resolved
EOF
    
    # Create network restart script
    local scripts_dir="$HOME/.config/hypr/scripts"
    cat > "$scripts_dir/network-restart.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/network-restart.sh"
    
    log_success "NetworkManager configuration completed"
}

# Test network installation
test_network() {
    log_info "Testing network system..."
    
    # Check if NetworkManager is available
    if command -v nmcli &> /dev/null; then
        log_success "✅ NetworkManager is available"
    else
        log_error "❌ NetworkManager not found"
        return 1
    fi
    
    # Check if NetworkManager service is active
    if systemctl is-active --quiet NetworkManager.service; then
        log_success "✅ NetworkManager service is active"
    else
        log_warn "⚠️  NetworkManager service not active (may need to be started)"
    fi
    
    # Check WiFi capability
    if nmcli radio wifi &> /dev/null; then
        log_success "✅ WiFi capability available"
    else
        log_warn "⚠️  WiFi capability not available"
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
    fi
    
    return 0
}

# Main execution
case "${1:-install}" in
    "install")
        install_network
        ;;
    "manager")
        install_network_manager
        ;;
    "wifi")
        install_wifi_tools
        ;;
    "gui")
        install_network_gui
        ;;
    "configure")
        configure_network_integration
        ;;
    "test")
        test_network
        ;;
    *)
        echo "Usage: $0 {install|manager|wifi|gui|configure|test}"
        exit 1
        ;;
esac

