import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pdf_viewer_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  const NoteDetailScreen({Key? key, required this.noteId}) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  bool _isWishlisted = false;
  bool _isPurchased = false;
  bool _isFollowing = false;

  bool _previewStatusLoaded = false;
  bool _previewUsed = false;
  Map<String, dynamic>? _note;
  Map<String, dynamic> get _details => _note ?? _mockDetails;
  bool _isPhysical = false;
  late final Map<String, dynamic> _mockDetails;

  bool _loadingDetails = false;
  int _activePhysicalImageIndex = 0;
  int _userCoins = 0;

  bool get _isRealObjectId => !widget.noteId.startsWith('physical_') && !widget.noteId.startsWith('placeholder_');

  Future<void> _fetchNoteDetails() async {
    if (!_isRealObjectId) return;
    setState(() => _loadingDetails = true);
    try {
      final dio = Dio();
      final String baseUrl = backendBaseUrl;
      final response = await dio.get('$baseUrl/notes/${widget.noteId}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _note = response.data['data'];
          if (_note != null) {
            _isPhysical = _note!['itemType'] == 'Physical';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching note details: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingDetails = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _isPhysical = widget.noteId.startsWith('physical_');
    _mockDetails = _isPhysical ? {
      'title': 'Scientific Calculator FX-991EX',
      'category': 'Calculators',
      'price': 999,
      'condition': 'Like New',
      'seller': 'Rahul Sharma',
      'description': 'Barely used calculator. Good for engineering students. Comes with original box and manual.',
      'images': [
        'https://images.unsplash.com/photo-1574607383476-f517f260d30b?q=80&w=800',
        'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?q=80&w=800',
      ],
      'rating': '4.9',
      'downloads': 'N/A',
    } : {
      'title': 'Data Structures & Algorithms Lecture Notes',
      'college': 'IIT Bombay',
      'department': 'Computer Science',
      'subject': 'Data Structures',
      'teacher': 'Prof. Raghavan K.',
      'pages': '124',
      'rating': '4.8',
      'downloads': '1,248',
      'language': 'English',
      'uploadDate': '2026-06-15',
      'price': 199,
      'description': 'Comprehensive lecture notes covering Arrays, Linked Lists, Trees, Graphs, Sorting Algorithms, Dynamic Programming, and Complexity Analysis. Includes code snippets in C++ and Python, along with practice exam problems and solutions.',
    };
    _loadPreviewStatus();
    _fetchNoteDetails();
    _checkPurchaseStatus();
    _fetchUserCoins();
  }

  Future<void> _loadPreviewStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _previewUsed = prefs.getBool('preview_used_${widget.noteId}') ?? false;
      _previewStatusLoaded = true;
    });
  }

  Future<void> _markPreviewUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preview_used_${widget.noteId}', true);
    setState(() {
      _previewUsed = true;
    });
  }

  final List<Map<String, dynamic>> _relatedNotes = [
    {'title': 'DBMS Practical Lab Manual', 'price': '₹99', 'rating': '4.6', 'color': AppColors.secondary},
    {'title': 'Theory of Computation Guide', 'price': '₹149', 'rating': '4.9', 'color': AppColors.accent},
    {'title': 'Operating System Complete Notes', 'price': '₹199', 'rating': '4.7', 'color': AppColors.success},
  ];

  final List<Map<String, dynamic>> _reviews = [
    {'user': 'Aditya R.', 'rating': 5, 'comment': 'Excellent notes! The explanations for recursion and dynamic programming are top notch.', 'date': '2 days ago'},
    {'user': 'Sneha K.', 'rating': 4, 'comment': 'Very helpful for semester exams. Deducted one star because a few code snippets had typos.', 'date': '1 week ago'},
  ];

  void _showReportDialog() {
    String selectedReason = 'Plagiarism';
    final TextEditingController descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Report Content', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    items: ['Plagiarism', 'Inappropriate Content', 'Copyright Infringement', 'Incorrect Subject', 'Other']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedReason = val!);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe the issue in detail...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSnack('Dispute report submitted successfully. Review pending.');
                  },
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _checkPurchaseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) return;

      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/orders',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> orders = response.data['data'] ?? [];
        final hasPurchased = orders.any((order) {
          final noteObj = order['note'];
          if (noteObj == null) return false;
          final orderNoteId = noteObj is Map ? noteObj['_id'] : noteObj;
          return orderNoteId == widget.noteId;
        });
        if (hasPurchased) {
          setState(() {
            _isPurchased = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking order purchase status: $e');
    }
  }

  Future<void> _fetchUserCoins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) return;
      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _userCoins = (response.data['user']['coins'] ?? 0) as int;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user coins: $e');
    }
  }

  Future<List<dynamic>> _loadSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) return [];

      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/auth/addresses',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error loading checkout addresses: $e');
    }
    return [];
  }

  void _showPurchaseSheet() {
    if (_isPhysical) {
      _showAddressPickerSheet();
    } else {
      _showCheckoutSummarySheet(null);
    }
  }

  void _showAddressPickerSheet() async {
    List<dynamic> addresses = await _loadSavedAddresses();
    if (!mounted) return;

    Map<String, dynamic>? selectedAddress;
    if (addresses.isNotEmpty) {
      final defaultAddr = addresses.firstWhere((a) => a['isDefault'] == true, orElse: () => addresses.first);
      selectedAddress = Map<String, dynamic>.from(defaultAddr);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select Delivery Address',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  
                  if (addresses.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No saved addresses found. Please add a new address.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ] else ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: addresses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final addr = addresses[index];
                          final isSelected = selectedAddress != null && selectedAddress!['_id'] == addr['_id'];
                          return ListTile(
                            leading: Radio<String>(
                              value: addr['_id'].toString(),
                              groupValue: selectedAddress?['_id']?.toString(),
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setSheetState(() {
                                  selectedAddress = Map<String, dynamic>.from(addr);
                                });
                              },
                            ),
                            title: Text(addr['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(
                              '${addr['addressLine'] ?? ''}, ${addr['city'] ?? ''} - ${addr['pinCode'] ?? ''}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            selected: isSelected,
                            onTap: () {
                              setSheetState(() {
                                selectedAddress = Map<String, dynamic>.from(addr);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final router = GoRouter.of(this.context);
                      Navigator.pop(context);
                      await router.push('/profile/addresses');
                      _showAddressPickerSheet();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add / Manage Saved Addresses', style: TextStyle(fontSize: 12)),
                  ),
                  
                  const SizedBox(height: 20),
                  GradientButton(
                    text: 'Proceed to Payment',
                    onPressed: selectedAddress == null 
                      ? null 
                      : () {
                          Navigator.pop(context);
                          _showCheckoutSummarySheet(selectedAddress!);
                        },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCheckoutSummarySheet(Map<String, dynamic>? address) {
    final double priceVal = ((_details['price'] ?? 0) as num).toDouble();
    int selectedPercent = _userCoins >= priceVal ? 100 : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            int calculatedCoins = (priceVal * (selectedPercent / 100.0)).round();
            if (calculatedCoins > _userCoins) calculatedCoins = _userCoins;
            final double calculatedCash = (priceVal - calculatedCoins).clamp(0.0, priceVal);

            String buttonLabel;
            if (calculatedCash == 0) {
              buttonLabel = 'Pay $calculatedCoins Coins';
            } else if (calculatedCoins == 0) {
              buttonLabel = 'Pay ₹${calculatedCash.toStringAsFixed(0)} Cash';
            } else {
              buttonLabel = 'Pay ₹${calculatedCash.toStringAsFixed(0)} + $calculatedCoins Coins';
            }

            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: GlassCard(
                borderRadius: 30,
                blur: 20,
                opacity: 0.12,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Checkout Summary',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Item Cost'),
                        Text('₹${priceVal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (address != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping'),
                          const Text('Free', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 6),
                      Text('Deliver to:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                      Text('${address['fullName']} (${address['phoneNumber']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(
                        '${address['addressLine'] ?? ''}, ${address['city'] ?? ''} - ${address['pinCode'] ?? ''}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                    const Divider(height: 28),

                    // ── Coin Payment Selector ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Apply Wallet Coins', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                        Row(children: [
                          const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('$_userCoins available', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [0, 25, 50, 75, 100].map((pct) {
                        final bool canAfford = (priceVal * pct / 100).round() <= _userCoins;
                        final bool isSelected = selectedPercent == pct;
                        return GestureDetector(
                          onTap: canAfford
                              ? () => setSheetState(() => selectedPercent = pct)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(colors: [AppColors.primary, AppColors.secondary])
                                  : null,
                              color: isSelected ? null : (isDark ? Colors.white12 : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(color: Colors.transparent),
                            ),
                            child: Text(
                              '$pct%',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (canAfford ? (isDark ? Colors.white70 : Colors.black54) : Colors.grey.shade400),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // ── Payment Breakdown ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 15),
                                const SizedBox(width: 6),
                                const Text('Paid via Coins', style: TextStyle(fontSize: 13)),
                              ]),
                              Text('$calculatedCoins Coins',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                const Icon(Icons.currency_rupee_rounded, color: AppColors.primary, size: 15),
                                const SizedBox(width: 6),
                                const Text('Paid via Cash (₹)', style: TextStyle(fontSize: 13)),
                              ]),
                              Text('₹${calculatedCash.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '₹${priceVal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: buttonLabel,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveOrderToBackendWithSplit(address, calculatedCoins, calculatedCash);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveOrderToPrefs(Map<String, dynamic> backendOrder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getStringList('user_orders') ?? [];
      
      final dynamic rawImages = _details['images'];
      String? thumb;
      if (rawImages is List && rawImages.isNotEmpty) {
        thumb = rawImages.first.toString();
      } else {
        thumb = _details['thumbnailUrl'] ?? (_details['images'] is List && (_details['images'] as List).isNotEmpty ? _details['images'][0] : null);
      }

      final newOrder = {
        'id': backendOrder['_id'] ?? backendOrder['id'] ?? 'ORD-NEW-99',
        'title': _details['title'] ?? 'Untitled Item',
        'price': _details['price'] == 0 ? 'Free' : '₹${_details['price']}',
        'itemType': _isPhysical ? 'Physical' : 'Digital',
        'category': _isPhysical ? (_details['physicalCategory'] ?? 'Classified') : 'Notes',
        'sellerName': _details['seller']?['name'] ?? _details['teacher'] ?? 'Campus Seller',
        'thumbnailUrl': thumb ?? 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=120',
        'purchaseDate': DateTime.now().toIso8601String(),
        'status': backendOrder['status'] ?? 'Ordered',
      };
      
      ordersJson.insert(0, jsonEncode(newOrder));
      await prefs.setStringList('user_orders', ordersJson);
    } catch (e) {
      debugPrint('Error saving purchase order: $e');
    }
  }

  Future<void> _saveOrderToBackendWithSplit(
    Map<String, dynamic>? address,
    int coinsUsed,
    double cashPaid,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) {
        _showSnack('Please login to purchase items.');
        return;
      }

      final price = ((_details['price'] ?? 0) as num).toDouble();
      final dio = Dio();

      final response = await dio.post(
        '$backendBaseUrl/orders',
        data: {
          'noteId': widget.noteId,
          'price': price,
          'coinsUsed': coinsUsed,
          'cashPaid': cashPaid,
          'shippingAddress': address != null
              ? {
                  'fullName': address['fullName'],
                  'phoneNumber': address['phoneNumber'],
                  'addressLine': address['addressLine'],
                  'city': address['city'],
                  'state': address['state'],
                  'pinCode': address['pinCode'],
                }
              : null,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        setState(() {
          _isPurchased = true;
          _userCoins = (_userCoins - coinsUsed).clamp(0, _userCoins);
        });
        _showSnack('Order placed! Paid ₹${cashPaid.toStringAsFixed(0)} + $coinsUsed coins 🎉');

        await _saveOrderToPrefs(response.data['data']);

        if (_isPhysical && mounted) {
          context.push('/orders');
        }
      }
    } on DioException catch (dioErr) {
      final msg = dioErr.response?.data?['message'] ?? dioErr.message;
      _showSnack('Purchase failed: $msg');
    } catch (e) {
      _showSnack('Error placing order: $e');
    }
  }

  void _completePayment() {
    final double priceVal = ((_details['price'] ?? 0) as num).toDouble();
    final int coinsToUse = (_userCoins >= priceVal) ? priceVal.round() : _userCoins;
    final double cashToPay = (priceVal - coinsToUse).clamp(0.0, priceVal);
    _saveOrderToBackendWithSplit(null, coinsToUse, cashToPay);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: _isWishlisted ? AppColors.error : (isDark ? Colors.white : Colors.black),
            ),
            onPressed: () {
              setState(() {
                _isWishlisted = !_isWishlisted;
              });
              _showSnack(_isWishlisted ? 'Added to Wishlist' : 'Removed from Wishlist');
            },
          ),
          IconButton(
            icon: Icon(Icons.report_problem_outlined, color: isDark ? Colors.white : Colors.black),
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Preview
            _isPhysical ? _buildPhysicalPreview(isDark) : _buildPdfPreview(isDark),
            const SizedBox(height: 24),

            // Note Title & College
            Text(
              _details['title'] ?? 'Untitled',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _isPhysical
                  ? (_details['physicalCategory'] ?? '')
                  : '${_details['college'] ?? ''} • ${_details['department'] ?? ''}',
              style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // Metadata Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetaCell(Icons.star_rounded, (_details['averageRating'] ?? _details['rating'] ?? '4.8').toString(), 'Rating', Colors.amber),
                _buildMetaCell(Icons.pages_rounded, (_details['pages'] ?? '124').toString(), 'Pages', AppColors.primary),
                _buildMetaCell(Icons.download_rounded, (_details['downloadsCount'] ?? _details['downloads'] ?? '1,248').toString(), 'Downloads', AppColors.accent),
                _buildMetaCell(Icons.language_rounded, _details['language'] ?? 'English', 'Language', AppColors.success),
              ],
            ),
            const SizedBox(height: 24),

            // Seller Card
            _buildSellerCard(isDark),
            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _details['description'] ?? '',
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Frequently Bought Together Bundle
            _buildBundleSection(isDark),
            const SizedBox(height: 24),

            // Related Notes Section
            Text(
              'Related Study Notes',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRelatedNotesScroll(),
            const SizedBox(height: 24),

            // Reviews & Ratings Section
            Text(
              'Customer Reviews',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildReviewsSection(isDark),
            const SizedBox(height: 32),

            // Actions Buttons
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: _isPhysical
                        ? (_isPurchased ? 'Track Shipping Order' : 'Order Now')
                        : (_isPurchased ? 'Download PDF with Watermark' : 'Buy Now - ₹${_details['price'] ?? 0}'),
                    icon: _isPurchased
                        ? (_isPhysical ? Icons.local_shipping_rounded : Icons.download_rounded)
                        : Icons.shopping_bag_outlined,
                    onPressed: () {
                      if (_isPurchased) {
                        if (_isPhysical) {
                          context.push('/orders');
                        } else {
                          _showSnack('Downloading PDF...');
                        }
                      } else {
                        _showPurchaseSheet();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalPreview(bool isDark) {
    // Get images from the details object (falls back to _mockDetails['images'] if mock)
    final dynamic rawImages = _details['images'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    }
    
    // Fallback to thumbnailUrl if images array is empty but we have a thumbnailUrl
    if (images.isEmpty && _details['thumbnailUrl'] != null) {
      images.add(_details['thumbnailUrl'] as String);
    }

    if (images.isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported_rounded, size: 54, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _activePhysicalImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = images[index];
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? AppColors.surfaceDark : Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, size: 44, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
                // Frosted page tag (e.g. 1/3)
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_activePhysicalImageIndex + 1}/${images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 6.0,
                width: _activePhysicalImageIndex == index ? 18.0 : 6.0,
                decoration: BoxDecoration(
                  color: _activePhysicalImageIndex == index ? AppColors.primary : Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPdfPreview(bool isDark) {
    final thumbnail = _details['thumbnailUrl'] as String?;
    final title = _details['title'] as String? ?? _mockDetails['title'] as String? ?? 'Notes';
    final dept = _details['department'] as String? ?? _mockDetails['department'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Clean Hero Cover ──────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background: real thumbnail OR gradient fallback
              if (thumbnail != null && thumbnail.startsWith('http'))
                Image.network(
                  thumbnail,
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _gradientCover(title, dept),
                )
              else
                _gradientCover(title, dept),

              // Bottom frosted label strip
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('PDF', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),

        const SizedBox(height: 14),

        // ── Preview Button (shown only if preview not yet used) ──────────
        if (_previewStatusLoaded && !_previewUsed)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final fileUrl = _details['fileUrl'] as String?;
                if (fileUrl == null || fileUrl.isEmpty) {
                  _showSnack('No preview available for this note.');
                  return;
                }
                await _markPreviewUsed();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      pdfUrl: fileUrl,
                      title: '$title (Preview)',
                      maxPages: 3,
                      onBuyNow: _showPurchaseSheet,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chrome_reader_mode_outlined, size: 18),
              label: const Text('Read Free Preview (3 Pages)', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          )
        else if (_previewStatusLoaded && _previewUsed)
          // Show subtle chip instead of the big amber banner
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.success),
              const SizedBox(width: 6),
              const Text('Preview already viewed — ', style: TextStyle(fontSize: 12, color: Colors.grey)),
              GestureDetector(
                onTap: _showPurchaseSheet,
                child: Text('Buy now →', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
      ],
    );
  }

  // Helper: gradient cover when no thumbnail is available
  Widget _gradientCover(String title, String dept) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            if (dept.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(dept, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildMetaCell(IconData icon, String value, String title, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildSellerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=120'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mockDetails['teacher'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                const Text('Professor at CSE Dept', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isFollowing = !_isFollowing;
              });
              _showSnack(_isFollowing ? 'Following Professor Raghavan' : 'Unfollowed Professor Raghavan');
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_isFollowing ? 'Following' : '+ Follow', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Frequently Bought Together',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('• Data Structures Notes\n• DBMS Practical Lab Manual', style: TextStyle(fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bundle price:', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  const Text('₹249', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  _completePayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Buy Bundle'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRelatedNotesScroll() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _relatedNotes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final note = _relatedNotes[index];
          return GestureDetector(
            onTap: () => context.push('/notes/0'),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note['title'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(note['price'] as String, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          Text(note['rating'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection(bool isDark) {
    return Column(
      children: _reviews.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark.withOpacity(0.3) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r['user'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Row(
                    children: List.generate(
                      5,
                      (starIdx) => Icon(
                        Icons.star_rounded,
                        color: starIdx < (r['rating'] as int) ? Colors.amber : Colors.grey,
                        size: 14,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 6),
              Text(r['comment'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
