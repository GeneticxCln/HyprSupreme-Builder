#!/bin/bash

# HyprSupreme GPU Switcher
# Advanced GPU switching and optimization for hybrid graphics systems

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$HOME/.config/hyprsupreme"
readonly GPU_CONFIG_FILE="$CONFIG_DIR/gpu_config.json"
readonly LOG_FILE="$CONFIG_DIR/gpu_switcher.log"

# Colors and formatting
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

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Error handling
error_exit() {
    echo -e "${ERROR} $1" >&2
    log "ERROR: $1"
    exit 1
}

# Show help
show_help() {
    cat << 'EOF'
HyprSupreme GPU Switcher - Advanced Graphics Management

USAGE:
    gpu_switcher.sh [COMMAND] [OPTIONS]

COMMANDS:
    detect              Detect available GPUs and current configuration
    list               List all available GPU profiles
    switch <profile>   Switch to specified GPU profile
    status             Show current GPU status and active profile
    optimize           Auto-optimize current GPU configuration
    power              Show GPU power consumption and thermal info
    benchmark          Run GPU performance benchmarks
    reset              Reset to system default GPU configuration
    monitor            Real-time GPU monitoring

GPU PROFILES:
    integrated         Use integrated GPU (Intel/AMD APU)
    discrete           Use discrete GPU (NVIDIA/AMD dGPU)
    hybrid             Use both GPUs (PRIME/Optimus)
    performance        Maximum performance mode
    power-save         Power-saving mode
    balanced           Balanced performance/power

EXAMPLES:
    gpu_switcher.sh detect          # Scan for available GPUs
    gpu_switcher.sh switch discrete # Switch to discrete GPU
    gpu_switcher.sh status          # Show current status
    gpu_switcher.sh optimize        # Auto-optimize current setup
    gpu_switcher.sh monitor         # Launch GPU monitor

OPTIONS:
    --force            Force switch without confirmation
    --dry-run          Show what would be done without executing
    --verbose          Enable verbose output
    --help             Show this help message

EOF
}

# Detect available GPUs
detect_gpus() {
    local gpu_data=()
    
    echo -e "${INFO} Detecting available GPUs..."
    
    # Intel integrated graphics
    if lspci | grep -i "intel.*graphics\|intel.*display" > /dev/null; then
        local intel_gpu=$(lspci | grep -i "intel.*graphics\|intel.*display" | head -1)
        gpu_data+=("intel:$intel_gpu")
        echo -e "${SUCCESS} Intel GPU: ${CYAN}$intel_gpu${NC}"
    fi
    
    # AMD graphics
    if lspci | grep -i "amd\|ati" | grep -i "vga\|display\|graphics" > /dev/null; then
        while IFS= read -r amd_gpu; do
            gpu_data+=("amd:$amd_gpu")
            echo -e "${SUCCESS} AMD GPU: ${CYAN}$amd_gpu${NC}"
        done < <(lspci | grep -i "amd\|ati" | grep -i "vga\|display\|graphics")
    fi
    
    # NVIDIA graphics
    if lspci | grep -i nvidia > /dev/null; then
        while IFS= read -r nvidia_gpu; do
            gpu_data+=("nvidia:$nvidia_gpu")
            echo -e "${SUCCESS} NVIDIA GPU: ${CYAN}$nvidia_gpu${NC}"
        done < <(lspci | grep -i nvidia)
    fi
    
    # Save detection results
    {
        echo "{"
        echo "  \"detection_date\": \"$(date -Iseconds)\","
        echo "  \"gpus\": ["
        for i in "${!gpu_data[@]}"; do
            local gpu="${gpu_data[$i]}"
            local vendor="${gpu%%:*}"
            local description="${gpu#*:}"
            echo "    {"
            echo "      \"vendor\": \"$vendor\","
            echo "      \"description\": \"$description\","
            echo "      \"index\": $i"
            echo "    }$([ $i -eq $((${#gpu_data[@]} - 1)) ] && echo "" || echo ",")"
        done
        echo "  ]"
        echo "}"
    } > "$GPU_CONFIG_FILE"
    
    echo -e "${INFO} GPU detection complete. Found ${#gpu_data[@]} GPU(s)."
    
    # Detect current configuration
    detect_current_config
}

