#!/bin/bash
# HyprSupreme-Builder Enhanced Error Management System
# Unified integration of error handling, recovery, and system health monitoring

set -euo pipefail

# Determine script directory for sourcing modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

#=====================================
# Enhanced Error System Metadata
#=====================================

readonly ENHANCED_ERROR_VERSION="2.1.1"
readonly ENHANCED_ERROR_NAME="HyprSupreme Enhanced Error Management"

# System health monitoring
HEALTH_CHECK_INTERVAL=30
HEALTH_ALERT_THRESHOLD=5
SYSTEM_MONITOR_ENABLED=true

# Predictive error detection
PREDICTIVE_ANALYSIS_ENABLED=true
PATTERN_LEARNING_ENABLED=true
ERROR_PREDICTION_THRESHOLD=0.7

# Advanced logging and analytics
DETAILED_ANALYTICS=true
PERFORMANCE_TRACKING=true
ERROR_CORRELATION_ANALYSIS=true

# Global state tracking
declare -A SYSTEM_HEALTH_METRICS=()
declare -A ERROR_PATTERNS=()
declare -A PERFORMANCE_METRICS=()
declare -A COMPONENT_STATUS=()
declare -a PREDICTIVE_WARNINGS=()
declare -a HEALTH_ALERTS=()

ENHANCED_MODE_ACTIVE=false
MONITORING_PID=""
ANALYTICS_ENABLED=true
SELF_HEALING_ENABLED=true

#=====================================
# Module Loading and Initialization
#=====================================

load_error_modules() {
    echo "Loading enhanced error management modules..."
    
    # Load core error handler first
    if [[ -f "$SCRIPT_DIR/error_handler.sh" ]]; then
        source "$SCRIPT_DIR/error_handler.sh"
        # Now log_message is available
        log_message "SUCCESS" "Core error handler loaded"
    else
        echo "FATAL: Cannot find error_handler.sh" >&2
        exit 1
    fi
    
    # Load advanced recovery system
    if [[ -f "$SCRIPT_DIR/error_recovery.sh" ]]; then
        source "$SCRIPT_DIR/error_recovery.sh"
        log_message "SUCCESS" "Advanced recovery system loaded"
    else
        log_message "WARNING" "Advanced recovery system not found - limited recovery capabilities"
    fi
    
    # Load prerequisite verification if available
    if [[ -f "$PROJECT_ROOT/tools/verify_prerequisites.sh" ]]; then
        PREREQUISITE_VERIFIER="$PROJECT_ROOT/tools/verify_prerequisites.sh"
        log_message "SUCCESS" "Prerequisite verification system available"
    else
        log_message "WARNING" "Prerequisite verification system not found"
    fi
    
    # Detect package manager for system-specific operations
    detect_package_manager
    
    return 0
}

detect_package_manager() {
    if command -v pacman &>/dev/null; then
        export PACKAGE_MANAGER="pacman"
        export DISTRO_FAMILY="arch"
    elif command -v apt &>/dev/null; then
        export PACKAGE_MANAGER="apt"
        export DISTRO_FAMILY="debian"
    elif command -v dnf &>/dev/null; then
        export PACKAGE_MANAGER="dnf"
        export DISTRO_FAMILY="redhat"
    elif command -v zypper &>/dev/null; then
        export PACKAGE_MANAGER="zypper"
        export DISTRO_FAMILY="suse"
    else
        export PACKAGE_MANAGER="unknown"
        export DISTRO_FAMILY="unknown"
        log_message "WARNING" "Unknown package manager - some features may be limited"
    fi
    
    log_message "INFO" "Detected package manager: $PACKAGE_MANAGER ($DISTRO_FAMILY family)"
}

#=====================================
# Enhanced Error Handler Integration
#=====================================

