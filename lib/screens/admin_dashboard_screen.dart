import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dto/petugas.dart';
import '../dto/presensi.dart';
import '../services/presensi_service.dart';
import 'admin_kelola_petugas_screen.dart';
import 'riwayat_presensi_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final PresensiService _service = PresensiService();

  List<Petugas> _semuaPetugas = [];
  List<Presensi> _presensiHariIni = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tanggalHariIni =
          DateFormat('yyyy-MM-dd').format(DateTime.now());
      final results = await Future.wait([
        _service.fetchPetugasList(),
        _service.fetchRiwayatPresensi(tanggal: tanggalHariIni),
      ]);
      if (!mounted) return;
      setState(() {
        _semuaPetugas = results[0] as List<Petugas>;
        _presensiHariIni = results[1] as List<Presensi>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tanggalFormatted =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    // Hitung statistik
    final totalPetugas =
        _semuaPetugas.where((p) => p.role == 'petugas').length;
    final sudahPresensi = _presensiHariIni.length;
    final belumPresensi = (totalPetugas - sudahPresensi).clamp(0, totalPetugas);
    final jumlahHadir =
        _presensiHariIni.where((p) => p.status == 'Hadir').length;
    final jumlahTelat =
        _presensiHariIni.where((p) => p.status == 'Telat').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_outlined,
                            size: 72, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade700, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header tanggal ──────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: colorScheme.primary.withAlpha(60)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.today,
                                  color: colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tanggalFormatted,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Ringkasan Hari Ini ──────────────────────────
                        Text(
                          'Ringkasan Presensi Hari Ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                label: 'Total Petugas',
                                value: '$totalPetugas',
                                icon: Icons.group_outlined,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                label: 'Sudah Presensi',
                                value: '$sudahPresensi',
                                icon: Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                label: 'Belum Presensi',
                                value: '$belumPresensi',
                                icon: Icons.pending_actions_outlined,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                label: 'Hadir',
                                value: '$jumlahHadir',
                                icon: Icons.how_to_reg_outlined,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                label: 'Telat',
                                value: '$jumlahTelat',
                                icon: Icons.warning_amber_outlined,
                                color: Colors.red,
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Aksi Cepat ──────────────────────────────────
                        Text(
                          'Aksi Cepat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.people_outline,
                                      color: Colors.blue.shade700),
                                ),
                                title: const Text('Kelola Akun Petugas'),
                                subtitle: Text(
                                    '${_semuaPetugas.length} akun terdaftar'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminKelolaPetugasScreen(),
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.history_outlined,
                                      color: Colors.green.shade700),
                                ),
                                title: const Text('Riwayat Semua Presensi'),
                                subtitle: const Text(
                                    'Lihat presensi semua petugas'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RiwayatPresensiScreen(
                                            showAll: true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── List presensi hari ini ──────────────────────
                        Text(
                          'Presensi Hari Ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_presensiHariIni.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'Belum ada presensi hari ini',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        else
                          ...(_presensiHariIni.map((p) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: p.status == 'Hadir'
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    child: Icon(
                                      p.status == 'Hadir'
                                          ? Icons.check
                                          : Icons.warning_amber,
                                      color: p.status == 'Hadir'
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  title: Text(p.namaPetugas,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text('Jam: ${p.jam}'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: p.status == 'Hadir'
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: p.status == 'Hadir'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    child: Text(
                                      p.status,
                                      style: TextStyle(
                                        color: p.status == 'Hadir'
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ))),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard({
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
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
