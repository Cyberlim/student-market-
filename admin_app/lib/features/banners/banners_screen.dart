import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import '../../core/constants/colors.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({Key? key}) : super(key: key);

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  List<dynamic> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() => _loading = true);
    try {
      final response = await AdminApiService.request('GET', '/api/banners/admin');
      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _banners = response.data['data'] ?? [];
        });
      } else {
        _snack('Failed to fetch banners.', kError);
      }
    } catch (e) {
      _snack('Error loading banners: $e', kError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBannerStatus(String id, bool currentStatus) async {
    try {
      final response = await AdminApiService.request(
        'PUT',
        '/api/banners/$id',
        data: {'isActive': !currentStatus},
      );
      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        _snack('Banner updated successfully.', kSuccess);
        _fetchBanners();
      } else {
        _snack('Failed to update banner status.', kError);
      }
    } catch (e) {
      _snack('Error: $e', kError);
    }
  }

  Future<void> _deleteBanner(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to permanently delete this banner?'),
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
      final response = await AdminApiService.request('DELETE', '/api/banners/$id');
      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        _snack('Banner deleted successfully.', kSuccess);
        _fetchBanners();
      } else {
        _snack('Failed to delete banner.', kError);
      }
    } catch (e) {
      _snack('Error: $e', kError);
    }
  }

  void _showAddBannerDialog() {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final tagCtrl = TextEditingController(text: 'FLASH DEAL');
    final discountCtrl = TextEditingController(text: '0');
    final bgImageCtrl = TextEditingController();
    final targetRouteCtrl = TextEditingController(text: '/ai-suite');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Create Promo Banner',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tagCtrl, decoration: const InputDecoration(labelText: 'Tag (e.g. FLASH DEAL, SPECIAL)')),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (e.g. 50% Off AI Credits)')),
                const SizedBox(height: 10),
                TextField(controller: subtitleCtrl, decoration: const InputDecoration(labelText: 'Subtitle')),
                const SizedBox(height: 10),
                TextField(
                  controller: discountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount Percent (optional)'),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                (() {
                  bool uploading = false;
                  return StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bgImageCtrl,
                              decoration: InputDecoration(
                                labelText: 'Background Image URL',
                                hintText: uploading ? 'Uploading...' : 'https://images.unsplash.com/...',
                                suffixIcon: uploading
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: uploading
                                ? null
                                : () async {
                                    setDialogState(() => uploading = true);
                                    final url = await AdminApiService.uploadImage();
                                    if (url != null) {
                                      bgImageCtrl.text = url;
                                      _snack('Image uploaded successfully!', kSuccess);
                                    }
                                    setDialogState(() => uploading = false);
                                  },
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary.withValues(alpha: 0.1),
                              foregroundColor: kPrimary,
                              elevation: 0,
                            ),
                          ),
                        ],
                      );
                    }
                  );
                })(),
                const SizedBox(height: 10),
                TextField(
                  controller: targetRouteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target App Route',
                    hintText: '/ai-suite, /store, or /search',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) {
                  _snack('Title is required', kError);
                  return;
                }
                Navigator.pop(context);
                try {
                  final response = await AdminApiService.request(
                    'POST',
                    '/api/banners',
                    data: {
                      'title': titleCtrl.text.trim(),
                      'subtitle': subtitleCtrl.text.trim(),
                      'tag': tagCtrl.text.trim(),
                      'discountPercent': int.tryParse(discountCtrl.text.trim()) ?? 0,
                      'bgImageUrl': bgImageCtrl.text.trim(),
                      'targetRoute': targetRouteCtrl.text.trim(),
                    },
                  );
                  if (response != null && response.statusCode == 201) {
                    _snack('Banner created successfully!', kSuccess);
                    _fetchBanners();
                  } else {
                    _snack('Failed to create banner.', kError);
                  }
                } catch (e) {
                  _snack('Error: $e', kError);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          'Banners Manager',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: kTextPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddBannerDialog,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('Add Banner', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _banners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.view_carousel_outlined, size: 64, color: kTextMuted.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('No promo banners created yet.',
                          style: GoogleFonts.inter(color: kTextMuted, fontSize: 15)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _showAddBannerDialog,
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                        child: const Text('Create Banner', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final gridCount = constraints.maxWidth > 800 ? 2 : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        final id = banner['_id'] ?? '';
                        final tag = banner['tag'] ?? 'PROMO';
                        final title = banner['title'] ?? 'Untitled';
                        final subtitle = banner['subtitle'] ?? '';
                        final discount = banner['discountPercent'] ?? 0;
                        final bgUrl = banner['bgImageUrl'] as String?;
                        final target = banner['targetRoute'] ?? '';
                        final active = banner['isActive'] ?? false;

                        return Container(
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                // Background preview (Image or dynamic gradient fallback)
                                Positioned.fill(
                                  child: bgUrl != null && bgUrl.startsWith('http')
                                      ? Image.network(
                                          bgUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _fallbackGradient(discount),
                                        )
                                      : _fallbackGradient(discount),
                                ),
                                // Gradient Overlay for readability
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.85),
                                          Colors.black.withOpacity(0.4),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ),
                                // Text details and switches
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                tag.toUpperCase(),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              title,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (subtitle.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                subtitle,
                                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Text(
                                              'Route: $target',
                                              style: const TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            children: [
                                              const Text('Active', style: TextStyle(color: Colors.white, fontSize: 12)),
                                              Switch(
                                                value: active,
                                                activeColor: kPrimary,
                                                onChanged: (val) => _toggleBannerStatus(id, active),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                            onPressed: () => _deleteBanner(id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  Widget _fallbackGradient(int discount) {
    final List<Color> colors = discount > 0
        ? [Colors.purple.shade800, Colors.pink.shade700]
        : [Colors.teal.shade800, Colors.cyan.shade700];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
