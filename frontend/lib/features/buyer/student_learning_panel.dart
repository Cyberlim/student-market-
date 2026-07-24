import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/constants/colors.dart';
import '../ai_features/ai_panel.dart';

class StudentLearningPanel extends StatefulWidget {
  final Map<String, dynamic> note;

  const StudentLearningPanel({Key? key, required this.note}) : super(key: key);

  @override
  State<StudentLearningPanel> createState() => _StudentLearningPanelState();
}

class _StudentLearningPanelState extends State<StudentLearningPanel> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  
  void _openAIAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: const AIPanel(), // Currently AIPanel fetches notes itself.
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.note['title'] ?? 'Document';
    final fileUrl = widget.note['fileUrl'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPdf = fileUrl.toLowerCase().contains('.pdf');

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
            tooltip: 'AI Study Assistant',
            onPressed: _openAIAssistant,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Bookmark',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmark added!')));
            },
          ),
        ],
      ),
      body: isPdf
          ? SfPdfViewer.network(
              fileUrl,
              key: _pdfViewerKey,
              canShowScrollHead: false,
              canShowScrollStatus: false,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('This document cannot be previewed in-app.', style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAIAssistant,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text('Ask AI', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
