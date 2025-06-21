#!/usr/bin/env python3
"""
Advanced API endpoints for the HyprSupreme-Builder community platform.
Provides theme discovery, plugin marketplace, and community features.
"""

from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import json
import os
import sqlite3
from datetime import datetime
from typing import Dict, List, Optional

app = Flask(__name__)
CORS(app)

# Database setup
DB_PATH = "community.db"

def init_database():
    """Initialize the community database with required tables."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Themes table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS themes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            author TEXT NOT NULL,
            version TEXT NOT NULL,
            description TEXT,
            downloads INTEGER DEFAULT 0,
            rating REAL DEFAULT 0.0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            config_data TEXT NOT NULL
        )
    ''')
    
    # Plugins table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS plugins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            author TEXT NOT NULL,
            version TEXT NOT NULL,
            description TEXT,
            downloads INTEGER DEFAULT 0,
            rating REAL DEFAULT 0.0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            manifest_data TEXT NOT NULL
        )
    ''')
    
    # Reviews table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_type TEXT NOT NULL, -- 'theme' or 'plugin'
            item_id INTEGER NOT NULL,
            user_name TEXT NOT NULL,
            rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
            comment TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.commit()
    conn.close()

# API Routes

@app.route('/api/themes', methods=['GET'])
def get_themes():
    """Get all available themes with pagination and filtering."""
    page = int(request.args.get('page', 1))
    limit = int(request.args.get('limit', 20))
    search = request.args.get('search', '')
    sort_by = request.args.get('sort', 'downloads')  # downloads, rating, created_at
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Build query with search and sorting
    query = '''
        SELECT id, name, author, version, description, downloads, rating, created_at
        FROM themes
        WHERE name LIKE ? OR description LIKE ?
        ORDER BY {} DESC
        LIMIT ? OFFSET ?
    '''.format(sort_by)
    
    search_pattern = f'%{search}%'
    offset = (page - 1) * limit
    
    cursor.execute(query, (search_pattern, search_pattern, limit, offset))
    themes = []
    
    for row in cursor.fetchall():
        themes.append({
            'id': row[0],
            'name': row[1],
            'author': row[2],
            'version': row[3],
            'description': row[4],
            'downloads': row[5],
            'rating': row[6],
            'created_at': row[7]
        })
    
    conn.close()
    
    return jsonify({
        'themes': themes,
        'page': page,
        'total': len(themes)
    })

@app.route('/api/themes/<theme_name>', methods=['GET'])
def get_theme_details(theme_name):
    """Get detailed information about a specific theme."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT id, name, author, version, description, downloads, rating, 
               created_at, updated_at, config_data
        FROM themes WHERE name = ?
    ''', (theme_name,))
    
    row = cursor.fetchone()
    if not row:
        return jsonify({'error': 'Theme not found'}), 404
    
    # Get reviews for this theme
    cursor.execute('''
        SELECT user_name, rating, comment, created_at
        FROM reviews
        WHERE item_type = 'theme' AND item_id = ?
        ORDER BY created_at DESC
    ''', (row[0],))
    
    reviews = []
    for review_row in cursor.fetchall():
        reviews.append({
            'user_name': review_row[0],
            'rating': review_row[1],
            'comment': review_row[2],
            'created_at': review_row[3]
        })
    
    conn.close()
    
    theme_data = {
        'id': row[0],
        'name': row[1],
        'author': row[2],
        'version': row[3],
        'description': row[4],
        'downloads': row[5],
        'rating': row[6],
        'created_at': row[7],
        'updated_at': row[8],
        'config': json.loads(row[9]),
        'reviews': reviews
    }
    
    return jsonify(theme_data)

@app.route('/api/themes/<theme_name>/download', methods=['POST'])
def download_theme(theme_name):
    """Download a theme and increment download counter."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Increment download counter
    cursor.execute('''
        UPDATE themes SET downloads = downloads + 1
        WHERE name = ?
    ''', (theme_name,))
    
    if cursor.rowcount == 0:
        conn.close()
        return jsonify({'error': 'Theme not found'}), 404
    
    # Get theme config
    cursor.execute('''
        SELECT config_data FROM themes WHERE name = ?
    ''', (theme_name,))
    
    row = cursor.fetchone()
    conn.commit()
    conn.close()
    
    return jsonify({
        'message': 'Theme downloaded successfully',
        'config': json.loads(row[0])
    })

@app.route('/api/plugins', methods=['GET'])
def get_plugins():
    """Get all available plugins with pagination and filtering."""
    page = int(request.args.get('page', 1))
    limit = int(request.args.get('limit', 20))
    search = request.args.get('search', '')
    sort_by = request.args.get('sort', 'downloads')
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    query = '''
        SELECT id, name, author, version, description, downloads, rating, created_at
        FROM plugins
        WHERE name LIKE ? OR description LIKE ?
        ORDER BY {} DESC
        LIMIT ? OFFSET ?
    '''.format(sort_by)
    
    search_pattern = f'%{search}%'
    offset = (page - 1) * limit
    
    cursor.execute(query, (search_pattern, search_pattern, limit, offset))
    plugins = []
    
    for row in cursor.fetchall():
        plugins.append({
            'id': row[0],
            'name': row[1],
            'author': row[2],
            'version': row[3],
            'description': row[4],
            'downloads': row[5],
            'rating': row[6],
            'created_at': row[7]
        })
    
    conn.close()
    
    return jsonify({
        'plugins': plugins,
        'page': page,
        'total': len(plugins)
    })

@app.route('/api/themes', methods=['POST'])
def upload_theme():
    """Upload a new theme to the community platform."""
    data = request.get_json()
    
    required_fields = ['name', 'author', 'version', 'config']
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        cursor.execute('''
            INSERT INTO themes (name, author, version, description, config_data)
            VALUES (?, ?, ?, ?, ?)
        ''', (
            data['name'],
            data['author'],
            data['version'],
            data.get('description', ''),
            json.dumps(data['config'])
        ))
        
        conn.commit()
        theme_id = cursor.lastrowid
        
        return jsonify({
            'message': 'Theme uploaded successfully',
            'theme_id': theme_id
        }), 201
        
    except sqlite3.IntegrityError:
        return jsonify({'error': 'Theme name already exists'}), 409
    finally:
        conn.close()

@app.route('/api/plugins', methods=['POST'])
def upload_plugin():
    """Upload a new plugin to the community platform."""
    data = request.get_json()
    
    required_fields = ['name', 'author', 'version', 'manifest']
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        cursor.execute('''
            INSERT INTO plugins (name, author, version, description, manifest_data)
            VALUES (?, ?, ?, ?, ?)
        ''', (
            data['name'],
            data['author'],
            data['version'],
            data.get('description', ''),
            json.dumps(data['manifest'])
        ))
        
        conn.commit()
        plugin_id = cursor.lastrowid
        
        return jsonify({
            'message': 'Plugin uploaded successfully',
            'plugin_id': plugin_id
        }), 201
        
    except sqlite3.IntegrityError:
        return jsonify({'error': 'Plugin name already exists'}), 409
    finally:
        conn.close()

@app.route('/api/reviews', methods=['POST'])
def submit_review():
    """Submit a review for a theme or plugin."""
    data = request.get_json()
    
    required_fields = ['item_type', 'item_id', 'user_name', 'rating']
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400
    
    if data['item_type'] not in ['theme', 'plugin']:
        return jsonify({'error': 'Invalid item type'}), 400
    
    if not (1 <= data['rating'] <= 5):
        return jsonify({'error': 'Rating must be between 1 and 5'}), 400
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT INTO reviews (item_type, item_id, user_name, rating, comment)
        VALUES (?, ?, ?, ?, ?)
    ''', (
        data['item_type'],
        data['item_id'],
        data['user_name'],
        data['rating'],
        data.get('comment', '')
    ))
    
    # Update average rating
    cursor.execute('''
        UPDATE {} SET rating = (
            SELECT AVG(rating) FROM reviews
            WHERE item_type = ? AND item_id = ?
        ) WHERE id = ?
    '''.format(data['item_type'] + 's'), (
        data['item_type'],
        data['item_id'],
        data['item_id']
    ))
    
    conn.commit()
    conn.close()
    
    return jsonify({'message': 'Review submitted successfully'}), 201

