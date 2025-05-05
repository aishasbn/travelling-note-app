// lib/models/lokasi.dart
class Lokasi {
  final int? id;
  final String judul;
  final String catatan;
  final double latitude;
  final double longitude;
  final String kota;
  final String tanggal;

  Lokasi({
    this.id,
    required this.judul,
    required this.catatan,
    required this.latitude,
    required this.longitude,
    required this.kota,
    required this.tanggal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'catatan': catatan,
      'latitude': latitude,
      'longitude': longitude,
      'kota': kota,
      'tanggal': tanggal,
    };
  }

  factory Lokasi.fromMap(Map<String, dynamic> map) {
    return Lokasi(
      id: map['id'],
      judul: map['judul'],
      catatan: map['catatan'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      kota: map['kota'],
      tanggal: map['tanggal'],
    );
  }
}