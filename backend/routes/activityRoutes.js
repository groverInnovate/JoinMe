const express = require('express');
const router = express.Router();
const activityController = require('../controllers/activityController');
const auth = require('../middleware/auth');

// Public routes
router.get('/', activityController.getActivities);
router.get('/nearby', activityController.getNearbyActivities); // Must be before /:id

// Protected routes (specific paths before param routes)
router.get('/my-activities', auth, activityController.getMyAllActivities);
router.get('/user/my', auth, activityController.getMyActivities);
router.get('/user/joined', auth, activityController.getJoinedActivities);

router.post('/', auth, activityController.createActivity);
router.post('/:id/join', auth, activityController.joinActivity);
router.post('/:id/leave', auth, activityController.leaveActivity);

// Param routes (must be last)
router.get('/:id', activityController.getActivity);

module.exports = router;

