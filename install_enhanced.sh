#!/bin/bash
# HyprSupreme-Builder Enhanced Installation Script
# Modular, robust installation with comprehensive error handling
# https://github.com/GeneticxCln/HyprSupreme-Builder

set -euo pipefail

# Initialize Enhanced Error Handling System
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_ROOT/modules/common/enhanced_error_system.sh" ]]; then
    source "$SCRIPT_ROOT/modules/common/enhanced_error_system.sh"
    
    # Configure enhanced error handling for installation
    configure_enhanced_error_system \
        --enable-monitoring \
        --enable-prediction \
        --enable-self-healing \
        --enable-analytics \
        --enable-recovery \
        --interactive-recovery \
        --monitoring-interval 20
        
    # Initialize the enhanced error system
    init_enhanced_error_system "$SCRIPT_ROOT/logs" "hyprsupreme-install"
    
    log_message "SUCCESS" "Enhanced error handling system activated"
else
    echo "WARNING: Enhanced error handling system not found - using basic error handling"
    echo "For best experience, ensure all modules are properly installed"
fi

#=====================================
# Script Metadata & Configuration
#=====================================

readonly SCRIPT_NAME="HyprSupreme-Builder Enhanced Installer"
readonly VERSION="2.1.1"
readonly PROJECT_NAME="HyprSupreme-Builder"
readonly GITHUB_REPO="GeneticxCln/HyprSupreme-Builder"
readonly MIN_BASH_VERSION="4.0"

# Directories and paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="$SCRIPT_DIR/logs"
readonly BACKUP_DIR="$HOME/HyprSupreme-Backups"
readonly CONFIG_DIR="$HOME/.config"
readonly CACHE_DIR="$HOME/.cache/hyprsupreme"

# System requirements
readonly MIN_RAM_GB=4
readonly MIN_STORAGE_GB=8
readonly RECOMMENDED_RAM_GB=8
readonly RECOMMENDED_STORAGE_GB=20

#=====================================
# Color Definitions
#=====================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m' # No Color

# Status indicators
readonly OK="${GREEN}✓${NC}"
readonly ERROR="${RED}✗${NC}"
readonly WARN="${YELLOW}⚠${NC}"
readonly INFO="${BLUE}ℹ${NC}"
readonly QUESTION="${PURPLE}?${NC}"
readonly ARROW="${CYAN}→${NC}"

#=====================================
# Global Variables
#=====================================

# Installation options
PRESET=""
THEME=""
GPU_TYPE=""
AUDIO_BACKEND=""
RESOLUTION=""
UNATTENDED=false
SKIP_CONFIRMATION=false
VERBOSE=false
DRY_RUN=false
FORCE_INSTALL=false
BACKUP_EXISTING=true

# System information
DISTRO_ID=""
DISTRO_FAMILY=""
PACKAGE_MANAGER=""
SUPPORT_LEVEL=""
SYSTEM_ARCH=""

# Installation state
LOG_FILE=""
CURRENT_BACKUP_DIR=""
TEMP_DIR=""
SUDO_KEEPER_PID=""
INSTALLATION_STEP=0
TOTAL_STEPS=12

# Error tracking
declare -a ERRORS=()
declare -a WARNINGS=()
declare -a INSTALLED_PACKAGES=()

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_INVALID_ARGS=1
readonly EXIT_SYSTEM_CHECK_FAILED=2
readonly EXIT_DEPENDENCY_FAILED=3
readonly EXIT_INSTALLATION_FAILED=4
readonly EXIT_USER_CANCELLED=5

#=====================================
# Utility Functions
#=====================================

print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                   $SCRIPT_NAME                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}                        v$VERSION                           ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║${YELLOW}          The Ultimate Hyprland Configuration Suite          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${ERROR} ${RED}$message${NC}" >&2
            ERRORS+=("$message")
            ;;
        "WARN")
            echo -e "${WARN} ${YELLOW}$message${NC}"
            WARNINGS+=("$message")
            ;;
        "INFO")
            echo -e "${INFO} ${message}"
            ;;
        "SUCCESS")
            echo -e "${OK} ${GREEN}$message${NC}"
            ;;
        "QUESTION")
            echo -e "${QUESTION} ${PURPLE}$message${NC}"
            ;;
        "STEP")
            ((INSTALLATION_STEP++))
            echo -e "${ARROW} ${CYAN}[$INSTALLATION_STEP/$TOTAL_STEPS] $message${NC}"
            ;;
    esac
    
    # Write to log file
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
    
    # Verbose output
    if [[ "$VERBOSE" == true ]]; then
        echo "[$timestamp] [$level] $message" >&2
    fi
}

