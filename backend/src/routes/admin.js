const express = require('express');
const router = express.Router();
const multer = require('multer');
const { getStats, getPendingNotes, getAllUsers, toggleUserBan, adjustUserCoins, uploadMedia } = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/auth');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }
});

// All routes require Admin role authentication
router.use(protect);
router.use(authorize('Admin'));

router.get('/stats', getStats);
router.get('/notes/pending', getPendingNotes);
router.get('/users', getAllUsers);
router.put('/users/:id/ban', toggleUserBan);
router.put('/users/:id/coins', adjustUserCoins);
router.post('/upload', upload.single('file'), uploadMedia);

module.exports = router;
