#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme-Builder - Wallpapers Installation Module

source "$(dirname "$0")/../common/functions.sh"

install_wallpapers() {
    log_info "Installing wallpaper collections..."
    
    # Create wallpapers directory
    local wallpapers_dir="$HOME/Pictures/Wallpapers"
    mkdir -p "$wallpapers_dir"
    
    # Install various wallpaper collections
    install_catppuccin_wallpapers
    install_nordic_wallpapers
    install_anime_wallpapers
    install_landscape_wallpapers
    install_abstract_wallpapers
    
    # Set up wallpaper utilities
    install_wallpaper_utilities
    
    # Set default wallpaper
    set_default_wallpaper
    
    log_success "Wallpapers installation completed"
}

install_catppuccin_wallpapers() {
    log_info "Installing Catppuccin wallpapers..."
    
    local catppuccin_dir="$HOME/Pictures/Wallpapers/Catppuccin"
    mkdir -p "$catppuccin_dir"
    
    # Download Catppuccin wallpapers
    local temp_dir="/tmp/catppuccin-wallpapers"
    
    if git clone https://github.com/catppuccin/wallpapers.git "$temp_dir" 2>/dev/null; then
        cp -r "$temp_dir/os/"* "$catppuccin_dir/" 2>/dev/null || true
        cp -r "$temp_dir/misc/"* "$catppuccin_dir/" 2>/dev/null || true
        rm -rf "$temp_dir"
        log_success "Catppuccin wallpapers installed"
    else
        log_warn "Failed to download Catppuccin wallpapers"
    fi
}

install_nordic_wallpapers() {
    log_info "Installing Nordic wallpapers..."
    
    local nordic_dir="$HOME/Pictures/Wallpapers/Nordic"
    mkdir -p "$nordic_dir"
    
    # Create some Nordic-style wallpapers with imagemagick
    if command -v convert &> /dev/null; then
        # Create gradient wallpapers
        convert -size 1920x1080 gradient:#2E3440-#3B4252 "$nordic_dir/nordic_gradient_1.png" 2>/dev/null || true
        convert -size 1920x1080 gradient:#3B4252-#434C5E "$nordic_dir/nordic_gradient_2.png" 2>/dev/null || true
        convert -size 1920x1080 gradient:#434C5E-#4C566A "$nordic_dir/nordic_gradient_3.png" 2>/dev/null || true
        
        log_success "Nordic wallpapers created"
    else
        log_warn "ImageMagick not available, skipping Nordic wallpaper generation"
    fi
}

install_anime_wallpapers() {
    log_info "Installing anime wallpapers..."
    
    local anime_dir="$HOME/Pictures/Wallpapers/Anime"
    mkdir -p "$anime_dir"
    
    # Download some popular anime wallpapers
    local wallpapers=(
        "https://raw.githubusercontent.com/dharmx/walls/main/anime/aesthetic_mountain.png"
        "https://raw.githubusercontent.com/dharmx/walls/main/anime/aesthetic_mountain_2.png"
        "https://raw.githubusercontent.com/dharmx/walls/main/anime/lofi_girl.png"
    )
    
    for url in "${wallpapers[@]}"; do
        local filename=$(basename "$url")
        if ! curl -fsSL "$url" -o "$anime_dir/$filename" 2>/dev/null; then
            log_warn "Failed to download $filename"
        fi
    done
    
    log_success "Anime wallpapers installed"
}

install_landscape_wallpapers() {
    log_info "Installing landscape wallpapers..."
    
    local landscape_dir="$HOME/Pictures/Wallpapers/Landscapes"
    mkdir -p "$landscape_dir"
    
    # Download some landscape wallpapers
    local wallpapers=(
        "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&h=1080&fit=crop"
        "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=1920&h=1080&fit=crop"
        "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1920&h=1080&fit=crop"
    )
    
    local counter=1
    for url in "${wallpapers[@]}"; do
        if ! curl -fsSL "$url" -o "$landscape_dir/landscape_$counter.jpg" 2>/dev/null; then
            log_warn "Failed to download landscape wallpaper $counter"
        fi
        ((counter++))
    done
    
    log_success "Landscape wallpapers installed"
}

install_abstract_wallpapers() {
    log_info "Installing abstract wallpapers..."
    
    local abstract_dir="$HOME/Pictures/Wallpapers/Abstract"
    mkdir -p "$abstract_dir"
    
    # Create some abstract wallpapers with imagemagick
    if command -v convert &> /dev/null; then
        # Create plasma wallpapers
        convert -size 1920x1080 plasma:fractal "$abstract_dir/plasma_1.png" 2>/dev/null || true
        convert -size 1920x1080 plasma: -blur 0x8 "$abstract_dir/plasma_blur.png" 2>/dev/null || true
        
        # Create noise wallpapers
        convert -size 1920x1080 xc: +noise Random -channel G -separate +channel -blur 0x8 -normalize "$abstract_dir/noise_green.png" 2>/dev/null || true
        convert -size 1920x1080 xc: +noise Random -channel B -separate +channel -blur 0x8 -normalize "$abstract_dir/noise_blue.png" 2>/dev/null || true
        
        log_success "Abstract wallpapers created"
    else
        log_warn "ImageMagick not available, skipping abstract wallpaper generation"
    fi
}

