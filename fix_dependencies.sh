#!/bin/bash
# HyprSupreme-Builder Dependency Fixer
# This script will install missing dependencies for HyprSupreme-Builder

set -e

echo "🔧 HyprSupreme-Builder Dependency Fixer"
echo "======================================"
echo

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on a supported system
if ! command -v pacman &> /dev/null; then
    print_error "This script is designed for Arch-based systems with pacman"
    print_error "For other distributions, please install the following packages manually:"
    echo "  - python-yaml or PyYAML"
    echo "  - python-requests or python3-requests"
    echo "  - python-psutil or python3-psutil"
    echo "  - python-cryptography or python3-cryptography"
    echo "  - python-gobject or python3-gi"
    echo "  - gtk4 and libadwaita"
    exit 1
fi

print_status "Detected Arch-based system with pacman"

# Check if user has sudo access
if ! sudo -n true 2>/dev/null; then
    print_warning "This script requires sudo access to install system packages"
    echo "Please run: sudo ./fix_dependencies.sh"
    echo
    print_status "Alternatively, install packages manually:"
    echo "sudo pacman -S --needed python-yaml python-requests python-psutil python-cryptography python-gobject gtk4 libadwaita"
    exit 1
fi

# Install system packages
print_status "Installing system packages..."
sudo pacman -S --needed --noconfirm \
    python-yaml \
    python-requests \
    python-psutil \
    python-cryptography \
    python-gobject \
    gtk4 \
    libadwaita \
    webkit2gtk-4.1 \
    || {
        print_error "Failed to install some system packages"
        print_warning "Trying to install missing packages with pip..."
        
        # Fallback to pip installation
        python3 -m pip install --user -r requirements.txt || {
            print_error "Failed to install Python packages with pip"
            print_error "Please install dependencies manually"
            exit 1
        }
    }

print_status "System packages installed successfully"

# Verify installations
print_status "Verifying installations..."

missing_deps=()

# Check Python modules
python3 -c "import yaml" 2>/dev/null || missing_deps+=("yaml")
python3 -c "import requests" 2>/dev/null || missing_deps+=("requests") 
python3 -c "import psutil" 2>/dev/null || missing_deps+=("psutil")
python3 -c "import cryptography" 2>/dev/null || missing_deps+=("cryptography")
python3 -c "import gi; gi.require_version('Gtk', '4.0')" 2>/dev/null || missing_deps+=("GTK4 bindings")

if [ ${#missing_deps[@]} -eq 0 ]; then
    print_status "All dependencies verified successfully!"
else
    print_warning "Some dependencies are still missing: ${missing_deps[*]}"
    print_status "Attempting to install missing Python packages with pip..."
    
    python3 -m pip install --user PyYAML requests psutil cryptography PyGObject || {
        print_error "Failed to install with pip. You may need to install these packages manually."
    }
fi

# Test HyprSupreme tools
print_status "Testing HyprSupreme tools..."

if ./hyprsupreme doctor >/dev/null 2>&1; then
    print_status "✅ Main script working"
else
    print_warning "⚠️  Main script has issues"
fi

if python3 tools/ai_assistant.py analyze >/dev/null 2>&1; then
    print_status "✅ AI Assistant working"
else
    print_warning "⚠️  AI Assistant has issues"
fi

if python3 gui/hyprsupreme-gui.py --help >/dev/null 2>&1; then
    print_status "✅ GUI dependencies working"
else
    print_warning "⚠️  GUI has dependency issues"
fi

echo
print_status "Dependency fix complete!"
print_status "You can now run: ./hyprsupreme --help"
echo

