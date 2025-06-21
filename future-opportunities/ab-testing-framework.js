// A/B Testing Framework for Data-Driven Feature Decisions
// This enables systematic testing of different feature variants

const crypto = require('crypto');
const fs = require('fs');

class ABTestingFramework {
    constructor(options = {}) {
        this.tests = new Map();
        this.userAssignments = new Map();
        this.metrics = new Map();
        this.logFile = options.logFile || 'ab-test-events.log';
        this.persistAssignments = options.persistAssignments !== false;
        this.assignmentStorage = options.assignmentStorage || new Map();
    }

    // Test Configuration
    createTest(testId, config) {
        const test = {
            id: testId,
            name: config.name,
            description: config.description,
            variants: config.variants, // Array of variant objects
            traffic: config.traffic || 1.0, // Percentage of traffic to include
            startDate: config.startDate || new Date(),
            endDate: config.endDate,
            isActive: config.isActive !== false,
            targetingRules: config.targetingRules || [],
            goals: config.goals || [],
            createdAt: new Date(),
            ...config
        };

        // Validate variants
        if (!test.variants || test.variants.length < 2) {
            throw new Error('Test must have at least 2 variants');
        }

        // Ensure variant weights sum to 1
        const totalWeight = test.variants.reduce((sum, v) => sum + (v.weight || 0), 0);
        if (Math.abs(totalWeight - 1) > 0.001) {
            throw new Error('Variant weights must sum to 1.0');
        }

        this.tests.set(testId, test);
        this.metrics.set(testId, {
            assignments: {},
            conversions: {},
            customEvents: {},
            startTime: new Date()
        });

        console.log(`🧪 A/B Test created: ${testId} - ${test.name}`);
        return test;
    }

    // User Assignment
    assignUser(userId, testId, context = {}) {
        const test = this.tests.get(testId);
        if (!test) {
            throw new Error(`Test ${testId} not found`);
        }

        // Check if test is active
        if (!this.isTestActive(test)) {
            return null;
        }

        // Check traffic allocation
        if (Math.random() > test.traffic) {
            return null;
        }

        // Check targeting rules
        if (!this.matchesTargeting(test, context)) {
            return null;
        }

        // Get existing assignment if persistent
        const existingAssignment = this.getUserAssignment(userId, testId);
        if (existingAssignment) {
            return existingAssignment;
        }

        // Assign to variant
        const variant = this.selectVariant(userId, test);
        const assignment = {
            userId,
            testId,
            variantId: variant.id,
            variantName: variant.name,
            assignedAt: new Date(),
            context
        };

        // Store assignment
        this.storeAssignment(assignment);
        this.recordMetric(testId, 'assignments', variant.id);

        this.logEvent({
            type: 'assignment',
            ...assignment
        });

        return assignment;
    }

    selectVariant(userId, test) {
        // Use deterministic assignment based on userId hash
        const hash = crypto.createHash('md5')
            .update(userId + test.id)
            .digest('hex');
        
        const hashValue = parseInt(hash.substring(0, 8), 16) / 0xffffffff;
        
        let cumulativeWeight = 0;
        for (const variant of test.variants) {
            cumulativeWeight += variant.weight;
            if (hashValue <= cumulativeWeight) {
                return variant;
            }
        }
        
        // Fallback to last variant
        return test.variants[test.variants.length - 1];
    }

    // Targeting and Rules
    matchesTargeting(test, context) {
        if (!test.targetingRules || test.targetingRules.length === 0) {
            return true;
        }

        return test.targetingRules.every(rule => {
            switch (rule.type) {
                case 'user_property':
                    return this.evaluateUserProperty(rule, context);
                case 'geo_location':
                    return this.evaluateGeoLocation(rule, context);
                case 'device_type':
                    return this.evaluateDeviceType(rule, context);
                case 'custom':
                    return this.evaluateCustomRule(rule, context);
                default:
                    return true;
            }
        });
    }

    evaluateUserProperty(rule, context) {
        const value = context[rule.property];
        switch (rule.operator) {
            case 'equals':
                return value === rule.value;
            case 'not_equals':
                return value !== rule.value;
            case 'in':
                return rule.values.includes(value);
            case 'not_in':
                return !rule.values.includes(value);
            case 'greater_than':
                return Number(value) > Number(rule.value);
            case 'less_than':
                return Number(value) < Number(rule.value);
            default:
                return true;
        }
    }

    evaluateGeoLocation(rule, context) {
        const userCountry = context.country || context.geoLocation?.country;
        if (rule.countries) {
            return rule.countries.includes(userCountry);
        }
        return true;
    }

