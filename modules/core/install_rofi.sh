#!/bin/bash
# HyprSupreme-Builder - Rofi Installation Module
# Enhanced with comprehensive error handling and validation

# Enable strict error handling modes
set -o errexit  # Exit on error
set -o pipefail # Exit if any command in a pipe fails
set -o nounset  # Exit if undefined variable is used

# Define error codes
readonly E_SUCCESS=0            # Success
readonly E_GENERAL=1            # General error
readonly E_DEPENDENCY=2         # Missing dependency
readonly E_PERMISSION=3         # Permission denied
readonly E_NETWORK=4            # Network error
readonly E_CONFIG=5             # Configuration error
readonly E_FILESYSTEM=6         # Filesystem error
readonly E_VALIDATION=7         # Validation error
readonly E_COMPATIBILITY=8      # Compatibility error
readonly E_INSTALLATION=9       # Installation error
readonly E_RUNTIME=10           # Runtime error
readonly E_THEME=11             # Theme error
readonly E_MODULE=12            # Module error

# Define log file location
LOG_FILE="/tmp/hypr_rofi_install_$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"

# Load common functions
FUNCTIONS_FILE="$(dirname "$0")/../common/functions.sh"
if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    echo "[ERROR] Common functions file not found: $FUNCTIONS_FILE" | tee -a "$LOG_FILE" >&2
    exit $E_DEPENDENCY
fi

source "$FUNCTIONS_FILE"

# Enhanced logging functions
log_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

log_error() {
    echo "$(log_timestamp) [ERROR] $1" | tee -a "$LOG_FILE" >&2
}

log_warning() {
    echo "$(log_timestamp) [WARNING] $1" | tee -a "$LOG_FILE" >&2
}

log_info() {
    echo "$(log_timestamp) [INFO] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo "$(log_timestamp) [SUCCESS] $1" | tee -a "$LOG_FILE"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "$(log_timestamp) [DEBUG] $1" | tee -a "$LOG_FILE"
    fi
}

# Enhanced error handling
error_exit() {
    local message="$1"
    local error_code="${2:-$E_GENERAL}"
    
    log_error "$message (Error code: $error_code)"
    exit "$error_code"
}

# Trap errors
trap 'last_error=$?; log_error "Command \"${BASH_COMMAND}\" failed with exit code $last_error"; exit $last_error' ERR

# Initialize variables
ROFI_CONFIG_DIR="$HOME/.config/rofi"
BACKUP_DIR="/tmp/hypr_rofi_backup_$(date +%Y%m%d-%H%M%S)"
INSTALLED_PACKAGES=()
RESTORE_NEEDED=false

# Validate sudo access before starting
validate_sudo_access "install_rofi.sh" || error_exit "Sudo access validation failed" $E_PERMISSION

# Check if Wayland is running
check_wayland_session() {
    log_info "Checking if running in a Wayland session..."
    
    if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${WAYLAND_SOCKET:-}" ]]; then
        if ! ps -e | grep -i "wayland" > /dev/null; then
            log_warning "Wayland session not detected. Rofi-wayland is optimized for Wayland environments."
            log_warning "Installation will continue but some features may not work correctly."
            return $E_COMPATIBILITY
        fi
    fi
    
    log_success "Wayland session detected."
    return $E_SUCCESS
}

# Validate dependencies
validate_dependencies() {
    log_info "Validating system dependencies..."
    
    local missing_deps=()
    local base_deps=("sed" "grep" "awk" "wl-clipboard")
    
    for dep in "${base_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "Missing dependencies: ${missing_deps[*]}"
        log_info "Attempting to install missing dependencies..."
        install_packages "${missing_deps[@]}" || {
            log_error "Failed to install required dependencies"
            return $E_DEPENDENCY
        }
    fi
    
    log_success "All dependencies are satisfied."
    return $E_SUCCESS
}

