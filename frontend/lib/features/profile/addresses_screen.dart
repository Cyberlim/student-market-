import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({Key? key}) : super(key: key);

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<dynamic> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/auth/addresses',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _addresses = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addAddress(Map<String, dynamic> addressData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final dio = Dio();
      final response = await dio.post(
        '$backendBaseUrl/auth/addresses',
        data: addressData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _showSnack('Address added successfully');
        _fetchAddresses();
      }
    } catch (e) {
      _showSnack('Failed to save address: $e');
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final dio = Dio();
      final response = await dio.delete(
        '$backendBaseUrl/auth/addresses/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _showSnack('Address deleted successfully');
        _fetchAddresses();
      }
    } catch (e) {
      _showSnack('Error deleting address: $e');
    }
  }

  void _showAddAddressSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Shipping Address',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addrCtrl,
                      decoration: const InputDecoration(labelText: 'Address Line / Hostel / Room'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(labelText: 'City'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: stateCtrl,
                            decoration: const InputDecoration(labelText: 'State'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pinCtrl,
                      decoration: const InputDecoration(labelText: 'Pin Code'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setCheckState) {
                        return CheckboxListTile(
                          title: const Text('Set as Default Address', style: TextStyle(fontSize: 13)),
                          value: isDefault,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setCheckState(() => isDefault = val!);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: 'Save Address',
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          _addAddress({
                            'fullName': nameCtrl.text,
                            'phoneNumber': phoneCtrl.text,
                            'addressLine': nameCtrl.text + ' - ' + addrCtrl.text, // combine name and address to keep unique details
                            'city': cityCtrl.text,
                            'state': stateCtrl.text,
                            'pinCode': pinCtrl.text,
                            'isDefault': isDefault,
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Addresses',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _addresses.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final addr = _addresses[index];
                    final isDefault = addr['isDefault'] ?? false;
                    return GlassCard(
                      borderRadius: 16,
                      opacity: 0.04,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: isDefault ? AppColors.primary : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      addr['fullName'] ?? '',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('DEFAULT', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${addr['addressLine'] ?? ''}\n${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['pinCode'] ?? ''}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Phone: ${addr['phoneNumber'] ?? ''}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            onPressed: () => _deleteAddress(addr['_id'] ?? ''),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAddressSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 72, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No Addresses Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Tap "+" to add your delivery details.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