progress_bar() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}Progress: [${NC}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "${CYAN}] ${WHITE}%d%%${NC}" "$percentage"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Enhanced installation script for HyprSupreme-Builder with improved error handling.

OPTIONS:
    -p, --preset PRESET         Installation preset (minimal|gaming|work|developer|custom)
    -t, --theme THEME           Theme to apply (catppuccin|gruvbox|nord|tokyo-night|dracula)
    -g, --gpu GPU_TYPE          GPU type (auto|nvidia|amd|intel|hybrid)
    -a, --audio BACKEND         Audio backend (auto|pipewire|pulseaudio)
    -r, --resolution RESOLUTION Monitor resolution (auto|1920x1080|2560x1440|3840x2160)
    
    -u, --unattended            Run in unattended mode (no user interaction)
    -y, --yes                   Skip confirmation prompts
    -v, --verbose               Enable verbose output
    -n, --dry-run               Show what would be done without executing
    -f, --force                 Force installation even if system checks fail
    --no-backup                 Skip creating backups of existing configurations
    
    -h, --help                  Show this help message
    --version                   Show version information

PRESETS:
    minimal     Essential components only (fastest installation)
    gaming      Gaming optimizations and performance tweaks
    work        Productivity tools and professional setup
    developer   Full development environment with tools
    custom      Interactive configuration selection

EXAMPLES:
    $0                                          # Interactive installation
    $0 --preset gaming --theme catppuccin       # Gaming setup with Catppuccin theme
    $0 --unattended --preset minimal            # Automated minimal installation
    $0 --verbose --dry-run                      # Test run with detailed output

For more information, see: INSTALLATION_GUIDE.md

EOF
}

show_version() {
    echo "$SCRIPT_NAME v$VERSION"
    echo "HyprSupreme-Builder Project"
    echo "https://github.com/$GITHUB_REPO"
}

#=====================================
# Error Handling Functions
#=====================================

cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_message "ERROR" "Installation failed with exit code $exit_code"
        
        # Stop sudo keeper if running
        if [[ -n "${SUDO_KEEPER_PID:-}" ]]; then
            kill "$SUDO_KEEPER_PID" 2>/dev/null || true
        fi
        
        # Clean up temporary files
        if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
            rm -rf "$TEMP_DIR" 2>/dev/null || true
        fi
        
        # Show available backup
        if [[ -n "${CURRENT_BACKUP_DIR:-}" && -d "$CURRENT_BACKUP_DIR" ]]; then
            log_message "INFO" "Backup available at: $CURRENT_BACKUP_DIR"
        fi
        
        # Show error summary
        if [[ ${#ERRORS[@]} -gt 0 ]]; then
            echo
            log_message "ERROR" "Installation failed with ${#ERRORS[@]} error(s):"
            for error in "${ERRORS[@]}"; do
                echo "  • $error"
            done
        fi
        
        echo
        log_message "INFO" "For troubleshooting help, check:"
        log_message "INFO" "  • Log file: $LOG_FILE"
        log_message "INFO" "  • Documentation: TROUBLESHOOTING.md"
        log_message "INFO" "  • GitHub Issues: https://github.com/$GITHUB_REPO/issues"
    fi
}

trap cleanup EXIT ERR INT TERM

error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    log_message "ERROR" "$message"
    exit "$exit_code"
}

check_prerequisites() {
    log_message "STEP" "Checking system prerequisites"
    
    # Check if prerequisite verifier exists and run it
    local prereq_script="$SCRIPT_DIR/tools/verify_prerequisites.sh"
    if [[ -f "$prereq_script" ]]; then
        log_message "INFO" "Running comprehensive prerequisite check..."
        
        local check_args=()
        [[ "$VERBOSE" == true ]] && check_args+=("--verbose")
        [[ "$UNATTENDED" == true ]] && check_args+=("--check-only")
        
        if ! "$prereq_script" "${check_args[@]}"; then
            if [[ "$FORCE_INSTALL" == true ]]; then
                log_message "WARN" "Prerequisite check failed but continuing due to --force"
            else
                error_exit "System prerequisites check failed. Use --force to override." $EXIT_SYSTEM_CHECK_FAILED
            fi
        fi
    else
        log_message "WARN" "Prerequisite verifier not found, performing basic checks"
        basic_system_check
    fi
}

basic_system_check() {
    # Basic fallback checks if comprehensive verifier is not available
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root" $EXIT_SYSTEM_CHECK_FAILED
    fi
    
    # Check Bash version
    local bash_version="${BASH_VERSION%%.*}"
    local min_version="${MIN_BASH_VERSION%%.*}"
    if (( bash_version < min_version )); then
        error_exit "Bash version $BASH_VERSION is too old (minimum: $MIN_BASH_VERSION)" $EXIT_SYSTEM_CHECK_FAILED
    fi
    
    # Check basic commands
    local required_commands=("sudo" "git" "curl" "wget")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            error_exit "Required command '$cmd' not found" $EXIT_DEPENDENCY_FAILED
        fi
    done
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null && ! sudo -v; then
        error_exit "Sudo access required but not available" $EXIT_SYSTEM_CHECK_FAILED
    fi
    
    # Check disk space
    local available_gb=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    if (( available_gb < MIN_STORAGE_GB )); then
        error_exit "Insufficient disk space: ${available_gb}GB (minimum: ${MIN_STORAGE_GB}GB)" $EXIT_SYSTEM_CHECK_FAILED
    fi
    
    # Check RAM
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    if (( ram_gb < MIN_RAM_GB )); then
        if [[ "$FORCE_INSTALL" == true ]]; then
            log_message "WARN" "Low RAM: ${ram_gb}GB (minimum: ${MIN_RAM_GB}GB) - continuing due to --force"
        else
            error_exit "Insufficient RAM: ${ram_gb}GB (minimum: ${MIN_RAM_GB}GB)" $EXIT_SYSTEM_CHECK_FAILED
        fi
    fi
    
    log_message "SUCCESS" "Basic system checks passed"
}

#=====================================
# System Detection Functions
#=====================================

detect_system() {
    log_message "STEP" "Detecting system configuration"
    
    # Get system information
    if [[ ! -f /etc/os-release ]]; then
        error_exit "Cannot detect operating system - /etc/os-release missing" $EXIT_SYSTEM_CHECK_FAILED
    fi
    
    source /etc/os-release
    DISTRO_ID="${ID,,}"
    SYSTEM_ARCH="$(uname -m)"
    
    log_message "INFO" "Operating System: $PRETTY_NAME"
    log_message "INFO" "Architecture: $SYSTEM_ARCH"
    
    # Determine distribution family and package manager
    case "$DISTRO_ID" in
        arch|endeavouros|cachyos|manjaro|garuda)
            PACKAGE_MANAGER="pacman"
            DISTRO_FAMILY="arch"
            SUPPORT_LEVEL="full"
            ;;
        ubuntu|debian|linuxmint|pop|elementary)
            PACKAGE_MANAGER="apt"
            DISTRO_FAMILY="debian"
            SUPPORT_LEVEL="limited"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            PACKAGE_MANAGER="dnf"
            DISTRO_FAMILY="redhat"
            SUPPORT_LEVEL="limited"
            ;;
        opensuse*|suse)
            PACKAGE_MANAGER="zypper"
            DISTRO_FAMILY="suse"
            SUPPORT_LEVEL="limited"
            ;;
        *)
            error_exit "Unsupported distribution: $PRETTY_NAME" $EXIT_SYSTEM_CHECK_FAILED
            ;;
    esac
    
    log_message "INFO" "Distribution family: $DISTRO_FAMILY"
    log_message "INFO" "Package manager: $PACKAGE_MANAGER"
    log_message "INFO" "Support level: $SUPPORT_LEVEL"
    
    if [[ "$SUPPORT_LEVEL" != "full" ]]; then
        log_message "WARN" "Limited support for this distribution - some features may not work"
    fi
}

