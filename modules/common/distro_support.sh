#!/bin/bash
# HyprSupreme-Builder - Distribution Support Module

# Exit on any error, undefined variable, or pipe failure
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/functions.sh"

# Distribution detection and package manager setup
detect_distribution() {
    log_info "Detecting Linux distribution..."
    
    # Initialize variables
    DISTRO_ID=""
    DISTRO_NAME=""
    DISTRO_VERSION=""
    PACKAGE_MANAGER=""
    INSTALL_CMD=""
    SEARCH_CMD=""
    UPDATE_CMD=""
    AUR_SUPPORT="false"
    
    # Read /etc/os-release for distribution info
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_NAME="$NAME"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        DISTRO_ID="${DISTRIB_ID,,}"
        DISTRO_NAME="$DISTRIB_DESCRIPTION"
        DISTRO_VERSION="$DISTRIB_RELEASE"
    else
        log_error "Cannot detect distribution. /etc/os-release not found."
        return 1
    fi
    
    log_info "Detected: $DISTRO_NAME ($DISTRO_ID) $DISTRO_VERSION"
    
    # Set package manager and commands based on distribution
    case "$DISTRO_ID" in
        arch|endeavouros|cachyos|manjaro|garuda|artix)
            PACKAGE_MANAGER="pacman"
            INSTALL_CMD="sudo pacman -S"
            SEARCH_CMD="pacman -Ss"
            UPDATE_CMD="sudo pacman -Syu"
            AUR_SUPPORT="true"
            setup_arch_like_system
            ;;
        ubuntu|debian|linuxmint|pop|elementary|zorin)
            PACKAGE_MANAGER="apt"
            INSTALL_CMD="sudo apt install"
            SEARCH_CMD="apt search"
            UPDATE_CMD="sudo apt update && sudo apt upgrade"
            AUR_SUPPORT="false"
            setup_debian_like_system
            ;;
        fedora|rhel|centos|rocky|almalinux)
            PACKAGE_MANAGER="dnf"
            INSTALL_CMD="sudo dnf install"
            SEARCH_CMD="dnf search"
            UPDATE_CMD="sudo dnf update"
            AUR_SUPPORT="false"
            setup_fedora_like_system
            ;;
        opensuse*|suse)
            PACKAGE_MANAGER="zypper"
            INSTALL_CMD="sudo zypper install"
            SEARCH_CMD="zypper search"
            UPDATE_CMD="sudo zypper update"
            AUR_SUPPORT="false"
            setup_opensuse_system
            ;;
        void)
            PACKAGE_MANAGER="xbps"
            INSTALL_CMD="sudo xbps-install"
            SEARCH_CMD="xbps-query -Rs"
            UPDATE_CMD="sudo xbps-install -Su"
            AUR_SUPPORT="false"
            setup_void_system
            ;;
        gentoo)
            PACKAGE_MANAGER="portage"
            INSTALL_CMD="sudo emerge"
            SEARCH_CMD="emerge --search"
            UPDATE_CMD="sudo emerge --sync && sudo emerge -uDN @world"
            AUR_SUPPORT="false"
            setup_gentoo_system
            ;;
        alpine)
            PACKAGE_MANAGER="apk"
            INSTALL_CMD="sudo apk add"
            SEARCH_CMD="apk search"
            UPDATE_CMD="sudo apk update && sudo apk upgrade"
            AUR_SUPPORT="false"
            setup_alpine_system
            ;;
        *)
            log_warn "Distribution '$DISTRO_ID' is not officially supported"
            log_info "Attempting to detect package manager..."
            detect_package_manager_fallback
            ;;
    esac
    
    # Export variables for use by other scripts
    export DISTRO_ID DISTRO_NAME DISTRO_VERSION
    export PACKAGE_MANAGER INSTALL_CMD SEARCH_CMD UPDATE_CMD AUR_SUPPORT
    
    log_success "Distribution setup completed"
    log_info "Package Manager: $PACKAGE_MANAGER"
    log_info "AUR Support: $AUR_SUPPORT"
}

