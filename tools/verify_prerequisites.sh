#!/bin/bash
# Enhanced Dependency and Prerequisite Verification Script
# HyprSupreme-Builder - Comprehensive system checks and error handling

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Status indicators
readonly OK="${GREEN}✓${NC}"
readonly ERROR="${RED}✗${NC}"
readonly WARN="${YELLOW}⚠${NC}"
readonly INFO="${BLUE}ℹ${NC}"
readonly QUESTION="${PURPLE}?${NC}"

# Script metadata
readonly SCRIPT_NAME="HyprSupreme Prerequisites Verifier"
readonly VERSION="2.1.1"
readonly MIN_BASH_VERSION="4.0"

# System requirements
readonly MIN_RAM_GB=4
readonly MIN_STORAGE_GB=8
readonly RECOMMENDED_RAM_GB=8
readonly RECOMMENDED_STORAGE_GB=20

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_DEPENDENCY_MISSING=1
readonly EXIT_SYSTEM_INCOMPATIBLE=2
readonly EXIT_INSUFFICIENT_RESOURCES=3
readonly EXIT_NETWORK_ERROR=4
readonly EXIT_PERMISSION_ERROR=5

# Global variables
VERBOSE=false
AUTO_INSTALL=false
SKIP_OPTIONAL=false
CHECK_ONLY=false
ERRORS_FOUND=0
WARNINGS_FOUND=0
REPORT_FILE=""

# Arrays for tracking
declare -a MISSING_CRITICAL=()
declare -a MISSING_OPTIONAL=()
declare -a SYSTEM_ISSUES=()
declare -a PERFORMANCE_WARNINGS=()

#=====================================
# Utility Functions
#=====================================

print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                  $SCRIPT_NAME                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}                      Version $VERSION                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${ERROR} ${message}" >&2
            ((ERRORS_FOUND++))
            ;;
        "WARN")
            echo -e "${WARN} ${message}"
            ((WARNINGS_FOUND++))
            ;;
        "INFO")
            echo -e "${INFO} ${message}"
            ;;
        "SUCCESS")
            echo -e "${OK} ${message}"
            ;;
        "QUESTION")
            echo -e "${QUESTION} ${message}"
            ;;
    esac
    
    # Write to report file if specified
    if [[ -n "$REPORT_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$REPORT_FILE"
    fi
    
    # Verbose logging
    if [[ "$VERBOSE" == true ]]; then
        echo "[$timestamp] [$level] $message" >&2
    fi
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Enhanced dependency and prerequisite verification for HyprSupreme-Builder

OPTIONS:
    -v, --verbose           Enable verbose output
    -a, --auto-install      Automatically install missing dependencies
    -s, --skip-optional     Skip optional dependency checks
    -c, --check-only        Only check, don't offer to install anything
    -r, --report FILE       Generate detailed report to file
    -h, --help              Show this help message

EXAMPLES:
    $0                                  # Basic prerequisite check
    $0 --verbose --report system.log   # Detailed check with report
    $0 --auto-install                  # Check and auto-install missing deps
    $0 --check-only                    # Check only, no installation prompts

EXIT CODES:
    $EXIT_SUCCESS                       # All checks passed
    $EXIT_DEPENDENCY_MISSING            # Critical dependencies missing
    $EXIT_SYSTEM_INCOMPATIBLE           # System not compatible
    $EXIT_INSUFFICIENT_RESOURCES        # Insufficient system resources
    $EXIT_NETWORK_ERROR                 # Network connectivity issues
    $EXIT_PERMISSION_ERROR              # Permission issues

EOF
}

#=====================================
# System Detection Functions
#=====================================

detect_system() {
    log_message "INFO" "Detecting system information..."
    
    # Operating system
    if [[ ! -f /etc/os-release ]]; then
        log_message "ERROR" "Cannot detect operating system - /etc/os-release missing"
        SYSTEM_ISSUES+=("Missing /etc/os-release file")
        return 1
    fi
    
    source /etc/os-release
    
    log_message "INFO" "Operating System: $PRETTY_NAME"
    log_message "INFO" "Kernel: $(uname -r)"
    log_message "INFO" "Architecture: $(uname -m)"
    
    # Check if system is Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_message "ERROR" "HyprSupreme-Builder requires Linux operating system"
        SYSTEM_ISSUES+=("Non-Linux operating system detected")
        return 1
    fi
    
    # Check architecture
    local arch=$(uname -m)
    if [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]]; then
        log_message "WARN" "Architecture $arch may not be fully supported"
        PERFORMANCE_WARNINGS+=("Potentially unsupported architecture: $arch")
    fi
    
    return 0
}

