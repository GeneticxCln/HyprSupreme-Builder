#!/bin/bash

# HyprSupreme-Builder - Driver Manager GUI
# Graphical interface for driver management

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_MANAGER="$SCRIPT_DIR/../modules/core/driver_manager.sh"

# Check if GUI tools are available
check_gui_tools() {
    if command -v zenity &> /dev/null; then
        GUI_TOOL="zenity"
    elif command -v kdialog &> /dev/null; then
        GUI_TOOL="kdialog"
    elif command -v dialog &> /dev/null; then
        GUI_TOOL="dialog"
    else
        echo "No GUI dialog tool found. Please install zenity, kdialog, or dialog."
        exit 1
    fi
}

# Show info dialog
show_info() {
    local title="$1"
    local message="$2"
    
    case "$GUI_TOOL" in
        "zenity")
            zenity --info --title="$title" --text="$message" --width=400
            ;;
        "kdialog")
            kdialog --msgbox "$message" --title "$title"
            ;;
        "dialog")
            dialog --title "$title" --msgbox "$message" 10 50
            clear
            ;;
    esac
}

# Show error dialog
show_error() {
    local title="$1"
    local message="$2"
    
    case "$GUI_TOOL" in
        "zenity")
            zenity --error --title="$title" --text="$message" --width=400
            ;;
        "kdialog")
            kdialog --error "$message" --title "$title"
            ;;
        "dialog")
            dialog --title "$title" --msgbox "ERROR: $message" 10 50
            clear
            ;;
    esac
}

# Show question dialog
show_question() {
    local title="$1"
    local message="$2"
    
    case "$GUI_TOOL" in
        "zenity")
            zenity --question --title="$title" --text="$message" --width=400
            ;;
        "kdialog")
            kdialog --yesno "$message" --title "$title"
            ;;
        "dialog")
            dialog --title "$title" --yesno "$message" 10 50
            ;;
    esac
}

# Show progress dialog
show_progress() {
    local title="$1"
    local command="$2"
    
    case "$GUI_TOOL" in
        "zenity")
            (
                echo "10"; echo "# Starting driver installation..."
                sleep 1
                echo "30"; echo "# Detecting hardware..."
                eval "$command" 2>&1 | while read -r line; do
                    echo "50"; echo "# $line"
                done
                echo "90"; echo "# Finalizing installation..."
                sleep 1
                echo "100"; echo "# Installation complete!"
            ) | zenity --progress --title="$title" --text="Starting..." --percentage=0 --auto-close --width=500
            ;;
        "kdialog")
            kdialog --progressbar "Installing drivers..." 0 | {
                eval "$command"
                echo 100
            }
            ;;
        "dialog")
            eval "$command" 2>&1 | dialog --title "$title" --programbox 20 70
            clear
            ;;
    esac
}

# Show menu
show_main_menu() {
    case "$GUI_TOOL" in
        "zenity")
            zenity --list \
                --title="HyprSupreme Driver Manager" \
                --text="Select an action:" \
                --column="Action" \
                --column="Description" \
                --width=600 --height=400 \
                "install" "Install all drivers automatically" \
                "install-gaming" "Install drivers with gaming support" \
                "install-gpu" "Install GPU drivers only" \
                "install-audio" "Install audio drivers only" \
                "install-network" "Install network drivers only" \
                "status" "Check current driver status" \
                "report" "Generate driver report" \
                "backup" "Backup driver configuration" \
                "uninstall-nvidia" "Uninstall NVIDIA drivers" \
                "exit" "Exit driver manager"
            ;;
        "kdialog")
            kdialog --menu "HyprSupreme Driver Manager" \
                install "Install all drivers automatically" \
                install-gaming "Install drivers with gaming support" \
                install-gpu "Install GPU drivers only" \
                install-audio "Install audio drivers only" \
                install-network "Install network drivers only" \
                status "Check current driver status" \
                report "Generate driver report" \
                backup "Backup driver configuration" \
                uninstall-nvidia "Uninstall NVIDIA drivers" \
                exit "Exit driver manager"
            ;;
        "dialog")
            dialog --title "HyprSupreme Driver Manager" \
                --menu "Select an action:" 15 60 8 \
                1 "Install all drivers automatically" \
                2 "Install drivers with gaming support" \
                3 "Install GPU drivers only" \
                4 "Install audio drivers only" \
                5 "Install network drivers only" \
                6 "Check current driver status" \
                7 "Generate driver report" \
                8 "Backup driver configuration" \
                9 "Uninstall NVIDIA drivers" \
                0 "Exit driver manager" 2>&1 >/dev/tty
            ;;
    esac
}

