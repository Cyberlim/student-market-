const express = require('express');
const router = express.Router();
const { claimDailyReward, requestWithdrawal, getWithdrawalHistory, updateWithdrawalStatus, claimReferral } = require('../controllers/walletController');
const { protect, authorize } = require('../middleware/auth');

router.post('/daily-reward', protect, claimDailyReward);
router.post('/withdraw', protect, requestWithdrawal);
router.post('/referral', protect, claimReferral);

router.route('/withdrawals')
  .get(protect, getWithdrawalHistory);

router.put('/withdrawals/:id', protect, authorize('Admin'), updateWithdrawalStatus);

module.exports = router;
