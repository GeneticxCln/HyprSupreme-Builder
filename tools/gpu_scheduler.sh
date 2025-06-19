#!/bin/bash

# HyprSupreme GPU Scheduler
# Intelligent automatic GPU profile switching based on applications, system state, and user behavior

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$HOME/.config/hyprsupreme"
readonly SCHEDULER_CONFIG="$CONFIG_DIR/gpu_scheduler.json"
readonly SCHEDULER_STATE="$CONFIG_DIR/scheduler_state"
readonly SCHEDULER_LOG="$CONFIG_DIR/gpu_scheduler.log"
readonly SCHEDULER_RULES="$CONFIG_DIR/gpu_rules.json"

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

# Ensure directories exist
mkdir -p "$CONFIG_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$SCHEDULER_LOG"
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
HyprSupreme GPU Scheduler - Intelligent Automatic GPU Management

USAGE:
    gpu_scheduler.sh [COMMAND] [OPTIONS]

COMMANDS:
    start              Start the GPU scheduler daemon
    stop               Stop the GPU scheduler
    status             Show scheduler status and statistics
    config             Configure scheduler settings
    rules              Manage application rules
    add-rule           Add new application rule
    remove-rule        Remove application rule
    test               Test scheduler logic without applying changes
    monitor            Real-time monitoring of scheduler decisions

SCHEDULER FEATURES:
    - Automatic profile switching based on running applications
    - Battery level awareness (switch to power-save when low)
    - Thermal management (reduce performance when overheating)
    - Gaming detection (auto-switch to performance for games)
    - Work hours optimization (balanced mode during work)
    - Sleep schedule awareness (power-save mode at night)
    - Application priority management
    - User behavior learning

EXAMPLES:
    gpu_scheduler.sh start           # Start intelligent scheduling
    gpu_scheduler.sh add-rule blender performance  # Blender = performance mode
    gpu_scheduler.sh config          # Configure scheduler behavior
    gpu_scheduler.sh monitor         # Watch real-time decisions

OPTIONS:
    --daemon           Run as background daemon
    --interval <sec>   Check interval in seconds (default: 10)
    --verbose          Enable verbose logging
    --help             Show this help message

EOF
}

# Initialize scheduler configuration
initialize_scheduler() {
    if [ ! -f "$SCHEDULER_CONFIG" ]; then
        echo -e "${INFO} Creating scheduler configuration..."
        create_default_config
    fi
    
    if [ ! -f "$SCHEDULER_RULES" ]; then
        echo -e "${INFO} Creating default application rules..."
        create_default_rules
    fi
}

# Create default scheduler configuration
create_default_config() {
    cat > "$SCHEDULER_CONFIG" << 'EOF'
{
  "enabled": true,
  "check_interval": 10,
  "features": {
    "battery_awareness": true,
    "thermal_management": true,
    "gaming_detection": true,
    "work_hours": true,
    "sleep_schedule": true,
    "application_priority": true,
    "user_learning": true
  },
  "thresholds": {
    "battery_low": 20,
    "battery_critical": 10,
    "temp_warning": 75,
    "temp_critical": 85,
    "cpu_high": 80,
    "memory_high": 85
  },
  "schedule": {
    "work_hours": {
      "start": "09:00",
      "end": "17:00",
      "profile": "productivity"
    },
    "sleep_hours": {
      "start": "23:00",
      "end": "07:00",
      "profile": "power-save"
    }
  },
  "priorities": {
    "gaming": 100,
    "content_creation": 90,
    "development": 70,
    "productivity": 60,
    "general": 50
  },
  "learning": {
    "adaptation_rate": 0.1,
    "min_usage_time": 300,
    "confidence_threshold": 0.7
  }
}
EOF
    echo -e "${SUCCESS} Default scheduler configuration created"
}

