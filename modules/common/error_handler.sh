#!/bin/bash
# HyprSupreme-Builder Comprehensive Error Handler
# Complete error management and system compatibility framework

set -euo pipefail

#=====================================
# Error Handler Metadata
#=====================================

readonly ERROR_HANDLER_VERSION="2.1.1"
readonly ERROR_HANDLER_NAME="HyprSupreme Error Management System"

# Error categorization constants
readonly ERROR_CATEGORY_SYSTEM="SYSTEM"
readonly ERROR_CATEGORY_DEPENDENCY="DEPENDENCY"
readonly ERROR_CATEGORY_NETWORK="NETWORK"
readonly ERROR_CATEGORY_PERMISSION="PERMISSION"
readonly ERROR_CATEGORY_COMPATIBILITY="COMPATIBILITY"
readonly ERROR_CATEGORY_CONFIGURATION="CONFIGURATION"
readonly ERROR_CATEGORY_HARDWARE="HARDWARE"
readonly ERROR_CATEGORY_USER="USER"
readonly ERROR_CATEGORY_UNKNOWN="UNKNOWN"

# Error severity levels
readonly ERROR_SEVERITY_FATAL="FATAL"
readonly ERROR_SEVERITY_CRITICAL="CRITICAL"
readonly ERROR_SEVERITY_WARNING="WARNING"
readonly ERROR_SEVERITY_INFO="INFO"

# Exit codes following POSIX standards and custom extensions
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_MISUSE_BUILTINS=2
readonly EXIT_CANNOT_EXECUTE=126
readonly EXIT_COMMAND_NOT_FOUND=127
readonly EXIT_INVALID_EXIT_ARGUMENT=128
readonly EXIT_FATAL_SIGNAL_BASE=128

# Custom exit codes for HyprSupreme-Builder
readonly EXIT_SYSTEM_INCOMPATIBLE=10
readonly EXIT_DEPENDENCY_MISSING=11
readonly EXIT_DEPENDENCY_VERSION=12
readonly EXIT_NETWORK_ERROR=13
readonly EXIT_PERMISSION_DENIED=14
readonly EXIT_INSUFFICIENT_RESOURCES=15
readonly EXIT_HARDWARE_INCOMPATIBLE=16
readonly EXIT_CONFIGURATION_ERROR=17
readonly EXIT_USER_CANCELLED=18
readonly EXIT_PACKAGE_MANAGER_ERROR=19
readonly EXIT_GPU_ERROR=20
readonly EXIT_AUDIO_ERROR=21
readonly EXIT_DISPLAY_ERROR=22
readonly EXIT_WAYLAND_ERROR=23
readonly EXIT_SECURITY_ERROR=24
readonly EXIT_BACKUP_ERROR=25

# Color codes for output (not readonly to avoid conflicts)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Status indicators
readonly FATAL_ICON="💀"
readonly CRITICAL_ICON="🚨"
readonly WARNING_ICON="⚠️"
readonly INFO_ICON="ℹ️"
readonly SUCCESS_ICON="✅"
readonly ERROR_ICON="❌"
readonly DEBUG_ICON="🔍"

#=====================================
# Global Error State
#=====================================

# Error tracking arrays
declare -a ERROR_LOG=()
declare -a WARNING_LOG=()
declare -a DEBUG_LOG=()
declare -A ERROR_COUNTS=(["FATAL"]=0 ["CRITICAL"]=0 ["WARNING"]=0 ["INFO"]=0)
declare -A ERROR_CATEGORIES=()

# Error context
ERROR_CONTEXT=""
ERROR_FUNCTION=""
ERROR_LINE=""
ERROR_COMMAND=""
LAST_EXIT_CODE=0
ERROR_RECOVERY_MODE=false
VERBOSE_ERRORS=false
SILENT_MODE=false
LOG_FILE=""
ERROR_REPORT_FILE=""

#=====================================
# Error Handler Initialization
#=====================================

init_error_handler() {
    local log_dir="${1:-logs}"
    local prefix="${2:-hyprsupreme}"
    
    # Create log directory if it doesn't exist
    mkdir -p "$log_dir"
    
    # Set up log files
    LOG_FILE="$log_dir/${prefix}-$(date +%Y%m%d-%H%M%S).log"
    ERROR_REPORT_FILE="$log_dir/${prefix}-errors-$(date +%Y%m%d-%H%M%S).log"
    
    # Error counts already initialized in global declarations
    
    # Set up trap handlers
    trap 'handle_exit $?' EXIT
    trap 'handle_error $LINENO $BASH_COMMAND' ERR
    trap 'handle_signal SIGINT' INT
    trap 'handle_signal SIGTERM' TERM
    trap 'handle_signal SIGHUP' HUP
    
    # Log initialization
    log_message "INFO" "Error handler initialized"
    log_message "INFO" "Log file: $LOG_FILE"
    log_message "INFO" "Error report: $ERROR_REPORT_FILE"
}

#=====================================
# Core Error Handling Functions
#=====================================

handle_error() {
    local line_number="$1"
    local command="$2"
    local exit_code=$?
    
    LAST_EXIT_CODE=$exit_code
    ERROR_LINE="$line_number"
    ERROR_COMMAND="$command"
    
    # Get function context
    if [[ ${#FUNCNAME[@]} -gt 2 ]]; then
        ERROR_FUNCTION="${FUNCNAME[2]}"
    else
        ERROR_FUNCTION="main"
    fi
    
    # Log the error
    local error_msg="Error in function '$ERROR_FUNCTION' at line $line_number: Command '$command' failed with exit code $exit_code"
    log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_SYSTEM" "$error_msg"
    
    # Try to provide context-specific error handling
    case "$command" in
        *pacman*|*apt*|*dnf*|*zypper*)
            handle_package_manager_error "$exit_code" "$command"
            ;;
        *curl*|*wget*)
            handle_network_error "$exit_code" "$command"
            ;;
        *sudo*)
            handle_permission_error "$exit_code" "$command"
            ;;
        *mkdir*|*cp*|*mv*|*rm*)
            handle_filesystem_error "$exit_code" "$command"
            ;;
        *)
            handle_generic_error "$exit_code" "$command"
            ;;
    esac
    
    # Check if we should attempt recovery
    if [[ "$ERROR_RECOVERY_MODE" == true ]]; then
        attempt_error_recovery "$exit_code" "$command"
    fi
}

