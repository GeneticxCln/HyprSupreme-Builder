#!/usr/bin/env python3
"""
Advanced resource monitoring system for HyprSupreme-Builder with real-time alerting,
trend analysis, and performance prediction capabilities.
"""

import os
import sys
import time
import json
import signal
import argparse
import subprocess
import datetime
import threading
import statistics
import collections
import psutil
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
from termcolor import colored
from tabulate import tabulate

# Constants
DEFAULT_INTERVAL = 1.0  # seconds
DEFAULT_DURATION = 0  # seconds (0 = run indefinitely)
DEFAULT_THRESHOLD_CPU = 80.0  # percentage
DEFAULT_THRESHOLD_MEMORY = 80.0  # percentage
DEFAULT_THRESHOLD_DISK = 90.0  # percentage
DEFAULT_ALERT_INTERVAL = 30.0  # seconds
DEFAULT_TREND_WINDOW = 60  # data points

# Output directories
OUTPUT_DIR = Path(os.path.expanduser("~/.local/share/hyprsupreme/monitoring"))
LOG_DIR = OUTPUT_DIR / "logs"
REPORT_DIR = OUTPUT_DIR / "reports"
TREND_DIR = OUTPUT_DIR / "trends"

# Process names to monitor
HYPRSUPREME_PROCESSES = [
    "hyprsupreme",
    "hyprland",
    "waybar",
    "auto-theme-switcher",
    "workspace-manager"
]

# Global state variables
running = True
last_alert_time = 0
trend_data = {
    "cpu": collections.deque(maxlen=DEFAULT_TREND_WINDOW),
    "memory": collections.deque(maxlen=DEFAULT_TREND_WINDOW),
    "disk": collections.deque(maxlen=DEFAULT_TREND_WINDOW),
    "io_read": collections.deque(maxlen=DEFAULT_TREND_WINDOW),
    "io_write": collections.deque(maxlen=DEFAULT_TREND_WINDOW),
    "processes": {}
}

# Initialize output directories
for directory in [OUTPUT_DIR, LOG_DIR, REPORT_DIR, TREND_DIR]:
    directory.mkdir(parents=True, exist_ok=True)


def log(message, level="INFO", console=True):
    """Log a message to both console and log file."""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"[{timestamp}] [{level}] {message}"
    
    if console:
        color_map = {
            "INFO": "white",
            "SUCCESS": "green",
            "WARNING": "yellow",
            "ERROR": "red",
            "ALERT": "red",
            "DEBUG": "blue"
        }
        print(colored(log_line, color_map.get(level, "white")))
    
    # Write to log file
    log_file = LOG_DIR / f"resource_monitor_{datetime.datetime.now().strftime('%Y%m%d')}.log"
    with open(log_file, "a") as f:
        f.write(log_line + "\n")


