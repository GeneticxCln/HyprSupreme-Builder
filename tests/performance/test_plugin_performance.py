#!/usr/bin/env python3
"""
Performance tests for the HyprSupreme-Builder plugin system.
Measures loading time, operation execution, and resource usage for plugins.
"""

import os
import sys
import time
import json
import argparse
import subprocess
import statistics
import resource
import psutil
from pathlib import Path
from datetime import datetime

# Add parent directory to path to import modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

# Try to import hyprsupreme modules
try:
    from modules.plugins.plugin_manager import PluginManager
except ImportError:
    print("Warning: Unable to import HyprSupreme modules directly, using CLI interface")
    PluginManager = None

# Constants
DEFAULT_ITERATIONS = 5
DEFAULT_PLUGINS = ["auto-theme-switcher", "workspace-manager"]
DEFAULT_OPERATIONS = ["enable", "disable", "status"]
RESULT_DIR = Path(os.path.expanduser("~/.local/share/hyprsupreme/benchmark"))
LOG_FILE = RESULT_DIR / "plugin_performance_benchmark.log"


def log(message):
    """Log message to file and stdout."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message = f"[{timestamp}] {message}"
    print(log_message)
    
    # Ensure directory exists
    RESULT_DIR.mkdir(parents=True, exist_ok=True)
    
    with open(LOG_FILE, "a") as f:
        f.write(log_message + "\n")


def get_memory_usage():
    """Get current memory usage in MB."""
    usage = resource.getrusage(resource.RUSAGE_SELF)
    return usage.ru_maxrss / 1024  # Convert KB to MB


def get_process_stats():
    """Get detailed process statistics."""
    process = psutil.Process(os.getpid())
    stats = {
        "cpu_percent": process.cpu_percent(interval=0.1),
        "memory_percent": process.memory_percent(),
        "memory_rss": process.memory_info().rss / (1024 * 1024),  # MB
        "threads": process.num_threads(),
        "open_files": len(process.open_files()),
        "io_counters": None
    }
    
    try:
        io = process.io_counters()
        stats["io_counters"] = {
            "read_count": io.read_count,
            "write_count": io.write_count,
            "read_bytes": io.read_bytes,
            "write_bytes": io.write_bytes
        }
    except:
        # io_counters may not be available on all platforms
        pass
    
    return stats


def get_system_info():
    """Collect system information for benchmarking context."""
    info = {
        "date": datetime.now().isoformat(),
        "os": "",
        "cpu": "",
        "memory": "",
        "gpu": "",
        "hyprland_version": "",
        "hyprsupreme_version": ""
    }
    
    try:
        # Get OS information
        os_info = subprocess.check_output("cat /etc/os-release | grep PRETTY_NAME", shell=True).decode().strip()
        info["os"] = os_info.split("=")[1].strip('"')
    except:
        info["os"] = "Unknown"
    
    try:
        # Get CPU information
        cpu_info = subprocess.check_output("cat /proc/cpuinfo | grep 'model name' | head -1", shell=True).decode().strip()
        info["cpu"] = cpu_info.split(":")[1].strip()
    except:
        info["cpu"] = "Unknown"
    
    try:
        # Get memory information
        mem_info = subprocess.check_output("free -h | grep Mem", shell=True).decode().strip()
        total_mem = mem_info.split()[1]
        info["memory"] = total_mem
    except:
        info["memory"] = "Unknown"
    
    try:
        # Get GPU information
        gpu_info = subprocess.check_output("lspci | grep -E 'VGA|3D' | head -1", shell=True).decode().strip()
        info["gpu"] = gpu_info.split(":")[2].strip()
    except:
        info["gpu"] = "Unknown"
    
    try:
        # Get Hyprland version
        hyprland_version = subprocess.check_output("hyprctl version", shell=True).decode().strip()
        info["hyprland_version"] = hyprland_version.split("\n")[0]
    except:
        info["hyprland_version"] = "Unknown"
    
    try:
        # Get HyprSupreme version
        hyprsupreme_version = subprocess.check_output("hyprsupreme --version", shell=True).decode().strip()
        info["hyprsupreme_version"] = hyprsupreme_version
    except:
        info["hyprsupreme_version"] = "Unknown"
    
    return info


def perform_plugin_operation(plugin_name, operation, use_api=False):
    """Perform a plugin operation and measure performance."""
    # Record start time, memory and process stats
    start_time = time.time()
    start_memory = get_memory_usage()
    start_stats = get_process_stats()
    
    # Perform operation using API or CLI
    result_success = True
    if use_api and PluginManager:
        manager = PluginManager()
        try:
            if operation == "enable":
                manager.enable_plugin(plugin_name)
            elif operation == "disable":
                manager.disable_plugin(plugin_name)
            elif operation == "status":
                manager.get_plugin(plugin_name)
            elif operation == "list":
                manager.get_plugins()
            else:
                # Custom plugin command execution
                manager.execute_command(plugin_name, operation, [])
        except Exception as e:
            result_success = False
    else:
        try:
            if operation in ["enable", "disable", "status"]:
                subprocess.run(["hyprsupreme", "plugin", operation, plugin_name], check=True)
            elif operation == "list":
                subprocess.run(["hyprsupreme", "plugin", "list"], check=True)
            else:
                # Custom plugin command execution
                subprocess.run(["hyprsupreme", "plugin", plugin_name, operation], check=True)
        except subprocess.CalledProcessError:
            result_success = False
    
    # Record end time, memory and process stats
    end_time = time.time()
    end_memory = get_memory_usage()
    end_stats = get_process_stats()
    
    # Calculate metrics
    operation_time = (end_time - start_time) * 1000  # Convert to milliseconds
    memory_delta = end_memory - start_memory
    
    # Calculate process stat deltas
    stats_delta = {
        "cpu_percent": end_stats["cpu_percent"],
        "memory_percent_delta": end_stats["memory_percent"] - start_stats["memory_percent"],
        "memory_rss_delta": end_stats["memory_rss"] - start_stats["memory_rss"],
        "threads_delta": end_stats["threads"] - start_stats["threads"],
        "open_files_delta": end_stats["open_files"] - start_stats["open_files"]
    }
    
    if end_stats["io_counters"] and start_stats["io_counters"]:
        stats_delta["io_counters"] = {
            "read_count_delta": end_stats["io_counters"]["read_count"] - start_stats["io_counters"]["read_count"],
            "write_count_delta": end_stats["io_counters"]["write_count"] - start_stats["io_counters"]["write_count"],
            "read_bytes_delta": end_stats["io_counters"]["read_bytes"] - start_stats["io_counters"]["read_bytes"],
            "write_bytes_delta": end_stats["io_counters"]["write_bytes"] - start_stats["io_counters"]["write_bytes"]
        }
    
    return {
        "plugin": plugin_name,
        "operation": operation,
        "operation_time_ms": operation_time,
        "memory_delta_mb": memory_delta,
        "stats_delta": stats_delta,
        "success": result_success
    }


def run_benchmark(plugins=None, operations=None, iterations=DEFAULT_ITERATIONS, use_api=False):
    """Run plugin performance benchmark with multiple plugins, operations and iterations."""
    if plugins is None:
        plugins = DEFAULT_PLUGINS
    
    if operations is None:
        operations = DEFAULT_OPERATIONS
    
    results = []
    
    log(f"Starting plugin performance benchmark with {iterations} iterations")
    log(f"Testing plugins: {', '.join(plugins)}")
    log(f"Operations: {', '.join(operations)}")
    
    # Collect system information
    system_info = get_system_info()
    log(f"System: {system_info['os']} | CPU: {system_info['cpu']} | Memory: {system_info['memory']} | GPU: {system_info['gpu']}")
    
    # Warm up - perform status operation once
    log("Warming up...")
    perform_plugin_operation(plugins[0], "status", use_api)
    
    # Run benchmark
    for i in range(iterations):
        log(f"Iteration {i+1}/{iterations}")
        
        for plugin in plugins:
            for operation in operations:
                log(f"  {plugin}: {operation}...")
                
                # If the operation is enable/disable, ensure clean state
                if operation == "enable":
                    # Disable first to ensure clean state
                    try:
                        subprocess.run(["hyprsupreme", "plugin", "disable", plugin], check=False)
                    except:
                        pass
                elif operation == "disable":
                    # Enable first to ensure we can disable
                    try:
                        subprocess.run(["hyprsupreme", "plugin", "enable", plugin], check=False)
                    except:
                        pass
                
                # Perform operation and measure
                result = perform_plugin_operation(plugin, operation, use_api)
                results.append(result)
                
                # Log result
                status = "✓" if result["success"] else "✗"
                log(f"  {status} Time: {result['operation_time_ms']:.2f} ms | Memory: {result['memory_delta_mb']:.2f} MB | CPU: {result['stats_delta']['cpu_percent']:.1f}%")
    
    return analyze_results(results, system_info)


def analyze_results(results, system_info):
    """Analyze benchmark results and generate statistics."""
    # Group results by plugin and operation
    plugin_operation_results = {}
    for result in results:
        plugin = result["plugin"]
        operation = result["operation"]
        key = f"{plugin}:{operation}"
        
        if key not in plugin_operation_results:
            plugin_operation_results[key] = {
                "operation_times": [],
                "memory_deltas": [],
                "cpu_percents": [],
                "success_count": 0,
                "failure_count": 0
            }
        
        data = plugin_operation_results[key]
        data["operation_times"].append(result["operation_time_ms"])
        data["memory_deltas"].append(result["memory_delta_mb"])
        data["cpu_percents"].append(result["stats_delta"]["cpu_percent"])
        
        if result["success"]:
            data["success_count"] += 1
        else:
            data["failure_count"] += 1
    
    # Calculate statistics
    stats = {
        "system_info": system_info,
        "date": datetime.now().isoformat(),
        "plugins": {}
    }
    
    for key, data in plugin_operation_results.items():
        plugin, operation = key.split(":", 1)
        
        if plugin not in stats["plugins"]:
            stats["plugins"][plugin] = {
                "operations": {}
            }
        
        operation_times = data["operation_times"]
        memory_deltas = data["memory_deltas"]
        cpu_percents = data["cpu_percents"]
        
        stats["plugins"][plugin]["operations"][operation] = {
            "operation_time_ms": {
                "min": min(operation_times),
                "max": max(operation_times),
                "avg": statistics.mean(operation_times),
                "median": statistics.median(operation_times),
                "stdev": statistics.stdev(operation_times) if len(operation_times) > 1 else 0
            },
            "memory_delta_mb": {
                "min": min(memory_deltas),
                "max": max(memory_deltas),
                "avg": statistics.mean(memory_deltas),
                "median": statistics.median(memory_deltas),
                "stdev": statistics.stdev(memory_deltas) if len(memory_deltas) > 1 else 0
            },
            "cpu_percent": {
                "min": min(cpu_percents),
                "max": max(cpu_percents),
                "avg": statistics.mean(cpu_percents),
                "median": statistics.median(cpu_percents),
                "stdev": statistics.stdev(cpu_percents) if len(cpu_percents) > 1 else 0
            },
            "success_rate": data["success_count"] / (data["success_count"] + data["failure_count"]) * 100,
            "raw_data": {
                "operation_times": operation_times,
                "memory_deltas": memory_deltas,
                "cpu_percents": cpu_percents
            }
        }
    
    return stats


def save_results(results):
    """Save benchmark results to file."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    result_file = RESULT_DIR / f"plugin_performance_benchmark_{timestamp}.json"
    
    # Ensure directory exists
    RESULT_DIR.mkdir(parents=True, exist_ok=True)
    
    with open(result_file, "w") as f:
        json.dump(results, f, indent=2)
    
    log(f"Results saved to {result_file}")
    return result_file