handle_exit() {
    local exit_code="$1"
    
    if [[ $exit_code -ne 0 ]]; then
        log_message "CRITICAL" "Script exiting with code $exit_code"
        generate_error_report
        
        # Show error summary if not in silent mode
        if [[ "$SILENT_MODE" != true ]]; then
            show_error_summary
        fi
    fi
}

handle_signal() {
    local signal="$1"
    log_message "WARNING" "Received signal: $signal"
    
    case "$signal" in
        SIGINT)
            log_message "INFO" "Interrupt signal received - cleaning up"
            cleanup_on_interrupt
            exit $EXIT_USER_CANCELLED
            ;;
        SIGTERM)
            log_message "INFO" "Termination signal received - shutting down gracefully"
            cleanup_on_termination
            exit $EXIT_SUCCESS
            ;;
        SIGHUP)
            log_message "INFO" "Hangup signal received - reloading configuration"
            reload_configuration
            ;;
    esac
}

#=====================================
# Specific Error Handlers
#=====================================

handle_package_manager_error() {
    local exit_code="$1"
    local command="$2"
    local package_manager=""
    
    # Determine package manager
    case "$command" in
        *pacman*) package_manager="pacman" ;;
        *apt*) package_manager="apt" ;;
        *dnf*) package_manager="dnf" ;;
        *zypper*) package_manager="zypper" ;;
        *) package_manager="unknown" ;;
    esac
    
    case "$exit_code" in
        1)
            case "$package_manager" in
                pacman)
                    log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_DEPENDENCY" \
                        "Pacman operation failed - check /var/log/pacman.log for details"
                    suggest_fix "Check if packages exist: pacman -Ss <package_name>"
                    suggest_fix "Update package database: sudo pacman -Sy"
                    ;;
                apt)
                    log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_DEPENDENCY" \
                        "APT operation failed - package not found or dependency issue"
                    suggest_fix "Update package list: sudo apt update"
                    suggest_fix "Check package availability: apt search <package_name>"
                    ;;
                dnf)
                    log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_DEPENDENCY" \
                        "DNF operation failed - package or repository issue"
                    suggest_fix "Check repositories: dnf repolist"
                    suggest_fix "Search for package: dnf search <package_name>"
                    ;;
                zypper)
                    log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_DEPENDENCY" \
                        "Zypper operation failed - package or repository issue"
                    suggest_fix "Refresh repositories: sudo zypper refresh"
                    suggest_fix "Search for package: zypper search <package_name>"
                    ;;
            esac
            ;;
        100)
            if [[ "$package_manager" == "apt" ]]; then
                log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_DEPENDENCY" \
                    "APT lock error - another package manager is running"
                suggest_fix "Wait for other package operations to complete"
                suggest_fix "Kill stuck processes: sudo killall apt apt-get"
                suggest_fix "Remove lock files: sudo rm /var/lib/dpkg/lock*"
            fi
            ;;
        *)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_DEPENDENCY" \
                "Package manager ($package_manager) failed with exit code $exit_code"
            ;;
    esac
}

handle_network_error() {
    local exit_code="$1"
    local command="$2"
    
    case "$exit_code" in
        6|7)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_NETWORK" \
                "Network connectivity issue - cannot resolve host or connect"
            suggest_fix "Check internet connection"
            suggest_fix "Test DNS resolution: nslookup google.com"
            suggest_fix "Check firewall settings"
            ;;
        22)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_NETWORK" \
                "HTTP error - server returned error status"
            suggest_fix "Check if the URL is correct"
            suggest_fix "Try again later - server might be temporarily down"
            ;;
        28)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_NETWORK" \
                "Operation timeout - server not responding"
            suggest_fix "Check internet connection speed"
            suggest_fix "Try with longer timeout: curl --connect-timeout 30"
            ;;
        35)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_NETWORK" \
                "SSL/TLS error - certificate verification failed"
            suggest_fix "Check system time and date"
            suggest_fix "Update CA certificates: sudo update-ca-certificates"
            ;;
        *)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_NETWORK" \
                "Network operation failed with exit code $exit_code"
            ;;
    esac
}

handle_permission_error() {
    local exit_code="$1"
    local command="$2"
    
    case "$exit_code" in
        1)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_PERMISSION" \
                "Permission denied or sudo authentication failed"
            suggest_fix "Check if user is in sudo group: groups \$USER"
            suggest_fix "Verify sudo configuration: sudo -l"
            suggest_fix "Re-authenticate: sudo -v"
            ;;
        126)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_PERMISSION" \
                "Command cannot be executed - permission denied"
            suggest_fix "Check file permissions: ls -la"
            suggest_fix "Make executable: chmod +x <file>"
            ;;
        127)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_SYSTEM" \
                "Command not found"
            suggest_fix "Check if command exists: which <command>"
            suggest_fix "Install required package"
            suggest_fix "Check PATH variable: echo \$PATH"
            ;;
        *)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_PERMISSION" \
                "Permission-related error with exit code $exit_code"
            ;;
    esac
}

handle_filesystem_error() {
    local exit_code="$1"
    local command="$2"
    
    case "$exit_code" in
        1)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_SYSTEM" \
                "Filesystem operation failed - check permissions and disk space"
            suggest_fix "Check disk space: df -h"
            suggest_fix "Check file permissions: ls -la"
            suggest_fix "Check if destination is writable"
            ;;
        2)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_SYSTEM" \
                "File or directory not found"
            suggest_fix "Verify path exists: ls -la <path>"
            suggest_fix "Create missing directories: mkdir -p <path>"
            ;;
        *)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_SYSTEM" \
                "Filesystem operation failed with exit code $exit_code"
            ;;
    esac
}

handle_generic_error() {
    local exit_code="$1"
    local command="$2"
    
    log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_UNKNOWN" \
        "Command failed: $command (exit code: $exit_code)"
    
    # Provide generic troubleshooting steps
    suggest_fix "Check command syntax and arguments"
    suggest_fix "Verify all required files exist"
    suggest_fix "Run with verbose mode for more details"
    suggest_fix "Check system logs: journalctl -xe"
}

#=====================================
# System Compatibility Checks
#=====================================

