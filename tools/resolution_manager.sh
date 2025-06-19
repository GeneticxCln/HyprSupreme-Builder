#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme Resolution Manager
# Comprehensive resolution and scaling function library

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration paths
HYPR_CONFIG="$HOME/.config/hypr"
MONITORS_CONFIG="$HYPR_CONFIG/monitors.conf"
BACKUP_DIR="$HYPR_CONFIG/backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Utility functions
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Backup current configuration
backup_config() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    if [ -f "$MONITORS_CONFIG" ]; then
        cp "$MONITORS_CONFIG" "$BACKUP_DIR/monitors_${timestamp}.conf"
        print_info "Backup created: monitors_${timestamp}.conf"
    fi
}

# Apply monitor configuration
apply_monitor_config() {
    local monitor="$1"
    local resolution="$2"
    local refresh="$3"
    local position="$4"
    local scale="$5"
    
    backup_config
    
    # Create or update monitors.conf
    cat > "$MONITORS_CONFIG" << EOF
# HyprSupreme Auto-Generated Monitor Configuration
# Generated on $(date)
# Monitor: $monitor, Resolution: $resolution, Refresh: $refresh, Position: $position, Scale: $scale

monitor = $monitor, ${resolution}@${refresh}, $position, $scale
EOF
    
    # Apply configuration
    if command -v hyprctl &> /dev/null; then
        hyprctl keyword monitor "$monitor,${resolution}@${refresh},$position,$scale"
        print_success "Monitor configuration applied: $monitor at ${resolution}@${refresh}Hz, ${scale}x scale"
    else
        print_warning "hyprctl not found. Configuration saved but not applied."
    fi
}

# Get available monitors
get_monitors() {
    if command -v hyprctl &> /dev/null; then
        hyprctl monitors | grep -E "Monitor.*:" | cut -d' ' -f2
    else
        echo "Unable to detect monitors (hyprctl not available)"
    fi
}

# Detect current monitor
detect_primary_monitor() {
    if command -v hyprctl &> /dev/null; then
        hyprctl monitors | head -1 | grep -o 'Monitor [^:]*' | cut -d' ' -f2
    else
        echo "eDP-1"  # Default fallback
    fi
}

# ===========================================
# STANDARD DESKTOP RESOLUTIONS
# ===========================================

# 1080p Functions
res_1080p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "1920x1080" "60" "auto" "$scale"
}

res_1080p_75() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "1920x1080" "75" "auto" "$scale"
}

res_1080p_120() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "1920x1080" "120" "auto" "$scale"
}

res_1080p_144() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "1920x1080" "144" "auto" "$scale"
}

res_1080p_165() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "1920x1080" "165" "auto" "$scale"
}

res_1080p_240() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "1920x1080" "240" "auto" "$scale"
}

# 1440p Functions (QHD)
res_1440p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "2560x1440" "60" "auto" "$scale"
}

res_1440p_75() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "2560x1440" "75" "auto" "$scale"
}

res_1440p_120() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "2560x1440" "120" "auto" "$scale"
}

res_1440p_144() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "2560x1440" "144" "auto" "$scale"
}

res_1440p_165() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "2560x1440" "165" "auto" "$scale"
}

res_1440p_240() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "2560x1440" "240" "auto" "$scale"
}

# 4K Functions (UHD)
res_4k_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.5}"
    apply_monitor_config "$monitor" "3840x2160" "60" "auto" "$scale"
}

res_4k_75() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.5}"
    apply_monitor_config "$monitor" "3840x2160" "75" "auto" "$scale"
}

res_4k_120() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.5}"
    apply_monitor_config "$monitor" "3840x2160" "120" "auto" "$scale"
}

res_4k_144() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.5}"
    apply_monitor_config "$monitor" "3840x2160" "144" "auto" "$scale"
}

# ===========================================
# ULTRAWIDE RESOLUTIONS
# ===========================================

# 21:9 Ultrawide Functions
res_ultrawide_1080p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "2560x1080" "60" "auto" "$scale"
}

