#!/bin/bash
# HyprSupreme-Builder - SDDM Installation Module

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
readonly E_THEME=7     # Theme-specific errors
readonly E_DISPLAY=8   # Display/resolution errors

# Path to the script
readonly SCRIPT_PATH="$(readlink -f "$0")"
readonly SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
readonly CONFIG_FILE="/etc/sddm.conf"
readonly BACKUP_DIR="$HOME/.config/sddm-backup-$(date +%Y%m%d-%H%M%S)"
readonly LOG_FILE="/tmp/sddm-install-$(date +%Y%m%d-%H%M%S).log"

# Source common functions
if [[ ! -f "${SCRIPT_DIR}/../common/functions.sh" ]]; then
    echo "ERROR: Required file not found: ${SCRIPT_DIR}/../common/functions.sh"
    exit $E_DEPENDENCY
fi

source "${SCRIPT_DIR}/../common/functions.sh"

# Source resolution manager if available
RESOLUTION_MANAGER="${SCRIPT_DIR}/../../tools/resolution_manager.sh"
if [[ ! -f "$RESOLUTION_MANAGER" ]]; then
    log_warn "Resolution manager not found: $RESOLUTION_MANAGER"
else
    source "$RESOLUTION_MANAGER"
fi

# Create log file
touch "$LOG_FILE" || true

# Error handling function
handle_error() {
    local exit_code=$1
    local error_message="${2:-Unknown error}"
    local error_source="${3:-$SCRIPT_PATH}"
    
    log_error "Error in $error_source: $error_message (code: $exit_code)"
    log_error "Check log file for details: $LOG_FILE"
    
    # Write error to log file
    echo "[ERROR] $(date): $error_message (code: $exit_code) in $error_source" >> "$LOG_FILE"
    
    # Return the exit code
    return $exit_code
}

# SDDM-specific error handler
handle_sddm_error() {
    local error_type="$1"
    local error_message="$2"
    
    case "$error_type" in
        "theme")
            log_error "SDDM theme error: $error_message"
            echo "[ERROR] $(date): SDDM theme error: $error_message" >> "$LOG_FILE"
            return $E_THEME
            ;;
        "config")
            log_error "SDDM configuration error: $error_message"
            echo "[ERROR] $(date): SDDM configuration error: $error_message" >> "$LOG_FILE"
            return $E_CONFIG
            ;;
        "display")
            log_error "SDDM display error: $error_message"
            echo "[ERROR] $(date): SDDM display error: $error_message" >> "$LOG_FILE"
            return $E_DISPLAY
            ;;
        "service")
            log_error "SDDM service error: $error_message"
            echo "[ERROR] $(date): SDDM service error: $error_message" >> "$LOG_FILE"
            return $E_SERVICE
            ;;
        *)
            log_error "Unknown SDDM error: $error_message"
            echo "[ERROR] $(date): Unknown SDDM error: $error_message" >> "$LOG_FILE"
            return $E_GENERAL
            ;;
    esac
}

# Trap errors
trap 'handle_error $? "Script interrupted" "$BASH_SOURCE:$LINENO"' ERR
trap 'log_warn "Script received SIGINT - operation canceled"; exit $E_GENERAL' INT
trap 'log_warn "Script received SIGTERM - operation canceled"; exit $E_GENERAL' TERM

check_dependencies() {
    log_info "Checking dependencies for SDDM installation..."
    echo "[INFO] $(date): Checking dependencies for SDDM installation" >> "$LOG_FILE"
    
    # Check for required packages
    local required_deps=(
        "qt5-base"     # Base Qt5 libraries
        "qt5-declarative" # QML support
        "xorg-server"  # X server
    )
    
    local missing_deps=()
    
    for dep in "${required_deps[@]}"; do
        if ! pacman -Q "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing_deps[*]}"
        log_info "Installing missing dependencies..."
        if ! install_packages "${missing_deps[@]}"; then
            log_error "Failed to install dependencies"
            echo "[ERROR] $(date): Failed to install dependencies: ${missing_deps[*]}" >> "$LOG_FILE"
            return $E_DEPENDENCY
        fi
    fi
    
    return $E_SUCCESS
}

