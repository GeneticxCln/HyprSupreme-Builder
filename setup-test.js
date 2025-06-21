// Quick verification script to test if the API server works
// Run with: node setup-test.js

const http = require('http');

console.log('🚀 Starting API Integration Testing Setup Verification...\n');

// Start the server
const app = require('./server');
const server = app.listen(3001, () => {
    console.log('✅ Server started on port 3001');
    
    // Test the health endpoint
    const options = {
        hostname: 'localhost',
        port: 3001,
        path: '/health',
        method: 'GET'
    };

    const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
            data += chunk;
        });
        
        res.on('end', () => {
            console.log('✅ Health check response:', JSON.parse(data));
            
            // Test users endpoint
            testUsersEndpoint(() => {
                server.close(() => {
                    console.log('\n🎉 Setup verification complete!');
                    console.log('\n📋 Next steps:');
                    console.log('1. Install Node.js dependencies: npm install');
                    console.log('2. Start the server: npm start');
                    console.log('3. Run Supertest: npm test');
                    console.log('4. Import Postman collection and run tests');
                    console.log('5. Run RestAssured tests: cd restassured && mvn test');
                });
            });
        });
    });
    
    req.on('error', (err) => {
        console.error('❌ Health check failed:', err.message);
        server.close();
    });
    
    req.end();
});

function testUsersEndpoint(callback) {
    const options = {
        hostname: 'localhost',
        port: 3001,
        path: '/api/users',
        method: 'GET'
    };

    const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
            data += chunk;
        });
        
        res.on('end', () => {
            const response = JSON.parse(data);
            console.log('✅ Users endpoint response:');
            console.log(`   - Success: ${response.success}`);
            console.log(`   - User count: ${response.count}`);
            console.log(`   - First user: ${response.data[0].name}`);
            callback();
        });
    });
    
    req.on('error', (err) => {
        console.error('❌ Users endpoint test failed:', err.message);
        callback();
    });
    
    req.end();
}
