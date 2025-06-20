#!/usr/bin/env python3
"""
HyprSupreme-Builder Monitoring Dashboard
Interactive system monitoring dashboard with real-time metrics visualization
"""

import sys
import os
import time
import signal
import subprocess
import threading
import re
import argparse
import json
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any
from collections import deque
import psutil

# PyQt5 imports for GUI
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QTableWidget, QTableWidgetItem, QTabWidget, QProgressBar,
    QGroupBox, QGridLayout, QFrame, QSplitter, QComboBox, QCheckBox,
    QHeaderView, QMenu, QAction, QToolBar, QStatusBar, QFileDialog,
    QMessageBox, QScrollArea, QSizePolicy
)
from PyQt5.QtCore import Qt, QTimer, pyqtSignal, QThread, QSize, QDateTime
from PyQt5.QtGui import QColor, QPainter, QIcon, QFont, QPalette

# Matplotlib for plots
import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import matplotlib.pyplot as plt
import numpy as np

# Constants for configuration
CONFIG_DIR = os.path.expanduser("~/.config/hyprsupreme/")
CACHE_DIR = os.path.expanduser("~/.cache/hyprsupreme/")
LOG_DIR = os.path.expanduser("~/.local/share/hyprsupreme/logs/")

# Create directories if they don't exist
for directory in [CONFIG_DIR, CACHE_DIR, LOG_DIR]:
    os.makedirs(directory, exist_ok=True)

# Threshold constants
CPU_WARNING_THRESHOLD = 80
CPU_CRITICAL_THRESHOLD = 90
MEMORY_WARNING_THRESHOLD = 75
MEMORY_CRITICAL_THRESHOLD = 85
DISK_WARNING_THRESHOLD = 75
DISK_CRITICAL_THRESHOLD = 85
NETWORK_WARNING_THRESHOLD = 50 * 1024 * 1024  # 50MB/s

# Cache for process names to avoid repeated syscalls
PROCESS_NAME_CACHE = {}

# Color schemes
COLORS = {
    "cpu": "#3498db",
    "memory": "#e74c3c",
    "disk": "#2ecc71",
    "network_up": "#9b59b6",
    "network_down": "#f39c12",
    "normal": "#2ecc71",
    "warning": "#f39c12",
    "critical": "#e74c3c",
    "background": "#2c3e50",
    "text": "#ecf0f1",
    "grid": "#34495e"
}

class TimeSeriesPlot(FigureCanvas):
    """Canvas for time series plots with real-time updates"""
    
    def __init__(self, title: str, y_label: str, time_window: int = 60, parent=None):
        """
        Initialize the time series plot
        
        Args:
            title: Title of the plot
            y_label: Label for Y axis
            time_window: Time window in seconds
            parent: Parent widget
        """
        # Set up the figure with dark theme
        plt.style.use('dark_background')
        self.fig = Figure(figsize=(5, 3), dpi=100)
        self.fig.patch.set_facecolor(COLORS["background"])
        
        super(TimeSeriesPlot, self).__init__(self.fig)
        self.setParent(parent)
        
        # Configure the axes
        self.axes = self.fig.add_subplot(111)
        self.axes.set_facecolor(COLORS["background"])
        self.axes.tick_params(colors=COLORS["text"])
        self.axes.set_title(title, color=COLORS["text"])
        self.axes.set_xlabel("Time (s)", color=COLORS["text"])
        self.axes.set_ylabel(y_label, color=COLORS["text"])
        self.axes.grid(True, color=COLORS["grid"], linestyle='-', linewidth=0.5, alpha=0.5)
        
        # Data containers
        self.time_window = time_window
        self.time_data = deque(maxlen=time_window)
        self.y_data = {}
        self.lines = {}
        
        # Set up the plot
        self.fig.tight_layout()
        self.setMinimumHeight(200)
        
    def add_series(self, name: str, color: str) -> None:
        """
        Add a new data series to the plot
        
        Args:
            name: Name of the data series
            color: Color for the line
        """
        self.y_data[name] = deque(maxlen=self.time_window)
        line, = self.axes.plot([], [], lw=2, color=color, label=name)
        self.lines[name] = line
        self.axes.legend(loc='upper left')
        
    def update_data(self, timestamp: float, values: Dict[str, float]) -> None:
        """
        Update plot with new data
        
        Args:
            timestamp: Current timestamp
            values: Dictionary mapping series names to values
        """
        if not self.time_data:
            # First data point, initialize time_data
            self.time_data.append(0)
            for name in values:
                if name in self.y_data:
                    self.y_data[name].append(values[name])
        else:
            # Calculate relative time for x-axis
            rel_time = timestamp - (timestamp - len(self.time_data) + 1)
            self.time_data.append(rel_time)
            
            # Update each data series
            for name, value in values.items():
                if name in self.y_data:
                    self.y_data[name].append(value)
        
        # Update plot lines
        for name, line in self.lines.items():
            if name in self.y_data:
                line.set_data(list(self.time_data), list(self.y_data[name]))
        
        # Adjust axes limits
        self.axes.relim()
        self.axes.autoscale_view()
        
        # Redraw the canvas
        self.draw()


