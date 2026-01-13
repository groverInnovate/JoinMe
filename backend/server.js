const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const http = require('http');
const { Server } = require('socket.io');

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();

// Create HTTP server for Socket.IO
const server = http.createServer(app);

// Initialize Socket.IO with CORS
const io = new Server(server, {
    cors: {
        origin: '*', // In production, restrict to your app's domain
        methods: ['GET', 'POST'],
    },
});

// Import socket handlers
const { initializeSocketHandlers } = require('./socket/socketHandlers');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Make io accessible to routes (for emitting events from controllers)
app.set('io', io);

// Port configuration
const PORT = process.env.PORT || 5000;

// MongoDB connection
const connectDB = async () => {
    try {
        if (process.env.MONGODB_URI) {
            await mongoose.connect(process.env.MONGODB_URI);
            console.log('✅ MongoDB connected successfully');
        } else {
            console.log('⚠️  MongoDB URI not configured. Running without database.');
        }
    } catch (error) {
        console.error('❌ MongoDB connection error:', error.message);
        process.exit(1);
    }
};

// Health check route
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Welcome to JoinMe API!',
        status: 'Server is running',
        timestamp: new Date().toISOString()
    });
});

// API health check
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'API is healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

// ============ API Routes ============

// Auth routes
const authRoutes = require('./routes/authRoutes');
app.use('/api/v1/auth', authRoutes);

// Aadhaar verification routes
const aadhaarRoutes = require('./routes/aadhaarRoutes');
app.use('/api/v1/aadhaar', aadhaarRoutes);

// Activity routes
const activityRoutes = require('./routes/activityRoutes');
app.use('/api/v1/activities', activityRoutes);

// ============ Error Handlers ============

// 404 handler for undefined routes
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found'
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Error:', err.message);

    // Handle multer errors
    if (err.name === 'MulterError') {
        return res.status(400).json({
            success: false,
            message: `File upload error: ${err.message}`,
        });
    }

    // Handle file filter errors
    if (err.message && err.message.includes('Only image files')) {
        return res.status(400).json({
            success: false,
            message: err.message,
        });
    }

    res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// Start server
const startServer = async () => {
    await connectDB();

    // Initialize Socket.IO handlers
    initializeSocketHandlers(io);

    server.listen(PORT, () => {
        console.log(`
🚀 ================================
   JoinMe Server Started!
   Port: ${PORT}
   Environment: ${process.env.NODE_ENV || 'development'}
   URL: http://localhost:${PORT}
   WebSocket: ws://localhost:${PORT}
================================ 🚀
    `);
    });
};

startServer();
