const express = require('express');
const router = express.Router();
const { createCoupon, validateCoupon, getCoupons } = require('../controllers/couponController');
const { protect, authorize } = require('../middleware/auth');

router.route('/')
  .get(protect, getCoupons)
  .post(protect, authorize('Seller', 'Admin'), createCoupon);

router.post('/validate', protect, validateCoupon);

module.exports = router;
