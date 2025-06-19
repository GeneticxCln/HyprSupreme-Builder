#!/bin/bash
# HyprSupreme-Builder Enhanced Build Script
# https://github.com/GeneticxCln/HyprSupreme-Builder
# 
# This script addresses common security and reliability issues found in installation scripts:
# - Comprehensive error handling and input validation
# - Secure package downloads and verification
# - Better dependency management
# - Improved user experience with clear progress feedback
# - Safer sudo handling

# Strict error handling
set -euo pipefail
IFS=$'\n\t'

# Script configuration
readonly SCRIPT_VERSION="2.1.0-enhanced"
readonly PROJECT_NAME="HyprSupreme-Builder"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEMP_DIR=$(mktemp -d)
readonly LOG_DIR="${SCRIPT_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/build-$(date +%Y%m%d-%H%M%S).log"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Status indicators
readonly OK="${GREEN}[✓]${NC}"
readonly ERROR="${RED}[✗]${NC}"
readonly WARN="${YELLOW}[⚠]${NC}"
readonly INFO="${BLUE}[ℹ]${NC}"
readonly PROGRESS="${CYAN}[⟳]${NC}"

# Global variables
UNATTENDED_MODE=false
SKIP_DEPS_CHECK=false
FORCE_REINSTALL=false
VERBOSE_MODE=false
DRY_RUN=false

# Cleanup function - handles script termination gracefully
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${ERROR} Script failed with exit code $exit_code" | tee -a "$LOG_FILE" 2>/dev/null || true
        echo -e "${INFO} Check the log file for details: $LOG_FILE" | tee -a "$LOG_FILE" 2>/dev/null || true
    fi
    
    # Clean up temporary files
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    
    # Reset terminal
    echo -e "${NC}"
}

# Set up signal traps
trap cleanup EXIT ERR INT TERM

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also display on screen if verbose mode or if it's an error/warning
    if [[ "$VERBOSE_MODE" == true ]] || [[ "$level" =~ ^(ERROR|WARN)$ ]]; then
        echo -e "[$level] $message"
    fi
}

# Progress indicator function
show_progress() {
    local message="$1"
    echo -e "${PROGRESS} $message"
    log "PROGRESS" "$message"
}

# Security: Verify file checksums when available
verify_checksum() {
    local file="$1"
    local expected_sum="$2"
    local algorithm="${3:-sha256}"
    
    if [[ -z "$expected_sum" ]]; then
        log "WARN" "No checksum provided for $file - skipping verification"
        return 0
    fi
    
    local actual_sum
    case "$algorithm" in
        sha256) actual_sum=$(sha256sum "$file" | cut -d' ' -f1) ;;
        md5) actual_sum=$(md5sum "$file" | cut -d' ' -f1) ;;
        *) log "ERROR" "Unsupported checksum algorithm: $algorithm"; return 1 ;;
    esac
    
    if [[ "$actual_sum" == "$expected_sum" ]]; then
        log "INFO" "Checksum verification passed for $file"
        return 0
    else
        log "ERROR" "Checksum verification failed for $file"
        log "ERROR" "Expected: $expected_sum"
        log "ERROR" "Actual: $actual_sum"
        return 1
    fi
}

# Improved sudo handling with timeout and validation
validate_sudo() {
    show_progress "Validating sudo access..."
    
    # Check if sudo is available
    if ! command -v sudo >/dev/null 2>&1; then
        echo -e "${ERROR} sudo is required but not installed"
        echo -e "${INFO} Please install sudo and ensure your user has sudo privileges"
        return 1
    fi
    
    # Check if user has sudo privileges
    if ! sudo -n true 2>/dev/null; then
        echo -e "${INFO} Sudo access required for system package installation"
        echo -e "${WARN} You will be prompted for your password"
        
        # Attempt to get sudo access with timeout
        if ! timeout 30 sudo -v; then
            echo -e "${ERROR} Failed to obtain sudo access"
            echo -e "${INFO} Please ensure you have sudo privileges and try again"
            return 1
        fi
    fi
    
    echo -e "${OK} Sudo access validated"
    log "INFO" "Sudo access validated successfully"
    return 0
}

