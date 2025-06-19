#!/bin/bash
# HyprSupreme-Builder - Waybar Installation Module

source "$(dirname "$0")/../common/functions.sh"

# Validate sudo access before starting
validate_sudo_access "install_waybar.sh"

# Error handling
error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Check if common functions exist
FUNCTIONS_FILE="$(dirname "$0")/../common/functions.sh"
if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    error_exit "Common functions file not found: $FUNCTIONS_FILE"
fi

source "$FUNCTIONS_FILE"

install_waybar() {
    log_info "Installing Waybar and related packages..."
    
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
    
    install_packages "${packages[@]}"
    
    # Create waybar config directory
    mkdir -p "$HOME/.config/waybar"
    
    # Create default waybar configuration
    create_default_waybar_config
    
    log_success "Waybar installation completed"
}

create_default_waybar_config() {
    log_info "Creating default Waybar configuration..."
    
    local config_file="$HOME/.config/waybar/config.jsonc"
    local style_file="$HOME/.config/waybar/style.css"
    
    # Create main configuration
    cat > "$config_file" << 'EOF'
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
        "on-click": "kitty -e 'sudo pacman -Syu'",
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

    # Create style configuration
    cat > "$style_file" << 'EOF'
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
    
    log_success "Default Waybar configuration created"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_waybar
fi

