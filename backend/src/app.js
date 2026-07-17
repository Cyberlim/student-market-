const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoose = require('mongoose');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const notesRoutes = require('./routes/notes');
const couponsRoutes = require('./routes/coupons');
const walletRoutes = require('./routes/wallet');
const adminRoutes = require('./routes/admin');
const ordersRoutes = require('./routes/orders');
const notificationsRoutes = require('./routes/notifications');
const configRoutes = require('./routes/config');
const aiRoutes = require('./routes/ai');
const bannersRoutes = require('./routes/banners');

const app = express();

// Simple request logger
app.use((req, res, next) => {
  console.log(`[HTTP] ${req.method} ${req.path}`);
  next();
});

// Security Middleware
app.use(helmet({
  crossOriginOpenerPolicy: false, // Prevent COOP from blocking Google Sign-In popup
}));
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (curl, Postman, mobile apps)
    if (!origin) return callback(null, true);
    // Allow any localhost port (Chrome/web dev)
    if (origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
      return callback(null, true);
    }
    // Allow any local network IP (10.x.x.x or 192.168.x.x) for Android physical device
    if (/^http:\/\/(10\.|192\.168\.)/.test(origin)) {
      return callback(null, true);
    }
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
}));
app.use(express.json());

// Rate Limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: { success: false, message: 'Too many requests from this IP, please try again after 15 minutes' }
});
app.use('/api/', limiter);

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/notes', notesRoutes);
app.use('/api/coupons', couponsRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/admin/config', configRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/banners', bannersRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'College Notes Marketplace Server is active' });
});

// Centralized Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error'
  });
});

// MongoDB connection
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/collegenotes';
const LOCAL_MONGO_URI = 'mongodb://localhost:27017/collegenotes';
const PORT = process.env.PORT || 5000;

const connectWithFallback = (uri) => {
  mongoose.connect(uri)
    .then(() => {
      console.log(`MongoDB connection active successfully to: ${uri}`);
      app.listen(PORT, '0.0.0.0', () => {
        console.log(`Server running on port ${PORT}`);
      });
    })
    .catch(err => {
      console.error(`Database connection failed for ${uri}:`, err.message);
      if (uri !== LOCAL_MONGO_URI) {
        console.log('Falling back to local MongoDB...');
        connectWithFallback(LOCAL_MONGO_URI);
      } else {
        console.error('All database connection attempts failed.');
        process.exit(1);
      }
    });
};

connectWithFallback(MONGO_URI);

module.exports = app;
