import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  /// If set, only renders the first [maxPages] pages and shows a locked overlay after.
  /// null = show all pages (purchased/full access)
  final int? maxPages;
  /// Called when user taps "Buy Now" inside the preview lock screen
  final VoidCallback? onBuyNow;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.maxPages,
    this.onBuyNow,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// Builds a self-contained HTML page that uses PDF.js to render the PDF.
  /// When [maxPages] is set, only pages 1–maxPages are rendered, followed by
  /// a "Buy Now" locked overlay for the remaining pages.
  String _buildPdfJsHtml() {
    final max = widget.maxPages ?? 0; // 0 = unlimited
    final escapedUrl = widget.pdfUrl.replaceAll("'", "\\'");

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
  <title>${widget.title}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: #e8e8e8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }

    #loading {
      position: fixed; inset: 0; background: #f5f5f5;
      display: flex; flex-direction: column; align-items: center; justify-content: center; z-index: 100;
    }
    .spinner {
      width: 48px; height: 48px; border: 4px solid #eee;
      border-top-color: #6C63FF; border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    #loading p { margin-top: 16px; color: #666; font-size: 14px; }

    #pdf-container { padding: 12px 8px; }
    .page-wrapper { margin-bottom: 12px; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.18); }
    canvas { display: block; width: 100%; height: auto; }
    .page-label {
      background: rgba(0,0,0,0.55); color: #fff; font-size: 11px;
      padding: 3px 10px; text-align: center;
    }

    /* Gradient fade before the lock card */
    #fade-overlay {
      display: none;
      height: 80px;
      background: linear-gradient(to bottom, transparent, #e8e8e8);
      margin-top: -80px;
      position: relative; z-index: 5;
    }

    /* Lock card */
    #locked-card {
      display: none;
      margin: 0 12px 32px;
      background: white; border-radius: 20px;
      padding: 32px 24px; text-align: center;
      box-shadow: 0 4px 24px rgba(0,0,0,0.12);
      position: relative; z-index: 6;
    }
    .lock-emoji { font-size: 52px; }
    .lock-title { font-size: 20px; font-weight: 700; color: #1a1a2e; margin: 14px 0 8px; }
    .lock-desc { font-size: 13px; color: #888; line-height: 1.5; margin-bottom: 24px; }
    .buy-btn {
      background: linear-gradient(135deg, #6C63FF, #7B2FBE);
      color: white; border: none; padding: 15px 40px;
      border-radius: 14px; font-size: 16px; font-weight: 700;
      cursor: pointer; width: 100%;
      box-shadow: 0 4px 16px rgba(108,99,255,0.4);
    }
    .buy-btn:active { opacity: 0.85; }
    .preview-badge {
      display: inline-block; background: #FFF3E0; color: #E65100;
      font-size: 11px; font-weight: 600; border-radius: 20px;
      padding: 4px 12px; margin-bottom: 16px; letter-spacing: 0.5px;
    }
  </style>
</head>
<body>

<div id="loading">
  <div class="spinner"></div>
  <p>Loading preview...</p>
</div>

<div id="pdf-container"></div>
<div id="fade-overlay"></div>
<div id="locked-card">
  <div class="lock-emoji">🔒</div>
  <div class="lock-title">Preview Ended</div>
  <div class="preview-badge">FREE PREVIEW · 3 PAGES</div>
  <div class="lock-desc">
    You've viewed the free preview.<br>
    Purchase to unlock all pages and download.
  </div>
  <button class="buy-btn" onclick="BuyNow.postMessage('buy')">
    🛒 Buy Now to Unlock All Pages
  </button>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
<script>
  pdfjsLib.GlobalWorkerOptions.workerSrc =
    'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

  const MAX_PAGES = $max;   // 0 = render all pages
  const PDF_URL   = '$escapedUrl';

  async function renderPdf() {
    try {
      const loadingTask = pdfjsLib.getDocument({ url: PDF_URL, withCredentials: false });
      const pdf = await loadingTask.promise;
      const total = pdf.numPages;
      const limit = (MAX_PAGES > 0) ? Math.min(MAX_PAGES, total) : total;

      const container = document.getElementById('pdf-container');

      for (let i = 1; i <= limit; i++) {
        const page = await pdf.getPage(i);
        const baseVp = page.getViewport({ scale: 1 });
        const scale  = (window.innerWidth - 16) / baseVp.width;
        const vp     = page.getViewport({ scale });

        const wrapper = document.createElement('div');
        wrapper.className = 'page-wrapper';

        const label = document.createElement('div');
        label.className = 'page-label';
        label.textContent = 'Page ' + i + ' of ' + (MAX_PAGES > 0 ? MAX_PAGES : total);
        wrapper.appendChild(label);

        const canvas  = document.createElement('canvas');
        canvas.width  = vp.width;
        canvas.height = vp.height;
        wrapper.appendChild(canvas);
        container.appendChild(wrapper);

        await page.render({ canvasContext: canvas.getContext('2d'), viewport: vp }).promise;
      }

      // Show lock overlay when preview is limited
      if (MAX_PAGES > 0 && total > MAX_PAGES) {
        document.getElementById('fade-overlay').style.display = 'block';
        document.getElementById('locked-card').style.display  = 'block';
      }
    } catch (err) {
      document.getElementById('pdf-container').innerHTML =
        '<p style="padding:40px;color:#c00;text-align:center">Failed to load PDF.<br>' + err.message + '</p>';
    } finally {
      document.getElementById('loading').style.display = 'none';
    }
  }

  renderPdf();
</script>
</body>
</html>
''';
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _isLoading = true; _hasError = false; });
          },
          onProgress: (p) {
            if (mounted) setState(() { _loadingProgress = p; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() { _isLoading = false; });
          },
          onWebResourceError: (e) {
            debugPrint('WebView error: ${e.description}');
            // PDF.js handles errors internally; don't show full-screen error for resource issues
          },
        ),
      )
      ..addJavaScriptChannel(
        'BuyNow',
        onMessageReceived: (_) {
          Navigator.pop(context);
          widget.onBuyNow?.call();
        },
      );

    if (widget.maxPages != null) {
      // Preview mode: render via PDF.js with hard page cap
      _controller.loadHtmlString(_buildPdfJsHtml());
    } else {
      // Full access: use Google Docs viewer (unlimited)
      final encoded = Uri.encodeComponent(widget.pdfUrl);
      _controller.loadRequest(
        Uri.parse('https://docs.google.com/gview?embedded=true&url=$encoded'),
      );
    }
  }

  void _reload() {
    setState(() { _isLoading = true; _hasError = false; });
    _initWebView();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPreview = widget.maxPages != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Row(
              children: [
                Text(
                  isPreview ? 'Free Preview · 3 pages' : 'PDF Document',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                ),
                if (isPreview) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PREVIEW',
                      style: GoogleFonts.poppins(
                          fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    value: _loadingProgress / 100,
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: isDark ? Colors.white70 : Colors.black54),
              onPressed: _reload,
            ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: _hasError ? _buildErrorView() : WebViewWidget(controller: _controller),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded,
                size: 72, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: 20),
            Text('Could not load PDF',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('The document might be loading slowly.\nTap retry to try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Retry', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
