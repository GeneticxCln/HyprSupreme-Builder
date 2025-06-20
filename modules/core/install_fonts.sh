#!/bin/bash

# HyprSupreme-Builder - Fonts Installation Module
# Enhanced with robust error handling and system improvements

# Strict mode
set -euo pipefail

# Error codes specific to font operations
readonly ERR_FONT_DEPENDENCY=50      # Missing font dependencies
readonly ERR_FONT_INSTALL=51         # Font package installation failed
readonly ERR_FONT_CACHE=52           # Font cache update failed
readonly ERR_FONT_CONFIG_BACKUP=53   # Font configuration backup failed
readonly ERR_FONT_VERIFICATION=54    # Font verification failed
readonly ERR_FONT_AUR=55             # AUR font installation failed
readonly ERR_PERMISSIONS=1           # Permission/sudo error

# Source common functions with robust path resolution
readonly SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
readonly FUNCTIONS_PATH="${SCRIPT_DIR}/../common/functions.sh"

if [[ ! -f "${FUNCTIONS_PATH}" ]]; then
    echo "Error: Required functions file not found: ${FUNCTIONS_PATH}" >&2
    exit 1
fi

source "${FUNCTIONS_PATH}"

# Default paths and configuration
FONT_CONFIG_DIR="$HOME/.config/fontconfig"
FONT_BACKUP_DIR="$HOME/.config/hypr-supreme/backups/fonts"
FONTS_INSTALLED=false

# Setup error handling and cleanup
error_handler() {
    local exit_code=$?
    
    # Handle specific error codes
    case $exit_code in
        $ERR_FONT_DEPENDENCY)
            log_error "Critical font dependencies are missing. Please install them manually."
            ;;
        $ERR_FONT_INSTALL)
            log_error "Failed to install required fonts. Check package manager for errors."
            ;;
        $ERR_FONT_CACHE)
            log_warn "Font cache update failed. You may need to run 'fc-cache -f' manually."
            ;;
        $ERR_FONT_CONFIG_BACKUP)
            log_warn "Font configuration backup failed. Proceeding without backup."
            ;;
        $ERR_FONT_VERIFICATION)
            log_error "Font verification failed. Some fonts may not be properly installed."
            ;;
        $ERR_FONT_AUR)
            log_warn "Some AUR fonts couldn't be installed. This won't affect core functionality."
            ;;
        $ERR_PERMISSIONS)
            log_error "This script requires sudo privileges for some operations."
            ;;
        *)
            if [[ $exit_code -ne 0 ]]; then
                log_error "Font installation failed with error code: $exit_code"
            fi
            ;;
    esac
    
    # Recovery attempt if some fonts were installed
    if [[ "$FONTS_INSTALLED" == "true" ]]; then
        log_warn "Attempting to update font cache to ensure partial installation works..."
        fc-cache -f &>/dev/null || true
    fi
    
    exit $exit_code
}

# Set up trap for script exit
trap error_handler EXIT

# Set up trap for unexpected signals
trap 'exit $ERR_FONT_INSTALL' SIGHUP SIGINT SIGTERM

# Check dependencies
check_font_dependencies() {
    log_info "Checking font dependencies..."
    
    local deps=("fc-cache" "fc-list")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing font dependencies: ${missing[*]}"
        log_info "Installing fontconfig package..."
        
        if ! install_packages "fontconfig"; then
            log_error "Failed to install fontconfig package"
            exit $ERR_FONT_DEPENDENCY
        fi
    fi
    
    # Verify if AUR helper is available
    check_aur_helper
    
    log_success "Font dependencies verified"
}

# Backup font configurations
backup_font_config() {
    log_info "Backing up font configurations..."
    
    # Create backup directory if it doesn't exist
    mkdir -p "$FONT_BACKUP_DIR" || {
        log_error "Failed to create backup directory: $FONT_BACKUP_DIR"
        exit $ERR_FONT_CONFIG_BACKUP
    }
    
    # Backup timestamp
    local backup_timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # Backup font config if it exists
    if [[ -d "$FONT_CONFIG_DIR" ]]; then
        log_info "Backing up existing fontconfig directory..."
        tar -czf "$FONT_BACKUP_DIR/fontconfig_${backup_timestamp}.tar.gz" -C "$(dirname "$FONT_CONFIG_DIR")" "$(basename "$FONT_CONFIG_DIR")" &>/dev/null || {
            log_warn "Failed to backup font configuration, continuing without backup"
            return $ERR_FONT_CONFIG_BACKUP
        }
    else
        log_info "No existing fontconfig directory found. Skipping backup."
    fi
    
    log_success "Font configuration backup completed"
    return 0
}

# Install essential fonts
install_essential_fonts() {
    log_info "Installing essential fonts for HyprSupreme..."
    
    # Essential fonts
    local packages=(
        "ttf-jetbrains-mono"
        "ttf-jetbrains-mono-nerd"
        "ttf-font-awesome"
        "ttf-fira-code"
        "ttf-fira-sans"
        "ttf-sourcecodepro-nerd"
        "ttf-meslo-nerd"
        "ttf-hack-nerd"
        "noto-fonts"
        "noto-fonts-emoji"
        "noto-fonts-cjk"
        "adobe-source-code-pro-fonts"
        "adobe-source-sans-fonts"
        "adobe-source-serif-fonts"
        "cantarell-fonts"
        "inter-font"
    )
    
    if ! install_packages "${packages[@]}"; then
        log_error "Failed to install essential fonts"
        exit $ERR_FONT_INSTALL
    fi
    
    FONTS_INSTALLED=true
    log_success "Essential fonts installed successfully"
}

