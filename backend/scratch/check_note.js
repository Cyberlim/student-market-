const mongoose = require('mongoose');

mongoose.connect('mongodb+srv://kuldeepsengar5678_db_user:Kuldeep@cluster0.ahqlr2v.mongodb.net/test?retryWrites=true&w=majority')
  .then(async () => {
    const Note = require('../src/models/Note');
    const note = await Note.findOne({ title: 'ugvuu' });
    if (note) {
      console.log('Note Found:');
      console.log('title:', note.title);
      console.log('fileUrl:', note.fileUrl);
      console.log('thumbnailUrl:', note.thumbnailUrl);
    } else {
      console.log('Note not found!');
    }
    process.exit(0);
  })
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
