const jwt = require('jsonwebtoken');

/**
 * Authentication Middleware
 * Verifies the JWT token and adds the user to the request object
 */
const auth = async (req, res, next) => {
    try {
        // Get token from header
        const token = req.header('Authorization')?.replace('Bearer ', '');

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'No authentication token, access denied',
            });
        }

        // Verify token
        // Fallback to a default secret for development if env var is missing
        const jwtSecret = process.env.JWT_SECRET || 'joinme_jwt_secret_dev_key_2024';

        try {
            const decoded = jwt.verify(token, jwtSecret);

            // Add user info to request
            // We store the userId as 'id' in the payload
            req.user = decoded;
            req.userId = decoded.id;

            next();
        } catch (err) {
            return res.status(401).json({
                success: false,
                message: 'Token is invalid or expired',
            });
        }
    } catch (error) {
        console.error('Auth middleware error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during authentication',
        });
    }
};

module.exports = auth;
