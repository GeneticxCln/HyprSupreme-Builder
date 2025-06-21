// Performance Optimization Framework
// Continuous monitoring and automated optimization for API performance

const fs = require('fs');
const os = require('os');
const EventEmitter = require('events');

class PerformanceOptimizer extends EventEmitter {
    constructor(options = {}) {
        super();
        
        this.metrics = new Map();
        this.benchmarks = new Map();
        this.optimizations = new Map();
        this.config = {
            samplingRate: options.samplingRate || 0.1, // 10% sampling
            alertThresholds: options.alertThresholds || {
                responseTime: 500, // ms
                memoryUsage: 0.8, // 80% of available memory
                cpuUsage: 0.7, // 70% CPU
                errorRate: 0.05 // 5% error rate
            },
            optimizationStrategies: options.optimizationStrategies || [
                'caching',
                'compression',
                'connection_pooling',
                'query_optimization',
                'load_balancing'
            ],
            monitoringInterval: options.monitoringInterval || 30000, // 30 seconds
            logFile: options.logFile || 'performance-metrics.log'
        };
        
        this.isMonitoring = false;
        this.monitoringInterval = null;
        this.requestCache = new Map();
        this.connectionPool = new Map();
        
        this.initializeOptimizations();
    }

    initializeOptimizations() {
        // Response Caching
        this.optimizations.set('caching', {
            enabled: false,
            strategy: 'memory',
            ttl: 300000, // 5 minutes
            maxSize: 100,
            cache: new Map(),
            hitRate: 0
        });

        // Response Compression
        this.optimizations.set('compression', {
            enabled: false,
            algorithm: 'gzip',
            threshold: 1024, // bytes
            compressionRatio: 0
        });

        // Connection Pooling
        this.optimizations.set('connection_pooling', {
            enabled: false,
            maxConnections: 100,
            minConnections: 10,
            idleTimeout: 30000,
            activeConnections: 0
        });

        // Query Optimization
        this.optimizations.set('query_optimization', {
            enabled: false,
            slowQueryThreshold: 100, // ms
            indexSuggestions: [],
            optimizedQueries: 0
        });

        // Load Balancing
        this.optimizations.set('load_balancing', {
            enabled: false,
            strategy: 'round_robin',
            servers: [],
            healthChecks: true
        });
    }

    // Performance Monitoring Middleware
    middleware() {
        return (req, res, next) => {
            const startTime = process.hrtime.bigint();
            const startMemory = process.memoryUsage();
            
            // Sample requests based on sampling rate
            const shouldSample = Math.random() < this.config.samplingRate;
            
            if (shouldSample) {
                req.performanceMonitoring = {
                    startTime,
                    startMemory,
                    endpoint: `${req.method} ${req.path}`
                };
            }

            // Apply optimizations
            this.applyCaching(req, res);
            this.applyCompression(req, res);
            
            // Intercept response end
            const originalEnd = res.end;
            res.end = (...args) => {
                if (shouldSample && req.performanceMonitoring) {
                    this.recordMetrics(req, res);
                }
                originalEnd.apply(res, args);
            };

            next();
        };
    }

    recordMetrics(req, res) {
        const endTime = process.hrtime.bigint();
        const endMemory = process.memoryUsage();
        const { startTime, startMemory, endpoint } = req.performanceMonitoring;
        
        const responseTime = Number(endTime - startTime) / 1000000; // Convert to ms
        const memoryDelta = endMemory.heapUsed - startMemory.heapUsed;
        
        const metric = {
            timestamp: new Date(),
            endpoint,
            method: req.method,
            statusCode: res.statusCode,
            responseTime,
            memoryDelta,
            memoryUsage: endMemory.heapUsed,
            cpuUsage: this.getCpuUsage(),
            contentLength: res.get('Content-Length') || 0,
            userAgent: req.get('User-Agent'),
            ip: req.ip
        };

        this.storeMetric(endpoint, metric);
        this.checkThresholds(metric);
        this.logMetric(metric);
    }

