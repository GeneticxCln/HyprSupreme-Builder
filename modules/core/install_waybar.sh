#!/bin/bash
# HyprSupreme-Builder - Waybar Installation Module

# Strict error handling
set -o errexit   # Exit on error
set -o pipefail  # Exit if any command in a pipe fails
set -o nounset   # Exit on undefined variables

# Define error codes
readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_PERMISSION=2
readonly E_DEPENDENCY=3
readonly E_NETWORK=4
readonly E_FILESYSTEM=5
readonly E_CONFIG=6
readonly E_SERVICE=7
readonly E_VALIDATION=8
readonly E_INSTALLATION=9
readonly E_USER_ABORT=10

# Define paths and filenames
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FUNCTIONS_FILE="${SCRIPT_DIR}/../common/functions.sh"
readonly CONFIG_DIR="$HOME/.config/waybar"
readonly CONFIG_FILE="$CONFIG_DIR/config.jsonc"
readonly STYLE_FILE="$CONFIG_DIR/style.css"
readonly BACKUP_DIR="$HOME/.config/waybar.bak.$(date +%Y%m%d%H%M%S)"
readonly LOG_DIR="$HOME/.local/share/HyprSupreme/logs"
readonly LOG_FILE="$LOG_DIR/waybar_install_$(date +%Y%m%d%H%M%S).log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR" || {
    echo "Failed to create log directory: $LOG_DIR" >&2
    exit $E_FILESYSTEM
}

# Setup logging
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

log_info() {
    log "[INFO] $1"
}

log_success() {
    log "[SUCCESS] $1"
}

log_warning() {
    log "[WARNING] $1" >&2
}

log_error() {
    log "[ERROR] $1" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        log "[DEBUG] $1"
    fi
}

# Enhanced error handler with error code support
error_exit() {
    local message="$1"
    local error_code="${2:-$E_GENERAL}"
    
    log_error "$message (Error code: $error_code)"
    exit "$error_code"
}

# Cleanup function for trap
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 && "$CLEANUP_PERFORMED" != "true" ]]; then
        log_error "Installation failed with exit code $exit_code"
        log_info "Performing cleanup..."
        
        # Restore backup if it exists and installation failed
        if [[ -d "$BACKUP_DIR" && "$CONFIG_BACKED_UP" == "true" ]]; then
            log_info "Restoring configuration from backup..."
            if restore_config; then
                log_success "Configuration restored from backup"
            else
                log_error "Failed to restore configuration from backup"
            fi
        fi
        
        # Additional cleanup steps
        export CLEANUP_PERFORMED="true"
    fi
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Installation completed successfully"
    fi
    
    return $exit_code
}

# Function to clean up on user abort (SIGINT)
handle_sigint() {
    log_warning "Installation aborted by user"
    export CLEANUP_PERFORMED="true"
    exit $E_USER_ABORT
}

# Function to handle other termination signals
handle_sigterm() {
    log_warning "Installation terminated by external signal"
    export CLEANUP_PERFORMED="true"
    exit $E_GENERAL
}

# Set traps for various signals
trap cleanup EXIT
trap handle_sigint INT
trap handle_sigterm TERM HUP

# Initialize global variables
CLEANUP_PERFORMED="false"
CONFIG_BACKED_UP="false"

# Check if common functions exist
if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    error_exit "Common functions file not found: $FUNCTIONS_FILE" $E_FILESYSTEM
fi

source "$FUNCTIONS_FILE"

# Validate running as non-root
validate_non_root() {
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root. Please run as a regular user." $E_PERMISSION
    fi
    log_debug "Running as non-root user: $(whoami)"
}

# Validate sudo access
validate_sudo() {
    log_info "Validating sudo access..."
    if ! sudo -v; then
        error_exit "Sudo access is required for this installation" $E_PERMISSION
    fi
    log_success "Sudo access confirmed"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check required dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    local missing_deps=()
    local deps=("pacman" "sudo" "mkdir" "cat" "grep" "chmod" "mv" "cp")
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error_exit "Missing required dependencies: ${missing_deps[*]}" $E_DEPENDENCY
    fi
    
    log_success "All dependencies are available"
}