class SystemMetricsCollector(QThread):
    """Thread for collecting system metrics in the background"""
    
    # Signal emitted when new metrics are available
    metrics_updated = pyqtSignal(dict)
    
    def __init__(self, interval: float = 1.0, parent=None):
        """
        Initialize the metrics collector
        
        Args:
            interval: Polling interval in seconds
            parent: Parent object
        """
        super(SystemMetricsCollector, self).__init__(parent)
        self.interval = interval
        self.running = False
        
        # Initialize network counters
        self.last_net_io = psutil.net_io_counters()
        self.last_net_time = time.time()
        
        # Process filter for HyprSupreme components
        self.process_filters = [
            "hypr", "waybar", "rofi", "hyprsupreme", "kitty", "ags"
        ]
        
    def run(self) -> None:
        """Main collection loop"""
        self.running = True
        
        while self.running:
            start_time = time.time()
            
            try:
                # Collect metrics
                metrics = self.collect_metrics()
                
                # Emit the signal with collected metrics
                self.metrics_updated.emit(metrics)
                
            except Exception as e:
                print(f"Error collecting metrics: {e}")
                
            # Sleep for the remaining time to maintain the interval
            elapsed = time.time() - start_time
            sleep_time = max(0, self.interval - elapsed)
            time.sleep(sleep_time)
    
    def stop(self) -> None:
        """Stop the collection thread"""
        self.running = False
        self.wait()
        
    def collect_metrics(self) -> Dict[str, Any]:
        """
        Collect system metrics
        
        Returns:
            Dictionary containing all system metrics
        """
        metrics = {
            "timestamp": time.time(),
            "cpu": {},
            "memory": {},
            "disk": {},
            "network": {},
            "processes": []
        }
        
        # CPU metrics
        cpu_percent = psutil.cpu_percent(interval=None)
        cpu_count = psutil.cpu_count()
        cpu_freq = psutil.cpu_freq()
        cpu_freqs = cpu_freq.current if cpu_freq else 0
        
        metrics["cpu"] = {
            "percent": cpu_percent,
            "count": cpu_count,
            "freq_mhz": cpu_freqs,
            "per_cpu": psutil.cpu_percent(interval=None, percpu=True),
            "status": self.get_status(cpu_percent, CPU_WARNING_THRESHOLD, CPU_CRITICAL_THRESHOLD)
        }
        
        # Memory metrics
        mem = psutil.virtual_memory()
        metrics["memory"] = {
            "total": mem.total,
            "available": mem.available,
            "used": mem.used,
            "percent": mem.percent,
            "status": self.get_status(mem.percent, MEMORY_WARNING_THRESHOLD, MEMORY_CRITICAL_THRESHOLD)
        }
        
        # Disk metrics
        disk = psutil.disk_usage('/')
        disk_io = psutil.disk_io_counters()
        metrics["disk"] = {
            "total": disk.total,
            "used": disk.used,
            "free": disk.free,
            "percent": disk.percent,
            "read_bytes": disk_io.read_bytes if disk_io else 0,
            "write_bytes": disk_io.write_bytes if disk_io else 0,
            "status": self.get_status(disk.percent, DISK_WARNING_THRESHOLD, DISK_CRITICAL_THRESHOLD)
        }
        
        # Network metrics
        current_net_io = psutil.net_io_counters()
        current_time = time.time()
        
        # Calculate network speeds
        time_diff = current_time - self.last_net_time
        if time_diff > 0:
            rx_speed = (current_net_io.bytes_recv - self.last_net_io.bytes_recv) / time_diff
            tx_speed = (current_net_io.bytes_sent - self.last_net_io.bytes_sent) / time_diff
        else:
            rx_speed = 0
            tx_speed = 0
            
        metrics["network"] = {
            "bytes_sent": current_net_io.bytes_sent,
            "bytes_recv": current_net_io.bytes_recv,
            "packets_sent": current_net_io.packets_sent,
            "packets_recv": current_net_io.packets_recv,
            "tx_speed": tx_speed,
            "rx_speed": rx_speed,
            "status": self.get_status(max(rx_speed, tx_speed), 
                                     NETWORK_WARNING_THRESHOLD * 0.5, 
                                     NETWORK_WARNING_THRESHOLD)
        }
        
        # Update network counters for next calculation
        self.last_net_io = current_net_io
        self.last_net_time = current_time
        
        # Process metrics (focus on HyprSupreme processes)
        for proc in psutil.process_iter(['pid', 'name', 'username', 'cpu_percent', 'memory_percent']):
            try:
                proc_info = proc.info
                proc_name = proc_info['name']
                
                # Filter for HyprSupreme related processes
                if any(filter_term in proc_name.lower() for filter_term in self.process_filters):
                    # Get process command line for better identification
                    try:
                        cmdline = " ".join(proc.cmdline())
                    except (psutil.NoSuchProcess, psutil.AccessDenied):
                        cmdline = proc_name
                        
                    # Calculate process status
                    cpu_status = self.get_status(proc_info['cpu_percent'] / cpu_count, 
                                              CPU_WARNING_THRESHOLD, 
                                              CPU_CRITICAL_THRESHOLD)
                    mem_status = self.get_status(proc_info['memory_percent'], 
                                              MEMORY_WARNING_THRESHOLD, 
                                              MEMORY_CRITICAL_THRESHOLD)
                                              
                    # Get the "worst" status
                    if cpu_status == "critical" or mem_status == "critical":
                        status = "critical"
                    elif cpu_status == "warning" or mem_status == "warning":
                        status = "warning"
                    else:
                        status = "normal"
                        
                    metrics["processes"].append({
                        "pid": proc_info['pid'],
                        "name": proc_name,
                        "cmdline": cmdline,
                        "username": proc_info['username'],
                        "cpu_percent": proc_info['cpu_percent'],
                        "memory_percent": proc_info['memory_percent'],
                        "status": status
                    })
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
                
        # Sort processes by CPU usage (descending)
        metrics["processes"].sort(key=lambda x: x["cpu_percent"], reverse=True)
        
        return metrics
        
    def get_status(self, value: float, warning_threshold: float, critical_threshold: float) -> str:
        """
        Determine the status level based on thresholds
        
        Args:
            value: The metric value to check
            warning_threshold: Threshold for warning level
            critical_threshold: Threshold for critical level
            
        Returns:
            Status string: "normal", "warning", or "critical"
        """
        if value >= critical_threshold:
            return "critical"
        elif value >= warning_threshold:
            return "warning"
        else:
            return "normal"


