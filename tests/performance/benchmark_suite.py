#!/usr/bin/env python3
"""
Comprehensive benchmark suite for HyprSupreme-Builder.
Tests performance of various components and operations.
"""

import os
import sys
import time
import json
import argparse
import subprocess
import resource
import psutil
import multiprocessing
from pathlib import Path
from datetime import datetime

# Add parent directory to path to import modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

# Constants
RESULT_DIR = Path(os.path.expanduser("~/.local/share/hyprsupreme/benchmark"))
LOG_FILE = RESULT_DIR / "benchmark_suite.log"
DEFAULT_TESTS = [
    "theme_switching",
    "plugin_loading",
    "config_generation",
    "system_response"
]


def log(message):
    """Log message to file and stdout."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message = f"[{timestamp}] {message}"
    print(log_message)
    
    # Ensure directory exists
    RESULT_DIR.mkdir(parents=True, exist_ok=True)
    
    with open(LOG_FILE, "a") as f:
        f.write(log_message + "\n")


def run_command(command):
    """Run a command and return its output and execution time."""
    start_time = time.time()
    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True
        )
        output = result.stdout
        success = True
    except subprocess.CalledProcessError as e:
        output = e.stderr
        success = False
    
    end_time = time.time()
    execution_time = (end_time - start_time) * 1000  # Convert to milliseconds
    
    return {
        "success": success,
        "output": output,
        "execution_time_ms": execution_time
    }


def get_system_metrics():
    """Get current system metrics."""
    metrics = {}
    
    # CPU usage
    metrics["cpu_percent"] = psutil.cpu_percent(interval=0.1)
    
    # Memory usage
    memory = psutil.virtual_memory()
    metrics["memory_used_percent"] = memory.percent
    metrics["memory_used_mb"] = memory.used / (1024 * 1024)
    metrics["memory_available_mb"] = memory.available / (1024 * 1024)
    
    # Disk I/O
    disk_io = psutil.disk_io_counters()
    metrics["disk_read_mb"] = disk_io.read_bytes / (1024 * 1024) if disk_io else 0
    metrics["disk_write_mb"] = disk_io.write_bytes / (1024 * 1024) if disk_io else 0
    
    # Process information
    process = psutil.Process(os.getpid())
    metrics["process_memory_mb"] = process.memory_info().rss / (1024 * 1024)
    metrics["process_cpu_percent"] = process.cpu_percent(interval=0.1)
    
    return metrics


def benchmark_theme_switching(themes=None, iterations=5):
    """Benchmark theme switching performance."""
    if themes is None:
        themes = ["tokyo-night", "catppuccin-mocha", "catppuccin-latte"]
    
    log(f"Running theme switching benchmark ({iterations} iterations per theme)")
    results = []
    
    for theme in themes:
        theme_results = []
        log(f"  Testing theme: {theme}")
        
        for i in range(iterations):
            before_metrics = get_system_metrics()
            cmd_result = run_command(["hyprsupreme", "theme", "apply", theme])
            after_metrics = get_system_metrics()
            
            result = {
                "theme": theme,
                "iteration": i + 1,
                "execution_time_ms": cmd_result["execution_time_ms"],
                "success": cmd_result["success"],
                "memory_delta_mb": after_metrics["process_memory_mb"] - before_metrics["process_memory_mb"],
                "cpu_usage_percent": after_metrics["process_cpu_percent"]
            }
            
            theme_results.append(result)
            log(f"    Iteration {i+1}: {result['execution_time_ms']:.2f} ms")
        
        # Calculate averages
        avg_time = sum(r["execution_time_ms"] for r in theme_results) / len(theme_results)
        avg_memory = sum(r["memory_delta_mb"] for r in theme_results) / len(theme_results)
        
        results.append({
            "theme": theme,
            "average_time_ms": avg_time,
            "average_memory_delta_mb": avg_memory,
            "iterations": theme_results
        })
        
        log(f"  Average for {theme}: {avg_time:.2f} ms, {avg_memory:.2f} MB")
    
    return results


def benchmark_plugin_loading(plugins=None, iterations=5):
    """Benchmark plugin loading performance."""
    if plugins is None:
        plugins = ["auto-theme-switcher", "workspace-manager"]
    
    log(f"Running plugin loading benchmark ({iterations} iterations per plugin)")
    results = []
    
    for plugin in plugins:
        plugin_results = []
        log(f"  Testing plugin: {plugin}")
        
        # First disable the plugin to ensure clean state
        run_command(["hyprsupreme", "plugin", "disable", plugin])
        
        for i in range(iterations):
            # Enable the plugin and measure performance
            before_metrics = get_system_metrics()
            cmd_result = run_command(["hyprsupreme", "plugin", "enable", plugin])
            after_metrics = get_system_metrics()
            
            result = {
                "plugin": plugin,
                "iteration": i + 1,
                "execution_time_ms": cmd_result["execution_time_ms"],
                "success": cmd_result["success"],
                "memory_delta_mb": after_metrics["process_memory_mb"] - before_metrics["process_memory_mb"],
                "cpu_usage_percent": after_metrics["process_cpu_percent"]
            }
            
            plugin_results.append(result)
            log(f"    Iteration {i+1}: {result['execution_time_ms']:.2f} ms")
            
            # Disable the plugin for the next iteration
            run_command(["hyprsupreme", "plugin", "disable", plugin])
            time.sleep(1)  # Give the system time to fully unload
        
        # Calculate averages
        avg_time = sum(r["execution_time_ms"] for r in plugin_results) / len(plugin_results)
        avg_memory = sum(r["memory_delta_mb"] for r in plugin_results) / len(plugin_results)
        
        results.append({
            "plugin": plugin,
            "average_time_ms": avg_time,
            "average_memory_delta_mb": avg_memory,
            "iterations": plugin_results
        })
        
        log(f"  Average for {plugin}: {avg_time:.2f} ms, {avg_memory:.2f} MB")
    
    return results


def benchmark_config_generation(profiles=None, iterations=5):
    """Benchmark configuration generation performance."""
    if profiles is None:
        profiles = ["default", "gaming", "minimal"]
    
    log(f"Running configuration generation benchmark ({iterations} iterations per profile)")
    results = []
    
    for profile in profiles:
        profile_results = []
        log(f"  Testing profile: {profile}")
        
        for i in range(iterations):
            before_metrics = get_system_metrics()
            cmd_result = run_command(["hyprsupreme", "config", "generate", "--profile", profile, "--dry-run"])
            after_metrics = get_system_metrics()
            
            result = {
                "profile": profile,
                "iteration": i + 1,
                "execution_time_ms": cmd_result["execution_time_ms"],
                "success": cmd_result["success"],
                "memory_delta_mb": after_metrics["process_memory_mb"] - before_metrics["process_memory_mb"],
                "cpu_usage_percent": after_metrics["process_cpu_percent"]
            }
            
            profile_results.append(result)
            log(f"    Iteration {i+1}: {result['execution_time_ms']:.2f} ms")
        
        # Calculate averages
        avg_time = sum(r["execution_time_ms"] for r in profile_results) / len(profile_results)
        avg_memory = sum(r["memory_delta_mb"] for r in profile_results) / len(profile_results)
        
        results.append({
            "profile": profile,
            "average_time_ms": avg_time,
            "average_memory_delta_mb": avg_memory,
            "iterations": profile_results
        })
        
        log(f"  Average for {profile}: {avg_time:.2f} ms, {avg_memory:.2f} MB")
    
    return results


def benchmark_system_response(operations=None, iterations=5):
    """Benchmark system response time for various operations."""
    if operations is None:
        operations = [
            {"name": "list_themes", "command": ["hyprsupreme", "theme", "list"]},
            {"name": "list_plugins", "command": ["hyprsupreme", "plugin", "list"]},
            {"name": "show_status", "command": ["hyprsupreme", "status"]},
            {"name": "cache_status", "command": ["hyprsupreme", "cache", "status"]}
        ]
    
    log(f"Running system response benchmark ({iterations} iterations per operation)")
    results = []
    
    for operation in operations:
        operation_results = []
        log(f"  Testing operation: {operation['name']}")
        
        for i in range(iterations):
            before_metrics = get_system_metrics()
            cmd_result = run_command(operation["command"])
            after_metrics = get_system_metrics()
            
            result = {
                "operation": operation["name"],
                "iteration": i + 1,
                "execution_time_ms": cmd_result["execution_time_ms"],
                "success": cmd_result["success"],
                "memory_delta_mb": after_metrics["process_memory_mb"] - before_metrics["process_memory_mb"],
                "cpu_usage_percent": after_metrics["process_cpu_percent"]
            }
            
            operation_results.append(result)
            log(f"    Iteration {i+1}: {result['execution_time_ms']:.2f} ms")
        
        # Calculate averages
        avg_time = sum(r["execution_time_ms"] for r in operation_results) / len(operation_results)
        avg_memory = sum(r["memory_delta_mb"] for r in operation_results) / len(operation_results)
        
        results.append({
            "operation": operation["name"],
            "average_time_ms": avg_time,
            "average_memory_delta_mb": avg_memory,
            "iterations": operation_results
        })
        
        log(f"  Average for {operation['name']}: {avg_time:.2f} ms, {avg_memory:.2f} MB")
    
    return results


def run_benchmark_suite(tests=None, iterations=5):
    """Run the complete benchmark suite."""
    if tests is None:
        tests = DEFAULT_TESTS
    
    log("Starting HyprSupreme Benchmark Suite")
    log("==================================")
    
    results = {
        "timestamp": datetime.now().isoformat(),
        "system_info": get_system_info(),
        "iterations": iterations,
        "tests": {}
    }
    
    # Run selected tests
    if "theme_switching" in tests:
        results["tests"]["theme_switching"] = benchmark_theme_switching(iterations=iterations)
    
    if "plugin_loading" in tests:
        results["tests"]["plugin_loading"] = benchmark_plugin_loading(iterations=iterations)
    
    if "config_generation" in tests:
        results["tests"]["config_generation"] = benchmark_config_generation(iterations=iterations)
    
    if "system_response" in tests:
        results["tests"]["system_response"] = benchmark_system_response(iterations=iterations)
    
    return results


def get_system_info():
    """Collect system information for benchmarking context."""
    info = {
        "os": "",
        "cpu": {
            "model": "",
            "cores": multiprocessing.cpu_count()
        },
        "memory": {
            "total": "",
            "available": ""
        },
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
        info["cpu"]["model"] = cpu_info.split(":")[1].strip()
    except:
        info["cpu"]["model"] = "Unknown"
    
    try:
        # Get memory information
        memory = psutil.virtual_memory()
        info["memory"]["total"] = f"{memory.total / (1024**3):.2f} GB"
        info["memory"]["available"] = f"{memory.available / (1024**3):.2f} GB"
    except:
        info["memory"]["total"] = "Unknown"
        info["memory"]["available"] = "Unknown"
    
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


def save_results(results):
    """Save benchmark results to file."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    result_file = RESULT_DIR / f"benchmark_suite_{timestamp}.json"
    
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
    log(f"System: {results['system_info']['os']}")
    log(f"CPU: {results['system_info']['cpu']['model']} ({results['system_info']['cpu']['cores']} cores)")
    log(f"Memory: {results['system_info']['memory']['total']}")
    log(f"GPU: {results['system_info']['gpu']}")
    log(f"Hyprland: {results['system_info']['hyprland_version']}")
    log(f"HyprSupreme: {results['system_info']['hyprsupreme_version']}")
    log("")
    
    for test_name, test_results in results["tests"].items():
        log(f"\n{test_name.upper()} TEST RESULTS:")
        log("-" * (len(test_name) + 13))
        
        for item in test_results:
            if "theme" in item:
                log(f"  Theme: {item['theme']}")
                log(f"    Average time: {item['average_time_ms']:.2f} ms")
                log(f"    Average memory delta: {item['average_memory_delta_mb']:.2f} MB")
            elif "plugin" in item:
                log(f"  Plugin: {item['plugin']}")
                log(f"    Average time: {item['average_time_ms']:.2f} ms")
                log(f"    Average memory delta: {item['average_memory_delta_mb']:.2f} MB")
            elif "profile" in item:
                log(f"  Profile: {item['profile']}")
                log(f"    Average time: {item['average_time_ms']:.2f} ms")
                log(f"    Average memory delta: {item['average_memory_delta_mb']:.2f} MB")
            elif "operation" in item:
                log(f"  Operation: {item['operation']}")
                log(f"    Average time: {item['average_time_ms']:.2f} ms")
                log(f"    Average memory delta: {item['average_memory_delta_mb']:.2f} MB")


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="HyprSupreme Benchmark Suite")
    parser.add_argument("--tests", nargs="+", choices=DEFAULT_TESTS, default=DEFAULT_TESTS,
                        help=f"Tests to run (default: {', '.join(DEFAULT_TESTS)})")
    parser.add_argument("--iterations", type=int, default=5,
                        help="Number of iterations per test (default: 5)")
    parser.add_argument("--output", type=str, default=None,
                        help="Output file path (default: auto-generated)")
    
    args = parser.parse_args()
    
    try:
        results = run_benchmark_suite(args.tests, args.iterations)
        result_file = save_results(results)
        print_summary(results)
        log(f"\nBenchmark completed successfully. Results saved to {result_file}")
    except Exception as e:
        log(f"Error during benchmark: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
