#!/bin/bash
# HyprSupreme-Builder Installation Script
# https://github.com/GeneticxCln/HyprSupreme-Builder

# Exit on any error, undefined variable, or pipe failure
set -euo pipefail

# Cleanup function for script failure
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "${ERROR} Script failed with exit code $exit_code" | tee -a "$LOG" 2>/dev/null || true
        echo "${ERROR} Check the log file for details: $LOG" | tee -a "$LOG" 2>/dev/null || true
        
        # Kill sudo keeper if running
        if [[ -n "${SUDO_KEEPER_PID:-}" ]]; then
            kill "$SUDO_KEEPER_PID" 2>/dev/null || true
        fi
        
        # Clean up temporary files
        if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
            rm -rf "$TEMP_DIR" 2>/dev/null || true
        fi
        
        # Restore interrupted backups if they exist
        if [[ -n "${CURRENT_BACKUP_DIR:-}" && -d "$CURRENT_BACKUP_DIR" ]]; then
            echo "${INFO} Backup available at: $CURRENT_BACKUP_DIR" | tee -a "$LOG" 2>/dev/null || true
        fi
    fi
}

# Set up trap for cleanup
trap cleanup EXIT ERR INT TERM

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

# Ask for user confirmation for package installations
confirm_package_installation() {
    local packages=("$@")
    local package_list=$(printf "%s " "${packages[@]}")
    
    if [[ "$UNATTENDED" == "true" ]]; then
        echo "${INFO} Unattended mode: Installing packages without confirmation: $package_list" | tee -a "$LOG"
        return 0
    fi
    
    echo "${NOTE} About to install the following packages: $package_list" | tee -a "$LOG"
    echo "${INFO} Do you want to proceed with the installation? [Y/n]"
    read -r response
    
    case "$response" in
        [nN][oO]|[nN])
            echo "${WARN} Package installation cancelled by user" | tee -a "$LOG"
            return 1
            ;;
        *)
            echo "${OK} Proceeding with package installation" | tee -a "$LOG"
            return 0
            ;;
    esac
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