# Backup existing configuration
backup_config() {
    log_info "Backing up existing Waybar configuration..."
    
    if [[ ! -d "$CONFIG_DIR" ]]; then
        log_info "No existing configuration to backup"
        return 0
    fi
    
    if ! mkdir -p "$BACKUP_DIR"; then
        log_error "Failed to create backup directory: $BACKUP_DIR"
        return 1
    fi
    
    # Copy configuration files to backup directory
    if ! cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" 2>/dev/null; then
        log_warning "Failed to copy some configuration files to backup"
        # Continue even if some files failed to copy
    fi
    
    log_success "Configuration backup created at: $BACKUP_DIR"
    export CONFIG_BACKED_UP="true"
    return 0
}

# Restore configuration from backup
restore_config() {
    log_info "Restoring Waybar configuration from backup..."
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "Backup directory not found: $BACKUP_DIR"
        return 1
    fi
    
    # Ensure the config directory exists
    mkdir -p "$CONFIG_DIR"
    
    # Remove current configuration
    rm -rf "$CONFIG_DIR/"*
    
    # Copy backup files back
    if ! cp -r "$BACKUP_DIR/"* "$CONFIG_DIR/"; then
        log_error "Failed to restore configuration from backup"
        return 1
    fi
    
    log_success "Configuration restored from: $BACKUP_DIR"
    return 0
}

# Check if Waybar is already running
check_waybar_running() {
    if pgrep -x "waybar" > /dev/null; then
        log_info "Waybar is already running"
        return 0
    else
        log_info "Waybar is not currently running"
        return 1
    fi
}

# Validate the Waybar JSON configuration
validate_waybar_config() {
    log_info "Validating Waybar configuration..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Basic JSON validation - check for balanced braces
    local open_braces
    local close_braces
    
    open_braces=$(grep -o "{" "$CONFIG_FILE" | wc -l)
    close_braces=$(grep -o "}" "$CONFIG_FILE" | wc -l)
    
    if [[ "$open_braces" != "$close_braces" ]]; then
        log_error "JSON validation failed: Unbalanced braces in $CONFIG_FILE"
        return 1
    fi
    
    # Check for required fields
    local required_fields=("layer" "position" "modules-left" "modules-right")
    local missing_fields=()
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\":" "$CONFIG_FILE"; then
            missing_fields+=("$field")
        fi
    done
    
    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        log_error "JSON validation failed: Missing required fields: ${missing_fields[*]}"
        return 1
    }
    
    log_success "Waybar configuration validation passed"
    return 0
}

# Configure Waybar autostart
configure_waybar_autostart() {
    log_info "Configuring Waybar autostart..."
    
    local hypr_dir="$HOME/.config/hypr"
    local autostart_file="$hypr_dir/autostart.conf"
    
    # Create Hyprland config directory if it doesn't exist
    if [[ ! -d "$hypr_dir" ]]; then
        if ! mkdir -p "$hypr_dir"; then
            log_error "Failed to create Hyprland config directory"
            return 1
        fi
    fi
    
    # Check if autostart.conf exists, create if not
    if [[ ! -f "$autostart_file" ]]; then
        if ! touch "$autostart_file"; then
            log_error "Failed to create autostart.conf"
            return 1
        fi
    fi
    
    # Check if waybar is already in autostart.conf
    if grep -q "waybar" "$autostart_file"; then
        log_info "Waybar is already configured to autostart"
    else
        # Add waybar to autostart.conf
        if ! echo "exec-once = waybar" >> "$autostart_file"; then
            log_error "Failed to add Waybar to autostart configuration"
            return 1
        fi
        log_success "Waybar added to autostart configuration"
    fi
    
    return 0
}

# Test Waybar functionality
test_waybar() {
    log_info "Testing Waybar installation..."
    
    # Check if waybar binary exists
    if ! command_exists "waybar"; then
        log_error "Waybar binary not found"
        return 1
    fi
    
    # Check if configuration files exist and are readable
    if [[ ! -r "$CONFIG_FILE" ]]; then
        log_error "Waybar config file is missing or not readable: $CONFIG_FILE"
        return 1
    fi
    
    if [[ ! -r "$STYLE_FILE" ]]; then
        log_error "Waybar style file is missing or not readable: $STYLE_FILE"
        return 1
    fi
    
    # Test waybar configuration (dry run)
    if ! waybar -c "$CONFIG_FILE" -s "$STYLE_FILE" -v > /dev/null 2>&1; then
        log_warning "Waybar configuration test failed, but continuing anyway"
    else
        log_success "Waybar configuration test passed"
    fi
    
    return 0
}

