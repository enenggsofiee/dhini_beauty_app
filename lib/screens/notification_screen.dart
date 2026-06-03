import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/glassmorphism.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications once when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
      if (authProvider.userId != 0) {
        notifProvider.fetchNotifications(authProvider.userId);
      }
    });
  }

  // Format relative time (e.g., "5 menit yang lalu", "Kemarin", "Baru saja")
  String _formatTime(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      Duration diff = now.difference(dt);
      
      if (diff.isNegative) {
        // Handle slight clock mismatch
        return 'Baru saja';
      }
      
      if (diff.inSeconds < 60) {
        return 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit yang lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam yang lalu';
      } else if (diff.inDays == 1) {
        return 'Kemarin';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} hari yang lalu';
      } else {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getIcon(String type, String title) {
    final t = type.toLowerCase();
    final titleL = title.toLowerCase();
    
    if (t.contains('created') || titleL.contains('dikonfirmasi') || titleL.contains('konfirmasi')) {
      return Icons.check_circle_rounded;
    } else if (titleL.contains('batal') || titleL.contains('cancelled') || titleL.contains('dibatalkan')) {
      return Icons.cancel_rounded;
    } else if (titleL.contains('selesai') || titleL.contains('completed') || titleL.contains('terima kasih')) {
      return Icons.stars_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getIconColor(String type, String title) {
    final t = type.toLowerCase();
    final titleL = title.toLowerCase();
    
    if (titleL.contains('dikonfirmasi') || titleL.contains('konfirmasi')) {
      return Colors.green;
    } else if (titleL.contains('batal') || titleL.contains('cancelled') || titleL.contains('dibatalkan')) {
      return Colors.redAccent;
    } else if (titleL.contains('selesai') || titleL.contains('completed') || titleL.contains('terima kasih')) {
      return Colors.amber;
    }
    return Constants.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final List<NotificationModel> notifications = notifProvider.notifications;

    return Scaffold(
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
              _buildAppBar(context, notifProvider),
              Expanded(
                child: notifProvider.isLoading && notifications.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Constants.primaryColor),
                      )
                    : RefreshIndicator(
                        color: Constants.primaryColor,
                        onRefresh: () async {
                          if (authProvider.userId != 0) {
                            await notifProvider.fetchNotifications(authProvider.userId);
                          }
                        },
                        child: notifications.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final notif = notifications[index];
                                  return _buildNotificationItem(context, notif, notifProvider);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, NotificationProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Constants.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Notifikasi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Constants.textDark,
              ),
            ),
          ),
          if (provider.notifications.isNotEmpty && provider.unreadCount > 0)
            TextButton.icon(
              onPressed: () => provider.markAllAsRead(),
              icon: const Icon(Icons.mark_chat_read_rounded, size: 16, color: Constants.primaryColor),
              label: const Text(
                'Baca semua',
                style: TextStyle(
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassContainer(
                width: 100,
                height: 100,
                borderRadius: BorderRadius.circular(30),
                child: const Center(
                  child: Icon(
                    Icons.notifications_off_rounded,
                    size: 48,
                    color: Constants.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tidak ada notifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Constants.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'Semua aktivitas terbaru pemesanan Anda akan muncul di sini secara real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Constants.textLight.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notif,
    NotificationProvider provider,
  ) {
    final icon = _getIcon(notif.type, notif.title);
    final iconColor = _getIconColor(notif.type, notif.title);
    final relativeTime = _formatTime(notif.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: GestureDetector(
        onTap: () {
          if (!notif.isRead) {
            provider.markAsRead(notif.id);
          }
          // Optionally display a bottom sheet with complete details on tap
          _showNotificationDetail(context, notif);
        },
        child: AnimatedOpacity(
          opacity: notif.isRead ? 0.75 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: GlassContainer(
            padding: const EdgeInsets.all(16.0),
            borderRadius: BorderRadius.circular(20),
            color: notif.isRead 
                ? Colors.white.withOpacity(0.2) 
                : Colors.white.withOpacity(0.55),
            border: Border.all(
              color: notif.isRead 
                  ? Colors.white.withOpacity(0.15) 
                  : Constants.primaryColor.withOpacity(0.25),
              width: 1.5,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                color: Constants.textDark,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Constants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif.message,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w500,
                          color: Constants.textLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        relativeTime,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: notif.isRead 
                              ? Constants.textLight.withOpacity(0.6) 
                              : Constants.primaryColor.withOpacity(0.8),
                        ),
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
  }

  void _showNotificationDetail(BuildContext context, NotificationModel notif) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(24.0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Constants.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  _getIcon(notif.type, notif.title),
                  color: _getIconColor(notif.type, notif.title),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notif.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Constants.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notif.message,
              style: const TextStyle(
                fontSize: 15,
                color: Constants.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Waktu diterima:',
                  style: TextStyle(fontSize: 12, color: Constants.textLight.withOpacity(0.8)),
                ),
                Text(
                  notif.createdAt,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Constants.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
