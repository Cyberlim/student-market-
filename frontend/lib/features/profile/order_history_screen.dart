import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/glass_card.dart';
import '../../core/utils/file_download_helper.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _userRole = 'Student';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final List<Map<String, dynamic>> combinedOrders = [];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      if (token.isNotEmpty) {
        _userRole = prefs.getString('user_role') ?? 'Student';
        final dio = Dio();
        final response = await dio.get(
          '$backendBaseUrl/orders',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          final List<dynamic> realData = response.data['data'] ?? [];
          for (var item in realData) {
            final noteObj = item['note'] ?? {};
            final sellerObj = noteObj['seller'] ?? {};
            combinedOrders.add({
              'id': item['_id'] ?? item['id'] ?? 'ORD-DB',
              'title': noteObj['title'] ?? 'Notes/Item',
              'price': '₹${item['price'] ?? 0}',
              'itemType': noteObj['itemType'] ?? 'Digital',
              'category': noteObj['physicalCategory'] ?? 'Classified',
              'sellerName': sellerObj['name'] ?? 'Campus Seller',
              'thumbnailUrl': noteObj['thumbnailUrl'] ?? '',
              'fileUrl': noteObj['fileUrl'] ?? '',
              'purchaseDate': item['createdAt'] ?? DateTime.now().toIso8601String(),
              'status': item['status'] ?? 'Ordered',
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading remote database orders: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getStringList('user_orders') ?? [];
      for (var s in ordersJson) {
        final mockOrder = jsonDecode(s) as Map<String, dynamic>;
        // Avoid duplicates if already populated by database
        if (!combinedOrders.any((o) => o['id'] == mockOrder['id'])) {
          combinedOrders.add(mockOrder);
        }
      }
      
      if (combinedOrders.isEmpty) {
        final mockOrders = [
          {
            'id': 'ORD-89304-X7',
            'title': 'High-performance Drafter Scale & T-Square',
            'price': '₹450',
            'itemType': 'Physical',
            'category': 'Drawing Instruments',
            'sellerName': 'Sneha Rao (Sem-5)',
            'thumbnailUrl': 'https://images.unsplash.com/photo-1509062522246-3755977927d7?q=80&w=120',
            'purchaseDate': DateTime.now().subtract(const Duration(hours: 36)).toIso8601String(),
            'status': 'Out for Delivery',
          },
          {
            'id': 'ORD-72901-B2',
            'title': 'Engineering Physics Cycle 1 lab manual',
            'price': '₹99',
            'itemType': 'Digital',
            'category': 'Notes',
            'sellerName': 'Prof. Raghavan',
            'thumbnailUrl': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=120',
            'purchaseDate': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
            'status': 'Delivered',
          },
        ];
        combinedOrders.addAll(mockOrders);
        await prefs.setStringList('user_orders', mockOrders.map((o) => jsonEncode(o)).toList());
      }
    } catch (e) {
      debugPrint('Error merging mock orders: $e');
    }

    setState(() {
      _orders = combinedOrders;
      _loading = false;
    });
  }

  Future<void> _advanceTracking(int index) async {
    final order = _orders[index];
    final orderId = order['id'].toString();
    if (order['itemType'] != 'Physical') return;
    
    final currentStatus = order['status'] ?? 'Ordered';
    String nextStatus = currentStatus;
    
    if (currentStatus == 'Ordered' || currentStatus == 'Pending') {
      nextStatus = 'Dispatched';
    } else if (currentStatus == 'Dispatched') {
      nextStatus = 'Out for Delivery';
    } else if (currentStatus == 'Out for Delivery') {
      nextStatus = 'Delivered';
    } else {
      nextStatus = 'Ordered'; // Loop back for review testing
    }

    setState(() {
      _orders[index]['status'] = nextStatus;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      // Update local storage
      final ordersJson = prefs.getStringList('user_orders') ?? [];
      final localIdx = ordersJson.indexWhere((s) => jsonDecode(s)['id'] == orderId);
      if (localIdx != -1) {
        final Map<String, dynamic> localOrder = jsonDecode(ordersJson[localIdx]);
        localOrder['status'] = nextStatus;
        ordersJson[localIdx] = jsonEncode(localOrder);
        await prefs.setStringList('user_orders', ordersJson);
      }

      if (token.isNotEmpty) {
        final dio = Dio();
        await dio.put(
          '$backendBaseUrl/orders/$orderId/status',
          data: {'status': nextStatus},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      debugPrint('Error updating tracking status in backend: $e');
    }

    _showSnack('Order Status updated to $nextStatus');
  }

  Future<void> _downloadFile(String fileUrl, String title, String noteId) async {
    await FileDownloadHelper.downloadAndOpen(fileUrl, title, noteId, _showSnack);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Purchase Orders',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _orders.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order, index, isDark);
                  },
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index, bool isDark) {
    final isPhysical = order['itemType'] == 'Physical';
    final status = order['status'] ?? 'Ordered';
    final dateStr = order['purchaseDate'] != null 
        ? order['purchaseDate'].substring(0, 10) 
        : 'N/A';

    return GlassCard(
      borderRadius: 20,
      opacity: 0.04,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Date Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['id'] ?? 'ORD-NEW-99',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Image and Title Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  order['thumbnailUrl'] ?? 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=120',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.withOpacity(0.2),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['title'] ?? 'Product Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seller: ${order['sellerName'] ?? 'Anonymous'} • ${order['price']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tracking Section for Physical Products
          if (isPhysical) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Shipment Tracking Status',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildTrackingTimeline(status),
            const SizedBox(height: 12),
            if (_userRole == 'Admin')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _advanceTracking(index),
                  icon: const Icon(Icons.local_shipping_rounded, size: 14),
                  label: const Text('Update Delivery Step', style: TextStyle(fontSize: 11)),
                ),
              ),
          ] else ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                    SizedBox(width: 6),
                    Text('Access Authorized', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success)),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    final noteObj = order['note'];
                    final noteId = noteObj is Map ? noteObj['_id'] ?? '' : noteObj.toString();
                    _downloadFile(order['fileUrl'] ?? '', order['title'] ?? 'Note', noteId);
                  },
                  child: const Text('Download Note PDF', style: TextStyle(fontSize: 12)),
                )
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline(String currentStatus) {
    final stages = ['Ordered', 'Dispatched', 'Out for Delivery', 'Delivered'];
    final currentIdx = stages.indexOf(currentStatus);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isCompleted = index <= currentIdx;
        final isCurrent = index == currentIdx;

        return Expanded(
          child: Row(
            children: [
              // Circle Node
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.primary : Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppColors.accent, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle,
                        size: isCompleted ? 12 : 6,
                        color: isCompleted ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stage == 'Out for Delivery' ? 'Out' : stage,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
              // Connecting Line
              if (index < stages.length - 1)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      height: 2,
                      color: index < currentIdx
                          ? AppColors.primary
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No Orders Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Your purchase logs will appear here.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