detect_distribution() {
    log_message "INFO" "Identifying Linux distribution..."
    
    source /etc/os-release
    local distro_id="${ID,,}"  # Convert to lowercase
    
    case "$distro_id" in
        arch|endeavouros|cachyos|manjaro|garuda)
            PACKAGE_MANAGER="pacman"
            DISTRO_FAMILY="arch"
            SUPPORT_LEVEL="full"
            log_message "SUCCESS" "Arch-based distribution detected - Full support available"
            ;;
        ubuntu|debian|linuxmint|pop|elementary)
            PACKAGE_MANAGER="apt"
            DISTRO_FAMILY="debian"
            SUPPORT_LEVEL="limited"
            log_message "WARN" "Debian-based distribution - Limited support"
            PERFORMANCE_WARNINGS+=("Some packages may require manual compilation")
            ;;
        fedora|rhel|centos|rocky|almalinux)
            PACKAGE_MANAGER="dnf"
            DISTRO_FAMILY="redhat"
            SUPPORT_LEVEL="limited"
            log_message "WARN" "Red Hat-based distribution - Limited support"
            PERFORMANCE_WARNINGS+=("Some packages may require COPR repositories")
            ;;
        opensuse*|suse)
            PACKAGE_MANAGER="zypper"
            DISTRO_FAMILY="suse"
            SUPPORT_LEVEL="limited"
            log_message "WARN" "SUSE-based distribution - Limited support"
            PERFORMANCE_WARNINGS+=("Some packages may not be available")
            ;;
        void)
            PACKAGE_MANAGER="xbps"
            DISTRO_FAMILY="void"
            SUPPORT_LEVEL="experimental"
            log_message "WARN" "Void Linux - Experimental support"
            ;;
        gentoo)
            PACKAGE_MANAGER="portage"
            DISTRO_FAMILY="gentoo"
            SUPPORT_LEVEL="experimental"
            log_message "WARN" "Gentoo - Manual compilation required"
            ;;
        nixos)
            PACKAGE_MANAGER="nix"
            DISTRO_FAMILY="nix"
            SUPPORT_LEVEL="experimental"
            log_message "WARN" "NixOS - Custom derivations required"
            ;;
        *)
            log_message "ERROR" "Unsupported distribution: $PRETTY_NAME"
            SYSTEM_ISSUES+=("Unsupported Linux distribution: $distro_id")
            return 1
            ;;
    esac
    
    log_message "INFO" "Distribution family: $DISTRO_FAMILY"
    log_message "INFO" "Package manager: $PACKAGE_MANAGER"
    log_message "INFO" "Support level: $SUPPORT_LEVEL"
    
    return 0
}

#=====================================
# Resource Checking Functions
#=====================================

check_bash_version() {
    log_message "INFO" "Checking Bash version..."
    
    local bash_version="${BASH_VERSION%%.*}"
    local min_version="${MIN_BASH_VERSION%%.*}"
    
    if (( bash_version < min_version )); then
        log_message "ERROR" "Bash version $BASH_VERSION is too old (minimum: $MIN_BASH_VERSION)"
        MISSING_CRITICAL+=("bash>=$MIN_BASH_VERSION")
        return 1
    fi
    
    log_message "SUCCESS" "Bash version $BASH_VERSION - OK"
    return 0
}