    storeMetric(endpoint, metric) {
        if (!this.metrics.has(endpoint)) {
            this.metrics.set(endpoint, {
                requests: [],
                aggregates: {
                    totalRequests: 0,
                    averageResponseTime: 0,
                    p95ResponseTime: 0,
                    p99ResponseTime: 0,
                    errorRate: 0,
                    throughput: 0
                }
            });
        }

        const endpointMetrics = this.metrics.get(endpoint);
        endpointMetrics.requests.push(metric);
        
        // Keep only last 1000 requests per endpoint
        if (endpointMetrics.requests.length > 1000) {
            endpointMetrics.requests.shift();
        }

        this.updateAggregates(endpoint);
    }

    updateAggregates(endpoint) {
        const endpointMetrics = this.metrics.get(endpoint);
        const requests = endpointMetrics.requests;
        
        if (requests.length === 0) return;

        // Calculate aggregates
        const responseTimes = requests.map(r => r.responseTime);
        const errorCount = requests.filter(r => r.statusCode >= 400).length;
        
        endpointMetrics.aggregates = {
            totalRequests: requests.length,
            averageResponseTime: this.average(responseTimes),
            p95ResponseTime: this.percentile(responseTimes, 95),
            p99ResponseTime: this.percentile(responseTimes, 99),
            errorRate: errorCount / requests.length,
            throughput: this.calculateThroughput(requests)
        };
    }

    checkThresholds(metric) {
        const { alertThresholds } = this.config;
        
        // Response time alert
        if (metric.responseTime > alertThresholds.responseTime) {
            this.emit('alert', {
                type: 'high_response_time',
                metric,
                threshold: alertThresholds.responseTime,
                message: `High response time: ${metric.responseTime}ms for ${metric.endpoint}`
            });
            
            this.suggestOptimizations(metric);
        }

        // Memory usage alert
        const memoryUsagePercent = metric.memoryUsage / (os.totalmem() * 1024 * 1024);
        if (memoryUsagePercent > alertThresholds.memoryUsage) {
            this.emit('alert', {
                type: 'high_memory_usage',
                metric,
                threshold: alertThresholds.memoryUsage,
                message: `High memory usage: ${(memoryUsagePercent * 100).toFixed(1)}%`
            });
        }

        // Error rate alert
        const endpointMetrics = this.metrics.get(metric.endpoint);
        if (endpointMetrics && endpointMetrics.aggregates.errorRate > alertThresholds.errorRate) {
            this.emit('alert', {
                type: 'high_error_rate',
                metric,
                threshold: alertThresholds.errorRate,
                message: `High error rate: ${(endpointMetrics.aggregates.errorRate * 100).toFixed(1)}% for ${metric.endpoint}`
            });
        }
    }

    suggestOptimizations(metric) {
        const suggestions = [];

        // Suggest caching for slow GET requests
        if (metric.method === 'GET' && metric.responseTime > 200) {
            suggestions.push({
                type: 'caching',
                priority: 'high',
                description: 'Enable response caching for this endpoint',
                estimatedImprovement: '60-80% response time reduction'
            });
        }

        // Suggest compression for large responses
        if (metric.contentLength > 1024) {
            suggestions.push({
                type: 'compression',
                priority: 'medium',
                description: 'Enable gzip compression',
                estimatedImprovement: '70% size reduction'
            });
        }

        // Suggest database optimization for data endpoints
        if (metric.endpoint.includes('/api/') && metric.responseTime > 500) {
            suggestions.push({
                type: 'query_optimization',
                priority: 'high',
                description: 'Optimize database queries and add indexes',
                estimatedImprovement: '50-90% query time reduction'
            });
        }

        if (suggestions.length > 0) {
            this.emit('optimization_suggestions', {
                endpoint: metric.endpoint,
                suggestions,
                currentMetric: metric
            });
        }
    }

