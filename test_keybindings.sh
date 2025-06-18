#!/bin/bash
# /* ---- 💫 HyprSupreme Keybinding Test Script 💫 ---- */
# Test script to validate Hyprland keybindings functionality

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Log file
LOG_FILE="$HOME/HyprSupreme-Builder/keybind_test_results.log"
echo "=== Hyprland Keybinding Test Results ===" > "$LOG_FILE"
echo "Test started: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  HyprSupreme Keybinding Tester${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" == "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "PASS: $test_name - $details" >> "$LOG_FILE"
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo -e "  ${YELLOW}Details: $details${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "FAIL: $test_name - $details" >> "$LOG_FILE"
    fi
}

# Check if Hyprland is running
check_hyprland_running() {
    echo -e "${BLUE}Checking Hyprland environment...${NC}"
    
    if pgrep -x "Hyprland" > /dev/null; then
        test_result "Hyprland Process" "PASS" "Hyprland is running"
    else
        test_result "Hyprland Process" "FAIL" "Hyprland is not running"
        return 1
    fi
    
    if command -v hyprctl > /dev/null; then
        test_result "hyprctl Command" "PASS" "hyprctl is available"
    else
        test_result "hyprctl Command" "FAIL" "hyprctl not found in PATH"
        return 1
    fi
    
    return 0
}

# Test keybinding configuration files
test_config_files() {
    echo -e "\n${BLUE}Testing keybinding configuration files...${NC}"
    
    local keybinds_conf="$HOME/.config/hypr/configs/Keybinds.conf"
    local user_keybinds_conf="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
    local laptop_conf="$HOME/.config/hypr/UserConfigs/Laptops.conf"
    
    # Test main keybinds file
    if [ -f "$keybinds_conf" ]; then
        local bind_count=$(grep -c "^bind" "$keybinds_conf" 2>/dev/null || echo 0)
        if [ "$bind_count" -gt 0 ]; then
            test_result "Main Keybinds File" "PASS" "Found $bind_count keybindings"
        else
            test_result "Main Keybinds File" "FAIL" "No keybindings found in file"
        fi
    else
        test_result "Main Keybinds File" "FAIL" "File does not exist: $keybinds_conf"
    fi
    
    # Test user keybinds file
    if [ -f "$user_keybinds_conf" ]; then
        local user_bind_count=$(grep -c "^bind" "$user_keybinds_conf" 2>/dev/null || echo 0)
        test_result "User Keybinds File" "PASS" "Found $user_bind_count user keybindings"
    else
        test_result "User Keybinds File" "FAIL" "File does not exist: $user_keybinds_conf"
    fi
    
    # Test laptop keybinds file (optional)
    if [ -f "$laptop_conf" ]; then
        local laptop_bind_count=$(grep -c "^bind" "$laptop_conf" 2>/dev/null || echo 0)
        test_result "Laptop Keybinds File" "PASS" "Found $laptop_bind_count laptop keybindings"
    else
        test_result "Laptop Keybinds File" "PASS" "Optional file not present (normal)"
    fi
}

