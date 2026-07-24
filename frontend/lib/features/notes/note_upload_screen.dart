import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/gradient_button.dart';

class NoteUploadScreen extends StatefulWidget {
  const NoteUploadScreen({Key? key}) : super(key: key);

  @override
  State<NoteUploadScreen> createState() => _NoteUploadScreenState();
}

class _NoteUploadScreenState extends State<NoteUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _collegeController = TextEditingController();
  final _subjectController = TextEditingController();
  final _priceController = TextEditingController();

  String _uploadType = 'Digital'; // 'Digital' (Study Material) or 'Physical' (Store Classifieds)
  String _physicalCategory = 'Calculators';
  String _itemCondition = 'Good';

  final List<String> _physicalCategories = [
    'Calculators',
    'Laptops',
    'Cycles',
    'Hostel furniture',
    'Lab coats',
    'Electronics'
  ];

  String _noteCategory = 'Notes';
  final List<String> _noteCategories = [
    'Notes',
    'Previous Year Paper',
    'Assignment',
    'Study Material',
    'Other'
  ];

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair'];

  bool _isFree = false;
  String? _selectedFileName;
  bool _isLoading = false;
  PlatformFile? _pickedFile;
  List<PlatformFile> _pickedImages = [];
  double _commissionRate = 10.0;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _fetchPlatformConfig();
  }

  Future<void> _fetchPlatformConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) return;
      final dio = Dio();
      final response = await dio.get(
        '$backendBaseUrl/admin/config',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            final rate = response.data['data']['platformCommissionRate'];
            _commissionRate = double.tryParse(rate.toString()) ?? 10.0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching platform config: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _collegeController.dispose();
    _subjectController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickRealFile() async {
    try {
      if (_uploadType == 'Digital') {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
        );
        if (result != null && result.files.isNotEmpty) {
          setState(() {
            _pickedFile = result.files.first;
            _selectedFileName = '${_pickedFile!.name} (${(_pickedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB)';
          });
        }
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );
        if (result != null && result.files.isNotEmpty) {
          setState(() {
            _pickedImages = result.files;
            _selectedFileName = '${_pickedImages.length} images selected';
          });
        }
      }
    } catch (e) {
      _showSnack('Error picking file: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_uploadType == 'Digital' && (_selectedFileName == null || _pickedFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_uploadType == 'Physical' && _pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image to upload'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) {
        throw Exception('User is not logged in. Please log in first.');
      }

      final dio = Dio();
      final String baseUrl = backendBaseUrl;

      // Prepare fields according to backend expectation:
      // digital notes: 'file' contains PDF/PPT
      // physical products: 'thumbnail' contains product image, 'images' contains array of photos
      final Map<String, dynamic> formDataMap = {
        'title': _titleController.text,
        'description': _descController.text,
        'price': _isFree ? '0' : _priceController.text,
        'itemType': _uploadType,
      };

      if (_uploadType == 'Digital') {
        MultipartFile filePayload;
        if (kIsWeb) {
          if (_pickedFile!.bytes == null) {
            throw Exception('File bytes are not available on Web platform.');
          }
          filePayload = MultipartFile.fromBytes(
            _pickedFile!.bytes!,
            filename: _pickedFile!.name,
          );
        } else {
          if (_pickedFile!.path == null) {
            throw Exception('File path is not available.');
          }
          final bytes = await File(_pickedFile!.path!).readAsBytes();
          filePayload = MultipartFile.fromBytes(
            bytes,
            filename: _pickedFile!.name,
          );
        }
        formDataMap['college'] = _collegeController.text;
        formDataMap['subject'] = _subjectController.text;
        formDataMap['department'] = 'General';
        formDataMap['semester'] = '1';
        formDataMap['category'] = _noteCategory;
        formDataMap['file'] = filePayload;
      } else {
        // Handle physical store images
        final List<MultipartFile> imagePayloads = [];
        for (final file in _pickedImages) {
          if (kIsWeb) {
            if (file.bytes != null) {
              imagePayloads.add(MultipartFile.fromBytes(file.bytes!, filename: file.name));
            }
          } else {
            if (file.path != null) {
              final bytes = await File(file.path!).readAsBytes();
              imagePayloads.add(MultipartFile.fromBytes(
                bytes,
                filename: file.name,
              ));
            }
          }
        }
        formDataMap['physicalCategory'] = _physicalCategory;
        formDataMap['itemCondition'] = _itemCondition;
        formDataMap['images'] = imagePayloads;
        
        // Also send first image as thumbnail for standard fallback using a new instance
        if (_pickedImages.isNotEmpty) {
          final firstFile = _pickedImages.first;
          Uint8List firstBytes;
          if (kIsWeb) {
            firstBytes = firstFile.bytes!;
          } else {
            firstBytes = await File(firstFile.path!).readAsBytes();
          }
          formDataMap['thumbnail'] = MultipartFile.fromBytes(
            firstBytes,
            filename: 'thumb_${firstFile.name}',
          );
        }
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await dio.post(
        '$baseUrl/notes',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_uploadType == 'Digital'
                  ? 'Note uploaded successfully! Pending admin approval.'
                  : 'Campus Store item posted successfully! Pending admin approval.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('Upload Error: $e');
      if (mounted) {
        String errorMsg = e.toString();
        if (e is DioException) {
          errorMsg = e.response?.data?['message'] ?? e.message ?? e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $errorMsg'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'List an Item',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Item Type Selector Switch
                Text(
                  'Item Type',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _uploadType = 'Digital';
                            _selectedFileName = null;
                            _pickedFile = null;
                            _pickedImages.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _uploadType == 'Digital' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '📚 Study Notes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _uploadType == 'Digital' ? Colors.white : Colors.grey,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _uploadType = 'Physical';
                            _selectedFileName = null;
                            _pickedFile = null;
                            _pickedImages.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _uploadType == 'Physical' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🎒 Campus Classifieds',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _uploadType == 'Physical' ? Colors.white : Colors.grey,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Upload Box
                GestureDetector(
                  onTap: _pickRealFile,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark.withOpacity(0.5) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedFileName == null
                                ? (_uploadType == 'Digital' ? Icons.upload_file_rounded : Icons.add_a_photo_rounded)
                                : Icons.task_rounded,
                            size: 44,
                            color: _selectedFileName == null ? AppColors.primary : AppColors.success,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFileName ??
                                (_uploadType == 'Digital'
                                    ? 'Tap to Select Study Material (PDF, PPT)'
                                    : 'Tap to Upload Item Images (JPG, PNG)'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _selectedFileName == null ? Colors.grey : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                const SizedBox(height: 24),

                // Form Section Header
                Text(
                  'Listing Details',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Title Input
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: _uploadType == 'Digital' ? 'Document Title' : 'Item Name',
                    prefixIcon: const Icon(Icons.title_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a title';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Input
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Details / Description',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter description details';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Dynamic inputs based on type
                if (_uploadType == 'Digital') ...[
                  // College
                  TextFormField(
                    controller: _collegeController,
                    decoration: const InputDecoration(
                      labelText: 'College Name',
                      prefixIcon: Icon(Icons.school_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter college';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Subject
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      prefixIcon: Icon(Icons.subject_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter subject';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Note Category Selection
                  DropdownButtonFormField<String>(
                    value: _noteCategory,
                    decoration: const InputDecoration(
                      labelText: 'Material Type',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: _noteCategories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _noteCategory = val);
                    },
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // Physical Category Selection
                  DropdownButtonFormField<String>(
                    value: _physicalCategory,
                    decoration: const InputDecoration(
                      labelText: 'Item Category',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: _physicalCategories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) => setState(() => _physicalCategory = val!),
                  ),
                  const SizedBox(height: 16),

                  // Condition Selection
                  DropdownButtonFormField<String>(
                    value: _itemCondition,
                    decoration: const InputDecoration(
                      labelText: 'Item Condition',
                      prefixIcon: Icon(Icons.thumb_up_rounded),
                    ),
                    items: _conditions
                        .map((cond) => DropdownMenuItem(value: cond, child: Text(cond)))
                        .toList(),
                    onChanged: (val) => setState(() => _itemCondition = val!),
                  ),
                  const SizedBox(height: 24),
                ],

                // Pricing Section
                Text(
                  'Pricing model',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Free / Giveaway'),
                      selected: _isFree,
                      selectedColor: AppColors.success.withOpacity(0.2),
                      onSelected: (val) {
                        setState(() {
                          _isFree = true;
                          _priceController.clear();
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      label: const Text('Set Price'),
                      selected: !_isFree,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      onSelected: (val) {
                        setState(() {
                          _isFree = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!_isFree) ...[
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (INR ₹)',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    validator: (value) {
                      if (!_isFree && (value == null || value.isEmpty)) {
                        return 'Please enter price';
                      }
                      if (int.tryParse(value ?? '') == null) {
                        return 'Price must be a valid number';
                      }
                      return null;
                    },
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final priceText = _priceController.text.trim();
                      final price = double.tryParse(priceText) ?? 0.0;
                      final fee = price * (_commissionRate / 100);
                      final earnings = price - fee;
                      if (price <= 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Listing Platform Fee (${_commissionRate.toStringAsFixed(0)}%):', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('₹${fee.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Your Estimated Earnings:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('₹${earnings.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 36),

                GradientButton(
                  text: 'Submit Product to Marketplace',
                  isLoading: _isLoading,
                  onPressed: _handleUpload,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
