#!/bin/bash
# Development Environment Setup for HyprSupreme-Builder

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if script is run from project root
if [[ ! -f "setup.py" || ! -f "pyproject.toml" ]]; then
    log_error "This script must be run from the project root directory"
    exit 1
fi

log_info "Setting up HyprSupreme-Builder development environment..."

# Check Python version
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
REQUIRED_VERSION="3.8"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
    log_error "Python 3.8+ is required. Current version: $PYTHON_VERSION"
    exit 1
fi

log_success "Python version check passed: $PYTHON_VERSION"

# Create virtual environment if it doesn't exist
if [[ ! -d "venv" ]]; then
    log_info "Creating virtual environment..."
    python3 -m venv venv
    log_success "Virtual environment created"
else
    log_info "Virtual environment already exists"
fi

# Activate virtual environment
log_info "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
log_info "Upgrading pip..."
pip install --upgrade pip

# Install development dependencies
log_info "Installing development dependencies..."
pip install -e ".[dev,web,gui,test,all]"

# Install pre-commit hooks
log_info "Installing pre-commit hooks..."
if command -v pre-commit >/dev/null 2>&1; then
    pre-commit install
    pre-commit install --hook-type commit-msg
    log_success "Pre-commit hooks installed"
else
    log_warning "pre-commit not found, installing..."
    pip install pre-commit
    pre-commit install
    pre-commit install --hook-type commit-msg
    log_success "Pre-commit installed and hooks configured"
fi

# Install additional development tools
log_info "Installing additional development tools..."

# BATS for shell testing
if ! command -v bats >/dev/null 2>&1; then
    log_info "Installing BATS (Bash Automated Testing System)..."
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm bats
    elif command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y bats
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y bats
    else
        log_warning "Could not install BATS automatically. Please install manually."
    fi
fi

# Shellcheck for shell script linting
if ! command -v shellcheck >/dev/null 2>&1; then
    log_info "Installing shellcheck..."
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm shellcheck
    elif command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y shellcheck
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y ShellCheck
    else
        log_warning "Could not install shellcheck automatically. Please install manually."
    fi
fi

# Docker (optional)
if ! command -v docker >/dev/null 2>&1; then
    log_warning "Docker not found. Install Docker to test containerized deployment."
    log_info "Installation guide: https://docs.docker.com/engine/install/"
fi

# Create development directories
log_info "Creating development directories..."
mkdir -p {logs,backups,config,data}
mkdir -p tests/{unit,integration,performance}

# Generate sample configuration
log_info "Creating sample development configuration..."
cat > config/dev-config.json << EOF
{
    "version": "2.0.0",
    "debug": true,
    "web_port": 5000,
    "web_host": "127.0.0.1",
    "community_enabled": true,
    "backup_enabled": true,
    "log_level": "DEBUG",
    "data_dir": "./data",
    "backup_dir": "./backups"
}
EOF

# Create secrets baseline for detect-secrets
log_info "Creating secrets baseline..."
if command -v detect-secrets >/dev/null 2>&1; then
    detect-secrets scan --baseline .secrets.baseline
    log_success "Secrets baseline created"
fi

# Run initial tests
log_info "Running initial tests..."
if python -m pytest tests/ -v --tb=short; then
    log_success "Initial tests passed"
else
    log_warning "Some tests failed. This is normal for a new setup."
fi

# Run BATS tests if available
if command -v bats >/dev/null 2>&1; then
    log_info "Running BATS tests..."
    if bats tests/test_*.bats; then
        log_success "BATS tests passed"
    else
        log_warning "Some BATS tests failed. Check test output above."
    fi
fi

# Create development aliases
log_info "Creating development aliases..."
cat > .dev-aliases << 'EOF'
# Development aliases for HyprSupreme-Builder
# Source this file: source .dev-aliases

alias hr-test="python -m pytest tests/ -v"
alias hr-test-unit="python -m pytest tests/unit/ -v"
alias hr-test-integration="python -m pytest tests/integration/ -v"
alias hr-test-bats="bats tests/test_*.bats"
alias hr-lint="pre-commit run --all-files"
alias hr-format="black . && isort ."
alias hr-type-check="mypy tools/ gui/ community/"
alias hr-security="bandit -r tools/ gui/ community/"
alias hr-coverage="python -m pytest --cov=tools --cov=gui --cov=community --cov-report=html"
alias hr-serve="python community/web_interface.py"
alias hr-build-docker="docker build -t hyprsupreme-builder ."
alias hr-run-docker="docker run -p 5000:5000 hyprsupreme-builder"
alias hr-clean="find . -type f -name '*.pyc' -delete && find . -type d -name '__pycache__' -delete"

# Quick commands
alias hr-dev-setup="./setup-dev.sh"
alias hr-finalize="./finalize_project.sh"
alias hr-install="./install.sh"

echo "HyprSupreme-Builder development aliases loaded!"
echo "Available commands:"
echo "  hr-test          - Run all tests"
echo "  hr-lint          - Run linting"
echo "  hr-format        - Format code"
echo "  hr-serve         - Start web server"
echo "  hr-build-docker  - Build Docker image"
EOF

# Display setup summary
log_success "Development environment setup complete!"
echo
echo "🎉 Setup Summary:"
echo "  ✅ Virtual environment created and activated"
echo "  ✅ Development dependencies installed"
echo "  ✅ Pre-commit hooks configured"
echo "  ✅ Development directories created"
echo "  ✅ Sample configuration generated"
echo
echo "📋 Next Steps:"
echo "  1. Source development aliases: source .dev-aliases"
echo "  2. Run tests: hr-test"
echo "  3. Start development server: hr-serve"
echo "  4. Check code quality: hr-lint"
echo
echo "📚 Documentation:"
echo "  • Development Guide: README.md"
echo "  • Contributing: CONTRIBUTING.md"
echo "  • Security: SECURITY.md"
echo
echo "🔧 Available Development Commands:"
echo "  • hr-test         - Run all tests"
echo "  • hr-lint         - Run code quality checks"
echo "  • hr-format       - Format code with Black and isort"
echo "  • hr-serve        - Start web development server"
echo "  • hr-coverage     - Generate test coverage report"
echo
log_info "Happy coding! 🚀"

