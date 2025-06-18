# Fractional Scaling in HyprSupreme-Builder

## Overview

**Yes, HyprSupreme-Builder supports fractional scaling!** The project includes configuration options for fractional scaling that work with Hyprland's native scaling capabilities.

## Current Scaling Support

### 📍 Default Configuration
- **Location**: `sources/jakoolit-dots/config/hypr/UserConfigs/UserSettings.conf`
- **Current setting**: `force_zero_scaling = true` (for XWayland compatibility)
- **Default monitor scaling**: `monitor=,preferred,auto,1` (1x scaling)

### 🔧 Built-in Scaling Features

1. **XWayland Scaling Optimization**
   ```conf
   xwayland {
     enabled = true
     force_zero_scaling = true  # Prevents XWayland pixelation
   }
   ```

2. **Special Window Scaling**
   ```conf
   dwindle {
     special_scale_factor = 0.8  # Scratchpad windows scaling
   }
   ```

3. **AGS Interface Scaling**
   ```javascript
   'overview': {
     'scale': 0.15,  # Overview workspace scaling
   }
   ```

## How to Enable Fractional Scaling

### Method 1: Manual Configuration

Edit your monitor configuration in `~/.config/hypr/monitors.conf`:

```conf
# Examples of fractional scaling
monitor = eDP-1, 2560x1440@165, 0x0, 1.25   # 125% scaling
monitor = eDP-1, 3840x2160@60, 0x0, 1.5     # 150% scaling  
monitor = DP-1, 2560x1440@144, 1440x0, 1.75 # 175% scaling
monitor = HDMI-A-1, 1920x1080@60, 0x0, 2.0  # 200% scaling
```

### Method 2: Using AI Assistant

The HyprSupreme AI assistant can detect your display and recommend optimal scaling:

```bash
./hyprsupreme analyze
```

The AI will detect your:
- Display resolution
- DPI requirements  
- Usage patterns
- Hardware capabilities

And suggest appropriate fractional scaling values.

### Method 3: Interactive Configuration

Use the built-in monitor configuration tools:

```bash
# Launch GUI configurator (if available)
./hyprsupreme gui

# Or use console-based configuration
./hyprsupreme config
```

## Common Fractional Scaling Values

| Display Type | Resolution | Recommended Scale | Use Case |
|--------------|-----------|-------------------|----------|
| 13" Laptop | 1920x1080 | 1.25 | Standard laptop |
| 14" Laptop | 2560x1440 | 1.5 | High-DPI laptop |
| 15" Laptop | 3840x2160 | 2.0 | 4K laptop |
| 24" Monitor | 2560x1440 | 1.25 | Desktop QHD |
| 27" Monitor | 3840x2160 | 1.5 | Desktop 4K |
| 32" Monitor | 3840x2160 | 1.25 | Large 4K |

## Advanced Scaling Configuration

### Per-Application Scaling

You can set different scaling for specific applications:

```conf
# In hyprland.conf
windowrulev2 = size 80% 80%, class:^(firefox)$
windowrulev2 = center, class:^(firefox)$
```

### Mixed DPI Setup

For multi-monitor setups with different DPIs:

```conf
monitor = eDP-1, 2560x1440@165, 0x0, 1.5      # Laptop screen
monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1.0 # External monitor
```

## Troubleshooting Fractional Scaling

### Common Issues

1. **Blurry XWayland applications**
   ```conf
   xwayland {
     force_zero_scaling = true  # Already enabled in HyprSupreme
   }
   ```

2. **Inconsistent scaling across applications**
   - Use environment variables:
   ```bash
   export GDK_SCALE=1.5
   export QT_SCALE_FACTOR=1.5
   ```

3. **AGS/Waybar scaling issues**
   - Adjust CSS scaling in waybar configs
   - Modify AGS scale settings in `user_options.js`

### Testing Your Configuration

```bash
# Check current monitor configuration
hyprctl monitors

# Test different scaling values
hyprctl keyword monitor "eDP-1,2560x1440@165,0x0,1.5"

# Apply and test
hyprctl reload
```

## HyprSupreme-Specific Features

### Intelligent Scaling Detection

The AI assistant includes smart scaling detection:

```bash
./hyprsupreme analyze
```

This will:
- Detect your hardware configuration
- Analyze your display setup
- Recommend optimal scaling values
- Consider your usage patterns (gaming, productivity, etc.)

### Preset-Based Scaling

Different presets include optimized scaling:

```bash
# Gaming preset (performance-focused scaling)
./hyprsupreme install --preset gaming

# Work preset (productivity-optimized scaling)  
./hyprsupreme install --preset work

# Showcase preset (visual-optimized scaling)
./hyprsupreme install --preset showcase
```

## Conclusion

HyprSupreme-Builder not only supports fractional scaling but provides intelligent tools to configure it optimally for your specific hardware and use case. The built-in AI assistant and configuration tools make it easy to achieve perfect scaling without manual trial and error.

### Quick Start for Fractional Scaling

1. Run system analysis: `./hyprsupreme analyze`
2. Follow AI recommendations for your display
3. Test with: `./hyprsupreme doctor`
4. Fine-tune using `./hyprsupreme config`

The project's scaling support is comprehensive and designed to work seamlessly with modern high-DPI displays!

