#!/bin/bash
# HyprSupreme-Builder - Comprehensive Dependency Validator

# Enable strict error handling
set -o pipefail

# Define exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_DEPENDENCY_ERROR=2
readonly EXIT_PERMISSION_ERROR=3
readonly EXIT_VALIDATION_ERROR=4
readonly EXIT_PYTHON_ERROR=5
readonly EXIT_CONFIG_ERROR=6

# Get absolute path to this script
readonly SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
readonly FUNCTIONS_PATH="${SCRIPT_DIR}/../common/functions.sh"

# Load common functions
if [[ ! -f "${FUNCTIONS_PATH}" ]]; then
    echo "Error: Common functions file not found at ${FUNCTIONS_PATH}" >&2
    exit "${EXIT_GENERAL_ERROR}"
fi

echo "Debug: Sourcing functions from ${FUNCTIONS_PATH}" >&2

if ! source "${FUNCTIONS_PATH}"; then
    echo "Error: Failed to source common functions" >&2
    exit "${EXIT_GENERAL_ERROR}"
fi

# Dependency validation configuration
VALIDATION_LOG="${HOME}/.cache/hyprsupreme/validation.log"
DEPENDENCY_CACHE="${HOME}/.cache/hyprsupreme/dependencies.json"

# System dependencies with version requirements
declare -A SYSTEM_DEPS=(
    ["pacman"]="6.0.0"
    ["git"]="2.30.0"
    ["curl"]="7.68.0"
    ["bash"]="5.0.0"
    ["systemctl"]="247"
    ["sudo"]="1.9.0"
)

# Python dependencies with version requirements
declare -A PYTHON_DEPS=(
    ["python3"]="3.9.0"
    ["pip3"]="21.0.0"
)

# Desktop environment dependencies
declare -A DE_DEPS=(
    ["wayland"]="1.20.0"
    ["hyprland"]="0.35.0"
)

# Optional dependencies that enhance functionality
declare -A OPTIONAL_DEPS=(
    ["flatpak"]="1.12.0"
    ["docker"]="20.10.0"
    ["yay"]="12.0.0"
    ["paru"]="1.11.0"
)

# Initialize dependency validation
init_dependency_validation() {
    log_info "Initializing comprehensive dependency validation..."
    
    local log_dir
    log_dir="$(dirname "${VALIDATION_LOG}")"
    if ! mkdir -p "${log_dir}"; then
        log_error "Failed to create log directory: ${log_dir}"
        return "${EXIT_PERMISSION_ERROR}"
    fi
    
    local cache_dir
    cache_dir="$(dirname "${DEPENDENCY_CACHE}")"
    if ! mkdir -p "${cache_dir}"; then
        log_error "Failed to create cache directory: ${cache_dir}"
        return "${EXIT_PERMISSION_ERROR}"
    fi
    
    if ! echo "# HyprSupreme Dependency Validation Log - $(date)" > "${VALIDATION_LOG}"; then
        log_error "Failed to create validation log file: ${VALIDATION_LOG}"
        return "${EXIT_PERMISSION_ERROR}"
    fi
    
    log_success "Dependency validation initialized"
    return "${EXIT_SUCCESS}"
}

