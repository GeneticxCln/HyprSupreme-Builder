#!/bin/bash
# HyprSupreme-Builder - Audio System Installation Module

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
    
    # Clean up any temporary resources if needed
    
    # Return the exit code
    return $exit_code
}

# Trap errors
trap 'handle_error $? "Script interrupted" "$BASH_SOURCE:$LINENO"' ERR
trap 'log_warn "Script received SIGINT - operation canceled"; exit $E_GENERAL' INT
trap 'log_warn "Script received SIGTERM - operation canceled"; exit $E_GENERAL' TERM

install_audio() {
    log_info "Installing audio system..."
    
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
    
    # Install PipeWire audio stack
    if ! install_pipewire; then
        log_error "Failed to install PipeWire audio stack"
        return $E_GENERAL
    fi
    
    # Install audio tools and utilities
    if ! install_audio_tools; then
        log_error "Failed to install audio tools"
        return $E_GENERAL
    fi
    
    # Configure audio integration
    if ! configure_audio_integration; then
        log_error "Failed to configure audio integration"
        return $E_GENERAL
    fi
    
    log_success "Audio system installation completed"
    return $E_SUCCESS
}

install_pipewire() {
    log_info "Installing PipeWire audio stack..."
    
    local packages=(
        # Core PipeWire
        "pipewire"
        "pipewire-alsa"
        "pipewire-pulse"
        "pipewire-jack"
        
        # Audio/Video management
        "wireplumber"
        "pipewire-audio"
        
        # Session manager
        "pipewire-media-session"
        
        # Utils
        "pipewire-docs"
        "gst-plugin-pipewire"
        
        # Bluetooth support
        "pipewire-zeroconf"
        "libldac"
        "bluez"
        "bluez-utils"
        "bluez-plugins"
    )
    
    # Install packages with error handling
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install PipeWire packages"
        return $E_DEPENDENCY
    fi
    
    # Verify installation
    if ! command -v pipewire &> /dev/null; then
        log_error "PipeWire installation failed: pipewire command not found"
        return $E_DEPENDENCY
    fi
    
    log_info "Enabling PipeWire services..."
    
    # Check if systemd user instance is available
    if ! systemctl --user status &> /dev/null; then
        log_error "Systemd user instance not available"
        return $E_SERVICE
    fi
    
    # Enable and start PipeWire services with error handling
    if ! systemctl --user enable pipewire.socket &> /dev/null; then
        log_warn "Failed to enable pipewire.socket, trying to continue..."
    fi
    
    if ! systemctl --user enable pipewire-pulse.socket &> /dev/null; then
        log_warn "Failed to enable pipewire-pulse.socket, trying to continue..."
    fi
    
    if ! systemctl --user enable wireplumber.service &> /dev/null; then
        log_warn "Failed to enable wireplumber.service, trying to continue..."
    fi
    
    # Verify services are enabled
    local error_count=0
    systemctl --user is-enabled pipewire.socket &> /dev/null || ((error_count++))
    systemctl --user is-enabled pipewire-pulse.socket &> /dev/null || ((error_count++))
    systemctl --user is-enabled wireplumber.service &> /dev/null || ((error_count++))
    
    if [[ $error_count -gt 0 ]]; then
        log_warn "Some PipeWire services could not be enabled ($error_count errors)"
    fi
    
    log_success "PipeWire installation completed"
    return $E_SUCCESS
}

