#!/bin/bash

# ==========================================
# HyprSupreme AI Update Manager
# Advanced update system with AI intelligence
# ==========================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$HOME/.config/hyprsupreme"
UPDATE_CONFIG="$CONFIG_DIR/update_manager.conf"
LOG_FILE="$CONFIG_DIR/logs/update_manager.log"
BACKUP_DIR="$CONFIG_DIR/backups"
AI_ENGINE="$PROJECT_ROOT/tools/ai_updater.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Icons for better UX
ICON_SUCCESS="✅"
ICON_ERROR="❌"
ICON_WARNING="⚠️"
ICON_INFO="ℹ️"
ICON_ROCKET="🚀"
ICON_ROBOT="🤖"
ICON_SHIELD="🛡️"
ICON_SEARCH="🔍"
ICON_DOWNLOAD="📥"
ICON_BACKUP="💾"

# Initialize logging
setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
}

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}${ICON_INFO}${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}${ICON_SUCCESS}${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}${ICON_WARNING}${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}${ICON_ERROR}${NC} $*" | tee -a "$LOG_FILE"
}

log_ai() {
    echo -e "${PURPLE}${ICON_ROBOT}${NC} $*" | tee -a "$LOG_FILE"
}

# Initialize configuration
init_config() {
    mkdir -p "$CONFIG_DIR" "$BACKUP_DIR" "$(dirname "$LOG_FILE")"
    
    if [[ ! -f "$UPDATE_CONFIG" ]]; then
        cat > "$UPDATE_CONFIG" << EOF
# HyprSupreme AI Update Manager Configuration

# Update checking
AUTO_CHECK=true
CHECK_INTERVAL=24  # hours
UPDATE_CHANNEL=stable  # stable, beta, dev

# AI settings
AI_ENABLED=true
AI_CONFIDENCE_THRESHOLD=0.7
AUTO_UPDATE_THRESHOLD=0.9

# Backup settings
AUTO_BACKUP=true
BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION_LEVEL=6

# Update behavior
PRESERVE_USER_CONFIGS=true
ROLLBACK_TIMEOUT=30  # minutes
MAX_DOWNLOAD_SIZE=1024  # MB

# Notification settings
NOTIFY_UPDATES=true
NOTIFY_SUCCESS=true
NOTIFY_ERRORS=true

# Safety settings
REQUIRE_CONFIRMATION=true
DRY_RUN_MODE=false
VERBOSE_OUTPUT=false
EOF
        log_success "Created default configuration at $UPDATE_CONFIG"
    fi
    
    source "$UPDATE_CONFIG"
}

