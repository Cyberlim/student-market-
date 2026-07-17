import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  final List<Map<String, dynamic>> _disputes = [
    {
      'id': 'D-001',
      'type': 'Plagiarism',
      'title': 'OS Notes by Ramesh Gupta',
      'reporter': 'Ananya Singh',
      'date': '29 Jun 2026',
      'description': 'These notes are copied word-for-word from the Silberschatz textbook without citation.',
      'resolved': false,
    },
    {
      'id': 'D-002',
      'type': 'Incorrect Content',
      'title': 'Physics Wave Optics Summary',
      'reporter': 'Kiran Patel',
      'date': '28 Jun 2026',
      'description': 'Several formulas in this document are incorrect and misleading.',
      'resolved': false,
    },
    {
      'id': 'D-003',
      'type': 'Spam / Fake',
      'title': 'Quick Exam Tips & Tricks',
      'reporter': 'Dev Kumar',
      'date': '27 Jun 2026',
      'description': 'This document contains only 2 pages but was listed as 40 pages. Very misleading.',
      'resolved': true,
    },
    {
      'id': 'D-004',
      'type': 'Inappropriate',
      'title': 'Engineering Memes Collection',
      'reporter': 'Priya Sharma',
      'date': '26 Jun 2026',
      'description': 'This is not a study material — it contains inappropriate meme images.',
      'resolved': false,
    },
  ];

  void _resolve(int i) {
    setState(() => _disputes[i]['resolved'] = true);
    _snack('Dispute marked as resolved.', kSuccess);
  }

  void _removeContent(int i) {
    setState(() => _disputes.removeAt(i));
    _snack('Content removed and reporter notified.', kError);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Plagiarism':     return kError;
      case 'Incorrect Content': return kWarning;
      case 'Spam / Fake':   return const Color(0xFFE879F9);
      default:              return kTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final open   = _disputes.where((d) => !d['resolved']).length;
    final closed = _disputes.where((d) =>  d['resolved']).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (isMobile) ...[
                Text('Disputes & Reports',
                    style: GoogleFonts.inter(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text('Review flagged content reports submitted by users.',
                    style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
                const SizedBox(height: 10),
                Row(children: [
                  _Badge('$open Open', kError),
                  const SizedBox(width: 10),
                  _Badge('$closed Resolved', kSuccess),
                ]),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Disputes & Reports',
                              style: GoogleFonts.inter(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          const SizedBox(height: 4),
                          Text('Review flagged content reports submitted by users.',
                              style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    _Badge('$open Open', kError),
                    const SizedBox(width: 10),
                    _Badge('$closed Resolved', kSuccess),
                  ],
                ),
              const SizedBox(height: 24),

              // Cards
              ...List.generate(_disputes.length, (i) {
                final d = _disputes[i];
                final resolved = d['resolved'] as bool;
                final typeColor = _typeColor(d['type']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: resolved ? kBorder : kError.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row — wraps on mobile
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(d['id'],
                              style: GoogleFonts.jetBrainsMono(
                                  color: kTextMuted, fontSize: 11)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: typeColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(d['type'],
                                style: GoogleFonts.inter(
                                    color: typeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: (resolved ? kSuccess : kWarning)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(resolved ? 'Resolved' : 'Open',
                                style: GoogleFonts.inter(
                                    color: resolved ? kSuccess : kWarning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ),
                          Text(d['date'],
                              style: GoogleFonts.inter(
                                  color: kTextMuted, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(d['title'],
                          style: GoogleFonts.inter(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Reported by: ${d['reporter']}',
                          style: GoogleFonts.inter(
                              color: kPrimary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(d['description'],
                          style: GoogleFonts.inter(
                              color: kTextMuted, fontSize: 13, height: 1.5)),
                      if (!resolved) ...[
                        const SizedBox(height: 14),
                        const Divider(color: kBorder),
                        const SizedBox(height: 10),
                        // Action buttons — full width on mobile
                        isMobile
                            ? Column(children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _resolve(i),
                                    icon: const Icon(Icons.check_rounded,
                                        size: 14, color: kSuccess),
                                    label: Text('Mark Resolved',
                                        style: GoogleFonts.inter(
                                            color: kSuccess, fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: kSuccess),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _removeContent(i),
                                    icon: const Icon(Icons.delete_rounded,
                                        size: 14, color: Colors.white),
                                    label: Text('Remove Content',
                                        style: GoogleFonts.inter(
                                            color: Colors.white, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kError,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ])
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _resolve(i),
                                    icon: const Icon(Icons.check_rounded,
                                        size: 14, color: kSuccess),
                                    label: Text('Mark Resolved',
                                        style: GoogleFonts.inter(
                                            color: kSuccess, fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: kSuccess),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => _removeContent(i),
                                    icon: const Icon(Icons.delete_rounded,
                                        size: 14, color: Colors.white),
                                    label: Text('Remove Content',
                                        style: GoogleFonts.inter(
                                            color: Colors.white, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kError,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: (i * 60).ms);
              }),
            ],
          ),
        );
      },
    );

  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