    // Optimization Implementations
    applyCaching(req, res) {
        const caching = this.optimizations.get('caching');
        if (!caching.enabled || req.method !== 'GET') return;

        const cacheKey = this.generateCacheKey(req);
        const cachedResponse = caching.cache.get(cacheKey);

        if (cachedResponse) {
            const isExpired = Date.now() - cachedResponse.timestamp > caching.ttl;
            if (!isExpired) {
                // Cache hit
                caching.hitRate = (caching.hitRate * 0.9) + (1 * 0.1); // Exponential moving average
                res.set('X-Cache', 'HIT');
                res.set('Content-Type', cachedResponse.contentType);
                return res.status(cachedResponse.statusCode).send(cachedResponse.data);
            } else {
                // Expired cache entry
                caching.cache.delete(cacheKey);
            }
        }

        // Cache miss - intercept response
        const originalSend = res.send;
        res.send = function(data) {
            if (res.statusCode === 200) {
                // Store in cache
                caching.cache.set(cacheKey, {
                    data,
                    statusCode: res.statusCode,
                    contentType: res.get('Content-Type'),
                    timestamp: Date.now()
                });

                // Manage cache size
                if (caching.cache.size > caching.maxSize) {
                    const firstKey = caching.cache.keys().next().value;
                    caching.cache.delete(firstKey);
                }
            }
            
            caching.hitRate = (caching.hitRate * 0.9) + (0 * 0.1); // Cache miss
            res.set('X-Cache', 'MISS');
            originalSend.call(this, data);
        };
    }

    applyCompression(req, res) {
        const compression = this.optimizations.get('compression');
        if (!compression.enabled) return;

        const acceptsGzip = req.headers['accept-encoding']?.includes('gzip');
        if (!acceptsGzip) return;

        const originalSend = res.send;
        res.send = function(data) {
            if (typeof data === 'string' && data.length > compression.threshold) {
                const zlib = require('zlib');
                const compressed = zlib.gzipSync(data);
                
                compression.compressionRatio = (compression.compressionRatio * 0.9) + 
                                              ((1 - compressed.length / data.length) * 0.1);
                
                res.set('Content-Encoding', 'gzip');
                res.set('Content-Length', compressed.length);
                return originalSend.call(this, compressed);
            }
            
            originalSend.call(this, data);
        };
    }

    generateCacheKey(req) {
        return `${req.method}:${req.originalUrl}:${JSON.stringify(req.query)}`;
    }

    // Performance Analysis
    analyzePerformance(endpoint = null) {
        if (endpoint) {
            return this.analyzeEndpoint(endpoint);
        }

        const analysis = {
            overall: this.getOverallMetrics(),
            endpoints: {},
            recommendations: [],
            optimizationStatus: this.getOptimizationStatus()
        };

        // Analyze each endpoint
        for (const [endpointName, metrics] of this.metrics.entries()) {
            analysis.endpoints[endpointName] = this.analyzeEndpoint(endpointName);
        }

        // Generate global recommendations
        analysis.recommendations = this.generateGlobalRecommendations(analysis);

        return analysis;
    }

    analyzeEndpoint(endpoint) {
        const metrics = this.metrics.get(endpoint);
        if (!metrics || metrics.requests.length === 0) {
            return { error: 'No data available for this endpoint' };
        }

        const { requests, aggregates } = metrics;
        const recentRequests = requests.slice(-100); // Last 100 requests

        return {
            endpoint,
            summary: aggregates,
            trends: this.calculateTrends(requests),
            patterns: this.identifyPatterns(requests),
            bottlenecks: this.identifyBottlenecks(requests),
            recommendations: this.generateEndpointRecommendations(endpoint, metrics)
        };
    }

    calculateTrends(requests) {
        if (requests.length < 10) return { insufficient_data: true };

        const recent = requests.slice(-50);
        const older = requests.slice(-100, -50);

        return {
            responseTime: {
                recent: this.average(recent.map(r => r.responseTime)),
                previous: this.average(older.map(r => r.responseTime)),
                trend: this.calculateTrendDirection(recent, older, 'responseTime')
            },
            errorRate: {
                recent: recent.filter(r => r.statusCode >= 400).length / recent.length,
                previous: older.filter(r => r.statusCode >= 400).length / older.length,
                trend: this.calculateTrendDirection(recent, older, 'statusCode', (r) => r >= 400)
            },
            throughput: {
                recent: this.calculateThroughput(recent),
                previous: this.calculateThroughput(older),
                trend: this.calculateTrendDirection(recent, older, 'throughput')
            }
        };
    }

