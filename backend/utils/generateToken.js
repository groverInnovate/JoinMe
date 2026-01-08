const jwt = require('jsonwebtoken');

/**
 * Generate JWT Token
 * @param {string} id - User ID
 * @returns {string} - JWT Token
 */
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET || 'joinme_jwt_secret_dev_key_2024', {
        expiresIn: '30d',
    });
};

module.exports = generateToken;
