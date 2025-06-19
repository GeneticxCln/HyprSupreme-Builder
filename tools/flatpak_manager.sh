#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme Flatpak Manager
# Comprehensive Flatpak integration and optimization for perfect app compatibility

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
FLATPAK_CONFIG_DIR="$HOME/.local/share/flatpak"
HYPR_CONFIG_DIR="$HOME/.config/hypr"
FLATPAK_OVERRIDES_DIR="$HOME/.local/share/flatpak/overrides"

# Utility functions
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${CYAN}$1${NC}"; }

# Check if Flatpak is properly configured
check_flatpak_setup() {
    print_header "🔍 Checking Flatpak Setup"
    
    # Check if Flatpak is installed
    if ! command -v flatpak &> /dev/null; then
        print_error "Flatpak is not installed!"
        echo "Install with: sudo pacman -S flatpak"
        return 1
    fi
    
    print_success "Flatpak $(flatpak --version | cut -d' ' -f2) is installed"
    
    # Check if Flathub is added
    if ! flatpak remotes | grep -q "flathub"; then
        print_warning "Flathub repository not found"
        echo "Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        print_success "Flathub repository added"
    else
        print_success "Flathub repository is configured"
    fi
    
    # Check for runtime
    local runtimes=$(flatpak list --runtime | wc -l)
    print_info "Installed runtimes: $runtimes"
    
    return 0
}

# Install essential Flatpak runtimes and apps
install_essential_flatpaks() {
    print_header "📦 Installing Essential Flatpak Apps & Runtimes"
    
    # Essential runtimes
    local runtimes=(
        "org.freedesktop.Platform//23.08"
        "org.freedesktop.Platform.GL.default//23.08"
        "org.gtk.Gtk3theme.adw-gtk3-dark"
        "org.gtk.Gtk3theme.adw-gtk3"
    )
    
    # Essential apps for a complete desktop experience
    local apps=(
        "org.mozilla.firefox"
        "org.libreoffice.LibreOffice"
        "org.gimp.GIMP"
        "com.discordapp.Discord"
        "org.telegram.desktop"
        "org.videolan.VLC"
        "com.spotify.Client"
        "org.audacityteam.Audacity"
        "org.blender.Blender"
        "com.vscodium.codium"
    )
    
    echo "Installing essential runtimes..."
    for runtime in "${runtimes[@]}"; do
        print_info "Installing runtime: $runtime"
        flatpak install -y flathub "$runtime" 2>/dev/null || print_warning "Runtime $runtime may already be installed or unavailable"
    done
    
    echo
    echo "The following apps are available for installation:"
    echo "Would you like to install any of these popular applications? (y/n for each)"
    echo
    
    for app in "${apps[@]}"; do
        read -p "Install $(echo $app | cut -d'.' -f2-)? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installing $app..."
            flatpak install -y flathub "$app"
        fi
    done
}

# Configure Flatpak for optimal Hyprland compatibility
configure_flatpak_for_hyprland() {
    print_header "⚙️ Configuring Flatpak for Hyprland Compatibility"
    
    # Create overrides directory
    mkdir -p "$FLATPAK_OVERRIDES_DIR"
    
    # Global Flatpak overrides for Hyprland compatibility
    cat > "$FLATPAK_OVERRIDES_DIR/global" << EOF
[Context]
shared=ipc;
sockets=x11;wayland;pulseaudio;session-bus;
devices=dri;all;
filesystems=xdg-config:ro;xdg-data:ro;xdg-documents;xdg-download;xdg-music;xdg-pictures;xdg-videos;xdg-desktop;

[Environment]
QT_QPA_PLATFORM=wayland;xcb
GDK_BACKEND=wayland,x11
WAYLAND_DISPLAY=wayland-1
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
MOZ_ENABLE_WAYLAND=1
ELECTRON_OZONE_PLATFORM_HINT=auto

[Session Bus Policy]
org.freedesktop.portal.*=talk
org.freedesktop.impl.portal.*=talk
EOF
    
    print_success "Global Flatpak overrides configured for Hyprland"
    
    # Configure portal for better integration
    configure_flatpak_portal
}

# Configure XDG Desktop Portal for Flatpak
configure_flatpak_portal() {
    print_header "🚪 Configuring XDG Desktop Portal"
    
    local portal_config_dir="$HOME/.config/xdg-desktop-portal"
    mkdir -p "$portal_config_dir"
    
    # Configure portal for Hyprland
    cat > "$portal_config_dir/hyprland-portals.conf" << EOF
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.Inhibit=hyprland
org.freedesktop.impl.portal.FileChooser=gtk
org.freedesktop.impl.portal.AppChooser=gtk
org.freedesktop.impl.portal.Print=gtk
EOF
    
    # Install required portal packages
    print_info "Installing required portal packages..."
    sudo pacman -S --needed --noconfirm \
        xdg-desktop-portal \
        xdg-desktop-portal-hyprland \
        xdg-desktop-portal-gtk \
        2>/dev/null || print_warning "Some portal packages may already be installed"
    
    print_success "XDG Desktop Portal configured"
}

