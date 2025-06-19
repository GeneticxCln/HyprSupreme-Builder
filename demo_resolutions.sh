#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme Resolution Management Demo
# Demonstrates all resolution functions and capabilities

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║         🖥️  HYPRSUPREME RESOLUTION MANAGEMENT DEMO 🖥️         ║"
echo "║                                                               ║"
echo "║              60+ Resolution Functions Available               ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo

echo -e "${BLUE}🎯 What's Available:${NC}"
echo
echo -e "${GREEN}Standard Resolutions:${NC}"
echo "  • 1080p: 60Hz, 75Hz, 120Hz, 144Hz, 165Hz, 240Hz"
echo "  • 1440p: 60Hz, 75Hz, 120Hz, 144Hz, 165Hz, 240Hz" 
echo "  • 4K: 60Hz, 75Hz, 120Hz, 144Hz"
echo

echo -e "${GREEN}Ultrawide Resolutions:${NC}"
echo "  • 21:9 (2560x1080): 60Hz, 75Hz, 144Hz"
echo "  • 21:9 QHD (3440x1440): 60Hz, 75Hz, 100Hz, 120Hz, 165Hz"
echo "  • 32:9 Super Ultrawide: 1080p and 1440p variants"
echo

echo -e "${GREEN}Professional/Creative:${NC}"
echo "  • 16:10 Monitors: 1200p, 1600p, 1800p, 4K+"
echo "  • High-End: 5K and 6K resolutions"
echo

echo -e "${GREEN}Laptop Optimized:${NC}"
echo "  • 768p, 900p, 1080p, 1440p, 4K"
echo "  • Pre-configured scaling for each size"
echo

echo -e "${GREEN}Scaling Functions:${NC}"
echo "  • 125%, 150%, 175%, 200% fractional scaling"
echo "  • Apply to current resolution or specify custom"
echo

echo -e "${GREEN}Multi-Monitor Support:${NC}"
echo "  • Dual monitor setups (side-by-side, laptop+external)"
echo "  • Triple monitor configurations"
echo "  • Mixed DPI/scaling support"
echo

echo -e "${BLUE}🚀 Quick Commands:${NC}"
echo
echo "# List all functions"
echo -e "  ${YELLOW}./hyprsupreme resolution list${NC}"
echo

echo "# Auto-detect optimal settings"
echo -e "  ${YELLOW}./hyprsupreme resolution auto${NC}"
echo

echo "# Apply specific resolution"
echo -e "  ${YELLOW}./hyprsupreme resolution res_1440p_144${NC}"
echo

echo "# Apply fractional scaling"
echo -e "  ${YELLOW}./hyprsupreme scale 125${NC}"
echo

echo "# Gaming setup example"
echo -e "  ${YELLOW}./hyprsupreme resolution res_1440p_240 DP-1 1.25${NC}"
echo

echo "# Professional setup example"
echo -e "  ${YELLOW}./hyprsupreme resolution res_4k_60 DP-1 1.5${NC}"
echo

echo "# Ultrawide gaming example"
echo -e "  ${YELLOW}./hyprsupreme resolution res_ultrawide_1440p_165 DP-1 1.25${NC}"
echo

echo -e "${BLUE}📋 Usage Examples:${NC}"
echo
echo -e "${GREEN}Gaming Setup:${NC}"
echo "  # High refresh rate 1440p with moderate scaling"
echo -e "  ${YELLOW}./hyprsupreme resolution res_1440p_240 DP-1 1.25${NC}"
echo

echo -e "${GREEN}Productivity Setup:${NC}"
echo "  # 4K with comfortable scaling for text"
echo -e "  ${YELLOW}./hyprsupreme resolution res_4k_60 DP-1 1.75${NC}"
echo

echo -e "${GREEN}Laptop + External Monitor:${NC}"
echo "  # Different scaling for each display"
echo -e "  ${YELLOW}./hyprsupreme resolution dual_mixed_laptop_external eDP-1 HDMI-A-1 1.25 1${NC}"
echo

echo -e "${GREEN}Creative Workstation:${NC}"
echo "  # 5K for color-critical work"
echo -e "  ${YELLOW}./hyprsupreme resolution res_5k_60 DP-1 2${NC}"
echo

echo -e "${BLUE}🔧 Advanced Features:${NC}"
echo
echo "• Automatic backup of current configuration"
echo "• AI-powered resolution recommendations"
echo "• Integration with HyprSupreme presets"
echo "• Multi-monitor position calculation"
echo "• Restore previous configurations"
echo "• Custom resolution function support"
echo

echo -e "${BLUE}🎮 Try It Now:${NC}"
echo
echo "1. Check your current setup:"
echo -e "   ${YELLOW}./hyprsupreme resolution current${NC}"
echo

echo "2. Get AI recommendations:"
echo -e "   ${YELLOW}./hyprsupreme analyze${NC}"
echo

echo "3. Apply optimal settings:"
echo -e "   ${YELLOW}./hyprsupreme resolution auto${NC}"
echo

echo "4. Test different scaling:"
echo -e "   ${YELLOW}./hyprsupreme scale 150${NC}"
echo

echo -e "${GREEN}✨ All resolutions are now just a function call away!${NC}"
echo
echo "Full documentation: RESOLUTION_FUNCTIONS.md"
echo "Source the resolution manager: source tools/resolution_manager.sh"