# Create default application rules
create_default_rules() {
    cat > "$SCHEDULER_RULES" << 'EOF'
{
  "applications": {
    "steam": {
      "profile": "gaming-competitive",
      "priority": 100,
      "category": "gaming",
      "gpu_profile": "performance"
    },
    "csgo": {
      "profile": "gaming-competitive",
      "priority": 100,
      "category": "gaming",
      "gpu_profile": "performance"
    },
    "cs2": {
      "profile": "gaming-competitive",
      "priority": 100,
      "category": "gaming",
      "gpu_profile": "performance"
    },
    "valorant": {
      "profile": "gaming-competitive",
      "priority": 100,
      "category": "gaming",
      "gpu_profile": "performance"
    },
    "apex": {
      "profile": "gaming-competitive",
      "priority": 100,
      "category": "gaming",
      "gpu_profile": "performance"
    },
    "overwatch2": {
      "profile": "gaming-competitive",
      "priority": 100,
      "category": "gaming",
      "gpu_profile": "performance"
    },
    "fortnite": {
      "profile": "gaming-competitive",
      "priority": 100,
      "category": "gaming",
      "gpu_profile": "performance"
    },
    "cyberpunk2077": {
      "profile": "gaming-immersive",
      "priority": 95,
      "category": "gaming",
      "gpu_profile": "performance"
    },
    "witcher3": {
      "profile": "gaming-immersive",
      "priority": 95,
      "category": "gaming",
      "gpu_profile": "performance"
    },
    "blender": {
      "profile": "content-creation",
      "priority": 90,
      "category": "creative",
      "gpu_profile": "performance"
    },
    "davinci-resolve": {
      "profile": "content-creation",
      "priority": 90,
      "category": "creative",
      "gpu_profile": "performance"
    },
    "obs": {
      "profile": "streaming",
      "priority": 85,
      "category": "content",
      "gpu_profile": "hybrid"
    },
    "obs-studio": {
      "profile": "streaming",
      "priority": 85,
      "category": "content",
      "gpu_profile": "hybrid"
    },
    "code": {
      "profile": "development",
      "priority": 70,
      "category": "work",
      "gpu_profile": "integrated"
    },
    "intellij": {
      "profile": "development",
      "priority": 70,
      "category": "work",
      "gpu_profile": "integrated"
    },
    "pycharm": {
      "profile": "development",
      "priority": 70,
      "category": "work",
      "gpu_profile": "integrated"
    },
    "firefox": {
      "profile": "productivity",
      "priority": 60,
      "category": "work",
      "gpu_profile": "balanced"
    },
    "chrome": {
      "profile": "productivity",
      "priority": 60,
      "category": "work",
      "gpu_profile": "balanced"
    },
    "libreoffice": {
      "profile": "productivity",
      "priority": 60,
      "category": "work",
      "gpu_profile": "integrated"
    },
    "gimp": {
      "profile": "content-creation",
      "priority": 80,
      "category": "creative",
      "gpu_profile": "discrete"
    },
    "krita": {
      "profile": "content-creation",
      "priority": 80,
      "category": "creative",
      "gpu_profile": "discrete"
    },
    "inkscape": {
      "profile": "content-creation",
      "priority": 75,
      "category": "creative",
      "gpu_profile": "discrete"
    },
    "python": {
      "profile": "ai-workload",
      "priority": 85,
      "category": "compute",
      "gpu_profile": "performance"
    },
    "jupyter": {
      "profile": "ai-workload",
      "priority": 85,
      "category": "compute",
      "gpu_profile": "performance"
    }
  },
  "categories": {
    "gaming": {
      "default_profile": "gaming-competitive",
      "gpu_profile": "performance"
    },
    "creative": {
      "default_profile": "content-creation",
      "gpu_profile": "discrete"
    },
    "work": {
      "default_profile": "productivity",
      "gpu_profile": "balanced"
    },
    "compute": {
      "default_profile": "ai-workload",
      "gpu_profile": "performance"
    },
    "content": {
      "default_profile": "streaming",
      "gpu_profile": "hybrid"
    }
  }
}
EOF
    echo -e "${SUCCESS} Default application rules created"
}

