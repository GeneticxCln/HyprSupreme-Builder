"""
Pytest configuration and shared fixtures for HyprSupreme-Builder tests.
"""

import os
import sys
import tempfile
import shutil
import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

@pytest.fixture
def temp_dir():
    """Create a temporary directory for tests."""
    temp_path = tempfile.mkdtemp()
    yield Path(temp_path)
    shutil.rmtree(temp_path, ignore_errors=True)

@pytest.fixture
def mock_home_dir(temp_dir):
    """Mock home directory for tests."""
    home_path = temp_dir / "home" / "testuser"
    home_path.mkdir(parents=True)
    
    with patch.dict(os.environ, {"HOME": str(home_path)}):
        yield home_path

@pytest.fixture
def sample_config():
    """Sample configuration for tests."""
    return {
        "preset": "jakoolit",
        "components": {
            "hyprland": True,
            "waybar": True,
            "rofi": True,
            "kitty": True,
            "nvidia": False
        },
        "theme": {
            "name": "Catppuccin",
            "variant": "mocha"
        },
        "performance": {
            "gaming_mode": True,
            "power_save": False
        }
    }

@pytest.fixture
def mock_system_commands():
    """Mock system commands for testing."""
    with patch('subprocess.run') as mock_run, \
         patch('subprocess.check_output') as mock_output, \
         patch('subprocess.Popen') as mock_popen:
        
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = ""
        mock_run.return_value.stderr = ""
        
        mock_output.return_value = b"mock output"
        
        mock_process = MagicMock()
        mock_process.communicate.return_value = (b"", b"")
        mock_process.returncode = 0
        mock_popen.return_value = mock_process
        
        yield {
            'run': mock_run,
            'output': mock_output,
            'popen': mock_popen
        }

@pytest.fixture
def project_root_fixture():
    """Project root path fixture."""
    return project_root

@pytest.fixture(autouse=True)
def setup_test_environment(temp_dir):
    """Set up test environment variables."""
    test_env = {
        "XDG_CONFIG_HOME": str(temp_dir / ".config"),
        "XDG_DATA_HOME": str(temp_dir / ".local" / "share"),
        "XDG_CACHE_HOME": str(temp_dir / ".cache"),
        "HYPRSUPREME_TEST_MODE": "1"
    }
    
    # Create directories
    for path in test_env.values():
        if path != "1":  # Skip HYPRSUPREME_TEST_MODE
            Path(path).mkdir(parents=True, exist_ok=True)
    
    with patch.dict(os.environ, test_env):
        yield

@pytest.fixture
def mock_package_manager():
    """Mock package manager operations."""
    def mock_install_packages(packages, manager="auto"):
        return True, f"Successfully installed {len(packages)} packages"
    
    def mock_check_package(package):
        return package in ["git", "curl", "wget", "base-devel"]
    
    return {
        "install": mock_install_packages,
        "check": mock_check_package
    }

class TestLogger:
    """Test logger for capturing log messages."""
    
    def __init__(self):
        self.messages = []
    
    def info(self, msg):
        self.messages.append(("INFO", msg))
    
    def warning(self, msg):
        self.messages.append(("WARNING", msg))
    
    def error(self, msg):
        self.messages.append(("ERROR", msg))
    
    def debug(self, msg):
        self.messages.append(("DEBUG", msg))
    
    def clear(self):
        self.messages.clear()

@pytest.fixture
def test_logger():
    """Test logger fixture."""
    return TestLogger()

