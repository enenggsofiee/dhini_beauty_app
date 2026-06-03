import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/glassmorphism.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final user = await _apiService.getUserSession();
    if (mounted) {
      final result = await _apiService.getBookings(user['id']);
      if (mounted) {
        if (result['success']) {
          setState(() {
            _bookings = result['data'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _cancelBooking(int bookingId, String treatmentName) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(32),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cancel Appointment?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Constants.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to cancel your booking for "$treatmentName"?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Constants.textLight, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Constants.textLight),
                    ),
                    child: const Text('No, Keep it', style: TextStyle(color: Constants.textDark, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final user = await _apiService.getUserSession();
    final result = await _apiService.cancelBooking(bookingId, user['id']);

    if (result['success']) {
      await _loadBookings();
      _showSnackBar(result['message'], isError: false);
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result['message'], isError: true);
    }
  }

  Future<void> _deleteBooking(int bookingId, String treatmentName) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(32),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hapus Riwayat Booking?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Constants.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Apakah Anda yakin ingin menghapus riwayat booking untuk "$treatmentName"?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Constants.textLight, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Constants.textLight),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Constants.textDark, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final user = await _apiService.getUserSession();
    final result = await _apiService.deleteBooking(bookingId, userId: user['id']);

    if (result['success']) {
      await _loadBookings();
      _showSnackBar(result['message'], isError: false);
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result['message'], isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    // Scaffold without appBar since it's used inside HomeScreen
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Constants.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Constants.textDark),
                    onPressed: _loadBookings,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
                  : _bookings.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy_rounded, size: 80, color: Constants.textLight),
                              SizedBox(height: 16),
                              Text('No Bookings Yet', style: TextStyle(color: Constants.textDark, fontSize: 18, fontWeight: FontWeight.w600)),
                              SizedBox(height: 8),
                              Text('Time to treat yourself!', style: TextStyle(color: Constants.textLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            final String status = booking['status'].toString().toLowerCase();
                            final bool isActive = (status == 'confirmed' || status == 'pending');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(20),
                                borderRadius: BorderRadius.circular(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          booking['tanggal_booking'],
                                          style: const TextStyle(color: Constants.textLight, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      booking['nama_treatment'],
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Constants.textDark),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded, size: 16, color: Constants.textLight),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${booking['jam_mulai']} - ${booking['jam_selesai']}',
                                          style: const TextStyle(color: Constants.textLight, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.sell_rounded, size: 16, color: Constants.primaryColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Rp ${booking['harga']}',
                                          style: const TextStyle(color: Constants.primaryColor, fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.payment_rounded, size: 16, color: Constants.textLight),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Via: ${booking['metode_pembayaran'] ?? 'Cash (Di Tempat)'}',
                                          style: const TextStyle(color: Constants.textLight, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    if (booking['catatan'] != null && booking['catatan'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.format_quote_rounded, size: 16, color: Constants.textLight),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                booking['catatan'],
                                                style: const TextStyle(color: Constants.textLight, fontStyle: FontStyle.italic, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (isActive) ...[
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: OutlinedButton(
                                          onPressed: () => _cancelBooking(
                                            int.tryParse(booking['id'].toString()) ?? 0, 
                                            booking['nama_treatment'].toString()
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          child: const Text('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                    if (!isActive) ...[
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: OutlinedButton(
                                          onPressed: () => _deleteBooking(
                                            int.tryParse(booking['id'].toString()) ?? 0,
                                            booking['nama_treatment'].toString()
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.delete_outline_rounded, size: 18),
                                              SizedBox(width: 8),
                                              Text('Hapus dari Riwayat', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
    );
  }
}