check_system_resources() {
    log_message "INFO" "Checking system resources..."
    
    # Check RAM
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    log_message "INFO" "Available RAM: ${ram_gb}GB"
    
    if (( ram_gb < MIN_RAM_GB )); then
        log_message "ERROR" "Insufficient RAM: ${ram_gb}GB (minimum: ${MIN_RAM_GB}GB)"
        SYSTEM_ISSUES+=("Insufficient RAM: ${ram_gb}GB < ${MIN_RAM_GB}GB")
        return 1
    elif (( ram_gb < RECOMMENDED_RAM_GB )); then
        log_message "WARN" "RAM below recommended: ${ram_gb}GB (recommended: ${RECOMMENDED_RAM_GB}GB)"
        PERFORMANCE_WARNINGS+=("RAM below recommended: ${ram_gb}GB")
    else
        log_message "SUCCESS" "RAM: ${ram_gb}GB - OK"
    fi
    
    # Check storage space
    local storage_gb=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    log_message "INFO" "Available storage: ${storage_gb}GB"
    
    if (( storage_gb < MIN_STORAGE_GB )); then
        log_message "ERROR" "Insufficient storage: ${storage_gb}GB (minimum: ${MIN_STORAGE_GB}GB)"
        SYSTEM_ISSUES+=("Insufficient storage: ${storage_gb}GB < ${MIN_STORAGE_GB}GB")
        return 1
    elif (( storage_gb < RECOMMENDED_STORAGE_GB )); then
        log_message "WARN" "Storage below recommended: ${storage_gb}GB (recommended: ${RECOMMENDED_STORAGE_GB}GB)"
        PERFORMANCE_WARNINGS+=("Storage below recommended: ${storage_gb}GB")
    else
        log_message "SUCCESS" "Storage: ${storage_gb}GB - OK"
    fi
    
    return 0
}

check_network_connectivity() {
    log_message "INFO" "Checking network connectivity..."
    
    local test_sites=("archlinux.org" "github.com" "8.8.8.8")
    local connected=false
    
    for site in "${test_sites[@]}"; do
        if ping -c 1 -W 5 "$site" &>/dev/null; then
            log_message "SUCCESS" "Network connectivity to $site - OK"
            connected=true
            break
        else
            log_message "WARN" "Cannot reach $site"
        fi
    done
    
    if [[ "$connected" == false ]]; then
        log_message "ERROR" "No network connectivity detected"
        SYSTEM_ISSUES+=("No network connectivity")
        return 1
    fi
    
    # Test HTTPS connectivity
    if command -v curl &>/dev/null; then
        if curl -s --connect-timeout 10 https://raw.githubusercontent.com/GeneticxCln/HyprSupreme-Builder/main/README.md >/dev/null; then
            log_message "SUCCESS" "HTTPS connectivity - OK"
        else
            log_message "WARN" "HTTPS connectivity issues detected"
            PERFORMANCE_WARNINGS+=("HTTPS connectivity problems")
        fi
    fi
    
    return 0
}

#=====================================
# Dependency Checking Functions
#=====================================

check_command() {
    local cmd="$1"
    local package="$2"
    local critical="${3:-true}"
    
    if command -v "$cmd" &>/dev/null; then
        local version=""
        case "$cmd" in
            git) version=" ($(git --version | awk '{print $3}'))" ;;
            curl) version=" ($(curl --version | head -1 | awk '{print $2}'))" ;;
            python3) version=" ($(python3 --version | awk '{print $2}'))" ;;
        esac
        log_message "SUCCESS" "$cmd$version - Found"
        return 0
    else
        if [[ "$critical" == "true" ]]; then
            log_message "ERROR" "$cmd - Missing (package: $package)"
            MISSING_CRITICAL+=("$package")
        else
            log_message "WARN" "$cmd - Missing (package: $package)"
            MISSING_OPTIONAL+=("$package")
        fi
        return 1
    fi
}

