#!/bin/bash
# HyprSupreme-Builder v3.0.0 Enhanced Edition - Quick Install Script
# https://github.com/GeneticxCln/HyprSupreme-Builder

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Icons
ROCKET="🚀"
STAR="⭐"
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"

print_banner() {
    echo -e "${PURPLE}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║              ${ROCKET} HYPRLAND SUPREME BUILDER ${ROCKET}                  ║"
    echo "║                                                               ║"
    echo "║          Enhanced Edition v3.0.0 - Quick Install             ║"
    echo "║                                                               ║"
    echo "║    ${STAR} Enterprise-Grade ${STAR} Production-Ready ${STAR} Enhanced ${STAR}     ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

print_features() {
    echo -e "${CYAN}${BOLD}${STAR} What's New in v3.0.0 Enhanced Edition:${NC}"
    echo
    echo -e "${GREEN}${CHECK} Enterprise-grade error handling with intelligent recovery${NC}"
    echo -e "${GREEN}${CHECK} Advanced system diagnostics and health monitoring${NC}"
    echo -e "${GREEN}${CHECK} Enhanced installation with unattended mode support${NC}"
    echo -e "${GREEN}${CHECK} Comprehensive prerequisite validation system${NC}"
    echo -e "${GREEN}${CHECK} Professional documentation and guides${NC}"
    echo -e "${GREEN}${CHECK} Cross-distribution compatibility improvements${NC}"
    echo -e "${GREEN}${CHECK} Production-ready stability and reliability${NC}"
    echo
}

check_requirements() {
    echo -e "${BLUE}${INFO} Checking system requirements...${NC}"
    
    # Check if running on Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo -e "${RED}${CROSS} This script requires Linux. Detected: $(uname -s)${NC}"
        exit 1
    fi
    
    # Check for required commands
    local required_commands=("git" "curl" "bash" "sudo")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}${CROSS} Required command not found: $cmd${NC}"
            echo -e "${YELLOW}${WARNING} Please install $cmd and try again${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}${CHECK} System requirements satisfied${NC}"
    echo
}

install_hyprsupreme() {
    local install_dir="${1:-$HOME/HyprSupreme-Builder}"
    local preset="${2:-interactive}"
    
    echo -e "${BLUE}${INFO} Installing HyprSupreme-Builder to: $install_dir${NC}"
    
    # Remove existing installation if it exists
    if [[ -d "$install_dir" ]]; then
        echo -e "${YELLOW}${WARNING} Existing installation found. Backing up to ${install_dir}.backup${NC}"
        mv "$install_dir" "${install_dir}.backup.$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Clone the repository
    echo -e "${BLUE}${INFO} Downloading HyprSupreme-Builder v3.0.0 Enhanced Edition...${NC}"
    if ! git clone --depth 1 --branch release/v3.0.0 https://github.com/GeneticxCln/HyprSupreme-Builder.git "$install_dir"; then
        echo -e "${RED}${CROSS} Failed to clone repository${NC}"
        exit 1
    fi
    
    # Change to installation directory
    cd "$install_dir"
    
    # Make scripts executable
    chmod +x install.sh hyprsupreme check_system.sh
    
    echo -e "${GREEN}${CHECK} HyprSupreme-Builder downloaded successfully${NC}"
    echo
    
    # Run system check
    echo -e "${BLUE}${INFO} Running system compatibility check...${NC}"
    if ./check_system.sh; then
        echo -e "${GREEN}${CHECK} System compatibility check passed${NC}"
    else
        echo -e "${YELLOW}${WARNING} System check completed with warnings. Installation can continue.${NC}"
    fi
    echo
    
    # Start installation based on preset
    case "$preset" in
        "gaming")
            echo -e "${BLUE}${INFO} Starting gaming-optimized installation...${NC}"
            ./install.sh --preset gaming
            ;;
        "work")
            echo -e "${BLUE}${INFO} Starting work-focused installation...${NC}"
            ./install.sh --preset work
            ;;
        "minimal")
            echo -e "${BLUE}${INFO} Starting minimal installation...${NC}"
            ./install.sh --preset minimal
            ;;
        "showcase")
            echo -e "${BLUE}${INFO} Starting showcase installation with maximum eye-candy...${NC}"
            ./install.sh --preset showcase
            ;;
        "unattended")
            echo -e "${BLUE}${INFO} Starting unattended installation...${NC}"
            ./install.sh --unattended --preset hybrid
            ;;
        *)
            echo -e "${BLUE}${INFO} Starting interactive installation...${NC}"
            ./install.sh
            ;;
    esac
}

show_usage() {
    echo -e "${WHITE}${BOLD}Usage:${NC}"
    echo "  $0 [OPTIONS]"
    echo
    echo -e "${WHITE}${BOLD}Options:${NC}"
    echo "  --preset PRESET    Install with specific preset (gaming|work|minimal|showcase|unattended)"
    echo "  --dir DIRECTORY    Install to specific directory (default: ~/HyprSupreme-Builder)"
    echo "  --help, -h         Show this help message"
    echo
    echo -e "${WHITE}${BOLD}Examples:${NC}"
    echo "  $0                           # Interactive installation"
    echo "  $0 --preset gaming           # Gaming-optimized setup"
    echo "  $0 --preset work             # Work-focused setup"
    echo "  $0 --preset unattended       # Fully automated setup"
    echo "  $0 --dir ~/my-hyprland       # Custom installation directory"
    echo
}

main() {
    local preset="interactive"
    local install_dir="$HOME/HyprSupreme-Builder"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --preset)
                preset="$2"
                shift 2
                ;;
            --dir)
                install_dir="$2"
                shift 2
                ;;
            --help|-h)
                print_banner
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}${CROSS} Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Main installation flow
    print_banner
    print_features
    check_requirements
    
    echo -e "${YELLOW}${BOLD}${ROCKET} Ready to install HyprSupreme-Builder v3.0.0 Enhanced Edition${NC}"
    echo
    
    if [[ "$preset" != "unattended" ]]; then
        echo -e "${BLUE}Installation will begin in 3 seconds... (Press Ctrl+C to cancel)${NC}"
        sleep 3
        echo
    fi
    
    install_hyprsupreme "$install_dir" "$preset"
    
    echo
    echo -e "${GREEN}${BOLD}${STAR} Installation completed successfully! ${STAR}${NC}"
    echo
    echo -e "${CYAN}${BOLD}Next steps:${NC}"
    echo -e "${WHITE}1. ${BLUE}Run system diagnostics: ${CYAN}cd $install_dir && ./check_system.sh${NC}"
    echo -e "${WHITE}2. ${BLUE}Launch GUI interface: ${CYAN}./hyprsupreme gui${NC}"
    echo -e "${WHITE}3. ${BLUE}Explore documentation: ${CYAN}cat README.md${NC}"
    echo -e "${WHITE}4. ${BLUE}Join the community: ${CYAN}./launch_web.sh${NC}"
    echo
    echo -e "${PURPLE}${BOLD}${ROCKET} Welcome to the ultimate Hyprland experience! ${ROCKET}${NC}"
}

# Run main function with all arguments
main "$@"