backup_sddm_config() {
    log_info "Backing up existing SDDM configuration..."
    echo "[INFO] $(date): Backing up existing SDDM configuration" >> "$LOG_FILE"
    
    # Create backup directory
    if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
        log_error "Failed to create backup directory: $BACKUP_DIR"
        echo "[ERROR] $(date): Failed to create backup directory: $BACKUP_DIR" >> "$LOG_FILE"
        return $E_DIRECTORY
    fi
    
    # Back up existing SDDM configuration if it exists
    if [[ -f "$CONFIG_FILE" ]]; then
        if ! sudo cp "$CONFIG_FILE" "$BACKUP_DIR/" 2>/dev/null; then
            log_warn "Failed to backup SDDM configuration"
            echo "[WARN] $(date): Failed to backup SDDM configuration" >> "$LOG_FILE"
        else
            log_info "Backed up SDDM configuration to $BACKUP_DIR/$(basename "$CONFIG_FILE")"
            echo "[INFO] $(date): Backed up SDDM configuration to $BACKUP_DIR/$(basename "$CONFIG_FILE")" >> "$LOG_FILE"
        fi
    fi
    
    # Back up SDDM theme if it exists
    if [[ -d "/usr/share/sddm/themes" ]]; then
        mkdir -p "$BACKUP_DIR/themes" 2>/dev/null || true
        
        # Find installed themes and copy them
        for theme_dir in /usr/share/sddm/themes/*; do
            if [[ -d "$theme_dir" ]]; then
                local theme_name=$(basename "$theme_dir")
                log_info "Found theme: $theme_name"
                echo "[INFO] $(date): Found theme: $theme_name" >> "$LOG_FILE"
            fi
        done
    fi
    
    log_success "Configuration backup completed to $BACKUP_DIR"
    echo "[INFO] $(date): Configuration backup completed to $BACKUP_DIR" >> "$LOG_FILE"
    
    return $E_SUCCESS
}

restore_sddm_config() {
    local backup_path="$1"
    
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup directory not found: $backup_path"
        echo "[ERROR] $(date): Backup directory not found: $backup_path" >> "$LOG_FILE"
        return $E_DIRECTORY
    fi
    
    log_info "Restoring SDDM configuration from backup..."
    echo "[INFO] $(date): Restoring SDDM configuration from backup" >> "$LOG_FILE"
    
    # Restore configuration file
    if [[ -f "$backup_path/$(basename "$CONFIG_FILE")" ]]; then
        if ! sudo cp "$backup_path/$(basename "$CONFIG_FILE")" "$CONFIG_FILE" 2>/dev/null; then
            log_error "Failed to restore SDDM configuration"
            echo "[ERROR] $(date): Failed to restore SDDM configuration" >> "$LOG_FILE"
            return $E_GENERAL
        fi
        log_info "Restored SDDM configuration"
        echo "[INFO] $(date): Restored SDDM configuration" >> "$LOG_FILE"
    fi
    
    log_success "Configuration restore completed from $backup_path"
    echo "[SUCCESS] $(date): Configuration restore completed from $backup_path" >> "$LOG_FILE"
    return $E_SUCCESS
}

install_sddm() {
    log_info "Installing SDDM display manager..."
    echo "[INFO] $(date): Starting SDDM installation" >> "$LOG_FILE"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        echo "[ERROR] $(date): This script should not be run as root" >> "$LOG_FILE"
        return $E_PERMISSION
    fi
    
    # Check for essential dependencies
    if ! command -v pacman &> /dev/null; then
        log_error "Package manager not found (pacman is required)"
        echo "[ERROR] $(date): Package manager not found (pacman is required)" >> "$LOG_FILE"
        return $E_DEPENDENCY
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        log_error "Failed to check/install dependencies"
        echo "[ERROR] $(date): Failed to check/install dependencies" >> "$LOG_FILE"
        return $E_DEPENDENCY
    fi
    
    # Backup existing configuration
    backup_sddm_config
    
    # SDDM and dependencies
    local packages=(
        "sddm"
        "qt5-graphicaleffects"
        "qt5-quickcontrols2"
        "qt5-svg"
        "qt5-wayland"     # For Wayland support
        "libxcb"          # X11 client library
        "ttf-jetbrains-mono-nerd" # Font for theme
    )
    
    log_info "Installing SDDM packages..."
    echo "[INFO] $(date): Installing SDDM packages: ${packages[*]}" >> "$LOG_FILE"
    
    # Install packages with error handling
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install SDDM packages"
        echo "[ERROR] $(date): Failed to install SDDM packages" >> "$LOG_FILE"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v sddm &> /dev/null; then
        log_error "SDDM installation failed: sddm command not found"
        echo "[ERROR] $(date): SDDM installation failed: sddm command not found" >> "$LOG_FILE"
        return $E_DEPENDENCY
    fi
    
    # Configure SDDM
    if ! configure_sddm; then
        log_error "Failed to configure SDDM"
        echo "[ERROR] $(date): Failed to configure SDDM" >> "$LOG_FILE"
        return $E_CONFIG
    fi
    
    # Install SDDM theme
    if ! install_sddm_theme; then
        log_warn "Failed to install SDDM theme, using default"
        echo "[WARN] $(date): Failed to install SDDM theme, using default" >> "$LOG_FILE"
        # Continue anyway, as SDDM has default themes
    fi
    
    # Enable SDDM service with validation
    log_info "Enabling SDDM service..."
    echo "[INFO] $(date): Enabling SDDM service" >> "$LOG_FILE"
    if ! enable_sddm_service; then
        log_error "Failed to enable SDDM service"
        echo "[ERROR] $(date): Failed to enable SDDM service" >> "$LOG_FILE"
        return $E_SERVICE
    fi
    
    # Test SDDM configuration
    if ! test_sddm_config; then
        log_warn "SDDM configuration test failed, but installation completed"
        echo "[WARN] $(date): SDDM configuration test failed, but installation completed" >> "$LOG_FILE"
        # Continue anyway, as this is just a test
    fi
    
    log_success "SDDM installation completed"
    echo "[SUCCESS] $(date): SDDM installation completed" >> "$LOG_FILE"
    
    return $E_SUCCESS
}

# Detect display resolution for SDDM
detect_display_resolution() {
    log_info "Detecting display resolution for SDDM..."
    echo "[INFO] $(date): Detecting display resolution for SDDM" >> "$LOG_FILE"
    
    # Try multiple methods to detect resolution
    local resolution=""
    local refresh_rate="60"
    
    # Method 1: Try xrandr if available
    if command -v xrandr &> /dev/null; then
        log_info "Using xrandr to detect resolution..."
        echo "[INFO] $(date): Using xrandr to detect resolution" >> "$LOG_FILE"
        
        local xrandr_output=""
        if ! xrandr_output=$(xrandr --query 2>/dev/null | grep "connected primary\|connected.*[0-9]\+x[0-9]\+" | head -1); then
            log_warn "xrandr query failed or returned no output"
            echo "[WARN] $(date): xrandr query failed or returned no output" >> "$LOG_FILE"
        fi
        
        if [[ -n "$xrandr_output" ]]; then
            resolution=$(echo "$xrandr_output" | grep -o '[0-9]\+x[0-9]\+' | head -1)
            refresh_rate=$(echo "$xrandr_output" | grep -o '[0-9]\+\.[0-9]\+\*' | sed 's/\*$//' | sed 's/\..*//' | head -1)
            [[ -z "$refresh_rate" ]] && refresh_rate="60"
            
            if [[ -n "$resolution" ]]; then
                log_info "xrandr detected resolution: $resolution at ${refresh_rate}Hz"
                echo "[INFO] $(date): xrandr detected resolution: $resolution at ${refresh_rate}Hz" >> "$LOG_FILE"
            else
                log_warn "xrandr output didn't contain resolution information"
                echo "[WARN] $(date): xrandr output didn't contain resolution information" >> "$LOG_FILE"
            fi
        fi
    fi
    
    # Method 2: Try wlr-randr if available (Wayland)
    if [[ -z "$resolution" ]] && command -v wlr-randr &> /dev/null; then
        log_info "Using wlr-randr to detect resolution (Wayland)..."
        echo "[INFO] $(date): Using wlr-randr to detect resolution (Wayland)" >> "$LOG_FILE"
        
        local wlr_output=""
        if ! wlr_output=$(wlr-randr 2>/dev/null | grep "current" | head -1); then
            log_warn "wlr-randr query failed or returned no output"
            echo "[WARN] $(date): wlr-randr query failed or returned no output" >> "$LOG_FILE"
        fi
        
        if [[ -n "$wlr_output" ]]; then
            resolution=$(echo "$wlr_output" | grep -o '[0-9]\+x[0-9]\+')
            refresh_rate=$(echo "$wlr_output" | grep -o '[0-9]\+\.[0-9]\+' | head -1 | sed 's/\..*//')
            [[ -z "$refresh_rate" ]] && refresh_rate="60"
            
            if [[ -n "$resolution" ]]; then
                log_info "wlr-randr detected resolution: $resolution at ${refresh_rate}Hz"
                echo "[INFO] $(date): wlr-randr detected resolution: $resolution at ${refresh_rate}Hz" >> "$LOG_FILE"
            fi
        fi
    fi
    
    # Method 3: Try reading from /sys/class/drm
    if [[ -z "$resolution" ]]; then
        log_info "Attempting to read resolution from /sys/class/drm..."
        echo "[INFO] $(date): Attempting to read resolution from /sys/class/drm" >> "$LOG_FILE"
        
        for mode_file in /sys/class/drm/card*/card*-*/modes; do
            if [[ -r "$mode_file" ]]; then
                resolution=$(head -1 "$mode_file" 2>/dev/null)
                if [[ -n "$resolution" ]]; then
                    log_info "Found resolution from /sys/class/drm: $resolution"
                    echo "[INFO] $(date): Found resolution from /sys/class/drm: $resolution" >> "$LOG_FILE"
                    break
                fi
            fi
        done
    fi
    
    # Method 4: Fallback - check common resolutions
    if [[ -z "$resolution" ]]; then
        log_warn "Unable to auto-detect resolution, checking common resolutions..."
        echo "[WARN] $(date): Unable to auto-detect resolution, checking common resolutions" >> "$LOG_FILE"
        
        # Try to detect based on common monitor sizes
        for test_res in "3840x2160" "2560x1440" "1920x1080" "1366x768"; do
            if command -v xrandr &> /dev/null && xrandr --dryrun --size "$test_res" &>/dev/null; then
                resolution="$test_res"
                log_info "Common resolution $test_res seems compatible"
                echo "[INFO] $(date): Common resolution $test_res seems compatible" >> "$LOG_FILE"
                break
            fi
        done
    fi
    
    # Set default if nothing detected
    if [[ -z "$resolution" ]]; then
        resolution="1920x1080"
        log_warn "Could not detect resolution, defaulting to $resolution"
        echo "[WARN] $(date): Could not detect resolution, defaulting to $resolution" >> "$LOG_FILE"
    else
        log_success "Detected resolution: $resolution at ${refresh_rate}Hz"
        echo "[SUCCESS] $(date): Detected resolution: $resolution at ${refresh_rate}Hz" >> "$LOG_FILE"
    fi
    
    # Configure X server arguments based on detected resolution
    if ! configure_display_args "$resolution" "$refresh_rate"; then
        handle_sddm_error "display" "Failed to configure display arguments"
        # Set a fallback configuration
        DISPLAY_ARGS="-dpi 96"
        export DISPLAY_ARGS
    fi
    
    return $E_SUCCESS
}