# Comprehensive dependency checker
check_system_dependencies() {
    echo "${INFO} Checking system dependencies..." | tee -a "$LOG"
    
    local missing_deps=()
    local critical_deps=("sudo" "pacman" "git" "curl" "wget" "bash" "systemctl")
    local optional_deps=("whiptail" "dialog" "python3" "python3-pip")
    
    # Check critical dependencies
    for dep in "${critical_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Validate sudo access with comprehensive checks
    if command -v validate_sudo_access >/dev/null 2>&1; then
        validate_sudo_access "$PROJECT_NAME"
    else
        # Fallback sudo validation
        echo "${INFO} Validating sudo access..." | tee -a "$LOG"
        if ! sudo -n true 2>/dev/null; then
            if ! sudo -v; then
                echo "${ERROR} Sudo access required for installation" | tee -a "$LOG"
                exit 1
            fi
        fi
        echo "${OK} Sudo access validated" | tee -a "$LOG"
    fi
    
    # Check disk space (require at least 2GB free)
    local available_space=$(df . | awk 'NR==2 {print $4}')
    local required_space=2097152  # 2GB in KB
    if [ "$available_space" -lt "$required_space" ]; then
        echo "${ERROR} Insufficient disk space. Required: 2GB, Available: $((available_space/1024))MB" | tee -a "$LOG"
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 archlinux.org &> /dev/null && ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo "${ERROR} No internet connection detected" | tee -a "$LOG"
        exit 1
    fi
    
    # Handle missing critical dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "${ERROR} Missing critical dependencies: ${missing_deps[*]}" | tee -a "$LOG"
        echo "${INFO} Attempting to install missing dependencies..." | tee -a "$LOG"
        
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "sudo")
                    echo "${ERROR} sudo is required but not installed. Please install manually." | tee -a "$LOG"
                    exit 1
                    ;;
                "pacman")
                    echo "${ERROR} This script requires pacman package manager" | tee -a "$LOG"
                    exit 1
                    ;;
                *)
                    if confirm_package_installation "$dep"; then
                        if [[ "$UNATTENDED" == "true" ]]; then
                            if ! sudo pacman -S --noconfirm "$dep" 2>/dev/null; then
                                echo "${ERROR} Failed to install $dep" | tee -a "$LOG"
                                exit 1
                            fi
                        else
                            if ! sudo pacman -S "$dep" 2>/dev/null; then
                                echo "${ERROR} Failed to install $dep" | tee -a "$LOG"
                                exit 1
                            fi
                        fi
                    else
                        echo "${ERROR} Installation of critical dependency $dep was cancelled" | tee -a "$LOG"
                        exit 1
                    fi
                    ;;
            esac
        done
    fi
    
    echo "${OK} System dependencies check passed" | tee -a "$LOG"
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
        if confirm_package_installation "git"; then
            if [[ "$UNATTENDED" == "true" ]]; then
                sudo pacman -S --noconfirm git
            else
                sudo pacman -S git
            fi
        else
            echo "${ERROR} Git is required to install yay" | tee -a "$LOG"
            exit 1
        fi
    fi
    
    echo "${NOTE} About to install yay AUR helper from source" | tee -a "$LOG"
    if [[ "$UNATTENDED" != "true" ]]; then
        echo "${INFO} Do you want to proceed with yay installation? [Y/n]"
        read -r response
        case "$response" in
            [nN][oO]|[nN])
                echo "${ERROR} yay installation cancelled by user" | tee -a "$LOG"
                exit 1
                ;;
        esac
    fi
    
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    if [[ "$UNATTENDED" == "true" ]]; then
        makepkg -si --noconfirm
    else
        makepkg -si
    fi
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
    
    if confirm_package_installation "${packages[@]}"; then
        for pkg in "${packages[@]}"; do
            if ! pacman -Qi "$pkg" &> /dev/null; then
                echo "${NOTE} Installing $pkg..." | tee -a "$LOG"
                if [[ "$UNATTENDED" == "true" ]]; then
                    sudo pacman -S --noconfirm "$pkg" || {
                        echo "${ERROR} Failed to install $pkg" | tee -a "$LOG"
                        exit 1
                    }
                else
                    sudo pacman -S "$pkg" || {
                        echo "${ERROR} Failed to install $pkg" | tee -a "$LOG"
                        exit 1
                    }
                fi
            fi
        done
    else
        echo "${ERROR} Essential packages installation cancelled" | tee -a "$LOG"
        exit 1
    fi
    
    # Try to install whiptail (might not be available on all distros)
    if ! pacman -Qi "libnewt" &> /dev/null; then
        echo "${NOTE} Installing dialog tools..." | tee -a "$LOG"
        if [[ "$UNATTENDED" == "true" ]]; then
            sudo pacman -S --noconfirm libnewt 2>/dev/null || {
                echo "${WARN} Could not install whiptail, using simple fallback menus" | tee -a "$LOG"
                USE_SIMPLE_MENUS=true
            }
        else
            echo "${INFO} Install dialog tools for better menus? [Y/n]"
            read -r response
            case "$response" in
                [nN][oO]|[nN])
                    echo "${WARN} Skipping dialog tools, using simple fallback menus" | tee -a "$LOG"
                    USE_SIMPLE_MENUS=true
                    ;;
                *)
                    sudo pacman -S libnewt 2>/dev/null || {
                        echo "${WARN} Could not install whiptail, using simple fallback menus" | tee -a "$LOG"
                        USE_SIMPLE_MENUS=true
                    }
                    ;;
            esac
        fi
    fi
}

