#!/bin/bash
# Auto Theme Switcher - Startup Script
# Initializes the theme switcher and applies the correct theme

# Plugin name
PLUGIN_NAME="auto-theme-switcher"

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
log "Auto Theme Switcher starting up"

# Check if config file exists, create default if not
if [ ! -f "$CONFIG_FILE" ]; then
    log "Creating default configuration"
    echo '{
  "enabled": true,
  "settings": {
    "light_theme": "catppuccin-latte",
    "dark_theme": "tokyo-night",
    "day_starts": "07:00",
    "night_starts": "19:00",
    "use_location": false,
    "latitude": 0,
    "longitude": 0,
    "transition": "instant"
  }
}' > "$CONFIG_FILE"
fi

# Check if state file exists, create default if not
if [ ! -f "$STATE_FILE" ]; then
    log "Creating default state"
    echo '{
  "auto_switch": true,
  "current_theme": "",
  "last_change": "",
  "next_change": ""
}' > "$STATE_FILE"
fi

# Check if the plugin is enabled
ENABLED=$(jq -r '.enabled' "$CONFIG_FILE")
if [ "$ENABLED" != "true" ]; then
    log "Plugin is disabled, exiting"
    exit 0
fi

# Load settings
LIGHT_THEME=$(jq -r '.settings.light_theme' "$CONFIG_FILE")
DARK_THEME=$(jq -r '.settings.dark_theme' "$CONFIG_FILE")
DAY_STARTS=$(jq -r '.settings.day_starts' "$CONFIG_FILE")
NIGHT_STARTS=$(jq -r '.settings.night_starts' "$CONFIG_FILE")
USE_LOCATION=$(jq -r '.settings.use_location' "$CONFIG_FILE")

# Set up recurring timer for hourly checks
# Create systemd user timer if possible
if command -v systemctl &> /dev/null && systemctl --user daemon-reload &> /dev/null; then
    # Create timer service
    mkdir -p "$HOME/.config/systemd/user"
    echo "[Unit]
Description=HyprSupreme Auto Theme Switcher Hourly Check

[Service]
Type=oneshot
ExecStart=hyprsupreme plugin auto-theme-switcher check

[Install]
WantedBy=default.target" > "$HOME/.config/systemd/user/hyprsupreme-auto-theme.service"

    echo "[Unit]
Description=HyprSupreme Auto Theme Switcher Timer

[Timer]
OnBootSec=1min
OnUnitActiveSec=10min
Unit=hyprsupreme-auto-theme.service

[Install]
WantedBy=timers.target" > "$HOME/.config/systemd/user/hyprsupreme-auto-theme.timer"

    systemctl --user daemon-reload
    systemctl --user enable --now hyprsupreme-auto-theme.timer
    log "Systemd timer created for recurring checks"
else
    # Fall back to cron if available
    if command -v crontab &> /dev/null; then
        (crontab -l 2>/dev/null; echo "*/10 * * * * hyprsupreme plugin auto-theme-switcher check") | crontab -
        log "Cron job created for recurring checks"
    else
        log "Warning: Could not set up recurring checks. Neither systemd nor cron available."
    fi
fi

# Apply the right theme based on current time
log "Determining initial theme based on time"
"$(dirname "$0")/check_time.sh"

log "Auto Theme Switcher initialized successfully"
exit 0