# Detect current GPU configuration
detect_current_config() {
    echo -e "${INFO} Analyzing current GPU configuration..."
    
    local current_mode="unknown"
    local active_gpu="unknown"
    
    # Check for PRIME setup
    if command -v prime-select > /dev/null 2>&1; then
        current_mode=$(prime-select query 2>/dev/null || echo "unknown")
        echo -e "${INFO} PRIME mode: ${CYAN}$current_mode${NC}"
    fi
    
    # Check for optimus-manager
    if command -v optimus-manager > /dev/null 2>&1; then
        local optimus_status=$(optimus-manager --print-mode 2>/dev/null || echo "unknown")
        echo -e "${INFO} Optimus mode: ${CYAN}$optimus_status${NC}"
        current_mode="$optimus_status"
    fi
    
    # Check active GPU via DRI
    if [ -d "/dev/dri" ]; then
        local dri_cards=$(ls /dev/dri/card* 2>/dev/null | wc -l)
        echo -e "${INFO} DRI cards detected: ${CYAN}$dri_cards${NC}"
    fi
    
    # Check GL renderer
    if command -v glxinfo > /dev/null 2>&1; then
        local gl_renderer=$(glxinfo | grep "OpenGL renderer" | cut -d: -f2 | xargs 2>/dev/null || echo "unknown")
        echo -e "${INFO} GL Renderer: ${CYAN}$gl_renderer${NC}"
        active_gpu="$gl_renderer"
    fi
    
    # Update config file with current status
    if [ -f "$GPU_CONFIG_FILE" ]; then
        local temp_file=$(mktemp)
        jq --arg mode "$current_mode" --arg gpu "$active_gpu" \
           '.current_mode = $mode | .active_gpu = $gpu' \
           "$GPU_CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$GPU_CONFIG_FILE"
    fi
}

# List available GPU profiles
list_profiles() {
    echo -e "${INFO} Available GPU profiles:"
    echo
    
    echo -e "${CYAN}integrated${NC}     - Use integrated GPU (Intel/AMD APU)"
    echo -e "                 ${WHITE}↳${NC} Best for: Basic tasks, power saving"
    echo
    
    echo -e "${CYAN}discrete${NC}      - Use discrete GPU (NVIDIA/AMD dGPU)"
    echo -e "                 ${WHITE}↳${NC} Best for: Gaming, rendering, AI workloads"
    echo
    
    echo -e "${CYAN}hybrid${NC}        - Use both GPUs (PRIME/Optimus)"
    echo -e "                 ${WHITE}↳${NC} Best for: Automatic switching based on workload"
    echo
    
    echo -e "${CYAN}performance${NC}   - Maximum performance mode"
    echo -e "                 ${WHITE}↳${NC} Best for: High-performance computing, benchmarks"
    echo
    
    echo -e "${CYAN}power-save${NC}    - Power-saving mode"
    echo -e "                 ${WHITE}↳${NC} Best for: Battery life, thermal management"
    echo
    
    echo -e "${CYAN}balanced${NC}      - Balanced performance/power"
    echo -e "                 ${WHITE}↳${NC} Best for: General use, productivity"
    echo
}

# Show current GPU status
show_status() {
    echo -e "${INFO} Current GPU Status:"
    echo
    
    # Hardware information
    echo -e "${WHITE}Hardware Information:${NC}"
    detect_gpus > /dev/null 2>&1
    
    if [ -f "$GPU_CONFIG_FILE" ]; then
        jq -r '.gpus[] | "  \(.vendor | ascii_upcase): \(.description)"' "$GPU_CONFIG_FILE" 2>/dev/null || echo "  No GPU data available"
        echo
        
        local current_mode=$(jq -r '.current_mode // "unknown"' "$GPU_CONFIG_FILE" 2>/dev/null)
        local active_gpu=$(jq -r '.active_gpu // "unknown"' "$GPU_CONFIG_FILE" 2>/dev/null)
        
        echo -e "${WHITE}Current Configuration:${NC}"
        echo -e "  Mode: ${CYAN}$current_mode${NC}"
        echo -e "  Active GPU: ${CYAN}$active_gpu${NC}"
        echo
    fi
    
    # Power and thermal information
    show_power_info
    
    # Processes using GPU
    show_gpu_processes
}

