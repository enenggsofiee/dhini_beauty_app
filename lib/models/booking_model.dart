class Booking {
  final int id;
  final int userId;
  final int treatmentId;
  final String treatmentName;
  final int harga;
  final String tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String status;

  Booking({
    required this.id,
    required this.userId,
    required this.treatmentId,
    required this.treatmentName,
    required this.harga,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      treatmentId: json['treatment_id'],
      treatmentName: json['nama_treatment'],
      harga: json['harga'],
      tanggal: json['tanggal_booking'],
      jamMulai: json['jam_mulai'].toString().substring(0, 5),
      jamSelesai: json['jam_selesai'].toString().substring(0, 5),
      status: json['status'],
    );
  }
}