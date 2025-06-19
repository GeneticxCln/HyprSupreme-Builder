#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme-Builder - AGS (Aylur's GTK Shell) Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_ags() {
    log_info "Installing AGS (Aylur's GTK Shell)..."
    
    # AGS and dependencies
    local packages=(
        "ags"
        "gtk3"
        "gtk4"
        "gtk-layer-shell"
        "gobject-introspection"
        "upower"
        "networkmanager"
        "bluez"
        "nodejs"
        "npm"
        "typescript"
        "sass"
        "dart-sass"
    )
    
    install_packages "${packages[@]}"
    
    # Create AGS config directory
    mkdir -p "$HOME/.config/ags"
    
    # Install AGS configuration
    install_ags_config
    
    log_success "AGS installation completed"
}

install_ags_config() {
    log_info "Installing AGS configuration..."
    
    # Create main config file
    local config_file="$HOME/.config/ags/config.js"
    
    cat > "$config_file" << 'EOF'
// HyprSupreme AGS Configuration
// Based on End-4 and JaKooLit configurations

import App from 'resource:///com/github/Aylur/ags/app.js'
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'

// Import widgets
import Bar from './modules/bar/Bar.js'
import NotificationPopups from './modules/notifications/NotificationPopups.js'
import OSD from './modules/osd/OSD.js'
import PowerMenu from './modules/powermenu/PowerMenu.js'
import QuickSettings from './modules/quicksettings/QuickSettings.js'

// Styles
import './style/main.scss'

// Main configuration
App.config({
    style: './style/main.css',
    windows: [
        Bar(0), // Primary monitor
        NotificationPopups(0),
        OSD(),
        PowerMenu(),
        QuickSettings(),
    ],
})

export default App
EOF

    # Create directories for modules
    mkdir -p "$HOME/.config/ags/modules/"{bar,notifications,osd,powermenu,quicksettings}
    mkdir -p "$HOME/.config/ags/style"
    mkdir -p "$HOME/.config/ags/assets"

    # Create basic bar widget
    create_ags_bar
    
    # Create basic styling
    create_ags_styles
    
    # Create package.json for dependencies
    create_ags_package_json
    
    log_success "AGS configuration installed"
}

create_ags_bar() {
    log_info "Creating AGS bar widget..."
    
    local bar_file="$HOME/.config/ags/modules/bar/Bar.js"
    
    cat > "$bar_file" << 'EOF'
// AGS Bar Widget
import Widget from 'resource:///com/github/Aylur/ags/widget.js'
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js'
import Network from 'resource:///com/github/Aylur/ags/service/network.js'
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js'
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js'
import SystemTray from 'resource:///com/github/Aylur/ags/service/systemtray.js'

// Workspaces widget
const Workspaces = () => Widget.Box({
    class_name: 'workspaces',
    children: Hyprland.bind('workspaces').transform(ws => {
        return ws.map(({ id }) => Widget.Button({
            on_clicked: () => Hyprland.messageAsync(`dispatch workspace ${id}`),
            child: Widget.Label(`${id}`),
            class_name: Hyprland.active.workspace.bind('id').transform(i => {
                return `workspace-button ${i === id ? 'focused' : ''}`.trim()
            }),
        }))
    }),
})

// Clock widget
const Clock = () => Widget.Label({
    class_name: 'clock',
    setup: self => self.poll(1000, () =>
        Utils.execAsync(['date', '+%H:%M %b %e'])
            .then(date => self.label = date)),
})

// System tray
const SysTray = () => Widget.Box({
    children: SystemTray.bind('items').transform(items => {
        return items.map(item => Widget.Button({
            child: Widget.Icon({ icon: item.bind('icon') }),
            on_primary_click: (_, event) => item.activate(event),
            on_secondary_click: (_, event) => item.openMenu(event),
            tooltip_markup: item.bind('tooltip_markup'),
        }))
    }),
})

// Network indicator
const NetworkIndicator = () => Widget.Icon().hook(Network, self => {
    const icon = Network[Network.primary] || Network.wifi || Network.wired

    if (icon) {
        self.icon = icon.icon_name
        self.tooltip_text = icon.bind('speed').transform(s => `${s} Mbps`)
    }
})

// Audio indicator
const AudioIndicator = () => Widget.Icon().hook(Audio, self => {
    if (!Audio.speaker)
        return

    const vol = Audio.speaker.volume * 100
    const icon = [
        [101, 'overamplified'],
        [67, 'high'],
        [34, 'medium'],
        [1, 'low'],
        [0, 'muted'],
    ].find(([threshold]) => threshold <= vol)?.[1]

    self.icon = `audio-volume-${icon}-symbolic`
    self.tooltip_text = `Volume: ${Math.floor(vol)}%`
}, 'speaker-changed')

// Battery indicator
const BatteryIndicator = () => Widget.Icon({
    icon: Battery.bind('icon_name'),
    tooltip_text: Battery.bind('percent').transform(p => `Battery: ${p}%`),
    visible: Battery.bind('available'),
})

// Left widgets
const Left = () => Widget.Box({
    spacing: 8,
    children: [
        Workspaces(),
    ],
})

// Center widgets
const Center = () => Widget.Box({
    spacing: 8,
    children: [
        Clock(),
    ],
})

// Right widgets
const Right = () => Widget.Box({
    hpack: 'end',
    spacing: 8,
    children: [
        SysTray(),
        NetworkIndicator(),
        AudioIndicator(),
        BatteryIndicator(),
    ],
})

export default (monitor = 0) => Widget.Window({
    name: `bar-${monitor}`,
    class_name: 'bar',
    monitor,
    anchor: ['top', 'left', 'right'],
    exclusivity: 'exclusive',
    child: Widget.CenterBox({
        start_widget: Left(),
        center_widget: Center(),
        end_widget: Right(),
    }),
})
EOF

    log_success "AGS bar widget created"
}

