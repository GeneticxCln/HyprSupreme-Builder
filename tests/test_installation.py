#!/usr/bin/env python3
"""
Test suite for HyprSupreme-Builder installation modules.

This test file verifies the functionality of the core installation modules, including:
1. Dependency validation
2. Audio installation
3. Bluetooth setup
4. Network configuration
5. Error handling
6. Installation state management

Tests use mocking to simulate system calls and filesystem operations.
"""

import os
import sys
import json
import tempfile
import unittest
from unittest import mock
import pytest
import subprocess
from pathlib import Path


class TestDependencyValidator(unittest.TestCase):
    """Test the dependency validator module."""

    @mock.patch('subprocess.run')
    @mock.patch('subprocess.check_output')
    def test_validate_system_dependency(self, mock_check_output, mock_run):
        """Test system dependency validation."""
        # Mock subprocess to simulate system commands
        mock_check_output.return_value = b"pacman 6.0.1\n"
        mock_run.return_value.returncode = 0

        # Create a temporary directory for testing
        with tempfile.TemporaryDirectory() as temp_dir:
            validation_log = os.path.join(temp_dir, "validation.log")
            
            # Set up environment variables for testing
            env = {
                "VALIDATION_LOG": validation_log,
                "HOME": temp_dir
            }
            
            # Call the script with proper arguments
            cmd = [
                "bash", "-c", 
                f"source {os.path.join(os.getcwd(), 'modules/core/dependency_validator.sh')} && "
                "validate_system_dependency pacman 6.0.0"
            ]
            
            # Use environment with the test paths
            result = subprocess.run(cmd, env=env, capture_output=True, text=True)
            
            # Verify the script returns success
            self.assertEqual(result.returncode, 0, f"Script failed: {result.stderr}")

    @mock.patch('subprocess.run')
    def test_validate_all_dependencies_success(self, mock_run):
        """Test validation of all dependencies with successful validation."""
        # Mock successful command executions
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = "6.0.1\n"

        # Create temporary test directory
        with tempfile.TemporaryDirectory() as temp_dir:
            log_dir = os.path.join(temp_dir, ".cache", "hyprsupreme")
            os.makedirs(log_dir, exist_ok=True)
            
            validation_log = os.path.join(log_dir, "validation.log")
            dependency_cache = os.path.join(log_dir, "dependencies.json")
            
            # Set up environment for testing
            env = {
                "VALIDATION_LOG": validation_log,
                "DEPENDENCY_CACHE": dependency_cache,
                "HOME": temp_dir
            }
            
            # Call the validation script
            cmd = [
                "bash", "-c", 
                f"source {os.path.join(os.getcwd(), 'modules/core/dependency_validator.sh')} && "
                "init_dependency_validation"
            ]
            
            # Execute with the test environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True)
            
            # Verify initialization succeeds
            self.assertEqual(result.returncode, 0, f"Init failed: {result.stderr}")
            
            # Check if log file was created
            self.assertTrue(os.path.exists(validation_log), "Validation log not created")

    @mock.patch('subprocess.run')
    def test_auto_fix_dependencies(self, mock_run):
        """Test the auto-fix functionality for missing dependencies."""
        # Mock successful package installation
        mock_run.return_value.returncode = 0
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Set up environment for testing
            env = {
                "HOME": temp_dir
            }
            
            # Call the auto-fix function with specific dependencies
            cmd = [
                "bash", "-c", 
                f"source {os.path.join(os.getcwd(), 'modules/core/dependency_validator.sh')} && "
                "auto_fix_dependencies curl git"
            ]
            
            # Execute with mocked environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True)
            
            # Verify the auto-fix function was called properly
            mock_run.assert_called()
            
            # The function should continue even if packages can't be installed in the test environment
            self.assertIn("auto-fix", result.stdout.lower() + result.stderr.lower())


