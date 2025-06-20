#!/bin/bash
# Auto Theme Switcher - Time Check Script
# Checks if theme should be changed based on time

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
log "Checking if theme should be changed"

# Check if state file exists
if [ ! -f "$STATE_FILE" ]; then
    log "State file not found, exiting"
    exit 1
fi

# Check if auto-switching is enabled
AUTO_SWITCH=$(jq -r '.auto_switch' "$STATE_FILE")
if [ "$AUTO_SWITCH" != "true" ]; then
    log "Auto-switching is disabled, exiting"
    exit 0
fi

# Load settings
LIGHT_THEME=$(jq -r '.settings.light_theme' "$CONFIG_FILE")
DARK_THEME=$(jq -r '.settings.dark_theme' "$CONFIG_FILE")
DAY_STARTS=$(jq -r '.settings.day_starts' "$CONFIG_FILE")
NIGHT_STARTS=$(jq -r '.settings.night_starts' "$CONFIG_FILE")
USE_LOCATION=$(jq -r '.settings.use_location' "$CONFIG_FILE")
LATITUDE=$(jq -r '.settings.latitude' "$CONFIG_FILE")
LONGITUDE=$(jq -r '.settings.longitude' "$CONFIG_FILE")

# Get current time
CURRENT_TIME=$(date +%H:%M)
CURRENT_HOUR=$(date +%H)
CURRENT_MIN=$(date +%M)
CURRENT_HOUR_MIN=$((CURRENT_HOUR * 60 + CURRENT_MIN))

# Convert day start and night start to minutes
DAY_HOUR=$(echo $DAY_STARTS | cut -d: -f1)
DAY_MIN=$(echo $DAY_STARTS | cut -d: -f2)
DAY_TIME=$((DAY_HOUR * 60 + DAY_MIN))

NIGHT_HOUR=$(echo $NIGHT_STARTS | cut -d: -f1)
NIGHT_MIN=$(echo $NIGHT_STARTS | cut -d: -f2)
NIGHT_TIME=$((NIGHT_HOUR * 60 + NIGHT_MIN))

# Determine if it's day or night
IS_DAY=false

if [ "$USE_LOCATION" = "true" ] && command -v curl &> /dev/null; then
    # If using location-based sunrise/sunset and curl is available
    log "Using location-based sunrise/sunset times"
    
    # If latitude and longitude are set to 0, try to get location
    if (( $(echo "$LATITUDE == 0" | bc -l) )) && (( $(echo "$LONGITUDE == 0" | bc -l) )); then
        # Try to get location if geoclue is available
        if command -v geoclue &> /dev/null; then
            log "Getting location using geoclue"
            # This is a simplified example, actual implementation would use geoclue properly
            LOCATION=$(geoclue location)
            LATITUDE=$(echo $LOCATION | cut -d' ' -f1)
            LONGITUDE=$(echo $LOCATION | cut -d' ' -f2)
        else
            log "Geoclue not available, using IP-based location"
            # Fallback to IP-based location
            LOCATION_DATA=$(curl -s 'https://ipinfo.io/')
            LOC=$(echo $LOCATION_DATA | jq -r '.loc')
            LATITUDE=$(echo $LOC | cut -d, -f1)
            LONGITUDE=$(echo $LOC | cut -d, -f2)
        fi
        
        # Save the location if found
        if (( $(echo "$LATITUDE != 0" | bc -l) )) && (( $(echo "$LONGITUDE != 0" | bc -l) )); then
            jq ".settings.latitude = $LATITUDE | .settings.longitude = $LONGITUDE" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
            mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        fi
    fi
    
    # Get sunrise and sunset times if we have coordinates
    if (( $(echo "$LATITUDE != 0" | bc -l) )) && (( $(echo "$LONGITUDE != 0" | bc -l) )); then
        # Get sunrise/sunset using online API (simplified for example)
        log "Getting sunrise/sunset times for lat: $LATITUDE, lon: $LONGITUDE"
        SUN_DATA=$(curl -s "https://api.sunrise-sunset.org/json?lat=$LATITUDE&lng=$LONGITUDE&formatted=0")
        SUNRISE=$(echo $SUN_DATA | jq -r '.results.sunrise' | date -f - +%H:%M)
        SUNSET=$(echo $SUN_DATA | jq -r '.results.sunset' | date -f - +%H:%M)
        
        # Convert to minutes
        SUNRISE_HOUR=$(echo $SUNRISE | cut -d: -f1)
        SUNRISE_MIN=$(echo $SUNRISE | cut -d: -f2)
        SUNRISE_TIME=$((SUNRISE_HOUR * 60 + SUNRISE_MIN))
        
        SUNSET_HOUR=$(echo $SUNSET | cut -d: -f1)
        SUNSET_MIN=$(echo $SUNSET | cut -d: -f2)
        SUNSET_TIME=$((SUNSET_HOUR * 60 + SUNSET_MIN))
        
        # Determine if it's day based on sunrise/sunset
        if [ $CURRENT_HOUR_MIN -ge $SUNRISE_TIME ] && [ $CURRENT_HOUR_MIN -lt $SUNSET_TIME ]; then
            IS_DAY=true
        else
            IS_DAY=false
        fi
        
        log "Sunrise: $SUNRISE, Sunset: $SUNSET, Current: $CURRENT_TIME, Is Day: $IS_DAY"
    else
        # Fallback to manual times if location not available
        log "Location not available, falling back to manual times"
        if [ $CURRENT_HOUR_MIN -ge $DAY_TIME ] && [ $CURRENT_HOUR_MIN -lt $NIGHT_TIME ]; then
            IS_DAY=true
        else
            IS_DAY=false
        fi
    fi
else
    # Use manual times
    log "Using manual day/night times: Day starts: $DAY_STARTS, Night starts: $NIGHT_STARTS"
    if [ $CURRENT_HOUR_MIN -ge $DAY_TIME ] && [ $CURRENT_HOUR_MIN -lt $NIGHT_TIME ]; then
        IS_DAY=true
    else
        IS_DAY=false
    fi
fi

# Get current theme
CURRENT_THEME=$(jq -r '.current_theme' "$STATE_FILE")

# Determine which theme to apply
TARGET_THEME=""
if [ "$IS_DAY" = "true" ]; then
    TARGET_THEME="$LIGHT_THEME"
    NEXT_CHANGE="$NIGHT_STARTS"
else
    TARGET_THEME="$DARK_THEME"
    NEXT_CHANGE="$DAY_STARTS"
fi

# Check if theme needs to be changed
if [ "$CURRENT_THEME" != "$TARGET_THEME" ]; then
    log "Changing theme from '$CURRENT_THEME' to '$TARGET_THEME'"
    
    # Apply the new theme
    hyprsupreme theme apply "$TARGET_THEME"
    
    # Update state
    jq ".current_theme = \"$TARGET_THEME\" | .last_change = \"$(date +%Y-%m-%d\ %H:%M:%S)\" | .next_change = \"$NEXT_CHANGE\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
    
    # Notify user
    if command -v notify-send &> /dev/null; then
        if [ "$IS_DAY" = "true" ]; then
            notify-send "Theme Changed" "Switched to light theme ($TARGET_THEME)"
        else
            notify-send "Theme Changed" "Switched to dark theme ($TARGET_THEME)"
        fi
    fi
else
    log "No theme change needed, already using correct theme: $CURRENT_THEME"
fi

exit 0