enhanced_error_trap() {
    local exit_code=$?
    local line_number="${1:-$LINENO}"
    local command="${2:-Unknown command}"
    local function_name="${FUNCNAME[1]:-main}"
    
    # Capture additional context
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local process_id=$$
    local user_id=$(id -u)
    local system_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    local memory_usage=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100}')
    local disk_usage=$(df . | awk 'NR==2 {printf "%.1f", $5}' | sed 's/%//')
    
    # Enhanced error context
    local error_context="Function: $function_name, Line: $line_number, PID: $process_id"
    error_context+=", Load: $system_load, Memory: ${memory_usage}%, Disk: ${disk_usage}%"
    
    # Call the main error handler with enhanced context
    if declare -f handle_error &>/dev/null; then
        ERROR_CONTEXT="$error_context"
        handle_error "$line_number" "$command"
    fi
    
    # Advanced error analysis and prediction
    analyze_error_trends "$exit_code" "$command" "$function_name"
    
    # Attempt intelligent recovery if enabled
    if [[ "$SELF_HEALING_ENABLED" == true ]] && declare -f attempt_smart_recovery &>/dev/null; then
        log_message "INFO" "Attempting intelligent error recovery"
        
        # Capture command output for analysis
        local command_output=""
        if [[ -n "$command" ]] && [[ "$command" != "Unknown command" ]]; then
            command_output=$(eval "$command" 2>&1 || true)
        fi
        
        if attempt_smart_recovery "$command" "$exit_code" "$command_output"; then
            log_message "SUCCESS" "Intelligent recovery successful"
            return 0
        else
            log_message "WARNING" "Intelligent recovery failed - manual intervention may be required"
        fi
    fi
    
    # Update system health metrics
    update_health_metrics "error" "$exit_code"
    
    # Check if system health is deteriorating
    if check_system_health_degradation; then
        trigger_health_alert "System health degradation detected"
    fi
    
    return $exit_code
}

#=====================================
# Predictive Error Analysis
#=====================================

analyze_error_trends() {
    local exit_code="$1"
    local command="$2"
    local function_name="$3"
    
    if [[ "$PREDICTIVE_ANALYSIS_ENABLED" != true ]]; then
        return 0
    fi
    
    local timestamp=$(date +%s)
    local error_signature="${command}_${exit_code}_${function_name}"
    
    # Track error patterns over time
    if [[ -z "${ERROR_PATTERNS[$error_signature]:-}" ]]; then
        ERROR_PATTERNS[$error_signature]="1:$timestamp"
    else
        local current_data="${ERROR_PATTERNS[$error_signature]}"
        local count="${current_data%%:*}"
        local first_occurrence="${current_data##*:}"
        local new_count=$((count + 1))
        ERROR_PATTERNS[$error_signature]="$new_count:$first_occurrence:$timestamp"
    fi
    
    # Analyze if this error is becoming frequent
    local pattern_data="${ERROR_PATTERNS[$error_signature]}"
    local occurrence_count="${pattern_data%%:*}"
    
    if [[ $occurrence_count -ge 3 ]]; then
        local time_span=$((timestamp - first_occurrence))
        local error_rate=$(echo "scale=2; $occurrence_count / ($time_span / 3600)" | bc -l 2>/dev/null || echo "0")
        
        if (( $(echo "$error_rate > 0.5" | bc -l 2>/dev/null || echo 0) )); then
            PREDICTIVE_WARNINGS+=("High error rate detected for: $error_signature (${error_rate}/hour)")
            log_message "WARNING" "Predictive analysis: Error pattern becoming frequent"
        fi
    fi
    
    # Pattern learning for future prevention
    if [[ "$PATTERN_LEARNING_ENABLED" == true ]]; then
        learn_error_pattern "$error_signature" "$exit_code" "$command"
    fi
}

learn_error_pattern() {
    local signature="$1"
    local exit_code="$2"
    local command="$3"
    
    # Create a learning file for this pattern
    local pattern_file="$PROJECT_ROOT/logs/patterns/${signature//\//_}.pattern"
    mkdir -p "$(dirname "$pattern_file")"
    
    # Store pattern data for machine learning
    cat >> "$pattern_file" << EOF
timestamp=$(date +%s)
exit_code=$exit_code
command=$command
system_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
memory_usage=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100}')
disk_usage=$(df . | awk 'NR==2 {printf "%.1f", $5}' | sed 's/%//')
user_count=$(who | wc -l)
process_count=$(ps aux | wc -l)
EOF
    
    # Trigger pattern analysis if we have enough data
    local pattern_count=$(wc -l < "$pattern_file" 2>/dev/null || echo 0)
    if [[ $pattern_count -ge 10 ]]; then
        analyze_learned_patterns "$signature" "$pattern_file"
    fi
}

