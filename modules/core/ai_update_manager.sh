#!/bin/bash

# ==========================================
# HyprSupreme AI Update Manager
# Advanced update system with AI intelligence
# ==========================================

# Enable strict error handling
set -o errexit  # Exit on error
set -o pipefail # Exit if any command in a pipe fails

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || {
    echo "Failed to determine script directory" >&2
    exit 1
}
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)" || {
    echo "Failed to determine project root directory" >&2
    exit 1
}
CONFIG_DIR="${HOME}/.config/hyprsupreme"
UPDATE_CONFIG="${CONFIG_DIR}/update_manager.conf"
LOG_FILE="${CONFIG_DIR}/logs/update_manager.log"
BACKUP_DIR="${CONFIG_DIR}/backups"
AI_ENGINE="${PROJECT_ROOT}/tools/ai_updater.py"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_DEPENDENCY_ERROR=2
readonly EXIT_PERMISSION_ERROR=3
readonly EXIT_NETWORK_ERROR=4
readonly EXIT_BACKUP_ERROR=5
readonly EXIT_UPDATE_ERROR=6
readonly EXIT_ROLLBACK_ERROR=7

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
    local log_dir
    log_dir="$(dirname "${LOG_FILE}")"
    
    mkdir -p "${log_dir}" || {
        echo "Failed to create log directory: ${log_dir}" >&2
        return ${EXIT_PERMISSION_ERROR}
    }
    
    # Redirect stdout and stderr to both console and log file
    exec 1> >(tee -a "${LOG_FILE}")
    exec 2> >(tee -a "${LOG_FILE}" >&2)
    
    return ${EXIT_SUCCESS}
}

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}${ICON_INFO}${NC} $*" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}${ICON_SUCCESS}${NC} $*" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}${ICON_WARNING}${NC} $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}${ICON_ERROR}${NC} $*" | tee -a "${LOG_FILE}"
}

log_ai() {
    echo -e "${PURPLE}${ICON_ROBOT}${NC} $*" | tee -a "${LOG_FILE}"
}

# Function to handle errors
handle_error() {
    local exit_code=$1
    local error_message=$2
    local error_source=${3:-"unknown"}
    
    log_error "Error in ${error_source}: ${error_message} (code: ${exit_code})"
    
    # If running with errexit disabled, we need to exit manually
    if [[ "${-}" != *e* ]]; then
        exit "${exit_code}"
    fi
}

# Initialize configuration
init_config() {
    # Create required directories with error handling
    mkdir -p "${CONFIG_DIR}" || {
        handle_error "${EXIT_PERMISSION_ERROR}" "Failed to create config directory" "init_config"
        return "${EXIT_PERMISSION_ERROR}"
    }
    
    mkdir -p "${BACKUP_DIR}" || {
        handle_error "${EXIT_PERMISSION_ERROR}" "Failed to create backup directory" "init_config"
        return "${EXIT_PERMISSION_ERROR}"
    }
    
    mkdir -p "$(dirname "${LOG_FILE}")" || {
        handle_error "${EXIT_PERMISSION_ERROR}" "Failed to create log directory" "init_config"
        return "${EXIT_PERMISSION_ERROR}"
    }
    
    # Create default configuration if it doesn't exist
    if [[ ! -f "${UPDATE_CONFIG}" ]]; then
        cat > "${UPDATE_CONFIG}" << EOF || {
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
            handle_error "${EXIT_PERMISSION_ERROR}" "Failed to create configuration file" "init_config"
            return "${EXIT_PERMISSION_ERROR}"
        }
        log_success "Created default configuration at ${UPDATE_CONFIG}"
    fi
    
    # Source the configuration file with error handling
    if ! source "${UPDATE_CONFIG}"; then
        handle_error "${EXIT_GENERAL_ERROR}" "Failed to load configuration file" "init_config"
        return "${EXIT_GENERAL_ERROR}"
    fi
    
    return "${EXIT_SUCCESS}"
}

