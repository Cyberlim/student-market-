import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import '../../core/constants/colors.dart';
import 'pdf_viewer_screen.dart';

class NotesAuditScreen extends StatefulWidget {
  const NotesAuditScreen({super.key});

  @override
  State<NotesAuditScreen> createState() => _NotesAuditScreenState();
}

class _NotesAuditScreenState extends State<NotesAuditScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _queue = [];
  bool _loading = false;
  late TabController _tabController;

  // Filtered lists
  List<Map<String, dynamic>> get _digitalNotes =>
      _queue.where((n) => n['itemType'] == 'Digital').toList();
  List<Map<String, dynamic>> get _campusItems =>
      _queue.where((n) => n['itemType'] == 'Physical').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingItems() async {
    setState(() => _loading = true);
    try {
      final response = await AdminApiService.request('GET', '/api/admin/notes/pending');
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _queue = data.map<Map<String, dynamic>>((item) {
            final seller = item['seller'] ?? {};
            return {
              'id': item['_id'] ?? '',
              'title': item['title'] ?? 'Untitled',
              'author': seller['name'] ?? 'Anonymous',
              'college': item['college'] ?? '',
              'price': item['price'] == 0 ? 'Free' : '₹${item['price']}',
              'date': item['createdAt'] != null
                  ? (item['createdAt'] as String).substring(0, 10)
                  : 'N/A',
              'itemType': item['itemType'] ?? 'Digital',
              'physicalCategory': item['physicalCategory'] ?? '',
              'itemCondition': item['itemCondition'] ?? '',
              'description': item['description'] ?? '',
              'thumbnailUrl': item['thumbnailUrl'] ?? '',
              'images': item['images'] ?? [],
              'fileUrl': item['fileUrl'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading pending items: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> item, String status) async {
    final noteId = item['id'] as String;
    final isApprove = status == 'Approved';
    try {
      final response = await AdminApiService.request(
        'PUT',
        '/api/notes/$noteId/status',
        data: {'status': status},
      );
      if (response != null && response.statusCode == 200) {
        _snack('Note status updated to $status.', kSuccess);
        _loadPendingItems();
      } else {
        _snack('Failed to update status.', kError);
      }
    } catch (e) {
      _snack('Error: $e', kError);
    }
  }

  Future<void> _deleteNote(Map<String, dynamic> item) async {
    final noteId = item['id'];
    if (noteId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to permanently delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: kError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await AdminApiService.request(
        'DELETE',
        '/api/notes/$noteId',
      );
      if (response != null && response.statusCode == 200) {
        _snack('Note deleted successfully.', kSuccess);
        _loadPendingItems();
      } else {
        _snack('Failed to delete note.', kError);
      }
    } catch (e) {
      _snack('Error: $e', kError);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, isMobile ? 16 : 28, isMobile ? 16 : 28, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Approval Queue',
                          style: GoogleFonts.inter(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 16 : 18)),
                      const SizedBox(height: 4),
                      Text('Review notes & campus store items before they go live.',
                          style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
                    ],
                  ),
                ),
                // Refresh button
                IconButton(
                  onPressed: _loadPendingItems,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kWarning))
                      : const Icon(Icons.refresh_rounded, color: kTextMuted, size: 20),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kWarning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kWarning.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.pending_actions_rounded, color: kWarning, size: 13),
                    const SizedBox(width: 6),
                    Text('${_queue.length} Pending',
                        style: GoogleFonts.inter(
                            color: kWarning, fontWeight: FontWeight.bold, fontSize: 12)),
                  ]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
            child: Container(
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
                ),
                labelColor: kPrimary,
                unselectedLabelColor: kTextMuted,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'All (${_queue.length})'),
                  Tab(text: '📚 Notes (${_digitalNotes.length})'),
                  Tab(text: '🛒 Campus (${_campusItems.length})'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_queue, isMobile),
                _buildList(_digitalNotes, isMobile),
                _buildList(_campusItems, isMobile),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool isMobile) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (items.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 0, isMobile ? 16 : 28, 24),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        final isPhysical = item['itemType'] == 'Physical';
        return _ItemCard(
          item: item,
          isPhysical: isPhysical,
          index: i,
          onApprove: () => _updateStatus(item, 'Approved'),
          onReject: () => _updateStatus(item, 'Rejected'),
          onDelete: () => _deleteNote(item),
        ).animate().fadeIn(duration: 280.ms, delay: (i * 50).ms);
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(vertical: 56),
        decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline_rounded, color: kSuccess, size: 44),
          const SizedBox(height: 14),
          Text('All Clear',
              style: GoogleFonts.inter(
                  color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text('Nothing awaiting review in this category.',
              style: GoogleFonts.inter(color: kTextMuted, fontSize: 13)),
        ]),
      ).animate().fadeIn(),
    );
  }
}