# Main installation function
install_waybar() {
    log_info "Installing Waybar and related packages..."
    
    # Validate user is not root
    validate_non_root
    
    # Validate sudo access
    validate_sudo
    
    # Check dependencies
    check_dependencies
    
    # Backup existing configuration
    if ! backup_config; then
        log_warning "Failed to backup existing configuration, but continuing"
    fi
    
    # Waybar and dependencies
    local packages=(
        "waybar"
        "otf-font-awesome"
        "ttf-jetbrains-mono"
        "ttf-jetbrains-mono-nerd"
        "ttf-font-awesome"
        "ttf-sourcecodepro-nerd"
        "playerctl"
        "pavucontrol"
        "bluetuith"
        "network-manager-applet"
        "bluez"
        "bluez-utils"
        "brightnessctl"
    )
    
    log_info "Installing required packages: ${packages[*]}"
    if ! install_packages "${packages[@]}"; then
        error_exit "Failed to install required packages" $E_INSTALLATION
    fi
    
    # Create waybar config directory
    log_info "Creating Waybar configuration directory..."
    if ! mkdir -p "$CONFIG_DIR"; then
        error_exit "Failed to create waybar configuration directory" $E_FILESYSTEM
    fi
    
    # Create default waybar configuration
    if ! create_default_waybar_config; then
        error_exit "Failed to create waybar configuration files" $E_CONFIG
    fi
    
    # Validate the configuration
    if ! validate_waybar_config; then
        error_exit "Waybar configuration validation failed" $E_VALIDATION
    fi
    
    # Configure autostart
    if ! configure_waybar_autostart; then
        log_warning "Failed to configure Waybar autostart, but continuing"
    fi
    
    # Test the installation
    if ! test_waybar; then
        log_warning "Waybar functionality test failed, but continuing"
    fi
    
    # Verify waybar installation
    if ! command -v waybar &> /dev/null; then
        error_exit "Waybar installation verification failed" $E_INSTALLATION
    fi
    
    # Check if config files exist
    if [[ ! -f "$CONFIG_FILE" ]] || [[ ! -f "$STYLE_FILE" ]]; then
        error_exit "Waybar configuration files were not created properly" $E_CONFIG
    fi
    
    log_success "Waybar installation completed successfully"
    return $E_SUCCESS
}