install_audio_tools() {
    log_info "Installing audio tools and utilities..."
    
    local basic_tools=(
        # Volume control
        "pavucontrol"
        "pulsemixer"
        "alsa-utils"
        
        # Audio information
        "alsa-tools"
        "alsa-firmware"
        
        # Codecs
        "ffmpeg"
        "gstreamer"
        "gst-plugins-base"
        "gst-plugins-good"
        "gst-plugins-bad"
        "gst-plugins-ugly"
        "gst-libav"
    )
    
    local advanced_tools=(
        # Advanced audio processing
        "easyeffects"
        "noise-suppression-for-voice"
        
        # Audio production
        "qpwgraph"
        "helvum"
        
        # Media players
        "mpv"
        "vlc"
        
        # Audio utilities
        "playerctl"
        "pamixer"
    )
    
    # Install basic tools with error handling
    log_info "Installing basic audio tools..."
    if ! install_packages "${basic_tools[@]}"; then
        log_error "Failed to install basic audio tools"
        return $E_DEPENDENCY
    fi
    
    # Verify critical tools are installed
    if ! command -v pamixer &> /dev/null || ! command -v pavucontrol &> /dev/null; then
        log_error "Critical audio tools (pamixer, pavucontrol) installation failed"
        return $E_DEPENDENCY
    fi
    
    # Ask for advanced tools if whiptail is available
    if command -v whiptail &> /dev/null; then
        if whiptail --yesno "Install advanced audio tools (EasyEffects, qpwgraph, audio production tools)?" 10 70; then
            log_info "Installing advanced audio tools..."
            if ! install_packages "${advanced_tools[@]}"; then
                log_warn "Some advanced audio tools could not be installed"
                # Continue anyway as these are optional
            else
                log_info "Advanced audio tools installed"
            fi
        fi
    else
        log_warn "whiptail not found, skipping advanced tools selection"
    fi
    
    log_success "Audio tools installation completed"
    return $E_SUCCESS
}

configure_audio_integration() {
    log_info "Configuring audio integration..."
    
    # Create audio scripts directory with error handling
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
    
    # Create audio control script
    if ! create_audio_control_script; then
        log_error "Failed to create audio control script"
        return $E_CONFIG
    fi
    
    # Create audio device manager script
    if ! create_audio_device_script; then
        log_error "Failed to create audio device manager script"
        return $E_CONFIG
    fi
    
    # Create media control script
    if ! create_media_control_script; then
        log_error "Failed to create media control script"
        return $E_CONFIG
    fi
    
    # Configure PipeWire
    if ! configure_pipewire; then
        log_error "Failed to configure PipeWire"
        return $E_CONFIG
    fi
    
    log_success "Audio integration configured"
    return $E_SUCCESS
}

create_audio_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/audio-control.sh"
    
    log_info "Creating audio control script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
#!/bin/bash
# Audio Control Script for HyprSupreme

show_volume_menu() {
    local menu="🔊 Volume Control
🎛️ Audio Mixer (PulseAudio)
🎚️ Terminal Mixer
🔧 Audio Effects
📊 Audio Graph
🎵 Audio Devices"
    
    local selection=$(echo "$menu" | rofi -dmenu -p "Audio Control" -theme-str 'window {width: 40%;}')
    
    case "$selection" in
        *"Volume Control"*)
            pavucontrol
            ;;
        *"Audio Mixer"*)
            warp-terminal -e pulsemixer
            ;;
        *"Terminal Mixer"*)
            warp-terminal -e alsamixer
            ;;
        *"Audio Effects"*)
            if command -v easyeffects &> /dev/null; then
                easyeffects
            else
                notify-send "Audio" "EasyEffects not installed"
            fi
            ;;
        *"Audio Graph"*)
            if command -v qpwgraph &> /dev/null; then
                qpwgraph
            elif command -v helvum &> /dev/null; then
                helvum
            else
                notify-send "Audio" "No audio graph tool installed"
            fi
            ;;
        *"Audio Devices"*)
            "$HOME/.config/hypr/scripts/audio-devices.sh"
            ;;
    esac
}

# Volume control functions
volume_up() {
    pamixer -i 5
    show_volume_notification
}

volume_down() {
    pamixer -d 5
    show_volume_notification
}

volume_mute() {
    pamixer -t
    show_volume_notification
}

