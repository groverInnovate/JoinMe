const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Activity title is required'],
            trim: true,
            maxlength: [100, 'Title cannot exceed 100 characters'],
        },
        description: {
            type: String,
            trim: true,
            maxlength: [1000, 'Description cannot exceed 1000 characters'],
        },
        category: {
            type: String,
            required: [true, 'Category is required'],
            enum: {
                values: [
                    'sports',
                    'study',
                    'food',
                    'travel',
                    'games',
                    'music',
                    'movies',
                    'fitness',
                    'hangout',
                    'other',
                ],
                message: '{VALUE} is not a valid category',
            },
        },
        creator: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Activity must have a creator'],
        },
        participants: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User',
            },
        ],
        maxParticipants: {
            type: Number,
            required: [true, 'Maximum participants is required'],
            min: [2, 'Activity must allow at least 2 participants'],
            max: [100, 'Activity cannot have more than 100 participants'],
        },
        // Location name (address/place name)
        location: {
            type: String,
            required: [true, 'Location is required'],
            trim: true,
        },
        // GeoJSON coordinates for geospatial queries
        coordinates: {
            type: {
                type: String,
                enum: ['Point'],
                default: 'Point',
            },
            coordinates: {
                type: [Number], // [longitude, latitude]
                default: undefined,
            },
        },
        date: {
            type: Date,
            required: [true, 'Activity date is required'],
        },
        time: {
            type: String,
            required: [true, 'Activity time is required'],
            trim: true,
        },
        status: {
            type: String,
            enum: {
                values: ['open', 'closed', 'completed', 'cancelled'],
                message: '{VALUE} is not a valid status',
            },
            default: 'open',
        },
    },
    {
        timestamps: true, // Adds createdAt and updatedAt
    }
);

// Indexes for efficient querying
activitySchema.index({ creator: 1 });
activitySchema.index({ date: 1 });
activitySchema.index({ status: 1, date: 1 }); // Compound index for filtering open activities by date
activitySchema.index({ category: 1 }); // For category-based filtering
activitySchema.index({ coordinates: '2dsphere' }); // For geospatial queries

// Virtual to check if activity is full
activitySchema.virtual('isFull').get(function () {
    return this.participants.length >= this.maxParticipants;
});

// Virtual for available spots
activitySchema.virtual('availableSpots').get(function () {
    return this.maxParticipants - this.participants.length;
});

// Ensure virtuals are included in JSON output
activitySchema.set('toJSON', { virtuals: true });
activitySchema.set('toObject', { virtuals: true });

// Pre-save middleware to auto-close activity if full
activitySchema.pre('save', function () {
    if (this.participants.length >= this.maxParticipants && this.status === 'open') {
        this.status = 'closed';
    }
});

const Activity = mongoose.model('Activity', activitySchema);

module.exports = Activity;