check_critical_dependencies() {
    log_message "INFO" "Checking critical dependencies..."
    
    local deps_ok=true
    
    # Essential system commands
    check_command "sudo" "sudo" || deps_ok=false
    check_command "git" "git" || deps_ok=false
    check_command "curl" "curl" || deps_ok=false
    check_command "wget" "wget" || deps_ok=false
    check_command "unzip" "unzip" || deps_ok=false
    
    # Development tools
    if [[ "$DISTRO_FAMILY" == "arch" ]]; then
        check_command "makepkg" "base-devel" || deps_ok=false
        check_command "gcc" "base-devel" || deps_ok=false
    elif [[ "$DISTRO_FAMILY" == "debian" ]]; then
        check_command "make" "build-essential" || deps_ok=false
        check_command "gcc" "build-essential" || deps_ok=false
    fi
    
    # Package manager specific
    case "$PACKAGE_MANAGER" in
        pacman)
            check_command "pacman" "pacman" || deps_ok=false
            ;;
        apt)
            check_command "apt" "apt" || deps_ok=false
            check_command "dpkg" "dpkg" || deps_ok=false
            ;;
        dnf)
            check_command "dnf" "dnf" || deps_ok=false
            ;;
        zypper)
            check_command "zypper" "zypper" || deps_ok=false
            ;;
    esac
    
    # System services
    check_command "systemctl" "systemd" || deps_ok=false
    
    return $([ "$deps_ok" == true ] && echo 0 || echo 1)
}

check_optional_dependencies() {
    if [[ "$SKIP_OPTIONAL" == true ]]; then
        log_message "INFO" "Skipping optional dependency checks"
        return 0
    fi
    
    log_message "INFO" "Checking optional dependencies..."
    
    # Dialog utilities
    check_command "whiptail" "libnewt" false
    check_command "dialog" "dialog" false
    
    # Python and tools
    check_command "python3" "python3" false
    check_command "pip3" "python3-pip" false
    
    # Development tools
    check_command "node" "nodejs" false
    check_command "npm" "npm" false
    
    # Graphics tools
    check_command "convert" "imagemagick" false
    check_command "ffmpeg" "ffmpeg" false
    
    return 0
}

check_wayland_support() {
    log_message "INFO" "Checking Wayland support..."
    
    # Check if Wayland libraries are available
    if ldconfig -p | grep -q "libwayland-client"; then
        log_message "SUCCESS" "Wayland client libraries - Found"
    else
        log_message "ERROR" "Wayland client libraries - Missing"
        MISSING_CRITICAL+=("wayland")
    fi
    
    # Check for Wayland compositor
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ -n "${XDG_SESSION_TYPE:-}" && "$XDG_SESSION_TYPE" == "wayland" ]]; then
        log_message "SUCCESS" "Wayland session detected"
    else
        log_message "WARN" "Not currently in a Wayland session"
        PERFORMANCE_WARNINGS+=("X11 session detected - Wayland recommended")
    fi
    
    return 0
}