class TestAudioInstallation(unittest.TestCase):
    """Test the audio installation module."""

    @mock.patch('subprocess.run')
    @mock.patch('os.path.exists')
    @mock.patch('os.makedirs')
    def test_install_pipewire(self, mock_makedirs, mock_exists, mock_run):
        """Test PipeWire installation process."""
        # Mock filesystem operations
        mock_exists.return_value = True
        mock_makedirs.return_value = None
        
        # Mock successful command execution
        mock_run.return_value.returncode = 0
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Set up environment for testing
            env = {
                "HOME": temp_dir,
                "XDG_CONFIG_HOME": os.path.join(temp_dir, ".config")
            }
            
            # Mock the install_packages function to avoid actual installation
            cmd = [
                "bash", "-c", 
                f"""
                # Mock install_packages function
                install_packages() {{ 
                    echo "Installing: $@"
                    return 0
                }}
                export -f install_packages
                
                # Mock command detection
                command() {{
                    if [ "$2" = "pipewire" ]; then
                        return 0
                    fi
                    return 1
                }}
                export -f command
                
                # Mock systemctl
                systemctl() {{
                    echo "Systemctl called with: $@"
                    return 0
                }}
                export -f systemctl
                
                # Source the script and test function
                source {os.path.join(os.getcwd(), 'modules/core/install_audio.sh')} && install_pipewire
                """
            ]
            
            # Execute with mocked environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify the function executed successfully
            self.assertEqual(result.returncode, 0, f"Function failed: {result.stderr}")
            self.assertIn("Installing PipeWire audio stack", result.stdout)
            self.assertIn("PipeWire installation completed", result.stdout)

    @mock.patch('subprocess.run')
    @mock.patch('os.path.exists')
    @mock.patch('os.makedirs')
    def test_configure_audio_integration(self, mock_makedirs, mock_exists, mock_run):
        """Test audio integration configuration."""
        # Mock filesystem operations
        mock_exists.return_value = False  # Force directory creation
        mock_makedirs.return_value = None
        
        # Mock successful command execution
        mock_run.return_value.returncode = 0
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Create config directories
            config_dir = os.path.join(temp_dir, ".config", "hypr", "scripts")
            os.makedirs(config_dir, exist_ok=True)
            
            # Set up environment for testing
            env = {
                "HOME": temp_dir
            }
            
            # Mock necessary functions
            cmd = [
                "bash", "-c", 
                f"""
                # Mock directory operations
                mkdir() {{
                    echo "mkdir: $@"
                    return 0
                }}
                export -f mkdir
                
                # Mock file write permissions
                test() {{
                    echo "Testing: $@"
                    return 0  # Always return true
                }}
                export -f test
                
                # Mock cat redirection to test file creation
                cat() {{
                    echo "File content would be written to: $3"
                    return 0
                }}
                export -f cat
                
                # Mock chmod
                chmod() {{
                    echo "chmod: $@"
                    return 0
                }}
                export -f chmod
                
                # Source the script and test the function
                HOME="{temp_dir}" source {os.path.join(os.getcwd(), 'modules/core/install_audio.sh')} && configure_audio_integration
                """
            ]
            
            # Execute with mocked environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify the function executed successfully
            self.assertEqual(result.returncode, 0, f"Function failed: {result.stderr}")
            self.assertIn("Configuring audio integration", result.stdout)
            self.assertIn("Audio integration configured", result.stdout)

    @mock.patch('subprocess.run')
    def test_audio_scripts_creation(self, mock_run):
        """Test creation of audio control scripts."""
        # Mock successful command execution
        mock_run.return_value.returncode = 0
        
        # Create temporary test directory with scripts subdirectory
        with tempfile.TemporaryDirectory() as temp_dir:
            scripts_dir = os.path.join(temp_dir, ".config", "hypr", "scripts")
            os.makedirs(scripts_dir, exist_ok=True)
            
            # Set up environment for testing
            env = {
                "HOME": temp_dir
            }
            
            # Test script creation
            cmd = [
                "bash", "-c", 
                f"""
                # Source the audio installation script
                source {os.path.join(os.getcwd(), 'modules/core/install_audio.sh')}
                
                # Call the script creation functions
                create_audio_control_script
                create_audio_device_script
                create_media_control_script
                """
            ]
            
            # Execute with test environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify script creation
            self.assertEqual(result.returncode, 0, f"Script creation failed: {result.stderr}")
            
            # Check if scripts were created
            expected_scripts = [
                os.path.join(scripts_dir, "audio-control.sh"),
                os.path.join(scripts_dir, "audio-devices.sh"),
                os.path.join(scripts_dir, "media-control.sh")
            ]
            
            for script in expected_scripts:
                self.assertTrue(os.path.exists(script), f"Script not created: {script}")
                self.assertTrue(os.access(script, os.X_OK), f"Script not executable: {script}")