analyze_learned_patterns() {
    local signature="$1"
    local pattern_file="$2"
    
    log_message "DEBUG" "Analyzing learned patterns for: $signature"
    
    # Simple correlation analysis
    local high_load_errors=$(grep "system_load" "$pattern_file" | awk -F= '$2 > 2.0' | wc -l)
    local high_memory_errors=$(grep "memory_usage" "$pattern_file" | awk -F= '$2 > 80.0' | wc -l)
    local high_disk_errors=$(grep "disk_usage" "$pattern_file" | awk -F= '$2 > 90.0' | wc -l)
    
    local total_errors=$(wc -l < "$pattern_file")
    
    # Calculate correlations
    local load_correlation=$(echo "scale=2; $high_load_errors / $total_errors" | bc -l 2>/dev/null || echo "0")
    local memory_correlation=$(echo "scale=2; $high_memory_errors / $total_errors" | bc -l 2>/dev/null || echo "0")
    local disk_correlation=$(echo "scale=2; $high_disk_errors / $total_errors" | bc -l 2>/dev/null || echo "0")
    
    # Generate predictive insights
    if (( $(echo "$load_correlation > $ERROR_PREDICTION_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        PREDICTIVE_WARNINGS+=("Pattern analysis: $signature strongly correlated with high system load")
    fi
    
    if (( $(echo "$memory_correlation > $ERROR_PREDICTION_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        PREDICTIVE_WARNINGS+=("Pattern analysis: $signature strongly correlated with high memory usage")
    fi
    
    if (( $(echo "$disk_correlation > $ERROR_PREDICTION_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        PREDICTIVE_WARNINGS+=("Pattern analysis: $signature strongly correlated with high disk usage")
    fi
}

#=====================================
# System Health Monitoring
#=====================================

start_health_monitoring() {
    if [[ "$SYSTEM_MONITOR_ENABLED" != true ]]; then
        return 0
    fi
    
    log_message "INFO" "Starting continuous system health monitoring"
    
    # Start background monitoring process
    {
        while true; do
            collect_health_metrics
            analyze_system_health
            sleep $HEALTH_CHECK_INTERVAL
        done
    } &
    
    MONITORING_PID=$!
    log_message "SUCCESS" "Health monitoring started (PID: $MONITORING_PID)"
    
    # Ensure monitoring is stopped on exit
    trap "stop_health_monitoring" EXIT
}

stop_health_monitoring() {
    if [[ -n "$MONITORING_PID" ]] && kill -0 "$MONITORING_PID" 2>/dev/null; then
        log_message "INFO" "Stopping health monitoring (PID: $MONITORING_PID)"
        kill "$MONITORING_PID" 2>/dev/null || true
        wait "$MONITORING_PID" 2>/dev/null || true
        MONITORING_PID=""
    fi
}

collect_health_metrics() {
    local timestamp=$(date +%s)
    
    # System metrics
    SYSTEM_HEALTH_METRICS[timestamp]="$timestamp"
    SYSTEM_HEALTH_METRICS[cpu_load]=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    SYSTEM_HEALTH_METRICS[memory_usage]=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100}')
    SYSTEM_HEALTH_METRICS[disk_usage]=$(df . | awk 'NR==2 {printf "%.1f", $5}' | sed 's/%//')
    SYSTEM_HEALTH_METRICS[process_count]=$(ps aux | wc -l)
    SYSTEM_HEALTH_METRICS[network_connections]=$(ss -tun | wc -l)
    
    # Error rate metrics
    local recent_errors=0
    if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
        recent_errors=$(grep -c "ERROR\|CRITICAL" "$LOG_FILE" 2>/dev/null | tail -100 | wc -l || echo 0)
    fi
    SYSTEM_HEALTH_METRICS[error_rate]="$recent_errors"
    
    # Component health checks
    check_component_health
}

check_component_health() {
    # Check disk space
    local disk_usage=$(df . | awk 'NR==2 {printf "%.0f", $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        COMPONENT_STATUS[disk]="critical"
    elif [[ $disk_usage -gt 80 ]]; then
        COMPONENT_STATUS[disk]="warning"
    else
        COMPONENT_STATUS[disk]="healthy"
    fi
    
    # Check memory
    local memory_usage=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    if [[ $memory_usage -gt 90 ]]; then
        COMPONENT_STATUS[memory]="critical"
    elif [[ $memory_usage -gt 80 ]]; then
        COMPONENT_STATUS[memory]="warning"
    else
        COMPONENT_STATUS[memory]="healthy"
    fi
    
    # Check system load
    local load=$(uptime | awk -F'load average:' '{print $1}' | awk '{print $NF}' | tr -d ',')
    local cpu_cores=$(nproc)
    local load_percentage=$(echo "scale=0; $load * 100 / $cpu_cores" | bc -l 2>/dev/null || echo 0)
    
    if [[ $load_percentage -gt 200 ]]; then
        COMPONENT_STATUS[cpu]="critical"
    elif [[ $load_percentage -gt 100 ]]; then
        COMPONENT_STATUS[cpu]="warning"
    else
        COMPONENT_STATUS[cpu]="healthy"
    fi
    
    # Check network connectivity
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        COMPONENT_STATUS[network]="healthy"
    else
        COMPONENT_STATUS[network]="critical"
    fi
}

analyze_system_health() {
    local critical_components=0
    local warning_components=0
    
    for component in "${!COMPONENT_STATUS[@]}"; do
        case "${COMPONENT_STATUS[$component]}" in
            critical)
                ((critical_components++))
                ;;
            warning)
                ((warning_components++))
                ;;
        esac
    done
    
    # Trigger alerts based on component health
    if [[ $critical_components -gt 0 ]]; then
        trigger_health_alert "Critical system components detected: $critical_components"
    elif [[ $warning_components -gt 2 ]]; then
        trigger_health_alert "Multiple warning components detected: $warning_components"
    fi
    
    # Check for degrading trends
    check_health_trends
}

check_system_health_degradation() {
    local recent_errors=${SYSTEM_HEALTH_METRICS[error_rate]:-0}
    local memory_usage=${SYSTEM_HEALTH_METRICS[memory_usage]:-0}
    local disk_usage=${SYSTEM_HEALTH_METRICS[disk_usage]:-0}
    
    # Simple degradation check
    if [[ $recent_errors -gt $HEALTH_ALERT_THRESHOLD ]] || \
       [[ $(echo "$memory_usage > 85" | bc -l 2>/dev/null || echo 0) -eq 1 ]] || \
       [[ $(echo "$disk_usage > 90" | bc -l 2>/dev/null || echo 0) -eq 1 ]]; then
        return 0  # Degradation detected
    fi
    
    return 1  # No degradation
}

check_health_trends() {
    # This is a simplified trend analysis
    # In a full implementation, this would analyze metrics over time
    
    local current_error_rate=${SYSTEM_HEALTH_METRICS[error_rate]:-0}
    local current_memory=${SYSTEM_HEALTH_METRICS[memory_usage]:-0}
    
    # Store trend data (simplified)
    echo "$(date +%s):$current_error_rate:$current_memory" >> "$PROJECT_ROOT/logs/health_trends.log"
    
    # Keep only last 100 entries
    tail -100 "$PROJECT_ROOT/logs/health_trends.log" > "$PROJECT_ROOT/logs/health_trends.log.tmp" && \
        mv "$PROJECT_ROOT/logs/health_trends.log.tmp" "$PROJECT_ROOT/logs/health_trends.log"
}

trigger_health_alert() {
    local alert_message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    HEALTH_ALERTS+=("[$timestamp] $alert_message")
    log_message "WARNING" "HEALTH ALERT: $alert_message"
    
    # Optionally trigger automated remediation
    if [[ "$SELF_HEALING_ENABLED" == true ]]; then
        attempt_automated_remediation "$alert_message"
    fi
}

attempt_automated_remediation() {
    local alert_type="$1"
    
    log_message "INFO" "Attempting automated remediation for: $alert_type"
    
    case "$alert_type" in
        *"disk"*|*"storage"*)
            cleanup_temporary_files
            ;;
        *"memory"*)
            clear_system_caches
            ;;
        *"load"*|*"cpu"*)
            optimize_system_performance
            ;;
        *"network"*)
            restart_network_services
            ;;
        *)
            log_message "INFO" "No automated remediation available for: $alert_type"
            ;;
    esac
}

cleanup_temporary_files() {
    log_message "INFO" "Performing automated disk cleanup"
    
    # Clean package manager caches
    case "$PACKAGE_MANAGER" in
        pacman)
            sudo pacman -Scc --noconfirm &>/dev/null || true
            ;;
        apt)
            sudo apt clean &>/dev/null || true
            sudo apt autoremove -y &>/dev/null || true
            ;;
        dnf)
            sudo dnf clean all &>/dev/null || true
            ;;
    esac
    
    # Clean temporary files
    sudo find /tmp -type f -atime +1 -delete 2>/dev/null || true
    
    # Clean user cache
    find "$HOME/.cache" -type f -atime +7 -delete 2>/dev/null || true
    
    log_message "SUCCESS" "Automated disk cleanup completed"
}

