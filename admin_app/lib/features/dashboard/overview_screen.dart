import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api_service.dart';
import '../../core/constants/colors.dart';

const double kSidebarBreakpoint = 700;

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {
    'totalRevenue': 0,
    'totalUsers': 0,
    'pendingAudits': 0,
    'reportedIssues': 0,
  };
  Map<String, dynamic> _health = {
    'database': 'Checking...',
    'cdn': 'Checking...',
    'gateway': 'Checking...',
  };
  List<double> _trends = [0, 0, 0, 0, 0, 0, 0];
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final response = await AdminApiService.request('GET', '/api/admin/stats');
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        setState(() {
          _stats = Map<String, dynamic>.from(response.data['stats'] ?? {});
          if (response.data['health'] != null) {
            _health = Map<String, dynamic>.from(response.data['health']);
          }
          if (response.data['trends'] != null) {
            _trends = (response.data['trends'] as List).map((e) => (e as num).toDouble()).toList();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < kSidebarBreakpoint;
        if (_loading) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimary),
          );
        }
        return RefreshIndicator(
          onRefresh: _loadStats,
          color: kPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI cards
                isMobile ? _mobileKpiGrid() : _desktopKpiRow(),
                const SizedBox(height: 24),

                // Charts
                isMobile
                    ? Column(children: [_revenueChart(), const SizedBox(height: 16), _healthPanel()])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _revenueChart()),
                          const SizedBox(width: 20),
                          Expanded(child: _healthPanel()),
                        ],
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  // KPI rows ──────────────────────────────────────────────────────────────
  Widget _desktopKpiRow() => Row(
        children: [
          _KpiCard('Total Revenue',    '₹${_stats['totalRevenue'] ?? 0}', 'platform commission', Icons.account_balance_wallet_rounded, kPrimary,  true),
          const SizedBox(width: 16),
          _KpiCard('Registered Users', '${_stats['totalUsers'] ?? 0}',    'all time',           Icons.groups_rounded,                 kSuccess,  true),
          const SizedBox(width: 16),
          _KpiCard('Pending Audits',   '${_stats['pendingAudits'] ?? 0}', 'action needed',      Icons.fact_check_rounded,             kWarning,  false),
          const SizedBox(width: 16),
          _KpiCard('Open Disputes',    '${_stats['reportedIssues'] ?? 0}','needs review',       Icons.report_problem_rounded,         kError,    false),
        ],
      );

  Widget _mobileKpiGrid() => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _KpiCardCompact('Revenue',  '₹${_stats['totalRevenue'] ?? 0}', Icons.account_balance_wallet_rounded, kPrimary),
          _KpiCardCompact('Users',    '${_stats['totalUsers'] ?? 0}',    Icons.groups_rounded,                 kSuccess),
          _KpiCardCompact('Audits',   '${_stats['pendingAudits'] ?? 0}', Icons.fact_check_rounded,             kWarning),
          _KpiCardCompact('Disputes', '${_stats['reportedIssues'] ?? 0}',Icons.report_problem_rounded,         kError),
        ],
      );

  // Revenue chart ──────────────────────────────────────────────────────────
  Widget _revenueChart() => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader('Revenue Trends', 'Weekly platform commission'),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: kBorder, strokeWidth: 1),
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          '₹${(v / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(color: kTextMuted, fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          const d = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return v.toInt() >= 0 && v.toInt() < 7
                              ? Text(d[v.toInt()],
                                  style: const TextStyle(color: kTextMuted, fontSize: 10))
                              : const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < _trends.length; i++)
                          FlSpot(i.toDouble(), _trends[i])
                      ],
                      isCurved: true,
                      gradient: const LinearGradient(colors: [kPrimary, Color(0xFF7C3AED)]),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                            radius: 3, color: kPrimary, strokeWidth: 2, strokeColor: kSurface),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            kPrimary.withValues(alpha: 0.18),
                            kPrimary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms);

  // Health panel ────────────────────────────────────────────────────────────
  Widget _healthPanel() => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader('System Health', 'Live infrastructure status'),
            const SizedBox(height: 16),
            _HealthRow('MongoDB Atlas',    _health['database'] ?? 'Unknown',  _health['database'] == 'Online'),
            _HealthRow('Cloudinary CDN',   _health['cdn'] ?? 'Unknown',       _health['cdn'] == 'Online'),
            _HealthRow('Razorpay Gateway', _health['gateway'] ?? 'Unknown',   _health['gateway'] == 'Online'),
            _HealthRow('API Latency',      '24 ms',   true),
          ],
        ),
      ).animate().fadeIn(duration: 450.ms);
}

// ─────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label, value, delta;
  final IconData icon;
  final Color color;
  final bool positive;
  const _KpiCard(this.label, this.value, this.delta, this.icon, this.color, this.positive);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _Card(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(color: kTextMuted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: GoogleFonts.inter(
                          color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(delta,
                      style: GoogleFonts.inter(
                          color: positive ? kSuccess : kWarning, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

class _KpiCardCompact extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiCardCompact(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: GoogleFonts.inter(color: kTextMuted, fontSize: 11)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: child,
      );
}

class _CardHeader extends StatelessWidget {
  final String title, subtitle;
  const _CardHeader(this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 3),
          Text(subtitle, style: GoogleFonts.inter(color: kTextMuted, fontSize: 11)),
        ],
      );
}

class _HealthRow extends StatelessWidget {
  final String label, status;
  final bool ok;
  const _HealthRow(this.label, this.status, this.ok);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
            Row(children: [
              Text(status,
                  style: GoogleFonts.inter(
                      color: ok ? kSuccess : kTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              if (ok) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, color: kSuccess, size: 11),
              ],
            ]),
          ],
        ),
      );
}
