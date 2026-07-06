class Petugas {
  final int id;
  final String username;
  final String nama;
  final String role;
  final String? fotoProfilUrl;
  final String bergabungSejak;

  Petugas({
    required this.id,
    required this.username,
    required this.nama,
    required this.role,
    this.fotoProfilUrl,
    required this.bergabungSejak,
  });

  factory Petugas.fromJson(Map<String, dynamic> json) {
    return Petugas(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      nama: json['nama'] ?? '',
      role: json['role'] ?? 'petugas',
      fotoProfilUrl: json['foto_profil_url'],
      bergabungSejak: json['bergabung_sejak'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama': nama,
      'role': role,
      'foto_profil_url': fotoProfilUrl,
      'bergabung_sejak': bergabungSejak,
    };
  }

  // Untuk update foto profil tanpa reconstruct dari network
  Petugas copyWith({String? fotoProfilUrl}) {
    return Petugas(
      id: id,
      username: username,
      nama: nama,
      role: role,
      fotoProfilUrl: fotoProfilUrl ?? this.fotoProfilUrl,
      bergabungSejak: bergabungSejak,
    );
  }
}