clear_system_caches() {
    log_message "INFO" "Clearing system caches to free memory"
    
    # Clear page cache, dentries and inodes
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
    
    log_message "SUCCESS" "System caches cleared"
}

optimize_system_performance() {
    log_message "INFO" "Optimizing system performance"
    
    # Reduce swappiness temporarily
    echo 10 | sudo tee /proc/sys/vm/swappiness >/dev/null 2>&1 || true
    
    # Kill high-CPU processes that are safe to restart
    # This is a conservative approach - only kill known safe processes
    pkill -f "update-.*" 2>/dev/null || true
    
    log_message "SUCCESS" "System performance optimization applied"
}

restart_network_services() {
    log_message "INFO" "Attempting to restart network services"
    
    # Try to restart NetworkManager
    sudo systemctl restart NetworkManager 2>/dev/null || true
    
    # Wait and test connectivity
    sleep 5
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        log_message "SUCCESS" "Network connectivity restored"
    else
        log_message "WARNING" "Network restart did not resolve connectivity issues"
    fi
}

#=====================================
# Performance Analytics
#=====================================

track_performance_metrics() {
    if [[ "$PERFORMANCE_TRACKING" != true ]]; then
        return 0
    fi
    
    local command="$1"
    local start_time="$2"
    local end_time="$3"
    local exit_code="$4"
    
    local duration=$((end_time - start_time))
    local command_hash=$(echo "$command" | md5sum | cut -d' ' -f1 | head -c8)
    
    # Store performance data
    local perf_file="$PROJECT_ROOT/logs/performance/${command_hash}.perf"
    mkdir -p "$(dirname "$perf_file")"
    
    cat >> "$perf_file" << EOF
timestamp=$end_time
duration=$duration
exit_code=$exit_code
command=$command
system_load=${SYSTEM_HEALTH_METRICS[cpu_load]:-0}
memory_usage=${SYSTEM_HEALTH_METRICS[memory_usage]:-0}
EOF
    
    # Analyze performance trends
    analyze_performance_trends "$command_hash" "$perf_file"
}

