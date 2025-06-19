#!/bin/bash

# HyprSupreme GPU Preset Manager
# Advanced GPU optimization presets for specific workflows and applications

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$HOME/.config/hyprsupreme"
readonly PRESETS_DIR="$CONFIG_DIR/gpu_presets"
readonly PRESETS_CONFIG="$PRESETS_DIR/presets.json"
readonly ACTIVE_PRESET_FILE="$PRESETS_DIR/active_preset"
readonly LOG_FILE="$CONFIG_DIR/gpu_presets.log"

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
mkdir -p "$PRESETS_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
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
HyprSupreme GPU Preset Manager - Advanced Workflow Optimizations

USAGE:
    gpu_presets.sh [COMMAND] [OPTIONS]

COMMANDS:
    list                List all available presets
    apply <preset>      Apply a specific preset
    create <name>       Create custom preset interactively
    edit <preset>       Edit existing preset
    delete <preset>     Delete preset
    active              Show currently active preset
    backup              Backup all presets
    restore <file>      Restore presets from backup

BUILT-IN PRESETS:
    gaming-competitive  Ultra-low latency for competitive gaming
    gaming-immersive   High visual quality for single-player games
    streaming          Optimized for streaming/recording
    productivity       Balanced for work applications
    development        Optimized for code editors and IDEs
    content-creation   Optimized for video/photo editing
    ai-workload        Optimized for AI/ML training
    presentation       Optimized for presentations/demos
    battery-extreme    Maximum battery life
    troubleshooting    Minimal effects for debugging

APPLICATION-SPECIFIC:
    blender            Optimized for Blender rendering
    unity              Optimized for Unity development
    unreal             Optimized for Unreal Engine
    obs                Optimized for OBS streaming
    davinci            Optimized for DaVinci Resolve
    photoshop          Optimized for image editing
    steam-deck         Steam Deck specific optimizations

EXAMPLES:
    gpu_presets.sh list
    gpu_presets.sh apply gaming-competitive
    gpu_presets.sh create my-custom-preset
    gpu_presets.sh active

OPTIONS:
    --force            Apply without confirmation
    --help             Show this help message

EOF
}

# Initialize default presets
initialize_presets() {
    if [ ! -f "$PRESETS_CONFIG" ]; then
        echo -e "${INFO} Creating default presets..."
        create_default_presets
    fi
}

