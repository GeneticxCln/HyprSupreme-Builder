# HyprSupreme-Builder Makefile
# Common development and maintenance tasks

.PHONY: help install install-dev test test-unit test-integration test-performance
.PHONY: lint format type-check security-check clean build docker-build docker-run
.PHONY: docs setup release

# Default target
help:
	@echo "HyprSupreme-Builder Development Commands"
	@echo "======================================="
	@echo ""
	@echo "Setup & Installation:"
	@echo "  setup           - Set up development environment"
	@echo "  install         - Install the package"
	@echo "  install-dev     - Install with development dependencies"
	@echo ""
	@echo "Testing:"
	@echo "  test            - Run all tests"
	@echo "  test-unit       - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-performance - Run performance tests only"
	@echo "  test-bats       - Run BATS shell tests"
	@echo ""
	@echo "Code Quality:"
	@echo "  lint            - Run all linters"
	@echo "  format          - Format code with black and isort"
	@echo "  type-check      - Run mypy type checking"
	@echo "  security-check  - Run security scans"
	@echo ""
	@echo "Docker:"
	@echo "  docker-build    - Build Docker image"
	@echo "  docker-run      - Run Docker container"
	@echo "  docker-dev      - Run development Docker container"
	@echo ""
	@echo "Build & Release:"
	@echo "  build           - Build distribution packages"
	@echo "  clean           - Clean build artifacts"
	@echo "  docs            - Generate documentation"
	@echo "  release         - Create a release"

# Setup and Installation
setup:
	@echo "Setting up development environment..."
	./setup-dev.sh

install:
	pip install .

install-dev:
	pip install -e ".[dev,test,web,gui,all]"

# Testing
test:
	@echo "Running all tests..."
	pytest tests/ -v --cov=tools --cov=gui --cov=community
	@if command -v bats >/dev/null 2>&1; then \
		echo "Running BATS tests..."; \
		bats tests/test_*.bats; \
	else \
		echo "BATS not found, skipping shell tests"; \
	fi

test-unit:
	pytest tests/unit/ -v

test-integration:
	pytest tests/integration/ -v

test-performance:
	pytest tests/performance/ -v -m "not slow"

test-performance-full:
	pytest tests/performance/ -v

test-bats:
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/test_*.bats; \
	else \
		echo "BATS not installed. Install with: sudo pacman -S bats"; \
		exit 1; \
	fi

# Code Quality
lint:
	@echo "Running linters..."
	flake8 tools/ gui/ community/ --max-line-length=88 --extend-ignore=E203,W503
	black --check .
	isort --check-only .
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -not -path "./sources/*" -exec shellcheck {} \;; \
	fi

format:
	@echo "Formatting code..."
	black .
	isort .

type-check:
	mypy tools/ gui/ community/ --ignore-missing-imports

security-check:
	@echo "Running security checks..."
	bandit -r tools/ gui/ community/ -f json -o bandit-report.json || true
	safety check --json --output safety-report.json || true
	@echo "Security reports generated: bandit-report.json, safety-report.json"

# Docker
docker-build:
	docker build -t hyprsupreme-builder .

docker-run:
	docker run -p 5000:5000 -v $(PWD)/data:/app/data -v $(PWD)/config:/app/config hyprsupreme-builder

docker-dev:
	docker-compose up --build

docker-clean:
	docker system prune -f
	docker rmi hyprsupreme-builder 2>/dev/null || true

# Build and Release
build: clean
	@echo "Building distribution packages..."
	python -m build

clean:
	@echo "Cleaning build artifacts..."
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name ".pytest_cache" -delete
	rm -f .coverage
	rm -rf htmlcov/
	rm -f bandit-report.json safety-report.json

docs:
	@echo "Documentation files:"
	@echo "  README.md - Main documentation"
	@echo "  API_DOCUMENTATION.md - API reference"
	@echo "  TROUBLESHOOTING.md - Troubleshooting guide"
	@echo "  CONTRIBUTING.md - Contribution guidelines"
	@echo "  SECURITY.md - Security policy"

# Development helpers
serve:
	python community/web_interface.py

install-deps:
	@echo "Installing system dependencies..."
	@if command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --needed python python-pip git curl wget; \
	elif command -v apt >/dev/null 2>&1; then \
		sudo apt update && sudo apt install -y python3 python3-pip git curl wget; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y python3 python3-pip git curl wget; \
	fi

check-system:
	@echo "System Information:"
	@echo "=================="
	@echo "OS: $(shell uname -s)"
	@echo "Architecture: $(shell uname -m)"
	@echo "Python: $(shell python3 --version 2>/dev/null || echo 'Not found')"
	@echo "Git: $(shell git --version 2>/dev/null || echo 'Not found')"
	@echo "Docker: $(shell docker --version 2>/dev/null || echo 'Not found')"
	@echo "Node.js: $(shell node --version 2>/dev/null || echo 'Not found')"

# Pre-commit
pre-commit-install:
	pre-commit install
	pre-commit install --hook-type commit-msg

pre-commit-run:
	pre-commit run --all-files

# Release process
version-bump:
	@echo "Current version: $(shell cat VERSION)"
	@read -p "Enter new version: " version; \
	echo $$version > VERSION; \
	echo "Version updated to: $$version"

release: test lint build
	@echo "Creating release..."
	@echo "1. Tests passed ✓"
	@echo "2. Code quality checks passed ✓" 
	@echo "3. Distribution built ✓"
	@echo ""
	@echo "Next steps:"
	@echo "1. Update CHANGELOG.md"
	@echo "2. Commit changes: git add -A && git commit -m 'chore: release v$(shell cat VERSION)'"
	@echo "3. Tag release: git tag v$(shell cat VERSION)"
	@echo "4. Push: git push origin main --tags"
	@echo "5. Upload to PyPI: twine upload dist/*"

# Quick development commands
dev-setup: setup install-dev pre-commit-install
	@echo "Development environment ready!"

dev-test: format lint test
	@echo "Development tests completed!"

# Project maintenance
update-deps:
	pip-compile --upgrade requirements.txt
	pre-commit autoupdate

# Utility commands
count-lines:
	@echo "Line count by file type:"
	@find . -name "*.py" -not -path "./sources/*" -not -path "./venv/*" | xargs wc -l | tail -1 | awk '{print "Python: " $$1 " lines"}'
	@find . -name "*.sh" -not -path "./sources/*" | xargs wc -l | tail -1 | awk '{print "Shell: " $$1 " lines"}'
	@find . -name "*.md" | xargs wc -l | tail -1 | awk '{print "Markdown: " $$1 " lines"}'

project-info:
	@echo "HyprSupreme-Builder Project Information"
	@echo "======================================"
	@echo "Version: $(shell cat VERSION)"
	@echo "Python files: $(shell find . -name "*.py" -not -path "./sources/*" -not -path "./venv/*" | wc -l)"
	@echo "Shell scripts: $(shell find . -name "*.sh" -not -path "./sources/*" | wc -l)"
	@echo "Documentation files: $(shell find . -name "*.md" | wc -l)"
	@echo "Test files: $(shell find tests/ -name "*.py" -o -name "*.bats" | wc -l)"
	@echo "Git commits: $(shell git rev-list --count HEAD 2>/dev/null || echo 'N/A')"