# Optimize Flatpak performance
optimize_flatpak_performance() {
    print_header "🚀 Optimizing Flatpak Performance"
    
    # Enable Flatpak system integration
    print_info "Enabling system integration..."
    
    # Create performance optimization overrides
    local perf_override="$FLATPAK_OVERRIDES_DIR/performance"
    cat > "$perf_override" << EOF
[Context]
shared=ipc;network;
sockets=x11;wayland;pulseaudio;session-bus;system-bus;
devices=dri;kvm;all;
filesystems=host-etc:ro;host-usr:ro;host-opt:ro;

[Environment]
# Performance optimizations
__GL_THREADED_OPTIMIZATIONS=1
__GL_SHADER_DISK_CACHE=1
MESA_GLTHREAD=true
# Wayland optimizations
WAYLAND_DISPLAY=wayland-1
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
MOZ_ENABLE_WAYLAND=1
ELECTRON_OZONE_PLATFORM_HINT=wayland
EOF
    
    # Clean up Flatpak cache
    print_info "Cleaning up Flatpak cache..."
    flatpak uninstall --unused -y 2>/dev/null || true
    
    # Update all Flatpak apps
    print_info "Updating Flatpak apps..."
    flatpak update -y
    
    print_success "Flatpak performance optimized"
}

# Install development tools as Flatpaks
install_dev_flatpaks() {
    print_header "💻 Installing Development Tools"
    
    local dev_apps=(
        "com.vscodium.codium"           # VSCodium
        "org.gnome.Builder"             # GNOME Builder
        "com.jetbrains.IntelliJ-IDEA-Community"  # IntelliJ IDEA
        "org.freedesktop.Sdk//23.08"   # Development SDK
        "org.freedesktop.Sdk.Extension.node18//23.08"  # Node.js
        "org.freedesktop.Sdk.Extension.rust-stable//23.08"  # Rust
        "org.freedesktop.Sdk.Extension.golang//23.08"  # Go
    )
    
    echo "Available development tools:"
    for app in "${dev_apps[@]}"; do
        echo "  - $(echo $app | cut -d'.' -f2- | cut -d'/' -f1)"
    done
    echo
    
    read -p "Install development tools? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for app in "${dev_apps[@]}"; do
            print_info "Installing $app..."
            flatpak install -y flathub "$app" 2>/dev/null || print_warning "$app may not be available"
        done
        print_success "Development tools installed"
    fi
}

# Configure app-specific optimizations
configure_app_specific() {
    print_header "🎯 Configuring App-Specific Optimizations"
    
    # Firefox optimizations
    if flatpak list | grep -q "org.mozilla.firefox"; then
        print_info "Configuring Firefox for Wayland..."
        cat > "$FLATPAK_OVERRIDES_DIR/org.mozilla.firefox" << EOF
[Context]
sockets=x11;wayland;pulseaudio;
shared=ipc;network;
devices=dri;

[Environment]
MOZ_ENABLE_WAYLAND=1
MOZ_WEBRENDER=1
MOZ_ACCELERATED=1
MOZ_USE_XINPUT2=1
EOF
    fi
    
    # Discord optimizations
    if flatpak list | grep -q "com.discordapp.Discord"; then
        print_info "Configuring Discord for better performance..."
        cat > "$FLATPAK_OVERRIDES_DIR/com.discordapp.Discord" << EOF
[Context]
sockets=x11;wayland;pulseaudio;
shared=ipc;network;
devices=dri;

[Environment]
ELECTRON_OZONE_PLATFORM_HINT=wayland
EOF
    fi
    
    # VSCode/VSCodium optimizations
    if flatpak list | grep -q "com.vscodium.codium"; then
        print_info "Configuring VSCodium for development..."
        cat > "$FLATPAK_OVERRIDES_DIR/com.vscodium.codium" << EOF
[Context]
sockets=x11;wayland;pulseaudio;ssh-auth;
shared=ipc;network;
devices=dri;
filesystems=host;

[Environment]
ELECTRON_OZONE_PLATFORM_HINT=wayland
EOF
    fi
    
    print_success "App-specific optimizations configured"
}

# List installed Flatpak apps with launch commands
list_flatpak_apps() {
    print_header "📱 Installed Flatpak Applications"
    
    local apps=$(flatpak list --app --columns=application)
    
    if [ -z "$apps" ]; then
        print_warning "No Flatpak applications installed"
        return
    fi
    
    echo "Installed Flatpak apps:"
    echo "======================="
    
    while IFS= read -r app; do
        if [ -n "$app" ]; then
            local name=$(flatpak info "$app" 2>/dev/null | grep "^Name:" | cut -d: -f2- | xargs)
            echo -e "${GREEN}$name${NC} (${BLUE}$app${NC})"
            echo "  Launch: flatpak run $app"
            echo
        fi
    done <<< "$apps"
}

