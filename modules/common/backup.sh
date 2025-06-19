#!/bin/bash
# HyprSupreme-Builder - Configuration Backup Utility

# Exit on any error, undefined variable, or pipe failure
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/functions.sh"

# Backup configuration
backup_existing_configs() {
    local backup_reason="${1:-manual}"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="$HOME/.config/hyprsupreme-backups/$backup_reason-$timestamp"
    
    log_info "Creating backup of existing configurations..."
    log_info "Backup directory: $backup_dir"
    
    mkdir -p "$backup_dir"
    
    # Export backup directory for cleanup trap
    export CURRENT_BACKUP_DIR="$backup_dir"
    
    # List of directories to backup
    local config_dirs=(
        ".config/hypr"
        ".config/waybar" 
        ".config/rofi"
        ".config/kitty"
        ".config/ags"
        ".config/dunst"
        ".config/sddm"
        ".config/gtk-3.0"
        ".config/gtk-4.0"
        ".local/share/themes"
        ".local/share/icons"
        ".local/share/fonts"
        ".local/share/wallpapers"
    )
    
    # List of individual files to backup
    local config_files=(
        ".bashrc"
        ".zshrc"
        ".xinitrc"
        ".Xresources"
        ".gtkrc-2.0"
    )
    
    local backed_up_count=0
    local total_items=$((${#config_dirs[@]} + ${#config_files[@]}))
    
    # Backup directories
    for dir in "${config_dirs[@]}"; do
        local full_path="$HOME/$dir"
        if [[ -d "$full_path" ]]; then
            log_info "Backing up directory: $dir"
            mkdir -p "$backup_dir/$(dirname "$dir")"
            cp -r "$full_path" "$backup_dir/$dir" || {
                log_warn "Failed to backup $dir (permissions?)"
            }
        else
            log_info "Directory not found, skipping: $dir"
        fi
        
        ((backed_up_count++))
        show_progress $backed_up_count $total_items "Backing up configurations"
    done
    
    # Backup individual files
    for file in "${config_files[@]}"; do
        local full_path="$HOME/$file"
        if [[ -f "$full_path" ]]; then
            log_info "Backing up file: $file"
            mkdir -p "$backup_dir/$(dirname "$file")"
            cp "$full_path" "$backup_dir/$file" || {
                log_warn "Failed to backup $file (permissions?)"
            }
        else
            log_info "File not found, skipping: $file"
        fi
        
        ((backed_up_count++))
        show_progress $backed_up_count $total_items "Backing up configurations"
    done
    
    # Create backup manifest
    create_backup_manifest "$backup_dir"
    
    # Create restore script
    create_restore_script "$backup_dir"
    
    log_success "Backup completed successfully!"
    log_info "Backup location: $backup_dir"
    log_info "To restore: bash $backup_dir/restore.sh"
    
    echo "$backup_dir"
}

# Create backup manifest
create_backup_manifest() {
    local backup_dir="$1"
    local manifest_file="$backup_dir/MANIFEST.txt"
    
    log_info "Creating backup manifest..."
    
    cat > "$manifest_file" << EOF
# HyprSupreme-Builder Configuration Backup Manifest
# Created: $(date)
# Hostname: $(hostname)
# User: $USER
# Backup Directory: $backup_dir

=== SYSTEM INFO ===
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel: $(uname -r)
Shell: $SHELL
Desktop Session: ${XDG_CURRENT_DESKTOP:-Unknown}

=== BACKED UP FILES ===
EOF
    
    # List all backed up files with sizes
    find "$backup_dir" -type f ! -name "MANIFEST.txt" ! -name "restore.sh" -exec ls -lh {} \; | \
        awk '{print $9 " (" $5 ")"}' | \
        sed "s|$backup_dir/||g" >> "$manifest_file"
    
    log_success "Backup manifest created: $manifest_file"
}

# Create restore script
create_restore_script() {
    local backup_dir="$1"
    local restore_script="$backup_dir/restore.sh"
    
    log_info "Creating restore script..."
    
    cat > "$restore_script" << 'EOF'
#!/bin/bash
# HyprSupreme-Builder Configuration Restore Script
# This script will restore configurations from this backup

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get backup directory
BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo -e "${BLUE}HyprSupreme-Builder Configuration Restore${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will overwrite your current configurations!${NC}"
echo -e "${YELLOW}Current configs will be backed up before restoration.${NC}"
echo ""
echo "Backup source: $BACKUP_DIR"
echo "Restore target: $HOME"
echo ""

# Confirm restoration
read -p "Do you want to proceed with restoration? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restoration cancelled."
    exit 0
fi

# Create safety backup before restore
echo -e "${BLUE}Creating safety backup of current configs...${NC}"
SAFETY_BACKUP="$HOME/.config/hyprsupreme-backups/pre-restore-$TIMESTAMP"
mkdir -p "$SAFETY_BACKUP"

# Find all config directories in backup
find "$BACKUP_DIR" -type d | while read -r dir; do
    relative_path="${dir#$BACKUP_DIR/}"
    if [[ -n "$relative_path" && -d "$HOME/$relative_path" ]]; then
        echo "Backing up current: $relative_path"
        mkdir -p "$SAFETY_BACKUP/$(dirname "$relative_path")" 2>/dev/null || true
        cp -r "$HOME/$relative_path" "$SAFETY_BACKUP/$relative_path" 2>/dev/null || true
    fi
done

echo -e "${GREEN}Safety backup created: $SAFETY_BACKUP${NC}"

# Restore configurations
echo -e "${BLUE}Restoring configurations...${NC}"

# Copy all backed up files
find "$BACKUP_DIR" -type f ! -name "MANIFEST.txt" ! -name "restore.sh" | while read -r file; do
    relative_path="${file#$BACKUP_DIR/}"
    target_path="$HOME/$relative_path"
    target_dir="$(dirname "$target_path")"
    
    echo "Restoring: $relative_path"
    mkdir -p "$target_dir"
    cp "$file" "$target_path"
done

echo ""
echo -e "${GREEN}Configuration restoration completed!${NC}"
echo -e "${YELLOW}Please log out and log back in for all changes to take effect.${NC}"
echo ""
echo "Safety backup available at: $SAFETY_BACKUP"
EOF
    
    chmod +x "$restore_script"
    log_success "Restore script created: $restore_script"
}

# List available backups
list_backups() {
    local backup_base_dir="$HOME/.config/hyprsupreme-backups"
    
    if [[ ! -d "$backup_base_dir" ]]; then
        log_info "No backups found. Backup directory doesn't exist: $backup_base_dir"
        return 0
    fi
    
    log_info "Available configuration backups:"
    echo ""
    
    local backup_count=0
    while IFS= read -r -d '' backup_dir; do
        local backup_name=$(basename "$backup_dir")
        local backup_date=$(echo "$backup_name" | grep -o '[0-9]\{8\}-[0-9]\{6\}' || echo "unknown")
        local backup_size=$(du -sh "$backup_dir" 2>/dev/null | cut -f1 || echo "unknown")
        local manifest_file="$backup_dir/MANIFEST.txt"
        
        echo "  📁 $backup_name"
        echo "     Size: $backup_size"
        echo "     Date: $backup_date"
        
        if [[ -f "$manifest_file" ]]; then
            local file_count=$(grep -c "^/" "$manifest_file" 2>/dev/null || echo "unknown")
            echo "     Files: $file_count"
        fi
        
        echo "     Restore: bash $backup_dir/restore.sh"
        echo ""
        
        ((backup_count++))
    done < <(find "$backup_base_dir" -maxdepth 1 -type d ! -path "$backup_base_dir" -print0 2>/dev/null | sort -z)
    
    if [[ $backup_count -eq 0 ]]; then
        log_info "No backups found in $backup_base_dir"
    else
        log_info "Found $backup_count backup(s)"
    fi
}

# Clean old backups
clean_old_backups() {
    local backup_base_dir="$HOME/.config/hyprsupreme-backups"
    local days_to_keep="${1:-30}"
    
    if [[ ! -d "$backup_base_dir" ]]; then
        log_info "No backup directory found: $backup_base_dir"
        return 0
    fi
    
    log_info "Cleaning backups older than $days_to_keep days..."
    
    local cleaned_count=0
    while IFS= read -r -d '' backup_dir; do
        if [[ -d "$backup_dir" ]]; then
            log_info "Removing old backup: $(basename "$backup_dir")"
            rm -rf "$backup_dir"
            ((cleaned_count++))
        fi
    done < <(find "$backup_base_dir" -maxdepth 1 -type d -mtime +$days_to_keep -print0 2>/dev/null)
    
    if [[ $cleaned_count -eq 0 ]]; then
        log_info "No old backups to clean"
    else
        log_success "Cleaned $cleaned_count old backup(s)"
    fi
}

# Main function
main() {
    case "${1:-backup}" in
        "backup")
            backup_existing_configs "${2:-manual}"
            ;;
        "list")
            list_backups
            ;;
        "clean")
            clean_old_backups "${2:-30}"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [backup|list|clean] [options]"
            echo ""
            echo "Commands:"
            echo "  backup [reason]     Create backup (default: manual)"
            echo "  list               List available backups"
            echo "  clean [days]       Clean backups older than N days (default: 30)"
            echo "  help               Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 backup pre-install"
            echo "  $0 list"
            echo "  $0 clean 7"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

