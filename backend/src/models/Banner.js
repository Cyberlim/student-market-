const mongoose = require('mongoose');

const BannerSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    default: '',
  },
  tag: {
    type: String,
    default: 'PROMO',
  },
  discountPercent: {
    type: Number,
    default: 0,
  },
  bgImageUrl: {
    type: String,
    default: '',
  },
  targetRoute: {
    type: String,
    default: '',
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

module.exports = mongoose.model('Banner', BannerSchema);