#=====================================
# Preset Configuration Functions
#=====================================

configure_preset() {
    if [[ -z "$PRESET" ]]; then
        if [[ "$UNATTENDED" == true ]]; then
            PRESET="minimal"
            log_message "INFO" "Unattended mode: Using minimal preset"
        else
            select_preset_interactive
        fi
    fi
    
    log_message "STEP" "Configuring installation preset: $PRESET"
    
    case "$PRESET" in
        minimal)
            configure_minimal_preset
            ;;
        gaming)
            configure_gaming_preset
            ;;
        work)
            configure_work_preset
            ;;
        developer)
            configure_developer_preset
            ;;
        custom)
            configure_custom_preset
            ;;
        *)
            error_exit "Unknown preset: $PRESET" $EXIT_INVALID_ARGS
            ;;
    esac
}

select_preset_interactive() {
    echo
    log_message "QUESTION" "Select installation preset:"
    echo "  1) minimal     - Essential components only (fastest)"
    echo "  2) gaming      - Gaming optimizations and performance"
    echo "  3) work        - Productivity tools and professional setup"
    echo "  4) developer   - Full development environment"
    echo "  5) custom      - Interactive configuration selection"
    echo
    
    while true; do
        read -p "Enter choice [1-5]: " choice
        case "$choice" in
            1) PRESET="minimal"; break ;;
            2) PRESET="gaming"; break ;;
            3) PRESET="work"; break ;;
            4) PRESET="developer"; break ;;
            5) PRESET="custom"; break ;;
            *) echo "Invalid choice. Please enter 1-5." ;;
        esac
    done
    
    log_message "INFO" "Selected preset: $PRESET"
}

configure_minimal_preset() {
    THEME="${THEME:-catppuccin}"
    GPU_TYPE="${GPU_TYPE:-auto}"
    AUDIO_BACKEND="${AUDIO_BACKEND:-auto}"
    RESOLUTION="${RESOLUTION:-auto}"
    
    log_message "INFO" "Minimal preset configured"
}

configure_gaming_preset() {
    THEME="${THEME:-gruvbox}"
    GPU_TYPE="${GPU_TYPE:-auto}"
    AUDIO_BACKEND="${AUDIO_BACKEND:-pipewire}"
    RESOLUTION="${RESOLUTION:-auto}"
    
    log_message "INFO" "Gaming preset configured with performance optimizations"
}

configure_work_preset() {
    THEME="${THEME:-nord}"
    GPU_TYPE="${GPU_TYPE:-auto}"
    AUDIO_BACKEND="${AUDIO_BACKEND:-pipewire}"
    RESOLUTION="${RESOLUTION:-auto}"
    
    log_message "INFO" "Work preset configured with productivity tools"
}

configure_developer_preset() {
    THEME="${THEME:-tokyo-night}"
    GPU_TYPE="${GPU_TYPE:-auto}"
    AUDIO_BACKEND="${AUDIO_BACKEND:-pipewire}"
    RESOLUTION="${RESOLUTION:-auto}"
    
    log_message "INFO" "Developer preset configured with development tools"
}