    identifyPatterns(requests) {
        const patterns = {
            timeOfDay: this.analyzeTimePatterns(requests),
            userAgent: this.analyzeUserAgentPatterns(requests),
            statusCode: this.analyzeStatusCodePatterns(requests),
            responseSize: this.analyzeResponseSizePatterns(requests)
        };

        return patterns;
    }

    identifyBottlenecks(requests) {
        const bottlenecks = [];

        // Identify slow requests
        const slowRequests = requests.filter(r => r.responseTime > 1000);
        if (slowRequests.length > requests.length * 0.1) {
            bottlenecks.push({
                type: 'slow_requests',
                severity: 'high',
                description: `${slowRequests.length} requests (${(slowRequests.length/requests.length*100).toFixed(1)}%) are slower than 1s`,
                suggestion: 'Consider database optimization, caching, or code profiling'
            });
        }

        // Identify memory-intensive requests
        const highMemoryRequests = requests.filter(r => r.memoryDelta > 10 * 1024 * 1024); // 10MB
        if (highMemoryRequests.length > 0) {
            bottlenecks.push({
                type: 'memory_intensive',
                severity: 'medium',
                description: `${highMemoryRequests.length} requests use excessive memory`,
                suggestion: 'Review data processing and implement streaming for large datasets'
            });
        }

        return bottlenecks;
    }

    generateEndpointRecommendations(endpoint, metrics) {
        const recommendations = [];
        const { aggregates } = metrics;

        // High response time recommendations
        if (aggregates.averageResponseTime > 500) {
            recommendations.push({
                priority: 'high',
                type: 'performance',
                title: 'Optimize Response Time',
                description: `Average response time is ${aggregates.averageResponseTime.toFixed(0)}ms`,
                actions: [
                    'Enable response caching',
                    'Optimize database queries',
                    'Implement pagination for large datasets',
                    'Add database indexes'
                ]
            });
        }

        // High error rate recommendations
        if (aggregates.errorRate > 0.05) {
            recommendations.push({
                priority: 'critical',
                type: 'reliability',
                title: 'Reduce Error Rate',
                description: `Error rate is ${(aggregates.errorRate * 100).toFixed(1)}%`,
                actions: [
                    'Implement better error handling',
                    'Add input validation',
                    'Monitor upstream dependencies',
                    'Implement circuit breakers'
                ]
            });
        }

        return recommendations;
    }

    // Automatic Optimization
    enableOptimization(optimizationType, config = {}) {
        const optimization = this.optimizations.get(optimizationType);
        if (!optimization) {
            throw new Error(`Unknown optimization type: ${optimizationType}`);
        }

        optimization.enabled = true;
        Object.assign(optimization, config);

        console.log(`✅ Enabled optimization: ${optimizationType}`);
        this.emit('optimization_enabled', { type: optimizationType, config });

        return optimization;
    }

    disableOptimization(optimizationType) {
        const optimization = this.optimizations.get(optimizationType);
        if (optimization) {
            optimization.enabled = false;
            console.log(`❌ Disabled optimization: ${optimizationType}`);
            this.emit('optimization_disabled', { type: optimizationType });
        }
    }

    autoOptimize() {
        console.log('🚀 Starting automatic optimization...');

        for (const [endpoint, metrics] of this.metrics.entries()) {
            const { aggregates } = metrics;

            // Auto-enable caching for slow GET endpoints
            if (endpoint.includes('GET') && aggregates.averageResponseTime > 300) {
                if (!this.optimizations.get('caching').enabled) {
                    this.enableOptimization('caching', {
                        ttl: this.calculateOptimalCacheTTL(metrics)
                    });
                }
            }

            // Auto-enable compression for large responses
            const avgContentLength = this.calculateAverageContentLength(metrics);
            if (avgContentLength > 1024 && !this.optimizations.get('compression').enabled) {
                this.enableOptimization('compression');
            }
        }
    }