create_ags_styles() {
    log_info "Creating AGS styles..."
    
    local style_file="$HOME/.config/ags/style/main.scss"
    
    cat > "$style_file" << 'EOF'
// HyprSupreme AGS Styles
// Catppuccin Mocha Theme

// Colors
$bg: #1e1e2e;
$bg-alt: #181825;
$fg: #cdd6f4;
$primary: #89b4fa;
$secondary: #f38ba8;
$accent: #a6e3a1;
$warning: #f9e2af;
$error: #f38ba8;
$surface: #313244;

// Spacing
$spacing: 8px;
$radius: 10px;

// Fonts
$font: "JetBrainsMono Nerd Font";

* {
    all: unset;
    font-family: $font;
    font-weight: bold;
    font-size: 14px;
}

// Bar styles
.bar {
    background-color: rgba($bg, 0.9);
    border-radius: $radius;
    margin: $spacing;
    padding: 0 $spacing;
    border: 2px solid $primary;
}

// Workspace styles
.workspaces {
    padding: $spacing/2;
    
    .workspace-button {
        padding: $spacing/2 $spacing;
        margin: 0 2px;
        border-radius: $radius/2;
        background-color: transparent;
        color: $fg;
        transition: all 200ms ease;
        
        &.focused {
            background-color: $primary;
            color: $bg;
        }
        
        &:hover {
            background-color: $surface;
        }
    }
}

// Clock styles
.clock {
    color: $accent;
    font-weight: bold;
    padding: $spacing/2;
}

// System tray styles
window {
    button {
        padding: $spacing/2;
        border-radius: $radius/2;
        
        &:hover {
            background-color: $surface;
        }
    }
    
    image {
        color: $fg;
        -gtk-icon-size: 16px;
    }
}

// Tooltips
tooltip {
    background-color: $bg-alt;
    border: 1px solid $primary;
    border-radius: $radius/2;
    padding: $spacing/2;
    color: $fg;
}

// Notifications
.notification-popup {
    background-color: $bg;
    border: 2px solid $primary;
    border-radius: $radius;
    padding: $spacing;
    margin: $spacing;
}

// Quick settings
.quick-settings {
    background-color: $bg;
    border: 2px solid $primary;
    border-radius: $radius;
    padding: $spacing;
    
    button {
        padding: $spacing;
        margin: $spacing/4;
        border-radius: $radius/2;
        background-color: $surface;
        
        &:hover {
            background-color: $primary;
            color: $bg;
        }
        
        &.active {
            background-color: $accent;
            color: $bg;
        }
    }
}

// Power menu
.power-menu {
    background-color: rgba($bg, 0.95);
    
    button {
        padding: $spacing * 2;
        margin: $spacing;
        border-radius: $radius;
        background-color: $surface;
        color: $fg;
        font-size: 16px;
        
        &:hover {
            background-color: $primary;
            color: $bg;
        }
        
        &.shutdown {
            background-color: $error;
            
            &:hover {
                background-color: darken($error, 10%);
            }
        }
    }
}
EOF

    log_success "AGS styles created"
}

create_ags_package_json() {
    log_info "Creating AGS package.json..."
    
    local package_file="$HOME/.config/ags/package.json"
    
    cat > "$package_file" << 'EOF'
{
  "name": "hyprsupreme-ags",
  "version": "1.0.0",
  "description": "HyprSupreme AGS Configuration",
  "main": "config.js",
  "scripts": {
    "build": "sass style/main.scss style/main.css",
    "watch": "sass --watch style/main.scss:style/main.css"
  },
  "dependencies": {
    "sass": "^1.69.0"
  },
  "author": "HyprSupreme-Builder",
  "license": "MIT"
}
EOF

    # Install npm dependencies
    if command -v npm &> /dev/null; then
        log_info "Installing AGS dependencies..."
        cd "$HOME/.config/ags" && npm install --silent 2>/dev/null || log_warn "Failed to install npm dependencies"
    fi

    log_success "AGS package.json created"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_ags
fi

