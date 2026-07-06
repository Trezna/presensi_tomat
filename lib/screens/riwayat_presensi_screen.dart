import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../dto/presensi.dart';
import '../services/auth_service.dart';
import '../services/presensi_service.dart';

class RiwayatPresensiScreen extends StatefulWidget {
  /// Kalau true, tampilkan riwayat semua petugas (mode admin).
  final bool showAll;
  const RiwayatPresensiScreen({super.key, this.showAll = false});

  @override
  State<RiwayatPresensiScreen> createState() => _RiwayatPresensiScreenState();
}

class _RiwayatPresensiScreenState extends State<RiwayatPresensiScreen> {
  final PresensiService _service = PresensiService();
  late Future<List<Presensi>> _futureRiwayat;
  int? _idPetugasLogin;

  @override
  void initState() {
    super.initState();
    _initRiwayat();
  }

  Future<void> _initRiwayat() async {
    if (widget.showAll) {
      // Admin: tampilkan semua tanpa filter id
      setState(() {
        _futureRiwayat = _service.fetchRiwayatPresensi();
      });
      return;
    }
    final petugas = await AuthService().getSesi();
    if (!mounted) return;
    setState(() {
      _idPetugasLogin = petugas?.id;
      _futureRiwayat = _service.fetchRiwayatPresensi(idPetugas: _idPetugasLogin);
    });
  }

  void _refreshData() {
    setState(() {
      if (widget.showAll) {
        _futureRiwayat = _service.fetchRiwayatPresensi();
      } else {
        _futureRiwayat = _service.fetchRiwayatPresensi(idPetugas: _idPetugasLogin);
      }
    });
  }

  String _pesanError(Object? error) {
    final msg = error?.toString() ?? '';
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('Network is unreachable') ||
        msg.contains('Failed host lookup')) {
      return 'Tidak dapat terhubung ke server.\nPastikan backend sedang berjalan dan emulator terhubung ke jaringan.';
    }
    if (msg.contains('HTTP')) {
      return 'Server mengembalikan error. Coba beberapa saat lagi.';
    }
    return 'Terjadi kesalahan. Coba tarik ke bawah untuk memuat ulang.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showAll ? 'Riwayat Semua Presensi' : 'Riwayat Presensi',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          )
        ],
      ),
      body: FutureBuilder<List<Presensi>>(
        future: _futureRiwayat,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 72, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      _pesanError(snapshot.error),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _refreshData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat presensi.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];

                // Task 1: Status langsung dari backend, tidak dihitung ulang dari jam
                final statusText = item.status;
                final statusColor = item.status == 'Hadir'
                    ? Colors.green
                    : Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pushNamed(context, '/detail_presensi', arguments: item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Task 7 (Hero) + Task 8 (foto lebih besar + rounded)
                          Hero(
                            tag: 'foto-presensi-${item.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: item.fotoUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.namaPetugas,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.tanggal}  •  ${item.jam}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