configure_custom_preset() {
    if [[ "$UNATTENDED" == true ]]; then
        error_exit "Custom preset requires interactive mode" $EXIT_INVALID_ARGS
    fi
    
    log_message "INFO" "Custom preset - interactive configuration"
    
    # Theme selection
    if [[ -z "$THEME" ]]; then
        select_theme_interactive
    fi
    
    # GPU selection
    if [[ -z "$GPU_TYPE" ]]; then
        select_gpu_interactive
    fi
    
    # Audio selection
    if [[ -z "$AUDIO_BACKEND" ]]; then
        select_audio_interactive
    fi
    
    # Resolution selection
    if [[ -z "$RESOLUTION" ]]; then
        select_resolution_interactive
    fi
}

select_theme_interactive() {
    echo
    log_message "QUESTION" "Select theme:"
    echo "  1) catppuccin  - Soothing pastel theme"
    echo "  2) gruvbox     - Retro groove colors"
    echo "  3) nord        - Arctic, north-bluish clean theme"
    echo "  4) tokyo-night - Dark theme inspired by Tokyo's night"
    echo "  5) dracula     - Dark theme with bright colors"
    echo "  6) auto        - Auto-detect best theme for system"
    echo
    
    while true; do
        read -p "Enter choice [1-6]: " choice
        case "$choice" in
            1) THEME="catppuccin"; break ;;
            2) THEME="gruvbox"; break ;;
            3) THEME="nord"; break ;;
            4) THEME="tokyo-night"; break ;;
            5) THEME="dracula"; break ;;
            6) THEME="auto"; break ;;
            *) echo "Invalid choice. Please enter 1-6." ;;
        esac
    done
    
    log_message "INFO" "Selected theme: $THEME"
}

select_gpu_interactive() {
    echo
    log_message "QUESTION" "Select GPU configuration:"
    echo "  1) auto        - Auto-detect GPU and configure drivers"
    echo "  2) nvidia      - NVIDIA proprietary drivers"
    echo "  3) amd         - AMD open-source drivers"
    echo "  4) intel       - Intel integrated graphics"
    echo "  5) hybrid      - Laptop with dual GPU setup"
    echo
    
    while true; do
        read -p "Enter choice [1-5]: " choice
        case "$choice" in
            1) GPU_TYPE="auto"; break ;;
            2) GPU_TYPE="nvidia"; break ;;
            3) GPU_TYPE="amd"; break ;;
            4) GPU_TYPE="intel"; break ;;
            5) GPU_TYPE="hybrid"; break ;;
            *) echo "Invalid choice. Please enter 1-5." ;;
        esac
    done
    
    log_message "INFO" "Selected GPU: $GPU_TYPE"
}

select_audio_interactive() {
    echo
    log_message "QUESTION" "Select audio backend:"
    echo "  1) auto        - Auto-detect best audio system"
    echo "  2) pipewire    - Modern audio system (recommended)"
    echo "  3) pulseaudio  - Traditional audio system"
    echo
    
    while true; do
        read -p "Enter choice [1-3]: " choice
        case "$choice" in
            1) AUDIO_BACKEND="auto"; break ;;
            2) AUDIO_BACKEND="pipewire"; break ;;
            3) AUDIO_BACKEND="pulseaudio"; break ;;
            *) echo "Invalid choice. Please enter 1-3." ;;
        esac
    done
    
    log_message "INFO" "Selected audio: $AUDIO_BACKEND"
}

select_resolution_interactive() {
    echo
    log_message "QUESTION" "Select default resolution:"
    echo "  1) auto        - Auto-detect optimal resolution"
    echo "  2) 1920x1080   - Full HD"
    echo "  3) 2560x1440   - QHD/1440p"
    echo "  4) 3840x2160   - 4K/UHD"
    echo "  5) custom      - Custom resolution"
    echo
    
    while true; do
        read -p "Enter choice [1-5]: " choice
        case "$choice" in
            1) RESOLUTION="auto"; break ;;
            2) RESOLUTION="1920x1080"; break ;;
            3) RESOLUTION="2560x1440"; break ;;
            4) RESOLUTION="3840x2160"; break ;;
            5) 
                read -p "Enter custom resolution (WIDTHxHEIGHT): " custom_res
                if [[ "$custom_res" =~ ^[0-9]+x[0-9]+$ ]]; then
                    RESOLUTION="$custom_res"
                    break
                else
                    echo "Invalid format. Use WIDTHxHEIGHT (e.g., 1920x1080)"
                fi
                ;;
            *) echo "Invalid choice. Please enter 1-5." ;;
        esac
    done
    
    log_message "INFO" "Selected resolution: $RESOLUTION"
}

#=====================================
# Installation Functions
#=====================================

setup_directories() {
    log_message "STEP" "Setting up directories"
    
    # Create required directories
    local dirs=("$LOG_DIR" "$CACHE_DIR")
    if [[ "$BACKUP_EXISTING" == true ]]; then
        dirs+=("$BACKUP_DIR")
    fi
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir"; then
                log_message "INFO" "Created directory: $dir"
            else
                error_exit "Failed to create directory: $dir" $EXIT_INSTALLATION_FAILED
            fi
        fi
    done
    
    # Set up log file
    LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
    touch "$LOG_FILE"
    log_message "INFO" "Logging to: $LOG_FILE"
    
    # Set up temporary directory
    TEMP_DIR=$(mktemp -d -t hyprsupreme-install.XXXXXX)
    log_message "INFO" "Using temp directory: $TEMP_DIR"
}

