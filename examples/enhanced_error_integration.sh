#!/bin/bash
# HyprSupreme-Builder Enhanced Error Handling Integration Example
# This demonstrates how to integrate the enhanced error management system

set -euo pipefail

# Define project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

#=====================================
# Example Integration Script
#=====================================

main() {
    echo "🚀 HyprSupreme-Builder Enhanced Error Handling Demo"
    echo "=================================================="
    echo
    
    # Initialize the enhanced error management system
    echo "📦 Loading enhanced error management system..."
    
    if [[ -f "$PROJECT_ROOT/modules/common/enhanced_error_system.sh" ]]; then
        source "$PROJECT_ROOT/modules/common/enhanced_error_system.sh"
        
        # Configure the system with desired options
        configure_enhanced_error_system \
            --enable-monitoring \
            --enable-prediction \
            --enable-self-healing \
            --enable-analytics \
            --enable-recovery \
            --interactive-recovery \
            --monitoring-interval 15
            
        echo "✅ Enhanced error management system activated!"
    else
        echo "❌ Enhanced error management system not found!"
        echo "Please ensure all error handling modules are in place."
        exit 1
    fi
    
    echo
    echo "🔧 Running demonstration tasks..."
    echo
    
    # Demonstrate enhanced error handling with various scenarios
    demonstrate_successful_operations
    demonstrate_recoverable_errors
    demonstrate_system_monitoring
    demonstrate_predictive_analysis
    
    echo
    echo "📊 Generating final comprehensive report..."
    
    # Generate a comprehensive report
    generate_comprehensive_report "examples/demo-report-$(date +%Y%m%d-%H%M%S).md"
    
    echo
    echo "🎉 Enhanced error handling demonstration completed!"
    echo "Check the generated reports in the logs/ directory for detailed analysis."
}

#=====================================
# Demonstration Functions
#=====================================

demonstrate_successful_operations() {
    echo "✨ Demonstrating successful operations with enhanced tracking..."
    
    # Execute commands with enhanced error handling
    execute_with_enhanced_error_handling echo "Testing successful command execution"
    execute_with_enhanced_error_handling ls "$PROJECT_ROOT" > /dev/null
    execute_with_enhanced_error_handling whoami > /dev/null
    execute_with_enhanced_error_handling date > /dev/null
    
    echo "✅ Successful operations completed and tracked"
}

demonstrate_recoverable_errors() {
    echo "🔄 Demonstrating recoverable error scenarios..."
    
    # Simulate recoverable errors (these will be caught and handled)
    
    # Test network error recovery
    echo "   Testing network error recovery..."
    if ! execute_with_enhanced_error_handling curl --connect-timeout 1 http://fake-url-that-does-not-exist.invalid 2>/dev/null; then
        echo "   ℹ️  Network error was handled gracefully"
    fi
    
    # Test file operation error recovery
    echo "   Testing file operation error recovery..."
    if ! execute_with_enhanced_error_handling ls /this/path/definitely/does/not/exist 2>/dev/null; then
        echo "   ℹ️  File operation error was handled gracefully"
    fi
    
    # Test package manager error (if we can simulate safely)
    echo "   Testing package manager error handling..."
    local package_manager="${PACKAGE_MANAGER:-unknown}"
    case "$package_manager" in
        pacman)
            if ! execute_with_enhanced_error_handling pacman -Q nonexistent-package-that-does-not-exist 2>/dev/null; then
                echo "   ℹ️  Package manager error was handled gracefully"
            fi
            ;;
        apt)
            if ! execute_with_enhanced_error_handling dpkg -l nonexistent-package-that-does-not-exist 2>/dev/null; then
                echo "   ℹ️  Package manager error was handled gracefully"
            fi
            ;;
        *)
            echo "   ℹ️  Package manager error simulation skipped for $package_manager"
            ;;
    esac
    
    echo "✅ Error recovery demonstrations completed"
}

