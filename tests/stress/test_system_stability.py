#!/usr/bin/env python3
"""
Stress tests for HyprSupreme-Builder system stability.
Tests system under high load, rapid theme switching, plugin enabling/disabling,
and configuration changes.
"""

import os
import sys
import time
import json
import random
import argparse
import threading
import subprocess
import multiprocessing
from pathlib import Path
from datetime import datetime

# Add parent directory to path to import modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

try:
    import psutil
except ImportError:
    print("Error: psutil module not installed. Please install with: pip install psutil")
    sys.exit(1)

# Constants
DEFAULT_DURATION = 300  # seconds
DEFAULT_THEME_SWITCH_INTERVAL = 5  # seconds
DEFAULT_PLUGIN_TOGGLE_INTERVAL = 10  # seconds
DEFAULT_CONFIG_CHANGE_INTERVAL = 20  # seconds
DEFAULT_CPU_WORKERS = max(multiprocessing.cpu_count() - 1, 1)  # Leave one CPU core free
LOG_DIR = Path(os.path.expanduser("~/.local/share/hyprsupreme/logs"))
RESULT_DIR = Path(os.path.expanduser("~/.local/share/hyprsupreme/stress_test"))

# Default test themes and plugins
DEFAULT_THEMES = ["tokyo-night", "catppuccin-mocha", "catppuccin-latte", "dracula", "nord"]
DEFAULT_PLUGINS = ["auto-theme-switcher", "workspace-manager"]