create_backup() {
    if [[ "$BACKUP_EXISTING" != true ]]; then
        log_message "INFO" "Skipping backup creation (--no-backup specified)"
        return 0
    fi
    
    log_message "STEP" "Creating backup of existing configurations"
    
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    CURRENT_BACKUP_DIR="$BACKUP_DIR/$backup_name"
    
    if mkdir -p "$CURRENT_BACKUP_DIR"; then
        log_message "INFO" "Created backup directory: $CURRENT_BACKUP_DIR"
    else
        error_exit "Failed to create backup directory" $EXIT_INSTALLATION_FAILED
    fi
    
    # Backup existing configurations
    local config_dirs=(".config/hypr" ".config/waybar" ".config/rofi" ".config/kitty")
    
    for config_dir in "${config_dirs[@]}"; do
        local source_path="$HOME/$config_dir"
        if [[ -d "$source_path" ]]; then
            local backup_path="$CURRENT_BACKUP_DIR/$config_dir"
            if mkdir -p "$(dirname "$backup_path")" && cp -r "$source_path" "$backup_path"; then
                log_message "INFO" "Backed up: $config_dir"
            else
                log_message "WARN" "Failed to backup: $config_dir"
            fi
        fi
    done
    
    # Create backup manifest
    cat > "$CURRENT_BACKUP_DIR/backup_info.txt" << EOF
HyprSupreme-Builder Backup
Created: $(date)
Preset: $PRESET
Theme: $THEME
GPU: $GPU_TYPE
Audio: $AUDIO_BACKEND
Resolution: $RESOLUTION
System: $DISTRO_ID ($SYSTEM_ARCH)
EOF
    
    log_message "SUCCESS" "Configuration backup completed"
}

install_dependencies() {
    log_message "STEP" "Installing system dependencies"
    
    case "$PACKAGE_MANAGER" in
        pacman)
            install_arch_dependencies
            ;;
        apt)
            install_debian_dependencies
            ;;
        dnf)
            install_fedora_dependencies
            ;;
        zypper)
            install_suse_dependencies
            ;;
        *)
            error_exit "Unsupported package manager: $PACKAGE_MANAGER" $EXIT_INSTALLATION_FAILED
            ;;
    esac
}

install_arch_dependencies() {
    log_message "INFO" "Installing Arch-based dependencies"
    
    local packages=(
        "git" "curl" "wget" "unzip" "base-devel"
        "hyprland" "waybar" "rofi" "kitty"
        "pipewire" "pipewire-pulse" "wireplumber"
        "grim" "slurp" "wl-clipboard"
        "python" "python-pip"
    )
    
    # Add preset-specific packages
    case "$PRESET" in
        gaming)
            packages+=("gamemode" "mangohud" "steam" "lutris")
            ;;
        work)
            packages+=("firefox" "thunderbird" "libreoffice-fresh")
            ;;
        developer)
            packages+=("code" "nodejs" "npm" "docker" "docker-compose")
            ;;
    esac
    
    if install_packages_pacman "${packages[@]}"; then
        log_message "SUCCESS" "Dependencies installed successfully"
    else
        error_exit "Failed to install dependencies" $EXIT_DEPENDENCY_FAILED
    fi
}

install_debian_dependencies() {
    log_message "INFO" "Installing Debian-based dependencies"
    log_message "WARN" "Limited support - some packages may need manual installation"
    
    # Update package list
    if ! sudo apt update; then
        error_exit "Failed to update package list" $EXIT_DEPENDENCY_FAILED
    fi
    
    local packages=(
        "git" "curl" "wget" "unzip" "build-essential"
        "pipewire" "pipewire-pulse" "wireplumber"
        "python3" "python3-pip"
    )
    
    if install_packages_apt "${packages[@]}"; then
        log_message "SUCCESS" "Basic dependencies installed"
        log_message "WARN" "Hyprland and other components may need manual compilation"
    else
        error_exit "Failed to install dependencies" $EXIT_DEPENDENCY_FAILED
    fi
}

install_fedora_dependencies() {
    log_message "INFO" "Installing Fedora-based dependencies"
    log_message "WARN" "Limited support - some packages may need COPR repositories"
    
    local packages=(
        "git" "curl" "wget" "unzip" "@development-tools"
        "pipewire" "pipewire-pulseaudio" "wireplumber"
        "python3" "python3-pip"
    )
    
    if install_packages_dnf "${packages[@]}"; then
        log_message "SUCCESS" "Basic dependencies installed"
        log_message "WARN" "Hyprland may need additional repositories"
    else
        error_exit "Failed to install dependencies" $EXIT_DEPENDENCY_FAILED
    fi
}

install_suse_dependencies() {
    log_message "INFO" "Installing SUSE-based dependencies"
    log_message "WARN" "Limited support - some packages may not be available"
    
    local packages=(
        "git" "curl" "wget" "unzip" "patterns-devel-base-devel_basis"
        "pipewire" "pipewire-pulseaudio"
        "python3" "python3-pip"
    )
    
    if install_packages_zypper "${packages[@]}"; then
        log_message "SUCCESS" "Basic dependencies installed"
        log_message "WARN" "Hyprland may need manual compilation"
    else
        error_exit "Failed to install dependencies" $EXIT_DEPENDENCY_FAILED
    fi
}

