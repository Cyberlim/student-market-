const mongoose = require('mongoose');

const NoteSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    required: true,
    trim: true,
  },
  college: {
    type: String,
    required: function() { return this.itemType === 'Digital'; },
    trim: true,
  },
  department: {
    type: String,
    required: function() { return this.itemType === 'Digital'; },
    trim: true,
  },
  semester: {
    type: Number,
    required: function() { return this.itemType === 'Digital'; },
  },
  subject: {
    type: String,
    required: function() { return this.itemType === 'Digital'; },
    trim: true,
  },
  price: {
    type: Number,
    default: 0, // 0 means Free / Give away
  },
  category: {
    type: String,
    enum: ['Notes', 'Previous Year Paper', 'Assignment', 'Study Material', 'Other'],
    default: 'Notes',
    required: function() { return this.itemType === 'Digital'; },
  },
  tags: [{
    type: String,
  }],
  fileUrl: {
    type: String,
    required: function() { return this.itemType === 'Digital'; }, // only digital notes require a PDF
  },
  thumbnailUrl: {
    type: String,
    required: true, // Image of the note or the physical item
  },
  images: [{
    type: String,
  }],
  seller: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  status: {
    type: String,
    enum: ['Pending', 'Approved', 'Rejected'],
    default: 'Pending', // All items require admin approval before going live
  },
  itemType: {
    type: String,
    enum: ['Digital', 'Physical'],
    default: 'Digital',
  },
  physicalCategory: {
    type: String,
    enum: ['Calculators', 'Laptops', 'Cycles', 'Hostel furniture', 'Lab coats', 'Electronics', 'None'],
    default: 'None',
  },
  itemCondition: {
    type: String,
    enum: ['New', 'Like New', 'Good', 'Fair', 'None'],
    default: 'None',
  },
  averageRating: {
    type: Number,
    default: 0.0,
  },
  downloadsCount: {
    type: Number,
    default: 0,
  },
  isSold: {
    type: Boolean,
    default: false,
  },
  rewardedForApproval: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

// Text index for search functionality
NoteSchema.index({ title: 'text', description: 'text', college: 'text', subject: 'text' });

module.exports = mongoose.model('Note', NoteSchema);
