const express = require('express');
const multer = require('multer');
const aadhaarController = require('../controllers/aadhaarController');

const router = express.Router();

// Configure multer for memory storage (for processing QR images)
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit
    },
    fileFilter: (req, file, cb) => {
        // Accept images - check mimetype and extension
        const allowedMimes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'image/heif'];
        const allowedExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif'];

        const ext = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));

        // Accept if mimetype is image/* OR extension is valid
        if (file.mimetype.startsWith('image/') || allowedMimes.includes(file.mimetype) || allowedExts.includes(ext)) {
            cb(null, true);
        } else {
            console.log('Rejected file:', file.originalname, 'mimetype:', file.mimetype);
            cb(new Error(`Only image files are allowed. Received: ${file.mimetype}`), false);
        }
    },
});

/**
 * @route   POST /api/v1/aadhaar/verify-qr
 * @desc    Verify Aadhaar QR code without linking to account
 * @access  Public (or Protected based on your needs)
 */
router.post('/verify-qr', upload.single('qrImage'), aadhaarController.verifyQR);

/**
 * @route   POST /api/v1/aadhaar/link
 * @desc    Verify and link Aadhaar to user account
 * @access  Protected (should add auth middleware in production)
 */
router.post('/link', upload.single('qrImage'), aadhaarController.linkAadhaar);

/**
 * @route   GET /api/v1/aadhaar/status/:userId
 * @desc    Check Aadhaar verification status
 * @access  Protected
 */
router.get('/status/:userId', aadhaarController.getVerificationStatus);

module.exports = router;
