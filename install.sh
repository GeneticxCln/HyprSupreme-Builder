#!/bin/bash
# HyprSupreme-Builder Installation Script
# https://github.com/GeneticxCln/HyprSupreme-Builder

clear

# Set colors for output
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Script version
VERSION="2.1.0"
PROJECT_NAME="HyprSupreme-Builder"

# Create logs directory
mkdir -p logs
LOG="logs/install-$(date +%Y%m%d-%H%M%S).log"

# Banner
print_banner() {
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║              🚀 HYPRLAND SUPREME BUILDER 🚀                  ║"
    echo "║                                                               ║"
    echo "║          Ultimate Configuration Builder v${VERSION}               ║"
    echo "║                                                               ║"
    echo "║    Combining: JaKooLit • ML4W • HyDE • End-4 • Prasanta     ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "${ERROR} This script should NOT be executed as root! Exiting..." | tee -a "$LOG"
        exit 1
    fi
}

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    else
        echo "${ERROR} Cannot detect distribution" | tee -a "$LOG"
        exit 1
    fi
    
    case $DISTRO in
        arch|endeavouros|cachyos|manjaro|garuda)
            PACKAGE_MANAGER="pacman"
            AUR_HELPER=""
            ;;
        *)
            echo "${ERROR} Unsupported distribution: $DISTRO" | tee -a "$LOG"
            echo "${INFO} Currently supported: Arch, EndeavourOS, CachyOS, Manjaro, Garuda" | tee -a "$LOG"
            exit 1
            ;;
    esac
    
    echo "${INFO} Detected: $DISTRO $DISTRO_VERSION" | tee -a "$LOG"
}

# Check for AUR helper
check_aur_helper() {
    if command -v yay &> /dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &> /dev/null; then
        AUR_HELPER="paru"
    else
        echo "${NOTE} No AUR helper found. Installing yay..." | tee -a "$LOG"
        install_yay
    fi
    echo "${INFO} Using AUR helper: $AUR_HELPER" | tee -a "$LOG"
}

# Install yay
install_yay() {
    if ! command -v git &> /dev/null; then
        sudo pacman -S --noconfirm git
    fi
    
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$OLDPWD"
    AUR_HELPER="yay"
}

# Install required packages
install_dependencies() {
    echo "${INFO} Installing dependencies..." | tee -a "$LOG"
    
    # Essential packages
    local packages=(
        "git"
        "curl"
        "wget" 
        "unzip"
        "base-devel"
    )
    
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg"  /dev/null; then
            echo "${NOTE} Installing $pkg..." | tee -a "$LOG"
            sudo pacman -S --noconfirm "$pkg" || {
                echo "${ERROR} Failed to install $pkg" | tee -a "$LOG"
                exit 1
            }
        fi
    done
    
    # Try to install whiptail (might not be available on all distros)
    if ! pacman -Qi "libnewt"  /dev/null; then
        echo "${NOTE} Installing dialog tools..." | tee -a "$LOG"
        sudo pacman -S --noconfirm libnewt 2/dev/null || {
            echo "${WARN} Could not install whiptail, using simple fallback menus" | tee -a "$LOG"
            USE_SIMPLE_MENUS=true
        }
    fi
}