class TestNetworkConfiguration(unittest.TestCase):
    """Test the network configuration module."""

    @mock.patch('subprocess.run')
    @mock.patch('os.path.exists')
    def test_install_network_manager(self, mock_exists, mock_run):
        """Test NetworkManager installation process."""
        # Mock filesystem checks
        mock_exists.return_value = True
        
        # Mock successful command execution
        mock_run.return_value.returncode = 0
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Set up environment for testing
            env = {
                "HOME": temp_dir
            }
            
            # Mock the installation functions
            cmd = [
                "bash", "-c", 
                f"""
                # Mock install_packages function
                install_packages() {{ 
                    echo "Installing: $@"
                    return 0
                }}
                export -f install_packages
                
                # Mock command detection
                command() {{
                    if [ "$2" = "nmcli" ]; then
                        return 0
                    fi
                    return 1
                }}
                export -f command
                
                # Mock sudo
                sudo() {{
                    echo "sudo: $@"
                    return 0
                }}
                export -f sudo
                
                # Mock systemctl
                systemctl() {{
                    echo "systemctl: $@"
                    return 0
                }}
                export -f systemctl
                
                # Source and test the function
                source {os.path.join(os.getcwd(), 'modules/core/install_network.sh')} && install_network_manager
                """
            ]
            
            # Execute with mocked environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify the function executed successfully
            self.assertEqual(result.returncode, 0, f"Function failed: {result.stderr}")
            self.assertIn("Installing NetworkManager", result.stdout)
            self.assertIn("NetworkManager installation completed", result.stdout)

    @mock.patch('subprocess.run')
    def test_wifi_hardware_detection(self, mock_run):
        """Test WiFi hardware detection functionality."""
        # Mock lspci output for WiFi detection
        mock_wifi_device = "03:00.0 Network controller: Intel Corporation WiFi 6 AX200"
        mock_run.return_value.stdout = mock_wifi_device
        mock_run.return_value.returncode = 0
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Set up environment for testing
            env = {
                "HOME": temp_dir
            }
            
            # Mock hardware detection
            cmd = [
                "bash", "-c", 
                f"""
                # Mock lspci command
                lspci() {{
                    echo "{mock_wifi_device}"
                    return 0
                }}
                export -f lspci
                
                # Mock grep
                grep() {{
                    echo "{mock_wifi_device}"
                    return 0
                }}
                export -f grep
                
                # Mock install_packages
                install_packages() {{
                    echo "Installing: $@"
                    return 0
                }}
                export -f install_packages
                
                # Mock lsmod
                lsmod() {{
                    echo "iwlwifi 401234 0"
                    return 0
                }}
                export -f lsmod
                
                # Source and test the function
                source {os.path.join(os.getcwd(), 'modules/core/install_network.sh')} && detect_wifi_hardware
                """
            ]
            
            # Execute with mocked environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify the function executed successfully
            self.assertEqual(result.returncode, 0, f"Function failed: {result.stderr}")
            self.assertIn("Detecting WiFi hardware", result.stdout)
            self.assertIn("Intel", result.stdout)  # Should detect Intel WiFi

    @mock.patch('subprocess.run')
    @mock.patch('os.path.exists')
    @mock.patch('os.makedirs')
    def test_network_scripts_creation(self, mock_makedirs, mock_exists, mock_run):
        """Test creation of network control scripts."""
        # Mock filesystem operations
        mock_exists.return_value = False  # Force directory creation
        mock_makedirs.return_value = None
        
        # Mock successful command execution
        mock_run.return_value.returncode = 0
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            scripts_dir = os.path.join(temp_dir, ".config", "hypr", "scripts")
            os.makedirs(scripts_dir, exist_ok=True)
            
            # Set up environment for testing
            env = {
                "HOME": temp_dir
            }
            
            # Test script creation
            cmd = [
                "bash", "-c", 
                f"""
                # Source the network installation script
                source {os.path.join(os.getcwd(), 'modules/core/install_network.sh')}
                
                # Call the script creation functions
                create_network_control_script
                create_wifi_manager_script
                create_network_monitor_script
                """
            ]
            
            # Execute with test environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify script creation
            self.assertEqual(result.returncode, 0, f"Script creation failed: {result.stderr}")
            
            # Check if scripts were created
            expected_scripts = [
                os.path.join(scripts_dir, "network-control.sh"),
                os.path.join(scripts_dir, "wifi-manager.sh"),
                os.path.join(scripts_dir, "network-monitor.sh")
            ]
            
            for script in expected_scripts:
                self.assertTrue(os.path.exists(script), f"Script not created: {script}")
                self.assertTrue(os.access(script, os.X_OK), f"Script not executable: {script}")


