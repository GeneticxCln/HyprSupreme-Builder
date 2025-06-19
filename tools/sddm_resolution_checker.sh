#!/bin/bash
# HyprSupreme SDDM Resolution Checker and Fixer
# Detects and fixes display resolution issues for SDDM login screen

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration files
SDDM_CONF="/etc/sddm.conf"
SDDM_XSETUP="/usr/share/sddm/scripts/Xsetup"
BACKUP_DIR="/etc/sddm.conf.d/hyprsupreme-backups"

# Create backup directory
sudo mkdir -p "$BACKUP_DIR"

show_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║           🖥️  SDDM RESOLUTION CHECKER & FIXER 🖥️            ║"
    echo "║                                                               ║"
    echo "║              HyprSupreme-Builder Resolution Tool              ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Detect current system resolution
detect_current_resolution() {
    log_info "Detecting current display resolution..."
    
    local resolution=""
    local refresh_rate="60"
    local method=""
    
    # Method 1: xrandr (most reliable for X11)
    if command -v xrandr &> /dev/null; then
        local xrandr_output=$(xrandr --query 2>/dev/null | grep -E "connected primary|connected.*[0-9]+x[0-9]+" | head -1)
        if [[ -n "$xrandr_output" ]]; then
            resolution=$(echo "$xrandr_output" | grep -o '[0-9]\+x[0-9]\+' | head -1)
            refresh_rate=$(echo "$xrandr_output" | grep -o '[0-9]\+\.[0-9]\+\*' | sed 's/\*$//' | head -1)
            [[ -z "$refresh_rate" ]] && refresh_rate="60"
            method="xrandr"
        fi
    fi
    
    # Method 2: Wayland tools
    if [[ -z "$resolution" ]] && command -v wlr-randr &> /dev/null; then
        local wlr_output=$(wlr-randr 2>/dev/null | grep "current" | head -1)
        if [[ -n "$wlr_output" ]]; then
            resolution=$(echo "$wlr_output" | grep -o '[0-9]\+x[0-9]\+')
            refresh_rate=$(echo "$wlr_output" | grep -o '[0-9]\+\.[0-9]\+' | head -1)
            [[ -z "$refresh_rate" ]] && refresh_rate="60"
            method="wlr-randr"
        fi
    fi
    
    # Method 3: DRM modes
    if [[ -z "$resolution" ]]; then
        for mode_file in /sys/class/drm/card*/card*-*/modes; do
            if [[ -r "$mode_file" ]]; then
                resolution=$(head -1 "$mode_file" 2>/dev/null)
                method="drm"
                break
            fi
        done
    fi
    
    # Method 4: EDID parsing
    if [[ -z "$resolution" ]]; then
        for edid_file in /sys/class/drm/card*/card*-*/edid; do
            if [[ -r "$edid_file" ]] && command -v edid-decode &> /dev/null; then
                local edid_output=$(edid-decode "$edid_file" 2>/dev/null | grep "Detailed Timing Descriptors" -A 20 | grep -o '[0-9]\+x[0-9]\+' | head -1)
                if [[ -n "$edid_output" ]]; then
                    resolution="$edid_output"
                    method="edid"
                    break
                fi
            fi
        done
    fi
    
    # Fallback
    if [[ -z "$resolution" ]]; then
        resolution="1920x1080"
        method="fallback"
        log_warning "Could not detect resolution, using fallback: $resolution"
    else
        log_success "Detected resolution: $resolution @ ${refresh_rate}Hz (method: $method)"
    fi
    
    echo "$resolution:$refresh_rate:$method"
}

