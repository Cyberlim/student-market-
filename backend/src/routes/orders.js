const express = require('express');
const router = express.Router();
const {
  createOrder,
  getMyOrders,
  getSellerOrders,
  getAllOrders,
  updateOrderStatus,
  setPickupDate,
} = require('../controllers/orderController');
const { protect, authorize } = require('../middleware/auth');

// Buyer: create order / view own orders
router.route('/')
  .post(protect, createOrder)
  .get(protect, getMyOrders);

// Seller: view orders for their listed items
router.route('/seller')
  .get(protect, getSellerOrders);

// Admin: view all orders
router.route('/admin')
  .get(protect, authorize('Admin'), getAllOrders);

// Admin: update shipping status
router.route('/:id/status')
  .put(protect, authorize('Admin'), updateOrderStatus);

// Admin: set pickup date for a physical order
router.route('/:id/pickup')
  .put(protect, authorize('Admin'), setPickupDate);

module.exports = router;
