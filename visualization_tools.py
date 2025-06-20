#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HyprSupreme Advanced Visualization Tools
Version: 1.0.0
Description: Advanced visualization capabilities for system performance monitoring,
             including 3D visualizations, heat maps, and correlation analysis.
"""

import os
import sys
import json
import time
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import cm
import matplotlib.dates as mdates
import seaborn as sns
from datetime import datetime, timedelta
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
from scipy.stats import pearsonr, spearmanr
import argparse
from PyQt5.QtWidgets import (QApplication, QMainWindow, QVBoxLayout, 
                             QHBoxLayout, QWidget, QPushButton, QTabWidget,
                             QLabel, QComboBox, QSpinBox, QDateEdit, 
                             QFileDialog, QSplitter, QCheckBox, QGroupBox,
                             QRadioButton, QMessageBox)
from PyQt5.QtCore import Qt, QSize, pyqtSignal, QThread, QTimer, QDateTime
from PyQt5.QtGui import QFont, QIcon, QColor, QPalette
import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.backends.backend_qt5agg import NavigationToolbar2QT as NavigationToolbar
from matplotlib.figure import Figure
from mpl_toolkits.mplot3d import Axes3D

# Configuration
DEFAULT_DATA_DIR = os.path.expanduser("~/.local/share/hyprsupreme/monitoring/data")
DEFAULT_CONFIG_FILE = os.path.expanduser("~/.config/hyprsupreme/visualization.conf")
DEFAULT_THEME = "dark"
DEFAULT_LOG_FILE = os.path.expanduser("~/.local/share/hyprsupreme/logs/visualization.log")

# Set default style
plt.style.use('dark_background')
sns.set_style("darkgrid")

class DataManager:
    """
    Handles loading, preprocessing, and managing monitoring data for visualizations
    """
    def __init__(self, data_dir=DEFAULT_DATA_DIR):
        self.data_dir = data_dir
        self.metrics_data = None
        self.time_series_data = None
        self.process_data = None
        self.system_specs = None
        
    def load_data(self, time_range=None):
        """
        Load monitoring data from JSON files within the specified time range
        
        Args:
            time_range (tuple): (start_datetime, end_datetime) to filter data
        
        Returns:
            bool: Success status
        """
        try:
            all_files = []
            for root, _, files in os.walk(self.data_dir):
                for file in files:
                    if file.endswith('.json'):
                        all_files.append(os.path.join(root, file))
                        
            if not all_files:
                print(f"No data files found in {self.data_dir}")
                return False
                
            # Load all files into a dataframe
            data_list = []
            for file_path in sorted(all_files):
                with open(file_path, 'r') as f:
                    try:
                        data = json.load(f)
                        # Extract timestamp from filename or data
                        if 'timestamp' not in data:
                            # Extract from filename like metrics_20250620_153045.json
                            filename = os.path.basename(file_path)
                            if '_' in filename and '.json' in filename:
                                date_part = filename.split('_')[1]
                                time_part = filename.split('_')[2].split('.')[0]
                                if len(date_part) == 8 and len(time_part) == 6:  # YYYYMMDD and HHMMSS
                                    timestamp = f"{date_part[:4]}-{date_part[4:6]}-{date_part[6:]} {time_part[:2]}:{time_part[2:4]}:{time_part[4:]}"
                                    data['timestamp'] = timestamp
                        
                        # Only append if it contains a timestamp
                        if 'timestamp' in data:
                            data_list.append(data)
                    except json.JSONDecodeError:
                        print(f"Error decoding JSON from {file_path}")
            
            # Convert to DataFrame
            if data_list:
                df = pd.json_normalize(data_list)
                
                # Ensure timestamp is datetime
                df['timestamp'] = pd.to_datetime(df['timestamp'])
                
                # Filter by time range if specified
                if time_range:
                    start_time, end_time = time_range
                    df = df[(df['timestamp'] >= start_time) & 
                            (df['timestamp'] <= end_time)]
                
                # Sort by timestamp
                df = df.sort_values('timestamp')
                
                # Process different types of data
                self._process_data(df)
                
                return True
            else:
                print("No valid data found in files")
                return False
                
        except Exception as e:
            print(f"Error loading data: {e}")
            return False
    
    def _process_data(self, df):
        """Process the loaded data into different categories"""
        # Extract basic time series metrics
        time_series_cols = ['timestamp', 'cpu.usage', 'memory.percent', 
                          'disk.percent', 'network.bytes_sent', 'network.bytes_recv']
        
        # Keep only columns that exist in the DataFrame
        valid_cols = [col for col in time_series_cols if col in df.columns]
        
        if valid_cols:
            self.time_series_data = df[valid_cols].copy()
        
        # Extract process data if available
        process_cols = [col for col in df.columns if 'processes' in col]
        if process_cols:
            self.process_data = df[process_cols].copy()
        
        # Extract system specifications if available
        system_cols = [col for col in df.columns if 'system' in col]
        if system_cols:
            self.system_specs = df[system_cols].iloc[0].to_dict()  # Use first row
            
        # Store the entire dataset
        self.metrics_data = df
        
    def get_metric_names(self):
        """Return list of available metrics"""
        if self.metrics_data is None:
            return []
        return [col for col in self.metrics_data.columns 
                if col != 'timestamp' and not col.startswith('_')]
    
    def get_time_range(self):
        """Return the total time range of loaded data"""
        if self.time_series_data is None or len(self.time_series_data) == 0:
            return None
        
        min_time = self.time_series_data['timestamp'].min()
        max_time = self.time_series_data['timestamp'].max()
        return (min_time, max_time)
    
    def export_data(self, file_path, format='csv'):
        """Export data to CSV or Excel format"""
        if self.metrics_data is None:
            return False
        
        try:
            if format.lower() == 'csv':
                self.metrics_data.to_csv(file_path, index=False)
            elif format.lower() == 'excel':
                self.metrics_data.to_excel(file_path, index=False)
            elif format.lower() == 'json':
                self.metrics_data.to_json(file_path, orient='records')
            else:
                return False
            return True
        except Exception as e:
            print(f"Error exporting data: {e}")
            return False


class HeatMapVisualizer:
    """
    Creates heat map visualizations for system resource usage and distributions
    """
    def __init__(self, data_manager):
        self.data_manager = data_manager
        
    def create_cpu_heatmap(self, figure=None, ax=None):
        """
        Create a CPU usage heatmap over time and cores
        
        Args:
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        if self.data_manager.metrics_data is None:
            return None, None
            
        # Extract CPU per-core data if available
        cpu_cols = [col for col in self.data_manager.metrics_data.columns 
                   if 'cpu.core' in col and '.percent' in col]
        
        if not cpu_cols:
            print("No per-core CPU data available")
            return None, None
            
        # Create figure if not provided
        if figure is None or ax is None:
            fig, ax = plt.subplots(figsize=(12, 8))
        else:
            fig = figure
            
        # Prepare data
        core_data = self.data_manager.metrics_data[['timestamp'] + cpu_cols].copy()
        
        # Convert to matrix form for heatmap
        # Extract datetime for x-axis
        timestamps = core_data['timestamp']
        core_matrix = core_data[cpu_cols].values.T
        
        # Create heatmap
        im = ax.imshow(core_matrix, aspect='auto', cmap='inferno', 
                      interpolation='nearest', origin='lower')
        
        # Format axes
        ax.set_title('CPU Core Usage Heatmap')
        ax.set_ylabel('CPU Core')
        ax.set_xlabel('Time')
        
        # Set y-axis ticks to core numbers
        ax.set_yticks(range(len(cpu_cols)))
        ax.set_yticklabels([f"Core {i}" for i in range(len(cpu_cols))])
        
        # Format x-axis to show times
        time_indices = np.linspace(0, len(timestamps)-1, min(10, len(timestamps)))
        time_indices = [int(i) for i in time_indices]
        ax.set_xticks(time_indices)
        time_labels = [timestamps.iloc[i].strftime('%H:%M:%S') for i in time_indices]
        ax.set_xticklabels(time_labels, rotation=45)
        
        # Add colorbar
        cbar = fig.colorbar(im, ax=ax)
        cbar.set_label('CPU Usage %')
        
        return fig, ax
    
    def create_metric_heatmap(self, metrics=None, time_bins=24, metric_bins=10, figure=None, ax=None):
        """
        Create a 2D heatmap showing distribution of metrics over time
        
        Args:
            metrics: List of metrics to include (default: top 5 by variance)
            time_bins: Number of time bins to divide the data into
            metric_bins: Number of bins for metric values
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        if self.data_manager.metrics_data is None:
            return None, None
            
        # If metrics not specified, use top variable metrics
        if metrics is None:
            # Exclude timestamp and get variance
            numeric_cols = self.data_manager.metrics_data.select_dtypes(include=[np.number]).columns
            variances = self.data_manager.metrics_data[numeric_cols].var()
            metrics = variances.nlargest(5).index.tolist()
        
        # Create figure if not provided
        if figure is None or ax is None:
            fig, ax = plt.subplots(figsize=(14, 10))
        else:
            fig = figure
        
        # Create a correlation matrix
        corr_matrix = self.data_manager.metrics_data[metrics].corr()
        
        # Create heatmap
        sns.heatmap(corr_matrix, annot=True, cmap='coolwarm', vmin=-1, vmax=1, ax=ax)
        
        ax.set_title('Metric Correlation Heatmap')
        
        return fig, ax
    
    def create_time_distribution_heatmap(self, metric, figure=None, ax=None):
        """
        Create a heatmap showing distribution of a metric over hours and days
        
        Args:
            metric: The metric to visualize
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        if self.data_manager.metrics_data is None or metric not in self.data_manager.metrics_data:
            return None, None
            
        # Create figure if not provided
        if figure is None or ax is None:
            fig, ax = plt.subplots(figsize=(12, 8))
        else:
            fig = figure
            
        # Extract hour and day from timestamp
        df = self.data_manager.metrics_data.copy()
        df['hour'] = df['timestamp'].dt.hour
        df['day'] = df['timestamp'].dt.day_name()
        
        # Order days of week properly
        day_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        
        # Calculate average metric value for each hour-day combination
        pivot_data = df.pivot_table(index='day', columns='hour', values=metric, aggfunc='mean')
        
        # Reorder days
        pivot_data = pivot_data.reindex(day_order)
        
        # Create heatmap
        sns.heatmap(pivot_data, cmap='viridis', ax=ax, cbar_kws={'label': metric})
        
        ax.set_title(f'{metric} by Hour and Day')
        ax.set_xlabel('Hour of Day')
        ax.set_ylabel('Day of Week')
        
        return fig, ax


