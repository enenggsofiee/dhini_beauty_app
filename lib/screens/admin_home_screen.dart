import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/glassmorphism.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'notification_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllBookings();
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
    try {
      Provider.of<NotificationProvider>(context, listen: false).stopPolling();
    } catch (e) {
      print('Error stopping polling on dispose: $e');
    }
    super.dispose();
  }

  Future<void> _loadAllBookings() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getAllBookings();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _allBookings = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(result['message'] ?? 'Gagal mengambil data', isError: true);
      }
    }
  }

  Future<void> _updateStatus(int bookingId, String currentStatus) async {
    final String? newStatus = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Status Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Constants.textDark)),
            const SizedBox(height: 16),
            _buildStatusOption(context, 'pending', 'Pending', Colors.orange),
            _buildStatusOption(context, 'confirmed', 'Confirmed', Colors.green),
            _buildStatusOption(context, 'completed', 'Completed', Colors.blue),
            _buildStatusOption(context, 'cancelled', 'Cancelled', Colors.redAccent),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      setState(() => _isLoading = true);
      final result = await _apiService.updateBookingStatus(bookingId, newStatus);
      if (result['success']) {
        _showSnackBar('Status berhasil diperbarui');
        _loadAllBookings();
      } else {
        _showSnackBar(result['message'], isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatusOption(BuildContext context, String value, String label, Color color) {
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 16),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Constants.textDark)),
      onTap: () => Navigator.pop(context, value),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.redAccent;
      case 'completed': return Colors.blue;
      default: return Constants.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = Provider.of<NotificationProvider>(context).unreadCount;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Constants.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Owner Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Constants.textDark)),
                        Text('Manage Appointments', style: TextStyle(color: Constants.textLight, fontSize: 14)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.refresh_rounded, color: Constants.textDark), onPressed: _loadAllBookings),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_none_rounded, color: Constants.textDark, size: 26),
                                if (unreadCount > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Constants.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
                    : _allBookings.isEmpty
                        ? const Center(child: Text('Belum ada pesanan masuk', style: TextStyle(color: Constants.textLight)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: _allBookings.length,
                            itemBuilder: (context, index) {
                              final booking = _allBookings[index];
                              final status = booking['status'].toString().toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(20),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(booking['nama_lengkap'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Constants.textDark)),
                                          GestureDetector(
                                            onTap: () => _updateStatus(int.tryParse(booking['id'].toString()) ?? 0, status),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 11)),
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.edit, size: 12, color: _getStatusColor(status)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(booking['no_telepon'], style: const TextStyle(color: Constants.textLight, fontSize: 13)),
                                      const Divider(height: 24, color: Colors.white30),
                                      Text(booking['nama_treatment'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Constants.primaryColor)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_month, size: 14, color: Constants.textLight),
                                          const SizedBox(width: 6),
                                          Text('${booking['tanggal_booking']} | ${booking['jam_mulai']} - ${booking['jam_selesai']}', style: const TextStyle(color: Constants.textLight, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.payment_rounded, size: 14, color: Constants.textLight),
                                          const SizedBox(width: 6),
                                          Text('Via: ${booking['metode_pembayaran'] ?? 'Cash (Di Tempat)'}', style: const TextStyle(color: Constants.textLight, fontSize: 13, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      if (booking['catatan'] != null && booking['catatan'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
                                          child: Text('Catatan: ${booking['catatan']}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Constants.textDark)),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
