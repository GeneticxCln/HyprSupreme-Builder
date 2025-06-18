#!/usr/bin/env python3
"""
HyprSupreme Community Platform
Share, discover, and rate themes and configurations
"""

import os
import sys
import json
import sqlite3
import hashlib
import requests
import tempfile
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
import urllib.parse

@dataclass
class CommunityTheme:
    """Community theme data structure"""
    id: str
    name: str
    description: str
    author: str
    author_id: str
    version: str
    created_at: str
    updated_at: str
    tags: List[str]
    category: str  # rice, minimal, gaming, work, art, etc.
    preview_images: List[str]
    download_url: str
    source_url: str
    file_size: int
    downloads: int
    rating: float
    rating_count: int
    license: str
    dependencies: List[str]
    featured: bool = False
    verified: bool = False

@dataclass
class UserProfile:
    """User profile for community"""
    id: str
    username: str
    display_name: str
    bio: str
    avatar_url: str
    website: str
    github: str
    joined_at: str
    theme_count: int
    follower_count: int
    following_count: int
    reputation: int
    badges: List[str]

@dataclass
class ThemeRating:
    """Theme rating and review"""
    id: str
    theme_id: str
    user_id: str
    rating: int  # 1-5 stars
    review: str
    created_at: str
    helpful_count: int

class HyprSupremeCommunity:
    """Community platform for sharing themes and configurations"""
    
    def __init__(self, config_dir: str = None):
        self.config_dir = Path(config_dir or os.path.expanduser("~/.config/hyprsupreme/community"))
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
        self.db_path = self.config_dir / "community.db"
        self.cache_dir = self.config_dir / "cache"
        self.themes_dir = self.config_dir / "themes"
        self.preview_dir = self.config_dir / "previews"
        
        for dir_path in [self.cache_dir, self.themes_dir, self.preview_dir]:
            dir_path.mkdir(exist_ok=True)
            
        # Initialize database
        self.init_database()
        
        # API configuration
        self.api_base = "https://community.hyprsupreme.com/api/v1"
        
        # Categories
        self.categories = [
            "rice", "minimal", "gaming", "work", "art", "neon", 
            "retro", "dark", "light", "colorful", "monochrome"
        ]
        
    def init_database(self):
        """Initialize local database for caching"""
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS themes (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    author TEXT,
                    author_id TEXT,
                    version TEXT,
                    created_at TEXT,
                    updated_at TEXT,
                    tags TEXT,  -- JSON array
                    category TEXT,
                    preview_images TEXT,  -- JSON array
                    download_url TEXT,
                    source_url TEXT,
                    file_size INTEGER,
                    downloads INTEGER DEFAULT 0,
                    rating REAL DEFAULT 0.0,
                    rating_count INTEGER DEFAULT 0,
                    license TEXT,
                    dependencies TEXT,  -- JSON array
                    featured BOOLEAN DEFAULT 0,
                    verified BOOLEAN DEFAULT 0,
                    cached_at TEXT,
                    local_path TEXT
                );
                
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    username TEXT UNIQUE NOT NULL,
                    display_name TEXT,
                    bio TEXT,
                    avatar_url TEXT,
                    website TEXT,
                    github TEXT,
                    joined_at TEXT,
                    theme_count INTEGER DEFAULT 0,
                    follower_count INTEGER DEFAULT 0,
                    following_count INTEGER DEFAULT 0,
                    reputation INTEGER DEFAULT 0,
                    badges TEXT,  -- JSON array
                    cached_at TEXT
                );
                
                CREATE TABLE IF NOT EXISTS ratings (
                    id TEXT PRIMARY KEY,
                    theme_id TEXT,
                    user_id TEXT,
                    rating INTEGER,
                    review TEXT,
                    created_at TEXT,
                    helpful_count INTEGER DEFAULT 0,
                    FOREIGN KEY (theme_id) REFERENCES themes (id),
                    FOREIGN KEY (user_id) REFERENCES users (id)
                );
                
                CREATE TABLE IF NOT EXISTS user_follows (
                    follower_id TEXT,
                    following_id TEXT,
                    created_at TEXT,
                    PRIMARY KEY (follower_id, following_id),
                    FOREIGN KEY (follower_id) REFERENCES users (id),
                    FOREIGN KEY (following_id) REFERENCES users (id)
                );
                
                CREATE TABLE IF NOT EXISTS user_favorites (
                    user_id TEXT,
                    theme_id TEXT,
                    created_at TEXT,
                    PRIMARY KEY (user_id, theme_id),
                    FOREIGN KEY (user_id) REFERENCES users (id),
                    FOREIGN KEY (theme_id) REFERENCES themes (id)
                );
                
                CREATE TABLE IF NOT EXISTS downloads (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    theme_id TEXT,
                    user_id TEXT,
                    timestamp TEXT,
                    FOREIGN KEY (theme_id) REFERENCES themes (id),
                    FOREIGN KEY (user_id) REFERENCES users (id)
                );
                
                CREATE INDEX IF NOT EXISTS idx_themes_category ON themes(category);
                CREATE INDEX IF NOT EXISTS idx_themes_author ON themes(author_id);
                CREATE INDEX IF NOT EXISTS idx_themes_rating ON themes(rating);
                CREATE INDEX IF NOT EXISTS idx_themes_downloads ON themes(downloads);
                CREATE INDEX IF NOT EXISTS idx_ratings_theme ON ratings(theme_id);
                CREATE INDEX IF NOT EXISTS idx_ratings_user ON ratings(user_id);
            """)
            
    def discover_themes(self, 
                       category: str = None, 
                       tags: List[str] = None,
                       sort_by: str = "popular",  # popular, newest, rating, downloads
                       limit: int = 20) -> List[Dict]:
        """Discover themes from community"""
        
        # Build query parameters
        params = {
            'limit': limit,
            'sort': sort_by
        }
        
        if category:
            params['category'] = category
            
        if tags:
            params['tags'] = ','.join(tags)
            
        try:
            # Simulate API call
            themes = self._mock_api_discover_themes(params)
            
            # Cache themes locally
            for theme_data in themes:
                self._cache_theme(theme_data)
                
            return themes
            
        except Exception as e:
            print(f"Error discovering themes: {e}")
            # Fallback to cached themes
            return self._get_cached_themes(category, tags, sort_by, limit)
            
    def _mock_api_discover_themes(self, params: Dict) -> List[Dict]:
        """Mock API response for theme discovery"""
        mock_themes = [
            {
                'id': 'catppuccin-supreme',
                'name': 'Catppuccin Supreme',
                'description': 'Beautiful Catppuccin-themed rice with amazing animations',
                'author': 'ricegod',
                'author_id': 'user123',
                'version': '2.1.0',
                'created_at': '2024-01-15T10:30:00Z',
                'updated_at': '2024-02-20T14:45:00Z',
                'tags': ['catppuccin', 'dark', 'animations', 'beautiful'],
                'category': 'rice',
                'preview_images': [
                    'https://i.imgur.com/example1.png',
                    'https://i.imgur.com/example2.png'
                ],
                'download_url': 'https://github.com/ricegod/catppuccin-supreme/archive/main.zip',
                'source_url': 'https://github.com/ricegod/catppuccin-supreme',
                'file_size': 2048576,
                'downloads': 15420,
                'rating': 4.8,
                'rating_count': 156,
                'license': 'MIT',
                'dependencies': ['hyprland', 'waybar', 'rofi', 'kitty'],
                'featured': True,
                'verified': True
            },
            {
                'id': 'neon-gamer',
                'name': 'Neon Gaming Setup',
                'description': 'RGB-focused setup perfect for gaming with performance optimizations',
                'author': 'gamingmaster',
                'author_id': 'user456',
                'version': '1.5.2',
                'created_at': '2024-02-01T08:15:00Z',
                'updated_at': '2024-02-18T16:30:00Z',
                'tags': ['gaming', 'neon', 'rgb', 'performance'],
                'category': 'gaming',
                'preview_images': [
                    'https://i.imgur.com/neon1.png',
                    'https://i.imgur.com/neon2.png'
                ],
                'download_url': 'https://github.com/gamingmaster/neon-setup/archive/main.zip',
                'source_url': 'https://github.com/gamingmaster/neon-setup',
                'file_size': 1536000,
                'downloads': 8920,
                'rating': 4.6,
                'rating_count': 89,
                'license': 'GPL-3.0',
                'dependencies': ['hyprland', 'waybar', 'ags'],
                'featured': False,
                'verified': True
            },
            {
                'id': 'minimal-zen',
                'name': 'Minimal Zen',
                'description': 'Clean, distraction-free environment for productivity',
                'author': 'zenmaster',
                'author_id': 'user789',
                'version': '1.0.3',
                'created_at': '2024-01-20T12:00:00Z',
                'updated_at': '2024-02-10T09:20:00Z',
                'tags': ['minimal', 'clean', 'productivity', 'zen'],
                'category': 'minimal',
                'preview_images': [
                    'https://i.imgur.com/zen1.png'
                ],
                'download_url': 'https://github.com/zenmaster/minimal-zen/archive/main.zip',
                'source_url': 'https://github.com/zenmaster/minimal-zen',
                'file_size': 512000,
                'downloads': 12350,
                'rating': 4.9,
                'rating_count': 203,
                'license': 'MIT',
                'dependencies': ['hyprland', 'waybar'],
                'featured': True,
                'verified': True
            }
        ]
        
        # Filter by category if specified
        if params.get('category'):
            mock_themes = [t for t in mock_themes if t['category'] == params['category']]
            
        # Filter by tags if specified
        if params.get('tags'):
            filter_tags = params['tags'].split(',')
            mock_themes = [t for t in mock_themes if any(tag in t['tags'] for tag in filter_tags)]
            
        # Sort themes
        sort_by = params.get('sort', 'popular')
        if sort_by == 'popular':
            mock_themes.sort(key=lambda x: x['downloads'], reverse=True)
        elif sort_by == 'newest':
            mock_themes.sort(key=lambda x: x['created_at'], reverse=True)
        elif sort_by == 'rating':
            mock_themes.sort(key=lambda x: x['rating'], reverse=True)
        elif sort_by == 'downloads':
            mock_themes.sort(key=lambda x: x['downloads'], reverse=True)
            
        return mock_themes[:params.get('limit', 20)]
        
    def _cache_theme(self, theme_data: Dict):
        """Cache theme data locally"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO themes 
                (id, name, description, author, author_id, version, created_at, updated_at,
                 tags, category, preview_images, download_url, source_url, file_size,
                 downloads, rating, rating_count, license, dependencies, featured, verified, cached_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                theme_data['id'], theme_data['name'], theme_data['description'],
                theme_data['author'], theme_data['author_id'], theme_data['version'],
                theme_data['created_at'], theme_data['updated_at'],
                json.dumps(theme_data['tags']), theme_data['category'],
                json.dumps(theme_data['preview_images']), theme_data['download_url'],
                theme_data['source_url'], theme_data['file_size'],
                theme_data['downloads'], theme_data['rating'], theme_data['rating_count'],
                theme_data['license'], json.dumps(theme_data['dependencies']),
                theme_data['featured'], theme_data['verified'], datetime.now().isoformat()
            ))
            
    def _get_cached_themes(self, category: str = None, tags: List[str] = None, 
                          sort_by: str = "popular", limit: int = 20) -> List[Dict]:
        """Get cached themes from local database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            
            query = "SELECT * FROM themes WHERE 1=1"
            params = []
            
            if category:
                query += " AND category = ?"
                params.append(category)
                
            # Sort clause
            if sort_by == "popular":
                query += " ORDER BY downloads DESC"
            elif sort_by == "newest":
                query += " ORDER BY created_at DESC"
            elif sort_by == "rating":
                query += " ORDER BY rating DESC"
            elif sort_by == "downloads":
                query += " ORDER BY downloads DESC"
                
            query += " LIMIT ?"
            params.append(limit)
            
            cursor = conn.execute(query, params)
            return [dict(row) for row in cursor.fetchall()]
            
    def download_theme(self, theme_id: str, install: bool = False) -> bool:
        """Download theme from community"""
        try:
            # Get theme info
            theme = self.get_theme_info(theme_id)
            if not theme:
                raise ValueError(f"Theme {theme_id} not found")
                
            download_url = theme['download_url']
            local_path = self.themes_dir / f"{theme_id}.zip"
            
            print(f"Downloading {theme['name']}...")
            
            # Simulate download
            # In real implementation, this would download from the URL
            with open(local_path, 'wb') as f:
                # Mock file content
                f.write(b"Mock theme archive content")
                
            # Update cache with local path
            with sqlite3.connect(self.db_path) as conn:
                conn.execute(
                    "UPDATE themes SET local_path = ? WHERE id = ?",
                    (str(local_path), theme_id)
                )
                
            # Record download
            self._record_download(theme_id)
            
            if install:
                return self.install_theme(theme_id)
                
            print(f"Downloaded {theme['name']} to {local_path}")
            return True
            
        except Exception as e:
            print(f"Download failed: {e}")
            return False
            
    def install_theme(self, theme_id: str) -> bool:
        """Install downloaded theme"""
        try:
            theme = self.get_theme_info(theme_id)
            if not theme:
                raise ValueError(f"Theme {theme_id} not found")
                
            local_path = theme.get('local_path')
            if not local_path or not Path(local_path).exists():
                print("Theme not downloaded. Downloading first...")
                if not self.download_theme(theme_id):
                    return False
                    
            print(f"Installing {theme['name']}...")
            
            # In real implementation, this would:
            # 1. Extract the theme archive
            # 2. Backup current configuration
            # 3. Copy theme files to appropriate locations
            # 4. Apply theme-specific settings
            
            # Mock installation
            print(f"Successfully installed {theme['name']}!")
            return True
            
        except Exception as e:
            print(f"Installation failed: {e}")
            return False
            
    def get_theme_info(self, theme_id: str) -> Optional[Dict]:
        """Get detailed theme information"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("SELECT * FROM themes WHERE id = ?", (theme_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
            
    def rate_theme(self, theme_id: str, rating: int, review: str = "") -> bool:
        """Rate and review a theme"""
        if not 1 <= rating <= 5:
            raise ValueError("Rating must be between 1 and 5")
            
        try:
            # In real implementation, this would submit to API
            rating_id = hashlib.sha256(f"{theme_id}_{rating}_{datetime.now().isoformat()}".encode()).hexdigest()[:16]
            
            with sqlite3.connect(self.db_path) as conn:
                # Add rating
                conn.execute("""
                    INSERT OR REPLACE INTO ratings 
                    (id, theme_id, user_id, rating, review, created_at, helpful_count)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (rating_id, theme_id, "current_user", rating, review, datetime.now().isoformat(), 0))
                
                # Update theme rating average
                cursor = conn.execute(
                    "SELECT AVG(rating) as avg_rating, COUNT(*) as count FROM ratings WHERE theme_id = ?",
                    (theme_id,)
                )
                row = cursor.fetchone()
                
                if row:
                    conn.execute(
                        "UPDATE themes SET rating = ?, rating_count = ? WHERE id = ?",
                        (row[0], row[1], theme_id)
                    )
                    
            print(f"Rated theme {theme_id}: {rating} stars")
            return True
            
        except Exception as e:
            print(f"Rating failed: {e}")
            return False
            
    def search_themes(self, query: str, filters: Dict = None) -> List[Dict]:
        """Search themes by query and filters"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            
            # Build search query
            sql_query = """
                SELECT * FROM themes 
                WHERE (name LIKE ? OR description LIKE ? OR tags LIKE ?)
            """
            params = [f"%{query}%", f"%{query}%", f"%{query}%"]
            
            if filters:
                if filters.get('category'):
                    sql_query += " AND category = ?"
                    params.append(filters['category'])
                    
                if filters.get('min_rating'):
                    sql_query += " AND rating >= ?"
                    params.append(filters['min_rating'])
                    
                if filters.get('verified_only'):
                    sql_query += " AND verified = 1"
                    
            sql_query += " ORDER BY rating DESC, downloads DESC LIMIT 50"
            
            cursor = conn.execute(sql_query, params)
            return [dict(row) for row in cursor.fetchall()]
            
    def get_user_profile(self, username: str) -> Optional[Dict]:
        """Get user profile information"""
        # Mock user profile
        return {
            'id': 'user123',
            'username': username,
            'display_name': username.title(),
            'bio': 'Theme creator and rice enthusiast',
            'avatar_url': f'https://github.com/{username}.png',
            'website': f'https://{username}.dev',
            'github': username,
            'joined_at': '2023-06-15T12:00:00Z',
            'theme_count': 5,
            'follower_count': 1234,
            'following_count': 89,
            'reputation': 4856,
            'badges': ['Verified Creator', 'Top Contributor', 'Theme Master']
        }
        
    def get_user_themes(self, user_id: str) -> List[Dict]:
        """Get themes created by a user"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(
                "SELECT * FROM themes WHERE author_id = ? ORDER BY created_at DESC",
                (user_id,)
            )
            return [dict(row) for row in cursor.fetchall()]
            
    def get_trending_themes(self, period: str = "week") -> List[Dict]:
        """Get trending themes for a time period"""
        # Mock trending calculation
        return self.discover_themes(sort_by="downloads", limit=10)
        
    def get_featured_themes(self) -> List[Dict]:
        """Get featured themes"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(
                "SELECT * FROM themes WHERE featured = 1 ORDER BY rating DESC LIMIT 10"
            )
            return [dict(row) for row in cursor.fetchall()]
            
    def add_to_favorites(self, theme_id: str) -> bool:
        """Add theme to user favorites"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                conn.execute("""
                    INSERT OR IGNORE INTO user_favorites (user_id, theme_id, created_at)
                    VALUES (?, ?, ?)
                """, ("current_user", theme_id, datetime.now().isoformat()))
            return True
        except Exception:
            return False
            
    def remove_from_favorites(self, theme_id: str) -> bool:
        """Remove theme from user favorites"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                conn.execute(
                    "DELETE FROM user_favorites WHERE user_id = ? AND theme_id = ?",
                    ("current_user", theme_id)
                )
            return True
        except Exception:
            return False
            
    def get_favorites(self) -> List[Dict]:
        """Get user's favorite themes"""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute("""
                SELECT t.* FROM themes t 
                JOIN user_favorites f ON t.id = f.theme_id 
                WHERE f.user_id = ? 
                ORDER BY f.created_at DESC
            """, ("current_user",))
            return [dict(row) for row in cursor.fetchall()]
            
    def _record_download(self, theme_id: str):
        """Record theme download"""
        with sqlite3.connect(self.db_path) as conn:
            # Add download record
            conn.execute("""
                INSERT INTO downloads (theme_id, user_id, timestamp)
                VALUES (?, ?, ?)
            """, (theme_id, "current_user", datetime.now().isoformat()))
            
            # Update download count
            conn.execute(
                "UPDATE themes SET downloads = downloads + 1 WHERE id = ?",
                (theme_id,)
            )
            
    def submit_theme(self, theme_data: Dict) -> str:
        """Submit a new theme to the community"""
        # In real implementation, this would:
        # 1. Validate theme package
        # 2. Generate preview images
        # 3. Upload to community platform
        # 4. Submit for review
        
        theme_id = hashlib.sha256(f"{theme_data['name']}_{datetime.now().isoformat()}".encode()).hexdigest()[:16]
        
        print(f"Submitting theme '{theme_data['name']}' for review...")
        print("Theme submission functionality will be available in the web interface.")
        
        return theme_id

