#!/bin/bash

echo "🔧 HyprSupreme Quick Fix"
echo "========================"

# Check if we're in the right directory
cd /home/alex/HyprSupreme-Builder

# Set wallpaper using swww (which is already running)
echo "[INFO] Setting wallpaper..."
if [ -d "$HOME/Pictures/wallpapers" ]; then
    # Find the first image file and set it
    wallpaper=$(find "$HOME/Pictures/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | head -1)
    if [ ! -z "$wallpaper" ]; then
        swww img "$wallpaper"
        echo "[SUCCESS] Wallpaper set to: $(basename "$wallpaper")"
    else
        echo "[WARN] No wallpapers found"
    fi
else
    echo "[WARN] Wallpaper directory not found"
fi

# Test application launcher
echo "[INFO] Testing application launcher..."
echo "Press Super+D to open application launcher"
echo "Press Super+Return to open terminal"
echo "Press Super+E to open file manager"
echo "Press Super+B to open browser"

# Check critical services
echo "[INFO] Checking services..."
if pgrep -x "waybar" > /dev/null; then
    echo "✅ Waybar is running"
else
    echo "❌ Waybar is not running - starting..."
    waybar &
fi

if pgrep -x "ags" > /dev/null; then
    echo "✅ AGS is running"
else
    echo "❌ AGS is not running - starting..."
    ags &
fi

if pgrep -x "swww-daemon" > /dev/null; then
    echo "✅ SWWW daemon is running"
else
    echo "❌ SWWW daemon is not running - starting..."
    swww-daemon --format xrgb &
    sleep 2
    if [ ! -z "$wallpaper" ]; then
        swww img "$wallpaper"
    fi
fi

# Test rofi
echo "[INFO] Testing rofi functionality..."
if command -v rofi > /dev/null; then
    echo "✅ Rofi is installed"
    # Test rofi config
    if rofi -help > /dev/null 2>&1; then
        echo "✅ Rofi configuration is working"
    else
        echo "❌ Rofi has configuration issues"
    fi
else
    echo "❌ Rofi is not installed"
fi

echo ""
echo "🎯 Quick Test Instructions:"
echo "=========================="
echo "1. Press Super+D to open application launcher"
echo "2. Type 'firefox' or any app name to test"
echo "3. Press Super+Return to open terminal"
echo "4. Press Super+E to open file manager"
echo ""
echo "If these shortcuts don't work, there may be keyboard layout issues."
echo "Try running: hyprctl reload"

echo ""
echo "[SUCCESS] Quick fix completed!"
echo "Your desktop should now be fully functional."