show_volume_notification() {
    local volume=$(pamixer --get-volume)
    local muted=$(pamixer --get-mute)
    
    if [ "$muted" = "true" ]; then
        notify-send "Audio" "Volume: Muted" --icon=audio-volume-muted
    else
        notify-send "Audio" "Volume: ${volume}%" --icon=audio-volume-high --hint=int:value:$volume
    fi
}

case "$1" in
    "menu")
        show_volume_menu
        ;;
    "up")
        volume_up
        ;;
    "down")
        volume_down
        ;;
    "mute")
        volume_mute
        ;;
    *)
        echo "Usage: $0 {menu|up|down|mute}"
        exit 1
        ;;
esac
EOF
    then
        log_error "Failed to write audio control script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make audio control script executable"
        return $E_PERMISSION
    fi
    
    log_info "Audio control script created successfully"
    return $E_SUCCESS
}

create_audio_device_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/audio-devices.sh"
    
    log_info "Creating audio device manager script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
#!/bin/bash
# Audio Device Manager for HyprSupreme

# Get available audio devices
get_audio_devices() {
    pactl list short sinks | while read -r line; do
        local id=$(echo "$line" | cut -f1)
        local name=$(echo "$line" | cut -f2)
        local description=$(pactl list sinks | grep -A 10 "Sink #$id" | grep "Description:" | cut -d' ' -f2-)
        echo "$id|$name|$description"
    done
}

# Show device selection menu
show_device_menu() {
    local devices=""
    local current_sink=$(pactl get-default-sink)
    
    while IFS='|' read -r id name description; do
        local indicator=""
        if [ "$name" = "$current_sink" ]; then
            indicator="✓ "
        fi
        devices+="${indicator}${description} (${name})\n"
    done < <(get_audio_devices)
    
    local selected=$(echo -e "$devices" | rofi -dmenu -p "Audio Output Device" -theme-str 'window {width: 50%;}')
    
    if [ -n "$selected" ]; then
        # Extract device name from selection
        local device_name=$(echo "$selected" | grep -o '([^)]*)' | tr -d '()')
        pactl set-default-sink "$device_name"
        notify-send "Audio" "Switched to: $(echo "$selected" | sed 's/✓ //' | sed 's/ (.*//')"
    fi
}

# Test audio on current device
test_audio() {
    notify-send "Audio Test" "Playing test sound..."
    speaker-test -t sine -f 1000 -l 1 &
    local test_pid=$!
    sleep 2
    kill $test_pid 2> /dev/null
    notify-send "Audio Test" "Test completed"
}

case "$1" in
    "menu")
        show_device_menu
        ;;
    "test")
        test_audio
        ;;
    *)
        echo "Usage: $0 {menu|test}"
        exit 1
        ;;
esac
EOF
    then
        log_error "Failed to write audio device manager script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make audio device manager script executable"
        return $E_PERMISSION
    fi
    
    log_info "Audio device manager script created successfully"
    return $E_SUCCESS
}

create_media_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    local script_file="$scripts_dir/media-control.sh"
    
    log_info "Creating media control script..."
    
    # Check if file exists and is writable
    if [[ -f "$script_file" && ! -w "$script_file" ]]; then
        log_error "Cannot write to existing file: $script_file"
        return $E_PERMISSION
    fi
    
    # Create the script with error handling
    if ! cat > "$script_file" << 'EOF'
#!/bin/bash
# Media Control Script for HyprSupreme

# Get current media info
get_media_info() {
    local player_status=$(playerctl status 2> /dev/null)
    local player_name=$(playerctl metadata --format "{{ playerName }}" 2> /dev/null)
    local title=$(playerctl metadata --format "{{ title }}" 2> /dev/null)
    local artist=$(playerctl metadata --format "{{ artist }}" 2> /dev/null)
    
    if [ -n "$title" ]; then
        echo "${player_name}: ${artist} - ${title} [${player_status}]"
    else
        echo "No media playing"
    fi
}