# Backup existing configuration
backup_config() {
    log_info "Backing up existing Rofi configuration..."
    
    if [[ -d "$ROFI_CONFIG_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        
        if cp -r "$ROFI_CONFIG_DIR" "$BACKUP_DIR/"; then
            log_success "Existing Rofi configuration backed up to $BACKUP_DIR/"
            RESTORE_NEEDED=true
            return $E_SUCCESS
        else
            log_error "Failed to backup Rofi configuration"
            return $E_FILESYSTEM
        fi
    else
        log_info "No existing Rofi configuration found, skipping backup"
        return $E_SUCCESS
    fi
}

# Restore configuration from backup
restore_config() {
    if [[ "$RESTORE_NEEDED" == "true" && -d "$BACKUP_DIR/rofi" ]]; then
        log_info "Restoring Rofi configuration from backup..."
        
        # Remove the current (possibly broken) configuration
        rm -rf "$ROFI_CONFIG_DIR"
        
        # Restore from backup
        if cp -r "$BACKUP_DIR/rofi" "$(dirname "$ROFI_CONFIG_DIR")/"; then
            log_success "Rofi configuration restored from backup"
            return $E_SUCCESS
        else
            log_error "Failed to restore Rofi configuration from backup"
            return $E_FILESYSTEM
        fi
    fi
    
    return $E_SUCCESS
}

# Cleanup function
cleanup() {
    local exit_code=$?
    
    log_info "Performing cleanup..."
    
    # If the script failed and we need to restore configs
    if [[ $exit_code -ne 0 && "$RESTORE_NEEDED" == "true" ]]; then
        log_warning "Installation failed. Attempting to restore configuration..."
        restore_config
    fi
    
    # Remove backup if successful
    if [[ $exit_code -eq 0 && -d "$BACKUP_DIR" ]]; then
        log_debug "Removing backup directory: $BACKUP_DIR"
        rm -rf "$BACKUP_DIR"
    fi
    
    # Cleanup any temporary files
    if [[ -f "/tmp/rofi_test_result.txt" ]]; then
        rm -f "/tmp/rofi_test_result.txt"
    fi
    
    log_info "Cleanup completed"
    
    # Log the final status
    if [[ $exit_code -eq 0 ]]; then
        log_success "Rofi installation completed successfully!"
        echo "=============================================="
        echo "Rofi has been installed successfully!"
        echo "Log file: $LOG_FILE"
        echo "=============================================="
    else
        log_error "Rofi installation failed with exit code: $exit_code"
        echo "=============================================="
        echo "Rofi installation failed!"
        echo "Please check the log file for details: $LOG_FILE"
        echo "=============================================="
    fi
}

# Register the cleanup function
trap cleanup EXIT

# Validate configuration files
validate_config() {
    local config_file="$1"
    log_info "Validating Rofi configuration file: $config_file"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return $E_FILESYSTEM
    fi
    
    # Basic syntax check for .rasi files
    if grep -E 'element-text, element-icon , mode-switcher' "$config_file" > /dev/null; then
        if grep -E 'window {' "$config_file" > /dev/null; then
            log_success "Configuration file syntax appears valid: $config_file"
            return $E_SUCCESS
        fi
    fi
    
    log_warning "Configuration file might have syntax issues: $config_file"
    return $E_VALIDATION
}

# Test rofi functionality
test_rofi() {
    log_info "Testing Rofi installation..."
    
    # Check if rofi is installed and working
    if ! command -v rofi &> /dev/null; then
        log_error "Rofi binary not found, installation may have failed"
        return $E_INSTALLATION
    fi
    
    # Test version output
    local rofi_version
    rofi_version=$(rofi -version 2>&1)
    if [[ $? -ne 0 || -z "$rofi_version" ]]; then
        log_error "Rofi binary exists but failed to execute"
        return $E_RUNTIME
    fi
    
    log_success "Rofi version: $rofi_version"
    
    # Test configuration loading
    if [[ -f "$ROFI_CONFIG_DIR/config.rasi" ]]; then
        if ! rofi -dump-config > /tmp/rofi_test_result.txt 2>&1; then
            log_error "Failed to load Rofi configuration"
            return $E_CONFIG
        fi
        
        log_success "Rofi configuration loaded successfully"
    fi
    
    log_success "Rofi testing completed successfully"
    return $E_SUCCESS
}

# Validate theme
validate_theme() {
    local theme_file="$1"
    log_info "Validating Rofi theme: $theme_file"
    
    if [[ ! -f "$theme_file" ]]; then
        log_error "Theme file not found: $theme_file"
        return $E_FILESYSTEM
    fi
    
    # Check for required theme elements
    local required_elements=("window" "mainbox" "inputbar" "listview" "element")
    local missing_elements=()
    
    for element in "${required_elements[@]}"; do
        if ! grep -E "$element\s*{" "$theme_file" > /dev/null; then
            missing_elements+=("$element")
        fi
    done
    
    if [[ ${#missing_elements[@]} -gt 0 ]]; then
        log_warning "Theme file is missing required elements: ${missing_elements[*]}"
        log_warning "Theme may not display correctly"
        return $E_THEME
    fi
    
    # Check for color definitions
    if ! grep -E '^\s*\*\s*{' "$theme_file" > /dev/null || 
       ! grep -E 'background-color:|text-color:|border-color:' "$theme_file" > /dev/null; then
        log_warning "Theme file may be missing color definitions"
        return $E_THEME
    fi
    
    log_success "Theme file appears valid: $theme_file"
    return $E_SUCCESS
}

# Main installation function
install_rofi() {
    log_info "Starting Rofi installation process..."
    
    # Pre-installation checks
    validate_dependencies || error_exit "Dependency validation failed" $E_DEPENDENCY
    check_wayland_session
    
    # Backup existing configuration
    backup_config
    
    log_info "Installing Rofi and related packages..."
    
    # Rofi and dependencies
    local packages=(
        "rofi-wayland"
        "rofi-calc"
        "rofi-emoji"
        "wtype"
    )
    
    # Install packages and track success
    if ! install_packages "${packages[@]}"; then
        error_exit "Failed to install Rofi packages" $E_INSTALLATION
    fi
    
    # Record installed packages for potential rollback
    INSTALLED_PACKAGES=("${packages[@]}")
    
    # Create rofi config directory
    if ! mkdir -p "$ROFI_CONFIG_DIR"; then
        error_exit "Failed to create Rofi configuration directory" $E_FILESYSTEM
    fi
    
    # Create default rofi configuration
    if ! create_default_rofi_config; then
        error_exit "Failed to create default Rofi configuration" $E_CONFIG
    fi
    
    # Validate configuration files
    validate_config "$ROFI_CONFIG_DIR/config.rasi" || log_warning "Config validation warning - continuing anyway"
    validate_theme "$ROFI_CONFIG_DIR/catppuccin-mocha.rasi" || log_warning "Theme validation warning - continuing anyway"
    
    # Test the installation
    test_rofi || log_warning "Rofi test failed - installation may be incomplete"
    
    log_success "Rofi installation completed successfully"
    return $E_SUCCESS
}

create_default_rofi_config() {
    log_info "Creating default Rofi configuration..."
    
    local config_file="$ROFI_CONFIG_DIR/config.rasi"
    
    # Check if directory exists
    if [[ ! -d "$ROFI_CONFIG_DIR" ]]; then
        log_error "Rofi config directory does not exist: $ROFI_CONFIG_DIR"
        if ! mkdir -p "$ROFI_CONFIG_DIR"; then
            return $E_FILESYSTEM
        fi
    fi
    
    # Create main configuration
    log_debug "Writing configuration to: $config_file"
    if ! cat > "$config_file" << 'EOF'
/**
 * HyprSupreme Rofi Configuration
 * Based on Catppuccin theme
 */

configuration {
    modi: "drun,run,window,ssh,combi";
    font: "JetBrainsMono Nerd Font 12";
    show-icons: true;
    terminal: "kitty";
    drun-display-format: "{icon} {name}";
    location: 0;
    disable-history: false;
    hide-scrollbar: true;
    display-drun: "   Apps ";
    display-run: "   Run ";
    display-window: " 﩯  Window";
    display-Network: " 󰤨  Network";
    sidebar-mode: true;
}

@theme "catppuccin-mocha"
EOF
    then
        log_error "Failed to write main Rofi configuration"
        return $E_FILESYSTEM
    fi

    # Create catppuccin theme
    local theme_file="$ROFI_CONFIG_DIR/catppuccin-mocha.rasi"
    log_debug "Writing theme to: $theme_file"
    
    if ! cat > "$theme_file" << 'EOF'
/**
 * Catppuccin Mocha theme for Rofi
 * User: GeneticxCln
 */

* {
    bg-col:  #1e1e2e;
    bg-col-light: #1e1e2e;
    border-col: #89b4fa;
    selected-col: #1e1e2e;
    blue: #89b4fa;
    fg-col: #cdd6f4;
    fg-col2: #f38ba8;
    grey: #6c7086;

    width: 600;
    font: "JetBrainsMono Nerd Font 14";
}

element-text, element-icon , mode-switcher {
    background-color: inherit;
    text-color:       inherit;
}

window {
    height: 360px;
    border: 3px;
    border-color: @border-col;
    background-color: @bg-col;
    border-radius: 15px;
}

mainbox {
    background-color: @bg-col;
}

inputbar {
    children: [prompt,entry];
    background-color: @bg-col;
    border-radius: 5px;
    padding: 2px;
}

prompt {
    background-color: @blue;
    padding: 6px;
    text-color: @bg-col;
    border-radius: 3px;
    margin: 20px 0px 0px 20px;
}

textbox-prompt-colon {
    expand: false;
    str: ":";
}

entry {
    padding: 6px;
    margin: 20px 0px 0px 10px;
    text-color: @fg-col;
    background-color: @bg-col;
}

listview {
    border: 0px 0px 0px;
    padding: 6px 0px 0px;
    margin: 10px 0px 0px 20px;
    columns: 2;
    lines: 5;
    background-color: @bg-col;
}

element {
    padding: 5px;
    background-color: @bg-col;
    text-color: @fg-col;
}

element-icon {
    size: 25px;
}

element selected {
    background-color: @selected-col;
    text-color: @fg-col2;
    border-radius: 5px;
}

mode-switcher {
    spacing: 0;
}

button {
    padding: 10px;
    background-color: @bg-col-light;
    text-color: @grey;
    vertical-align: 0.5;
    horizontal-align: 0.5;
}

button selected {
  background-color: @bg-col;
  text-color: @blue;
}

message {
    background-color: @bg-col-light;
    margin: 2px;
    padding: 2px;
    border-radius: 5px;
}

textbox {
    padding: 6px;
    margin: 20px 0px 0px 20px;
    text-color: @blue;
    background-color: @bg-col-light;
}
EOF
    then
        log_error "Failed to write Rofi theme configuration"
        return $E_FILESYSTEM
    fi
    
    # Set appropriate permissions
    chmod 644 "$config_file" "$theme_file"
    
    log_success "Default Rofi configuration created successfully"
    return $E_SUCCESS
}

# Function to print usage information
print_usage() {
    cat << EOF
Usage: $0 [options]

Options:
  --help          Show this help message
  --test-only     Only test existing installation without installing
  --force         Force reinstallation even if already installed
  --verbose       Enable verbose logging
  --debug         Enable debug logging
  --no-backup     Skip configuration backup
  --custom-theme=PATH  Use a custom theme file at PATH

EOF
}

# Parse command-line arguments
parse_arguments() {
    local test_only=false
    local force=false
    local no_backup=false
    local custom_theme=""
    
    for arg in "$@"; do
        case $arg in
            --help)
                print_usage
                exit $E_SUCCESS
                ;;
            --test-only)
                test_only=true
                ;;
            --force)
                force=true
                ;;
            --verbose)
                export VERBOSE=true
                ;;
            --debug)
                export DEBUG=true
                ;;
            --no-backup)
                no_backup=true
                ;;
            --custom-theme=*)
                custom_theme="${arg#*=}"
                ;;
            *)
                log_warning "Unknown option: $arg"
                ;;
        esac
    done
    
    # Apply parsed arguments
    if [[ "$test_only" == "true" ]]; then
        test_rofi
        exit $?
    fi
    
    if [[ "$no_backup" == "true" ]]; then
        RESTORE_NEEDED=false
    fi
    
    if [[ -n "$custom_theme" && -f "$custom_theme" ]]; then
        log_info "Using custom theme: $custom_theme"
        if ! cp "$custom_theme" "$ROFI_CONFIG_DIR/custom-theme.rasi"; then
            log_error "Failed to copy custom theme"
        else
            # Update config to use the custom theme
            sed -i 's/@theme "catppuccin-mocha"/@theme "custom-theme"/g' "$ROFI_CONFIG_DIR/config.rasi"
        fi
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Print banner
    echo "===================================="
    echo "  HyprSupreme Rofi Installer v2.0"
    echo "===================================="
    
    # Parse command-line arguments if any
    if [[ $# -gt 0 ]]; then
        parse_arguments "$@"
    fi
    
    # Run main installation function
    install_rofi
    exit $?
fi

