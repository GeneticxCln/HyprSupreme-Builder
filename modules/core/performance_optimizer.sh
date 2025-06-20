#!/bin/bash
# HyprSupreme-Builder - Performance Optimization Module

# Add debug output to trace source path resolution
resolved_script_path="$(readlink -f "${BASH_SOURCE[0]}")"
resolved_dir="$(dirname "$resolved_script_path")"
functions_path="$resolved_dir/../common/functions.sh"
echo "Debug: Script path: $resolved_script_path"
echo "Debug: Script directory: $resolved_dir"
echo "Debug: Functions path: $functions_path"
echo "Debug: Functions exists: $([[ -f "$functions_path" ]] && echo "yes" || echo "no")"

source "$functions_path"

# Performance optimization configuration
PARALLEL_JOBS=${PARALLEL_JOBS:-$(nproc)}
CACHE_DIR="$HOME/.cache/hyprsupreme"
PERFORMANCE_LOG="$CACHE_DIR/performance.log"

# Initialize performance optimization
init_performance() {
    log_info "Initializing performance optimization..."
    
    # Create cache directories
    mkdir -p "$CACHE_DIR"/{downloads,packages,themes,builds}
    
    # Set up performance logging
    echo "# HyprSupreme Performance Log - $(date)" > "$PERFORMANCE_LOG"
    
    # Optimize system for installation
    optimize_system_performance
    
    log_success "Performance optimization initialized"
}

# Optimize system performance during installation
optimize_system_performance() {
    log_info "Optimizing system performance..."
    
    # Set optimal I/O scheduler for SSDs/NVMe
    optimize_io_scheduler
    
    # Optimize memory usage
    optimize_memory
    
    # Set CPU governor for performance
    optimize_cpu_governor
    
    # Configure parallel downloads
    configure_parallel_downloads
}

