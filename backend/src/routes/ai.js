const express = require('express');
const router = express.Router();
const { generateSummary, generateQuiz, generateFlashcards } = require('../controllers/aiController');
const { protect } = require('../middleware/auth');

router.post('/summary', protect, generateSummary);
router.post('/quiz', protect, generateQuiz);
router.post('/flashcards', protect, generateFlashcards);

module.exports = router;
