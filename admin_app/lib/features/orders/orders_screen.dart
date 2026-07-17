import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import '../../core/constants/colors.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String _typeFilter = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    try {
      final response = await AdminApiService.request('GET', '/api/orders/admin');
      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _orders = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin orders: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      final response = await AdminApiService.request(
        'PUT',
        '/api/orders/$orderId/status',
        data: {'status': newStatus},
      );
      if (response != null && response.statusCode == 200) {
        _snack('Order status updated to $newStatus successfully.', kSuccess);
        _fetchOrders();
      } else {
        _snack('Failed to update order status.', kError);
      }
    } catch (e) {
      _snack('Error: $e', kError);
    }
  }

  Future<void> _setPickupDate(String orderId) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Select Pickup Date',
    );
    if (picked == null) return;
    try {
      final response = await AdminApiService.request(
        'PUT',
        '/api/orders/$orderId/pickup',
        data: {'pickupDate': picked.toIso8601String()},
      );
      if (response != null && response.statusCode == 200) {
        _snack('Pickup date set to ${picked.day}/${picked.month}/${picked.year}', kSuccess);
        _fetchOrders();
      } else {
        _snack('Failed to set pickup date.', kError);
      }
    } catch (e) {
      _snack('Error setting pickup date: $e', kError);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return kWarning;
      case 'dispatched':
        return Colors.blue;
      case 'out for delivery':
        return Colors.purple;
      case 'delivered':
      case 'completed':
        return kSuccess;
      default:
        return kTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final pad = isMobile ? 16.0 : 28.0;

        List<dynamic> filtered = _orders.where((o) {
          final note = o['note'] ?? {};
          final itemType = note['itemType'] ?? 'Digital';
          final status = o['status'] ?? 'Pending';
          bool matchesType = _typeFilter == 'All' ||
              itemType.toString().toLowerCase() == _typeFilter.toLowerCase();
          bool matchesStatus = _statusFilter == 'All' ||
              status.toString().toLowerCase() == _statusFilter.toLowerCase();
          return matchesType && matchesStatus;
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              if (isMobile) ...[
                Text(
                  'Order & Shipping',
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track transactions and shipping updates.',
                  style: GoogleFonts.inter(color: kTextMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _fetchOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSurface,
                      foregroundColor: kTextPrimary,
                      side: const BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                  ),
                ),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order & Shipping Management',
                            style: GoogleFonts.inter(
                              color: kTextPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track transactions and advance shipping updates for physical campus goods.',
                            style: GoogleFonts.inter(color: kTextMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSurface,
                        foregroundColor: kTextPrimary,
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // ── Filters ──
              if (isMobile)
                Column(
                  children: [
                    _buildDropdown(
                      label: 'Item Type',
                      value: _typeFilter,
                      items: ['All', 'Physical', 'Digital'],
                      onChanged: (v) => setState(() => _typeFilter = v!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Status',
                      value: _statusFilter,
                      items: ['All', 'Pending', 'Dispatched', 'Out for Delivery', 'Delivered', 'Completed'],
                      onChanged: (v) => setState(() => _statusFilter = v!),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    _buildDropdown(
                      label: 'Item Type',
                      value: _typeFilter,
                      items: ['All', 'Physical', 'Digital'],
                      onChanged: (v) => setState(() => _typeFilter = v!),
                    ),
                    const SizedBox(width: 16),
                    _buildDropdown(
                      label: 'Status',
                      value: _statusFilter,
                      items: ['All', 'Pending', 'Dispatched', 'Out for Delivery', 'Delivered', 'Completed'],
                      onChanged: (v) => setState(() => _statusFilter = v!),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // ── Order Cards ──
              if (_loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: kPrimary)))
              else if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 48, color: kTextMuted),
                      const SizedBox(height: 12),
                      Text('No orders found matching the filter criteria.',
                          style: GoogleFonts.inter(color: kTextMuted, fontSize: 14)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    final orderId = order['_id'] ?? order['id'] ?? '';
                    final buyer = order['buyer'] ?? {};
                    final note = order['note'] ?? {};
                    final status = order['status'] ?? 'Pending';
                    final isPhysical = note['itemType'] == 'Physical';
                    final price = order['price'] ?? 0;
                    final dateStr = order['createdAt'] != null
                        ? DateTime.parse(order['createdAt']).toLocal().toString().substring(0, 16)
                        : 'Unknown Date';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: icon + details
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isPhysical
                                      ? Colors.blue.withValues(alpha: 0.12)
                                      : kPrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPhysical
                                      ? Icons.local_shipping_rounded
                                      : Icons.download_rounded,
                                  color: isPhysical ? Colors.blue : kPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Invoice + Status in same row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Invoice: ${order['invoiceNumber'] ?? 'INV-UNKNOWN'}',
                                            style: GoogleFonts.inter(
                                                color: kTextMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status,
                                            style: GoogleFonts.inter(
                                              color: _statusColor(status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      note['title'] ?? 'Untitled Item',
                                      style: GoogleFonts.inter(
                                          color: kTextPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Buyer: ${buyer['name'] ?? 'Guest'} · ${buyer['email'] ?? ''}',
                                      style: GoogleFonts.inter(color: kTextMuted, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Purchased: $dateStr',
                                      style: GoogleFonts.inter(color: kTextMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Shipping address if physical
                          if (isPhysical && order['shippingAddress'] != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: kBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.pin_drop_outlined,
                                        size: 13, color: Colors.blue),
                                    const SizedBox(width: 5),
                                    Text('SHIPPING ADDRESS',
                                        style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order['shippingAddress']['fullName']} (${order['shippingAddress']['phoneNumber']})',
                                    style: GoogleFonts.inter(
                                        color: kTextPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${order['shippingAddress']['addressLine']}, ${order['shippingAddress']['city']} - ${order['shippingAddress']['pinCode']}',
                                    style: GoogleFonts.inter(color: kTextMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Price + Action buttons (stacked on mobile)
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹$price',
                                style: GoogleFonts.inter(
                                    color: kPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (isPhysical && status.toLowerCase() != 'delivered') ...[
                                Flexible(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          String next = 'Pending';
                                          if (status.toLowerCase() == 'pending') {
                                            next = 'Dispatched';
                                          } else if (status.toLowerCase() == 'dispatched') {
                                            next = 'Out for Delivery';
                                          } else if (status.toLowerCase() == 'out for delivery') {
                                            next = 'Delivered';
                                          }
                                          _updateStatus(orderId, next);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6)),
                                        ),
                                        child: Text(
                                          status.toLowerCase() == 'pending'
                                              ? 'Dispatch'
                                              : (status.toLowerCase() == 'dispatched'
                                                  ? 'Out for Delivery'
                                                  : 'Delivered'),
                                          style: GoogleFonts.inter(
                                              fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Builder(builder: (ctx) {
                                        final rawPickup = order['pickupDate'];
                                        String pickupLabel = '📅 Set Date';
                                        if (rawPickup != null) {
                                          try {
                                            final dt = DateTime.parse(rawPickup.toString())
                                                .toLocal();
                                            pickupLabel =
                                                '📅 ${dt.day}/${dt.month}/${dt.year}';
                                          } catch (_) {}
                                        }
                                        return OutlinedButton(
                                          onPressed: () => _setPickupDate(orderId),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.teal,
                                            side: const BorderSide(color: Colors.teal),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: Text(pickupLabel,
                                              style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: kTextMuted, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: kSurface,
              style: GoogleFonts.inter(color: kTextPrimary, fontSize: 13),
              icon: const Icon(Icons.arrow_drop_down, color: kTextMuted),
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