# Create default presets configuration
create_default_presets() {
    cat > "$PRESETS_CONFIG" << 'EOF'
{
  "presets": {
    "gaming-competitive": {
      "name": "Gaming - Competitive",
      "description": "Ultra-low latency for competitive gaming (FPS, MOBA, etc.)",
      "category": "gaming",
      "priority": "performance",
      "settings": {
        "decoration": {
          "blur": false,
          "drop_shadow": false,
          "rounding": 0
        },
        "animations": {
          "enabled": false
        },
        "misc": {
          "vfr": false,
          "vrr": 2,
          "allow_tearing": true,
          "disable_hyprland_logo": true,
          "disable_splash_rendering": true,
          "no_cursor_warps": true
        },
        "input": {
          "force_no_accel": true
        }
      },
      "gpu_profile": "performance",
      "applications": ["cs2", "valorant", "apex", "fortnite", "overwatch2"]
    },
    "gaming-immersive": {
      "name": "Gaming - Immersive",
      "description": "High visual quality for single-player and immersive games",
      "category": "gaming",
      "priority": "quality",
      "settings": {
        "decoration": {
          "blur": true,
          "blur_size": 8,
          "blur_passes": 3,
          "drop_shadow": true,
          "shadow_range": 8,
          "rounding": 8
        },
        "animations": {
          "enabled": true,
          "bezier": "immersiveBezier, 0.05, 0.9, 0.1, 1.05",
          "animation_windows": "1, 6, immersiveBezier",
          "animation_workspaces": "1, 5, default"
        },
        "misc": {
          "vrr": 1,
          "allow_tearing": false
        }
      },
      "gpu_profile": "discrete",
      "applications": ["cyberpunk2077", "witcher3", "rdr2", "elden-ring"]
    },
    "streaming": {
      "name": "Streaming/Recording",
      "description": "Optimized for streaming and recording content",
      "category": "content",
      "priority": "balanced",
      "settings": {
        "decoration": {
          "blur": true,
          "blur_size": 4,
          "blur_passes": 2,
          "drop_shadow": true,
          "shadow_range": 4,
          "rounding": 6
        },
        "animations": {
          "enabled": true,
          "bezier": "streamBezier, 0.25, 0.1, 0.25, 1",
          "animation_windows": "1, 4, streamBezier",
          "animation_workspaces": "1, 3, default"
        },
        "misc": {
          "vfr": true,
          "vrr": 0
        }
      },
      "gpu_profile": "hybrid",
      "applications": ["obs-studio", "ffmpeg", "kdenlive"]
    },
    "productivity": {
      "name": "Productivity",
      "description": "Balanced settings for office work and productivity",
      "category": "work",
      "priority": "balanced",
      "settings": {
        "decoration": {
          "blur": true,
          "blur_size": 3,
          "blur_passes": 1,
          "drop_shadow": true,
          "shadow_range": 3,
          "rounding": 4
        },
        "animations": {
          "enabled": true,
          "bezier": "workBezier, 0.25, 0.1, 0.25, 1",
          "animation_windows": "1, 3, workBezier",
          "animation_workspaces": "1, 2, default"
        },
        "misc": {
          "vfr": true
        }
      },
      "gpu_profile": "balanced",
      "applications": ["firefox", "thunderbird", "libreoffice", "teams"]
    },
    "development": {
      "name": "Development",
      "description": "Optimized for coding and development environments",
      "category": "work",
      "priority": "performance",
      "settings": {
        "decoration": {
          "blur": false,
          "drop_shadow": true,
          "shadow_range": 2,
          "rounding": 2
        },
        "animations": {
          "enabled": true,
          "bezier": "devBezier, 0.23, 1, 0.32, 1",
          "animation_windows": "1, 2, devBezier",
          "animation_workspaces": "1, 1, default"
        },
        "misc": {
          "vfr": true,
          "focus_on_activate": true
        }
      },
      "gpu_profile": "integrated",
      "applications": ["code", "vim", "emacs", "jetbrains-*", "git"]
    },
    "content-creation": {
      "name": "Content Creation",
      "description": "Optimized for video editing, 3D work, and creative applications",
      "category": "creative",
      "priority": "performance",
      "settings": {
        "decoration": {
          "blur": true,
          "blur_size": 6,
          "blur_passes": 2,
          "drop_shadow": true,
          "shadow_range": 6,
          "rounding": 6
        },
        "animations": {
          "enabled": true,
          "bezier": "creativeBezier, 0.05, 0.9, 0.1, 1.05",
          "animation_windows": "1, 5, creativeBezier",
          "animation_workspaces": "1, 4, default"
        },
        "misc": {
          "vrr": 1,
          "allow_tearing": false
        }
      },
      "gpu_profile": "performance",
      "applications": ["blender", "davinci-resolve", "gimp", "inkscape", "krita"]
    },
    "ai-workload": {
      "name": "AI/ML Workloads",
      "description": "Optimized for AI training and machine learning tasks",
      "category": "compute",
      "priority": "performance",
      "settings": {
        "decoration": {
          "blur": false,
          "drop_shadow": false,
          "rounding": 0
        },
        "animations": {
          "enabled": false
        },
        "misc": {
          "vfr": true,
          "disable_hyprland_logo": true,
          "disable_splash_rendering": true
        }
      },
      "gpu_profile": "performance",
      "applications": ["python", "jupyter", "pytorch", "tensorflow", "conda"]
    },
    "presentation": {
      "name": "Presentation Mode",
      "description": "Clean, professional look for presentations and demos",
      "category": "work",
      "priority": "quality",
      "settings": {
        "decoration": {
          "blur": true,
          "blur_size": 5,
          "blur_passes": 2,
          "drop_shadow": true,
          "shadow_range": 5,
          "rounding": 8
        },
        "animations": {
          "enabled": true,
          "bezier": "presentBezier, 0.25, 0.1, 0.25, 1",
          "animation_windows": "1, 4, presentBezier",
          "animation_workspaces": "1, 3, default"
        },
        "misc": {
          "vfr": false,
          "vrr": 0
        }
      },
      "gpu_profile": "discrete",
      "applications": ["impress", "powerpoint", "teams", "zoom", "obs"]
    },
    "battery-extreme": {
      "name": "Battery Extreme",
      "description": "Maximum battery life with minimal visual effects",
      "category": "power",
      "priority": "efficiency",
      "settings": {
        "decoration": {
          "blur": false,
          "drop_shadow": false,
          "rounding": 0
        },
        "animations": {
          "enabled": false
        },
        "misc": {
          "vfr": true,
          "disable_hyprland_logo": true,
          "disable_splash_rendering": true,
          "no_cursor_warps": true
        }
      },
      "gpu_profile": "power-save",
      "applications": ["*"]
    },
    "troubleshooting": {
      "name": "Troubleshooting",
      "description": "Minimal effects for debugging and troubleshooting",
      "category": "debug",
      "priority": "stability",
      "settings": {
        "decoration": {
          "blur": false,
          "drop_shadow": false,
          "rounding": 0
        },
        "animations": {
          "enabled": false
        },
        "misc": {
          "vfr": true,
          "disable_hyprland_logo": true,
          "disable_splash_rendering": true,
          "debug": true
        }
      },
      "gpu_profile": "integrated",
      "applications": ["*"]
    }
  },
  "application_presets": {
    "blender": {
      "name": "Blender Optimization",
      "description": "Optimized specifically for Blender 3D work",
      "settings": {
        "decoration": {
          "blur": false,
          "drop_shadow": true,
          "shadow_range": 2,
          "rounding": 4
        },
        "animations": {
          "enabled": false
        },
        "misc": {
          "vrr": 1,
          "allow_tearing": true
        }
      },
      "gpu_profile": "performance",
      "process_name": "blender"
    },
    "obs": {
      "name": "OBS Studio",
      "description": "Optimized for OBS streaming and recording",
      "settings": {
        "decoration": {
          "blur": true,
          "blur_size": 3,
          "blur_passes": 1,
          "drop_shadow": true,
          "shadow_range": 3,
          "rounding": 4
        },
        "animations": {
          "enabled": true,
          "bezier": "obsBezier, 0.25, 0.1, 0.25, 1",
          "animation_windows": "1, 3, obsBezier"
        },
        "misc": {
          "vrr": 0,
          "vfr": true
        }
      },
      "gpu_profile": "hybrid",
      "process_name": "obs"
    },
    "steam-deck": {
      "name": "Steam Deck Mode",
      "description": "Optimized for Steam Deck gaming handheld",
      "settings": {
        "decoration": {
          "blur": true,
          "blur_size": 2,
          "blur_passes": 1,
          "drop_shadow": true,
          "shadow_range": 2,
          "rounding": 4
        },
        "animations": {
          "enabled": true,
          "bezier": "deckBezier, 0.25, 0.1, 0.25, 1",
          "animation_windows": "1, 2, deckBezier",
          "animation_workspaces": "1, 1, default"
        },
        "misc": {
          "vfr": true,
          "allow_tearing": true
        }
      },
      "gpu_profile": "balanced",
      "device_specific": "steam_deck"
    }
  }
}
EOF
    echo -e "${SUCCESS} Default presets created"
}