res_ultrawide_1080p_75() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "2560x1080" "75" "auto" "$scale"
}

res_ultrawide_1080p_144() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "2560x1080" "144" "auto" "$scale"
}

res_ultrawide_1440p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "3440x1440" "60" "auto" "$scale"
}

res_ultrawide_1440p_75() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "3440x1440" "75" "auto" "$scale"
}

res_ultrawide_1440p_100() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "3440x1440" "100" "auto" "$scale"
}

res_ultrawide_1440p_120() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "3440x1440" "120" "auto" "$scale"
}

res_ultrawide_1440p_165() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "3440x1440" "165" "auto" "$scale"
}

# 32:9 Super Ultrawide Functions
res_super_ultrawide_1080p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "3840x1080" "60" "auto" "$scale"
}

res_super_ultrawide_1080p_120() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "3840x1080" "120" "auto" "$scale"
}

res_super_ultrawide_1440p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "5120x1440" "60" "auto" "$scale"
}

res_super_ultrawide_1440p_120() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "5120x1440" "120" "auto" "$scale"
}

# ===========================================
# LAPTOP RESOLUTIONS
# ===========================================

# Common Laptop Resolutions
res_laptop_768p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "1366x768" "60" "auto" "$scale"
}

res_laptop_900p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "1600x900" "60" "auto" "$scale"
}

res_laptop_1080p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "1920x1080" "60" "auto" "$scale"
}

res_laptop_1440p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.5}"
    apply_monitor_config "$monitor" "2560x1440" "60" "auto" "$scale"
}

res_laptop_4k_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-2}"
    apply_monitor_config "$monitor" "3840x2160" "60" "auto" "$scale"
}

# ===========================================
# PROFESSIONAL/CREATIVE RESOLUTIONS
# ===========================================

# 16:10 Professional Monitors
res_pro_1200p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1}"
    apply_monitor_config "$monitor" "1920x1200" "60" "auto" "$scale"
}

res_pro_1600p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.25}"
    apply_monitor_config "$monitor" "2560x1600" "60" "auto" "$scale"
}

res_pro_1800p_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.5}"
    apply_monitor_config "$monitor" "3200x1800" "60" "auto" "$scale"
}

res_pro_4k_plus_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.75}"
    apply_monitor_config "$monitor" "3840x2400" "60" "auto" "$scale"
}

# 5K and 6K Resolutions
res_5k_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-2}"
    apply_monitor_config "$monitor" "5120x2880" "60" "auto" "$scale"
}

res_6k_60() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-2.5}"
    apply_monitor_config "$monitor" "6016x3384" "60" "auto" "$scale"
}

# ===========================================
# SCALING SPECIFIC FUNCTIONS
# ===========================================

# Fractional Scaling Presets
scale_125() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local current_res=$(hyprctl monitors | grep -A1 "$monitor" | grep -o '[0-9]*x[0-9]*@[0-9]*' | head -1)
    if [ -n "$current_res" ]; then
        local res=$(echo "$current_res" | cut -d'@' -f1)
        local refresh=$(echo "$current_res" | cut -d'@' -f2)
        apply_monitor_config "$monitor" "$res" "$refresh" "auto" "1.25"
    fi
}

scale_150() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local current_res=$(hyprctl monitors | grep -A1 "$monitor" | grep -o '[0-9]*x[0-9]*@[0-9]*' | head -1)
    if [ -n "$current_res" ]; then
        local res=$(echo "$current_res" | cut -d'@' -f1)
        local refresh=$(echo "$current_res" | cut -d'@' -f2)
        apply_monitor_config "$monitor" "$res" "$refresh" "auto" "1.5"
    fi
}

scale_175() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local current_res=$(hyprctl monitors | grep -A1 "$monitor" | grep -o '[0-9]*x[0-9]*@[0-9]*' | head -1)
    if [ -n "$current_res" ]; then
        local res=$(echo "$current_res" | cut -d'@' -f1)
        local refresh=$(echo "$current_res" | cut -d'@' -f2)
        apply_monitor_config "$monitor" "$res" "$refresh" "auto" "1.75"
    fi
}