# Get display information
get_display_info() {
    log_info "Gathering display information..."
    
    echo "=== DISPLAY HARDWARE ==="
    
    # GPU information
    if command -v lspci &> /dev/null; then
        echo "GPU: $(lspci | grep -E 'VGA|3D|Display' | head -1)"
    fi
    
    # Monitor information
    if command -v xrandr &> /dev/null; then
        echo "=== CONNECTED DISPLAYS ==="
        xrandr --query | grep -E "connected|disconnected" | while read line; do
            echo "  $line"
        done
        
        echo "=== AVAILABLE MODES ==="
        xrandr --query | grep -A 20 "connected" | grep "   [0-9]" | head -10
    fi
    
    # Current resolution detection
    local res_info=$(detect_current_resolution)
    local current_res=$(echo "$res_info" | cut -d: -f1)
    local current_refresh=$(echo "$res_info" | cut -d: -f2)
    local detection_method=$(echo "$res_info" | cut -d: -f3)
    
    echo "=== CURRENT SETUP ==="
    echo "Resolution: $current_res"
    echo "Refresh Rate: ${current_refresh}Hz"
    echo "Detection Method: $detection_method"
    
    # DPI calculation
    if [[ "$current_res" =~ ([0-9]+)x([0-9]+) ]]; then
        local width=${BASH_REMATCH[1]}
        local height=${BASH_REMATCH[2]}
        
        case "$current_res" in
            "3840x2160"|"3200x1800")
                echo "Recommended DPI: 144 (4K/High-DPI)"
                echo "Recommended Scale: 1.5x"
                ;;
            "2560x1440")
                echo "Recommended DPI: 120 (QHD)"
                echo "Recommended Scale: 1.25x"
                ;;
            "1920x1080")
                echo "Recommended DPI: 96 (Standard HD)"
                echo "Recommended Scale: 1.0x"
                ;;
            "1366x768")
                echo "Recommended DPI: 84 (Laptop)"
                echo "Recommended Scale: 1.0x"
                ;;
            *)
                echo "Recommended DPI: 96 (Standard)"
                echo "Recommended Scale: 1.0x"
                ;;
        esac
    fi
}

# Check current SDDM configuration
check_sddm_config() {
    log_info "Checking current SDDM configuration..."
    
    if [[ ! -f "$SDDM_CONF" ]]; then
        log_warning "SDDM configuration file not found: $SDDM_CONF"
        return 1
    fi
    
    echo "=== CURRENT SDDM CONFIG ==="
    
    # Check ServerArguments
    local server_args=$(grep "^ServerArguments" "$SDDM_CONF" 2>/dev/null || echo "ServerArguments not set")
    echo "Server Arguments: $server_args"
    
    # Check theme
    local theme=$(grep "^Current=" "$SDDM_CONF" 2>/dev/null | cut -d= -f2 || echo "No theme set")
    echo "Current Theme: $theme"
    
    # Check if HiDPI is enabled
    local hidpi=$(grep -i "hidpi\|dpi\|scale" "$SDDM_CONF" 2>/dev/null || echo "No HiDPI settings found")
    if [[ "$hidpi" != "No HiDPI settings found" ]]; then
        echo "HiDPI Settings: $hidpi"
    else
        echo "HiDPI Settings: Not configured"
    fi
    
    # Check Xsetup script
    if [[ -f "$SDDM_XSETUP" ]]; then
        echo "Xsetup Script: Exists"
        if grep -q "xrandr\|resolution\|dpi" "$SDDM_XSETUP" 2>/dev/null; then
            echo "Xsetup has resolution settings: Yes"
        else
            echo "Xsetup has resolution settings: No"
        fi
    else
        echo "Xsetup Script: Not found"
    fi
}