# Fallback package manager detection
detect_package_manager_fallback() {
    log_info "Attempting fallback package manager detection..."
    
    if command_exists pacman; then
        PACKAGE_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S"
        SEARCH_CMD="pacman -Ss"
        UPDATE_CMD="sudo pacman -Syu"
        AUR_SUPPORT="true"
    elif command_exists apt; then
        PACKAGE_MANAGER="apt"
        INSTALL_CMD="sudo apt install"
        SEARCH_CMD="apt search"
        UPDATE_CMD="sudo apt update && sudo apt upgrade"
    elif command_exists dnf; then
        PACKAGE_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install"
        SEARCH_CMD="dnf search"
        UPDATE_CMD="sudo dnf update"
    elif command_exists yum; then
        PACKAGE_MANAGER="yum"
        INSTALL_CMD="sudo yum install"
        SEARCH_CMD="yum search"
        UPDATE_CMD="sudo yum update"
    elif command_exists zypper; then
        PACKAGE_MANAGER="zypper"
        INSTALL_CMD="sudo zypper install"
        SEARCH_CMD="zypper search"
        UPDATE_CMD="sudo zypper update"
    elif command_exists xbps-install; then
        PACKAGE_MANAGER="xbps"
        INSTALL_CMD="sudo xbps-install"
        SEARCH_CMD="xbps-query -Rs"
        UPDATE_CMD="sudo xbps-install -Su"
    elif command_exists emerge; then
        PACKAGE_MANAGER="portage"
        INSTALL_CMD="sudo emerge"
        SEARCH_CMD="emerge --search"
        UPDATE_CMD="sudo emerge --sync && sudo emerge -uDN @world"
    elif command_exists apk; then
        PACKAGE_MANAGER="apk"
        INSTALL_CMD="sudo apk add"
        SEARCH_CMD="apk search"
        UPDATE_CMD="sudo apk update && sudo apk upgrade"
    else
        log_error "No supported package manager found"
        return 1
    fi
    
    log_warn "Using fallback detection: $PACKAGE_MANAGER"
}

# Global package mappings - declared at module level
declare -gA ARCH_PACKAGES=(
    ["git"]="git"
    ["curl"]="curl"
    ["wget"]="wget"
    ["unzip"]="unzip"
    ["hyprland"]="hyprland"
    ["waybar"]="waybar"
    ["rofi"]="rofi"
    ["kitty"]="kitty"
    ["sddm"]="sddm"
    ["fonts-noto"]="noto-fonts"
    ["fonts-awesome"]="ttf-font-awesome"
    ["python3"]="python"
    ["python3-pip"]="python-pip"
    ["base-devel"]="base-devel"
)

declare -gA DEBIAN_PACKAGES=(
    ["git"]="git"
    ["curl"]="curl"
    ["wget"]="wget"
    ["unzip"]="unzip"
    ["hyprland"]="hyprland"
    ["waybar"]="waybar"
    ["rofi"]="rofi"
    ["kitty"]="kitty"
    ["sddm"]="sddm"
    ["fonts-noto"]="fonts-noto"
    ["fonts-awesome"]="fonts-font-awesome"
    ["python3"]="python3"
    ["python3-pip"]="python3-pip"
    ["base-devel"]="build-essential"
)

declare -gA FEDORA_PACKAGES=(
    ["git"]="git"
    ["curl"]="curl"
    ["wget"]="wget"
    ["unzip"]="unzip"
    ["hyprland"]="hyprland"
    ["waybar"]="waybar"
    ["rofi"]="rofi"
    ["kitty"]="kitty"
    ["sddm"]="sddm"
    ["fonts-noto"]="google-noto-fonts"
    ["fonts-awesome"]="fontawesome-fonts"
    ["python3"]="python3"
    ["python3-pip"]="python3-pip"
    ["base-devel"]="@development-tools"
)

declare -gA OPENSUSE_PACKAGES=(
    ["git"]="git"
    ["curl"]="curl"
    ["wget"]="wget"
    ["unzip"]="unzip"
    ["hyprland"]="hyprland"
    ["waybar"]="waybar"
    ["rofi"]="rofi"
    ["kitty"]="kitty"
    ["sddm"]="sddm"
    ["fonts-noto"]="noto-sans-fonts"
    ["fonts-awesome"]="fontawesome-fonts"
    ["python3"]="python3"
    ["python3-pip"]="python3-pip"
    ["base-devel"]="patterns-devel-base-devel_basis"
)

declare -gA VOID_PACKAGES=(
    ["git"]="git"
    ["curl"]="curl"
    ["wget"]="wget"
    ["unzip"]="unzip"
    ["hyprland"]="hyprland"
    ["waybar"]="waybar"
    ["rofi"]="rofi"
    ["kitty"]="kitty"
    ["sddm"]="sddm"
    ["fonts-noto"]="noto-fonts-ttf"
    ["fonts-awesome"]="font-awesome"
    ["python3"]="python3"
    ["python3-pip"]="python3-pip"
    ["base-devel"]="base-devel"
)

