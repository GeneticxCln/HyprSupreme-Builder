#!/bin/bash
# HyprSupreme-Builder - Hyprland Installation Module

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
readonly E_WAYLAND=7  # Wayland-specific errors
readonly E_GRAPHICS=8 # Graphics driver errors

# Path to the script
readonly SCRIPT_PATH="$(readlink -f "$0")"
readonly SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
readonly CONFIG_DIR="$HOME/.config/hypr"
readonly BACKUP_DIR="$HOME/.config/hypr-backup-$(date +%Y%m%d-%H%M%S)"

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

# Hyprland-specific error handler
handle_hyprland_error() {
    local error_type="$1"
    local error_message="$2"
    
    case "$error_type" in
        "wayland")
            log_error "Wayland error: $error_message"
            return $E_WAYLAND
            ;;
        "graphics")
            log_error "Graphics driver error: $error_message"
            return $E_GRAPHICS
            ;;
        "config")
            log_error "Configuration error: $error_message"
            return $E_CONFIG
            ;;
        *)
            log_error "Unknown Hyprland error: $error_message"
            return $E_GENERAL
            ;;
    esac
}

# Trap errors
trap 'handle_error $? "Script interrupted" "$BASH_SOURCE:$LINENO"' ERR
trap 'log_warn "Script received SIGINT - operation canceled"; exit $E_GENERAL' INT
trap 'log_warn "Script received SIGTERM - operation canceled"; exit $E_GENERAL' TERM

check_wayland_support() {
    log_info "Checking Wayland support..."
    
    # Check if Wayland-compatible GPU is available
    if ! lspci | grep -q -i "VGA\|3D\|Display"; then
        log_error "No GPU detected - Wayland requires a compatible GPU"
        return $E_GRAPHICS
    fi
    
    # Check for compatible graphics driver
    local has_compatible_driver=false
    
    # Check for NVIDIA
    if lspci | grep -q -i "NVIDIA"; then
        log_info "NVIDIA GPU detected"
        # Check for NVIDIA driver
        if command -v nvidia-smi &> /dev/null; then
            log_success "NVIDIA driver detected"
            has_compatible_driver=true
        else
            log_warn "NVIDIA GPU detected but driver not installed"
            log_warn "Hyprland may not work properly with NVIDIA without proper drivers"
        fi
    fi
    
    # Check for AMD/Intel
    if lspci | grep -q -i "AMD\|ATI\|Intel"; then
        log_info "AMD/Intel GPU detected"
        if lsmod | grep -q -E "amdgpu|radeon|i915"; then
            log_success "AMD/Intel driver detected"
            has_compatible_driver=true
        else
            log_warn "AMD/Intel GPU detected but driver module not loaded"
        fi
    fi
    
    if ! $has_compatible_driver; then
        log_warn "No compatible graphics driver detected - Wayland may not work properly"
        # Don't return error - still try to install
    fi
    
    return $E_SUCCESS
}

