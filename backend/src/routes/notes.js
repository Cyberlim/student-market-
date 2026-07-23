const express = require('express');
const router = express.Router();
const multer = require('multer');
const { uploadNote, getNotes, getNoteById, reviewNote, updateNoteStatus, getMyStudyNotes, reportNote, getNoteReviews, deleteNote } = require('../controllers/noteController');
const { protect, authorize } = require('../middleware/auth');


// Multer basic disk storage fallback config
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, '/tmp/uploads/'); // fallback tmp folder path
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + '-' + file.originalname);
  }
});
const upload = multer({ 
  storage: multer.memoryStorage(), // use memory storage so Cloudinary can stream directly
  limits: { fileSize: 50 * 1024 * 1024 } // 50MB
});

const uploadFields = upload.fields([
  { name: 'file', maxCount: 1 },
  { name: 'thumbnail', maxCount: 1 },
  { name: 'images', maxCount: 5 }
]);

router.route('/')
  .get(getNotes)
  .post(protect, uploadFields, uploadNote);

router.get('/my-library', protect, getMyStudyNotes);

router.route('/:id')
  .get(getNoteById)
  .delete(protect, authorize('Admin'), deleteNote);

router.post('/:id/reviews', protect, reviewNote);
router.get('/:id/reviews', getNoteReviews);

router.post('/:id/report', protect, reportNote);


router.put('/:id/status', protect, authorize('Admin'), updateNoteStatus);

module.exports = router;