# List all available presets
list_presets() {
    initialize_presets
    
    echo -e "${INFO} Available GPU Presets:"
    echo
    
    # Built-in presets
    echo -e "${CYAN}=== BUILT-IN PRESETS ===${NC}"
    jq -r '.presets | to_entries[] | "\(.key)|\(.value.name)|\(.value.description)|\(.value.category)"' "$PRESETS_CONFIG" | while IFS='|' read -r key name desc category; do
        local category_color=""
        case "$category" in
            "gaming") category_color="${GREEN}" ;;
            "work") category_color="${BLUE}" ;;
            "creative") category_color="${PURPLE}" ;;
            "compute") category_color="${YELLOW}" ;;
            "power") category_color="${RED}" ;;
            "debug") category_color="${WHITE}" ;;
            *) category_color="${CYAN}" ;;
        esac
        
        printf "  ${category_color}%-20s${NC} %s\n" "$key" "$name"
        printf "    ${WHITE}↳${NC} %s\n" "$desc"
        printf "    ${WHITE}Category:${NC} %s\n\n" "$category"
    done
    
    # Application-specific presets
    echo -e "${CYAN}=== APPLICATION-SPECIFIC PRESETS ===${NC}"
    jq -r '.application_presets | to_entries[] | "\(.key)|\(.value.name)|\(.value.description)"' "$PRESETS_CONFIG" | while IFS='|' read -r key name desc; do
        printf "  ${YELLOW}%-20s${NC} %s\n" "$key" "$name"
        printf "    ${WHITE}↳${NC} %s\n\n" "$desc"
    done
    
    # Show active preset
    show_active_preset
}

