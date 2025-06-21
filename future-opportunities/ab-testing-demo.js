// A/B Testing Framework Demo
// Data-driven decisions through controlled experiments!

const express = require('express');
const ABTestingFramework = require('./ab-testing-framework');

console.log(`
🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪
🧪                                                           🧪
🧪           A/B TESTING FRAMEWORK DEMONSTRATION            🧪
🧪                                                           🧪
🧪     "In God we trust. All others must bring data."       🧪
🧪                                    - W. Edwards Deming   🧪
🧪                                                           🧪
🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪
`);

class ABTestingDemo {
    constructor() {
        this.app = express();
        this.port = 3002;
        this.users = new Map(); // Simulate user database
        this.setupABTesting();
        this.setupApp();
        this.createExperiments();
        this.startDemo();
    }

    setupABTesting() {
        console.log('🔬 Initializing A/B Testing Framework...\n');
        
        this.abTesting = new ABTestingFramework({
            persistAssignments: true,
            logFile: './metrics/ab-testing-demo.log'
        });

        // Set up event listeners
        this.abTesting.on('assignment', (assignment) => {
            console.log(`👤 User ${assignment.userId} assigned to ${assignment.variantName} in ${assignment.testId}`);
        });

        this.abTesting.on('conversion', (conversion) => {
            console.log(`🎯 Conversion! User ${conversion.userId} completed ${conversion.goalId} in ${conversion.testId}`);
        });

        console.log('✅ A/B Testing Framework ready for experiments!\n');
    }

    setupApp() {
        this.app.use(express.json());
        this.app.use(this.abTesting.middleware());

        // Landing page with A/B tested button
        this.app.get('/landing', (req, res) => {
            const userId = req.headers['x-user-id'] || `visitor_${Date.now()}`;
            const buttonVariant = req.abTest.getVariant('button_color_test', { userId });
            const layoutVariant = req.abTest.getVariant('layout_test', { userId });

            res.json({
                message: '🎯 A/B Testing Landing Page',
                user: userId,
                experiments: {
                    buttonColor: buttonVariant || 'control',
                    layout: layoutVariant || 'standard'
                },
                content: this.generateLandingContent(buttonVariant, layoutVariant),
                instructions: 'Visit /purchase to simulate a conversion!'
            });
        });

        // Pricing page with A/B tested features
        this.app.get('/pricing', (req, res) => {
            const userId = req.headers['x-user-id'] || `visitor_${Date.now()}`;
            const pricingVariant = req.abTest.getVariant('pricing_strategy_test', { userId });

            res.json({
                message: '💰 Pricing Page (A/B Tested)',
                user: userId,
                pricingStrategy: pricingVariant || 'standard',
                prices: this.generatePricingContent(pricingVariant),
                experiment: 'pricing_strategy_test'
            });
        });

        // Purchase conversion endpoint
        this.app.post('/purchase', (req, res) => {
            const userId = req.headers['x-user-id'] || req.body.userId || `visitor_${Date.now()}`;
            const amount = req.body.amount || Math.floor(Math.random() * 100) + 10;

            // Record conversions for all active tests
            req.abTest.recordConversion('button_color_test', 'purchase', amount);
            req.abTest.recordConversion('layout_test', 'purchase', amount);
            req.abTest.recordConversion('pricing_strategy_test', 'purchase', amount);

            res.json({
                message: '🎉 Purchase successful!',
                user: userId,
                amount: amount,
                conversionsRecorded: ['button_color_test', 'layout_test', 'pricing_strategy_test']
            });
        });

        // Newsletter signup
        this.app.post('/newsletter', (req, res) => {
            const userId = req.headers['x-user-id'] || req.body.userId || `visitor_${Date.now()}`;

            req.abTest.recordConversion('button_color_test', 'signup', 1);
            req.abTest.recordConversion('layout_test', 'signup', 1);

            res.json({
                message: '📧 Newsletter signup successful!',
                user: userId,
                conversionsRecorded: ['button_color_test', 'layout_test']
            });
        });

        // Test management endpoints
        this.app.get('/experiments', (req, res) => {
            const tests = this.abTesting.getAllTests();
            res.json({
                message: '🧪 Active Experiments',
                totalTests: tests.length,
                tests: tests.map(test => ({
                    id: test.id,
                    name: test.name,
                    status: test.status,
                    variants: test.variants?.length || 0,
                    traffic: test.traffic
                }))
            });
        });

        this.app.get('/experiments/:testId/results', (req, res) => {
            try {
                const results = this.abTesting.getTestResults(req.params.testId);
                res.json({
                    message: `📊 Results for ${req.params.testId}`,
                    ...results
                });
            } catch (error) {
                res.status(404).json({ error: error.message });
            }
        });

        // Simulate user traffic
        this.app.post('/simulate-traffic', (req, res) => {
            const users = req.body.users || 10;
            console.log(`🚀 Simulating traffic with ${users} users...`);
            this.simulateUserTraffic(users);
            res.json({
                message: `🎭 Simulating ${users} users`,
                tip: 'Check /experiments/{testId}/results to see the data!'
            });
        });
    }