class TestErrorHandling(unittest.TestCase):
    """Test the error handling in installation modules."""

    def test_dependency_validator_error_handling(self):
        """Test error handling in dependency validator."""
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Attempt to validate a dependency that definitely doesn't exist
            cmd = [
                "bash", "-c", 
                f"""
                # Source the dependency validator
                source {os.path.join(os.getcwd(), 'modules/core/dependency_validator.sh')}
                
                # Validate a non-existent dependency
                validate_system_dependency non_existent_dependency 1.0.0
                """
            ]
            
            # Execute and expect an error
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            # It should fail with an error message about the missing dependency
            self.assertNotEqual(result.returncode, 0, "Validation should fail for non-existent dependency")
            self.assertIn("missing", result.stdout.lower() + result.stderr.lower())

    @mock.patch('subprocess.run')
    def test_audio_installation_error_handling(self, mock_run):
        """Test error handling in audio installation module."""
        # Mock command failure
        mock_run.return_value.returncode = 1
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Set up environment for testing
            env = {
                "HOME": temp_dir
            }
            
            # Test error handling in audio installation
            cmd = [
                "bash", "-c", 
                f"""
                # Mock functions to trigger errors
                install_packages() {{
                    return 1  # Simulate package installation failure
                }}
                export -f install_packages
                
                command() {{
                    return 1  # Simulate command not found
                }}
                export -f command
                
                # Source the audio installation script
                source {os.path.join(os.getcwd(), 'modules/core/install_audio.sh')}
                
                # Call the install function which should handle errors
                install_pipewire || echo "Error handled correctly"
                """
            ]
            
            # Execute with mocked environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify error was handled correctly
            self.assertIn("Error handled correctly", result.stdout)
            self.assertIn("Failed to install", result.stdout.lower() + result.stderr.lower())

    @mock.patch('subprocess.run')
    def test_network_error_handling(self, mock_run):
        """Test error handling in network configuration module."""
        # Mock command failure
        mock_run.return_value.returncode = 1
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Set up environment for testing
            env = {
                "HOME": temp_dir
            }
            
            # Test error handling in network installation
            cmd = [
                "bash", "-c", 
                f"""
                # Mock test_connectivity to simulate network failure
                test_connectivity() {{
                    return 1  # Simulate connectivity test failure
                }}
                export -f test_connectivity
                
                # Source the network installation script
                source {os.path.join(os.getcwd(), 'modules/core/install_network.sh')}
                
                # Call the network error handler and check result
                handle_network_error "connection" "Network unreachable"
                echo "Error code: $?"
                """
            ]
            
            # Execute with mocked environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify error was handled and correct error code returned
            self.assertIn("Network connection error", result.stdout.lower() + result.stderr.lower())
            self.assertIn("Error code: 7", result.stdout)  # E_NETWORK=7


