#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme Community Platform Startup Script

echo "🚀 Starting HyprSupreme Community Platform..."
echo "=============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}📍 Working directory: $SCRIPT_DIR${NC}"

# Check if virtual environment exists
if [[ ! -d "community_venv" ]]; then
    echo -e "${YELLOW}⚠️  Virtual environment not found. Creating...${NC}"
    python3 -m venv community_venv
    echo -e "${GREEN}✅ Created virtual environment${NC}"
fi

# Check if packages are installed
if ! ./community_venv/bin/python -c "import flask" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Installing required packages...${NC}"
    ./community_venv/bin/pip install flask werkzeug requests jinja2
    echo -e "${GREEN}✅ Packages installed${NC}"
fi

# Test core platform
echo -e "${BLUE}📍 Testing core platform...${NC}"
if ./community_venv/bin/python community/community_platform.py > /tmp/community_test.log 2>&1; then
    echo -e "${GREEN}✅ Core platform test passed${NC}"
else
    echo -e "${YELLOW}⚠️  Core platform test had issues - check /tmp/community_test.log${NC}"
fi

# Create templates if needed
if [[ ! -d "community/templates" ]]; then
    echo -e "${BLUE}📍 Creating web templates...${NC}"
    ./community_venv/bin/python -c "
import sys
sys.path.append('community')
from web_interface import create_templates
create_templates()
print('Templates created successfully')
"
    echo -e "${GREEN}✅ Templates created${NC}"
fi

# Show available commands
echo ""
echo -e "${GREEN}🎉 Community Platform Ready!${NC}"
echo ""
echo "Available commands:"
echo ""
echo "1. Start Web Interface:"
echo "   cd community && ../community_venv/bin/python web_interface.py"
echo "   Then visit: http://localhost:5000"
echo ""
echo "2. Test CLI Tools:"
echo "   ./community_venv/bin/python tools/hyprsupreme-community.py discover"
echo "   ./community_venv/bin/python tools/hyprsupreme-community.py search minimal"
echo ""
echo "3. Test Keybindings:"
echo "   ./test_keybindings.sh"
echo ""
echo "4. Manual activation (for development):"
echo "   cd community && ../community_venv/bin/python"
echo ""

# Offer to start web interface
read -p "Would you like to start the web interface now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}📍 Starting web interface...${NC}"
    echo "Press Ctrl+C to stop the server"
    echo "Visit: http://localhost:5000"
    echo ""
    cd community
    ../community_venv/bin/python web_interface.py
fi

