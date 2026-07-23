import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndLoad();
  }

  Future<void> _downloadAndLoad() async {
    try {
      // Download the PDF to a temp file
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: kTextPrimary),
                overflow: TextOverflow.ellipsis),
            if (_totalPages > 0)
              Text('Page ${_currentPage + 1} of $_totalPages',
                  style: GoogleFonts.inter(fontSize: 11, color: kTextMuted)),
          ],
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kPrimary),
                  const SizedBox(height: 16),
                  Text('Loading PDF…', style: GoogleFonts.inter(color: kTextMuted)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: kError, size: 48),
                        const SizedBox(height: 12),
                        Text('Failed to load PDF', style: GoogleFonts.inter(color: kTextPrimary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(_error!, style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : PDFView(
                  filePath: _localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  onRender: (pages) => setState(() => _totalPages = pages ?? 0),
                  onPageChanged: (page, _) => setState(() => _currentPage = page ?? 0),
                  onError: (error) => setState(() => _error = error.toString()),
                  onPageError: (page, error) => debugPrint('Page $page error: $error'),
                ),
    );
  }
}
