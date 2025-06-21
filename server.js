const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// In-memory data store for demo
let users = [
  { id: 1, name: 'John Doe', email: 'john@example.com', age: 30 },
  { id: 2, name: 'Jane Smith', email: 'jane@example.com', age: 25 }
];

let nextId = 3;

// Routes

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Get all users
app.get('/api/users', (req, res) => {
  res.status(200).json({
    success: true,
    data: users,
    count: users.length
  });
});

// Get user by ID
app.get('/api/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const user = users.find(u => u.id === id);
  
  if (!user) {
    return res.status(404).json({
      success: false,
      error: 'User not found'
    });
  }
  
  res.status(200).json({
    success: true,
    data: user
  });
});

// Create new user
app.post('/api/users', (req, res) => {
  const { name, email, age } = req.body;
  
  // Validation
  if (!name || !email) {
    return res.status(400).json({
      success: false,
      error: 'Name and email are required'
    });
  }
  
  // Check if email already exists
  if (users.find(u => u.email === email)) {
    return res.status(409).json({
      success: false,
      error: 'Email already exists'
    });
  }
  
  const newUser = {
    id: nextId++,
    name,
    email,
    age: age || null
  };
  
  users.push(newUser);
  
  res.status(201).json({
    success: true,
    data: newUser,
    message: 'User created successfully'
  });
});

// Update user
app.put('/api/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const userIndex = users.findIndex(u => u.id === id);
  
  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'User not found'
    });
  }
  
  const { name, email, age } = req.body;
  
  // Check if new email conflicts with existing users (excluding current user)
  if (email && users.find(u => u.email === email && u.id !== id)) {
    return res.status(409).json({
      success: false,
      error: 'Email already exists'
    });
  }
  
  // Update user
  users[userIndex] = {
    ...users[userIndex],
    ...(name && { name }),
    ...(email && { email }),
    ...(age !== undefined && { age })
  };
  
  res.status(200).json({
    success: true,
    data: users[userIndex],
    message: 'User updated successfully'
  });
});

// Delete user
app.delete('/api/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const userIndex = users.findIndex(u => u.id === id);
  
  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'User not found'
    });
  }
  
  const deletedUser = users.splice(userIndex, 1)[0];
  
  res.status(200).json({
    success: true,
    data: deletedUser,
    message: 'User deleted successfully'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// Start server
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`API base URL: http://localhost:${PORT}/api`);
  });
}

module.exports = app;
