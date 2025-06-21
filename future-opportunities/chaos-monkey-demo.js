// Chaos Engineering Demo
// Experience the power of controlled failure testing!

const express = require('express');
const ChaosMonkey = require('./chaos-monkey');

console.log(`
🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒
🐒                                                           🐒
🐒           CHAOS ENGINEERING DEMONSTRATION                🐒
🐒                                                           🐒
🐒     "In the midst of chaos, there is also opportunity"   🐒
🐒                                        - Sun Tzu         🐒
🐒                                                           🐒
🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒🐒
`);

class ChaosEngineeringDemo {
    constructor() {
        this.app = express();
        this.port = 3001;
        this.setupChaosMonkey();
        this.setupApp();
        this.startDemo();
    }

    setupChaosMonkey() {
        console.log('🔧 Initializing Chaos Monkey...\n');
        
        this.chaos = new ChaosMonkey({
            enabled: true,
            failureRate: 0.2, // 20% failure rate for dramatic demo
            scenarios: [
                'latency',
                'error',
                'resource_exhaustion',
                'database_failure',
                'network_partition',
                'memory_leak'
            ],
            logFile: './metrics/chaos-demo.log'
        });

        // Set up event listeners for dramatic effect
        this.chaos.on('chaosEvent', (event) => {
            console.log(`💥 CHAOS EVENT: ${event.scenario.toUpperCase()} triggered on ${event.endpoint}!`);
        });

        console.log('✅ Chaos Monkey is armed and dangerous!\n');
    }

    setupApp() {
        this.app.use(express.json());
        this.app.use(this.chaos.middleware());

        // Demo API endpoints
        this.app.get('/api/stable', (req, res) => {
            res.json({
                message: 'This endpoint should be stable... or is it? 🤔',
                timestamp: new Date().toISOString(),
                chaos: 'May the odds be ever in your favor!'
            });
        });

        this.app.get('/api/database', (req, res) => {
            // Simulate database operation
            res.json({
                data: [1, 2, 3, 4, 5],
                message: 'Database query successful... unless chaos strikes! 💾',
                query_time: Math.random() * 100
            });
        });

        this.app.post('/api/upload', (req, res) => {
            // Simulate file upload
            res.json({
                message: 'File uploaded successfully... probably! 📁',
                size: Math.random() * 10000,
                status: 'uploaded'
            });
        });

        // Chaos control endpoints
        this.chaos.setupChaosEndpoints(this.app);

        // Special demo endpoints
        this.app.get('/chaos-demo/status', (req, res) => {
            const metrics = this.chaos.getMetrics();
            res.json({
                message: '🐒 Chaos Monkey Status Report',
                enabled: this.chaos.enabled,
                failureRate: `${(this.chaos.failureRate * 100).toFixed(1)}%`,
                scenarios: this.chaos.scenarios,
                metrics: {
                    totalRequests: metrics.totalRequests,
                    chaosEvents: metrics.chaosEvents,
                    chaosRate: metrics.chaosRate,
                    scenarioBreakdown: metrics.scenarios
                }
            });
        });

        this.app.post('/chaos-demo/unleash', (req, res) => {
            console.log('🔥 UNLEASHING MAXIMUM CHAOS! 🔥');
            this.chaos.setFailureRate(0.5); // 50% chaos!
            res.json({
                message: '🐒 CHAOS UNLEASHED! Failure rate increased to 50%!',
                warning: 'Brace for impact! 💥'
            });
        });

        this.app.post('/chaos-demo/calm', (req, res) => {
            console.log('🕊️ Restoring calm...');
            this.chaos.setFailureRate(0.1); // Back to 10%
            res.json({
                message: '🕊️ Chaos has been calmed. Failure rate reduced to 10%.',
                status: 'peaceful'
            });
        });
    }

    startDemo() {
        this.server = this.app.listen(this.port, () => {
            console.log(`
🎭 CHAOS ENGINEERING DEMO RUNNING!

🌐 Server: http://localhost:${this.port}
📊 Status: http://localhost:${this.port}/chaos-demo/status

🔥 TEST THESE ENDPOINTS:
   GET  /api/stable      - "Stable" endpoint (yeah right!)
   GET  /api/database    - Database simulation
   POST /api/upload      - File upload simulation
   
🎛️ CHAOS CONTROLS:
   GET  /chaos/status    - Detailed chaos metrics
   POST /chaos/enable    - Enable chaos monkey
   POST /chaos/disable   - Disable chaos monkey
   POST /chaos-demo/unleash  - UNLEASH MAXIMUM CHAOS! 🔥
   POST /chaos-demo/calm     - Restore calm 🕊️

💡 TIP: Keep refreshing the endpoints to see chaos in action!
`);

            this.runDemonstration();
        });

        process.on('SIGINT', () => {
            console.log('\n🛑 Shutting down chaos demo...');
            this.server.close();
            console.log('🐒 Chaos Monkey has been contained! Demo complete.\n');
            process.exit(0);
        });
    }

    runDemonstration() {
        console.log('🎬 Starting automated chaos demonstration...\n');

        // Scenario 1: Gradual chaos increase
        setTimeout(() => {
            console.log('🎬 DEMO SCENARIO 1: Gradual Chaos Escalation');
            console.log('   📈 Increasing failure rate from 20% to 30%...');
            this.chaos.setFailureRate(0.3);
        }, 5000);

        // Scenario 2: Add new chaos scenario
        setTimeout(() => {
            console.log('\n🎬 DEMO SCENARIO 2: New Chaos Type');
            console.log('   🆕 Adding "timeout" scenario...');
            this.chaos.addScenario('timeout');
        }, 10000);

        // Scenario 3: Show metrics
        setTimeout(() => {
            console.log('\n🎬 DEMO SCENARIO 3: Chaos Metrics Report');
            const metrics = this.chaos.getMetrics();
            console.log('   📊 Current metrics:', {
                totalRequests: metrics.totalRequests,
                chaosEvents: metrics.chaosEvents,
                chaosRate: metrics.chaosRate
            });
        }, 15000);

        // Scenario 4: Maximum chaos!
        setTimeout(() => {
            console.log('\n🎬 DEMO SCENARIO 4: MAXIMUM CHAOS! 🔥');
            console.log('   💥 Setting failure rate to 50%!');
            this.chaos.setFailureRate(0.5);
            console.log('   🚨 Your system is now under extreme stress!');
        }, 20000);

        // Scenario 5: Recovery
        setTimeout(() => {
            console.log('\n🎬 DEMO SCENARIO 5: Recovery Phase');
            console.log('   🏥 Reducing chaos to test recovery...');
            this.chaos.setFailureRate(0.1);
            console.log('   ✅ System should start recovering now!');
        }, 30000);

        // Continuous updates
        setInterval(() => {
            const metrics = this.chaos.getMetrics();
            if (metrics.totalRequests > 0) {
                console.log(`\n📈 LIVE METRICS: ${metrics.totalRequests} requests, ${metrics.chaosEvents} chaos events (${metrics.chaosRate} rate)`);
            }
        }, 20000);
    }
}

// Start the demo
if (require.main === module) {
    new ChaosEngineeringDemo();
}

module.exports = ChaosEngineeringDemo;
