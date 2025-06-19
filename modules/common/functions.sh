#!/bin/bash

# HyprSupreme-Builder - Common Functions

# Exit on any error, undefined variable, or pipe failure
set -euo pipefail

# Initialize temp directory for cleanup
TEMP_DIR=$(mktemp -d)
export TEMP_DIR

# Colors for output
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
SUCCESS="$(tput setaf 2)[SUCCESS]$(tput sgr0)"
RESET="$(tput sgr0)"

# Log file
LOG="${LOG:-logs/install-$(date +%Y%m%d-%H%M%S).log}"

# Logging functions
log_info() {
    echo "${INFO} $1" | tee -a "$LOG"
}

log_success() {
    echo "${SUCCESS} $1" | tee -a "$LOG"
}

log_error() {
    echo "${ERROR} $1" | tee -a "$LOG"
}

log_warn() {
    echo "${WARN} $1" | tee -a "$LOG"
}

log_note() {
    echo "${NOTE} $1" | tee -a "$LOG"
}

# Ask for user confirmation for package installations
confirm_package_installation() {
    local packages=("$@")
    local package_list=$(printf "%s " "${packages[@]}")
    
    if [[ "$UNATTENDED" == "true" ]]; then
        log_info "Unattended mode: Installing packages without confirmation: $package_list"
        return 0
    fi
    
    log_note "About to install the following packages: $package_list"
    echo "Do you want to proceed with the installation? [Y/n]"
    read -r response
    
    case "$response" in
        [nN][oO]|[nN])
            log_warn "Package installation cancelled by user"
            return 1
            ;;
        *)
            log_info "Proceeding with package installation"
            return 0
            ;;
    esac
}

# Package installation function with user confirmation
install_packages() {
    local packages=("$@")
    
    # Ask for confirmation before installing
    if ! confirm_package_installation "${packages[@]}"; then
        log_error "Package installation cancelled"
        return 1
    fi
    
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            log_info "Installing $pkg..."
            
            # Try official repos first
            if [[ "$UNATTENDED" == "true" ]]; then
                if sudo pacman -S --noconfirm "$pkg" &> /dev/null; then
                    log_success "Installed $pkg from official repos"
                elif [[ -n "$AUR_HELPER" ]]; then
                    if $AUR_HELPER -S --noconfirm "$pkg" &> /dev/null; then
                        log_success "Installed $pkg from AUR"
                    else
                        log_error "Failed to install $pkg"
                        return 1
                    fi
                else
                    log_error "Failed to install $pkg - no AUR helper available"
                    return 1
                fi
            else
                # Interactive mode - let user confirm each package
                if sudo pacman -S "$pkg" &> /dev/null; then
                    log_success "Installed $pkg from official repos"
                elif [[ -n "$AUR_HELPER" ]]; then
                    if $AUR_HELPER -S "$pkg" &> /dev/null; then
                        log_success "Installed $pkg from AUR"
                    else
                        log_error "Failed to install $pkg"
                        return 1
                    fi
                else
                    log_error "Failed to install $pkg - no AUR helper available"
                    return 1
                fi
            fi
        else
            log_info "$pkg is already installed"
        fi
    done
    
    return 0
}

# Copy configuration files with backup
copy_config() {
    local source="$1"
    local dest="$2"
    local backup_suffix=".backup-$(date +%Y%m%d-%H%M%S)"
    
    if [[ -e "$dest" ]]; then
        log_info "Backing up existing $dest"
        cp -r "$dest" "${dest}${backup_suffix}"
    fi
    
    log_info "Copying $source to $dest"
    cp -r "$source" "$dest"
}

# Create symlink with backup
create_symlink() {
    local source="$1"
    local dest="$2"
    local backup_suffix=".backup-$(date +%Y%m%d-%H%M%S)"
    
    if [[ -e "$dest" ]]; then
        log_info "Backing up existing $dest"
        mv "$dest" "${dest}${backup_suffix}"
    fi
    
    log_info "Creating symlink: $dest -> $source"
    ln -sf "$source" "$dest"
}

# Download and extract archive
download_extract() {
    local url="$1"
    local dest="$2"
    local temp_file="/tmp/$(basename "$url")"
    
    log_info "Downloading $url"
    curl -fsSL "$url" -o "$temp_file" || {
        log_error "Failed to download $url"
        return 1
    }
    
    mkdir -p "$dest"
    
    case "$temp_file" in
        *.tar.gz|*.tgz)
            tar -xzf "$temp_file" -C "$dest" --strip-components=1
            ;;
        *.tar.bz2)
            tar -xjf "$temp_file" -C "$dest" --strip-components=1
            ;;
        *.zip)
            unzip -q "$temp_file" -d "$dest"
            ;;
        *)
            log_error "Unsupported archive format: $temp_file"
            return 1
            ;;
    esac
    
    rm -f "$temp_file"
    log_success "Extracted to $dest"
}

