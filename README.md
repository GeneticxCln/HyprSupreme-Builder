# API Integration Testing with Postman, Supertest, and RestAssured

This project demonstrates comprehensive integration testing for a REST API using three popular testing tools:
- **Postman** - GUI-based API testing with automation capabilities
- **Supertest** - Node.js library for HTTP integration testing
- **RestAssured** - Java library for REST API testing

## 📋 Table of Contents
- [Project Structure](#project-structure)
- [API Overview](#api-overview)
- [Setup Instructions](#setup-instructions)
- [Running Tests](#running-tests)
- [Testing Tools Comparison](#testing-tools-comparison)
- [Best Practices](#best-practices)

## 🏗️ Project Structure

```
api-integration-testing/
├── server.js                     # Express.js API server
├── package.json                  # Node.js dependencies
├── tests/
│   └── integration.test.js       # Supertest integration tests
├── postman/
│   └── API-Integration-Tests.postman_collection.json
└── restassured/
    ├── pom.xml                   # Maven configuration
    └── src/test/java/com/example/api/
        └── ApiIntegrationTests.java
```

## 🔧 API Overview

The sample API provides a complete CRUD interface for user management:

### Endpoints
- `GET /health` - Health check endpoint
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Sample Data Structure
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "age": 30
}
```

## 🚀 Setup Instructions

### Prerequisites
- Node.js (v14+)
- Java 11+ (for RestAssured tests)
- Maven (for RestAssured tests)
- Postman application (for Postman tests)

### 1. Install Node.js Dependencies
```bash
cd api-integration-testing
npm install
```

### 2. Start the API Server
```bash
npm start
```
The server will run on `http://localhost:3000`

### 3. Verify API is Running
```bash
curl http://localhost:3000/health
```

## 🧪 Running Tests

### Supertest (Node.js)
```bash
# Run all integration tests
npm test

# Run specific test pattern
npm run test:integration
```

### Postman
1. **Import Collection:**
   - Open Postman
   - Import `postman/API-Integration-Tests.postman_collection.json`

2. **Run Collection:**
   - Click "Run Collection"
   - Ensure API server is running on localhost:3000
   - Execute all tests or individual requests

3. **Command Line (Newman):**
   ```bash
   npm install -g newman
   newman run postman/API-Integration-Tests.postman_collection.json
   ```

### RestAssured (Java)
```bash
cd restassured

# Run all tests
mvn test

# Run specific test class
mvn test -Dtest=ApiIntegrationTests

# Run with detailed output
mvn test -Dtest=ApiIntegrationTests -DforkCount=1 -DreuseForks=false
```

## ⚖️ Testing Tools Comparison

| Feature | Postman | Supertest | RestAssured |
|---------|---------|-----------|-------------|
| **Language** | JavaScript | JavaScript/Node.js | Java |
| **Learning Curve** | Easy | Medium | Medium |
| **GUI Support** | ✅ Excellent | ❌ Code only | ❌ Code only |
| **CI/CD Integration** | ✅ Newman CLI | ✅ Native | ✅ Maven/Gradle |
| **Test Organization** | Collections/Folders | Jest/Mocha describe blocks | JUnit annotations |
| **Assertions** | Chai.js syntax | Jest matchers | Hamcrest matchers |
| **Data Management** | Variables/Environments | JavaScript objects | Java objects |
| **Reporting** | Built-in HTML reports | Jest reporters | Maven Surefire reports |
| **Performance Testing** | ✅ Basic | ⚠️ Limited | ⚠️ Limited |
| **Team Collaboration** | ✅ Workspaces | ✅ Version control | ✅ Version control |

### When to Use Each Tool

#### Postman
- **Best for:** Manual testing, API exploration, team collaboration
- **Use when:** 
  - Non-developers need to test APIs
  - Quick prototyping and debugging
  - Need GUI-based test creation
  - API documentation is required

#### Supertest
- **Best for:** Node.js applications, JavaScript teams
- **Use when:**
  - Testing Node.js/Express applications
  - Team already uses JavaScript/TypeScript
  - Need tight integration with Jest/Mocha
  - Prefer lightweight, code-first approach

#### RestAssured
- **Best for:** Java applications, enterprise environments
- **Use when:**
  - Testing Java-based APIs (Spring Boot, etc.)
  - Team primarily uses Java
  - Need advanced JSON/XML validation
  - Enterprise-grade test reporting required

## 📊 Test Coverage

All three tools cover the same test scenarios:

### ✅ CRUD Operations
- Create, Read, Update, Delete users
- Response validation
- Status code verification

### ✅ Error Handling
- 404 errors for non-existent resources
- 400 errors for invalid input
- 409 errors for conflicts

### ✅ Integration Scenarios
- Complete user lifecycle testing
- Bulk operations
- Data consistency verification

### ✅ Performance Testing
- Response time validation
- Basic load testing capabilities

## 🎯 Best Practices

### General Testing Principles
1. **Test Independence:** Each test should be independent and not rely on others
2. **Data Cleanup:** Clean up test data after each test run
3. **Meaningful Assertions:** Test both happy path and error scenarios
4. **Clear Test Names:** Use descriptive test names and organize logically

### Postman Best Practices
- Use collection variables for reusable data
- Implement proper test scripts with assertions
- Organize tests in logical folders
- Use environments for different deployment stages

### Supertest Best Practices
- Use `beforeEach`/`afterEach` for test setup/cleanup
- Group related tests using `describe` blocks
- Use async/await for better readability
- Mock external dependencies when necessary

### RestAssured Best Practices
- Use `@BeforeAll` for one-time setup
- Organize tests with nested classes (`@Nested`)
- Use method chaining for readable assertions
- Implement proper test ordering when needed

## 🔧 Configuration

### Environment Variables
Create a `.env` file for configuration:
```bash
PORT=3000
NODE_ENV=test
API_BASE_URL=http://localhost:3000
```

### Postman Environment
Set up environment variables in Postman:
- `baseUrl`: `http://localhost:3000`
- `userId`: (dynamically set during tests)

### RestAssured Configuration
Configure base URI in test setup:
```java
@BeforeAll
public static void setup() {
    RestAssured.baseURI = "http://localhost:3000";
}
```

## 🚀 Advanced Features

### Data-Driven Testing
Each tool supports data-driven testing:
- **Postman:** CSV/JSON data files
- **Supertest:** JavaScript arrays/objects
- **RestAssured:** JUnit parameterized tests

### Test Reporting
- **Postman:** HTML reports via Newman
- **Supertest:** Jest coverage reports
- **RestAssured:** Maven Surefire reports

### Continuous Integration
All tools integrate well with CI/CD pipelines:
```yaml
# GitHub Actions example
- name: Run Integration Tests
  run: |
    npm install
    npm start &
    npm test
    newman run postman/API-Integration-Tests.postman_collection.json
    cd restassured && mvn test
```

## 📚 Additional Resources

- [Postman Documentation](https://learning.postman.com/)
- [Supertest GitHub](https://github.com/visionmedia/supertest)
- [RestAssured Documentation](https://rest-assured.io/)
- [API Testing Best Practices](https://www.postman.com/api-testing/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all existing tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