check_dependencies() {
    log_info "Checking dependencies for Hyprland..."
    
    # Check for required packages
    local required_deps=(
        "meson"         # Build system
        "ninja"         # Build system
        "gcc"           # Compiler
        "libxcb"        # X library
        "libdrm"        # Direct Rendering Manager
        "wayland"       # Wayland protocol
        "wlroots"       # Wayland compositor library
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
            return $E_DEPENDENCY
        fi
    fi
    
    return $E_SUCCESS
}

backup_existing_config() {
    if [[ -d "$CONFIG_DIR" ]]; then
        log_info "Backing up existing Hyprland configuration..."
        
        # Create backup directory
        if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
            log_error "Failed to create backup directory: $BACKUP_DIR"
            return $E_DIRECTORY
        fi
        
        # Copy configuration files
        if ! cp -r "$CONFIG_DIR"/* "$BACKUP_DIR"/ 2>/dev/null; then
            log_warn "Some configuration files could not be backed up"
            # Continue anyway
        fi
        
        log_success "Existing configuration backed up to $BACKUP_DIR"
    fi
    
    return $E_SUCCESS
}

create_default_config() {
    log_info "Creating default Hyprland configuration..."
    
    if [[ ! -d "$CONFIG_DIR" ]]; then
        if ! mkdir -p "$CONFIG_DIR" 2>/dev/null; then
            log_error "Failed to create config directory: $CONFIG_DIR"
            return $E_DIRECTORY
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$CONFIG_DIR" ]]; then
        log_error "No write permission for config directory: $CONFIG_DIR"
        return $E_PERMISSION
    fi
    
    # Create hyprland.conf if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/hyprland.conf" ]]; then
        log_info "Creating default hyprland.conf..."
        
        if ! cat > "$CONFIG_DIR/hyprland.conf" << 'EOF'
# HyprSupreme default configuration

# Monitor
monitor=,preferred,auto,1

# Set variables
$mainMod = SUPER

# Autostart
exec-once = waybar
exec-once = hyprpaper
exec-once = wl-clipboard-history -t
exec-once = ~/.config/hypr/scripts/xdg-portal-hyprland
exec-once = dunst
exec-once = nm-applet --indicator

# Some default env vars
env = XCURSOR_SIZE,24

# Input configuration
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1
    natural_scroll = false
    touchpad {
        natural_scroll = true
    }
    sensitivity = 0
}

# General appearance
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decoration
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layouts
dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_is_master = true
}

# Gestures
gestures {
    workspace_swipe = false
}

# Key bindings
bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, rofi -show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
EOF
        then
            log_error "Failed to create default hyprland.conf"
            return $E_CONFIG
        fi
    else
        log_info "Using existing hyprland.conf"
    fi
    
    # Create hyprpaper.conf if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/hyprpaper.conf" ]]; then
        log_info "Creating default hyprpaper.conf..."
        
        if ! cat > "$CONFIG_DIR/hyprpaper.conf" << 'EOF'
# HyprSupreme default wallpaper configuration

preload = ~/.config/hypr/wallpapers/default.jpg
wallpaper = ,~/.config/hypr/wallpapers/default.jpg
EOF
        then
            log_error "Failed to create default hyprpaper.conf"
            return $E_CONFIG
        fi
    else
        log_info "Using existing hyprpaper.conf"
    fi
    
    # Create scripts directory and XDG portal script
    local scripts_dir="$CONFIG_DIR/scripts"
    if [[ ! -d "$scripts_dir" ]]; then
        if ! mkdir -p "$scripts_dir" 2>/dev/null; then
            log_error "Failed to create scripts directory: $scripts_dir"
            return $E_DIRECTORY
        fi
    fi
    
    # Create XDG portal script
    local xdg_script="$scripts_dir/xdg-portal-hyprland"
    
    if ! cat > "$xdg_script" << 'EOF'
#!/bin/bash

sleep 1
killall -e xdg-desktop-portal-hyprland xdg-desktop-portal-wlr xdg-desktop-portal-gtk xdg-desktop-portal
sleep 1
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &
EOF
    then
        log_error "Failed to create XDG portal script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$xdg_script" 2>/dev/null; then
        log_error "Failed to make XDG portal script executable"
        return $E_PERMISSION
    fi
    
    # Create wallpapers directory and download default wallpaper
    local wallpapers_dir="$CONFIG_DIR/wallpapers"
    if [[ ! -d "$wallpapers_dir" ]]; then
        if ! mkdir -p "$wallpapers_dir" 2>/dev/null; then
            log_error "Failed to create wallpapers directory: $wallpapers_dir"
            return $E_DIRECTORY
        fi
    fi
    
    # Download a default wallpaper if none exists
    if [[ ! -f "$wallpapers_dir/default.jpg" ]]; then
        log_info "Downloading default wallpaper..."
        
        # Use a default wallpaper URL or copy from the project
        if ! curl -s "https://raw.githubusercontent.com/hyprwm/hyprpaper/main/example/wallpaper.png" -o "$wallpapers_dir/default.jpg" 2>/dev/null; then
            log_warn "Failed to download default wallpaper"
            # Try to copy from the project if available
            if [[ -f "$SCRIPT_DIR/../../sources/wallpapers/default.jpg" ]]; then
                cp "$SCRIPT_DIR/../../sources/wallpapers/default.jpg" "$wallpapers_dir/default.jpg" || true
            fi
        fi
    fi
    
    log_success "Default configuration created"
    return $E_SUCCESS
}

install_hyprland() {
    log_info "Installing Hyprland..."
    
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
    
    # Check Wayland support
    if ! check_wayland_support; then
        log_warn "Wayland support check failed, but continuing anyway"
        # Continue anyway but warn the user
    fi
    
    # Check and install dependencies
    if ! check_dependencies; then
        log_error "Failed to check/install dependencies"
        return $E_DEPENDENCY
    fi
    
    # Backup existing configuration if any
    backup_existing_config
    
    # Install Hyprland and essential packages
    local packages=(
        # Core Hyprland components
        "hyprland"
        "hyprpaper"
        "hyprlock"
        "hypridle"
        "xdg-desktop-portal-hyprland"
        
        # Wayland compatibility
        "qt5-wayland"
        "qt6-wayland"
        "xorg-xwayland"
        
        # Authentication
        "polkit-kde-agent"
        
        # Utilities
        "wl-clipboard"
        "cliphist"
        "grim"          # Screenshot utility
        "slurp"         # Area selection
        "swappy"        # Screenshot editing
        "dunst"         # Notifications
        "libnotify"     # Notification library
        "waybar"        # Status bar
    )
    
    log_info "Installing Hyprland packages..."
    
    # Install packages with error handling
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install Hyprland packages"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v hyprctl &> /dev/null; then
        log_error "Hyprland installation failed: hyprctl command not found"
        return $E_DEPENDENCY
    fi
    
    # Create configuration files
    if ! create_default_config; then
        log_error "Failed to create default configuration"
        return $E_CONFIG
    fi
    
    # Setup systemd user services if needed
    setup_user_services
    
    log_success "Hyprland installation completed"
    return $E_SUCCESS
}

setup_user_services() {
    log_info "Setting up user services..."
    
    # Create systemd user directory if it doesn't exist
    local systemd_dir="$HOME/.config/systemd/user"
    if [[ ! -d "$systemd_dir" ]]; then
        if ! mkdir -p "$systemd_dir" 2>/dev/null; then
            log_warn "Failed to create systemd user directory"
            return $E_DIRECTORY
        fi
    fi
    
    # No specific services to setup currently
    
    return $E_SUCCESS
}

# Test Hyprland installation
test_hyprland() {
    log_info "Testing Hyprland installation..."
    local errors=0
    local warnings=0
    
    # Check if Hyprland is installed
    if command -v hyprctl &> /dev/null; then
        log_success "✅ Hyprland is installed"
        
        # Get Hyprland version
        local hyprland_version=$(hyprctl version 2>/dev/null | grep -oP "(?<=v)[0-9]+\.[0-9]+\.[0-9]+" || echo "unknown")
        if [[ "$hyprland_version" != "unknown" ]]; then
            log_success "✅ Hyprland version: $hyprland_version"
        else
            log_warn "⚠️  Could not determine Hyprland version"
            ((warnings++))
        fi
    else
        log_error "❌ Hyprland not found"
        ((errors++))
    fi
    
    # Check for essential packages
    local essential_packages=("hyprpaper" "xdg-desktop-portal-hyprland" "wl-clipboard")
    for pkg in "${essential_packages[@]}"; do
        if pacman -Q "$pkg" &> /dev/null; then
            log_success "✅ Package $pkg is installed"
        else
            log_error "❌ Essential package $pkg is missing"
            ((errors++))
        fi
    done
    
    # Check configuration files
    local required_configs=("hyprland.conf" "hyprpaper.conf")
    for config in "${required_configs[@]}"; do
        if [[ -f "$CONFIG_DIR/$config" ]]; then
            log_success "✅ Configuration file $config exists"
        else
            log_error "❌ Configuration file $config is missing"
            ((errors++))
        fi
    done
    
    # Check if required scripts exist
    if [[ -x "$CONFIG_DIR/scripts/xdg-portal-hyprland" ]]; then
        log_success "✅ XDG portal script exists and is executable"
    elif [[ -f "$CONFIG_DIR/scripts/xdg-portal-hyprland" ]]; then
        log_warn "⚠️  XDG portal script exists but is not executable"
        ((warnings++))
    else
        log_error "❌ XDG portal script is missing"
        ((errors++))
    fi
    
    # Check if we're currently running in Wayland
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        log_success "✅ Currently running in Wayland session"
    else
        log_warn "⚠️  Not currently running in Wayland session"
        ((warnings++))
    fi
    
    # Check if XDG desktop portal is available
    if [[ -f "/usr/lib/xdg-desktop-portal" ]]; then
        log_success "✅ XDG desktop portal is available"
    else
        log_warn "⚠️  XDG desktop portal not found"
        ((warnings++))
    fi
    
    # Check GPU driver compatibility
    if lspci | grep -q -i "NVIDIA" && ! command -v nvidia-smi &> /dev/null; then
        log_warn "⚠️  NVIDIA GPU detected but driver not installed"
        ((warnings++))
    fi
    
    # Report summary
    if [[ $errors -gt 0 ]]; then
        log_error "Hyprland test completed with $errors errors and $warnings warnings"
        return $E_GENERAL
    elif [[ $warnings -gt 0 ]]; then
        log_warn "Hyprland test completed with $warnings warnings"
        return $E_SUCCESS
    else
        log_success "Hyprland test completed successfully"
        return $E_SUCCESS
    fi
}

restore_config() {
    local backup_path="$1"
    
    if [[ -d "$backup_path" ]]; then
        log_info "Restoring configuration from backup: $backup_path"
        
        if ! cp -r "$backup_path"/* "$CONFIG_DIR"/ 2>/dev/null; then
            log_error "Failed to restore configuration"
            return $E_GENERAL
        fi
        
        log_success "Configuration restored from backup"
        return $E_SUCCESS
    else
        log_error "Backup directory not found: $backup_path"
        return $E_DIRECTORY
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
            install_hyprland
            exit_code=$?
            ;;
        "test")
            test_hyprland
            exit_code=$?
            ;;
        "config")
            create_default_config
            exit_code=$?
            ;;
        "backup")
            backup_existing_config
            exit_code=$?
            ;;
        "restore")
            if [[ -n "${2:-}" ]]; then
                restore_config "$2"
                exit_code=$?
            else
                log_error "No backup path specified"
                echo "Usage: $0 restore <backup_path>"
                exit_code=$E_GENERAL
            fi
            ;;
        "help")
            echo "Usage: $0 {install|test|config|backup|restore|help}"
            echo ""
            echo "Operations:"
            echo "  install    - Install Hyprland and create configuration (default)"
            echo "  test       - Test Hyprland installation"
            echo "  config     - Create default configuration"
            echo "  backup     - Backup existing configuration"
            echo "  restore    - Restore configuration from backup"
            echo "  help       - Show this help message"
            exit_code=$E_SUCCESS
            ;;
        *)
            log_error "Invalid operation: $operation"
            echo "Usage: $0 {install|test|config|backup|restore|help}"
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

