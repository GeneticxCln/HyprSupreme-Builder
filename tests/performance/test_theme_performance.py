#!/usr/bin/env python3
"""
Performance tests for HyprSupreme-Builder theme operations
"""

import pytest
import time
import tempfile
import shutil
import sys
import os
from pathlib import Path

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

try:
    from community.community_platform import CommunityPlatform
except ImportError:
    pytest.skip("Community platform not available", allow_module_level=True)


class TestThemePerformance:
    """Performance tests for theme operations"""

    def setup_method(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()
        self.platform = CommunityPlatform(data_dir=self.test_dir)
        self.platform.init_database()

    def teardown_method(self):
        """Clean up test environment"""
        shutil.rmtree(self.test_dir, ignore_errors=True)

    @pytest.mark.slow
    def test_bulk_theme_creation_performance(self):
        """Test performance of creating multiple themes"""
        num_themes = 100
        start_time = time.time()

        # Create test user
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        user_id = self.platform.create_user(user_data)

        # Create themes in bulk
        for i in range(num_themes):
            theme_data = {
                "name": f"Test Theme {i}",
                "description": f"Test theme number {i}",
                "author": "testuser",
                "category": "minimal",
                "tags": ["test", f"theme{i}"],
                "version": "1.0.0"
            }
            self.platform.create_theme(theme_data)

        end_time = time.time()
        duration = end_time - start_time

        # Performance assertions
        assert duration < 10.0, f"Creating {num_themes} themes took {duration:.2f}s (expected < 10s)"
        
        avg_time_per_theme = duration / num_themes
        assert avg_time_per_theme < 0.1, f"Average time per theme: {avg_time_per_theme:.3f}s (expected < 0.1s)"

    @pytest.mark.slow
    def test_theme_search_performance(self):
        """Test performance of theme search operations"""
        # Create test data
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        user_id = self.platform.create_user(user_data)

        # Create 50 themes with various names
        themes = [
            "Minimal Dark", "Minimal Light", "Colorful Bright", "Gaming RGB",
            "Professional Clean", "Retro Vintage", "Modern Sleek", "Artistic Creative"
        ]
        
        for i in range(50):
            theme_name = themes[i % len(themes)] + f" v{i//len(themes) + 1}"
            theme_data = {
                "name": theme_name,
                "description": f"Description for {theme_name}",
                "author": "testuser",
                "category": themes[i % len(themes)].split()[0].lower(),
                "tags": theme_name.lower().split(),
                "version": "1.0.0"
            }
            self.platform.create_theme(theme_data)

        # Test search performance
        search_queries = ["minimal", "dark", "colorful", "gaming", "professional"]
        
        for query in search_queries:
            start_time = time.time()
            results = self.platform.search_themes(query)
            end_time = time.time()
            
            search_time = end_time - start_time
            assert search_time < 0.5, f"Search for '{query}' took {search_time:.3f}s (expected < 0.5s)"
            assert len(results) > 0, f"Search for '{query}' returned no results"

    @pytest.mark.slow
    def test_database_query_performance(self):
        """Test database query performance under load"""
        # Create test data
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "display_name": "Test User"
        }
        user_id = self.platform.create_user(user_data)

        # Create themes
        for i in range(20):
            theme_data = {
                "name": f"Performance Test Theme {i}",
                "description": f"Theme for performance testing {i}",
                "author": "testuser",
                "category": "test",
                "tags": ["performance", "test"],
                "version": "1.0.0"
            }
            self.platform.create_theme(theme_data)

        # Test multiple concurrent queries
        start_time = time.time()
        
        for _ in range(10):
            # Simulate various database operations
            themes = self.platform.get_themes()
            stats = self.platform.get_statistics()
            user_profile = self.platform.get_user_profile("testuser")
            search_results = self.platform.search_themes("test")

        end_time = time.time()
        total_time = end_time - start_time
        
        # Should complete 40 operations (10 iterations × 4 operations) quickly
        assert total_time < 2.0, f"40 database operations took {total_time:.2f}s (expected < 2s)"

    def test_memory_usage_theme_operations(self):
        """Test memory usage during theme operations"""
        import psutil
        import os
        
        process = psutil.Process(os.getpid())
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB

        # Create user
        user_data = {
            "username": "memtest",
            "email": "memtest@example.com",
            "display_name": "Memory Test User"
        }
        user_id = self.platform.create_user(user_data)

        # Create many themes to test memory usage
        for i in range(100):
            theme_data = {
                "name": f"Memory Test Theme {i}",
                "description": f"This is a memory test theme with a longer description {i}" * 10,
                "author": "memtest",
                "category": "memory",
                "tags": ["memory", "test", f"theme{i}"],
                "version": "1.0.0"
            }
            self.platform.create_theme(theme_data)

        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory

        # Memory increase should be reasonable (less than 50MB for 100 themes)
        assert memory_increase < 50, f"Memory increased by {memory_increase:.1f}MB (expected < 50MB)"

    @pytest.mark.slow  
    def test_concurrent_operations_simulation(self):
        """Simulate concurrent theme operations"""
        import threading
        import queue
        
        results_queue = queue.Queue()
        
        def create_themes_worker(worker_id, num_themes):
            """Worker function to create themes"""
            try:
                # Create user for this worker
                user_data = {
                    "username": f"worker{worker_id}",
                    "email": f"worker{worker_id}@example.com",
                    "display_name": f"Worker {worker_id}"
                }
                user_id = self.platform.create_user(user_data)
                
                # Create themes
                for i in range(num_themes):
                    theme_data = {
                        "name": f"Worker {worker_id} Theme {i}",
                        "description": f"Theme {i} from worker {worker_id}",
                        "author": f"worker{worker_id}",
                        "category": "concurrent",
                        "tags": ["concurrent", f"worker{worker_id}"],
                        "version": "1.0.0"
                    }
                    self.platform.create_theme(theme_data)
                    
                results_queue.put(("success", worker_id, num_themes))
            except Exception as e:
                results_queue.put(("error", worker_id, str(e)))

        # Start multiple worker threads
        num_workers = 3
        themes_per_worker = 10
        threads = []
        
        start_time = time.time()
        
        for worker_id in range(num_workers):
            thread = threading.Thread(
                target=create_themes_worker,
                args=(worker_id, themes_per_worker)
            )
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        end_time = time.time()
        duration = end_time - start_time

        # Collect results
        successful_workers = 0
        total_themes_created = 0
        
        while not results_queue.empty():
            status, worker_id, data = results_queue.get()
            if status == "success":
                successful_workers += 1
                total_themes_created += data
            else:
                pytest.fail(f"Worker {worker_id} failed: {data}")

        # Verify results
        assert successful_workers == num_workers, f"Only {successful_workers}/{num_workers} workers succeeded"
        assert total_themes_created == num_workers * themes_per_worker
        
        # Performance check - should complete in reasonable time
        expected_max_time = 5.0  # 5 seconds should be enough for 3 workers creating 10 themes each
        assert duration < expected_max_time, f"Concurrent operations took {duration:.2f}s (expected < {expected_max_time}s)"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

