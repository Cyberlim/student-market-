const mongoose = require('mongoose');

const PlatformConfigSchema = new mongoose.Schema({
  initialWelcomeCoins: {
    type: Number,
    default: 0,
  },
  referralRefereeReward: {
    type: Number,
    default: 50,
  },
  referralReferrerReward: {
    type: Number,
    default: 50,
  },
  noteApprovalReward: {
    type: Number,
    default: 50,
  },
  platformCommissionRate: {
    type: Number,
    default: 10, // percentage of cash paid / coins paid taken by admin
  },
  deliveryCost: {
    type: Number,
    default: 50,
  },
  freeDeliveryMinPrice: {
    type: Number,
    default: 500,
  },
  freeDeliveryRule: {
    type: String,
    enum: ['None', 'Price Only', 'Same City', 'Same Pincode'],
    default: 'None',
  },
  appName: {
    type: String,
    default: 'EduMarket',
  },
  appLogoUrl: {
    type: String,
    default: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?q=80&w=120',
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  }
});

module.exports = mongoose.model('PlatformConfig', PlatformConfigSchema);