class ProcessMonitorWidget(QWidget):
    """Widget for displaying and monitoring processes"""
    
    def __init__(self, parent=None):
        super(ProcessMonitorWidget, self).__init__(parent)
        
        # Set up the layout
        layout = QVBoxLayout(self)
        
        # Create the process table
        self.process_table = QTableWidget()
        self.process_table.setColumnCount(5)
        self.process_table.setHorizontalHeaderLabels(["PID", "Name", "CPU %", "Memory %", "User"])
        self.process_table.setSelectionBehavior(QTableWidget.SelectRows)
        self.process_table.setSortingEnabled(True)
        self.process_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        
        # Set up table styling
        self.process_table.setShowGrid(True)
        self.process_table.setAlternatingRowColors(True)
        
        # Add table to layout
        layout.addWidget(self.process_table)
        
        # Context menu for additional options
        self.process_table.setContextMenuPolicy(Qt.CustomContextMenu)
        self.process_table.customContextMenuRequested.connect(self.show_context_menu)
        
    def update_processes(self, processes: List[Dict[str, Any]]) -> None:
        """
        Update the process table with new data
        
        Args:
            processes: List of process information dictionaries
        """
        # Set the row count to match the number of processes
        self.process_table.setRowCount(len(processes))
        
        # Fill the table with process information
        for row, proc in enumerate(processes):
            # Set PID
            pid_item = QTableWidgetItem(str(proc["pid"]))
            pid_item.setTextAlignment(Qt.AlignCenter)
            self.process_table.setItem(row, 0, pid_item)
            
            # Set Name
            name_item = QTableWidgetItem(proc["name"])
            self.process_table.setItem(row, 1, name_item)
            
            # Set CPU %
            cpu_item = QTableWidgetItem(f"{proc['cpu_percent']:.1f}")
            cpu_item.setTextAlignment(Qt.AlignCenter)
            self.process_table.setItem(row, 2, cpu_item)
            
            # Set Memory %
            mem_item = QTableWidgetItem(f"{proc['memory_percent']:.1f}")
            mem_item.setTextAlignment(Qt.AlignCenter)
            self.process_table.setItem(row, 3, mem_item)
            
            # Set Username
            user_item = QTableWidgetItem(proc["username"])
            self.process_table.setItem(row, 4, user_item)
            
            # Set row color based on status
            self.color_row(row, proc["status"])
            
    def color_row(self, row: int, status: str) -> None:
        """
        Set the background color of a row based on status
        
        Args:
            row: Row index
            status: Status string ("normal", "warning", or "critical")
        """
        if status == "critical":
            color = QColor(COLORS["critical"])
            color.setAlpha(100)  # semi-transparent
        elif status == "warning":
            color = QColor(COLORS["warning"])
            color.setAlpha(80)  # semi-transparent
        else:
            return  # Leave normal rows with default color
            
        for col in range(self.process_table.columnCount()):
            item = self.process_table.item(row, col)
            if item:
                item.setBackground(color)
                
    def show_context_menu(self, position) -> None:
        """
        Show context menu for process operations
        
        Args:
            position: Position where to show the menu
        """
        menu = QMenu()
        menu.addAction("Process Details", self.show_process_details)
        menu.addSeparator()
        menu.addAction("Kill Process", self.kill_process)
        
        menu.exec_(self.process_table.viewport().mapToGlobal(position))
        
    def show_process_details(self) -> None:
        """Show detailed information about the selected process"""
        selected_rows = self.process_table.selectedIndexes()
        if not selected_rows:
            return
            
        row = selected_rows[0].row()
        pid = int(self.process_table.item(row, 0).text())
        
        try:
            process = psutil.Process(pid)
            details = {
                "Name": process.name(),
                "PID": pid,
                "Status": process.status(),
                "Created": datetime.fromtimestamp(process.create_time()).strftime('%Y-%m-%d %H:%M:%S'),
                "CPU %": f"{process.cpu_percent(interval=0.1):.1f}",
                "Memory %": f"{process.memory_percent():.1f}",
                "Memory Info": {k: self._format_bytes(v) for k, v in process.memory_info()._asdict().items()},
                "Threads": process.num_threads(),
                "Command Line": " ".join(process.cmdline()),
                "Executable": process.exe(),
                "Working Directory": process.cwd(),
                "Username": process.username(),
            }
            
            # Format the details as text
            details_text = "Process Details:\n\n"
            for key, value in details.items():
                if isinstance(value, dict):
                    details_text += f"{key}:\n"
                    for subkey, subvalue in value.items():
                        details_text += f"  {subkey}: {subvalue}\n"
                else:
                    details_text += f"{key}: {value}\n"
                    
            # Show the details in a message box
            QMessageBox.information(self, "Process Details", details_text)
            
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            QMessageBox.warning(self, "Error", "Process details not available")
            
    def kill_process(self) -> None:
        """Kill the selected process"""
        selected_rows = self.process_table.selectedIndexes()
        if not selected_rows:
            return
            
        row = selected_rows[0].row()
        pid = int(self.process_table.item(row, 0).text())
        process_name = self.process_table.item(row, 1).text()
        
        # Confirm before killing
        reply = QMessageBox.question(
            self, 
            "Kill Process", 
            f"Are you sure you want to kill '{process_name}' (PID: {pid})?",
            QMessageBox.Yes | QMessageBox.No, 
            QMessageBox.No
        )
        
        if reply == QMessageBox.Yes:
            try:
                process = psutil.Process(pid)
                process.kill()
                QMessageBox.information(self, "Success", f"Process {process_name} (PID: {pid}) has been terminated.")
            except (psutil.NoSuchProcess, psutil.AccessDenied) as e:
                QMessageBox.warning(self, "Error", f"Failed to kill process: {str(e)}")
                
    def _format_bytes(self, bytes: int) -> str:
        """
        Format bytes to human-readable format
        
        Args:
            bytes: Size in bytes
            
        Returns:
            Formatted string with appropriate unit
        """
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes < 1024:
                return f"{bytes:.2f} {unit}"
            bytes /= 1024
        return f"{bytes:.2f} PB"


