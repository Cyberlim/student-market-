const express = require('express');
const router = express.Router();
const { getConfig, updateConfig } = require('../controllers/configController');
const { protect, authorize } = require('../middleware/auth');

router.route('/')
  .get(protect, getConfig)
  .put(protect, authorize('Admin'), updateConfig);

module.exports = router;