scale_200() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local current_res=$(hyprctl monitors | grep -A1 "$monitor" | grep -o '[0-9]*x[0-9]*@[0-9]*' | head -1)
    if [ -n "$current_res" ]; then
        local res=$(echo "$current_res" | cut -d'@' -f1)
        local refresh=$(echo "$current_res" | cut -d'@' -f2)
        apply_monitor_config "$monitor" "$res" "$refresh" "auto" "2.0"
    fi
}

# ===========================================
# MULTI-MONITOR FUNCTIONS
# ===========================================

# Dual Monitor Setups
dual_1080p_side_by_side() {
    local monitor1="${1:-$(detect_primary_monitor)}"
    local monitor2="${2:-HDMI-A-1}"
    backup_config
    
    cat > "$MONITORS_CONFIG" << EOF
# Dual 1080p Side-by-Side Configuration
monitor = $monitor1, 1920x1080@60, 0x0, 1
monitor = $monitor2, 1920x1080@60, 1920x0, 1
EOF
    
    if command -v hyprctl &> /dev/null; then
        hyprctl keyword monitor "$monitor1,1920x1080@60,0x0,1"
        hyprctl keyword monitor "$monitor2,1920x1080@60,1920x0,1"
    fi
    print_success "Dual 1080p side-by-side configuration applied"
}

dual_mixed_laptop_external() {
    local laptop="${1:-eDP-1}"
    local external="${2:-HDMI-A-1}"
    local laptop_scale="${3:-1.25}"
    local external_scale="${4:-1}"
    
    backup_config
    
    cat > "$MONITORS_CONFIG" << EOF
# Laptop + External Monitor Configuration
monitor = $laptop, 1920x1080@60, 0x0, $laptop_scale
monitor = $external, 1920x1080@60, 1920x0, $external_scale
EOF
    
    if command -v hyprctl &> /dev/null; then
        hyprctl keyword monitor "$laptop,1920x1080@60,0x0,$laptop_scale"
        hyprctl keyword monitor "$external,1920x1080@60,1920x0,$external_scale"
    fi
    print_success "Laptop + External monitor configuration applied"
}

# Triple Monitor Setup
triple_monitor_setup() {
    local center="${1:-DP-1}"
    local left="${2:-DP-2}"
    local right="${3:-HDMI-A-1}"
    
    backup_config
    
    cat > "$MONITORS_CONFIG" << EOF
# Triple Monitor Configuration
monitor = $left, 1920x1080@60, 0x0, 1
monitor = $center, 2560x1440@144, 1920x0, 1.25
monitor = $right, 1920x1080@60, 4480x0, 1
EOF
    
    if command -v hyprctl &> /dev/null; then
        hyprctl keyword monitor "$left,1920x1080@60,0x0,1"
        hyprctl keyword monitor "$center,2560x1440@144,1920x0,1.25"
        hyprctl keyword monitor "$right,1920x1080@60,4480x0,1"
    fi
    print_success "Triple monitor configuration applied"
}

# ===========================================
# UTILITY FUNCTIONS
# ===========================================