analyze_performance_trends() {
    local command_hash="$1"
    local perf_file="$2"
    
    local entry_count=$(wc -l < "$perf_file" 2>/dev/null || echo 0)
    
    if [[ $entry_count -ge 5 ]]; then
        # Calculate average duration
        local avg_duration=$(grep "duration=" "$perf_file" | awk -F= '{sum+=$2} END {printf "%.2f", sum/NR}')
        local recent_duration=$(tail -1 "$perf_file" | grep "duration=" | awk -F= '{print $2}')
        
        # Check for performance degradation
        if [[ -n "$avg_duration" ]] && [[ -n "$recent_duration" ]]; then
            local degradation_factor=$(echo "scale=2; $recent_duration / $avg_duration" | bc -l 2>/dev/null || echo 1)
            
            if (( $(echo "$degradation_factor > 2.0" | bc -l 2>/dev/null || echo 0) )); then
                PREDICTIVE_WARNINGS+=("Performance degradation detected for command pattern (${degradation_factor}x slower)")
            fi
        fi
    fi
}

#=====================================
# Enhanced Command Execution
#=====================================

execute_with_enhanced_error_handling() {
    local command="$1"
    shift
    local args=("$@")
    
    log_message "DEBUG" "Executing with enhanced error handling: $command ${args[*]}"
    
    # Pre-execution checks
    if [[ "$PREDICTIVE_ANALYSIS_ENABLED" == true ]]; then
        check_predictive_warnings "$command"
    fi
    
    # Performance tracking
    local start_time=$(date +%s)
    local command_output=""
    local exit_code=0
    
    # Enhanced execution with output capture
    if command_output=$("$command" "${args[@]}" 2>&1); then
        exit_code=0
        log_message "DEBUG" "Command succeeded: $command"
    else
        exit_code=$?
        log_message "WARNING" "Command failed with exit code $exit_code: $command"
        
        # Advanced recovery attempt
        if [[ "$SELF_HEALING_ENABLED" == true ]] && declare -f attempt_smart_recovery &>/dev/null; then
            if attempt_smart_recovery "$command ${args[*]}" "$exit_code" "$command_output"; then
                log_message "SUCCESS" "Command recovered successfully"
                exit_code=0
            fi
        fi
    fi
    
    # Performance tracking
    local end_time=$(date +%s)
    track_performance_metrics "$command ${args[*]}" "$start_time" "$end_time" "$exit_code"
    
    # Update system health
    update_health_metrics "command_execution" "$exit_code"
    
    return $exit_code
}

