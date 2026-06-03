class Treatment {
  final int id;
  final String nama;
  final String deskripsi;
  final int harga;
  final int durasi;

  Treatment({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.durasi,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      id: int.parse(json['id'].toString()),
      nama: json['nama_treatment'],
      deskripsi: json['deskripsi'] ?? '',
      harga: int.parse(json['harga'].toString()),
      durasi: int.parse(json['durasi'].toString()),
    );
  }

  String get formattedHarga {
    return 'Rp ${harga.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_treatment': nama,
      'deskripsi': deskripsi,
      'harga': harga,
      'durasi': durasi,
    };
  }
}