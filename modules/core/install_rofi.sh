#!/bin/bash
# HyprSupreme-Builder - Rofi Installation Module

source "$(dirname "$0")/../common/functions.sh"

# Validate sudo access before starting
validate_sudo_access "install_rofi.sh"

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

install_rofi() {
    log_info "Installing Rofi and related packages..."
    
    # Rofi and dependencies
    local packages=(
        "rofi-wayland"
        "rofi-calc"
        "rofi-emoji"
        "wtype"
    )
    
    install_packages "${packages[@]}"
    
    # Create rofi config directory
    mkdir -p "$HOME/.config/rofi"
    
    # Create default rofi configuration
    create_default_rofi_config
    
    log_success "Rofi installation completed"
}

create_default_rofi_config() {
    log_info "Creating default Rofi configuration..."
    
    local config_file="$HOME/.config/rofi/config.rasi"
    
    # Create main configuration
    cat > "$config_file" << 'EOF'
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

    # Create catppuccin theme
    local theme_file="$HOME/.config/rofi/catppuccin-mocha.rasi"
    
    cat > "$theme_file" << 'EOF'
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
    
    log_success "Default Rofi configuration created"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_rofi
fi