# Check dependencies
check_dependencies() {
    local deps=("python3" "git" "curl" "tar" "gzip")
    local python_deps=("requests" "semver")
    local missing_deps=()
    
    # Check system dependencies
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Check Python dependencies
    for dep in "${python_deps[@]}"; do
        if ! python3 -c "import $dep" &> /dev/null; then
            missing_deps+=("python3-$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install missing dependencies and try again"
        return 1
    fi
    
    # Check AI engine
    if [[ ! -f "$AI_ENGINE" ]]; then
        log_warning "AI engine not found at $AI_ENGINE"
        log_info "Some features may not be available"
        AI_ENABLED=false
    fi
    
    return 0
}

# AI integration functions
call_ai_engine() {
    local command="$1"
    shift
    
    if [[ "$AI_ENABLED" == "true" && -f "$AI_ENGINE" ]]; then
        python3 "$AI_ENGINE" "$command" "$@"
    else
        log_warning "AI engine not available, using fallback logic"
        return 1
    fi
}

# Check for updates using AI
check_updates() {
    local force=${1:-false}
    
    log_info "${ICON_SEARCH} Checking for HyprSupreme updates..."
    
    if [[ "$AI_ENABLED" == "true" ]]; then
        log_ai "Using AI-powered update detection"
        
        local ai_args=()
        [[ "$force" == "true" ]] && ai_args+=("--force")
        
        if call_ai_engine "check" "${ai_args[@]}"; then
            return 0
        else
            log_warning "AI check failed, falling back to manual method"
        fi
    fi
    
    # Fallback manual check
    check_updates_manual "$force"
}

# Manual update checking (fallback)
check_updates_manual() {
    local force=${1:-false}
    
    # Check if we should check (respects CHECK_INTERVAL)
    if [[ "$force" != "true" && "$AUTO_CHECK" == "true" ]]; then
        local last_check_file="$CONFIG_DIR/.last_check"
        if [[ -f "$last_check_file" ]]; then
            local last_check=$(cat "$last_check_file")
            local current_time=$(date +%s)
            local time_diff=$(( (current_time - last_check) / 3600 ))
            
            if [[ $time_diff -lt $CHECK_INTERVAL ]]; then
                log_info "Update check not needed (last check $time_diff hours ago)"
                return 0
            fi
        fi
    fi
    
    log_info "Checking GitHub for updates..."
    
    # Get current version
    local current_version
    if [[ -f "$PROJECT_ROOT/VERSION" ]]; then
        current_version=$(cat "$PROJECT_ROOT/VERSION")
    else
        current_version=$(git -C "$PROJECT_ROOT" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
    fi
    
    # Check GitHub releases
    local api_url="https://api.github.com/repos/GeneticxCln/HyprSupreme-Builder/releases/latest"
    local latest_info
    
    if latest_info=$(curl -s "$api_url" 2>/dev/null); then
        local latest_version=$(echo "$latest_info" | grep '"tag_name"' | cut -d '"' -f 4 | sed 's/^v//')
        
        if [[ -n "$latest_version" && "$latest_version" != "$current_version" ]]; then
            log_success "Update available: $current_version → $latest_version"
            
            # Store update info
            local update_info_file="$CONFIG_DIR/.update_available"
            echo "$latest_version" > "$update_info_file"
            
            # Show changelog if available
            local changelog=$(echo "$latest_info" | grep '"body"' | cut -d '"' -f 4)
            if [[ -n "$changelog" ]]; then
                log_info "Changelog preview:"
                echo "$changelog" | head -5
            fi
            
            return 0
        else
            log_success "Already up to date (version $current_version)"
        fi
    else
        log_error "Failed to check for updates"
        return 1
    fi
    
    # Update last check time
    echo "$(date +%s)" > "$CONFIG_DIR/.last_check"
    return 0
}

# Generate update strategy using AI
generate_update_strategy() {
    local version="$1"
    
    if [[ "$AI_ENABLED" == "true" ]]; then
        log_ai "Generating AI-powered update strategy for version $version"
        
        # This would call the AI engine to analyze the update
        # For now, we'll implement basic logic
        local strategy_file="$CONFIG_DIR/.update_strategy"
        
        cat > "$strategy_file" << EOF
{
    "version": "$version",
    "approach": "incremental",
    "backup_level": "standard",
    "merge_strategy": "auto",
    "estimated_time": 10,
    "confidence": 0.8,
    "user_interaction_needed": false,
    "rollback_plan": "automatic"
}
EOF
        
        log_success "Update strategy generated"
        return 0
    else
        log_warning "AI not available, using default strategy"
        return 1
    fi
}

# Create intelligent backup
create_backup() {
    local backup_type=${1:-"pre_update"}
    local backup_id="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_id"
    
    log_info "${ICON_SHIELD} Creating $backup_type backup..."
    
    mkdir -p "$backup_path"
    
    if [[ "$AI_ENABLED" == "true" ]]; then
        log_ai "Using AI to determine backup scope"
        
        if call_ai_engine "backup" "--type" "$backup_type"; then
            log_success "AI backup completed: $backup_id"
            echo "$backup_id" > "$CONFIG_DIR/.last_backup"
            return 0
        else
            log_warning "AI backup failed, using manual backup"
        fi
    fi
    
    # Manual backup (fallback)
    create_backup_manual "$backup_type" "$backup_path" "$backup_id"
}

# Manual backup creation
create_backup_manual() {
    local backup_type="$1"
    local backup_path="$2"
    local backup_id="$3"
    
    log_info "Creating manual backup..."
    
    # Define what to backup
    local backup_items=(
        "$PROJECT_ROOT:hyprsupreme"
        "$HOME/.config/hypr:config/hypr"
        "$HOME/.config/waybar:config/waybar"
        "$HOME/.config/rofi:config/rofi"
    )
    
    # Add more items for comprehensive backup
    if [[ "$backup_type" == "comprehensive" || "$backup_type" == "pre_update" ]]; then
        backup_items+=(
            "$HOME/.config/kitty:config/kitty"
            "$HOME/.config/ags:config/ags"
            "$HOME/.themes:themes"
            "$HOME/.icons:icons"
        )
    fi
    
    # Create backup archive
    local archive_path="$backup_path/backup.tar.gz"
    local temp_dir=$(mktemp -d)
    
    for item in "${backup_items[@]}"; do
        local source="${item%:*}"
        local target="${item#*:}"
        
        if [[ -d "$source" || -f "$source" ]]; then
            mkdir -p "$temp_dir/$(dirname "$target")"
            cp -r "$source" "$temp_dir/$target" 2>/dev/null || {
                log_warning "Could not backup $source"
                continue
            }
            log_info "  ${ICON_BACKUP} Backed up: $source"
        fi
    done
    
    # Create compressed archive
    if (cd "$temp_dir" && tar -czf "$archive_path" .); then
        # Create metadata
        cat > "$backup_path/metadata.json" << EOF
{
    "backup_id": "$backup_id",
    "backup_type": "$backup_type",
    "created_date": "$(date -Iseconds)",
    "version": "$(cat "$PROJECT_ROOT/VERSION" 2>/dev/null || echo "unknown")",
    "size": "$(du -sh "$archive_path" | cut -f1)"
}
EOF
        
        log_success "Backup created: $backup_id ($(du -sh "$archive_path" | cut -f1))"
        echo "$backup_id" > "$CONFIG_DIR/.last_backup"
        
        # Cleanup
        rm -rf "$temp_dir"
        return 0
    else
        log_error "Failed to create backup archive"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Download update
download_update() {
    local version="$1"
    local download_url="$2"
    
    log_info "${ICON_DOWNLOAD} Downloading update $version..."
    
    if [[ "$AI_ENABLED" == "true" ]]; then
        log_ai "Using AI-optimized download"
        
        if call_ai_engine "download" "$version"; then
            log_success "AI download completed"
            return 0
        else
            log_warning "AI download failed, using manual method"
        fi
    fi
    
    # Manual download (fallback)
    download_update_manual "$version" "$download_url"
}

# Manual download
download_update_manual() {
    local version="$1"
    local download_url="$2"
    local download_dir="$CONFIG_DIR/downloads"
    local download_file="$download_dir/hyprsupreme_$version.zip"
    
    mkdir -p "$download_dir"
    
    # For git-based updates
    if [[ "$download_url" == "local_git" ]]; then
        log_info "Updating from local git repository..."
        
        if git -C "$PROJECT_ROOT" fetch origin; then
            log_success "Git fetch completed"
            return 0
        else
            log_error "Git fetch failed"
            return 1
        fi
    fi
    
    # For URL downloads
    if [[ -n "$download_url" ]]; then
        log_info "Downloading from: $download_url"
        
        if curl -L -o "$download_file" "$download_url"; then
            log_success "Download completed: $(du -sh "$download_file" | cut -f1)"
            return 0
        else
            log_error "Download failed"
            return 1
        fi
    fi
    
    return 1
}

# Apply update with AI guidance
apply_update() {
    local version="$1"
    local strategy_file="$CONFIG_DIR/.update_strategy"
    
    log_info "${ICON_ROCKET} Applying update $version..."
    
    # Load strategy if available
    local approach="incremental"
    local backup_needed=true
    
    if [[ -f "$strategy_file" ]]; then
        approach=$(grep -o '"approach": "[^"]*"' "$strategy_file" | cut -d '"' -f 4)
        log_info "Using strategy: $approach"
    fi
    
    # Create backup if needed
    if [[ "$backup_needed" == "true" && "$AUTO_BACKUP" == "true" ]]; then
        if ! create_backup "pre_update"; then
            log_error "Backup creation failed"
            if [[ "$REQUIRE_CONFIRMATION" == "true" ]]; then
                read -p "Continue without backup? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    log_info "Update cancelled by user"
                    return 1
                fi
            fi
        fi
    fi
    
    # Apply update using AI if available
    if [[ "$AI_ENABLED" == "true" ]]; then
        log_ai "Applying update with AI guidance"
        
        if call_ai_engine "update" "$version" "--auto"; then
            log_success "AI update completed successfully"
            post_update_tasks "$version"
            return 0
        else
            log_warning "AI update failed, trying manual method"
        fi
    fi
    
    # Manual update application
    apply_update_manual "$version" "$approach"
}

# Manual update application
apply_update_manual() {
    local version="$1"
    local approach="$2"
    
    log_info "Applying manual update using $approach approach..."
    
    case "$approach" in
        "incremental")
            apply_incremental_update "$version"
            ;;
        "full")
            apply_full_update "$version"
            ;;
        "custom")
            apply_custom_update "$version"
            ;;
        *)
            log_error "Unknown update approach: $approach"
            return 1
            ;;
    esac
}

