const https = require('https');
const Note = require('../models/Note');

// Call Gemini API via native https connection
const callGemini = (prompt) => {
  return new Promise((resolve, reject) => {
    const key = process.env.GEMINI_API_KEY || '';
    if (!key) {
      return reject(new Error('No GEMINI_API_KEY configured in environment'));
    }
    const postData = JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }]
    });

    const options = {
      hostname: 'generativelanguage.googleapis.com',
      port: 443,
      path: `/v1beta/models/gemini-1.5-flash:generateContent?key=${key}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          if (json.candidates && json.candidates[0].content && json.candidates[0].content.parts[0].text) {
            resolve(json.candidates[0].content.parts[0].text);
          } else {
            reject(new Error(json.error?.message || 'Unexpected Gemini response structure'));
          }
        } catch (err) {
          reject(err);
        }
      });
    });

    req.on('error', (err) => reject(err));
    req.write(postData);
    req.end();
  });
};

// Heuristic fallback helper for generating smart study items locally based on keywords
const getHeuristicAIResponse = (type, title, description) => {
  const query = `${title} ${description}`.toLowerCase();
  
  if (type === 'summary') {
    if (query.includes('stack') || query.includes('queue') || query.includes('dsa') || query.includes('data structure')) {
      return `• Data structures organize and store data for efficient access and modification.
• Stacks are LIFO (Last-In, First-Out) structures used in function calling, expression evaluation, and backtracking algorithms.
• Queues are FIFO (First-In, First-Out) structures used in task scheduling, printers, and buffer streams.
• Trees store hierarchical data, where Binary Trees restrict children count to at most two per node.`;
    }
    if (query.includes('dbms') || query.includes('database') || query.includes('sql')) {
      return `• A Database Management System (DBMS) controls creation, maintenance, and use of databases.
• Relational Databases organize data into tables consisting of rows and columns, utilizing SQL for queries.
• Normalization is the process of organizing data in a database to reduce redundancy and improve data integrity.
• Transactions follow ACID properties (Atomicity, Consistency, Isolation, Durability) to guarantee reliable execution.`;
    }
    // Generic
    return `• Key Study Points for "${title}":
• High-level summary outlines core academic definitions, methodologies, and context.
• Practice examples help reinforce underlying concepts and theoretical formulas.
• Active recall flashcards should be used to cement facts before examinations.
• Reviewing related exercises provides hands-on mastery of the subject matter.`;
  }

  if (type === 'quiz') {
    if (query.includes('stack') || query.includes('queue') || query.includes('dsa') || query.includes('data structure')) {
      return [
        {
          question: 'Which of the following data structures operates on a Last-In, First-Out (LIFO) model?',
          options: ['Queue', 'Stack', 'Linked List', 'Binary Tree'],
          answer: 1,
        },
        {
          question: 'What is the time complexity to access an element at index i in an Array?',
          options: ['O(1)', 'O(n)', 'O(log n)', 'O(n log n)'],
          answer: 0,
        },
        {
          question: 'What is the average time complexity of searching a value in a balanced Binary Search Tree?',
          options: ['O(1)', 'O(n)', 'O(log n)', 'O(n log n)'],
          answer: 2,
        }
      ];
    }
    if (query.includes('dbms') || query.includes('database') || query.includes('sql')) {
      return [
        {
          question: 'Which SQL keyword is used to remove duplicates from a query result set?',
          options: ['UNIQUE', 'DISTINCT', 'ONLY', 'FILTER'],
          answer: 1,
        },
        {
          question: 'In ACID properties, what does "I" stand for?',
          options: ['Integrity', 'Index', 'Isolation', 'Inheritance'],
          answer: 2,
        },
        {
          question: 'What type of relationship is established by a Foreign Key referencing a Primary Key?',
          options: ['One-to-One', 'Many-to-Many', 'Referential Integrity Constraint', 'None of the above'],
          answer: 2,
        }
      ];
    }
    // Generic
    return [
      {
        question: `What is the primary objective of studying "${title}"?`,
        options: ['Theoretical understanding', 'Practical application', 'Both A and B', 'None of the above'],
        answer: 2,
      },
      {
        question: `Which approach is best suited to master "${title}" topics?`,
        options: ['Passive reading', 'Active recall & testing', 'Rote memorization', 'Leaving it until the night before'],
        answer: 1,
      }
    ];
  }

  if (type === 'flashcards') {
    if (query.includes('stack') || query.includes('queue') || query.includes('dsa') || query.includes('data structure')) {
      return [
        { question: 'Time complexity of Merge Sort?', answer: 'O(n log n) in all cases (best, average, worst).' },
        { question: 'What is a Semaphore?', answer: 'An integer variable used for signaling and solving critical section synchronization issues.' },
        { question: 'What is a Hash Table?', answer: 'A data structure that maps keys to values using a hash function for O(1) average lookup times.' }
      ];
    }
    if (query.includes('dbms') || query.includes('database') || query.includes('sql')) {
      return [
        { question: 'What is a Primary Key?', answer: 'A unique identifier for each record in a database table. Cannot be null.' },
        { question: 'What is the purpose of Normalization?', answer: 'To minimize redundancy and dependency by organizing fields and table relations.' },
        { question: 'What is a Foreign Key?', answer: 'A column or group of columns that provides a link between data in two tables.' }
      ];
    }
    // Generic
    return [
      { question: `What is the core definition of ${title}?`, answer: `It refers to: ${description || 'the study material covered under this course module.'}` },
      { question: 'What is active recall?', answer: 'A learning technique where the mind is actively stimulated to retrieve information, rather than reading it passively.' }
    ];
  }

  return null;
};

// Generate Note Summary
exports.generateSummary = async (req, res) => {
  try {
    const { noteId } = req.body;
    const note = await Note.findById(noteId);
    if (!note) {
      return res.status(404).json({ success: false, message: 'Note document not found' });
    }

    let summaryText;
    try {
      const prompt = `Generate a concise study summary with bullet points for a document titled "${note.title}". Description: "${note.description}". Output only the summary, keep it under 150 words.`;
      summaryText = await callGemini(prompt);
    } catch (apiErr) {
      console.log('Gemini API call skipped/failed, using local heuristic fallback:', apiErr.message);
      summaryText = getHeuristicAIResponse('summary', note.title, note.description);
    }

    res.status(200).json({ success: true, summary: summaryText });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// Generate Quiz Questions
exports.generateQuiz = async (req, res) => {
  try {
    const { noteId } = req.body;
    const note = await Note.findById(noteId);
    if (!note) {
      return res.status(404).json({ success: false, message: 'Note document not found' });
    }

    let quizData;
    try {
      const prompt = `Create a multiple choice quiz based on "${note.title}". Description: "${note.description}". Return exactly 3 questions in a strict JSON array format, where each object has: "question" (string), "options" (array of 4 strings), and "answer" (index integer 0-3 of the correct option). Do not output markdown, ticks, or text surrounding the JSON.`;
      const responseText = await callGemini(prompt);
      
      // Clean up markdown block format if present
      const cleanJson = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
      quizData = JSON.parse(cleanJson);
    } catch (err) {
      console.log('Gemini API call skipped/failed, using local heuristic fallback');
      quizData = getHeuristicAIResponse('quiz', note.title, note.description);
    }

    res.status(200).json({ success: true, data: quizData });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// Generate Flashcards
exports.generateFlashcards = async (req, res) => {
  try {
    const { noteId } = req.body;
    const note = await Note.findById(noteId);
    if (!note) {
      return res.status(404).json({ success: false, message: 'Note document not found' });
    }

    let flashcardsData;
    try {
      const prompt = `Create 3 study flashcards based on "${note.title}". Description: "${note.description}". Return exactly 3 items in a strict JSON array format, where each object has: "question" (short study prompt string) and "answer" (fact answer string). Do not output markdown, ticks, or text surrounding the JSON.`;
      const responseText = await callGemini(prompt);
      const cleanJson = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
      flashcardsData = JSON.parse(cleanJson);
    } catch (err) {
      console.log('Gemini API call skipped/failed, using local heuristic fallback');
      flashcardsData = getHeuristicAIResponse('flashcards', note.title, note.description);
    }

    res.status(200).json({ success: true, data: flashcardsData });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