# Configuration selection menu
select_config_sources() {
    echo "${INFO} Select configuration sources to include:" | tee -a "$LOG"
    
    if [[ "${USE_SIMPLE_MENUS:-false}" == "true" ]] || ! command -v whiptail >/dev/null 2>&1; then
        select_config_sources_simple
        return
    fi
    
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

# Simple fallback configuration selection
select_config_sources_simple() {
    echo "" | tee -a "$LOG"
    echo "${NOTE} Configuration Sources:" | tee -a "$LOG"
    echo "  1) JaKooLit's Comprehensive Setup (recommended)" | tee -a "$LOG"
    echo "  2) ML4W Professional Workflow" | tee -a "$LOG"
    echo "  3) HyDE Dynamic Theming System" | tee -a "$LOG"
    echo "  4) End-4 Modern Widgets & Animations" | tee -a "$LOG"
    echo "  5) Prasanta Beautiful Themes" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "Enter numbers separated by spaces (e.g., '1 3 5') or press Enter for default (1):"
    read -r selection
    
    # Default to JaKooLit if no selection
    if [[ -z "$selection" ]]; then
        selection="1"
    fi
    
    SELECTED_CONFIGS=""
    for num in $selection; do
        case $num in
            1) SELECTED_CONFIGS="$SELECTED_CONFIGS \"jakoolit\"" ;;
            2) SELECTED_CONFIGS="$SELECTED_CONFIGS \"ml4w\"" ;;
            3) SELECTED_CONFIGS="$SELECTED_CONFIGS \"hyde\"" ;;
            4) SELECTED_CONFIGS="$SELECTED_CONFIGS \"end4\"" ;;
            5) SELECTED_CONFIGS="$SELECTED_CONFIGS \"prasanta\"" ;;
        esac
    done
    
    SELECTED_CONFIGS=$(echo "$SELECTED_CONFIGS" | xargs)
    echo "${INFO} Selected configurations: $SELECTED_CONFIGS" | tee -a "$LOG"
}

# Component selection menu
select_components() {
    echo "${INFO} Select components to install:" | tee -a "$LOG"
    
    if [[ "${USE_SIMPLE_MENUS:-false}" == "true" ]] || ! command -v whiptail >/dev/null 2>&1; then
        select_components_simple
        return
    fi
    
    COMPONENTS=(
        "hyprland" "Hyprland Window Manager" "ON"
        "waybar" "Status Bar" "ON"
        "rofi" "Application Launcher" "ON"
        "warp" "Warp Terminal (Modern AI Terminal)" "ON"
        "kitty" "Kitty Terminal (Fallback)" "OFF"
        "ags" "Aylur's GTK Shell (Widgets)" "OFF"
        "sddm" "Display Manager" "OFF"
        "system-utils" "System Utilities (File/Package/Volume Mgr)" "ON"
        "notifications" "Notification System (Mako/Dunst)" "ON"
        "audio" "Audio System (PipeWire/Controls)" "ON"
        "bluetooth" "Bluetooth System & Controls" "ON"
        "network" "Network & WiFi Management" "ON"
        "power" "Power Management & Battery" "ON"
        "theme-switcher" "Theme Switcher & Manager" "ON"
        "workspace-time" "Workspace & Time Management" "ON"
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

# Simple fallback component selection
select_components_simple() {
    echo "" | tee -a "$LOG"
    echo "${NOTE} Components (default: core components 1-4,7-10):" | tee -a "$LOG"
    echo "  1) Hyprland Window Manager" | tee -a "$LOG"
    echo "  2) Waybar Status Bar" | tee -a "$LOG"
    echo "  3) Rofi Application Launcher" | tee -a "$LOG"
    echo "  4) Kitty Terminal Emulator" | tee -a "$LOG"
    echo "  5) AGS (Aylur's GTK Shell)" | tee -a "$LOG"
    echo "  6) SDDM Display Manager" | tee -a "$LOG"
    echo "  7) GTK & Icon Themes" | tee -a "$LOG"
    echo "  8) Font Collection" | tee -a "$LOG"
    echo "  9) Wallpaper Collection" | tee -a "$LOG"
    echo "  10) Utility Scripts" | tee -a "$LOG"
    echo "  11) NVIDIA Drivers & Optimization" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "Enter numbers separated by spaces or press Enter for default:"
    read -r selection
    
    # Default to core components
    if [[ -z "$selection" ]]; then
        selection="1 2 3 4 7 8 9 10"
    fi
    
    SELECTED_COMPONENTS=""
    for num in $selection; do
        case $num in
            1) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"hyprland\"" ;;
            2) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"waybar\"" ;;
            3) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"rofi\"" ;;
            4) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"kitty\"" ;;
            5) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"ags\"" ;;
            6) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"sddm\"" ;;
            7) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"themes\"" ;;
            8) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"fonts\"" ;;
            9) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"wallpapers\"" ;;
            10) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"scripts\"" ;;
            11) SELECTED_COMPONENTS="$SELECTED_COMPONENTS \"nvidia\"" ;;
        esac
    done
    
    SELECTED_COMPONENTS=$(echo "$SELECTED_COMPONENTS" | xargs)
    echo "${INFO} Selected components: $SELECTED_COMPONENTS" | tee -a "$LOG"
}