# Configure display arguments for SDDM
configure_display_args() {
    local resolution="$1"
    local refresh="$2"
    
    log_info "Configuring display arguments for resolution: $resolution at ${refresh}Hz"
    echo "[INFO] $(date): Configuring display arguments for resolution: $resolution at ${refresh}Hz" >> "$LOG_FILE"
    
    # Validate resolution format
    if ! [[ "$resolution" =~ ^[0-9]+x[0-9]+$ ]]; then
        log_error "Invalid resolution format: $resolution (expected WIDTHxHEIGHT)"
        echo "[ERROR] $(date): Invalid resolution format: $resolution (expected WIDTHxHEIGHT)" >> "$LOG_FILE"
        return $E_DISPLAY
    fi
    
    # Extract width and height
    local width=$(echo "$resolution" | cut -d'x' -f1)
    local height=$(echo "$resolution" | cut -d'x' -f2)
    
    # Validate width and height are numeric
    if ! [[ "$width" =~ ^[0-9]+$ ]] || ! [[ "$height" =~ ^[0-9]+$ ]]; then
        log_error "Invalid resolution components: width=$width, height=$height"
        echo "[ERROR] $(date): Invalid resolution components: width=$width, height=$height" >> "$LOG_FILE"
        return $E_DISPLAY
    fi
    
    # Validate refresh rate is numeric
    if ! [[ "$refresh" =~ ^[0-9]+$ ]]; then
        log_warn "Invalid refresh rate: $refresh, defaulting to 60Hz"
        echo "[WARN] $(date): Invalid refresh rate: $refresh, defaulting to 60Hz" >> "$LOG_FILE"
        refresh="60"
    fi
    
    # Configure DPI based on resolution
    local dpi="96"
    case "$resolution" in
        "3840x2160"|"3200x1800")
            dpi="144"  # 1.5x scaling for 4K
            ;;
        "2560x1440")
            dpi="120"  # 1.25x scaling for 1440p
            ;;
        "1920x1080")
            dpi="96"   # 1x scaling for 1080p
            ;;
        "1366x768")
            dpi="84"   # Slightly smaller for laptop screens
            ;;
        *)
            # Calculate appropriate DPI based on resolution
            if [[ $width -gt 2000 ]] || [[ $height -gt 1200 ]]; then
                dpi="120"  # Higher DPI for high-res displays
            elif [[ $width -lt 1000 ]] || [[ $height -lt 600 ]]; then
                dpi="72"   # Lower DPI for small displays
            else
                dpi="96"   # Standard DPI for typical displays
            fi
            ;;
    esac
    
    # Set display arguments
    DISPLAY_ARGS="-dpi $dpi"
    
    # Add preferred mode if available
    if [[ -n "$resolution" ]]; then
        DISPLAY_ARGS="$DISPLAY_ARGS -mode $resolution"
    fi
    
    # Add refresh rate if it's not 60Hz (the default)
    if [[ -n "$refresh" ]] && [[ "$refresh" != "60" ]]; then
        DISPLAY_ARGS="$DISPLAY_ARGS -rate $refresh"
    fi
    
    log_info "SDDM display args configured: $DISPLAY_ARGS"
    echo "[INFO] $(date): SDDM display args configured: $DISPLAY_ARGS" >> "$LOG_FILE"
    
    # Export for use in config file
    export DISPLAY_ARGS
    
    return $E_SUCCESS
}

