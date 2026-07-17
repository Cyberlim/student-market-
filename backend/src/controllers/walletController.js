const User = require('../models/User');
const Withdrawal = require('../models/Withdrawal');

// @desc    Claim Daily check-in coins
// @route   POST /api/wallet/daily-reward
// @access  Private
exports.claimDailyReward = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Add 10 daily check-in coins
    user.coins += 10;
    
    // Add Daily Check-in Badge if not already present
    if (!user.badges.includes('DailyEarner')) {
      user.badges.push('DailyEarner');
    }
    await user.save();

    res.status(200).json({
      success: true,
      message: '10 Coins claimed successfully!',
      coins: user.coins,
      badges: user.badges
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Submit bank withdrawal request
// @route   POST /api/wallet/withdraw
// @access  Private
exports.requestWithdrawal = async (req, res) => {
  try {
    const { amount, accountNumber, ifscCode, accountHolderName, bankName } = req.body;
    const user = await User.findById(req.user.id);

    if (user.coins < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient coins in wallet' });
    }

    // Deduct coins first (1 coin = 1 Rupee conversion rate)
    user.coins -= amount;
    await user.save();

    const request = await Withdrawal.create({
      seller: req.user.id,
      amount: parseFloat(amount),
      bankDetails: {
        accountNumber,
        ifscCode,
        accountHolderName,
        bankName,
      }
    });

    res.status(201).json({ success: true, message: 'Withdrawal request submitted successfully', data: request, currentCoins: user.coins });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get withdrawal requests history
// @route   GET /api/wallet/withdrawals
// @access  Private
exports.getWithdrawalHistory = async (req, res) => {
  try {
    let query = {};
    // If not Admin, only show current user's history
    if (req.user.role !== 'Admin') {
      query.seller = req.user.id;
    }

    const history = await Withdrawal.find(query).populate('seller', 'name email').sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: history });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Approve/Reject withdrawal requests
// @route   PUT /api/wallet/withdrawals/:id
// @access  Private (Admin)
exports.updateWithdrawalStatus = async (req, res) => {
  try {
    const { status } = req.body; // Approved or Rejected
    const request = await Withdrawal.findById(req.params.id);

    if (!request) {
      return res.status(404).json({ success: false, message: 'Withdrawal request not found' });
    }

    if (request.status !== 'Pending') {
      return res.status(400).json({ success: false, message: 'Request has already been processed' });
    }

    request.status = status;
    await request.save();

    // If rejected, refund the coins back to the user's account
    if (status === 'Rejected') {
      const user = await User.findById(request.seller);
      if (user) {
        user.coins += request.amount;
        await user.save();
      }
    }

    res.status(200).json({ success: true, message: `Request status updated to ${status}`, data: request });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Submit referral coupon reward
// @route   POST /api/wallet/referral
// @access  Private
exports.claimReferral = async (req, res) => {
  try {
    const { code } = req.body;
    // Find the referring user
    const referrer = await User.findOne({ referralCode: code });
    if (!referrer) {
      return res.status(404).json({ success: false, message: 'Invalid referral code' });
    }

    if (referrer._id.equals(req.user.id)) {
      return res.status(400).json({ success: false, message: 'Cannot refer yourself' });
    }

    const user = await User.findById(req.user.id);
    if (user.referredBy) {
      return res.status(400).json({ success: false, message: 'Referral reward already claimed' });
    }

    // Award coins to both parties (50 coins each)
    referrer.coins += 50;
    if (!referrer.badges.includes('Influencer')) {
      referrer.badges.push('Influencer');
    }
    await referrer.save();

    user.coins += 50;
    user.referredBy = referrer._id;
    await user.save();

    res.status(200).json({ success: true, message: 'Referral reward credited successfully!', currentCoins: user.coins });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