def log(message, file=None):
    """Log message to file and stdout."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message = f"[{timestamp}] {message}"
    print(log_message)
    
    if file:
        with open(file, "a") as f:
            f.write(log_message + "\n")


def get_system_info():
    """Collect system information for stress test context."""
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


def cpu_worker():
    """Worker function to generate CPU load."""
    while True:
        # Compute-intensive operation
        _ = [i * i for i in range(10000)]
        time.sleep(0.01)  # Small sleep to prevent 100% CPU lock


def start_cpu_load(num_workers):
    """Start CPU load workers."""
    workers = []
    for _ in range(num_workers):
        worker = threading.Thread(target=cpu_worker)
        worker.daemon = True
        worker.start()
        workers.append(worker)
    return workers


def memory_worker(chunk_size_mb=50, max_chunks=5):
    """Worker function to consume memory."""
    chunks = []
    try:
        for _ in range(max_chunks):
            # Allocate chunk_size_mb MB of memory
            chunk = bytearray(chunk_size_mb * 1024 * 1024)
            chunks.append(chunk)
            time.sleep(1)
    except MemoryError:
        pass
    
    # Hold memory for a while then release
    time.sleep(5)
    chunks.clear()


def start_memory_load():
    """Start memory load worker."""
    worker = threading.Thread(target=memory_worker)
    worker.daemon = True
    worker.start()
    return worker


def disk_worker(size_mb=10, dir_path=None):
    """Worker function to generate disk I/O."""
    if dir_path is None:
        dir_path = os.path.join(os.path.expanduser("~"), ".cache", "hyprsupreme", "stress_test")
    
    os.makedirs(dir_path, exist_ok=True)
    file_path = os.path.join(dir_path, f"io_test_{int(time.time())}.dat")
    
    try:
        # Write file
        with open(file_path, "wb") as f:
            f.write(os.urandom(size_mb * 1024 * 1024))
        
        # Read file
        with open(file_path, "rb") as f:
            data = f.read()
        
        # Delete file
        os.unlink(file_path)
    except Exception as e:
        print(f"Disk worker error: {e}")


def start_disk_load(interval=5):
    """Start periodic disk I/O operations."""
    def disk_load_thread():
        while True:
            disk_worker()
            time.sleep(interval)
    
    worker = threading.Thread(target=disk_load_thread)
    worker.daemon = True
    worker.start()
    return worker


def theme_switcher(themes, interval, log_file):
    """Thread function to switch themes at regular intervals."""
    log(f"Theme switcher started with interval {interval}s", log_file)
    
    while True:
        theme = random.choice(themes)
        log(f"Switching to theme: {theme}", log_file)
        
        try:
            result = subprocess.run(
                ["hyprsupreme", "theme", "apply", theme],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=10  # Add timeout to prevent hanging
            )
            
            if result.returncode == 0:
                log(f"Successfully switched to theme: {theme}", log_file)
            else:
                log(f"Failed to switch to theme: {theme}. Error: {result.stderr.decode()}", log_file)
        except subprocess.TimeoutExpired:
            log(f"Timeout when switching to theme: {theme}", log_file)
        except Exception as e:
            log(f"Error switching theme: {e}", log_file)
        
        time.sleep(interval)


def plugin_toggler(plugins, interval, log_file):
    """Thread function to toggle plugins at regular intervals."""
    log(f"Plugin toggler started with interval {interval}s", log_file)
    
    # Get initial plugin status
    plugin_status = {plugin: False for plugin in plugins}
    
    while True:
        plugin = random.choice(plugins)
        action = "enable" if not plugin_status[plugin] else "disable"
        
        log(f"{action.capitalize()}ing plugin: {plugin}", log_file)
        
        try:
            result = subprocess.run(
                ["hyprsupreme", "plugin", action, plugin],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=10  # Add timeout to prevent hanging
            )
            
            if result.returncode == 0:
                plugin_status[plugin] = not plugin_status[plugin]
                log(f"Successfully {action}d plugin: {plugin}", log_file)
            else:
                log(f"Failed to {action} plugin: {plugin}. Error: {result.stderr.decode()}", log_file)
        except subprocess.TimeoutExpired:
            log(f"Timeout when {action}ing plugin: {plugin}", log_file)
        except Exception as e:
            log(f"Error toggling plugin: {e}", log_file)
        
        time.sleep(interval)


def config_changer(interval, log_file):
    """Thread function to make random config changes."""
    log(f"Config changer started with interval {interval}s", log_file)
    
    # Define configuration options to change
    config_options = [
        ("general:gaps_in", str(random.randint(0, 15))),
        ("general:gaps_out", str(random.randint(0, 20))),
        ("general:border_size", str(random.randint(1, 5))),
        ("decoration:rounding", str(random.randint(0, 15))),
        ("decoration:blur", str(random.choice([True, False]).lower())),
        ("decoration:drop_shadow", str(random.choice([True, False]).lower())),
        ("animations:enabled", str(random.choice([True, False]).lower())),
        ("input:sensitivity", str(random.uniform(0.3, 1.2)))
    ]
    
    while True:
        # Select a random config option
        section, option = random.choice(config_options)
        
        log(f"Changing config option: {section} = {option}", log_file)
        
        try:
            result = subprocess.run(
                ["hyprsupreme", "config", "set", section, option],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=10  # Add timeout to prevent hanging
            )
            
            if result.returncode == 0:
                log(f"Successfully changed config: {section} = {option}", log_file)
            else:
                log(f"Failed to change config: {section} = {option}. Error: {result.stderr.decode()}", log_file)
        except subprocess.TimeoutExpired:
            log(f"Timeout when changing config: {section} = {option}", log_file)
        except Exception as e:
            log(f"Error changing config: {e}", log_file)
        
        time.sleep(interval)


def monitor_system_stats(interval, duration, log_file, result_file):
    """Monitor system statistics during stress test."""
    log(f"System monitor started with interval {interval}s", log_file)
    
    stats = {
        "timestamp": [],
        "cpu_percent": [],
        "memory_percent": [],
        "swap_percent": [],
        "disk_io_read": [],
        "disk_io_write": [],
        "hyprsupreme_processes": [],
        "hyprsupreme_cpu_percent": [],
        "hyprsupreme_memory_percent": []
    }
    
    start_time = time.time()
    end_time = start_time + duration
    
    while time.time() < end_time:
        timestamp = datetime.now().isoformat()
        stats["timestamp"].append(timestamp)
        
        # System CPU and memory
        stats["cpu_percent"].append(psutil.cpu_percent(interval=0.1))
        stats["memory_percent"].append(psutil.virtual_memory().percent)
        stats["swap_percent"].append(psutil.swap_memory().percent)
        
        # Disk I/O
        disk_io = psutil.disk_io_counters()
        stats["disk_io_read"].append(disk_io.read_bytes)
        stats["disk_io_write"].append(disk_io.write_bytes)
        
        # HyprSupreme process monitoring
        hyprsupreme_processes = []
        hyprsupreme_cpu = []
        hyprsupreme_mem = []
        
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                cmdline = " ".join(proc.info['cmdline'] if proc.info['cmdline'] else [])
                if "hyprsupreme" in cmdline.lower():
                    hyprsupreme_processes.append(proc.pid)
                    hyprsupreme_cpu.append(proc.cpu_percent(interval=0.1))
                    hyprsupreme_mem.append(proc.memory_percent())
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        
        stats["hyprsupreme_processes"].append(len(hyprsupreme_processes))
        stats["hyprsupreme_cpu_percent"].append(sum(hyprsupreme_cpu) if hyprsupreme_cpu else 0)
        stats["hyprsupreme_memory_percent"].append(sum(hyprsupreme_mem) if hyprsupreme_mem else 0)
        
        # Log current stats
        elapsed = time.time() - start_time
        remaining = duration - elapsed
        log(f"[{elapsed:.0f}s/{duration}s] CPU: {stats['cpu_percent'][-1]:.1f}% | "
            f"Mem: {stats['memory_percent'][-1]:.1f}% | "
            f"HyprSupreme processes: {stats['hyprsupreme_processes'][-1]} | "
            f"HyprSupreme CPU: {stats['hyprsupreme_cpu_percent'][-1]:.1f}%", log_file)
        
        # Sleep until next interval
        time.sleep(interval)
    
    # Save stats to result file
    with open(result_file, "w") as f:
        json.dump(stats, f, indent=2)
    
    log(f"System monitoring complete. Stats saved to {result_file}", log_file)
    return stats


def run_stress_test(args):
    """Run the stress test with specified parameters."""
    # Set up logging and result directories
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    RESULT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Create session ID and log files
    session_id = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = LOG_DIR / f"stress_test_{session_id}.log"
    result_file = RESULT_DIR / f"stress_test_results_{session_id}.json"
    
    # Initialize log file
    with open(log_file, "w") as f:
        f.write(f"HyprSupreme Stress Test Session {session_id}\n")
        f.write(f"Started at: {datetime.now().isoformat()}\n\n")
    
    # Log test parameters
    log(f"Starting HyprSupreme stress test with the following parameters:", log_file)
    log(f"Duration: {args.duration} seconds", log_file)
    log(f"Theme switch interval: {args.theme_interval} seconds", log_file)
    log(f"Plugin toggle interval: {args.plugin_interval} seconds", log_file)
    log(f"Config change interval: {args.config_interval} seconds", log_file)
    log(f"CPU workers: {args.cpu_workers}", log_file)
    log(f"Themes: {args.themes}", log_file)
    log(f"Plugins: {args.plugins}", log_file)
    
    # Collect and log system information
    system_info = get_system_info()
    log(f"System info:", log_file)
    for key, value in system_info.items():
        log(f"  {key}: {value}", log_file)
    
    # Start system monitor
    log("Starting system monitor...", log_file)
    monitor_thread = threading.Thread(
        target=monitor_system_stats,
        args=(5, args.duration, log_file, result_file)
    )
    monitor_thread.daemon = True
    monitor_thread.start()
    
    # Start CPU load if enabled
    cpu_workers = []
    if args.cpu_load:
        log(f"Starting CPU load with {args.cpu_workers} workers...", log_file)
        cpu_workers = start_cpu_load(args.cpu_workers)
    
    # Start memory load if enabled
    memory_worker = None
    if args.memory_load:
        log("Starting memory load...", log_file)
        memory_worker = start_memory_load()
    
    # Start disk load if enabled
    disk_worker = None
    if args.disk_load:
        log("Starting disk I/O load...", log_file)
        disk_worker = start_disk_load()
    
    # Start theme switcher if enabled
    theme_thread = None
    if args.theme_switching:
        log(f"Starting theme switcher with interval {args.theme_interval}s...", log_file)
        theme_thread = threading.Thread(
            target=theme_switcher,
            args=(args.themes, args.theme_interval, log_file)
        )
        theme_thread.daemon = True
        theme_thread.start()
    
    # Start plugin toggler if enabled
    plugin_thread = None
    if args.plugin_toggling:
        log(f"Starting plugin toggler with interval {args.plugin_interval}s...", log_file)
        plugin_thread = threading.Thread(
            target=plugin_toggler,
            args=(args.plugins, args.plugin_interval, log_file)
        )
        plugin_thread.daemon = True
        plugin_thread.start()
    
    # Start config changer if enabled
    config_thread = None
    if args.config_changing:
        log(f"Starting config changer with interval {args.config_interval}s...", log_file)
        config_thread = threading.Thread(
            target=config_changer,
            args=(args.config_interval, log_file)
        )
        config_thread.daemon = True
        config_thread.start()
    
    # Wait for test duration
    log(f"Stress test running for {args.duration} seconds...", log_file)
    try:
        start_time = time.time()
        while time.time() - start_time < args.duration:
            time.sleep(1)
            elapsed = time.time() - start_time
            if elapsed % 30 == 0:  # Log every 30 seconds
                log(f"Stress test running... Elapsed: {elapsed:.0f}s / {args.duration}s", log_file)
    
    except KeyboardInterrupt:
        log("Stress test interrupted by user", log_file)
    
    finally:
        log("Stress test completed", log_file)
        
        # Ensure monitor thread completes
        if monitor_thread.is_alive():
            monitor_thread.join(timeout=10)
        
        # Generate report
        generate_report(session_id, log_file, result_file, system_info)
        
        log(f"Test results saved to {result_file}", log_file)
        log(f"Log file: {log_file}", log_file)


def generate_report(session_id, log_file, result_file, system_info):
    """Generate a comprehensive report of the stress test."""
    report_file = RESULT_DIR / f"stress_test_report_{session_id}.html"
    
    # Read stats from result file
    try:
        with open(result_file, "r") as f:
            stats = json.load(f)
    except:
        log(f"Error reading result file: {result_file}", log_file)
        return
    
    # Count issues from log file
    error_count = 0
    timeout_count = 0
    success_count = 0
    
    try:
        with open(log_file, "r") as f:
            for line in f:
                if "Error" in line or "Failed" in line:
                    error_count += 1
                elif "Timeout" in line:
                    timeout_count += 1
                elif "Successfully" in line:
                    success_count += 1
    except:
        log(f"Error reading log file: {log_file}", log_file)
    
    # Calculate statistics
    avg_cpu = sum(stats["cpu_percent"]) / len(stats["cpu_percent"]) if stats["cpu_percent"] else 0
    max_cpu = max(stats["cpu_percent"]) if stats["cpu_percent"] else 0
    avg_mem = sum(stats["memory_percent"]) / len(stats["memory_percent"]) if stats["memory_percent"] else 0
    max_mem = max(stats["memory_percent"]) if stats["memory_percent"] else 0
    
    avg_hyprsupreme_cpu = sum(stats["hyprsupreme_cpu_percent"]) / len(stats["hyprsupreme_cpu_percent"]) if stats["hyprsupreme_cpu_percent"] else 0
    max_hyprsupreme_cpu = max(stats["hyprsupreme_cpu_percent"]) if stats["hyprsupreme_cpu_percent"] else 0
    avg_hyprsupreme_mem = sum(stats["hyprsupreme_memory_percent"]) / len(stats["hyprsupreme_memory_percent"]) if stats["hyprsupreme_memory_percent"] else 0
    max_hyprsupreme_mem = max(stats["hyprsupreme_memory_percent"]) if stats["hyprsupreme_memory_percent"] else 0
    
    # Generate HTML report
    html = f"""<!DOCTYPE html>
