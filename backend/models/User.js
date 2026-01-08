const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            trim: true,
            default: 'User', // Default name if not provided
            maxlength: [100, 'Name cannot exceed 100 characters'],
        },
        email: {
            type: String,
            required: [true, 'Email is required'],
            unique: true,
            lowercase: true,
            trim: true,
            match: [
                /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
                'Please enter a valid email address',
            ],
        },
        phone: {
            type: String,
            trim: true,
            match: [/^[6-9]\d{9}$/, 'Please enter a valid 10-digit Indian phone number'],
        },
        aadhaarNumber: {
            type: String,
            select: false, // Don't include in queries by default
        },
        profilePicture: {
            type: String,
            default: null,
        },
        password: {
            type: String,
            required: [true, 'Password is required'],
            minlength: [6, 'Password must be at least 6 characters'],
            select: false, // Don't include in queries by default
        },
        isVerified: {
            type: Boolean,
            default: false,
        },
        isActive: {
            type: Boolean,
            default: true,
        },
        lastLogin: {
            type: Date,
            default: null,
        },
    },
    {
        timestamps: true, // Adds createdAt and updatedAt automatically
    }
);

// ============ Indexes ============

// Note: email already has an index from unique: true

// Index on aadhaarNumber for fast lookups and uniqueness enforcement
userSchema.index({ aadhaarNumber: 1 }, { unique: true, sparse: true });

// Compound index for common queries
userSchema.index({ isActive: 1, createdAt: -1 });

// ============ Pre-save Middleware ============

// Hash password before saving
// Hash password before saving
userSchema.pre('save', async function () {
    // Only hash password if it's modified
    if (this.isModified('password')) {
        const salt = await bcrypt.genSalt(12);
        this.password = await bcrypt.hash(this.password, salt);
    }
});

// ============ Instance Methods ============

/**
 * Compare password with hashed password
 * @param {string} candidatePassword - Password to compare
 * @returns {Promise<boolean>} - True if passwords match
 */
userSchema.methods.comparePassword = async function (candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
};

/**
 * Compare Aadhaar number with hashed Aadhaar
 * @param {string} candidateAadhaar - Aadhaar number to compare
 * @returns {Promise<boolean>} - True if Aadhaar numbers match
 */
userSchema.methods.compareAadhaar = async function (candidateAadhaar) {
    if (!this.aadhaarNumber) return false;
    return bcrypt.compare(candidateAadhaar, this.aadhaarNumber);
};

/**
 * Get public profile (excludes sensitive data)
 * @returns {Object} - Public user data
 */
userSchema.methods.toPublicProfile = function () {
    return {
        id: this._id,
        name: this.name,
        email: this.email,
        phone: this.phone,
        profilePicture: this.profilePicture,
        isVerified: this.isVerified,
        createdAt: this.createdAt,
    };
};

// ============ Static Methods ============

/**
 * Find user by email
 * @param {string} email - User email
 * @returns {Promise<User>} - User document
 */
userSchema.statics.findByEmail = function (email) {
    return this.findOne({ email: email.toLowerCase() });
};

/**
 * Find active users
 * @returns {Promise<User[]>} - Array of active users
 */
userSchema.statics.findActiveUsers = function () {
    return this.find({ isActive: true }).sort({ createdAt: -1 });
};

// ============ Virtual Fields ============

// Virtual for full profile URL
userSchema.virtual('profileUrl').get(function () {
    if (this.profilePicture) {
        return this.profilePicture.startsWith('http')
            ? this.profilePicture
            : `/uploads/profiles/${this.profilePicture}`;
    }
    return null;
});

// Ensure virtuals are included in JSON output
userSchema.set('toJSON', { virtuals: true });
userSchema.set('toObject', { virtuals: true });

const User = mongoose.model('User', userSchema);

module.exports = User;