check_system_compatibility() {
    log_message "INFO" "Starting comprehensive system compatibility check"
    
    local errors=0
    
    # Operating system compatibility
    errors=$((errors + $(check_os_compatibility)))
    
    # Distribution compatibility
    errors=$((errors + $(check_distribution_compatibility)))
    
    # Kernel compatibility
    errors=$((errors + $(check_kernel_compatibility)))
    
    # Architecture compatibility
    errors=$((errors + $(check_architecture_compatibility)))
    
    # Hardware compatibility
    errors=$((errors + $(check_hardware_compatibility)))
    
    # Software dependencies
    errors=$((errors + $(check_software_dependencies)))
    
    # System resources
    errors=$((errors + $(check_system_resources)))
    
    # Security requirements
    errors=$((errors + $(check_security_requirements)))
    
    if [[ $errors -gt 0 ]]; then
        log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_COMPATIBILITY" \
            "System compatibility check failed with $errors error(s)"
        return $EXIT_SYSTEM_INCOMPATIBLE
    fi
    
    log_message "SUCCESS" "System compatibility check passed"
    return $EXIT_SUCCESS
}

check_os_compatibility() {
    local errors=0
    local os_name=$(uname -s)
    
    case "$os_name" in
        Linux)
            log_message "SUCCESS" "Operating system: Linux - Compatible"
            ;;
        Darwin)
            log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                "macOS is not supported - Hyprland requires Linux with Wayland"
            suggest_fix "Use a Linux distribution with Wayland support"
            suggest_fix "Consider dual-booting or virtual machine"
            errors=$((errors + 1))
            ;;
        CYGWIN*|MINGW*|MSYS*)
            log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                "Windows/Cygwin is not supported - Hyprland requires Linux with Wayland"
            suggest_fix "Use WSL2 with a supported Linux distribution"
            suggest_fix "Consider dual-booting or virtual machine"
            errors=$((errors + 1))
            ;;
        FreeBSD|OpenBSD|NetBSD)
            log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                "BSD systems are not currently supported"
            suggest_fix "Use a Linux distribution instead"
            errors=$((errors + 1))
            ;;
        *)
            log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                "Unknown operating system: $os_name"
            errors=$((errors + 1))
            ;;
    esac
    
    echo $errors
}

check_distribution_compatibility() {
    local errors=0
    
    if [[ ! -f /etc/os-release ]]; then
        log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_COMPATIBILITY" \
            "Cannot detect Linux distribution - /etc/os-release missing"
        errors=$((errors + 1))
        echo $errors
        return
    fi
    
    source /etc/os-release
    local distro_id="${ID,,}"
    local version_id="${VERSION_ID:-}"
    
    case "$distro_id" in
        # Tier 1 - Full Support
        arch)
            log_message "SUCCESS" "Arch Linux - Full support (Tier 1)"
            ;;
        endeavouros)
            log_message "SUCCESS" "EndeavourOS - Full support (Tier 1)"
            ;;
        cachyos)
            log_message "SUCCESS" "CachyOS - Full support (Tier 1)"
            ;;
        manjaro)
            log_message "SUCCESS" "Manjaro - Full support (Tier 1)"
            ;;
        garuda)
            log_message "SUCCESS" "Garuda Linux - Full support (Tier 1)"
            ;;
            
        # Tier 2 - Limited Support
        ubuntu)
            if version_compare "$version_id" "20.04" ">="; then
                log_message "WARNING" "Ubuntu $version_id - Limited support (Tier 2)"
                suggest_fix "Some packages may need manual compilation"
            else
                log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                    "Ubuntu $version_id is too old - minimum version 20.04"
                errors=$((errors + 1))
            fi
            ;;
        debian)
            if version_compare "$version_id" "11" ">="; then
                log_message "WARNING" "Debian $version_id - Limited support (Tier 2)"
                suggest_fix "Some packages may need backports or manual compilation"
            else
                log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                    "Debian $version_id is too old - minimum version 11"
                errors=$((errors + 1))
            fi
            ;;
        fedora)
            if version_compare "$version_id" "35" ">="; then
                log_message "WARNING" "Fedora $version_id - Limited support (Tier 2)"
                suggest_fix "Some packages may need COPR repositories"
            else
                log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                    "Fedora $version_id is too old - minimum version 35"
                errors=$((errors + 1))
            fi
            ;;
        opensuse-tumbleweed)
            log_message "WARNING" "openSUSE Tumbleweed - Limited support (Tier 2)"
            suggest_fix "Some packages may not be available in standard repos"
            ;;
        opensuse-leap)
            if version_compare "$version_id" "15.4" ">="; then
                log_message "WARNING" "openSUSE Leap $version_id - Limited support (Tier 2)"
            else
                log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                    "openSUSE Leap $version_id is too old - minimum version 15.4"
                errors=$((errors + 1))
            fi
            ;;
            
        # Tier 3 - Experimental Support
        void)
            log_message "WARNING" "Void Linux - Experimental support (Tier 3)"
            suggest_fix "Advanced users only - manual configuration required"
            ;;
        gentoo)
            log_message "WARNING" "Gentoo - Experimental support (Tier 3)"
            suggest_fix "Manual compilation and configuration required"
            ;;
        nixos)
            log_message "WARNING" "NixOS - Experimental support (Tier 3)"
            suggest_fix "Custom derivations and configuration required"
            ;;
        alpine)
            log_message "WARNING" "Alpine Linux - Experimental support (Tier 3)"
            suggest_fix "Limited package availability"
            ;;
            
        # Unsupported
        centos|rhel|rocky|almalinux)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                "Enterprise Linux distributions have limited Wayland support"
            suggest_fix "Consider using Fedora instead"
            errors=$((errors + 1))
            ;;
        *)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                "Unsupported Linux distribution: $PRETTY_NAME"
            suggest_fix "Use a supported distribution from Tier 1 or 2"
            errors=$((errors + 1))
            ;;
    esac
    
    echo $errors
}

check_kernel_compatibility() {
    local errors=0
    local kernel_version=$(uname -r | cut -d'-' -f1)
    local major_version=$(echo "$kernel_version" | cut -d'.' -f1)
    local minor_version=$(echo "$kernel_version" | cut -d'.' -f2)
    
    # Hyprland requires relatively recent kernel for Wayland support
    if [[ $major_version -lt 5 ]] || [[ $major_version -eq 5 && $minor_version -lt 15 ]]; then
        log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_COMPATIBILITY" \
            "Kernel $kernel_version is too old - minimum required: 5.15"
        suggest_fix "Update your kernel to at least version 5.15"
        suggest_fix "Consider upgrading your distribution"
        errors=$((errors + 1))
    elif [[ $major_version -eq 5 && $minor_version -lt 19 ]]; then
        log_message "WARNING" "Kernel $kernel_version is older than recommended (6.1+)"
        suggest_fix "Consider updating kernel for better Wayland support"
    else
        log_message "SUCCESS" "Kernel $kernel_version - Compatible"
    fi
    
    # Check for required kernel modules
    local required_modules=("drm" "kms" "wayland")
    for module in "${required_modules[@]}"; do
        if ! lsmod | grep -q "$module" && ! find /lib/modules/$(uname -r) -name "*$module*" -type f 2>/dev/null | grep -q .; then
            log_error "$ERROR_SEVERITY_WARNING" "$ERROR_CATEGORY_HARDWARE" \
                "Kernel module '$module' not found - may affect Wayland functionality"
            suggest_fix "Ensure your kernel has Wayland/DRM support enabled"
        fi
    done
    
    echo $errors
}

