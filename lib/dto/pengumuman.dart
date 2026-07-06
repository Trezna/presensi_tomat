class Pengumuman {
  final int id;
  final String judul;
  final String isi;
  final String tanggal;

  Pengumuman({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tanggal,
  });

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    return Pengumuman(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '',
      isi: json['isi'] ?? '',
      tanggal: json['tanggal'] ?? '',
    );
  }
}
