#!/bin/bash
# HyprSupreme-Builder - Audio System Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_audio() {
    log_info "Installing audio system..."
    
    # Install PipeWire audio stack
    install_pipewire
    
    # Install audio tools and utilities
    install_audio_tools
    
    # Configure audio integration
    configure_audio_integration
    
    log_success "Audio system installation completed"
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
    
    install_packages "${packages[@]}"
    
    # Enable and start PipeWire services
    systemctl --user enable pipewire.socket
    systemctl --user enable pipewire-pulse.socket
    systemctl --user enable wireplumber.service
    
    log_success "PipeWire installation completed"
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
    
    # Install basic tools
    install_packages "${basic_tools[@]}"
    
    # Ask for advanced tools
    if whiptail --yesno "Install advanced audio tools (EasyEffects, qpwgraph, audio production tools)?" 10 70; then
        install_packages "${advanced_tools[@]}"
        log_info "Advanced audio tools installed"
    fi
    
    log_success "Audio tools installation completed"
}

configure_audio_integration() {
    log_info "Configuring audio integration..."
    
    # Create audio scripts directory
    local scripts_dir="$HOME/.config/hypr/scripts"
    mkdir -p "$scripts_dir"
    
    # Create audio control script
    create_audio_control_script
    
    # Create audio device manager script
    create_audio_device_script
    
    # Create media control script
    create_media_control_script
    
    # Configure PipeWire
    configure_pipewire
    
    log_success "Audio integration configured"
}

create_audio_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/audio-control.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/audio-control.sh"
}

create_audio_device_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/audio-devices.sh" << 'EOF'
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
    kill $test_pid 2>/dev/null
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
    
    chmod +x "$scripts_dir/audio-devices.sh"
}

create_media_control_script() {
    local scripts_dir="$HOME/.config/hypr/scripts"
    
    cat > "$scripts_dir/media-control.sh" << 'EOF'
#!/bin/bash
# Media Control Script for HyprSupreme

# Get current media info
get_media_info() {
    local player_status=$(playerctl status 2>/dev/null)
    local player_name=$(playerctl metadata --format "{{ playerName }}" 2>/dev/null)
    local title=$(playerctl metadata --format "{{ title }}" 2>/dev/null)
    local artist=$(playerctl metadata --format "{{ artist }}" 2>/dev/null)
    
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
    
    chmod +x "$scripts_dir/media-control.sh"
}

configure_pipewire() {
    log_info "Configuring PipeWire..."
    
    # Create PipeWire config directory
    mkdir -p "$HOME/.config/pipewire"
    mkdir -p "$HOME/.config/wireplumber"
    
    # Create basic PipeWire configuration
    cat > "$HOME/.config/pipewire/pipewire.conf" << 'EOF'
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
    
    # Create audio restart script
    local scripts_dir="$HOME/.config/hypr/scripts"
    cat > "$scripts_dir/audio-restart.sh" << 'EOF'
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
    
    chmod +x "$scripts_dir/audio-restart.sh"
    
    log_success "PipeWire configuration completed"
}

# Test audio installation
test_audio() {
    log_info "Testing audio system..."
    
    # Check PipeWire
    if command -v pipewire &> /dev/null; then
        log_success "✅ PipeWire is installed"
    else
        log_error "❌ PipeWire not found"
        return 1
    fi
    
    # Check audio controls
    if command -v pamixer &> /dev/null; then
        log_success "✅ Audio control tools available"
    else
        log_error "❌ Audio control tools not found"
        return 1
    fi
    
    # Check volume control GUI
    if command -v pavucontrol &> /dev/null; then
        log_success "✅ Volume control GUI available"
    else
        log_warn "⚠️  Volume control GUI not found"
    fi
    
    # Test audio functionality
    if pgrep -x "pipewire" > /dev/null; then
        log_success "✅ PipeWire is running"
    else
        log_warn "⚠️  PipeWire not running (normal if not in graphical environment)"
    fi
    
    return 0
}

# Main execution
case "${1:-install}" in
    "install")
        install_audio
        ;;
    "pipewire")
        install_pipewire
        ;;
    "tools")
        install_audio_tools
        ;;
    "configure")
        configure_audio_integration
        ;;
    "test")
        test_audio
        ;;
    *)
        echo "Usage: $0 {install|pipewire|tools|configure|test}"
        exit 1
        ;;
esac