def get_system_resources():
    """Get current system resource usage."""
    # CPU, memory, and disk usage
    cpu_percent = psutil.cpu_percent(interval=None)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    # Network stats
    net_io = psutil.net_io_counters()
    
    # Disk I/O stats
    disk_io = psutil.disk_io_counters()
    
    # Process info for HyprSupreme components
    processes = []
    for proc in psutil.process_iter(['pid', 'name', 'username', 'cpu_percent', 'memory_percent']):
        try:
            proc_info = proc.info
            proc_name = proc_info['name'].lower()
            
            if any(name in proc_name for name in HYPRSUPREME_PROCESSES):
                # Get detailed info for relevant processes
                detailed_proc = psutil.Process(proc_info['pid'])
                
                # Skip if process has terminated
                if not detailed_proc.is_running():
                    continue
                    
                # Update CPU percent (needs a second call for accuracy)
                proc_info['cpu_percent'] = detailed_proc.cpu_percent(interval=0.1)
                
                # Get additional info
                proc_info['memory_mb'] = detailed_proc.memory_info().rss / (1024 * 1024)
                proc_info['threads'] = detailed_proc.num_threads()
                proc_info['create_time'] = datetime.datetime.fromtimestamp(
                    detailed_proc.create_time()
                ).strftime("%Y-%m-%d %H:%M:%S")
                
                # Get open files
                try:
                    proc_info['open_files'] = len(detailed_proc.open_files())
                except psutil.AccessDenied:
                    proc_info['open_files'] = "N/A"
                
                # Get I/O counters if available
                try:
                    io_counters = detailed_proc.io_counters()
                    proc_info['io_read_mb'] = io_counters.read_bytes / (1024 * 1024)
                    proc_info['io_write_mb'] = io_counters.write_bytes / (1024 * 1024)
                except (psutil.AccessDenied, AttributeError):
                    proc_info['io_read_mb'] = 0
                    proc_info['io_write_mb'] = 0
                
                processes.append(proc_info)
                
                # Track process in trend data
                if proc_name not in trend_data["processes"]:
                    trend_data["processes"][proc_name] = {
                        "cpu": collections.deque(maxlen=DEFAULT_TREND_WINDOW),
                        "memory": collections.deque(maxlen=DEFAULT_TREND_WINDOW)
                    }
                
                trend_data["processes"][proc_name]["cpu"].append(proc_info['cpu_percent'])
                trend_data["processes"][proc_name]["memory"].append(proc_info['memory_mb'])
                
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    
    # Collect in a dictionary
    resources = {
        "timestamp": datetime.datetime.now().isoformat(),
        "cpu": {
            "percent": cpu_percent,
            "count": psutil.cpu_count(),
            "load_avg": os.getloadavg()
        },
        "memory": {
            "total_mb": memory.total / (1024 * 1024),
            "used_mb": memory.used / (1024 * 1024),
            "percent": memory.percent
        },
        "disk": {
            "total_gb": disk.total / (1024 * 1024 * 1024),
            "used_gb": disk.used / (1024 * 1024 * 1024),
            "percent": disk.percent
        },
        "network": {
            "bytes_sent_mb": net_io.bytes_sent / (1024 * 1024),
            "bytes_recv_mb": net_io.bytes_recv / (1024 * 1024)
        },
        "disk_io": {
            "read_mb": disk_io.read_bytes / (1024 * 1024),
            "write_mb": disk_io.write_bytes / (1024 * 1024)
        },
        "processes": processes
    }
    
    # Update trend data
    trend_data["cpu"].append(cpu_percent)
    trend_data["memory"].append(memory.percent)
    trend_data["disk"].append(disk.percent)
    trend_data["io_read"].append(disk_io.read_bytes / (1024 * 1024))
    trend_data["io_write"].append(disk_io.write_bytes / (1024 * 1024))
    
    return resources


def check_thresholds(resources, thresholds):
    """Check if any resource exceeds defined thresholds."""
    alerts = []
    
    # CPU threshold
    if resources["cpu"]["percent"] > thresholds["cpu"]:
        alerts.append({
            "resource": "CPU",
            "value": resources["cpu"]["percent"],
            "threshold": thresholds["cpu"],
            "message": f"CPU usage is {resources['cpu']['percent']:.1f}% (threshold: {thresholds['cpu']}%)"
        })
    
    # Memory threshold
    if resources["memory"]["percent"] > thresholds["memory"]:
        alerts.append({
            "resource": "Memory",
            "value": resources["memory"]["percent"],
            "threshold": thresholds["memory"],
            "message": f"Memory usage is {resources['memory']['percent']:.1f}% (threshold: {thresholds['memory']}%)"
        })
    
    # Disk threshold
    if resources["disk"]["percent"] > thresholds["disk"]:
        alerts.append({
            "resource": "Disk",
            "value": resources["disk"]["percent"],
            "threshold": thresholds["disk"],
            "message": f"Disk usage is {resources['disk']['percent']:.1f}% (threshold: {thresholds['disk']}%)"
        })
    
    # Process specific thresholds
    for proc in resources["processes"]:
        if proc["cpu_percent"] > thresholds["cpu"]:
            alerts.append({
                "resource": f"Process {proc['name']} (PID {proc['pid']})",
                "value": proc["cpu_percent"],
                "threshold": thresholds["cpu"],
                "message": f"Process {proc['name']} (PID {proc['pid']}) CPU usage is {proc['cpu_percent']:.1f}% (threshold: {thresholds['cpu']}%)"
            })
    
    return alerts