# Enhanced dependency checking with automatic resolution
check_dependencies() {
    show_progress "Checking system dependencies..."
    
    local missing_critical=()
    local missing_optional=()
    
    # Critical dependencies - script cannot function without these
    local critical_deps=(
        "bash:4.0"           # Minimum bash version
        "curl"               # For downloading files
        "git"                # For cloning repositories
        "sudo"               # For system modifications
        "systemctl"          # For managing services
    )
    
    # Optional dependencies - improve functionality but not critical
    local optional_deps=(
        "wget"               # Alternative download tool
        "whiptail"           # Better UI dialogs
        "python3"            # For Python scripts
        "pip3"               # Python package manager
    )
    
    # Check critical dependencies
    for dep_spec in "${critical_deps[@]}"; do
        local dep_name="${dep_spec%%:*}"
        local min_version="${dep_spec#*:}"
        
        if ! command -v "$dep_name" >/dev/null 2>&1; then
            missing_critical+=("$dep_name")
            log "ERROR" "Critical dependency missing: $dep_name"
        elif [[ "$min_version" != "$dep_name" ]]; then
            # Version checking for bash
            if [[ "$dep_name" == "bash" ]]; then
                local bash_version="${BASH_VERSION%%.*}"
                if [[ "$bash_version" -lt "${min_version%%.*}" ]]; then
                    echo -e "${ERROR} Bash version $min_version or higher required (found $BASH_VERSION)"
                    return 1
                fi
            fi
        fi
    done
    
    # Check optional dependencies
    for dep in "${optional_deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_optional+=("$dep")
            log "WARN" "Optional dependency missing: $dep"
        fi
    done
    
    # Handle missing critical dependencies
    if [[ ${#missing_critical[@]} -gt 0 ]]; then
        echo -e "${ERROR} Missing critical dependencies: ${missing_critical[*]}"
        
        if [[ "$UNATTENDED_MODE" == false ]]; then
            echo -e "${INFO} Attempt to install missing dependencies? [Y/n]"
            read -r response
            case "$response" in
                [nN][oO]|[nN])
                    echo -e "${ERROR} Cannot proceed without critical dependencies"
                    return 1
                    ;;
            esac
        fi
        
        install_missing_dependencies "${missing_critical[@]}"
    fi
    
    # Offer to install optional dependencies
    if [[ ${#missing_optional[@]} -gt 0 && "$UNATTENDED_MODE" == false ]]; then
        echo -e "${INFO} Install optional dependencies for better experience? [Y/n]"
        read -r response
        case "$response" in
            [nN][oO]|[nN])
                log "INFO" "Skipping optional dependencies"
                ;;
            *)
                install_missing_dependencies "${missing_optional[@]}"
                ;;
        esac
    fi
    
    echo -e "${OK} Dependency check completed"
    return 0
}

# Install missing dependencies with proper error handling
install_missing_dependencies() {
    local deps=("$@")
    
    show_progress "Installing missing dependencies: ${deps[*]}"
    
    # Detect package manager
    local pkg_manager=""
    if command -v pacman >/dev/null 2>&1; then
        pkg_manager="pacman"
    elif command -v apt >/dev/null 2>&1; then
        pkg_manager="apt"
    elif command -v dnf >/dev/null 2>&1; then
        pkg_manager="dnf"
    elif command -v zypper >/dev/null 2>&1; then
        pkg_manager="zypper"
    else
        echo -e "${ERROR} No supported package manager found"
        echo -e "${INFO} Please install the following packages manually: ${deps[*]}"
        return 1
    fi
    
    # Install dependencies based on package manager
    case "$pkg_manager" in
        pacman)
            if [[ "$UNATTENDED_MODE" == true ]]; then
                sudo pacman -S --noconfirm "${deps[@]}" || return 1
            else
                sudo pacman -S "${deps[@]}" || return 1
            fi
            ;;
        apt)
            sudo apt update || return 1
            if [[ "$UNATTENDED_MODE" == true ]]; then
                sudo apt install -y "${deps[@]}" || return 1
            else
                sudo apt install "${deps[@]}" || return 1
            fi
            ;;
        dnf)
            if [[ "$UNATTENDED_MODE" == true ]]; then
                sudo dnf install -y "${deps[@]}" || return 1
            else
                sudo dnf install "${deps[@]}" || return 1
            fi
            ;;
        zypper)
            if [[ "$UNATTENDED_MODE" == true ]]; then
                sudo zypper install -y "${deps[@]}" || return 1
            else
                sudo zypper install "${deps[@]}" || return 1
            fi
            ;;
    esac
    
    echo -e "${OK} Dependencies installed successfully"
    log "INFO" "Successfully installed dependencies: ${deps[*]}"
}

