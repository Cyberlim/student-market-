import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class AIPanel extends StatefulWidget {
  const AIPanel({Key? key}) : super(key: key);

  @override
  State<AIPanel> createState() => _AIPanelState();
}

class _AIPanelState extends State<AIPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _availableNotes = [];
  Map<String, dynamic>? _selectedNote;
  bool _loadingNotes = true;

  // Summary Tab
  bool _isSummarizing = false;
  String? _summaryResult;

  // Quiz Tab
  bool _isQuizLoading = false;
  List<dynamic> _quizQuestions = [];
  int _activeQuestion = 0;
  int? _selectedAnswer;
  bool _quizChecked = false;

  // Flashcards Tab
  bool _isFlashcardsLoading = false;
  List<dynamic> _flashcards = [];
  int _currentFlashcard = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? '';
  }

  Future<void> _fetchNotes() async {
    setState(() => _loadingNotes = true);
    try {
      final token = await _getToken();
      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/notes',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final notes = response.data['data'] as List? ?? [];
        setState(() {
          _availableNotes = notes;
          if (_availableNotes.isNotEmpty) {
            _selectedNote = _availableNotes.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching notes for AI panel: $e');
    } finally {
      if (mounted) setState(() => _loadingNotes = false);
    }
  }

  // 1. Generate Summary from Backend
  Future<void> _generateSummary() async {
    if (_selectedNote == null) return;
    setState(() {
      _isSummarizing = true;
      _summaryResult = null;
    });

    try {
      final token = await _getToken();
      final dio = Dio();
      final response = await dio.post(
        '$backendBaseUrl/ai/summary',
        data: {'noteId': _selectedNote!['_id'] || _selectedNote!['id']},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _summaryResult = response.data['summary'];
        });
      }
    } catch (e) {
      _showSnack('Failed to generate summary: $e');
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  // 2. Generate Quiz from Backend
  Future<void> _generateQuiz() async {
    if (_selectedNote == null) return;
    setState(() {
      _isQuizLoading = true;
      _quizQuestions = [];
      _activeQuestion = 0;
      _selectedAnswer = null;
      _quizChecked = false;
    });

    try {
      final token = await _getToken();
      final dio = Dio();
      final response = await dio.post(
        '$backendBaseUrl/ai/quiz',
        data: {'noteId': _selectedNote!['_id'] || _selectedNote!['id']},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _quizQuestions = response.data['data'] as List? ?? [];
        });
      }
    } catch (e) {
      _showSnack('Failed to generate quiz: $e');
    } finally {
      if (mounted) setState(() => _isQuizLoading = false);
    }
  }

  // 3. Generate Flashcards from Backend
  Future<void> _generateFlashcards() async {
    if (_selectedNote == null) return;
    setState(() {
      _isFlashcardsLoading = true;
      _flashcards = [];
      _currentFlashcard = 0;
      _showAnswer = false;
    });

    try {
      final token = await _getToken();
      final dio = Dio();
      final response = await dio.post(
        '$backendBaseUrl/ai/flashcards',
        data: {'noteId': _selectedNote!['_id'] || _selectedNote!['id']},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _flashcards = response.data['data'] as List? ?? [];
        });
      }
    } catch (e) {
      _showSnack('Failed to generate flashcards: $e');
    } finally {
      if (mounted) setState(() => _isFlashcardsLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  // Document picker sheet
  void _openDocumentSelector(bool isDark) {
    if (_availableNotes.isEmpty) {
      _showSnack('No uploaded study notes found to study.');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Document to Study', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _availableNotes.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final note = _availableNotes[index];
                    final isSelected = _selectedNote?['_id'] == note['_id'];
                    return ListTile(
                      leading: const Icon(Icons.description_rounded, color: AppColors.primary),
                      title: Text(note['title'] ?? '', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(note['subject'] ?? 'General subject', style: const TextStyle(fontSize: 11)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _selectedNote = note;
                          // Reset states
                          _summaryResult = null;
                          _quizQuestions = [];
                          _flashcards = [];
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Study Suite',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Quiz'),
            Tab(text: 'Flashcards'),
          ],
        ),
      ),
      body: SafeArea(
        child: _loadingNotes
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(isDark),
                  _buildQuizTab(isDark),
                  _buildFlashcardsTab(isDark),
                ],
              ),
      ),
    );
  }

  // ── Tab 1: Summary ────────────────────────────────────────────────
  Widget _buildSummaryTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectedDocCard(isDark),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Generate AI Summary',
            isLoading: _isSummarizing,
            onPressed: _selectedNote == null ? null : _generateSummary,
          ),
          const SizedBox(height: 24),
          if (_summaryResult != null)
            GlassCard(
              borderRadius: 20,
              opacity: 0.04,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text('AI Summary Result', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _summaryResult!,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Tab 2: Quiz ───────────────────────────────────────────────────
  Widget _buildQuizTab(bool isDark) {
    if (_selectedNote == null) {
      return Center(child: Text('Please upload or select a document first.', style: GoogleFonts.poppins(color: Colors.grey)));
    }

    if (_isQuizLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_quizQuestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSelectedDocCard(isDark),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Generate Quiz Questions',
              onPressed: _generateQuiz,
            ),
          ],
        ),
      );
    }

    final quiz = _quizQuestions[_activeQuestion];
    final List<dynamic> options = quiz['options'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_activeQuestion + 1} of ${_quizQuestions.length}',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              TextButton(onPressed: _generateQuiz, child: const Text('Regenerate')),
            ],
          ),
          const SizedBox(height: 12),

          // Question container
          GlassCard(
            borderRadius: 20,
            opacity: 0.05,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz['question'] ?? 'No question text',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 20),
                // Choices
                Column(
                  children: List.generate(options.length, (index) {
                    final isSelected = _selectedAnswer == index;
                    Color borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;
                    Color bgCol = Colors.transparent;

                    if (_quizChecked) {
                      if (index == quiz['answer']) {
                        borderCol = AppColors.success;
                        bgCol = AppColors.success.withOpacity(0.12);
                      } else if (isSelected) {
                        borderCol = AppColors.error;
                        bgCol = AppColors.error.withOpacity(0.12);
                      }
                    } else if (isSelected) {
                      borderCol = AppColors.primary;
                      bgCol = AppColors.primary.withOpacity(0.08);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol, width: isSelected ? 2 : 1),
                        color: bgCol,
                      ),
                      child: ListTile(
                        onTap: _quizChecked
                            ? null
                            : () {
                                setState(() {
                                  _selectedAnswer = index;
                                });
                              },
                        title: Text(
                          options[index].toString(),
                          style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        ),
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_quizChecked)
                Expanded(
                  child: GradientButton(
                    text: 'Verify Answer',
                    onPressed: _selectedAnswer == null
                        ? null
                        : () {
                            setState(() {
                              _quizChecked = true;
                            });
                          },
                  ),
                ),
              if (_quizChecked) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedAnswer = null;
                        _quizChecked = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                if (_activeQuestion < _quizQuestions.length - 1)
                  Expanded(
                    child: GradientButton(
                      text: 'Next Question',
                      onPressed: () {
                        setState(() {
                          _activeQuestion++;
                          _selectedAnswer = null;
                          _quizChecked = false;
                        });
                      },
                    ),
                  ),
              ]
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Tab 3: Flashcards ─────────────────────────────────────────────
  Widget _buildFlashcardsTab(bool isDark) {
    if (_selectedNote == null) {
      return Center(child: Text('Please upload or select a document first.', style: GoogleFonts.poppins(color: Colors.grey)));
    }

    if (_isFlashcardsLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_flashcards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSelectedDocCard(isDark),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Generate Study Flashcards',
              onPressed: _generateFlashcards,
            ),
          ],
        ),
      );
    }

    final card = _flashcards[_currentFlashcard];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Card ${_currentFlashcard + 1} of ${_flashcards.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              TextButton(onPressed: _generateFlashcards, child: const Text('Regenerate')),
            ],
          ),
          const SizedBox(height: 12),
          // Flashcard layout
          GestureDetector(
            onTap: () {
              setState(() {
                _showAnswer = !_showAnswer;
              });
            },
            child: AspectRatio(
              aspectRatio: 1.4,
              child: GlassCard(
                borderRadius: 24,
                opacity: 0.06,
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showAnswer ? Icons.visibility_rounded : Icons.help_outline_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _showAnswer ? (card['answer'] ?? '') : (card['question'] ?? ''),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _showAnswer ? AppColors.primary : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _showAnswer ? 'Tap card to hide answer' : 'Tap card to reveal answer',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary),
                onPressed: _currentFlashcard > 0
                    ? () {
                        setState(() {
                          _currentFlashcard--;
                          _showAnswer = false;
                        });
                      }
                    : null,
              ),
              Text(
                '${_currentFlashcard + 1} / ${_flashcards.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary),
                onPressed: _currentFlashcard < _flashcards.length - 1
                    ? () {
                        setState(() {
                          _currentFlashcard++;
                          _showAnswer = false;
                        });
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Selected Document Card widget
  Widget _buildSelectedDocCard(bool isDark) {
    return GlassCard(
      borderRadius: 16,
      opacity: 0.05,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  _selectedNote != null
                      ? '${_selectedNote!['title']} (${_selectedNote!['subject'] ?? 'Notes'})'
                      : 'No study notes selected',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openDocumentSelector(isDark),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
