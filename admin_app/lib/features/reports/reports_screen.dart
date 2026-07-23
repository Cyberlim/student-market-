import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import '../../core/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApiService.request('GET', '/api/admin/reports');
      if (res != null && res.data['success'] == true) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(res.data['data']);
        });
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final res = await AdminApiService.request('PUT', '/api/admin/reports/$id/status', data: {'status': status});
      if (res != null && res.data['success'] == true) {
        _fetchReports();
      }
    } catch (e) {
      debugPrint('Error updating report status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text('User Reports', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: kSurface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _reports.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_rounded, size: 60, color: kTextMuted),
          const SizedBox(height: 16),
          Text('No Reports', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('All clear! There are no pending reports.', style: GoogleFonts.inter(color: kTextMuted)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        final isPending = report['status'] == 'Pending';

        return Card(
          color: kSurface,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending ? kWarning.withValues(alpha: 0.1) : kSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report['status'] ?? 'Unknown',
                        style: GoogleFonts.inter(
                          color: isPending ? kWarning : kSuccess,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      report['createdAt'] != null
                          ? DateTime.parse(report['createdAt']).toLocal().toString().split(' ')[0]
                          : '',
                      style: GoogleFonts.inter(fontSize: 12, color: kTextMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Reason: ${report['reason']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                if (report['details'] != null && (report['details'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(report['details'], style: GoogleFonts.inter(color: kTextMuted)),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text('Reported Content', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (report['note'] != null) ...[
                  Text('Note: ${report['note']['title']}', style: GoogleFonts.inter(color: kPrimary)),
                ],
                const SizedBox(height: 16),
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(report['_id'], 'Dismissed'),
                          style: OutlinedButton.styleFrom(foregroundColor: kTextMuted),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(report['_id'], 'Action Taken'),
                          style: ElevatedButton.styleFrom(backgroundColor: kError),
                          child: const Text('Take Action / Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms);
      },
    );
  }
}