declare -gA GENTOO_PACKAGES=(
    ["git"]="dev-vcs/git"
    ["curl"]="net-misc/curl"
    ["wget"]="net-misc/wget"
    ["unzip"]="app-arch/unzip"
    ["hyprland"]="gui-wm/hyprland"
    ["waybar"]="gui-apps/waybar"
    ["rofi"]="x11-misc/rofi"
    ["kitty"]="x11-terms/kitty"
    ["sddm"]="x11-misc/sddm"
    ["fonts-noto"]="media-fonts/noto"
    ["fonts-awesome"]="media-fonts/fontawesome"
    ["python3"]="dev-lang/python"
    ["python3-pip"]="dev-python/pip"
)

declare -gA ALPINE_PACKAGES=(
    ["git"]="git"
    ["curl"]="curl"
    ["wget"]="wget"
    ["unzip"]="unzip"
    ["hyprland"]="hyprland"
    ["waybar"]="waybar"
    ["rofi"]="rofi"
    ["kitty"]="kitty"
    ["sddm"]="sddm"
    ["fonts-noto"]="font-noto"
    ["fonts-awesome"]="font-awesome"
    ["python3"]="python3"
    ["python3-pip"]="py3-pip"
    ["base-devel"]="alpine-sdk"
)

# Arch-like system setup
setup_arch_like_system() {
    log_info "Setting up Arch-like system support..."
    
    # Check for AUR helpers
    if command_exists yay; then
        AUR_HELPER="yay"
    elif command_exists paru; then
        AUR_HELPER="paru"
    elif command_exists pikaur; then
        AUR_HELPER="pikaur"
    elif command_exists trizen; then
        AUR_HELPER="trizen"
    else
        log_info "No AUR helper found - will install yay if needed"
        AUR_HELPER=""
    fi
    
    export AUR_HELPER
}

# Debian-like system setup
setup_debian_like_system() {
    log_info "Setting up Debian-like system support..."
    
    # Enable additional repositories if needed
    if [[ "$DISTRO_ID" == "ubuntu" ]]; then
        setup_ubuntu_repos
    fi
    
    log_warn "Note: Some Hyprland components may need to be built from source on Debian-based systems"
}

# Ubuntu repository setup
setup_ubuntu_repos() {
    log_info "Setting up Ubuntu repositories..."
    
    # Add universe repository if not already enabled
    if ! grep -q "universe" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        log_info "Enabling Ubuntu universe repository..."
        sudo add-apt-repository universe -y
    fi
    
    # Add PPA for newer packages if needed
    if [[ "$DISTRO_VERSION" < "23.04" ]]; then
        log_info "Adding PPAs for newer Hyprland packages..."
        # Note: Add specific PPAs here when available
    fi
}

# Fedora-like system setup
setup_fedora_like_system() {
    log_info "Setting up Fedora-like system support..."
    
    # Enable RPM Fusion if not already enabled
    if ! rpm -qa | grep -q rpmfusion; then
        log_info "Enabling RPM Fusion repositories..."
        sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    fi
    
    log_warn "Note: Some Hyprland components may need COPR repositories on Fedora"
}

# openSUSE system setup
setup_opensuse_system() {
    log_info "Setting up openSUSE system support..."
    
    # Add Packman repository for multimedia
    if ! zypper repos | grep -q packman; then
        log_info "Adding Packman repository..."
        sudo zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
    fi
}

# Void Linux system setup
setup_void_system() {
    log_info "Setting up Void Linux system support..."
}

# Gentoo system setup
setup_gentoo_system() {
    log_info "Setting up Gentoo system support..."
    
    log_warn "Note: Emerge times may be significant on Gentoo"
}

# Alpine Linux system setup
setup_alpine_system() {
    log_info "Setting up Alpine Linux system support..."
    
    # Enable community and testing repositories
    if ! grep -q "community" /etc/apk/repositories; then
        echo "https://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d. -f1-2)/community" | sudo tee -a /etc/apk/repositories
    fi
    
    log_warn "Note: Alpine uses musl libc which may cause compatibility issues"
}