def analyze_trends():
    """Analyze resource usage trends and identify potential issues."""
    trend_analysis = {
        "cpu": {
            "increasing": False,
            "avg": 0,
            "max": 0,
            "min": 0,
            "trend_percent": 0
        },
        "memory": {
            "increasing": False,
            "avg": 0,
            "max": 0,
            "min": 0,
            "trend_percent": 0
        },
        "disk": {
            "increasing": False,
            "avg": 0,
            "max": 0,
            "min": 0,
            "trend_percent": 0
        },
        "processes": {}
    }
    
    # Analyze CPU trends
    if len(trend_data["cpu"]) >= 10:
        trend_analysis["cpu"]["avg"] = statistics.mean(trend_data["cpu"])
        trend_analysis["cpu"]["max"] = max(trend_data["cpu"])
        trend_analysis["cpu"]["min"] = min(trend_data["cpu"])
        
        # Calculate trend (using last 10 points)
        last_10 = list(trend_data["cpu"])[-10:]
        if len(last_10) >= 10:
            first_half_avg = statistics.mean(last_10[:5])
            second_half_avg = statistics.mean(last_10[5:])
            trend_analysis["cpu"]["trend_percent"] = ((second_half_avg - first_half_avg) / first_half_avg) * 100 if first_half_avg > 0 else 0
            trend_analysis["cpu"]["increasing"] = trend_analysis["cpu"]["trend_percent"] > 5  # 5% increase
    
    # Analyze memory trends
    if len(trend_data["memory"]) >= 10:
        trend_analysis["memory"]["avg"] = statistics.mean(trend_data["memory"])
        trend_analysis["memory"]["max"] = max(trend_data["memory"])
        trend_analysis["memory"]["min"] = min(trend_data["memory"])
        
        # Calculate trend (using last 10 points)
        last_10 = list(trend_data["memory"])[-10:]
        if len(last_10) >= 10:
            first_half_avg = statistics.mean(last_10[:5])
            second_half_avg = statistics.mean(last_10[5:])
            trend_analysis["memory"]["trend_percent"] = ((second_half_avg - first_half_avg) / first_half_avg) * 100 if first_half_avg > 0 else 0
            trend_analysis["memory"]["increasing"] = trend_analysis["memory"]["trend_percent"] > 3  # 3% increase
    
    # Analyze disk trends
    if len(trend_data["disk"]) >= 10:
        trend_analysis["disk"]["avg"] = statistics.mean(trend_data["disk"])
        trend_analysis["disk"]["max"] = max(trend_data["disk"])
        trend_analysis["disk"]["min"] = min(trend_data["disk"])
        
        # Calculate trend (using last 10 points)
        last_10 = list(trend_data["disk"])[-10:]
        if len(last_10) >= 10:
            first_half_avg = statistics.mean(last_10[:5])
            second_half_avg = statistics.mean(last_10[5:])
            trend_analysis["disk"]["trend_percent"] = ((second_half_avg - first_half_avg) / first_half_avg) * 100 if first_half_avg > 0 else 0
            trend_analysis["disk"]["increasing"] = trend_analysis["disk"]["trend_percent"] > 1  # 1% increase
    
    # Analyze process trends
    for proc_name, proc_data in trend_data["processes"].items():
        if len(proc_data["cpu"]) >= 10:
            proc_analysis = {
                "cpu": {
                    "increasing": False,
                    "avg": statistics.mean(proc_data["cpu"]),
                    "max": max(proc_data["cpu"]),
                    "min": min(proc_data["cpu"]),
                    "trend_percent": 0
                },
                "memory": {
                    "increasing": False,
                    "avg": statistics.mean(proc_data["memory"]),
                    "max": max(proc_data["memory"]),
                    "min": min(proc_data["memory"]),
                    "trend_percent": 0
                }
            }
            
            # Calculate CPU trend
            last_10_cpu = list(proc_data["cpu"])[-10:]
            if len(last_10_cpu) >= 10:
                first_half_avg = statistics.mean(last_10_cpu[:5])
                second_half_avg = statistics.mean(last_10_cpu[5:])
                proc_analysis["cpu"]["trend_percent"] = ((second_half_avg - first_half_avg) / first_half_avg) * 100 if first_half_avg > 0 else 0
                proc_analysis["cpu"]["increasing"] = proc_analysis["cpu"]["trend_percent"] > 10  # 10% increase
            
            # Calculate memory trend
            last_10_mem = list(proc_data["memory"])[-10:]
            if len(last_10_mem) >= 10:
                first_half_avg = statistics.mean(last_10_mem[:5])
                second_half_avg = statistics.mean(last_10_mem[5:])
                proc_analysis["memory"]["trend_percent"] = ((second_half_avg - first_half_avg) / first_half_avg) * 100 if first_half_avg > 0 else 0
                proc_analysis["memory"]["increasing"] = proc_analysis["memory"]["trend_percent"] > 5  # 5% increase
            
            trend_analysis["processes"][proc_name] = proc_analysis
    
    return trend_analysis