check_gpu_drivers() {
    log_message "INFO" "Checking GPU drivers..."
    
    local gpu_found=false
    
    # Check for GPU hardware
    if lspci | grep -i "vga\|3d\|display" >/dev/null; then
        gpu_found=true
        local gpu_info=$(lspci | grep -i "vga\|3d\|display" | head -1)
        log_message "INFO" "GPU detected: $gpu_info"
        
        # NVIDIA check
        if lspci | grep -i nvidia >/dev/null; then
            if command -v nvidia-smi &>/dev/null; then
                log_message "SUCCESS" "NVIDIA drivers - Found"
            else
                log_message "WARN" "NVIDIA GPU detected but drivers not found"
                PERFORMANCE_WARNINGS+=("NVIDIA GPU without proprietary drivers")
            fi
        fi
        
        # AMD check
        if lspci | grep -i "amd\|radeon" >/dev/null; then
            if [[ -d /sys/class/drm/card0 ]]; then
                log_message "SUCCESS" "AMD/Radeon drivers - Found"
            else
                log_message "WARN" "AMD GPU detected but drivers may be missing"
                PERFORMANCE_WARNINGS+=("AMD GPU with potential driver issues")
            fi
        fi
        
        # Intel check
        if lspci | grep -i intel >/dev/null; then
            if [[ -d /sys/class/drm/card0 ]]; then
                log_message "SUCCESS" "Intel graphics drivers - Found"
            else
                log_message "WARN" "Intel GPU detected but drivers may be missing"
                PERFORMANCE_WARNINGS+=("Intel GPU with potential driver issues")
            fi
        fi
    fi
    
    if [[ "$gpu_found" == false ]]; then
        log_message "WARN" "No GPU detected - software rendering will be used"
        PERFORMANCE_WARNINGS+=("No dedicated GPU detected")
    fi
    
    return 0
}

#=====================================
# Permission and Security Checks
#=====================================

check_permissions() {
    log_message "INFO" "Checking permissions and access..."
    
    # Check if running as root (should not be)
    if [[ $EUID -eq 0 ]]; then
        log_message "ERROR" "Script should not be run as root"
        SYSTEM_ISSUES+=("Running as root user")
        return 1
    fi
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_message "INFO" "Testing sudo access..."
        if sudo -v; then
            log_message "SUCCESS" "Sudo access - OK"
        else
            log_message "ERROR" "Sudo access required but not available"
            SYSTEM_ISSUES+=("No sudo access")
            return 1
        fi
    else
        log_message "SUCCESS" "Sudo access - OK"
    fi
    
    # Check write permissions in home directory
    if [[ ! -w "$HOME" ]]; then
        log_message "ERROR" "No write permission in home directory"
        SYSTEM_ISSUES+=("No write permission in $HOME")
        return 1
    fi
    
    # Check if required directories can be created
    local test_dir="$HOME/.hyprsupreme-test-$$"
    if mkdir -p "$test_dir" 2>/dev/null; then
        rmdir "$test_dir"
        log_message "SUCCESS" "Directory creation permissions - OK"
    else
        log_message "ERROR" "Cannot create directories in home"
        SYSTEM_ISSUES+=("Cannot create directories in $HOME")
        return 1
    fi
    
    return 0
}

#=====================================
# Installation Functions
#=====================================

install_missing_dependencies() {
    if [[ ${#MISSING_CRITICAL[@]} -eq 0 && ${#MISSING_OPTIONAL[@]} -eq 0 ]]; then
        log_message "SUCCESS" "No missing dependencies to install"
        return 0
    fi
    
    local all_missing=("${MISSING_CRITICAL[@]}" "${MISSING_OPTIONAL[@]}")
    
    if [[ "$AUTO_INSTALL" == true ]]; then
        log_message "INFO" "Auto-installing missing dependencies..."
        install_packages "${all_missing[@]}"
    elif [[ "$CHECK_ONLY" != true ]]; then
        log_message "QUESTION" "Install missing dependencies? [y/N]"
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                install_packages "${all_missing[@]}"
                ;;
            *)
                log_message "INFO" "Skipping dependency installation"
                ;;
        esac
    fi
}

install_packages() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    log_message "INFO" "Installing packages: ${packages[*]}"
    
    case "$PACKAGE_MANAGER" in
        pacman)
            if sudo pacman -S --needed --noconfirm "${packages[@]}"; then
                log_message "SUCCESS" "Package installation completed"
            else
                log_message "ERROR" "Package installation failed"
                return 1
            fi
            ;;
        apt)
            if sudo apt update && sudo apt install -y "${packages[@]}"; then
                log_message "SUCCESS" "Package installation completed"
            else
                log_message "ERROR" "Package installation failed"
                return 1
            fi
            ;;
        dnf)
            if sudo dnf install -y "${packages[@]}"; then
                log_message "SUCCESS" "Package installation completed"
            else
                log_message "ERROR" "Package installation failed"
                return 1
            fi
            ;;
        zypper)
            if sudo zypper install -y "${packages[@]}"; then
                log_message "SUCCESS" "Package installation completed"
            else
                log_message "ERROR" "Package installation failed"
                return 1
            fi
            ;;
        *)
            log_message "ERROR" "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
    
    return 0
}

