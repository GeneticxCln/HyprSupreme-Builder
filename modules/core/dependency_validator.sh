#!/bin/bash
# HyprSupreme-Builder - Comprehensive Dependency Validator

source "$(dirname "$0")/../common/functions.sh"

# Dependency validation configuration
VALIDATION_LOG="$HOME/.cache/hyprsupreme/validation.log"
DEPENDENCY_CACHE="$HOME/.cache/hyprsupreme/dependencies.json"

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
    
    mkdir -p "$(dirname "$VALIDATION_LOG")"
    mkdir -p "$(dirname "$DEPENDENCY_CACHE")"
    
    echo "# HyprSupreme Dependency Validation Log - $(date)" > "$VALIDATION_LOG"
    
    log_success "Dependency validation initialized"
}

# Check all system dependencies
validate_all_dependencies() {
    log_info "Running comprehensive dependency validation..."
    
    local validation_start=$(date +%s)
    local total_deps=0
    local valid_deps=0
    local missing_deps=()
    local version_issues=()
    
    # Validate system dependencies
    log_info "Validating system dependencies..."
    for dep in "${!SYSTEM_DEPS[@]}"; do
        ((total_deps++))
        if validate_system_dependency "$dep" "${SYSTEM_DEPS[$dep]}"; then
            ((valid_deps++))
        else
            missing_deps+=("$dep")
        fi
    done
    
    # Validate Python dependencies
    log_info "Validating Python dependencies..."
    for dep in "${!PYTHON_DEPS[@]}"; do
        ((total_deps++))
        if validate_python_dependency "$dep" "${PYTHON_DEPS[$dep]}"; then
            ((valid_deps++))
        else
            missing_deps+=("$dep")
        fi
    done
    
    # Validate desktop environment dependencies
    log_info "Validating desktop environment dependencies..."
    for dep in "${!DE_DEPS[@]}"; do
        ((total_deps++))
        if validate_de_dependency "$dep" "${DE_DEPS[$dep]}"; then
            ((valid_deps++))
        else
            missing_deps+=("$dep")
        fi
    done
    
    # Validate optional dependencies
    log_info "Validating optional dependencies..."
    for dep in "${!OPTIONAL_DEPS[@]}"; do
        ((total_deps++))
        if validate_optional_dependency "$dep" "${OPTIONAL_DEPS[$dep]}"; then
            ((valid_deps++))
        fi
        # Optional deps don't count as missing
    done
    
    # Generate validation report
    generate_validation_report "$total_deps" "$valid_deps" "${missing_deps[@]}"
    
    local validation_end=$(date +%s)
    local validation_duration=$((validation_end - validation_start))
    
    log_info "Dependency validation completed in ${validation_duration}s"
    
    # Return success if no critical dependencies are missing
    [[ ${#missing_deps[@]} -eq 0 ]]
}

# Validate individual system dependency
validate_system_dependency() {
    local dep="$1"
    local required_version="$2"
    
    if ! command -v "$dep" &> /dev/null; then
        log_error "Missing system dependency: $dep"
        echo "MISSING: $dep" >> "$VALIDATION_LOG"
        return 1
    fi
    
    local current_version
    case "$dep" in
        "pacman")
            current_version=$(pacman --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
            ;;
        "git")
            current_version=$(git --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
            ;;
        "curl")
            current_version=$(curl --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
            ;;
        "bash")
            current_version=$(bash --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
            ;;
        "systemctl")
            current_version=$(systemctl --version | head -1 | grep -o '[0-9]\+')
            ;;
        "sudo")
            current_version=$(sudo --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
            ;;
        *)
            current_version="unknown"
            ;;
    esac
    
    if version_compare "$current_version" "$required_version"; then
        log_success "✅ $dep ($current_version >= $required_version)"
        echo "VALID: $dep $current_version" >> "$VALIDATION_LOG"
        return 0
    else
        log_error "❌ $dep version too old ($current_version < $required_version)"
        echo "VERSION_OLD: $dep $current_version < $required_version" >> "$VALIDATION_LOG"
        return 1
    fi
}

# Validate Python dependency
validate_python_dependency() {
    local dep="$1"
    local required_version="$2"
    
    case "$dep" in
        "python3")
            if ! command -v python3 &> /dev/null; then
                log_error "Missing Python 3"
                return 1
            fi
            local current_version=$(python3 --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
            ;;
        "pip3")
            if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
                log_error "Missing pip3"
                return 1
            fi
            local current_version=$(python3 -m pip --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            ;;
    esac
    
    if version_compare "$current_version" "$required_version"; then
        log_success "✅ $dep ($current_version >= $required_version)"
        return 0
    else
        log_error "❌ $dep version too old ($current_version < $required_version)"
        return 1
    fi
}

# Validate desktop environment dependency
validate_de_dependency() {
    local dep="$1"
    local required_version="$2"
    
    case "$dep" in
        "wayland")
            if [[ -z "$WAYLAND_DISPLAY" ]] && [[ -z "$XDG_SESSION_TYPE" || "$XDG_SESSION_TYPE" != "wayland" ]]; then
                log_warn "⚠️  Not running on Wayland (current: ${XDG_SESSION_TYPE:-X11})"
                return 1
            fi
            log_success "✅ Wayland session detected"
            return 0
            ;;
        "hyprland")
            if command -v hyprctl &> /dev/null; then
                local current_version=$(hyprctl version | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/v//')
                if version_compare "$current_version" "$required_version"; then
                    log_success "✅ Hyprland ($current_version >= $required_version)"
                    return 0
                else
                    log_warn "⚠️  Hyprland version too old ($current_version < $required_version)"
                    return 1
                fi
            else
                log_warn "⚠️  Hyprland not installed (will be installed)"
                return 1
            fi
            ;;
    esac
    
    return 1
}