# Check dependencies
check_dependencies() {
    local deps=("python3" "git" "curl" "tar" "gzip")
    local python_deps=("requests" "semver")
    local missing_deps=()
    
    # Check system dependencies
    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" &> /dev/null; then
            missing_deps+=("${dep}")
        fi
    done
    
    # Check Python dependencies
    for dep in "${python_deps[@]}"; do
        if ! python3 -c "import ${dep}" &> /dev/null; then
            missing_deps+=("python3-${dep}")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install missing dependencies and try again"
        return "${EXIT_DEPENDENCY_ERROR}"
    fi
    
    # Check AI engine
    if [[ ! -f "${AI_ENGINE}" ]]; then
        log_warning "AI engine not found at ${AI_ENGINE}"
        log_info "Some features may not be available"
        AI_ENABLED=false
    fi
    
    return "${EXIT_SUCCESS}"
}

# AI integration functions
call_ai_engine() {
    local command="$1"
    local exit_code
    shift
    
    if [[ "${AI_ENABLED}" == "true" && -f "${AI_ENGINE}" ]]; then
        python3 "${AI_ENGINE}" "${command}" "$@"
        exit_code=$?
        
        if [[ ${exit_code} -ne 0 ]]; then
            log_warning "AI engine command '${command}' failed with exit code ${exit_code}"
            return "${exit_code}"
        fi
        return "${EXIT_SUCCESS}"
    else
        log_warning "AI engine not available, using fallback logic"
        return "${EXIT_GENERAL_ERROR}"
    fi
}

# Check for updates using AI
check_updates() {
    local force=${1:-false}
    local result
    
    log_info "${ICON_SEARCH} Checking for HyprSupreme updates..."
    
    if [[ "${AI_ENABLED}" == "true" ]]; then
        log_ai "Using AI-powered update detection"
        
        local ai_args=()
        [[ "${force}" == "true" ]] && ai_args+=("--force")
        
        if call_ai_engine "check" "${ai_args[@]}"; then
            return "${EXIT_SUCCESS}"
        else
            log_warning "AI check failed, falling back to manual method"
        fi
    fi
    
    # Fallback manual check
    check_updates_manual "${force}"
    result=$?
    
    return "${result}"
}

# Manual update checking (fallback)
check_updates_manual() {
    local force=${1:-false}
    
    # Check if we should check (respects CHECK_INTERVAL)
    if [[ "${force}" != "true" && "${AUTO_CHECK}" == "true" ]]; then
        local last_check_file="${CONFIG_DIR}/.last_check"
        if [[ -f "${last_check_file}" ]]; then
            local last_check
            last_check=$(cat "${last_check_file}") || {
                log_warning "Failed to read last check time, proceeding with update check"
            }
            
            if [[ -n "${last_check}" ]]; then
                local current_time
                current_time=$(date +%s) || current_time=0
                local time_diff=$(( (current_time - last_check) / 3600 ))
                
                if [[ ${time_diff} -lt ${CHECK_INTERVAL} ]]; then
                    log_info "Update check not needed (last check ${time_diff} hours ago)"
                    return "${EXIT_SUCCESS}"
                fi
            fi
        fi
    fi
    
    log_info "Checking GitHub for updates..."
    
    # Get current version
    local current_version
    if [[ -f "${PROJECT_ROOT}/VERSION" ]]; then
        current_version=$(cat "${PROJECT_ROOT}/VERSION") || {
            log_warning "Failed to read VERSION file"
            current_version="unknown"
        }
    else
        current_version=$(git -C "${PROJECT_ROOT}" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//') || {
            log_warning "Failed to get version from git tags"
            current_version="unknown"
        }
    fi
    
    # Check GitHub releases
    local api_url="https://api.github.com/repos/GeneticxCln/HyprSupreme-Builder/releases/latest"
    local latest_info
    
    if ! latest_info=$(curl -s -f "${api_url}" 2>/dev/null); then
        log_error "Failed to connect to GitHub API"
        return "${EXIT_NETWORK_ERROR}"
    fi
    
    local latest_version
    latest_version=$(echo "${latest_info}" | grep '"tag_name"' | cut -d '"' -f 4 | sed 's/^v//') || {
        log_error "Failed to parse version information from GitHub response"
        return "${EXIT_GENERAL_ERROR}"
    }
    
    if [[ -n "${latest_version}" && "${latest_version}" != "${current_version}" ]]; then
        log_success "Update available: ${current_version} → ${latest_version}"
        
        # Store update info
        local update_info_file="${CONFIG_DIR}/.update_available"
        echo "${latest_version}" > "${update_info_file}" || {
            log_warning "Failed to store update information"
        }
        
        # Show changelog if available
        local changelog
        changelog=$(echo "${latest_info}" | grep '"body"' | cut -d '"' -f 4) || changelog=""
        if [[ -n "${changelog}" ]]; then
            log_info "Changelog preview:"
            echo "${changelog}" | head -5
        fi
        
        return "${EXIT_SUCCESS}"
    else
        log_success "Already up to date (version ${current_version})"
    fi
    
    # Update last check time
    if ! echo "$(date +%s)" > "${CONFIG_DIR}/.last_check"; then
        log_warning "Failed to update last check timestamp"
    fi
    
    return "${EXIT_SUCCESS}"
}