# Feature selection menu  
select_features() {
    echo "${INFO} Select advanced features:" | tee -a "$LOG"
    
    if [[ "${USE_SIMPLE_MENUS:-false}" == "true" ]] || ! command -v whiptail >/dev/null 2>&1; then
        select_features_simple
        return
    fi
    
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

# Simple fallback feature selection
select_features_simple() {
    echo "" | tee -a "$LOG"
    echo "${NOTE} Advanced Features (default: 1-6,8):" | tee -a "$LOG"
    echo "  1) Advanced Animations & Effects" | tee -a "$LOG"
    echo "  2) Background Blur Effects" | tee -a "$LOG"
    echo "  3) Window Shadows" | tee -a "$LOG"
    echo "  4) Rounded Corners" | tee -a "$LOG"
    echo "  5) Window Transparency" | tee -a "$LOG"
    echo "  6) Workspace Gesture Navigation" | tee -a "$LOG"
    echo "  7) Automatic Theme Switching" | tee -a "$LOG"
    echo "  8) Performance Optimizations" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "Enter numbers separated by spaces or press Enter for default:"
    read -r selection
    
    # Default to most features except auto_theme
    if [[ -z "$selection" ]]; then
        selection="1 2 3 4 5 6 8"
    fi
    
    SELECTED_FEATURES=""
    for num in $selection; do
        case $num in
            1) SELECTED_FEATURES="$SELECTED_FEATURES \"animations\"" ;;
            2) SELECTED_FEATURES="$SELECTED_FEATURES \"blur\"" ;;
            3) SELECTED_FEATURES="$SELECTED_FEATURES \"shadows\"" ;;
            4) SELECTED_FEATURES="$SELECTED_FEATURES \"rounded\"" ;;
            5) SELECTED_FEATURES="$SELECTED_FEATURES \"transparency\"" ;;
            6) SELECTED_FEATURES="$SELECTED_FEATURES \"workspace_swipe\"" ;;
            7) SELECTED_FEATURES="$SELECTED_FEATURES \"auto_theme\"" ;;
            8) SELECTED_FEATURES="$SELECTED_FEATURES \"performance\"" ;;
        esac
    done
    
    SELECTED_FEATURES=$(echo "$SELECTED_FEATURES" | xargs)
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
    
    if [[ "${USE_SIMPLE_MENUS:-false}" == "true" ]] || ! command -v whiptail >/dev/null 2>&1; then
        select_preset_simple
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