# Configuration selection menu
select_config_sources() {
    echo "${INFO} Select configuration sources to include:" | tee -a "$LOG"
    
    # Available configurations
    CONFIGS=(
        "jakoolit" "JaKooLit's Comprehensive Setup" "ON"
        "ml4w" "ML4W Professional Workflow" "OFF"
        "hyde" "HyDE Dynamic Theming System" "OFF"
        "end4" "End-4 Modern Widgets & Animations" "OFF"
        "prasanta" "Prasanta Beautiful Themes" "OFF"
    )
    
    SELECTED_CONFIGS=$(whiptail --title "Configuration Sources" \
        --checklist "Choose configurations to integrate:" \
        20 80 10 "${CONFIGS[@]}" 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        echo "${ERROR} Installation cancelled by user" | tee -a "$LOG"
        exit 0
    fi
    
    echo "${INFO} Selected configurations: $SELECTED_CONFIGS" | tee -a "$LOG"
}

# Component selection menu
select_components() {
    echo "${INFO} Select components to install:" | tee -a "$LOG"
    
    COMPONENTS=(
        "hyprland" "Hyprland Window Manager" "ON"
        "waybar" "Status Bar" "ON"
        "rofi" "Application Launcher" "ON"
        "warp" "Warp Terminal (Modern AI Terminal)" "ON"
        "kitty" "Kitty Terminal (Fallback)" "OFF"
        "ags" "Aylur's GTK Shell (Widgets)" "OFF"
        "sddm" "Display Manager" "OFF"
        "themes" "GTK & Icon Themes" "ON"
        "fonts" "Font Collection" "ON"
        "wallpapers" "Wallpaper Collection" "ON"
        "scripts" "Utility Scripts" "ON"
        "nvidia" "NVIDIA Drivers & Optimization" "OFF"
    )
    
    SELECTED_COMPONENTS=$(whiptail --title "Component Selection" \
        --checklist "Choose components to install:" \
        20 80 15 "${COMPONENTS[@]}" 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        echo "${ERROR} Installation cancelled by user" | tee -a "$LOG"
        exit 0
    fi
    
    echo "${INFO} Selected components: $SELECTED_COMPONENTS" | tee -a "$LOG"
}

# Feature selection menu  
select_features() {
    echo "${INFO} Select advanced features:" | tee -a "$LOG"
    
    FEATURES=(
        "animations" "Advanced Animations & Effects" "ON"
        "blur" "Background Blur Effects" "ON"
        "shadows" "Window Shadows" "ON"
        "rounded" "Rounded Corners" "ON"
        "transparency" "Window Transparency" "ON"
        "workspace_swipe" "Workspace Gesture Navigation" "ON"
        "auto_theme" "Automatic Theme Switching" "OFF"
        "performance" "Performance Optimizations" "ON"
    )
    
    SELECTED_FEATURES=$(whiptail --title "Feature Selection" \
        --checklist "Choose advanced features:" \
        20 80 10 "${FEATURES[@]}" 3>&1 1>&2 2>&3)
    
    echo "${INFO} Selected features: $SELECTED_FEATURES" | tee -a "$LOG"
}

# Preset selection
select_preset() {
    if [[ "$1" == "--preset" && -n "$2" ]]; then
        PRESET="$2"
        echo "${INFO} Using preset: $PRESET" | tee -a "$LOG"
        load_preset "$PRESET"
        return
    fi
    
    PRESET=$(whiptail --title "Preset Selection" \
        --menu "Choose a preset configuration:" \
        20 80 10 \
        "custom" "Custom - Manual selection" \
        "showcase" "Showcase - Maximum eye-candy" \
        "gaming" "Gaming - Performance optimized" \
        "work" "Work - Productivity focused" \
        "minimal" "Minimal - Lightweight setup" \
        "hybrid" "Hybrid - Balanced configuration" \
        3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        PRESET="custom"
    fi
    
    echo "${INFO} Selected preset: $PRESET" | tee -a "$LOG"
    
    if [[ "$PRESET" != "custom" ]]; then
        load_preset "$PRESET"
    fi
}

# Load preset configuration
load_preset() {
    local preset="$1"
    
    case "$preset" in
        "showcase")
            SELECTED_CONFIGS='"jakoolit" "hyde" "end4" "prasanta"'
            SELECTED_COMPONENTS='"hyprland" "waybar" "rofi" "warp" "ags" "sddm" "themes" "fonts" "wallpapers" "scripts"'
            SELECTED_FEATURES='"animations" "blur" "shadows" "rounded" "transparency" "workspace_swipe" "auto_theme"'
            ;;
        "gaming")
            SELECTED_CONFIGS='"jakoolit" "ml4w"'
            SELECTED_COMPONENTS='"hyprland" "waybar" "rofi" "warp" "themes" "fonts" "scripts"'
            SELECTED_FEATURES='"performance" "workspace_swipe"'
            ;;
        "work")
            SELECTED_CONFIGS='"ml4w" "jakoolit"'
            SELECTED_COMPONENTS='"hyprland" "waybar" "rofi" "warp" "themes" "fonts" "scripts"'
            SELECTED_FEATURES='"rounded" "transparency" "workspace_swipe" "performance"'
            ;;
        "minimal")
            SELECTED_CONFIGS='"jakoolit"'
            SELECTED_COMPONENTS='"hyprland" "waybar" "rofi" "warp" "fonts"'
            SELECTED_FEATURES='"performance"'
            ;;
        "hybrid")
            SELECTED_CONFIGS='"jakoolit" "ml4w" "hyde"'
            SELECTED_COMPONENTS='"hyprland" "waybar" "rofi" "warp" "ags" "themes" "fonts" "wallpapers" "scripts"'
            SELECTED_FEATURES='"animations" "blur" "rounded" "transparency" "workspace_swipe"'
            ;;
    esac
    
    echo "${OK} Loaded preset: $preset" | tee -a "$LOG"
}

