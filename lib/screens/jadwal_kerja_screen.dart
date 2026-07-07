import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../dto/jadwal_kerja.dart';
import '../services/presensi_service.dart';

class JadwalKerjaScreen extends StatefulWidget {
  /// Kalau true, tampilkan tombol tambah/hapus jadwal (mode admin).
  final bool isAdmin;
  const JadwalKerjaScreen({super.key, this.isAdmin = false});

  @override
  State<JadwalKerjaScreen> createState() => _JadwalKerjaScreenState();
}

class _JadwalKerjaScreenState extends State<JadwalKerjaScreen> {
  final PresensiService _service = PresensiService();

  List<JadwalKerja> _allJadwal = [];
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchJadwal();
  }

  Future<void> _fetchJadwal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.fetchJadwalKerja();
      if (mounted) {
        setState(() {
          _allJadwal = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('SocketException') ||
            msg.contains('Connection refused') ||
            msg.contains('Failed host lookup')) {
          msg =
              'Tidak dapat terhubung ke server.\nPastikan backend sedang berjalan.';
        }
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      }
    }
  }

  String _formatTanggal(DateTime day) {
    return DateFormat('yyyy-MM-dd').format(day);
  }

  List<JadwalKerja> _getJadwalForDay(DateTime day) {
    final tanggal = _formatTanggal(day);
    return _allJadwal.where((j) => j.tanggal == tanggal).toList();
  }

  // ── Admin: Tambah Jadwal ─────────────────────────────────────────────────

  Future<void> _tambahJadwal() async {
    final judulCtrl = TextEditingController();
    final jamMulaiCtrl = TextEditingController(text: '07:00');
    final jamSelesaiCtrl = TextEditingController(text: '08:00');
    final keteranganCtrl = TextEditingController();
    DateTime tanggalDipilih = _selectedDay;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Jadwal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanggal
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Tanggal'),
                  subtitle: Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(tanggalDipilih),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: tanggalDipilih,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2028),
                    );
                    if (picked != null) {
                      setDialogState(() => tanggalDipilih = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: judulCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul Jadwal',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: jamMulaiCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Jam Mulai',
                          border: OutlineInputBorder(),
                          hintText: '07:00',
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: jamSelesaiCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Jam Selesai',
                          border: OutlineInputBorder(),
                          hintText: '08:00',
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: keteranganCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final judul = judulCtrl.text.trim();
    final jamMulai = jamMulaiCtrl.text.trim();
    final jamSelesai = jamSelesaiCtrl.text.trim();
    final keterangan = keteranganCtrl.text.trim();

    if (judul.isEmpty || jamMulai.isEmpty || jamSelesai.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan jam wajib diisi')),
      );
      return;
    }

    try {
      await _service.addJadwal(
        tanggal: DateFormat('yyyy-MM-dd').format(tanggalDipilih),
        judul: judul,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        keterangan: keterangan,
      );
      await _fetchJadwal();
      // Setelah tambah, pilih hari yang baru ditambahkan
      setState(() {
        _selectedDay = tanggalDipilih;
        _focusedDay = tanggalDipilih;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _hapusJadwal(JadwalKerja jadwal) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Yakin ingin menghapus "${jadwal.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      await _service.deleteJadwal(jadwal.id);
      await _fetchJadwal();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final jadwalTerpilih = _getJadwalForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kerja'),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchJadwal,
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _tambahJadwal,
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _fetchJadwal,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // ── Kalender ──────────────────────────────────────────
                TableCalendar<JadwalKerja>(
                  locale: 'id_ID',
                  firstDay: DateTime.utc(2026, 1, 1),
                  lastDay: DateTime.utc(2027, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getJadwalForDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(80),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(color: colorScheme.primary),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
                const Divider(height: 1),
                // ── Header tanggal terpilih ────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(_selectedDay),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${jadwalTerpilih.length} jadwal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── List jadwal ───────────────────────────────────────
                Expanded(
                  child: jadwalTerpilih.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada jadwal\ndi tanggal ini',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                ),
                              ),
                              if (widget.isAdmin) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _tambahJadwal,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Jadwal'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchJadwal,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            itemCount: jadwalTerpilih.length,
                            itemBuilder: (context, index) {
                              final jadwal = jadwalTerpilih[index];
                              return _buildJadwalCard(jadwal);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildJadwalCard(JadwalKerja jadwal) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jam badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    jadwal.jamMulai,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '│',
                    style: TextStyle(color: colorScheme.primary.withAlpha(100)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jadwal.jamSelesai,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Konten jadwal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal.judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (jadwal.keterangan.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      jadwal.keterangan,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Tombol hapus (hanya mode admin)
            if (widget.isAdmin)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _hapusJadwal(jadwal),
                tooltip: 'Hapus jadwal',
              ),
          ],
        ),
      ),
    );
  }
}
