class Endpoints {
  // 10.0.2.2 adalah localhost untuk Android Emulator.
  // Gunakan IP lokal network misal 192.168.x.x untuk testing di device fisik.
  static const String baseUrl = 'http://172.20.10.2:8000/api';
  static const String hostUrl = 'http://172.20.10.2:8000';

  static const String presensi = '$baseUrl/presensi';
  static const String pengumuman = '$baseUrl/pengumuman';
  static const String login = '$baseUrl/login';
  static const String jadwal = '$baseUrl/jadwal';
  static const String petugasList = '$baseUrl/petugas';

  static String petugas(int id) => '$baseUrl/petugas/$id';
  static String fotoProfil(int id) => '$baseUrl/petugas/$id/foto';
  static String pengumumanById(int id) => '$baseUrl/pengumuman/$id';
  static String jadwalById(int id) => '$baseUrl/jadwal/$id';
}