# Check all system dependencies
validate_all_dependencies() {
    log_info "Running comprehensive dependency validation..."
    
    local validation_start
    validation_start=$(date +%s) || validation_start=0
    
    local total_deps=0
    local valid_deps=0
    local missing_deps=()
    local version_issues=()
    local validation_result="${EXIT_SUCCESS}"
    
    # Validate system dependencies
    log_info "Validating system dependencies..."
    for dep in "${!SYSTEM_DEPS[@]}"; do
        ((total_deps++))
        if validate_system_dependency "${dep}" "${SYSTEM_DEPS[${dep}]}"; then
            ((valid_deps++))
        else
            missing_deps+=("${dep}")
            # Critical system dependencies are required
            validation_result="${EXIT_DEPENDENCY_ERROR}"
        fi
    done
    
    # Validate Python dependencies
    log_info "Validating Python dependencies..."
    for dep in "${!PYTHON_DEPS[@]}"; do
        ((total_deps++))
        if validate_python_dependency "${dep}" "${PYTHON_DEPS[${dep}]}"; then
            ((valid_deps++))
        else
            missing_deps+=("${dep}")
            # Python dependencies are important but less critical
            [[ "${validation_result}" -eq "${EXIT_SUCCESS}" ]] && validation_result="${EXIT_PYTHON_ERROR}"
        fi
    done
    
    # Validate desktop environment dependencies
    log_info "Validating desktop environment dependencies..."
    for dep in "${!DE_DEPS[@]}"; do
        ((total_deps++))
        if validate_de_dependency "${dep}" "${DE_DEPS[${dep}]}"; then
            ((valid_deps++))
        else
            missing_deps+=("${dep}")
            # DE dependencies might be installed later
            [[ "${validation_result}" -eq "${EXIT_SUCCESS}" ]] && validation_result="${EXIT_VALIDATION_ERROR}"
        fi
    done
    
    # Validate optional dependencies
    log_info "Validating optional dependencies..."
    for dep in "${!OPTIONAL_DEPS[@]}"; do
        ((total_deps++))
        if validate_optional_dependency "${dep}" "${OPTIONAL_DEPS[${dep}]}"; then
            ((valid_deps++))
        fi
        # Optional deps don't count as missing
    done
    
    # Generate validation report
    if ! generate_validation_report "${total_deps}" "${valid_deps}" "${missing_deps[@]}"; then
        log_warning "Failed to generate validation report"
    fi
    
    local validation_end
    validation_end=$(date +%s) || validation_end=0
    local validation_duration=$((validation_end - validation_start))
    
    log_info "Dependency validation completed in ${validation_duration}s"
    
    # Cache results
    cache_validation_results "${validation_result}" || log_warning "Failed to cache validation results"
    
    # Return success if no critical dependencies are missing
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        return "${EXIT_SUCCESS}"
    else
        return "${validation_result}"
    fi
}

# Validate individual system dependency
validate_system_dependency() {
    local dep="$1"
    local required_version="$2"
    
    if ! command -v "${dep}" &> /dev/null; then
        log_error "Missing system dependency: ${dep}"
        if ! echo "MISSING: ${dep}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_DEPENDENCY_ERROR}"
    fi
    
    local current_version
    case "${dep}" in
        "pacman")
            current_version=$(pacman --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') || current_version="unknown"
            ;;
        "git")
            current_version=$(git --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') || current_version="unknown"
            ;;
        "curl")
            current_version=$(curl --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') || current_version="unknown"
            ;;
        "bash")
            current_version=$(bash --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') || current_version="unknown"
            ;;
        "systemctl")
            current_version=$(systemctl --version 2>/dev/null | head -1 | grep -o '[0-9]\+') || current_version="unknown"
            ;;
        "sudo")
            current_version=$(sudo --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') || current_version="unknown"
            ;;
        *)
            current_version="unknown"
            ;;
    esac
    
    if [[ "${current_version}" == "unknown" ]]; then
        log_warning "Could not determine version for ${dep}"
        if ! echo "VERSION_UNKNOWN: ${dep}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_VALIDATION_ERROR}"
    fi
    
    if version_compare "${current_version}" "${required_version}"; then
        log_success "✅ ${dep} (${current_version} >= ${required_version})"
        if ! echo "VALID: ${dep} ${current_version}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_SUCCESS}"
    else
        log_error "❌ ${dep} version too old (${current_version} < ${required_version})"
        if ! echo "VERSION_OLD: ${dep} ${current_version} < ${required_version}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_VALIDATION_ERROR}"
    fi
}

