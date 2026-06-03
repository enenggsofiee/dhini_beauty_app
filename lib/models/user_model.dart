class User {
  final int id;
  final String username;
  final String namaLengkap;
  final String noTelepon;

  User({
    required this.id,
    required this.username,
    required this.namaLengkap,
    required this.noTelepon,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      namaLengkap: json['nama_lengkap'],
      noTelepon: json['no_telepon'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama_lengkap': namaLengkap,
      'no_telepon': noTelepon,
    };
  }
}