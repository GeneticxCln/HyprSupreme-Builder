#!/bin/bash
# HyprSupreme Visual Effects Manager
# Unified module for blur, transparency, shadows, and dynamic color management
# Enhanced Edition v2.1.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration paths
HYPR_CONFIG="$HOME/.config/hypr"
USER_CONFIGS="$HYPR_CONFIG/UserConfigs"
THEMES_DIR="$HYPR_CONFIG/themes"
SCRIPTS_DIR="$HYPR_CONFIG/scripts"
BACKUP_DIR="$HYPR_CONFIG/backups/visual-effects"

# Ensure directories exist
mkdir -p "$USER_CONFIGS" "$THEMES_DIR" "$SCRIPTS_DIR" "$BACKUP_DIR"

# Utility functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${PURPLE}[VISUAL FX]${NC} $1"; }

# Backup current configuration
backup_configs() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/visual_effects_backup_${timestamp}.tar.gz"
    
    log_info "Creating backup of current visual effects..."
    
    tar -czf "$backup_file" -C "$USER_CONFIGS" \
        UserDecorations.conf \
        BlurPresets.conf \
        UserAnimations.conf \
        2>/dev/null || true
    
    log_success "Backup created: $(basename "$backup_file")"
}

# ========== BLUR MANAGEMENT ==========
apply_blur_preset() {
    local preset="$1"
    local blur_file="$USER_CONFIGS/UserDecorations.conf"
    
    backup_configs
    
    case "$preset" in
        "performance"|"minimal")
            log_info "Applying minimal blur (performance optimized)..."
            cat >> "$blur_file" << 'EOF'

# Performance Blur Preset
decoration {
    blur {
        enabled = true
        size = 4
        passes = 1
        ignore_opacity = true
        new_optimizations = true
        xray = false
        noise = 0.0
        contrast = 1.0
        brightness = 1.0
        vibrancy = 0.0
        vibrancy_darkness = 0.0
        special = false
        popups = true
        popups_ignorealpha = 0.1
    }
}
EOF
            ;;
        "balanced"|"medium")
            log_info "Applying balanced blur (recommended)..."
            cat >> "$blur_file" << 'EOF'

# Balanced Blur Preset
decoration {
    blur {
        enabled = true
        size = 8
        passes = 3
        ignore_opacity = true
        new_optimizations = true
        xray = false
        noise = 0.0117
        contrast = 0.8916
        brightness = 0.8172
        vibrancy = 0.1696
        vibrancy_darkness = 0.0
        special = true
        popups = true
        popups_ignorealpha = 0.2
    }
}
EOF
            ;;
        "heavy"|"eyecandy")
            log_info "Applying heavy blur (maximum visual appeal)..."
            cat >> "$blur_file" << 'EOF'

# Heavy Blur Preset
decoration {
    blur {
        enabled = true
        size = 12
        passes = 4
        ignore_opacity = true
        new_optimizations = true
        xray = false
        noise = 0.02
        contrast = 0.9
        brightness = 0.8
        vibrancy = 0.3
        vibrancy_darkness = 0.1
        special = true
        popups = true
        popups_ignorealpha = 0.3
    }
}
EOF
            ;;
        "glass")
            log_info "Applying glass effect..."
            cat >> "$blur_file" << 'EOF'

# Glass Effect Preset
decoration {
    active_opacity = 0.95
    inactive_opacity = 0.85
    blur {
        enabled = true
        size = 6
        passes = 2
        ignore_opacity = true
        new_optimizations = true
        xray = false
        noise = 0.01
        contrast = 1.1
        brightness = 1.2
        vibrancy = 0.2
        vibrancy_darkness = 0.0
        special = true
        popups = true
        popups_ignorealpha = 0.2
    }
}
EOF
            ;;
        "frosted")
            log_info "Applying frosted glass effect..."
            cat >> "$blur_file" << 'EOF'

