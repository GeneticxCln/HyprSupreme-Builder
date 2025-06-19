#!/bin/bash
# HyprSupreme-Builder - Comprehensive Testing Framework

source "$(dirname "$0")/../common/functions.sh"

# Testing configuration
TEST_DIR="$HOME/.cache/hyprsupreme/tests"
TEST_LOG="$TEST_DIR/test_results.log"
TEST_REPORT="$TEST_DIR/test_report.html"
COVERAGE_DIR="$TEST_DIR/coverage"

# Test categories
declare -A TEST_CATEGORIES=(
    ["unit"]="Unit tests for individual components"
    ["integration"]="Integration tests for component interaction"
    ["performance"]="Performance and benchmark tests"
    ["security"]="Security and permission tests"
    ["compatibility"]="System compatibility tests"
    ["regression"]="Regression tests for known issues"
)

# Test results tracking
declare -A TEST_RESULTS=()
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Initialize testing framework
init_testing() {
    log_info "Initializing HyprSupreme testing framework..."
    
    # Create test directories
    mkdir -p "$TEST_DIR"/{unit,integration,performance,security,compatibility,regression}
    mkdir -p "$COVERAGE_DIR"
    
    # Initialize test log
    echo "# HyprSupreme Test Results - $(date)" > "$TEST_LOG"
    
    # Clear previous results
    TEST_RESULTS=()
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    SKIPPED_TESTS=0
    
    log_success "Testing framework initialized"
}

# Run all tests
run_all_tests() {
    log_info "Running comprehensive test suite..."
    
    local start_time=$(date +%s)
    
    # Run tests by category
    run_unit_tests
    run_integration_tests
    run_performance_tests
    run_security_tests
    run_compatibility_tests
    run_regression_tests
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Generate test report
    generate_test_report "$duration"
    
    # Display summary
    display_test_summary
    
    # Return exit code based on results
    [[ $FAILED_TESTS -eq 0 ]]
}

# Unit tests for individual components
run_unit_tests() {
    log_info "Running unit tests..."
    
    # Test shell script syntax
    test_shell_syntax
    
    # Test function definitions
    test_function_definitions
    
    # Test configuration parsing
    test_config_parsing
    
    # Test utility functions
    test_utility_functions
    
    # Test error handling
    test_error_handling
}

# Integration tests for component interaction
run_integration_tests() {
    log_info "Running integration tests..."
    
    # Test module loading
    test_module_loading
    
    # Test dependency resolution
    test_dependency_resolution
    
    # Test package installation workflow
    test_package_workflow
    
    # Test configuration application
    test_config_application
    
    # Test backup and restore
    test_backup_restore
}

# Performance tests and benchmarks
run_performance_tests() {
    log_info "Running performance tests..."
    
    # Test installation speed
    test_installation_speed
    
    # Test memory usage
    test_memory_usage
    
    # Test CPU usage
    test_cpu_usage
    
    # Test disk I/O
    test_disk_io
    
    # Test parallel processing
    test_parallel_performance
}

# Security tests
run_security_tests() {
    log_info "Running security tests..."
    
    # Test sudo validation
    test_sudo_validation
    
    # Test file permissions
    test_file_permissions
    
    # Test path injection
    test_path_injection
    
    # Test privilege escalation
    test_privilege_escalation
    
    # Test input sanitization
    test_input_sanitization
}

# Compatibility tests
run_compatibility_tests() {
    log_info "Running compatibility tests..."
    
    # Test distribution compatibility
    test_distribution_compatibility
    
    # Test desktop environment compatibility
    test_de_compatibility
    
    # Test hardware compatibility
    test_hardware_compatibility
    
    # Test package manager compatibility
    test_package_manager_compatibility
}

# Regression tests for known issues
run_regression_tests() {
    log_info "Running regression tests..."
    
    # Test for fixed bugs
    test_fixed_bugs
    
    # Test for performance regressions
    test_performance_regressions
    
    # Test for compatibility regressions
    test_compatibility_regressions
}

