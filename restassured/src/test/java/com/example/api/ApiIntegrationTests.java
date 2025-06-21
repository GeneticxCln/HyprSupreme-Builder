package com.example.api;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Nested;

import static io.restassured.RestAssured.*;
import static io.restassured.matcher.RestAssuredMatchers.*;
import static org.hamcrest.Matchers.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("API Integration Tests")
public class ApiIntegrationTests {

    private static final String BASE_URL = "http://localhost:3000";
    private static int createdUserId;

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = BASE_URL;
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
    }

    @Nested
    @DisplayName("Health Check Tests")
    class HealthCheckTests {

        @Test
        @DisplayName("GET /health should return healthy status")
        public void testHealthCheck() {
            given()
            .when()
                .get("/health")
            .then()
                .statusCode(200)
                .contentType(ContentType.JSON)
                .body("status", equalTo("healthy"))
                .body("version", equalTo("1.0.0"))
                .body("timestamp", notNullValue())
                .time(lessThan(200L));
        }
    }

    @Nested
    @DisplayName("Users CRUD Operations")
    class UsersCrudTests {

        @Test
        @Order(1)
        @DisplayName("GET /api/users should return all users")
        public void testGetAllUsers() {
            given()
            .when()
                .get("/api/users")
            .then()
                .statusCode(200)
                .contentType(ContentType.JSON)
                .body("success", equalTo(true))
                .body("data", is(instanceOf(java.util.List.class)))
                .body("count", greaterThan(0))
                .body("data[0].id", notNullValue())
                .body("data[0].name", notNullValue())
                .body("data[0].email", notNullValue());
        }

        @Test
        @Order(2)
        @DisplayName("GET /api/users/1 should return specific user")
        public void testGetUserById() {
            given()
            .when()
                .get("/api/users/1")
            .then()
                .statusCode(200)
                .contentType(ContentType.JSON)
                .body("success", equalTo(true))
                .body("data.id", equalTo(1))
                .body("data.name", equalTo("John Doe"))
                .body("data.email", equalTo("john@example.com"));
        }

        @Test
        @Order(3)
        @DisplayName("POST /api/users should create new user")
        public void testCreateUser() {
            String requestBody = """
                {
                    "name": "RestAssured User",
                    "email": "restassured@example.com",
                    "age": 35
                }
                """;

            Response response = given()
                .contentType(ContentType.JSON)
                .body(requestBody)
            .when()
                .post("/api/users")
            .then()
                .statusCode(201)
                .contentType(ContentType.JSON)
                .body("success", equalTo(true))
                .body("message", equalTo("User created successfully"))
                .body("data.name", equalTo("RestAssured User"))
                .body("data.email", equalTo("restassured@example.com"))
                .body("data.age", equalTo(35))
                .body("data.id", notNullValue())
                .extract().response();

            // Store the created user ID for subsequent tests
            createdUserId = response.path("data.id");
        }

        @Test
        @Order(4)
        @DisplayName("PUT /api/users/{id} should update existing user")
        public void testUpdateUser() {
            String requestBody = """
                {
                    "name": "Updated RestAssured User",
                    "age": 36
                }
                """;

            given()
                .contentType(ContentType.JSON)
                .body(requestBody)
                .pathParam("id", createdUserId)
            .when()
                .put("/api/users/{id}")
            .then()
                .statusCode(200)
                .contentType(ContentType.JSON)
                .body("success", equalTo(true))
                .body("message", equalTo("User updated successfully"))
                .body("data.name", equalTo("Updated RestAssured User"))
                .body("data.age", equalTo(36))
                .body("data.email", equalTo("restassured@example.com")); // Should remain unchanged
        }

        @Test
        @Order(5)
        @DisplayName("DELETE /api/users/{id} should delete existing user")
        public void testDeleteUser() {
            given()
                .pathParam("id", createdUserId)
            .when()
                .delete("/api/users/{id}")
            .then()
                .statusCode(200)
                .contentType(ContentType.JSON)
                .body("success", equalTo(true))
                .body("message", equalTo("User deleted successfully"))
                .body("data.id", equalTo(createdUserId));

            // Verify user is actually deleted
            given()
                .pathParam("id", createdUserId)
            .when()
                .get("/api/users/{id}")
            .then()
                .statusCode(404)
                .body("success", equalTo(false))
                .body("error", equalTo("User not found"));
        }
    }

    @Nested
    @DisplayName("Error Handling Tests")
    class ErrorHandlingTests {

        @Test
        @DisplayName("GET /api/users/999 should return 404 for non-existent user")
        public void testGetNonExistentUser() {
            given()
            .when()
                .get("/api/users/999")
            .then()
                .statusCode(404)
                .contentType(ContentType.JSON)
                .body("success", equalTo(false))
                .body("error", equalTo("User not found"));
        }

        @Test
        @DisplayName("POST /api/users with missing fields should return 400")
        public void testCreateUserWithMissingFields() {
            String requestBody = """
                {
                    "name": "Incomplete User"
                }
                """;

            given()
                .contentType(ContentType.JSON)
                .body(requestBody)
            .when()
                .post("/api/users")
            .then()
                .statusCode(400)
                .contentType(ContentType.JSON)
                .body("success", equalTo(false))
                .body("error", equalTo("Name and email are required"));
        }

        @Test
        @DisplayName("POST /api/users with duplicate email should return 409")
        public void testCreateUserWithDuplicateEmail() {
            String requestBody = """
                {
                    "name": "Duplicate Email User",
                    "email": "john@example.com"
                }
                """;

            given()
                .contentType(ContentType.JSON)
                .body(requestBody)
            .when()
                .post("/api/users")
            .then()
                .statusCode(409)
                .contentType(ContentType.JSON)
                .body("success", equalTo(false))
                .body("error", equalTo("Email already exists"));
        }

        @Test
        @DisplayName("PUT /api/users/999 should return 404 for non-existent user")
        public void testUpdateNonExistentUser() {
            String requestBody = """
                {
                    "name": "Non-existent User"
                }
                """;

            given()
                .contentType(ContentType.JSON)
                .body(requestBody)
            .when()
                .put("/api/users/999")
            .then()
                .statusCode(404)
                .contentType(ContentType.JSON)
                .body("success", equalTo(false))
                .body("error", equalTo("User not found"));
        }

        @Test
        @DisplayName("DELETE /api/users/999 should return 404 for non-existent user")
        public void testDeleteNonExistentUser() {
            given()
            .when()
                .delete("/api/users/999")
            .then()
                .statusCode(404)
                .contentType(ContentType.JSON)
                .body("success", equalTo(false))
                .body("error", equalTo("User not found"));
        }

        @Test
        @DisplayName("GET /api/nonexistent should return 404")
        public void testNonExistentRoute() {
            given()
            .when()
                .get("/api/nonexistent")
            .then()
                .statusCode(404)
                .contentType(ContentType.JSON)
                .body("success", equalTo(false))
                .body("error", equalTo("Route not found"));
        }
    }

    @Nested
    @DisplayName("Integration Scenarios")
    class IntegrationScenarios {

        @Test
        @DisplayName("Complete user lifecycle: Create -> Read -> Update -> Delete")
        public void testCompleteUserLifecycle() {
            // 1. Create user
            String createRequestBody = """
                {
                    "name": "Lifecycle Test User",
                    "email": "lifecycle@example.com",
                    "age": 40
                }
                """;

            Response createResponse = given()
                .contentType(ContentType.JSON)
                .body(createRequestBody)
            .when()
                .post("/api/users")
            .then()
                .statusCode(201)
                .body("success", equalTo(true))
                .body("data.name", equalTo("Lifecycle Test User"))
                .extract().response();

            int userId = createResponse.path("data.id");

            // 2. Read user
            given()
                .pathParam("id", userId)
            .when()
                .get("/api/users/{id}")
            .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data.id", equalTo(userId))
                .body("data.name", equalTo("Lifecycle Test User"))
                .body("data.email", equalTo("lifecycle@example.com"));

            // 3. Update user
            String updateRequestBody = """
                {
                    "name": "Updated Lifecycle User",
                    "age": 41
                }
                """;

            given()
                .contentType(ContentType.JSON)
                .body(updateRequestBody)
                .pathParam("id", userId)
            .when()
                .put("/api/users/{id}")
            .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data.name", equalTo("Updated Lifecycle User"))
                .body("data.age", equalTo(41));

            // 4. Delete user
            given()
                .pathParam("id", userId)
            .when()
                .delete("/api/users/{id}")
            .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data.id", equalTo(userId));

            // 5. Verify deletion
            given()
                .pathParam("id", userId)
            .when()
                .get("/api/users/{id}")
            .then()
                .statusCode(404)
                .body("success", equalTo(false))
                .body("error", equalTo("User not found"));
        }

        @Test
        @DisplayName("Bulk operations: Create multiple users and verify count")
        public void testBulkOperations() {
            // Get initial count
            Response initialResponse = given()
            .when()
                .get("/api/users")
            .then()
                .statusCode(200)
                .extract().response();

            int initialCount = initialResponse.path("count");

            // Create multiple users
            String[] users = {
                """
                {
                    "name": "Bulk User 1",
                    "email": "bulk1@restassured.com"
                }
                """,
                """
                {
                    "name": "Bulk User 2", 
                    "email": "bulk2@restassured.com"
                }
                """,
                """
                {
                    "name": "Bulk User 3",
                    "email": "bulk3@restassured.com"
                }
                """
            };

            for (String user : users) {
                given()
                    .contentType(ContentType.JSON)
                    .body(user)
                .when()
                    .post("/api/users")
                .then()
                    .statusCode(201)
                    .body("success", equalTo(true));
            }

            // Verify count increased
            given()
            .when()
                .get("/api/users")
            .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("count", equalTo(initialCount + users.length));
        }

        @Test
        @DisplayName("Response time performance test")
        public void testResponseTimePerformance() {
            given()
            .when()
                .get("/api/users")
            .then()
                .statusCode(200)
                .time(lessThan(100L)); // Response should be under 100ms

            given()
            .when()
                .get("/health")
            .then()
                .statusCode(200)
                .time(lessThan(50L)); // Health check should be under 50ms
        }
    }
}