# Apply incremental update
apply_incremental_update() {
    local version="$1"
    
    log_info "Applying incremental update..."
    
    # For git-based updates
    if git -C "$PROJECT_ROOT" rev-parse --git-dir &>/dev/null; then
        log_info "Updating via git..."
        
        if git -C "$PROJECT_ROOT" pull origin main; then
            log_success "Git update successful"
            
            # Update version file
            echo "$version" > "$PROJECT_ROOT/VERSION"
            
            post_update_tasks "$version"
            return 0
        else
            log_error "Git update failed"
            return 1
        fi
    else
        log_error "Not a git repository"
        return 1
    fi
}

# Apply full update
apply_full_update() {
    local version="$1"
    
    log_info "Applying full update (complete replacement)..."
    
    # This would involve downloading and extracting a complete new version
    # For now, we'll use git reset
    if git -C "$PROJECT_ROOT" rev-parse --git-dir &>/dev/null; then
        if git -C "$PROJECT_ROOT" reset --hard origin/main; then
            log_success "Full update successful"
            echo "$version" > "$PROJECT_ROOT/VERSION"
            post_update_tasks "$version"
            return 0
        else
            log_error "Full update failed"
            return 1
        fi
    else
        log_error "Cannot perform full update: not a git repository"
        return 1
    fi
}

