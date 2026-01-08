const User = require('../models/User');
const generateToken = require('../utils/generateToken');
const jwt = require('jsonwebtoken');

/**
 * Auth Controller
 */
const authController = {
    /**
     * @desc    Register a new user
     * @route   POST /api/v1/auth/register
     * @access  Public
     */
    registerUser: async (req, res) => {
        try {
            const { name, email, password, phone, verificationToken } = req.body;

            // Check if user already exists
            const userExists = await User.findOne({ email });

            if (userExists) {
                return res.status(400).json({
                    success: false,
                    message: 'User already exists',
                });
            }

            let userData = {
                name,
                email,
                password,
                phone,
            };

            // If verification token is provided, process Aadhaar data
            if (verificationToken) {
                try {
                    const jwtSecret = process.env.JWT_SECRET || 'joinme_jwt_secret_dev_key_2024';
                    const decoded = jwt.verify(verificationToken, jwtSecret);

                    if (decoded.type === 'aadhaar_verification') {
                        const { aadhaarData } = decoded;

                        // Check if Aadhaar is already linked to another account
                        const aadhaarExists = await User.findOne({
                            'aadhaarData.deduplicationHash': aadhaarData.deduplicationHash
                        });

                        if (aadhaarExists) {
                            return res.status(400).json({
                                success: false,
                                message: 'This Aadhaar is already registered with another account',
                            });
                        }

                        // Use verified name and add Aadhaar data
                        userData.name = aadhaarData.name; // Override name with verified name
                        userData.isVerified = true;
                        userData.aadhaarData = aadhaarData;
                    }
                } catch (err) {
                    return res.status(400).json({
                        success: false,
                        message: 'Invalid or expired verification token',
                    });
                }
            }

            // Create user
            const user = await User.create(userData);

            if (user) {
                res.status(201).json({
                    success: true,
                    data: {
                        _id: user._id,
                        name: user.name,
                        email: user.email,
                        isVerified: user.isVerified,
                        token: generateToken(user._id),
                    },
                });
            } else {
                res.status(400).json({
                    success: false,
                    message: 'Invalid user data',
                });
            }
        } catch (error) {
            console.error('Register error:', error);
            res.status(500).json({
                success: false,
                message: 'Server error during registration',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined,
            });
        }
    },

    /**
     * @desc    Auth user & get token
     * @route   POST /api/v1/auth/login
     * @access  Public
     */
    loginUser: async (req, res) => {
        try {
            const { email, password } = req.body;

            // Check for user email
            const user = await User.findOne({ email }).select('+password');

            if (user && (await user.comparePassword(password))) {
                res.json({
                    success: true,
                    data: {
                        _id: user._id,
                        name: user.name,
                        email: user.email,
                        isVerified: user.isVerified,
                        profilePicture: user.profilePicture,
                        token: generateToken(user._id),
                    },
                });
            } else {
                res.status(401).json({
                    success: false,
                    message: 'Invalid email or password',
                });
            }
        } catch (error) {
            console.error('Login error:', error);
            res.status(500).json({
                success: false,
                message: 'Server error during login',
            });
        }
    },

    /**
     * @desc    Get current user profile
     * @route   GET /api/v1/auth/me
     * @access  Private
     */
    getMe: async (req, res) => {
        try {
            const user = await User.findById(req.userId);

            if (user) {
                res.json({
                    success: true,
                    data: user.toPublicProfile(),
                });
            } else {
                res.status(404).json({
                    success: false,
                    message: 'User not found',
                });
            }
        } catch (error) {
            console.error('Get user error:', error);
            res.status(500).json({
                success: false,
                message: 'Server error',
            });
        }
    },
};

module.exports = authController;