# Show currently active preset
show_active_preset() {
    if [ -f "$ACTIVE_PRESET_FILE" ]; then
        local active=$(cat "$ACTIVE_PRESET_FILE")
        echo -e "${INFO} Currently Active: ${GREEN}$active${NC}"
    else
        echo -e "${INFO} No preset currently active"
    fi
}

# Apply a specific preset
apply_preset() {
    local preset_name="$1"
    local force="${2:-false}"
    
    initialize_presets
    
    # Check if preset exists
    if ! jq -e ".presets[\"$preset_name\"] // .application_presets[\"$preset_name\"]" "$PRESETS_CONFIG" > /dev/null 2>&1; then
        error_exit "Preset '$preset_name' not found. Use 'list' to see available presets."
    fi
    
    echo -e "${INFO} Applying preset: ${CYAN}$preset_name${NC}"
    
    # Get preset data
    local preset_data=""
    if jq -e ".presets[\"$preset_name\"]" "$PRESETS_CONFIG" > /dev/null 2>&1; then
        preset_data=$(jq ".presets[\"$preset_name\"]" "$PRESETS_CONFIG")
    else
        preset_data=$(jq ".application_presets[\"$preset_name\"]" "$PRESETS_CONFIG")
    fi
    
    local preset_desc=$(echo "$preset_data" | jq -r '.description')
    local gpu_profile=$(echo "$preset_data" | jq -r '.gpu_profile // "balanced"')
    
    echo -e "${INFO} Description: $preset_desc"
    echo -e "${INFO} GPU Profile: $gpu_profile"
    echo
    
    # Confirmation (unless forced)
    if [ "$force" != "true" ]; then
        read -p "Apply this preset? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${INFO} Preset application cancelled."
            exit 0
        fi
    fi
    
    # Apply GPU profile first
    echo -e "${INFO} Switching to GPU profile: $gpu_profile"
    if ! "$SCRIPT_DIR/gpu_switcher.sh" switch "$gpu_profile" --force; then
        error_exit "Failed to switch GPU profile"
    fi
    
    # Apply Hyprland configuration
    apply_hyprland_preset "$preset_name" "$preset_data"
    
    # Save active preset
    echo "$preset_name" > "$ACTIVE_PRESET_FILE"
    
    echo -e "${SUCCESS} Preset '$preset_name' applied successfully!"
    echo -e "${INFO} Please restart Hyprland or reload configuration for full effect."
    
    log "Applied preset: $preset_name"
}