# Check if service is running
is_service_running() {
    local service="$1"
    systemctl is-active --quiet "$service"
}

# Enable and start service
enable_service() {
    local service="$1"
    
    log_info "Enabling service: $service"
    sudo systemctl enable "$service"
    
    if ! is_service_running "$service"; then
        log_info "Starting service: $service"
        sudo systemctl start "$service"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Comprehensive sudo validation
validate_sudo_access() {
    local script_name="${1:-$(basename "$0")}"
    
    # Check if running as root (which we don't want)
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should NOT be run as root!"
        log_error "Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Check if sudo command exists
    if ! command_exists sudo; then
        log_error "sudo is not installed on this system"
        log_error "Please install sudo: pacman -S sudo"
        exit 1
    fi
    
    # Check if user is in sudo group or has sudo privileges
    if ! groups | grep -q -E '(wheel|sudo|admin)'; then
        log_warn "User is not in wheel/sudo/admin group"
        log_info "Checking if sudo access is configured anyway..."
    fi
    
    # Test sudo access without password prompt first
    if sudo -n true 2>/dev/null; then
        log_success "Sudo access validated (passwordless)"
        return 0
    fi
    
    # Test sudo access with password prompt
    log_info "Testing sudo access (may prompt for password)..."
    if sudo -v 2>/dev/null; then
        log_success "Sudo access validated"
        # Keep sudo timestamp fresh for the duration of the script
        keep_sudo_alive &
        SUDO_KEEPER_PID=$!
        trap 'kill $SUDO_KEEPER_PID 2>/dev/null' EXIT
        return 0
    else
        log_error "Sudo access validation failed!"
        log_error "This script requires sudo privileges to:"
        log_error "  • Install packages with pacman"
        log_error "  • Enable/start system services"
        log_error "  • Modify system configuration files"
        log_error "  • Install fonts and themes"
        log_error ""
        log_error "Please ensure your user has sudo privileges:"
        log_error "  1. Add user to wheel group: sudo usermod -aG wheel \$USER"
        log_error "  2. Uncomment wheel group in /etc/sudoers"
        log_error "  3. Or contact your system administrator"
        exit 1
    fi
}

# Keep sudo timestamp alive during long operations
keep_sudo_alive() {
    while true; do
        sleep 60
        sudo -n true 2>/dev/null || break
    done
}

# Validate specific sudo command before execution
validate_sudo_command() {
    local command="$1"
    local description="$2"
    
    if ! sudo -n true 2>/dev/null; then
        log_info "Sudo access required for: $description"
        if ! sudo -v; then
            log_error "Cannot obtain sudo access for: $command"
            return 1
        fi
    fi
    
    return 0
}

# Execute command with sudo validation
sudo_execute() {
    local description="$1"
    shift
    local command=("$@")
    
    log_info "Executing: $description"
    
    if ! validate_sudo_command "${command[*]}" "$description"; then
        log_error "Failed to validate sudo access for: $description"
        return 1
    fi
    
    if sudo "${command[@]}"; then
        log_success "Successfully executed: $description"
        return 0
    else
        log_error "Failed to execute: $description"
        return 1
    fi
}

# Get GPU info
get_gpu_info() {
    lspci | grep -E "VGA|3D|Display" | head -1
}

# Check if NVIDIA GPU
is_nvidia_gpu() {
    get_gpu_info | grep -qi nvidia
}

# Check if AMD GPU
is_amd_gpu() {
    get_gpu_info | grep -qi amd
}

# Check if Intel GPU
is_intel_gpu() {
    get_gpu_info | grep -qi intel
}

# Progress bar function
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${INFO} %s [" "$message"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%" "$percent"
    
    if [[ $current -eq $total ]]; then
        printf "\n"
    fi
}

# Validate config file
validate_config() {
    local config_file="$1"
    local config_type="$2"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        return 1
    fi
    
    case "$config_type" in
        "hyprland")
            # Basic Hyprland config validation
            if ! grep -q "exec-once" "$config_file" && ! grep -q "bind" "$config_file"; then
                log_warn "Config file may not be a valid Hyprland config: $config_file"
            fi
            ;;
        "waybar")
            # Basic Waybar config validation
            if ! grep -q '"modules-' "$config_file"; then
                log_warn "Config file may not be a valid Waybar config: $config_file"
            fi
            ;;
    esac
    
    return 0
}

# Merge configuration files
merge_configs() {
    local base_config="$1"
    local override_config="$2"
    local output_config="$3"
    
    log_info "Merging configs: $base_config + $override_config -> $output_config"
    
    # Simple merge - override config takes precedence
    cp "$base_config" "$output_config"
    
    if [[ -f "$override_config" ]]; then
        # Append override config
        echo "" >> "$output_config"
        echo "# Merged from: $override_config" >> "$output_config"
        cat "$override_config" >> "$output_config"
    fi
}