class ThreeDVisualizer:
    """
    Creates 3D visualizations for system performance data
    """
    def __init__(self, data_manager):
        self.data_manager = data_manager
        
    def create_3d_surface(self, x_metric, y_metric, z_metric, figure=None, ax=None):
        """
        Create a 3D surface plot showing relationship between three metrics
        
        Args:
            x_metric: Metric for X axis
            y_metric: Metric for Y axis
            z_metric: Metric for Z axis (height)
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        if (self.data_manager.metrics_data is None or
            x_metric not in self.data_manager.metrics_data or
            y_metric not in self.data_manager.metrics_data or
            z_metric not in self.data_manager.metrics_data):
            return None, None
        
        # Create figure if not provided
        if figure is None or ax is None:
            fig = plt.figure(figsize=(12, 10))
            ax = fig.add_subplot(111, projection='3d')
        else:
            fig = figure
        
        # Extract data
        x_data = self.data_manager.metrics_data[x_metric].values
        y_data = self.data_manager.metrics_data[y_metric].values
        z_data = self.data_manager.metrics_data[z_metric].values
        
        # Create the 3D scatter plot
        scatter = ax.scatter(x_data, y_data, z_data, c=z_data, cmap='viridis', 
                           marker='o', s=30, alpha=0.6)
        
        # Add labels
        ax.set_xlabel(x_metric)
        ax.set_ylabel(y_metric)
        ax.set_zlabel(z_metric)
        ax.set_title(f'3D Relationship: {x_metric} vs {y_metric} vs {z_metric}')
        
        # Add color bar
        cbar = fig.colorbar(scatter, ax=ax, shrink=0.5, aspect=5)
        cbar.set_label(z_metric + ' Value')
        
        return fig, ax
    
    def create_3d_time_surface(self, metric, time_resolution='hour', figure=None, ax=None):
        """
        Create a 3D surface showing metric value over time (as a surface)
        
        Args:
            metric: The metric to visualize
            time_resolution: Time bucketing ('minute', 'hour', 'day')
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        if self.data_manager.metrics_data is None or metric not in self.data_manager.metrics_data:
            return None, None
            
        # Create figure if not provided
        if figure is None or ax is None:
            fig = plt.figure(figsize=(12, 10))
            ax = fig.add_subplot(111, projection='3d')
        else:
            fig = figure
            
        # Group data by time resolution
        df = self.data_manager.metrics_data.copy()
        
        if time_resolution == 'minute':
            df['time_group'] = df['timestamp'].dt.strftime('%Y-%m-%d %H:%M')
        elif time_resolution == 'hour':
            df['time_group'] = df['timestamp'].dt.strftime('%Y-%m-%d %H')
        else:  # day
            df['time_group'] = df['timestamp'].dt.strftime('%Y-%m-%d')
            
        df['day'] = df['timestamp'].dt.day
        df['hour'] = df['timestamp'].dt.hour
        
        # Calculate average for each time group
        grouped = df.groupby(['day', 'hour'])[metric].mean().reset_index()
        
        # Create meshgrid for surface plot
        days = sorted(grouped['day'].unique())
        hours = sorted(grouped['hour'].unique())
        
        # Create coordinate matrices
        X, Y = np.meshgrid(days, hours)
        
        # Create Z matrix (the metric values)
        Z = np.zeros(X.shape)
        for i, hour in enumerate(hours):
            for j, day in enumerate(days):
                value = grouped[(grouped['day'] == day) & (grouped['hour'] == hour)]
                if not value.empty:
                    Z[i, j] = value[metric].values[0]
        
        # Create the surface plot
        surf = ax.plot_surface(X, Y, Z, cmap='plasma', edgecolor='none', alpha=0.8)
        
        # Add labels
        ax.set_xlabel('Day of Month')
        ax.set_ylabel('Hour of Day')
        ax.set_zlabel(metric)
        ax.set_title(f'3D Time Surface: {metric} by Day and Hour')
        
        # Add color bar
        cbar = fig.colorbar(surf, ax=ax, shrink=0.5, aspect=5)
        cbar.set_label(metric + ' Value')
        
        return fig, ax
    
    def create_3d_comparison(self, metrics, figure=None, ax=None):
        """
        Create a 3D bar chart comparing multiple metrics
        
        Args:
            metrics: List of metrics to compare
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        if self.data_manager.metrics_data is None:
            return None, None
            
        # Filter metrics to those that exist
        valid_metrics = [m for m in metrics if m in self.data_manager.metrics_data]
        
        if not valid_metrics:
            return None, None
            
        # Create figure if not provided
        if figure is None or ax is None:
            fig = plt.figure(figsize=(12, 10))
            ax = fig.add_subplot(111, projection='3d')
        else:
            fig = figure
            
        # Group data by day
        df = self.data_manager.metrics_data.copy()
        df['day'] = df['timestamp'].dt.day
        
        # Calculate daily averages for each metric
        daily_avgs = df.groupby('day')[valid_metrics].mean()
        
        # Setup the coordinates
        x_pos = np.arange(len(daily_avgs.index))
        y_pos = np.arange(len(valid_metrics))
        x_pos_mesh, y_pos_mesh = np.meshgrid(x_pos, y_pos)
        
        # Flatten the meshgrid
        x_pos_flat = x_pos_mesh.flatten()
        y_pos_flat = y_pos_mesh.flatten()
        
        # Create array for bar heights
        heights = np.zeros_like(x_pos_flat, dtype=float)
        
        # Fill in the heights
        for i, metric in enumerate(valid_metrics):
            for j, day in enumerate(daily_avgs.index):
                idx = i * len(daily_avgs.index) + j
                heights[idx] = daily_avgs.loc[day, metric]
        
        # Normalize heights to similar scale
        max_heights = np.max(heights)
        if max_heights > 0:
            heights = heights / max_heights
        
        # Width and depth of bars
        width = depth = 0.8
        
        # Create the 3D bar chart
        ax.bar3d(x_pos_flat, y_pos_flat, np.zeros_like(heights), 
                width, depth, heights, color='teal', alpha=0.8, shade=True)
        
        # Set labels
        ax.set_xticks(x_pos)
        ax.set_xticklabels([f"Day {d}" for d in daily_avgs.index])
        ax.set_yticks(y_pos)
        ax.set_yticklabels(valid_metrics)
        
        ax.set_xlabel('Day')
        ax.set_ylabel('Metric')
        ax.set_zlabel('Normalized Value')
        ax.set_title('3D Comparison of Metrics Over Days')
        
        return fig, ax


class CorrelationAnalyzer:
    """
    Performs correlation analysis between different metrics
    """
    def __init__(self, data_manager):
        self.data_manager = data_manager
        
    def calculate_correlations(self, metrics=None, method='pearson'):
        """
        Calculate correlations between specified metrics
        
        Args:
            metrics: List of metrics to analyze (None = all)
            method: Correlation method ('pearson' or 'spearman')
            
        Returns:
            DataFrame: Correlation matrix
        """
        if self.data_manager.metrics_data is None:
            return None
            
        # If metrics not specified, use all numeric columns except timestamp
        if metrics is None:
            metrics = self.data_manager.metrics_data.select_dtypes(include=[np.number]).columns.tolist()
            
        # Ensure all metrics exist in the data
        valid_metrics = [m for m in metrics if m in self.data_manager.metrics_data.columns]
        
        if not valid_metrics:
            return None
            
        # Calculate correlation matrix
        if method.lower() == 'pearson':
            corr_matrix = self.data_manager.metrics_data[valid_metrics].corr(method='pearson')
        else:
            corr_matrix = self.data_manager.metrics_data[valid_metrics].corr(method='spearman')
            
        return corr_matrix
        
    def plot_correlation_matrix(self, metrics=None, method='pearson', figure=None, ax=None):
        """
        Plot a correlation matrix for specified metrics
        
        Args:
            metrics: List of metrics to analyze (None = all)
            method: Correlation method ('pearson' or 'spearman')
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        corr_matrix = self.calculate_correlations(metrics, method)
        
        if corr_matrix is None:
            return None, None
            
        # Create figure if not provided
        if figure is None or ax is None:
            fig, ax = plt.subplots(figsize=(12, 10))
        else:
            fig = figure
            
        # Create mask for upper triangle
        mask = np.triu(np.ones_like(corr_matrix, dtype=bool))
        
        # Create heatmap
        sns.heatmap(corr_matrix, mask=mask, cmap='coolwarm', vmin=-1, vmax=1,
                   annot=True, fmt=".2f", ax=ax)
        
        ax.set_title(f'{method.capitalize()} Correlation Matrix')
        
        return fig, ax
        
    def find_top_correlations(self, target_metric, n=5, method='pearson'):
        """
        Find metrics most correlated with a target metric
        
        Args:
            target_metric: The metric to find correlations with
            n: Number of top correlations to return
            method: Correlation method ('pearson' or 'spearman')
            
        Returns:
            DataFrame: Top correlated metrics
        """
        if (self.data_manager.metrics_data is None or 
            target_metric not in self.data_manager.metrics_data.columns):
            return None
            
        # Calculate correlations with target
        numeric_cols = self.data_manager.metrics_data.select_dtypes(include=[np.number]).columns
        
        if method.lower() == 'pearson':
            correlations = {}
            for col in numeric_cols:
                if col != target_metric:
                    corr, _ = pearsonr(
                        self.data_manager.metrics_data[target_metric],
                        self.data_manager.metrics_data[col]
                    )
                    correlations[col] = corr
        else:
            correlations = {}
            for col in numeric_cols:
                if col != target_metric:
                    corr, _ = spearmanr(
                        self.data_manager.metrics_data[target_metric],
                        self.data_manager.metrics_data[col]
                    )
                    correlations[col] = corr
                
        # Convert to DataFrame and sort
        corr_df = pd.DataFrame({'metric': list(correlations.keys()),
                              'correlation': list(correlations.values())})
        corr_df = corr_df.sort_values('correlation', key=abs, ascending=False)
        
        return corr_df.head(n)
        
    def plot_top_correlations(self, target_metric, n=5, method='pearson', figure=None, ax=None):
        """
        Plot top correlations with a target metric
        
        Args:
            target_metric: The metric to find correlations with
            n: Number of top correlations to plot
            method: Correlation method ('pearson' or 'spearman')
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        top_corrs = self.find_top_correlations(target_metric, n, method)
        
        if top_corrs is None or len(top_corrs) == 0:
            return None, None
            
        # Create figure if not provided
        if figure is None or ax is None:
            fig, ax = plt.subplots(figsize=(10, 6))
        else:
            fig = figure
            
        # Create bar chart
        colors = ['g' if c >= 0 else 'r' for c in top_corrs['correlation']]
        ax.bar(top_corrs['metric'], top_corrs['correlation'], color=colors)
        
        # Format plot
        ax.axhline(y=0, color='k', linestyle='-', alpha=0.3)
        ax.set_title(f'Top Correlations with {target_metric}')
        ax.set_ylabel(f'{method.capitalize()} Correlation')
        plt.xticks(rotation=45, ha='right')
        ax.set_ylim(-1, 1)
        
        # Add correlation values
        for i, v in enumerate(top_corrs['correlation']):
            ax.text(i, v + (0.1 if v >= 0 else -0.1), 
                   f"{v:.2f}", ha='center', va='center' if v >= 0 else 'top')
        
        plt.tight_layout()
        
        return fig, ax


class TrendAnalyzer:
    """
    Analyzes long-term trends in system performance data
    """
    def __init__(self, data_manager):
        self.data_manager = data_manager
        
    def analyze_trend(self, metric, window=None):
        """
        Analyze trend for a specific metric
        
        Args:
            metric: The metric to analyze
            window: Rolling window size for smoothing
            
        Returns:
            DataFrame: Trend analysis results
        """
        if (self.data_manager.metrics_data is None or 
            metric not in self.data_manager.metrics_data.columns):
            return None
            
        # Copy the relevant data
        df = self.data_manager.metrics_data[['timestamp', metric]].copy()
        
        # Set index to timestamp for time series analysis
        df = df.set_index('timestamp')
        
        # Apply rolling window if specified
        if window is not None and window > 1:
            df[f'{metric}_rolling'] = df[metric].rolling(window=window).mean()
            
        # Calculate daily statistics
        df['day'] = df.index.date
        daily_stats = df.groupby('day')[metric].agg(['mean', 'min', 'max', 'std'])
        
        # Calculate overall trend using linear regression
        x = np.arange(len(df))
        y = df[metric].values
        
        # Remove NaN values
        mask = ~np.isnan(y)
        x = x[mask]
        y = y[mask]
        
        if len(x) > 1:
            slope, intercept = np.polyfit(x, y, 1)
            trend_direction = "increasing" if slope > 0 else "decreasing"
            trend_strength = abs(slope)
        else:
            slope, intercept = 0, 0
            trend_direction = "unknown"
            trend_strength = 0
        
        # Prepare result
        result = {
            'metric': metric,
            'start_time': df.index.min(),
            'end_time': df.index.max(),
            'mean': df[metric].mean(),
            'min': df[metric].min(),
            'max': df[metric].max(),
            'std': df[metric].std(),
            'trend_direction': trend_direction,
            'trend_strength': trend_strength,
            'slope': slope,
            'intercept': intercept,
            'daily_stats': daily_stats
        }
        
        return result
        
    def plot_trend(self, metric, window=None, show_trend_line=True, figure=None, ax=None):
        """
        Plot trend analysis for a specific metric
        
        Args:
            metric: The metric to analyze
            window: Rolling window size for smoothing
            show_trend_line: Whether to show the trend line
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        trend_data = self.analyze_trend(metric, window)
        
        if trend_data is None:
            return None, None
            
        # Create figure if not provided
        if figure is None or ax is None:
            fig, ax = plt.subplots(figsize=(12, 6))
        else:
            fig = figure
            
        # Extract data
        df = self.data_manager.metrics_data[['timestamp', metric]].copy()
        
        # Plot the raw data
        ax.plot(df['timestamp'], df[metric], 'o-', alpha=0.5, label='Raw data')
        
        # Plot rolling average if window specified
        if window is not None and window > 1:
            rolling_avg = df[metric].rolling(window=window).mean()
            ax.plot(df['timestamp'], rolling_avg, 'r-', 
                   linewidth=2, label=f'{window}-point Rolling Average')
        
        # Plot trend line if requested
        if show_trend_line and trend_data['slope'] != 0:
            x = np.arange(len(df))
            trend_y = trend_data['slope'] * x + trend_data['intercept']
            ax.plot(df['timestamp'], trend_y, 'g--', 
                   linewidth=2, label='Trend Line')
            
            # Add trend information as text
            direction = "increasing" if trend_data['slope'] > 0 else "decreasing"
            ax.text(0.02, 0.95, f"Trend: {direction}\nSlope: {trend_data['slope']:.4f}", 
                   transform=ax.transAxes, bbox=dict(facecolor='white', alpha=0.7))
        
        # Format plot
        ax.set_title(f'Trend Analysis: {metric}')
        ax.set_xlabel('Time')
        ax.set_ylabel(metric)
        ax.grid(True, alpha=0.3)
        ax.legend()
        
        # Format x-axis
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d %H:%M'))
        plt.xticks(rotation=45)
        
        plt.tight_layout()
        
        return fig, ax
        
    def plot_daily_comparison(self, metric, figure=None, ax=None):
        """
        Plot daily comparison for a specific metric
        
        Args:
            metric: The metric to analyze
            figure: Matplotlib figure (optional)
            ax: Matplotlib axis (optional)
            
        Returns:
            fig, ax: The figure and axis objects
        """
        if (self.data_manager.metrics_data is None or 
            metric not in self.data_manager.metrics_data.columns):
            return None, None
            
        # Create figure if not provided
        if figure is None or ax is None:
            fig, ax = plt.subplots(figsize=(12, 6))
        else:
            fig = figure
            
        # Extract data and group by day
        df = self.data_manager.metrics_data[['timestamp', metric]].copy()
        df['day'] = df['timestamp'].dt.date
        
        # Calculate daily statistics
        daily_stats = df.groupby('day')[metric].agg(['mean', 'min', 'max']).reset_index()
        
        # Plot daily min, max, and mean
        ax.fill_between(daily_stats['day'], daily_stats['min'], daily_stats['max'], 
                       alpha=0.2, color='blue', label='Min-Max Range')
        ax.plot(daily_stats['day'], daily_stats['mean'], 'o-', 
               color='blue', label='Daily Mean')
        
        # Format plot
        ax.set_title(f'Daily {metric} Comparison')
        ax.set_xlabel('Date')
        ax.set_ylabel(metric)
        ax.grid(True, alpha=0.3)
        ax.legend()
        
        # Format x-axis
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
        plt.xticks(rotation=45)
        
        plt.tight_layout()
        
        return fig, ax


