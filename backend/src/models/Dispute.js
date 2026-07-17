const mongoose = require('mongoose');

const DisputeSchema = new mongoose.Schema({
  user: {
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
    enum: ['Plagiarism', 'Inappropriate Content', 'Copyright Infringement', 'Incorrect Subject', 'Other'],
  },
  description: {
    type: String,
    required: true,
    trim: true,
  },
  status: {
    type: String,
    enum: ['Open', 'Resolved'],
    default: 'Open',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

module.exports = mongoose.model('Dispute', DisputeSchema);
