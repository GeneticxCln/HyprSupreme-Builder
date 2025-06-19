#!/bin/bash
# HyprSupreme-Builder System Validation Script
# Comprehensive error checking and issue detection

# Note: We don't use 'set -e' here because we want to handle errors gracefully
set -uo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

readonly ERROR="${RED}✗${NC}"
readonly SUCCESS="${GREEN}✓${NC}"
readonly INFO="${BLUE}ℹ${NC}"
readonly WARNING="${YELLOW}⚠${NC}"
readonly FIX="${PURPLE}🔧${NC}"

# Counters for issues
CRITICAL_ISSUES=0
WARNING_ISSUES=0
INFO_ISSUES=0
FIXED_ISSUES=0

# Report arrays
CRITICAL_REPORTS=()
WARNING_REPORTS=()
INFO_REPORTS=()
FIXED_REPORTS=()

# Logging
LOG_FILE="logs/system_check-$(date +%Y%m%d-%H%M%S).log"
mkdir -p logs

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

report_critical() {
    echo -e "${ERROR} $1"
    CRITICAL_REPORTS+=("$1")
    ((CRITICAL_ISSUES++))
    log "CRITICAL: $1"
}

report_warning() {
    echo -e "${WARNING} $1"
    WARNING_REPORTS+=("$1")
    ((WARNING_ISSUES++))
    log "WARNING: $1"
}

report_info() {
    echo -e "${INFO} $1"
    INFO_REPORTS+=("$1")
    ((INFO_ISSUES++))
    log "INFO: $1"
}

report_success() {
    echo -e "${SUCCESS} $1"
    log "SUCCESS: $1"
}

report_fix() {
    echo -e "${FIX} $1"
    FIXED_REPORTS+=("$1")
    ((FIXED_ISSUES++))
    log "FIXED: $1"
}

print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║         🔍 HYPRSUPREME SYSTEM VALIDATION TOOL 🔍            ║"
    echo "║                                                              ║"
    echo "║              Comprehensive Error Detection                   ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 1. Dependency Checks
check_dependencies() {
    echo -e "${CYAN}=== Dependency Checks ===${NC}"
    
    local critical_deps=("sudo" "pacman" "git" "curl" "wget" "bash" "systemctl")
    local optional_deps=("yay" "paru" "whiptail" "dialog" "python3" "jq")
    
    # Critical dependencies
    for dep in "${critical_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            report_success "Critical dependency found: $dep"
        else
            report_critical "Missing critical dependency: $dep"
        fi
    done
    
    # Optional dependencies
    for dep in "${optional_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            report_success "Optional dependency found: $dep"
        else
            report_warning "Missing optional dependency: $dep"
        fi
    done
    
    # Check sudo privileges
    if sudo -n true 2>/dev/null; then
        report_success "Sudo privileges available without password"
    elif sudo -v 2>/dev/null; then
        report_success "Sudo privileges available"
    else
        report_critical "No sudo privileges available"
    fi
}

