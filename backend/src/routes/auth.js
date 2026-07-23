const express = require('express');
const router = express.Router();
const { register, login, getMe, googleLogin, verifyOtp, forgotPassword, getAddresses, addAddress, deleteAddress, updateProfile, updateFcmToken } = require('../controllers/authController');
const { protect } = require('../middleware/auth');

router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, getMe);
router.post('/google', googleLogin);
router.post('/otp/verify', verifyOtp);
router.post('/forgot-password', forgotPassword);
router.put('/profile', protect, updateProfile);
router.put('/fcm-token', protect, updateFcmToken);
const { followUser, unfollowUser } = require('../controllers/authController');
router.post('/follow/:id', protect, followUser);
router.post('/unfollow/:id', protect, unfollowUser);

// User Addresses
router.route('/addresses')
  .get(protect, getAddresses)
  .post(protect, addAddress);
router.route('/addresses/:id')
  .delete(protect, deleteAddress);

module.exports = router;