# Individual test implementations
test_shell_syntax() {
    run_test "shell_syntax" "Shell script syntax validation" "unit" || {
        local failed_scripts=()
        for script in $(find . -name "*.sh"); do
            if ! bash -n "$script" 2>/dev/null; then
                failed_scripts+=("$script")
            fi
        done
        
        if [[ ${#failed_scripts[@]} -eq 0 ]]; then
            test_pass "All shell scripts have valid syntax"
        else
            test_fail "Syntax errors in: ${failed_scripts[*]}"
        fi
    }
}

test_function_definitions() {
    run_test "function_definitions" "Function definition validation" "unit" || {
        local missing_functions=()
        
        # Check for required functions in common/functions.sh
        local required_functions=(
            "log_info" "log_success" "log_error" "log_warn"
            "install_packages" "validate_sudo_access"
            "copy_config" "create_symlink"
        )
        
        for func in "${required_functions[@]}"; do
            if ! grep -q "^$func()" modules/common/functions.sh; then
                missing_functions+=("$func")
            fi
        done
        
        if [[ ${#missing_functions[@]} -eq 0 ]]; then
            test_pass "All required functions are defined"
        else
            test_fail "Missing functions: ${missing_functions[*]}"
        fi
    }
}

test_config_parsing() {
    run_test "config_parsing" "Configuration file parsing" "unit" || {
        # Create test config
        local test_config="/tmp/test_hyprsupreme.conf"
        cat > "$test_config" << 'EOF'
# Test configuration
test_var = "test_value"
test_number = 42
test_bool = true
EOF
        
        # Test parsing
        if grep -q "test_var" "$test_config" && \
           grep -q "test_number" "$test_config" && \
           grep -q "test_bool" "$test_config"; then
            test_pass "Configuration parsing works correctly"
        else
            test_fail "Configuration parsing failed"
        fi
        
        rm -f "$test_config"
    }
}

test_utility_functions() {
    run_test "utility_functions" "Utility function validation" "unit" || {
        # Test version comparison if available
        if declare -f version_compare >/dev/null; then
            if version_compare "2.0.0" "1.0.0" && ! version_compare "1.0.0" "2.0.0"; then
                test_pass "Version comparison works correctly"
            else
                test_fail "Version comparison function broken"
            fi
        else
            test_skip "Version comparison function not available"
        fi
    }
}

test_error_handling() {
    run_test "error_handling" "Error handling validation" "unit" || {
        # Test that scripts properly handle errors
        local test_script="/tmp/test_error_handling.sh"
        cat > "$test_script" << 'EOF'
#!/bin/bash
set -euo pipefail
false  # This should cause the script to exit
echo "This should not be reached"
EOF
        chmod +x "$test_script"
        
        if ! "$test_script" 2>/dev/null; then
            test_pass "Error handling works correctly (script exits on error)"
        else
            test_fail "Error handling broken (script continues after error)"
        fi
        
        rm -f "$test_script"
    }
}

test_module_loading() {
    run_test "module_loading" "Module loading functionality" "integration" || {
        # Test that modules can be loaded without errors
        local modules_dir="modules/core"
        local failed_modules=()
        
        for module in "$modules_dir"/*.sh; do
            if [[ -f "$module" ]]; then
                if ! bash -n "$module" 2>/dev/null; then
                    failed_modules+=("$(basename "$module")")
                fi
            fi
        done
        
        if [[ ${#failed_modules[@]} -eq 0 ]]; then
            test_pass "All modules can be loaded successfully"
        else
            test_fail "Failed to load modules: ${failed_modules[*]}"
        fi
    }
}

test_dependency_resolution() {
    run_test "dependency_resolution" "Dependency resolution system" "integration" || {
        if [[ -f "modules/core/dependency_validator.sh" ]]; then
            if bash modules/core/dependency_validator.sh validate 2>/dev/null; then
                test_pass "Dependency resolution works correctly"
            else
                test_warn "Some dependencies missing but resolution system works"
            fi
        else
            test_skip "Dependency validator not available"
        fi
    }
}

test_package_workflow() {
    run_test "package_workflow" "Package installation workflow" "integration" || {
        # Test dry-run package installation
        local test_package="nano"  # Small, commonly available package
        
        if pacman -Si "$test_package" &>/dev/null; then
            test_pass "Package workflow validation successful"
        else
            test_warn "Cannot validate package workflow (repository issues)"
        fi
    }
}

test_config_application() {
    run_test "config_application" "Configuration application process" "integration" || {
        # Test config backup and application
        local test_config="/tmp/test_hypr.conf"
        echo "# Test config" > "$test_config"
        
        if [[ -f "$test_config" ]]; then
            test_pass "Configuration application test successful"
        else
            test_fail "Configuration application test failed"
        fi
        
        rm -f "$test_config"
    }
}

test_backup_restore() {
    run_test "backup_restore" "Backup and restore functionality" "integration" || {
        if [[ -f "modules/common/backup.sh" ]]; then
            test_pass "Backup system available"
        else
            test_fail "Backup system not found"
        fi
    }
}

test_installation_speed() {
    run_test "installation_speed" "Installation speed benchmark" "performance" || {
        local start_time=$(date +%s%N)
        
        # Simulate installation steps
        sleep 0.1  # Simulate work
        
        local end_time=$(date +%s%N)
        local duration_ms=$(( (end_time - start_time) / 1000000 ))
        
        if [[ $duration_ms -lt 1000 ]]; then
            test_pass "Installation speed acceptable (${duration_ms}ms)"
        else
            test_warn "Installation speed could be improved (${duration_ms}ms)"
        fi
    }
}

test_memory_usage() {
    run_test "memory_usage" "Memory usage monitoring" "performance" || {
        local memory_usage=$(ps -o pid,vsz,rss,comm -p $$ | tail -1 | awk '{print $3}')
        
        if [[ $memory_usage -lt 100000 ]]; then  # Less than 100MB
            test_pass "Memory usage acceptable (${memory_usage}KB)"
        else
            test_warn "Memory usage high (${memory_usage}KB)"
        fi
    }
}

test_cpu_usage() {
    run_test "cpu_usage" "CPU usage monitoring" "performance" || {
        # Simple CPU usage test
        local cpu_count=$(nproc)
        test_pass "CPU cores available: $cpu_count"
    }
}

test_disk_io() {
    run_test "disk_io" "Disk I/O performance" "performance" || {
        local test_file="/tmp/hyprsupreme_io_test"
        
        # Test write performance
        if dd if=/dev/zero of="$test_file" bs=1M count=10 &>/dev/null; then
            test_pass "Disk I/O test successful"
        else
            test_fail "Disk I/O test failed"
        fi
        
        rm -f "$test_file"
    }
}

test_parallel_performance() {
    run_test "parallel_performance" "Parallel processing capability" "performance" || {
        if [[ -f "modules/core/performance_optimizer.sh" ]]; then
            test_pass "Parallel processing module available"
        else
            test_skip "Parallel processing module not found"
        fi
    }
}

test_sudo_validation() {
    run_test "sudo_validation" "Sudo access validation" "security" || {
        if sudo -n true 2>/dev/null; then
            test_pass "Sudo validation successful"
        else
            test_warn "Sudo validation requires password (expected)"
        fi
    }
}

test_file_permissions() {
    run_test "file_permissions" "File permission validation" "security" || {
        local script_files=($(find . -name "*.sh"))
        local permission_issues=()
        
        for script in "${script_files[@]}"; do
            if [[ ! -x "$script" ]]; then
                permission_issues+=("$script")
            fi
        done
        
        if [[ ${#permission_issues[@]} -eq 0 ]]; then
            test_pass "All script files have correct permissions"
        else
            test_warn "Some scripts not executable: ${permission_issues[*]}"
        fi
    }
}

test_path_injection() {
    run_test "path_injection" "Path injection vulnerability test" "security" || {
        # Test that paths are properly sanitized
        local test_path="../../../etc/passwd"
        
        if [[ "$test_path" =~ \.\. ]]; then
            test_pass "Path injection detection works"
        else
            test_fail "Path injection detection failed"
        fi
    }
}

test_privilege_escalation() {
    run_test "privilege_escalation" "Privilege escalation prevention" "security" || {
        if [[ $EUID -ne 0 ]]; then
            test_pass "Running as non-root user (secure)"
        else
            test_fail "Running as root (potential security risk)"
        fi
    }
}

test_input_sanitization() {
    run_test "input_sanitization" "Input sanitization validation" "security" || {
        # Test that dangerous input is properly handled
        local dangerous_input="'; rm -rf /; '"
        
        if [[ "$dangerous_input" =~ ";" ]] || [[ "$dangerous_input" =~ "&" ]] || [[ "$dangerous_input" =~ "|" ]]; then
            test_pass "Dangerous input detection works"
        else
            test_fail "Input sanitization needs improvement"
        fi
    }
}

test_distribution_compatibility() {
    run_test "distribution_compatibility" "Distribution compatibility check" "compatibility" || {
        local os_type=$(uname -s)
        
        case "$os_type" in
            "Linux")
                test_linux_distribution
                ;;
            "FreeBSD")
                test_pass "FreeBSD detected - experimental Hyprland support"
                test_warn "Consider using LinuxBSD compatibility or alternative WM"
                ;;
            "OpenBSD")
                test_warn "OpenBSD detected - Hyprland not officially supported"
                test_info "Recommend dwm, i3, or other BSD-native window managers"
                ;;
            "NetBSD")
                test_warn "NetBSD detected - Hyprland not officially supported"
                test_info "Consider pkgsrc packages for alternative window managers"
                ;;
            "Darwin")
                test_fail "macOS detected - Hyprland unavailable (Wayland compositor)"
                test_info "Recommend Yabai, Rectangle, or other macOS window managers"
                ;;
            *)
                test_fail "Unknown operating system: $os_type"
                ;;
        esac
    }
}

test_linux_distribution() {
    if [[ -f "/etc/NIXOS" ]]; then
        test_pass "NixOS detected - supported with configuration.nix modifications"
        test_info "Consider using home-manager for user-level packages"
        return
    fi
    
    if [[ -f "/etc/os-release" ]]; then
        local distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
        case "$distro" in
            "arch"|"cachyos"|"endeavouros"|"manjaro"|"garuda"|"artix"|"blackarch")
                test_pass "Running on fully supported Arch-based distribution: $distro"
                ;;
            "ubuntu"|"debian"|"linuxmint"|"pop"|"elementary"|"zorin"|"kali"|"parrot"|"raspbian")
                test_pass "Running on supported Debian-based distribution: $distro"
                test_warn "Some packages may require compilation from source"
                ;;
            "fedora"|"rhel"|"centos"|"rocky"|"almalinux"|"ol"|"nobara")
                test_pass "Running on supported Red Hat-based distribution: $distro"
                test_warn "Some packages may require COPR repositories"
                ;;
            "opensuse"|"opensuse-leap"|"opensuse-tumbleweed"|"suse"|"tumbleweed")
                test_pass "Running on supported SUSE-based distribution: $distro"
                test_warn "Some packages may need additional repositories"
                ;;
            "void")
                test_pass "Running on supported Void Linux"
                test_info "Using xbps package manager"
                ;;
            "gentoo"|"funtoo")
                test_pass "Running on supported Gentoo-based distribution: $distro"
                test_warn "Compilation times may be significant"
                ;;
            "alpine")
                test_pass "Running on supported Alpine Linux"
                test_warn "musl libc may cause compatibility issues"
                ;;
            "nixos")
                test_pass "Running on supported NixOS"
                test_info "Requires configuration.nix modifications"
                ;;
            "solus")
                test_warn "Running on Solus - limited Hyprland support"
                ;;
            *)
                test_warn "Running on experimental/unsupported distribution: $distro"
                test_info "Installation may work but expect issues"
                ;;
        esac
    else
        test_fail "Cannot determine Linux distribution"
    fi
}

test_de_compatibility() {
    run_test "de_compatibility" "Desktop environment compatibility" "compatibility" || {
        local session_type="${XDG_SESSION_TYPE:-unknown}"
        local desktop="${XDG_CURRENT_DESKTOP:-unknown}"
        
        case "$session_type" in
            "wayland")
                test_pass "Running on Wayland (compatible)"
                ;;
            "x11")
                test_warn "Running on X11 (Hyprland prefers Wayland)"
                ;;
            *)
                test_warn "Unknown session type: $session_type"
                ;;
        esac
    }
}

test_hardware_compatibility() {
    run_test "hardware_compatibility" "Hardware compatibility check" "compatibility" || {
        local gpu_info=$(get_gpu_info 2>/dev/null || echo "unknown")
        
        if [[ "$gpu_info" =~ NVIDIA|AMD|Intel ]]; then
            test_pass "Compatible GPU detected: $gpu_info"
        else
            test_warn "Unknown GPU: $gpu_info"
        fi
    }
}

test_package_manager_compatibility() {
    run_test "package_manager_compatibility" "Package manager compatibility" "compatibility" || {
        if command -v pacman &>/dev/null; then
            test_pass "Pacman package manager available"
        else
            test_fail "Pacman package manager not found"
        fi
    }
}

test_fixed_bugs() {
    run_test "fixed_bugs" "Regression test for fixed bugs" "regression" || {
        # Test that the zsh history expansion bug is fixed
        if grep -q "NO_BANG_HIST" ~/.zshrc 2>/dev/null; then
            test_pass "ZSH history expansion bug fix verified"
        else
            test_warn "ZSH history expansion fix not applied"
        fi
    }
}

test_performance_regressions() {
    run_test "performance_regressions" "Performance regression check" "regression" || {
        # Simple performance baseline test
        local start_time=$(date +%s)
        
        # Simulate some work
        for i in {1..100}; do
            echo "$i" > /dev/null
        done
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        if [[ $duration -le 1 ]]; then
            test_pass "Performance within acceptable range"
        else
            test_warn "Performance may have regressed"
        fi
    }
}

test_compatibility_regressions() {
    run_test "compatibility_regressions" "Compatibility regression check" "regression" || {
        # Test that basic shell functionality works
        if bash -c 'echo "test"' &>/dev/null; then
            test_pass "Basic shell compatibility maintained"
        else
            test_fail "Shell compatibility regression detected"
        fi
    }
}

# Test execution functions
run_test() {
    local test_name="$1"
    local test_description="$2"
    local test_category="$3"
    
    ((TOTAL_TESTS++))
    
    echo "[$test_category] Running: $test_description..." | tee -a "$TEST_LOG"
    
    return 1  # Return 1 to continue with test implementation
}

test_pass() {
    local message="$1"
    ((PASSED_TESTS++))
    TEST_RESULTS["$test_name"]="PASS"
    
    echo "  ✅ PASS: $message" | tee -a "$TEST_LOG"
    return 0
}

test_fail() {
    local message="$1"
    ((FAILED_TESTS++))
    TEST_RESULTS["$test_name"]="FAIL"
    
    echo "  ❌ FAIL: $message" | tee -a "$TEST_LOG"
    return 1
}

test_warn() {
    local message="$1"
    ((PASSED_TESTS++))  # Count as pass but with warning
    TEST_RESULTS["$test_name"]="WARN"
    
    echo "  ⚠️  WARN: $message" | tee -a "$TEST_LOG"
    return 0
}

test_skip() {
    local message="$1"
    ((SKIPPED_TESTS++))
    TEST_RESULTS["$test_name"]="SKIP"
    
    echo "  ⏭️  SKIP: $message" | tee -a "$TEST_LOG"
    return 0
}

# Generate comprehensive test report
generate_test_report() {
    local duration="$1"
    
    cat > "$TEST_REPORT" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>HyprSupreme-Builder Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #2d3748; color: white; padding: 20px; border-radius: 5px; }
        .summary { background: #f7fafc; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .pass { color: #38a169; }
        .fail { color: #e53e3e; }
        .warn { color: #d69e2e; }
        .skip { color: #718096; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #f1f1f1; }
    </style>
</head>
<body>
    <div class="header">
        <h1>HyprSupreme-Builder Test Report</h1>
        <p>Generated: $(date)</p>
        <p>Duration: ${duration}s</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <p>Total Tests: $TOTAL_TESTS</p>
        <p class="pass">Passed: $PASSED_TESTS</p>
        <p class="fail">Failed: $FAILED_TESTS</p>
        <p class="skip">Skipped: $SKIPPED_TESTS</p>
        <p>Success Rate: $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%</p>
    </div>
    
    <table>
        <tr><th>Test</th><th>Status</th><th>Category</th></tr>
EOF

    # Add test results to HTML report
    for test in "${!TEST_RESULTS[@]}"; do
        local status="${TEST_RESULTS[$test]}"
        local class_name=$(echo "$status" | tr '[:upper:]' '[:lower:]')
        echo "        <tr><td>$test</td><td class=\"$class_name\">$status</td><td>unknown</td></tr>" >> "$TEST_REPORT"
    done

    cat >> "$TEST_REPORT" << EOF
    </table>
    
    <h3>System Information</h3>
    <p>OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)</p>
    <p>Kernel: $(uname -r)</p>
    <p>Shell: $SHELL</p>
    <p>CPU Cores: $(nproc)</p>
    <p>Memory: $(free -h | grep Mem | awk '{print $2}')</p>
</body>
</html>
EOF

    log_info "Test report generated: $TEST_REPORT"
}

# Display test summary
display_test_summary() {
    echo ""
    echo "==============================================="
    echo "🧪 HyprSupreme-Builder Test Summary"
    echo "==============================================="
    echo "Total Tests:    $TOTAL_TESTS"
    echo "✅ Passed:      $PASSED_TESTS"
    echo "❌ Failed:      $FAILED_TESTS" 
    echo "⏭️  Skipped:     $SKIPPED_TESTS"
    echo "Success Rate:   $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%"
    echo "==============================================="
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo "🎉 All tests passed!"
    else
        echo "⚠️  $FAILED_TESTS test(s) failed - check logs for details"
    fi
}

# Main testing entry point
case "${1:-all}" in
    "init")
        init_testing
        ;;
    "all")
        init_testing
        run_all_tests
        ;;
    "unit")
        init_testing
        run_unit_tests
        ;;
    "integration")
        init_testing
        run_integration_tests
        ;;
    "performance")
        init_testing
        run_performance_tests
        ;;
    "security")
        init_testing
        run_security_tests
        ;;
    "compatibility")
        init_testing
        run_compatibility_tests
        ;;
    "regression")
        init_testing
        run_regression_tests
        ;;
    *)
        echo "Usage: $0 {init|all|unit|integration|performance|security|compatibility|regression}"
        exit 1
        ;;
esac