    evaluateDeviceType(rule, context) {
        const deviceType = context.deviceType || this.detectDeviceType(context.userAgent);
        if (rule.deviceTypes) {
            return rule.deviceTypes.includes(deviceType);
        }
        return true;
    }

    evaluateCustomRule(rule, context) {
        if (typeof rule.evaluator === 'function') {
            return rule.evaluator(context);
        }
        return true;
    }

    detectDeviceType(userAgent) {
        if (!userAgent) return 'unknown';
        
        if (/Mobile|Android|iPhone|iPad/.test(userAgent)) {
            return 'mobile';
        } else if (/Tablet|iPad/.test(userAgent)) {
            return 'tablet';
        } else {
            return 'desktop';
        }
    }

    // Conversion Tracking
    recordConversion(userId, testId, goalId, value = 1) {
        const assignment = this.getUserAssignment(userId, testId);
        if (!assignment) {
            return false; // User not in test
        }

        const conversion = {
            userId,
            testId,
            variantId: assignment.variantId,
            goalId,
            value,
            convertedAt: new Date()
        };

        this.recordMetric(testId, 'conversions', assignment.variantId, goalId, value);

        this.logEvent({
            type: 'conversion',
            ...conversion
        });

        return true;
    }

    recordCustomEvent(userId, testId, eventName, properties = {}) {
        const assignment = this.getUserAssignment(userId, testId);
        if (!assignment) {
            return false;
        }

        const event = {
            userId,
            testId,
            variantId: assignment.variantId,
            eventName,
            properties,
            recordedAt: new Date()
        };

        this.recordMetric(testId, 'customEvents', assignment.variantId, eventName);

        this.logEvent({
            type: 'custom_event',
            ...event
        });

        return true;
    }

    // Analytics and Reporting
    getTestResults(testId) {
        const test = this.tests.get(testId);
        const metrics = this.metrics.get(testId);
        
        if (!test || !metrics) {
            throw new Error(`Test ${testId} not found`);
        }

        const results = {
            testId,
            testName: test.name,
            status: this.getTestStatus(test),
            duration: this.getTestDuration(test),
            variants: test.variants.map(variant => ({
                id: variant.id,
                name: variant.name,
                weight: variant.weight,
                assignments: metrics.assignments[variant.id] || 0,
                conversions: this.getVariantConversions(testId, variant.id),
                customEvents: this.getVariantCustomEvents(testId, variant.id)
            }))
        };

        // Calculate statistical significance
        results.statisticalAnalysis = this.calculateStatisticalSignificance(testId);

        return results;
    }

    calculateStatisticalSignificance(testId) {
        const metrics = this.metrics.get(testId);
        const test = this.tests.get(testId);
        
        if (!metrics || !test) return null;

        const variants = test.variants.map(variant => {
            const assignments = metrics.assignments[variant.id] || 0;
            const conversions = this.getTotalConversions(testId, variant.id);
            const conversionRate = assignments > 0 ? conversions / assignments : 0;
            
            return {
                id: variant.id,
                name: variant.name,
                assignments,
                conversions,
                conversionRate
            };
        });

        // Simple statistical analysis (chi-square test approximation)
        if (variants.length === 2) {
            return this.calculateTwoVariantSignificance(variants[0], variants[1]);
        }

        return { variants, note: 'Multi-variant statistical analysis requires more complex calculations' };
    }

    calculateTwoVariantSignificance(variantA, variantB) {
        const pooledRate = (variantA.conversions + variantB.conversions) / 
                          (variantA.assignments + variantB.assignments);
        
        const expectedA = variantA.assignments * pooledRate;
        const expectedB = variantB.assignments * pooledRate;
        
        const chiSquare = Math.pow(variantA.conversions - expectedA, 2) / expectedA +
                         Math.pow(variantB.conversions - expectedB, 2) / expectedB;
        
        // Approximate p-value calculation (simplified)
        const pValue = this.approximatePValue(chiSquare);
        
        return {
            variantA: { ...variantA },
            variantB: { ...variantB },
            chiSquare,
            pValue,
            isSignificant: pValue < 0.05,
            confidence: (1 - pValue) * 100,
            lift: variantA.assignments > 0 && variantB.assignments > 0 ? 
                  ((variantA.conversionRate - variantB.conversionRate) / variantB.conversionRate * 100) : 0
        };
    }

    approximatePValue(chiSquare) {
        // Simplified p-value approximation for chi-square with 1 degree of freedom
        if (chiSquare > 6.635) return 0.01;
        if (chiSquare > 3.841) return 0.05;
        if (chiSquare > 2.706) return 0.10;
        return 0.20;
    }

