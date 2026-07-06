class Presensi {
  final int id;
  final int? idPetugas;
  final String namaPetugas;
  final String tanggal;
  final String jam;
  final String fotoUrl;
  final String status;
  final double? latitude;
  final double? longitude;

  Presensi({
    required this.id,
    this.idPetugas,
    required this.namaPetugas,
    required this.tanggal,
    required this.jam,
    required this.fotoUrl,
    required this.status,
    this.latitude,
    this.longitude,
  });

  factory Presensi.fromJson(Map<String, dynamic> json) {
    return Presensi(
      id: json['id'] ?? 0,
      idPetugas: json['id_petugas'],
      namaPetugas: json['nama_petugas'] ?? '',
      tanggal: json['tanggal'] ?? '',
      jam: json['jam'] ?? '',
      fotoUrl: json['foto_url'] ?? '',
      status: json['status'] ?? 'Hadir',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