#=====================================
# Reporting Functions
#=====================================

generate_summary() {
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                    VERIFICATION SUMMARY                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Overall status
    local overall_status="PASS"
    if [[ ${#MISSING_CRITICAL[@]} -gt 0 || ${#SYSTEM_ISSUES[@]} -gt 0 ]]; then
        overall_status="FAIL"
    fi
    
    if [[ "$overall_status" == "PASS" ]]; then
        echo -e "${OK} ${GREEN}Overall Status: PASS${NC}"
    else
        echo -e "${ERROR} ${RED}Overall Status: FAIL${NC}"
    fi
    
    echo
    echo -e "${INFO} Statistics:"
    echo -e "   Errors found: ${RED}$ERRORS_FOUND${NC}"
    echo -e "   Warnings found: ${YELLOW}$WARNINGS_FOUND${NC}"
    echo
    
    # Critical issues
    if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
        echo -e "${ERROR} ${RED}Missing critical dependencies:${NC}"
        for dep in "${MISSING_CRITICAL[@]}"; do
            echo -e "   • $dep"
        done
        echo
    fi
    
    # System issues
    if [[ ${#SYSTEM_ISSUES[@]} -gt 0 ]]; then
        echo -e "${ERROR} ${RED}System issues:${NC}"
        for issue in "${SYSTEM_ISSUES[@]}"; do
            echo -e "   • $issue"
        done
        echo
    fi
    
    # Optional dependencies
    if [[ ${#MISSING_OPTIONAL[@]} -gt 0 ]]; then
        echo -e "${WARN} ${YELLOW}Missing optional dependencies:${NC}"
        for dep in "${MISSING_OPTIONAL[@]}"; do
            echo -e "   • $dep"
        done
        echo
    fi
    
    # Performance warnings
    if [[ ${#PERFORMANCE_WARNINGS[@]} -gt 0 ]]; then
        echo -e "${WARN} ${YELLOW}Performance warnings:${NC}"
        for warning in "${PERFORMANCE_WARNINGS[@]}"; do
            echo -e "   • $warning"
        done
        echo
    fi
    
    # Recommendations
    echo -e "${INFO} ${BLUE}Recommendations:${NC}"
    if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
        echo -e "   • Install missing critical dependencies before proceeding"
    fi
    if [[ ${#SYSTEM_ISSUES[@]} -gt 0 ]]; then
        echo -e "   • Resolve system issues before installation"
    fi
    if [[ ${#MISSING_OPTIONAL[@]} -gt 0 ]]; then
        echo -e "   • Consider installing optional dependencies for better experience"
    fi
    if [[ ${#PERFORMANCE_WARNINGS[@]} -gt 0 ]]; then
        echo -e "   • Review performance warnings for optimal setup"
    fi
    
    if [[ "$overall_status" == "PASS" ]]; then
        echo -e "   • ${GREEN}System is ready for HyprSupreme-Builder installation${NC}"
    fi
    
    echo
}

generate_detailed_report() {
    if [[ -z "$REPORT_FILE" ]]; then
        return 0
    fi
    
    log_message "INFO" "Generating detailed report: $REPORT_FILE"
    
    cat << EOF > "$REPORT_FILE"
# HyprSupreme-Builder Prerequisites Verification Report
Generated: $(date)
Script Version: $VERSION

## System Information
- OS: $PRETTY_NAME
- Kernel: $(uname -r)
- Architecture: $(uname -m)
- Distribution Family: ${DISTRO_FAMILY:-unknown}
- Package Manager: ${PACKAGE_MANAGER:-unknown}
- Support Level: ${SUPPORT_LEVEL:-unknown}

## Resource Check
- RAM: $(free -h | awk '/^Mem:/{print $2}')
- Storage: $(df -h . | awk 'NR==2 {print $4}') available
- CPU: $(nproc) cores

## Verification Results
- Errors: $ERRORS_FOUND
- Warnings: $WARNINGS_FOUND

## Missing Critical Dependencies
EOF
    
    if [[ ${#MISSING_CRITICAL[@]} -eq 0 ]]; then
        echo "None" >> "$REPORT_FILE"
    else
        for dep in "${MISSING_CRITICAL[@]}"; do
            echo "- $dep" >> "$REPORT_FILE"
        done
    fi
    
    cat << EOF >> "$REPORT_FILE"

## Missing Optional Dependencies
EOF
    
    if [[ ${#MISSING_OPTIONAL[@]} -eq 0 ]]; then
        echo "None" >> "$REPORT_FILE"
    else
        for dep in "${MISSING_OPTIONAL[@]}"; do
            echo "- $dep" >> "$REPORT_FILE"
        done
    fi
    
    cat << EOF >> "$REPORT_FILE"

## System Issues
EOF
    
    if [[ ${#SYSTEM_ISSUES[@]} -eq 0 ]]; then
        echo "None" >> "$REPORT_FILE"
    else
        for issue in "${SYSTEM_ISSUES[@]}"; do
            echo "- $issue" >> "$REPORT_FILE"
        done
    fi
    
    cat << EOF >> "$REPORT_FILE"

## Performance Warnings
EOF
    
    if [[ ${#PERFORMANCE_WARNINGS[@]} -eq 0 ]]; then
        echo "None" >> "$REPORT_FILE"
    else
        for warning in "${PERFORMANCE_WARNINGS[@]}"; do
            echo "- $warning" >> "$REPORT_FILE"
        done
    fi
    
    log_message "SUCCESS" "Detailed report saved to: $REPORT_FILE"
}

#=====================================
# Main Function
#=====================================

main() {
    print_header
    
    # System detection
    detect_system || exit $EXIT_SYSTEM_INCOMPATIBLE
    detect_distribution || exit $EXIT_SYSTEM_INCOMPATIBLE
    
    # Resource checks
    check_bash_version || exit $EXIT_SYSTEM_INCOMPATIBLE
    check_system_resources || exit $EXIT_INSUFFICIENT_RESOURCES
    check_network_connectivity || exit $EXIT_NETWORK_ERROR
    check_permissions || exit $EXIT_PERMISSION_ERROR
    
    # Dependency checks
    check_critical_dependencies
    check_optional_dependencies
    check_wayland_support
    check_gpu_drivers
    
    # Installation if requested
    if [[ "$CHECK_ONLY" != true ]]; then
        install_missing_dependencies
    fi
    
    # Generate reports
    generate_summary
    generate_detailed_report
    
    # Determine exit code
    if [[ ${#MISSING_CRITICAL[@]} -gt 0 ]]; then
        exit $EXIT_DEPENDENCY_MISSING
    elif [[ ${#SYSTEM_ISSUES[@]} -gt 0 ]]; then
        exit $EXIT_SYSTEM_INCOMPATIBLE
    else
        exit $EXIT_SUCCESS
    fi
}

#=====================================
# Command Line Parsing
#=====================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -a|--auto-install)
            AUTO_INSTALL=true
            shift
            ;;
        -s|--skip-optional)
            SKIP_OPTIONAL=true
            shift
            ;;
        -c|--check-only)
            CHECK_ONLY=true
            shift
            ;;
        -r|--report)
            REPORT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_usage >&2
            exit 1
            ;;
    esac
done

# Run main function
main "$@"