# Test if scripts exist and are executable
test_script_dependencies() {
    echo -e "\n${BLUE}Testing script dependencies...${NC}"
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    local critical_scripts=(
        "LockScreen.sh"
        "Wlogout.sh" 
        "Volume.sh"
        "ScreenShot.sh"
        "KeyHints.sh"
        "GameMode.sh"
        "ChangeLayout.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        local script_path="$scripts_dir/$script"
        if [ -f "$script_path" ] && [ -x "$script_path" ]; then
            test_result "Script: $script" "PASS" "Script exists and is executable"
        elif [ -f "$script_path" ]; then
            test_result "Script: $script" "FAIL" "Script exists but is not executable"
        else
            test_result "Script: $script" "FAIL" "Script does not exist"
        fi
    done
}

# Test hyprctl commands that keybindings rely on
test_hyprctl_functionality() {
    echo -e "\n${BLUE}Testing hyprctl functionality...${NC}"
    
    # Test basic hyprctl commands
    if hyprctl version > /dev/null 2>&1; then
        test_result "hyprctl version" "PASS" "Command executed successfully"
    else
        test_result "hyprctl version" "FAIL" "Command failed"
    fi
    
    if hyprctl clients > /dev/null 2>&1; then
        test_result "hyprctl clients" "PASS" "Command executed successfully"
    else
        test_result "hyprctl clients" "FAIL" "Command failed"
    fi
    
    if hyprctl workspaces > /dev/null 2>&1; then
        test_result "hyprctl workspaces" "PASS" "Command executed successfully"
    else
        test_result "hyprctl workspaces" "FAIL" "Command failed"
    fi
}

# Test workspace switching functionality
test_workspace_functionality() {
    echo -e "\n${BLUE}Testing workspace functionality...${NC}"
    
    # Get current workspace
    local current_ws=$(hyprctl activeworkspace | grep "workspace ID" | awk '{print $3}' 2>/dev/null)
    
    if [ -n "$current_ws" ]; then
        test_result "Get Active Workspace" "PASS" "Current workspace: $current_ws"
        
        # Test workspace switching (non-destructive)
        if hyprctl dispatch workspace 1 > /dev/null 2>&1; then
            test_result "Workspace Switch Command" "PASS" "Successfully switched to workspace 1"
            # Switch back to original
            hyprctl dispatch workspace "$current_ws" > /dev/null 2>&1
        else
            test_result "Workspace Switch Command" "FAIL" "Failed to switch workspace"
        fi
    else
        test_result "Get Active Workspace" "FAIL" "Could not determine current workspace"
    fi
}

# Test applications that keybindings launch
test_application_dependencies() {
    echo -e "\n${BLUE}Testing application dependencies...${NC}"
    
    local apps=(
        "rofi:Application launcher"
        "waybar:Status bar"
        "swaync:Notification center"
        "wlogout:Power menu"
        "hyprlock:Screen locker"
        "kitty:Terminal emulator"
    )
    
    for app_info in "${apps[@]}"; do
        local app=$(echo "$app_info" | cut -d':' -f1)
        local description=$(echo "$app_info" | cut -d':' -f2)
        
        if command -v "$app" > /dev/null; then
            test_result "Application: $app" "PASS" "$description available"
        else
            test_result "Application: $app" "FAIL" "$description not found in PATH"
        fi
    done
}

# Test key binding syntax validation
test_keybind_syntax() {
    echo -e "\n${BLUE}Testing keybinding syntax...${NC}"
    
    local keybinds_conf="$HOME/.config/hypr/configs/Keybinds.conf"
    local user_keybinds_conf="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
    
    # Check for basic syntax errors in keybindings
    local syntax_errors=0
    
    # Test main keybinds file
    if [ -f "$keybinds_conf" ]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^bind.*= ]] && [[ ! "$line" =~ ^bind[a-z]*[[:space:]]*=[[:space:]]*.*,.* ]]; then
                ((syntax_errors++))
                echo "Syntax error in $keybinds_conf: $line" >> "$LOG_FILE"
            fi
        done < "$keybinds_conf"
    fi
    
    # Test user keybinds file
    if [ -f "$user_keybinds_conf" ]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^bind.*= ]] && [[ ! "$line" =~ ^bind[a-z]*[[:space:]]*=[[:space:]]*.*,.* ]]; then
                ((syntax_errors++))
                echo "Syntax error in $user_keybinds_conf: $line" >> "$LOG_FILE"
            fi
        done < "$user_keybinds_conf"
    fi
    
    if [ "$syntax_errors" -eq 0 ]; then
        test_result "Keybinding Syntax" "PASS" "No syntax errors found"
    else
        test_result "Keybinding Syntax" "FAIL" "$syntax_errors syntax errors found (see log)"
    fi
}

# Generate summary report
generate_summary() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}        TEST SUMMARY${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "Success Rate: ${success_rate}%"
    
    echo "" >> "$LOG_FILE"
    echo "=== SUMMARY ===" >> "$LOG_FILE"
    echo "Total Tests: $TOTAL_TESTS" >> "$LOG_FILE"
    echo "Passed: $PASSED_TESTS" >> "$LOG_FILE"
    echo "Failed: $FAILED_TESTS" >> "$LOG_FILE"
    echo "Success Rate: ${success_rate}%" >> "$LOG_FILE"
    echo "Test completed: $(date)" >> "$LOG_FILE"
    
    echo -e "\nDetailed results saved to: ${LOG_FILE}"
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All tests passed! Your keybindings should work correctly.${NC}"
        return 0
    else
        echo -e "\n${YELLOW}⚠️  Some tests failed. Check the log for details.${NC}"
        return 1
    fi
}

# Main execution
main() {
    print_header
    
    # Only run tests if Hyprland is available
    if check_hyprland_running; then
        test_config_files
        test_script_dependencies
        test_hyprctl_functionality
        test_workspace_functionality
        test_application_dependencies
        test_keybind_syntax
    else
        echo -e "${RED}Cannot run full test suite without Hyprland${NC}"
        echo -e "${YELLOW}Running basic configuration tests only...${NC}"
        test_config_files
        test_script_dependencies
        test_application_dependencies
    fi
    
    generate_summary
}

# Run the tests
main "$@"

