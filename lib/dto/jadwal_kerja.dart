class JadwalKerja {
  final int id;
  final String tanggal;
  final String judul;
  final String jamMulai;
  final String jamSelesai;
  final String keterangan;

  JadwalKerja({
    required this.id,
    required this.tanggal,
    required this.judul,
    required this.jamMulai,
    required this.jamSelesai,
    required this.keterangan,
  });

  factory JadwalKerja.fromJson(Map<String, dynamic> json) {
    return JadwalKerja(
      id: json['id'] ?? 0,
      tanggal: json['tanggal'] ?? '',
      judul: json['judul'] ?? '',
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      keterangan: json['keterangan'] ?? '',
    );
  }
}
