#!/bin/bash
# HyprSupreme-Builder - Warp Terminal Installation Module

readonly SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
readonly FUNCTIONS_PATH="${SCRIPT_DIR}/../common/functions.sh"

if [[ ! -f "${FUNCTIONS_PATH}" ]]; then
    echo "Error: Required functions file not found: ${FUNCTIONS_PATH}" >&2
    exit 1
fi

source "${FUNCTIONS_PATH}"

install_warp() {
    log_info "Installing Warp terminal and dependencies..."
    
    # Check if Warp is already installed
    if command -v warp-terminal &> /dev/null; then
        log_success "Warp terminal is already installed"
        configure_warp
        return 0
    fi
    
    # Install Warp terminal from AUR
    local packages=(
        "warp-terminal"
    )
    
    # Try to install with AUR helper
    if command -v wal &> /dev/null; then
        log_info "Installing Warp via yay..."
        yay -S --noconfirm warp-terminal || {
            log_error "Failed to install Warp via yay"
            fallback_warp_install
            return $?
        }
    elif command -v paru &> /dev/null; then
        log_info "Installing Warp via paru..."
        paru -S --noconfirm warp-terminal || {
            log_error "Failed to install Warp via paru"
            fallback_warp_install
            return $?
        }
    else
        log_warn "No AUR helper found, trying manual installation..."
        fallback_warp_install
        return $?
    fi
    
    configure_warp
    log_success "Warp terminal installation completed"
}

fallback_warp_install() {
    log_info "Attempting manual Warp installation..."
    
    # Create temporary directory
    local temp_dir="/tmp/warp-install-$$"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Download the latest Warp .deb package (if available) or use flatpak
    if command -v flatpak &> /dev/null; then
        log_info "Installing Warp via Flatpak..."
        flatpak install -y flathub dev.warp.Warp
        
        # Create symlink for easy access
        local local_bin="${HOME}/.local/bin"
        mkdir -p "$local_bin"
        cat > "$local_bin/warp-terminal" << 'EOF'
#!/bin/bash
exec flatpak run dev.warp.Warp "$@"
EOF
        chmod +x "$local_bin/warp-terminal"
        
    else
        log_error "Cannot install Warp terminal - no suitable package manager found"
        log_info "Please install Warp manually from: https://warp.dev"
        return 1
    fi
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
}

configure_warp() {
    log_info "Configuring Warp terminal..."
    
    # Create Warp config directory
    mkdir -p "$HOME/.warp"
    mkdir -p "$HOME/.config/warp-terminal"
    
    # Create Warp settings if they don't exist
    create_warp_settings
    
    # Update HyprSupreme configuration to use Warp
    update_hyprsupreme_config
    
    log_success "Warp terminal configuration completed"
}

create_warp_settings() {
    local settings_file="$HOME/.warp/user_preferences.json"
    
    if [ ! -f "$settings_file" ]; then
        log_info "Creating Warp user preferences..."
        
        cat > "$settings_file" << 'EOF'
{
  "appearance": {
    "theme": "base16_dark",
    "font_size": 13,
    "opacity": 0.95,
    "background_blur": true
  },
  "editor": {
    "vim_mode": false,
    "completion": true,
    "suggestions": true
  },
  "terminal": {
    "shell": "/bin/zsh",
    "working_directory": "home",
    "cursor_style": "block"
  },
  "features": {
    "ai_suggestions": true,
    "blocks": true,
    "workflows": true
  }
}
EOF
    fi
    
    # Create themes directory and add custom theme
    mkdir -p "$HOME/.warp/themes"
    
    local theme_file="$HOME/.warp/themes/hyprland_dark.yaml"
    cat > "$theme_file" << 'EOF'
name: "Hyprland Dark"
author: "HyprSupreme"
description: "Dark theme optimized for Hyprland"

background: "#1e1e2e"
foreground: "#cdd6f4"
details: "darker"
terminal_colors:
  normal:
    black: "#45475a"
    red: "#f38ba8"
    green: "#a6e3a1"
    yellow: "#f9e2af"
    blue: "#89b4fa"
    magenta: "#f5c2e7"
    cyan: "#94e2d5"
    white: "#bac2de"
  bright:
    black: "#585b70"
    red: "#f38ba8"
    green: "#a6e3a1"
    yellow: "#f9e2af"
    blue: "#89b4fa"
    magenta: "#f5c2e7"
    cyan: "#94e2d5"
    white: "#a6adc8"
EOF
}

update_hyprsupreme_config() {
    log_info "Updating HyprSupreme configuration for Warp terminal..."
    
    # Update the user defaults configuration
    local user_defaults="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"
    
    if [ -f "$user_defaults" ]; then
        # Backup the original
        cp "$user_defaults" "$user_defaults.backup-$(date +%Y%m%d-%H%M%S)"
        
        # Update terminal setting
        sed -i 's/\$term = .*/\$term = warp-terminal/' "$user_defaults"
        log_success "Updated terminal setting in user defaults"
    fi
    
    # Check if we need to update any other configuration files
    local hyprland_conf="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$hyprland_conf" ]; then
        # Update any direct kitty references in startup
        if grep -q "kitty" "$hyprland_conf"; then
            log_info "Found kitty references in hyprland.conf - these may need manual review"
        fi
    fi
}

# Test Warp installation
test_warp() {
    log_info "Testing Warp terminal installation..."
    
    if command -v warp-terminal &> /dev/null; then
        log_success "✅ Warp terminal is accessible via command line"
        
        # Test if it can launch (non-blocking)
        if timeout 5s warp-terminal --version &> /dev/null; then
            log_success "✅ Warp terminal launches successfully"
        else
            log_warn "⚠️  Warp terminal may have issues launching (this might be normal in headless environment)"
        fi
        
        return 0
    else
        log_error "❌ Warp terminal is not accessible"
        return 1
    fi
}

# Main execution
case "${1:-install}" in
    "install")
        install_warp
        ;;
    "configure")
        configure_warp
        ;;
    "test")
        test_warp
        ;;
    *)
        echo "Usage: $0 {install|configure|test}"
        exit 1
        ;;
esac

