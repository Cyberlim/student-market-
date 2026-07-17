import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/glass_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _loading = false;
  List<dynamic> _realItems = [];

  @override
  void initState() {
    super.initState();
    _fetchDatabaseData();
  }

  Future<void> _fetchDatabaseData() async {
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final String baseUrl = backendBaseUrl;
      final response = await dio.get('$baseUrl/notes');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _realItems = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading search database items: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  
  // Advanced Filter Parameters
  String _selectedCollege = 'All';
  String _selectedSubject = 'All';
  String _selectedDepartment = 'All';
  String _selectedLanguage = 'All';
  String _selectedSemester = 'All';
  String _selectedSort = 'Newest';
  double _minPrice = 0.0;
  double _maxPrice = 500.0;
  double _minRating = 0.0;

  bool _isListening = false;

  final List<String> _colleges = ['All', 'IIT Bombay', 'BITS Pilani', 'Delhi University', 'VIT University'];
  final List<String> _subjects = ['All', 'Computer Science', 'Electrical', 'Mechanical', 'Mathematics'];
  final List<String> _departments = ['All', 'CSE', 'ECE', 'Mechanical', 'Civil', 'Economics'];
  final List<String> _languages = ['All', 'English', 'Hindi', 'Tamil', 'Spanish'];
  final List<String> _semesters = ['All', '1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> _sortOptions = ['Newest', 'Popular', 'Rating', 'Price: Low to High', 'Price: High to Low'];

  bool _fuzzyMatch(String text, String query) {
    if (query.isEmpty) return true;
    text = text.toLowerCase();
    query = query.toLowerCase();
    
    // 1. Direct contains check
    if (text.contains(query)) return true;
    
    // 2. Word-by-word intersection check
    final queryWords = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (queryWords.isNotEmpty && queryWords.every((word) => text.contains(word))) return true;
    
    // 3. Subsequence fuzzy match (letters appear in order)
    int queryIdx = 0;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == query[queryIdx]) {
        queryIdx++;
        if (queryIdx == query.length) return true;
      }
    }
    
    return false;
  }

  List<dynamic> get _filteredNotes {
    final List<dynamic> allItems = _realItems;

    List<dynamic> results = allItems.where((item) {
      final title = (item['title'] ?? '').toString();
      final subject = (item['subject'] ?? '').toString();
      final college = (item['college'] ?? item['seller']?['name'] ?? '').toString();
      final department = (item['department'] ?? '').toString();
      final desc = (item['description'] ?? '').toString();
      final itemCondition = (item['itemCondition'] ?? '').toString();
      final physicalCategory = (item['physicalCategory'] ?? '').toString();

      final searchTarget = '$title $subject $college $department $desc $itemCondition $physicalCategory';
      final matchesSearch = _fuzzyMatch(searchTarget, _searchController.text);

      final matchesCollege = _selectedCollege == 'All' || college.toLowerCase().contains(_selectedCollege.toLowerCase());
      final matchesSubject = _selectedSubject == 'All' || subject.toLowerCase().contains(_selectedSubject.toLowerCase());
      final matchesDept = _selectedDepartment == 'All' || department.toLowerCase().contains(_selectedDepartment.toLowerCase());
      
      final language = (item['language'] ?? 'English').toString();
      final matchesLang = _selectedLanguage == 'All' || language.toLowerCase().contains(_selectedLanguage.toLowerCase());
      
      final semester = (item['semester'] ?? 'All').toString();
      final matchesSem = _selectedSemester == 'All' || semester.toLowerCase().contains(_selectedSemester.toLowerCase());
      
      final double price = ((item['price'] ?? 0) as num).toDouble();
      final matchesPrice = price >= _minPrice && price <= _maxPrice;
      
      final double rating = ((item['rating'] ?? 0.0) as num).toDouble();
      final matchesRating = rating >= _minRating;

      return matchesSearch && matchesCollege && matchesSubject && matchesDept && matchesLang && matchesSem && matchesPrice && matchesRating;
    }).toList();

    // Sorting logic
    if (_selectedSort == 'Newest') {
      results.sort((a, b) {
        final idA = a['_id'] ?? a['id'] ?? '';
        final idB = b['_id'] ?? b['id'] ?? '';
        return idB.toString().compareTo(idA.toString());
      });
    } else if (_selectedSort == 'Popular') {
      results.sort((a, b) {
        final downloadsA = a['downloads'] ?? 0;
        final downloadsB = b['downloads'] ?? 0;
        return downloadsB.compareTo(downloadsA);
      });
    } else if (_selectedSort == 'Rating') {
      results.sort((a, b) {
        final ratingA = a['rating'] ?? 0.0;
        final ratingB = b['rating'] ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
    } else if (_selectedSort == 'Price: Low to High') {
      results.sort((a, b) {
        final priceA = a['price'] ?? 0;
        final priceB = b['price'] ?? 0;
        return priceA.compareTo(priceB);
      });
    } else if (_selectedSort == 'Price: High to Low') {
      results.sort((a, b) {
        final priceA = a['price'] ?? 0;
        final priceB = b['price'] ?? 0;
        return priceB.compareTo(priceA);
      });
    }

    return results;
  }

  void _triggerVoiceSearch() {
    setState(() => _isListening = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isListening = false;
          _searchController.text = 'Data Structures';
        });
        _showSnack('Voice search identified: "Data Structures"');
      }
    });
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

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sheetDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: sheetDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Sorting Selector
                    Text('Sort By', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildSheetDropdown('Sorting Options', _selectedSort, _sortOptions, (val) {
                      setSheetState(() => _selectedSort = val!);
                      setState(() {});
                    }),
                    const SizedBox(height: 20),
                    // College
                    Text('College', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildSheetDropdown('Colleges', _selectedCollege, _colleges, (val) {
                      setSheetState(() => _selectedCollege = val!);
                      setState(() {});
                    }),
                    const SizedBox(height: 20),
                    // Department
                    Text('Department', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildSheetDropdown('Departments', _selectedDepartment, _departments, (val) {
                      setSheetState(() => _selectedDepartment = val!);
                      setState(() {});
                    }),
                    const SizedBox(height: 20),
                    // Semester
                    Text('Semester', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildSheetDropdown('Semesters', _selectedSemester, _semesters, (val) {
                      setSheetState(() => _selectedSemester = val!);
                      setState(() {});
                    }),
                    const SizedBox(height: 20),
                    // Language
                    Text('Language', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildSheetDropdown('Languages', _selectedLanguage, _languages, (val) {
                      setSheetState(() => _selectedLanguage = val!);
                      setState(() {});
                    }),
                    const SizedBox(height: 20),
                    // Price Range Slider
                    Text('Price Range (Coins/₹)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                    RangeSlider(
                      values: RangeValues(_minPrice, _maxPrice),
                      min: 0,
                      max: 500,
                      divisions: 50,
                      activeColor: AppColors.primary,
                      labels: RangeLabels('₹${_minPrice.round()}', '₹${_maxPrice.round()}'),
                      onChanged: (RangeValues val) {
                        setSheetState(() {
                          _minPrice = val.start;
                          _maxPrice = val.end;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Apply Filters', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetDropdown(String label, String selected, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          onChanged: onChanged,
          isExpanded: true,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Marketplace Search',
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search & Voice Trigger Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search notes, files, subjects...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _triggerVoiceSearch,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.mic_rounded, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filters toggle & Quick chips
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openFiltersSheet,
                        icon: const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                        label: Text('Filters', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_selectedCollege != 'All')
                                _buildFilterChip('College: $_selectedCollege', () => setState(() => _selectedCollege = 'All')),
                              if (_selectedDepartment != 'All')
                                _buildFilterChip('Dept: $_selectedDepartment', () => setState(() => _selectedDepartment = 'All')),
                              if (_selectedSemester != 'All')
                                _buildFilterChip('Sem: $_selectedSemester', () => setState(() => _selectedSemester = 'All')),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Search Results (${results.length})',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // Results Grid
                  Expanded(
                    child: results.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final note = results[index];
                              return _buildNoteCard(context, note, isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
            
            // Voice Listening Overlay Sheet
            if (_isListening)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: GlassCard(
                      borderRadius: 24,
                      opacity: 0.1,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mic_rounded, color: Colors.white, size: 64)
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .scale(duration: 500.ms, begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
                          const SizedBox(height: 24),
                          Text('Listening...', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Say notes subject or college name', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        deleteIcon: const Icon(Icons.close, size: 10),
        onDeleted: onDeleted,
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, dynamic note, bool isDark) {
    final id = note['_id'] ?? note['id'] ?? '';
    final price = ((note['price'] ?? 0) as num).toDouble();
    final priceStr = price == 0 ? 'Free' : '₹${price.toStringAsFixed(0)}';
    
    final color = note['color'] as Color? ?? AppColors.primary;
    final thumbnailUrl = note['thumbnailUrl'] as String?;
    final hasThumbnail = thumbnailUrl != null && thumbnailUrl.startsWith('http');
    
    final title = (note['title'] ?? 'Untitled').toString();
    final college = (note['college'] ?? note['seller']?['name'] ?? 'General').toString();
    final pages = note['pages'] ?? 'N/A';
    final semester = note['semester'] ?? '1';
    final rating = note['rating'] ?? 0.0;
    final downloads = note['downloads'] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/notes/$id'),
      child: GlassCard(
        borderRadius: 20,
        opacity: 0.04,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasThumbnail
                    ? Image.network(
                        thumbnailUrl,
                        width: 80,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.description, color: Colors.white, size: 32),
                      )
                    : const Icon(Icons.description, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$college • $pages Pages • Sem-$semester',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: price > 0 ? AppColors.primary : AppColors.success,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '$rating',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($downloads dl)',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
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
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No Results Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters or query terms.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