# Apply Hyprland configuration from preset
apply_hyprland_preset() {
    local preset_name="$1"
    local preset_data="$2"
    
    local hypr_config="$HOME/.config/hypr/hyprland.conf"
    
    if [ ! -f "$hypr_config" ]; then
        echo -e "${WARNING} Hyprland config not found, skipping preset application"
        return
    fi
    
    echo -e "${INFO} Applying Hyprland preset configuration..."
    
    # Backup current config
    cp "$hypr_config" "${hypr_config}.preset_backup.$(date +%Y%m%d_%H%M%S)"
    
    # Remove existing preset settings
    sed -i '/# GPU_PRESET_START/,/# GPU_PRESET_END/d' "$hypr_config"
    
    # Generate preset configuration
    {
        echo
        echo "# GPU_PRESET_START - Auto-generated by HyprSupreme GPU Preset Manager"
        echo "# Preset: $preset_name"
        echo "# Generated: $(date)"
        echo
        
        # Decoration settings
        local decoration=$(echo "$preset_data" | jq '.settings.decoration // {}')
        if [ "$decoration" != "{}" ]; then
            echo "decoration {"
            
            local blur=$(echo "$decoration" | jq -r '.blur // empty')
            if [ -n "$blur" ]; then
                echo "    blur = $blur"
            fi
            
            local blur_size=$(echo "$decoration" | jq -r '.blur_size // empty')
            if [ -n "$blur_size" ]; then
                echo "    blur_size = $blur_size"
            fi
            
            local blur_passes=$(echo "$decoration" | jq -r '.blur_passes // empty')
            if [ -n "$blur_passes" ]; then
                echo "    blur_passes = $blur_passes"
            fi
            
            local drop_shadow=$(echo "$decoration" | jq -r '.drop_shadow // empty')
            if [ -n "$drop_shadow" ]; then
                echo "    drop_shadow = $drop_shadow"
            fi
            
            local shadow_range=$(echo "$decoration" | jq -r '.shadow_range // empty')
            if [ -n "$shadow_range" ]; then
                echo "    shadow_range = $shadow_range"
            fi
            
            local rounding=$(echo "$decoration" | jq -r '.rounding // empty')
            if [ -n "$rounding" ]; then
                echo "    rounding = $rounding"
            fi
            
            echo "}"
            echo
        fi
        
        # Animation settings
        local animations=$(echo "$preset_data" | jq '.settings.animations // {}')
        if [ "$animations" != "{}" ]; then
            echo "animations {"
            
            local enabled=$(echo "$animations" | jq -r '.enabled // empty')
            if [ -n "$enabled" ]; then
                echo "    enabled = $enabled"
            fi
            
            local bezier=$(echo "$animations" | jq -r '.bezier // empty')
            if [ -n "$bezier" ]; then
                echo "    bezier = $bezier"
            fi
            
            local anim_windows=$(echo "$animations" | jq -r '.animation_windows // empty')
            if [ -n "$anim_windows" ]; then
                echo "    animation = windows, $anim_windows"
            fi
            
            local anim_workspaces=$(echo "$animations" | jq -r '.animation_workspaces // empty')
            if [ -n "$anim_workspaces" ]; then
                echo "    animation = workspaces, $anim_workspaces"
            fi
            
            echo "}"
            echo
        fi
        
        # Misc settings
        local misc=$(echo "$preset_data" | jq '.settings.misc // {}')
        if [ "$misc" != "{}" ]; then
            echo "misc {"
            
            local vfr=$(echo "$misc" | jq -r '.vfr // empty')
            if [ -n "$vfr" ]; then
                echo "    vfr = $vfr"
            fi
            
            local vrr=$(echo "$misc" | jq -r '.vrr // empty')
            if [ -n "$vrr" ]; then
                echo "    vrr = $vrr"
            fi
            
            local allow_tearing=$(echo "$misc" | jq -r '.allow_tearing // empty')
            if [ -n "$allow_tearing" ]; then
                echo "    allow_tearing = $allow_tearing"
            fi
            
            local disable_logo=$(echo "$misc" | jq -r '.disable_hyprland_logo // empty')
            if [ -n "$disable_logo" ]; then
                echo "    disable_hyprland_logo = $disable_logo"
            fi
            
            local no_cursor_warps=$(echo "$misc" | jq -r '.no_cursor_warps // empty')
            if [ -n "$no_cursor_warps" ]; then
                echo "    no_cursor_warps = $no_cursor_warps"
            fi
            
            echo "}"
            echo
        fi
        
        echo "# GPU_PRESET_END"
        echo
    } >> "$hypr_config"
    
    echo -e "${SUCCESS} Hyprland preset configuration applied"
}

