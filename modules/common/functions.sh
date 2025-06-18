#!/bin/bash
# HyprSupreme-Builder - Common Functions

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

# Package installation function
install_packages() {
    local packages=("$@")
    
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            log_info "Installing $pkg..."
            
            # Try official repos first
            if sudo pacman -S --noconfirm "$pkg" &> /dev/null; then
                log_success "Installed $pkg from official repos"
            # Try AUR if not in official repos
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
    command -v "$1" &> /dev/null
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