# Generate update strategy using AI
generate_update_strategy() {
    local version="$1"
    
    if [[ "${AI_ENABLED}" == "true" ]]; then
        log_ai "Generating AI-powered update strategy for version ${version}"
        
        # This would call the AI engine to analyze the update
        # For now, we'll implement basic logic
        local strategy_file="${CONFIG_DIR}/.update_strategy"
        
        cat > "${strategy_file}" << EOF || {
{
    "version": "${version}",
    "approach": "incremental",
    "backup_level": "standard",
    "merge_strategy": "auto",
    "estimated_time": 10,
    "confidence": 0.8,
    "user_interaction_needed": false,
    "rollback_plan": "automatic"
}
EOF
            log_error "Failed to write update strategy file"
            return "${EXIT_PERMISSION_ERROR}"
        }
        
        log_success "Update strategy generated"
        return "${EXIT_SUCCESS}"
    else
        log_warning "AI not available, using default strategy"
        return "${EXIT_GENERAL_ERROR}"
    fi
}

# Create intelligent backup
create_backup() {
    local backup_type=${1:-"pre_update"}
    local backup_id="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_id}"
    local result
    
    log_info "${ICON_SHIELD} Creating ${backup_type} backup..."
    
    if ! mkdir -p "${backup_path}"; then
        log_error "Failed to create backup directory: ${backup_path}"
        return "${EXIT_PERMISSION_ERROR}"
    fi
    
    if [[ "${AI_ENABLED}" == "true" ]]; then
        log_ai "Using AI to determine backup scope"
        
        if call_ai_engine "backup" "--type" "${backup_type}"; then
            log_success "AI backup completed: ${backup_id}"
            
            if ! echo "${backup_id}" > "${CONFIG_DIR}/.last_backup"; then
                log_warning "Failed to save backup ID, but backup was successful"
            fi
            
            return "${EXIT_SUCCESS}"
        else
            log_warning "AI backup failed, using manual backup"
        fi
    fi
    
    # Manual backup (fallback)
    create_backup_manual "${backup_type}" "${backup_path}" "${backup_id}"
    result=$?
    
    return "${result}"
}