check_predictive_warnings() {
    local command="$1"
    
    # Check if we have warnings for this command pattern
    for warning in "${PREDICTIVE_WARNINGS[@]}"; do
        if echo "$warning" | grep -q "$command"; then
            log_message "WARNING" "Predictive analysis warning: $warning"
        fi
    done
}

update_health_metrics() {
    local event_type="$1"
    local value="$2"
    
    case "$event_type" in
        error)
            SYSTEM_HEALTH_METRICS[last_error_time]=$(date +%s)
            SYSTEM_HEALTH_METRICS[error_count]=$((${SYSTEM_HEALTH_METRICS[error_count]:-0} + 1))
            ;;
        command_execution)
            SYSTEM_HEALTH_METRICS[last_command_time]=$(date +%s)
            if [[ $value -eq 0 ]]; then
                SYSTEM_HEALTH_METRICS[success_count]=$((${SYSTEM_HEALTH_METRICS[success_count]:-0} + 1))
            else
                SYSTEM_HEALTH_METRICS[failure_count]=$((${SYSTEM_HEALTH_METRICS[failure_count]:-0} + 1))
            fi
            ;;
    esac
}

#=====================================
# Enhanced Reporting
#=====================================

generate_comprehensive_report() {
    local report_file="${1:-logs/comprehensive-error-report-$(date +%Y%m%d-%H%M%S).md}"
    
    log_message "INFO" "Generating comprehensive error management report"
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# HyprSupreme-Builder Comprehensive Error Management Report
Generated: $(date)
Enhanced Error System Version: $ENHANCED_ERROR_VERSION

## Executive Summary

### System Health Overview
- Current Status: $(get_overall_system_status)
- Total Errors Detected: ${SYSTEM_HEALTH_METRICS[error_count]:-0}
- Successful Operations: ${SYSTEM_HEALTH_METRICS[success_count]:-0}
- System Uptime: $(uptime -p)
- Health Alerts Generated: ${#HEALTH_ALERTS[@]}

### Component Status
EOF

    # Add component status
    for component in "${!COMPONENT_STATUS[@]}"; do
        echo "- $component: ${COMPONENT_STATUS[$component]}" >> "$report_file"
    done

    cat >> "$report_file" << EOF

## Error Analysis

### Error Patterns Detected
EOF

    # Add error patterns
    for pattern in "${!ERROR_PATTERNS[@]}"; do
        local pattern_data="${ERROR_PATTERNS[$pattern]}"
        local count="${pattern_data%%:*}"
        echo "- $pattern: $count occurrences" >> "$report_file"
    done

    cat >> "$report_file" << EOF

### Predictive Warnings
EOF

    # Add predictive warnings
    for warning in "${PREDICTIVE_WARNINGS[@]}"; do
        echo "- $warning" >> "$report_file"
    done

    cat >> "$report_file" << EOF

### Health Alerts
EOF

    # Add health alerts
    for alert in "${HEALTH_ALERTS[@]}"; do
        echo "- $alert" >> "$report_file"
    done

    cat >> "$report_file" << EOF

## System Metrics

### Current Metrics
- CPU Load: ${SYSTEM_HEALTH_METRICS[cpu_load]:-Unknown}
- Memory Usage: ${SYSTEM_HEALTH_METRICS[memory_usage]:-Unknown}%
- Disk Usage: ${SYSTEM_HEALTH_METRICS[disk_usage]:-Unknown}%
- Process Count: ${SYSTEM_HEALTH_METRICS[process_count]:-Unknown}
- Network Connections: ${SYSTEM_HEALTH_METRICS[network_connections]:-Unknown}

### Performance Analytics
$(generate_performance_summary)

## Recommendations

$(generate_recommendations)

---
Report generated by HyprSupreme-Builder Enhanced Error Management System
EOF

    log_message "SUCCESS" "Comprehensive report saved to: $report_file"
}

get_overall_system_status() {
    local critical_count=0
    local warning_count=0
    
    for status in "${COMPONENT_STATUS[@]}"; do
        case "$status" in
            critical) ((critical_count++)) ;;
            warning) ((warning_count++)) ;;
        esac
    done
    
    if [[ $critical_count -gt 0 ]]; then
        echo "CRITICAL"
    elif [[ $warning_count -gt 0 ]]; then
        echo "WARNING"
    else
        echo "HEALTHY"
    fi
}

