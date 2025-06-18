#!/usr/bin/env python3
"""
Unit tests for HyprSupreme encryption and security functions
Tests all cryptographic operations and security features
"""

import os
import sys
import unittest
import tempfile
import shutil
from pathlib import Path
import json
import time
import hashlib

# Add tools directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "tools"))

# Import by adding the specific file
import importlib.util
spec = importlib.util.spec_from_file_location("hyprsupreme_cloud", 
                                             Path(__file__).parent.parent / "tools" / "hyprsupreme-cloud.py")
hyprsupreme_cloud = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hyprsupreme_cloud)

HyprSupremeCloud = hyprsupreme_cloud.HyprSupremeCloud
ENCRYPTION_AVAILABLE = hyprsupreme_cloud.ENCRYPTION_AVAILABLE

class TestEncryption(unittest.TestCase):
    """Test encryption and cryptographic functions"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = Path(tempfile.mkdtemp())
        self.cloud = HyprSupremeCloud(str(self.test_dir / "config"))
        self.test_data = b"This is sensitive test data for encryption testing"
        
    def tearDown(self):
        """Clean up test environment"""
        shutil.rmtree(self.test_dir)
        
    @unittest.skipIf(not ENCRYPTION_AVAILABLE, "Cryptography module not available")
    def test_master_key_generation(self):
        """Test master key generation and storage"""
        # Test key generation
        key1 = self.cloud.get_or_create_master_key()
        self.assertEqual(len(key1), 32)  # 256-bit key
        
        # Test key persistence
        key2 = self.cloud.get_or_create_master_key()
        self.assertEqual(key1, key2)
        
        # Test key files exist
        key_file = self.cloud.keys_dir / "master.key"
        salt_file = self.cloud.keys_dir / "master.salt"
        self.assertTrue(key_file.exists())
        self.assertTrue(salt_file.exists())
        
        # Test file permissions
        self.assertEqual(oct(key_file.stat().st_mode)[-3:], '600')
        self.assertEqual(oct(salt_file.stat().st_mode)[-3:], '600')
        
    @unittest.skipIf(not ENCRYPTION_AVAILABLE, "Cryptography module not available")
    def test_device_keypair_generation(self):
        """Test RSA keypair generation for device authentication"""
        private_key, public_key = self.cloud.get_or_create_device_keypair()
        
        # Test key format
        self.assertTrue(private_key.startswith(b'-----BEGIN PRIVATE KEY-----'))
        self.assertTrue(public_key.startswith(b'-----BEGIN PUBLIC KEY-----'))
        
        # Test key persistence
        private_key2, public_key2 = self.cloud.get_or_create_device_keypair()
        self.assertEqual(private_key, private_key2)
        self.assertEqual(public_key, public_key2)
        
    @unittest.skipIf(not ENCRYPTION_AVAILABLE, "Cryptography module not available")
    def test_data_encryption_decryption(self):
        """Test AES-GCM encryption and decryption"""
        # Test basic encryption/decryption
        encrypted_data = self.cloud.encrypt_data(self.test_data)
        
        # Verify encrypted data structure
        self.assertIn('ciphertext', encrypted_data)
        self.assertIn('nonce', encrypted_data)
        self.assertIn('timestamp', encrypted_data)
        self.assertIn('aad', encrypted_data)
        
        # Test nonce is random
        encrypted_data2 = self.cloud.encrypt_data(self.test_data)
        self.assertNotEqual(encrypted_data['nonce'], encrypted_data2['nonce'])
        
        # Test decryption
        decrypted_data = self.cloud.decrypt_data(encrypted_data)
        self.assertEqual(decrypted_data, self.test_data)
        
    @unittest.skipIf(not ENCRYPTION_AVAILABLE, "Cryptography module not available")
    def test_encryption_with_additional_data(self):
        """Test encryption with additional authenticated data"""
        aad = b"Additional authenticated data"
        encrypted_data = self.cloud.encrypt_data(self.test_data, aad)
        
        # Should decrypt successfully with correct AAD
        decrypted_data = self.cloud.decrypt_data(encrypted_data, aad)
        self.assertEqual(decrypted_data, self.test_data)
        
        # Should fail with wrong AAD
        with self.assertRaises(Exception):
            self.cloud.decrypt_data(encrypted_data, b"Wrong AAD")
            
    @unittest.skipIf(not ENCRYPTION_AVAILABLE, "Cryptography module not available")
    def test_timestamp_validation(self):
        """Test timestamp validation for replay attack prevention"""
        # Create encrypted data
        encrypted_data = self.cloud.encrypt_data(self.test_data)
        
        # Should decrypt within time limit
        decrypted_data = self.cloud.decrypt_data(encrypted_data, max_age=3600)
        self.assertEqual(decrypted_data, self.test_data)
        
        # Manually create old timestamp
        old_timestamp = int(time.time() - 7200).to_bytes(8, 'big')  # 2 hours ago
        encrypted_data['timestamp'] = old_timestamp
        
        # Should fail with old timestamp
        with self.assertRaises(ValueError):
            self.cloud.decrypt_data(encrypted_data, max_age=3600)
            
    @unittest.skipIf(not ENCRYPTION_AVAILABLE, "Cryptography module not available")
    def test_digital_signatures(self):
        """Test digital signature creation and verification"""
        # Test signing
        signature = self.cloud.sign_data(self.test_data)
        self.assertIsInstance(signature, bytes)
        self.assertGreater(len(signature), 0)
        
        # Test verification with correct public key
        _, public_key = self.cloud.device_keypair
        is_valid = self.cloud.verify_signature(self.test_data, signature, public_key)
        self.assertTrue(is_valid)
        
        # Test verification with wrong data
        wrong_data = b"Wrong data"
        is_valid = self.cloud.verify_signature(wrong_data, signature, public_key)
        self.assertFalse(is_valid)
        
    def test_fallback_mode(self):
        """Test graceful fallback when encryption is not available"""
        # This test works even without cryptography module
        if not ENCRYPTION_AVAILABLE:
            # Test encryption fallback
            encrypted_data = self.cloud.encrypt_data(self.test_data)
            self.assertEqual(encrypted_data['ciphertext'], self.test_data)
            
            # Test decryption fallback
            decrypted_data = self.cloud.decrypt_data(encrypted_data)
            self.assertEqual(decrypted_data, self.test_data)
            
            # Test signature fallback
            signature = self.cloud.sign_data(self.test_data)
            expected_sig = hashlib.sha256(self.test_data).digest()
            self.assertEqual(signature, expected_sig)


class TestSecurityFeatures(unittest.TestCase):
    """Test security features and access controls"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = Path(tempfile.mkdtemp())
        self.cloud = HyprSupremeCloud(str(self.test_dir / "config"))
        
    def tearDown(self):
        """Clean up test environment"""
        shutil.rmtree(self.test_dir)
        
    def test_device_id_generation(self):
        """Test device ID generation and persistence"""
        device_id1 = self.cloud.get_or_create_device_id()
        self.assertIsInstance(device_id1, str)
        self.assertEqual(len(device_id1), 36)  # UUID format
        
        # Test persistence
        device_id2 = self.cloud.get_or_create_device_id()
        self.assertEqual(device_id1, device_id2)
        
        # Test file permissions
        device_file = self.cloud.config_dir / ".device_id"
        self.assertTrue(device_file.exists())
        self.assertEqual(oct(device_file.stat().st_mode)[-3:], '600')
        
    def test_secure_directory_creation(self):
        """Test secure directory creation with proper permissions"""
        # Test that secure directories are created with 0o700 permissions
        for directory in [self.cloud.cache_dir, self.cloud.encrypted_cache_dir, self.cloud.keys_dir]:
            self.assertTrue(directory.exists())
            self.assertEqual(oct(directory.stat().st_mode)[-3:], '700')
            
    def test_settings_security(self):
        """Test settings file security"""
        # Save settings
        self.cloud.settings['test_key'] = 'test_value'
        self.cloud.save_settings()
        
        # Test settings file exists
        self.assertTrue(self.cloud.settings_path.exists())
        
        # Test settings persistence
        cloud2 = HyprSupremeCloud(str(self.test_dir / "config"))
        self.assertEqual(cloud2.settings.get('test_key'), 'test_value')
        
    def test_authentication_simulation(self):
        """Test authentication mechanism"""
        # Test successful authentication
        success = self.cloud.authenticate("testuser", "testpass")
        self.assertTrue(success)
        self.assertEqual(self.cloud.settings['username'], "testuser")
        self.assertIn("fake_api_key", self.cloud.settings['api_key'])
        
        # Test failed authentication
        success = self.cloud.authenticate("", "")
        self.assertFalse(success)


