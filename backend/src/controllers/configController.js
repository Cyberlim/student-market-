const PlatformConfig = require('../models/PlatformConfig');

// Get active platform configuration (or seed default if none exists)
exports.getConfig = async (req, res) => {
  try {
    let config = await PlatformConfig.findOne();
    if (!config) {
      config = await PlatformConfig.create({
        initialWelcomeCoins: 0,
        referralRefereeReward: 50,
        referralReferrerReward: 50,
        noteApprovalReward: 50,
        platformCommissionRate: 10,
        deliveryCost: 50,
        freeDeliveryMinPrice: 500,
        freeDeliveryRule: 'None',
        appName: 'CloudNotes',
        appLogoUrl: '',
      });
    }
    res.status(200).json({ success: true, data: config });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// Update platform configurations (Admin only)
exports.updateConfig = async (req, res) => {
  try {
    const {
      initialWelcomeCoins,
      referralRefereeReward,
      referralReferrerReward,
      noteApprovalReward,
      platformCommissionRate,
      deliveryCost,
      freeDeliveryMinPrice,
      freeDeliveryRule,
      appName,
      appLogoUrl,
    } = req.body;

    let config = await PlatformConfig.findOne();
    if (!config) {
      config = new PlatformConfig();
    }

    if (initialWelcomeCoins !== undefined) config.initialWelcomeCoins = Number(initialWelcomeCoins);
    if (referralRefereeReward !== undefined) config.referralRefereeReward = Number(referralRefereeReward);
    if (referralReferrerReward !== undefined) config.referralReferrerReward = Number(referralReferrerReward);
    if (noteApprovalReward !== undefined) config.noteApprovalReward = Number(noteApprovalReward);
    if (platformCommissionRate !== undefined) config.platformCommissionRate = Number(platformCommissionRate);
    if (deliveryCost !== undefined) config.deliveryCost = Number(deliveryCost);
    if (freeDeliveryMinPrice !== undefined) config.freeDeliveryMinPrice = Number(freeDeliveryMinPrice);
    if (freeDeliveryRule !== undefined) config.freeDeliveryRule = freeDeliveryRule;
    if (appName !== undefined) config.appName = appName;
    if (appLogoUrl !== undefined) config.appLogoUrl = appLogoUrl;

    config.updatedAt = Date.now();
    await config.save();

    res.status(200).json({ success: true, message: 'Platform configurations updated', data: config });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