# Install AUR fonts if AUR helper is available
install_aur_fonts() {
    if [[ -z "${AUR_HELPER:-}" ]]; then
        log_warn "AUR helper not detected. Skipping AUR fonts installation."
        return 0
    fi
    
    log_info "Installing additional Nerd Fonts from AUR..."
    
    # AUR fonts
    local aur_fonts=(
        "ttf-ubuntu-nerd"
        "ttf-roboto-mono-nerd"
        "ttf-cascadia-code-nerd"
        "ttf-victor-mono-nerd"
    )
    
    local failures=0
    
    for font in "${aur_fonts[@]}"; do
        log_info "Installing $font from AUR..."
        if ! $AUR_HELPER -S --noconfirm "$font" &>/dev/null; then
            log_warn "Failed to install $font from AUR"
            ((failures++))
        fi
    done
    
    if [[ $failures -eq ${#aur_fonts[@]} ]]; then
        log_error "Failed to install any AUR fonts"
        return $ERR_FONT_AUR
    elif [[ $failures -gt 0 ]]; then
        log_warn "Some AUR fonts failed to install: $failures out of ${#aur_fonts[@]}"
    else
        log_success "All AUR fonts installed successfully"
    fi
    
    FONTS_INSTALLED=true
    return 0
}

# Update font cache
update_font_cache() {
    log_info "Updating font cache..."
    
    # Update system font cache with error handling
    if ! sudo fc-cache -fv &>/dev/null; then
        log_warn "Failed to update system font cache, attempting without sudo..."
        
        # Try user-only font cache update
        if ! fc-cache -fv &>/dev/null; then
            log_error "Failed to update font cache"
            return $ERR_FONT_CACHE
        fi
    fi
    
    log_success "Font cache updated"
    return 0
}

# Verify fonts were properly installed
verify_fonts() {
    log_info "Verifying font installation..."
    
    local essential_fonts=(
        "JetBrains Mono"
        "Fira Code"
        "Font Awesome"
        "Noto Sans"
        "Noto Color Emoji"
    )
    
    local missing=()
    
    for font in "${essential_fonts[@]}"; do
        if ! fc-list | grep -i "$font" &>/dev/null; then
            missing+=("$font")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Some essential fonts may not be properly installed: ${missing[*]}"
        log_info "You may need to run 'fc-cache -f' manually or restart your system"
        return $ERR_FONT_VERIFICATION
    fi
    
    log_success "Font verification completed successfully"
    return 0
}

# Test font cache status
test_font_cache() {
    log_info "Testing font cache status..."
    
    # Check if fc-cache is working
    if ! fc-cache -v &>/dev/null; then
        log_error "Font cache system is not functioning properly"
        return $ERR_FONT_CACHE
    fi
    
    # Check number of available fonts
    local font_count=$(fc-list | wc -l)
    log_info "Found $font_count fonts in the system"
    
    if [[ $font_count -lt 10 ]]; then
        log_warn "Very few fonts detected in the system. Font cache may be corrupted."
        return $ERR_FONT_CACHE
    fi
    
    log_success "Font cache is working properly"
    return 0
}

# Main fonts installation function
install_fonts() {
    log_info "Starting fonts installation for HyprSupreme..."
    
    # Validate running as non-root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run directly as root"
        exit $ERR_PERMISSIONS
    fi
    
    # Check dependencies
    check_font_dependencies
    
    # Backup existing configuration
    backup_font_config
    
    # Install essential fonts
    install_essential_fonts
    
    # Install AUR fonts if available
    install_aur_fonts || true  # Continue even if AUR fonts fail
    
    # Update font cache
    update_font_cache
    
    # Verify installation
    verify_fonts || true  # Continue even if verification shows issues
    
    log_success "Fonts installation completed successfully"
    return 0
}

# Restore font configuration from backup
restore_font_config() {
    log_info "Restoring font configuration from backup..."
    
    # Check if backup directory exists
    if [[ ! -d "$FONT_BACKUP_DIR" ]]; then
        log_error "Font backup directory not found: $FONT_BACKUP_DIR"
        return $ERR_FONT_CONFIG_BACKUP
    fi
    
    # Find the most recent backup
    local latest_backup=$(find "$FONT_BACKUP_DIR" -name "fontconfig_*.tar.gz" | sort -r | head -n 1)
    
    if [[ -z "$latest_backup" ]]; then
        log_error "No font configuration backups found"
        return $ERR_FONT_CONFIG_BACKUP
    fi
    
    log_info "Found backup: $(basename "$latest_backup")"
    
    # Remove current configuration if it exists
    if [[ -d "$FONT_CONFIG_DIR" ]]; then
        log_info "Removing current font configuration..."
        rm -rf "$FONT_CONFIG_DIR"
    fi
    
    # Extract backup
    log_info "Extracting backup..."
    tar -xzf "$latest_backup" -C "$(dirname "$FONT_CONFIG_DIR")" &>/dev/null
    
    # Update font cache after restore
    update_font_cache
    
    log_success "Font configuration restored successfully"
    return 0
}

# Main script entry point
main() {
    local operation="${1:-install}"
    
    case "$operation" in
        "install")
            install_fonts
            ;;
        "test")
            test_font_cache
            ;;
        "restore")
            restore_font_config
            ;;
        "update-cache")
            update_font_cache
            ;;
        *)
            log_error "Unknown operation: $operation"
            log_info "Available operations: install, test, restore, update-cache"
            exit 1
            ;;
    esac
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

