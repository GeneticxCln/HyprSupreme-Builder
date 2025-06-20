#!/usr/bin/env python3
"""
HyprSupreme System Resource Monitor
Monitors and reports system resource usage for HyprSupreme components.
Tracks memory, CPU, and file I/O usage of themes and plugins.
"""

import os
import sys
import time
import json
import signal
import argparse
import subprocess
import threading
import statistics
from datetime import datetime
from pathlib import Path

try:
    import psutil
except ImportError:
    print("Error: psutil module not installed. Please install with: pip install psutil")
    sys.exit(1)

# Constants
DEFAULT_INTERVAL = 1  # seconds
DEFAULT_DURATION = 60  # seconds
LOG_DIR = Path(os.path.expanduser("~/.local/share/hyprsupreme/logs"))
DATA_DIR = Path(os.path.expanduser("~/.local/share/hyprsupreme/data"))
PROCESS_NAME = "hyprsupreme"

# Global variables
running = True
collected_data = {
    "timestamp": [],
    "cpu_percent": [],
    "memory_percent": [],
    "memory_rss": [],  # MB
    "io_read_bytes": [],
    "io_write_bytes": [],
    "threads": [],
    "open_files": [],
    "connections": []
}

class ResourceMonitor:
    """Monitors system resources used by HyprSupreme components."""
    
    def __init__(self, interval=DEFAULT_INTERVAL, log_dir=LOG_DIR, data_dir=DATA_DIR):
        """Initialize the resource monitor.
        
        Args:
            interval: Sampling interval in seconds
            log_dir: Directory to store log files
            data_dir: Directory to store data files
        """
        self.interval = interval
        self.log_dir = log_dir
        self.data_dir = data_dir
        self.processes = []
        self.session_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = self.log_dir / f"resource_monitor_{self.session_id}.log"
        self.data_file = self.data_dir / f"resource_data_{self.session_id}.json"
        
        # Ensure directories exist
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        self.collected_data = {
            "system_info": self._get_system_info(),
            "process_data": {},
            "global_data": {
                "timestamp": [],
                "cpu_total": [],
                "memory_total": [],
                "swap_total": []
            },
            "theme_data": {},
            "plugin_data": {}
        }
        
        # Initialize logger
        with open(self.log_file, "w") as f:
            f.write(f"HyprSupreme Resource Monitor Session {self.session_id}\n")
            f.write(f"Started at: {datetime.now().isoformat()}\n")
            f.write(f"System Info: {json.dumps(self.collected_data['system_info'], indent=2)}\n\n")
    
    def _get_system_info(self):
        """Collect system information."""
        info = {
            "date": datetime.now().isoformat(),
            "os": "Unknown",
            "cpu": "Unknown",
            "memory": "Unknown",
            "gpu": "Unknown",
            "hyprland_version": "Unknown",
            "hyprsupreme_version": "Unknown"
        }
        
        try:
            # Get OS information
            os_info = subprocess.check_output("cat /etc/os-release | grep PRETTY_NAME", shell=True).decode().strip()
            info["os"] = os_info.split("=")[1].strip('"')
        except:
            pass
        
        try:
            # Get CPU information
            cpu_info = subprocess.check_output("cat /proc/cpuinfo | grep 'model name' | head -1", shell=True).decode().strip()
            info["cpu"] = cpu_info.split(":")[1].strip()
            info["cpu_cores"] = os.cpu_count()
        except:
            pass
        
        try:
            # Get memory information
            mem_info = subprocess.check_output("free -h | grep Mem", shell=True).decode().strip()
            total_mem = mem_info.split()[1]
            info["memory"] = total_mem
        except:
            pass
        
        try:
            # Get GPU information
            gpu_info = subprocess.check_output("lspci | grep -E 'VGA|3D' | head -1", shell=True).decode().strip()
            info["gpu"] = gpu_info.split(":")[2].strip()
        except:
            pass
        
        try:
            # Get Hyprland version
            hyprland_version = subprocess.check_output("hyprctl version", shell=True).decode().strip()
            info["hyprland_version"] = hyprland_version.split("\n")[0]
        except:
            pass
        
        try:
            # Get HyprSupreme version
            hyprsupreme_version = subprocess.check_output("hyprsupreme --version", shell=True).decode().strip()
            info["hyprsupreme_version"] = hyprsupreme_version
        except:
            pass
        
        return info
    
    def log(self, message):
        """Log a message to the log file and stdout."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] {message}"
        print(log_message)
        
        with open(self.log_file, "a") as f:
            f.write(log_message + "\n")
    
    def find_processes(self):
        """Find all HyprSupreme related processes."""
        self.processes = []
        
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                # Check if process is related to hyprsupreme
                if any(PROCESS_NAME in cmd.lower() for cmd in proc.info['cmdline'] if cmd):
                    self.processes.append(proc)
                    self.log(f"Found HyprSupreme process: PID {proc.pid} - {' '.join(proc.info['cmdline'])}")
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        
        return len(self.processes)
    
    def collect_process_data(self, process):
        """Collect resource usage data for a single process."""
        try:
            with process.oneshot():
                pid = process.pid
                cmdline = " ".join(process.cmdline())
                
                # Extract component type and name
                component_type = "unknown"
                component_name = "unknown"
                
                if "theme" in cmdline.lower():
                    component_type = "theme"
                    # Extract theme name from command line
                    for arg in process.cmdline():
                        if arg.endswith(".theme") or arg.endswith(".yaml"):
                            component_name = os.path.basename(arg).split(".")[0]
                            break
                elif "plugin" in cmdline.lower():
                    component_type = "plugin"
                    # Extract plugin name from command line
                    cmd_str = " ".join(process.cmdline())
                    for plugin in ["auto-theme-switcher", "workspace-manager"]:  # Add known plugins here
                        if plugin in cmd_str:
                            component_name = plugin
                            break
                
                # Collect process data
                process_data = {
                    "pid": pid,
                    "cpu_percent": process.cpu_percent(),
                    "memory_percent": process.memory_percent(),
                    "memory_rss": process.memory_info().rss / (1024 * 1024),  # MB
                    "threads": process.num_threads(),
                    "open_files": len(process.open_files()),
                    "connections": len(process.connections()),
                    "cmdline": cmdline,
                    "component_type": component_type,
                    "component_name": component_name
                }
                
                # Add I/O data if available
                try:
                    io = process.io_counters()
                    process_data.update({
                        "io_read_bytes": io.read_bytes,
                        "io_write_bytes": io.write_bytes
                    })
                except:
                    process_data.update({
                        "io_read_bytes": 0,
                        "io_write_bytes": 0
                    })
                
                return process_data
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess) as e:
            self.log(f"Error collecting data for process {process.pid}: {e}")
            return None
    
    def collect_system_data(self):
        """Collect system-wide resource usage data."""
        timestamp = datetime.now().isoformat()
        
        # Add timestamp
        self.collected_data["global_data"]["timestamp"].append(timestamp)
        
        # System-wide CPU and memory
        self.collected_data["global_data"]["cpu_total"].append(psutil.cpu_percent(interval=0.1))
        self.collected_data["global_data"]["memory_total"].append(psutil.virtual_memory().percent)
        self.collected_data["global_data"]["swap_total"].append(psutil.swap_memory().percent)
        
        return timestamp
    
    def monitor_resources(self, duration=DEFAULT_DURATION):
        """Monitor resources for a specified duration.
        
        Args:
            duration: Monitoring duration in seconds
        """
        self.log(f"Starting resource monitoring for {duration} seconds (interval: {self.interval}s)")
        
        # Find HyprSupreme processes
        num_processes = self.find_processes()
        if num_processes == 0:
            self.log("Warning: No HyprSupreme processes found. Is HyprSupreme running?")
        
        start_time = time.time()
        end_time = start_time + duration
        
        try:
            while time.time() < end_time:
                # Collect system-wide data
                timestamp = self.collect_system_data()
                
                # Refresh process list periodically
                if time.time() - start_time > 10:  # Refresh every 10 seconds
                    self.find_processes()
                    start_time = time.time()
                
                # Collect data for each process
                for process in self.processes:
                    try:
                        process_data = self.collect_process_data(process)
                        if process_data:
                            pid = str(process_data["pid"])
                            
                            # Initialize process data if needed
                            if pid not in self.collected_data["process_data"]:
                                self.collected_data["process_data"][pid] = {
                                    "cmdline": process_data["cmdline"],
                                    "component_type": process_data["component_type"],
                                    "component_name": process_data["component_name"],
                                    "data": {
                                        "timestamp": [],
                                        "cpu_percent": [],
                                        "memory_percent": [],
                                        "memory_rss": [],
                                        "threads": [],
                                        "open_files": [],
                                        "connections": [],
                                        "io_read_bytes": [],
                                        "io_write_bytes": []
                                    }
                                }
                            
                            # Add data to the process
                            process_dict = self.collected_data["process_data"][pid]["data"]
                            process_dict["timestamp"].append(timestamp)
                            process_dict["cpu_percent"].append(process_data["cpu_percent"])
                            process_dict["memory_percent"].append(process_data["memory_percent"])
                            process_dict["memory_rss"].append(process_data["memory_rss"])
                            process_dict["threads"].append(process_data["threads"])
                            process_dict["open_files"].append(process_data["open_files"])
                            process_dict["connections"].append(process_data["connections"])
                            process_dict["io_read_bytes"].append(process_data["io_read_bytes"])
                            process_dict["io_write_bytes"].append(process_data["io_write_bytes"])
                            
                            # Add to component-specific data
                            component_type = process_data["component_type"]
                            component_name = process_data["component_name"]
                            
                            if component_type == "theme" and component_name != "unknown":
                                if component_name not in self.collected_data["theme_data"]:
                                    self.collected_data["theme_data"][component_name] = {
                                        "cpu": [], "memory": [], "timestamp": []
                                    }
                                self.collected_data["theme_data"][component_name]["cpu"].append(process_data["cpu_percent"])
                                self.collected_data["theme_data"][component_name]["memory"].append(process_data["memory_rss"])
                                self.collected_data["theme_data"][component_name]["timestamp"].append(timestamp)
                            
                            elif component_type == "plugin" and component_name != "unknown":
                                if component_name not in self.collected_data["plugin_data"]:
                                    self.collected_data["plugin_data"][component_name] = {
                                        "cpu": [], "memory": [], "timestamp": []
                                    }
                                self.collected_data["plugin_data"][component_name]["cpu"].append(process_data["cpu_percent"])
                                self.collected_data["plugin_data"][component_name]["memory"].append(process_data["memory_rss"])
                                self.collected_data["plugin_data"][component_name]["timestamp"].append(timestamp)
                    
                    except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                        # Process no longer exists, remove it from our list
                        self.processes.remove(process)
                
                # Sleep until next interval
                time.sleep(self.interval)
        
        except KeyboardInterrupt:
            self.log("Monitoring interrupted by user")
        
        # Save collected data
        self.save_data()
        self.log(f"Monitoring complete. Data saved to {self.data_file}")
        return self.data_file
    
    def save_data(self):
        """Save collected data to JSON file."""
        with open(self.data_file, "w") as f:
            json.dump(self.collected_data, f, indent=2)
        self.log(f"Data saved to {self.data_file}")
    
    def analyze_data(self):
        """Analyze collected data and print summary."""
        if not self.collected_data["process_data"]:
            self.log("No data collected for analysis")
            return
        
        self.log("\nResource Usage Summary:")
        self.log("=======================")
        
        # System-wide summary
        if self.collected_data["global_data"]["cpu_total"]:
            self.log("\nSystem-wide Resource Usage:")
            self.log(f"  CPU: Avg {statistics.mean(self.collected_data['global_data']['cpu_total']):.1f}% | " +
                  f"Max {max(self.collected_data['global_data']['cpu_total']):.1f}%")
            self.log(f"  Memory: Avg {statistics.mean(self.collected_data['global_data']['memory_total']):.1f}% | " +
                  f"Max {max(self.collected_data['global_data']['memory_total']):.1f}%")
            self.log(f"  Swap: Avg {statistics.mean(self.collected_data['global_data']['swap_total']):.1f}% | " +
                  f"Max {max(self.collected_data['global_data']['swap_total']):.1f}%")
        
        # Process summary
        self.log("\nProcess Resource Usage:")
        for pid, process_info in self.collected_data["process_data"].items():
            cmdline = process_info["cmdline"]
            component_type = process_info["component_type"]
            component_name = process_info["component_name"]
            
            data = process_info["data"]
            if not data["cpu_percent"]:
                continue  # Skip if no data collected
            
            avg_cpu = statistics.mean(data["cpu_percent"]) if data["cpu_percent"] else 0
            avg_mem = statistics.mean(data["memory_rss"]) if data["memory_rss"] else 0
            max_cpu = max(data["cpu_percent"]) if data["cpu_percent"] else 0
            max_mem = max(data["memory_rss"]) if data["memory_rss"] else 0
            
            self.log(f"  PID {pid} ({component_type}/{component_name}):")
            self.log(f"    CPU: Avg {avg_cpu:.1f}% | Max {max_cpu:.1f}%")
            self.log(f"    Memory: Avg {avg_mem:.1f} MB | Max {max_mem:.1f} MB")
            
            # I/O stats if available
            if data["io_read_bytes"] and len(data["io_read_bytes"]) > 1:
                io_read_delta = data["io_read_bytes"][-1] - data["io_read_bytes"][0]
                io_write_delta = data["io_write_bytes"][-1] - data["io_write_bytes"][0]
                self.log(f"    I/O: Read {io_read_delta / 1024:.1f} KB | Write {io_write_delta / 1024:.1f} KB")
        
        # Theme summary
        if self.collected_data["theme_data"]:
            self.log("\nTheme Resource Usage:")
            for theme, data in self.collected_data["theme_data"].items():
                if not data["cpu"]:
                    continue
                
                avg_cpu = statistics.mean(data["cpu"]) if data["cpu"] else 0
                avg_mem = statistics.mean(data["memory"]) if data["memory"] else 0
                
                self.log(f"  {theme}:")
                self.log(f"    CPU: Avg {avg_cpu:.1f}% | Memory: Avg {avg_mem:.1f} MB")
        
        # Plugin summary
        if self.collected_data["plugin_data"]:
            self.log("\nPlugin Resource Usage:")
            for plugin, data in self.collected_data["plugin_data"].items():
                if not data["cpu"]:
                    continue
                
                avg_cpu = statistics.mean(data["cpu"]) if data["cpu"] else 0
                avg_mem = statistics.mean(data["memory"]) if data["memory"] else 0
                
                self.log(f"  {plugin}:")
                self.log(f"    CPU: Avg {avg_cpu:.1f}% | Memory: Avg {avg_mem:.1f} MB")
        
        return self.collected_data


def monitor_hyprsupreme_switch_theme(theme_name, duration=10):
    """Monitor resources during theme switching."""
    monitor = ResourceMonitor(interval=0.2)
    
    # Start monitoring in a separate thread
    monitor_thread = threading.Thread(target=monitor.monitor_resources, args=(duration,))
    monitor_thread.daemon = True
    monitor_thread.start()
    
    # Wait a bit to establish baseline
    time.sleep(1)
    
    # Execute theme switch
    try:
        subprocess.run(["hyprsupreme", "theme", "apply", theme_name], check=True)
        print(f"Switched to theme: {theme_name}")
    except subprocess.CalledProcessError as e:
        print(f"Error switching theme: {e}")
    
    # Wait for monitoring to complete
    monitor_thread.join()
    
    # Analyze and return data
    return monitor.analyze_data()


def monitor_hyprsupreme_enable_plugin(plugin_name, duration=10):
    """Monitor resources during plugin enabling."""
    monitor = ResourceMonitor(interval=0.2)
    
    # Start monitoring in a separate thread
    monitor_thread = threading.Thread(target=monitor.monitor_resources, args=(duration,))
    monitor_thread.daemon = True
    monitor_thread.start()
    
    # Wait a bit to establish baseline
    time.sleep(1)
    
    # Execute plugin enable
    try:
        subprocess.run(["hyprsupreme", "plugin", "enable", plugin_name], check=True)
        print(f"Enabled plugin: {plugin_name}")
    except subprocess.CalledProcessError as e:
        print(f"Error enabling plugin: {e}")
    
    # Wait for monitoring to complete
    monitor_thread.join()
    
    # Analyze and return data
    return monitor.analyze_data()


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="HyprSupreme Resource Monitor")
    parser.add_argument("--interval", type=float, default=DEFAULT_INTERVAL,
                        help=f"Sampling interval in seconds (default: {DEFAULT_INTERVAL})")
    parser.add_argument("--duration", type=int, default=DEFAULT_DURATION,
                        help=f"Monitoring duration in seconds (default: {DEFAULT_DURATION})")
    parser.add_argument("--theme", type=str,
                        help="Monitor resources while switching to the specified theme")
    parser.add_argument("--plugin", type=str,
                        help="Monitor resources while enabling the specified plugin")
    parser.add_argument("--analyze", type=str,
                        help="Analyze an existing data file")
    
    args = parser.parse_args()
    
    # Handle special monitoring cases
    if args.theme:
        monitor_hyprsupreme_switch_theme(args.theme, args.duration)
        return
    
    if args.plugin:
        monitor_hyprsupreme_enable_plugin(args.plugin, args.duration)
        return
    
    if args.analyze:
        try:
            with open(args.analyze, "r") as f:
                data = json.load(f)
            
            # Create a monitor instance and inject the data
            monitor = ResourceMonitor()
            monitor.collected_data = data
            monitor.analyze_data()
            return
        except Exception as e:
            print(f"Error analyzing data file: {e}")
            return
    
    # Default operation: monitor all HyprSupreme processes
    monitor = ResourceMonitor(interval=args.interval)
    monitor.monitor_resources(duration=args.duration)
    monitor.analyze_data()


if __name__ == "__main__":
    main()
