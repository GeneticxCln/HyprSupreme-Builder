#!/bin/bash
# Workspace Manager - Startup Script
# Initializes the workspace manager and sets up hooks

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

# Start logging
log "Workspace Manager starting up"

# Check if config file exists, create default if not
if [ ! -f "$CONFIG_FILE" ]; then
    log "Creating default configuration"
    echo '{
  "enabled": true,
  "settings": {
    "dynamic_names": true,
    "icon_support": true,
    "persist_names": true,
    "default_layout": "dwindle",
    "auto_arrange": true,
    "workspace_icons": {
      "1": "",
      "2": "",
      "3": "",
      "4": "",
      "5": "",
      "6": "",
      "7": "",
      "8": "",
      "9": "",
      "10": ""
    },
    "app_icons": {
      "Firefox": "",
      "Chromium": "",
      "Google-chrome": "",
      "kitty": "",
      "Alacritty": "",
      "Code": "",
      "code-oss": "",
      "discord": "",
      "Spotify": "",
      "Steam": "",
      "Thunar": "",
      "dolphin": "",
      "gimp": ""
    }
  }
}' > "$CONFIG_FILE"
fi

# Check if state file exists, create default if not
if [ ! -f "$STATE_FILE" ]; then
    log "Creating default state"
    echo '{
  "workspaces": {},
  "active_workspace": 1,
  "last_update": ""
}' > "$STATE_FILE"
fi

# Check if the plugin is enabled
ENABLED=$(jq -r '.enabled' "$CONFIG_FILE")
if [ "$ENABLED" != "true" ]; then
    log "Plugin is disabled, exiting"
    exit 0
fi

# Load settings
DYNAMIC_NAMES=$(jq -r '.settings.dynamic_names' "$CONFIG_FILE")
ICON_SUPPORT=$(jq -r '.settings.icon_support' "$CONFIG_FILE")
DEFAULT_LAYOUT=$(jq -r '.settings.default_layout' "$CONFIG_FILE")

# Initialize workspace state
log "Initializing workspace state"

# Get all current workspaces
WORKSPACES=$(hyprctl workspaces -j)

# Build initial workspace state
echo "$WORKSPACES" | jq -c '.[]' | while read -r workspace; do
    WS_ID=$(echo "$workspace" | jq -r '.id')
    WS_NAME=$(echo "$workspace" | jq -r '.name')
    
    # Check if we already have a stored name for this workspace
    STORED_NAME=$(jq -r ".workspaces[\"$WS_ID\"].custom_name // \"\"" "$STATE_FILE")
    
    if [ -n "$STORED_NAME" ] && [ "$STORED_NAME" != "null" ]; then
        # Use stored name
        log "Using stored name for workspace $WS_ID: $STORED_NAME"
        hyprctl dispatch renameworkspace "$WS_ID" "$STORED_NAME" > /dev/null 2>&1
    else
        # Get workspace icon
        WS_ICON=$(jq -r ".settings.workspace_icons[\"$WS_ID\"] // \"\"" "$CONFIG_FILE")
        
        if [ -n "$WS_ICON" ] && [ "$WS_ICON" != "null" ] && [ "$ICON_SUPPORT" = "true" ]; then
            NEW_NAME="$WS_ID $WS_ICON"
            log "Setting icon for workspace $WS_ID: $NEW_NAME"
            hyprctl dispatch renameworkspace "$WS_ID" "$NEW_NAME" > /dev/null 2>&1
            
            # Update state
            jq ".workspaces[\"$WS_ID\"] = {\"custom_name\": \"$NEW_NAME\", \"layout\": \"$DEFAULT_LAYOUT\", \"windows\": []}" "$STATE_FILE" > "$STATE_FILE.tmp"
            mv "$STATE_FILE.tmp" "$STATE_FILE"
        fi
    fi
    
    # Set layout if needed
    STORED_LAYOUT=$(jq -r ".workspaces[\"$WS_ID\"].layout // \"\"" "$STATE_FILE")
    
    if [ -n "$STORED_LAYOUT" ] && [ "$STORED_LAYOUT" != "null" ]; then
        log "Setting layout for workspace $WS_ID to $STORED_LAYOUT"
        hyprctl dispatch layout "$STORED_LAYOUT" > /dev/null 2>&1
    else
        # Set default layout
        log "Setting default layout for workspace $WS_ID to $DEFAULT_LAYOUT"
        hyprctl dispatch layout "$DEFAULT_LAYOUT" > /dev/null 2>&1
        
        # Update state
        jq ".workspaces[\"$WS_ID\"].layout = \"$DEFAULT_LAYOUT\"" "$STATE_FILE" > "$STATE_FILE.tmp"
        mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi
done

# Set up socket for Hyprland events
HYPR_SOCKET="/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Create a background process to listen for events
if [ -e "$HYPR_SOCKET" ]; then
    log "Setting up event listener on socket: $HYPR_SOCKET"
    
    # Launch event listener in background
    (
        socat -U - UNIX-CONNECT:"$HYPR_SOCKET" | while read -r line; do
            EVENT_TYPE=$(echo "$line" | awk '{print $1}')
            case "$EVENT_TYPE" in
                workspace)
                    # Workspace changed event
                    WORKSPACE_ID=$(echo "$line" | awk '{print $3}')
                    "$(dirname "$0")/workspace_changed.sh" "$WORKSPACE_ID"
                    ;;
                openwindow)
                    # Window opened event
                    WINDOW_ADDR=$(echo "$line" | awk '{print $3}')
                    WINDOW_WS=$(echo "$line" | awk '{print $4}')
                    "$(dirname "$0")/window_opened.sh" "$WINDOW_ADDR" "$WINDOW_WS"
                    ;;
                closewindow)
                    # Window closed event
                    WINDOW_ADDR=$(echo "$line" | awk '{print $3}')
                    "$(dirname "$0")/window_closed.sh" "$WINDOW_ADDR"
                    ;;
            esac
        done
    ) &
    
    # Save background process ID
    echo $! > "$CONFIG_DIR/listener.pid"
    log "Event listener started with PID $!"
else
    log "Warning: Hyprland socket not found, event listening disabled"
fi

log "Workspace Manager initialized successfully"
exit 0