install_packages_pacman() {
    local packages=("$@")
    log_message "INFO" "Installing packages: ${packages[*]}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_message "INFO" "DRY RUN: Would install: ${packages[*]}"
        return 0
    fi
    
    local install_cmd=(sudo pacman -S --needed --noconfirm)
    [[ "$UNATTENDED" != true ]] && install_cmd=(sudo pacman -S --needed)
    
    if "${install_cmd[@]}" "${packages[@]}"; then
        INSTALLED_PACKAGES+=("${packages[@]}")
        return 0
    else
        return 1
    fi
}

install_packages_apt() {
    local packages=("$@")
    log_message "INFO" "Installing packages: ${packages[*]}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_message "INFO" "DRY RUN: Would install: ${packages[*]}"
        return 0
    fi
    
    local install_cmd=(sudo apt install -y)
    [[ "$UNATTENDED" != true ]] && install_cmd=(sudo apt install)
    
    if "${install_cmd[@]}" "${packages[@]}"; then
        INSTALLED_PACKAGES+=("${packages[@]}")
        return 0
    else
        return 1
    fi
}

install_packages_dnf() {
    local packages=("$@")
    log_message "INFO" "Installing packages: ${packages[*]}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_message "INFO" "DRY RUN: Would install: ${packages[*]}"
        return 0
    fi
    
    local install_cmd=(sudo dnf install -y)
    [[ "$UNATTENDED" != true ]] && install_cmd=(sudo dnf install)
    
    if "${install_cmd[@]}" "${packages[@]}"; then
        INSTALLED_PACKAGES+=("${packages[@]}")
        return 0
    else
        return 1
    fi
}

install_packages_zypper() {
    local packages=("$@")
    log_message "INFO" "Installing packages: ${packages[*]}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_message "INFO" "DRY RUN: Would install: ${packages[*]}"
        return 0
    fi
    
    local install_cmd=(sudo zypper install -y)
    [[ "$UNATTENDED" != true ]] && install_cmd=(sudo zypper install)
    
    if "${install_cmd[@]}" "${packages[@]}"; then
        INSTALLED_PACKAGES+=("${packages[@]}")
        return 0
    else
        return 1
    fi
}

#=====================================
# Configuration Functions
#=====================================

configure_hyprland() {
    log_message "STEP" "Configuring Hyprland"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_message "INFO" "DRY RUN: Would configure Hyprland"
        return 0
    fi
    
    # Use existing configuration scripts if available
    if [[ -f "$SCRIPT_DIR/modules/core/install_hyprland.sh" ]]; then
        log_message "INFO" "Using existing Hyprland installation module"
        if bash "$SCRIPT_DIR/modules/core/install_hyprland.sh"; then
            log_message "SUCCESS" "Hyprland configured successfully"
        else
            error_exit "Failed to configure Hyprland" $EXIT_INSTALLATION_FAILED
        fi
    else
        log_message "INFO" "Creating basic Hyprland configuration"
        create_basic_hyprland_config
    fi
}

create_basic_hyprland_config() {
    local hypr_dir="$CONFIG_DIR/hypr"
    mkdir -p "$hypr_dir"
    
    cat > "$hypr_dir/hyprland.conf" << 'EOF'
# HyprSupreme-Builder Basic Configuration
# Generated by Enhanced Installer

# Monitor configuration
monitor=,preferred,auto,1

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = no
    }
    sensitivity = 0
}

# General configuration
general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decoration
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layout
dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

# Gestures
gestures {
    workspace_swipe = off
}

# Keybindings
$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, D, exec, rofi -show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Start essential services
exec-once = waybar
exec-once = hyprpaper
EOF
    
    log_message "SUCCESS" "Basic Hyprland configuration created"
}

apply_theme() {
    log_message "STEP" "Applying theme: $THEME"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_message "INFO" "DRY RUN: Would apply theme: $THEME"
        return 0
    fi
    
    # Use existing theme installation if available
    if [[ -f "$SCRIPT_DIR/modules/themes/install_themes.sh" ]]; then
        log_message "INFO" "Using existing theme installation module"
        SELECTED_THEME="$THEME" bash "$SCRIPT_DIR/modules/themes/install_themes.sh"
    else
        log_message "INFO" "Creating basic theme configuration"
        create_basic_theme_config
    fi
}

create_basic_theme_config() {
    local theme_dir="$CONFIG_DIR/hyprsupreme/themes"
    mkdir -p "$theme_dir"
    
    case "$THEME" in
        catppuccin)
            create_catppuccin_theme
            ;;
        gruvbox)
            create_gruvbox_theme
            ;;
        nord)
            create_nord_theme
            ;;
        *)
            log_message "WARN" "Unknown theme: $THEME, using default"
            create_default_theme
            ;;
    esac
}

