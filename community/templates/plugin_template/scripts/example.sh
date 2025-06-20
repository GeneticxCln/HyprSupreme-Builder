#!/bin/bash
# Example command script for HyprSupreme plugin
# This script is executed when the user runs: hyprsupreme plugin example-command

# Plugin name (should match manifest.yaml)
PLUGIN_NAME="plugin-name"

# Log file location
LOG_DIR="$HOME/.local/share/hyprsupreme/logs/plugins"
LOG_FILE="$LOG_DIR/$PLUGIN_NAME.log"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Start logging
log "Example command executed with args: $@"

# Parse arguments
if [ $# -eq 0 ]; then
    echo "Usage: hyprsupreme plugin example-command [options]"
    echo ""
    echo "Options:"
    echo "  --help          Show this help message"
    echo "  --status        Show current plugin status"
    echo "  --action=VALUE  Perform a specific action"
    echo ""
    exit 0
fi

# Process arguments
for arg in "$@"; do
    case $arg in
        --help)
            echo "Example command help:"
            echo "This command demonstrates plugin functionality."
            echo ""
            echo "Usage: hyprsupreme plugin example-command [options]"
            echo ""
            echo "Options:"
            echo "  --help          Show this help message"
            echo "  --status        Show current plugin status"
            echo "  --action=VALUE  Perform a specific action"
            echo ""
            exit 0
            ;;
        --status)
            echo "Plugin status: Active"
            echo "Version: 1.0.0"
            
            # Get active workspaces as an example
            WORKSPACES=$(hyprctl workspaces -j | jq -r '.[].id')
            echo "Active workspaces: $WORKSPACES"
            
            exit 0
            ;;
        --action=*)
            ACTION="${arg#*=}"
            echo "Performing action: $ACTION"
            
            case $ACTION in
                test)
                    echo "Running test action"
                    # Add your test action code here
                    ;;
                refresh)
                    echo "Refreshing plugin state"
                    # Add your refresh action code here
                    ;;
                *)
                    echo "Unknown action: $ACTION"
                    echo "Available actions: test, refresh"
                    exit 1
                    ;;
            esac
            
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for available options"
            exit 1
            ;;
    esac
done

exit 0
