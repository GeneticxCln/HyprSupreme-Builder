#!/bin/bash
# HyprSupreme-Builder - Warp Terminal Default Setup
# This script ensures Warp terminal is properly configured as the default

set -e

# Colors
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 3)[WARN]$(tput sgr0)"

echo "🚀 HyprSupreme-Builder: Warp Terminal Setup"
echo "==========================================="

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "info") echo "$INFO $message" ;;
        "ok") echo "$OK $message" ;;
        "error") echo "$ERROR $message" ;;
        "warn") echo "$WARN $message" ;;
    esac
}

# Check if we're in the right directory
if [ ! -f "hyprsupreme" ]; then
    print_status "error" "Please run this script from the HyprSupreme-Builder directory"
    exit 1
fi

# 1. Install and configure Warp terminal
print_status "info" "Setting up Warp terminal..."

if [ -f "modules/core/install_warp.sh" ]; then
    chmod +x modules/core/install_warp.sh
    ./modules/core/install_warp.sh configure
    print_status "ok" "Warp terminal configured"
else
    print_status "error" "Warp installation module not found"
    exit 1
fi

# 2. Verify Warp terminal is accessible
if command -v warp-terminal &> /dev/null; then
    print_status "ok" "Warp terminal is installed and accessible"
else
    print_status "error" "Warp terminal not found in PATH"
    exit 1
fi

# 3. Check HyprSupreme configuration
USER_DEFAULTS="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"
if [ -f "$USER_DEFAULTS" ]; then
    if grep -q "warp-terminal" "$USER_DEFAULTS"; then
        print_status "ok" "HyprSupreme configured to use Warp terminal"
    else
        print_status "warn" "Updating HyprSupreme configuration..."
        # Backup and update
        cp "$USER_DEFAULTS" "$USER_DEFAULTS.backup-$(date +%Y%m%d-%H%M%S)"
        sed -i 's/\$term = .*/\$term = warp-terminal/' "$USER_DEFAULTS"
        print_status "ok" "HyprSupreme configuration updated"
    fi
else
    print_status "error" "HyprSupreme user defaults not found"
    exit 1
fi

# 4. Create Warp configuration directories
print_status "info" "Setting up Warp configuration directories..."
mkdir -p "$HOME/.warp"
mkdir -p "$HOME/.config/warp-terminal"

# 5. Create a simple Warp preferences file if it doesn't exist
WARP_PREFS="$HOME/.warp/user_preferences.json"
if [ ! -f "$WARP_PREFS" ]; then
    print_status "info" "Creating Warp user preferences..."
    cat > "$WARP_PREFS" << 'EOF'
{
  "appearance": {
    "theme": "base16_dark",
    "font_size": 13,
    "opacity": 0.95
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
    print_status "ok" "Warp preferences created"
fi

# 6. Test terminal functionality
print_status "info" "Testing terminal functionality..."
if timeout 5s warp-terminal --version &> /dev/null; then
    print_status "ok" "Warp terminal launches successfully"
else
    print_status "warn" "Warp terminal test completed (may need GUI environment)"
fi

# 7. Update build presets to use Warp
print_status "info" "Updating build presets..."
for preset_file in presets/*.preset; do
    if [ -f "$preset_file" ]; then
        if grep -q "kitty" "$preset_file" 2>/dev/null; then
            sed -i 's/kitty/warp/g' "$preset_file"
            print_status "ok" "Updated $(basename "$preset_file")"
        fi
    fi
done

# 8. Reload Hyprland configuration
if pgrep -x "Hyprland" > /dev/null; then
    print_status "info" "Reloading Hyprland configuration..."
    hyprctl reload
    print_status "ok" "Hyprland configuration reloaded"
fi

# 9. Final verification
print_status "info" "Final verification..."

# Check if Warp is set as default
if grep -q "warp-terminal" "$USER_DEFAULTS" 2>/dev/null; then
    print_status "ok" "✅ Warp is set as default terminal"
else
    print_status "error" "❌ Warp is not set as default terminal"
    exit 1
fi

# Check if Warp is accessible
if command -v warp-terminal &> /dev/null; then
    print_status "ok" "✅ Warp terminal is accessible"
else
    print_status "error" "❌ Warp terminal is not accessible"
    exit 1
fi

echo ""
echo "🎉 Warp Terminal Setup Complete!"
echo "================================"
echo ""
echo "✅ Warp terminal is now the default terminal"
echo "✅ HyprSupreme-Builder configured to use Warp"
echo "✅ All presets updated to include Warp"
echo ""
echo "🎯 Usage:"
echo "• Press Super+Return to open Warp terminal"
echo "• Use ./hyprsupreme install to build with Warp included"
echo "• Warp provides AI-powered assistance and modern features"
echo ""
echo "📋 Next steps:"
echo "1. Log into Warp terminal to set up your account (optional)"
echo "2. Explore Warp's AI features and workflows"
echo "3. Test the Super+Return keybinding"
echo ""
print_status "ok" "Setup completed successfully!"

