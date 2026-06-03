import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/glassmorphism.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import 'booking_screen.dart';
import 'riwayat_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  List<dynamic> _treatments = [];
  bool _isLoading = true;
  String _userName = '';

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadUserData();
    _loadTreatments();
    _startNotificationPolling();
  }

  void _startNotificationPolling() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Inisialisasi layanan notifikasi sistem tray & minta izin
      final notifService = NotificationService();
      await notifService.initialize();
      await notifService.requestPermissions();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userId != 0) {
        Provider.of<NotificationProvider>(context, listen: false)
            .startPolling(authProvider.userId);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    try {
      Provider.of<NotificationProvider>(context, listen: false).stopPolling();
    } catch (e) {
      print('Error stopping polling on dispose: $e');
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await _apiService.getUserSession();
    if (mounted) {
      setState(() {
        _userName = user['nama_lengkap'] ?? 'User';
      });
    }
  }

  Future<void> _loadTreatments() async {
    final result = await _apiService.getTreatments();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _treatments = result['data'];
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // For floating bottom nav
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Constants.backgroundGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _selectedIndex == 0 ? _buildHomePage() : _buildOtherPage(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  Widget _buildAppBar() {
    final unreadCount = Provider.of<NotificationProvider>(context).unreadCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(color: Constants.textLight, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Constants.textDark,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GlassContainer(
                  width: 45,
                  height: 45,
                  borderRadius: BorderRadius.circular(15),
                  child: const Center(
                    child: Icon(Icons.notifications_none_rounded, color: Constants.textDark),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Constants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openTreatmentByKeyword(String keyword) {
    final found = _treatments.firstWhere(
      (t) => t['nama_treatment'].toString().toLowerCase().contains(keyword.toLowerCase()),
      orElse: () => null,
    );

    if (found != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => BookingScreen(treatment: found),
          transitionsBuilder: (context, anim, secAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Treatment "$keyword" sedang tidak tersedia untuk dibooking.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Constants.primaryColor,
        ),
      );
    }
  }

  Widget _buildPortfolioSection() {
    final List<Map<String, String>> portfolioItems = [
      {
        'title': 'Eyelash Classic Doll',
        'keyword': 'eyelash',
        'image': 'assets/images/eyelash.jpeg',
        'desc': 'Lentik & natural bertekstur doll-eye'
      },
      {
        'title': 'Eyebrow Tint & Shape',
        'keyword': 'alis',
        'image': 'assets/images/eyebrow.jpeg',
        'desc': 'Bingkai alis tegas & presisi alami'
      },
      {
        'title': 'Glossy Coral Lip Blush',
        'keyword': 'lip blush',
        'image': 'assets/images/lipblush.jpeg',
        'desc': 'Bibir merona sehat berkilau'
      },
      {
        'title': 'Chromosome Whitening Glow',
        'keyword': 'whitening',
        'image': 'assets/images/suntik whitening.jpeg',
        'desc': 'Kulit bersinar merata tiada cela'
      },
      {
        'title': 'Premium Piercing',
        'keyword': 'tindik',
        'image': 'assets/images/tindik.jpeg',
        'desc': 'Tindik telinga & tubuh higienis presisi'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Hasil Treatment Terbaik ✨',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Constants.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: portfolioItems.length,
            itemBuilder: (context, index) {
              final item = portfolioItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () => _openTreatmentByKeyword(item['keyword']!),
                  child: Container(
                    width: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Constants.primaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Image.asset(
                            item['image']!,
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Constants.secondaryColor,
                              child: const Icon(Icons.image_not_supported_rounded, color: Constants.primaryColor, size: 40),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.8),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['desc']!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHomePage() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Constants.primaryColor),
      );
    }

    if (_treatments.isEmpty) {
      return const Center(child: Text("No treatments available.", style: TextStyle(color: Constants.textLight)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioSection(),
          
          const SizedBox(height: 32),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Layanan Treatment Kami 🌸',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Constants.textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _treatments.length,
              itemBuilder: (context, index) {
                final treatment = _treatments[index];
                final delay = (index * 0.1).clamp(0.0, 1.0);
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
                  ),
                );

                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - animation.value)),
                      child: Opacity(
                        opacity: animation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, anim, secAnim) => BookingScreen(treatment: treatment),
                            transitionsBuilder: (context, anim, secAnim, child) {
                              return FadeTransition(opacity: anim, child: child);
                            },
                          ),
                        );
                      },
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Constants.secondaryColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: treatment['gambar'] != null && treatment['gambar'].toString().isNotEmpty
                                    ? Image.network(
                                        '${Constants.baseUrl}/../uploads/treatments/${treatment['gambar']}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.spa_rounded, color: Constants.primaryColor, size: 30),
                                      )
                                    : const Icon(Icons.spa_rounded, color: Constants.primaryColor, size: 30),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    treatment['nama_treatment'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Constants.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: Constants.textLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${treatment['durasi']} min',
                                        style: const TextStyle(color: Constants.textLight, fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.sell_rounded, size: 14, color: Constants.textLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Rp ${treatment['harga']}',
                                        style: const TextStyle(
                                          color: Constants.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Constants.textLight),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherPage() {
    if (_selectedIndex == 1) {
      return const RiwayatScreen();
    }
    return const ProfileScreen();
  }

  Widget _buildGlassBottomNav() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: GlassContainer(
        height: 70,
        borderRadius: BorderRadius.circular(35),
        color: Colors.white.withOpacity(0.3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.history_rounded, 'History'),
            _buildNavItem(2, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Constants.primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Constants.primaryColor : Constants.textLight,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}