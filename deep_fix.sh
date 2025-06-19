#!/bin/bash
# HyprSupreme Deep Fix Script
# Comprehensive error detection and fixing for the entire build

set -euo pipefail

# Colors
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 3)[WARN]$(tput sgr0)"
FIX="$(tput setaf 6)[FIX]$(tput sgr0)"
RESET="$(tput sgr0)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="logs/deep_fix-$(date +%Y%m%d-%H%M%S).log"

# Create logs directory
mkdir -p logs

echo "═══════════════════════════════════════════════════════════════"
echo "              🔧 HYPRSUPREME DEEP FIX TOOL 🔧"
echo "═══════════════════════════════════════════════════════════════"
echo | tee -a "$LOG_FILE"

log_action() {
    echo "$1" | tee -a "$LOG_FILE"
}

# 1. Fix Python Dependencies
fix_python_dependencies() {
    log_action "${INFO} Fixing Python dependencies..."
    
    # Install system-level packages if missing
    local missing_packages=()
    
    if ! python3 -c "import yaml" 2>/dev/null; then
        missing_packages+=("python-yaml")
    fi
    
    if ! python3 -c "import gi; gi.require_version('Gtk', '4.0')" 2>/dev/null; then
        missing_packages+=("python-gobject" "gtk4")
    fi
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_action "${FIX} Installing missing Python packages: ${missing_packages[*]}"
        sudo pacman -S --noconfirm "${missing_packages[@]}" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Set up virtual environment with all dependencies
    if [ ! -d "$SCRIPT_DIR/venv" ]; then
        log_action "${FIX} Creating virtual environment..."
        python3 -m venv "$SCRIPT_DIR/venv"
    fi
    
    source "$SCRIPT_DIR/venv/bin/activate"
    pip install --upgrade pip
    pip install -r requirements.txt 2>&1 | tee -a "$LOG_FILE"
    deactivate
    
    log_action "${OK} Python dependencies fixed"
}

# 2. Add Error Handling to Scripts Missing It
fix_error_handling() {
    log_action "${INFO} Adding error handling to scripts..."
    
    # Scripts that need error handling based on the system check
    local scripts_needing_fixes=(
        "community/launch_web.sh"
        "demo_resolutions.sh"
        "launch_web.sh"
        "modules/core/apply_config.sh"
        "modules/core/apply_feature.sh"
        "modules/core/install_fonts.sh"
        "modules/core/install_kitty.sh"
        "modules/core/install_nvidia.sh"
        "modules/core/install_sddm.sh"
        "modules/scripts/install_scripts.sh"
        "modules/themes/install_themes.sh"
        "modules/themes/install_wallpapers.sh"
        "modules/themes/theme_engine.sh"
        "modules/widgets/install_ags.sh"
        "start_community.sh"
        "test_community_connectivity.sh"
        "test_keybindings.sh"
        "tools/flatpak_manager.sh"
        "tools/resolution_manager.sh"
        "tools/sddm_resolution_checker.sh"
        "venv_runner.sh"
        "verify_community_setup.sh"
    )
    
    for script in "${scripts_needing_fixes[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            # Check if it already has error handling
            if ! grep -q "set -" "$SCRIPT_DIR/$script"; then
                log_action "${FIX} Adding error handling to $script"
                
                # Create a backup
                cp "$SCRIPT_DIR/$script" "$SCRIPT_DIR/$script.backup"
                
                # Add error handling after shebang
                sed -i '2i\\n# Error handling\nset -euo pipefail\n' "$SCRIPT_DIR/$script"
            fi
        fi
    done
    
    log_action "${OK} Error handling added to scripts"
}

# 3. Fix File Permissions
fix_file_permissions() {
    log_action "${INFO} Fixing file permissions..."
    
    # Make all .sh files executable
    find "$SCRIPT_DIR" -name "*.sh" -type f ! -executable -exec chmod +x {} \; 2>/dev/null
    
    # Make main executable
    chmod +x "$SCRIPT_DIR/hyprsupreme"
    
    # Make Python scripts executable
    find "$SCRIPT_DIR" -name "*.py" -type f ! -executable -exec chmod +x {} \; 2>/dev/null
    
    log_action "${OK} File permissions fixed"
}

# 4. Validate and Fix Configuration Files
fix_configuration_files() {
    log_action "${INFO} Validating configuration files..."
    
    # Check pyproject.toml syntax
    if [ -f "$SCRIPT_DIR/pyproject.toml" ]; then
        if ! python3 -c "import tomllib; tomllib.load(open('pyproject.toml', 'rb'))" 2>/dev/null; then
            log_action "${WARN} pyproject.toml has syntax issues"
            # You might want to fix specific issues here
        else
            log_action "${OK} pyproject.toml is valid"
        fi
    fi
    
    # Validate requirements.txt
    if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
        # Remove any problematic lines
        grep -v "^#" "$SCRIPT_DIR/requirements.txt" | grep -v "^$" > "$SCRIPT_DIR/requirements.txt.tmp"
        mv "$SCRIPT_DIR/requirements.txt.tmp" "$SCRIPT_DIR/requirements.txt"
        log_action "${OK} requirements.txt cleaned"
    fi
}