install_wallpaper_utilities() {
    log_info "Installing wallpaper utilities..."
    
    # Install wallpaper-related packages
    local packages=(
        "feh"
        "nitrogen"
        "swaybg"
        "swww"
        "hyprpaper"
        "imagemagick"
    )
    
    install_packages "${packages[@]}"
    
    # Create wallpaper scripts
    create_wallpaper_scripts
    
    log_success "Wallpaper utilities installed"
}

create_wallpaper_scripts() {
    log_info "Creating wallpaper scripts..."
    
    local scripts_dir="$HOME/.config/hypr/scripts"
    mkdir -p "$scripts_dir"
    
    # Random wallpaper script
    local random_wallpaper_script="$scripts_dir/random-wallpaper.sh"
    
    cat > "$random_wallpaper_script" << 'EOF'
#!/bin/bash
# Random Wallpaper Script for HyprSupreme

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Find all image files
mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null)

if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Select random wallpaper
selected_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"

# Set wallpaper using hyprpaper
hyprctl hyprpaper wallpaper ",$selected_wallpaper"

echo "Set wallpaper: $selected_wallpaper"
EOF

    chmod +x "$random_wallpaper_script"
    
    # Wallpaper selector script
    local wallpaper_selector_script="$scripts_dir/wallpaper-selector.sh"
    
    cat > "$wallpaper_selector_script" << 'EOF'
#!/bin/bash
# Wallpaper Selector Script for HyprSupreme

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Find all image files
mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null)

if [ ${#wallpapers[@]} -eq 0 ]; then
    notify-send "No wallpapers found" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Create rofi options
rofi_options=""
for wallpaper in "${wallpapers[@]}"; do
    filename=$(basename "$wallpaper")
    rofi_options="$rofi_options$filename\n"
done

# Show rofi menu
selected=$(echo -e "$rofi_options" | rofi -dmenu -p "Select Wallpaper" -theme-str 'window {width: 40%;}')

if [ -n "$selected" ]; then
    # Find the full path
    for wallpaper in "${wallpapers[@]}"; do
        if [[ "$(basename "$wallpaper")" == "$selected" ]]; then
            # Set wallpaper
            hyprctl hyprpaper wallpaper ",$wallpaper"
            notify-send "Wallpaper Changed" "Set to: $selected"
            break
        fi
    done
fi
EOF

    chmod +x "$wallpaper_selector_script"
    
    # Time-based wallpaper script
    local time_wallpaper_script="$scripts_dir/time-wallpaper.sh"
    
    cat > "$time_wallpaper_script" << 'EOF'
#!/bin/bash
# Time-based Wallpaper Script for HyprSupreme

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
current_hour=$(date +%H)

# Define time periods
if [ $current_hour -ge 6 ] && [ $current_hour -lt 12 ]; then
    # Morning (6-12)
    preferred_dirs=("Landscapes" "Nordic")
elif [ $current_hour -ge 12 ] && [ $current_hour -lt 18 ]; then
    # Afternoon (12-18)
    preferred_dirs=("Catppuccin" "Abstract")
elif [ $current_hour -ge 18 ] && [ $current_hour -lt 22 ]; then
    # Evening (18-22)
    preferred_dirs=("Anime" "Abstract")
else
    # Night (22-6)
    preferred_dirs=("Nordic" "Catppuccin")
fi

# Find wallpapers in preferred directories
wallpapers=()
for dir in "${preferred_dirs[@]}"; do
    if [ -d "$WALLPAPER_DIR/$dir" ]; then
        mapfile -t -O ${#wallpapers[@]} wallpapers < <(find "$WALLPAPER_DIR/$dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null)
    fi
done

# Fallback to all wallpapers if none found
if [ ${#wallpapers[@]} -eq 0 ]; then
    mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null)
fi

if [ ${#wallpapers[@]} -gt 0 ]; then
    selected_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    hyprctl hyprpaper wallpaper ",$selected_wallpaper"
    echo "Set time-appropriate wallpaper: $selected_wallpaper"
fi
EOF

    chmod +x "$time_wallpaper_script"
    
    log_success "Wallpaper scripts created"
}

set_default_wallpaper() {
    log_info "Setting default wallpaper..."
    
    # Find a wallpaper to set as default
    local wallpaper_dir="$HOME/Pictures/Wallpapers"
    local default_wallpaper
    
    # Priority order for default wallpaper
    local search_dirs=("Catppuccin" "Nordic" "Landscapes" "Abstract" "Anime")
    
    for dir in "${search_dirs[@]}"; do
        if [ -d "$wallpaper_dir/$dir" ]; then
            default_wallpaper=$(find "$wallpaper_dir/$dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | head -1)
            if [ -n "$default_wallpaper" ]; then
                break
            fi
        fi
    done
    
    # Fallback to any wallpaper
    if [ -z "$default_wallpaper" ]; then
        default_wallpaper=$(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | head -1)
    fi
    
    if [ -n "$default_wallpaper" ]; then
        # Create hyprpaper config
        local hyprpaper_config="$HOME/.config/hypr/hyprpaper.conf"
        
        cat > "$hyprpaper_config" << EOF
preload = $default_wallpaper
wallpaper = ,$default_wallpaper
splash = false
ipc = on
EOF
        
        log_success "Default wallpaper set: $(basename "$default_wallpaper")"
    else
        log_warn "No wallpapers found to set as default"
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_wallpapers
fi