# Validate Python dependency
validate_python_dependency() {
    local dep="$1"
    local required_version="$2"
    local current_version
    
    case "${dep}" in
        "python3")
            if ! command -v python3 &> /dev/null; then
                log_error "Missing Python 3"
                if ! echo "MISSING: ${dep}" >> "${VALIDATION_LOG}"; then
                    log_warning "Could not write to validation log"
                fi
                return "${EXIT_PYTHON_ERROR}"
            fi
            
            current_version=$(python3 --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') || {
                log_error "Failed to determine Python 3 version"
                current_version="unknown"
            }
            ;;
        "pip3")
            if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
                log_error "Missing pip3"
                if ! echo "MISSING: ${dep}" >> "${VALIDATION_LOG}"; then
                    log_warning "Could not write to validation log"
                fi
                return "${EXIT_PYTHON_ERROR}"
            fi
            
            current_version=$(python3 -m pip --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1) || {
                log_error "Failed to determine pip3 version"
                current_version="unknown"
            }
            ;;
        *)
            log_error "Unknown Python dependency: ${dep}"
            return "${EXIT_VALIDATION_ERROR}"
            ;;
    esac
    
    if [[ "${current_version}" == "unknown" ]]; then
        log_warning "Could not determine version for ${dep}"
        if ! echo "VERSION_UNKNOWN: ${dep}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_VALIDATION_ERROR}"
    fi
    
    if version_compare "${current_version}" "${required_version}"; then
        log_success "✅ ${dep} (${current_version} >= ${required_version})"
        if ! echo "VALID: ${dep} ${current_version}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_SUCCESS}"
    else
        log_error "❌ ${dep} version too old (${current_version} < ${required_version})"
        if ! echo "VERSION_OLD: ${dep} ${current_version} < ${required_version}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_VALIDATION_ERROR}"
    fi
}

# Validate desktop environment dependency
validate_de_dependency() {
    local dep="$1"
    local required_version="$2"
    
    case "${dep}" in
        "wayland")
            if [[ -z "${WAYLAND_DISPLAY}" ]] && [[ -z "${XDG_SESSION_TYPE}" || "${XDG_SESSION_TYPE}" != "wayland" ]]; then
                log_warn "⚠️  Not running on Wayland (current: ${XDG_SESSION_TYPE:-X11})"
                if ! echo "DE_MISSING: ${dep} (using ${XDG_SESSION_TYPE:-X11})" >> "${VALIDATION_LOG}"; then
                    log_warning "Could not write to validation log"
                fi
                return "${EXIT_VALIDATION_ERROR}"
            fi
            log_success "✅ Wayland session detected"
            if ! echo "VALID: ${dep}" >> "${VALIDATION_LOG}"; then
                log_warning "Could not write to validation log"
            fi
            return "${EXIT_SUCCESS}"
            ;;
        "hyprland")
            if command -v hyprctl &> /dev/null; then
                local current_version
                current_version=$(hyprctl version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/v//') || {
                    log_warning "Failed to determine Hyprland version"
                    current_version="unknown"
                }
                
                if [[ "${current_version}" == "unknown" ]]; then
                    log_warning "Could not determine version for ${dep}"
                    if ! echo "VERSION_UNKNOWN: ${dep}" >> "${VALIDATION_LOG}"; then
                        log_warning "Could not write to validation log"
                    fi
                    return "${EXIT_VALIDATION_ERROR}"
                fi
                
                if version_compare "${current_version}" "${required_version}"; then
                    log_success "✅ Hyprland (${current_version} >= ${required_version})"
                    if ! echo "VALID: ${dep} ${current_version}" >> "${VALIDATION_LOG}"; then
                        log_warning "Could not write to validation log"
                    fi
                    return "${EXIT_SUCCESS}"
                else
                    log_warn "⚠️  Hyprland version too old (${current_version} < ${required_version})"
                    if ! echo "VERSION_OLD: ${dep} ${current_version} < ${required_version}" >> "${VALIDATION_LOG}"; then
                        log_warning "Could not write to validation log"
                    fi
                    return "${EXIT_VALIDATION_ERROR}"
                fi
            else
                log_warn "⚠️  Hyprland not installed (will be installed)"
                if ! echo "MISSING: ${dep} (will be installed)" >> "${VALIDATION_LOG}"; then
                    log_warning "Could not write to validation log"
                fi
                return "${EXIT_VALIDATION_ERROR}"
            fi
            ;;
        *)
            log_error "Unknown desktop environment dependency: ${dep}"
            return "${EXIT_VALIDATION_ERROR}"
            ;;
    esac
    
    return "${EXIT_VALIDATION_ERROR}"
}