# Show text output
show_text_output() {
    local title="$1"
    local content="$2"
    
    case "$GUI_TOOL" in
        "zenity")
            echo "$content" | zenity --text-info \
                --title="$title" \
                --width=800 --height=600 \
                --font="monospace"
            ;;
        "kdialog")
            echo "$content" | kdialog --textbox /dev/stdin 600 800 --title "$title"
            ;;
        "dialog")
            echo "$content" | dialog --title "$title" --textbox /dev/stdin 20 80
            clear
            ;;
    esac
}

# Execute driver manager command
execute_driver_command() {
    local command="$1"
    local description="$2"
    
    if show_question "Confirm Action" "Are you sure you want to $description?"; then
        case "$command" in
            "status"|"report")
                # Commands that show output
                local output=$(bash "$DRIVER_MANAGER" "$command" 2>&1)
                show_text_output "$description" "$output"
                ;;
            *)
                # Commands that need progress indication
                show_progress "$description" "bash '$DRIVER_MANAGER' '$command'"
                if [ $? -eq 0 ]; then
                    show_info "Success" "$description completed successfully!"
                else
                    show_error "Error" "Failed to $description. Check the logs for details."
                fi
                ;;
        esac
    fi
}

# Handle dialog choice for dialog tool
handle_dialog_choice() {
    case "$1" in
        "1") echo "install" ;;
        "2") echo "install-gaming" ;;
        "3") echo "install-gpu" ;;
        "4") echo "install-audio" ;;
        "5") echo "install-network" ;;
        "6") echo "status" ;;
        "7") echo "report" ;;
        "8") echo "backup" ;;
        "9") echo "uninstall-nvidia" ;;
        "0") echo "exit" ;;
        *) echo "exit" ;;
    esac
}

# Main GUI loop
main_gui_loop() {
    while true; do
        choice=$(show_main_menu)
        
        # Handle dialog tool special case
        if [ "$GUI_TOOL" = "dialog" ]; then
            choice=$(handle_dialog_choice "$choice")
        fi
        
        case "$choice" in
            "install")
                execute_driver_command "install" "install all drivers"
                ;;
            "install-gaming")
                execute_driver_command "install-gaming" "install drivers with gaming support"
                ;;
            "install-gpu")
                execute_driver_command "install-gpu" "install GPU drivers"
                ;;
            "install-audio")
                execute_driver_command "install-audio" "install audio drivers"
                ;;
            "install-network")
                execute_driver_command "install-network" "install network drivers"
                ;;
            "status")
                execute_driver_command "status" "Driver Status Report"
                ;;
            "report")
                execute_driver_command "report" "Driver Hardware Report"
                ;;
            "backup")
                execute_driver_command "backup" "backup driver configuration"
                ;;
            "uninstall-nvidia")
                execute_driver_command "uninstall-nvidia" "uninstall NVIDIA drivers"
                ;;
            "exit"|"")
                break
                ;;
        esac
    done
}

# System requirements check
check_requirements() {
    if [ ! -f "$DRIVER_MANAGER" ]; then
        show_error "Error" "Driver manager script not found at: $DRIVER_MANAGER"
        exit 1
    fi
    
    if [ ! -x "$DRIVER_MANAGER" ]; then
        chmod +x "$DRIVER_MANAGER"
    fi
}

# Welcome message
show_welcome() {
    show_info "HyprSupreme Driver Manager" \
        "Welcome to the HyprSupreme Driver Manager!\n\nThis tool will help you automatically detect and install drivers for your hardware.\n\nFeatures:\n• Automatic hardware detection\n• GPU driver installation (NVIDIA/AMD/Intel)\n• Audio driver configuration\n• Network driver setup\n• Gaming optimization\n• Driver status monitoring\n\nClick OK to continue."
}

# Main function
main() {
    check_gui_tools
    check_requirements
    
    # Show welcome message
    show_welcome
    
    # Start main GUI loop
    main_gui_loop
    
    # Exit message
    show_info "Thank You" "Thank you for using HyprSupreme Driver Manager!"
}

# Run main function
main "$@"

