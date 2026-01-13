const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * Socket.IO Event Handlers
 */

// Store connected users: Map<userId, Set<socketId>>
const connectedUsers = new Map();

/**
 * Initialize Socket.IO handlers
 * @param {Server} io - Socket.IO server instance
 */
const initializeSocketHandlers = (io) => {
    // Authentication middleware for socket connections
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');

            if (!token) {
                return next(new Error('Authentication required'));
            }

            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            const user = await User.findById(decoded.id).select('-password');

            if (!user) {
                return next(new Error('User not found'));
            }

            socket.userId = user._id.toString();
            socket.user = user;
            next();
        } catch (error) {
            console.error('Socket auth error:', error.message);
            next(new Error('Invalid token'));
        }
    });

    // Handle new connections
    io.on('connection', (socket) => {
        console.log(`User connected: ${socket.userId} (socket: ${socket.id})`);

        // Add user to connected users map
        if (!connectedUsers.has(socket.userId)) {
            connectedUsers.set(socket.userId, new Set());
        }
        connectedUsers.get(socket.userId).add(socket.id);

        // Join user's personal room for direct messages
        socket.join(`user:${socket.userId}`);

        // Emit online status to friends/other users
        socket.broadcast.emit('user:online', {
            userId: socket.userId,
            name: socket.user.name,
        });

        // Handle joining an activity room
        socket.on('activity:join', (activityId) => {
            socket.join(`activity:${activityId}`);
            console.log(`User ${socket.userId} joined activity room: ${activityId}`);

            // Notify others in the activity
            socket.to(`activity:${activityId}`).emit('activity:user_joined', {
                userId: socket.userId,
                name: socket.user.name,
                activityId,
            });
        });

        // Handle leaving an activity room
        socket.on('activity:leave', (activityId) => {
            socket.leave(`activity:${activityId}`);
            console.log(`User ${socket.userId} left activity room: ${activityId}`);

            // Notify others in the activity
            socket.to(`activity:${activityId}`).emit('activity:user_left', {
                userId: socket.userId,
                name: socket.user.name,
                activityId,
            });
        });

        // Handle activity messages/chat
        socket.on('activity:message', ({ activityId, message }) => {
            io.to(`activity:${activityId}`).emit('activity:new_message', {
                userId: socket.userId,
                name: socket.user.name,
                message,
                activityId,
                timestamp: new Date().toISOString(),
            });
        });

        // Handle typing indicator
        socket.on('activity:typing', ({ activityId, isTyping }) => {
            socket.to(`activity:${activityId}`).emit('activity:user_typing', {
                userId: socket.userId,
                name: socket.user.name,
                isTyping,
                activityId,
            });
        });

        // Handle disconnection
        socket.on('disconnect', () => {
            console.log(`User disconnected: ${socket.userId} (socket: ${socket.id})`);

            // Remove socket from connected users
            const userSockets = connectedUsers.get(socket.userId);
            if (userSockets) {
                userSockets.delete(socket.id);
                if (userSockets.size === 0) {
                    connectedUsers.delete(socket.userId);

                    // Emit offline status only if no more connections
                    socket.broadcast.emit('user:offline', {
                        userId: socket.userId,
                    });
                }
            }
        });

        // Handle errors
        socket.on('error', (error) => {
            console.error(`Socket error for user ${socket.userId}:`, error);
        });
    });

    console.log('Socket.IO handlers initialized');
};

/**
 * Emit event to specific user (all their connected sockets)
 * @param {Server} io - Socket.IO server instance
 * @param {string} userId - Target user ID
 * @param {string} event - Event name
 * @param {object} data - Event data
 */
const emitToUser = (io, userId, event, data) => {
    io.to(`user:${userId}`).emit(event, data);
};

/**
 * Emit event to activity room
 * @param {Server} io - Socket.IO server instance
 * @param {string} activityId - Activity ID
 * @param {string} event - Event name
 * @param {object} data - Event data
 */
const emitToActivity = (io, activityId, event, data) => {
    io.to(`activity:${activityId}`).emit(event, data);
};

/**
 * Check if user is online
 * @param {string} userId - User ID to check
 * @returns {boolean}
 */
const isUserOnline = (userId) => {
    return connectedUsers.has(userId) && connectedUsers.get(userId).size > 0;
};

/**
 * Get online user count
 * @returns {number}
 */
const getOnlineUserCount = () => {
    return connectedUsers.size;
};

module.exports = {
    initializeSocketHandlers,
    emitToUser,
    emitToActivity,
    isUserOnline,
    getOnlineUserCount,
};
