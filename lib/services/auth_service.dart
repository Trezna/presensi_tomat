import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../dto/petugas.dart';
import '../endpoints/endpoints.dart';

/// Singleton AuthService — simpan/ambil/hapus sesi login + operasi petugas.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _kSesiKey = 'sesi_petugas';

  // ── Sesi ──────────────────────────────────────────────────────────────────

  /// Ambil petugas yang sedang login dari SharedPreferences.
  /// Return null kalau belum login.
  Future<Petugas?> getSesi() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kSesiKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Petugas.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Simpan sesi petugas ke SharedPreferences.
  Future<void> simpanSesi(Petugas petugas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSesiKey, jsonEncode(petugas.toJson()));
  }

  /// Hapus sesi (logout).
  Future<void> hapusSesi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSesiKey);
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Login ke backend. Throws Exception kalau gagal (401 atau network error).
  Future<Petugas> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(Endpoints.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username.trim(), 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final petugas = Petugas.fromJson(data);
        await simpanSesi(petugas);
        return petugas;
      } else if (response.statusCode == 401) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['error'] ?? 'Username atau password salah');
      } else {
        throw Exception('Gagal login: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Pastikan backend berjalan.');
    } catch (e) {
      rethrow;
    }
  }

  // ── Petugas ───────────────────────────────────────────────────────────────

  /// Ambil data petugas terbaru dari server dan update sesi lokal.
  Future<Petugas> getPetugas(int id) async {
    try {
      final response = await http.get(Uri.parse(Endpoints.petugas(id)));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final petugas = Petugas.fromJson(data);
        await simpanSesi(petugas);
        return petugas;
      } else {
        throw Exception('Gagal ambil data petugas: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kesalahan jaringan: $e');
    }
  }

  /// Upload/ganti foto profil petugas.
  Future<Petugas> uploadFotoProfil(int id, File foto) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(Endpoints.fotoProfil(id)),
      );
      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final petugas = Petugas.fromJson(data);
        await simpanSesi(petugas);
        return petugas;
      } else {
        throw Exception('Gagal upload foto: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal upload foto profil: $e');
    }
  }
}