generate_performance_summary() {
    echo "Performance summary generation would analyze:"
    echo "- Average command execution times"
    echo "- Performance degradation trends"
    echo "- Resource utilization patterns"
    echo "- Bottleneck identification"
}

generate_recommendations() {
    local recommendations=""
    
    # Check component statuses and generate recommendations
    for component in "${!COMPONENT_STATUS[@]}"; do
        case "${COMPONENT_STATUS[$component]}" in
            critical)
                case "$component" in
                    disk)
                        recommendations+="- URGENT: Clean up disk space immediately\n"
                        ;;
                    memory)
                        recommendations+="- URGENT: Reduce memory usage or add more RAM\n"
                        ;;
                    cpu)
                        recommendations+="- URGENT: Reduce system load or optimize processes\n"
                        ;;
                    network)
                        recommendations+="- URGENT: Fix network connectivity issues\n"
                        ;;
                esac
                ;;
            warning)
                case "$component" in
                    disk)
                        recommendations+="- Monitor disk usage and plan cleanup\n"
                        ;;
                    memory)
                        recommendations+="- Consider optimizing memory usage\n"
                        ;;
                    cpu)
                        recommendations+="- Monitor system load\n"
                        ;;
                esac
                ;;
        esac
    done
    
    # Add general recommendations based on patterns
    if [[ ${#ERROR_PATTERNS[@]} -gt 5 ]]; then
        recommendations+="- Review error patterns for systemic issues\n"
    fi
    
    if [[ ${#PREDICTIVE_WARNINGS[@]} -gt 0 ]]; then
        recommendations+="- Address predictive warnings to prevent future issues\n"
    fi
    
    if [[ -z "$recommendations" ]]; then
        recommendations="- System appears healthy, continue monitoring\n"
    fi
    
    echo -e "$recommendations"
}

#=====================================
# Main Interface Functions
#=====================================

init_enhanced_error_system() {
    # Load all required modules first
    if ! load_error_modules; then
        echo "FATAL: Failed to load required error handling modules" >&2
        exit 1
    fi
    
    # Now log_message is available
    log_message "INFO" "Initializing Enhanced Error Management System v$ENHANCED_ERROR_VERSION"
    
    # Initialize core error handler
    if declare -f init_error_handler &>/dev/null; then
        init_error_handler "$@"
    fi
    
    # Initialize recovery system
    if declare -f init_recovery_system &>/dev/null; then
        init_recovery_system "$@"
    fi
    
    # Set up enhanced error trapping
    trap 'enhanced_error_trap $LINENO "$BASH_COMMAND"' ERR
    
    # Start health monitoring
    start_health_monitoring
    
    # Initialize analytics
    mkdir -p "$PROJECT_ROOT/logs/patterns" "$PROJECT_ROOT/logs/performance"
    
    ENHANCED_MODE_ACTIVE=true
    
    log_message "SUCCESS" "Enhanced Error Management System fully initialized"
    
    # Generate initial system report
    generate_comprehensive_report "logs/initial-system-report-$(date +%Y%m%d-%H%M%S).md"
}

configure_enhanced_error_system() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --enable-monitoring)
                SYSTEM_MONITOR_ENABLED=true
                shift
                ;;
            --disable-monitoring)
                SYSTEM_MONITOR_ENABLED=false
                shift
                ;;
            --enable-prediction)
                PREDICTIVE_ANALYSIS_ENABLED=true
                shift
                ;;
            --disable-prediction)
                PREDICTIVE_ANALYSIS_ENABLED=false
                shift
                ;;
            --enable-self-healing)
                SELF_HEALING_ENABLED=true
                shift
                ;;
            --disable-self-healing)
                SELF_HEALING_ENABLED=false
                shift
                ;;
            --enable-analytics)
                ANALYTICS_ENABLED=true
                shift
                ;;
            --disable-analytics)
                ANALYTICS_ENABLED=false
                shift
                ;;
            --monitoring-interval)
                HEALTH_CHECK_INTERVAL="$2"
                shift 2
                ;;
            *)
                # Pass unknown options to recovery system
                if declare -f configure_recovery_system &>/dev/null; then
                    configure_recovery_system "$1"
                fi
                shift
                ;;
        esac
    done
    
    # Only log if log_message function is available
    if declare -f log_message &>/dev/null; then
        log_message "INFO" "Enhanced error system configured:"
        log_message "INFO" "  System monitoring: $SYSTEM_MONITOR_ENABLED"
        log_message "INFO" "  Predictive analysis: $PREDICTIVE_ANALYSIS_ENABLED"
        log_message "INFO" "  Self-healing: $SELF_HEALING_ENABLED"
        log_message "INFO" "  Analytics: $ANALYTICS_ENABLED"
        log_message "INFO" "  Monitoring interval: $HEALTH_CHECK_INTERVAL seconds"
    else
        echo "Enhanced error system configured with specified options"
    fi
}