create_catppuccin_theme() {
    cat > "$CONFIG_DIR/hyprsupreme/themes/catppuccin.conf" << 'EOF'
# Catppuccin Theme for HyprSupreme-Builder

$base = 0xff1e1e2e
$mantle = 0xff181825
$crust = 0xff11111b
$text = 0xffcdd6f4
$subtext0 = 0xffa6adc8
$subtext1 = 0xffbac2de
$surface0 = 0xff313244
$surface1 = 0xff45475a
$surface2 = 0xff585b70
$overlay0 = 0xff6c7086
$overlay1 = 0xff7f849c
$overlay2 = 0xff9399b2
$blue = 0xff89b4fa
$lavender = 0xffb4befe
$sapphire = 0xff74c7ec
$sky = 0xff89dceb
$teal = 0xff94e2d5
$green = 0xffa6e3a1
$yellow = 0xfff9e2af
$peach = 0xfffab387
$maroon = 0xffeba0ac
$red = 0xfff38ba8
$mauve = 0xffcba6f7
$pink = 0xfff5c2e7
$flamingo = 0xfff2cdcd
$rosewater = 0xfff5e0dc

general {
    col.active_border = $mauve $pink 45deg
    col.inactive_border = $surface0
}

decoration {
    col.shadow = $crust
}
EOF
    
    log_message "SUCCESS" "Catppuccin theme configuration created"
}

create_gruvbox_theme() {
    cat > "$CONFIG_DIR/hyprsupreme/themes/gruvbox.conf" << 'EOF'
# Gruvbox Theme for HyprSupreme-Builder

$bg = 0xff282828
$fg = 0xffebdbb2
$red = 0xffcc241d
$green = 0xff98971a
$yellow = 0xffd79921
$blue = 0xff458588
$purple = 0xffb16286
$aqua = 0xff689d6a
$orange = 0xffd65d0e
$gray = 0xffa89984

general {
    col.active_border = $orange $yellow 45deg
    col.inactive_border = $gray
}

decoration {
    col.shadow = $bg
}
EOF
    
    log_message "SUCCESS" "Gruvbox theme configuration created"
}

create_nord_theme() {
    cat > "$CONFIG_DIR/hyprsupreme/themes/nord.conf" << 'EOF'
# Nord Theme for HyprSupreme-Builder

$nord0 = 0xff2e3440
$nord1 = 0xff3b4252
$nord2 = 0xff434c5e
$nord3 = 0xff4c566a
$nord4 = 0xffd8dee9
$nord5 = 0xffe5e9f0
$nord6 = 0xffeceff4
$nord7 = 0xff8fbcbb
$nord8 = 0xff88c0d0
$nord9 = 0xff81a1c1
$nord10 = 0xff5e81ac
$nord11 = 0xffbf616a
$nord12 = 0xffd08770
$nord13 = 0xffebcb8b
$nord14 = 0xffa3be8c
$nord15 = 0xffb48ead

general {
    col.active_border = $nord8 $nord9 45deg
    col.inactive_border = $nord1
}

decoration {
    col.shadow = $nord0
}
EOF
    
    log_message "SUCCESS" "Nord theme configuration created"
}

create_default_theme() {
    cat > "$CONFIG_DIR/hyprsupreme/themes/default.conf" << 'EOF'
# Default Theme for HyprSupreme-Builder

general {
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
}

decoration {
    col.shadow = rgba(1a1a1aee)
}
EOF
    
    log_message "SUCCESS" "Default theme configuration created"
}

finalize_installation() {
    log_message "STEP" "Finalizing installation"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_message "INFO" "DRY RUN: Would finalize installation"
        return 0
    fi
    
    # Create desktop entry
    create_desktop_entry
    
    # Set up user service
    setup_user_service
    
    # Generate configuration summary
    generate_config_summary
    
    log_message "SUCCESS" "Installation finalized"
}

create_desktop_entry() {
    local desktop_file="$HOME/.local/share/applications/hyprsupreme.desktop"
    mkdir -p "$(dirname "$desktop_file")"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=HyprSupreme Builder
Comment=Ultimate Hyprland Configuration Suite
Exec=$SCRIPT_DIR/hyprsupreme
Icon=preferences-desktop
Terminal=false
StartupNotify=true
Categories=System;Settings;
Keywords=hyprland;wayland;configuration;
EOF
    
    log_message "INFO" "Desktop entry created"
}

setup_user_service() {
    local service_dir="$HOME/.config/systemd/user"
    mkdir -p "$service_dir"
    
    cat > "$service_dir/hyprsupreme.service" << EOF
[Unit]
Description=HyprSupreme Background Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=$SCRIPT_DIR/hyprsupreme --daemon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
    
    log_message "INFO" "User service created"
}

