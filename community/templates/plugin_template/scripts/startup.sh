#!/bin/bash
# Example startup script for HyprSupreme plugin
# This script runs when the plugin is initialized

# Plugin name (should match manifest.yaml)
PLUGIN_NAME="plugin-name"

# Log file location
LOG_DIR="$HOME/.local/share/hyprsupreme/logs/plugins"
LOG_FILE="$LOG_DIR/$PLUGIN_NAME.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Start logging
log "Plugin startup initiated"

# Check if the plugin is already running
if pgrep -f "$PLUGIN_NAME-daemon" > /dev/null; then
    log "Plugin is already running, stopping previous instance"
    pkill -f "$PLUGIN_NAME-daemon"
fi

# Check for required dependencies
for cmd in jq hyprctl; do
    if ! command -v $cmd &> /dev/null; then
        log "ERROR: Required dependency '$cmd' not found"
        notify-send "Plugin Error" "Required dependency '$cmd' not found"
        exit 1
    fi
done

# Load plugin configuration
CONFIG_DIR="$HOME/.config/hyprsupreme/plugins/$PLUGIN_NAME"
CONFIG_FILE="$CONFIG_DIR/config.json"

if [ -f "$CONFIG_FILE" ]; then
    log "Loading configuration from $CONFIG_FILE"
else
    log "Configuration file not found, creating default"
    mkdir -p "$CONFIG_DIR"
    echo '{
  "enabled": true,
  "settings": {
    "refresh_rate": 60,
    "notify": true
  }
}' > "$CONFIG_FILE"
fi

# Check if plugin is enabled in configuration
ENABLED=$(jq -r '.enabled' "$CONFIG_FILE")

if [ "$ENABLED" != "true" ]; then
    log "Plugin is disabled in configuration, exiting"
    exit 0
fi

# Initialize plugin
log "Initializing plugin"

# Start plugin daemon or service if needed
# nohup /path/to/daemon > /dev/null 2>&1 &

# Register with Hyprland if needed
# hyprctl keyword plugin...

# Example: Set up a monitor for workspace changes
# hyprctl keyword plugin:some_setting...

log "Plugin initialized successfully"

# Notify user if enabled
NOTIFY=$(jq -r '.settings.notify' "$CONFIG_FILE")
if [ "$NOTIFY" = "true" ]; then
    notify-send "Plugin Activated" "$PLUGIN_NAME has been initialized"
fi

exit 0
