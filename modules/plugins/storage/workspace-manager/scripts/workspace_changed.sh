#!/bin/bash
# Workspace Manager - Workspace Changed Script
# Triggered when workspace changes

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

# Get workspace ID
WORKSPACE_ID="$1"

if [ -z "$WORKSPACE_ID" ]; then
    # If no workspace ID provided, get active workspace
    WORKSPACE_ID=$(hyprctl activeworkspace -j | jq -r '.id')
fi

log "Workspace changed to $WORKSPACE_ID"

# Update active workspace in state
jq ".active_workspace = $WORKSPACE_ID | .last_update = \"$(date +%Y-%m-%d\ %H:%M:%S)\"" "$STATE_FILE" > "$STATE_FILE.tmp"
mv "$STATE_FILE.tmp" "$STATE_FILE"

# Get workspace layout
LAYOUT=$(jq -r ".workspaces[\"$WORKSPACE_ID\"].layout // \"\"" "$STATE_FILE")
if [ -n "$LAYOUT" ] && [ "$LAYOUT" != "null" ]; then
    log "Setting layout for workspace $WORKSPACE_ID to $LAYOUT"
    hyprctl dispatch layout "$LAYOUT" > /dev/null 2>&1
fi

# Check if this is a new workspace
WS_EXISTS=$(jq -r ".workspaces[\"$WORKSPACE_ID\"] // \"\"" "$STATE_FILE")
if [ -z "$WS_EXISTS" ] || [ "$WS_EXISTS" = "null" ]; then
    # New workspace, initialize it
    DEFAULT_LAYOUT=$(jq -r '.settings.default_layout' "$CONFIG_FILE")
    WS_ICON=$(jq -r ".settings.workspace_icons[\"$WORKSPACE_ID\"] // \"\"" "$CONFIG_FILE")
    
    if [ -n "$WS_ICON" ] && [ "$WS_ICON" != "null" ]; then
        NEW_NAME="$WORKSPACE_ID $WS_ICON"
        log "Setting name for new workspace $WORKSPACE_ID: $NEW_NAME"
        hyprctl dispatch renameworkspace "$WORKSPACE_ID" "$NEW_NAME" > /dev/null 2>&1
    else
        NEW_NAME="$WORKSPACE_ID"
    fi
    
    # Update state
    jq ".workspaces[\"$WORKSPACE_ID\"] = {\"custom_name\": \"$NEW_NAME\", \"layout\": \"$DEFAULT_LAYOUT\", \"windows\": []}" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
    
    # Set layout
    log "Setting default layout for new workspace $WORKSPACE_ID to $DEFAULT_LAYOUT"
    hyprctl dispatch layout "$DEFAULT_LAYOUT" > /dev/null 2>&1
fi

exit 0