# Troubleshoot Flatpak issues
troubleshoot_flatpak() {
    print_header "🔧 Flatpak Troubleshooting"
    
    echo "Running Flatpak diagnostics..."
    echo
    
    # Check remotes
    print_info "Configured remotes:"
    flatpak remotes --show-details
    echo
    
    # Check for broken installations
    print_info "Checking for issues..."
    flatpak repair --user
    
    # Check portal status
    print_info "Portal status:"
    if command -v portal-test-app &> /dev/null; then
        echo "Portal test app available"
    else
        print_warning "Consider installing portal test app for debugging"
    fi
    
    # Check environment
    print_info "Environment variables:"
    env | grep -E "(XDG|WAYLAND|QT|GDK)" | sort
    
    print_success "Troubleshooting complete"
}

# Create desktop entries for easy access
create_desktop_entries() {
    print_header "🖥️ Creating Desktop Entries"
    
    local desktop_dir="$HOME/.local/share/applications"
    mkdir -p "$desktop_dir"
    
    # Create HyprSupreme Flatpak Manager entry
    cat > "$desktop_dir/hyprsupreme-flatpak.desktop" << EOF
[Desktop Entry]
Name=HyprSupreme Flatpak Manager
Comment=Manage Flatpak applications for HyprSupreme
Exec=/home/alex/HyprSupreme-Builder/tools/flatpak_manager.sh
Icon=application-x-flatpak
Terminal=true
Type=Application
Categories=System;Settings;
EOF
    
    print_success "Desktop entries created"
}

# Main menu
show_menu() {
    print_header "╔═══════════════════════════════════════════════════════════════╗"
    print_header "║                                                               ║"
    print_header "║            🚀 HYPRSUPREME FLATPAK MANAGER 🚀                 ║"
    print_header "║                                                               ║"
    print_header "║              Perfect Flatpak Integration                     ║"
    print_header "║                                                               ║"
    print_header "╚═══════════════════════════════════════════════════════════════╝"
    echo
    echo "1) Check Flatpak Setup"
    echo "2) Install Essential Apps"
    echo "3) Configure for Hyprland"
    echo "4) Optimize Performance"
    echo "5) Install Development Tools"
    echo "6) Configure App-Specific Settings"
    echo "7) List Installed Apps"
    echo "8) Troubleshoot Issues"
    echo "9) Create Desktop Entries"
    echo "10) Complete Setup (All Steps)"
    echo "0) Exit"
    echo
}

# Complete setup function
complete_setup() {
    print_header "🔄 Running Complete Flatpak Setup"
    
    check_flatpak_setup
    configure_flatpak_for_hyprland
    optimize_flatpak_performance
    configure_app_specific
    create_desktop_entries
    
    echo
    print_success "✅ Complete Flatpak setup finished!"
    print_info "You can now install apps with: flatpak install flathub <app-id>"
    print_info "Run apps with: flatpak run <app-id>"
    print_info "Access this manager with: ./tools/flatpak_manager.sh"
}

# Command line interface
main() {
    case "$1" in
        "check"|"status")
            check_flatpak_setup
            ;;
        "install")
            if [ -n "$2" ]; then
                print_info "Installing Flatpak app: $2"
                flatpak install -y flathub "$2"
            else
                install_essential_flatpaks
            fi
            ;;
        "configure"|"config")
            configure_flatpak_for_hyprland
            ;;
        "optimize"|"perf")
            optimize_flatpak_performance
            ;;
        "dev"|"development")
            install_dev_flatpaks
            ;;
        "list"|"apps")
            list_flatpak_apps
            ;;
        "troubleshoot"|"fix")
            troubleshoot_flatpak
            ;;
        "setup"|"complete")
            complete_setup
            ;;
        "help"|"--help")
            echo "HyprSupreme Flatpak Manager Commands:"
            echo "  check       - Check Flatpak setup"
            echo "  install     - Install essential apps"
            echo "  configure   - Configure for Hyprland"
            echo "  optimize    - Optimize performance"
            echo "  dev         - Install development tools"
            echo "  list        - List installed apps"
            echo "  troubleshoot- Fix common issues"
            echo "  setup       - Complete setup (recommended)"
            echo "  help        - Show this help"
            ;;
        "")
            # Interactive mode
            while true; do
                show_menu
                read -p "Select option (0-10): " choice
                case $choice in
                    1) check_flatpak_setup ;;
                    2) install_essential_flatpaks ;;
                    3) configure_flatpak_for_hyprland ;;
                    4) optimize_flatpak_performance ;;
                    5) install_dev_flatpaks ;;
                    6) configure_app_specific ;;
                    7) list_flatpak_apps ;;
                    8) troubleshoot_flatpak ;;
                    9) create_desktop_entries ;;
                    10) complete_setup ;;
                    0) exit 0 ;;
                    *) print_error "Invalid option" ;;
                esac
                echo
                read -p "Press Enter to continue..."
                clear
            done
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use 'help' for available commands"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