# Fix SDDM resolution issues
fix_sddm_resolution() {
    log_info "Fixing SDDM resolution configuration..."
    
    # Backup current config
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    sudo cp "$SDDM_CONF" "$BACKUP_DIR/sddm.conf.backup.$timestamp" 2>/dev/null
    
    # Get current resolution
    local res_info=$(detect_current_resolution)
    local resolution=$(echo "$res_info" | cut -d: -f1)
    local refresh_rate=$(echo "$res_info" | cut -d: -f2)
    
    # Calculate DPI
    local dpi="96"
    case "$resolution" in
        "3840x2160"|"3200x1800")
            dpi="144"
            ;;
        "2560x1440")
            dpi="120"
            ;;
        "1920x1080")
            dpi="96"
            ;;
        "1366x768")
            dpi="84"
            ;;
    esac
    
    log_info "Configuring SDDM for $resolution @ ${refresh_rate}Hz with ${dpi} DPI"
    
    # Update SDDM configuration
    local temp_conf=$(mktemp)
    
    # Read existing config or create new one
    if [[ -f "$SDDM_CONF" ]]; then
        cp "$SDDM_CONF" "$temp_conf"
    else
        echo "# HyprSupreme SDDM Configuration" > "$temp_conf"
    fi
    
    # Update or add ServerArguments
    if grep -q "^ServerArguments" "$temp_conf"; then
        sed -i "s/^ServerArguments=.*/ServerArguments=-nolisten tcp -dpi $dpi/" "$temp_conf"
    else
        echo "" >> "$temp_conf"
        echo "[X11]" >> "$temp_conf"
        echo "ServerArguments=-nolisten tcp -dpi $dpi" >> "$temp_conf"
    fi
    
    # Ensure X11 section exists and is properly configured
    if ! grep -q "^\[X11\]" "$temp_conf"; then
        echo "" >> "$temp_conf"
        echo "[X11]" >> "$temp_conf"
    fi
    
    # Update configuration
    sudo cp "$temp_conf" "$SDDM_CONF"
    rm "$temp_conf"
    
    # Create/update Xsetup script for additional resolution settings
    create_xsetup_script "$resolution" "$refresh_rate" "$dpi"
    
    log_success "SDDM configuration updated for $resolution"
}

# Create Xsetup script for resolution management
create_xsetup_script() {
    local resolution="$1"
    local refresh_rate="$2"
    local dpi="$3"
    
    log_info "Creating SDDM Xsetup script..."
    
    # Backup existing Xsetup
    if [[ -f "$SDDM_XSETUP" ]]; then
        sudo cp "$SDDM_XSETUP" "$BACKUP_DIR/Xsetup.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create new Xsetup script
    sudo tee "$SDDM_XSETUP" > /dev/null << EOF
#!/bin/sh
# HyprSupreme SDDM Xsetup Script
# Auto-generated resolution configuration

# Set DPI
xrdb -merge << XRDB_EOF
Xft.dpi: $dpi
XRDB_EOF

# Detect and set optimal resolution
if command -v xrandr > /dev/null 2>&1; then
    # Get primary display
    PRIMARY_DISPLAY=\$(xrandr | grep "connected primary" | cut -d' ' -f1)
    
    # Fallback to first connected display
    if [ -z "\$PRIMARY_DISPLAY" ]; then
        PRIMARY_DISPLAY=\$(xrandr | grep " connected" | head -1 | cut -d' ' -f1)
    fi
    
    if [ -n "\$PRIMARY_DISPLAY" ]; then
        # Try to set the detected resolution
        xrandr --output "\$PRIMARY_DISPLAY" --mode "$resolution" --rate "$refresh_rate" 2>/dev/null || {
            # Fallback to auto mode
            xrandr --output "\$PRIMARY_DISPLAY" --auto 2>/dev/null
        }
        
        # Set DPI via xrandr as well
        xrandr --dpi "$dpi" 2>/dev/null
    fi
fi

# Additional cursor and theme setup
if [ -d /usr/share/icons/default ]; then
    xsetroot -cursor_name left_ptr
fi

# Set background color (fallback)
xsetroot -solid "#1e1e2e"

# Load any user-specific settings
if [ -f /etc/X11/Xresources ]; then
    xrdb -merge /etc/X11/Xresources
fi
EOF
    
    # Make executable
    sudo chmod +x "$SDDM_XSETUP"
    
    log_success "SDDM Xsetup script created"
}

