import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';

// ─── Chat message model ───────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMessage({required this.text, required this.isUser}) : time = DateTime.now();
}

// ─── Main AI Panel Widget ─────────────────────────────────────────────────────
class AIPanel extends StatefulWidget {
  const AIPanel({super.key});

  @override
  State<AIPanel> createState() => _AIPanelState();
}

class _AIPanelState extends State<AIPanel> with TickerProviderStateMixin {
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
  int _correctCount = 0;

  // Flashcards Tab
  bool _isFlashcardsLoading = false;
  List<dynamic> _flashcards = [];
  int _currentFlashcard = 0;
  bool _showAnswer = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Chat Tab
  final List<_ChatMessage> _chatMessages = [];
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _fetchNotes();

    // Welcome message in chat
    _chatMessages.add(_ChatMessage(
      text: '👋 Hi! I\'m your AI study assistant. Select a document above and ask me anything — "Explain stacks", "What is ACID?", "Summarize this topic", etc.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flipController.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
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
        '$backendBaseUrl/notes/my-library',
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

  // ── 1. Generate Summary ───────────────────────────────────────────────────
  Future<void> _generateSummary() async {
    if (_selectedNote == null) return;
    setState(() {
      _isSummarizing = true;
      _summaryResult = null;
    });
    try {
      final token = await _getToken();
      final dio = Dio();
      final noteId = _selectedNote!['_id'] ?? _selectedNote!['id'];
      final response = await dio.post(
        '$backendBaseUrl/ai/summary',
        data: {'noteId': noteId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() => _summaryResult = response.data['summary']);
      } else {
        _showSnack('Failed to generate summary. Try again.');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  // ── 2. Generate Quiz ──────────────────────────────────────────────────────
  Future<void> _generateQuiz() async {
    if (_selectedNote == null) return;
    setState(() {
      _isQuizLoading = true;
      _quizQuestions = [];
      _activeQuestion = 0;
      _selectedAnswer = null;
      _quizChecked = false;
      _correctCount = 0;
    });
    try {
      final token = await _getToken();
      final dio = Dio();
      final noteId = _selectedNote!['_id'] ?? _selectedNote!['id'];
      final response = await dio.post(
        '$backendBaseUrl/ai/quiz',
        data: {'noteId': noteId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() => _quizQuestions = response.data['data'] as List? ?? []);
      } else {
        _showSnack('Failed to generate quiz. Try again.');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isQuizLoading = false);
    }
  }

  // ── 3. Generate Flashcards ────────────────────────────────────────────────
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
      final noteId = _selectedNote!['_id'] ?? _selectedNote!['id'];
      final response = await dio.post(
        '$backendBaseUrl/ai/flashcards',
        data: {'noteId': noteId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() => _flashcards = response.data['data'] as List? ?? []);
      } else {
        _showSnack('Failed to generate flashcards. Try again.');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isFlashcardsLoading = false);
    }
  }

  void _flipCard() {
    setState(() => _showAnswer = !_showAnswer);
    if (_showAnswer) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  // ── 4. AI Chat ────────────────────────────────────────────────────────────
  Future<void> _sendChatMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _isChatLoading) return;

    setState(() {
      _chatMessages.add(_ChatMessage(text: text, isUser: true));
      _isChatLoading = true;
    });
    _chatCtrl.clear();
    _scrollChatToBottom();

    try {
      final token = await _getToken();
      final dio = Dio();
      final Map<String, dynamic> payload = {'message': text};
      if (_selectedNote != null) {
        payload['noteContext'] = {
          'title': _selectedNote!['title'] ?? '',
          'subject': _selectedNote!['subject'] ?? '',
        };
      }
      final response = await dio.post(
        '$backendBaseUrl/ai/chat',
        data: payload,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final reply = response.data['reply'] ?? 'Sorry, I could not generate a response.';
        setState(() => _chatMessages.add(_ChatMessage(text: reply, isUser: false)));
      } else {
        setState(() => _chatMessages.add(_ChatMessage(
          text: 'Sorry, something went wrong. Please try again.',
          isUser: false,
        )));
      }
    } catch (e) {
      setState(() => _chatMessages.add(_ChatMessage(
        text: 'Connection error. Please check your internet and try again.',
        isUser: false,
      )));
    } finally {
      if (mounted) setState(() => _isChatLoading = false);
      _scrollChatToBottom();
    }
  }

  void _scrollChatToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openDocumentSelector() {
    if (_availableNotes.isEmpty) {
      _showSnack('No study notes found. Upload notes first.');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Select Study Document',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Choose a document to generate AI content from',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: _availableNotes.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final note = _availableNotes[index];
                      final isSelected = _selectedNote?['_id'] == note['_id'];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text(note['title'] ?? 'Untitled',
                            style: GoogleFonts.inter(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14)),
                        subtitle: Text(
                          '${note['subject'] ?? 'Notes'} · ${note['semester'] ?? ''}',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedNote = note;
                            _summaryResult = null;
                            _quizQuestions = [];
                            _flashcards = [];
                            _showAnswer = false;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('AI Study Suite',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Column(
            children: [
              // Document selector card in app bar area
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: InkWell(
                  onTap: _openDocumentSelector,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _loadingNotes
                                ? 'Loading notes...'
                                : (_selectedNote != null
                                    ? '${_selectedNote!['title']} · ${_selectedNote!['subject'] ?? ''}'
                                    : 'Tap to select a study document'),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _selectedNote != null ? null : Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.expand_more_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                tabs: const [
                  Tab(text: '✨ Summary'),
                  Tab(text: '📝 Quiz'),
                  Tab(text: '🃏 Cards'),
                  Tab(text: '💬 Ask AI'),
                ],
              ),
            ],
          ),
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
                  _buildChatTab(isDark),
                ],
              ),
      ),
    );
  }

  // ══ Tab 1: Summary ══════════════════════════════════════════════════════════
  Widget _buildSummaryTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Generate button
          _buildGradientButton(
            label: _isSummarizing ? 'Generating Summary...' : '✨ Generate AI Summary',
            isLoading: _isSummarizing,
            onPressed: _selectedNote == null ? null : _generateSummary,
          ),
          const SizedBox(height: 20),
          if (_isSummarizing) ...[
            _buildLoadingCard('Analyzing document with AI...'),
          ],
          if (_summaryResult != null) ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF1E3A5F)]
                      : [const Color(0xFFEDE9FE), const Color(0xFFDBEAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Text('AI Summary',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 14,
                                color: AppColors.primary)),
                      ]),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
                        tooltip: 'Copy summary',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _summaryResult!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Summary copied!',
                                  style: GoogleFonts.inter(fontSize: 13)),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(_summaryResult!,
                      style: GoogleFonts.inter(fontSize: 14, height: 1.7)),
                ],
              ),
            ),
          ],
          if (_summaryResult == null && !_isSummarizing) ...[
            _buildEmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'AI-Powered Summary',
              subtitle: 'Select a document and tap "Generate Summary" to get a smart bullet-point summary of your study material.',
            ),
          ],
        ],
      ),
    );
  }

  // ══ Tab 2: Quiz ═════════════════════════════════════════════════════════════
  Widget _buildQuizTab(bool isDark) {
    if (_isQuizLoading) {
      return _buildLoadingCard('Generating quiz questions with AI...');
    }

    if (_quizQuestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmptyState(
              icon: Icons.quiz_outlined,
              title: 'AI Quiz Generator',
              subtitle: 'Generate 5 multiple-choice questions based on your selected study document.',
            ),
            const SizedBox(height: 24),
            _buildGradientButton(
              label: '📝 Generate Quiz Questions',
              onPressed: _selectedNote == null ? null : _generateQuiz,
            ),
          ],
        ),
      );
    }

    // Quiz complete screen
    if (_activeQuestion >= _quizQuestions.length) {
      return _buildQuizCompleteScreen(isDark);
    }

    final quiz = _quizQuestions[_activeQuestion];
    final List<dynamic> options = quiz['options'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_activeQuestion + 1} of ${_quizQuestions.length}',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              TextButton.icon(
                onPressed: _generateQuiz,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Regenerate'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_activeQuestion + 1) / _quizQuestions.length,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),

          // Question card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz['question'] ?? 'No question',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 15, height: 1.5)),
                const SizedBox(height: 20),
                // Options
                ...List.generate(options.length, (index) {
                  final isSelected = _selectedAnswer == index;
                  final correctIdx = quiz['answer'] as int? ?? -1;
                  Color borderCol =
                      isDark ? Colors.grey.shade700 : Colors.grey.shade300;
                  Color bgCol = Colors.transparent;
                  Widget? trailingIcon;

                  if (_quizChecked) {
                    if (index == correctIdx) {
                      borderCol = AppColors.success;
                      bgCol = AppColors.success.withValues(alpha: 0.1);
                      trailingIcon = const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 20);
                    } else if (isSelected) {
                      borderCol = AppColors.error;
                      bgCol = AppColors.error.withValues(alpha: 0.1);
                      trailingIcon = const Icon(Icons.cancel_rounded,
                          color: AppColors.error, size: 20);
                    }
                  } else if (isSelected) {
                    borderCol = AppColors.primary;
                    bgCol = AppColors.primary.withValues(alpha: 0.08);
                  }

                  return GestureDetector(
                    onTap: _quizChecked
                        ? null
                        : () => setState(() => _selectedAnswer = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: borderCol, width: isSelected ? 2 : 1),
                        color: bgCol,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: isSelected && !_quizChecked
                                ? AppColors.primary
                                : Colors.grey.withValues(alpha: 0.2),
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected && !_quizChecked
                                      ? Colors.white
                                      : Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(options[index].toString(),
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                          ),
                          ?trailingIcon,
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          if (!_quizChecked)
            _buildGradientButton(
              label: 'Check Answer',
              onPressed: _selectedAnswer == null
                  ? null
                  : () => setState(() => _quizChecked = true),
            ),
          if (_quizChecked) ...[
            // Explanation
            if ((quiz['explanation'] ?? '').toString().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quiz['explanation'].toString(),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.success,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() {
                        _selectedAnswer = null;
                        _quizChecked = false;
                      }),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child:
                      Text('Reset', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradientButton(
                  label: _activeQuestion < _quizQuestions.length - 1
                      ? 'Next →'
                      : 'See Results 🎉',
                  onPressed: () {
                    if (_selectedAnswer == quiz['answer']) {
                      setState(() => _correctCount++);
                    }
                    if (_activeQuestion < _quizQuestions.length - 1) {
                      setState(() {
                        _activeQuestion++;
                        _selectedAnswer = null;
                        _quizChecked = false;
                      });
                    } else {
                      setState(() => _activeQuestion = _quizQuestions.length);
                    }
                  },
                ),
              ),
            ]),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildQuizCompleteScreen(bool isDark) {
    final score = _correctCount;
    final total = _quizQuestions.length;
    final pct = total > 0 ? (score / total * 100).round() : 0;
    Color scoreColor = pct >= 80
        ? AppColors.success
        : pct >= 50
            ? Colors.orange
            : AppColors.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Quiz Complete! 🎉',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scoreColor.withValues(alpha: 0.1),
                border: Border.all(color: scoreColor, width: 4),
              ),
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$pct%',
                      style: GoogleFonts.inter(
                          fontSize: 28, fontWeight: FontWeight.bold, color: scoreColor)),
                  Text('$score/$total',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pct >= 80
                  ? '🌟 Excellent! You have a strong grasp of this material.'
                  : pct >= 50
                      ? '👍 Good effort! Review the topics you missed.'
                      : '📖 Keep studying! Use the Flashcards tab to reinforce concepts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildGradientButton(
              label: '🔄 Try Again',
              onPressed: _generateQuiz,
            ),
          ],
        ),
      ),
    );
  }

  // ══ Tab 3: Flashcards ════════════════════════════════════════════════════════
  Widget _buildFlashcardsTab(bool isDark) {
    if (_isFlashcardsLoading) {
      return _buildLoadingCard('Generating flashcards with AI...');
    }

    if (_flashcards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmptyState(
              icon: Icons.style_outlined,
              title: 'AI Flashcards',
              subtitle: 'Generate 8 smart flashcards based on your selected document. Tap each card to reveal the answer.',
            ),
            const SizedBox(height: 24),
            _buildGradientButton(
              label: '🃏 Generate Flashcards',
              onPressed: _selectedNote == null ? null : _generateFlashcards,
            ),
          ],
        ),
      );
    }

    final card = _flashcards[_currentFlashcard];

    return Column(
      children: [
        const SizedBox(height: 16),
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_flashcards.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _currentFlashcard ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == _currentFlashcard
                  ? AppColors.primary
                  : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
        const SizedBox(height: 8),
        Text('${_currentFlashcard + 1} / ${_flashcards.length}',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 12),

        // Flip card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_flipAnimation.value * 3.14159),
                    child: _flipAnimation.value < 0.5
                        ? _buildCardFace(
                            icon: Icons.help_outline_rounded,
                            label: 'QUESTION',
                            text: card['question'] ?? '',
                            hint: 'Tap to reveal answer',
                            isDark: isDark,
                            isAnswer: false,
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(3.14159),
                            child: _buildCardFace(
                              icon: Icons.lightbulb_rounded,
                              label: 'ANSWER',
                              text: card['answer'] ?? '',
                              hint: 'Tap to flip back',
                              isDark: isDark,
                              isAnswer: true,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),

        // Navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentFlashcard > 0
                      ? () {
                          setState(() {
                            _currentFlashcard--;
                            _showAnswer = false;
                          });
                          _flipController.reset();
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                  label: const Text('Prev'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _currentFlashcard < _flashcards.length - 1
                    ? _buildGradientButton(
                        label: 'Next →',
                        onPressed: () {
                          setState(() {
                            _currentFlashcard++;
                            _showAnswer = false;
                          });
                          _flipController.reset();
                        },
                      )
                    : OutlinedButton.icon(
                        onPressed: _generateFlashcards,
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text('Regenerate'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFace({
    required IconData icon,
    required String label,
    required String text,
    required String hint,
    required bool isDark,
    required bool isAnswer,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAnswer
              ? [const Color(0xFF7C3AED), AppColors.primary]
              : isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF8F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isAnswer ? AppColors.primary : Colors.black)
                .withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: isAnswer
            ? null
            : Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: (isAnswer ? Colors.white : AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: isAnswer ? Colors.white70 : AppColors.primary),
                  const SizedBox(width: 6),
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: isAnswer ? Colors.white70 : AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.6,
                color: isAnswer ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(hint,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isAnswer ? Colors.white60 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ══ Tab 4: Chat ══════════════════════════════════════════════════════════════
  Widget _buildChatTab(bool isDark) {
    return Column(
      children: [
        // Suggestion chips
        if (_chatMessages.length <= 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _buildSuggestionChip('Explain this topic'),
                _buildSuggestionChip('What are the key formulas?'),
                _buildSuggestionChip('Give me examples'),
                _buildSuggestionChip('How to remember this?'),
              ],
            ),
          ),

        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _chatScroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _chatMessages.length + (_isChatLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isChatLoading && index == _chatMessages.length) {
                return _buildTypingIndicator(isDark);
              }
              final msg = _chatMessages[index];
              return _buildChatBubble(msg, isDark);
            },
          ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  maxLines: null,
                  onSubmitted: (_) => _sendChatMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ask anything about your notes...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                    filled: true,
                    fillColor:
                        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendChatMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF7C3AED)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(_ChatMessage msg, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF7C3AED)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: msg.isUser
                    ? null
                    : Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.6,
                  color: msg.isUser ? Colors.white : null,
                ),
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF7C3AED)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _buildDot(i * 150)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.3 + value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        _chatCtrl.text = label;
        _sendChatMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────
  Widget _buildGradientButton({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
              : const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF7C3AED)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  const Color(0xFF7C3AED).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.grey, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(message,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Text('This may take a few seconds...',
              style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}
