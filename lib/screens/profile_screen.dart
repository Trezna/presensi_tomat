import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../dto/petugas.dart';
import '../dto/presensi.dart';
import '../services/auth_service.dart';
import '../services/presensi_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final PresensiService _presensiService = PresensiService();
  final ImagePicker _picker = ImagePicker();

  Petugas? _petugas;
  List<Presensi> _riwayat = [];
  bool _isLoadingProfil = true;
  bool _isUploadingFoto = false;

  // Statistik
  int _totalBulanIni = 0;
  int _jumlahHadir = 0;
  int _jumlahTelat = 0;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    setState(() => _isLoadingProfil = true);
    try {
      final petugas = await _authService.getSesi();
      if (!mounted) return;
      if (petugas == null) {
        _redirectLogin();
        return;
      }

      // Admin tidak perlu statistik presensi (itu bukan hal yang relevan
      // buat akun admin) â€” skip fetch riwayat sama sekali buat hemat request.
      if (petugas.role == 'admin') {
        setState(() {
          _petugas = petugas;
          _riwayat = [];
          _totalBulanIni = 0;
          _jumlahHadir = 0;
          _jumlahTelat = 0;
          _isLoadingProfil = false;
        });
        return;
      }

      // Fetch riwayat untuk statistik pribadi (khusus petugas)
      final riwayat = await _presensiService.fetchRiwayatPresensi(
        idPetugas: petugas.id,
      );
      if (!mounted) return;

      final now = DateTime.now();
      int bulanIni = 0, hadir = 0, telat = 0;
      for (final p in riwayat) {
        try {
          final tgl = DateTime.parse(p.tanggal);
          if (tgl.month == now.month && tgl.year == now.year) {
            bulanIni++;
            if (p.status == 'Hadir') {
              hadir++;
            } else {
              telat++;
            }
          }
        } catch (_) {}
      }

      setState(() {
        _petugas = petugas;
        _riwayat = riwayat;
        _totalBulanIni = bulanIni;
        _jumlahHadir = hadir;
        _jumlahTelat = telat;
        _isLoadingProfil = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfil = false);
    }
  }

  Future<void> _gantiFotoProfil() async {
    if (_petugas == null) return;

    // Pilih sumber: kamera atau galeri
    final sumber = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (sumber == null) return;

    final XFile? picked = await _picker.pickImage(
      source: sumber,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingFoto = true);
    try {
      final petugasBaru = await _authService.uploadFotoProfil(
        _petugas!.id,
        File(picked.path),
      );
      if (mounted) {
        setState(() {
          _petugas = petugasBaru;
          _isUploadingFoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingFoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Dipanggil otomatis kalau sesi ternyata null/invalid (bukan aksi manual
  /// user). TIDAK menampilkan dialog konfirmasi apa pun â€” langsung redirect
  /// diam-diam ke halaman Login.
  Future<void> _redirectLogin() async {
    await _authService.hapusSesi();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
  }

  /// Dipanggil HANYA dari tombol "Logout" yang ditekan user secara manual.
  /// Menampilkan dialog konfirmasi sebelum benar-benar logout.
  Future<void> _logout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    await _authService.hapusSesi();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
  }

  String _formatTanggal(String tanggal) {
    try {
      final dt = DateTime.parse(tanggal);
      return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProfil,
          ),
        ],
      ),
      body: _isLoadingProfil
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfil,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // â”€â”€ Header profil â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withAlpha(180),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          children: [
                            // Foto profil dengan tombol edit
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.white24,
                                  child: _petugas?.fotoProfilUrl != null
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: _petugas!.fotoProfilUrl!,
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            placeholder: (ctx, url) =>
                                                const CircularProgressIndicator(
                                                  color: Colors.white,
                                                ),
                                            errorWidget: (ctx, url, err) =>
                                                const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                ),
                                // Loading overlay saat upload
                                if (_isUploadingFoto)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Tombol edit foto
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _isUploadingFoto
                                        ? null
                                        : _gantiFotoProfil,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(50),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Nama
                            Text(
                              _petugas?.nama ?? '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(120),
                                ),
                              ),
                              child: Text(
                                _petugas?.role.toUpperCase() ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Bergabung sejak
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Bergabung: ${_formatTanggal(_petugas?.bergabungSejak ?? '')}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // â”€â”€ Statistik presensi bulan ini (khusus petugas) â”€â”€
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_petugas?.role != 'admin') ...[
                            Text(
                              'Statistik Bulan Ini',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatBox(
                                    label: 'Total Presensi',
                                    value: '$_totalBulanIni',
                                    icon: Icons.fact_check_outlined,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildStatBox(
                                    label: 'Hadir',
                                    value: '$_jumlahHadir',
                                    icon: Icons.check_circle_outline,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildStatBox(
                                    label: 'Telat',
                                    value: '$_jumlahTelat',
                                    icon: Icons.warning_amber_outlined,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // â”€â”€ Info tambahan â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      Icons.person_outline,
                                      color: colorScheme.primary,
                                    ),
                                    title: const Text('Username'),
                                    trailing: Text(
                                      _petugas?.username ?? '-',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  if (_petugas?.role != 'admin') ...[
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: Icon(
                                        Icons.history,
                                        color: colorScheme.primary,
                                      ),
                                      title: const Text('Total Riwayat'),
                                      trailing: Text(
                                        '${_riwayat.length} presensi',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // â”€â”€ Tombol Logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // â”€â”€ Info app (kecil di bawah) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                          Center(
                            child: Text(
                              'Presensi Kebun Tomat v1.0.0 (UAS)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