demonstrate_system_monitoring() {
    echo "📊 Demonstrating system health monitoring..."
    
    # Show current system metrics
    echo "   Current system metrics:"
    echo "   - CPU Load: ${SYSTEM_HEALTH_METRICS[cpu_load]:-Unknown}"
    echo "   - Memory Usage: ${SYSTEM_HEALTH_METRICS[memory_usage]:-Unknown}%"
    echo "   - Disk Usage: ${SYSTEM_HEALTH_METRICS[disk_usage]:-Unknown}%"
    echo "   - Process Count: ${SYSTEM_HEALTH_METRICS[process_count]:-Unknown}"
    
    # Show component health status
    echo "   Component health status:"
    for component in "${!COMPONENT_STATUS[@]}"; do
        local status="${COMPONENT_STATUS[$component]}"
        local icon="✅"
        case "$status" in
            critical) icon="🔴" ;;
            warning) icon="🟡" ;;
            healthy) icon="✅" ;;
        esac
        echo "   - $component: $icon $status"
    done
    
    # Trigger a test health check
    collect_health_metrics
    analyze_system_health
    
    echo "✅ System monitoring demonstration completed"
}

demonstrate_predictive_analysis() {
    echo "🔮 Demonstrating predictive error analysis..."
    
    # Create some error patterns for analysis
    echo "   Generating error patterns for analysis..."
    
    # Simulate repeated errors to trigger pattern detection
    for i in {1..3}; do
        echo "   Simulating error pattern $i/3..."
        analyze_error_trends "1" "test_command" "demo_function"
        sleep 1
    done
    
    # Show any predictive warnings generated
    if [[ ${#PREDICTIVE_WARNINGS[@]} -gt 0 ]]; then
        echo "   Predictive warnings generated:"
        for warning in "${PREDICTIVE_WARNINGS[@]}"; do
            echo "   ⚠️  $warning"
        done
    else
        echo "   ℹ️  No predictive warnings generated (expected for demo)"
    fi
    
    echo "✅ Predictive analysis demonstration completed"
}

#=====================================
# Usage and Help
#=====================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Enhanced Error Handling Integration Example for HyprSupreme-Builder

This script demonstrates the comprehensive error management system including:
- Advanced error handling and recovery
- System health monitoring
- Predictive error analysis
- Performance tracking
- Automated remediation

OPTIONS:
    --help, -h          Show this help message
    --verbose, -v       Enable verbose output
    --monitoring-only   Only demonstrate monitoring features
    --recovery-only     Only demonstrate recovery features
    --no-reports        Skip report generation

EXAMPLES:
    $0                  # Run full demonstration
    $0 --verbose        # Run with detailed output
    $0 --monitoring-only # Only show monitoring features

The enhanced error system provides:
- 🔄 Intelligent error recovery
- 📊 Real-time system monitoring
- 🔮 Predictive error analysis  
- ⚡ Performance optimization
- 📈 Comprehensive reporting

EOF
}

#=====================================
# Command Line Processing
#=====================================

# Parse command line arguments
MONITORING_ONLY=false
RECOVERY_ONLY=false
NO_REPORTS=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            exit 0
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --monitoring-only)
            MONITORING_ONLY=true
            shift
            ;;
        --recovery-only)
            RECOVERY_ONLY=true
            shift
            ;;
        --no-reports)
            NO_REPORTS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set verbose mode if requested
if [[ "$VERBOSE" == true ]]; then
    set -x
fi

#=====================================
# Main Execution
#=====================================

# Conditional execution based on options
if [[ "$MONITORING_ONLY" == true ]]; then
    echo "🔧 Running monitoring-only demonstration..."
    source "$PROJECT_ROOT/modules/common/enhanced_error_system.sh"
    configure_enhanced_error_system --enable-monitoring --monitoring-interval 5
    demonstrate_system_monitoring
elif [[ "$RECOVERY_ONLY" == true ]]; then
    echo "🔧 Running recovery-only demonstration..."
    source "$PROJECT_ROOT/modules/common/enhanced_error_system.sh"
    configure_enhanced_error_system --enable-recovery --enable-self-healing
    demonstrate_recoverable_errors
else
    # Run full demonstration
    main
fi

echo
echo "📚 For more information, check the documentation:"
echo "   - Error Handler: $PROJECT_ROOT/modules/common/error_handler.sh"
echo "   - Recovery System: $PROJECT_ROOT/modules/common/error_recovery.sh" 
echo "   - Enhanced System: $PROJECT_ROOT/modules/common/enhanced_error_system.sh"
echo
echo "💡 To integrate into your scripts, simply source the enhanced_error_system.sh"
echo "   and call init_enhanced_error_system at the beginning of your script."

exit 0

