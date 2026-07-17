const Coupon = require('../models/Coupon');

// @desc    Create a new coupon
// @route   POST /api/coupons
// @access  Private (Seller/Admin)
exports.createCoupon = async (req, res) => {
  try {
    const { code, discountPercent, maxDiscount, expiryDate } = req.body;

    const existing = await Coupon.findOne({ code: code.toUpperCase() });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Coupon code already exists' });
    }

    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      discountPercent: parseInt(discountPercent, 10),
      maxDiscount: parseFloat(maxDiscount),
      expiryDate: new Date(expiryDate),
    });

    res.status(201).json({ success: true, data: coupon });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Validate a coupon code
// @route   POST /api/coupons/validate
// @access  Private
exports.validateCoupon = async (req, res) => {
  try {
    const { code } = req.body;
    const coupon = await Coupon.findOne({ code: code.toUpperCase(), active: true });

    if (!coupon) {
      return res.status(404).json({ success: false, message: 'Coupon not found or inactive' });
    }

    if (new Date() > coupon.expiryDate) {
      coupon.active = false;
      await coupon.save();
      return res.status(400).json({ success: false, message: 'Coupon has expired' });
    }

    res.status(200).json({
      success: true,
      data: {
        code: coupon.code,
        discountPercent: coupon.discountPercent,
        maxDiscount: coupon.maxDiscount,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get all active coupons
// @route   GET /api/coupons
// @access  Private
exports.getCoupons = async (req, res) => {
  try {
    const coupons = await Coupon.find({ active: true, expiryDate: { $gt: new Date() } });
    res.status(200).json({ success: true, data: coupons });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
