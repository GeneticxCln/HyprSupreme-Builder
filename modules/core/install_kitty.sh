#!/bin/bash

# HyprSupreme-Builder - Kitty Terminal Installation Module
# Enhanced with comprehensive error handling, backup/restore, and validation

# Error handling
set -o errexit
set -o pipefail
set -o nounset
set -o errtrace

# Error codes
readonly E_SUCCESS=0      # Success
readonly E_GENERAL=1      # General error
readonly E_DEPENDENCY=2   # Missing dependency
readonly E_INSTALL=3      # Installation error
readonly E_CONFIG=4       # Configuration error
readonly E_BACKUP=5       # Backup error
readonly E_RESTORE=6      # Restore error
readonly E_VALIDATION=7   # Validation error
readonly E_FILESYSTEM=8   # Filesystem error
readonly E_PERMISSIONS=9  # Permissions error
readonly E_FONT=10        # Font error
readonly E_TEST=11        # Test error
readonly E_TERMINAL=12    # Terminal capability error
readonly E_THEME=13       # Theme error

# Script variables
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
readonly LOG_FILE="${HOME}/.local/share/hyprsupreme/logs/kitty-${TIMESTAMP}.log"
readonly CONFIG_DIR="${HOME}/.config/kitty"
readonly BACKUP_DIR="${HOME}/.local/share/hyprsupreme/backups/kitty-${TIMESTAMP}"
readonly DEFAULT_FONT="JetBrainsMono Nerd Font"

# Command line options
OPT_VERBOSE=false
OPT_DEBUG=false
OPT_FORCE=false
OPT_TEST_ONLY=false
OPT_NO_BACKUP=false
OPT_CUSTOM_THEME=""

# Source common functions
source "${SCRIPT_DIR}/../common/functions.sh" || {
    echo "Error: Failed to source common functions."
    exit $E_GENERAL
}

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")" || {
    echo "Error: Failed to create log directory."
    exit $E_FILESYSTEM
}

# Initialize log
init_log() {
    echo "=== Kitty Terminal Installation Log - $(date) ===" > "$LOG_FILE"
    echo "Script: $SCRIPT_NAME" >> "$LOG_FILE"
    echo "User: $(whoami)" >> "$LOG_FILE"
    echo "System: $(uname -a)" >> "$LOG_FILE"
    echo "=================================================" >> "$LOG_FILE"
}

# Enhanced logging functions
log_debug() {
    if $OPT_DEBUG; then
        echo -e "[DEBUG] $*" | tee -a "$LOG_FILE"
    else
        echo -e "[DEBUG] $*" >> "$LOG_FILE"
    fi
}