# List all available functions
list_functions() {
    echo -e "${BLUE}Available Resolution Functions:${NC}"
    echo
    echo -e "${GREEN}Standard Desktop Resolutions:${NC}"
    echo "  res_1080p_60, res_1080p_75, res_1080p_120, res_1080p_144, res_1080p_165, res_1080p_240"
    echo "  res_1440p_60, res_1440p_75, res_1440p_120, res_1440p_144, res_1440p_165, res_1440p_240"
    echo "  res_4k_60, res_4k_75, res_4k_120, res_4k_144"
    echo
    echo -e "${GREEN}Ultrawide Resolutions:${NC}"
    echo "  res_ultrawide_1080p_60, res_ultrawide_1080p_75, res_ultrawide_1080p_144"
    echo "  res_ultrawide_1440p_60, res_ultrawide_1440p_75, res_ultrawide_1440p_100, res_ultrawide_1440p_120, res_ultrawide_1440p_165"
    echo "  res_super_ultrawide_1080p_60, res_super_ultrawide_1080p_120"
    echo "  res_super_ultrawide_1440p_60, res_super_ultrawide_1440p_120"
    echo
    echo -e "${GREEN}Laptop Resolutions:${NC}"
    echo "  res_laptop_768p_60, res_laptop_900p_60, res_laptop_1080p_60, res_laptop_1440p_60, res_laptop_4k_60"
    echo
    echo -e "${GREEN}Professional Resolutions:${NC}"
    echo "  res_pro_1200p_60, res_pro_1600p_60, res_pro_1800p_60, res_pro_4k_plus_60"
    echo "  res_5k_60, res_6k_60"
    echo
    echo -e "${GREEN}Scaling Functions:${NC}"
    echo "  scale_125, scale_150, scale_175, scale_200"
    echo
    echo -e "${GREEN}Multi-Monitor Functions:${NC}"
    echo "  dual_1080p_side_by_side, dual_mixed_laptop_external, triple_monitor_setup"
    echo
    echo -e "${GREEN}Utility Functions:${NC}"
    echo "  list_functions, show_current_config, restore_backup, auto_detect_optimal"
}

# Show current configuration
show_current_config() {
    if command -v hyprctl &> /dev/null; then
        echo -e "${BLUE}Current Monitor Configuration:${NC}"
        hyprctl monitors
    else
        print_warning "hyprctl not available. Cannot show current configuration."
    fi
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    if [ -z "$backup_file" ]; then
        echo -e "${BLUE}Available backups:${NC}"
        ls -la "$BACKUP_DIR"/monitors_*.conf 2>/dev/null || echo "No backups found"
        return
    fi
    
    if [ -f "$BACKUP_DIR/$backup_file" ]; then
        cp "$BACKUP_DIR/$backup_file" "$MONITORS_CONFIG"
        print_success "Configuration restored from $backup_file"
    else
        print_error "Backup file not found: $backup_file"
    fi
}

# Auto-detect optimal resolution
auto_detect_optimal() {
    local monitor="${1:-$(detect_primary_monitor)}"
    
    if command -v hyprctl &> /dev/null; then
        local current_info=$(hyprctl monitors | grep -A10 "$monitor")
        local resolution=$(echo "$current_info" | grep -o '[0-9]*x[0-9]*' | head -1)
        
        print_info "Detected monitor: $monitor"
        print_info "Current resolution: $resolution"
        
        # Auto-suggest based on resolution
        case "$resolution" in
            "1920x1080")
                print_info "Suggested: res_1080p_144 for gaming or res_1080p_60 for standard use"
                ;;
            "2560x1440")
                print_info "Suggested: res_1440p_144 with 1.25x scaling"
                ;;
            "3840x2160")
                print_info "Suggested: res_4k_60 with 1.5x scaling"
                ;;
            "3440x1440")
                print_info "Suggested: res_ultrawide_1440p_120 with 1.25x scaling"
                ;;
            *)
                print_info "Custom resolution detected. Use manual configuration."
                ;;
        esac
    else
        print_warning "Cannot auto-detect without hyprctl"
    fi
}

# Main function for CLI usage
main() {
    case "$1" in
        "list"|"help")
            list_functions
            ;;
        "current"|"status")
            show_current_config
            ;;
        "backup")
            restore_backup "$2"
            ;;
        "auto"|"detect")
            auto_detect_optimal "$2"
            ;;
        *)
            if [ -n "$1" ] && type "$1" &>/dev/null; then
                "$@"
            else
                echo "Usage: $0 [function_name] [arguments]"
                echo "       $0 list    - Show all available functions"
                echo "       $0 current - Show current configuration"
                echo "       $0 auto    - Auto-detect optimal settings"
                echo
                echo "Example: $0 res_1440p_144 DP-1 1.25"
            fi
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