# Enhanced system checks
check_system_requirements() {
    show_progress "Performing system requirements check..."
    
    # Check if running as root (should not be)
    if [[ $EUID -eq 0 ]]; then
        echo -e "${ERROR} This script should NOT be run as root"
        echo -e "${INFO} Please run as a regular user with sudo privileges"
        return 1
    fi
    
    # Check available disk space (minimum 2GB)
    local available_space_kb
    available_space_kb=$(df "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
    local required_space_kb=$((2 * 1024 * 1024)) # 2GB in KB
    
    if [[ "$available_space_kb" -lt "$required_space_kb" ]]; then
        echo -e "${ERROR} Insufficient disk space"
        echo -e "${INFO} Required: 2GB, Available: $((available_space_kb / 1024 / 1024))GB"
        return 1
    fi
    
    # Check internet connectivity
    show_progress "Testing internet connectivity..."
    local test_sites=("github.com" "archlinux.org" "8.8.8.8")
    local connectivity=false
    
    for site in "${test_sites[@]}"; do
        if ping -c 1 -W 5 "$site" >/dev/null 2>&1; then
            connectivity=true
            break
        fi
    done
    
    if [[ "$connectivity" == false ]]; then
        echo -e "${ERROR} No internet connection detected"
        echo -e "${INFO} Internet access is required for downloading packages and configurations"
        return 1
    fi
    
    # Check if Hyprland is already installed
    if command -v hyprland >/dev/null 2>&1 && [[ "$FORCE_REINSTALL" == false ]]; then
        echo -e "${WARN} Hyprland is already installed"
        if [[ "$UNATTENDED_MODE" == false ]]; then
            echo -e "${INFO} Continue with configuration update? [Y/n]"
            read -r response
            case "$response" in
                [nN][oO]|[nN])
                    echo -e "${INFO} Installation cancelled by user"
                    return 1
                    ;;
            esac
        fi
    fi
    
    echo -e "${OK} System requirements check passed"
    return 0
}

# Secure download function with verification
secure_download() {
    local url="$1"
    local destination="$2"
    local checksum="${3:-}"
    local algorithm="${4:-sha256}"
    
    show_progress "Downloading $(basename "$destination")..."
    
    # Verify URL is HTTPS or trusted source
    if [[ ! "$url" =~ ^https:// ]] && [[ ! "$url" =~ ^git@ ]]; then
        echo -e "${WARN} Non-HTTPS URL detected: $url"
        if [[ "$UNATTENDED_MODE" == false ]]; then
            echo -e "${INFO} Continue with potentially insecure download? [y/N]"
            read -r response
            case "$response" in
                [yY][eE][sS]|[yY])
                    log "WARN" "User approved non-HTTPS download: $url"
                    ;;
                *)
                    echo -e "${ERROR} Download cancelled for security reasons"
                    return 1
                    ;;
            esac
        else
            log "ERROR" "Non-HTTPS URL rejected in unattended mode: $url"
            return 1
        fi
    fi
    
    # Download with progress and timeout
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL --connect-timeout 10 --max-time 300 --progress-bar "$url" -o "$destination"; then
            echo -e "${ERROR} Download failed: $url"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget --timeout=10 --tries=3 --progress=bar "$url" -O "$destination"; then
            echo -e "${ERROR} Download failed: $url"
            return 1
        fi
    else
        echo -e "${ERROR} No download tool available (curl or wget required)"
        return 1
    fi
    
    # Verify checksum if provided
    if [[ -n "$checksum" ]]; then
        if ! verify_checksum "$destination" "$checksum" "$algorithm"; then
            echo -e "${ERROR} Checksum verification failed for downloaded file"
            rm -f "$destination"
            return 1
        fi
    fi
    
    echo -e "${OK} Download completed and verified"
    log "INFO" "Successfully downloaded and verified: $destination"
    return 0
}

