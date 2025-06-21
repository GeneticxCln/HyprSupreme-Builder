// Chaos Monkey Implementation for API Testing
// This simulates various failure scenarios to test system resilience

const express = require('express');
const fs = require('fs');
const path = require('path');

class ChaosMonkey {
    constructor(options = {}) {
        this.enabled = options.enabled || false;
        this.failureRate = options.failureRate || 0.1; // 10% failure rate
        this.scenarios = options.scenarios || ['latency', 'error', 'resource_exhaustion'];
        this.logFile = options.logFile || 'chaos-events.log';
        this.metrics = {
            totalRequests: 0,
            chaosEvents: 0,
            scenarios: {}
        };
    }

    // Main middleware function
    middleware() {
        return (req, res, next) => {
            this.metrics.totalRequests++;
            
            if (!this.enabled || Math.random() > this.failureRate) {
                return next();
            }

            const scenario = this.selectScenario();
            this.executeScenario(scenario, req, res, next);
        };
    }

    selectScenario() {
        const scenario = this.scenarios[Math.floor(Math.random() * this.scenarios.length)];
        this.metrics.chaosEvents++;
        this.metrics.scenarios[scenario] = (this.metrics.scenarios[scenario] || 0) + 1;
        return scenario;
    }

    executeScenario(scenario, req, res, next) {
        const event = {
            timestamp: new Date().toISOString(),
            scenario,
            endpoint: req.path,
            method: req.method,
            userAgent: req.get('User-Agent')
        };

        this.logEvent(event);

        switch (scenario) {
            case 'latency':
                this.simulateLatency(req, res, next);
                break;
            case 'error':
                this.simulateError(req, res, next);
                break;
            case 'resource_exhaustion':
                this.simulateResourceExhaustion(req, res, next);
                break;
            case 'network_partition':
                this.simulateNetworkPartition(req, res, next);
                break;
            case 'database_failure':
                this.simulateDatabaseFailure(req, res, next);
                break;
            case 'memory_leak':
                this.simulateMemoryLeak(req, res, next);
                break;
            default:
                next();
        }
    }

    // Chaos Scenarios

    simulateLatency(req, res, next) {
        const delay = Math.random() * 5000 + 1000; // 1-6 seconds delay
        console.log(`🐒 CHAOS: Adding ${Math.round(delay)}ms latency to ${req.path}`);
        
        setTimeout(() => {
            next();
        }, delay);
    }

    simulateError(req, res, next) {
        const errors = [
            { status: 500, message: 'Internal Server Error - Chaos Monkey' },
            { status: 503, message: 'Service Temporarily Unavailable' },
            { status: 429, message: 'Too Many Requests' },
            { status: 502, message: 'Bad Gateway' }
        ];
        
        const error = errors[Math.floor(Math.random() * errors.length)];
        console.log(`🐒 CHAOS: Simulating ${error.status} error for ${req.path}`);
        
        res.status(error.status).json({
            success: false,
            error: error.message,
            chaosEvent: true,
            timestamp: new Date().toISOString()
        });
    }

    simulateResourceExhaustion(req, res, next) {
        console.log(`🐒 CHAOS: Simulating resource exhaustion for ${req.path}`);
        
        // Simulate CPU intensive operation
        const start = Date.now();
        const duration = Math.random() * 2000 + 500; // 0.5-2.5 seconds
        
        while (Date.now() - start < duration) {
            // CPU intensive loop
            Math.random() * Math.random();
        }
        
        next();
    }

    simulateNetworkPartition(req, res, next) {
        console.log(`🐒 CHAOS: Simulating network partition for ${req.path}`);
        
        // Simulate connection timeout
        setTimeout(() => {
            if (!res.headersSent) {
                res.status(504).json({
                    success: false,
                    error: 'Gateway Timeout - Network Partition Simulation',
                    chaosEvent: true
                });
            }
        }, 30000); // 30 second timeout
        
        // 50% chance the request still goes through
        if (Math.random() > 0.5) {
            next();
        }
    }

