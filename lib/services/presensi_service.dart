import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../dto/jadwal_kerja.dart';
import '../dto/pengumuman.dart';
import '../dto/petugas.dart';
import '../dto/presensi.dart';
import '../endpoints/endpoints.dart';

class PresensiService {
  // ── Presensi ────────────────────────────────────────────────────────────────

  /// Ambil daftar riwayat presensi (opsional filter per user dan/atau tanggal)
  Future<List<Presensi>> fetchRiwayatPresensi({
    int? idPetugas,
    String? tanggal,
  }) async {
    try {
      String url = Endpoints.presensi;
      final params = <String>[];
      if (idPetugas != null) params.add('id_petugas=$idPetugas');
      if (tanggal != null) params.add('tanggal=$tanggal');
      if (params.isNotEmpty) url = '$url?${params.join('&')}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> list = data['presensi'] ?? [];
        return list.map((e) => Presensi.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat riwayat: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  /// Upload presensi baru (multipart) — sertakan lat/lng kalau tersedia
  Future<Presensi> uploadPresensi(
    String namaPetugas,
    File foto, {
    int? idPetugas,
    double? latitude,
    double? longitude,
  }) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse(Endpoints.presensi));

      request.fields['nama_petugas'] = namaPetugas;
      if (idPetugas != null) {
        request.fields['id_petugas'] = idPetugas.toString();
      }
      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }

      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Presensi.fromJson(data);
      } else {
        throw Exception('Gagal presensi: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal upload presensi: $e');
    }
  }

  /// Cek apakah hari ini sudah presensi (opsional filter per user)
  Future<bool> cekPresensiHariIni({int? idPetugas}) async {
    try {
      final riwayat = await fetchRiwayatPresensi(idPetugas: idPetugas);
      if (riwayat.isEmpty) return false;
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      return riwayat.any((p) => p.tanggal == todayStr);
    } catch (e) {
      throw Exception('Gagal cek presensi hari ini: $e');
    }
  }

  // ── Jadwal ──────────────────────────────────────────────────────────────────

  /// Ambil semua jadwal kerja
  Future<List<JadwalKerja>> fetchJadwalKerja() async {
    try {
      final response = await http.get(Uri.parse(Endpoints.jadwal));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> list = data['jadwal'] ?? [];
        return list.map((e) => JadwalKerja.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat jadwal: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  /// Tambah jadwal baru (admin)
  Future<JadwalKerja> addJadwal({
    required String tanggal,
    required String judul,
    required String jamMulai,
    required String jamSelesai,
    String keterangan = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Endpoints.jadwal),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tanggal': tanggal,
          'judul': judul,
          'jam_mulai': jamMulai,
          'jam_selesai': jamSelesai,
          'keterangan': keterangan,
        }),
      );
      if (response.statusCode == 201) {
        return JadwalKerja.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal tambah jadwal: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal tambah jadwal: $e');
    }
  }

  /// Hapus jadwal (admin)
  Future<void> deleteJadwal(int id) async {
    try {
      final response =
          await http.delete(Uri.parse(Endpoints.jadwalById(id)));
      if (response.statusCode != 200) {
        throw Exception('Gagal hapus jadwal: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal hapus jadwal: $e');
    }
  }

  // ── Pengumuman ──────────────────────────────────────────────────────────────

  /// Ambil semua pengumuman
  Future<List<Pengumuman>> fetchPengumuman() async {
    try {
      final response = await http.get(Uri.parse(Endpoints.pengumuman));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> list = data['pengumuman'] ?? [];
        return list.map((e) => Pengumuman.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat pengumuman: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  /// Tambah pengumuman (admin)
  Future<Pengumuman> addPengumuman({
    required String judul,
    required String isi,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Endpoints.pengumuman),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'judul': judul, 'isi': isi}),
      );
      if (response.statusCode == 201) {
        return Pengumuman.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Gagal tambah pengumuman: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal tambah pengumuman: $e');
    }
  }

  /// Hapus pengumuman (admin)
  Future<void> deletePengumuman(int id) async {
    try {
      final response =
          await http.delete(Uri.parse(Endpoints.pengumumanById(id)));
      if (response.statusCode != 200) {
        throw Exception(
            'Gagal hapus pengumuman: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal hapus pengumuman: $e');
    }
  }

  // ── Petugas (Admin) ─────────────────────────────────────────────────────────

  /// Ambil list semua petugas (admin)
  Future<List<Petugas>> fetchPetugasList() async {
    try {
      final response = await http.get(Uri.parse(Endpoints.petugasList));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> list = data['petugas'] ?? [];
        return list.map((e) => Petugas.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat petugas: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  /// Tambah petugas baru (admin)
  Future<Petugas> addPetugas({
    required String username,
    required String password,
    required String nama,
    String role = 'petugas',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Endpoints.petugasList),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'nama': nama,
          'role': role,
        }),
      );
      if (response.statusCode == 201) {
        return Petugas.fromJson(jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
            body['error'] ?? 'Gagal tambah petugas: HTTP ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Edit data petugas (admin). Password opsional — kirim string kosong
  /// kalau tidak ingin mengubah password.
  Future<Petugas> editPetugas({
    required int id,
    required String nama,
    required String role,
    String password = '',
  }) async {
    try {
      final response = await http.put(
        Uri.parse(Endpoints.petugas(id)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'role': role,
          if (password.isNotEmpty) 'password': password,
        }),
      );
      if (response.statusCode == 200) {
        return Petugas.fromJson(jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal update petugas: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  /// Hapus petugas (admin).
  Future<void> deletePetugas(int id) async {
    try {
      final response = await http.delete(Uri.parse(Endpoints.petugas(id)));
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal hapus petugas: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }
}