@app.route('/api/stats', methods=['GET'])
def get_platform_stats():
    """Get platform statistics."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get theme stats
    cursor.execute('SELECT COUNT(*), SUM(downloads) FROM themes')
    theme_count, theme_downloads = cursor.fetchone()
    
    # Get plugin stats
    cursor.execute('SELECT COUNT(*), SUM(downloads) FROM plugins')
    plugin_count, plugin_downloads = cursor.fetchone()
    
    # Get recent items
    cursor.execute('''
        SELECT name, 'theme' as type, created_at FROM themes
        UNION ALL
        SELECT name, 'plugin' as type, created_at FROM plugins
        ORDER BY created_at DESC
        LIMIT 10
    ''')
    
    recent_items = []
    for row in cursor.fetchall():
        recent_items.append({
            'name': row[0],
            'type': row[1],
            'created_at': row[2]
        })
    
    conn.close()
    
    return jsonify({
        'themes': {
            'count': theme_count or 0,
            'total_downloads': theme_downloads or 0
        },
        'plugins': {
            'count': plugin_count or 0,
            'total_downloads': plugin_downloads or 0
        },
        'recent_items': recent_items
    })

# Web Interface Routes

@app.route('/')
def index():
    """Main community platform page."""
    return render_template('index.html')

@app.route('/themes')
def themes_page():
    """Theme browser page."""
    return render_template('themes.html')

@app.route('/plugins')
def plugins_page():
    """Plugin browser page."""
    return render_template('plugins.html')

@app.route('/upload')
def upload_page():
    """Upload theme/plugin page."""
    return render_template('upload.html')

if __name__ == '__main__':
    init_database()
    app.run(debug=True, host='0.0.0.0', port=5000)