# Validate optional dependency
validate_optional_dependency() {
    local dep="$1"
    local required_version="$2"
    
    if ! command -v "$dep" &> /dev/null; then
        log_info "ℹ️  Optional dependency not found: $dep (will enhance functionality if installed)"
        return 1
    fi
    
    local current_version
    case "$dep" in
        "flatpak")
            current_version=$(flatpak --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
            ;;
        "docker")
            current_version=$(docker --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
            ;;
        "yay"|"paru")
            current_version=$(${dep} --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            ;;
        *)
            current_version="unknown"
            ;;
    esac
    
    if version_compare "$current_version" "$required_version"; then
        log_success "✅ $dep ($current_version >= $required_version) [OPTIONAL]"
        return 0
    else
        log_info "ℹ️  $dep version could be newer ($current_version < $required_version) [OPTIONAL]"
        return 1
    fi
}

# Compare versions (returns 0 if current >= required)
version_compare() {
    local current="$1"
    local required="$2"
    
    # Handle empty or unknown versions
    [[ -z "$current" || "$current" == "unknown" ]] && return 1
    [[ -z "$required" ]] && return 0
    
    # Use sort -V for version comparison
    if printf '%s\n%s\n' "$required" "$current" | sort -V -C; then
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
        return 0
    fi
    
    log_info "Attempting to auto-fix ${#missing_deps[@]} missing dependencies..."
    
    local packages_to_install=()
    local python_packages=()
    
    for dep in "${missing_deps[@]}"; do
        case "$dep" in
            "git"|"curl"|"sudo")
                packages_to_install+=("$dep")
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
        esac
    done
    
    # Install system packages
    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        log_info "Installing system packages: ${packages_to_install[*]}"
        if confirm_package_installation "${packages_to_install[@]}"; then
            for pkg in "${packages_to_install[@]}"; do
                if ! sudo pacman -S --noconfirm "$pkg"; then
                    log_error "Failed to install $pkg"
                    return 1
                fi
            done
        fi
    fi
    
    # Validate Python packages are available after system installation
    if [[ " ${missing_deps[*]} " =~ " python3 " ]] || [[ " ${missing_deps[*]} " =~ " pip3 " ]]; then
        validate_python_environment
    fi
    
    log_success "Dependency auto-fix completed"
}