# 2. File System Checks
check_filesystem() {
    echo -e "${CYAN}=== File System Checks ===${NC}"
    
    # Check disk space
    local available_space=$(df . | awk 'NR==2 {print $4}')
    local required_space=2097152  # 2GB in KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        report_critical "Insufficient disk space. Required: 2GB, Available: $((available_space/1024))MB"
    else
        report_success "Sufficient disk space available: $((available_space/1024))MB"
    fi
    
    # Check file permissions
    local script_files=(
        "./install.sh"
        "./hyprsupreme"
        "./tools/gpu_switcher.sh"
        "./tools/gpu_presets.sh"
        "./tools/gpu_scheduler.sh"
    )
    
    for file in "${script_files[@]}"; do
        if [[ -f "$file" ]]; then
            if [[ -x "$file" ]]; then
                report_success "Script is executable: $file"
            else
                report_warning "Script not executable: $file"
                if chmod +x "$file" 2>/dev/null; then
                    report_fix "Made script executable: $file"
                else
                    report_critical "Cannot make script executable: $file"
                fi
            fi
        else
            report_critical "Missing script file: $file"
        fi
    done
    
    # Check directory structure
    local required_dirs=(
        "./modules/core"
        "./modules/themes"
        "./modules/widgets"
        "./modules/scripts"
        "./tools"
        "./logs"
        "./sources"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            report_success "Required directory exists: $dir"
        else
            report_warning "Missing directory: $dir"
            if mkdir -p "$dir" 2>/dev/null; then
                report_fix "Created missing directory: $dir"
            else
                report_critical "Cannot create directory: $dir"
            fi
        fi
    done
}

# 3. Network Connectivity
check_network() {
    echo -e "${CYAN}=== Network Connectivity ===${NC}"
    
    # Check internet connectivity
    local test_sites=("archlinux.org" "github.com" "8.8.8.8")
    local connected=false
    
    for site in "${test_sites[@]}"; do
        if ping -c 1 -W 5 "$site" &> /dev/null; then
            report_success "Network connectivity verified: $site"
            connected=true
            break
        fi
    done
    
    if [ "$connected" = false ]; then
        report_critical "No internet connectivity detected"
    fi
    
    # Check DNS resolution
    if nslookup archlinux.org &> /dev/null; then
        report_success "DNS resolution working"
    else
        report_warning "DNS resolution issues detected"
    fi
}

# 4. Script Validation
check_scripts() {
    echo -e "${CYAN}=== Script Validation ===${NC}"
    
    # Check shell scripts for common issues
    find . -name "*.sh" -type f | while read -r script; do
        # Skip if not a regular file
        [[ -f "$script" ]] || continue
        
        # Check shebang
        if head -n1 "$script" | grep -q "^#!/bin/bash"; then
            report_success "Valid shebang: $script"
        else
            report_warning "Missing or invalid shebang: $script"
        fi
        
        # Check for set -e or error handling
        if grep -q "set -e\|error_exit\|trap" "$script"; then
            report_success "Error handling present: $script"
        else
            report_warning "No error handling detected: $script"
        fi
        
        # Check for unquoted variables (basic check)
        if grep -q '\$[A-Za-z_][A-Za-z0-9_]*[^"]' "$script"; then
            report_info "Potential unquoted variables in: $script"
        fi
        
        # Check syntax
        if bash -n "$script" 2>/dev/null; then
            report_success "Valid syntax: $script"
        else
            report_critical "Syntax errors in: $script"
        fi
    done
}

# 5. GPU System Validation
check_gpu_system() {
    echo -e "${CYAN}=== GPU System Validation ===${NC}"
    
    # Check GPU detection
    if lspci | grep -E "VGA|3D|Display" &> /dev/null; then
        local gpu_count=$(lspci | grep -E "VGA|3D|Display" | wc -l)
        report_success "GPU(s) detected: $gpu_count"
        
        # Run GPU switcher detection
        if [[ -x "./tools/gpu_switcher.sh" ]]; then
            if ./tools/gpu_switcher.sh detect &> /dev/null; then
                report_success "GPU switcher detection working"
            else
                report_warning "GPU switcher detection failed"
            fi
        else
            report_warning "GPU switcher not executable or missing"
        fi
    else
        report_warning "No GPU detected via lspci"
    fi
    
    # Check for NVIDIA-specific tools
    if command -v nvidia-smi &> /dev/null; then
        if nvidia-smi &> /dev/null; then
            report_success "NVIDIA tools working"
        else
            report_warning "NVIDIA tools installed but not working"
        fi
    fi
    
    # Check Wayland/Hyprland compatibility
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        report_success "Running on Wayland"
    elif [[ -n "$WAYLAND_DISPLAY" ]]; then
        report_success "Wayland display available"
    else
        report_info "Not currently running Wayland (this is fine for installation)"
    fi
}

# 6. Configuration Validation
check_configurations() {
    echo -e "${CYAN}=== Configuration Validation ===${NC}"
    
    # Check JSON files for syntax
    find . -name "*.json" -type f | while read -r json_file; do
        if jq empty "$json_file" 2>/dev/null; then
            report_success "Valid JSON: $json_file"
        else
            report_critical "Invalid JSON syntax: $json_file"
        fi
    done
    
    # Check important config files exist
    local config_files=(
        "./pyproject.toml"
        "./requirements.txt"
        "./.gitignore"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            report_success "Config file exists: $file"
        else
            report_warning "Missing config file: $file"
        fi
    done
}

# 7. Security Checks
check_security() {
    echo -e "${CYAN}=== Security Checks ===${NC}"
    
    # Check for files with suspicious permissions
    find . -type f -perm /o+w | while read -r writable_file; do
        report_warning "World-writable file: $writable_file"
    done
    
    # Check for potential security issues in scripts
    grep -r "eval\|exec.*\$\|system.*\$" --include="*.sh" . | while read -r line; do
        report_info "Potential security concern: $line"
    done
    
    # Check for hardcoded credentials (basic check)
    grep -ri "password\|secret\|token" --include="*.sh" --include="*.py" . | grep -v "example\|placeholder\|template" | while read -r line; do
        report_info "Potential credential in code: $line"
    done
}

# 8. Performance Checks
check_performance() {
    echo -e "${CYAN}=== Performance Checks ===${NC}"
    
    # Check system resources
    local ram_mb=$(free -m | awk 'NR==2{print $2}')
    if [ "$ram_mb" -lt 2048 ]; then
        report_warning "Low RAM: ${ram_mb}MB (recommended: 2GB+)"
    else
        report_success "Sufficient RAM: ${ram_mb}MB"
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        report_warning "Single CPU core detected (may affect performance)"
    else
        report_success "Multiple CPU cores: $cpu_cores"
    fi
    
    # Check for SSD vs HDD (basic check)
    if lsblk -d -o name,rota | grep -q "0"; then
        report_success "SSD detected (better performance)"
    else
        report_info "HDD detected (SSD recommended for better performance)"
    fi
}

# 9. Package System Checks
check_package_system() {
    echo -e "${CYAN}=== Package System Checks ===${NC}"
    
    # Check pacman
    if sudo pacman -Sy --noconfirm >/dev/null 2>&1; then
        report_success "Package database updated successfully"
    else
        report_warning "Failed to update package database"
    fi
    
    # Check for failed services
    local failed_services=$(systemctl --failed --no-legend | wc -l)
    if [ "$failed_services" -eq 0 ]; then
        report_success "No failed systemd services"
    else
        report_warning "$failed_services failed systemd services detected"
    fi
    
    # Check for broken packages
    if pacman -Qk 2>/dev/null | grep -q "MISSING"; then
        report_warning "Some packages have missing files"
    else
        report_success "Package integrity check passed"
    fi
}

# 10. Module Validation
check_modules() {
    echo -e "${CYAN}=== Module Validation ===${NC}"
    
    # Check that all required modules exist
    local required_modules=(
        "./modules/core/install_hyprland.sh"
        "./modules/core/install_waybar.sh"
        "./modules/core/install_rofi.sh"
        "./modules/core/install_kitty.sh"
        "./modules/core/apply_config.sh"
        "./modules/common/functions.sh"
    )
    
    for module in "${required_modules[@]}"; do
        if [[ -f "$module" ]]; then
            if [[ -x "$module" ]]; then
                report_success "Module ready: $module"
            else
                report_warning "Module not executable: $module"
            fi
        else
            report_critical "Missing required module: $module"
        fi
    done
}

# Auto-fix function
auto_fix_issues() {
    echo -e "${CYAN}=== Auto-Fix Attempt ===${NC}"
    
    # Fix script permissions
    find . -name "*.sh" -type f ! -executable -exec chmod +x {} \; 2>/dev/null && \
        report_fix "Fixed script permissions"
    
    # Create missing directories
    mkdir -p logs sources modules/{core,themes,widgets,scripts} tools 2>/dev/null && \
        report_fix "Created missing directories"
    
    # Update package database
    if sudo pacman -Sy --noconfirm &> /dev/null; then
        report_fix "Updated package database"
    fi
}

# Generate report
generate_report() {
    echo
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                        VALIDATION REPORT                    ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${RED}Critical Issues: $CRITICAL_ISSUES${NC}"
    for issue in "${CRITICAL_REPORTS[@]}"; do
        echo -e "  ${ERROR} $issue"
    done
    echo
    
    echo -e "${YELLOW}Warnings: $WARNING_ISSUES${NC}"
    for issue in "${WARNING_REPORTS[@]}"; do
        echo -e "  ${WARNING} $issue"
    done
    echo
    
    echo -e "${BLUE}Information: $INFO_ISSUES${NC}"
    for issue in "${INFO_REPORTS[@]}"; do
        echo -e "  ${INFO} $issue"
    done
    echo
    
    echo -e "${PURPLE}Auto-Fixed: $FIXED_ISSUES${NC}"
    for issue in "${FIXED_REPORTS[@]}"; do
        echo -e "  ${FIX} $issue"
    done
    echo
    
    # Overall status
    if [ "$CRITICAL_ISSUES" -eq 0 ]; then
        if [ "$WARNING_ISSUES" -eq 0 ]; then
            echo -e "${GREEN}🎉 System validation passed! Ready for installation.${NC}"
            exit 0
        else
            echo -e "${YELLOW}⚠️  System validation passed with warnings. Installation should work but may have issues.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ System validation failed! Critical issues must be resolved before installation.${NC}"
        exit 2
    fi
}

# Main execution
main() {
    print_banner
    
    echo -e "${INFO} Starting comprehensive system validation..."
    echo -e "${INFO} Log file: $LOG_FILE"
    echo
    
    check_dependencies
    check_filesystem
    check_network
    check_scripts
    check_gpu_system
    check_configurations
    check_security
    check_performance
    check_package_system
    check_modules
    
    # Auto-fix if requested
    if [[ "${1:-}" == "--fix" ]]; then
        auto_fix_issues
    fi
    
    generate_report
}

# Show help
show_help() {
    echo "HyprSupreme System Validation Tool"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --fix     Attempt to automatically fix common issues"
    echo "  --help    Show this help message"
    echo
    echo "Exit codes:"
    echo "  0    All checks passed"
    echo "  1    Warnings found (installation should work)"
    echo "  2    Critical issues found (installation will likely fail)"
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac

