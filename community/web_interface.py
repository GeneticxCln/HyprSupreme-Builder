#!/usr/bin/env python3
"""
HyprSupreme Community Web Interface
A Flask-based web application for the community platform
"""

import os
import sys
import json
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional

from flask import Flask, render_template, request, jsonify, session, redirect, url_for, flash
from werkzeug.security import generate_password_hash, check_password_hash
import secrets

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))
# Import the mock community class for testing
from community_platform import MockHyprSupremeCommunity

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

# Initialize community platform with mock data
community = MockHyprSupremeCommunity()

class CommunityWebApp:
    """Web interface for the community platform"""
    
    def __init__(self):
        self.setup_routes()
        
    def setup_routes(self):
        """Setup Flask routes"""
        
        @app.route('/')
        def index():
            """Homepage with featured and trending themes"""
            featured_themes = community.get_featured_themes()
            trending_themes = community.get_trending_themes()
            
            stats = {
                'total_themes': len(community._get_cached_themes(limit=1000)),
                'total_downloads': sum(theme.get('downloads', 0) for theme in community._get_cached_themes(limit=1000)),
                'active_users': 1250,  # Mock data
                'categories': len(community.categories)
            }
            
            return render_template('index.html', 
                                 featured_themes=featured_themes,
                                 trending_themes=trending_themes,
                                 stats=stats)
        
        @app.route('/discover')
        def discover():
            """Theme discovery page"""
            category = request.args.get('category')
            sort_by = request.args.get('sort', 'popular')
            tags = request.args.getlist('tags')
            limit = int(request.args.get('limit', 20))
            
            themes = community.discover_themes(
                category=category,
                tags=tags if tags else None,
                sort_by=sort_by,
                limit=limit
            )
            
            return render_template('discover.html',
                                 themes=themes,
                                 categories=community.categories,
                                 current_category=category,
                                 current_sort=sort_by)
        
        @app.route('/theme/<theme_id>')
        def theme_detail(theme_id):
            """Individual theme page"""
            theme = community.get_theme_info(theme_id)
            if not theme:
                flash('Theme not found', 'error')
                return redirect(url_for('discover'))
                
            # Get reviews/ratings
            reviews = self.get_theme_reviews(theme_id)
            
            # Check if user has favorited
            is_favorited = self.is_theme_favorited(theme_id)
            
            return render_template('theme_detail.html',
                                 theme=theme,
                                 reviews=reviews,
                                 is_favorited=is_favorited)
        
        @app.route('/search')
        def search():
            """Search themes"""
            query = request.args.get('q', '')
            category = request.args.get('category')
            min_rating = request.args.get('min_rating', type=float)
            verified_only = request.args.get('verified', type=bool)
            
            if not query:
                return render_template('search.html', themes=[], query='')
                
            filters = {}
            if category:
                filters['category'] = category
            if min_rating:
                filters['min_rating'] = min_rating
            if verified_only:
                filters['verified_only'] = verified_only
                
            themes = community.search_themes(query, filters)
            
            return render_template('search.html',
                                 themes=themes,
                                 query=query,
                                 categories=community.categories)
        
        @app.route('/user/<username>')
        def user_profile(username):
            """User profile page"""
            user = community.get_user_profile(username)
            if not user:
                flash('User not found', 'error')
                return redirect(url_for('index'))
                
            user_themes = community.get_user_themes(user['id'])
            
            return render_template('user_profile.html',
                                 user=user,
                                 themes=user_themes)
        
        @app.route('/favorites')
        def favorites():
            """User favorites page"""
            if 'user_id' not in session:
                flash('Please log in to view favorites', 'warning')
                return redirect(url_for('login'))
                
            favorite_themes = community.get_favorites()
            
            return render_template('favorites.html',
                                 themes=favorite_themes)
        
        @app.route('/submit')
        def submit_theme():
            """Theme submission page"""
            if 'user_id' not in session:
                flash('Please log in to submit themes', 'warning')
                return redirect(url_for('login'))
                
            return render_template('submit_theme.html',
                                 categories=community.categories)
        
        @app.route('/stats')
        def community_stats():
            """Community statistics page"""
            stats = self.get_community_statistics()
            return render_template('stats.html', stats=stats)
        
        @app.route('/api/theme/<theme_id>/favorite', methods=['POST'])
        def toggle_favorite(theme_id):
            """Toggle theme favorite status"""
            if 'user_id' not in session:
                return jsonify({'error': 'Not logged in'}), 401
                
            action = request.json.get('action')  # 'add' or 'remove'
            
            if action == 'add':
                success = community.add_to_favorites(theme_id)
            elif action == 'remove':
                success = community.remove_from_favorites(theme_id)
            else:
                return jsonify({'error': 'Invalid action'}), 400
                
            return jsonify({'success': success})
        
        @app.route('/api/theme/<theme_id>/rate', methods=['POST'])
        def rate_theme(theme_id):
            """Rate and review a theme"""
            if 'user_id' not in session:
                return jsonify({'error': 'Not logged in'}), 401
                
            rating = request.json.get('rating')
            review = request.json.get('review', '')
            
            if not rating or rating < 1 or rating > 5:
                return jsonify({'error': 'Invalid rating'}), 400
                
            success = community.rate_theme(theme_id, rating, review)
            return jsonify({'success': success})
        
        @app.route('/api/theme/<theme_id>/download', methods=['POST'])
        def download_theme(theme_id):
            """Download theme API"""
            success = community.download_theme(theme_id)
            return jsonify({'success': success})
        
        @app.route('/api/community/stats')
        def api_stats():
            """API endpoint for community stats"""
            stats = self.get_community_statistics()
            return jsonify(stats)
        
        @app.route('/login')
        def login():
            """Login page"""
            return render_template('login.html')
        
        @app.route('/register')
        def register():
            """Registration page"""
            return render_template('register.html')
        
        @app.route('/events')
        def community_events():
            """Community events page"""
            events = self.get_community_events()
            return render_template('events.html', events=events)
        
        @app.route('/leaderboard')
        def leaderboard():
            """Community leaderboard"""
            leaderboard_data = self.get_leaderboard()
            return render_template('leaderboard.html', leaderboard=leaderboard_data)
    
    def get_theme_reviews(self, theme_id: str) -> List[Dict]:
        """Get reviews for a theme"""
        # Mock reviews data
        return [
            {
                'id': 'review1',
                'user': 'ricemaster',
                'rating': 5,
                'review': 'Amazing theme! Love the animations and color scheme.',
                'created_at': '2024-02-15T10:30:00Z',
                'helpful_count': 12
            },
            {
                'id': 'review2', 
                'user': 'linuxfan',
                'rating': 4,
                'review': 'Great theme, but could use better waybar integration.',
                'created_at': '2024-02-10T15:20:00Z',
                'helpful_count': 8
            }
        ]
    
    def is_theme_favorited(self, theme_id: str) -> bool:
        """Check if theme is in user's favorites"""
        if 'user_id' not in session:
            return False
        # Mock check
        return False
    
    def get_community_statistics(self) -> Dict:
        """Get comprehensive community statistics"""
        themes = community._get_cached_themes(limit=1000)
        
        total_downloads = sum(theme.get('downloads', 0) for theme in themes)
        avg_rating = sum(theme.get('rating', 0) for theme in themes) / len(themes) if themes else 0
        
        # Category distribution
        category_stats = {}
        for theme in themes:
            category = theme.get('category', 'unknown')
            category_stats[category] = category_stats.get(category, 0) + 1
        
        # Monthly growth (mock data)
        monthly_growth = [
            {'month': 'Jan 2024', 'themes': 45, 'users': 120, 'downloads': 2500},
            {'month': 'Feb 2024', 'themes': 62, 'users': 180, 'downloads': 3200},
            {'month': 'Mar 2024', 'themes': 78, 'users': 250, 'downloads': 4100},
        ]
        
        return {
            'total_themes': len(themes),
            'total_downloads': total_downloads,
            'average_rating': round(avg_rating, 2),
            'active_users': 1250,  # Mock
            'category_distribution': category_stats,
            'monthly_growth': monthly_growth,
            'top_contributors': [
                {'username': 'ricegod', 'themes': 8, 'downloads': 45000},
                {'username': 'gamingmaster', 'themes': 5, 'downloads': 32000},
                {'username': 'zenmaster', 'themes': 3, 'downloads': 28000},
            ]
        }
    
    def get_community_events(self) -> List[Dict]:
        """Get upcoming community events"""
        return [
            {
                'id': 'rice-contest-2024',
                'title': 'Rice Contest 2024',
                'description': 'Annual rice competition with amazing prizes!',
                'date': '2024-03-15T18:00:00Z',
                'type': 'contest',
                'participants': 89
            },
            {
                'id': 'theme-workshop',
                'title': 'Theme Creation Workshop',
                'description': 'Learn how to create stunning Hyprland themes',
                'date': '2024-03-08T16:00:00Z',
                'type': 'workshop',
                'participants': 34
            },
            {
                'id': 'community-showcase',
                'title': 'Monthly Showcase',
                'description': 'Show off your latest rice creations',
                'date': '2024-03-01T20:00:00Z',
                'type': 'showcase',
                'participants': 156
            }
        ]
    
    def get_leaderboard(self) -> Dict:
        """Get community leaderboard"""
        return {
            'top_creators': [
                {'rank': 1, 'username': 'ricegod', 'themes': 8, 'total_downloads': 45000, 'avg_rating': 4.8},
                {'rank': 2, 'username': 'gamingmaster', 'themes': 5, 'total_downloads': 32000, 'avg_rating': 4.6},
                {'rank': 3, 'username': 'zenmaster', 'themes': 3, 'total_downloads': 28000, 'avg_rating': 4.9},
            ],
            'most_downloaded': [
                {'rank': 1, 'theme': 'Catppuccin Supreme', 'downloads': 15420, 'rating': 4.8},
                {'rank': 2, 'theme': 'Minimal Zen', 'downloads': 12350, 'rating': 4.9},
                {'rank': 3, 'theme': 'Neon Gaming Setup', 'downloads': 8920, 'rating': 4.6},
            ],
            'highest_rated': [
                {'rank': 1, 'theme': 'Minimal Zen', 'rating': 4.9, 'reviews': 203},
                {'rank': 2, 'theme': 'Catppuccin Supreme', 'rating': 4.8, 'reviews': 156},
                {'rank': 3, 'theme': 'Neon Gaming Setup', 'rating': 4.6, 'reviews': 89},
            ]
        }

def create_templates():
    """Create HTML templates for the web interface"""
    templates_dir = Path(__file__).parent / "templates"
    templates_dir.mkdir(exist_ok=True)
    
    # Base template
    base_template = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}HyprSupreme Community{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body class="bg-gray-900 text-white">
    <nav class="bg-gray-800 border-b border-gray-700">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-16">
                <div class="flex items-center">
                    <a href="{{ url_for('index') }}" class="text-xl font-bold text-blue-400">
                        <i class="fas fa-desktop mr-2"></i>HyprSupreme
                    </a>
                    <div class="ml-10 flex items-baseline space-x-4">
                        <a href="{{ url_for('discover') }}" class="hover:text-blue-400 px-3 py-2 rounded-md">Discover</a>
                        <a href="{{ url_for('search') }}" class="hover:text-blue-400 px-3 py-2 rounded-md">Search</a>
                        <a href="{{ url_for('community_stats') }}" class="hover:text-blue-400 px-3 py-2 rounded-md">Stats</a>
                        <a href="{{ url_for('leaderboard') }}" class="hover:text-blue-400 px-3 py-2 rounded-md">Leaderboard</a>
                        <a href="{{ url_for('community_events') }}" class="hover:text-blue-400 px-3 py-2 rounded-md">Events</a>
                    </div>
                </div>
                <div class="flex items-center space-x-4">
                    <a href="{{ url_for('submit_theme') }}" class="bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded-md">
                        <i class="fas fa-plus mr-1"></i>Submit Theme
                    </a>
                    <a href="{{ url_for('favorites') }}" class="hover:text-blue-400">
                        <i class="fas fa-heart"></i>
                    </a>
                </div>
            </div>
        </div>
    </nav>

    <main>
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4">
                    {% for category, message in messages %}
                        <div class="alert alert-{{ category }} bg-{% if category == 'error' %}red{% elif category == 'warning' %}yellow{% else %}green{% endif %}-600 text-white px-4 py-2 rounded-md mb-4">
                            {{ message }}
                        </div>
                    {% endfor %}
                </div>
            {% endif %}
        {% endwith %}
        
        {% block content %}{% endblock %}
    </main>

    <footer class="bg-gray-800 border-t border-gray-700 mt-20">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <div class="text-center text-gray-400">
                <p>&copy; 2024 HyprSupreme Community. Made with ❤️ for the Linux community.</p>
            </div>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
</body>
</html>'''
    
    # Index template
    index_template = '''{% extends "base.html" %}

{% block content %}
<div class="bg-gradient-to-r from-blue-600 to-purple-700 py-20">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <h1 class="text-4xl md:text-6xl font-bold mb-6">
            Welcome to HyprSupreme Community
        </h1>
        <p class="text-xl md:text-2xl mb-8 opacity-90">
            Discover, share, and customize amazing Hyprland themes
        </p>
        <div class="flex justify-center space-x-4">
            <a href="{{ url_for('discover') }}" class="bg-white text-blue-600 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100">
                Explore Themes
            </a>
            <a href="{{ url_for('submit_theme') }}" class="border-2 border-white text-white px-8 py-3 rounded-lg font-semibold hover:bg-white hover:text-blue-600">
                Submit Your Theme
            </a>
        </div>
    </div>
</div>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <!-- Community Stats -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-8 mb-16">
        <div class="bg-gray-800 p-6 rounded-lg text-center">
            <div class="text-3xl font-bold text-blue-400">{{ stats.total_themes }}</div>
            <div class="text-gray-400">Themes</div>
        </div>
        <div class="bg-gray-800 p-6 rounded-lg text-center">
            <div class="text-3xl font-bold text-green-400">{{ stats.total_downloads }}</div>
            <div class="text-gray-400">Downloads</div>
        </div>
        <div class="bg-gray-800 p-6 rounded-lg text-center">
            <div class="text-3xl font-bold text-purple-400">{{ stats.active_users }}</div>
            <div class="text-gray-400">Active Users</div>
        </div>
        <div class="bg-gray-800 p-6 rounded-lg text-center">
            <div class="text-3xl font-bold text-yellow-400">{{ stats.categories }}</div>
            <div class="text-gray-400">Categories</div>
        </div>
    </div>

    <!-- Featured Themes -->
    <section class="mb-16">
        <h2 class="text-3xl font-bold mb-8">Featured Themes</h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            {% for theme in featured_themes[:3] %}
            <div class="bg-gray-800 rounded-lg overflow-hidden hover:bg-gray-750 transition-colors">
                <div class="h-48 bg-gradient-to-r from-blue-500 to-purple-600"></div>
                <div class="p-6">
                    <h3 class="text-xl font-semibold mb-2">{{ theme.name }}</h3>
                    <p class="text-gray-400 mb-4">{{ theme.description[:100] }}...</p>
                    <div class="flex items-center justify-between">
                        <span class="text-sm text-gray-500">by {{ theme.author }}</span>
                        <div class="flex items-center space-x-2">
                            <span class="text-yellow-400">
                                <i class="fas fa-star"></i> {{ theme.rating }}
                            </span>
                            <span class="text-gray-500">
                                <i class="fas fa-download"></i> {{ theme.downloads }}
                            </span>
                        </div>
                    </div>
                    <a href="{{ url_for('theme_detail', theme_id=theme.id) }}" 
                       class="block w-full bg-blue-600 hover:bg-blue-700 text-center py-2 rounded-md mt-4">
                        View Theme
                    </a>
                </div>
            </div>
            {% endfor %}
        </div>
    </section>

    <!-- Trending Themes -->
    <section>
        <h2 class="text-3xl font-bold mb-8">Trending This Week</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {% for theme in trending_themes[:4] %}
            <div class="bg-gray-800 p-4 rounded-lg">
                <h4 class="font-semibold mb-2">{{ theme.name }}</h4>
                <p class="text-sm text-gray-400 mb-3">{{ theme.category.title() }}</p>
                <div class="flex items-center justify-between text-sm">
                    <span class="text-yellow-400">
                        <i class="fas fa-star"></i> {{ theme.rating }}
                    </span>
                    <span class="text-green-400">
                        <i class="fas fa-arrow-up"></i> {{ theme.downloads }}
                    </span>
                </div>
            </div>
            {% endfor %}
        </div>
    </section>
</div>
{% endblock %}'''

    # Save templates
    (templates_dir / "base.html").write_text(base_template)
    (templates_dir / "index.html").write_text(index_template)
    
    print(f"Created templates in {templates_dir}")

def main():
    """Run the web application"""
    create_templates()
    web_app = CommunityWebApp()
    
    print("Starting HyprSupreme Community Web Interface...")
    print("Visit http://localhost:5000 to access the community platform")
    
    app.run(debug=True, host='0.0.0.0', port=5000)

if __name__ == "__main__":
    main()