class StatusIndicator(QFrame):
    """Custom widget for showing status indicators"""
    
    def __init__(self, parent=None):
        super(StatusIndicator, self).__init__(parent)
        
        # Set up widget properties
        self.setMinimumSize(15, 15)
        self.setMaximumSize(15, 15)
        self.status = "normal"
        
    def set_status(self, status: str) -> None:
        """
        Set the status indicator color
        
        Args:
            status: Status string ("normal", "warning", or "critical")
        """
        self.status = status
        self.update()
        
    def paintEvent(self, event) -> None:
        """Custom paint event to draw the status indicator"""
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        
        # Set the color based on status
        if self.status == "critical":
            color = QColor(COLORS["critical"])
        elif self.status == "warning":
            color = QColor(COLORS["warning"])
        else:
            color = QColor(COLORS["normal"])
            
        # Draw a filled circle
        painter.setBrush(color)
        painter.setPen(Qt.NoPen)
        painter.drawEllipse(2, 2, 11, 11)


class SystemStatusWidget(QWidget):
    """Widget for displaying overall system status"""
    
    def __init__(self, parent=None):
        super(SystemStatusWidget, self).__init__(parent)
        
        # Set up the layout
        layout = QGridLayout(self)
        
        # CPU status
        layout.addWidget(QLabel("CPU:"), 0, 0)
        self.cpu_indicator = StatusIndicator()
        layout.addWidget(self.cpu_indicator, 0, 1)
        self.cpu_label = QLabel("0.0%")
        layout.addWidget(self.cpu_label, 0, 2)
        self.cpu_bar = QProgressBar()
        self.cpu_bar.setRange(0, 100)
        layout.addWidget(self.cpu_bar, 0, 3)
        
        # Memory status
        layout.addWidget(QLabel("Memory:"), 1, 0)
        self.memory_indicator = StatusIndicator()
        layout.addWidget(self.memory_indicator, 1, 1)
        self.memory_label = QLabel("0.0%")
        layout.addWidget(self.memory_label, 1, 2)
        self.memory_bar = QProgressBar()
        self.memory_bar.setRange(0, 100)
        layout.addWidget(self.memory_bar, 1, 3)
        
        # Disk status
        layout.addWidget(QLabel("Disk:"), 2, 0)
        self.disk_indicator = StatusIndicator()
        layout.addWidget(self.disk_indicator, 2, 1)
        self.disk_label = QLabel("0.0%")
        layout.addWidget(self.disk_label, 2, 2)
        self.disk_bar = QProgressBar()
        self.disk_bar.setRange(0, 100)
        layout.addWidget(self.disk_bar, 2, 3)
        
        # Network status
        layout.addWidget(QLabel("Network:"), 3, 0)
        self.network_indicator = StatusIndicator()
        layout.addWidget(self.network_indicator, 3, 1)
        self.network_label = QLabel("↑ 0.0 KB/s  ↓ 0.0 KB/s")
        layout.addWidget(self.network_label, 3, 2, 1, 2)
        
        # Set up widget styling
        for bar in [self.cpu_bar, self.memory_bar, self.disk_bar]:
            bar.setTextVisible(True)
            
    def update_status(self, metrics: Dict[str, Any]) -> None:
        """
        Update the status indicators with new metrics
        
        Args:
            metrics: Dictionary containing system metrics
        """
        # Update CPU
        cpu_percent = metrics["cpu"]["percent"]
        self.cpu_indicator.set_status(metrics["cpu"]["status"])
        self.cpu_label.setText(f"{cpu_percent:.1f}%")
        self.cpu_bar.setValue(int(cpu_percent))
        self.set_bar_color(self.cpu_bar, metrics["cpu"]["status"])
        
        # Update Memory
        memory_percent = metrics["memory"]["percent"]
        self.memory_indicator.set_status(metrics["memory"]["status"])
        self.memory_label.setText(f"{memory_percent:.1f}%")
        self.memory_bar.setValue(int(memory_percent))
        self.set_bar_color(self.memory_bar, metrics["memory"]["status"])
        
        # Update Disk
        disk_percent = metrics["disk"]["percent"]
        self.disk_indicator.set_status(metrics["disk"]["status"])
        self.disk_label.setText(f"{disk_percent:.1f}%")
        self.disk_bar.setValue(int(disk_percent))
        self.set_bar_color(self.disk_bar, metrics["disk"]["status"])
        
        # Update Network
        tx_speed = self._format_network_speed(metrics["network"]["tx_speed"])
        rx_speed = self._format_network_speed(metrics["network"]["rx_speed"])
        self.network_indicator.set_status(metrics["network"]["status"])
        self.network_label.setText(f"↑ {tx_speed}  ↓ {rx_speed}")
        
    def set_bar_color(self, bar: QProgressBar, status: str) -> None:
        """
        Set progress bar color based on status
        
        Args:
            bar: Progress bar to update
            status: Status string ("normal", "warning", or "critical")
        """
        style = ""
        if status == "critical":
            style = f"QProgressBar::chunk {{ background-color: {COLORS['critical']}; }}"
        elif status == "warning":
            style = f"QProgressBar::chunk {{ background-color: {COLORS['warning']}; }}"
        else:
            style = f"QProgressBar::chunk {{ background-color: {COLORS['normal']}; }}"
            
        bar.setStyleSheet(style)
        
    def _format_network_speed(self, bytes_per_sec: float) -> str:
        """
        Format network speed to human-readable format
        
        Args:
            bytes_per_sec: Speed in bytes per second
            
        Returns:
            Formatted speed string with appropriate unit
        """
        if bytes_per_sec < 1024:
            return f"{bytes_per_sec:.1f} B/s"
        elif bytes_per_sec < 1024*1024:
            return f"{bytes_per_sec/1024:.1f} KB/s"
        elif bytes_per_sec < 1024*1024*1024:
            return f"{bytes_per_sec/(1024*1024):.1f} MB/s"
        else:
            return f"{bytes_per_sec/(1024*1024*1024):.1f} GB/s"


