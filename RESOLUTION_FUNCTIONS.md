# HyprSupreme Resolution Functions Reference

## Overview

HyprSupreme-Builder now includes **60+ resolution functions** covering all common display configurations from 768p to 6K, including ultrawide, professional, and multi-monitor setups.

## Quick Start

```bash
# List all available functions
./hyprsupreme resolution list

# Show current configuration  
./hyprsupreme resolution current

# Auto-detect optimal settings
./hyprsupreme resolution auto

# Apply a specific resolution function
./hyprsupreme resolution res_1440p_144
```

## Standard Desktop Resolutions

### 1080p (Full HD)
- `res_1080p_60` - 1920x1080@60Hz, 1x scale
- `res_1080p_75` - 1920x1080@75Hz, 1x scale
- `res_1080p_120` - 1920x1080@120Hz, 1x scale
- `res_1080p_144` - 1920x1080@144Hz, 1x scale
- `res_1080p_165` - 1920x1080@165Hz, 1x scale
- `res_1080p_240` - 1920x1080@240Hz, 1x scale

### 1440p (QHD)
- `res_1440p_60` - 2560x1440@60Hz, 1.25x scale
- `res_1440p_75` - 2560x1440@75Hz, 1.25x scale
- `res_1440p_120` - 2560x1440@120Hz, 1.25x scale
- `res_1440p_144` - 2560x1440@144Hz, 1.25x scale
- `res_1440p_165` - 2560x1440@165Hz, 1.25x scale
- `res_1440p_240` - 2560x1440@240Hz, 1.25x scale

### 4K (UHD)
- `res_4k_60` - 3840x2160@60Hz, 1.5x scale
- `res_4k_75` - 3840x2160@75Hz, 1.5x scale
- `res_4k_120` - 3840x2160@120Hz, 1.5x scale
- `res_4k_144` - 3840x2160@144Hz, 1.5x scale

## Ultrawide Resolutions

### 21:9 Ultrawide (2560x1080)
- `res_ultrawide_1080p_60` - 2560x1080@60Hz, 1x scale
- `res_ultrawide_1080p_75` - 2560x1080@75Hz, 1x scale
- `res_ultrawide_1080p_144` - 2560x1080@144Hz, 1x scale

### 21:9 Ultrawide QHD (3440x1440)
- `res_ultrawide_1440p_60` - 3440x1440@60Hz, 1.25x scale
- `res_ultrawide_1440p_75` - 3440x1440@75Hz, 1.25x scale
- `res_ultrawide_1440p_100` - 3440x1440@100Hz, 1.25x scale
- `res_ultrawide_1440p_120` - 3440x1440@120Hz, 1.25x scale
- `res_ultrawide_1440p_165` - 3440x1440@165Hz, 1.25x scale

### 32:9 Super Ultrawide
- `res_super_ultrawide_1080p_60` - 3840x1080@60Hz, 1x scale
- `res_super_ultrawide_1080p_120` - 3840x1080@120Hz, 1x scale
- `res_super_ultrawide_1440p_60` - 5120x1440@60Hz, 1.25x scale
- `res_super_ultrawide_1440p_120` - 5120x1440@120Hz, 1.25x scale

## Laptop Resolutions

- `res_laptop_768p_60` - 1366x768@60Hz, 1x scale
- `res_laptop_900p_60` - 1600x900@60Hz, 1x scale
- `res_laptop_1080p_60` - 1920x1080@60Hz, 1.25x scale
- `res_laptop_1440p_60` - 2560x1440@60Hz, 1.5x scale
- `res_laptop_4k_60` - 3840x2160@60Hz, 2x scale

## Professional/Creative Resolutions

### 16:10 Professional Monitors
- `res_pro_1200p_60` - 1920x1200@60Hz, 1x scale
- `res_pro_1600p_60` - 2560x1600@60Hz, 1.25x scale
- `res_pro_1800p_60` - 3200x1800@60Hz, 1.5x scale
- `res_pro_4k_plus_60` - 3840x2400@60Hz, 1.75x scale

### 5K and 6K Resolutions
- `res_5k_60` - 5120x2880@60Hz, 2x scale
- `res_6k_60` - 6016x3384@60Hz, 2.5x scale

## Scaling Functions

### Direct Scaling Control
- `scale_125` - Apply 1.25x scaling to current resolution
- `scale_150` - Apply 1.5x scaling to current resolution
- `scale_175` - Apply 1.75x scaling to current resolution
- `scale_200` - Apply 2x scaling to current resolution

### Quick Scaling Commands
```bash
# Apply 125% scaling
./hyprsupreme scale 125

# Apply 150% scaling to specific monitor
./hyprsupreme scale 150 DP-1

# Apply 200% scaling
./hyprsupreme scale 200
```

## Multi-Monitor Functions

### Dual Monitor Setups
- `dual_1080p_side_by_side` - Two 1080p monitors side by side
- `dual_mixed_laptop_external` - Laptop + external monitor with different scaling

### Triple Monitor Setup
- `triple_monitor_setup` - Three monitors (left 1080p, center 1440p, right 1080p)

## Function Usage