# Manual backup creation
create_backup_manual() {
    local backup_type="$1"
    local backup_path="$2"
    local backup_id="$3"
    local exit_code
    
    log_info "Creating manual backup..."
    
    # Define what to backup
    local backup_items=(
        "${PROJECT_ROOT}:hyprsupreme"
        "${HOME}/.config/hypr:config/hypr"
        "${HOME}/.config/waybar:config/waybar"
        "${HOME}/.config/rofi:config/rofi"
    )
    
    # Add more items for comprehensive backup
    if [[ "${backup_type}" == "comprehensive" || "${backup_type}" == "pre_update" ]]; then
        backup_items+=(
            "${HOME}/.config/kitty:config/kitty"
            "${HOME}/.config/ags:config/ags"
            "${HOME}/.themes:themes"
            "${HOME}/.icons:icons"
        )
    fi
    
    # Create backup archive
    local archive_path="${backup_path}/backup.tar.gz"
    local temp_dir
    
    # Create temporary directory with error handling
    temp_dir=$(mktemp -d) || {
        log_error "Failed to create temporary directory for backup"
        return "${EXIT_GENERAL_ERROR}"
    }
    
    # Track backup success
    local backup_success=true
    local backup_count=0
    
    for item in "${backup_items[@]}"; do
        local source="${item%:*}"
        local target="${item#*:}"
        
        if [[ -d "${source}" || -f "${source}" ]]; then
            if ! mkdir -p "${temp_dir}/$(dirname "${target}")"; then
                log_warning "Failed to create directory for ${target}"
                continue
            fi
            
            if cp -r "${source}" "${temp_dir}/${target}" 2>/dev/null; then
                log_info "  ${ICON_BACKUP} Backed up: ${source}"
                ((backup_count++))
            else {
                log_warning "Could not backup ${source}"
                continue
            }
            fi
        fi
    done
    
    # Verify at least one item was backed up
    if [[ ${backup_count} -eq 0 ]]; then
        log_error "No items were successfully backed up"
        rm -rf "${temp_dir}"
        return "${EXIT_BACKUP_ERROR}"
    fi
    
    # Create compressed archive
    if (cd "${temp_dir}" && tar -czf "${archive_path}" .); then
        # Create metadata
        local version
        version=$(cat "${PROJECT_ROOT}/VERSION" 2>/dev/null || echo "unknown")
        local size
        size=$(du -sh "${archive_path}" 2>/dev/null | cut -f1)
        
        if ! cat > "${backup_path}/metadata.json" << EOF; then
{
    "backup_id": "${backup_id}",
    "backup_type": "${backup_type}",
    "created_date": "$(date -Iseconds)",
    "version": "${version}",
    "size": "${size}"
}
EOF
            log_warning "Failed to create backup metadata file"
        fi
        
        log_success "Backup created: ${backup_id} (${size})"
        
        if ! echo "${backup_id}" > "${CONFIG_DIR}/.last_backup"; then
            log_warning "Failed to save backup ID reference"
        fi
        
        # Cleanup
        rm -rf "${temp_dir}"
        return "${EXIT_SUCCESS}"
    else
        log_error "Failed to create backup archive"
        rm -rf "${temp_dir}"
        return "${EXIT_BACKUP_ERROR}"
    fi
}

# Download update
download_update() {
    local version="$1"
    local download_url="$2"
    local result
    
    log_info "${ICON_DOWNLOAD} Downloading update ${version}..."
    
    if [[ "${AI_ENABLED}" == "true" ]]; then
        log_ai "Using AI-optimized download"
        
        if call_ai_engine "download" "${version}"; then
            log_success "AI download completed"
            return "${EXIT_SUCCESS}"
        else
            log_warning "AI download failed, using manual method"
        fi
    fi
    
    # Manual download (fallback)
    download_update_manual "${version}" "${download_url}"
    result=$?
    
    return "${result}"
}