class MonitoringDashboard(QMainWindow):
    """Main application window for the monitoring dashboard"""
    
    def __init__(self):
        super(MonitoringDashboard, self).__init__()
        
        # Window setup
        self.setWindowTitle("HyprSupreme Monitoring Dashboard")
        self.setMinimumSize(800, 600)
        
        # Create central widget and main layout
        central_widget = QWidget()
        main_layout = QVBoxLayout(central_widget)
        
        # Create the header
        header_layout = QHBoxLayout()
        title_label = QLabel("HyprSupreme Monitoring Dashboard")
        title_label.setStyleSheet("font-size: 18px; font-weight: bold;")
        header_layout.addWidget(title_label)
        
        # Add system overview to header
        self.system_status = SystemStatusWidget()
        header_layout.addWidget(self.system_status)
        
        # Add header to main layout
        main_layout.addLayout(header_layout)
        
        # Create tabs for different sections
        self.tabs = QTabWidget()
        
        # Overview tab
        overview_tab = QWidget()
        overview_layout = QVBoxLayout(overview_tab)
        
        # System metrics charts
        charts_layout = QGridLayout()
        
        # CPU usage chart
        self.cpu_chart = TimeSeriesPlot("CPU Usage", "Percent (%)")
        self.cpu_chart.add_series("CPU", COLORS["cpu"])
        charts_layout.addWidget(self.cpu_chart, 0, 0)
        
        # Memory usage chart
        self.memory_chart = TimeSeriesPlot("Memory Usage", "Percent (%)")
        self.memory_chart.add_series("Memory", COLORS["memory"])
        charts_layout.addWidget(self.memory_chart, 0, 1)
        
        # Disk usage chart
        self.disk_chart = TimeSeriesPlot("Disk I/O", "MB/s")
        self.disk_chart.add_series("Read", COLORS["network_down"])
        self.disk_chart.add_series("Write", COLORS["network_up"])
        charts_layout.addWidget(self.disk_chart, 1, 0)
        
        # Network usage chart
        self.network_chart = TimeSeriesPlot("Network Traffic", "MB/s")
        self.network_chart.add_series("Download", COLORS["network_down"])
        self.network_chart.add_series("Upload", COLORS["network_up"])
        charts_layout.addWidget(self.network_chart, 1, 1)
        
        overview_layout.addLayout(charts_layout)
        
        # Add process monitor to overview
        self.process_monitor = ProcessMonitorWidget()
        overview_layout.addWidget(self.process_monitor)
        
        # Add tabs
        self.tabs.addTab(overview_tab, "Overview")
        
        # Add tabs to main layout
        main_layout.addWidget(self.tabs)
        
        # Create status bar
        self.statusbar = QStatusBar()
        self.setStatusBar(self.statusbar)
        
        # Add system info to status bar
        self.system_info_label = QLabel()
        self.statusbar.addPermanentWidget(self.system_info_label)
        
        # Add current time to status bar
        self.time_label = QLabel()
        self.statusbar.addPermanentWidget(self.time_label)
        
        # Create toolbar with actions
        self.toolbar = QToolBar("Main Toolbar")
        self.addToolBar(self.toolbar)
        
        # Start/Stop monitoring actions
        self.start_action = QAction("Start Monitoring", self)
        self.start_action.triggered.connect(self.start_monitoring)
        self.toolbar.addAction(self.start_action)
        
        self.stop_action = QAction("Stop Monitoring", self)
        self.stop_action.triggered.connect(self.stop_monitoring)
        self.stop_action.setEnabled(False)
        self.toolbar.addAction(self.stop_action)
        
        self.toolbar.addSeparator()
        
        # Export data action
        export_action = QAction("Export Data", self)
        export_action.triggered.connect(self.export_data)
        self.toolbar.addAction(export_action)
        
        # Take screenshot action
        screenshot_action = QAction("Take Screenshot", self)
        screenshot_action.triggered.connect(self.take_screenshot)
        self.toolbar.addAction(screenshot_action)
        
        # Set central widget
        self.setCentralWidget(central_widget)
        
        # Initialize metrics collector thread
        self.metrics_collector = None
        self.metrics_history = []
        
        # Update timer for time display
        self.time_timer = QTimer(self)
        self.time_timer.timeout.connect(self.update_time)
        self.time_timer.start(1000)  # Update every second
        
        # Start monitoring on launch
        self.start_monitoring()
        
    def start_monitoring(self) -> None:
        """Start system metrics collection and monitoring"""
        if self.metrics_collector is None or not self.metrics_collector.isRunning():
            # Create and start metrics collector thread
            self.metrics_collector = SystemMetricsCollector(interval=1.0)
            self.metrics_collector.metrics_updated.connect(self.update_dashboard)
            self.metrics_collector.start()
            
            # Update UI
            self.start_action.setEnabled(False)
            self.stop_action.setEnabled(True)
            self.statusbar.showMessage("Monitoring started")
            
    def stop_monitoring(self) -> None:
        """Stop system metrics collection and monitoring"""
        if self.metrics_collector and self.metrics_collector.isRunning():
            # Stop metrics collector thread
            self.metrics_collector.stop()
            self.metrics_collector = None
            
            # Update UI
            self.start_action.setEnabled(True)
            self.stop_action.setEnabled(False)
            self.statusbar.showMessage("Monitoring stopped")
            
    def update_dashboard(self, metrics: Dict[str, Any]) -> None:
        """
        Update dashboard with new metrics
        
        Args:
            metrics: Dictionary containing system metrics
        """
        # Store metrics in history
        self.metrics_history.append(metrics)
        if len(self.metrics_history) > 3600:  # Keep up to 1 hour of data at 1s intervals
            self.metrics_history.pop(0)
            
        # Update system status indicators
        self.system_status.update_status(metrics)
        
        # Update charts
        timestamp = metrics["timestamp"]
        
        # CPU chart
        self.cpu_chart.update_data(timestamp, {"CPU": metrics["cpu"]["percent"]})
        
        # Memory chart
        self.memory_chart.update_data(timestamp, {"Memory": metrics["memory"]["percent"]})
        
        # Disk I/O chart (convert to MB/s)
        if len(self.metrics_history) > 1:
            prev_metrics = self.metrics_history[-2]
            time_diff = timestamp - prev_metrics["timestamp"]
            
            if time_diff > 0:
                read_diff = (metrics["disk"]["read_bytes"] - prev_metrics["disk"]["read_bytes"]) / time_diff
                write_diff = (metrics["disk"]["write_bytes"] - prev_metrics["disk"]["write_bytes"]) / time_diff
                
                # Convert to MB/s
                read_mb = read_diff / (1024 * 1024)
                write_mb = write_diff / (1024 * 1024)
                
                self.disk_chart.update_data(timestamp, {"Read": read_mb, "Write": write_mb})
        
        # Network chart (convert to MB/s)
        network_data = {
            "Download": metrics["network"]["rx_speed"] / (1024 * 1024),
            "Upload": metrics["network"]["tx_speed"] / (1024 * 1024)
        }
        self.network_chart.update_data(timestamp, network_data)
        
        # Update process list
        self.process_monitor.update_processes(metrics["processes"])
        
        # Update system info label in status bar
        cpu_info = f"CPU: {metrics['cpu']['count']} cores @ {metrics['cpu']['freq_mhz']:.0f} MHz"
        mem_info = f"RAM: {metrics['memory']['total'] / (1024**3):.1f} GB"
        self.system_info_label.setText(f"{cpu_info} | {mem_info}")
        
    def update_time(self) -> None:
        """Update the time display in the status bar"""
        current_time = QDateTime.currentDateTime().toString("yyyy-MM-dd hh:mm:ss")
        self.time_label.setText(current_time)
        
    def export_data(self) -> None:
        """Export collected metrics to a file"""
        if not self.metrics_history:
            QMessageBox.warning(self, "Export Error", "No data available to export")
            return
            
        # Ask for file location
        filepath, _ = QFileDialog.getSaveFileName(
            self, 
            "Export Metrics Data", 
            f"{CACHE_DIR}/hyprsupreme_metrics_{int(time.time())}.json",
            "JSON Files (*.json)"
        )
        
        if not filepath:
            return
            
        try:
            # Convert data to serializable format
            export_data = []
            for metric in self.metrics_history:
                # Create a simplified copy without complex objects
                simplified = {
                    "timestamp": metric["timestamp"],
                    "cpu": {
                        "percent": metric["cpu"]["percent"],
                        "count": metric["cpu"]["count"],
                        "per_cpu": metric["cpu"]["per_cpu"]
                    },
                    "memory": {
                        "total": metric["memory"]["total"],
                        "used": metric["memory"]["used"],
                        "percent": metric["memory"]["percent"]
                    },
                    "disk": {
                        "total": metric["disk"]["total"],
                        "used": metric["disk"]["used"],
                        "percent": metric["disk"]["percent"]
                    },
                    "network": {
                        "tx_speed": metric["network"]["tx_speed"],
                        "rx_speed": metric["network"]["rx_speed"]
                    },
                    "processes": [
                        {
                            "pid": p["pid"],
                            "name": p["name"],
                            "cpu_percent": p["cpu_percent"],
                            "memory_percent": p["memory_percent"]
                        }
                        for p in metric["processes"][:10]  # Only include top 10 processes
                    ]
                }
                export_data.append(simplified)
                
            # Write to file
            with open(filepath, 'w') as f:
                json.dump(export_data, f, indent=2)
                
            QMessageBox.information(self, "Export Successful", f"Metrics data exported to {filepath}")
            
        except Exception as e:
            QMessageBox.critical(self, "Export Error", f"Failed to export data: {str(e)}")
            
    def take_screenshot(self) -> None:
        """Capture a screenshot of the dashboard"""
        # Ask for file location
        filepath, _ = QFileDialog.getSaveFileName(
            self, 
            "Save Screenshot", 
            f"{CACHE_DIR}/hyprsupreme_dashboard_{int(time.time())}.png",
            "PNG Files (*.png)"
        )
        
        if not filepath:
            return
            
        try:
            # Capture screenshot
            screenshot = self.grab()
            screenshot.save(filepath, "PNG")
            
            QMessageBox.information(self, "Screenshot Saved", f"Dashboard screenshot saved to {filepath}")
            
        except Exception as e:
            QMessageBox.critical(self, "Screenshot Error", f"Failed to save screenshot: {str(e)}")
            
    def closeEvent(self, event) -> None:
        """Handle window close event - clean up resources"""
        # Stop monitoring
        self.stop_monitoring()
        
        # Stop timers
        self.time_timer.stop()
        
        # Accept the event
        event.accept()


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="HyprSupreme Monitoring Dashboard")
    parser.add_argument("--interval", type=float, default=1.0, help="Monitoring interval in seconds")
    parser.add_argument("--log", action="store_true", help="Enable logging to file")
    parser.add_argument("--dark", action="store_true", help="Force dark mode theme")
    
    return parser.parse_args()