# Validate optional dependency
validate_optional_dependency() {
    local dep="$1"
    local required_version="$2"
    
    if ! command -v "${dep}" &> /dev/null; then
        log_info "ℹ️  Optional dependency not found: ${dep} (will enhance functionality if installed)"
        if ! echo "OPTIONAL_MISSING: ${dep}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_SUCCESS}"  # Not a failure for optional deps
    fi
    
    local current_version
    case "${dep}" in
        "flatpak")
            current_version=$(flatpak --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') || current_version="unknown"
            ;;
        "docker")
            current_version=$(docker --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') || current_version="unknown"
            ;;
        "yay"|"paru")
            current_version=$(${dep} --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1) || current_version="unknown"
            ;;
        *)
            current_version="unknown"
            ;;
    esac
    
    if [[ "${current_version}" == "unknown" ]]; then
        log_warning "Could not determine version for optional dependency: ${dep}"
        if ! echo "OPTIONAL_VERSION_UNKNOWN: ${dep}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_SUCCESS}"  # Not a failure for optional deps
    fi
    
    if version_compare "${current_version}" "${required_version}"; then
        log_success "✅ ${dep} (${current_version} >= ${required_version}) [OPTIONAL]"
        if ! echo "OPTIONAL_VALID: ${dep} ${current_version}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_SUCCESS}"
    else
        log_info "ℹ️  ${dep} version could be newer (${current_version} < ${required_version}) [OPTIONAL]"
        if ! echo "OPTIONAL_VERSION_OLD: ${dep} ${current_version} < ${required_version}" >> "${VALIDATION_LOG}"; then
            log_warning "Could not write to validation log"
        fi
        return "${EXIT_SUCCESS}"  # Not a failure for optional deps
    fi
}

# Compare versions (returns 0 if current >= required)
version_compare() {
    local current="$1"
    local required="$2"
    
    # Handle empty or unknown versions
    [[ -z "${current}" || "${current}" == "unknown" ]] && return 1
    [[ -z "${required}" ]] && return 0
    
    # Validate versions are in the expected format
    if ! [[ "${current}" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        log_warning "Invalid current version format: ${current}"
        return 1
    fi
    
    if ! [[ "${required}" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        log_warning "Invalid required version format: ${required}"
        return 1
    fi
    
    # Use sort -V for version comparison
    if printf '%s\n%s\n' "${required}" "${current}" | sort -V -C; then
        return 0
    else
        return 1
    fi
}

# Auto-fix missing dependencies
auto_fix_dependencies() {
    local missing_deps=("$@")
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        log_success "No missing dependencies to fix"
        return "${EXIT_SUCCESS}"
    fi
    
    log_info "Attempting to auto-fix ${#missing_deps[@]} missing dependencies..."
    
    local packages_to_install=()
    local python_packages=()
    local fix_success=true
    
    for dep in "${missing_deps[@]}"; do
        case "${dep}" in
            "git"|"curl"|"sudo")
                packages_to_install+=("${dep}")
                ;;
            "python3")
                packages_to_install+=("python")
                ;;
            "pip3")
                packages_to_install+=("python-pip")
                ;;
            "flatpak")
                packages_to_install+=("flatpak")
                ;;
            "systemctl")
                packages_to_install+=("systemd")
                ;;
            *)
                log_warning "No auto-fix strategy for dependency: ${dep}"
                # Don't consider this a failure
                ;;
        esac
    done
    
    # Install system packages
    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        log_info "Installing system packages: ${packages_to_install[*]}"
        
        if ! command -v pacman &>/dev/null; then
            log_error "Pacman package manager not found, cannot auto-fix dependencies"
            return "${EXIT_DEPENDENCY_ERROR}"
        fi
        
        if ! command -v sudo &>/dev/null; then
            log_error "sudo not found, cannot auto-fix dependencies requiring system privileges"
            return "${EXIT_PERMISSION_ERROR}"
        fi
        
        # Check if confirm_package_installation function exists (from functions.sh)
        if declare -f confirm_package_installation &>/dev/null; then
            if confirm_package_installation "${packages_to_install[@]}"; then
                local install_error=false
                for pkg in "${packages_to_install[@]}"; do
                    log_info "Installing ${pkg}..."
                    if ! sudo pacman -S --noconfirm "${pkg}"; then
                        log_error "Failed to install ${pkg}"
                        install_error=true
                        fix_success=false
                    else
                        log_success "Successfully installed ${pkg}"
                    fi
                done
                
                if [[ "${install_error}" == "true" ]]; then
                    log_warning "Some packages failed to install"
                fi
            else
                log_warning "User cancelled package installation"
                fix_success=false
            fi
        else
            log_warning "confirm_package_installation function not available"
            # Try to install without confirmation as a fallback
            for pkg in "${packages_to_install[@]}"; do
                log_info "Installing ${pkg}..."
                if ! sudo pacman -S --noconfirm "${pkg}"; then
                    log_error "Failed to install ${pkg}"
                    fix_success=false
                else
                    log_success "Successfully installed ${pkg}"
                fi
            done
        fi
    fi
    
    # Validate Python packages are available after system installation
    if [[ " ${missing_deps[*]} " =~ " python3 " ]] || [[ " ${missing_deps[*]} " =~ " pip3 " ]]; then
        if ! validate_python_environment; then
            log_error "Failed to validate Python environment"
            fix_success=false
        fi
    fi
    
    if [[ "${fix_success}" == "true" ]]; then
        log_success "Dependency auto-fix completed successfully"
        return "${EXIT_SUCCESS}"
    else
        log_warning "Dependency auto-fix completed with some issues"
        return "${EXIT_VALIDATION_ERROR}"
    fi
}