check_architecture_compatibility() {
    local errors=0
    local arch=$(uname -m)
    
    case "$arch" in
        x86_64)
            log_message "SUCCESS" "Architecture: $arch - Fully supported"
            ;;
        aarch64|arm64)
            log_message "WARNING" "Architecture: $arch - Limited support"
            suggest_fix "Some packages may not be available for ARM64"
            suggest_fix "Performance may vary compared to x86_64"
            ;;
        armv7l|armhf)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                "Architecture: $arch - Not recommended for Hyprland"
            suggest_fix "Use ARM64/AArch64 system for better performance"
            errors=$((errors + 1))
            ;;
        i386|i686)
            log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                "Architecture: $arch - 32-bit systems not supported"
            suggest_fix "Use a 64-bit system (x86_64 or ARM64)"
            errors=$((errors + 1))
            ;;
        *)
            log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_COMPATIBILITY" \
                "Architecture: $arch - Unsupported"
            errors=$((errors + 1))
            ;;
    esac
    
    echo $errors
}

check_hardware_compatibility() {
    local errors=0
    
    # GPU compatibility check
    errors=$((errors + $(check_gpu_compatibility)))
    
    # Memory check
    errors=$((errors + $(check_memory_compatibility)))
    
    # Storage check
    errors=$((errors + $(check_storage_compatibility)))
    
    # Display compatibility
    errors=$((errors + $(check_display_compatibility)))
    
    # Audio compatibility
    errors=$((errors + $(check_audio_compatibility)))
    
    echo $errors
}

check_gpu_compatibility() {
    local errors=0
    local gpu_found=false
    
    # Check for GPU hardware
    if command -v lspci &>/dev/null; then
        local gpu_info=$(lspci | grep -i "vga\|3d\|display" | head -1)
        if [[ -n "$gpu_info" ]]; then
            gpu_found=true
            log_message "INFO" "GPU detected: $gpu_info"
            
            # NVIDIA specific checks
            if echo "$gpu_info" | grep -qi "nvidia"; then
                if command -v nvidia-smi &>/dev/null; then
                    local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1)
                    if [[ -n "$driver_version" ]]; then
                        log_message "SUCCESS" "NVIDIA drivers: $driver_version"
                        # Check for minimum driver version (470+ for Wayland)
                        if version_compare "$driver_version" "470" ">="; then
                            log_message "SUCCESS" "NVIDIA driver supports Wayland"
                        else
                            log_message "WARNING" "NVIDIA driver $driver_version may have limited Wayland support"
                            suggest_fix "Consider updating NVIDIA drivers to 470+"
                        fi
                    else
                        log_message "WARNING" "NVIDIA GPU detected but driver version check failed"
                    fi
                else
                    log_error "$ERROR_SEVERITY_WARNING" "$ERROR_CATEGORY_HARDWARE" \
                        "NVIDIA GPU detected but no drivers found"
                    suggest_fix "Install NVIDIA proprietary drivers"
                    suggest_fix "Or use nouveau open-source drivers (limited performance)"
                fi
            fi
            
            # AMD specific checks
            if echo "$gpu_info" | grep -qi "amd\|radeon"; then
                if [[ -d /sys/class/drm/card0 ]]; then
                    log_message "SUCCESS" "AMD/Radeon drivers detected"
                    # Check for AMDGPU vs radeon driver
                    if lsmod | grep -q "amdgpu"; then
                        log_message "SUCCESS" "Using AMDGPU driver (recommended)"
                    elif lsmod | grep -q "radeon"; then
                        log_message "WARNING" "Using legacy radeon driver"
                        suggest_fix "Consider switching to AMDGPU driver for better performance"
                    fi
                else
                    log_error "$ERROR_SEVERITY_WARNING" "$ERROR_CATEGORY_HARDWARE" \
                        "AMD GPU detected but drivers may be missing"
                fi
            fi
            
            # Intel specific checks
            if echo "$gpu_info" | grep -qi "intel"; then
                if lsmod | grep -q "i915"; then
                    log_message "SUCCESS" "Intel graphics drivers loaded"
                else
                    log_error "$ERROR_SEVERITY_WARNING" "$ERROR_CATEGORY_HARDWARE" \
                        "Intel GPU detected but i915 driver not loaded"
                fi
            fi
        fi
    fi
    
    if [[ "$gpu_found" == false ]]; then
        log_error "$ERROR_SEVERITY_WARNING" "$ERROR_CATEGORY_HARDWARE" \
            "No discrete GPU detected - using software rendering"
        suggest_fix "Performance may be limited with software rendering"
        suggest_fix "Consider installing GPU drivers if you have discrete graphics"
    fi
    
    # Check for Wayland support
    if ! ldconfig -p 2>/dev/null | grep -q "libwayland-client"; then
        log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_HARDWARE" \
            "Wayland client libraries not found"
        suggest_fix "Install wayland development packages"
        errors=$((errors + 1))
    fi
    
    echo $errors
}

check_memory_compatibility() {
    local errors=0
    local total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_ram_gb=$((total_ram_kb / 1024 / 1024))
    local available_ram_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local available_ram_gb=$((available_ram_kb / 1024 / 1024))
    
    log_message "INFO" "Total RAM: ${total_ram_gb}GB, Available: ${available_ram_gb}GB"
    
    if [[ $total_ram_gb -lt 4 ]]; then
        log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_HARDWARE" \
            "Insufficient RAM: ${total_ram_gb}GB (minimum: 4GB)"
        suggest_fix "Add more RAM to your system"
        suggest_fix "Consider using a lighter desktop environment"
        errors=$((errors + 1))
    elif [[ $total_ram_gb -lt 8 ]]; then
        log_message "WARNING" "RAM below recommended: ${total_ram_gb}GB (recommended: 8GB+)"
        suggest_fix "Performance may be limited with less than 8GB RAM"
        suggest_fix "Consider closing other applications during installation"
    else
        log_message "SUCCESS" "RAM: ${total_ram_gb}GB - Adequate"
    fi
    
    # Check for swap
    local swap_total_kb=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    local swap_total_gb=$((swap_total_kb / 1024 / 1024))
    
    if [[ $swap_total_gb -eq 0 && $total_ram_gb -lt 8 ]]; then
        log_message "WARNING" "No swap space configured with limited RAM"
        suggest_fix "Consider adding swap space: sudo fallocate -l 2G /swapfile"
        suggest_fix "Enable swap: sudo swapon /swapfile"
    fi
    
    echo $errors
}

