class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final int bookingId;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.bookingId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      bookingId: int.tryParse(json['booking_id'].toString()) ?? 0,
      isRead: (int.tryParse(json['is_read'].toString()) ?? 0) == 1,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
