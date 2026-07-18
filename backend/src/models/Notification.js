const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  message: {
    type: String,
    required: true,
    trim: true,
  },
  type: {
    type: String,
    enum: ['Order', 'Approval', 'Promo', 'General'],
    default: 'General',
  },
  isRead: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

NotificationSchema.post('save', async function(doc) {
  try {
    // Only send on initial creation
    if (!this.$isNew) return;

    const User = mongoose.model('User');
    const user = await User.findById(doc.user);
    if (user && user.fcmToken) {
      const { sendPushNotification } = require('../utils/firebase');
      await sendPushNotification(user.fcmToken, doc.title, doc.message, { notificationId: doc._id.toString() });
    }
  } catch (err) {
    console.error('Error in Notification post-save hook:', err.message);
  }
});

module.exports = mongoose.model('Notification', NotificationSchema);