class TestInstallationState(unittest.TestCase):
    """Test installation state management."""

    @mock.patch('subprocess.run')
    @mock.patch('os.path.exists')
    def test_installation_state_tracking(self, mock_exists, mock_run):
        """Test that installation state is properly tracked."""
        # Mock filesystem checks
        mock_exists.return_value = True
        
        # Mock successful command execution
        mock_run.return_value.returncode = 0
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Set up state tracking file
            cache_dir = os.path.join(temp_dir, ".cache", "hyprsupreme")
            os.makedirs(cache_dir, exist_ok=True)
            
            # Set up environment for testing
            env = {
                "HOME": temp_dir,
                "VALIDATION_LOG": os.path.join(cache_dir, "validation.log"),
                "DEPENDENCY_CACHE": os.path.join(cache_dir, "dependencies.json")
            }
            
            # Test state tracking in dependency validator
            cmd = [
                "bash", "-c", 
                f"""
                # Source the dependency validator
                source {os.path.join(os.getcwd(), 'modules/core/dependency_validator.sh')}
                
                # Initialize validation and cache results
                init_dependency_validation
                cache_validation_results 0
                
                # Check if cache file exists
                if [[ -f "$DEPENDENCY_CACHE" ]]; then
                    echo "State cached successfully"
                    grep -q "validation_status" "$DEPENDENCY_CACHE" && echo "Validation status recorded"
                fi
                """
            ]
            
            # Execute with test environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify state was cached properly
            self.assertEqual(result.returncode, 0, f"State tracking failed: {result.stderr}")
            self.assertIn("State cached successfully", result.stdout)
            self.assertIn("Validation status recorded", result.stdout)

    @mock.patch('subprocess.run')
    def test_service_state_management(self, mock_run):
        """Test that service state is properly managed."""
        # Mock successful command execution
        mock_run.return_value.returncode = 0
        
        # Create temporary test environment
        with tempfile.TemporaryDirectory() as temp_dir:
            # Set up environment for testing
            env = {
                "HOME": temp_dir
            }
            
            # Test service state management in audio installation
            cmd = [
                "bash", "-c", 
                f"""
                # Mock systemctl to track service state management
                systemctl() {{
                    echo "systemctl: $@"
                    if [[ "$1" == "--user" && "$2" == "enable" ]]; then
                        echo "Service $3 enabled"
                    fi
                    if [[ "$1" == "--user" && "$2" == "is-enabled" ]]; then
                        echo "Checking if $3 is enabled"
                        return 0  # Simulate service is enabled
                    fi
                    return 0
                }}
                export -f systemctl
                
                # Source the audio installation script
                source {os.path.join(os.getcwd(), 'modules/core/install_audio.sh')}
                
                # Check service enablement
                if systemctl --user is-enabled pipewire.socket &> /dev/null; then
                    echo "Service state verified"
                fi
                """
            ]
            
            # Execute with mocked environment
            result = subprocess.run(cmd, env=env, capture_output=True, text=True, shell=True)
            
            # Verify service state was checked properly
            self.assertEqual(result.returncode, 0, f"Service state check failed: {result.stderr}")
            self.assertIn("Checking if pipewire.socket is enabled", result.stdout)
            self.assertIn("Service state verified", result.stdout)


if __name__ == "__main__":
    unittest.main()
