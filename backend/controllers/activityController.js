const Activity = require('../models/Activity');

/**
 * Activity Controller
 */
const activityController = {
    /**
     * Create a new activity
     * POST /api/v1/activities
     * @access Protected
     */
    createActivity: async (req, res) => {
        try {
            const {
                title,
                description,
                category,
                maxParticipants,
                location,
                date,
                time,
            } = req.body;

            // Validate required fields
            if (!title || !category || !maxParticipants || !location || !date || !time) {
                return res.status(400).json({
                    success: false,
                    message: 'Please provide all required fields: title, category, maxParticipants, location, date, time',
                });
            }

            // Create activity with creator set to logged-in user
            const activity = await Activity.create({
                title,
                description,
                category,
                creator: req.userId, // From auth middleware
                participants: [req.userId], // Creator is first participant
                maxParticipants,
                location,
                date: new Date(date),
                time,
            });

            // Populate creator info for response
            await activity.populate('creator', 'name email profilePicture');

            // Emit socket event for new activity
            const io = req.app.get('io');
            if (io) {
                io.emit('activity:created', {
                    activity,
                    createdBy: {
                        id: req.userId,
                        name: activity.creator.name,
                    },
                });
            }

            res.status(201).json({
                success: true,
                message: 'Activity created successfully',
                data: activity,
            });
        } catch (error) {
            console.error('Create activity error:', error);

            // Handle validation errors
            if (error.name === 'ValidationError') {
                const messages = Object.values(error.errors).map((err) => err.message);
                return res.status(400).json({
                    success: false,
                    message: messages.join(', '),
                });
            }

            res.status(500).json({
                success: false,
                message: 'Failed to create activity',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined,
            });
        }
    },

    /**
     * Get all activities (with filters)
     * GET /api/v1/activities
     * @access Public
     */
    getActivities: async (req, res) => {
        try {
            const { category, status, date, limit = 20, page = 1 } = req.query;

            // Build query
            const query = {};

            if (category) {
                query.category = category;
            }

            if (status) {
                query.status = status;
            } else {
                // Default to open activities
                query.status = 'open';
            }

            if (date) {
                // Filter activities on or after specified date
                query.date = { $gte: new Date(date) };
            } else {
                // Default to upcoming activities
                query.date = { $gte: new Date() };
            }

            // Pagination
            const skip = (parseInt(page) - 1) * parseInt(limit);

            const activities = await Activity.find(query)
                .populate('creator', 'name profilePicture')
                .populate('participants', 'name profilePicture')
                .sort({ date: 1 }) // Upcoming first
                .skip(skip)
                .limit(parseInt(limit));

            const total = await Activity.countDocuments(query);

            res.status(200).json({
                success: true,
                data: activities,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / parseInt(limit)),
                },
            });
        } catch (error) {
            console.error('Get activities error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to fetch activities',
            });
        }
    },

    /**
     * Get single activity by ID
     * GET /api/v1/activities/:id
     * @access Public
     */
    getActivity: async (req, res) => {
        try {
            const activity = await Activity.findById(req.params.id)
                .populate('creator', 'name email profilePicture')
                .populate('participants', 'name profilePicture');

            if (!activity) {
                return res.status(404).json({
                    success: false,
                    message: 'Activity not found',
                });
            }

            res.status(200).json({
                success: true,
                data: activity,
            });
        } catch (error) {
            console.error('Get activity error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to fetch activity',
            });
        }
    },

    /**
     * Join an activity
     * POST /api/v1/activities/:id/join
     * @access Protected
     */
    joinActivity: async (req, res) => {
        try {
            const activity = await Activity.findById(req.params.id);

            if (!activity) {
                return res.status(404).json({
                    success: false,
                    message: 'Activity not found',
                });
            }

            // Check if activity is open
            if (activity.status !== 'open') {
                return res.status(400).json({
                    success: false,
                    message: 'This activity is no longer accepting participants',
                });
            }

            // Check if already a participant
            if (activity.participants.includes(req.userId)) {
                return res.status(400).json({
                    success: false,
                    message: 'You have already joined this activity',
                });
            }

            // Check if activity is full
            if (activity.participants.length >= activity.maxParticipants) {
                return res.status(400).json({
                    success: false,
                    message: 'This activity is full',
                });
            }

            // Add user to participants
            activity.participants.push(req.userId);
            await activity.save();

            await activity.populate('participants', 'name profilePicture');
            await activity.populate('creator', 'name profilePicture');

            // Emit socket event for user joined
            const io = req.app.get('io');
            if (io) {
                io.to(`activity:${activity._id}`).emit('activity:participant_joined', {
                    activityId: activity._id,
                    userId: req.userId,
                    participantsCount: activity.participants.length,
                    activity,
                });
            }

            res.status(200).json({
                success: true,
                message: 'Successfully joined the activity',
                data: activity,
            });
        } catch (error) {
            console.error('Join activity error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to join activity',
            });
        }
    },

    /**
     * Leave an activity
     * POST /api/v1/activities/:id/leave
     * @access Protected
     */
    leaveActivity: async (req, res) => {
        try {
            const activity = await Activity.findById(req.params.id);

            if (!activity) {
                return res.status(404).json({
                    success: false,
                    message: 'Activity not found',
                });
            }

            // Check if user is the creator
            if (activity.creator.toString() === req.userId) {
                return res.status(400).json({
                    success: false,
                    message: 'Creator cannot leave the activity. Cancel it instead.',
                });
            }

            // Check if user is a participant
            if (!activity.participants.includes(req.userId)) {
                return res.status(400).json({
                    success: false,
                    message: 'You are not a participant of this activity',
                });
            }

            // Remove user from participants
            activity.participants = activity.participants.filter(
                (p) => p.toString() !== req.userId
            );

            // Reopen if was closed due to being full
            if (activity.status === 'closed' && activity.participants.length < activity.maxParticipants) {
                activity.status = 'open';
            }

            await activity.save();

            // Emit socket event for user left
            const io = req.app.get('io');
            if (io) {
                io.to(`activity:${activity._id}`).emit('activity:participant_left', {
                    activityId: activity._id,
                    userId: req.userId,
                    participantsCount: activity.participants.length,
                    status: activity.status,
                });
            }

            res.status(200).json({
                success: true,
                message: 'Successfully left the activity',
            });
        } catch (error) {
            console.error('Leave activity error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to leave activity',
            });
        }
    },

    /**
     * Get activities created by user
     * GET /api/v1/activities/my
     * @access Protected
     */
    getMyActivities: async (req, res) => {
        try {
            const activities = await Activity.find({ creator: req.userId })
                .populate('participants', 'name profilePicture')
                .sort({ date: -1 });

            res.status(200).json({
                success: true,
                data: activities,
            });
        } catch (error) {
            console.error('Get my activities error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to fetch your activities',
            });
        }
    },

    /**
     * Get activities user has joined
     * GET /api/v1/activities/joined
     * @access Protected
     */
    getJoinedActivities: async (req, res) => {
        try {
            const activities = await Activity.find({
                participants: req.userId,
                creator: { $ne: req.userId }, // Exclude own activities
            })
                .populate('creator', 'name profilePicture')
                .populate('participants', 'name profilePicture')
                .sort({ date: 1 });

            res.status(200).json({
                success: true,
                data: activities,
            });
        } catch (error) {
            console.error('Get joined activities error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to fetch joined activities',
            });
        }
    },

    /**
     * Get all user's activities (created + joined)
     * GET /api/v1/activities/my-activities
     * @access Protected
     */
    getMyAllActivities: async (req, res) => {
        try {
            // Get activities created by user
            const createdActivities = await Activity.find({ creator: req.userId })
                .populate('creator', 'name profilePicture')
                .populate('participants', 'name profilePicture')
                .sort({ date: -1 });

            // Get activities user has joined (excluding own)
            const joinedActivities = await Activity.find({
                participants: req.userId,
                creator: { $ne: req.userId },
            })
                .populate('creator', 'name profilePicture')
                .populate('participants', 'name profilePicture')
                .sort({ date: 1 });

            res.status(200).json({
                success: true,
                data: {
                    created: createdActivities,
                    joined: joinedActivities,
                },
            });
        } catch (error) {
            console.error('Get my all activities error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to fetch your activities',
            });
        }
    },
};

module.exports = activityController;