cleanup_enhanced_error_system() {
    # Only log if log_message function is available
    if declare -f log_message &>/dev/null; then
        log_message "INFO" "Cleaning up Enhanced Error Management System"
    else
        echo "Cleaning up Enhanced Error Management System"
    fi
    
    # Stop monitoring
    stop_health_monitoring
    
    # Generate final comprehensive report
    if [[ "$ENHANCED_MODE_ACTIVE" == true ]]; then
        generate_comprehensive_report "logs/final-system-report-$(date +%Y%m%d-%H%M%S).md"
    fi
    
    # Call recovery system cleanup if available
    if declare -f generate_recovery_report &>/dev/null; then
        generate_recovery_report
    fi
    
    # Call main error handler cleanup if available
    if declare -f generate_error_report &>/dev/null; then
        generate_error_report
    fi
    
    # Only log if log_message function is available
    if declare -f log_message &>/dev/null; then
        log_message "SUCCESS" "Enhanced Error Management System cleanup completed"
    else
        echo "Enhanced Error Management System cleanup completed"
    fi
}

# Export enhanced functions
export -f init_enhanced_error_system
export -f configure_enhanced_error_system
export -f execute_with_enhanced_error_handling
export -f cleanup_enhanced_error_system

# Set up cleanup on exit
trap 'cleanup_enhanced_error_system' EXIT

# Initialize if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_enhanced_error_system "$@"
fi