# Validate Python environment and packages
validate_python_environment() {
    log_info "Validating Python environment..."
    
    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not available after installation"
        return 1
    fi
    
    # Check if pip is available
    if ! python3 -m pip --version &> /dev/null; then
        log_info "Installing pip via ensurepip..."
        python3 -m ensurepip --upgrade
    fi
    
    # Validate required Python packages for the project
    local python_requirements=(
        "PyYAML>=6.0"
        "requests>=2.28.0"
        "psutil>=5.9.0"
        "Pillow>=9.0.0"
    )
    
    for req in "${python_requirements[@]}"; do
        local package=$(echo "$req" | cut -d'>' -f1)
        if ! python3 -c "import $package" &> /dev/null; then
            log_info "Installing Python package: $req"
            python3 -m pip install --user "$req"
        fi
    done
    
    log_success "Python environment validated"
}

# Generate comprehensive validation report
generate_validation_report() {
    local total_deps="$1"
    local valid_deps="$2"
    shift 2
    local missing_deps=("$@")
    
    local success_rate=$((valid_deps * 100 / total_deps))
    
    {
        echo "=== HyprSupreme Dependency Validation Report ==="
        echo "Date: $(date)"
        echo "Total dependencies checked: $total_deps"
        echo "Valid dependencies: $valid_deps"
        echo "Missing dependencies: ${#missing_deps[@]}"
        echo "Success rate: ${success_rate}%"
        echo ""
        
        if [[ ${#missing_deps[@]} -gt 0 ]]; then
            echo "Missing dependencies:"
            for dep in "${missing_deps[@]}"; do
                echo "  - $dep"
            done
            echo ""
        fi
        
        echo "System Information:"
        echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "  Kernel: $(uname -r)"
        echo "  Architecture: $(uname -m)"
        echo "  Shell: $SHELL"
        echo "  Session: ${XDG_SESSION_TYPE:-unknown}"
        echo "  Desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
        echo ""
        
        echo "Hardware Information:"
        echo "  CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
        echo "  Cores: $(nproc)"
        echo "  Memory: $(free -h | grep Mem | awk '{print $2}')"
        echo "  GPU: $(get_gpu_info)"
        echo ""
        
        echo "Package Manager Status:"
        echo "  Pacman version: $(pacman --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')"
        echo "  AUR helper: ${AUR_HELPER:-none}"
        echo "  Flatpak status: $(command -v flatpak &> /dev/null && echo "available" || echo "not available")"
        echo ""
        
        echo "==============================================" 
    } > "${VALIDATION_LOG%.log}_report.txt"
    
    # Also append to main log
    cat "${VALIDATION_LOG%.log}_report.txt" >> "$VALIDATION_LOG"
    
    log_info "Validation report generated: ${VALIDATION_LOG%.log}_report.txt"
    
    # Display summary
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        log_success "🎉 All critical dependencies validated successfully! (${success_rate}%)"
    elif [[ ${#missing_deps[@]} -le 3 ]]; then
        log_warn "⚠️  Some dependencies missing but auto-fixable (${success_rate}%)"
    else
        log_error "❌ Multiple critical dependencies missing (${success_rate}%)"
    fi
}

# Cache dependency validation results
cache_validation_results() {
    local results="$1"
    
    cat > "$DEPENDENCY_CACHE" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "validation_results": "$results",
    "system": {
        "os": "$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)",
        "kernel": "$(uname -r)",
        "arch": "$(uname -m)"
    }
}
EOF
    
    log_info "Validation results cached"
}

# Main dependency validation entry point
case "${1:-validate}" in
    "init")
        init_dependency_validation
        ;;
    "validate")
        init_dependency_validation
        validate_all_dependencies
        ;;
    "fix")
        shift
        auto_fix_dependencies "$@"
        ;;
    "python")
        validate_python_environment
        ;;
    "report")
        generate_validation_report "$2" "$3" "${@:4}"
        ;;
    *)
        echo "Usage: $0 {init|validate|fix|python|report}"
        exit 1
        ;;
esac

