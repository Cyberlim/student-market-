const Order = require('../models/Order');
const Note = require('../models/Note');
const User = require('../models/User');
const Notification = require('../models/Notification');

// Create a new order
exports.createOrder = async (req, res) => {
  try {
    const { noteId, price, shippingAddress, coinsUsed = 0, cashPaid = 0 } = req.body;
    const buyerId = req.user.id;

    // Find note
    const note = await Note.findById(noteId).populate('seller', 'name email');
    if (!note) {
      return res.status(404).json({ success: false, message: 'Item not found' });
    }

    // Check if already sold (physical items can only be sold once)
    if (note.isSold) {
      return res.status(400).json({ success: false, message: 'This item has already been sold.' });
    }

    // Find buyer
    const buyer = await User.findById(buyerId);
    if (!buyer) {
      return res.status(404).json({ success: false, message: 'Buyer profile not found' });
    }

    // Process coin payment
    if (coinsUsed > 0) {
      if (buyer.coins < coinsUsed) {
        return res.status(400).json({ success: false, message: 'Insufficient coins balance' });
      }
      buyer.coins -= coinsUsed;
      await buyer.save();
    }

    // Add coins to seller (seller gets the price of the item minus configured platform commission rate)
    if (price > 0) {
      const PlatformConfig = require('../models/PlatformConfig');
      let config = await PlatformConfig.findOne();
      if (!config) {
        config = { platformCommissionRate: 10 };
      }
      const seller = await User.findById(note.seller._id || note.seller);
      if (seller) {
        const commRate = config.platformCommissionRate ?? 10;
        const commissionAmount = price * (commRate / 100);
        const creditedAmount = Math.max(0, price - commissionAmount);
        seller.coins = (seller.coins || 0) + creditedAmount;
        await seller.save();
      }
    }

    // Create Order
    const isPhysical = note.itemType === 'Physical';
    const order = await Order.create({
      buyer: buyerId,
      note: noteId,
      price: price,
      coinsUsed: coinsUsed,
      cashPaid: cashPaid,
      status: isPhysical ? 'Pending' : 'Completed',
      shippingAddress: isPhysical ? shippingAddress : undefined,
      razorpayOrderId: 'MOCK-RPAY-' + Date.now(),
      invoiceNumber: 'INV-' + Date.now() + '-' + Math.floor(Math.random() * 1000)
    });

    // Mark physical item as sold so it disappears from marketplace feed
    if (isPhysical) {
      note.isSold = true;
      await note.save();
    }

    // Send notifications to both seller and buyer
    try {
      const sellerId = note.seller._id || note.seller;
      const buyerName = buyer.name || 'A student';
      
      // Notify Seller
      await Notification.create({
        user: sellerId,
        title: isPhysical ? '🎉 Your Item Was Sold!' : '📄 Your Notes Were Purchased!',
        message: `${buyerName} purchased "${note.title}" for ₹${price}${coinsUsed > 0 ? ` (${coinsUsed} coins + ₹${cashPaid} cash)` : ''}.`,
        type: 'Order',
      });

      // Notify Buyer
      await Notification.create({
        user: req.user.id,
        title: '🛍️ Purchase Successful!',
        message: `You have successfully purchased "${note.title}" for ₹${price}. You can access it in your library now.`,
        type: 'Order',
      });
    } catch (notifErr) {
      console.error('Notification creation failed (non-fatal):', notifErr.message);
    }

    res.status(201).json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// Get current user's orders (as buyer)
exports.getMyOrders = async (req, res) => {
  try {
    const orders = await Order.find({ buyer: req.user.id })
      .populate('note')
      .populate({ path: 'note', populate: { path: 'seller', select: 'name email' } })
      .sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// Get orders where the logged-in user is the seller (for seller analytics)
exports.getSellerOrders = async (req, res) => {
  try {
    // Find all notes belonging to this seller
    const sellerNotes = await Note.find({ seller: req.user.id }).select('_id');
    const noteIds = sellerNotes.map(n => n._id);

    const orders = await Order.find({ note: { $in: noteIds } })
      .populate('buyer', 'name email avatar')
      .populate('note', 'title thumbnailUrl price itemType physicalCategory')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, data: orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// Get all orders (Admin dashboard)
exports.getAllOrders = async (req, res) => {
  try {
    const orders = await Order.find()
      .populate('buyer', 'name email')
      .populate('note')
      .sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// Update order status (Admin)
exports.updateOrderStatus = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    order.status = req.body.status;
    await order.save();

    // Notify buyer of status update
    try {
      const populatedOrder = await Order.findById(order._id).populate('note', 'title');
      await Notification.create({
        user: order.buyer,
        title: '📦 Order Status Updated',
        message: `Your order for "${populatedOrder.note?.title || 'item'}" is now: ${req.body.status}.`,
        type: 'Order',
      });
    } catch (notifErr) {
      console.error('Buyer notification failed (non-fatal):', notifErr.message);
    }

    res.status(200).json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// Set pickup date for physical order (Admin)
exports.setPickupDate = async (req, res) => {
  try {
    const { pickupDate } = req.body;
    const order = await Order.findById(req.params.id).populate('note', 'title');
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    order.pickupDate = pickupDate ? new Date(pickupDate) : null;
    await order.save();

    // Notify buyer of pickup date
    if (pickupDate) {
      try {
        const formattedDate = new Date(pickupDate).toLocaleDateString('en-IN', {
          day: 'numeric', month: 'long', year: 'numeric'
        });
        await Notification.create({
          user: order.buyer,
          title: '📅 Pickup Date Scheduled',
          message: `Your order for "${order.note?.title || 'item'}" is scheduled for pickup on ${formattedDate}.`,
          type: 'Order',
        });
      } catch (notifErr) {
        console.error('Pickup notification failed (non-fatal):', notifErr.message);
      }
    }

    res.status(200).json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