# Get current system state
get_system_state() {
    local state="{}"
    
    # Battery information
    local battery_level=100
    local battery_status="unknown"
    if [ -d "/sys/class/power_supply" ]; then
        for battery in /sys/class/power_supply/BAT*; do
            if [ -f "$battery/capacity" ]; then
                battery_level=$(cat "$battery/capacity" 2>/dev/null || echo "100")
                battery_status=$(cat "$battery/status" 2>/dev/null || echo "unknown")
                break
            fi
        done
    fi
    
    # Temperature information
    local cpu_temp=0
    local gpu_temp=0
    
    # CPU temperature
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        cpu_temp=$(($(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0") / 1000))
    fi
    
    # GPU temperature (NVIDIA)
    if command -v nvidia-smi > /dev/null 2>&1; then
        gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "0")
    fi
    
    # System load
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1)
    local memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    
    # Current time
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    local current_time="${current_hour}:${current_minute}"
    
    # Build state JSON
    state=$(jq -n \
        --argjson battery_level "$battery_level" \
        --arg battery_status "$battery_status" \
        --argjson cpu_temp "$cpu_temp" \
        --argjson gpu_temp "$gpu_temp" \
        --argjson cpu_usage "${cpu_usage:-0}" \
        --argjson memory_usage "$memory_usage" \
        --argjson load_avg "${load_avg:-0}" \
        --arg current_time "$current_time" \
        '{
            battery: {
                level: $battery_level,
                status: $battery_status
            },
            temperature: {
                cpu: $cpu_temp,
                gpu: $gpu_temp
            },
            load: {
                cpu: $cpu_usage,
                memory: $memory_usage,
                avg: $load_avg
            },
            time: $current_time
        }')
    
    echo "$state"
}

# Get running applications
get_running_applications() {
    local apps=()
    
    # Get process list
    while IFS= read -r line; do
        local pid=$(echo "$line" | awk '{print $1}')
        local cmd=$(echo "$line" | awk '{print $11}' | xargs basename 2>/dev/null || echo "unknown")
        
        # Filter out system processes and add to apps
        if [[ "$cmd" != "unknown" && "$cmd" != "[kthreadd]" && ! "$cmd" =~ ^\[ ]]; then
            apps+=("$cmd")
        fi
    done < <(ps aux --no-headers | tail -n +2)
    
    # Remove duplicates and output as JSON array
    printf '%s\n' "${apps[@]}" | sort -u | jq -R . | jq -s .
}

# Determine optimal profile based on current state
determine_optimal_profile() {
    local system_state="$1"
    local running_apps="$2"
    
    initialize_scheduler
    
    local config=$(cat "$SCHEDULER_CONFIG")
    local rules=$(cat "$SCHEDULER_RULES")
    
    # Check if scheduler is enabled
    local enabled=$(echo "$config" | jq -r '.enabled')
    if [ "$enabled" != "true" ]; then
        echo "balanced"
        return
    fi
    
    # Get thresholds
    local battery_low=$(echo "$config" | jq -r '.thresholds.battery_low')
    local temp_critical=$(echo "$config" | jq -r '.thresholds.temp_critical')
    local battery_level=$(echo "$system_state" | jq -r '.battery.level')
    local cpu_temp=$(echo "$system_state" | jq -r '.temperature.cpu')
    local gpu_temp=$(echo "$system_state" | jq -r '.temperature.gpu')
    local current_time=$(echo "$system_state" | jq -r '.time')
    
    # Critical conditions override everything
    if [ "$battery_level" -le 10 ]; then
        echo "battery-extreme"
        return
    fi
    
    if [ "$cpu_temp" -ge "$temp_critical" ] || [ "$gpu_temp" -ge "$temp_critical" ]; then
        echo "power-save"
        return
    fi
    
    # Sleep schedule
    local sleep_enabled=$(echo "$config" | jq -r '.features.sleep_schedule')
    if [ "$sleep_enabled" = "true" ]; then
        local sleep_start=$(echo "$config" | jq -r '.schedule.sleep_hours.start')
        local sleep_end=$(echo "$config" | jq -r '.schedule.sleep_hours.end')
        local sleep_profile=$(echo "$config" | jq -r '.schedule.sleep_hours.profile')
        
        if is_time_in_range "$current_time" "$sleep_start" "$sleep_end"; then
            echo "$sleep_profile"
            return
        fi
    fi
    
    # Battery awareness
    local battery_enabled=$(echo "$config" | jq -r '.features.battery_awareness')
    if [ "$battery_enabled" = "true" ] && [ "$battery_level" -le "$battery_low" ]; then
        echo "power-save"
        return
    fi
    
    # Application-based detection
    local highest_priority=0
    local best_profile="balanced"
    
    echo "$running_apps" | jq -r '.[]' | while read -r app; do
        local app_rule=$(echo "$rules" | jq -r ".applications[\"$app\"] // empty")
        if [ -n "$app_rule" ] && [ "$app_rule" != "null" ]; then
            local priority=$(echo "$app_rule" | jq -r '.priority')
            local profile=$(echo "$app_rule" | jq -r '.profile')
            
            if [ "$priority" -gt "$highest_priority" ]; then
                highest_priority="$priority"
                best_profile="$profile"
            fi
        fi
    done
    
    # If no specific application found, check categories
    if [ "$highest_priority" -eq 0 ]; then
        # Work hours detection
        local work_enabled=$(echo "$config" | jq -r '.features.work_hours')
        if [ "$work_enabled" = "true" ]; then
            local work_start=$(echo "$config" | jq -r '.schedule.work_hours.start')
            local work_end=$(echo "$config" | jq -r '.schedule.work_hours.end')
            local work_profile=$(echo "$config" | jq -r '.schedule.work_hours.profile')
            
            if is_time_in_range "$current_time" "$work_start" "$work_end"; then
                best_profile="$work_profile"
            fi
        fi
    fi
    
    echo "$best_profile"
}

# Check if time is in range
is_time_in_range() {
    local current="$1"
    local start="$2"
    local end="$3"
    
    # Convert times to minutes since midnight
    local current_min=$(($(echo "$current" | cut -d: -f1) * 60 + $(echo "$current" | cut -d: -f2)))
    local start_min=$(($(echo "$start" | cut -d: -f1) * 60 + $(echo "$start" | cut -d: -f2)))
    local end_min=$(($(echo "$end" | cut -d: -f1) * 60 + $(echo "$end" | cut -d: -f2)))
    
    # Handle overnight ranges
    if [ "$start_min" -gt "$end_min" ]; then
        # Overnight range (e.g., 23:00 to 07:00)
        [ "$current_min" -ge "$start_min" ] || [ "$current_min" -le "$end_min" ]
    else
        # Same day range (e.g., 09:00 to 17:00)
        [ "$current_min" -ge "$start_min" ] && [ "$current_min" -le "$end_min" ]
    fi
}

# Start the scheduler daemon
start_scheduler() {
    local interval="${1:-10}"
    local daemon_mode="${2:-false}"
    
    echo -e "${INFO} Starting GPU scheduler with ${interval}s interval..."
    
    # Check if already running
    if [ -f "$SCHEDULER_STATE" ]; then
        local pid=$(cat "$SCHEDULER_STATE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${WARNING} Scheduler already running (PID: $pid)"
            return 0
        else
            rm -f "$SCHEDULER_STATE"
        fi
    fi
    
    initialize_scheduler
    
    # Start scheduler loop
    if [ "$daemon_mode" = "true" ]; then
        nohup bash -c "scheduler_loop $interval" > /dev/null 2>&1 &
        local scheduler_pid=$!
        echo "$scheduler_pid" > "$SCHEDULER_STATE"
        echo -e "${SUCCESS} GPU scheduler started as daemon (PID: $scheduler_pid)"
    else
        echo "$$" > "$SCHEDULER_STATE"
        echo -e "${SUCCESS} GPU scheduler started (PID: $$)"
        scheduler_loop "$interval"
    fi
}

# Main scheduler loop
scheduler_loop() {
    local interval="$1"
    local last_profile=""
    local switch_count=0
    
    log "Scheduler started with ${interval}s interval"
    
    while true; do
        # Get current state
        local system_state=$(get_system_state)
        local running_apps=$(get_running_applications)
        local optimal_profile=$(determine_optimal_profile "$system_state" "$running_apps")
        
        # Check if profile change is needed
        if [ "$optimal_profile" != "$last_profile" ] && [ -n "$optimal_profile" ]; then
            echo -e "${INFO} Switching to profile: ${CYAN}$optimal_profile${NC}"
            log "Profile switch: $last_profile -> $optimal_profile"
            
            # Apply the profile
            if "$SCRIPT_DIR/gpu_presets.sh" apply "$optimal_profile" --force >/dev/null 2>&1; then
                last_profile="$optimal_profile"
                switch_count=$((switch_count + 1))
                echo -e "${SUCCESS} Applied profile: $optimal_profile"
                log "Successfully applied profile: $optimal_profile"
            else
                echo -e "${ERROR} Failed to apply profile: $optimal_profile"
                log "Failed to apply profile: $optimal_profile"
            fi
        fi
        
        # Sleep for interval
        sleep "$interval"
    done
}

# Stop scheduler
stop_scheduler() {
    if [ ! -f "$SCHEDULER_STATE" ]; then
        echo -e "${WARNING} Scheduler is not running"
        return 0
    fi
    
    local pid=$(cat "$SCHEDULER_STATE" 2>/dev/null || echo "")
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        rm -f "$SCHEDULER_STATE"
        echo -e "${SUCCESS} GPU scheduler stopped (PID: $pid)"
        log "Scheduler stopped"
    else
        rm -f "$SCHEDULER_STATE"
        echo -e "${WARNING} Scheduler was not running"
    fi
}

# Show scheduler status
show_status() {
    echo -e "${INFO} GPU Scheduler Status:"
    echo
    
    # Check if running
    if [ -f "$SCHEDULER_STATE" ]; then
        local pid=$(cat "$SCHEDULER_STATE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "  Status: ${GREEN}Running${NC} (PID: $pid)"
            
            # Show uptime
            local start_time=$(ps -o lstart= -p "$pid" 2>/dev/null || echo "unknown")
            echo -e "  Started: ${CYAN}$start_time${NC}"
        else
            echo -e "  Status: ${RED}Stopped${NC} (stale PID file)"
            rm -f "$SCHEDULER_STATE"
        fi
    else
        echo -e "  Status: ${RED}Stopped${NC}"
    fi
    
    # Show current system state
    echo
    echo -e "${CYAN}Current System State:${NC}"
    local state=$(get_system_state)
    echo "  Battery: $(echo "$state" | jq -r '.battery.level')% ($(echo "$state" | jq -r '.battery.status'))"
    echo "  CPU Temp: $(echo "$state" | jq -r '.temperature.cpu')°C"
    echo "  GPU Temp: $(echo "$state" | jq -r '.temperature.gpu')°C"
    echo "  CPU Usage: $(echo "$state" | jq -r '.load.cpu')%"
    echo "  Memory: $(echo "$state" | jq -r '.load.memory')%"
    echo "  Time: $(echo "$state" | jq -r '.time')"
    echo
    
    # Show running applications
    echo -e "${CYAN}Monitored Applications:${NC}"
    local apps=$(get_running_applications)
    local rules=$(cat "$SCHEDULER_RULES" 2>/dev/null || echo '{"applications":{}}')
    
    echo "$apps" | jq -r '.[]' | while read -r app; do
        local rule=$(echo "$rules" | jq -r ".applications[\"$app\"] // empty")
        if [ -n "$rule" ] && [ "$rule" != "null" ]; then
            local profile=$(echo "$rule" | jq -r '.profile')
            local priority=$(echo "$rule" | jq -r '.priority')
            echo -e "  ${GREEN}$app${NC} -> $profile (priority: $priority)"
        fi
    done
    
    # Show current optimal profile
    echo
    local optimal=$(determine_optimal_profile "$state" "$apps")
    echo -e "  ${CYAN}Optimal Profile:${NC} $optimal"
    
    # Show active preset
    if [ -f "$CONFIG_DIR/gpu_presets/active_preset" ]; then
        local active=$(cat "$CONFIG_DIR/gpu_presets/active_preset")
        echo -e "  ${CYAN}Active Preset:${NC} $active"
    fi
}

# Monitor scheduler in real-time
monitor_scheduler() {
    echo -e "${INFO} GPU Scheduler Real-time Monitor"
    echo -e "${INFO} Press ${CYAN}Ctrl+C${NC} to exit"
    echo
    
    while true; do
        clear
        echo -e "${CYAN}=== HyprSupreme GPU Scheduler Monitor ===${NC}"
        echo -e "$(date '+%Y-%m-%d %H:%M:%S')"
        echo
        
        # Show scheduler status
        show_status
        
        sleep 5
    done
}

# Main function
main() {
    case "${1:-}" in
        "start")
            local interval="${2:-10}"
            local daemon_flag=false
            if [ "${3:-}" = "--daemon" ]; then
                daemon_flag=true
            fi
            start_scheduler "$interval" "$daemon_flag"
            ;;
        "stop")
            stop_scheduler
            ;;
        "status")
            show_status
            ;;
        "monitor")
            monitor_scheduler
            ;;
        "test")
            local state=$(get_system_state)
            local apps=$(get_running_applications)
            local optimal=$(determine_optimal_profile "$state" "$apps")
            echo -e "${INFO} Test mode - would switch to: ${CYAN}$optimal${NC}"
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

