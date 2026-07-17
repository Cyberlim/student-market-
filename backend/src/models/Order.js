const mongoose = require('mongoose');

const OrderSchema = new mongoose.Schema({
  buyer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  note: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Note',
    required: true,
  },
  price: {
    type: Number,
    required: true,
  },
  coinsUsed: {
    type: Number,
    default: 0,
  },
  cashPaid: {
    type: Number,
    default: 0,
  },
  status: {
    type: String,
    enum: ['Pending', 'Completed', 'Failed', 'Dispatched', 'Out for Delivery', 'Delivered', 'Cancelled'],
    default: 'Pending',
  },
  shippingAddress: {
    fullName: String,
    phoneNumber: String,
    addressLine: String,
    city: String,
    state: String,
    pinCode: String
  },
  razorpayOrderId: {
    type: String,
    required: false,
  },
  razorpayPaymentId: {
    type: String,
  },
  invoiceNumber: {
    type: String,
    unique: false,
  },
  pickupDate: {
    type: Date,
    default: null,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

module.exports = mongoose.model('Order', OrderSchema);