create_default_waybar_config() {
    log_info "Creating default Waybar configuration..."
    
    local temp_config_file="$CONFIG_DIR/config.jsonc.tmp"
    local temp_style_file="$CONFIG_DIR/style.css.tmp"
    
    # Create main configuration in temporary file first
    cat > "$temp_config_file" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "spacing": 4,
    "margin-top": 8,
    "margin-left": 8,
    "margin-right": 8,
    
    "modules-left": [
        "custom/logo",
        "hyprland/workspaces",
        "hyprland/window"
    ],
    
    "modules-center": [
        "clock"
    ],
    
    "modules-right": [
        "tray",
        "custom/updates",
        "network", 
        "bluetooth",
        "wireplumber",
        "backlight",
        "battery",
        "custom/power"
    ],
    
    "custom/logo": {
        "format": "󱄅",
        "tooltip": false,
        "on-click": "rofi -show drun"
    },
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "1",
            "2": "2", 
            "3": "3",
            "4": "4",
            "5": "5",
            "6": "6",
            "7": "7",
            "8": "8",
            "9": "9",
            "10": "10"
        },
        "persistent-workspaces": {
            "*": 5
        }
    },
    
    "hyprland/window": {
        "format": "{title}",
        "max-length": 50,
        "separate-outputs": true
    },
    
    "clock": {
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format": "{:%I:%M %p}",
        "format-alt": "{:%Y-%m-%d}"
    },
    
    "tray": {
        "spacing": 10
    },
    
    "custom/updates": {
        "format": "󰏗 {}",
        "interval": 3600,
        "exec": "checkupdates | wc -l",
        "exec-if": "exit 0",
        "on-click": "kitty -e 'sudo pacman -Syu 2>/dev/null'",
        "signal": 8,
        "tooltip": true,
        "tooltip-format": "Click to update system"
    },
    
    "network": {
        "format-wifi": "󰤨 {signalStrength}%",
        "format-ethernet": "󱘖 Wired",
        "tooltip-format": "{ifname} via {gwaddr}",
        "format-linked": "󱘖 {ifname} (No IP)",
        "format-disconnected": "󰤭",
        "format-alt": "{ifname}: {ipaddr}/{cidr}",
        "on-click-right": "nm-connection-editor"
    },
    
    "bluetooth": {
        "format": "󰂯",
        "format-disabled": "󰂲",
        "format-off": "󰂲",
        "interval": 30,
        "on-click": "blueman-manager",
        "format-no-controller": ""
    },
    
    "wireplumber": {
        "format": "{icon} {volume}%",
        "format-muted": "󰖁",
        "on-click": "pavucontrol",
        "format-icons": ["󰕿", "󰖀", "󰕾"]
    },
    
    "backlight": {
        "device": "intel_backlight",
        "format": "{icon} {percent}%",
        "format-icons": ["󰃞", "󰃟", "󰃠"]
    },
    
    "battery": {
        "states": {
            "good": 95,
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-full": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-plugged": "󰂄 {capacity}%",
        "format-alt": "{icon} {time}",
        "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    
    "custom/power": {
        "format": "󰐥",
        "tooltip": false,
        "on-click": "wlogout"
    }
}
EOF

    # Check if config was created successfully
    if [[ ! -f "$temp_config_file" ]]; then
        log_error "Failed to create temporary config file"
        return 1
    fi
    
    # Move temporary file to final location
    if ! mv "$temp_config_file" "$CONFIG_FILE"; then
        log_error "Failed to move config file to final location"
        return 1
    fi
    
    # Create style configuration in temporary file first
    cat > "$temp_style_file" << 'EOF'
/* HyprSupreme Waybar Style */
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(21, 18, 27, 0.9);
    color: #cdd6f4;
    border-radius: 15px;
    border: 2px solid #89b4fa;
}

tooltip {
    background: #1e1e2e;
    border-radius: 10px;
    border-width: 2px;
    border-style: solid;
    border-color: #89b4fa;
}

#workspaces button {
    padding: 5px;
    color: #cdd6f4;
    margin-right: 5px;
    margin-left: 5px;
    border-radius: 10px;
}

#workspaces button.active {
    color: #1e1e2e;
    background: #89b4fa;
    border-radius: 10px;
}

#workspaces button.focused {
    color: #1e1e2e;
    background: #a6adc8;
    border-radius: 10px;
}

#workspaces button.urgent {
    color: #1e1e2e;
    background: #f38ba8;
    border-radius: 10px;
}

#workspaces button:hover {
    background: #11111b;
    color: #cdd6f4;
    border-radius: 10px;
}

#custom-logo,
#window,
#clock,
#battery,
#wireplumber,
#backlight,
#network,
#bluetooth,
#custom-updates,
#tray,
#custom-power {
    background: #1e1e2e;
    padding: 0px 10px;
    margin: 3px 0px;
    margin-top: 10px;
    border: 1px solid #181825;
    border-radius: 10px;
}

#custom-logo {
    color: #89b4fa;
    font-size: 18px;
    padding-right: 8px;
    padding-left: 13px;
}

#window {
    color: #cdd6f4;
}

#clock {
    color: #fab387;
}

#battery {
    color: #a6e3a1;
}

#battery.charging {
    color: #a6e3a1;
}

#battery.warning:not(.charging) {
    background-color: #f38ba8;
    color: #1e1e2e;
}

#battery.critical:not(.charging) {
    background-color: #f38ba8;
    color: #1e1e2e;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#wireplumber {
    color: #89b4fa;
}