    createExperiments() {
        console.log('🧪 Creating demo experiments...\n');

        // Experiment 1: Button Color Test
        this.abTesting.createTest('button_color_test', {
            name: 'Button Color Optimization',
            description: 'Testing different button colors for conversion rate',
            variants: [
                { id: 'blue', name: 'Blue Button', weight: 0.33 },
                { id: 'green', name: 'Green Button', weight: 0.33 },
                { id: 'orange', name: 'Orange Button', weight: 0.34 }
            ],
            traffic: 0.8, // 80% of users
            goals: ['purchase', 'signup'],
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
        });

        // Experiment 2: Layout Test
        this.abTesting.createTest('layout_test', {
            name: 'Page Layout Optimization',
            description: 'Testing different page layouts for user engagement',
            variants: [
                { id: 'standard', name: 'Standard Layout', weight: 0.5 },
                { id: 'modern', name: 'Modern Layout', weight: 0.5 }
            ],
            traffic: 0.6, // 60% of users
            goals: ['purchase', 'signup', 'engagement'],
            startDate: new Date(),
            endDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000) // 21 days
        });

        // Experiment 3: Pricing Strategy
        this.abTesting.createTest('pricing_strategy_test', {
            name: 'Pricing Strategy Test',
            description: 'Testing different pricing strategies',
            variants: [
                { id: 'standard', name: 'Standard Pricing', weight: 0.4 },
                { id: 'discount', name: 'Discount Pricing', weight: 0.3 },
                { id: 'premium', name: 'Premium Pricing', weight: 0.3 }
            ],
            traffic: 0.7, // 70% of users
            goals: ['purchase'],
            targetingRules: [
                {
                    type: 'user_property',
                    property: 'accountAge',
                    operator: 'greater_than',
                    value: 0
                }
            ],
            startDate: new Date(),
            endDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) // 14 days
        });

        console.log('✅ Created 3 demo experiments:');
        console.log('   🔵 Button Color Test (3 variants)');
        console.log('   📱 Layout Test (2 variants)');
        console.log('   💰 Pricing Strategy Test (3 variants)\n');
    }

    generateLandingContent(buttonVariant, layoutVariant) {
        const buttonStyles = {
            blue: { color: '#007bff', text: 'Buy Now (Blue)' },
            green: { color: '#28a745', text: 'Buy Now (Green)' },
            orange: { color: '#fd7e14', text: 'Buy Now (Orange)' },
            control: { color: '#6c757d', text: 'Buy Now (Control)' }
        };

        const layouts = {
            standard: { style: 'Traditional layout with sidebar' },
            modern: { style: 'Clean, minimal modern layout' },
            control: { style: 'Default layout' }
        };

        return {
            button: buttonStyles[buttonVariant] || buttonStyles.control,
            layout: layouts[layoutVariant] || layouts.control,
            headline: layoutVariant === 'modern' ? 
                'Experience the Future' : 'Welcome to Our Service',
            description: 'This content is dynamically generated based on your A/B test assignments!'
        };
    }

    generatePricingContent(pricingVariant) {
        const pricingStrategies = {
            standard: {
                basic: '$9.99/month',
                pro: '$19.99/month',
                enterprise: '$49.99/month'
            },
            discount: {
                basic: '$7.99/month (20% OFF!)',
                pro: '$15.99/month (20% OFF!)',
                enterprise: '$39.99/month (20% OFF!)'
            },
            premium: {
                basic: '$12.99/month (Premium)',
                pro: '$24.99/month (Premium)',
                enterprise: '$59.99/month (Premium)'
            }
        };

        return pricingStrategies[pricingVariant] || pricingStrategies.standard;
    }

    simulateUserTraffic(userCount) {
        for (let i = 0; i < userCount; i++) {
            setTimeout(() => {
                const userId = `sim_user_${Date.now()}_${i}`;
                
                // Simulate landing page visit
                const mockReq = {
                    headers: { 'x-user-id': userId },
                    abTest: {
                        getVariant: (testId) => {
                            const assignment = this.abTesting.assignUser(userId, testId);
                            return assignment ? assignment.variantId : null;
                        },
                        recordConversion: (testId, goalId, value) => {
                            return this.abTesting.recordConversion(userId, testId, goalId, value);
                        }
                    }
                };

                // Get variant assignments
                mockReq.abTest.getVariant('button_color_test');
                mockReq.abTest.getVariant('layout_test');
                mockReq.abTest.getVariant('pricing_strategy_test');

                // Simulate some conversions (30% conversion rate)
                if (Math.random() < 0.3) {
                    setTimeout(() => {
                        mockReq.abTest.recordConversion('button_color_test', 'purchase', Math.floor(Math.random() * 100) + 10);
                        mockReq.abTest.recordConversion('layout_test', 'purchase', Math.floor(Math.random() * 100) + 10);
                        mockReq.abTest.recordConversion('pricing_strategy_test', 'purchase', Math.floor(Math.random() * 100) + 10);
                    }, Math.random() * 2000);
                }

                // Simulate newsletter signups (15% rate)
                if (Math.random() < 0.15) {
                    setTimeout(() => {
                        mockReq.abTest.recordConversion('button_color_test', 'signup', 1);
                        mockReq.abTest.recordConversion('layout_test', 'signup', 1);
                    }, Math.random() * 3000);
                }
            }, i * 100); // Stagger requests
        }
    }

    startDemo() {
        this.server = this.app.listen(this.port, () => {
            console.log(`
🎭 A/B TESTING DEMO RUNNING!

🌐 Server: http://localhost:${this.port}
📊 Experiments: http://localhost:${this.port}/experiments

🧪 TEST THESE ENDPOINTS:
   GET  /landing             - Landing page (A/B tested)
   GET  /pricing             - Pricing page (A/B tested)
   POST /purchase            - Purchase conversion
   POST /newsletter          - Newsletter signup
   
📈 EXPERIMENT MANAGEMENT:
   GET  /experiments         - List all experiments
   GET  /experiments/{id}/results - View test results
   POST /simulate-traffic    - Simulate user traffic
   
💡 TIP: Add header 'x-user-id: your_id' to maintain consistent assignments!

🎯 SAMPLE COMMANDS:
   curl http://localhost:${this.port}/landing -H "x-user-id: user123"
   curl -X POST http://localhost:${this.port}/simulate-traffic -d '{"users":50}' -H "Content-Type: application/json"
`);

            this.runDemonstration();
        });

        process.on('SIGINT', () => {
            console.log('\n🛑 Shutting down A/B testing demo...');
            this.server.close();
            console.log('🧪 A/B Testing Framework demo complete!\n');
            process.exit(0);
        });
    }

    runDemonstration() {
        console.log('🎬 Starting automated A/B testing demonstration...\n');

        // Scenario 1: Initial traffic simulation
        setTimeout(() => {
            console.log('🎬 DEMO SCENARIO 1: Initial Traffic Simulation');
            console.log('   👥 Simulating 20 users...');
            this.simulateUserTraffic(20);
        }, 3000);

        // Scenario 2: Show early results
        setTimeout(() => {
            console.log('\n🎬 DEMO SCENARIO 2: Early Results');
            try {
                const results = this.abTesting.getTestResults('button_color_test');
                console.log('   📊 Button Color Test Results:');
                results.variants.forEach(variant => {
                    console.log(`      ${variant.name}: ${variant.assignments} assignments`);
                });
            } catch (error) {
                console.log('   📊 Collecting data... results will be available soon!');
            }
        }, 8000);

        // Scenario 3: More traffic
        setTimeout(() => {
            console.log('\n🎬 DEMO SCENARIO 3: Traffic Surge');
            console.log('   🚀 Simulating 50 more users...');
            this.simulateUserTraffic(50);
        }, 12000);

        // Scenario 4: Statistical analysis
        setTimeout(() => {
            console.log('\n🎬 DEMO SCENARIO 4: Statistical Analysis');
            try {
                const results = this.abTesting.getTestResults('button_color_test');
                if (results.statisticalAnalysis) {
                    console.log('   📈 Statistical Analysis:', {
                        significant: results.statisticalAnalysis.isSignificant,
                        confidence: `${results.statisticalAnalysis.confidence?.toFixed(1)}%`
                    });
                } else {
                    console.log('   📈 More data needed for statistical significance');
                }
            } catch (error) {
                console.log('   📈 Statistical analysis in progress...');
            }
        }, 20000);

        // Continuous updates
        setInterval(() => {
            const tests = this.abTesting.getAllTests();
            const totalAssignments = tests.reduce((sum, test) => {
                return sum + Object.values(test.assignments || {}).reduce((s, c) => s + c, 0);
            }, 0);
            
            if (totalAssignments > 0) {
                console.log(`\n📊 LIVE METRICS: ${totalAssignments} total assignments across ${tests.length} experiments`);
            }
        }, 25000);
    }
}

// Start the demo
if (require.main === module) {
    new ABTestingDemo();
}

module.exports = ABTestingDemo;