# Optimize I/O scheduler
optimize_io_scheduler() {
    for disk in /sys/block/*/queue/scheduler; do
        if [[ -f "$disk" ]]; then
            local device=$(echo "$disk" | cut -d'/' -f4)
            local current_scheduler=$(cat "$disk" | grep -o '\[.*\]' | tr -d '[]')
            
            # Check if it's an SSD/NVMe
            if [[ -f "/sys/block/$device/queue/rotational" ]] && [[ $(cat "/sys/block/$device/queue/rotational") == "0" ]]; then
                # SSD/NVMe - use none or mq-deadline
                if grep -q "none" "$disk"; then
                    echo "none" | sudo tee "$disk" > /dev/null 2>&1 || true
                elif grep -q "mq-deadline" "$disk"; then
                    echo "mq-deadline" | sudo tee "$disk" > /dev/null 2>&1 || true
                fi
                log_info "Optimized I/O scheduler for $device (SSD/NVMe)"
            fi
        fi
    done
}

# Optimize memory usage
optimize_memory() {
    # Increase swappiness for better memory management during installation
    echo 10 | sudo tee /proc/sys/vm/swappiness > /dev/null 2>&1 || true
    
    # Clear caches to free up memory
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true
    
    log_info "Optimized memory settings"
}

# Optimize CPU governor
optimize_cpu_governor() {
    if [[ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]]; then
        # Set performance governor during installation
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            if [[ -f "$cpu" ]] && grep -q "performance" "$(dirname "$cpu")/scaling_available_governors" 2>/dev/null; then
                echo "performance" | sudo tee "$cpu" > /dev/null 2>&1 || true
            fi
        done
        log_info "Set CPU governor to performance mode"
    fi
}

# Configure parallel downloads
configure_parallel_downloads() {
    local pacman_conf="/etc/pacman.conf"
    
    if [[ -f "$pacman_conf" ]]; then
        # Enable parallel downloads in pacman
        if ! grep -q "^ParallelDownloads" "$pacman_conf"; then
            echo "ParallelDownloads = 5" | sudo tee -a "$pacman_conf" > /dev/null
            log_info "Enabled parallel downloads in pacman"
        fi
    fi
}

# Parallel package installation with proper dependency handling
install_packages_parallel() {
    local packages=("$@")
    local batch_size=3
    local pids=()
    
    log_info "Installing ${#packages[@]} packages in parallel (batch size: $batch_size)..."
    
    # Split packages into batches
    local batch=()
    local batch_count=0
    
    for pkg in "${packages[@]}"; do
        batch+=("$pkg")
        
        if [[ ${#batch[@]} -eq $batch_size ]]; then
            install_package_batch "${batch[@]}" &
            pids+=($!)
            batch=()
            ((batch_count++))
            
            # Limit concurrent batches
            if [[ ${#pids[@]} -ge $PARALLEL_JOBS ]]; then
                wait_for_batch "${pids[@]}"
                pids=()
            fi
        fi
    done
    
    # Install remaining packages
    if [[ ${#batch[@]} -gt 0 ]]; then
        install_package_batch "${batch[@]}" &
        pids+=($!)
    fi
    
    # Wait for all batches to complete
    if [[ ${#pids[@]} -gt 0 ]]; then
        wait_for_batch "${pids[@]}"
    fi
    
    log_success "Parallel package installation completed"
}

# Install a batch of packages
install_package_batch() {
    local packages=("$@")
    local start_time=$(date +%s)
    
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            if sudo pacman -S --noconfirm "$pkg" &> /dev/null; then
                log_success "Installed $pkg"
            elif [[ -n "$AUR_HELPER" ]] && $AUR_HELPER -S --noconfirm "$pkg" &> /dev/null; then
                log_success "Installed $pkg from AUR"
            else
                log_error "Failed to install $pkg"
            fi
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "Batch completed in ${duration}s: ${packages[*]}" >> "$PERFORMANCE_LOG"
}

# Wait for package installation batches
wait_for_batch() {
    local pids=("$@")
    
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

# Download files in parallel with caching
download_parallel() {
    local urls=("$@")
    local pids=()
    
    log_info "Downloading ${#urls[@]} files in parallel..."
    
    for url in "${urls[@]}"; do
        download_single_cached "$url" &
        pids+=($!)
        
        # Limit concurrent downloads
        if [[ ${#pids[@]} -ge $PARALLEL_JOBS ]]; then
            for pid in "${pids[@]}"; do
                wait "$pid"
            done
            pids=()
        fi
    done
    
    # Wait for remaining downloads
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    log_success "Parallel downloads completed"
}

# Download single file with caching
download_single_cached() {
    local url="$1"
    local filename=$(basename "$url")
    local cache_file="$CACHE_DIR/downloads/$filename"
    
    # Check if file exists in cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        # Use cached file if less than 24 hours old
        if [[ $cache_age -lt 86400 ]]; then
            log_info "Using cached $filename"
            return 0
        fi
    fi
    
    # Download file
    if curl -fsSL "$url" -o "$cache_file"; then
        log_success "Downloaded and cached $filename"
    else
        log_error "Failed to download $url"
        return 1
    fi
}

# Restore system performance settings
restore_performance() {
    log_info "Restoring system performance settings..."
    
    # Restore CPU governor
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$cpu" ]] && grep -q "powersave" "$(dirname "$cpu")/scaling_available_governors" 2>/dev/null; then
            echo "powersave" | sudo tee "$cpu" > /dev/null 2>&1 || true
        fi
    done
    
    # Restore swappiness
    echo 60 | sudo tee /proc/sys/vm/swappiness > /dev/null 2>&1 || true
    
    log_success "System performance settings restored"
}

# Performance monitoring
monitor_performance() {
    local operation="$1"
    local start_time=$(date +%s)
    
    # Monitor system resources
    {
        echo "=== Performance Monitor: $operation ==="
        echo "Start time: $(date)"
        echo "CPU cores: $(nproc)"
        echo "Memory: $(free -h | grep Mem)"
        echo "Load average: $(uptime | cut -d',' -f3-5)"
        echo "Disk usage: $(df -h / | tail -1)"
        echo ""
    } >> "$PERFORMANCE_LOG"
    
    # Return function to call when operation completes
    echo "$start_time"
}

# Complete performance monitoring
complete_performance_monitor() {
    local operation="$1"
    local start_time="$2"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    {
        echo "=== Performance Monitor Complete: $operation ==="
        echo "End time: $(date)"
        echo "Duration: ${duration}s"
        echo "Memory after: $(free -h | grep Mem)"
        echo "Load average: $(uptime | cut -d',' -f3-5)"
        echo "========================================"
        echo ""
    } >> "$PERFORMANCE_LOG"
    
    log_info "$operation completed in ${duration}s"
}

# Cache management functions
clean_cache() {
    local cache_age_days="${1:-7}"
    
    log_info "Cleaning cache older than $cache_age_days days..."
    
    # Clean download cache
    find "$CACHE_DIR/downloads" -type f -mtime +$cache_age_days -delete 2>/dev/null || true
    
    # Clean package cache
    find "$CACHE_DIR/packages" -type f -mtime +$cache_age_days -delete 2>/dev/null || true
    
    # Clean theme cache
    find "$CACHE_DIR/themes" -type f -mtime +$cache_age_days -delete 2>/dev/null || true
    
    log_success "Cache cleaned"
}

# Get cache size
get_cache_size() {
    if [[ -d "$CACHE_DIR" ]]; then
        du -sh "$CACHE_DIR" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# Main performance optimization entry point
case "${1:-init}" in
    "init")
        init_performance
        ;;
    "install_parallel")
        shift
        install_packages_parallel "$@"
        ;;
    "download_parallel")
        shift
        download_parallel "$@"
        ;;
    "restore")
        restore_performance
        ;;
    "clean_cache")
        clean_cache "${2:-7}"
        ;;
    "monitor")
        monitor_performance "$2"
        ;;
    "complete_monitor")
        complete_performance_monitor "$2" "$3"
        ;;
    "cache_size")
        get_cache_size
        ;;
    *)
        echo "Usage: $0 {init|install_parallel|download_parallel|restore|clean_cache|monitor|complete_monitor|cache_size}"
        exit 1
        ;;
esac

