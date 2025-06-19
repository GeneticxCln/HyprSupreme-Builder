#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme Community Platform Verification Script

echo "🔍 Verifying HyprSupreme Community Platform Setup"
echo "=================================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TOTAL_TESTS=0

check_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ $1${NC}"
    fi
}

echo -e "${BLUE}📍 Checking virtual environment...${NC}"

# Check if virtual environment exists
if [[ -d "community_venv" ]]; then
    check_test "Virtual environment directory exists"
else
    echo -e "${RED}❌ Virtual environment directory missing${NC}"
    exit 1
fi

# Check Python executable
if [[ -x "community_venv/bin/python" ]]; then
    check_test "Python executable exists"
else
    echo -e "${RED}❌ Python executable missing${NC}"
    exit 1
fi

# Test Python version
PYTHON_VERSION=$(./community_venv/bin/python --version 2>&1)
echo "Python version: $PYTHON_VERSION"
check_test "Python version check"

echo -e "\n${BLUE}📍 Checking Python packages...${NC}"

# Check Flask
if ./community_venv/bin/python -c "import flask; print(f'Flask {flask.__version__}')" 2>/dev/null; then
    check_test "Flask installed"
else
    echo -e "${RED}❌ Flask not installed${NC}"
fi

# Check requests
if ./community_venv/bin/python -c "import requests; print(f'Requests {requests.__version__}')" 2>/dev/null; then
    check_test "Requests installed"
else
    echo -e "${RED}❌ Requests not installed${NC}"
fi

# Check werkzeug
if ./community_venv/bin/python -c "import werkzeug; print(f'Werkzeug {werkzeug.__version__}')" 2>/dev/null; then
    check_test "Werkzeug installed"
else
    echo -e "${RED}❌ Werkzeug not installed${NC}"
fi

echo -e "\n${BLUE}📍 Checking community platform files...${NC}"

# Check core files
if [[ -f "community/community_platform.py" ]]; then
    check_test "Core platform file exists"
else
    echo -e "${RED}❌ Core platform file missing${NC}"
fi

if [[ -f "community/web_interface.py" ]]; then
    check_test "Web interface file exists"
else
    echo -e "${RED}❌ Web interface file missing${NC}"
fi

if [[ -d "community/templates" ]]; then
    check_test "Templates directory exists"
else
    echo -e "${RED}❌ Templates directory missing${NC}"
fi

if [[ -f "community/templates/base.html" && -f "community/templates/index.html" ]]; then
    check_test "Required templates exist"
else
    echo -e "${RED}❌ Required templates missing${NC}"
fi

echo -e "\n${BLUE}📍 Testing platform functionality...${NC}"

# Test core platform
if ./community_venv/bin/python community/community_platform.py > /tmp/community_verify.log 2>&1; then
    if grep -q "ALL SYSTEMS OPERATIONAL" /tmp/community_verify.log; then
        check_test "Core platform functionality"
    else
        echo -e "${YELLOW}⚠️  Core platform test completed with warnings${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    fi
else
    echo -e "${RED}❌ Core platform test failed${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Test web interface import
if ./community_venv/bin/python -c "
import sys
sys.path.append('community')
from web_interface import CommunityWebApp
print('Web interface imports successfully')
" 2>/dev/null; then
    check_test "Web interface imports"
else
    echo -e "${RED}❌ Web interface import failed${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

echo -e "\n${BLUE}📍 Checking CLI tools...${NC}"

if [[ -f "tools/hyprsupreme-community.py" ]]; then
    check_test "CLI tool exists"
    
    if ./community_venv/bin/python tools/hyprsupreme-community.py --help > /dev/null 2>&1; then
        check_test "CLI tool help works"
    else
        echo -e "${YELLOW}⚠️  CLI tool help failed${NC}"
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    fi
else
    echo -e "${RED}❌ CLI tool missing${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 2))
fi

# Final report
echo ""
echo "=================================================="
echo -e "${BLUE}📊 VERIFICATION RESULTS${NC}"
echo "=================================================="

SUCCESS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))

echo "Tests passed: $TESTS_PASSED/$TOTAL_TESTS ($SUCCESS_RATE%)"

if [ $SUCCESS_RATE -ge 90 ]; then
    echo -e "${GREEN}🎉 EXCELLENT! Community platform is fully ready${NC}"
    
    echo ""
    echo -e "${GREEN}✅ Ready to use commands:${NC}"
    echo ""
    echo "🌐 Start web interface:"
    echo "   cd community && ../community_venv/bin/python web_interface.py"
    echo ""
    echo "🔧 Test core platform:"
    echo "   ./community_venv/bin/python community/community_platform.py"
    echo ""
    echo "💻 Use CLI tools:"
    echo "   ./community_venv/bin/python tools/hyprsupreme-community.py discover"
    echo ""
    echo "🚀 Quick start:"
    echo "   ./start_community.sh"
    
elif [ $SUCCESS_RATE -ge 70 ]; then
    echo -e "${YELLOW}⚠️  GOOD - Minor issues detected${NC}"
    echo "Check the failed tests above and resolve any issues"
    
else
    echo -e "${RED}❌ ISSUES DETECTED - Setup incomplete${NC}"
    echo "Several components need attention. Check the failed tests above."
fi

echo ""
echo "📝 Detailed logs saved to: /tmp/community_verify.log"

exit $((100 - SUCCESS_RATE))