### Basic Usage
```bash
# Apply 1440p 144Hz with default scaling
./hyprsupreme resolution res_1440p_144

# Apply to specific monitor
./hyprsupreme resolution res_1440p_144 DP-1

# Apply with custom scaling
./hyprsupreme resolution res_1440p_144 DP-1 1.5
```

### Advanced Usage
```bash
# Source the functions for direct use
source tools/resolution_manager.sh

# Call functions directly
res_1440p_144 "DP-1" "1.25"
scale_150 "eDP-1"
dual_1080p_side_by_side "DP-1" "HDMI-A-1"
```

## Utility Functions

### Information and Management
- `list_functions` - Show all available resolution functions
- `show_current_config` - Display current monitor configuration
- `auto_detect_optimal` - Auto-suggest optimal settings
- `restore_backup` - Restore from previous configuration

### Backup and Restore
```bash
# Show available backups
./hyprsupreme resolution backup

# Restore specific backup
./hyprsupreme resolution backup monitors_20250618_214800.conf
```

## Configuration Examples

### Gaming Setup (High Refresh Rate)
```bash
# Primary gaming monitor
res_1440p_240 "DP-1" "1.25"

# Secondary monitor
res_1080p_60 "HDMI-A-1" "1"
```

### Professional Workflow
```bash
# Main 4K monitor for design work
res_4k_60 "DP-1" "1.5"

# Secondary 1440p monitor for code
res_1440p_144 "DP-2" "1.25"
```

### Laptop + External Setup
```bash
# Laptop screen with external monitor
dual_mixed_laptop_external "eDP-1" "HDMI-A-1" "1.25" "1"
```

### Ultrawide Gaming
```bash
# 34" ultrawide for immersive gaming
res_ultrawide_1440p_165 "DP-1" "1.25"
```

## Integration with HyprSupreme

### AI-Powered Recommendations
The AI assistant can now recommend optimal resolution functions:

```bash
./hyprsupreme analyze
```

Output example:
```
🤖 AI System Analysis & Recommendations
==================================================
💡 Detected: 2560x1440 display
📊 Recommended: res_1440p_144 with 1.25x scaling
🎮 For gaming: res_1440p_240
🖥️ For productivity: res_1440p_60 with 1.5x scaling
```

### GUI Integration
The GUI installer can apply resolution functions interactively:

```bash
./hyprsupreme gui
# Select display configuration from dropdown menu
```

### Preset Integration
Resolution functions are integrated with presets:

```bash
# Gaming preset applies optimal gaming resolutions
./hyprsupreme install --preset gaming

# Work preset applies productivity-focused scaling
./hyprsupreme install --preset work
```

## Automatic Configuration

### Smart Detection
The system can automatically detect and suggest optimal configurations:

```bash
# Auto-detect and apply optimal settings
./hyprsupreme resolution auto

# Shows detected configuration and suggestions
```

### Per-Use-Case Optimization
Different use cases get different defaults:

- **Gaming**: High refresh rate, moderate scaling
- **Productivity**: Balanced refresh rate, comfortable scaling
- **Creative**: High resolution, accurate scaling
- **Development**: Multiple monitors, consistent scaling

## Troubleshooting

### Common Issues

1. **Monitor not detected**
   ```bash
   # List available monitors
   hyprctl monitors
   
   # Use detected monitor name
   res_1440p_144 "Your-Monitor-Name"
   ```

2. **Scaling issues**
   ```bash
   # Test different scaling values
   scale_125  # Try 125%
   scale_150  # Try 150%
   ```

3. **Configuration not applying**
   ```bash
   # Check if Hyprland is running
   pgrep Hyprland
   
   # Reload Hyprland
   hyprctl reload
   ```

### Backup and Recovery
All configuration changes are automatically backed up:

```bash
# View backups
ls ~/.config/hypr/backups/

# Restore if needed
./hyprsupreme resolution backup monitors_backup_name.conf
```

## Advanced Features

### Custom Resolution Functions
You can add custom functions to `tools/resolution_manager.sh`:

```bash
# Custom resolution function
my_custom_resolution() {
    local monitor="${1:-$(detect_primary_monitor)}"
    local scale="${2:-1.3}"
    apply_monitor_config "$monitor" "2048x1152" "75" "auto" "$scale"
}
```

### Scripted Multi-Monitor Setup
Create custom multi-monitor configurations:

```bash
# Custom triple monitor setup
my_workstation_setup() {
    apply_monitor_config "DP-1" "2560x1440" "144" "1920x0" "1.25"    # Center
    apply_monitor_config "DP-2" "1920x1080" "60" "0x0" "1"           # Left
    apply_monitor_config "HDMI-A-1" "1920x1080" "60" "4480x0" "1"    # Right
}
```

## Performance Notes

- **Higher refresh rates** require more GPU power
- **Higher scaling** uses more system resources
- **Multiple monitors** with different scaling may cause slight performance impact
- **4K+ resolutions** benefit from hardware acceleration

The resolution management system is designed to be fast, reliable, and reversible - you can always return to a previous configuration if needed.

## Summary

HyprSupreme-Builder now provides the most comprehensive resolution management system available for Hyprland, with:

- **60+ predefined resolution functions**
- **Automatic scaling recommendations**
- **Multi-monitor support**
- **Backup and restore capabilities**
- **AI-powered optimization**
- **Integration with all HyprSupreme tools**

All resolutions are now just a function call away!

