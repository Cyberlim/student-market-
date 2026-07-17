const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    enum: ['Student', 'Teacher', 'Admin'],
    default: 'Student',
  },
  coins: {
    type: Number,
    default: 0, // starting coins
  },
  badges: [{
    type: String,
  }],
  referralCode: {
    type: String,
    unique: true,
  },
  referredBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
  avatar: {
    type: String,
    default: '',
  },
  isBanned: {
    type: Boolean,
    default: false,
  },
  addresses: [{
    fullName: { type: String, required: true },
    phoneNumber: { type: String, required: true },
    addressLine: { type: String, required: true },
    city: { type: String, required: true },
    state: { type: String, required: true },
    pinCode: { type: String, required: true },
    isDefault: { type: Boolean, default: false }
  }],
  college: { type: String, default: '' },
  department: { type: String, default: '' },
  phone: { type: String, default: '' },
  bio: { type: String, default: '' },
  isProfileComplete: { type: Boolean, default: false },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

// Hash password before saving
UserSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
  } catch (err) {
    throw err;
  }
});

// Compare password
UserSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', UserSchema);