    simulateDatabaseFailure(req, res, next) {
        console.log(`🐒 CHAOS: Simulating database failure for ${req.path}`);
        
        // Only affect database-related endpoints
        if (req.path.includes('/api/users')) {
            res.status(503).json({
                success: false,
                error: 'Database connection failed - Chaos Monkey',
                chaosEvent: true,
                retryAfter: 30
            });
        } else {
            next();
        }
    }

    simulateMemoryLeak(req, res, next) {
        console.log(`🐒 CHAOS: Simulating memory leak for ${req.path}`);
        
        // Create memory leak simulation
        const leakyArray = [];
        for (let i = 0; i < 10000; i++) {
            leakyArray.push(new Array(1000).fill('memory-leak-simulation'));
        }
        
        // Don't actually leak memory - clean up after a short time
        setTimeout(() => {
            leakyArray.length = 0;
        }, 1000);
        
        next();
    }

    // Utility Methods

    logEvent(event) {
        const logEntry = JSON.stringify(event) + '\n';
        fs.appendFileSync(this.logFile, logEntry);
    }

    getMetrics() {
        return {
            ...this.metrics,
            chaosRate: this.metrics.totalRequests > 0 
                ? (this.metrics.chaosEvents / this.metrics.totalRequests * 100).toFixed(2) + '%'
                : '0%'
        };
    }

    enable() {
        this.enabled = true;
        console.log('🐒 Chaos Monkey ENABLED - Prepare for chaos!');
    }

    disable() {
        this.enabled = false;
        console.log('🐒 Chaos Monkey DISABLED - Systems returning to normal');
    }

    setFailureRate(rate) {
        this.failureRate = Math.max(0, Math.min(1, rate));
        console.log(`🐒 Chaos Monkey failure rate set to ${(this.failureRate * 100).toFixed(1)}%`);
    }

    addScenario(scenario) {
        if (!this.scenarios.includes(scenario)) {
            this.scenarios.push(scenario);
            console.log(`🐒 Added new chaos scenario: ${scenario}`);
        }
    }

    removeScenario(scenario) {
        const index = this.scenarios.indexOf(scenario);
        if (index > -1) {
            this.scenarios.splice(index, 1);
            console.log(`🐒 Removed chaos scenario: ${scenario}`);
        }
    }

    // Chaos Testing Endpoints
    setupChaosEndpoints(app) {
        // Chaos control endpoint
        app.get('/chaos/status', (req, res) => {
            res.json({
                enabled: this.enabled,
                failureRate: this.failureRate,
                scenarios: this.scenarios,
                metrics: this.getMetrics()
            });
        });

        app.post('/chaos/enable', (req, res) => {
            this.enable();
            res.json({ message: 'Chaos Monkey enabled', enabled: true });
        });

        app.post('/chaos/disable', (req, res) => {
            this.disable();
            res.json({ message: 'Chaos Monkey disabled', enabled: false });
        });

        app.post('/chaos/configure', (req, res) => {
            const { failureRate, scenarios } = req.body;
            
            if (failureRate !== undefined) {
                this.setFailureRate(failureRate);
            }
            
            if (scenarios && Array.isArray(scenarios)) {
                this.scenarios = scenarios;
            }
            
            res.json({
                message: 'Chaos Monkey configured',
                failureRate: this.failureRate,
                scenarios: this.scenarios
            });
        });

        app.get('/chaos/metrics', (req, res) => {
            res.json(this.getMetrics());
        });

        app.post('/chaos/reset-metrics', (req, res) => {
            this.metrics = {
                totalRequests: 0,
                chaosEvents: 0,
                scenarios: {}
            };
            res.json({ message: 'Metrics reset', metrics: this.metrics });
        });
    }
}

module.exports = ChaosMonkey;
