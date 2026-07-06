import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dto/jadwal_kerja.dart';
import '../dto/petugas.dart';
import '../services/auth_service.dart';
import '../services/presensi_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PresensiService _service = PresensiService();
  String _currentTime = '';
  late Timer _timer;

  bool _isLoadingStatus = true;
  bool _sudahPresensi = false;
  String _errorMessage = '';

  int _presensiBuilanIni = 0;
  String _terakhirPresensi = '-';

  Petugas? _petugasLogin;

  // Jadwal hari ini (Fitur 2)
  List<JadwalKerja> _jadwalHariIni = [];
  bool _isLoadingJadwal = true;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    _loadData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime =
            DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now());
      });
    }
  }

  Future<void> _loadData() async {
    // Load sesi petugas dulu
    final petugas = await AuthService().getSesi();
    if (!mounted) return;
    setState(() {
      _petugasLogin = petugas;
    });

    // Load status presensi + statistik
    await _checkStatusPresensi();

    // Load jadwal hari ini
    await _loadJadwalHariIni();
  }

  Future<void> _checkStatusPresensi() async {
    setState(() {
      _isLoadingStatus = true;
      _errorMessage = '';
    });

    try {
      final riwayat = await _service.fetchRiwayatPresensi(
        idPetugas: _petugasLogin?.id,
      );
      if (!mounted) return;

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final nowMonth = today.month;
      final nowYear = today.year;

      final sudah = riwayat.any((p) => p.tanggal == todayStr);

      int bulanIni = 0;
      String terakhir = '-';
      for (final p in riwayat) {
        try {
          final tgl = DateTime.parse(p.tanggal);
          if (tgl.month == nowMonth && tgl.year == nowYear) bulanIni++;
        } catch (_) {}
      }
      if (riwayat.isNotEmpty) terakhir = riwayat.first.tanggal;

      setState(() {
        _sudahPresensi = sudah;
        _presensiBuilanIni = bulanIni;
        _terakhirPresensi = terakhir;
        _isLoadingStatus = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingStatus = false;
        });
      }
    }
  }

  Future<void> _loadJadwalHariIni() async {
    setState(() => _isLoadingJadwal = true);
    try {
      final semua = await _service.fetchJadwalKerja();
      if (!mounted) return;
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      setState(() {
        _jadwalHariIni =
            semua.where((j) => j.tanggal == todayStr).toList();
        _isLoadingJadwal = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingJadwal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Presensi'),
        backgroundColor: colorScheme.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Halo, ${_petugasLogin?.nama ?? 'Petugas'} 🌱',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _currentTime,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildJadwalHariIniCard(),
              const SizedBox(height: 16),
              _buildStatistikCard(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _sudahPresensi || _isLoadingStatus
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/presensi').then((_) {
                          _loadData();
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _sudahPresensi
                      ? 'SUDAH PRESENSI HARI INI ✓'
                      : 'PRESENSI SEKARANG',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_isLoadingStatus) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text('Gagal memuat status',
                  style: TextStyle(color: Colors.red.shade900)),
              TextButton(
                onPressed: _loadData,
                child: const Text('Coba Lagi'),
              )
            ],
          ),
        ),
      );
    }

    return Card(
      color: _sudahPresensi
          ? Colors.lightGreen.shade100
          : Colors.orange.shade100,
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            Icon(
              _sudahPresensi
                  ? Icons.check_circle_outline
                  : Icons.pending_actions,
              size: 56,
              color: _sudahPresensi
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
            const SizedBox(height: 12),
            Text(
              _sudahPresensi
                  ? 'Sudah Presensi Hari Ini'
                  : 'Belum Presensi Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _sudahPresensi
                    ? Colors.green.shade900
                    : Colors.orange.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Jadwal Hari Ini section
  Widget _buildJadwalHariIniCard() {
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Jadwal Hari Ini',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoadingJadwal)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_jadwalHariIni.isEmpty)
              Text(
                'Tidak ada jadwal hari ini',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13),
              )
            else
              ...(_jadwalHariIni.map((j) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${j.jamMulai}–${j.jamSelesai}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            j.judul,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikCard() {
    if (_isLoadingStatus || _errorMessage.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.calendar_month_outlined,
                label: 'Bulan Ini',
                value: '$_presensiBuilanIni kali',
                color: Colors.teal,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade300),
            Expanded(
              child: _buildStatItem(
                icon: Icons.history_outlined,
                label: 'Terakhir Presensi',
                value: _terakhirPresensi,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