# Show media info notification
show_media_info() {
    local info=$(get_media_info)
    notify-send "Media Player" "$info" --icon=multimedia-player
}

# Media control functions
media_play_pause() {
    playerctl play-pause
    show_media_info
}

media_next() {
    playerctl next
    sleep 0.5
    show_media_info
}

media_previous() {
    playerctl previous
    sleep 0.5
    show_media_info
}

media_stop() {
    playerctl stop
    notify-send "Media Player" "Stopped" --icon=media-playback-stop
}

case "$1" in
    "play-pause"|"toggle")
        media_play_pause
        ;;
    "next")
        media_next
        ;;
    "previous"|"prev")
        media_previous
        ;;
    "stop")
        media_stop
        ;;
    "info")
        show_media_info
        ;;
    *)
        echo "Usage: $0 {play-pause|next|previous|stop|info}"
        exit 1
        ;;
esac
EOF
    then
        log_error "Failed to write media control script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$script_file" 2>/dev/null; then
        log_error "Failed to make media control script executable"
        return $E_PERMISSION
    fi
    
    log_info "Media control script created successfully"
    return $E_SUCCESS
}

configure_pipewire() {
    log_info "Configuring PipeWire..."
    
    # Create PipeWire config directories with error handling
    local pipewire_dir="$HOME/.config/pipewire"
    local wireplumber_dir="$HOME/.config/wireplumber"
    local config_file="$pipewire_dir/pipewire.conf"
    
    # Create PipeWire config directory
    if [[ ! -d "$pipewire_dir" ]]; then
        if ! mkdir -p "$pipewire_dir" 2>/dev/null; then
            log_error "Failed to create PipeWire config directory: $pipewire_dir"
            return $E_DIRECTORY
        fi
    fi
    
    # Create WirePlumber config directory
    if [[ ! -d "$wireplumber_dir" ]]; then
        if ! mkdir -p "$wireplumber_dir" 2>/dev/null; then
            log_error "Failed to create WirePlumber config directory: $wireplumber_dir"
            return $E_DIRECTORY
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$pipewire_dir" ]]; then
        log_error "No write permission for PipeWire config directory: $pipewire_dir"
        return $E_PERMISSION
    fi
    
    # Create basic PipeWire configuration with error handling
    log_info "Creating PipeWire configuration..."
    
    if ! cat > "$config_file" << 'EOF'
# PipeWire Configuration for HyprSupreme
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 1024
    default.clock.min-quantum = 32
    default.clock.max-quantum = 2048
    default.clock.quantum-limit = 8192
}

context.modules = [
    { name = libpipewire-module-rtkit
        args = {
            nice.level   = -11
            rt.prio      = 88
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-profiler }
    { name = libpipewire-module-metadata }
    { name = libpipewire-module-spa-device-factory }
    { name = libpipewire-module-spa-node-factory }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-client-device }
    { name = libpipewire-module-portal
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-access
        args = {
            access.allowed = [
                "uid:0",
                "gid:audio",
                "uid:1000"
            ]
        }
    }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-link-factory }
    { name = libpipewire-module-session-manager }
]
EOF
    then
        log_error "Failed to write PipeWire configuration"
        return $E_CONFIG
    fi
    
    # Create audio restart script
    local scripts_dir="$HOME/.config/hypr/scripts"
    local restart_script="$scripts_dir/audio-restart.sh"
    
    log_info "Creating audio restart script..."
    
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
# Audio System Restart Script for HyprSupreme

restart_audio() {
    notify-send "Audio" "Restarting audio system..."
    
    # Stop services
    systemctl --user stop pipewire.socket
    systemctl --user stop pipewire-pulse.socket
    systemctl --user stop wireplumber.service
    systemctl --user stop pipewire.service
    
    sleep 2
    
    # Start services
    systemctl --user start pipewire.socket
    systemctl --user start pipewire-pulse.socket
    systemctl --user start wireplumber.service
    
    sleep 3
    
    notify-send "Audio" "Audio system restarted"
}