check_storage_compatibility() {
    local errors=0
    local available_space_kb=$(df . | awk 'NR==2 {print $4}')
    local available_space_gb=$((available_space_kb / 1024 / 1024))
    
    log_message "INFO" "Available storage: ${available_space_gb}GB"
    
    if [[ $available_space_gb -lt 8 ]]; then
        log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_HARDWARE" \
            "Insufficient storage: ${available_space_gb}GB (minimum: 8GB)"
        suggest_fix "Free up disk space"
        suggest_fix "Clean package cache and temporary files"
        errors=$((errors + 1))
    elif [[ $available_space_gb -lt 20 ]]; then
        log_message "WARNING" "Storage below recommended: ${available_space_gb}GB (recommended: 20GB+)"
        suggest_fix "Consider freeing up more space for optimal performance"
    else
        log_message "SUCCESS" "Storage: ${available_space_gb}GB - Adequate"
    fi
    
    # Check filesystem type
    local filesystem=$(df -T . | awk 'NR==2 {print $2}')
    case "$filesystem" in
        ext4|btrfs|xfs|f2fs)
            log_message "SUCCESS" "Filesystem: $filesystem - Compatible"
            ;;
        ntfs|fat32|vfat)
            log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_HARDWARE" \
                "Filesystem: $filesystem - Not recommended for Linux"
            suggest_fix "Use a native Linux filesystem (ext4, btrfs, xfs)"
            errors=$((errors + 1))
            ;;
        *)
            log_message "WARNING" "Filesystem: $filesystem - Compatibility unknown"
            ;;
    esac
    
    echo $errors
}

check_display_compatibility() {
    local errors=0
    
    # Check for display server
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        log_message "SUCCESS" "Currently running Wayland session"
    elif [[ -n "${DISPLAY:-}" ]]; then
        log_message "WARNING" "Currently running X11 session"
        suggest_fix "Hyprland works best with Wayland"
        suggest_fix "Log out and select Wayland session if available"
    else
        log_message "WARNING" "No display server detected (running headless?)"
        suggest_fix "Ensure you're running in a graphical environment"
    fi
    
    # Check for display resolution
    if command -v xrandr &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
        local resolution=$(xrandr --current | grep '*' | head -1 | awk '{print $1}')
        if [[ -n "$resolution" ]]; then
            log_message "INFO" "Current resolution: $resolution"
        fi
    elif command -v wlr-randr &>/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        local resolution=$(wlr-randr | grep -E '^\s+[0-9]+x[0-9]+' | head -1 | awk '{print $1}')
        if [[ -n "$resolution" ]]; then
            log_message "INFO" "Current resolution: $resolution"
        fi
    fi
    
    # Check for multiple monitors
    local monitor_count=0
    if command -v xrandr &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
        monitor_count=$(xrandr --listmonitors | grep -c "Monitor")
    elif [[ -d /sys/class/drm ]]; then
        monitor_count=$(find /sys/class/drm -name "card*-*" -type d | wc -l)
    fi
    
    if [[ $monitor_count -gt 1 ]]; then
        log_message "INFO" "Multiple monitors detected: $monitor_count"
        suggest_fix "Configure multi-monitor setup after installation"
    fi
    
    echo $errors
}

check_audio_compatibility() {
    local errors=0
    
    # Check for audio system
    if systemctl --user is-active --quiet pipewire; then
        log_message "SUCCESS" "PipeWire audio system detected"
    elif systemctl --user is-active --quiet pulseaudio; then
        log_message "SUCCESS" "PulseAudio system detected"
        suggest_fix "Consider migrating to PipeWire for better performance"
    elif pgrep -x "pulseaudio" >/dev/null; then
        log_message "SUCCESS" "PulseAudio running (non-systemd)"
    else
        log_message "WARNING" "No audio system detected"
        suggest_fix "Install PipeWire or PulseAudio"
    fi
    
    # Check for audio devices
    if [[ -d /proc/asound ]]; then
        local audio_cards=$(cat /proc/asound/cards 2>/dev/null | grep -E "^\s*[0-9]" | wc -l)
        if [[ $audio_cards -gt 0 ]]; then
            log_message "SUCCESS" "Audio devices detected: $audio_cards"
        else
            log_message "WARNING" "No audio devices found"
            suggest_fix "Check if audio hardware is properly connected"
        fi
    fi
    
    echo $errors
}

check_software_dependencies() {
    local errors=0
    
    # Essential system tools
    local essential_tools=("bash" "sudo" "systemctl" "grep" "awk" "sed")
    for tool in "${essential_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_DEPENDENCY" \
                "Essential tool missing: $tool"
            errors=$((errors + 1))
        fi
    done
    
    # Development tools
    local dev_tools=("git" "curl" "wget" "unzip" "make" "gcc")
    local missing_dev_tools=()
    for tool in "${dev_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_dev_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_dev_tools[@]} -gt 0 ]]; then
        log_message "WARNING" "Missing development tools: ${missing_dev_tools[*]}"
        suggest_fix "Install development tools package (build-essential, base-devel, etc.)"
    fi
    
    # Package manager check
    local package_managers=("pacman" "apt" "dnf" "zypper")
    local pm_found=false
    for pm in "${package_managers[@]}"; do
        if command -v "$pm" &>/dev/null; then
            log_message "SUCCESS" "Package manager: $pm"
            pm_found=true
            break
        fi
    done
    
    if [[ "$pm_found" == false ]]; then
        log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_DEPENDENCY" \
            "No supported package manager found"
        errors=$((errors + 1))
    fi
    
    # Python check
    if command -v python3 &>/dev/null; then
        local python_version=$(python3 --version 2>&1 | awk '{print $2}')
        if version_compare "$python_version" "3.8" ">="; then
            log_message "SUCCESS" "Python: $python_version"
        else
            log_error "$ERROR_SEVERITY_WARNING" "$ERROR_CATEGORY_DEPENDENCY" \
                "Python $python_version is below recommended (3.8+)"
        fi
    else
        log_message "WARNING" "Python 3 not found"
        suggest_fix "Install Python 3.8+"
    fi
    
    echo $errors
}

