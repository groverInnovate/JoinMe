const express = require('express');
const router = express.Router();
const activityController = require('../controllers/activityController');
const auth = require('../middleware/auth');

// Public routes
router.get('/', activityController.getActivities);
router.get('/:id', activityController.getActivity);

// Protected routes
router.get('/my-activities', auth, activityController.getMyAllActivities);
router.post('/', auth, activityController.createActivity);
router.post('/:id/join', auth, activityController.joinActivity);
router.post('/:id/leave', auth, activityController.leaveActivity);
router.get('/user/my', auth, activityController.getMyActivities);
router.get('/user/joined', auth, activityController.getJoinedActivities);

module.exports = router;
