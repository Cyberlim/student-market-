const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./src/models/User');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const res = await User.findOneAndUpdate(
    { email: 'kuldeepsengar5678@gmail.com' },
    { $set: { role: 'Admin' } },
    { new: true, upsert: false }
  );
  if (res) {
    console.log('Updated:', res.email, '=> role:', res.role);
  } else {
    console.log('User not found (will be created with Admin role on first login).');
  }
  process.exit(0);
}

run().catch(console.error);