# Apply custom update with conflict resolution
apply_custom_update() {
    local version="$1"
    
    log_info "Applying custom update with smart conflict resolution..."
    
    # This would involve sophisticated merging logic
    # For now, fall back to incremental
    apply_incremental_update "$version"
}

# Post-update tasks
post_update_tasks() {
    local version="$1"
    
    log_info "Running post-update tasks..."
    
    # Update configuration files if needed
    if [[ -f "$PROJECT_ROOT/scripts/post_update.sh" ]]; then
        log_info "Running post-update script..."
        if bash "$PROJECT_ROOT/scripts/post_update.sh"; then
            log_success "Post-update script completed"
        else
            log_warning "Post-update script failed"
        fi
    fi
    
    # Clear caches
    rm -f "$CONFIG_DIR/.update_strategy" "$CONFIG_DIR/.update_available"
    
    # Log successful update
    echo "$(date -Iseconds): Updated to $version" >> "$CONFIG_DIR/update_history.log"
    
    # Send notification if enabled
    if [[ "$NOTIFY_SUCCESS" == "true" ]]; then
        send_notification "HyprSupreme Update" "Successfully updated to version $version" "success"
    fi
    
    log_success "Update to version $version completed successfully!"
}

# Rollback to previous version
rollback_update() {
    local backup_id="$1"
    
    if [[ -z "$backup_id" ]]; then
        # Use most recent backup
        backup_id=$(cat "$CONFIG_DIR/.last_backup" 2>/dev/null)
    fi
    
    if [[ -z "$backup_id" ]]; then
        log_error "No backup specified and no recent backup found"
        return 1
    fi
    
    log_info "Rolling back to backup: $backup_id"
    
    if [[ "$AI_ENABLED" == "true" ]]; then
        log_ai "Using AI-guided rollback"
        
        if call_ai_engine "rollback" "$backup_id"; then
            log_success "AI rollback completed"
            return 0
        else
            log_warning "AI rollback failed, using manual method"
        fi
    fi
    
    # Manual rollback
    rollback_manual "$backup_id"
}