    // Middleware for Express.js
    middleware() {
        return (req, res, next) => {
            const userId = this.extractUserId(req);
            
            req.abTest = {
                getVariant: (testId, context = {}) => {
                    const assignment = this.assignUser(userId, testId, {
                        ...context,
                        userAgent: req.get('User-Agent'),
                        ip: req.ip
                    });
                    return assignment ? assignment.variantId : null;
                },
                
                recordConversion: (testId, goalId, value) => {
                    return this.recordConversion(userId, testId, goalId, value);
                },
                
                recordEvent: (testId, eventName, properties) => {
                    return this.recordCustomEvent(userId, testId, eventName, properties);
                }
            };
            
            next();
        };
    }

    // Utility Methods
    extractUserId(req) {
        // Try multiple sources for user ID
        return req.user?.id || 
               req.session?.userId || 
               req.headers['x-user-id'] || 
               req.ip || 
               'anonymous';
    }

    isTestActive(test) {
        if (!test.isActive) return false;
        
        const now = new Date();
        if (test.startDate && now < test.startDate) return false;
        if (test.endDate && now > test.endDate) return false;
        
        return true;
    }

    getTestStatus(test) {
        if (!test.isActive) return 'inactive';
        
        const now = new Date();
        if (test.startDate && now < test.startDate) return 'scheduled';
        if (test.endDate && now > test.endDate) return 'completed';
        
        return 'running';
    }

    getTestDuration(test) {
        const start = test.startDate || test.createdAt;
        const end = test.endDate || new Date();
        return Math.floor((end - start) / (1000 * 60 * 60 * 24)); // days
    }

    storeAssignment(assignment) {
        const key = `${assignment.userId}:${assignment.testId}`;
        this.userAssignments.set(key, assignment);
        
        if (this.persistAssignments) {
            this.assignmentStorage.set(key, assignment);
        }
    }

    getUserAssignment(userId, testId) {
        const key = `${userId}:${testId}`;
        return this.userAssignments.get(key) || this.assignmentStorage.get(key);
    }

    recordMetric(testId, type, variantId, subKey = null, value = 1) {
        const metrics = this.metrics.get(testId);
        if (!metrics) return;

        if (!metrics[type]) metrics[type] = {};
        if (!metrics[type][variantId]) metrics[type][variantId] = {};

        if (subKey) {
            if (!metrics[type][variantId][subKey]) {
                metrics[type][variantId][subKey] = 0;
            }
            metrics[type][variantId][subKey] += value;
        } else {
            if (!metrics[type][variantId]) {
                metrics[type][variantId] = 0;
            }
            metrics[type][variantId] += value;
        }
    }

    getVariantConversions(testId, variantId) {
        const metrics = this.metrics.get(testId);
        return metrics?.conversions?.[variantId] || {};
    }

    getVariantCustomEvents(testId, variantId) {
        const metrics = this.metrics.get(testId);
        return metrics?.customEvents?.[variantId] || {};
    }

    getTotalConversions(testId, variantId) {
        const conversions = this.getVariantConversions(testId, variantId);
        return Object.values(conversions).reduce((sum, count) => sum + count, 0);
    }

    logEvent(event) {
        const logEntry = JSON.stringify({
            ...event,
            timestamp: new Date().toISOString()
        }) + '\n';
        
        fs.appendFileSync(this.logFile, logEntry);
    }

    // Test Management
    pauseTest(testId) {
        const test = this.tests.get(testId);
        if (test) {
            test.isActive = false;
            console.log(`🛑 A/B Test paused: ${testId}`);
        }
    }

    resumeTest(testId) {
        const test = this.tests.get(testId);
        if (test) {
            test.isActive = true;
            console.log(`▶️ A/B Test resumed: ${testId}`);
        }
    }

    endTest(testId) {
        const test = this.tests.get(testId);
        if (test) {
            test.isActive = false;
            test.endDate = new Date();
            console.log(`🏁 A/B Test ended: ${testId}`);
            return this.getTestResults(testId);
        }
    }

    // Export/Import
    exportTestData(testId) {
        const test = this.tests.get(testId);
        const metrics = this.metrics.get(testId);
        
        if (!test) {
            throw new Error(`Test ${testId} not found`);
        }

        return {
            test,
            metrics,
            results: this.getTestResults(testId),
            exportedAt: new Date()
        };
    }

    getAllTests() {
        return Array.from(this.tests.entries()).map(([id, test]) => ({
            id,
            ...test,
            status: this.getTestStatus(test),
            assignments: this.metrics.get(id)?.assignments || {}
        }));
    }
}

module.exports = ABTestingFramework;