log_info() {
    echo -e "[INFO] $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "\e[33m[WARNING] $*\e[0m" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "\e[31m[ERROR] $*\e[0m" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "\e[32m[SUCCESS] $*\e[0m" | tee -a "$LOG_FILE"
}

# Error handler
error_handler() {
    local line=$1
    local linecallfunc=$2
    local command="$3"
    local errorcode=$4
    
    if [[ $errorcode -ne 0 ]]; then
        log_error "Error occurred at line $line (called from line $linecallfunc): Command '$command' exited with status $errorcode"
        cleanup
        exit $errorcode
    fi
}

# Set up error handling
trap 'error_handler ${LINENO} ${BASH_LINENO[0]} "${BASH_COMMAND}" $?' ERR
trap cleanup EXIT
trap 'log_error "Script interrupted. Cleaning up..."; cleanup; exit $E_GENERAL' INT TERM

# Cleanup function
cleanup() {
    log_debug "Performing cleanup..."
    # Kill any background processes spawned by this script
    jobs -p | xargs -r kill &>/dev/null
    log_debug "Cleanup completed."
}

# Backup kitty configuration
backup_config() {
    if $OPT_NO_BACKUP; then
        log_warn "Skipping backup as requested."
        return 0
    fi

    log_info "Backing up existing Kitty configuration..."
    
    if [[ ! -d "$CONFIG_DIR" ]]; then
        log_info "No existing configuration found. Skipping backup."
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR" || {
        log_error "Failed to create backup directory: $BACKUP_DIR"
        return $E_BACKUP
    }
    
    if cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" 2>/dev/null; then
        log_success "Configuration backed up to $BACKUP_DIR"
    else
        if [[ -z "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]]; then
            log_info "Config directory exists but is empty. Nothing to backup."
            return 0
        else
            log_error "Failed to backup configuration."
            return $E_BACKUP
        fi
    fi
    
    # Save timestamp of backup for potential restoration
    echo "$TIMESTAMP" > "${BACKUP_DIR}/backup_timestamp"
    
    return 0
}

# Restore kitty configuration
restore_config() {
    local backup_to_restore="$1"
    
    if [[ -z "$backup_to_restore" ]]; then
        # Find most recent backup if none specified
        backup_to_restore=$(find "${HOME}/.local/share/hyprsupreme/backups" -maxdepth 1 -name "kitty-*" -type d | sort -r | head -n1)
    fi
    
    if [[ ! -d "$backup_to_restore" ]]; then
        log_error "Backup directory not found: $backup_to_restore"
        return $E_RESTORE
    fi
    
    log_info "Restoring Kitty configuration from $backup_to_restore..."
    
    # Ensure config directory exists
    mkdir -p "$CONFIG_DIR" || {
        log_error "Failed to create configuration directory: $CONFIG_DIR"
        return $E_FILESYSTEM
    }
    
    # Remove current configuration
    rm -rf "${CONFIG_DIR:?}/"* || {
        log_warn "Failed to remove current configuration. Continuing anyway."
    }
    
    # Copy backup files
    if cp -r "$backup_to_restore/"* "$CONFIG_DIR/" 2>/dev/null; then
        # Remove backup timestamp file from configuration
        rm -f "$CONFIG_DIR/backup_timestamp" 2>/dev/null
        
        log_success "Configuration restored from $backup_to_restore"
        return 0
    else
        log_error "Failed to restore configuration from $backup_to_restore"
        return $E_RESTORE
    fi
}

# Check for required dependencies
check_dependencies() {
    log_info "Checking for required dependencies..."
    
    local missing_deps=()
    local core_deps=("kitty" "fc-list" "convert" "python3")
    
    for dep in "${core_deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing_deps[*]}"
        
        # Try to map commands to package names
        local packages=()
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                kitty) packages+=("kitty") ;;
                fc-list) packages+=("fontconfig") ;;
                convert) packages+=("imagemagick") ;;
                python3) packages+=("python") ;;
                *) packages+=("$dep") ;;
            esac
        done
        
        log_info "Installing missing dependencies: ${packages[*]}"
        install_packages "${packages[@]}" || {
            log_error "Failed to install dependencies."
            return $E_DEPENDENCY
        }
    else
        log_success "All core dependencies are installed."
    fi
    
    return 0
}

# Validate kitty configuration
validate_config() {
    log_info "Validating Kitty configuration..."
    
    if [[ ! -f "$CONFIG_DIR/kitty.conf" ]]; then
        log_error "Kitty configuration file not found: $CONFIG_DIR/kitty.conf"
        return $E_VALIDATION
    }
    
    # Check for syntax errors in configuration
    if ! kitty -c "$CONFIG_DIR/kitty.conf" &>/dev/null; then
        log_error "Kitty configuration has syntax errors."
        return $E_VALIDATION
    fi
    
    # Check for essential settings
    local required_settings=("font_family" "background" "foreground")
    local missing_settings=()
    
    for setting in "${required_settings[@]}"; do
        if ! grep -q "^$setting " "$CONFIG_DIR/kitty.conf"; then
            missing_settings+=("$setting")
        fi
    done
    
    if [[ ${#missing_settings[@]} -gt 0 ]]; then
        log_warn "Missing essential settings in kitty.conf: ${missing_settings[*]}"
        log_info "Will use defaults for missing settings."
    fi
    
    # Check for font availability
    local font_family
    font_family=$(grep "^font_family" "$CONFIG_DIR/kitty.conf" | awk '{$1=""; print $0}' | xargs)
    
    if [[ -n "$font_family" ]]; then
        if ! fc-list | grep -q "$font_family"; then
            log_warn "Font '$font_family' not found on the system."
            log_info "Will attempt to install the font or fall back to a system font."
        else
            log_success "Font '$font_family' is available."
        fi
    fi
    
    log_success "Kitty configuration validated."
    return 0
}

# Check terminal capabilities
check_terminal_capabilities() {
    log_info "Checking terminal capabilities..."
    
    # Check if we're in a wayland session
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        log_success "Running in a Wayland session."
    else
        log_warn "Not running in a Wayland session. Kitty performs best under Wayland."
    fi
    
    # Check for GPU acceleration capability
    if command -v glxinfo &>/dev/null; then
        if glxinfo | grep -q "direct rendering: Yes"; then
            log_success "GPU acceleration is available."
        else
            log_warn "GPU acceleration may not be available. Kitty performance might be affected."
        fi
    else
        log_debug "glxinfo not found. Skipping GPU acceleration check."
    fi
    
    # Check color support
    if [[ "$TERM" == "xterm-kitty" ]]; then
        log_success "Running in a Kitty terminal with full color support."
    elif [[ "$COLORTERM" == "truecolor" || "$TERM" == *"-256color" ]]; then
        log_success "Terminal supports true color or 256 colors."
    else
        log_warn "Terminal may have limited color support. Kitty theme might not render correctly."
    fi
    
    return 0
}

# Verify fonts
verify_fonts() {
    log_info "Verifying font availability..."
    
    local font_found=false
    
    # Try to detect the configured font
    local configured_font
    if [[ -f "$CONFIG_DIR/kitty.conf" ]]; then
        configured_font=$(grep "^font_family" "$CONFIG_DIR/kitty.conf" | awk '{$1=""; print $0}' | xargs)
    fi
    
    # If no configured font, use default
    if [[ -z "$configured_font" ]]; then
        configured_font="$DEFAULT_FONT"
    fi
    
    # Check if the font is available
    if fc-list | grep -q "$configured_font"; then
        log_success "Required font '$configured_font' is installed."
        font_found=true
    else
        log_warn "Required font '$configured_font' is not installed."
        
        # Check for JetBrains Mono Nerd Font (our default)
        if fc-list | grep -q "JetBrainsMono Nerd Font"; then
            log_info "JetBrainsMono Nerd Font is available as a fallback."
            font_found=true
        # Check for any Nerd Font
        elif fc-list | grep -q "Nerd Font"; then
            local available_nerd_font
            available_nerd_font=$(fc-list | grep "Nerd Font" | head -n1 | awk -F: '{print $1}')
            log_info "Found alternative Nerd Font: $available_nerd_font"
            font_found=true
        fi
    fi
    
    if ! $font_found; then
        log_warn "No suitable fonts found. Will try to install Nerd Fonts."
        
        # Attempt to install nerd fonts
        if command -v paru &>/dev/null; then
            log_info "Installing ttf-jetbrains-mono-nerd using paru..."
            paru -S --noconfirm ttf-jetbrains-mono-nerd || {
                log_error "Failed to install fonts with paru."
                return $E_FONT
            }
        elif command -v yay &>/dev/null; then
            log_info "Installing ttf-jetbrains-mono-nerd using yay..."
            yay -S --noconfirm ttf-jetbrains-mono-nerd || {
                log_error "Failed to install fonts with yay."
                return $E_FONT
            }
        else
            log_error "Cannot install fonts: neither paru nor yay is available."
            return $E_FONT
        fi
        
        # Refresh font cache
        fc-cache -f || log_warn "Failed to refresh font cache."
        
        # Verify the font was installed
        if fc-list | grep -q "JetBrainsMono Nerd Font"; then
            log_success "Successfully installed JetBrainsMono Nerd Font."
        else
            log_error "Failed to install required font."
            return $E_FONT
        fi
    fi
    
    return 0
}

# Test kitty installation
test_kitty() {
    log_info "Testing Kitty installation..."
    
    # Check if kitty is installed
    if ! command -v kitty &>/dev/null; then
        log_error "Kitty is not installed."
        return $E_TEST
    fi
    
    # Check if kitty can start
    if ! kitty --version &>/dev/null; then
        log_error "Kitty failed to start."
        return $E_TEST
    fi
    
    # Test configuration
    if [[ -f "$CONFIG_DIR/kitty.conf" ]]; then
        if ! kitty -c "$CONFIG_DIR/kitty.conf" --debug-config &>/dev/null; then
            log_error "Kitty configuration test failed."
            return $E_TEST
        fi
    else
        log_warn "No configuration file found to test."
    fi
    
    log_success "Kitty installation tests passed."
    return 0
}

# Install kitty and dependencies
install_kitty() {
    log_info "Installing Kitty terminal and related packages..."
    
    # Kitty and dependencies
    local packages=(
        "kitty"
        "python-pillow"
        "imagemagick"
    )
    
    install_packages "${packages[@]}" || {
        log_error "Failed to install required packages."
        return $E_INSTALL
    }
    
    # Create kitty config directory
    mkdir -p "$CONFIG_DIR" || {
        log_error "Failed to create Kitty configuration directory."
        return $E_FILESYSTEM
    }
    
    # Create default kitty configuration
    create_default_kitty_config || {
        log_error "Failed to create default Kitty configuration."
        return $E_CONFIG
    }
    
    # Set up autostart if needed
    if $OPT_FORCE || ask_user "Would you like to configure Kitty to start with Hyprland?"; then
        setup_autostart || log_warn "Failed to set up autostart."
    fi
    
    log_success "Kitty installation completed successfully."
    return 0
}

setup_autostart() {
    log_info "Setting up Kitty autostart..."
    
    local hypr_autostart="${HOME}/.config/hypr/autostart.conf"
    
    # Create autostart directory if it doesn't exist
    mkdir -p "$(dirname "$hypr_autostart")" || {
        log_error "Failed to create Hyprland configuration directory."
        return $E_FILESYSTEM
    }
    
    # Check if autostart.conf exists
    if [[ ! -f "$hypr_autostart" ]]; then
        echo "# Hyprland Autostart Configuration" > "$hypr_autostart"
        echo "# Added by HyprSupreme-Builder" >> "$hypr_autostart"
        echo "" >> "$hypr_autostart"
    fi
    
    # Check if kitty is already in autostart
    if grep -q "^exec-once = kitty" "$hypr_autostart"; then
        log_info "Kitty autostart already configured."
    else
        echo "# Terminal" >> "$hypr_autostart"
        echo "exec-once = kitty" >> "$hypr_autostart"
        log_success "Added Kitty to Hyprland autostart."
    fi
    
    return 0
}

# Check kitty theme 
validate_theme() {
    local theme_name="$1"
    log_info "Validating theme: $theme_name"
    
    # Check for built-in themes
    local builtin_themes_dir="/usr/share/kitty/themes"
    if [[ -f "$builtin_themes_dir/$theme_name.conf" ]]; then
        log_success "Found built-in theme: $theme_name"
        return 0
    fi
    
    # Check for user themes
    local user_themes_dir="$CONFIG_DIR/themes"
    if [[ -f "$user_themes_dir/$theme_name.conf" ]]; then
        log_success "Found user theme: $theme_name"
        return 0
    fi
    
    # Check if it's a direct file path
    if [[ -f "$theme_name" ]]; then
        log_success "Found theme file: $theme_name"
        return 0
    fi
    
    log_error "Theme not found: $theme_name"
    return $E_THEME
}

# Install a custom theme
install_theme() {
    local theme_name="$1"
    
    if [[ -z "$theme_name" ]]; then
        log_info "No custom theme specified. Using default theme."
        return 0
    fi
    
    log_info "Installing custom theme: $theme_name"
    
    # Create themes directory
    local user_themes_dir="$CONFIG_DIR/themes"
    mkdir -p "$user_themes_dir" || {
        log_error "Failed to create themes directory."
        return $E_FILESYSTEM
    }
    
    # Check if theme exists
    if ! validate_theme "$theme_name"; then
        log_error "Invalid theme: $theme_name"
        return $E_THEME
    fi
    
    # Copy theme if it's a file path
    if [[ -f "$theme_name" ]]; then
        local theme_filename=$(basename "$theme_name")
        cp "$theme_name" "$user_themes_dir/$theme_filename" || {
            log_error "Failed to copy theme file."
            return $E_FILESYSTEM
        }
        theme_name="$theme_filename"
        log_success "Installed theme from file: $theme_name"
    fi
    
    # Update kitty.conf to include the theme
    local config_file="$CONFIG_DIR/kitty.conf"
    
    # Remove any existing include lines for themes
    sed -i '/^include.*theme/d' "$config_file" || {
        log_warn "Failed to clean up existing theme includes."
    }
    
    # Add the new theme
    if [[ -f "$user_themes_dir/$theme_name.conf" ]]; then
        echo "include themes/$theme_name.conf" >> "$config_file"
        log_success "Configured Kitty to use theme: $theme_name"
    elif [[ -f "/usr/share/kitty/themes/$theme_name.conf" ]]; then
        echo "include /usr/share/kitty/themes/$theme_name.conf" >> "$config_file"
        log_success "Configured Kitty to use built-in theme: $theme_name"
    else
        log_error "Failed to configure theme: $theme_name"
        return $E_THEME
    fi
    
    return 0
}

# Create default kitty configuration
create_default_kitty_config() {
    log_info "Creating default Kitty configuration..."
    
    local config_file="$CONFIG_DIR/kitty.conf"
    
    # Check if config file already exists and backup is needed
    if [[ -f "$config_file" && "$OPT_FORCE" != true ]]; then
        log_warn "Configuration file already exists: $config_file"
        if ! $OPT_NO_BACKUP; then
            backup_config || log_error "Failed to backup existing configuration."
        fi
        
        if ! ask_user "Would you like to overwrite the existing configuration?"; then
            log_info "Keeping existing configuration."
            return 0
        fi
    fi
    
    # Create main configuration
    cat > "$config_file" << 'EOF' || {
        log_error "Failed to write configuration file."
        return $E_FILESYSTEM
    }
# HyprSupreme Kitty Configuration
# Based on Catppuccin Mocha theme

# Font configuration
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size        12.0

# Cursor configuration
cursor_shape               block
cursor_beam_thickness      1.5
cursor_underline_thickness 2.0
cursor_blink_interval      0.5
cursor_stop_blinking_after 15.0

# Scrollback
scrollback_lines 2000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER
scrollback_pager_history_size 0
wheel_scroll_multiplier 5.0

# Mouse
mouse_hide_wait 3.0
url_color #89b4fa
url_style curly
open_url_modifiers kitty_mod
open_url_with default
url_prefixes http https file ftp
detect_urls yes

# Selection
copy_on_select no
strip_trailing_spaces never
select_by_word_characters @-./_~?&=%+#
click_interval -1.0
focus_follows_mouse no
pointer_shape_when_grabbed arrow

# Performance tuning
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Terminal bell
enable_audio_bell no
visual_bell_duration 0.0
window_alert_on_bell yes
bell_on_tab yes
command_on_bell none

# Window layout
remember_window_size  yes
initial_window_width  640
initial_window_height 400
enabled_layouts *
window_resize_step_cells 2
window_resize_step_lines 2
window_border_width 0.5pt
draw_minimal_borders yes
window_margin_width 0
single_window_margin_width -1
window_padding_width 8
placement_strategy center
active_border_color #89b4fa
inactive_border_color #6c7086
bell_border_color #f9e2af
inactive_text_alpha 1.0

# Tab bar
tab_bar_edge bottom
tab_bar_margin_width 0.0
tab_bar_style powerline
tab_powerline_style slanted
tab_bar_min_tabs 2
tab_switch_strategy previous
tab_fade 0.25 0.5 0.75 1
tab_separator " ┇"
tab_title_template "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}"
active_tab_title_template none
active_tab_foreground   #11111b
active_tab_background   #89b4fa
active_tab_font_style   bold-italic
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
inactive_tab_font_style normal

# Color scheme - Catppuccin Mocha
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc

# Cursor colors
cursor #f5e0dc
cursor_text_color #1e1e2e

# URL underline color when hovering with mouse
url_color #89b4fa

# Kitty window border colors
active_border_color #b4befe
inactive_border_color #6c7086
bell_border_color #f9e2af

# OS Window titlebar colors
wayland_titlebar_color system
macos_titlebar_color system

# Tab bar colors
active_tab_foreground   #11111b
active_tab_background   #89b4fa
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background      #11111b

# Colors for marks (marked text in the terminal)
mark1_foreground #1e1e2e
mark1_background #b4befe
mark2_foreground #1e1e2e
mark2_background #cba6f7
mark3_foreground #1e1e2e
mark3_background #74c7ec

# The 16 terminal colors

# normal
color0 #45475a
color1 #f38ba8
color2 #a6e3a1
color3 #f9e2af
color4 #89b4fa
color5 #f5c2e7
color6 #94e2d5
color7 #bac2de

# bright
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8

# Advanced settings
shell .
editor .
close_on_child_death no
allow_remote_control no
update_check_interval 24
startup_session none
clipboard_control write-clipboard write-primary
allow_hyperlinks yes
shell_integration enabled
term xterm-kitty

# Keybindings
kitty_mod ctrl+shift

# Window management
map kitty_mod+enter new_window
map kitty_mod+n new_os_window
map kitty_mod+w close_window
map kitty_mod+] next_window
map kitty_mod+[ previous_window
map kitty_mod+f move_window_forward
map kitty_mod+b move_window_backward
map kitty_mod+` move_window_to_top
map kitty_mod+r start_resizing_window
map kitty_mod+1 first_window
map kitty_mod+2 second_window
map kitty_mod+3 third_window
map kitty_mod+4 fourth_window
map kitty_mod+5 fifth_window
map kitty_mod+6 sixth_window
map kitty_mod+7 seventh_window
map kitty_mod+8 eighth_window
map kitty_mod+9 ninth_window
map kitty_mod+0 tenth_window

# Tab management
map kitty_mod+right next_tab
map kitty_mod+left  previous_tab
map kitty_mod+t     new_tab
map kitty_mod+q     close_tab
map kitty_mod+.     move_tab_forward
map kitty_mod+,     move_tab_backward
map kitty_mod+alt+t set_tab_title

# Layout management
map kitty_mod+l next_layout

# Font sizes
map kitty_mod+equal  change_font_size all +2.0
map kitty_mod+minus  change_font_size all -2.0
map kitty_mod+0      change_font_size all 0

# Select and act on visible text
map kitty_mod+e kitten hints
map kitty_mod+p>f kitten hints --type path --program -
map kitty_mod+p>shift+f kitten hints --type path
map kitty_mod+p>l kitten hints --type line --program -
map kitty_mod+p>w kitten hints --type word --program -
map kitty_mod+p>h kitten hints --type hash --program -
map kitty_mod+p>n kitten hints --type linenum

# Miscellaneous
map kitty_mod+f11    toggle_fullscreen
map kitty_mod+f10    toggle_maximized
map kitty_mod+u      kitten unicode_input
map kitty_mod+f2     edit_config_file
map kitty_mod+escape kitty_shell window

# Clipboard
map kitty_mod+c copy_to_clipboard
map kitty_mod+v paste_from_clipboard
map kitty_mod+s paste_from_selection
map shift+insert paste_from_selection
map kitty_mod+o pass_selection_to_program

# Scrolling
map kitty_mod+up        scroll_line_up
map kitty_mod+k         scroll_line_up
map kitty_mod+down      scroll_line_down
map kitty_mod+j         scroll_line_down
map kitty_mod+page_up   scroll_page_up
map kitty_mod+page_down scroll_page_down
map kitty_mod+home      scroll_home
map kitty_mod+end       scroll_end
map kitty_mod+h         show_scrollback
EOF
    
    log_success "Default Kitty configuration created"
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --verbose|-v)
                OPT_VERBOSE=true
                ;;
            --debug|-d)
                OPT_DEBUG=true
                OPT_VERBOSE=true
                set -x  # Enable bash debug mode
                ;;
            --force|-f)
                OPT_FORCE=true
                ;;
            --test-only|-t)
                OPT_TEST_ONLY=true
                ;;
            --no-backup|-n)
                OPT_NO_BACKUP=true
                ;;
            --theme=*)
                OPT_CUSTOM_THEME="${1#*=}"
                ;;
            --restore)
                if [[ -n "$2" && "$2" != -* ]]; then
                    restore_config "$2"
                    exit $?
                else
                    restore_config
                    exit $?
                fi
                ;;
            --uninstall)
                uninstall_kitty
                exit $?
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit $E_GENERAL
                ;;
        esac
        shift
    done
}

# Show help message
show_help() {
    cat << EOF
Kitty Terminal Installer for HyprSupreme

Usage: $SCRIPT_NAME [OPTIONS]

Options:
  -h, --help              Show this help message and exit
  -v, --verbose           Enable verbose output
  -d, --debug             Enable debug mode (implies --verbose)
  -f, --force             Force installation, overwriting existing configurations
  -t, --test-only         Only run tests, don't install anything
  -n, --no-backup         Don't backup existing configuration
  --theme=THEME           Install specific theme (name or file path)
  --restore [BACKUP_DIR]  Restore configuration from backup
  --uninstall             Uninstall Kitty terminal

Examples:
  $SCRIPT_NAME                    # Standard installation
  $SCRIPT_NAME --force            # Force reinstallation
  $SCRIPT_NAME --theme=Dracula    # Install with Dracula theme
  $SCRIPT_NAME --restore          # Restore latest backup
EOF
}

# Uninstall kitty
uninstall_kitty() {
    log_info "Uninstalling Kitty terminal..."
    
    if ! command -v kitty &>/dev/null; then
        log_warn "Kitty does not appear to be installed."
        
        if ask_user "Would you like to remove Kitty configuration files anyway?"; then
            rm -rf "$CONFIG_DIR" && log_success "Removed Kitty configuration."
            return 0
        else
            return 0
        fi
    fi
    
    # Backup before uninstalling if not disabled
    if ! $OPT_NO_BACKUP; then
        backup_config || log_warn "Failed to backup configuration before uninstalling."
    fi
    
    # Remove autostart entry
    local hypr_autostart="${HOME}/.config/hypr/autostart.conf"
    if [[ -f "$hypr_autostart" ]]; then
        sed -i '/^exec-once = kitty/d' "$hypr_autostart" && 
            log_success "Removed Kitty from Hyprland autostart."
    fi
    
    # Remove configuration
    if [[ -d "$CONFIG_DIR" ]]; then
        rm -rf "$CONFIG_DIR" && log_success "Removed Kitty configuration."
    fi
    
    # Uninstall package
    if ask_user "Would you like to remove the Kitty package from your system?"; then
        if is_package_installed "kitty"; then
            remove_packages "kitty" && log_success "Removed Kitty package."
        else
            log_warn "Kitty package is not installed through the package manager."
        fi
    fi
    
    log_success "Kitty uninstallation completed."
    return 0
}

# Main function
main() {
    init_log
    parse_args "$@"
    
    log_info "Starting Kitty terminal setup for HyprSupreme..."
    
    if $OPT_TEST_ONLY; then
        log_info "Running in test-only mode."
        test_kitty
        validate_config
        check_terminal_capabilities
        verify_fonts
        log_info "Tests completed."
        exit $?
    fi
    
    # Backup existing configuration
    if ! $OPT_NO_BACKUP; then
        backup_config || log_warn "Backup failed, but continuing with installation."
    fi
    
    # Check dependencies
    check_dependencies || {
        log_error "Failed to meet dependencies. Cannot continue."
        exit $E_DEPENDENCY
    }
    
    # Verify terminal capabilities
    check_terminal_capabilities || log_warn "Terminal capability check failed."
    
    # Verify fonts
    verify_fonts || log_warn "Font verification failed."
    
    # Install kitty
    install_kitty || {
        log_error "Kitty installation failed."
        exit $E_INSTALL
    }
    
    # Install custom theme if specified
    if [[ -n "$OPT_CUSTOM_THEME" ]]; then
        install_theme "$OPT_CUSTOM_THEME" || log_warn "Failed to install custom theme."
    fi
    
    # Validate configuration
    validate_config || log_warn "Configuration validation failed."
    
    # Test installation
    test_kitty || log_warn "Installation tests failed."
    
    log_success "Kitty setup completed successfully."
    
    # Provide usage hints
    cat << EOF

=== Kitty Terminal Setup Complete ===
You can now launch Kitty by running:
    kitty

Configuration is stored in:
    $CONFIG_DIR

Backups are stored in:
    $(dirname "$BACKUP_DIR")

To customize Kitty further, edit:
    $CONFIG_DIR/kitty.conf

For additional themes, visit:
    https://github.com/kovidgoyal/kitty-themes

To restore a backup, run:
    $SCRIPT_NAME --restore

Thank you for using HyprSupreme-Builder!
=======================================
EOF
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

