const request = require('supertest');
const app = require('../server');

describe('API Integration Tests', () => {
  
  describe('Health Check', () => {
    test('GET /health should return healthy status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);
      
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('version', '1.0.0');
    });
  });

  describe('Users API', () => {
    
    test('GET /api/users should return all users', async () => {
      const response = await request(app)
        .get('/api/users')
        .expect(200);
      
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.count).toBeGreaterThan(0);
      expect(response.body.data[0]).toHaveProperty('id');
      expect(response.body.data[0]).toHaveProperty('name');
      expect(response.body.data[0]).toHaveProperty('email');
    });

    test('GET /api/users/:id should return specific user', async () => {
      const response = await request(app)
        .get('/api/users/1')
        .expect(200);
      
      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe(1);
      expect(response.body.data.name).toBe('John Doe');
      expect(response.body.data.email).toBe('john@example.com');
    });

    test('GET /api/users/:id should return 404 for non-existent user', async () => {
      const response = await request(app)
        .get('/api/users/999')
        .expect(404);
      
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('User not found');
    });

    test('POST /api/users should create new user', async () => {
      const newUser = {
        name: 'Alice Johnson',
        email: 'alice@example.com',
        age: 28
      };

      const response = await request(app)
        .post('/api/users')
        .send(newUser)
        .expect(201);
      
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(newUser.name);
      expect(response.body.data.email).toBe(newUser.email);
      expect(response.body.data.age).toBe(newUser.age);
      expect(response.body.data.id).toBeDefined();
      expect(response.body.message).toBe('User created successfully');
    });

    test('POST /api/users should return 400 for missing required fields', async () => {
      const invalidUser = {
        name: 'Bob Smith'
        // Missing email
      };

      const response = await request(app)
        .post('/api/users')
        .send(invalidUser)
        .expect(400);
      
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Name and email are required');
    });

    test('POST /api/users should return 409 for duplicate email', async () => {
      const duplicateUser = {
        name: 'John Duplicate',
        email: 'john@example.com' // This email already exists
      };

      const response = await request(app)
        .post('/api/users')
        .send(duplicateUser)
        .expect(409);
      
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Email already exists');
    });

    test('PUT /api/users/:id should update existing user', async () => {
      const updateData = {
        name: 'John Updated',
        age: 31
      };

      const response = await request(app)
        .put('/api/users/1')
        .send(updateData)
        .expect(200);
      
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('John Updated');
      expect(response.body.data.age).toBe(31);
      expect(response.body.data.email).toBe('john@example.com'); // Should remain unchanged
      expect(response.body.message).toBe('User updated successfully');
    });

    test('PUT /api/users/:id should return 404 for non-existent user', async () => {
      const updateData = {
        name: 'Non-existent User'
      };

      const response = await request(app)
        .put('/api/users/999')
        .send(updateData)
        .expect(404);
      
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('User not found');
    });

    test('DELETE /api/users/:id should delete existing user', async () => {
      // First, create a user to delete
      const newUser = {
        name: 'To Be Deleted',
        email: 'delete@example.com'
      };

      const createResponse = await request(app)
        .post('/api/users')
        .send(newUser)
        .expect(201);
      
      const userId = createResponse.body.data.id;

      // Now delete the user
      const deleteResponse = await request(app)
        .delete(`/api/users/${userId}`)
        .expect(200);
      
      expect(deleteResponse.body.success).toBe(true);
      expect(deleteResponse.body.data.id).toBe(userId);
      expect(deleteResponse.body.message).toBe('User deleted successfully');

      // Verify user is actually deleted
      await request(app)
        .get(`/api/users/${userId}`)
        .expect(404);
    });

    test('DELETE /api/users/:id should return 404 for non-existent user', async () => {
      const response = await request(app)
        .delete('/api/users/999')
        .expect(404);
      
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('User not found');
    });

  });

  describe('Error Handling', () => {
    
    test('should return 404 for non-existent routes', async () => {
      const response = await request(app)
        .get('/api/nonexistent')
        .expect(404);
      
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Route not found');
    });

  });

  describe('Integration Test Scenarios', () => {
    
    test('Complete user lifecycle: Create -> Read -> Update -> Delete', async () => {
      // 1. Create user
      const newUser = {
        name: 'Test User',
        email: 'test@lifecycle.com',
        age: 25
      };

      const createResponse = await request(app)
        .post('/api/users')
        .send(newUser)
        .expect(201);
      
      const userId = createResponse.body.data.id;
      expect(createResponse.body.data.name).toBe(newUser.name);

      // 2. Read user
      const readResponse = await request(app)
        .get(`/api/users/${userId}`)
        .expect(200);
      
      expect(readResponse.body.data.name).toBe(newUser.name);
      expect(readResponse.body.data.email).toBe(newUser.email);

      // 3. Update user
      const updateData = {
        name: 'Updated Test User',
        age: 26
      };

      const updateResponse = await request(app)
        .put(`/api/users/${userId}`)
        .send(updateData)
        .expect(200);
      
      expect(updateResponse.body.data.name).toBe(updateData.name);
      expect(updateResponse.body.data.age).toBe(updateData.age);

      // 4. Delete user
      const deleteResponse = await request(app)
        .delete(`/api/users/${userId}`)
        .expect(200);
      
      expect(deleteResponse.body.data.id).toBe(userId);

      // 5. Verify deletion
      await request(app)
        .get(`/api/users/${userId}`)
        .expect(404);
    });

    test('Bulk operations: Create multiple users and verify count', async () => {
      const initialUsersResponse = await request(app)
        .get('/api/users')
        .expect(200);
      
      const initialCount = initialUsersResponse.body.count;

      // Create multiple users
      const usersToCreate = [
        { name: 'Bulk User 1', email: 'bulk1@example.com' },
        { name: 'Bulk User 2', email: 'bulk2@example.com' },
        { name: 'Bulk User 3', email: 'bulk3@example.com' }
      ];

      for (const user of usersToCreate) {
        await request(app)
          .post('/api/users')
          .send(user)
          .expect(201);
      }

      // Verify count increased
      const finalUsersResponse = await request(app)
        .get('/api/users')
        .expect(200);
      
      expect(finalUsersResponse.body.count).toBe(initialCount + usersToCreate.length);
    });

  });
  
});
