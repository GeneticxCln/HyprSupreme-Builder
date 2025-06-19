#!/bin/bash

# Error handling
set -euo pipefail

# Virtual Environment Runner for HyprSupreme-Builder
# This script runs Python tools with the virtual environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo "Virtual environment not found. Creating..."
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install PyYAML requests psutil cryptography
    echo "Virtual environment created successfully."
fi

# Activate virtual environment and run the command
source "$VENV_DIR/bin/activate"
exec "$@"