def print_summary(results):
    """Print a summary of benchmark results."""
    log("\nBenchmark Summary:")
    log("=================")
    
    for plugin, plugin_data in results["plugins"].items():
        log(f"\nPlugin: {plugin}")
        
        for operation, data in plugin_data["operations"].items():
            log(f"  Operation: {operation}")
            log(f"    Success Rate: {data['success_rate']:.1f}%")
            log(f"    Operation Time (ms):")
            log(f"      Min: {data['operation_time_ms']['min']:.2f}")
            log(f"      Max: {data['operation_time_ms']['max']:.2f}")
            log(f"      Avg: {data['operation_time_ms']['avg']:.2f}")
            log(f"      Median: {data['operation_time_ms']['median']:.2f}")
            
            log(f"    Memory Delta (MB):")
            log(f"      Min: {data['memory_delta_mb']['min']:.2f}")
            log(f"      Max: {data['memory_delta_mb']['max']:.2f}")
            log(f"      Avg: {data['memory_delta_mb']['avg']:.2f}")
            log(f"      Median: {data['memory_delta_mb']['median']:.2f}")
            
            log(f"    CPU Usage (%):")
            log(f"      Min: {data['cpu_percent']['min']:.1f}")
            log(f"      Max: {data['cpu_percent']['max']:.1f}")
            log(f"      Avg: {data['cpu_percent']['avg']:.1f}")
            log(f"      Median: {data['cpu_percent']['median']:.1f}")


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="HyprSupreme Plugin Performance Benchmark")
    parser.add_argument("--plugins", nargs="+", default=DEFAULT_PLUGINS,
                        help=f"Plugins to test (default: {', '.join(DEFAULT_PLUGINS)})")
    parser.add_argument("--operations", nargs="+", default=DEFAULT_OPERATIONS,
                        help=f"Operations to test (default: {', '.join(DEFAULT_OPERATIONS)})")
    parser.add_argument("--iterations", type=int, default=DEFAULT_ITERATIONS,
                        help=f"Number of iterations per plugin and operation (default: {DEFAULT_ITERATIONS})")
    parser.add_argument("--use-api", action="store_true",
                        help="Use PluginManager API instead of CLI (default: False)")
    
    args = parser.parse_args()
    
    log("HyprSupreme Plugin Performance Benchmark")
    log("======================================")
    
    try:
        results = run_benchmark(args.plugins, args.operations, args.iterations, args.use_api)
        result_file = save_results(results)
        print_summary(results)
        log(f"\nBenchmark completed successfully. Results saved to {result_file}")
    except Exception as e:
        log(f"Error during benchmark: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
