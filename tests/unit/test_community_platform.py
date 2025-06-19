#!/usr/bin/env python3
"""
Unit tests for Community Platform
"""

import unittest
import tempfile
import shutil
import sys
import os
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

try:
    from community.community_platform import CommunityPlatform, Theme, User
except ImportError:
    # Skip tests if community module not available
    raise unittest.SkipTest("Community platform module not available")


class TestCommunityPlatform(unittest.TestCase):
    """Test cases for CommunityPlatform class"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()
        self.platform = CommunityPlatform(data_dir=self.test_dir)

    def tearDown(self):
        """Clean up test environment"""
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_init_database(self):
        """Test database initialization"""
        self.platform.init_database()
        db_path = Path(self.test_dir) / "community.db"
        self.assertTrue(db_path.exists())

    def test_create_user(self):
        """Test user creation"""
        self.platform.init_database()
        
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        
        user_id = self.platform.create_user(user_data)
        self.assertIsNotNone(user_id)
        
        # Test duplicate username
        with self.assertRaises(ValueError):
            self.platform.create_user(user_data)

    def test_create_theme(self):
        """Test theme creation"""
        self.platform.init_database()
        
        # Create a user first
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        user_id = self.platform.create_user(user_data)
        
        # Create theme
        theme_data = {
            "name": "Test Theme",
            "description": "A test theme",
            "author": "testuser",
            "category": "minimal",
            "tags": ["test", "minimal"],
            "version": "1.0.0"
        }
        
        theme_id = self.platform.create_theme(theme_data)
        self.assertIsNotNone(theme_id)

    def test_get_themes(self):
        """Test theme retrieval"""
        self.platform.init_database()
        
        # Create user and theme
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        user_id = self.platform.create_user(user_data)
        
        theme_data = {
            "name": "Test Theme",
            "description": "A test theme",
            "author": "testuser",
            "category": "minimal",
            "tags": ["test"],
            "version": "1.0.0"
        }
        theme_id = self.platform.create_theme(theme_data)
        
        # Get themes
        themes = self.platform.get_themes()
        self.assertEqual(len(themes), 1)
        self.assertEqual(themes[0]["name"], "Test Theme")

    def test_search_themes(self):
        """Test theme search functionality"""
        self.platform.init_database()
        
        # Create user
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        user_id = self.platform.create_user(user_data)
        
        # Create multiple themes
        themes_data = [
            {
                "name": "Minimal Dark",
                "description": "A minimal dark theme",
                "author": "testuser",
                "category": "minimal",
                "tags": ["dark", "minimal"],
                "version": "1.0.0"
            },
            {
                "name": "Colorful Theme",
                "description": "A colorful theme",
                "author": "testuser",
                "category": "colorful",
                "tags": ["bright", "colorful"],
                "version": "1.0.0"
            }
        ]
        
        for theme_data in themes_data:
            self.platform.create_theme(theme_data)
        
        # Search by query
        results = self.platform.search_themes("minimal")
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["name"], "Minimal Dark")
        
        # Search by category
        results = self.platform.search_themes(category="colorful")
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["name"], "Colorful Theme")

    def test_rate_theme(self):
        """Test theme rating functionality"""
        self.platform.init_database()
        
        # Create user and theme
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        user_id = self.platform.create_user(user_data)
        
        theme_data = {
            "name": "Test Theme",
            "description": "A test theme",
            "author": "testuser",
            "category": "minimal",
            "tags": ["test"],
            "version": "1.0.0"
        }
        theme_id = self.platform.create_theme(theme_data)
        
        # Rate theme
        success = self.platform.rate_theme(theme_id, user_id, 5)
        self.assertTrue(success)
        
        # Test invalid rating
        success = self.platform.rate_theme(theme_id, user_id, 6)  # Invalid rating
        self.assertFalse(success)

    def test_get_user_profile(self):
        """Test user profile retrieval"""
        self.platform.init_database()
        
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        user_id = self.platform.create_user(user_data)
        
        profile = self.platform.get_user_profile("testuser")
        self.assertIsNotNone(profile)
        self.assertEqual(profile["username"], "testuser")
        self.assertEqual(profile["display_name"], "Test User")

    def test_get_statistics(self):
        """Test statistics retrieval"""
        self.platform.init_database()
        
        # Create some test data
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        user_id = self.platform.create_user(user_data)
        
        theme_data = {
            "name": "Test Theme",
            "description": "A test theme",
            "author": "testuser",
            "category": "minimal",
            "tags": ["test"],
            "version": "1.0.0"
        }
        theme_id = self.platform.create_theme(theme_data)
        
        stats = self.platform.get_statistics()
        self.assertIn("total_themes", stats)
        self.assertIn("total_users", stats)
        self.assertEqual(stats["total_themes"], 1)
        self.assertEqual(stats["total_users"], 1)


class TestThemeClass(unittest.TestCase):
    """Test cases for Theme class"""

    def test_theme_creation(self):
        """Test Theme object creation"""
        theme_data = {
            "id": "test-theme",
            "name": "Test Theme",
            "description": "A test theme",
            "author": "testuser",
            "category": "minimal",
            "tags": ["test", "minimal"],
            "version": "1.0.0",
            "created_at": "2023-01-01T00:00:00Z",
            "downloads": 0,
            "rating": 0.0
        }
        
        theme = Theme(**theme_data)
        self.assertEqual(theme.name, "Test Theme")
        self.assertEqual(theme.author, "testuser")
        self.assertEqual(theme.category, "minimal")
        self.assertIn("test", theme.tags)

    def test_theme_validation(self):
        """Test Theme validation"""
        # Test with invalid data
        with self.assertRaises(TypeError):
            Theme()  # Missing required fields


class TestUserClass(unittest.TestCase):
    """Test cases for User class"""

    def test_user_creation(self):
        """Test User object creation"""
        user_data = {
            "id": "test-user",
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User",
            "created_at": "2023-01-01T00:00:00Z",
            "theme_count": 0,
            "reputation": 0
        }
        
        user = User(**user_data)
        self.assertEqual(user.username, "testuser")
        self.assertEqual(user.email, "test@example.com")
        self.assertEqual(user.display_name, "Test User")

    def test_user_validation(self):
        """Test User validation"""
        # Test with invalid email
        with self.assertRaises(ValueError):
            User(
                id="test",
                username="test",
                email="invalid-email",
                display_name="Test",
                created_at="2023-01-01T00:00:00Z",
                theme_count=0,
                reputation=0
            )


if __name__ == "__main__":
    unittest.main()