class VisualizationApp(QMainWindow):
    """
    Main application window for HyprSupreme Advanced Visualization Tools
    """
    def __init__(self):
        super().__init__()
        
        # Initialize components
        self.data_manager = DataManager()
        self.heat_map_visualizer = HeatMapVisualizer(self.data_manager)
        self.three_d_visualizer = ThreeDVisualizer(self.data_manager)
        self.correlation_analyzer = CorrelationAnalyzer(self.data_manager)
        self.trend_analyzer = TrendAnalyzer(self.data_manager)
        
        # Set up UI
        self.init_ui()
        
    def init_ui(self):
        """Initialize the user interface"""
        self.setWindowTitle('HyprSupreme Advanced Visualization Tools')
        self.setGeometry(100, 100, 1200, 800)
        
        # Set up central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        
        # Create toolbar with actions
        toolbar = self.addToolBar('Main Toolbar')
        
        # Load data action
        load_action = toolbar.addAction('Load Data')
        load_action.triggered.connect(self.load_data)
        
        # Export data action
        export_action = toolbar.addAction('Export Data')
        export_action.triggered.connect(self.export_data)
        
        # Add separator
        toolbar.addSeparator()
        
        # Theme toggle
        self.dark_mode_action = toolbar.addAction('Toggle Dark Mode')
        self.dark_mode_action.setCheckable(True)
        self.dark_mode_action.setChecked(True)  # Default to dark mode
        self.dark_mode_action.triggered.connect(self.toggle_theme)
        
        # Add separator
        toolbar.addSeparator()
        
        # Screenshot action
        screenshot_action = toolbar.addAction('Screenshot')
        screenshot_action.triggered.connect(self.take_screenshot)
        
        # Create tab widget for different visualization types
        self.tabs = QTabWidget()
        main_layout.addWidget(self.tabs)
        
        # Create tabs for different visualization types
        self.create_heatmap_tab()
        self.create_3d_visualization_tab()
        self.create_correlation_tab()
        self.create_trend_analysis_tab()
        
        # Status bar for information
        self.statusBar().showMessage('Ready')
        
        # Apply initial theme
        self.apply_theme(True)  # Dark mode by default
        
    def create_heatmap_tab(self):
        """Create the heat map visualization tab"""
        tab = QWidget()
        layout = QVBoxLayout(tab)
        
        # Control panel
        control_panel = QWidget()
        control_layout = QHBoxLayout(control_panel)
        
        # Metric selection
        metric_label = QLabel('Metric:')
        self.heatmap_metric_combo = QComboBox()
        self.heatmap_metric_combo.setMinimumWidth(200)
        control_layout.addWidget(metric_label)
        control_layout.addWidget(self.heatmap_metric_combo)
        
        # Heat map type selection
        type_label = QLabel('Type:')
        self.heatmap_type_combo = QComboBox()
        self.heatmap_type_combo.addItems(['CPU Cores', 'Metric Correlation', 'Time Distribution'])
        control_layout.addWidget(type_label)
        control_layout.addWidget(self.heatmap_type_combo)
        
        # Generate button
        generate_button = QPushButton('Generate Heat Map')
        generate_button.clicked.connect(self.generate_heatmap)
        control_layout.addWidget(generate_button)
        
        control_layout.addStretch()
        
        # Add control panel to layout
        layout.addWidget(control_panel)
        
        # Figure canvas for the heat map
        self.heatmap_figure = plt.figure(figsize=(10, 8))
        self.heatmap_canvas = FigureCanvas(self.heatmap_figure)
        self.heatmap_canvas.setParent(tab)
        
        # Add matplotlib toolbar
        self.heatmap_toolbar = NavigationToolbar(self.heatmap_canvas, tab)
        
        # Add canvas and toolbar to layout
        layout.addWidget(self.heatmap_toolbar)
        layout.addWidget(self.heatmap_canvas)
        
        # Add tab to main tabs
        self.tabs.addTab(tab, 'Heat Maps')
        
    def create_3d_visualization_tab(self):
        """Create the 3D visualization tab"""
        tab = QWidget()
        layout = QVBoxLayout(tab)
        
        # Control panel
        control_panel = QWidget()
        control_layout = QHBoxLayout(control_panel)
        
        # 3D visualization type
        type_label = QLabel('Type:')
        self.viz_3d_type_combo = QComboBox()
        self.viz_3d_type_combo.addItems(['3D Surface', 'Time Surface', '3D Comparison'])
        self.viz_3d_type_combo.currentIndexChanged.connect(self.update_3d_controls)
        control_layout.addWidget(type_label)
        control_layout.addWidget(self.viz_3d_type_combo)
        
        # Metric selection for X
        x_label = QLabel('X Metric:')
        self.viz_3d_x_combo = QComboBox()
        self.viz_3d_x_combo.setMinimumWidth(150)
        control_layout.addWidget(x_label)
        control_layout.addWidget(self.viz_3d_x_combo)
        
        # Metric selection for Y
        y_label = QLabel('Y Metric:')
        self.viz_3d_y_combo = QComboBox()
        self.viz_3d_y_combo.setMinimumWidth(150)
        control_layout.addWidget(y_label)
        control_layout.addWidget(self.viz_3d_y_combo)
        
        # Metric selection for Z
        z_label = QLabel('Z Metric:')
        self.viz_3d_z_combo = QComboBox()
        self.viz_3d_z_combo.setMinimumWidth(150)
        control_layout.addWidget(z_label)
        control_layout.addWidget(self.viz_3d_z_combo)
        
        # Generate button
        generate_button = QPushButton('Generate 3D Visualization')
        generate_button.clicked.connect(self.generate_3d_visualization)
        control_layout.addWidget(generate_button)
        
        control_layout.addStretch()
        
        # Add control panel to layout
        layout.addWidget(control_panel)
        
        # Figure canvas for the 3D visualization
        self.viz_3d_figure = plt.figure(figsize=(10, 8))
        self.viz_3d_canvas = FigureCanvas(self.viz_3d_figure)
        self.viz_3d_canvas.setParent(tab)
        
        # Add matplotlib toolbar
        self.viz_3d_toolbar = NavigationToolbar(self.viz_3d_canvas, tab)
        
        # Add canvas and toolbar to layout
        layout.addWidget(self.viz_3d_toolbar)
        layout.addWidget(self.viz_3d_canvas)
        
        # Add tab to main tabs
        self.tabs.addTab(tab, '3D Visualizations')
        
    def create_correlation_tab(self):
        """Create the correlation analysis tab"""
        tab = QWidget()
        layout = QVBoxLayout(tab)
        
        # Control panel
        control_panel = QWidget()
        control_layout = QHBoxLayout(control_panel)
        
        # Correlation type
        type_label = QLabel('Analysis:')
        self.corr_type_combo = QComboBox()
        self.corr_type_combo.addItems(['Correlation Matrix', 'Top Correlations'])
        self.corr_type_combo.currentIndexChanged.connect(self.update_correlation_controls)
        control_layout.addWidget(type_label)
        control_layout.addWidget(self.corr_type_combo)
        
        # Target metric for top correlations
        target_label = QLabel('Target Metric:')
        self.corr_target_combo = QComboBox()
        self.corr_target_combo.setMinimumWidth(200)
        control_layout.addWidget(target_label)
        control_layout.addWidget(self.corr_target_combo)
        
        # Number of top correlations
        top_n_label = QLabel('Top N:')
        self.corr_top_n_spin = QSpinBox()
        self.corr_top_n_spin.setRange(1, 20)
        self.corr_top_n_spin.setValue(5)
        control_layout.addWidget(top_n_label)
        control_layout.addWidget(self.corr_top_n_spin)
        
        # Correlation method
        method_label = QLabel('Method:')
        self.corr_method_combo = QComboBox()
        self.corr_method_combo.addItems(['Pearson', 'Spearman'])
        control_layout.addWidget(method_label)
        control_layout.addWidget(self.corr_method_combo)
        
        # Generate button
        generate_button = QPushButton('Generate Correlation Analysis')
        generate_button.clicked.connect(self.generate_correlation)
        control_layout.addWidget(generate_button)
        
        control_layout.addStretch()
        
        # Add control panel to layout
        layout.addWidget(control_panel)
        
        # Figure canvas for the correlation visualization
        self.corr_figure = plt.figure(figsize=(10, 8))
        self.corr_canvas = FigureCanvas(self.corr_figure)
        self.corr_canvas.setParent(tab)
        
        # Add matplotlib toolbar
        self.corr_toolbar = NavigationToolbar(self.corr_canvas, tab)
        
        # Add canvas and toolbar to layout
        layout.addWidget(self.corr_toolbar)
        layout.addWidget(self.corr_canvas)
        
        # Add tab to main tabs
        self.tabs.addTab(tab, 'Correlation Analysis')
        
    def create_trend_analysis_tab(self):
        """Create the trend analysis tab"""
        tab = QWidget()
        layout = QVBoxLayout(tab)
        
        # Control panel
        control_panel = QWidget()
        control_layout = QHBoxLayout(control_panel)
        
        # Metric selection
        metric_label = QLabel('Metric:')
        self.trend_metric_combo = QComboBox()
        self.trend_metric_combo.setMinimumWidth(200)
        control_layout.addWidget(metric_label)
        control_layout.addWidget(self.trend_metric_combo)
        
        # Analysis type
        type_label = QLabel('Analysis:')
        self.trend_type_combo = QComboBox()
        self.trend_type_combo.addItems(['Trend with Rolling Average', 'Daily Comparison'])
        control_layout.addWidget(type_label)
        control_layout.addWidget(self.trend_type_combo)
        
        # Window size for rolling average
        window_label = QLabel('Window Size:')
        self.trend_window_spin = QSpinBox()
        self.trend_window_spin.setRange(2, 100)
        self.trend_window_spin.setValue(10)
        control_layout.addWidget(window_label)
        control_layout.addWidget(self.trend_window_spin)
        
        # Show trend line checkbox
        self.trend_line_check = QCheckBox('Show Trend Line')
        self.trend_line_check.setChecked(True)
        control_layout.addWidget(self.trend_line_check)
        
        # Generate button
        generate_button = QPushButton('Generate Trend Analysis')
        generate_button.clicked.connect(self.generate_trend)
        control_layout.addWidget(generate_button)
        
        control_layout.addStretch()
        
        # Add control panel to layout
        layout.addWidget(control_panel)
        
        # Figure canvas for the trend visualization
        self.trend_figure = plt.figure(figsize=(10, 8))
        self.trend_canvas = FigureCanvas(self.trend_figure)
        self.trend_canvas.setParent(tab)
        
        # Add matplotlib toolbar
        self.trend_toolbar = NavigationToolbar(self.trend_canvas, tab)
        
        # Add canvas and toolbar to layout
        layout.addWidget(self.trend_toolbar)
        layout.addWidget(self.trend_canvas)
        
        # Add tab to main tabs
        self.tabs.addTab(tab, 'Trend Analysis')
        
    def load_data(self):
        """Load data from JSON files"""
        # Open file dialog to select directory
        data_dir = QFileDialog.getExistingDirectory(
            self, 'Select Data Directory', DEFAULT_DATA_DIR,
            QFileDialog.ShowDirsOnly | QFileDialog.DontResolveSymlinks
        )
        
        if data_dir:
            # Update data manager directory
            self.data_manager.data_dir = data_dir
            
            # Load data
            success = self.data_manager.load_data()
            
            if success:
                self.statusBar().showMessage(f'Data loaded successfully from {data_dir}')
                
                # Update metric dropdowns
                self.update_metric_dropdowns()
            else:
                self.statusBar().showMessage('Failed to load data')
                QMessageBox.warning(self, 'Data Load Error', 
                                  'Failed to load monitoring data from the selected directory.')
    
    def update_metric_dropdowns(self):
        """Update all metric selection dropdowns with available metrics"""
        metrics = self.data_manager.get_metric_names()
        
        # Update heat map metric dropdown
        self.heatmap_metric_combo.clear()
        self.heatmap_metric_combo.addItems(metrics)
        
        # Update 3D visualization dropdowns
        self.viz_3d_x_combo.clear()
        self.viz_3d_y_combo.clear()
        self.viz_3d_z_combo.clear()
        
        self.viz_3d_x_combo.addItems(metrics)
        self.viz_3d_y_combo.addItems(metrics)
        self.viz_3d_z_combo.addItems(metrics)
        
        # Try to select different metrics for x, y, z if possible
        if len(metrics) >= 3:
            self.viz_3d_x_combo.setCurrentIndex(0)
            self.viz_3d_y_combo.setCurrentIndex(1)
            self.viz_3d_z_combo.setCurrentIndex(2)
        
        # Update correlation target dropdown
        self.corr_target_combo.clear()
        self.corr_target_combo.addItems(metrics)
        
        # Update trend metric dropdown
        self.trend_metric_combo.clear()
        self.trend_metric_combo.addItems(metrics)
        
        # Update controls based on visualization type
        self.update_3d_controls()
        self.update_correlation_controls()
    
    def update_3d_controls(self):
        """Update 3D visualization controls based on selected type"""
        viz_type = self.viz_3d_type_combo.currentText()
        
        if viz_type == '3D Surface':
            # Show all metric selections
            self.viz_3d_x_combo.setEnabled(True)
            self.viz_3d_y_combo.setEnabled(True)
            self.viz_3d_z_combo.setEnabled(True)
        elif viz_type == 'Time Surface':
            # Only need Z metric, X and Y are time dimensions
            self.viz_3d_x_combo.setEnabled(False)
            self.viz_3d_y_combo.setEnabled(False)
            self.viz_3d_z_combo.setEnabled(True)
        elif viz_type == '3D Comparison':
            # Only need to select multiple metrics for comparison
            self.viz_3d_x_combo.setEnabled(False)
            self.viz_3d_y_combo.setEnabled(False)
            self.viz_3d_z_combo.setEnabled(True)
    
    def update_correlation_controls(self):
        """Update correlation controls based on selected analysis type"""
        corr_type = self.corr_type_combo.currentText()
        
        if corr_type == 'Correlation Matrix':
            # Don't need target metric or top N for matrix
            self.corr_target_combo.setEnabled(False)
            self.corr_top_n_spin.setEnabled(False)
        elif corr_type == 'Top Correlations':
            # Need target metric and top N for top correlations
            self.corr_target_combo.setEnabled(True)
            self.corr_top_n_spin.setEnabled(True)
    
    def generate_heatmap(self):
        """Generate and display heat map visualization"""
        if self.data_manager.metrics_data is None:
            self.statusBar().showMessage('No data loaded')
            return
            
        # Clear previous figure
        self.heatmap_figure.clear()
        
        # Get selected options
        heatmap_type = self.heatmap_type_combo.currentText()
        metric = self.heatmap_metric_combo.currentText()
        
        # Create appropriate heat map
        ax = self.heatmap_figure.add_subplot(111)
        
        if heatmap_type == 'CPU Cores':
            _, _ = self.heat_map_visualizer.create_cpu_heatmap(
                figure=self.heatmap_figure, ax=ax)
        elif heatmap_type == 'Metric Correlation':
            _, _ = self.heat_map_visualizer.create_metric_heatmap(
                figure=self.heatmap_figure, ax=ax)
        elif heatmap_type == 'Time Distribution':
            _, _ = self.heat_map_visualizer.create_time_distribution_heatmap(
                metric, figure=self.heatmap_figure, ax=ax)
        
        # Refresh canvas
        self.heatmap_canvas.draw()
        
        self.statusBar().showMessage(f'Generated {heatmap_type} heat map')
    
    def generate_3d_visualization(self):
        """Generate and display 3D visualization"""
        if self.data_manager.metrics_data is None:
            self.statusBar().showMessage('No data loaded')
            return
            
        # Clear previous figure
        self.viz_3d_figure.clear()
        
        # Get selected options
        viz_type = self.viz_3d_type_combo.currentText()
        x_metric = self.viz_3d_x_combo.currentText()
        y_metric = self.viz_3d_y_combo.currentText()
        z_metric = self.viz_3d_z_combo.currentText()
        
        # Create appropriate 3D visualization
        if viz_type == '3D Surface':
            ax = self.viz_3d_figure.add_subplot(111, projection='3d')
            _, _ = self.three_d_visualizer.create_3d_surface(
                x_metric, y_metric, z_metric, figure=self.viz_3d_figure, ax=ax)
        elif viz_type == 'Time Surface':
            ax = self.viz_3d_figure.add_subplot(111, projection='3d')
            _, _ = self.three_d_visualizer.create_3d_time_surface(
                z_metric, figure=self.viz_3d_figure, ax=ax)
        elif viz_type == '3D Comparison':
            ax = self.viz_3d_figure.add_subplot(111, projection='3d')
            
            # Use all available metrics for comparison
            metrics = self.data_manager.get_metric_names()
            # Limit to top 5 most variable metrics
            if len(metrics) > 5:
                numeric_cols = self.data_manager.metrics_data.select_dtypes(
                    include=[np.number]).columns
                variances = self.data_manager.metrics_data[numeric_cols].var()
                metrics = variances.nlargest(5).index.tolist()
                
            _, _ = self.three_d_visualizer.create_3d_comparison(
                metrics, figure=self.viz_3d_figure, ax=ax)
        
        # Refresh canvas
        self.viz_3d_canvas.draw()
        
        self.statusBar().showMessage(f'Generated {viz_type} visualization')
    
    def generate_correlation(self):
        """Generate and display correlation analysis"""
        if self.data_manager.metrics_data is None:
            self.statusBar().showMessage('No data loaded')
            return
            
        # Clear previous figure
        self.corr_figure.clear()
        
        # Get selected options
        corr_type = self.corr_type_combo.currentText()
        target_metric = self.corr_target_combo.currentText()
        top_n = self.corr_top_n_spin.value()
        method = self.corr_method_combo.currentText().lower()
        
        # Create appropriate correlation visualization
        ax = self.corr_figure.add_subplot(111)
        
        if corr_type == 'Correlation Matrix':
            _, _ = self.correlation_analyzer.plot_correlation_matrix(
                method=method, figure=self.corr_figure, ax=ax)
        elif corr_type == 'Top Correlations':
            _, _ = self.correlation_analyzer.plot_top_correlations(
                target_metric, n=top_n, method=method, figure=self.corr_figure, ax=ax)
        
        # Refresh canvas
        self.corr_canvas.draw()
        
        self.statusBar().showMessage(f'Generated {corr_type} analysis')
    
    def generate_trend(self):
        """Generate and display trend analysis"""
        if self.data_manager.metrics_data is None:
            self.statusBar().showMessage('No data loaded')
            return
            
        # Clear previous figure
        self.trend_figure.clear()
        
        # Get selected options
        metric = self.trend_metric_combo.currentText()
        trend_type = self.trend_type_combo.currentText()
        window = self.trend_window_spin.value()
        show_trend_line = self.trend_line_check.isChecked()
        
        # Create appropriate trend visualization
        ax = self.trend_figure.add_subplot(111)
        
        if trend_type == 'Trend with Rolling Average':
            _, _ = self.trend_analyzer.plot_trend(
                metric, window=window, show_trend_line=show_trend_line, 
                figure=self.trend_figure, ax=ax)
        elif trend_type == 'Daily Comparison':
            _, _ = self.trend_analyzer.plot_daily_comparison(
                metric, figure=self.trend_figure, ax=ax)
        
        # Refresh canvas
        self.trend_canvas.draw()
        
        self.statusBar().showMessage(f'Generated {trend_type} analysis for {metric}')
    
    def export_data(self):
        """Export processed data to file"""
        if self.data_manager.metrics_data is None:
            self.statusBar().showMessage('No data loaded')
            return
            
        # Open file dialog to select save location
        file_filter = "CSV Files (*.csv);;Excel Files (*.xlsx);;JSON Files (*.json)"
        file_path, selected_filter = QFileDialog.getSaveFileName(
            self, 'Export Data', '', file_filter)
        
        if file_path:
            # Determine format from selected filter
            if 'CSV' in selected_filter:
                format = 'csv'
            elif 'Excel' in selected_filter:
                format = 'excel'
            elif 'JSON' in selected_filter:
                format = 'json'
            else:
                format = 'csv'  # Default
                
            # Export data
            success = self.data_manager.export_data(file_path, format)
            
            if success:
                self.statusBar().showMessage(f'Data exported to {file_path}')
            else:
                self.statusBar().showMessage('Failed to export data')
    
    def take_screenshot(self):
        """Take screenshot of current visualization"""
        # Determine current tab and canvas
        current_tab = self.tabs.currentIndex()
        
        if current_tab == 0:  # Heat Map tab
            canvas = self.heatmap_canvas
            prefix = "heatmap"
        elif current_tab == 1:  # 3D Visualization tab
            canvas = self.viz_3d_canvas
            prefix = "3d_viz"
        elif current_tab == 2:  # Correlation tab
            canvas = self.corr_canvas
            prefix = "correlation"
        elif current_tab == 3:  # Trend Analysis tab
            canvas = self.trend_canvas
            prefix = "trend"
        else:
            self.statusBar().showMessage('No visualization to capture')
            return
            
        # Generate filename with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        default_filename = f"{prefix}_{timestamp}.png"
        
        # Open file dialog to select save location
        file_filter = "PNG Files (*.png);;JPG Files (*.jpg);;PDF Files (*.pdf)"
        file_path, selected_filter = QFileDialog.getSaveFileName(
            self, 'Save Screenshot', default_filename, file_filter)
        
        if file_path:
            # Save figure
            figure = canvas.figure
            figure.savefig(file_path, dpi=150, bbox_inches='tight')
            
            self.statusBar().showMessage(f'Screenshot saved to {file_path}')
    
    def toggle_theme(self):
        """Toggle between dark and light theme"""
        dark_mode = self.dark_mode_action.isChecked()
        self.apply_theme(dark_mode)
    
    def apply_theme(self, dark_mode=True):
        """Apply dark or light theme to the application"""
        if dark_mode:
            # Set dark palette
            palette = QPalette()
            palette.setColor(QPalette.Window, QColor(53, 53, 53))
            palette.setColor(QPalette.WindowText, Qt.white)
            palette.setColor(QPalette.Base, QColor(25, 25, 25))
            palette.setColor(QPalette.AlternateBase, QColor(53, 53, 53))
            palette.setColor(QPalette.ToolTipBase, Qt.white)
            palette.setColor(QPalette.ToolTipText, Qt.white)
            palette.setColor(QPalette.Text, Qt.white)
            palette.setColor(QPalette.Button, QColor(53, 53, 53))
            palette.setColor(QPalette.ButtonText, Qt.white)
            palette.setColor(QPalette.BrightText, Qt.red)
            palette.setColor(QPalette.Link, QColor(42, 130, 218))
            palette.setColor(QPalette.Highlight, QColor(42, 130, 218))
            palette.setColor(QPalette.HighlightedText, Qt.black)
            
            self.setPalette(palette)
            
            # Set matplotlib style
            plt.style.use('dark_background')
            sns.set_style("darkgrid")
        else:
            # Set light palette (system default)
            self.setPalette(QApplication.style().standardPalette())
            
            # Set matplotlib style
            plt.style.use('default')
            sns.set_style("whitegrid")
        
        # Redraw all canvases
        self.heatmap_canvas.draw()
        self.viz_3d_canvas.draw()
        self.corr_canvas.draw()
        self.trend_canvas.draw()


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='HyprSupreme Advanced Visualization Tools')
    parser.add_argument('--data-dir', default=DEFAULT_DATA_DIR,
                      help='Directory containing monitoring data files')
    parser.add_argument('--config', default=DEFAULT_CONFIG_FILE,
                      help='Configuration file path')
    parser.add_argument('--theme', default=DEFAULT_THEME, choices=['dark', 'light'],
                      help='UI theme (dark or light)')
    parser.add_argument('--log-file', default=DEFAULT_LOG_FILE,
                      help='Log file path')
    
    return parser.parse_args()


def main():
    """Main entry point"""
    # Parse command line arguments
    args = parse_arguments()
    
    # Initialize Qt application
    app = QApplication(sys.argv)
    
    # Set application info
    app.setApplicationName("HyprSupreme Advanced Visualization Tools")
    app.setOrganizationName("HyprSupreme")
    
    # Create and show main window
    main_window = VisualizationApp()
    main_window.show()
    
    # Set theme based on arguments
    main_window.apply_theme(args.theme == 'dark')
    main_window.dark_mode_action.setChecked(args.theme == 'dark')
    
    # Run application
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