# Frosted Glass Preset
decoration {
    active_opacity = 0.9
    inactive_opacity = 0.8
    blur {
        enabled = true
        size = 10
        passes = 3
        ignore_opacity = true
        new_optimizations = true
        xray = false
        noise = 0.05
        contrast = 0.8
        brightness = 0.9
        vibrancy = 0.15
        vibrancy_darkness = 0.05
        special = true
        popups = true
        popups_ignorealpha = 0.25
    }
}
EOF
            ;;
        "off"|"disabled")
            log_info "Disabling blur effects..."
            cat >> "$blur_file" << 'EOF'

# Blur Disabled
decoration {
    active_opacity = 1.0
    inactive_opacity = 0.95
    blur {
        enabled = false
    }
}
EOF
            ;;
        *)
            log_error "Unknown blur preset: $preset"
            return 1
            ;;
    esac
    
    log_success "Blur preset '$preset' applied successfully"
    reload_hyprland
}

# ========== TRANSPARENCY MANAGEMENT ==========
apply_transparency_preset() {
    local preset="$1"
    local transparency_file="$USER_CONFIGS/UserTransparency.conf"
    
    backup_configs
    
    case "$preset" in
        "conservative")
            log_info "Applying conservative transparency..."
            cat > "$transparency_file" << 'EOF'
# Conservative Transparency Preset
decoration {
    active_opacity = 1.0
    inactive_opacity = 0.95
    fullscreen_opacity = 1.0
    dim_inactive = false
    dim_strength = 0.05
    dim_special = 0.9
}

# Per-application transparency rules
windowrulev2 = opacity 0.95 0.95, class:(kitty)
windowrulev2 = opacity 1.0 1.0, class:(firefox)
windowrulev2 = opacity 1.0 1.0, class:(chromium)
windowrulev2 = opacity 1.0 1.0, class:(code)
windowrulev2 = opacity 0.98 0.98, class:(discord)
windowrulev2 = opacity 1.0 1.0, class:(steam)
EOF
            ;;
        "moderate")
            log_info "Applying moderate transparency..."
            cat > "$transparency_file" << 'EOF'
# Moderate Transparency Preset
decoration {
    active_opacity = 0.98
    inactive_opacity = 0.9
    fullscreen_opacity = 1.0
    dim_inactive = true
    dim_strength = 0.1
    dim_special = 0.8
}

# Per-application transparency rules
windowrulev2 = opacity 0.9 0.85, class:(kitty)
windowrulev2 = opacity 0.95 0.9, class:(thunar)
windowrulev2 = opacity 0.98 0.95, class:(code)
windowrulev2 = opacity 1.0 1.0, class:(firefox)
windowrulev2 = opacity 1.0 1.0, class:(chromium)
windowrulev2 = opacity 0.92 0.88, class:(discord)
windowrulev2 = opacity 1.0 1.0, class:(steam)
windowrulev2 = opacity 0.95 0.9, class:(spotify)
EOF
            ;;
        "aggressive")
            log_info "Applying aggressive transparency..."
            cat > "$transparency_file" << 'EOF'
# Aggressive Transparency Preset
decoration {
    active_opacity = 0.95
    inactive_opacity = 0.8
    fullscreen_opacity = 1.0
    dim_inactive = true
    dim_strength = 0.2
    dim_special = 0.7
}

# Per-application transparency rules  
windowrulev2 = opacity 0.8 0.7, class:(kitty)
windowrulev2 = opacity 0.85 0.8, class:(thunar)
windowrulev2 = opacity 0.9 0.85, class:(code)
windowrulev2 = opacity 0.95 0.9, class:(firefox)
windowrulev2 = opacity 0.95 0.9, class:(chromium)
windowrulev2 = opacity 0.85 0.8, class:(discord)
windowrulev2 = opacity 1.0 1.0, class:(steam)
windowrulev2 = opacity 0.9 0.85, class:(spotify)
windowrulev2 = opacity 0.8 0.75, class:(rofi)
EOF
            ;;
        "glass-extreme")
            log_info "Applying extreme glass transparency..."
            cat > "$transparency_file" << 'EOF'
# Glass Extreme Transparency Preset
decoration {
    active_opacity = 0.9
    inactive_opacity = 0.7
    fullscreen_opacity = 1.0
    dim_inactive = true
    dim_strength = 0.25
    dim_special = 0.6
}

