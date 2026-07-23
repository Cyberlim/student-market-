const mongoose = require('mongoose');

const ReportSchema = new mongoose.Schema({
  reporter: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  note: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Note',
    required: true,
  },
  reason: {
    type: String,
    required: true,
    enum: ['Inappropriate Content', 'Copyright Violation', 'Spam', 'Misleading Information', 'Other'],
  },
  details: {
    type: String,
    trim: true,
  },
  status: {
    type: String,
    enum: ['Pending', 'Dismissed', 'Action Taken'],
    default: 'Pending',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

module.exports = mongoose.model('Report', ReportSchema);