def detect_anomalies(resources, trend_analysis):
    """Detect anomalies in resource usage based on trends and statistical analysis."""
    anomalies = []
    
    # CPU anomaly detection (z-score method)
    if len(trend_data["cpu"]) >= 30:
        cpu_data = list(trend_data["cpu"])
        cpu_mean = statistics.mean(cpu_data)
        try:
            cpu_stdev = statistics.stdev(cpu_data)
            if cpu_stdev > 0:
                cpu_current = resources["cpu"]["percent"]
                z_score = (cpu_current - cpu_mean) / cpu_stdev
                
                if z_score > 2.5:  # More than 2.5 standard deviations
                    anomalies.append({
                        "resource": "CPU",
                        "value": cpu_current,
                        "z_score": z_score,
                        "message": f"CPU usage anomaly detected: {cpu_current:.1f}% (z-score: {z_score:.2f})"
                    })
        except statistics.StatisticsError:
            pass
    
    # Memory anomaly detection
    if len(trend_data["memory"]) >= 30:
        mem_data = list(trend_data["memory"])
        mem_mean = statistics.mean(mem_data)
        try:
            mem_stdev = statistics.stdev(mem_data)
            if mem_stdev > 0:
                mem_current = resources["memory"]["percent"]
                z_score = (mem_current - mem_mean) / mem_stdev
                
                if z_score > 2.5:
                    anomalies.append({
                        "resource": "Memory",
                        "value": mem_current,
                        "z_score": z_score,
                        "message": f"Memory usage anomaly detected: {mem_current:.1f}% (z-score: {z_score:.2f})"
                    })
        except statistics.StatisticsError:
            pass
    
    # Process anomaly detection
    for proc in resources["processes"]:
        proc_name = proc["name"].lower()
        if proc_name in trend_data["processes"] and len(trend_data["processes"][proc_name]["cpu"]) >= 15:
            proc_cpu_data = list(trend_data["processes"][proc_name]["cpu"])
            proc_cpu_mean = statistics.mean(proc_cpu_data)
            
            try:
                proc_cpu_stdev = statistics.stdev(proc_cpu_data)
                if proc_cpu_stdev > 0:
                    proc_cpu_current = proc["cpu_percent"]
                    z_score = (proc_cpu_current - proc_cpu_mean) / proc_cpu_stdev
                    
                    if z_score > 3.0:  # Higher threshold for processes
                        anomalies.append({
                            "resource": f"Process {proc['name']} (PID {proc['pid']})",
                            "value": proc_cpu_current,
                            "z_score": z_score,
                            "message": f"Process {proc['name']} CPU usage anomaly: {proc_cpu_current:.1f}% (z-score: {z_score:.2f})"
                        })
            except statistics.StatisticsError:
                pass
    
    return anomalies


def predict_resource_exhaustion(trend_analysis, thresholds):
    """Predict when resources might exhaust based on current trends."""
    predictions = []
    
    # CPU prediction
    if trend_analysis["cpu"]["increasing"] and trend_analysis["cpu"]["trend_percent"] > 0:
        current_cpu = trend_analysis["cpu"]["avg"]
        trend_rate = trend_analysis["cpu"]["trend_percent"] / 100
        
        if current_cpu < thresholds["cpu"] and trend_rate > 0:
            # Calculate time to threshold
            remaining_percentage = thresholds["cpu"] - current_cpu
            intervals_to_threshold = remaining_percentage / (current_cpu * trend_rate)
            time_to_threshold = intervals_to_threshold * DEFAULT_INTERVAL * 10  # 10 data points used for trend
            
            if time_to_threshold < 300:  # Less than 5 minutes
                predictions.append({
                    "resource": "CPU",
                    "current": current_cpu,
                    "threshold": thresholds["cpu"],
                    "time_seconds": time_to_threshold,
                    "message": f"CPU usage predicted to reach {thresholds['cpu']}% in {time_to_threshold:.1f} seconds"
                })
    
    # Memory prediction
    if trend_analysis["memory"]["increasing"] and trend_analysis["memory"]["trend_percent"] > 0:
        current_memory = trend_analysis["memory"]["avg"]
        trend_rate = trend_analysis["memory"]["trend_percent"] / 100
        
        if current_memory < thresholds["memory"] and trend_rate > 0:
            # Calculate time to threshold
            remaining_percentage = thresholds["memory"] - current_memory
            intervals_to_threshold = remaining_percentage / (current_memory * trend_rate)
            time_to_threshold = intervals_to_threshold * DEFAULT_INTERVAL * 10
            
            if time_to_threshold < 600:  # Less than 10 minutes
                predictions.append({
                    "resource": "Memory",
                    "current": current_memory,
                    "threshold": thresholds["memory"],
                    "time_seconds": time_to_threshold,
                    "message": f"Memory usage predicted to reach {thresholds['memory']}% in {time_to_threshold:.1f} seconds"
                })
    
    # Disk prediction
    if trend_analysis["disk"]["increasing"] and trend_analysis["disk"]["trend_percent"] > 0:
        current_disk = trend_analysis["disk"]["avg"]
        trend_rate = trend_analysis["disk"]["trend_percent"] / 100
        
        if current_disk < thresholds["disk"] and trend_rate > 0:
            # Calculate time to threshold
            remaining_percentage = thresholds["disk"] - current_disk
            intervals_to_threshold = remaining_percentage / (current_disk * trend_rate)
            time_to_threshold = intervals_to_threshold * DEFAULT_INTERVAL * 10
            
            if time_to_threshold < 1800:  # Less than 30 minutes
                predictions.append({
                    "resource": "Disk",
                    "current": current_disk,
                    "threshold": thresholds["disk"],
                    "time_seconds": time_to_threshold,
                    "message": f"Disk usage predicted to reach {thresholds['disk']}% in {time_to_threshold:.1f} seconds"
                })
    
    return predictions