# Test SDDM configuration
test_sddm_config() {
    log_info "Testing SDDM configuration..."
    
    # Check if SDDM service is enabled
    if systemctl is-enabled sddm &> /dev/null; then
        log_success "SDDM service is enabled"
    else
        log_warning "SDDM service is not enabled"
        echo "To enable: sudo systemctl enable sddm"
    fi
    
    # Check if SDDM is active
    if systemctl is-active sddm &> /dev/null; then
        log_info "SDDM is currently running"
    else
        log_info "SDDM is not currently running"
    fi
    
    # Validate configuration syntax
    if sddm --test-mode --config "$SDDM_CONF" &> /dev/null; then
        log_success "SDDM configuration is valid"
    else
        log_error "SDDM configuration has errors"
        return 1
    fi
    
    # Check theme availability
    local theme=$(grep "^Current=" "$SDDM_CONF" 2>/dev/null | cut -d= -f2)
    if [[ -n "$theme" ]]; then
        local theme_path="/usr/share/sddm/themes/$theme"
        if [[ -d "$theme_path" ]]; then
            log_success "SDDM theme '$theme' is available"
        else
            log_warning "SDDM theme '$theme' not found at $theme_path"
        fi
    fi
}

# Restart SDDM safely
restart_sddm() {
    log_warning "Restarting SDDM will log out all users!"
    read -p "Are you sure you want to restart SDDM? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restarting SDDM service..."
        sudo systemctl restart sddm
        log_success "SDDM restarted"
    else
        log_info "SDDM restart cancelled"
        echo "Changes will take effect on next system boot or manual SDDM restart"
    fi
}

# Restore from backup
restore_backup() {
    log_info "Available SDDM configuration backups:"
    
    local backups=($(ls "$BACKUP_DIR"/sddm.conf.backup.* 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_warning "No backups found in $BACKUP_DIR"
        return 1
    fi
    
    for i in "${!backups[@]}"; do
        local backup_name=$(basename "${backups[$i]}")
        local backup_date=$(echo "$backup_name" | grep -o '[0-9]\{8\}_[0-9]\{6\}')
        echo "  $((i+1)). $backup_name ($(echo $backup_date | sed 's/_/ /'))"
    done
    
    read -p "Select backup to restore (1-${#backups[@]}, or 0 to cancel): " selection
    
    if [[ "$selection" -ge 1 && "$selection" -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((selection-1))]}"
        sudo cp "$selected_backup" "$SDDM_CONF"
        log_success "Configuration restored from $(basename "$selected_backup")"
    else
        log_info "Restore cancelled"
    fi
}

# Main menu
show_menu() {
    echo
    echo "Available options:"
    echo "  1. Check display information"
    echo "  2. Check SDDM configuration"
    echo "  3. Fix SDDM resolution automatically"
    echo "  4. Test SDDM configuration"
    echo "  5. Restart SDDM (applies changes)"
    echo "  6. Restore from backup"
    echo "  7. Exit"
    echo
}

# Main function
main() {
    show_banner
    
    if [[ "$1" == "auto" ]]; then
        # Auto mode - detect and fix
        get_display_info
        echo
        check_sddm_config
        echo
        fix_sddm_resolution
        echo
        test_sddm_config
        return
    fi
    
    while true; do
        show_menu
        read -p "Select option (1-7): " choice
        
        case $choice in
            1)
                get_display_info
                ;;
            2)
                check_sddm_config
                ;;
            3)
                fix_sddm_resolution
                ;;
            4)
                test_sddm_config
                ;;
            5)
                restart_sddm
                ;;
            6)
                restore_backup
                ;;
            7)
                log_info "Exiting..."
                break
                ;;
            *)
                log_error "Invalid option. Please select 1-7."
                ;;
        esac
        echo
    done
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

