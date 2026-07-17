const https = require('https');
const Note = require('../models/Note');

// ─── Gemini API caller ────────────────────────────────────────────────────────
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
      path: `/v1/models/gemini-1.5-flash:generateContent?key=${key}`,
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
          if (json.candidates && json.candidates[0]?.content?.parts[0]?.text) {
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

// ─── Heuristic fallback (when no API key is set) ──────────────────────────────
const getHeuristicAIResponse = (type, title, description) => {
  const query = `${title} ${description}`.toLowerCase();

  // ── DSA / Data Structures ──
  if (type === 'summary') {
    if (query.includes('stack') || query.includes('queue') || query.includes('dsa') || query.includes('data structure') || query.includes('algorithm')) {
      return `📌 Key Concepts in "${title}"\n\n• Data structures organize and store data for efficient access and modification.\n• Stacks operate on LIFO (Last-In, First-Out) — used in recursion, expression evaluation, and undo features.\n• Queues operate on FIFO (First-In, First-Out) — used in scheduling, BFS, and buffering.\n• Trees store hierarchical data. Binary Search Trees allow O(log n) search.\n• Graphs represent networks of nodes. DFS and BFS are key traversal algorithms.\n• Sorting algorithms: Merge Sort O(n log n), Quick Sort O(n log n) avg, Bubble Sort O(n²).`;
    }
    if (query.includes('dbms') || query.includes('database') || query.includes('sql')) {
      return `📌 Key Concepts in "${title}"\n\n• A DBMS manages creation, maintenance, and use of structured databases.\n• Relational Databases use tables with rows/columns; queried via SQL.\n• Normalization (1NF, 2NF, 3NF) reduces redundancy and data anomalies.\n• ACID Properties ensure reliable transactions: Atomicity, Consistency, Isolation, Durability.\n• Indexes speed up queries. Primary Keys uniquely identify rows. Foreign Keys link tables.\n• JOINs (INNER, LEFT, RIGHT, FULL) combine rows from multiple tables.`;
    }
    if (query.includes('os') || query.includes('operating system') || query.includes('process') || query.includes('thread')) {
      return `📌 Key Concepts in "${title}"\n\n• An Operating System manages hardware resources and provides services to applications.\n• Processes are independent execution units; Threads share memory within a process.\n• CPU Scheduling algorithms: FCFS, SJF, Round Robin, Priority Scheduling.\n• Deadlock occurs when processes wait on each other indefinitely — prevented via Banker's Algorithm.\n• Memory management techniques: Paging, Segmentation, Virtual Memory.\n• File systems organize data in hierarchical directories. File allocation: contiguous, linked, indexed.`;
    }
    if (query.includes('network') || query.includes('tcp') || query.includes('ip') || query.includes('http')) {
      return `📌 Key Concepts in "${title}"\n\n• Computer Networks enable communication between devices using protocols.\n• OSI Model has 7 layers: Physical, Data Link, Network, Transport, Session, Presentation, Application.\n• TCP (Transmission Control Protocol) ensures reliable, ordered data delivery. UDP is faster but unreliable.\n• IP addresses identify devices. IPv4 uses 32-bit, IPv6 uses 128-bit addressing.\n• DNS resolves domain names to IP addresses. HTTP/HTTPS handles web requests.\n• Subnetting divides a network into smaller segments using subnet masks.`;
    }
    // Generic fallback
    return `📌 Study Summary: "${title}"\n\n• This document covers foundational and advanced concepts within this subject area.\n• Key theoretical frameworks, definitions, and methodologies are presented throughout.\n• Formulas, diagrams, and practical examples reinforce the core ideas.\n• Active recall and spaced repetition will maximize retention of this material.\n• Review previous year exam questions to identify frequently tested topics.\n• Focus on understanding underlying principles before memorizing specific facts.`;
  }

  if (type === 'quiz') {
    if (query.includes('stack') || query.includes('queue') || query.includes('dsa') || query.includes('data structure') || query.includes('algorithm')) {
      return [
        { question: 'Which data structure operates on a Last-In, First-Out (LIFO) principle?', options: ['Queue', 'Stack', 'Linked List', 'Deque'], answer: 1 },
        { question: 'What is the time complexity of accessing an element by index in an Array?', options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'], answer: 0 },
        { question: 'Which sorting algorithm has the best average-case time complexity?', options: ['Bubble Sort', 'Insertion Sort', 'Merge Sort', 'Selection Sort'], answer: 2 },
        { question: 'What traversal visits: Left → Root → Right in a Binary Tree?', options: ['Pre-order', 'Post-order', 'Level-order', 'In-order'], answer: 3 },
        { question: 'Which data structure uses hashing for O(1) average-time lookups?', options: ['Array', 'Hash Table', 'Stack', 'Heap'], answer: 1 },
      ];
    }
    if (query.includes('dbms') || query.includes('database') || query.includes('sql')) {
      return [
        { question: 'Which SQL clause removes duplicate rows from a result set?', options: ['UNIQUE', 'DISTINCT', 'GROUP BY', 'FILTER'], answer: 1 },
        { question: 'What does the "A" in ACID properties stand for?', options: ['Association', 'Atomicity', 'Authorization', 'Aggregation'], answer: 1 },
        { question: 'Which normal form eliminates partial dependencies?', options: ['1NF', '2NF', '3NF', 'BCNF'], answer: 1 },
        { question: 'Which JOIN returns all rows from the left table even without a match?', options: ['INNER JOIN', 'RIGHT JOIN', 'LEFT JOIN', 'CROSS JOIN'], answer: 2 },
        { question: 'Which SQL aggregate function returns the number of rows?', options: ['SUM()', 'AVG()', 'COUNT()', 'MAX()'], answer: 2 },
      ];
    }
    // Generic
    return [
      { question: `What is the primary focus of the document titled "${title}"?`, options: ['Theoretical concepts', 'Practical applications', 'Both theory and application', 'Historical context'], answer: 2 },
      { question: 'Which study technique is most effective for long-term memory retention?', options: ['Passive reading', 'Active recall testing', 'Highlighting text', 'Watching videos only'], answer: 1 },
      { question: 'What does "spaced repetition" mean in academic study?', options: ['Studying the same topic repeatedly in a row', 'Reviewing topics at increasing intervals over time', 'Sharing notes with a study group', 'Spacing out rest breaks evenly'], answer: 1 },
      { question: 'Which of the following best supports deep understanding of a subject?', options: ['Memorizing definitions', 'Explaining the concept in your own words', 'Copying textbook paragraphs', 'Reading just the summary'], answer: 1 },
      { question: `Which approach would help most when studying "${title}"?`, options: ['Skip difficult sections', 'Practice with examples and past papers', 'Only read once', 'Memorize without understanding'], answer: 1 },
    ];
  }

  if (type === 'flashcards') {
    if (query.includes('stack') || query.includes('queue') || query.includes('dsa') || query.includes('data structure') || query.includes('algorithm')) {
      return [
        { question: 'Time complexity of Binary Search?', answer: 'O(log n) — halves the search space with each comparison.' },
        { question: 'What is a Hash Collision?', answer: 'When two different keys produce the same hash value. Resolved via chaining or open addressing.' },
        { question: 'What is a Min-Heap?', answer: 'A complete binary tree where the parent node is always ≤ its children. Root holds the minimum value.' },
        { question: 'What is Dynamic Programming?', answer: 'An optimization technique that solves complex problems by breaking them into overlapping subproblems and caching results.' },
        { question: 'Stack vs Queue — key difference?', answer: 'Stack: LIFO (Last-In First-Out). Queue: FIFO (First-In First-Out).' },
        { question: 'What is Big-O notation?', answer: 'A mathematical notation describing the upper bound of an algorithm\'s time or space complexity as input size grows.' },
        { question: 'What is DFS (Depth-First Search)?', answer: 'A graph traversal algorithm that explores as far as possible along each branch before backtracking. Uses a Stack.' },
        { question: 'What is a Balanced BST?', answer: 'A Binary Search Tree where the height difference between left and right subtrees is at most 1, ensuring O(log n) operations.' },
      ];
    }
    if (query.includes('dbms') || query.includes('database') || query.includes('sql')) {
      return [
        { question: 'What is a Primary Key?', answer: 'A unique identifier for each row in a table. Cannot be NULL or duplicate.' },
        { question: 'What is Normalization?', answer: 'The process of organizing a database to reduce redundancy and improve data integrity across 1NF, 2NF, 3NF forms.' },
        { question: 'What is a Foreign Key?', answer: 'A column that references the Primary Key of another table, creating a relationship between two tables.' },
        { question: 'What does ACID stand for?', answer: 'Atomicity, Consistency, Isolation, Durability — properties that guarantee reliable database transactions.' },
        { question: 'What is an Index in a database?', answer: 'A data structure that improves query performance by allowing the database to locate rows quickly without full table scans.' },
        { question: 'Difference between DELETE and TRUNCATE?', answer: 'DELETE removes specific rows and can be rolled back. TRUNCATE removes all rows faster and cannot be rolled back.' },
        { question: 'What is a View in SQL?', answer: 'A virtual table based on the result of a SQL query. Simplifies complex queries and provides security by hiding table structure.' },
        { question: 'What is the purpose of GROUP BY?', answer: 'Groups rows with the same values in specified columns into summary rows, often used with aggregate functions like COUNT, SUM, AVG.' },
      ];
    }
    // Generic
    return [
      { question: `What is the main subject covered in "${title}"?`, answer: `${description || 'Core academic concepts and theoretical frameworks relevant to this subject module.'}` },
      { question: 'What is Active Recall?', answer: 'A study technique where you actively stimulate memory retrieval by testing yourself, proven to improve long-term retention.' },
      { question: 'What is the Feynman Technique?', answer: 'A learning method where you explain a concept in simple terms as if teaching it to a child, exposing gaps in your knowledge.' },
      { question: 'What is Spaced Repetition?', answer: 'Reviewing information at strategically increasing intervals to exploit the psychological spacing effect for stronger memory.' },
      { question: 'What is the Pomodoro Technique?', answer: 'A time-management method: study for 25 minutes, take a 5-minute break. After 4 cycles, take a longer 15–30 minute break.' },
      { question: 'Why are practice problems important?', answer: 'They simulate exam conditions, strengthen problem-solving skills, and expose knowledge gaps that passive reading misses.' },
      { question: 'What is elaborative interrogation?', answer: 'A study strategy where you ask "why?" and "how?" about the material, forcing deeper processing and better memory encoding.' },
      { question: 'What is interleaving in studying?', answer: 'Mixing different topics or problem types in a single session instead of blocking one topic at a time, improving long-term skill transfer.' },
    ];
  }

  return null;
};

// ─── Generate Note Summary ────────────────────────────────────────────────────
exports.generateSummary = async (req, res) => {
  try {
    const { noteId } = req.body;
    if (!noteId) return res.status(400).json({ success: false, message: 'noteId is required' });

    const note = await Note.findById(noteId);
    if (!note) return res.status(404).json({ success: false, message: 'Note document not found' });

    let summaryText;
    try {
      const prompt = `You are an academic study assistant. Generate a concise study summary with bullet points for a document titled "${note.title}". Subject: "${note.subject || 'General'}". Description: "${note.description}". Use clear bullet points (•), keep it under 200 words, and focus on the most important concepts a student should know.`;
      summaryText = await callGemini(prompt);
    } catch (apiErr) {
      console.log('Gemini API skipped:', apiErr.message);
      summaryText = getHeuristicAIResponse('summary', note.title, note.description || '');
    }

    res.status(200).json({ success: true, summary: summaryText });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── Generate Quiz Questions ──────────────────────────────────────────────────
exports.generateQuiz = async (req, res) => {
  try {
    const { noteId } = req.body;
    if (!noteId) return res.status(400).json({ success: false, message: 'noteId is required' });

    const note = await Note.findById(noteId);
    if (!note) return res.status(404).json({ success: false, message: 'Note document not found' });

    let quizData;
    try {
      const prompt = `You are an academic quiz generator. Create 5 multiple-choice questions based on the document titled "${note.title}". Subject: "${note.subject || 'General'}". Description: "${note.description}". 
Return ONLY a valid JSON array with exactly 5 objects. Each object must have:
- "question": the question text (string)
- "options": array of exactly 4 answer choices (array of strings)  
- "answer": integer index (0-3) of the correct option

Do not include any markdown, code blocks, or extra text. Return pure JSON only.`;
      const responseText = await callGemini(prompt);
      const cleanJson = responseText.replace(/```json/gi, '').replace(/```/g, '').trim();
      quizData = JSON.parse(cleanJson);
    } catch (err) {
      console.log('Gemini API skipped:', err.message);
      quizData = getHeuristicAIResponse('quiz', note.title, note.description || '');
    }

    res.status(200).json({ success: true, data: quizData });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── Generate Flashcards ──────────────────────────────────────────────────────
exports.generateFlashcards = async (req, res) => {
  try {
    const { noteId } = req.body;
    if (!noteId) return res.status(400).json({ success: false, message: 'noteId is required' });

    const note = await Note.findById(noteId);
    if (!note) return res.status(404).json({ success: false, message: 'Note document not found' });

    let flashcardsData;
    try {
      const prompt = `You are an academic flashcard generator. Create 8 study flashcards based on the document titled "${note.title}". Subject: "${note.subject || 'General'}". Description: "${note.description}".
Return ONLY a valid JSON array with exactly 8 objects. Each object must have:
- "question": a short study prompt (string)
- "answer": a concise factual answer (string)

Do not include any markdown, code blocks, or extra text. Return pure JSON only.`;
      const responseText = await callGemini(prompt);
      const cleanJson = responseText.replace(/```json/gi, '').replace(/```/g, '').trim();
      flashcardsData = JSON.parse(cleanJson);
    } catch (err) {
      console.log('Gemini API skipped:', err.message);
      flashcardsData = getHeuristicAIResponse('flashcards', note.title, note.description || '');
    }

    res.status(200).json({ success: true, data: flashcardsData });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── AI Chat ──────────────────────────────────────────────────────────────────
exports.aiChat = async (req, res) => {
  try {
    const { message, noteContext } = req.body;
    if (!message || message.trim() === '') {
      return res.status(400).json({ success: false, message: 'message is required' });
    }

    let replyText;
    try {
      const contextLine = noteContext
        ? `The student is studying a document titled "${noteContext.title}" about "${noteContext.subject || 'this subject'}". `
        : '';
      const prompt = `You are a helpful academic study assistant for college students. ${contextLine}Answer the following question clearly and concisely. If it involves a formula or code, format it neatly. Keep the answer under 200 words.\n\nStudent question: "${message.trim()}"`;
      replyText = await callGemini(prompt);
    } catch (apiErr) {
      console.log('Gemini API skipped for chat:', apiErr.message);
      // Smart keyword-based fallback for chat
      const q = message.toLowerCase();
      if (q.includes('what is') || q.includes('define') || q.includes('explain')) {
        const topic = message.replace(/what is|define|explain/gi, '').trim();
        replyText = `📚 ${topic} is a fundamental concept in this subject. It refers to a structured approach or principle used to solve specific problems in this domain. For a complete definition, refer to your textbook or add a Gemini API key to enable real AI answers.`;
      } else if (q.includes('difference between') || q.includes('compare')) {
        replyText = `🔍 Both concepts share similarities but differ in their core purpose and implementation. To get a detailed comparison, please add a GEMINI_API_KEY to your backend .env file to enable real AI responses.`;
      } else if (q.includes('formula') || q.includes('equation') || q.includes('calculate')) {
        replyText = `🧮 This calculation involves specific formulas covered in your study material. Enable real AI by adding a GEMINI_API_KEY to the backend .env file for detailed formula explanations.`;
      } else {
        replyText = `🤖 Great question! To get accurate AI-powered answers, please add your GEMINI_API_KEY to the backend .env file. Get a free key at: https://aistudio.google.com/app/apikey\n\nFor now, I recommend reviewing your lecture notes and the selected document for information about: "${message}"`;
      }
    }

    res.status(200).json({ success: true, reply: replyText });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