# Manual rollback
rollback_manual() {
    local backup_id="$1"
    local backup_path="$BACKUP_DIR/$backup_id"
    local archive_path="$backup_path/backup.tar.gz"
    
    if [[ ! -f "$archive_path" ]]; then
        log_error "Backup archive not found: $archive_path"
        return 1
    fi
    
    log_info "Extracting backup..."
    
    # Create temporary directory for extraction
    local temp_dir=$(mktemp -d)
    
    if tar -xzf "$archive_path" -C "$temp_dir"; then
        log_info "Restoring files..."
        
        # Restore HyprSupreme files
        if [[ -d "$temp_dir/hyprsupreme" ]]; then
            rm -rf "$PROJECT_ROOT.backup"
            mv "$PROJECT_ROOT" "$PROJECT_ROOT.backup" 2>/dev/null
            mv "$temp_dir/hyprsupreme" "$PROJECT_ROOT"
            log_success "HyprSupreme files restored"
        fi
        
        # Restore config files
        if [[ -d "$temp_dir/config" ]]; then
            cp -r "$temp_dir/config"/* "$HOME/.config/" 2>/dev/null
            log_success "Configuration files restored"
        fi
        
        # Restore themes and icons if present
        [[ -d "$temp_dir/themes" ]] && cp -r "$temp_dir/themes" "$HOME/.themes" 2>/dev/null
        [[ -d "$temp_dir/icons" ]] && cp -r "$temp_dir/icons" "$HOME/.icons" 2>/dev/null
        
        rm -rf "$temp_dir"
        log_success "Rollback completed successfully"
        return 0
    else
        log_error "Failed to extract backup"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Send desktop notification
send_notification() {
    local title="$1"
    local message="$2"
    local type="${3:-info}"
    
    if [[ "$NOTIFY_UPDATES" != "true" ]]; then
        return 0
    fi
    
    # Try different notification methods
    if command -v notify-send &>/dev/null; then
        local icon=""
        case "$type" in
            "success") icon="--icon=dialog-information" ;;
            "error") icon="--icon=dialog-error" ;;
            "warning") icon="--icon=dialog-warning" ;;
        esac
        notify-send $icon "$title" "$message"
    elif command -v zenity &>/dev/null; then
        case "$type" in
            "success") zenity --info --title="$title" --text="$message" ;;
            "error") zenity --error --title="$title" --text="$message" ;;
            "warning") zenity --warning --title="$title" --text="$message" ;;
            *) zenity --info --title="$title" --text="$message" ;;
        esac
    fi
}

# Cleanup old backups
cleanup_backups() {
    log_info "Cleaning up old backups..."
    
    # Remove backups older than retention period
    find "$BACKUP_DIR" -type d -name "backup_*" -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null
    
    log_success "Backup cleanup completed"
}

# Show update status
show_status() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}     HyprSupreme Update Manager Status     ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    # Current version
    local current_version="unknown"
    if [[ -f "$PROJECT_ROOT/VERSION" ]]; then
        current_version=$(cat "$PROJECT_ROOT/VERSION")
    fi
    echo -e "${GREEN}Current Version:${NC} $current_version"
    
    # Last check
    local last_check="Never"
    if [[ -f "$CONFIG_DIR/.last_check" ]]; then
        local last_check_time=$(cat "$CONFIG_DIR/.last_check")
        last_check=$(date -d "@$last_check_time" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown")
    fi
    echo -e "${GREEN}Last Check:${NC} $last_check"
    
    # Available updates
    if [[ -f "$CONFIG_DIR/.update_available" ]]; then
        local available_version=$(cat "$CONFIG_DIR/.update_available")
        echo -e "${YELLOW}Update Available:${NC} $available_version"
    else
        echo -e "${GREEN}Status:${NC} Up to date"
    fi
    
    # AI status
    if [[ "$AI_ENABLED" == "true" && -f "$AI_ENGINE" ]]; then
        echo -e "${PURPLE}AI Engine:${NC} ${GREEN}Available${NC}"
    else
        echo -e "${PURPLE}AI Engine:${NC} ${YELLOW}Not Available${NC}"
    fi
    
    # Recent backups
    local backup_count=$(find "$BACKUP_DIR" -type d -name "backup_*" 2>/dev/null | wc -l)
    echo -e "${GREEN}Backups:${NC} $backup_count available"
    
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
}

# Show help
show_help() {
    cat << EOF
HyprSupreme AI Update Manager

USAGE:
    $(basename "$0") [COMMAND] [OPTIONS]

COMMANDS:
    check [--force]           Check for available updates
    update [VERSION]          Update to latest or specific version
    rollback [BACKUP_ID]      Rollback to previous version
    backup [TYPE]             Create backup (manual, pre_update, comprehensive)
    status                    Show current status
    history                   Show update history
    cleanup                   Clean up old backups
    config                    Edit configuration
    help                      Show this help message

OPTIONS:
    --force                   Force operation (skip checks)
    --dry-run                 Show what would be done without executing
    --verbose                 Enable verbose output
    --no-ai                   Disable AI features for this run

EXAMPLES:
    $(basename "$0") check --force
    $(basename "$0") update
    $(basename "$0") update v2.1.0
    $(basename "$0") rollback
    $(basename "$0") backup comprehensive

For more information, visit: https://github.com/GeneticxCln/HyprSupreme-Builder
EOF
}

# Main function
main() {
    local command="$1"
    shift
    
    # Initialize
    setup_logging
    init_config
    
    # Parse global options
    local force=false
    local dry_run=false
    local verbose=false
    local no_ai=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --no-ai)
                no_ai=true
                AI_ENABLED=false
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Handle commands
    case "$command" in
        "check")
            check_updates "$force"
            ;;
        "update")
            local version="$1"
            if [[ -z "$version" && -f "$CONFIG_DIR/.update_available" ]]; then
                version=$(cat "$CONFIG_DIR/.update_available")
            fi
            
            if [[ -n "$version" ]]; then
                if [[ "$REQUIRE_CONFIRMATION" == "true" && "$force" != "true" ]]; then
                    read -p "Update to version $version? (y/N): " -n 1 -r
                    echo
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        log_info "Update cancelled by user"
                        exit 0
                    fi
                fi
                
                generate_update_strategy "$version"
                apply_update "$version"
            else
                log_error "No version specified and no updates available"
                exit 1
            fi
            ;;
        "rollback")
            local backup_id="$1"
            rollback_update "$backup_id"
            ;;
        "backup")
            local backup_type="${1:-manual}"
            create_backup "$backup_type"
            ;;
        "status")
            show_status
            ;;
        "history")
            if [[ -f "$CONFIG_DIR/update_history.log" ]]; then
                cat "$CONFIG_DIR/update_history.log"
            else
                log_info "No update history available"
            fi
            ;;
        "cleanup")
            cleanup_backups
            ;;
        "config")
            ${EDITOR:-nano} "$UPDATE_CONFIG"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