# Per-application transparency rules
windowrulev2 = opacity 0.7 0.6, class:(kitty)
windowrulev2 = opacity 0.8 0.7, class:(thunar)
windowrulev2 = opacity 0.85 0.8, class:(code)
windowrulev2 = opacity 0.9 0.85, class:(firefox)
windowrulev2 = opacity 0.9 0.85, class:(chromium)
windowrulev2 = opacity 0.8 0.75, class:(discord)
windowrulev2 = opacity 1.0 1.0, class:(steam)
windowrulev2 = opacity 0.85 0.8, class:(spotify)
windowrulev2 = opacity 0.75 0.7, class:(rofi)
EOF
            ;;
        "off"|"disabled")
            log_info "Disabling transparency effects..."
            cat > "$transparency_file" << 'EOF'
# Transparency Disabled
decoration {
    active_opacity = 1.0
    inactive_opacity = 1.0
    fullscreen_opacity = 1.0
    dim_inactive = false
    dim_strength = 0.0
    dim_special = 1.0
}

# Remove transparency from all applications
windowrulev2 = opacity 1.0 1.0, class:(.*)
EOF
            ;;
        *)
            log_error "Unknown transparency preset: $preset"
            return 1
            ;;
    esac
    
    log_success "Transparency preset '$preset' applied successfully"
    reload_hyprland
}

# ========== SHADOW MANAGEMENT ==========
apply_shadow_preset() {
    local preset="$1"
    local shadow_file="$USER_CONFIGS/UserShadows.conf"
    
    backup_configs
    
    case "$preset" in
        "minimal")
            log_info "Applying minimal shadows..."
            cat > "$shadow_file" << 'EOF'
# Minimal Shadow Preset
decoration {
    shadow {
        enabled = true
        range = 4
        render_power = 1
        offset = 0 1
        scale = 1.0
        color = rgba(00000020)
        color_inactive = rgba(00000010)
    }
}
EOF
            ;;
        "moderate")
            log_info "Applying moderate shadows..."
            cat > "$shadow_file" << 'EOF'
# Moderate Shadow Preset
decoration {
    shadow {
        enabled = true
        range = 8
        render_power = 2
        offset = 0 2
        scale = 1.0
        color = rgba(00000060)
        color_inactive = rgba(00000040)
    }
}
EOF
            ;;
        "dramatic")
            log_info "Applying dramatic shadows..."
            cat > "$shadow_file" << 'EOF'
# Dramatic Shadow Preset
decoration {
    shadow {
        enabled = true
        range = 15
        render_power = 3
        offset = 0 4
        scale = 1.0
        color = rgba(00000080)
        color_inactive = rgba(00000060)
    }
}
EOF
            ;;
        "colored")
            log_info "Applying colored shadows..."
            cat > "$shadow_file" << 'EOF'
# Colored Shadow Preset
decoration {
    shadow {
        enabled = true
        range = 12
        render_power = 2
        offset = 0 3
        scale = 1.0
        color = rgba(8B5A2B40)  # Brown shadow
        color_inactive = rgba(2F2F2F30)
    }
}
EOF
            ;;
        "off"|"disabled")
            log_info "Disabling shadows..."
            cat > "$shadow_file" << 'EOF'
# Shadows Disabled
decoration {
    shadow {
        enabled = false
    }
}
EOF
            ;;
        *)
            log_error "Unknown shadow preset: $preset"
            return 1
            ;;
    esac
    
    log_success "Shadow preset '$preset' applied successfully"
    reload_hyprland
}