<html>
<head>
    <title>HyprSupreme Stress Test Report - {session_id}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        h1, h2, h3 {{ color: #333; }}
        .summary {{ background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-bottom: 20px; }}
        .stats {{ display: flex; flex-wrap: wrap; }}
        .stat-box {{ background-color: #e9e9e9; padding: 10px; margin: 10px; border-radius: 5px; min-width: 200px; }}
        .success {{ color: green; }}
        .warning {{ color: orange; }}
        .error {{ color: red; }}
        table {{ border-collapse: collapse; width: 100%; }}
        th, td {{ padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }}
        th {{ background-color: #f2f2f2; }}
        tr:hover {{ background-color: #f5f5f5; }}
    </style>
</head>
<body>
    <h1>HyprSupreme Stress Test Report</h1>
    <p>Session ID: {session_id}</p>
    <p>Date: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <p><strong>System:</strong> {system_info.get('os', 'Unknown')}</p>
        <p><strong>CPU:</strong> {system_info.get('cpu', 'Unknown')}</p>
        <p><strong>Memory:</strong> {system_info.get('memory', 'Unknown')}</p>
        <p><strong>GPU:</strong> {system_info.get('gpu', 'Unknown')}</p>
        <p><strong>Hyprland Version:</strong> {system_info.get('hyprland_version', 'Unknown')}</p>
        <p><strong>HyprSupreme Version:</strong> {system_info.get('hyprsupreme_version', 'Unknown')}</p>
    </div>
    
    <h2>Test Results</h2>
    <div class="stats">
        <div class="stat-box">
            <h3>Operation Results</h3>
            <p><span class="success">Successful operations:</span> {success_count}</p>
            <p><span class="warning">Timeouts:</span> {timeout_count}</p>
            <p><span class="error">Errors:</span> {error_count}</p>
        </div>
        
        <div class="stat-box">
            <h3>System CPU Usage</h3>
            <p>Average: {avg_cpu:.1f}%</p>
            <p>Maximum: {max_cpu:.1f}%</p>
        </div>
        
        <div class="stat-box">
            <h3>System Memory Usage</h3>
            <p>Average: {avg_mem:.1f}%</p>
            <p>Maximum: {max_mem:.1f}%</p>
        </div>
        
        <div class="stat-box">
            <h3>HyprSupreme CPU Usage</h3>
            <p>Average: {avg_hyprsupreme_cpu:.1f}%</p>
            <p>Maximum: {max_hyprsupreme_cpu:.1f}%</p>
        </div>
        
        <div class="stat-box">
            <h3>HyprSupreme Memory Usage</h3>
            <p>Average: {avg_hyprsupreme_mem:.1f}%</p>
            <p>Maximum: {max_hyprsupreme_mem:.1f}%</p>
        </div>
    </div>
    
    <h2>Detailed Results</h2>
    <p>For detailed results, please refer to the log file: {log_file}</p>
    <p>Raw data file: {result_file}</p>
    
    <h2>Conclusion</h2>
    <p>The stress test {'completed successfully' if error_count == 0 else f'completed with {error_count} errors and {timeout_count} timeouts'}.</p>
    <p>HyprSupreme {'handled the stress test well' if error_count == 0 else 'exhibited some issues during the stress test'}.</p>
</body>
</html>
"""
    
    # Write HTML report
    with open(report_file, "w") as f:
        f.write(html)
    
    log(f"Report generated: {report_file}", log_file)


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="HyprSupreme System Stability Stress Test")
    parser.add_argument("--duration", type=int, default=DEFAULT_DURATION,
                        help=f"Test duration in seconds (default: {DEFAULT_DURATION})")
    parser.add_argument("--theme-interval", type=int, default=DEFAULT_THEME_SWITCH_INTERVAL,
                        help=f"Theme switching interval in seconds (default: {DEFAULT_THEME_SWITCH_INTERVAL})")
    parser.add_argument("--plugin-interval", type=int, default=DEFAULT_PLUGIN_TOGGLE_INTERVAL,
                        help=f"Plugin toggling interval in seconds (default: {DEFAULT_PLUGIN_TOGGLE_INTERVAL})")
    parser.add_argument("--config-interval", type=int, default=DEFAULT_CONFIG_CHANGE_INTERVAL,
                        help=f"Configuration change interval in seconds (default: {DEFAULT_CONFIG_CHANGE_INTERVAL})")
    parser.add_argument("--cpu-workers", type=int, default=DEFAULT_CPU_WORKERS,
                        help=f"Number of CPU worker threads (default: {DEFAULT_CPU_WORKERS})")
    parser.add_argument("--themes", nargs="+", default=DEFAULT_THEMES,
                        help=f"Themes to test (default: {', '.join(DEFAULT_THEMES)})")
    parser.add_argument("--plugins", nargs="+", default=DEFAULT_PLUGINS,
                        help=f"Plugins to test (default: {', '.join(DEFAULT_PLUGINS)})")
    
    # Test components to enable/disable
    parser.add_argument("--no-theme-switching", dest="theme_switching", action="store_false",
                        help="Disable theme switching during test")
    parser.add_argument("--no-plugin-toggling", dest="plugin_toggling", action="store_false",
                        help="Disable plugin toggling during test")
    parser.add_argument("--no-config-changing", dest="config_changing", action="store_false",
                        help="Disable configuration changes during test")
    parser.add_argument("--no-cpu-load", dest="cpu_load", action="store_false",
                        help="Disable CPU load generation during test")
    parser.add_argument("--no-memory-load", dest="memory_load", action="store_false",
                        help="Disable memory load generation during test")
    parser.add_argument("--no-disk-load", dest="disk_load", action="store_false",
                        help="Disable disk I/O load generation during test")
    
    # Set defaults for boolean flags
    parser.set_defaults(
        theme_switching=True,
        plugin_toggling=True,
        config_changing=True,
        cpu_load=True,
        memory_load=True,
        disk_load=True
    )
    
    args = parser.parse_args()
    
    try:
        run_stress_test(args)
    except Exception as e:
        print(f"Error during stress test: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
