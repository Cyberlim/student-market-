const express = require('express');
const router = express.Router();
const { getBanners, getAllBanners, createBanner, updateBanner, deleteBanner } = require('../controllers/bannerController');
const { protect, authorize } = require('../middleware/auth');

router.route('/')
  .get(getBanners)
  .post(protect, authorize('Admin'), createBanner);

router.route('/admin')
  .get(protect, authorize('Admin'), getAllBanners);

router.route('/:id')
  .put(protect, authorize('Admin'), updateBanner)
  .delete(protect, authorize('Admin'), deleteBanner);

module.exports = router;