check_system_resources() {
    local errors=0
    
    # CPU check
    local cpu_cores=$(nproc)
    log_message "INFO" "CPU cores: $cpu_cores"
    
    if [[ $cpu_cores -lt 2 ]]; then
        log_message "WARNING" "Single-core CPU detected - performance may be limited"
        suggest_fix "Consider using a lighter window manager"
    fi
    
    # Load average check
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    if [[ -n "$load_avg" ]]; then
        # Convert to integer for comparison
        local load_int=$(echo "$load_avg" | cut -d'.' -f1)
        if [[ $load_int -gt $cpu_cores ]]; then
            log_message "WARNING" "High system load: $load_avg (cores: $cpu_cores)"
            suggest_fix "Wait for system load to decrease before installation"
        fi
    fi
    
    # Process count check
    local process_count=$(ps aux | wc -l)
    if [[ $process_count -gt 500 ]]; then
        log_message "WARNING" "High process count: $process_count"
        suggest_fix "Consider closing unnecessary applications"
    fi
    
    # Disk I/O check
    if command -v iostat &>/dev/null; then
        local io_wait=$(iostat -c 1 1 | tail -1 | awk '{print $4}')
        if [[ -n "$io_wait" ]] && (( $(echo "$io_wait > 20" | bc -l 2>/dev/null || echo 0) )); then
            log_message "WARNING" "High disk I/O wait: $io_wait%"
            suggest_fix "Wait for disk activity to decrease"
        fi
    fi
    
    echo $errors
}

check_security_requirements() {
    local errors=0
    
    # Check if running as root (should not be)
    if [[ $EUID -eq 0 ]]; then
        log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_SECURITY" \
            "Running as root is not allowed"
        suggest_fix "Run as a regular user with sudo privileges"
        errors=$((errors + 1))
    fi
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        if ! timeout 10 sudo -v 2>/dev/null; then
            log_error "$ERROR_SEVERITY_FATAL" "$ERROR_CATEGORY_PERMISSION" \
                "Sudo access required but not available"
            suggest_fix "Add user to sudo group: sudo usermod -aG sudo \$USER"
            suggest_fix "Or configure sudoers file"
            errors=$((errors + 1))
        fi
    fi
    
    # Check for write permissions in home directory
    if [[ ! -w "$HOME" ]]; then
        log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_PERMISSION" \
            "No write permission in home directory"
        suggest_fix "Fix home directory permissions: sudo chown -R \$USER:\$USER \$HOME"
        errors=$((errors + 1))
    fi
    
    # Check SELinux status
    if command -v getenforce &>/dev/null; then
        local selinux_status=$(getenforce 2>/dev/null || echo "Unknown")
        case "$selinux_status" in
            Enforcing)
                log_message "WARNING" "SELinux is enforcing - may cause issues"
                suggest_fix "Consider setting SELinux to permissive mode during installation"
                ;;
            Permissive)
                log_message "INFO" "SELinux is in permissive mode"
                ;;
            Disabled)
                log_message "INFO" "SELinux is disabled"
                ;;
        esac
    fi
    
    # Check AppArmor status
    if command -v aa-status &>/dev/null; then
        if aa-status --enabled 2>/dev/null; then
            log_message "INFO" "AppArmor is enabled"
        fi
    fi
    
    # Check for secure boot
    if [[ -d /sys/firmware/efi ]]; then
        if [[ -f /sys/firmware/efi/efivars/SecureBoot-* ]] 2>/dev/null; then
            log_message "INFO" "UEFI Secure Boot may be enabled"
            suggest_fix "Secure Boot may interfere with some graphics drivers"
        fi
    fi
    
    echo $errors
}

#=====================================
# Utility Functions
#=====================================

version_compare() {
    local version1="$1"
    local version2="$2"
    local operator="$3"
    
    # Remove any non-numeric characters except dots
    version1=$(echo "$version1" | sed 's/[^0-9.]//g')
    version2=$(echo "$version2" | sed 's/[^0-9.]//g')
    
    # Convert to comparable format
    local ver1_comparable=$(echo "$version1" | awk -F. '{printf "%d%03d%03d", $1,$2,$3}')
    local ver2_comparable=$(echo "$version2" | awk -F. '{printf "%d%03d%03d", $1,$2,$3}')
    
    case "$operator" in
        ">=")
            [[ $ver1_comparable -ge $ver2_comparable ]]
            ;;
        ">")
            [[ $ver1_comparable -gt $ver2_comparable ]]
            ;;
        "<=")
            [[ $ver1_comparable -le $ver2_comparable ]]
            ;;
        "<")
            [[ $ver1_comparable -lt $ver2_comparable ]]
            ;;
        "=="|"=")
            [[ $ver1_comparable -eq $ver2_comparable ]]
            ;;
        "!=")
            [[ $ver1_comparable -ne $ver2_comparable ]]
            ;;
        *)
            return 1
            ;;
    esac
}

log_error() {
    local severity="$1"
    local category="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Increment error count
    ((ERROR_COUNTS[$severity]++)) || true
    
    # Add to error log
    local error_entry="[$timestamp] [$severity] [$category] $message"
    case "$severity" in
        FATAL)
            ERROR_LOG+=("$error_entry")
            if [[ "$SILENT_MODE" != true ]]; then
                echo -e "${FATAL_ICON} ${RED}${BOLD}FATAL${NC} ${RED}[$category]${NC} $message" >&2
            fi
            ;;
        CRITICAL)
            ERROR_LOG+=("$error_entry")
            if [[ "$SILENT_MODE" != true ]]; then
                echo -e "${CRITICAL_ICON} ${RED}${BOLD}CRITICAL${NC} ${RED}[$category]${NC} $message" >&2
            fi
            ;;
        WARNING)
            WARNING_LOG+=("$error_entry")
            if [[ "$SILENT_MODE" != true ]]; then
                echo -e "${WARNING_ICON} ${YELLOW}${BOLD}WARNING${NC} ${YELLOW}[$category]${NC} $message"
            fi
            ;;
        INFO)
            if [[ "$VERBOSE_ERRORS" == true ]] && [[ "$SILENT_MODE" != true ]]; then
                echo -e "${INFO_ICON} ${BLUE}${BOLD}INFO${NC} ${BLUE}[$category]${NC} $message"
            fi
            ;;
    esac
    
    # Write to log file
    if [[ -n "$LOG_FILE" ]]; then
        echo "$error_entry" >> "$LOG_FILE"
    fi
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        SUCCESS)
            if [[ "$SILENT_MODE" != true ]]; then
                echo -e "${SUCCESS_ICON} ${GREEN}$message${NC}"
            fi
            ;;
        INFO)
            if [[ "$SILENT_MODE" != true ]]; then
                echo -e "${INFO_ICON} $message"
            fi
            ;;
        DEBUG)
            if [[ "$VERBOSE_ERRORS" == true ]] && [[ "$SILENT_MODE" != true ]]; then
                echo -e "${DEBUG_ICON} ${DIM}$message${NC}"
            fi
            DEBUG_LOG+=("[$timestamp] [DEBUG] $message")
            ;;
        *)
            if [[ "$SILENT_MODE" != true ]]; then
                echo "$message"
            fi
            ;;
    esac
    
    # Write to log file
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