# 5. Fix Module Dependencies
fix_module_dependencies() {
    log_action "${INFO} Checking module dependencies..."
    
    # Ensure all common functions are properly sourced
    local modules_dir="$SCRIPT_DIR/modules"
    
    for module in "$modules_dir"/*/; do
        if [ -d "$module" ]; then
            for script in "$module"/*.sh; do
                if [ -f "$script" ]; then
                    # Check if it sources common functions when needed
                    if grep -q "log_" "$script" && ! grep -q "source.*functions.sh" "$script"; then
                        log_action "${FIX} Adding functions.sh source to $(basename "$script")"
                        sed -i '/^#!/a\\n# Source common functions\nSOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"\nsource "$SOURCE_DIR/common/functions.sh"' "$script"
                    fi
                fi
            done
        fi
    done
    
    log_action "${OK} Module dependencies checked"
}

# 6. Fix GPU Switcher Scripts
fix_gpu_scripts() {
    log_action "${INFO} Validating GPU switcher scripts..."
    
    local gpu_scripts=(
        "tools/gpu_switcher.sh"
        "tools/gpu_presets.sh"
        "tools/gpu_scheduler.sh"
    )
    
    for script in "${gpu_scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            # Check for syntax errors
            if ! bash -n "$SCRIPT_DIR/$script"; then
                log_action "${ERROR} Syntax error in $script"
            else
                log_action "${OK} $script syntax is valid"
            fi
            
            # Ensure script is executable
            chmod +x "$SCRIPT_DIR/$script"
        fi
    done
}

# 7. Fix Python Script Issues
fix_python_scripts() {
    log_action "${INFO} Validating Python scripts..."
    
    local python_scripts=(
        "gui/hyprsupreme-gui.py"
        "tools/hyprsupreme-cloud.py"
        "tools/hyprsupreme-community.py"
        "tools/hyprsupreme-migrate.py"
        "tools/ai_assistant.py"
    )
    
    for script in "${python_scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            # Check syntax
            if ! python3 -m py_compile "$SCRIPT_DIR/$script"; then
                log_action "${ERROR} Syntax error in $script"
            else
                log_action "${OK} $script syntax is valid"
            fi
            
            # Make executable
            chmod +x "$SCRIPT_DIR/$script"
        fi
    done
}

# 8. Fix Missing Directories
fix_directory_structure() {
    log_action "${INFO} Ensuring proper directory structure..."
    
    local required_dirs=(
        "logs"
        "modules/common"
        "modules/core"
        "modules/themes"
        "modules/widgets"
        "modules/scripts"
        "tools"
        "gui"
        "sources"
        "presets"
        "community"
        "tests"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$SCRIPT_DIR/$dir" ]; then
            log_action "${FIX} Creating missing directory: $dir"
            mkdir -p "$SCRIPT_DIR/$dir"
        fi
    done
    
    log_action "${OK} Directory structure verified"
}

# 9. Test All Main Functions
test_functionality() {
    log_action "${INFO} Testing core functionality..."
    
    # Test main hyprsupreme command
    if "$SCRIPT_DIR/hyprsupreme" --version >/dev/null 2>&1; then
        log_action "${OK} Main hyprsupreme command working"
    else
        log_action "${ERROR} Main hyprsupreme command failed"
    fi
    
    # Test critical scripts
    local critical_scripts=(
        "install.sh"
        "check_system.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        if bash -n "$SCRIPT_DIR/$script"; then
            log_action "${OK} $script syntax valid"
        else
            log_action "${ERROR} $script has syntax errors"
        fi
    done
}

# 10. Clean up temporary files and caches
cleanup_build() {
    log_action "${INFO} Cleaning up build artifacts..."
    
    # Remove Python cache
    find "$SCRIPT_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$SCRIPT_DIR" -name "*.pyc" -type f -delete 2>/dev/null || true
    
    # Remove old logs (keep last 10)
    find "$SCRIPT_DIR/logs" -name "*.log" -type f | sort | head -n -10 | xargs rm -f 2>/dev/null || true
    
    log_action "${OK} Build cleanup completed"
}

# Main execution
main() {
    log_action "${INFO} Starting HyprSupreme deep fix process..."
    
    cd "$SCRIPT_DIR"
    
    fix_directory_structure
    fix_file_permissions
    fix_python_dependencies
    fix_configuration_files
    fix_error_handling
    fix_module_dependencies
    fix_gpu_scripts
    fix_python_scripts
    test_functionality
    cleanup_build
    
    echo | tee -a "$LOG_FILE"
    log_action "${OK} Deep fix completed successfully!"
    log_action "${INFO} Log file: $LOG_FILE"
    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo "              ✅ HYPRSUPREME DEEP FIX COMPLETE ✅"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    log_action "${INFO} You can now run: ./hyprsupreme doctor"
    log_action "${INFO} Or start installation with: ./hyprsupreme install"
}

# Run main function
main "$@"