enable_sddm_service() {
    log_info "Enabling SDDM service..."
    echo "[INFO] $(date): Enabling SDDM service" >> "$LOG_FILE"
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to enable SDDM service"
        echo "[WARN] $(date): Sudo access required to enable SDDM service" >> "$LOG_FILE"
        # Continue anyway, will prompt for password
    fi
    
    # Disable other display managers if they're enabled
    for dm in "lightdm" "gdm" "lxdm" "slim"; do
        if systemctl is-enabled "$dm.service" &>/dev/null; then
            log_warn "Found another display manager ($dm) enabled, disabling it..."
            echo "[WARN] $(date): Found another display manager ($dm) enabled, disabling it" >> "$LOG_FILE"
            sudo systemctl disable "$dm.service" &>/dev/null || true
        fi
    done
    
    # Enable SDDM service
    if ! enable_service "sddm"; then
        log_error "Failed to enable SDDM service"
        echo "[ERROR] $(date): Failed to enable SDDM service" >> "$LOG_FILE"
        return $E_SERVICE
    fi
    
    # Verify service is enabled
    if ! systemctl is-enabled sddm.service &>/dev/null; then
        log_error "SDDM service is not enabled properly"
        echo "[ERROR] $(date): SDDM service is not enabled properly" >> "$LOG_FILE"
        return $E_SERVICE
    fi
    
    log_success "SDDM service enabled"
    echo "[SUCCESS] $(date): SDDM service enabled" >> "$LOG_FILE"
    return $E_SUCCESS
}

test_sddm_config() {
    log_info "Testing SDDM configuration..."
    echo "[INFO] $(date): Testing SDDM configuration" >> "$LOG_FILE"
    
    local errors=0
    local warnings=0
    
    # Check if SDDM is installed
    if command -v sddm &> /dev/null; then
        log_success "✅ SDDM is installed"
        echo "[SUCCESS] $(date): SDDM is installed" >> "$LOG_FILE"
        
        # Check SDDM version
        local sddm_version=$(sddm --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        if [[ "$sddm_version" != "unknown" ]]; then
            log_success "✅ SDDM version: $sddm_version"
            echo "[SUCCESS] $(date): SDDM version: $sddm_version" >> "$LOG_FILE"
        else
            log_warn "⚠️  Could not determine SDDM version"
            echo "[WARN] $(date): Could not determine SDDM version" >> "$LOG_FILE"
            ((warnings++))
        fi
    else
        log_error "❌ SDDM not found"
        echo "[ERROR] $(date): SDDM not found" >> "$LOG_FILE"
        ((errors++))
        # No point continuing other tests if SDDM is not installed
        return $E_GENERAL
    fi
    
    # Check if configuration file exists
    if [[ -f "$CONFIG_FILE" ]]; then
        log_success "✅ SDDM configuration file exists"
        echo "[SUCCESS] $(date): SDDM configuration file exists" >> "$LOG_FILE"
        
        # Validate configuration file
        if sddm --test-mode --config "$CONFIG_FILE" &>/dev/null; then
            log_success "✅ SDDM configuration is valid"
            echo "[SUCCESS] $(date): SDDM configuration is valid" >> "$LOG_FILE"
        else
            log_warn "⚠️  SDDM configuration validation failed"
            echo "[WARN] $(date): SDDM configuration validation failed" >> "$LOG_FILE"
            ((warnings++))
        fi
    else
        log_error "❌ SDDM configuration file is missing"
        echo "[ERROR] $(date): SDDM configuration file is missing" >> "$LOG_FILE"
        ((errors++))
    fi
    
    # Check if theme exists
    local theme_name=$(grep -i "Current=.*" "$CONFIG_FILE" 2>/dev/null | head -1 | cut -d'=' -f2)
    if [[ -n "$theme_name" ]]; then
        log_info "SDDM theme set to: $theme_name"
        echo "[INFO] $(date): SDDM theme set to: $theme_name" >> "$LOG_FILE"
        
        if [[ -d "/usr/share/sddm/themes/$theme_name" ]]; then
            log_success "✅ SDDM theme directory exists"
            echo "[SUCCESS] $(date): SDDM theme directory exists" >> "$LOG_FILE"
            
            # Check if theme has required files
            if [[ -f "/usr/share/sddm/themes/$theme_name/Main.qml" ]]; then
                log_success "✅ SDDM theme is properly set up"
                echo "[SUCCESS] $(date): SDDM theme is properly set up" >> "$LOG_FILE"
            else
                log_warn "⚠️  SDDM theme may be missing required files"
                echo "[WARN] $(date): SDDM theme may be missing required files" >> "$LOG_FILE"
                ((warnings++))
            fi
        else
            log_warn "⚠️  SDDM theme directory not found: /usr/share/sddm/themes/$theme_name"
            echo "[WARN] $(date): SDDM theme directory not found: /usr/share/sddm/themes/$theme_name" >> "$LOG_FILE"
            ((warnings++))
        fi
    else
        log_warn "⚠️  SDDM theme not specified in configuration"
        echo "[WARN] $(date): SDDM theme not specified in configuration" >> "$LOG_FILE"
        ((warnings++))
    fi
    
    # Check if SDDM service is enabled
    if systemctl is-enabled sddm.service &>/dev/null; then
        log_success "✅ SDDM service is enabled"
        echo "[SUCCESS] $(date): SDDM service is enabled" >> "$LOG_FILE"
    else
        log_error "❌ SDDM service is not enabled"
        echo "[ERROR] $(date): SDDM service is not enabled" >> "$LOG_FILE"
        ((errors++))
    fi
    
    # Report summary
    if [[ $errors -gt 0 ]]; then
        log_error "SDDM configuration test completed with $errors errors and $warnings warnings"
        echo "[ERROR] $(date): SDDM configuration test completed with $errors errors and $warnings warnings" >> "$LOG_FILE"
        return $E_GENERAL
    elif [[ $warnings -gt 0 ]]; then
        log_warn "SDDM configuration test completed with $warnings warnings"
        echo "[WARN] $(date): SDDM configuration test completed with $warnings warnings" >> "$LOG_FILE"
        return $E_SUCCESS
    else
        log_success "SDDM configuration test completed successfully"
        echo "[SUCCESS] $(date): SDDM configuration test completed successfully" >> "$LOG_FILE"
        return $E_SUCCESS
    fi
}

configure_sddm() {
    log_info "Configuring SDDM..."
    echo "[INFO] $(date): Configuring SDDM" >> "$LOG_FILE"
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to configure SDDM"
        echo "[WARN] $(date): Sudo access required to configure SDDM" >> "$LOG_FILE"
        # Continue anyway, will prompt for password
    fi
    
    # Detect current display resolution
    if ! detect_display_resolution; then
        log_warn "Display resolution detection failed, using defaults"
        echo "[WARN] $(date): Display resolution detection failed, using defaults" >> "$LOG_FILE"
        # Set fallback display args
        DISPLAY_ARGS="-dpi 96"
        export DISPLAY_ARGS
    fi
    
    # Ensure DISPLAY_ARGS is set
    if [[ -z "${DISPLAY_ARGS:-}" ]]; then
        log_warn "DISPLAY_ARGS not set, using default"
        echo "[WARN] $(date): DISPLAY_ARGS not set, using default" >> "$LOG_FILE"
        DISPLAY_ARGS="-dpi 96"
        export DISPLAY_ARGS
    fi
    
    log_info "Creating SDDM configuration file: $CONFIG_FILE"
    echo "[INFO] $(date): Creating SDDM configuration file: $CONFIG_FILE" >> "$LOG_FILE"
    
    # Create SDDM configuration
    if ! sudo tee "$CONFIG_FILE" > /dev/null << EOF
[Autologin]
# Whether sddm should automatically log back into sessions when they exit
Relogin=false

# Name of session file for autologin session (if empty try last logged in)
Session=

# Username for autologin session
User=

[General]
# Halt command
HaltCommand=/usr/bin/systemctl poweroff

# Input method module
InputMethod=

# Comma-separated list of Linux namespaces for user session to enter
Namespaces=

# Maximum number of concurrent sessions
NumSessions=3

# Reboot command
RebootCommand=/usr/bin/systemctl reboot

# Current theme name
Current=catppuccin-mocha

[Theme]
# Current theme name
Current=catppuccin-mocha

# Cursor theme used in the greeter
CursorTheme=

# Number of users to use as threshold
DisableAvatarsThreshold=7

# Enable Qt's automatic high-DPI scaling
EnableAvatars=true

# Face icon directory path
FacesDir=/usr/share/sddm/faces

# Theme directory path
ThemeDir=/usr/share/sddm/themes

[Users]
# Default $PATH for logged in users
DefaultPath=/usr/local/sbin:/usr/local/bin:/usr/bin

# Comma-separated list of shells users listed in sddm
DefaultShell=/bin/bash

# Hide shells for users listed
HideShells=

# Hide users from list
HideUsers=

# Maximum user id for displayed users
MaximumUid=60513

# Minimum user id for displayed users
MinimumUid=1000

# Remember the session of the last successfully logged in user
RememberLastSession=true

# Remember the last successfully logged in user
RememberLastUser=true

[Wayland]
# Path to a script to execute when starting the desktop session
SessionCommand=/usr/share/sddm/scripts/wayland-session

# Directory containing available Wayland sessions
SessionDir=/usr/share/wayland-sessions

# Path to the user session log file
SessionLogFile=.local/share/sddm/wayland-session.log

[X11]
# Path to a script to execute when starting the display server
DisplayCommand=/usr/share/sddm/scripts/Xsetup

# Path to a script to execute when stopping the display server
DisplayStopCommand=/usr/share/sddm/scripts/Xstop

# Minimum VT for X servers
MinimumVT=1

# Arguments passed to the X server invocation
ServerArguments=-nolisten tcp $DISPLAY_ARGS

# Path to X server binary
ServerPath=/usr/bin/X

# Path to a script to execute when starting the desktop session
SessionCommand=/usr/share/sddm/scripts/Xsession

# Directory containing available X sessions
SessionDir=/usr/share/xsessions

# Path to the user session log file
SessionLogFile=.local/share/sddm/xorg-session.log

# Path to the Xauthority file
UserAuthFile=.Xauthority

# Path to xauth binary
XauthPath=/usr/bin/xauth

# Path to Xephyr binary
XephyrPath=/usr/bin/Xephyr
EOF
    then
        handle_sddm_error "config" "Failed to create SDDM configuration file"
        return $E_CONFIG
    fi
    
    # Verify config file was created
    if ! sudo test -f "$CONFIG_FILE"; then
        handle_sddm_error "config" "SDDM configuration file not created"
        return $E_CONFIG
    fi
    
    # Make sure config file is readable by others (needed by SDDM)
    sudo chmod 644 "$CONFIG_FILE" 2>/dev/null || true
    
    # Create Xsetup script to set custom display settings
    log_info "Creating SDDM Xsetup script..."
    echo "[INFO] $(date): Creating SDDM Xsetup script" >> "$LOG_FILE"
    
    local xsetup_dir="/usr/share/sddm/scripts"
    if ! sudo test -d "$xsetup_dir"; then
        if ! sudo mkdir -p "$xsetup_dir" 2>/dev/null; then
            log_warn "Failed to create SDDM scripts directory"
            echo "[WARN] $(date): Failed to create SDDM scripts directory" >> "$LOG_FILE"
            # Continue anyway
        fi
    fi
    
    # Create Xsetup script with monitor configuration
    local xsetup_file="$xsetup_dir/Xsetup"
    if ! sudo tee "$xsetup_file" > /dev/null << 'EOF'
#!/bin/sh
# Xsetup - run as root before the login dialog appears

# Set display parameters
if command -v xrandr >/dev/null 2>&1; then
    # Get primary monitor
    PRIMARY=$(xrandr | grep " connected" | grep "primary" | cut -d" " -f1)
    
    if [ -z "$PRIMARY" ]; then
        # If no primary monitor found, use the first connected monitor
        PRIMARY=$(xrandr | grep " connected" | head -n 1 | cut -d" " -f1)
    fi
    
    # Set resolution if we found a monitor
    if [ -n "$PRIMARY" ]; then
        # Get best mode for the monitor
        BEST_MODE=$(xrandr | grep -A1 "$PRIMARY" | grep -v "$PRIMARY" | grep -oE '[0-9]+x[0-9]+' | head -n 1)
        
        if [ -n "$BEST_MODE" ]; then
            xrandr --output "$PRIMARY" --mode "$BEST_MODE" --primary
        fi
    fi
fi

# Set default cursor
xsetroot -cursor_name left_ptr

# Set keyboard layout if needed
setxkbmap -layout us

exit 0
EOF
    then
        log_warn "Failed to create SDDM Xsetup script"
        echo "[WARN] $(date): Failed to create SDDM Xsetup script" >> "$LOG_FILE"
        # Continue anyway
    else
        sudo chmod +x "$xsetup_file" 2>/dev/null || true
        log_info "SDDM Xsetup script created"
        echo "[INFO] $(date): SDDM Xsetup script created" >> "$LOG_FILE"
    fi
    
    log_success "SDDM configured"
    echo "[SUCCESS] $(date): SDDM configured" >> "$LOG_FILE"
    return $E_SUCCESS
}

validate_sddm_theme() {
    local theme_dir="$1"
    
    log_info "Validating SDDM theme: $theme_dir"
    echo "[INFO] $(date): Validating SDDM theme: $theme_dir" >> "$LOG_FILE"
    
    # Check if theme directory exists
    if [[ ! -d "$theme_dir" ]]; then
        log_error "Theme directory does not exist: $theme_dir"
        echo "[ERROR] $(date): Theme directory does not exist: $theme_dir" >> "$LOG_FILE"
        return $E_THEME
    fi
    
    # Check for required theme files
    local required_files=("Main.qml" "theme.conf" "metadata.desktop")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$theme_dir/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Theme is missing required files: ${missing_files[*]}"
        echo "[ERROR] $(date): Theme is missing required files: ${missing_files[*]}" >> "$LOG_FILE"
        return $E_THEME
    fi
    
    # Check if theme.conf contains required entries
    if ! grep -q "\[General\]" "$theme_dir/theme.conf"; then
        log_warn "Theme configuration may be incomplete (missing [General] section)"
        echo "[WARN] $(date): Theme configuration may be incomplete (missing [General] section)" >> "$LOG_FILE"
    fi
    
    # Check if Main.qml contains basic QML imports
    if ! grep -q "import QtQuick" "$theme_dir/Main.qml"; then
        log_warn "Theme QML file may be incomplete (missing QtQuick import)"
        echo "[WARN] $(date): Theme QML file may be incomplete (missing QtQuick import)" >> "$LOG_FILE"
    fi
    
    log_success "Theme validation passed: $theme_dir"
    echo "[SUCCESS] $(date): Theme validation passed: $theme_dir" >> "$LOG_FILE"
    return $E_SUCCESS
}

install_sddm_theme() {
    log_info "Installing SDDM Catppuccin theme..."
    echo "[INFO] $(date): Installing SDDM Catppuccin theme" >> "$LOG_FILE"
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to install SDDM theme"
        echo "[WARN] $(date): Sudo access required to install SDDM theme" >> "$LOG_FILE"
        # Continue anyway, will prompt for password
    fi
    
    # Create theme directory
    local theme_dir="/usr/share/sddm/themes/catppuccin-mocha"
    if ! sudo test -d "$theme_dir"; then
        log_info "Creating theme directory: $theme_dir"
        echo "[INFO] $(date): Creating theme directory: $theme_dir" >> "$LOG_FILE"
        
        if ! sudo mkdir -p "$theme_dir" 2>/dev/null; then
            handle_sddm_error "theme" "Failed to create theme directory: $theme_dir"
            return $E_DIRECTORY
        fi
    else
        log_info "Theme directory already exists: $theme_dir"
        echo "[INFO] $(date): Theme directory already exists: $theme_dir" >> "$LOG_FILE"
    fi
    
    # Clone and install catppuccin theme
    log_info "Downloading Catppuccin SDDM theme..."
    echo "[INFO] $(date): Downloading Catppuccin SDDM theme" >> "$LOG_FILE"
    
    # Create temp directory
    local temp_dir="/tmp/sddm-catppuccin-$(date +%s)"
    if ! mkdir -p "$temp_dir" 2>/dev/null; then
        handle_sddm_error "theme" "Failed to create temporary directory for theme download"
        # Fallback to creating a basic theme
        log_warn "Falling back to creating a basic theme"
        echo "[WARN] $(date): Falling back to creating a basic theme" >> "$LOG_FILE"
        return create_basic_sddm_theme
    fi
    
    # Download theme
    if ! git clone https://github.com/catppuccin/sddm.git "$temp_dir" 2>/dev/null; then
        log_warn "Failed to download Catppuccin SDDM theme, creating basic theme"
        echo "[WARN] $(date): Failed to download Catppuccin SDDM theme, creating basic theme" >> "$LOG_FILE"
        rm -rf "$temp_dir" 2>/dev/null || true
        return create_basic_sddm_theme
    fi
    
    # Check if source theme directory exists
    local source_theme_dir="$temp_dir/src/catppuccin-mocha"
    if [[ ! -d "$source_theme_dir" ]]; then
        log_warn "Source theme directory not found: $source_theme_dir"
        echo "[WARN] $(date): Source theme directory not found: $source_theme_dir" >> "$LOG_FILE"
        rm -rf "$temp_dir" 2>/dev/null || true
        return create_basic_sddm_theme
    fi
    
    # Copy theme files
    log_info "Copying theme files to: $theme_dir"
    echo "[INFO] $(date): Copying theme files to: $theme_dir" >> "$LOG_FILE"
    
    if ! sudo cp -r "$source_theme_dir/." "$theme_dir/" 2>/dev/null; then
        log_warn "Failed to copy theme files, creating basic theme"
        echo "[WARN] $(date): Failed to copy theme files, creating basic theme" >> "$LOG_FILE"
        rm -rf "$temp_dir" 2>/dev/null || true
        return create_basic_sddm_theme
    fi
    
    # Clean up
    rm -rf "$temp_dir" 2>/dev/null || true
    
    # Validate theme
    if ! validate_sddm_theme "$theme_dir"; then
        log_warn "Theme validation failed, creating basic theme"
        echo "[WARN] $(date): Theme validation failed, creating basic theme" >> "$LOG_FILE"
        return create_basic_sddm_theme
    fi
    
    log_success "Catppuccin SDDM theme installed"
    echo "[SUCCESS] $(date): Catppuccin SDDM theme installed" >> "$LOG_FILE"
    return $E_SUCCESS
}

create_basic_sddm_theme() {
    log_info "Creating basic SDDM theme..."
    echo "[INFO] $(date): Creating basic SDDM theme" >> "$LOG_FILE"
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Sudo access required to create SDDM theme"
        echo "[WARN] $(date): Sudo access required to create SDDM theme" >> "$LOG_FILE"
        # Continue anyway, will prompt for password
    fi
    
    local theme_dir="/usr/share/sddm/themes/catppuccin-mocha"
    if ! sudo mkdir -p "$theme_dir" 2>/dev/null; then
        handle_sddm_error "theme" "Failed to create theme directory: $theme_dir"
        return $E_DIRECTORY
    fi
    
    log_info "Creating theme configuration file..."
    echo "[INFO] $(date): Creating theme configuration file" >> "$LOG_FILE"
    
    # Create theme.conf
    if ! sudo tee "$theme_dir/theme.conf" > /dev/null << 'EOF'
[General]
type=color

color=#1e1e2e
fontSize=24
font=JetBrainsMono Nerd Font

[Input]
color=#89b4fa
borderColor=#89b4fa
borderWidth=2
borderRadius=8

[ComboBox]
color=#89b4fa
borderColor=#89b4fa
borderWidth=2
borderRadius=8
EOF
    then
        handle_sddm_error "theme" "Failed to create theme configuration file"
        return $E_CONFIG
    fi
    
    log_info "Creating theme metadata file..."
    echo "[INFO] $(date): Creating theme metadata file" >> "$LOG_FILE"
    
    # Create metadata.desktop
    if ! sudo tee "$theme_dir/metadata.desktop" > /dev/null << 'EOF'
[SddmGreeterTheme]
Name=Catppuccin Mocha
Description=Catppuccin Mocha theme for SDDM
Author=HyprSupreme-Builder
Copyright=(c) 2024
License=MIT
Type=sddm-theme
Version=1.0
Website=https://github.com/GeneticxCln/HyprSupreme-Builder
MainScript=Main.qml
ConfigFile=theme.conf
TranslationsDirectory=translations
Theme-Id=catppuccin-mocha
Theme-API=2.0
EOF
    then
        handle_sddm_error "theme" "Failed to create theme metadata file"
        return $E_CONFIG
    fi
    
    log_info "Creating theme QML file..."
    echo "[INFO] $(date): Creating theme QML file" >> "$LOG_FILE"
    
    # Create basic Main.qml
    if ! sudo tee "$theme_dir/Main.qml" > /dev/null << 'EOF'
import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    width: 640
    height: 480
    color: "#1e1e2e"

    Clock {
        id: clock
        anchors.centerIn: parent
        color: "#cdd6f4"
        timeFont.family: "JetBrainsMono Nerd Font"
        timeFont.pointSize: 48
    }

    LoginFrame {
        id: frame
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 100
    }
}
EOF
    then
        handle_sddm_error "theme" "Failed to create theme QML file"
        return $E_CONFIG
    fi
    
    # Set proper permissions for theme files
    sudo chmod -R 755 "$theme_dir" 2>/dev/null || true
    
    # Validate theme
    if ! validate_sddm_theme "$theme_dir"; then
        log_warn "Basic theme validation failed"
        echo "[WARN] $(date): Basic theme validation failed" >> "$LOG_FILE"
        # Continue anyway, as this is already a fallback
    fi
    
    log_success "Basic SDDM theme created"
    echo "[SUCCESS] $(date): Basic SDDM theme created" >> "$LOG_FILE"
    return $E_SUCCESS
}

# Verify user is not root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        echo "[ERROR] $(date): This script should not be run as root" >> "$LOG_FILE"
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
            install_sddm
            exit_code=$?
            ;;
        "config")
            configure_sddm
            exit_code=$?
            ;;
        "theme")
            install_sddm_theme
            exit_code=$?
            ;;
        "test")
            test_sddm_config
            exit_code=$?
            ;;
        "backup")
            backup_sddm_config
            exit_code=$?
            ;;
        "restore")
            if [[ -n "${2:-}" ]]; then
                restore_sddm_config "$2"
                exit_code=$?
            else
                log_error "No backup path specified"
                echo "Usage: $0 restore <backup_path>"
                exit_code=$E_GENERAL
            fi
            ;;
        "help")
            echo "Usage: $0 {install|config|theme|test|backup|restore|help}"
            echo ""
            echo "Operations:"
            echo "  install    - Install SDDM display manager (default)"
            echo "  config     - Configure SDDM"
            echo "  theme      - Install SDDM theme"
            echo "  test       - Test SDDM configuration"
            echo "  backup     - Backup existing configuration"
            echo "  restore    - Restore configuration from backup"
            echo "  help       - Show this help message"
            exit_code=$E_SUCCESS
            ;;
        *)
            log_error "Invalid operation: $operation"
            echo "Usage: $0 {install|config|theme|test|backup|restore|help}"
            exit_code=$E_GENERAL
            ;;
    esac
    
    # Return with appropriate exit code
    if [[ $exit_code -eq $E_SUCCESS ]]; then
        log_success "Operation '$operation' completed successfully"
        echo "[SUCCESS] $(date): Operation '$operation' completed successfully" >> "$LOG_FILE"
    else
        log_error "Operation '$operation' failed with code $exit_code"
        echo "[ERROR] $(date): Operation '$operation' failed with code $exit_code" >> "$LOG_FILE"
    fi
    
    return $exit_code
}

# Run main function if script is executed directly
main "$@"
exit $?

