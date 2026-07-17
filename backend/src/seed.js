const mongoose = require('mongoose');
const User = require('./models/User');
require('dotenv').config();

const seedAdmin = async () => {
  const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/collegenotes';
  console.log(`Connecting to database at ${mongoUri}...`);
  
  try {
    await mongoose.connect(mongoUri);
    console.log('Database connected successfully.');

    const adminEmail = 'admin@edumarket.in';
    const adminExists = await User.findOne({ email: adminEmail });

    if (adminExists) {
      console.log(`Admin user with email ${adminEmail} already exists.`);
    } else {
      console.log('Seeding admin user...');
      const adminUser = await User.create({
        name: 'Administrator',
        email: adminEmail,
        password: 'admin123', // Will be hashed automatically by the pre-save hook
        role: 'Admin',
        referralCode: 'ADMINX',
        coins: 1000000,
        avatar: 'https://res.cloudinary.com/demo/image/upload/v1/sample_avatar.jpg'
      });
      console.log('Admin user seeded successfully:', adminUser);
    }
  } catch (error) {
    console.error('Error seeding admin user:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Database disconnected.');
  }
};

seedAdmin();
