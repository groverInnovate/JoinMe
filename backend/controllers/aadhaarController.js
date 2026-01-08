const jwt = require('jsonwebtoken');
const aadhaarService = require('../utils/aadhaarService');
const User = require('../models/User');

/**
 * Aadhaar Verification Controller
 */
const aadhaarController = {
    /**
     * Verify Aadhaar QR code
     * POST /api/v1/aadhaar/verify-qr
     */
    verifyQR: async (req, res) => {
        try {
            // Check if file was uploaded
            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    message: 'No QR code image uploaded',
                });
            }

            // Verify the QR code
            const result = await aadhaarService.verifyAadhaarQR(req.file.buffer);

            if (!result.success) {
                return res.status(400).json({
                    success: false,
                    message: result.error || 'Failed to verify Aadhaar QR code',
                });
            }

            // Generate a deduplication hash
            const dedupHash = aadhaarService.generateDeduplicationHash({
                ...result.data,
                uid: result.data.uidLastFour
            });

            // Create a verification token for the frontend to pass to /register
            const verificationPayload = {
                type: 'aadhaar_verification',
                aadhaarData: {
                    name: result.data.name,
                    dob: result.data.dateOfBirth,
                    gender: result.data.gender,
                    uidLast4: result.data.uidLastFour,
                    pincode: result.data.address ? result.data.address.postcode : null,
                    state: result.data.address ? result.data.address.state : null,
                    deduplicationHash: dedupHash
                }
            };

            const verificationToken = jwt.sign(
                verificationPayload,
                process.env.JWT_SECRET || 'joinme_jwt_secret_dev_key_2024',
                { expiresIn: '30m' } // 30 minutes to complete registration
            );

            res.status(200).json({
                success: true,
                message: 'Aadhaar QR code verified successfully',
                data: result,
                verificationToken, // Pass this to subsequent steps
            });
        } catch (error) {
            console.error('Aadhaar verification error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to verify Aadhaar QR code',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined,
            });
        }
    },

    /**
     * Link Aadhaar to user account
     * POST /api/v1/aadhaar/link
     */
    linkAadhaar: async (req, res) => {
        try {
            const { userId } = req.body;

            // Check if file was uploaded
            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    message: 'No QR code image uploaded',
                });
            }

            // Verify the QR code
            const result = await aadhaarService.verifyAadhaarQR(req.file.buffer);

            if (!result.success) {
                return res.status(400).json({
                    success: false,
                    message: result.error || 'Failed to verify Aadhaar QR code',
                });
            }

            // Find the user
            const user = await User.findById(userId);
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'User not found',
                });
            }

            // Check if user already has Aadhaar linked
            if (user.isVerified) {
                return res.status(400).json({
                    success: false,
                    message: 'Aadhaar already linked to this account',
                });
            }

            // Create a hash of the reference (since we only have last 4 digits)
            const aadhaarHash = aadhaarService.hashAadhaarNumber(
                result.referenceId // Using reference ID as unique identifier
            );

            // Update user with Aadhaar data
            user.aadhaarNumber = aadhaarHash;
            user.isVerified = true;
            user.name = result.data.name || user.name;

            // Set profile picture from Aadhaar photo if available
            if (result.data.photoBase64 && !user.profilePicture) {
                // You could save this to file storage and set URL
                // For now, we'll skip or store as base64
                user.profilePicture = `data:image/jpeg;base64,${result.data.photoBase64}`;
            }

            await user.save();

            res.status(200).json({
                success: true,
                message: 'Aadhaar linked successfully',
                data: {
                    referenceId: result.referenceId,
                    isVerified: true,
                    verifiedName: result.data.name,
                    verifiedAt: new Date().toISOString(),
                },
            });
        } catch (error) {
            console.error('Aadhaar linking error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to link Aadhaar',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined,
            });
        }
    },

    /**
     * Check Aadhaar verification status
     * GET /api/v1/aadhaar/status/:userId
     */
    getVerificationStatus: async (req, res) => {
        try {
            const { userId } = req.params;

            const user = await User.findById(userId);
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: 'User not found',
                });
            }

            res.status(200).json({
                success: true,
                data: {
                    isVerified: user.isVerified,
                    hasAadhaar: !!user.aadhaarNumber,
                },
            });
        } catch (error) {
            console.error('Status check error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to check verification status',
            });
        }
    },
};

module.exports = aadhaarController;
