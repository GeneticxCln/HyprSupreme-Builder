#!/bin/bash

# Error handling
set -euo pipefail

# HyprSupreme Community Platform Connectivity Test

echo "🔧 HyprSupreme Community Platform Connectivity Test"
echo "=================================================="

# Check Python environment
echo "📍 Checking Python environment..."
if command -v python3 &> /dev/null; then
    echo "✅ Python3 is available"
    python3 --version
else
    echo "❌ Python3 not found"
    exit 1
fi

# Check virtual environment
if [[ -d "community_venv" ]]; then
    echo "✅ Virtual environment exists"
    source community_venv/bin/activate
    echo "✅ Virtual environment activated"
    
    # Check Flask
    if python -c "import flask" 2>/dev/null; then
        echo "✅ Flask is available"
    else
        echo "❌ Flask not available"
    fi
    
    # Check requests
    if python -c "import requests" 2>/dev/null; then
        echo "✅ Requests library available"
    else
        echo "❌ Requests library not available"
    fi
    
else
    echo "⚠️  Virtual environment not found"
    echo "Creating virtual environment..."
    python3 -m venv community_venv
    source community_venv/bin/activate
    pip install flask werkzeug requests
fi

# Test community platform
echo "📍 Testing community platform..."
cd community
python3 community_platform.py

echo "✅ Connectivity test completed!"