# Create custom preset interactively
create_custom_preset() {
    local preset_name="$1"
    
    if [ -z "$preset_name" ]; then
        read -p "Enter preset name: " preset_name
    fi
    
    # Validate preset name
    if [[ ! "$preset_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error_exit "Invalid preset name. Use only letters, numbers, hyphens, and underscores."
    fi
    
    initialize_presets
    
    # Check if preset already exists
    if jq -e ".presets[\"$preset_name\"] // .application_presets[\"$preset_name\"]" "$PRESETS_CONFIG" > /dev/null 2>&1; then
        read -p "Preset '$preset_name' already exists. Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${INFO} Preset creation cancelled."
            exit 0
        fi
    fi
    
    echo -e "${INFO} Creating custom preset: ${CYAN}$preset_name${NC}"
    echo
    
    # Interactive configuration
    read -p "Description: " preset_desc
    
    echo "Select category:"
    echo "1) Gaming"
    echo "2) Work/Productivity"
    echo "3) Creative/Content"
    echo "4) Computing/AI"
    echo "5) Power/Battery"
    echo "6) Debug/Troubleshooting"
    read -p "Choice (1-6): " category_choice
    
    local category="custom"
    case "$category_choice" in
        1) category="gaming" ;;
        2) category="work" ;;
        3) category="creative" ;;
        4) category="compute" ;;
        5) category="power" ;;
        6) category="debug" ;;
    esac
    
    echo "Select GPU profile:"
    echo "1) Integrated"
    echo "2) Discrete"
    echo "3) Hybrid"
    echo "4) Performance"
    echo "5) Power-save"
    echo "6) Balanced"
    read -p "Choice (1-6): " gpu_choice
    
    local gpu_profile="balanced"
    case "$gpu_choice" in
        1) gpu_profile="integrated" ;;
        2) gpu_profile="discrete" ;;
        3) gpu_profile="hybrid" ;;
        4) gpu_profile="performance" ;;
        5) gpu_profile="power-save" ;;
        6) gpu_profile="balanced" ;;
    esac
    
    # Visual effects configuration
    echo
    echo "Configure visual effects:"
    read -p "Enable blur? (y/N): " blur_choice
    local blur="false"
    local blur_size=3
    local blur_passes=1
    if [[ $blur_choice =~ ^[Yy]$ ]]; then
        blur="true"
        read -p "Blur size (1-10): " blur_size
        read -p "Blur passes (1-4): " blur_passes
    fi
    
    read -p "Enable animations? (y/N): " anim_choice
    local animations="false"
    if [[ $anim_choice =~ ^[Yy]$ ]]; then
        animations="true"
    fi
    
    read -p "Enable drop shadows? (y/N): " shadow_choice
    local shadows="false"
    local shadow_range=4
    if [[ $shadow_choice =~ ^[Yy]$ ]]; then
        shadows="true"
        read -p "Shadow range (1-10): " shadow_range
    fi
    
    read -p "Corner rounding (0-20): " rounding
    
    # Create preset JSON
    local temp_file=$(mktemp)
    jq --arg name "$preset_name" \
       --arg desc "$preset_desc" \
       --arg category "$category" \
       --arg gpu_profile "$gpu_profile" \
       --argjson blur "$blur" \
       --argjson blur_size "$blur_size" \
       --argjson blur_passes "$blur_passes" \
       --argjson drop_shadow "$shadows" \
       --argjson shadow_range "$shadow_range" \
       --argjson rounding "$rounding" \
       --argjson animations "$animations" \
       '.presets[$name] = {
         "name": $name,
         "description": $desc,
         "category": $category,
         "priority": "custom",
         "settings": {
           "decoration": {
             "blur": $blur,
             "blur_size": $blur_size,
             "blur_passes": $blur_passes,
             "drop_shadow": $drop_shadow,
             "shadow_range": $shadow_range,
             "rounding": $rounding
           },
           "animations": {
             "enabled": $animations
           },
           "misc": {
             "vfr": true
           }
         },
         "gpu_profile": $gpu_profile,
         "applications": ["custom"]
       }' "$PRESETS_CONFIG" > "$temp_file" && mv "$temp_file" "$PRESETS_CONFIG"
    
    echo -e "${SUCCESS} Custom preset '$preset_name' created successfully!"
    echo -e "${INFO} Use 'gpu_presets.sh apply $preset_name' to apply it."
    
    log "Created custom preset: $preset_name"
}

# Main function
main() {
    case "${1:-}" in
        "list")
            list_presets
            ;;
        "apply")
            if [ -z "${2:-}" ]; then
                error_exit "Preset name required for apply command"
            fi
            local force_flag=false
            if [ "${3:-}" = "--force" ]; then
                force_flag=true
            fi
            apply_preset "$2" "$force_flag"
            ;;
        "create")
            create_custom_preset "${2:-}"
            ;;
        "active")
            show_active_preset
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

