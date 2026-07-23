const User = require('../models/User');
const Note = require('../models/Note');
const Dispute = require('../models/Dispute');
const Report = require('../models/Report');

// @desc    Get Admin Stats
// @route   GET /api/admin/stats
// @access  Private (Admin)
exports.getStats = async (req, res) => {
  try {
    const mongoose = require('mongoose');
    const totalUsers = await User.countDocuments();
    const pendingAudits = await Note.countDocuments({ status: 'Pending' });
    
    // Calculate total platform revenue (e.g. 10% commission on orders)
    const Order = require('../models/Order');
    let totalRevenue = 0;
    const orders = await Order.find({ status: { $in: ['Completed', 'Dispatched', 'Out for Delivery', 'Delivered'] } });
    totalRevenue = orders.reduce((sum, order) => sum + ((order.price || 0) * 0.1), 0);

    const reportedIssues = await Dispute.countDocuments();

    // System Health
    const dbStatus = mongoose.connection.readyState === 1 ? 'Online' : 'Degraded';
    const cdnStatus = process.env.CLOUDINARY_CLOUD_NAME ? 'Online' : 'Configured';
    const razorpayStatus = process.env.RAZORPAY_KEY_ID ? 'Online' : 'Test Mode';

    // Revenue Trends (last 7 days)
    const today = new Date();
    const trends = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      d.setHours(0,0,0,0);
      const nextDay = new Date(d);
      nextDay.setDate(d.getDate() + 1);

      const dailyOrders = orders.filter(o => new Date(o.createdAt) >= d && new Date(o.createdAt) < nextDay);
      const dailyRev = dailyOrders.reduce((sum, order) => sum + ((order.price || 0) * 0.1), 0);
      trends.push(dailyRev);
    }

    res.status(200).json({
      success: true,
      stats: {
        totalRevenue: totalRevenue,
        totalUsers,
        pendingAudits,
        reportedIssues
      },
      health: {
        database: dbStatus,
        cdn: cdnStatus,
        gateway: razorpayStatus
      },
      trends: trends
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get Pending Notes for Audit
// @route   GET /api/admin/notes/pending
// @access  Private (Admin)
exports.getPendingNotes = async (req, res) => {
  try {
    const notes = await Note.find({ status: 'Pending' }).populate('seller', 'name email');
    res.status(200).json({ success: true, data: notes });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get All Users
// @route   GET /api/admin/users
// @access  Private (Admin)
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find({}, '-password');
    
    const usersWithNoteCount = await Promise.all(users.map(async (user) => {
      const noteCount = await Note.countDocuments({ seller: user._id });
      return {
        ...user._doc,
        id: user._id,
        notesCount: noteCount
      };
    }));

    res.status(200).json({ success: true, data: usersWithNoteCount });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Toggle User Ban Status
// @route   PUT /api/admin/users/:id/ban
// @access  Private (Admin)
exports.toggleUserBan = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.isBanned = !user.isBanned;
    await user.save();

    res.status(200).json({ success: true, message: `User status updated successfully`, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Adjust User Coin Balance
// @route   PUT /api/admin/users/:id/coins
// @access  Private (Admin)
exports.adjustUserCoins = async (req, res) => {
  try {
    const { coins } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.coins = coins;
    await user.save();

    res.status(200).json({ success: true, message: 'Coins adjusted successfully', data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Upload Media to Cloudinary
// @route   POST /api/admin/upload
// @access  Private (Admin)
exports.uploadMedia = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Please upload a file' });
    }

    const { uploadToCloudinary } = require('../config/cloudinary');
    const fileUrl = await uploadToCloudinary(req.file.buffer, 'image');

    if (!fileUrl) {
      // Fallback sample url if Cloudinary credentials are not set
      const fallbackUrl = 'https://res.cloudinary.com/demo/image/upload/v1/sample_product.jpg';
      return res.status(200).json({ success: true, url: fallbackUrl });
    }

    res.status(200).json({ success: true, url: fileUrl });
  } catch (err) {
    console.error('Admin upload error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get all reports
// @route   GET /api/admin/reports
// @access  Private (Admin)
exports.getReports = async (req, res) => {
  try {
    const reports = await Report.find()
      .populate('reporter', 'name email avatar')
      .populate('note', 'title thumbnailUrl itemType price status')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: reports.length, data: reports });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Update report status
// @route   PUT /api/admin/reports/:id/status
// @access  Private (Admin)
exports.updateReportStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['Pending', 'Dismissed', 'Action Taken'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const report = await Report.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );

    if (!report) {
      return res.status(404).json({ success: false, message: 'Report not found' });
    }

    res.status(200).json({ success: true, data: report });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