# Get package name for current distribution
get_package_name() {
    local generic_name="$1"
    local package_name=""
    
    case "$PACKAGE_MANAGER" in
        "pacman")
            package_name="${ARCH_PACKAGES[$generic_name]:-$generic_name}"
            ;;
        "apt")
            package_name="${DEBIAN_PACKAGES[$generic_name]:-$generic_name}"
            ;;
        "dnf"|"yum")
            package_name="${FEDORA_PACKAGES[$generic_name]:-$generic_name}"
            ;;
        "zypper")
            package_name="${OPENSUSE_PACKAGES[$generic_name]:-$generic_name}"
            ;;
        "xbps")
            package_name="${VOID_PACKAGES[$generic_name]:-$generic_name}"
            ;;
        "portage")
            package_name="${GENTOO_PACKAGES[$generic_name]:-$generic_name}"
            ;;
        "apk")
            package_name="${ALPINE_PACKAGES[$generic_name]:-$generic_name}"
            ;;
        *)
            package_name="$generic_name"
            ;;
    esac
    
    echo "$package_name"
}

# Install packages with distribution-specific handling
install_packages_distro() {
    local packages=("$@")
    local distro_packages=()
    
    # Convert generic package names to distro-specific names
    for pkg in "${packages[@]}"; do
        local distro_pkg=$(get_package_name "$pkg")
        if [[ -n "$distro_pkg" ]]; then
            distro_packages+=("$distro_pkg")
        fi
    done
    
    if [[ ${#distro_packages[@]} -eq 0 ]]; then
        log_warn "No packages to install"
        return 0
    fi
    
    log_info "Installing packages: ${distro_packages[*]}"
    
    # Distribution-specific installation
    case "$PACKAGE_MANAGER" in
        "pacman")
            if [[ "$UNATTENDED" == "true" ]]; then
                sudo pacman -S --noconfirm "${distro_packages[@]}"
            else
                sudo pacman -S "${distro_packages[@]}"
            fi
            ;;
        "apt")
            sudo apt update
            if [[ "$UNATTENDED" == "true" ]]; then
                sudo apt install -y "${distro_packages[@]}"
            else
                sudo apt install "${distro_packages[@]}"
            fi
            ;;
        "dnf")
            if [[ "$UNATTENDED" == "true" ]]; then
                sudo dnf install -y "${distro_packages[@]}"
            else
                sudo dnf install "${distro_packages[@]}"
            fi
            ;;
        "yum")
            if [[ "$UNATTENDED" == "true" ]]; then
                sudo yum install -y "${distro_packages[@]}"
            else
                sudo yum install "${distro_packages[@]}"
            fi
            ;;
        "zypper")
            if [[ "$UNATTENDED" == "true" ]]; then
                sudo zypper install -y "${distro_packages[@]}"
            else
                sudo zypper install "${distro_packages[@]}"
            fi
            ;;
        "xbps")
            if [[ "$UNATTENDED" == "true" ]]; then
                sudo xbps-install -y "${distro_packages[@]}"
            else
                sudo xbps-install "${distro_packages[@]}"
            fi
            ;;
        "portage")
            sudo emerge "${distro_packages[@]}"
            ;;
        "apk")
            if [[ "$UNATTENDED" == "true" ]]; then
                sudo apk add "${distro_packages[@]}"
            else
                sudo apk add "${distro_packages[@]}"
            fi
            ;;
        *)
            log_error "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

# Check if distribution is supported for Hyprland
check_hyprland_support() {
    case "$DISTRO_ID" in
        arch|endeavouros|cachyos|manjaro|garuda)
            log_success "Full Hyprland support available"
            return 0
            ;;
        ubuntu|debian|fedora|opensuse*)
            log_warn "Limited Hyprland support - some packages may need compilation"
            return 0
            ;;
        void|gentoo|alpine)
            log_warn "Advanced distribution - manual configuration may be required"
            return 0
            ;;
        *)
            log_error "Hyprland support for $DISTRO_ID is experimental"
            log_info "Proceeding anyway, but expect issues"
            return 1
            ;;
    esac
}

# Main function
main() {
    case "${1:-detect}" in
        "detect")
            detect_distribution
            check_hyprland_support
            ;;
        "install")
            shift
            install_packages_distro "$@"
            ;;
        "get-package")
            get_package_name "$2"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [detect|install|get-package] [options]"
            echo ""
            echo "Commands:"
            echo "  detect              Detect distribution and setup package manager"
            echo "  install PACKAGES    Install packages using distribution package manager"
            echo "  get-package NAME    Get distribution-specific package name"
            echo "  help               Show this help"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