# Show GPU power and thermal information
show_power_info() {
    echo -e "${WHITE}Power & Thermal:${NC}"
    
    # NVIDIA GPUs
    if command -v nvidia-smi > /dev/null 2>&1; then
        local nvidia_info=$(nvidia-smi --query-gpu=name,power.draw,temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "")
        if [ -n "$nvidia_info" ]; then
            echo "$nvidia_info" | while IFS=, read -r name power temp; do
                echo -e "  ${GREEN}NVIDIA${NC} $name: ${YELLOW}${power}W${NC}, ${YELLOW}${temp}°C${NC}"
            done
        fi
    fi
    
    # AMD GPUs
    if [ -d "/sys/class/drm" ]; then
        for card in /sys/class/drm/card*/device; do
            if [ -f "$card/power_state" ] && [ -f "$card/vendor" ]; then
                local vendor=$(cat "$card/vendor" 2>/dev/null)
                if [ "$vendor" = "0x1002" ]; then  # AMD vendor ID
                    local power_state=$(cat "$card/power_state" 2>/dev/null || echo "unknown")
                    echo -e "  ${RED}AMD${NC} GPU: Power state ${CYAN}$power_state${NC}"
                fi
            fi
        done
    fi
    
    echo
}

# Show processes using GPU
show_gpu_processes() {
    echo -e "${WHITE}GPU Processes:${NC}"
    
    # NVIDIA processes
    if command -v nvidia-smi > /dev/null 2>&1; then
        local nvidia_procs=$(nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader 2>/dev/null)
        if [ -n "$nvidia_procs" ] && [ "$nvidia_procs" != "No running processes found" ]; then
            echo -e "  ${GREEN}NVIDIA processes:${NC}"
            echo "$nvidia_procs" | while IFS=, read -r pid name memory; do
                echo -e "    PID $pid: $name (${memory})"
            done
        else
            echo -e "  ${CYAN}No NVIDIA processes running${NC}"
        fi
    fi
    
    # General GPU processes
    if command -v fuser > /dev/null 2>&1; then
        local dri_procs=$(fuser /dev/dri/* 2>/dev/null | wc -w)
        if [ "$dri_procs" -gt 0 ]; then
            echo -e "  ${CYAN}DRI processes: $dri_procs${NC}"
        fi
    fi
    
    echo
}

# Switch GPU profile
switch_profile() {
    local profile="$1"
    local force_switch="${2:-false}"
    
    echo -e "${INFO} Switching to profile: ${CYAN}$profile${NC}"
    
    # Validation
    case "$profile" in
        integrated|discrete|hybrid|performance|power-save|balanced)
            ;;
        *)
            error_exit "Invalid profile: $profile"
            ;;
    esac
    
    # Confirmation (unless forced)
    if [ "$force_switch" != "true" ]; then
        echo -e "${WARNING} This will restart your graphics session."
        echo -e "${WARNING} Save your work before continuing."
        echo
        read -p "Continue with GPU switch? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${INFO} GPU switch cancelled."
            exit 0
        fi
    fi
    
    # Execute profile switch
    case "$profile" in
        "integrated")
            switch_to_integrated
            ;;
        "discrete")
            switch_to_discrete
            ;;
        "hybrid")
            switch_to_hybrid
            ;;
        "performance")
            switch_to_performance
            ;;
        "power-save")
            switch_to_power_save
            ;;
        "balanced")
            switch_to_balanced
            ;;
    esac
    
    # Update configuration
    update_hyprland_config "$profile"
    
    echo -e "${SUCCESS} Profile switch complete!"
    echo -e "${INFO} Please restart your session for changes to take effect."
}

# Switch to integrated GPU
switch_to_integrated() {
    echo -e "${INFO} Configuring integrated GPU mode..."
    
    # PRIME setup
    if command -v prime-select > /dev/null 2>&1; then
        sudo prime-select intel 2>/dev/null || sudo prime-select on-demand 2>/dev/null || true
    fi
    
    # Optimus manager
    if command -v optimus-manager > /dev/null 2>&1; then
        optimus-manager --switch integrated --no-confirm 2>/dev/null || true
    fi
    
    # Environment variables
    export DRI_PRIME=0
    export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
    
    log "Switched to integrated GPU mode"
}

# Switch to discrete GPU
switch_to_discrete() {
    echo -e "${INFO} Configuring discrete GPU mode..."
    
    # PRIME setup
    if command -v prime-select > /dev/null 2>&1; then
        sudo prime-select nvidia 2>/dev/null || true
    fi
    
    # Optimus manager
    if command -v optimus-manager > /dev/null 2>&1; then
        optimus-manager --switch nvidia --no-confirm 2>/dev/null || true
    fi
    
    # NVIDIA specific
    if lspci | grep -i nvidia > /dev/null; then
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
    fi
    
    # AMD specific
    if lspci | grep -i amd.*vga > /dev/null; then
        export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
    fi
    
    log "Switched to discrete GPU mode"
}

# Switch to hybrid mode
switch_to_hybrid() {
    echo -e "${INFO} Configuring hybrid GPU mode..."
    
    # PRIME setup
    if command -v prime-select > /dev/null 2>&1; then
        sudo prime-select on-demand 2>/dev/null || true
    fi
    
    # Optimus manager
    if command -v optimus-manager > /dev/null 2>&1; then
        optimus-manager --switch hybrid --no-confirm 2>/dev/null || true
    fi
    
    # Enable GPU switching
    export DRI_PRIME=1
    export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json:/usr/share/vulkan/icd.d/nvidia_icd.json
    
    log "Switched to hybrid GPU mode"
}

# Performance mode
switch_to_performance() {
    echo -e "${INFO} Configuring performance mode..."
    
    # Switch to discrete first
    switch_to_discrete
    
    # NVIDIA performance tweaks
    if command -v nvidia-settings > /dev/null 2>&1; then
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" 2>/dev/null || true  # Prefer maximum performance
        nvidia-settings -a "[gpu:0]/GPUFanControlState=1" 2>/dev/null || true
        nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=80" 2>/dev/null || true
    fi
    
    # AMD performance tweaks
    if [ -f "/sys/class/drm/card0/device/power_dpm_force_performance_level" ]; then
        echo "high" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1 || true
    fi
    
    log "Switched to performance mode"
}

# Power save mode
switch_to_power_save() {
    echo -e "${INFO} Configuring power save mode..."
    
    # Switch to integrated first
    switch_to_integrated
    
    # NVIDIA power saving
    if command -v nvidia-settings > /dev/null 2>&1; then
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=0" 2>/dev/null || true  # Auto mode
    fi
    
    # AMD power saving
    if [ -f "/sys/class/drm/card0/device/power_dpm_force_performance_level" ]; then
        echo "low" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1 || true
    fi
    
    # CPU governor
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
        echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null 2>&1 || true
    fi
    
    log "Switched to power save mode"
}

# Balanced mode
switch_to_balanced() {
    echo -e "${INFO} Configuring balanced mode..."
    
    # Use hybrid mode as base
    switch_to_hybrid
    
    # Balanced performance settings
    if command -v nvidia-settings > /dev/null 2>&1; then
        nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=0" 2>/dev/null || true  # Auto mode
    fi
    
    if [ -f "/sys/class/drm/card0/device/power_dpm_force_performance_level" ]; then
        echo "auto" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1 || true
    fi
    
    log "Switched to balanced mode"
}

# Update Hyprland configuration for GPU profile
update_hyprland_config() {
    local profile="$1"
    local hypr_config="$HOME/.config/hypr/hyprland.conf"
    
    if [ ! -f "$hypr_config" ]; then
        echo -e "${WARNING} Hyprland config not found, skipping GPU-specific optimizations"
        return
    fi
    
    echo -e "${INFO} Updating Hyprland configuration for $profile profile..."
    
    # Backup current config
    cp "$hypr_config" "${hypr_config}.gpu_backup.$(date +%Y%m%d_%H%M%S)"
    
    # Remove existing GPU settings
    sed -i '/# GPU_SWITCHER_START/,/# GPU_SWITCHER_END/d' "$hypr_config"
    
    # Add new GPU-specific settings
    {
        echo
        echo "# GPU_SWITCHER_START - Auto-generated by HyprSupreme GPU Switcher"
        echo "# Profile: $profile"
        echo "# Generated: $(date)"
        echo
        
        case "$profile" in
            "integrated")
                echo "# Integrated GPU optimizations"
                echo "decoration {"
                echo "    blur = false"
                echo "    drop_shadow = false"
                echo "}"
                echo "animations {"
                echo "    enabled = false"
                echo "}"
                echo "misc {"
                echo "    vfr = true"
                echo "}"
                ;;
            "discrete"|"performance")
                echo "# Discrete/Performance GPU optimizations"
                echo "decoration {"
                echo "    blur = true"
                echo "    blur_size = 8"
                echo "    blur_passes = 3"
                echo "    drop_shadow = true"
                echo "    shadow_range = 8"
                echo "}"
                echo "animations {"
                echo "    enabled = true"
                echo "    bezier = myBezier, 0.05, 0.9, 0.1, 1.05"
                echo "    animation = windows, 1, 7, myBezier"
                echo "    animation = windowsOut, 1, 7, default, popin 80%"
                echo "    animation = border, 1, 10, default"
                echo "    animation = fade, 1, 7, default"
                echo "    animation = workspaces, 1, 6, default"
                echo "}"
                echo "misc {"
                echo "    vrr = 1"
                echo "}"
                ;;
            "power-save")
                echo "# Power save optimizations"
                echo "decoration {"
                echo "    blur = false"
                echo "    drop_shadow = false"
                echo "}"
                echo "animations {"
                echo "    enabled = false"
                echo "}"
                echo "misc {"
                echo "    vfr = true"
                echo "    disable_hyprland_logo = true"
                echo "}"
                ;;
            "balanced"|"hybrid")
                echo "# Balanced/Hybrid optimizations"
                echo "decoration {"
                echo "    blur = true"
                echo "    blur_size = 4"
                echo "    blur_passes = 2"
                echo "    drop_shadow = true"
                echo "    shadow_range = 4"
                echo "}"
                echo "animations {"
                echo "    enabled = true"
                echo "    bezier = myBezier, 0.05, 0.9, 0.1, 1.05"
                echo "    animation = windows, 1, 5, myBezier"
                echo "    animation = windowsOut, 1, 5, default, popin 80%"
                echo "    animation = border, 1, 8, default"
                echo "    animation = fade, 1, 5, default"
                echo "    animation = workspaces, 1, 4, default"
                echo "}"
                echo "misc {"
                echo "    vfr = true"
                echo "}"
                ;;
        esac
        
        # NVIDIA specific settings
        if lspci | grep -i nvidia > /dev/null; then
            echo
            echo "# NVIDIA specific settings"
            echo "env = LIBVA_DRIVER_NAME,nvidia"
            echo "env = XDG_SESSION_TYPE,wayland"
            echo "env = GBM_BACKEND,nvidia-drm"
            echo "env = __GLX_VENDOR_LIBRARY_NAME,nvidia"
            echo "env = WLR_NO_HARDWARE_CURSORS,1"
        fi
        
        echo
        echo "# GPU_SWITCHER_END"
        echo
    } >> "$hypr_config"
    
    echo -e "${SUCCESS} Hyprland configuration updated for $profile profile"
}

# Auto-optimize current configuration
optimize_current() {
    echo -e "${INFO} Auto-optimizing current GPU configuration..."
    
    # Detect current hardware
    detect_gpus > /dev/null 2>&1
    
    if [ ! -f "$GPU_CONFIG_FILE" ]; then
        error_exit "No GPU data found. Run 'detect' first."
    fi
    
    local gpu_count=$(jq '.gpus | length' "$GPU_CONFIG_FILE" 2>/dev/null || echo "0")
    local has_nvidia=$(jq '.gpus[] | select(.vendor == "nvidia")' "$GPU_CONFIG_FILE" 2>/dev/null | wc -l)
    local has_intel=$(jq '.gpus[] | select(.vendor == "intel")' "$GPU_CONFIG_FILE" 2>/dev/null | wc -l)
    local has_amd=$(jq '.gpus[] | select(.vendor == "amd")' "$GPU_CONFIG_FILE" 2>/dev/null | wc -l)
    
    echo -e "${INFO} Detected configuration:"
    echo -e "  Total GPUs: ${CYAN}$gpu_count${NC}"
    echo -e "  NVIDIA GPUs: ${CYAN}$has_nvidia${NC}"
    echo -e "  Intel GPUs: ${CYAN}$has_intel${NC}"
    echo -e "  AMD GPUs: ${CYAN}$has_amd${NC}"
    echo
    
    # Determine optimal profile
    local optimal_profile="balanced"
    
    if [ "$gpu_count" -eq 1 ]; then
        if [ "$has_nvidia" -gt 0 ] || [ "$has_amd" -gt 0 ]; then
            optimal_profile="discrete"
        else
            optimal_profile="integrated"
        fi
    elif [ "$gpu_count" -gt 1 ]; then
        optimal_profile="hybrid"
    fi
    
    echo -e "${INFO} Recommended profile: ${CYAN}$optimal_profile${NC}"
    echo
    
    read -p "Apply recommended profile? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${INFO} Optimization cancelled."
        exit 0
    fi
    
    switch_profile "$optimal_profile" true
}

# Run GPU benchmarks
run_benchmark() {
    echo -e "${INFO} Running GPU benchmarks..."
    
    # Create benchmark results directory
    local bench_dir="$CONFIG_DIR/benchmarks"
    mkdir -p "$bench_dir"
    
    local results_file="$bench_dir/benchmark_$(date +%Y%m%d_%H%M%S).json"
    
    echo -e "${INFO} Results will be saved to: $results_file"
    echo
    
    # Initialize results
    echo "{" > "$results_file"
    echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$results_file"
    echo "  \"system\": {" >> "$results_file"
    
    # System information
    echo "    \"hostname\": \"$(hostname)\"," >> "$results_file"
    echo "    \"kernel\": \"$(uname -r)\"," >> "$results_file"
    echo "    \"cpu\": \"$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)\"," >> "$results_file"
    echo "    \"memory\": \"$(free -h | grep Mem | awk '{print $2}')\"" >> "$results_file"
    echo "  }," >> "$results_file"
    echo "  \"benchmarks\": {" >> "$results_file"
    
    # OpenGL benchmark
    if command -v glxgears > /dev/null 2>&1; then
        echo -e "${INFO} Running OpenGL benchmark (glxgears)..."
        local gl_result=$(timeout 10s glxgears 2>&1 | tail -n 1 | grep -o '[0-9]* frames' | cut -d' ' -f1 || echo "0")
        echo "    \"opengl_fps\": $gl_result," >> "$results_file"
        echo -e "${SUCCESS} OpenGL FPS: ${CYAN}$gl_result${NC}"
    fi
    
    # Vulkan benchmark
    if command -v vkcube > /dev/null 2>&1; then
        echo -e "${INFO} Running Vulkan benchmark..."
        echo "    \"vulkan\": \"supported\"," >> "$results_file"
        echo -e "${SUCCESS} Vulkan: ${GREEN}Supported${NC}"
    else
        echo "    \"vulkan\": \"not_available\"," >> "$results_file"
        echo -e "${WARNING} Vulkan: ${YELLOW}Not Available${NC}"
    fi
    
    # GPU memory benchmark
    if command -v nvidia-smi > /dev/null 2>&1; then
        local gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
        if [ -n "$gpu_mem" ]; then
            echo "    \"gpu_memory_mb\": $gpu_mem," >> "$results_file"
            echo -e "${SUCCESS} GPU Memory: ${CYAN}${gpu_mem}MB${NC}"
        fi
    fi
    
    # Close JSON
    echo "    \"completed\": true" >> "$results_file"
    echo "  }" >> "$results_file"
    echo "}" >> "$results_file"
    
    echo
    echo -e "${SUCCESS} Benchmark complete! Results saved to:"
    echo -e "  ${CYAN}$results_file${NC}"
}

# Real-time GPU monitoring
monitor_gpu() {
    echo -e "${INFO} Starting real-time GPU monitor..."
    echo -e "${INFO} Press ${CYAN}Ctrl+C${NC} to exit"
    echo
    
    # Check for monitoring tools
    local has_nvidia=false
    local has_intel=false
    local has_amd=false
    
    if command -v nvidia-smi > /dev/null 2>&1; then
        has_nvidia=true
    fi
    
    if [ -d "/sys/class/drm" ]; then
        has_intel=true
        has_amd=true
    fi
    
    while true; do
        clear
        echo -e "${CYAN}=== HyprSupreme GPU Monitor ===${NC}"
        echo -e "$(date '+%Y-%m-%d %H:%M:%S')"
        echo
        
        # NVIDIA monitoring
        if [ "$has_nvidia" = true ]; then
            echo -e "${GREEN}NVIDIA GPUs:${NC}"
            nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader 2>/dev/null | while IFS=, read -r name util mem_used mem_total temp power; do
                echo -e "  ${WHITE}$name${NC}"
                echo -e "    GPU: ${CYAN}${util}${NC} | Memory: ${CYAN}${mem_used}/${mem_total}${NC} | Temp: ${YELLOW}${temp}°C${NC} | Power: ${YELLOW}${power}W${NC}"
            done
            echo
        fi
        
        # Intel monitoring
        if [ "$has_intel" = true ] && [ -f "/sys/class/drm/card0/device/vendor" ]; then
            local vendor=$(cat /sys/class/drm/card0/device/vendor 2>/dev/null)
            if [ "$vendor" = "0x8086" ]; then  # Intel vendor ID
                echo -e "${BLUE}Intel GPU:${NC}"
                if [ -f "/sys/class/drm/card0/gt_cur_freq_mhz" ]; then
                    local freq=$(cat /sys/class/drm/card0/gt_cur_freq_mhz 2>/dev/null || echo "unknown")
                    echo -e "  Current Frequency: ${CYAN}${freq}MHz${NC}"
                fi
                echo
            fi
        fi
        
        # System load
        echo -e "${WHITE}System Load:${NC}"
        echo -e "  CPU: ${CYAN}$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%${NC}"
        echo -e "  Memory: ${CYAN}$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')%${NC}"
        echo -e "  Load Average: ${CYAN}$(uptime | awk -F'load average:' '{print $2}')${NC}"
        
        sleep 2
    done
}

# Reset to default configuration
reset_config() {
    echo -e "${WARNING} This will reset GPU configuration to system defaults."
    echo
    read -p "Continue with reset? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${INFO} Reset cancelled."
        exit 0
    fi
    
    echo -e "${INFO} Resetting GPU configuration..."
    
    # Reset PRIME
    if command -v prime-select > /dev/null 2>&1; then
        sudo prime-select on-demand 2>/dev/null || true
    fi
    
    # Reset optimus-manager
    if command -v optimus-manager > /dev/null 2>&1; then
        optimus-manager --switch hybrid --no-confirm 2>/dev/null || true
    fi
    
    # Remove GPU-specific Hyprland settings
    local hypr_config="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$hypr_config" ]; then
        sed -i '/# GPU_SWITCHER_START/,/# GPU_SWITCHER_END/d' "$hypr_config"
        echo -e "${SUCCESS} Removed GPU-specific Hyprland settings"
    fi
    
    # Clear configuration
    rm -f "$GPU_CONFIG_FILE"
    
    echo -e "${SUCCESS} GPU configuration reset to defaults"
    log "GPU configuration reset to defaults"
}

# Main function
main() {
    case "${1:-}" in
        "detect")
            detect_gpus
            ;;
        "list")
            list_profiles
            ;;
        "switch")
            if [ -z "${2:-}" ]; then
                error_exit "Profile name required for switch command"
            fi
            local force_flag=false
            if [ "${3:-}" = "--force" ]; then
                force_flag=true
            fi
            switch_profile "$2" "$force_flag"
            ;;
        "status")
            show_status
            ;;
        "optimize")
            optimize_current
            ;;
        "power")
            show_power_info
            ;;
        "benchmark")
            run_benchmark
            ;;
        "monitor")
            monitor_gpu
            ;;
        "reset")
            reset_config
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            error_exit "Unknown command: $1. Use 'help' for usage information."
            ;;
    esac
}

# Run main function with all arguments
main "$@"