# Validate Python environment and packages
validate_python_environment() {
    log_info "Validating Python environment..."
    
    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not available after installation"
        return "${EXIT_PYTHON_ERROR}"
    fi
    
    # Check Python version
    local python_version
    python_version=$(python3 --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') || {
        log_error "Failed to determine Python version"
        return "${EXIT_PYTHON_ERROR}"
    }
    
    log_info "Python version: ${python_version}"
    
    # Check if pip is available
    if ! python3 -m pip --version &> /dev/null; then
        log_info "Installing pip via ensurepip..."
        if ! python3 -m ensurepip --upgrade; then
            log_error "Failed to install pip via ensurepip"
            return "${EXIT_PYTHON_ERROR}"
        fi
        
        # Verify pip installation was successful
        if ! python3 -m pip --version &> /dev/null; then
            log_error "pip installation failed"
            return "${EXIT_PYTHON_ERROR}"
        fi
    fi
    
    # Validate required Python packages for the project
    local python_requirements=(
        "PyYAML>=6.0"
        "requests>=2.28.0"
        "psutil>=5.9.0"
        "Pillow>=9.0.0"
    )
    
    local install_errors=false
    
    for req in "${python_requirements[@]}"; do
        local package
        package=$(echo "${req}" | cut -d'>' -f1) || {
            log_error "Failed to parse requirement: ${req}"
            continue
        }
        
        if ! python3 -c "import ${package}" &> /dev/null; then
            log_info "Installing Python package: ${req}"
            if ! python3 -m pip install --user "${req}"; then
                log_error "Failed to install Python package: ${req}"
                install_errors=true
            else
                # Verify installation was successful
                if ! python3 -c "import ${package}" &> /dev/null; then
                    log_error "Python package installation verification failed: ${package}"
                    install_errors=true
                else
                    log_success "Successfully installed Python package: ${package}"
                fi
            fi
        else
            log_success "Python package already installed: ${package}"
        fi
    done
    
    if [[ "${install_errors}" == "true" ]]; then
        log_warning "Python environment validation completed with some errors"
        return "${EXIT_PYTHON_ERROR}"
    else
        log_success "Python environment validated successfully"
        return "${EXIT_SUCCESS}"
    fi
}