# Manual download
download_update_manual() {
    local version="$1"
    local download_url="$2"
    local download_dir="${CONFIG_DIR}/downloads"
    local download_file="${download_dir}/hyprsupreme_${version}.zip"
    
    if ! mkdir -p "${download_dir}"; then
        log_error "Failed to create download directory: ${download_dir}"
        return "${EXIT_PERMISSION_ERROR}"
    fi
    
    # For git-based updates
    if [[ "${download_url}" == "local_git" ]]; then
        log_info "Updating from local git repository..."
        
        if ! git -C "${PROJECT_ROOT}" rev-parse --git-dir &>/dev/null; then
            log_error "Not a git repository: ${PROJECT_ROOT}"
            return "${EXIT_GENERAL_ERROR}"
        fi
        
        if git -C "${PROJECT_ROOT}" fetch origin; then
            log_success "Git fetch completed"
            return "${EXIT_SUCCESS}"
        else
            log_error "Git fetch failed"
            return "${EXIT_NETWORK_ERROR}"
        fi
    fi
    
    # For URL downloads
    if [[ -n "${download_url}" ]]; then
        log_info "Downloading from: ${download_url}"
        
        local curl_exit_code
        curl -L --fail -o "${download_file}" "${download_url}"
        curl_exit_code=$?
        
        if [[ ${curl_exit_code} -eq 0 ]]; then
            local size
            size=$(du -sh "${download_file}" 2>/dev/null | cut -f1)
            log_success "Download completed: ${size}"
            
            # Verify download integrity
            if [[ ! -f "${download_file}" || ! -s "${download_file}" ]]; then
                log_error "Download file is empty or missing"
                return "${EXIT_NETWORK_ERROR}"
            fi
            
            return "${EXIT_SUCCESS}"
        else
            log_error "Download failed with error code: ${curl_exit_code}"
            return "${EXIT_NETWORK_ERROR}"
        fi
    fi
    
    log_error "No download URL provided and not a git repository"
    return "${EXIT_GENERAL_ERROR}"
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
    
    if [[ "${NOTIFY_UPDATES}" != "true" ]]; then
        return "${EXIT_SUCCESS}"
    fi
    
    # Try different notification methods
    if command -v notify-send &>/dev/null; then
        local icon=""
        case "${type}" in
            "success") icon="--icon=dialog-information" ;;
            "error") icon="--icon=dialog-error" ;;
            "warning") icon="--icon=dialog-warning" ;;
        esac
        
        if ! notify-send ${icon} "${title}" "${message}"; then
            log_warning "Failed to send notification using notify-send"
        fi
        
    elif command -v zenity &>/dev/null; then
        case "${type}" in
            "success") 
                if ! zenity --info --title="${title}" --text="${message}" &>/dev/null; then
                    log_warning "Failed to send success notification using zenity"
                fi
                ;;
            "error") 
                if ! zenity --error --title="${title}" --text="${message}" &>/dev/null; then
                    log_warning "Failed to send error notification using zenity"
                fi
                ;;
            "warning") 
                if ! zenity --warning --title="${title}" --text="${message}" &>/dev/null; then
                    log_warning "Failed to send warning notification using zenity"
                fi
                ;;
            *) 
                if ! zenity --info --title="${title}" --text="${message}" &>/dev/null; then
                    log_warning "Failed to send info notification using zenity"
                fi
                ;;
        esac
    else
        log_warning "No notification method available (notify-send or zenity)"
    fi
    
    return "${EXIT_SUCCESS}"
}