def main():
    """Main entry point for the application"""
    # Parse command line arguments
    args = parse_arguments()
    
    # Create application instance
    app = QApplication(sys.argv)
    
    # Set up dark theme if requested
    if args.dark:
        app.setStyle("Fusion")
        palette = QPalette()
        palette.setColor(QPalette.Window, QColor(53, 53, 53))
        palette.setColor(QPalette.WindowText, QColor(255, 255, 255))
        palette.setColor(QPalette.Base, QColor(25, 25, 25))
        palette.setColor(QPalette.AlternateBase, QColor(53, 53, 53))
        palette.setColor(QPalette.ToolTipBase, QColor(0, 0, 0))
        palette.setColor(QPalette.ToolTipText, QColor(255, 255, 255))
        palette.setColor(QPalette.Text, QColor(255, 255, 255))
        palette.setColor(QPalette.Button, QColor(53, 53, 53))
        palette.setColor(QPalette.ButtonText, QColor(255, 255, 255))
        palette.setColor(QPalette.BrightText, QColor(255, 0, 0))
        palette.setColor(QPalette.Link, QColor(42, 130, 218))
        palette.setColor(QPalette.Highlight, QColor(42, 130, 218))
        palette.setColor(QPalette.HighlightedText, QColor(0, 0, 0))
        app.setPalette(palette)
    
    # Create and show the main window
    window = MonitoringDashboard()
    window.show()
    
    # Start the application event loop
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