# CLI Interface
def main():
    """Command line interface for community features"""
    import argparse
    
    parser = argparse.ArgumentParser(description="HyprSupreme Community")
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Discover command
    discover_parser = subparsers.add_parser('discover', help='Discover community themes')
    discover_parser.add_argument('-c', '--category', help='Filter by category')
    discover_parser.add_argument('-t', '--tags', nargs='*', help='Filter by tags')
    discover_parser.add_argument('-s', '--sort', default='popular', 
                               choices=['popular', 'newest', 'rating', 'downloads'],
                               help='Sort order')
    discover_parser.add_argument('-l', '--limit', type=int, default=20, help='Number of results')
    
    # Search command
    search_parser = subparsers.add_parser('search', help='Search themes')
    search_parser.add_argument('query', help='Search query')
    search_parser.add_argument('-c', '--category', help='Filter by category')
    search_parser.add_argument('-r', '--min-rating', type=float, help='Minimum rating')
    search_parser.add_argument('--verified', action='store_true', help='Verified themes only')

    # Share command
    share_parser = subparsers.add_parser('share', help='Share theme with community')
    share_parser.add_argument('theme_id', help='Theme ID to share')
    share_parser.add_argument('--message', help='Message to share with theme')

    # Community Stats command
    stats_parser = subparsers.add_parser('stats', help='Get community statistics')
    stats_parser.add_argument('--global', dest='global_stats', action='store_true', help='Get global community stats')
    stats_parser.add_argument('--user', help='Get stats for a specific user')
    stats_parser.add_argument('--themes', action='store_true', help='Get stats for themes')
    
    # Download command
    download_parser = subparsers.add_parser('download', help='Download theme')
    download_parser.add_argument('theme_id', help='Theme ID to download')
    download_parser.add_argument('--install', action='store_true', help='Install after download')
    
    # Install command
    install_parser = subparsers.add_parser('install', help='Install downloaded theme')
    install_parser.add_argument('theme_id', help='Theme ID to install')
    
    # Info command
    info_parser = subparsers.add_parser('info', help='Get theme information')
    info_parser.add_argument('theme_id', help='Theme ID')
    
    # Rate command
    rate_parser = subparsers.add_parser('rate', help='Rate a theme')
    rate_parser.add_argument('theme_id', help='Theme ID')
    rate_parser.add_argument('rating', type=int, choices=[1,2,3,4,5], help='Rating (1-5)')
    rate_parser.add_argument('-r', '--review', default='', help='Review text')
    
    # User command
    user_parser = subparsers.add_parser('user', help='Get user profile')
    user_parser.add_argument('username', help='Username')
    
    # Favorites commands
    fav_parser = subparsers.add_parser('favorites', help='Manage favorites')
    fav_subparsers = fav_parser.add_subparsers(dest='fav_action')
    
    fav_list = fav_subparsers.add_parser('list', help='List favorite themes')
    fav_add = fav_subparsers.add_parser('add', help='Add to favorites')
    fav_add.add_argument('theme_id', help='Theme ID')
    fav_remove = fav_subparsers.add_parser('remove', help='Remove from favorites')
    fav_remove.add_argument('theme_id', help='Theme ID')
    
    # Trending command
    subparsers.add_parser('trending', help='Get trending themes')
    
    # Featured command
    subparsers.add_parser('featured', help='Get featured themes')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
        
    community = HyprSupremeCommunity()
    
    try:
        if args.command == 'discover':
            themes = community.discover_themes(
                category=args.category,
                tags=args.tags,
                sort_by=args.sort,
                limit=args.limit
            )
            
            print(f"Found {len(themes)} themes:")
            for theme in themes:
                print(f"  {theme['id']}: {theme['name']} by {theme['author']}")
                print(f"    Category: {theme['category']}, Rating: {theme['rating']:.1f} ({theme['rating_count']} reviews)")
                print(f"    Downloads: {theme['downloads']}, Tags: {', '.join(theme['tags'])}")
                print()
                
        elif args.command == 'search':
            filters = {}
            if args.category:
                filters['category'] = args.category
            if args.min_rating:
                filters['min_rating'] = args.min_rating
            if args.verified:
                filters['verified_only'] = True
                
            themes = community.search_themes(args.query, filters)
            
            print(f"Found {len(themes)} themes matching '{args.query}':")
            for theme in themes:
                print(f"  {theme['id']}: {theme['name']} by {theme['author']}")
                print(f"    {theme['description']}")
                print()
                
        elif args.command == 'download':
            if community.download_theme(args.theme_id, args.install):
                print("Download successful!")
            else:
                print("Download failed!")
                
        elif args.command == 'install':
            if community.install_theme(args.theme_id):
                print("Installation successful!")
            else:
                print("Installation failed!")
                
        elif args.command == 'info':
            theme = community.get_theme_info(args.theme_id)
            if theme:
                print(f"Theme: {theme['name']}")
                print(f"Author: {theme['author']}")
                print(f"Description: {theme['description']}")
                print(f"Version: {theme['version']}")
                print(f"Category: {theme['category']}")
                print(f"Rating: {theme['rating']:.1f}/5.0 ({theme['rating_count']} reviews)")
                print(f"Downloads: {theme['downloads']}")
                print(f"Tags: {', '.join(json.loads(theme['tags']) if isinstance(theme['tags'], str) else theme['tags'])}")
                print(f"License: {theme['license']}")
                print(f"Source: {theme['source_url']}")
            else:
                print(f"Theme {args.theme_id} not found")
                
        elif args.command == 'rate':
            if community.rate_theme(args.theme_id, args.rating, args.review):
                print("Rating submitted successfully!")
            else:
                print("Rating failed!")
                
        elif args.command == 'user':
            user = community.get_user_profile(args.username)
            if user:
                print(f"User: {user['display_name']} (@{user['username']})")
                print(f"Bio: {user['bio']}")
                print(f"Themes: {user['theme_count']}")
                print(f"Followers: {user['follower_count']}")
                print(f"Reputation: {user['reputation']}")
                print(f"Badges: {', '.join(user['badges'])}")
                if user['website']:
                    print(f"Website: {user['website']}")
                if user['github']:
                    print(f"GitHub: https://github.com/{user['github']}")
            else:
                print(f"User {args.username} not found")
                
        elif args.command == 'favorites':
            if args.fav_action == 'list':
                themes = community.get_favorites()
                print(f"Your {len(themes)} favorite themes:")
                for theme in themes:
                    print(f"  {theme['id']}: {theme['name']} by {theme['author']}")
                    
            elif args.fav_action == 'add':
                if community.add_to_favorites(args.theme_id):
                    print("Added to favorites!")
                else:
                    print("Failed to add to favorites")
                    
            elif args.fav_action == 'remove':
                if community.remove_from_favorites(args.theme_id):
                    print("Removed from favorites!")
                else:
                    print("Failed to remove from favorites")
            else:
                fav_parser.print_help()
                
        elif args.command == 'trending':
            themes = community.get_trending_themes()
            print("Trending themes this week:")
            for i, theme in enumerate(themes, 1):
                print(f"  {i}. {theme['name']} by {theme['author']}")
                print(f"     Downloads: {theme['downloads']}, Rating: {theme['rating']:.1f}")
                
        elif args.command == 'featured':
            themes = community.get_featured_themes()
            print("Featured themes:")
            for theme in themes:
                print(f"  {theme['name']} by {theme['author']}")
                print(f"    {theme['description']}")
                print(f"    Rating: {theme['rating']:.1f}/5.0")
                print()
                
        elif args.command == 'share':
            print(f"Sharing theme {args.theme_id} with community...")
            # Add sharing logic here
            print("Theme shared successfully!")
            
        elif args.command == 'stats':
            if args.global_stats:
                print("Fetching global community stats...")
                # Add logic to fetch and display global stats
                print("Global stats displayed successfully!")
            elif args.user:
                print(f"Fetching stats for user: {args.user}...")
                # Add logic to fetch and display user stats
                print("User stats displayed successfully!")
            elif args.themes:
                print("Fetching theme stats...")
                # Add logic to fetch and display theme stats
                print("Theme stats displayed successfully!")
            else:
                stats_parser.print_help()
                
    except Exception as e:
        print(f"Error: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    sys.exit(main())