# Download configuration sources
download_configs() {
    echo "${INFO} Downloading configuration sources..." | tee -a "$LOG"
    mkdir -p sources
    
    for config in $(echo $SELECTED_CONFIGS | tr -d '"'); do
        case "$config" in
            "jakoolit")
                if [ ! -d "sources/jakoolit" ]; then
                    echo "${NOTE} Downloading JaKooLit configuration..." | tee -a "$LOG"
                    git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git sources/jakoolit
                    git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git sources/jakoolit-dots
                fi
                ;;
            "ml4w")
                if [ ! -d "sources/ml4w" ]; then
                    echo "${NOTE} Downloading ML4W configuration..." | tee -a "$LOG"
                    git clone --depth=1 https://github.com/mylinuxforwork/dotfiles.git sources/ml4w
                fi
                ;;
            "hyde")
                if [ ! -d "sources/hyde" ]; then
                    echo "${NOTE} Downloading HyDE configuration..." | tee -a "$LOG"
                    git clone --depth=1 https://github.com/prasanthrangan/hyprdots.git sources/hyde
                fi
                ;;
            "end4")
                if [ ! -d "sources/end4" ]; then
                    echo "${NOTE} Downloading End-4 configuration..." | tee -a "$LOG"
                    git clone --depth=1 https://github.com/end-4/dots-hyprland.git sources/end4
                fi
                ;;
            "prasanta")
                if [ ! -d "sources/prasanta" ]; then
                    echo "${NOTE} Downloading Prasanta configuration..." | tee -a "$LOG"
                    git clone --depth=1 https://github.com/prasanthrangan/hyprdots.git sources/prasanta
                fi
                ;;
        esac
    done
}

# Install components
install_components() {
    echo "${INFO} Installing selected components..." | tee -a "$LOG"
    
    # Create modules directory structure
    mkdir -p modules/{core,themes,widgets,scripts}
    
    for component in $(echo $SELECTED_COMPONENTS | tr -d '"'); do
        echo "${NOTE} Installing component: $component..." | tee -a "$LOG"
        
        case "$component" in
            "hyprland")
                ./modules/core/install_hyprland.sh
                ;;
            "waybar")
                ./modules/core/install_waybar.sh
                ;;
            "rofi")
                ./modules/core/install_rofi.sh
                ;;
            "warp")
                ./modules/core/install_warp.sh
                ;;
            "kitty")
                ./modules/core/install_kitty.sh
                ;;
            "ags")
                ./modules/widgets/install_ags.sh
                ;;
            "sddm")
                ./modules/core/install_sddm.sh
                ;;
            "themes")
                ./modules/themes/install_themes.sh
                ;;
            "fonts")
                ./modules/core/install_fonts.sh
                ;;
            "wallpapers")
                ./modules/themes/install_wallpapers.sh
                ;;
            "scripts")
                ./modules/scripts/install_scripts.sh
                ;;
            "nvidia")
                ./modules/core/install_nvidia.sh
                ;;
        esac
    done
}

# Apply configurations
apply_configurations() {
    echo "${INFO} Applying configurations..." | tee -a "$LOG"
    
    # Backup existing configs
    backup_configs
    
    # Apply selected configurations
    for config in $(echo $SELECTED_CONFIGS | tr -d '"'); do
        echo "${NOTE} Applying $config configuration..." | tee -a "$LOG"
        ./modules/core/apply_config.sh "$config"
    done
    
    # Apply features
    apply_features
}