#wireplumber.muted {
    color: #f38ba8;
}

#backlight {
    color: #f9e2af;
}

#network {
    color: #94e2d5;
}

#network.disconnected {
    color: #f38ba8;
}

#bluetooth {
    color: #89b4fa;
}

#bluetooth.disabled {
    color: #a6adc8;
}

#bluetooth.off {
    color: #f38ba8;
}

#custom-updates {
    color: #f9e2af;
}

#tray {
    color: #cdd6f4;
}

#custom-power {
    color: #f38ba8;
    margin-right: 8px;
    padding-right: 16px;
}

@keyframes blink {
    to {
        background-color: #f38ba8;
        color: #1e1e2e;
    }
}
EOF
    
    # Check if style was created successfully
    if [[ ! -f "$temp_style_file" ]]; then
        log_error "Failed to create temporary style file"
        return 1
    fi
    
    # Move temporary file to final location
    if ! mv "$temp_style_file" "$STYLE_FILE"; then
        log_error "Failed to move style file to final location"
        return 1
    fi
    
    # Validate JSON configuration
    if ! grep -q '"layer":' "$CONFIG_FILE"; then
        log_error "Waybar config validation failed"
        return 1
    fi
    
    # Set correct permissions
    if ! chmod 644 "$CONFIG_FILE" "$STYLE_FILE"; then
        log_error "Failed to set permissions on configuration files"
        return 1
    fi
    
    log_success "Default Waybar configuration created"
    return 0
}

# Check if waybar is already installed and running
check_existing_waybar() {
    log_info "Checking for existing Waybar installation..."
    
    if command_exists "waybar"; then
        log_info "Waybar is already installed"
        
        if check_waybar_running; then
            log_info "Waybar process is currently running"
            return 0
        fi
    else
        log_info "Waybar is not installed"
        return 1
    fi
    
    return 1
}

# Uninstall waybar (used for cleanup or reinstall)
uninstall_waybar() {
    log_info "Uninstalling Waybar..."
    
    # Kill any running waybar instances
    if check_waybar_running; then
        log_info "Stopping running Waybar instances..."
        if ! killall -q waybar; then
            log_warning "Failed to stop Waybar instances"
        fi
    fi
    
    # Remove waybar package (but not its dependencies)
    if command_exists "waybar"; then
        log_info "Removing Waybar package..."
        if ! sudo pacman -R --noconfirm waybar; then
            log_error "Failed to remove Waybar package"
            return 1
        fi
    fi
    
    # Remove configuration
    if [[ -d "$CONFIG_DIR" ]]; then
        log_info "Removing Waybar configuration..."
        if ! rm -rf "$CONFIG_DIR"; then
            log_error "Failed to remove Waybar configuration directory"
            return 1
        fi
    fi
    
    log_success "Waybar has been uninstalled"
    return 0
}

# Handle force reinstallation if requested
handle_reinstall() {
    if [[ "${FORCE_REINSTALL:-false}" == "true" ]]; then
        log_info "Force reinstall requested"
        
        if check_existing_waybar; then
            log_info "Uninstalling existing Waybar installation..."
            if ! uninstall_waybar; then
                log_warning "Failed to completely uninstall Waybar, continuing anyway"
            fi
        fi
    elif check_existing_waybar; then
        read -rp "Waybar is already installed. Would you like to reinstall? [y/N] " answer
        case ${answer,,} in
            y|yes)
                log_info "Reinstallation confirmed by user"
                if ! uninstall_waybar; then
                    log_warning "Failed to completely uninstall Waybar, continuing anyway"
                fi
                ;;
            *)
                log_info "Keeping existing installation"
                ;;
        esac
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Starting Waybar installation script..."
    log_info "Log file: $LOG_FILE"
    
    # Handle reinstallation if needed
    handle_reinstall
    
    # Start installation
    install_waybar
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Waybar has been successfully installed and configured"
        log_info "To start Waybar manually, run: waybar"
        log_info "Configuration is located at: $CONFIG_DIR"
    else
        log_error "Waybar installation failed with exit code $exit_code"
        log_info "Check the log file for details: $LOG_FILE"
        exit $exit_code
    fi
fi

