# HyprSupreme Visual Effects Manager

A comprehensive module for managing blur, transparency, shadows, and dynamic color schemes in your Hyprland configuration.

## 🌟 Features

- **Advanced Blur Management** - Multiple blur presets from performance-optimized to maximum eye-candy
- **Smart Transparency** - Per-application transparency rules with preset configurations
- **Dynamic Shadows** - Customizable shadow effects with color support
- **Intelligent Color Generation** - Generate complete color schemes from base colors or wallpapers
- **Preset Combinations** - Pre-configured visual style packages
- **Automatic Backups** - Configuration backups before any changes
- **Live Preview** - Instant application with Hyprland reload

## 🚀 Quick Start

### Using HyprSupreme Commands

```bash
# Apply visual presets (recommended)
./hyprsupreme visual showcase      # Maximum eye-candy
./hyprsupreme visual gaming        # Performance optimized
./hyprsupreme visual productivity  # Balanced for work
./hyprsupreme visual glass         # Glass aesthetic
./hyprsupreme visual minimal       # Clean and fast

# Individual effect management
./hyprsupreme blur heavy           # Apply heavy blur
./hyprsupreme transparency moderate # Apply moderate transparency
./hyprsupreme shadows dramatic     # Apply dramatic shadows

# Color scheme generation
./hyprsupreme colors "#ff6b6b" "red-theme"  # Generate from hex color
./hyprsupreme colors extract ~/wallpaper.jpg # Extract from wallpaper
```

### Direct Module Usage

```bash
# Use the module directly
./modules/visual-effects/visual_effects_manager.sh [command] [options]

# Examples
./modules/visual-effects/visual_effects_manager.sh status
./modules/visual-effects/visual_effects_manager.sh list
./modules/visual-effects/visual_effects_manager.sh preset gaming
```

## 📋 Available Presets

### Blur Presets
- **performance/minimal** - Minimal blur for best performance (size: 4, passes: 1)
- **balanced/medium** - Recommended balanced blur (size: 8, passes: 3)
- **heavy/eyecandy** - Maximum visual appeal (size: 12, passes: 4)
- **glass** - Glass-like transparency effect (size: 6, passes: 2)
- **frosted** - Frosted glass effect (size: 10, passes: 3)
- **off/disabled** - Disable blur entirely

### Transparency Presets
- **conservative** - Minimal transparency (active: 1.0, inactive: 0.95)
- **moderate** - Balanced transparency (active: 0.98, inactive: 0.9)
- **aggressive** - High transparency (active: 0.95, inactive: 0.8)
- **glass-extreme** - Maximum transparency (active: 0.9, inactive: 0.7)
- **off/disabled** - No transparency

### Shadow Presets
- **minimal** - Subtle shadows (range: 4, power: 1)
- **moderate** - Balanced shadows (range: 8, power: 2)
- **dramatic** - Strong shadows (range: 15, power: 3)
- **colored** - Colored shadows with custom colors
- **off/disabled** - No shadows

### Combined Visual Presets
- **gaming** - Performance optimized (minimal blur, conservative transparency, minimal shadows)
- **productivity** - Balanced for work (balanced blur, moderate transparency, moderate shadows)
- **showcase** - Maximum eye-candy (heavy blur, aggressive transparency, dramatic shadows)
- **glass** - Glass aesthetic (glass blur, glass-extreme transparency, colored shadows)
- **minimal** - Clean and fast (all effects disabled)

## 🎨 Color Management

### Generate Color Schemes

```bash
# From hex color
./hyprsupreme colors "#ff6b6b" "red-theme"
./hyprsupreme colors "#6b73ff" "blue-theme"
./hyprsupreme colors "#50fa7b" "green-theme"

# From wallpaper (requires PIL/Pillow)
./hyprsupreme colors extract ~/Pictures/wallpaper.jpg "wallpaper-theme"
```

### Color Scheme Features
- **Automatic palette generation** - Creates primary, secondary, accent, and surface colors
- **Smart text colors** - Automatically determines light/dark text based on luminance
- **Hyprland integration** - Generates complete border, shadow, and groupbar colors
- **HSV color theory** - Uses proper color theory for harmonious palettes

## 📁 File Structure

```
modules/visual-effects/
├── visual_effects_manager.sh    # Main module script
├── README.md                    # This documentation
└── generated_scripts/           # Auto-generated helper scripts
    ├── color_generator.py       # Color palette generator
    └── wallpaper_color_extractor.py # Wallpaper color extraction
```

## 🔧 Configuration Files

The module manages these configuration files in `~/.config/hypr/UserConfigs/`:

- **UserDecorations.conf** - Main decoration settings (blur, opacity, shadows)
- **UserTransparency.conf** - Transparency and per-app opacity rules
- **UserShadows.conf** - Shadow-specific configurations
- **UserColors.conf** - Color scheme sourcing
- **BlurPresets.conf** - Reference blur presets (existing)

Color schemes are stored in `~/.config/hypr/themes/`:
- **{scheme-name}.conf** - Generated color schemes

## 📊 Status and Monitoring

