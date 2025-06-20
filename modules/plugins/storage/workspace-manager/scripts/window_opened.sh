#!/bin/bash
# Workspace Manager - Window Opened Script
# Triggered when a new window opens

# Plugin name
PLUGIN_NAME="workspace-manager"

# Log file location
LOG_DIR="$HOME/.local/share/hyprsupreme/logs/plugins"
LOG_FILE="$LOG_DIR/$PLUGIN_NAME.log"

# Config location
CONFIG_DIR="$HOME/.config/hyprsupreme/plugins/$PLUGIN_NAME"
CONFIG_FILE="$CONFIG_DIR/config.json"
STATE_FILE="$CONFIG_DIR/state.json"

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$CONFIG_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Get arguments
WINDOW_ADDR="$1"
WORKSPACE_ID="$2"

if [ -z "$WINDOW_ADDR" ]; then
    log "Error: No window address provided"
    exit 1
fi

if [ -z "$WORKSPACE_ID" ]; then
    # If no workspace ID provided, determine it from the window
    WINDOW_DATA=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$WINDOW_ADDR\")")
    WORKSPACE_ID=$(echo "$WINDOW_DATA" | jq -r '.workspace.id')
fi

log "Window opened: $WINDOW_ADDR on workspace $WORKSPACE_ID"

# Get window information
WINDOW_DATA=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$WINDOW_ADDR\")")
APP_ID=$(echo "$WINDOW_DATA" | jq -r '.class')
WINDOW_TITLE=$(echo "$WINDOW_DATA" | jq -r '.title')

log "Window info: App ID=$APP_ID, Title=$WINDOW_TITLE"

# Add window to workspace state
jq ".workspaces[\"$WORKSPACE_ID\"].windows += [{\"address\": \"$WINDOW_ADDR\", \"app_id\": \"$APP_ID\", \"title\": \"$WINDOW_TITLE\"}]" "$STATE_FILE" > "$STATE_FILE.tmp"
mv "$STATE_FILE.tmp" "$STATE_FILE"

# Check if dynamic naming is enabled
DYNAMIC_NAMES=$(jq -r '.settings.dynamic_names' "$CONFIG_FILE")
if [ "$DYNAMIC_NAMES" != "true" ]; then
    log "Dynamic naming disabled, not updating workspace name"
    exit 0
fi

# Get app icon if available
ICON_SUPPORT=$(jq -r '.settings.icon_support' "$CONFIG_FILE")
APP_ICON=""
if [ "$ICON_SUPPORT" = "true" ]; then
    APP_ICON=$(jq -r ".settings.app_icons[\"$APP_ID\"] // \"\"" "$CONFIG_FILE")
fi

# Get workspace icon
WS_ICON=$(jq -r ".settings.workspace_icons[\"$WORKSPACE_ID\"] // \"\"" "$CONFIG_FILE")
if [ -z "$WS_ICON" ] || [ "$WS_ICON" = "null" ]; then
    WS_ICON=""
fi

# Count windows in workspace
WINDOW_COUNT=$(jq -r ".workspaces[\"$WORKSPACE_ID\"].windows | length" "$STATE_FILE")

# Update workspace name
if [ -n "$APP_ICON" ] && [ "$APP_ICON" != "null" ]; then
    # Use app icon in name
    NEW_NAME="$WORKSPACE_ID $WS_ICON $APP_ICON"
    if [ "$WINDOW_COUNT" -gt 1 ]; then
        NEW_NAME="$NEW_NAME ($WINDOW_COUNT)"
    fi
    
    log "Setting workspace name with app icon: $NEW_NAME"
    hyprctl dispatch renameworkspace "$WORKSPACE_ID" "$NEW_NAME" > /dev/null 2>&1
    
    # Update state
    jq ".workspaces[\"$WORKSPACE_ID\"].custom_name = \"$NEW_NAME\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
else
    # No app icon, use default or app name
    if [ "$WINDOW_COUNT" -eq 1 ]; then
        # First window, use app name
        NEW_NAME="$WORKSPACE_ID $WS_ICON: $APP_ID"
        log "Setting workspace name with app name: $NEW_NAME"
        hyprctl dispatch renameworkspace "$WORKSPACE_ID" "$NEW_NAME" > /dev/null 2>&1
        
        # Update state
        jq ".workspaces[\"$WORKSPACE_ID\"].custom_name = \"$NEW_NAME\"" "$STATE_FILE" > "$STATE_FILE.tmp"
        mv "$STATE_FILE.tmp" "$STATE_FILE"
    else
        # Multiple windows, update counter
        CURRENT_NAME=$(jq -r ".workspaces[\"$WORKSPACE_ID\"].custom_name // \"\"" "$STATE_FILE")
        if [ -n "$CURRENT_NAME" ] && [ "$CURRENT_NAME" != "null" ]; then
            # Update with window count
            NEW_NAME=$(echo "$CURRENT_NAME" | sed -E "s/\([0-9]+\)$//g").trim
            NEW_NAME="$NEW_NAME ($WINDOW_COUNT)"
            
            log "Updating workspace name with window count: $NEW_NAME"
            hyprctl dispatch renameworkspace "$WORKSPACE_ID" "$NEW_NAME" > /dev/null 2>&1
            
            # Update state
            jq ".workspaces[\"$WORKSPACE_ID\"].custom_name = \"$NEW_NAME\"" "$STATE_FILE" > "$STATE_FILE.tmp"
            mv "$STATE_FILE.tmp" "$STATE_FILE"
        fi
    fi
fi

exit 0
