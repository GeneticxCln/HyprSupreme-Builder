#!/usr/bin/env python3
"""
Performance tests for the HyprSupreme-Builder theme switching system.
"""

import os
import sys
import time
import json
import argparse
import subprocess
import statistics
import resource
from pathlib import Path
from datetime import datetime

# Add parent directory to path to import modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

# Try to import hyprsupreme modules
try:
    from modules.themes.theme_manager import ThemeManager
except ImportError:
    print("Warning: Unable to import HyprSupreme modules directly, using CLI interface")
    ThemeManager = None

# Constants
DEFAULT_ITERATIONS = 5
DEFAULT_THEMES = ["tokyo-night", "catppuccin-mocha", "catppuccin-latte"]
RESULT_DIR = Path(os.path.expanduser("~/.local/share/hyprsupreme/benchmark"))
LOG_FILE = RESULT_DIR / "theme_switching_benchmark.log"


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


def measure_theme_switch(theme_name, use_api=False):
    """Measure time and resources used to switch to a theme."""
    # Record start time and memory
    start_time = time.time()
    start_memory = get_memory_usage()
    
    # Switch theme using API or CLI
    if use_api and ThemeManager:
        theme_manager = ThemeManager()
        theme_manager.apply_theme(theme_name)
    else:
        subprocess.run(["hyprsupreme", "theme", "apply", theme_name], check=True)
    
    # Record end time and memory
    end_time = time.time()
    end_memory = get_memory_usage()
    
    # Calculate metrics
    switch_time = (end_time - start_time) * 1000  # Convert to milliseconds
    memory_delta = end_memory - start_memory
    
    return {
        "theme": theme_name,
        "switch_time_ms": switch_time,
        "memory_delta_mb": memory_delta
    }


def run_benchmark(themes=None, iterations=DEFAULT_ITERATIONS, use_api=False):
    """Run theme switching benchmark with multiple themes and iterations."""
    if themes is None:
        themes = DEFAULT_THEMES
    
    results = []
    
    log(f"Starting theme switching benchmark with {iterations} iterations")
    log(f"Testing themes: {', '.join(themes)}")
    
    # Collect system information
    system_info = get_system_info()
    log(f"System: {system_info['os']} | CPU: {system_info['cpu']} | Memory: {system_info['memory']} | GPU: {system_info['gpu']}")
    
    # Warm up - apply default theme once
    log("Warming up...")
    measure_theme_switch(themes[0], use_api)
    
    # Run benchmark
    for i in range(iterations):
        log(f"Iteration {i+1}/{iterations}")
        
        for theme in themes:
            log(f"  Switching to {theme}...")
            result = measure_theme_switch(theme, use_api)
            results.append(result)
            log(f"  Switch time: {result['switch_time_ms']:.2f} ms | Memory delta: {result['memory_delta_mb']:.2f} MB")
    
    return analyze_results(results, system_info)


def analyze_results(results, system_info):
    """Analyze benchmark results and generate statistics."""
    # Group results by theme
    theme_results = {}
    for result in results:
        theme = result["theme"]
        if theme not in theme_results:
            theme_results[theme] = {
                "switch_times": [],
                "memory_deltas": []
            }
        
        theme_results[theme]["switch_times"].append(result["switch_time_ms"])
        theme_results[theme]["memory_deltas"].append(result["memory_delta_mb"])
    
    # Calculate statistics
    stats = {
        "system_info": system_info,
        "date": datetime.now().isoformat(),
        "themes": {}
    }
    
    for theme, data in theme_results.items():
        switch_times = data["switch_times"]
        memory_deltas = data["memory_deltas"]
        
        stats["themes"][theme] = {
            "switch_time_ms": {
                "min": min(switch_times),
                "max": max(switch_times),
                "avg": statistics.mean(switch_times),
                "median": statistics.median(switch_times),
                "stdev": statistics.stdev(switch_times) if len(switch_times) > 1 else 0
            },
            "memory_delta_mb": {
                "min": min(memory_deltas),
                "max": max(memory_deltas),
                "avg": statistics.mean(memory_deltas),
                "median": statistics.median(memory_deltas),
                "stdev": statistics.stdev(memory_deltas) if len(memory_deltas) > 1 else 0
            },
            "raw_data": {
                "switch_times": switch_times,
                "memory_deltas": memory_deltas
            }
        }
    
    return stats


def save_results(results):
    """Save benchmark results to file."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    result_file = RESULT_DIR / f"theme_switching_benchmark_{timestamp}.json"
    
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
    
    for theme, data in results["themes"].items():
        log(f"\nTheme: {theme}")
        log(f"  Switch Time (ms):")
        log(f"    Min: {data['switch_time_ms']['min']:.2f}")
        log(f"    Max: {data['switch_time_ms']['max']:.2f}")
        log(f"    Avg: {data['switch_time_ms']['avg']:.2f}")
        log(f"    Median: {data['switch_time_ms']['median']:.2f}")
        
        log(f"  Memory Delta (MB):")
        log(f"    Min: {data['memory_delta_mb']['min']:.2f}")
        log(f"    Max: {data['memory_delta_mb']['max']:.2f}")
        log(f"    Avg: {data['memory_delta_mb']['avg']:.2f}")
        log(f"    Median: {data['memory_delta_mb']['median']:.2f}")


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="HyprSupreme Theme Switching Benchmark")
    parser.add_argument("--themes", nargs="+", default=DEFAULT_THEMES,
                        help=f"Themes to test (default: {', '.join(DEFAULT_THEMES)})")
    parser.add_argument("--iterations", type=int, default=DEFAULT_ITERATIONS,
                        help=f"Number of iterations per theme (default: {DEFAULT_ITERATIONS})")
    parser.add_argument("--use-api", action="store_true",
                        help="Use ThemeManager API instead of CLI (default: False)")
    
    args = parser.parse_args()
    
    log("HyprSupreme Theme Switching Benchmark")
    log("===================================")
    
    try:
        results = run_benchmark(args.themes, args.iterations, args.use_api)
        result_file = save_results(results)
        print_summary(results)
        log(f"\nBenchmark completed successfully. Results saved to {result_file}")
    except Exception as e:
        log(f"Error during benchmark: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
