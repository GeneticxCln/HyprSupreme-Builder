# HyprSupreme-Builder Test Suite

This directory contains comprehensive test suites for the HyprSupreme-Builder project.

## Test Categories

- **Unit Tests**: Tests for individual components and functions
- **Integration Tests**: Tests for interactions between components
- **Performance Tests**: Tests for system performance and resource usage
- **Edge Case Tests**: Tests for handling unusual or extreme conditions
- **Stress Tests**: Tests for system stability under heavy load
- **Monitoring**: Tools for monitoring resource usage and performance

## Running Tests

### Basic Test Execution

To run all tests:

```bash
cd ~/github-build
./tests/run_tests.sh
```

To run a specific test category:

```bash
./tests/run_tests.sh unit
./tests/run_tests.sh integration
./tests/run_tests.sh performance
```

### Advanced Test Options

For more detailed test output:

```bash
./tests/run_tests.sh --verbose
```

To generate HTML test reports:

```bash
./tests/run_tests.sh --report
```

## Edge Case Testing

Edge case tests focus on unusual scenarios and boundary conditions:

```bash
./tests/run_tests.sh edge
```

These tests verify system behavior with:
- Conflicting configurations between themes and plugins
- Rapid theme/plugin switching
- Plugin dependency resolution including circular dependencies
- Configuration migration between themes
- Plugin priority conflict resolution

## Resource Monitoring

The advanced resource monitoring system provides real-time insights into system performance:

```bash
# Basic monitoring
python tests/monitoring/resource_monitor_advanced.py

# Monitor theme switching
python tests/monitoring/resource_monitor_advanced.py --monitor-theme tokyo-night

# Monitor plugin enabling
python tests/monitoring/resource_monitor_advanced.py --monitor-plugin workspace-manager

# Custom thresholds and intervals
python tests/monitoring/resource_monitor_advanced.py --cpu-threshold 70 --memory-threshold 80 --interval 2
```

The monitor provides:
- Real-time resource usage statistics
- Trend analysis with predictive alerts
- Anomaly detection using statistical methods
- Automatic trend visualization
- Detailed performance reports

## Test Development

When adding new tests:

1. Place tests in the appropriate category directory
2. Follow the naming convention: `test_*.py` or `test_*.sh`
3. Add test documentation in the test file header
4. Update this README if adding new test categories

## Continuous Integration

These tests are automatically run in the CI pipeline for each commit and pull request.