# Generate comprehensive validation report
generate_validation_report() {
    local total_deps="$1"
    local valid_deps="$2"
    shift 2
    local missing_deps=("$@")
    
    # Avoid division by zero
    local success_rate=0
    if [[ ${total_deps} -gt 0 ]]; then
        success_rate=$((valid_deps * 100 / total_deps))
    fi
    
    local report_file="${VALIDATION_LOG%.log}_report.txt"
    
    {
        echo "=== HyprSupreme Dependency Validation Report ==="
        echo "Date: $(date)"
        echo "Total dependencies checked: ${total_deps}"
        echo "Valid dependencies: ${valid_deps}"
        echo "Missing dependencies: ${#missing_deps[@]}"
        echo "Success rate: ${success_rate}%"
        echo ""
        
        if [[ ${#missing_deps[@]} -gt 0 ]]; then
            echo "Missing dependencies:"
            for dep in "${missing_deps[@]}"; do
                echo "  - ${dep}"
            done
            echo ""
        fi
        
        echo "System Information:"
        if [[ -f "/etc/os-release" ]]; then
            echo "  OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Unknown")"
        else
            echo "  OS: Unknown (no /etc/os-release file)"
        fi
        echo "  Kernel: $(uname -r 2>/dev/null || echo "Unknown")"
        echo "  Architecture: $(uname -m 2>/dev/null || echo "Unknown")"
        echo "  Shell: ${SHELL:-Unknown}"
        echo "  Session: ${XDG_SESSION_TYPE:-Unknown}"
        echo "  Desktop: ${XDG_CURRENT_DESKTOP:-Unknown}"
        echo ""
        
        echo "Hardware Information:"
        if command -v lscpu &>/dev/null; then
            echo "  CPU: $(lscpu 2>/dev/null | grep 'Model name' | cut -d':' -f2 | xargs || echo "Unknown")"
        else
            echo "  CPU: Unknown (lscpu command not available)"
        fi
        
        if command -v nproc &>/dev/null; then
            echo "  Cores: $(nproc 2>/dev/null || echo "Unknown")"
        else
            echo "  Cores: Unknown (nproc command not available)"
        fi
        
        if command -v free &>/dev/null; then
            echo "  Memory: $(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo "Unknown")"
        else
            echo "  Memory: Unknown (free command not available)"
        fi
        
        # Only call get_gpu_info if the function exists (from functions.sh)
        if declare -f get_gpu_info &>/dev/null; then
            echo "  GPU: $(get_gpu_info 2>/dev/null || echo "Unknown")"
        else
            echo "  GPU: Unknown (get_gpu_info function not available)"
        fi
        echo ""
        
        echo "Package Manager Status:"
        if command -v pacman &>/dev/null; then
            echo "  Pacman version: $(pacman --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "Unknown")"
        else
            echo "  Pacman version: Not installed"
        fi
        echo "  AUR helper: ${AUR_HELPER:-None}"
        
        if command -v flatpak &>/dev/null; then
            echo "  Flatpak status: Available ($(flatpak --version 2>/dev/null || echo "version unknown"))"
        else
            echo "  Flatpak status: Not available"
        fi
        echo ""
        
        echo "==============================================" 
    } > "${report_file}" || {
        log_error "Failed to write validation report"
        return "${EXIT_PERMISSION_ERROR}"
    }
    
    # Also append to main log
    if ! cat "${report_file}" >> "${VALIDATION_LOG}"; then
        log_warning "Failed to append report to validation log"
    fi
    
    log_info "Validation report generated: ${report_file}"
    
    # Display summary
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        log_success "🎉 All critical dependencies validated successfully! (${success_rate}%)"
        return "${EXIT_SUCCESS}"
    elif [[ ${#missing_deps[@]} -le 3 ]]; then
        log_warn "⚠️  Some dependencies missing but auto-fixable (${success_rate}%)"
        return "${EXIT_VALIDATION_ERROR}"
    else
        log_error "❌ Multiple critical dependencies missing (${success_rate}%)"
        return "${EXIT_DEPENDENCY_ERROR}"
    fi
}

# Cache dependency validation results
cache_validation_results() {
    local result_code="$1"
    local timestamp
    local os_name
    local kernel_version
    local arch
    
    # Get timestamp in ISO 8601 format with error handling
    timestamp=$(date -Iseconds 2>/dev/null) || timestamp="$(date)"
    
    # Get OS information with error handling
    if [[ -f "/etc/os-release" ]]; then
        os_name=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2) || os_name="Unknown"
    else
        os_name="Unknown"
    fi
    
    # Get kernel version with error handling
    kernel_version=$(uname -r 2>/dev/null) || kernel_version="Unknown"
    
    # Get architecture with error handling
    arch=$(uname -m 2>/dev/null) || arch="Unknown"
    
    # Create the JSON cache file with error handling
    if ! cat > "${DEPENDENCY_CACHE}" << EOF; then
{
    "timestamp": "${timestamp}",
    "validation_result_code": "${result_code}",
    "validation_status": "$(
        case "${result_code}" in
            "${EXIT_SUCCESS}") echo "success" ;;
            "${EXIT_DEPENDENCY_ERROR}") echo "critical_dependencies_missing" ;;
            "${EXIT_PYTHON_ERROR}") echo "python_dependencies_missing" ;;
            "${EXIT_VALIDATION_ERROR}") echo "non_critical_issues" ;;
            *) echo "unknown" ;;
        esac
    )",
    "system": {
        "os": "${os_name}",
        "kernel": "${kernel_version}",
        "arch": "${arch}",
        "xdg_session": "${XDG_SESSION_TYPE:-Unknown}",
        "desktop": "${XDG_CURRENT_DESKTOP:-Unknown}"
    },
    "runtime_environment": {
        "shell": "${SHELL:-Unknown}",
        "shell_version": "$(${SHELL} --version 2>/dev/null | head -1 || echo "Unknown")",
        "python_version": "$(python3 --version 2>/dev/null || echo "Not available")",
        "pip_version": "$(python3 -m pip --version 2>/dev/null || echo "Not available")"
    },
    "last_validation_time": $(date +%s 2>/dev/null || echo 0)
}
EOF
        log_error "Failed to write to dependency cache file: ${DEPENDENCY_CACHE}"
        return "${EXIT_PERMISSION_ERROR}"
    fi
    
    log_info "Validation results cached successfully"
    return "${EXIT_SUCCESS}"
}