# Simple fallback preset selection
select_preset_simple() {
    echo "" | tee -a "$LOG"
    echo "${NOTE} Available Presets:" | tee -a "$LOG"
    echo "  1) Custom - Manual selection" | tee -a "$LOG"
    echo "  2) Showcase - Maximum eye-candy" | tee -a "$LOG"
    echo "  3) Gaming - Performance optimized" | tee -a "$LOG"
    echo "  4) Work - Productivity focused" | tee -a "$LOG"
    echo "  5) Minimal - Lightweight setup" | tee -a "$LOG"
    echo "  6) Hybrid - Balanced configuration" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "Enter choice (1-6) or press Enter for Custom:"
    read -r choice
    
    case "$choice" in
        2) PRESET="showcase" ;;
        3) PRESET="gaming" ;;
        4) PRESET="work" ;;
        5) PRESET="minimal" ;;
        6) PRESET="hybrid" ;;
        *) PRESET="custom" ;;
    esac
    
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
                    if ! git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git sources/jakoolit; then
                        echo "${ERROR} Failed to clone JaKooLit Arch-Hyprland repository" | tee -a "$LOG"
                        exit 1
                    fi
                    if ! git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git sources/jakoolit-dots; then
                        echo "${ERROR} Failed to clone JaKooLit Hyprland-Dots repository" | tee -a "$LOG"
                        exit 1
                    fi
                fi
                ;;
            "ml4w")
                if [ ! -d "sources/ml4w" ]; then
                    echo "${NOTE} Downloading ML4W configuration..." | tee -a "$LOG"
                    if ! git clone --depth=1 https://github.com/mylinuxforwork/dotfiles.git sources/ml4w; then
                        echo "${ERROR} Failed to clone ML4W dotfiles repository" | tee -a "$LOG"
                        exit 1
                    fi
                fi
                ;;
            "hyde")
                if [ ! -d "sources/hyde" ]; then
                    echo "${NOTE} Downloading HyDE configuration..." | tee -a "$LOG"
                    if ! git clone --depth=1 https://github.com/prasanthrangan/hyprdots.git sources/hyde; then
                        echo "${ERROR} Failed to clone HyDE hyprdots repository" | tee -a "$LOG"
                        exit 1
                    fi
                fi
                ;;
            "end4")
                if [ ! -d "sources/end4" ]; then
                    echo "${NOTE} Downloading End-4 configuration..." | tee -a "$LOG"
                    if ! git clone --depth=1 https://github.com/end-4/dots-hyprland.git sources/end4; then
                        echo "${ERROR} Failed to clone End-4 dots-hyprland repository" | tee -a "$LOG"
                        exit 1
                    fi
                fi
                ;;
            "prasanta")
                if [ ! -d "sources/prasanta" ]; then
                    echo "${NOTE} Downloading Prasanta configuration..." | tee -a "$LOG"
                    if ! git clone --depth=1 https://github.com/prasanthrangan/hyprdots.git sources/prasanta; then
                        echo "${ERROR} Failed to clone Prasanta hyprdots repository" | tee -a "$LOG"
                        exit 1
                    fi
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
            "system-utils")
                ./modules/core/install_system_utils.sh
                ;;
            "notifications")
                ./modules/core/install_notifications.sh
                ;;
            "audio")
                ./modules/core/install_audio.sh
                ;;
            "bluetooth")
                ./modules/core/install_bluetooth.sh
                ;;
            "network")
                ./modules/core/install_network.sh
                ;;
            "power")
                ./modules/core/install_power.sh
                ;;
            "theme-switcher")
                ./modules/core/install_theme_switcher.sh
                ;;
            "workspace-time")
                ./modules/core/install_workspace_time.sh
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
    
    # Use the comprehensive backup system
    if [[ -f "modules/common/backup.sh" ]]; then
        BACKUP_DIR=$(bash modules/common/backup.sh backup "pre-install")
        echo "${OK} Comprehensive backup created at: $BACKUP_DIR" | tee -a "$LOG"
        export CURRENT_BACKUP_DIR="$BACKUP_DIR"
    else
        # Fallback to simple backup if backup module not available
        echo "${WARN} Backup module not found, using simple backup" | tee -a "$LOG"
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
        
        echo "${OK} Simple backup created at: $BACKUP_DIR" | tee -a "$LOG"
        export CURRENT_BACKUP_DIR="$BACKUP_DIR"
    fi
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