def save_monitoring_data(resources, trend_analysis, anomalies, predictions):
    """Save monitoring data to files for later analysis."""
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Save resources snapshot
    resources_file = REPORT_DIR / f"resources_{timestamp}.json"
    with open(resources_file, "w") as f:
        json.dump(resources, f, indent=2)
    
    # Save trend analysis
    if trend_analysis:
        trend_file = TREND_DIR / f"trend_analysis_{timestamp}.json"
        with open(trend_file, "w") as f:
            # Convert deque objects to lists for JSON serialization
            serializable_trends = {
                "cpu": {k: v for k, v in trend_analysis["cpu"].items()},
                "memory": {k: v for k, v in trend_analysis["memory"].items()},
                "disk": {k: v for k, v in trend_analysis["disk"].items()},
                "processes": {}
            }
            
            for proc_name, proc_data in trend_analysis["processes"].items():
                serializable_trends["processes"][proc_name] = {
                    "cpu": {k: v for k, v in proc_data["cpu"].items()},
                    "memory": {k: v for k, v in proc_data["memory"].items()}
                }
            
            json.dump(serializable_trends, f, indent=2)
    
    # Save anomalies and predictions if any
    if anomalies or predictions:
        alert_file = REPORT_DIR / f"alerts_{timestamp}.json"
        with open(alert_file, "w") as f:
            json.dump({
                "timestamp": timestamp,
                "anomalies": anomalies,
                "predictions": predictions
            }, f, indent=2)


def generate_trend_graphs():
    """Generate visual graphs of resource trends."""
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    graph_file = TREND_DIR / f"resource_trends_{timestamp}.png"
    
    # Create figure with subplots
    fig, axs = plt.subplots(3, 1, figsize=(10, 12))
    
    # Plot CPU usage
    cpu_data = list(trend_data["cpu"])
    axs[0].plot(cpu_data, 'r-')
    axs[0].set_title('CPU Usage Trend')
    axs[0].set_ylabel('Percentage')
    axs[0].set_ylim(0, 100)
    axs[0].grid(True)
    
    # Plot memory usage
    memory_data = list(trend_data["memory"])
    axs[1].plot(memory_data, 'b-')
    axs[1].set_title('Memory Usage Trend')
    axs[1].set_ylabel('Percentage')
    axs[1].set_ylim(0, 100)
    axs[1].grid(True)
    
    # Plot disk I/O
    io_read_data = list(trend_data["io_read"])
    io_write_data = list(trend_data["io_write"])
    
    # Calculate differences for I/O rates
    io_read_rate = [0] + [io_read_data[i] - io_read_data[i-1] for i in range(1, len(io_read_data))]
    io_write_rate = [0] + [io_write_data[i] - io_write_data[i-1] for i in range(1, len(io_write_data))]
    
    axs[2].plot(io_read_rate, 'g-', label='Read')
    axs[2].plot(io_write_rate, 'y-', label='Write')
    axs[2].set_title('Disk I/O Rate')
    axs[2].set_ylabel('MB/s')
    axs[2].legend()
    axs[2].grid(True)
    
    plt.tight_layout()
    plt.savefig(graph_file)
    plt.close(fig)
    
    log(f"Trend graphs saved to {graph_file}", "INFO")
    return graph_file