# Function to handle errors and exit appropriately
handle_error() {
    local error_code="$1"
    local error_message="$2"
    local error_source="${3:-unknown}"
    
    log_error "Error in ${error_source}: ${error_message} (code: ${error_code})"
    exit "${error_code}"
}

# Main dependency validation entry point
main() {
    local command="${1:-validate}"
    local exit_code="${EXIT_SUCCESS}"
    
    case "${command}" in
        "init")
            if ! init_dependency_validation; then
                exit_code="${EXIT_GENERAL_ERROR}"
            fi
            ;;
        "validate")
            if ! init_dependency_validation; then
                handle_error "${EXIT_GENERAL_ERROR}" "Failed to initialize dependency validation" "main"
            fi
            
            validate_all_dependencies
            exit_code=$?
            ;;
        "fix")
            shift
            if [[ $# -eq 0 ]]; then
                log_error "No dependencies specified for fixing"
                echo "Usage: $0 fix dependency1 [dependency2 ...]" >&2
                exit_code="${EXIT_GENERAL_ERROR}"
            else
                auto_fix_dependencies "$@"
                exit_code=$?
            fi
            ;;
        "python")
            validate_python_environment
            exit_code=$?
            ;;
        "report")
            if [[ $# -lt 3 ]]; then
                log_error "Insufficient arguments for report command"
                echo "Usage: $0 report total_deps valid_deps [missing_dep1 ...]" >&2
                exit_code="${EXIT_GENERAL_ERROR}"
            else
                generate_validation_report "$2" "$3" "${@:4}"
                exit_code=$?
            fi
            ;;
        "help"|"--help"|"-h")
            echo "HyprSupreme-Builder - Comprehensive Dependency Validator"
            echo ""
            echo "Usage: $0 COMMAND [ARGS]"
            echo ""
            echo "Commands:"
            echo "  init               Initialize the dependency validation system"
            echo "  validate           Validate all dependencies (default)"
            echo "  fix DEPS...        Auto-fix specified dependencies"
            echo "  python             Validate and fix Python environment"
            echo "  report TOTAL VALID [MISSING...]"
            echo "                     Generate a validation report with the given stats"
            echo "  help               Show this help message"
            echo ""
            echo "Exit Codes:"
            echo "  ${EXIT_SUCCESS}    Success"
            echo "  ${EXIT_GENERAL_ERROR}    General error"
            echo "  ${EXIT_DEPENDENCY_ERROR}    Critical dependency error"
            echo "  ${EXIT_PERMISSION_ERROR}    Permission error"
            echo "  ${EXIT_VALIDATION_ERROR}    Validation error (non-critical)"
            echo "  ${EXIT_PYTHON_ERROR}    Python environment error"
            echo "  ${EXIT_CONFIG_ERROR}    Configuration error"
            ;;
        *)
            log_error "Unknown command: ${command}"
            echo "Usage: $0 {init|validate|fix|python|report|help}" >&2
            exit_code="${EXIT_GENERAL_ERROR}"
            ;;
    esac
    
    exit "${exit_code}"
}

# Execute main function
main "$@"