# ========== COLOR SCHEME MANAGEMENT ==========
generate_color_scheme() {
    local base_color="$1"
    local scheme_name="$2"
    local color_file="$THEMES_DIR/${scheme_name}.conf"
    
    log_info "Generating color scheme '$scheme_name' from base color '$base_color'..."
    
    # Create color scheme generator
    cat > "$SCRIPTS_DIR/color_generator.py" << 'EOF'
#!/usr/bin/env python3
import sys
import colorsys

def hex_to_rgb(hex_color):
    """Convert hex to RGB."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(rgb):
    """Convert RGB to hex."""
    return f"0xff{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"

def adjust_color(rgb, brightness=1.0, saturation=1.0, hue_shift=0.0):
    """Adjust HSV properties of RGB color."""
    h, s, v = colorsys.rgb_to_hsv(rgb[0]/255, rgb[1]/255, rgb[2]/255)
    h = (h + hue_shift) % 1.0
    s = min(1.0, s * saturation)
    v = min(1.0, v * brightness)
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return (int(r * 255), int(g * 255), int(b * 255))

def generate_palette(base_hex):
    """Generate a complete color palette from base color."""
    base_rgb = hex_to_rgb(base_hex)
    
    palette = {
        'primary': rgb_to_hex(base_rgb),
        'primary_light': rgb_to_hex(adjust_color(base_rgb, brightness=1.3)),
        'primary_dark': rgb_to_hex(adjust_color(base_rgb, brightness=0.7)),
        'secondary': rgb_to_hex(adjust_color(base_rgb, hue_shift=0.16667)),  # +60 degrees
        'secondary_light': rgb_to_hex(adjust_color(base_rgb, hue_shift=0.16667, brightness=1.3)),
        'accent': rgb_to_hex(adjust_color(base_rgb, hue_shift=0.33333)),  # +120 degrees
        'background': rgb_to_hex(adjust_color(base_rgb, brightness=0.1, saturation=0.3)),
        'surface': rgb_to_hex(adjust_color(base_rgb, brightness=0.15, saturation=0.4)),
        'surface_variant': rgb_to_hex(adjust_color(base_rgb, brightness=0.2, saturation=0.5)),
        'error': '0xfff44336',
        'warning': '0xffff9800',
        'success': '0xff4caf50',
        'info': '0xff2196f3',
    }
    
    # Determine text colors based on luminance
    def get_luminance(rgb):
        return (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / 255
    
    text_color = '0xffffffff' if get_luminance(base_rgb) < 0.5 else '0xff000000'
    text_secondary = '0xffb0b0b0' if get_luminance(base_rgb) < 0.5 else '0xff404040'
    
    palette.update({
        'on_primary': text_color,
        'on_surface': text_color,
        'on_background': text_color,
        'text_primary': text_color,
        'text_secondary': text_secondary,
    })
    
    return palette

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: color_generator.py <base_color> <output_file>")
        sys.exit(1)
    
    base_color = sys.argv[1]
    output_file = sys.argv[2]
    
    palette = generate_palette(base_color)
    
    with open(output_file, 'w') as f:
        f.write(f"# Auto-generated color scheme from {base_color}\n")
        f.write(f"# Generated on $(date)\n\n")
        
        # Write color variables
        for name, color in palette.items():
            f.write(f"${name} = {color}\n")
        
        f.write(f"\n# Hyprland color configuration\n")
        f.write(f"general {{\n")
        f.write(f"    col.active_border = {palette['primary']} {palette['secondary']} 45deg\n")
        f.write(f"    col.inactive_border = {palette['surface']}\n")
        f.write(f"}}\n\n")
        
        f.write(f"decoration {{\n")
        f.write(f"    col.shadow = {palette['background']}\n")
        f.write(f"    col.shadow_inactive = {palette['surface']}\n")
        f.write(f"}}\n\n")
        
        f.write(f"group {{\n")
        f.write(f"    col.border_active = {palette['accent']}\n")
        f.write(f"    col.border_inactive = {palette['surface_variant']}\n")
        f.write(f"    \n")
        f.write(f"    groupbar {{\n")
        f.write(f"        col.active = {palette['primary']}\n")
        f.write(f"        col.inactive = {palette['surface']}\n")
        f.write(f"    }}\n")
        f.write(f"}}\n")
    
    print(f"Color scheme generated: {output_file}")
EOF
    
    chmod +x "$SCRIPTS_DIR/color_generator.py"
    
    # Generate the color scheme
    if python3 "$SCRIPTS_DIR/color_generator.py" "$base_color" "$color_file"; then
        log_success "Color scheme '$scheme_name' generated successfully"
        echo "source = $color_file" > "$USER_CONFIGS/UserColors.conf"
        reload_hyprland
    else
        log_error "Failed to generate color scheme"
        return 1
    fi
}

# ========== DYNAMIC COLOR EXTRACTION ==========
extract_colors_from_wallpaper() {
    local wallpaper_path="$1"
    local scheme_name="${2:-auto-wallpaper}"
    
    log_info "Extracting colors from wallpaper: $(basename "$wallpaper_path")"
    
    # Check if wallpaper exists
    if [[ ! -f "$wallpaper_path" ]]; then
        log_error "Wallpaper file not found: $wallpaper_path"
        return 1
    fi
    
    # Create advanced color extractor
    cat > "$SCRIPTS_DIR/wallpaper_color_extractor.py" << 'EOF'
#!/usr/bin/env python3
import sys
import os
from PIL import Image
import colorsys
from collections import Counter

def get_dominant_colors(image_path, num_colors=8):
    """Extract dominant colors from image."""
    try:
        image = Image.open(image_path)
        image = image.convert('RGB')
        image = image.resize((150, 150))  # Optimize for speed
        
        pixels = list(image.getdata())
        
        # Count color frequency
        color_counts = Counter(pixels)
        dominant_colors = color_counts.most_common(num_colors)
        
        return [color[0] for color in dominant_colors]
    except Exception as e:
        print(f"Error processing image: {e}")
        return None

def rgb_to_hex(rgb):
    """Convert RGB to hex."""
    return f"0xff{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"

def adjust_color(rgb, brightness=1.0, saturation=1.0):
    """Adjust brightness and saturation."""
    h, s, v = colorsys.rgb_to_hsv(rgb[0]/255, rgb[1]/255, rgb[2]/255)
    s = min(1.0, s * saturation)
    v = min(1.0, v * brightness)
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return (int(r * 255), int(g * 255), int(b * 255))

def create_theme_from_colors(colors, output_file):
    """Create Hyprland theme from extracted colors."""
    if not colors or len(colors) < 3:
        return False
    
    # Select colors for different purposes
    primary = colors[0]  # Most dominant
    secondary = colors[1] if len(colors) > 1 else primary
    accent = colors[2] if len(colors) > 2 else secondary
    
    # Generate theme colors
    theme_colors = {
        'primary': rgb_to_hex(primary),
        'primary_light': rgb_to_hex(adjust_color(primary, brightness=1.2)),
        'primary_dark': rgb_to_hex(adjust_color(primary, brightness=0.8)),
        'secondary': rgb_to_hex(secondary),
        'accent': rgb_to_hex(accent),
        'background': rgb_to_hex(adjust_color(primary, brightness=0.05, saturation=0.2)),
        'surface': rgb_to_hex(adjust_color(primary, brightness=0.1, saturation=0.3)),
        'shadow': rgb_to_hex(adjust_color(primary, brightness=0.0, saturation=0.1)),
    }
    
    # Write theme file
    with open(output_file, 'w') as f:
        f.write("# Auto-generated theme from wallpaper\n")
        f.write(f"# Extracted colors: {len(colors)} dominant colors\n\n")
        
        for name, color in theme_colors.items():
            f.write(f"${name} = {color}\n")
        
        f.write(f"\ngeneral {{\n")
        f.write(f"    col.active_border = {theme_colors['primary']} {theme_colors['accent']} 45deg\n")
        f.write(f"    col.inactive_border = {theme_colors['surface']}\n")
        f.write(f"}}\n\n")
        
        f.write(f"decoration {{\n")
        f.write(f"    col.shadow = {theme_colors['shadow']}\n")
        f.write(f"    col.shadow_inactive = {theme_colors['background']}\n")
        f.write(f"}}\n")
    
    return True

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: wallpaper_color_extractor.py <image_path> <output_file>")
        sys.exit(1)
    
    image_path = sys.argv[1]
    output_file = sys.argv[2]
    
    colors = get_dominant_colors(image_path)
    if colors and create_theme_from_colors(colors, output_file):
        print(f"Theme generated successfully: {output_file}")
    else:
        print("Failed to generate theme")
        sys.exit(1)
EOF
    
    chmod +x "$SCRIPTS_DIR/wallpaper_color_extractor.py"
    
    # Extract colors and generate theme
    local theme_file="$THEMES_DIR/${scheme_name}.conf"
    if python3 "$SCRIPTS_DIR/wallpaper_color_extractor.py" "$wallpaper_path" "$theme_file"; then
        log_success "Colors extracted and theme generated: $scheme_name"
        echo "source = $theme_file" > "$USER_CONFIGS/UserColors.conf"
        reload_hyprland
    else
        log_error "Failed to extract colors from wallpaper"
        return 1
    fi
}

# ========== PRESET COMBINATIONS ==========
apply_visual_preset() {
    local preset="$1"
    
    log_header "Applying visual preset: $preset"
    
    case "$preset" in
        "gaming")
            apply_blur_preset "performance"
            apply_transparency_preset "conservative"
            apply_shadow_preset "minimal"
            log_success "Gaming preset applied (performance optimized)"
            ;;
        "productivity")
            apply_blur_preset "balanced"
            apply_transparency_preset "moderate"
            apply_shadow_preset "moderate"
            log_success "Productivity preset applied (balanced visuals)"
            ;;
        "showcase")
            apply_blur_preset "heavy"
            apply_transparency_preset "aggressive"
            apply_shadow_preset "dramatic"
            log_success "Showcase preset applied (maximum eye-candy)"
            ;;
        "glass")
            apply_blur_preset "glass"
            apply_transparency_preset "glass-extreme"
            apply_shadow_preset "colored"
            log_success "Glass preset applied (transparent aesthetic)"
            ;;
        "minimal")
            apply_blur_preset "off"
            apply_transparency_preset "off"
            apply_shadow_preset "off"
            log_success "Minimal preset applied (clean and fast)"
            ;;
        *)
            log_error "Unknown visual preset: $preset"
            show_help
            return 1
            ;;
    esac
}

# ========== UTILITY FUNCTIONS ==========
reload_hyprland() {
    if command -v hyprctl >/dev/null 2>&1; then
        log_info "Reloading Hyprland configuration..."
        hyprctl reload
        log_success "Hyprland configuration reloaded"
    else
        log_warning "hyprctl not found - restart Hyprland manually to apply changes"
    fi
}

list_presets() {
    echo -e "${CYAN}Available Visual Effect Presets:${NC}"
    echo
    echo -e "${GREEN}Blur Presets:${NC}"
    echo "  • performance/minimal - Minimal blur for best performance"
    echo "  • balanced/medium     - Balanced blur (recommended)"
    echo "  • heavy/eyecandy      - Heavy blur for maximum visual appeal"
    echo "  • glass               - Glass-like transparency effect"
    echo "  • frosted             - Frosted glass effect"
    echo "  • off/disabled        - Disable blur entirely"
    echo
    echo -e "${GREEN}Transparency Presets:${NC}"
    echo "  • conservative        - Minimal transparency"
    echo "  • moderate            - Balanced transparency"
    echo "  • aggressive          - High transparency"
    echo "  • glass-extreme       - Maximum transparency"
    echo "  • off/disabled        - No transparency"
    echo
    echo -e "${GREEN}Shadow Presets:${NC}"
    echo "  • minimal             - Subtle shadows"
    echo "  • moderate            - Balanced shadows"
    echo "  • dramatic            - Strong shadows"
    echo "  • colored             - Colored shadows"
    echo "  • off/disabled        - No shadows"
    echo
    echo -e "${GREEN}Combined Presets:${NC}"
    echo "  • gaming              - Performance optimized"
    echo "  • productivity        - Balanced for work"
    echo "  • showcase            - Maximum eye-candy"
    echo "  • glass               - Glass aesthetic"
    echo "  • minimal             - Clean and fast"
}

show_status() {
    echo -e "${CYAN}Current Visual Effects Status:${NC}"
    echo
    
    # Check blur status
    if hyprctl getoption decoration:blur:enabled | grep -q "int: 1"; then
        local blur_size=$(hyprctl getoption decoration:blur:size | grep -o "int: [0-9]*" | cut -d' ' -f2)
        local blur_passes=$(hyprctl getoption decoration:blur:passes | grep -o "int: [0-9]*" | cut -d' ' -f2)
        echo -e "${GREEN}✓ Blur:${NC} Enabled (size: $blur_size, passes: $blur_passes)"
    else
        echo -e "${RED}✗ Blur:${NC} Disabled"
    fi
    
    # Check transparency
    local active_opacity=$(hyprctl getoption decoration:active_opacity | grep -o "float: [0-9.]*" | cut -d' ' -f2)
    local inactive_opacity=$(hyprctl getoption decoration:inactive_opacity | grep -o "float: [0-9.]*" | cut -d' ' -f2)
    echo -e "${GREEN}✓ Transparency:${NC} Active: $active_opacity, Inactive: $inactive_opacity"
    
    # Check shadows
    if hyprctl getoption decoration:drop_shadow | grep -q "int: 1"; then
        local shadow_range=$(hyprctl getoption decoration:shadow_range | grep -o "int: [0-9]*" | cut -d' ' -f2)
        echo -e "${GREEN}✓ Shadows:${NC} Enabled (range: $shadow_range)"
    else
        echo -e "${RED}✗ Shadows:${NC} Disabled"
    fi
    
    echo
    echo -e "${BLUE}Configuration files:${NC}"
    ls -la "$USER_CONFIGS"/ | grep -E "(Decoration|Blur|Shadow|Transparency|Colors)" || echo "No visual effect configs found"
}

show_help() {
    echo -e "${CYAN}HyprSupreme Visual Effects Manager${NC}"
    echo -e "${WHITE}Advanced blur, transparency, shadows, and color management${NC}"
    echo
    echo -e "${YELLOW}USAGE:${NC}"
    echo "  $0 [command] [options]"
    echo
    echo -e "${YELLOW}COMMANDS:${NC}"
    echo -e "${GREEN}Blur Management:${NC}"
    echo "  blur <preset>              Apply blur preset"
    echo "  blur off                   Disable blur"
    echo
    echo -e "${GREEN}Transparency:${NC}"
    echo "  transparency <preset>      Apply transparency preset"
    echo "  opacity <value>            Set global opacity (0.0-1.0)"
    echo
    echo -e "${GREEN}Shadows:${NC}"
    echo "  shadows <preset>           Apply shadow preset"
    echo "  shadows off                Disable shadows"
    echo
    echo -e "${GREEN}Colors:${NC}"
    echo "  color <hex_color> <name>   Generate color scheme"
    echo "  extract <wallpaper>        Extract colors from wallpaper"
    echo
    echo -e "${GREEN}Presets:${NC}"
    echo "  preset <name>              Apply combined visual preset"
    echo "  list                       List all available presets"
    echo
    echo -e "${GREEN}Management:${NC}"
    echo "  status                     Show current visual effects status"
    echo "  backup                     Create configuration backup"
    echo "  reload                     Reload Hyprland configuration"
    echo
    echo -e "${YELLOW}EXAMPLES:${NC}"
    echo "  $0 preset gaming           # Apply gaming preset"
    echo "  $0 blur heavy              # Apply heavy blur"
    echo "  $0 transparency moderate   # Apply moderate transparency"
    echo "  $0 color \"#ff6b6b\" red      # Generate red color scheme"
    echo "  $0 extract ~/wallpaper.jpg # Extract colors from wallpaper"
}

# ========== MAIN FUNCTION ==========
main() {
    case "$1" in
        "blur")
            apply_blur_preset "$2"
            ;;
        "transparency"|"opacity")
            if [[ "$1" == "opacity" && "$2" =~ ^[0-9]*\.?[0-9]+$ ]]; then
                # Set specific opacity value
                log_info "Setting global opacity to $2"
                hyprctl keyword decoration:active_opacity "$2"
                hyprctl keyword decoration:inactive_opacity "$2"
            else
                apply_transparency_preset "$2"
            fi
            ;;
        "shadows"|"shadow")
            apply_shadow_preset "$2"
            ;;
        "color"|"colors")
            generate_color_scheme "$2" "$3"
            ;;
        "extract")
            extract_colors_from_wallpaper "$2" "$3"
            ;;
        "preset")
            apply_visual_preset "$2"
            ;;
        "list")
            list_presets
            ;;
        "status")
            show_status
            ;;
        "backup")
            backup_configs
            ;;
        "reload")
            reload_hyprland
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