generate_config_summary() {
    local summary_file="$HOME/.config/hyprsupreme/installation_summary.txt"
    mkdir -p "$(dirname "$summary_file")"
    
    cat > "$summary_file" << EOF
# HyprSupreme-Builder Installation Summary
Generated: $(date)
Installer Version: $VERSION

## Configuration
Preset: $PRESET
Theme: $THEME
GPU Type: $GPU_TYPE
Audio Backend: $AUDIO_BACKEND
Resolution: $RESOLUTION

## System Information
Distribution: $DISTRO_ID
Architecture: $SYSTEM_ARCH
Package Manager: $PACKAGE_MANAGER
Support Level: $SUPPORT_LEVEL

## Installation Details
Backup Created: $([[ "$BACKUP_EXISTING" == true ]] && echo "Yes ($CURRENT_BACKUP_DIR)" || echo "No")
Packages Installed: ${#INSTALLED_PACKAGES[@]}
Log File: $LOG_FILE

## Installed Packages
$(printf '%s\n' "${INSTALLED_PACKAGES[@]}")

## Next Steps
1. Log out and log back in with Hyprland session
2. Run: ./hyprsupreme --post-install for additional setup
3. Check documentation in INSTALLATION_GUIDE.md
4. Visit community platform: ./launch_web.sh

For support: https://github.com/$GITHUB_REPO/issues
EOF
    
    log_message "INFO" "Installation summary saved to: $summary_file"
}

#=====================================
# Post-Installation Functions
#=====================================

show_completion_message() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${WHITE}               INSTALLATION COMPLETED SUCCESSFULLY!              ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    log_message "SUCCESS" "HyprSupreme-Builder installation completed!"
    echo
    log_message "INFO" "Configuration Summary:"
    echo "  • Preset: $PRESET"
    echo "  • Theme: $THEME"
    echo "  • GPU: $GPU_TYPE"
    echo "  • Audio: $AUDIO_BACKEND"
    echo "  • Resolution: $RESOLUTION"
    echo
    
    if [[ "$BACKUP_EXISTING" == true && -n "$CURRENT_BACKUP_DIR" ]]; then
        log_message "INFO" "Backup created: $CURRENT_BACKUP_DIR"
    fi
    
    echo
    log_message "INFO" "Next steps:"
    echo "  1. Log out and select Hyprland session"
    echo "  2. Run: ./hyprsupreme --setup for additional configuration"
    echo "  3. Test keybindings: ./test_keybindings.sh"
    echo "  4. Browse community themes: ./launch_web.sh"
    echo
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        log_message "WARN" "Installation completed with ${#WARNINGS[@]} warning(s):"
        for warning in "${WARNINGS[@]}"; do
            echo "  • $warning"
        done
        echo
    fi
    
    log_message "INFO" "Documentation:"
    echo "  • Installation Guide: INSTALLATION_GUIDE.md"
    echo "  • Keybindings: KEYBINDINGS_REFERENCE.md"
    echo "  • Troubleshooting: TROUBLESHOOTING.md"
    echo "  • Community: COMMUNITY_COMMANDS.md"
    echo
    
    log_message "INFO" "Support:"
    echo "  • GitHub Issues: https://github.com/$GITHUB_REPO/issues"
    echo "  • Discussions: https://github.com/$GITHUB_REPO/discussions"
    echo "  • Log file: $LOG_FILE"
    echo
    
    echo -e "${CYAN}Thank you for using HyprSupreme-Builder! 🎉${NC}"
}

#=====================================
# Main Installation Flow
#=====================================

main() {
    print_banner
    
    # Parse command line arguments first
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--preset)
                PRESET="$2"
                shift 2
                ;;
            -t|--theme)
                THEME="$2"
                shift 2
                ;;
            -g|--gpu)
                GPU_TYPE="$2"
                shift 2
                ;;
            -a|--audio)
                AUDIO_BACKEND="$2"
                shift 2
                ;;
            -r|--resolution)
                RESOLUTION="$2"
                shift 2
                ;;
            -u|--unattended)
                UNATTENDED=true
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE_INSTALL=true
                shift
                ;;
            --no-backup)
                BACKUP_EXISTING=false
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            *)
                error_exit "Unknown option: $1" $EXIT_INVALID_ARGS
                ;;
        esac
    done
    
    # Show configuration if dry run
    if [[ "$DRY_RUN" == true ]]; then
        log_message "INFO" "DRY RUN MODE - No changes will be made"
        echo
    fi
    
    # Show configuration summary
    log_message "INFO" "Installation Configuration:"
    echo "  • Preset: ${PRESET:-<interactive>}"
    echo "  • Theme: ${THEME:-<auto-detect>}"
    echo "  • GPU: ${GPU_TYPE:-<auto-detect>}"
    echo "  • Audio: ${AUDIO_BACKEND:-<auto-detect>}"
    echo "  • Resolution: ${RESOLUTION:-<auto-detect>}"
    echo "  • Unattended: $UNATTENDED"
    echo "  • Backup: $BACKUP_EXISTING"
    echo "  • Verbose: $VERBOSE"
    echo "  • Dry Run: $DRY_RUN"
    echo
    
    # Confirmation prompt
    if [[ "$SKIP_CONFIRMATION" != true && "$UNATTENDED" != true && "$DRY_RUN" != true ]]; then
        log_message "QUESTION" "Proceed with installation? [Y/n]"
        read -r response
        case "$response" in
            [nN][oO]|[nN])
                log_message "INFO" "Installation cancelled by user"
                exit $EXIT_USER_CANCELLED
                ;;
        esac
    fi
    
    # Main installation flow
    check_prerequisites
    detect_system
    configure_preset
    setup_directories
    create_backup
    install_dependencies
    configure_hyprland
    apply_theme
    finalize_installation
    
    # Show completion message
    if [[ "$DRY_RUN" != true ]]; then
        show_completion_message
    else
        log_message "INFO" "DRY RUN completed - no changes were made"
    fi
}

# Run main function with all arguments
main "$@"

