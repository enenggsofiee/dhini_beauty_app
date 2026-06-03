import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  // ==================== AUTHENTICATION ====================
  
  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    print('🔄 Mencoba login: $username');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      print('📡 Login response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Register
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    print('🔄 Mencoba register: ${data['username']}');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      print('📡 Register response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Register error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Google Login / Auto Register
  Future<Map<String, dynamic>> googleLogin(Map<String, dynamic> data) async {
    print('🔄 Mencoba Google Login: ${data['email']}');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/google_login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      print('📡 Google Login response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Google Login error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Login and Link Google Account from Login Screen
  Future<Map<String, dynamic>> loginAndLink(String username, String password, String email) async {
    print('🔄 Mencoba Login & Link: $username dengan Google: $email');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/login_and_link.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
        }),
      );
      print('📡 Login & Link response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Login & Link error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Get User Data
  Future<Map<String, dynamic>> getUserData(int userId) async {
    print('🔄 Mengambil data user: $userId');
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/get_user.php?id=$userId'),
      );
      print('📡 Get user response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get user error: $e');
      return {'success': false, 'message': 'Gagal mengambil data user: $e'};
    }
  }

  // Upload Profile Image
  Future<Map<String, dynamic>> uploadProfileImage(int userId, String base64Image) async {
    print('🔄 Mengunggah foto profil user: $userId');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/upload_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'image_base64': base64Image}),
      );
      print('📡 Upload profile response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Upload profile error: $e');
      return {'success': false, 'message': 'Gagal upload foto profil: $e'};
    }
  }

  // Link Google Account
  Future<Map<String, dynamic>> linkGoogleAccount(int userId, String email) async {
    print('🔄 Menghubungkan Google Account: $email untuk user: $userId');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/link_google.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'email': email}),
      );
      print('📡 Link Google response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Link Google error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ==================== TREATMENTS ====================
  
  // Get Treatments
  Future<Map<String, dynamic>> getTreatments() async {
    print('🔄 Mengambil data treatments');
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/get_treatments.php'),
      );
      print('📡 Treatments response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get treatments error: $e');
      return {'success': false, 'message': 'Gagal mengambil data treatment'};
    }
  }

  // ==================== BOOKINGS ====================
  
  // Create Booking
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    print('🔄 Membuat booking: $data');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/create_booking.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      print('📡 Create booking response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Create booking error: $e');
      return {'success': false, 'message': 'Gagal membuat booking: $e'};
    }
  }

  // Get Bookings by User ID
  Future<Map<String, dynamic>> getBookings(int userId) async {
    print('🔄 Mengambil bookings untuk user: $userId');
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/get_bookings.php?user_id=$userId'),
      );
      print('📡 Get bookings response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get bookings error: $e');
      return {'success': false, 'message': 'Gagal mengambil riwayat booking'};
    }
  }

  // Cancel Booking
  Future<Map<String, dynamic>> cancelBooking(int bookingId, int userId) async {
    print('🔄 Membatalkan booking ID: $bookingId untuk user: $userId');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/cancel_booking.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'booking_id': bookingId, 'user_id': userId}),
      );
      print('📡 Cancel booking response: ${response.body}');
      print('📡 Response status code: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Cancel booking error: $e');
      return {'success': false, 'message': 'Gagal membatalkan booking: $e'};
    }
  }

  // ==================== USER SESSION ====================
  
  // Save user session
  Future<void> saveUserSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert ID safely whether it's String or int
    int userId = 0;
    if (user['id'] != null) {
      if (user['id'] is int) {
        userId = user['id'];
      } else {
        userId = int.tryParse(user['id'].toString()) ?? 0;
      }
    }
    
    await prefs.setInt('user_id', userId);
    await prefs.setString('username', user['username']?.toString() ?? '');
    await prefs.setString('nama_lengkap', user['nama_lengkap']?.toString() ?? '');
    await prefs.setString('no_telepon', user['no_telepon']?.toString() ?? '');
    await prefs.setString('role', user['role']?.toString() ?? 'customer');
    print('✅ User session saved: ${user['username']} (ID: $userId, Role: ${user['role']})');
  }

  // Get user session
  Future<Map<String, dynamic>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('user_id'),
      'username': prefs.getString('username'),
      'nama_lengkap': prefs.getString('nama_lengkap'),
      'no_telepon': prefs.getString('no_telepon'),
      'role': prefs.getString('role') ?? 'customer',
    };
  }

  // Get All Bookings (For Admin)
  Future<Map<String, dynamic>> getAllBookings() async {
    print('🔄 Mengambil semua data booking untuk admin');
    try {
      final response = await http.get(Uri.parse('${Constants.baseUrl}/get_all_bookings.php'));
      print('📡 All Bookings response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ All Bookings error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Update Booking Status (For Admin)
  Future<Map<String, dynamic>> updateBookingStatus(dynamic bookingId, String status) async {
    print('🔄 Mengubah status booking ID: $bookingId menjadi $status');
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/update_booking_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'booking_id': bookingId, 'status': status}),
      );
      print('📡 Update Status response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Update Status error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('👋 User logged out');
  }

  // ==================== NOTIFICATIONS ====================
  
  // Get Notifications
  Future<Map<String, dynamic>> getNotifications(int userId) async {
    print('🔄 Mengambil notifikasi untuk user: $userId');
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/get_notifications.php?user_id=$userId'),
      );
      print('📡 Get notifications response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get notifications error: $e');
      return {'success': false, 'message': 'Gagal mengambil notifikasi: $e'};
    }
  }

  // Mark Notifications as Read
  Future<Map<String, dynamic>> markNotificationsAsRead(int userId, {int? notificationId}) async {
    print('🔄 Menandai notifikasi sebagai dibaca: user $userId, notif $notificationId');
    try {
      final Map<String, dynamic> bodyData = {'user_id': userId};
      if (notificationId != null) {
        bodyData['notification_id'] = notificationId;
      }
      
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/mark_notifications_read.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );
      print('📡 Mark read response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Mark read error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }
}