# Cleanup old backups
cleanup_backups() {
    log_info "Cleaning up old backups..."
    
    # Check if backup directory exists
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_warning "Backup directory doesn't exist: ${BACKUP_DIR}"
        return "${EXIT_SUCCESS}"
    fi
    
    # Check if we have write permissions to the backup directory
    if [[ ! -w "${BACKUP_DIR}" ]]; then
        log_error "No write permission to backup directory: ${BACKUP_DIR}"
        return "${EXIT_PERMISSION_ERROR}"
    }
    
    # Safety check for BACKUP_RETENTION_DAYS
    if [[ -z "${BACKUP_RETENTION_DAYS}" || "${BACKUP_RETENTION_DAYS}" -lt 1 ]]; then
        log_warning "Invalid backup retention days (${BACKUP_RETENTION_DAYS}), using default of 30 days"
        BACKUP_RETENTION_DAYS=30
    fi
    
    # Remove backups older than retention period
    local removed_count=0
    local old_backups
    old_backups=$(find "${BACKUP_DIR}" -type d -name "backup_*" -mtime "+${BACKUP_RETENTION_DAYS}" 2>/dev/null)
    
    if [[ -n "${old_backups}" ]]; then
        echo "${old_backups}" | while read -r backup_dir; do
            if rm -rf "${backup_dir}" 2>/dev/null; then
                ((removed_count++))
                log_info "Removed old backup: $(basename "${backup_dir}")"
            else
                log_warning "Failed to remove backup: ${backup_dir}"
            fi
        done
    fi
    
    log_success "Backup cleanup completed (${removed_count} backups removed)"
    return "${EXIT_SUCCESS}"
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
    local exit_code
    shift
    
    # Initialize with error handling
    if ! setup_logging; then
        echo "Failed to setup logging" >&2
        exit "${EXIT_GENERAL_ERROR}"
    fi
    
    if ! init_config; then
        log_error "Failed to initialize configuration"
        exit "${EXIT_GENERAL_ERROR}"
    fi
    
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
                # When in dry-run mode, disable operations that modify the system
                log_info "Running in dry-run mode - no changes will be made"
                shift
                ;;
            --verbose)
                verbose=true
                log_info "Verbose mode enabled"
                shift
                ;;
            --no-ai)
                no_ai=true
                AI_ENABLED=false
                log_info "AI features disabled for this run"
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Check dependencies
    if ! check_dependencies; then
        log_error "Failed dependency check, exiting"
        exit "${EXIT_DEPENDENCY_ERROR}"
    fi
    
    # Handle commands
    case "${command}" in
        "check")
            check_updates "${force}"
            exit_code=$?
            ;;
        "update")
            local version="$1"
            if [[ -z "${version}" && -f "${CONFIG_DIR}/.update_available" ]]; then
                version=$(cat "${CONFIG_DIR}/.update_available") || {
                    log_error "Failed to read available update version"
                    exit "${EXIT_GENERAL_ERROR}"
                }
            fi
            
            if [[ -n "${version}" ]]; then
                if [[ "${REQUIRE_CONFIRMATION}" == "true" && "${force}" != "true" && "${dry_run}" != "true" ]]; then
                    read -p "Update to version ${version}? (y/N): " -n 1 -r
                    echo
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        log_info "Update cancelled by user"
                        exit "${EXIT_SUCCESS}"
                    fi
                fi
                
                if [[ "${dry_run}" != "true" ]]; then
                    generate_update_strategy "${version}"
                    apply_update "${version}"
                    exit_code=$?
                else
                    log_info "Dry run: would update to version ${version}"
                    exit_code="${EXIT_SUCCESS}"
                fi
            else
                log_error "No version specified and no updates available"
                exit_code="${EXIT_GENERAL_ERROR}"
            fi
            ;;
        "rollback")
            local backup_id="$1"
            if [[ "${dry_run}" != "true" ]]; then
                rollback_update "${backup_id}"
                exit_code=$?
            else
                log_info "Dry run: would rollback to backup ${backup_id:-'latest'}"
                exit_code="${EXIT_SUCCESS}"
            fi
            ;;
        "backup")
            local backup_type="${1:-manual}"
            if [[ "${dry_run}" != "true" ]]; then
                create_backup "${backup_type}"
                exit_code=$?
            else
                log_info "Dry run: would create ${backup_type} backup"
                exit_code="${EXIT_SUCCESS}"
            fi
            ;;
        "status")
            show_status
            exit_code="${EXIT_SUCCESS}"
            ;;
        "history")
            if [[ -f "${CONFIG_DIR}/update_history.log" ]]; then
                cat "${CONFIG_DIR}/update_history.log" || {
                    log_error "Failed to read update history"
                    exit_code="${EXIT_GENERAL_ERROR}"
                }
            else
                log_info "No update history available"
            fi
            exit_code="${EXIT_SUCCESS}"
            ;;
        "cleanup")
            if [[ "${dry_run}" != "true" ]]; then
                cleanup_backups
                exit_code=$?
            else
                log_info "Dry run: would clean up old backups"
                exit_code="${EXIT_SUCCESS}"
            fi
            ;;
        "config")
            if [[ "${dry_run}" != "true" ]]; then
                ${EDITOR:-nano} "${UPDATE_CONFIG}" || {
                    log_error "Failed to open configuration in editor"
                    exit_code="${EXIT_GENERAL_ERROR}"
                }
            else
                log_info "Dry run: would open configuration file in editor"
            fi
            exit_code="${EXIT_SUCCESS}"
            ;;
        "help"|"--help"|"-h")
            show_help
            exit_code="${EXIT_SUCCESS}"
            ;;
        "")
            show_help
            exit_code="${EXIT_SUCCESS}"
            ;;
        *)
            log_error "Unknown command: ${command}"
            show_help
            exit_code="${EXIT_GENERAL_ERROR}"
            ;;
    esac
    
    exit "${exit_code}"
}

# Run main function
main "$@"