// ── Item Card (handles both Digital Notes and Physical Campus Items) ──────────
class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isPhysical;
  final VoidCallback onApprove, onReject, onDelete;
  final int index;

  const _ItemCard({
    required this.item,
    required this.isPhysical,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isPhysical ? const Color(0xFF2196F3) : kError;
    final IconData typeIcon = isPhysical ? Icons.storefront_rounded : Icons.picture_as_pdf_rounded;
    final String typeLabel = isPhysical ? 'Campus Store' : 'Digital Note';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + title + type badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(typeIcon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(typeLabel,
                              style: GoogleFonts.inter(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: kWarning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('PENDING',
                              style: GoogleFonts.inter(
                                  color: kWarning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item['price'] == 'Free'
                      ? kSuccess.withValues(alpha: 0.12)
                      : kTextPrimary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item['price'] as String,
                    style: GoogleFonts.inter(
                        color: item['price'] == 'Free' ? kSuccess : kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: kBorder, height: 1),
          const SizedBox(height: 10),

          // Details grid
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _infoChip(Icons.person_outline_rounded, item['author'] as String),
              if (!isPhysical && (item['college'] as String).isNotEmpty)
                _infoChip(Icons.school_outlined, item['college'] as String),
              if (isPhysical && (item['physicalCategory'] as String).isNotEmpty)
                _infoChip(Icons.category_outlined, item['physicalCategory'] as String),
              if (isPhysical && (item['itemCondition'] as String).isNotEmpty)
                _infoChip(Icons.star_outline_rounded, item['itemCondition'] as String),
              _infoChip(Icons.calendar_today_outlined, item['date'] as String),
            ],
          ),

          if ((item['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item['description'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: kTextMuted, fontSize: 11)),
          ],

          // 🖼️ Review Attachments (PDF document cover or physical item images)
          if (isPhysical) ...[
            if (item['images'] != null && (item['images'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Product Photos (${(item['images'] as List).length})',
                  style: GoogleFonts.inter(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 6),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (item['images'] as List).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final imgUrl = item['images'][index].toString();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imgUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: kBorder.withValues(alpha: 0.5),
                          child: const Icon(Icons.broken_image_rounded, size: 20, color: kTextMuted),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]
          ] else ...[
            if ((item['thumbnailUrl'] as String).startsWith('http')) ...[
              const SizedBox(height: 12),
              Text('Document Preview (Page 1 Cover)',
                  style: GoogleFonts.inter(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['thumbnailUrl'] as String,
                  height: 120,
                  width: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 8),
              if (item['fileUrl'] != null && (item['fileUrl'] as String).isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                        final pdfUrl = item['fileUrl'] as String;
                        final title = item['title'] as String;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(url: pdfUrl, title: title),
                          ),
                        );
                      },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: Text('View Full PDF', style: GoogleFonts.inter(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimary,
                      side: const BorderSide(color: kPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
            ]
          ],

          const SizedBox(height: 14),

          // Action buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 15),
                label: Text('Reject', style: GoogleFonts.inter(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kWarning,
                  side: const BorderSide(color: kWarning),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded, size: 15),
                label: Text('Approve', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccess,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, size: 15),
                label: Text('Delete', style: GoogleFonts.inter(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kError,
                  side: const BorderSide(color: kError),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kTextMuted),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.inter(color: kTextMuted, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ],
      );
}