    calculateOptimalCacheTTL(metrics) {
        // Simple heuristic: longer TTL for slower endpoints
        const avgResponseTime = metrics.aggregates.averageResponseTime;
        if (avgResponseTime > 1000) return 600000; // 10 minutes
        if (avgResponseTime > 500) return 300000;  // 5 minutes
        return 180000; // 3 minutes
    }

    // Monitoring and Reporting
    startMonitoring() {
        if (this.isMonitoring) return;

        this.isMonitoring = true;
        this.monitoringInterval = setInterval(() => {
            this.generatePerformanceReport();
            this.checkForOptimizationOpportunities();
        }, this.config.monitoringInterval);

        console.log('📊 Performance monitoring started');
    }

    stopMonitoring() {
        if (!this.isMonitoring) return;

        this.isMonitoring = false;
        if (this.monitoringInterval) {
            clearInterval(this.monitoringInterval);
            this.monitoringInterval = null;
        }

        console.log('📊 Performance monitoring stopped');
    }

    generatePerformanceReport() {
        const report = {
            timestamp: new Date(),
            system: {
                memory: process.memoryUsage(),
                uptime: process.uptime(),
                cpuUsage: this.getCpuUsage()
            },
            application: this.analyzePerformance(),
            optimizations: this.getOptimizationStatus()
        };

        this.emit('performance_report', report);
        return report;
    }

    checkForOptimizationOpportunities() {
        const opportunities = [];

        for (const [endpoint, metrics] of this.metrics.entries()) {
            const { aggregates } = metrics;

            // Check if caching would help
            if (!this.optimizations.get('caching').enabled && 
                endpoint.includes('GET') && 
                aggregates.averageResponseTime > 200) {
                opportunities.push({
                    type: 'caching',
                    endpoint,
                    impact: 'high',
                    description: 'Enable caching to reduce response time'
                });
            }

            // Check if query optimization is needed
            if (aggregates.p95ResponseTime > 1000) {
                opportunities.push({
                    type: 'query_optimization',
                    endpoint,
                    impact: 'high',
                    description: 'Optimize database queries'
                });
            }
        }

        if (opportunities.length > 0) {
            this.emit('optimization_opportunities', opportunities);
        }
    }

    // Utility Methods
    getCpuUsage() {
        const usage = process.cpuUsage();
        return (usage.user + usage.system) / 1000000; // Convert to seconds
    }

    average(numbers) {
        return numbers.reduce((sum, n) => sum + n, 0) / numbers.length;
    }

    percentile(numbers, p) {
        const sorted = numbers.sort((a, b) => a - b);
        const index = Math.ceil((p / 100) * sorted.length) - 1;
        return sorted[index];
    }

    calculateThroughput(requests) {
        if (requests.length < 2) return 0;
        
        const timeSpan = requests[requests.length - 1].timestamp - requests[0].timestamp;
        return (requests.length / timeSpan) * 1000; // requests per second
    }

    getOptimizationStatus() {
        const status = {};
        for (const [name, optimization] of this.optimizations.entries()) {
            status[name] = {
                enabled: optimization.enabled,
                ...optimization
            };
        }
        return status;
    }

    logMetric(metric) {
        const logEntry = JSON.stringify({
            ...metric,
            timestamp: metric.timestamp.toISOString()
        }) + '\n';
        
        fs.appendFileSync(this.config.logFile, logEntry);
    }

    // Export/Import
    exportMetrics() {
        return {
            metrics: Object.fromEntries(this.metrics),
            optimizations: Object.fromEntries(this.optimizations),
            config: this.config,
            exportedAt: new Date()
        };
    }

    importMetrics(data) {
        if (data.metrics) {
            this.metrics = new Map(Object.entries(data.metrics));
        }
        if (data.optimizations) {
            this.optimizations = new Map(Object.entries(data.optimizations));
        }
        if (data.config) {
            this.config = { ...this.config, ...data.config };
        }
    }
}

module.exports = PerformanceOptimizer;