def monitor_resources_during_operation(operation_name, operation_func, *args, **kwargs):
    """Monitor resource usage during a specific operation."""
    log(f"Starting resource monitoring for operation: {operation_name}", "INFO")
    
    # Reset monitoring data
    operation_data = {
        "name": operation_name,
        "start_time": datetime.datetime.now().isoformat(),
        "end_time": None,
        "duration_seconds": 0,
        "measurements": [],
        "summary": {}
    }
    
    # Start monitoring thread
    stop_monitoring = threading.Event()
    
    def monitor_thread():
        while not stop_monitoring.is_set():
            resources = get_system_resources()
            operation_data["measurements"].append(resources)
            time.sleep(0.5)
    
    monitor = threading.Thread(target=monitor_thread)
    monitor.daemon = True
    monitor.start()
    
    # Execute the operation
    start_time = time.time()
    try:
        result = operation_func(*args, **kwargs)
        success = True
    except Exception as e:
        result = e
        success = False
    
    # Stop monitoring
    end_time = time.time()
    stop_monitoring.set()
    monitor.join()
    
    # Record operation data
    operation_data["end_time"] = datetime.datetime.now().isoformat()
    operation_data["duration_seconds"] = end_time - start_time
    operation_data["success"] = success
    
    # Calculate summary statistics
    if operation_data["measurements"]:
        cpu_values = [m["cpu"]["percent"] for m in operation_data["measurements"]]
        memory_values = [m["memory"]["percent"] for m in operation_data["measurements"]]
        
        operation_data["summary"] = {
            "cpu": {
                "min": min(cpu_values),
                "max": max(cpu_values),
                "avg": sum(cpu_values) / len(cpu_values)
            },
            "memory": {
                "min": min(memory_values),
                "max": max(memory_values),
                "avg": sum(memory_values) / len(memory_values)
            }
        }
    
    # Save operation monitoring data
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    operation_file = REPORT_DIR / f"operation_{operation_name.replace(' ', '_')}_{timestamp}.json"
    
    with open(operation_file, "w") as f:
        # Create a simplified version for storage
        simplified_data = {
            "name": operation_data["name"],
            "start_time": operation_data["start_time"],
            "end_time": operation_data["end_time"],
            "duration_seconds": operation_data["duration_seconds"],
            "success": operation_data["success"],
            "summary": operation_data["summary"],
            # Simplify measurements to save space
            "measurements_count": len(operation_data["measurements"]),
            "cpu_avg": operation_data["summary"]["cpu"]["avg"] if "cpu" in operation_data["summary"] else 0,
            "memory_avg": operation_data["summary"]["memory"]["avg"] if "memory" in operation_data["summary"] else 0
        }
        json.dump(simplified_data, f, indent=2)
    
    log(f"Operation monitoring completed: {operation_name}", "INFO")
    log(f"Duration: {operation_data['duration_seconds']:.2f}s, " +
        f"CPU: {operation_data['summary']['cpu']['avg']:.1f}%, " +
        f"Memory: {operation_data['summary']['memory']['avg']:.1f}%", "INFO")
    
    return result, operation_data


def display_resources(resources):
    """Display current system resources in a human-readable format."""
    # Main system resources table
    system_table = [
        ["CPU Usage", f"{resources['cpu']['percent']:.1f}%"],
        ["Load Average", f"{resources['cpu']['load_avg'][0]:.2f}, {resources['cpu']['load_avg'][1]:.2f}, {resources['cpu']['load_avg'][2]:.2f}"],
        ["Memory Usage", f"{resources['memory']['used_mb']:.0f}MB / {resources['memory']['total_mb']:.0f}MB ({resources['memory']['percent']:.1f}%)"],
        ["Disk Usage", f"{resources['disk']['used_gb']:.1f}GB / {resources['disk']['total_gb']:.1f}GB ({resources['disk']['percent']:.1f}%)"],
        ["Network", f"↑ {resources['network']['bytes_sent_mb']:.1f}MB ↓ {resources['network']['bytes_recv_mb']:.1f}MB"],
        ["Disk I/O", f"Read: {resources['disk_io']['read_mb']:.1f}MB, Write: {resources['disk_io']['write_mb']:.1f}MB"]
    ]
    
    print("\n" + colored("=== SYSTEM RESOURCES ===", "cyan", attrs=["bold"]))
    print(tabulate(system_table, tablefmt="simple"))
    
    # Processes table
    if resources["processes"]:
        process_table = []
        
        for proc in sorted(resources["processes"], key=lambda p: p["cpu_percent"], reverse=True)[:10]:  # Top 10 by CPU
            process_table.append([
                proc["pid"],
                proc["name"][:20],
                f"{proc['cpu_percent']:.1f}%",
                f"{proc['memory_mb']:.1f}MB",
                proc["threads"],
                proc["open_files"] if isinstance(proc["open_files"], int) else "N/A"
            ])
        
        print("\n" + colored("=== TOP PROCESSES ===", "cyan", attrs=["bold"]))
        print(tabulate(process_table, headers=["PID", "Name", "CPU", "Memory", "Threads", "Files"], tablefmt="simple"))