```bash
# Check current visual effects status
./hyprsupreme visual status

# Output example:
Current Visual Effects Status:

✓ Blur: Enabled (size: 12, passes: 4)
✓ Transparency: Active: 0.95, Inactive: 0.8
✓ Shadows: Enabled (range: 15)

Configuration files:
-rw-r--r-- alex alex  1.2K UserDecorations.conf
-rw-r--r-- alex alex  800B UserTransparency.conf
-rw-r--r-- alex alex  400B UserShadows.conf
```

## 🛠️ Advanced Usage

### Custom Opacity Control

```bash
# Set specific opacity value
./hyprsupreme transparency opacity 0.85
```

### Manual Configuration Management

```bash
# Create backup
./modules/visual-effects/visual_effects_manager.sh backup

# Reload configuration
./modules/visual-effects/visual_effects_manager.sh reload
```

### Per-Application Rules

The transparency presets include intelligent per-application rules:

```bash
# Conservative preset includes:
windowrulev2 = opacity 0.95 0.95, class:(kitty)      # Terminal
windowrulev2 = opacity 1.0 1.0, class:(firefox)     # Browser (solid)
windowrulev2 = opacity 1.0 1.0, class:(steam)       # Gaming (solid)
windowrulev2 = opacity 0.98 0.98, class:(discord)   # Chat apps

# Aggressive preset includes:
windowrulev2 = opacity 0.8 0.7, class:(kitty)       # Very transparent terminal
windowrulev2 = opacity 0.85 0.8, class:(thunar)     # File manager
windowrulev2 = opacity 0.9 0.85, class:(code)       # Code editor
```

## 🔍 Dependencies

### Required
- **bash** - Shell scripting
- **hyprctl** - Hyprland control (for live application)
- **python3** - Color generation scripts

### Optional
- **python3-PIL (Pillow)** - For wallpaper color extraction
- **python3-colorsys** - Enhanced color manipulation

### Installation
```bash
# On Arch/CachyOS
sudo pacman -S python python-pillow

# On Ubuntu/Debian
sudo apt install python3 python3-pil

# Via pip
pip install Pillow
```

## 🎯 Performance Impact

### Gaming Mode (Minimal Impact)
- **Blur**: Size 4, 1 pass - ~1-2% GPU usage
- **Transparency**: Conservative settings - Minimal CPU impact
- **Shadows**: Minimal range - ~0.5% GPU usage

### Showcase Mode (Maximum Visual)
- **Blur**: Size 12, 4 passes - ~5-8% GPU usage
- **Transparency**: Aggressive settings - ~2-3% CPU impact
- **Shadows**: Dramatic range - ~2-3% GPU usage

## 🐛 Troubleshooting

### Common Issues

1. **"hyprctl not found"**
   - Ensure Hyprland is installed and running
   - Check PATH includes hyprctl location

2. **Color generation fails**
   - Install Python PIL: `pip install Pillow`
   - Check image file permissions and format

3. **Effects not applying**
   - Check Hyprland configuration sourcing
   - Verify UserConfigs directory exists
   - Run `./hyprsupreme visual reload`

4. **Performance issues**
   - Use gaming preset: `./hyprsupreme visual gaming`
   - Reduce blur passes and size manually
   - Disable effects: `./hyprsupreme visual minimal`

### Debug Mode

```bash
# Enable debug output (modify script)
export DEBUG=1
./modules/visual-effects/visual_effects_manager.sh status
```

## 🔄 Integration with HyprSupreme

This module is fully integrated with the HyprSupreme-Builder system:

- **Backup System** - Automatic backups before changes
- **Preset System** - Works with HyprSupreme presets
- **GUI Integration** - Can be controlled via the GUI installer
- **Cloud Sync** - Visual settings sync with cloud backups
- **Community Sharing** - Share visual presets with the community

## 📝 Examples

### Quick Setup for Different Use Cases

```bash
# Gaming setup - priority on performance
./hyprsupreme visual gaming

# Work setup - balanced visuals and performance  
./hyprsupreme visual productivity

# Content creation - maximum visual appeal
./hyprsupreme visual showcase

# Minimalist setup - clean and fast
./hyprsupreme visual minimal

# Custom glass aesthetic
./hyprsupreme visual glass
```

### Custom Color Workflows

```bash
# Create theme from your wallpaper
./hyprsupreme colors extract ~/Pictures/current-wallpaper.jpg "my-theme"

# Create theme from brand colors
./hyprsupreme colors "#1e88e5" "brand-blue"

# Create theme from favorite color
./hyprsupreme colors "#e91e63" "pink-aesthetic"
```

## 🚀 Future Enhancements

- **Real-time preview** - Live preview before applying
- **Animation effects** - Transition animations between states
- **Seasonal themes** - Automatic theme switching based on time/date
- **AI color suggestions** - AI-powered color harmony recommendations
- **Performance monitoring** - Real-time performance impact display
- **Theme marketplace** - Share and download community visual themes

---

**Created for HyprSupreme-Builder Enhanced Edition v2.1.0**

For more information, visit the [HyprSupreme-Builder repository](https://github.com/GeneticxCln/HyprSupreme-Builder).