case "$1" in
    "restart")
        restart_audio
        ;;
    *)
        restart_audio
        ;;
esac
EOF
    then
        log_error "Failed to write audio restart script"
        return $E_CONFIG
    fi
    
    # Make script executable
    if ! chmod +x "$restart_script" 2>/dev/null; then
        log_error "Failed to make audio restart script executable"
        return $E_PERMISSION
    fi
    
    log_success "PipeWire configuration completed"
    return $E_SUCCESS
}

# Test audio installation
test_audio() {
    log_info "Testing audio system..."
    local errors=0
    local warnings=0
    
    # Check PipeWire installation
    if command -v pipewire &> /dev/null; then
        log_success "✅ PipeWire is installed"
    else
        log_error "❌ PipeWire not found"
        ((errors++))
    fi
    
    # Check audio controls
    if command -v pamixer &> /dev/null; then
        log_success "✅ Audio control tools available"
    else
        log_error "❌ Audio control tools not found"
        ((errors++))
    fi
    
    # Check volume control GUI
    if command -v pavucontrol &> /dev/null; then
        log_success "✅ Volume control GUI available"
    else
        log_warn "⚠️  Volume control GUI not found"
        ((warnings++))
    fi
    
    # Test audio functionality
    if pgrep -x "pipewire" > /dev/null; then
        log_success "✅ PipeWire is running"
        
        # Check if PipeWire services are active
        if systemctl --user is-active pipewire.service &>/dev/null; then
            log_success "✅ PipeWire service is active"
        else
            log_warn "⚠️  PipeWire service is not active"
            ((warnings++))
        fi
        
        # Check for audio devices
        if pactl list sinks &>/dev/null && [[ $(pactl list sinks | grep -c "Sink") -gt 0 ]]; then
            log_success "✅ Audio output devices detected"
        else
            log_warn "⚠️  No audio output devices detected"
            ((warnings++))
        fi
    else
        log_warn "⚠️  PipeWire not running (normal if not in graphical environment)"
        ((warnings++))
    fi
    
    # Check script files
    local scripts_dir="$HOME/.config/hypr/scripts"
    local required_scripts=("audio-control.sh" "audio-devices.sh" "media-control.sh" "audio-restart.sh")
    
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
    
    # Check PipeWire configuration
    if [[ -f "$HOME/.config/pipewire/pipewire.conf" ]]; then
        log_success "✅ PipeWire configuration exists"
    else
        log_warn "⚠️  PipeWire configuration is missing"
        ((warnings++))
    fi
    
    # Report summary
    if [[ $errors -gt 0 ]]; then
        log_error "Audio system test completed with $errors errors and $warnings warnings"
        return $E_GENERAL
    elif [[ $warnings -gt 0 ]]; then
        log_warn "Audio system test completed with $warnings warnings"
        return $E_SUCCESS
    else
        log_success "Audio system test completed successfully"
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
            install_audio
            exit_code=$?
            ;;
        "pipewire")
            install_pipewire
            exit_code=$?
            ;;
        "tools")
            install_audio_tools
            exit_code=$?
            ;;
        "configure")
            configure_audio_integration
            exit_code=$?
            ;;
        "test")
            test_audio
            exit_code=$?
            ;;
        "help")
            echo "Usage: $0 {install|pipewire|tools|configure|test|help}"
            echo ""
            echo "Operations:"
            echo "  install    - Install the complete audio system (default)"
            echo "  pipewire   - Install only PipeWire audio stack"
            echo "  tools      - Install audio tools and utilities"
            echo "  configure  - Configure audio integration"
            echo "  test       - Test audio installation"
            echo "  help       - Show this help message"
            exit_code=$E_SUCCESS
            ;;
        *)
            log_error "Invalid operation: $operation"
            echo "Usage: $0 {install|pipewire|tools|configure|test|help}"
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