suggest_fix() {
    local suggestion="$1"
    if [[ "$SILENT_MODE" != true ]]; then
        echo -e "   ${CYAN}💡 Suggestion:${NC} $suggestion"
    fi
    
    # Write to log file
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$timestamp] [SUGGESTION] $suggestion" >> "$LOG_FILE"
    fi
}

#=====================================
# Error Recovery Functions
#=====================================

attempt_error_recovery() {
    local exit_code="$1"
    local command="$2"
    
    log_message "INFO" "Attempting error recovery for command: $command"
    
    case "$command" in
        *pacman*)
            recover_pacman_error "$exit_code"
            ;;
        *apt*)
            recover_apt_error "$exit_code"
            ;;
        *curl*|*wget*)
            recover_network_error "$exit_code"
            ;;
        *mkdir*|*cp*|*mv*)
            recover_filesystem_error "$exit_code"
            ;;
        *)
            log_message "WARNING" "No specific recovery method for command: $command"
            ;;
    esac
}

recover_pacman_error() {
    local exit_code="$1"
    
    case "$exit_code" in
        1)
            log_message "INFO" "Attempting to update package database"
            if sudo pacman -Sy --noconfirm; then
                log_message "SUCCESS" "Package database updated successfully"
                return 0
            fi
            ;;
    esac
    
    log_message "WARNING" "Pacman error recovery failed"
    return 1
}

recover_apt_error() {
    local exit_code="$1"
    
    case "$exit_code" in
        100)
            log_message "INFO" "Attempting to fix APT lock issues"
            sudo killall -9 apt apt-get 2>/dev/null || true
            sudo rm -f /var/lib/dpkg/lock* 2>/dev/null || true
            sudo rm -f /var/cache/apt/archives/lock 2>/dev/null || true
            if sudo dpkg --configure -a; then
                log_message "SUCCESS" "APT lock issues resolved"
                return 0
            fi
            ;;
        1)
            log_message "INFO" "Attempting to update package lists"
            if sudo apt update; then
                log_message "SUCCESS" "Package lists updated successfully"
                return 0
            fi
            ;;
    esac
    
    log_message "WARNING" "APT error recovery failed"
    return 1
}

recover_network_error() {
    local exit_code="$1"
    
    log_message "INFO" "Testing network connectivity"
    
    # Try different DNS servers
    local dns_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    for dns in "${dns_servers[@]}"; do
        if ping -c 1 -W 5 "$dns" &>/dev/null; then
            log_message "SUCCESS" "Network connectivity restored"
            return 0
        fi
    done
    
    log_message "WARNING" "Network error recovery failed"
    return 1
}

recover_filesystem_error() {
    local exit_code="$1"
    
    log_message "INFO" "Checking filesystem permissions and space"
    
    # Check disk space
    local available_space=$(df . | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1048576 ]]; then # Less than 1GB
        log_message "WARNING" "Low disk space: $((available_space / 1024))MB available"
        return 1
    fi
    
    # Try to create a test file
    local test_file="/tmp/hyprsupreme-test-$$"
    if touch "$test_file" 2>/dev/null; then
        rm -f "$test_file"
        log_message "SUCCESS" "Filesystem permissions appear correct"
        return 0
    fi
    
    log_message "WARNING" "Filesystem error recovery failed"
    return 1
}

#=====================================
# Cleanup Functions
#=====================================

cleanup_on_interrupt() {
    log_message "WARNING" "Installation interrupted by user"
    
    # Kill any running background processes
    if [[ -n "${!}" ]]; then
        kill "${!}" 2>/dev/null || true
    fi
    
    # Clean up temporary files
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    
    # Generate final report
    generate_error_report
}

cleanup_on_termination() {
    log_message "INFO" "Graceful shutdown initiated"
    
    # Save current state
    save_installation_state
    
    # Generate final report
    generate_error_report
}

reload_configuration() {
    log_message "INFO" "Reloading configuration"
    
    # Re-read configuration if it exists
    if [[ -f "$HOME/.config/hyprsupreme/config.sh" ]]; then
        source "$HOME/.config/hyprsupreme/config.sh"
        log_message "SUCCESS" "Configuration reloaded"
    fi
}

save_installation_state() {
    local state_file="$HOME/.config/hyprsupreme/installation_state.json"
    mkdir -p "$(dirname "$state_file")"
    
    cat > "$state_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "error_counts": {
        "fatal": ${ERROR_COUNTS[FATAL]},
        "critical": ${ERROR_COUNTS[CRITICAL]},
        "warning": ${ERROR_COUNTS[WARNING]},
        "info": ${ERROR_COUNTS[INFO]}
    },
    "last_error": "$ERROR_COMMAND",
    "context": "$ERROR_CONTEXT",
    "function": "$ERROR_FUNCTION",
    "line": "$ERROR_LINE"
}
EOF
    
    log_message "INFO" "Installation state saved to: $state_file"
}

#=====================================
# Reporting Functions
#=====================================