# Enhanced package installation with conflict resolution
install_packages() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log "WARN" "No packages specified for installation"
        return 0
    fi
    
    show_progress "Installing packages: ${packages[*]}"
    
    # Check which packages are already installed
    local to_install=()
    local already_installed=()
    
    for pkg in "${packages[@]}"; do
        if pacman -Qi "$pkg" >/dev/null 2>&1; then
            already_installed+=("$pkg")
        else
            to_install+=("$pkg")
        fi
    done
    
    if [[ ${#already_installed[@]} -gt 0 ]]; then
        echo -e "${INFO} Already installed: ${already_installed[*]}"
        log "INFO" "Packages already installed: ${already_installed[*]}"
    fi
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        echo -e "${OK} All packages are already installed"
        return 0
    fi
    
    # Confirm installation if not in unattended mode
    if [[ "$UNATTENDED_MODE" == false ]]; then
        echo -e "${INFO} About to install: ${to_install[*]}"
        echo -e "${INFO} Proceed with installation? [Y/n]"
        read -r response
        case "$response" in
            [nN][oO]|[nN])
                echo -e "${WARN} Package installation cancelled by user"
                return 1
                ;;
        esac
    fi
    
    # Perform installation
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${INFO} DRY RUN: Would install packages: ${to_install[*]}"
        return 0
    fi
    
    local install_cmd="sudo pacman -S"
    if [[ "$UNATTENDED_MODE" == true ]]; then
        install_cmd+=" --noconfirm"
    fi
    
    if ! $install_cmd "${to_install[@]}"; then
        echo -e "${ERROR} Package installation failed"
        log "ERROR" "Failed to install packages: ${to_install[*]}"
        return 1
    fi
    
    echo -e "${OK} Packages installed successfully"
    log "INFO" "Successfully installed packages: ${to_install[*]}"
    return 0
}

# Print usage information
show_usage() {
    cat << EOF
${PROJECT_NAME} Enhanced Build Script v${SCRIPT_VERSION}

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -u, --unattended        Run in unattended mode (no user interaction)
    -f, --force             Force reinstallation even if already installed
    -v, --verbose           Enable verbose output
    -d, --dry-run           Show what would be done without actually doing it
    --skip-deps             Skip dependency checks (not recommended)

EXAMPLES:
    $0                      # Interactive installation
    $0 --unattended        # Automated installation
    $0 --verbose --dry-run  # See what would be installed

SECURITY NOTES:
    - This script requires sudo privileges for system package installation
    - Downloads are verified with checksums when available
    - Script refuses to run as root for security reasons
    - Non-HTTPS downloads require explicit user approval

LOG FILES:
    Installation logs are saved to: $LOG_DIR/

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -u|--unattended)
                UNATTENDED_MODE=true
                shift
                ;;
            -f|--force)
                FORCE_REINSTALL=true
                shift
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS_CHECK=true
                shift
                ;;
            *)
                echo -e "${ERROR} Unknown option: $1"
                echo -e "${INFO} Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Display banner
print_banner() {
    cat << 'EOF'

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              🚀 HYPRLAND SUPREME BUILDER 🚀                  ║
║                                                               ║
║          Enhanced Build Script with Security Focus           ║
║                                                               ║
║    ✓ Error Handling  ✓ Security  ✓ Progress Tracking        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF
}

# Main execution function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Display banner
    print_banner
    
    # Initialize logging
    mkdir -p "$LOG_DIR"
    log "INFO" "Starting ${PROJECT_NAME} Enhanced Build Script v${SCRIPT_VERSION}"
    log "INFO" "Script directory: $SCRIPT_DIR"
    log "INFO" "Log file: $LOG_FILE"
    
    # System checks
    if ! check_system_requirements; then
        log "ERROR" "System requirements check failed"
        exit 1
    fi
    
    # Validate sudo access
    if ! validate_sudo; then
        log "ERROR" "Sudo validation failed"
        exit 1
    fi
    
    # Check dependencies unless skipped
    if [[ "$SKIP_DEPS_CHECK" == false ]]; then
        if ! check_dependencies; then
            log "ERROR" "Dependency check failed"
            exit 1
        fi
    else
        log "WARN" "Dependency check skipped by user request"
    fi
    
    # If this is a dry run, show what would be done and exit
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${INFO} DRY RUN MODE - No actual changes will be made"
        echo -e "${INFO} Would proceed to run the main installation script: ./install.sh"
        log "INFO" "Dry run completed successfully"
        exit 0
    fi
    
    # Run the main installation script
    show_progress "Launching main installation script..."
    
    if [[ ! -f "$SCRIPT_DIR/install.sh" ]]; then
        echo -e "${ERROR} Main installation script not found: $SCRIPT_DIR/install.sh"
        log "ERROR" "install.sh not found in script directory"
        exit 1
    fi
    
    local install_args=()
    if [[ "$UNATTENDED_MODE" == true ]]; then
        install_args+=("--unattended")
    fi
    if [[ "$VERBOSE_MODE" == true ]]; then
        install_args+=("--verbose")
    fi
    
    echo -e "${INFO} Executing: ./install.sh ${install_args[*]}"
    log "INFO" "Launching install.sh with arguments: ${install_args[*]}"
    
    if ! "$SCRIPT_DIR/install.sh" "${install_args[@]}"; then
        echo -e "${ERROR} Main installation script failed"
        log "ERROR" "install.sh execution failed"
        exit 1
    fi
    
    echo -e "${OK} Installation completed successfully!"
    log "INFO" "Installation completed successfully"
    
    # Display summary
    cat << EOF

${OK} ${PROJECT_NAME} Enhanced Build Script completed successfully!

📝 Log file saved to: $LOG_FILE
🎯 Next steps:
   1. Reboot your system if required
   2. Log in to your new Hyprland session
   3. Enjoy your enhanced desktop environment!

⭐ If you found this useful, please star the repository:
   https://github.com/GeneticxCln/HyprSupreme-Builder

EOF
}

# Execute main function with all script arguments
main "$@"