class TestDataIntegrity(unittest.TestCase):
    """Test data integrity and validation"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = Path(tempfile.mkdtemp())
        self.cloud = HyprSupremeCloud(str(self.test_dir / "config"))
        
    def tearDown(self):
        """Clean up test environment"""
        shutil.rmtree(self.test_dir)
        
    def test_checksum_calculation(self):
        """Test file checksum calculation"""
        # Create test file
        test_file = self.test_dir / "test.txt"
        test_content = "Test content for checksum"
        test_file.write_text(test_content)
        
        # Calculate checksum
        checksum = self.cloud.calculate_checksum(test_file)
        
        # Verify checksum format (SHA256)
        self.assertEqual(len(checksum), 64)
        self.assertTrue(all(c in '0123456789abcdef' for c in checksum))
        
        # Verify checksum consistency
        checksum2 = self.cloud.calculate_checksum(test_file)
        self.assertEqual(checksum, checksum2)
        
        # Verify checksum changes with content
        test_file.write_text("Modified content")
        checksum3 = self.cloud.calculate_checksum(test_file)
        self.assertNotEqual(checksum, checksum3)
        
    def test_profile_validation(self):
        """Test configuration profile validation"""
        # Create mock config files
        config_dir = Path.home() / ".config"
        hypr_dir = config_dir / "hypr"
        hypr_dir.mkdir(parents=True, exist_ok=True)
        
        test_config = hypr_dir / "hyprland.conf"
        test_config.write_text("# Test Hyprland config")
        
        try:
            # Test profile creation
            profile_id = self.cloud.create_profile_from_current(
                "Test Profile",
                "Test description",
                ["test", "profile"]
            )
            
            self.assertIsInstance(profile_id, str)
            self.assertEqual(len(profile_id), 16)  # Expected hash length
            
            # Test profile retrieval
            profile = self.cloud.get_profile_from_db(profile_id)
            self.assertIsNotNone(profile)
            self.assertEqual(profile['name'], "Test Profile")
            self.assertEqual(profile['description'], "Test description")
            
            # Test profile components detection
            components = self.cloud.detect_components()
            self.assertIn("hyprland", components)
            
        finally:
            # Clean up
            if test_config.exists():
                test_config.unlink()
            if hypr_dir.exists() and not any(hypr_dir.iterdir()):
                hypr_dir.rmdir()


class TestPerformance(unittest.TestCase):
    """Test performance and efficiency of security operations"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = Path(tempfile.mkdtemp())
        self.cloud = HyprSupremeCloud(str(self.test_dir / "config"))
        
    def tearDown(self):
        """Clean up test environment"""
        shutil.rmtree(self.test_dir)
        
    @unittest.skipIf(not ENCRYPTION_AVAILABLE, "Cryptography module not available")
    def test_encryption_performance(self):
        """Test encryption performance with various data sizes"""
        test_sizes = [1024, 10240, 102400]  # 1KB, 10KB, 100KB
        
        for size in test_sizes:
            test_data = os.urandom(size)
            
            # Measure encryption time
            start_time = time.time()
            encrypted_data = self.cloud.encrypt_data(test_data)
            encryption_time = time.time() - start_time
            
            # Measure decryption time
            start_time = time.time()
            decrypted_data = self.cloud.decrypt_data(encrypted_data)
            decryption_time = time.time() - start_time
            
            # Verify correctness
            self.assertEqual(decrypted_data, test_data)
            
            # Performance should be reasonable (less than 1 second for these sizes)
            self.assertLess(encryption_time, 1.0)
            self.assertLess(decryption_time, 1.0)
            
    def test_key_generation_performance(self):
        """Test key generation performance"""
        if not ENCRYPTION_AVAILABLE:
            return
            
        # Test master key generation (should be fast on subsequent calls)
        start_time = time.time()
        for _ in range(10):
            key = self.cloud.get_or_create_master_key()
        key_gen_time = time.time() - start_time
        
        # Should be very fast after first generation
        self.assertLess(key_gen_time, 1.0)


if __name__ == '__main__':
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test cases
    suite.addTests(loader.loadTestsFromTestCase(TestEncryption))
    suite.addTests(loader.loadTestsFromTestCase(TestSecurityFeatures))
    suite.addTests(loader.loadTestsFromTestCase(TestDataIntegrity))
    suite.addTests(loader.loadTestsFromTestCase(TestPerformance))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Exit with appropriate code
    sys.exit(0 if result.wasSuccessful() else 1)