# Backup existing configurations
backup_configs() {
    echo "${INFO} Creating backup of existing configurations..." | tee -a "$LOG"
    
    BACKUP_DIR="$HOME/.config/hyprland-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup directories if they exist
    local dirs=(".config/hypr" ".config/waybar" ".config/rofi" ".config/kitty" ".config/ags")
    
    for dir in "${dirs[@]}"; do
        if [ -d "$HOME/$dir" ]; then
            cp -r "$HOME/$dir" "$BACKUP_DIR/"
            echo "${OK} Backed up $dir" | tee -a "$LOG"
        fi
    done
    
    echo "${OK} Backup created at: $BACKUP_DIR" | tee -a "$LOG"
}

# Apply selected features
apply_features() {
    echo "${INFO} Applying selected features..." | tee -a "$LOG"
    
    for feature in $(echo $SELECTED_FEATURES | tr -d '"'); do
        echo "${NOTE} Applying feature: $feature..." | tee -a "$LOG"
        ./modules/core/apply_feature.sh "$feature"
    done
}

# Post-installation setup
post_install() {
    echo "${INFO} Running post-installation setup..." | tee -a "$LOG"
    
    # Set up shell
    if [[ $SHELL != *"zsh"* ]]; then
        echo "${NOTE} Setting up Zsh..." | tee -a "$LOG"
        chsh -s "$(which zsh)"
    fi
    
    # Create desktop entries
    create_desktop_entries
    
    # Set up autostart
    setup_autostart
    
    echo "${OK} Post-installation setup completed!" | tee -a "$LOG"
}

# Create desktop entries
create_desktop_entries() {
    echo "${INFO} Creating desktop entries..." | tee -a "$LOG"
    
    mkdir -p "$HOME/.local/share/applications"
    
    # HyprSupreme Settings
    cat > "$HOME/.local/share/applications/hyprsupreme-settings.desktop" << EOF
[Desktop Entry]
Name=HyprSupreme Settings
Comment=Configure HyprSupreme Builder
Exec=hyprsupreme-settings
Icon=preferences-system
Type=Application
Categories=Settings;System;
EOF
    
    echo "${OK} Desktop entries created" | tee -a "$LOG"
}

# Setup autostart
setup_autostart() {
    echo "${INFO} Setting up autostart..." | tee -a "$LOG"
    
    mkdir -p "$HOME/.config/autostart"
    
    # Add autostart entries based on selected components
    if echo "$SELECTED_COMPONENTS" | grep -q "waybar"; then
        cat > "$HOME/.config/autostart/waybar.desktop" << EOF
[Desktop Entry]
Name=Waybar
Exec=waybar
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    fi
}

# Installation summary
show_summary() {
    clear
    print_banner
    
    echo "${OK} Installation completed successfully!" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "${INFO} Installation Summary:" | tee -a "$LOG"
    echo "  • Configurations: $(echo $SELECTED_CONFIGS | tr -d '"' | wc -w) selected" | tee -a "$LOG"
    echo "  • Components: $(echo $SELECTED_COMPONENTS | tr -d '"' | wc -w) installed" | tee -a "$LOG"
    echo "  • Features: $(echo $SELECTED_FEATURES | tr -d '"' | wc -w) enabled" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "${NOTE} Next steps:" | tee -a "$LOG"
    echo "  1. Reboot your system" | tee -a "$LOG"
    echo "  2. Log out and select Hyprland session" | tee -a "$LOG"
    echo "  3. Run 'hyprsupreme-config' to customize further" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "${GREEN}Thank you for using HyprSupreme-Builder!${RESET}" | tee -a "$LOG"
}

# Main installation function
main() {
    print_banner
    
    echo "${INFO} Starting HyprSupreme-Builder installation..." | tee -a "$LOG"
    echo "${INFO} Log file: $LOG" | tee -a "$LOG"
    
    # Pre-installation checks
    check_root
    detect_distro
    install_dependencies
    check_aur_helper
    
    # Configuration
    select_preset "$@"
    
    if [[ "$PRESET" == "custom" ]]; then
        select_config_sources
        select_components  
        select_features
    fi
    
    # Installation
    download_configs
    install_components
    apply_configurations
    post_install
    
    # Summary
    show_summary
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

