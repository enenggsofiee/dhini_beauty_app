import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  Timer? _pollingTimer;
  int? _currentUserId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // Fetch notifications from the backend
  Future<void> fetchNotifications(int userId) async {
    _currentUserId = userId;
    
    // Only show loading indicator on first fetch or if list is empty to prevent UI flickers during polling
    if (_notifications.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final result = await _apiService.getNotifications(userId);
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        final List<NotificationModel> newNotifications = 
            data.map((json) => NotificationModel.fromJson(json)).toList();
        
        // Periksa apakah ada notifikasi baru untuk ditampilkan di bilah atas (sistem tray)
        if (newNotifications.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final lastShownId = prefs.getInt('last_shown_notification_id') ?? 0;
          
          // Dapatkan notifikasi unread dengan ID yang lebih besar dari yang terakhir ditayangkan
          List<NotificationModel> notificationsToTrigger = newNotifications
              .where((n) => !n.isRead && n.id > lastShownId)
              .toList();
          
          if (notificationsToTrigger.isNotEmpty) {
            // Jika ini pertama kali load (list lokal kosong) dan SharedPreferences baru (0),
            // ambil saja 1 notifikasi unread terbaru agar tidak membombardir bilah atas
            if (_notifications.isEmpty && lastShownId == 0) {
              notificationsToTrigger = [notificationsToTrigger.first];
            } else {
              // Balik urutan agar berurutan secara waktu (kronologis)
              notificationsToTrigger = notificationsToTrigger.reversed.toList();
            }

            final notifService = NotificationService();
            for (var notif in notificationsToTrigger) {
              await notifService.showNotification(
                id: notif.id,
                title: notif.title,
                body: notif.message,
              );
            }
            
            // Simpan ID tertinggi sebagai penanda sudah ditayangkan
            final highestId = newNotifications
                .map((n) => n.id)
                .reduce((curr, next) => curr > next ? curr : next);
            await prefs.setInt('last_shown_notification_id', highestId);
          } else if (_notifications.isEmpty) {
            // Jika tidak ada yang unread di awal, tetap catat ID tertinggi dari semua notif yang ada
            final highestId = newNotifications
                .map((n) => n.id)
                .reduce((curr, next) => curr > next ? curr : next);
            await prefs.setInt('last_shown_notification_id', highestId);
          }
        }
        
        _notifications = newNotifications;
        
        // Count unread
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      print('Error fetching notifications in provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    if (_currentUserId == null || _currentUserId == 0) return;
    
    // Optimistic update
    final updatedNotifications = _notifications.map((n) {
      return NotificationModel(
        id: n.id,
        userId: n.userId,
        title: n.title,
        message: n.message,
        type: n.type,
        bookingId: n.bookingId,
        isRead: true,
        createdAt: n.createdAt,
      );
    }).toList();
    
    _notifications = updatedNotifications;
    _unreadCount = 0;
    notifyListeners();

    try {
      await _apiService.markNotificationsAsRead(_currentUserId!);
      // Re-fetch to ensure sync with database
      fetchNotifications(_currentUserId!);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // Mark specific notification as read
  Future<void> markAsRead(int notificationId) async {
    if (_currentUserId == null || _currentUserId == 0) return;

    // Optimistic update
    int index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      final n = _notifications[index];
      _notifications[index] = NotificationModel(
        id: n.id,
        userId: n.userId,
        title: n.title,
        message: n.message,
        type: n.type,
        bookingId: n.bookingId,
        isRead: true,
        createdAt: n.createdAt,
      );
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      notifyListeners();
    }

    try {
      await _apiService.markNotificationsAsRead(_currentUserId!, notificationId: notificationId);
      // Re-fetch to ensure sync with database
      fetchNotifications(_currentUserId!);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Start polling notifications periodically (e.g. every 20 seconds)
  void startPolling(int userId) {
    stopPolling(); // Stop any existing timer first
    _currentUserId = userId;
    
    // Initial fetch
    fetchNotifications(userId);
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_currentUserId != null && _currentUserId != 0) {
        fetchNotifications(_currentUserId!);
      }
    });
    print('⏰ Notification polling started for user $userId');
  }

  // Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('⏰ Notification polling stopped');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
