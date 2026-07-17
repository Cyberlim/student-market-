import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/glass_card.dart';

// ─── Coins Scoring Widget ─────────────────────────────────────────────────
class CoinsScoringWidget extends StatefulWidget {
  final int coins;
  const CoinsScoringWidget({Key? key, required this.coins}) : super(key: key);

  @override
  State<CoinsScoringWidget> createState() => _CoinsScoringWidgetState();
}

class _CoinsScoringWidgetState extends State<CoinsScoringWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.bounceIn)), weight: 60),
    ]).animate(_controller);
    _spinAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCirc),
    );
    
    // Auto trigger animation on mount
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CoinsScoringWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coins != widget.coins) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    return GestureDetector(
      onTap: () => _controller.forward(from: 0.0),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return GlassCard(
            borderRadius: 20,
            opacity: 0.12,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 4 : 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _spinAnimation.value,
                    child: Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.amber,
                      size: isCompact ? 16 : 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.coins} Coins',
                  style: GoogleFonts.poppins(
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: _controller.isAnimating
                        ? [
                            const Shadow(
                              blurRadius: 10,
                              color: Colors.amber,
                            )
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── HomeScreen State ──────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _followedSellers = {};
  final Set<String> _bookmarkedItems = {};
  String _selectedCategory = 'All';
  String _currentMarketTab = 'Digital'; // 'Digital' (Notes) or 'Physical' (Store)

  bool _loading = false;
  List<dynamic> _realNotes = [];
  List<dynamic> _realPhysicalProducts = [];
  List<dynamic> _realBanners = [];
  String _userName = 'Alok';
  String _userAvatar = 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=120';
  String _configAppName = 'EduMarket';
  String _configAppLogoUrl = '';

  PageController? _bannerPageController;
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? '';
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        final fullName = prefs.getString('user_name') ?? 'Alok';
        _userName = fullName.split(' ').first;
        _userAvatar = prefs.getString('user_avatar') ?? 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=120';
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _fetchDatabaseData() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final String baseUrl = backendBaseUrl;
      final token = await _getToken();

      // 1. Fetch Digital Notes
      try {
        final notesRes = await dio.get('$baseUrl/notes', queryParameters: {'itemType': 'Digital'});
        if (notesRes.statusCode == 200 && notesRes.data['success'] == true) {
          _realNotes = notesRes.data['data'] ?? [];
        }
      } catch (e) {
        debugPrint('Error fetching digital notes: $e');
      }

      // 2. Fetch Physical Store Products
      try {
        final physicalRes = await dio.get('$baseUrl/notes', queryParameters: {'itemType': 'Physical'});
        if (physicalRes.statusCode == 200 && physicalRes.data['success'] == true) {
          _realPhysicalProducts = physicalRes.data['data'] ?? [];
        }
      } catch (e) {
        debugPrint('Error fetching physical products: $e');
      }

      // 3. Fetch Active Banners
      try {
        final bannersRes = await dio.get('$baseUrl/banners');
        if (bannersRes.statusCode == 200 && bannersRes.data['success'] == true) {
          _realBanners = bannersRes.data['data'] ?? [];
          _startBannerTimer();
        }
      } catch (e) {
        debugPrint('Error fetching banners: $e');
      }

      // 4. Fetch Config Branding
      try {
        final configRes = await dio.get(
          '$baseUrl/admin/config',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        if (configRes.statusCode == 200 && configRes.data['success'] == true) {
          final cfg = configRes.data['data'] ?? {};
          _configAppName = cfg['appName'] ?? 'EduMarket';
          _configAppLogoUrl = cfg['appLogoUrl'] ?? '';
        }
      } catch (e) {
        debugPrint('Error fetching config branding: $e');
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error fetching database data: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  late ScrollController _scrollController;
  bool _showFloatingSearchBar = false;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(initialPage: 0);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadUserProfile();
    _fetchDatabaseData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController?.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!mounted) return;
    final currentOffset = _scrollController.offset;
    
    // Show floating search bar when scrolling down, hide when scrolling up
    if (currentOffset <= 120) {
      if (_showFloatingSearchBar) {
        setState(() {
          _showFloatingSearchBar = false;
        });
      }
    } else if (currentOffset > _lastScrollOffset) {
      // Scroll Down -> Show search bar
      if (!_showFloatingSearchBar) {
        setState(() {
          _showFloatingSearchBar = true;
        });
      }
    } else if (currentOffset < _lastScrollOffset) {
      // Scroll Up -> Hide search bar
      if (_showFloatingSearchBar) {
        setState(() {
          _showFloatingSearchBar = false;
        });
      }
    }
    _lastScrollOffset = currentOffset;
  }

  final List<String> _digitalCategories = [
    'All',
    'Notes',
    'Previous Year Papers',
    'Assignments',
    'Lab Manuals',
    'Practical Files',
    'PPTs',
    'Project Reports',
    'Cheat Sheets',
    'Research Papers'
  ];

  final List<String> _physicalCategories = [
    'All',
    'Calculators',
    'Laptops',
    'Cycles',
    'Hostel furniture',
    'Lab coats',
    'Electronics'
  ];



  void _toggleFollow(String name) {
    setState(() {
      if (_followedSellers.contains(name)) {
        _followedSellers.remove(name);
        _showSnack('Unfollowed $name');
      } else {
        _followedSellers.add(name);
        _showSnack('Followed $name');
      }
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300) {
            // Swipe Left -> Show Physical Classifieds
            if (_currentMarketTab == 'Digital') {
              setState(() {
                _currentMarketTab = 'Physical';
                _selectedCategory = _physicalCategories[0];
              });
            }
          } else if (details.primaryVelocity! > 300) {
            // Swipe Right -> Show Digital Study Materials
            if (_currentMarketTab == 'Physical') {
              setState(() {
                _currentMarketTab = 'Digital';
                _selectedCategory = _digitalCategories[0];
              });
            }
          }
        },
        child: Stack(
          children: [
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _fetchDatabaseData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Redesigned Floating Premium Top Bar Header
                      _buildRedesignedTopBar(context),
                      const SizedBox(height: 24),
  
                      // Interactive Search
                      _buildSearchHero(context, isDark),
                      const SizedBox(height: 28),
  
                      // Segment Switcher: Digital Study Materials vs Physical Classifieds
                      _buildMarketTabSwitcher(),
                      const SizedBox(height: 24),
  
                      // Category list based on active tab
                      Text(
                        _currentMarketTab == 'Digital' ? 'Study Categories' : 'Campus Store Categories',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      _buildCategorySelector(),
                      const SizedBox(height: 28),
  
                      // Conditional lists rendering
                      if (_currentMarketTab == 'Digital') ...[
                        // Featured Notes Slider
                        _buildSectionHeader(context, '⭐ Featured Notes', () => context.push('/search')),
                        const SizedBox(height: 12),
                        _buildNotesScrollList(context, isFeatured: true),
                        const SizedBox(height: 28),
  
                        // Dynamic Promos Carousel
                        _buildBannersCarousel(context),
                        const SizedBox(height: 28),
  
                        // Trending Notes Slider
                        _buildSectionHeader(context, '🔥 Trending Notes', () => context.push('/search')),
                        const SizedBox(height: 12),
                        _buildNotesScrollList(context, isTrending: true),
                        const SizedBox(height: 28),
  
                        Builder(
                          builder: (context) {
                            final sellersList = _getDynamicSellers();
                            if (sellersList.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(context, '👑 Top Sellers', () {}),
                                const SizedBox(height: 12),
                                _buildTopSellersList(sellersList),
                                const SizedBox(height: 28),
                              ],
                            );
                          },
                        ),
                      ] else ...[
                        // Physical Products Grid / List
                        _buildSectionHeader(context, '🎒 Featured Classifieds', () => context.push('/search')),
                        const SizedBox(height: 12),
                        _buildPhysicalProductsList(context),
                        const SizedBox(height: 28),
  
                        // Campus Deals Banner
                        _realBanners.length > 1
                            ? _buildDynamicBanner(context, _realBanners[1])
                            : _buildClassifiedsPromoCard(context),
                        const SizedBox(height: 28),
                      ],
  
                      // Recommended Notes
                      _buildSectionHeader(context, '🎯 Recommended for you', () => context.push('/search')),
                      const SizedBox(height: 12),
                      _buildNotesScrollList(context, isRecommended: true),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
  
            // Dynamic Floating search bar: slides down when scrolling down, hides when scrolling up
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              top: _showFloatingSearchBar ? MediaQuery.of(context).padding.top + 16 : -150.0,
              left: 20,
              right: 20,
              child: _buildFloatingSearchHero(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Redesigned Top Bar Header with Coins Scoring Animation
  Widget _buildRedesignedTopBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _configAppLogoUrl.startsWith('http')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            _configAppLogoUrl,
                            width: isCompact ? 16 : 18,
                            height: isCompact ? 16 : 18,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.school_rounded, color: Colors.white, size: isCompact ? 16 : 18),
                          ),
                        )
                      : Icon(Icons.school_rounded, color: Colors.white, size: isCompact ? 16 : 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _configAppName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 12 : 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        isCompact ? _userName : 'Welcome back, $_userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 9 : 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Coins tracker with scoring animation
              const CoinsScoringWidget(coins: 450),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: CircleAvatar(
                    radius: isCompact ? 13 : 15,
                    backgroundImage: NetworkImage(_userAvatar),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHero(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => context.push('/search'),
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        opacity: 0.05,
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentMarketTab == 'Digital'
                    ? 'Search by college, subject, teacher...'
                    : 'Search laptops, cycles, calculator models...',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  // Floating sticky search bar overlay
  Widget _buildFloatingSearchHero(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/search'),
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          opacity: isDark ? 0.15 : 0.08,
          blur: 24,
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentMarketTab == 'Digital'
                      ? 'Search college, subject, teacher...'
                      : 'Search laptops, cycles, calculators...',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMarketTabButton('Digital', '📚 Study Materials'),
          ),
          Expanded(
            child: _buildMarketTabButton('Physical', '🎒 Campus Store'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTabButton(String tab, String label) {
    final isSelected = _currentMarketTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMarketTab = tab;
          _selectedCategory = tab == 'Digital' ? _digitalCategories[0] : _physicalCategories[0];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final list = _currentMarketTab == 'Digital' ? _digitalCategories : _physicalCategories;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = list[index];
          final isSelected = cat == _selectedCategory;
          return ChoiceChip(
            label: Text(
              cat,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: Theme.of(context).cardColor,
            onSelected: (val) {
              if (val) {
                setState(() => _selectedCategory = cat);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onSeeAll,
          child: const Row(
            children: [
              Text('See All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesScrollList(BuildContext context, {bool isFeatured = false, bool isTrending = false, bool isRecommended = false}) {
    // Use real DB data if available, otherwise show placeholder cards
    List<dynamic> notes = _realNotes;
    if (_selectedCategory != 'All') {
      notes = _realNotes.where((note) {
        final subject = (note['subject'] ?? '').toString().toLowerCase();
        final title = (note['title'] ?? '').toString().toLowerCase();
        final desc = (note['description'] ?? '').toString().toLowerCase();
        final cat = _selectedCategory.toLowerCase();
        final category = (note['category'] ?? '').toString().toLowerCase();
        return subject.contains(cat) || title.contains(cat) || desc.contains(cat) || category.contains(cat);
      }).toList();
    }

    if (_loading && notes.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (notes.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_rounded, size: 40, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No study notes found in the database.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Show real notes from database
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: notes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final note = notes[index] as Map<String, dynamic>;
          final id = note['_id'] ?? note['id'] ?? '';
          final title = note['title'] ?? 'Untitled';
          final college = note['college'] ?? note['seller']?['name'] ?? '';
          final price = (note['price'] ?? 0) == 0 ? 'Free' : '₹${note['price']}';
          final rating = (note['averageRating'] ?? 0.0).toStringAsFixed(1);
          final thumbnail = note['thumbnailUrl'] as String?;
          final isBookmarked = _bookmarkedItems.contains(id);
          final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.success];
          final colorIdx = index % colors.length;

          return GestureDetector(
            onTap: () => context.push('/notes/$id'),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: thumbnail != null && thumbnail.startsWith('http')
                            ? Image.network(thumbnail, height: 110, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 110, width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [colors[colorIdx], colors[colorIdx].withValues(alpha: 0.6)],
                                    ),
                                  ),
                                  child: const Center(child: Icon(Icons.description_rounded, color: Colors.white, size: 36)),
                                ))
                            : Container(
                                height: 110, width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colors[colorIdx], colors[colorIdx].withValues(alpha: 0.6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(child: Icon(Icons.description_rounded, color: Colors.white, size: 36)),
                              ),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isBookmarked) _bookmarkedItems.remove(id);
                              else _bookmarkedItems.add(id);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                            child: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(college, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(price, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                                color: price == 'Free' ? AppColors.success : AppColors.primary)),
                              Row(children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 2),
                                Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ]),
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
      ),
    );
  }

  Widget _buildPhysicalProductsList(BuildContext context) {
    // Try to filter real products first
    final List<dynamic> realItems = _selectedCategory == 'All'
        ? _realPhysicalProducts
        : _realPhysicalProducts
            .where((p) => p['physicalCategory'] == _selectedCategory)
            .toList();

    if (realItems.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No campus store items found in the database.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: realItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final p = realItems[index] as Map<String, dynamic>;
          final id = p['_id'] ?? p['id'] ?? '';
          final title = p['title'] ?? 'Untitled';
          final sellerName = p['seller']?['name'] ?? 'Seller';
          final price = (p['price'] ?? 0) == 0 ? 'Free' : '₹${p['price']}';
          final condition = p['itemCondition'] ?? 'Good';
          final thumbnailUrl = p['thumbnailUrl'] as String?;
          final isBookmarked = _bookmarkedItems.contains(id);

          return GestureDetector(
            onTap: () => context.push('/notes/$id'),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: thumbnailUrl != null && thumbnailUrl.startsWith('http')
                            ? Image.network(
                                thumbnailUrl,
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallbackContainer(index),
                              )
                            : _fallbackContainer(index),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isBookmarked) _bookmarkedItems.remove(id);
                                else _bookmarkedItems.add(id);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                            child: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            condition,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Seller: $sellerName', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Text(price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackContainer(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    final color = colors[index % colors.length];
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Icon(Icons.shopping_bag_outlined, color: color, size: 38),
      ),
    );
  }

  List<Map<String, dynamic>> _getDynamicSellers() {
    final Map<String, Map<String, dynamic>> sellersMap = {};
    for (var note in _realNotes) {
      final seller = note['seller'];
      if (seller != null && seller['_id'] != null) {
        sellersMap[seller['_id']] = {
          'name': seller['name'] ?? 'Anonymous Seller',
          'college': seller['college'] ?? 'Campus',
          'avatar': seller['avatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=120',
        };
      }
    }
    for (var product in _realPhysicalProducts) {
      final seller = product['seller'];
      if (seller != null && seller['_id'] != null) {
        sellersMap[seller['_id']] = {
          'name': seller['name'] ?? 'Anonymous Seller',
          'college': seller['college'] ?? 'Campus',
          'avatar': seller['avatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=120',
        };
      }
    }
    return sellersMap.values.toList();
  }

  Widget _buildTopSellersList(List<Map<String, dynamic>> sellers) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sellers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final s = sellers[index];
          final name = s['name'] as String;
          final isFollowing = _followedSellers.contains(name);

          return Container(
            width: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: s['avatar'].toString().startsWith('http') ? NetworkImage(s['avatar'] as String) : null,
                  child: s['avatar'].toString().startsWith('http') ? null : const Icon(Icons.person),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  s['college'] as String,
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _toggleFollow(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.transparent : AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : '+ Follow',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isFollowing ? AppColors.primary : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlashSaleBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FLASH DEAL',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get 50% Off on AI Credits',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Summarize & Quiz notes inside 1 tap.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.flash_on_rounded, size: 54, color: Colors.white),
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildClassifiedsPromoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.teal, Colors.cyan]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CAMPUS SWAP',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sell Your Used Items!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'List calculators, laptops, cycles for cash.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.sell_rounded, size: 54, color: Colors.white),
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildDynamicBanner(BuildContext context, dynamic banner) {
    final title = banner['title'] ?? '';
    final subtitle = banner['subtitle'] ?? '';
    final tag = banner['tag'] ?? 'PROMO';
    final discount = banner['discountPercent'] ?? 0;
    final bgUrl = banner['bgImageUrl'] as String?;
    final target = banner['targetRoute'] ?? '';

    return GestureDetector(
      onTap: () {
        if (target.isNotEmpty) {
          context.push(target);
        }
      },
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: bgUrl != null && bgUrl.startsWith('http')
                    ? Image.network(
                        bgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultBannerGradient(discount),
                      )
                    : _defaultBannerGradient(discount),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
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
                              color: Colors.white.withValues(alpha: 0.2),
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
                            style: GoogleFonts.poppins(
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
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _defaultBannerGradient(int discount) {
    final colors = discount > 0
        ? [AppColors.primary, AppColors.secondary]
        : [Colors.teal, Colors.cyan];
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

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_realBanners.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerPageController != null && _bannerPageController!.hasClients) {
        _currentBannerPage = (_currentBannerPage + 1) % _realBanners.length;
        _bannerPageController!.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Widget _buildBannersCarousel(BuildContext context) {
    if (_realBanners.isEmpty) {
      return _buildFlashSaleBanner(context);
    }
    if (_realBanners.length == 1) {
      return _buildDynamicBanner(context, _realBanners[0]);
    }

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _bannerPageController,
            onPageChanged: (page) {
              setState(() {
                _currentBannerPage = page;
              });
            },
            itemCount: _realBanners.length,
            itemBuilder: (context, index) {
              return _buildDynamicBanner(context, _realBanners[index]);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _realBanners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              width: _currentBannerPage == index ? 15 : 5,
              decoration: BoxDecoration(
                color: _currentBannerPage == index ? AppColors.primary : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
