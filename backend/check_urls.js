const mongoose = require('mongoose');
require('dotenv').config();
const Note = require('./src/models/Note');

async function checkUrls() {
  await mongoose.connect(process.env.MONGO_URI);
  const notes = await Note.find({}, 'title fileUrl');
  console.log('Notes in DB:');
  notes.forEach(n => console.log(n.title, '=>', n.fileUrl));
  process.exit(0);
}

checkUrls().catch(console.error);
