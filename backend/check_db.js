const mongoose = require('mongoose');
require('dotenv').config();

const checkDb = async () => {
  const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/collegenotes';
  console.log(`Connecting to database at ${mongoUri}...`);
  try {
    await mongoose.connect(mongoUri);
    console.log('Connected!');

    const User = require('./src/models/User');
    const Note = require('./src/models/Note');
    const Dispute = require('./src/models/Dispute');
    const Order = require('./src/models/Order');

    const usersCount = await User.countDocuments();
    const notesCount = await Note.countDocuments();
    const disputesCount = await Dispute.countDocuments();
    const ordersCount = await Order.countDocuments();

    console.log('Users in DB:', usersCount);
    console.log('Notes in DB:', notesCount);
    console.log('Disputes in DB:', disputesCount);
    console.log('Orders in DB:', ordersCount);

    if (usersCount > 0) {
      const sampleUsers = await User.find().limit(3);
      console.log('Sample Users:', sampleUsers.map(u => ({ email: u.email, role: u.role })));
    }
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await mongoose.disconnect();
  }
};

checkDb();