generate_error_report() {
    if [[ -z "$ERROR_REPORT_FILE" ]]; then
        return 0
    fi
    
    log_message "INFO" "Generating comprehensive error report"
    
    cat > "$ERROR_REPORT_FILE" << EOF
# HyprSupreme-Builder Error Report
Generated: $(date)
Error Handler Version: $ERROR_HANDLER_VERSION

## Summary
- Fatal Errors: ${ERROR_COUNTS[FATAL]}
- Critical Errors: ${ERROR_COUNTS[CRITICAL]}
- Warnings: ${ERROR_COUNTS[WARNING]}
- Info Messages: ${ERROR_COUNTS[INFO]}

## System Information
- OS: $(uname -o 2>/dev/null || echo "Unknown")
- Kernel: $(uname -r)
- Architecture: $(uname -m)
- Shell: $0
- User: $(whoami)
- Working Directory: $(pwd)
- Time: $(date)

## Environment
- PATH: $PATH
- SHELL: ${SHELL:-Unknown}
- DISPLAY: ${DISPLAY:-Not set}
- WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-Not set}
- XDG_SESSION_TYPE: ${XDG_SESSION_TYPE:-Unknown}

## Error Details

### Fatal/Critical Errors
EOF
    
    # Add error details
    for error in "${ERROR_LOG[@]}"; do
        echo "- $error" >> "$ERROR_REPORT_FILE"
    done
    
    cat >> "$ERROR_REPORT_FILE" << EOF

### Warnings
EOF
    
    # Add warning details
    for warning in "${WARNING_LOG[@]}"; do
        echo "- $warning" >> "$ERROR_REPORT_FILE"
    done
    
    if [[ "$VERBOSE_ERRORS" == true ]]; then
        cat >> "$ERROR_REPORT_FILE" << EOF

### Debug Information
EOF
        
        # Add debug details
        for debug in "${DEBUG_LOG[@]}"; do
            echo "- $debug" >> "$ERROR_REPORT_FILE"
        done
    fi
    
    cat >> "$ERROR_REPORT_FILE" << EOF

## Hardware Information
$(lscpu 2>/dev/null | head -10 || echo "CPU information not available")

$(free -h 2>/dev/null || echo "Memory information not available")

$(df -h 2>/dev/null | head -5 || echo "Disk information not available")

$(lspci 2>/dev/null | grep -i "vga\|3d\|display" || echo "GPU information not available")

## Distribution Information
EOF
    
    if [[ -f /etc/os-release ]]; then
        cat /etc/os-release >> "$ERROR_REPORT_FILE"
    else
        echo "Distribution information not available" >> "$ERROR_REPORT_FILE"
    fi
    
    cat >> "$ERROR_REPORT_FILE" << EOF

## Kernel Modules
$(lsmod 2>/dev/null | head -10 || echo "Kernel module information not available")

## Recent System Logs
$(journalctl --no-pager -n 20 2>/dev/null || echo "System logs not available")

---
End of Error Report
EOF
    
    log_message "SUCCESS" "Error report saved to: $ERROR_REPORT_FILE"
}

show_error_summary() {
    local total_errors=$((ERROR_COUNTS[FATAL] + ERROR_COUNTS[CRITICAL]))
    local total_warnings=${ERROR_COUNTS[WARNING]}
    
    echo
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${WHITE}                        ERROR SUMMARY                           ${RED}║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    if [[ $total_errors -gt 0 ]]; then
        echo -e "${CRITICAL_ICON} ${RED}${BOLD}ERRORS DETECTED${NC}"
        echo -e "   Fatal: ${ERROR_COUNTS[FATAL]}"
        echo -e "   Critical: ${ERROR_COUNTS[CRITICAL]}"
        echo
        
        if [[ ${#ERROR_LOG[@]} -gt 0 ]]; then
            echo -e "${RED}Recent errors:${NC}"
            local count=0
            for error in "${ERROR_LOG[@]}"; do
                if [[ $count -lt 5 ]]; then
                    echo -e "   • ${error#*] }"
                    ((count++))
                fi
            done
            
            if [[ ${#ERROR_LOG[@]} -gt 5 ]]; then
                echo -e "   ... and $((${#ERROR_LOG[@]} - 5)) more errors"
            fi
        fi
    fi
    
    if [[ $total_warnings -gt 0 ]]; then
        echo
        echo -e "${WARNING_ICON} ${YELLOW}${BOLD}WARNINGS${NC}"
        echo -e "   Count: ${ERROR_COUNTS[WARNING]}"
        
        if [[ ${#WARNING_LOG[@]} -gt 0 ]]; then
            echo -e "${YELLOW}Recent warnings:${NC}"
            local count=0
            for warning in "${WARNING_LOG[@]}"; do
                if [[ $count -lt 3 ]]; then
                    echo -e "   • ${warning#*] }"
                    ((count++))
                fi
            done
        fi
    fi
    
    echo
    echo -e "${INFO_ICON} ${BLUE}For detailed information:${NC}"
    echo -e "   • Log file: ${LOG_FILE:-Not available}"
    echo -e "   • Error report: ${ERROR_REPORT_FILE:-Not available}"
    echo -e "   • System check: ./tools/verify_prerequisites.sh --verbose"
    echo
    
    if [[ $total_errors -gt 0 ]]; then
        echo -e "${CRITICAL_ICON} ${RED}${BOLD}Installation cannot proceed with critical errors${NC}"
        echo -e "   Please resolve the issues above and try again"
    elif [[ $total_warnings -gt 0 ]]; then
        echo -e "${WARNING_ICON} ${YELLOW}Installation can proceed but warnings should be reviewed${NC}"
    fi
    
    echo
}

#=====================================
# Configuration Functions
#=====================================

set_error_handler_options() {
    local options="$1"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                VERBOSE_ERRORS=true
                shift
                ;;
            --silent|-s)
                SILENT_MODE=true
                shift
                ;;
            --recovery|-r)
                ERROR_RECOVERY_MODE=true
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            --error-report)
                ERROR_REPORT_FILE="$2"
                shift 2
                ;;
            --context)
                ERROR_CONTEXT="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
}

#=====================================
# Main Error Handler Function
#=====================================

run_with_error_handling() {
    local command="$1"
    shift
    local args=("$@")
    
    ERROR_CONTEXT="$command"
    log_message "DEBUG" "Executing: $command ${args[*]}"
    
    # Execute command with error handling
    if "$command" "${args[@]}"; then
        log_message "DEBUG" "Command succeeded: $command"
        return 0
    else
        local exit_code=$?
        log_error "$ERROR_SEVERITY_CRITICAL" "$ERROR_CATEGORY_SYSTEM" \
            "Command failed: $command (exit code: $exit_code)"
        return $exit_code
    fi
}

# Export functions for use in other scripts
export -f init_error_handler
export -f log_error
export -f log_message
export -f suggest_fix
export -f check_system_compatibility
export -f run_with_error_handling
export -f set_error_handler_options

# Initialize if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_error_handler
    check_system_compatibility
fi

