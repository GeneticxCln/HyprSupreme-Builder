#!/bin/bash

# Error handling
set -euo pipefail

# Simple launcher for HyprSupreme Community Web Interface

echo "🚀 Launching HyprSupreme Community Web Interface..."
echo "=================================================="

# Check if we're in the right directory
if [[ ! -f "community/web_interface.py" ]]; then
    echo "❌ Error: web_interface.py not found in community/ directory"
    echo "Please run this script from the HyprSupreme-Builder root directory"
    exit 1
fi

# Check if virtual environment exists
if [[ ! -f "community_venv/bin/python" ]]; then
    echo "❌ Error: Virtual environment not found"
    echo "Please run: python3 -m venv community_venv"
    echo "Then install packages: ./community_venv/bin/pip install flask werkzeug requests"
    exit 1
fi

# Check if Flask is installed
if ! ./community_venv/bin/python -c "import flask" 2>/dev/null; then
    echo "⚠️  Flask not found. Installing dependencies..."
    ./community_venv/bin/pip install flask werkzeug requests jinja2
fi

echo "✅ Environment check passed"
echo "📍 Starting web server..."
echo "🌐 Visit: http://localhost:5000"
echo "🛑 Press Ctrl+C to stop the server"
echo ""

# Change to community directory and run
cd community
../community_venv/bin/python web_interface.py