def print_trend_analysis(trend_analysis):
    """Display trend analysis results."""
    if not trend_analysis:
        return
    
    print("\n" + colored("=== TREND ANALYSIS ===", "cyan", attrs=["bold"]))
    
    # System resource trends
    system_trends = [
        ["CPU", f"{trend_analysis['cpu']['avg']:.1f}%", 
         f"{trend_analysis['cpu']['trend_percent']:.1f}%", 
         "↑" if trend_analysis['cpu']['increasing'] else "↓"],
        ["Memory", f"{trend_analysis['memory']['avg']:.1f}%", 
         f"{trend_analysis['memory']['trend_percent']:.1f}%", 
         "↑" if trend_analysis['memory']['increasing'] else "↓"],
        ["Disk", f"{trend_analysis['disk']['avg']:.1f}%", 
         f"{trend_analysis['disk']['trend_percent']:.1f}%", 
         "↑" if trend_analysis['disk']['increasing'] else "↓"]
    ]
    
    print(tabulate(system_trends, headers=["Resource", "Average", "Trend", "Direction"], tablefmt="simple"))
    
    # Process trends
    if trend_analysis["processes"]:
        print("\n" + colored("=== PROCESS TRENDS ===", "cyan", attrs=["bold"]))
        
        process_trends = []
        for proc_name, proc_data in trend_analysis["processes"].items():
            process_trends.append([
                proc_name[:20],
                f"{proc_data['cpu']['avg']:.1f}%",
                f"{proc_data['cpu']['trend_percent']:.1f}%",
                "↑" if proc_data['cpu']['increasing'] else "↓",
                f"{proc_data['memory']['avg']:.1f}MB",
                f"{proc_data['memory']['trend_percent']:.1f}%",
                "↑" if proc_data['memory']['increasing'] else "↓"
            ])
        
        print(tabulate(process_trends[:5], headers=["Process", "CPU Avg", "CPU Trend", "Dir", "Mem Avg", "Mem Trend", "Dir"], tablefmt="simple"))


def monitor_theme_switching(theme_name):
    """Monitor resource usage during theme switching."""
    def switch_theme():
        try:
            subprocess.run(["hyprsupreme", "theme", "apply", theme_name], check=True)
            return True
        except subprocess.CalledProcessError as e:
            return e
    
    result, stats = monitor_resources_during_operation(f"Theme Switch to {theme_name}", switch_theme)
    return result, stats


def monitor_plugin_enabling(plugin_name, enable=True):
    """Monitor resource usage during plugin enabling/disabling."""
    action = "enable" if enable else "disable"
    
    def toggle_plugin():
        try:
            subprocess.run(["hyprsupreme", "plugin", action, plugin_name], check=True)
            return True
        except subprocess.CalledProcessError as e:
            return e
    
    result, stats = monitor_resources_during_operation(f"Plugin {action.title()} {plugin_name}", toggle_plugin)
    return result, stats