# GPU optimization
optimize_gpu_configuration() {
    echo "${INFO} Optimizing GPU configuration..." | tee -a "$LOG"
    
    # Check if GPU switcher is available
    if [ -f "./tools/gpu_switcher.sh" ]; then
        echo "${NOTE} Detecting GPU hardware..." | tee -a "$LOG"
        
        # Run GPU detection
        ./tools/gpu_switcher.sh detect >> "$LOG" 2>&1
        
        # Auto-optimize based on detected hardware
        echo "${NOTE} Applying optimal GPU settings..." | tee -a "$LOG"
        ./tools/gpu_switcher.sh optimize --force >> "$LOG" 2>&1
        
        # Install GPU presets for different workflows
        if [ -f "./tools/gpu_presets.sh" ]; then
            echo "${NOTE} Installing GPU presets..." | tee -a "$LOG"
            ./tools/gpu_presets.sh backup >> "$LOG" 2>&1 || true
        fi
        
        echo "${OK} GPU configuration optimized!" | tee -a "$LOG"
        echo "${INFO} You can later run 'hyprsupreme gpu' to switch profiles" | tee -a "$LOG"
    else
        echo "${WARN} GPU switcher not found, skipping GPU optimization" | tee -a "$LOG"
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

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unattended)
                UNATTENDED="true"
                echo "${INFO} Running in unattended mode" | tee -a "$LOG"
                shift
                ;;
            --preset)
                if [[ -n "$2" ]]; then
                    PRESET_ARG="$2"
                    shift 2
                else
                    echo "${ERROR} --preset requires a value" | tee -a "$LOG"
                    exit 1
                fi
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "${ERROR} Unknown option: $1" | tee -a "$LOG"
                echo "${INFO} Use --help for usage information" | tee -a "$LOG"
                exit 1
                ;;
        esac
    done
}

# Show help information
show_help() {
    echo "HyprSupreme-Builder Installation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --unattended      Run in unattended mode (no user prompts)"
    echo "  --preset NAME     Use predefined configuration preset"
    echo "                    Available presets: showcase, gaming, work, minimal, hybrid"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Interactive installation"
    echo "  $0 --preset gaming   # Gaming optimized setup"
    echo "  $0 --unattended --preset minimal  # Automated minimal install"
    echo ""
}

# Main installation function
main() {
    # Initialize all global variables
    UNATTENDED="false"
    PRESET_ARG=""
    PRESET="custom"
    SELECTED_CONFIGS=""
    SELECTED_COMPONENTS=""
    SELECTED_FEATURES=""
    DISTRO=""
    DISTRO_VERSION=""
    PACKAGE_MANAGER=""
    AUR_HELPER=""
    CONFIG_DIR="$HOME/.config"
    BACKUP_DIR=""
    
    # Export critical variables
    export UNATTENDED PRESET SELECTED_CONFIGS SELECTED_COMPONENTS SELECTED_FEATURES
    export DISTRO DISTRO_VERSION PACKAGE_MANAGER AUR_HELPER CONFIG_DIR
    
    # Parse command line arguments
    parse_arguments "$@"
    
    print_banner
    
    echo "${INFO} Starting HyprSupreme-Builder installation..." | tee -a "$LOG"
    echo "${INFO} Log file: $LOG" | tee -a "$LOG"
    
    if [[ "$UNATTENDED" == "true" ]]; then
        echo "${WARN} UNATTENDED MODE: Packages will be installed without confirmation" | tee -a "$LOG"
        echo "${INFO} Press Ctrl+C within 5 seconds to cancel..." | tee -a "$LOG"
        sleep 5
    fi
    
    # Pre-installation checks
    check_root
    # Load and run distribution detection
    if [ -f "modules/common/distro_support.sh" ]; then
        source modules/common/distro_support.sh
        detect_distribution
    else
        detect_distro  # Fallback to original function
    fi
    
    check_system_dependencies
    install_dependencies
    check_aur_helper
    
    # Configuration
    if [[ -n "$PRESET_ARG" ]]; then
        select_preset "--preset" "$PRESET_ARG"
    else
        select_preset
    fi
    
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
    
    # GPU optimization
    optimize_gpu_configuration
    
    # Summary
    show_summary
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