def signal_handler(sig, frame):
    """Handle interrupt signal."""
    global running
    log("Stopping monitoring (received interrupt signal)", "INFO")
    running = False


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="Advanced Resource Monitor for HyprSupreme-Builder")
    parser.add_argument("--interval", type=float, default=DEFAULT_INTERVAL,
                        help=f"Sampling interval in seconds (default: {DEFAULT_INTERVAL})")
    parser.add_argument("--duration", type=int, default=DEFAULT_DURATION,
                        help=f"Monitoring duration in seconds, 0 for indefinite (default: {DEFAULT_DURATION})")
    parser.add_argument("--cpu-threshold", type=float, default=DEFAULT_THRESHOLD_CPU,
                        help=f"CPU usage alert threshold in percent (default: {DEFAULT_THRESHOLD_CPU}%)")
    parser.add_argument("--memory-threshold", type=float, default=DEFAULT_THRESHOLD_MEMORY,
                        help=f"Memory usage alert threshold in percent (default: {DEFAULT_THRESHOLD_MEMORY}%)")
    parser.add_argument("--disk-threshold", type=float, default=DEFAULT_THRESHOLD_DISK,
                        help=f"Disk usage alert threshold in percent (default: {DEFAULT_THRESHOLD_DISK}%)")
    parser.add_argument("--alert-interval", type=float, default=DEFAULT_ALERT_INTERVAL,
                        help=f"Minimum time between alerts in seconds (default: {DEFAULT_ALERT_INTERVAL}s)")
    parser.add_argument("--graph-interval", type=int, default=300,
                        help="Interval for generating trend graphs in seconds (default: 300s)")
    parser.add_argument("--monitor-theme", type=str, metavar="THEME_NAME",
                        help="Monitor resources while switching to specified theme")
    parser.add_argument("--monitor-plugin", type=str, metavar="PLUGIN_NAME",
                        help="Monitor resources while enabling specified plugin")
    parser.add_argument("--disable-plugin", action="store_true",
                        help="Disable the plugin instead of enabling (with --monitor-plugin)")
    
    args = parser.parse_args()
    
    # Register signal handler
    signal.signal(signal.SIGINT, signal_handler)
    
    # Set up thresholds
    thresholds = {
        "cpu": args.cpu_threshold,
        "memory": args.memory_threshold,
        "disk": args.disk_threshold
    }
    
    # Special operations mode
    if args.monitor_theme:
        log(f"Monitoring resources during theme switch to {args.monitor_theme}", "INFO")
        result, stats = monitor_theme_switching(args.monitor_theme)
        if result is True:
            log(f"Theme switch completed successfully", "SUCCESS")
        else:
            log(f"Theme switch failed: {result}", "ERROR")
        return
    
    if args.monitor_plugin:
        action = "disabling" if args.disable_plugin else "enabling"
        log(f"Monitoring resources during plugin {action} {args.monitor_plugin}", "INFO")
        result, stats = monitor_plugin_enabling(args.monitor_plugin, not args.disable_plugin)
        if result is True:
            log(f"Plugin operation completed successfully", "SUCCESS")
        else:
            log(f"Plugin operation failed: {result}", "ERROR")
        return
    
    # Regular monitoring mode
    log("Starting advanced resource monitoring for HyprSupreme", "INFO")
    log(f"Alert thresholds - CPU: {thresholds['cpu']}%, Memory: {thresholds['memory']}%, Disk: {thresholds['disk']}%", "INFO")
    
    global running, last_alert_time
    running = True
    last_alert_time = time.time()
    last_graph_time = time.time()
    start_time = time.time()
    
    try:
        while running:
            # Check if duration limit reached
            if args.duration > 0 and time.time() - start_time >= args.duration:
                log(f"Reached monitoring duration limit ({args.duration}s)", "INFO")
                break
            
            # Get current resource usage
            resources = get_system_resources()
            
            # Display current resources
            display_resources(resources)
            
            # Analyze trends if enough data
            trend_analysis = analyze_trends() if len(trend_data["cpu"]) >= 10 else None
            
            # Detect anomalies and make predictions
            anomalies = detect_anomalies(resources, trend_analysis) if trend_analysis else []
            predictions = predict_resource_exhaustion(trend_analysis, thresholds) if trend_analysis else []
            
            # Check resource thresholds
            alerts = check_thresholds(resources, thresholds)
            
            # Print trend analysis
            if trend_analysis:
                print_trend_analysis(trend_analysis)
            
            # Handle alerts, anomalies, and predictions
            current_time = time.time()
            if (alerts or anomalies or predictions) and current_time - last_alert_time >= args.alert_interval:
                for alert in alerts:
                    log(alert["message"], "ALERT")
                
                for anomaly in anomalies:
                    log(anomaly["message"], "WARNING")
                
                for prediction in predictions:
                    log(prediction["message"], "WARNING")
                
                last_alert_time = current_time
            
            # Generate trend graphs periodically
            if current_time - last_graph_time >= args.graph_interval and len(trend_data["cpu"]) >= 20:
                graph_file = generate_trend_graphs()
                last_graph_time = current_time
            
            # Save monitoring data
            save_monitoring_data(resources, trend_analysis, anomalies, predictions)
            
            # Wait for next interval
            time.sleep(args.interval)
    
    except KeyboardInterrupt:
        log("Monitoring stopped by user", "INFO")
    except Exception as e:
        log(f"Error during monitoring: {e}", "ERROR")
    finally:
        # Generate final trend graphs if enough data
        if len(trend_data["cpu"]) >= 20:
            generate_trend_graphs()
        
        log("Resource monitoring completed", "INFO")


if __name__ == "__main__":
    main()
