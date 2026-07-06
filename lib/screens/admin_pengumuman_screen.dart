import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dto/pengumuman.dart';
import '../services/presensi_service.dart';

class AdminPengumumanScreen extends StatefulWidget {
  const AdminPengumumanScreen({super.key});

  @override
  State<AdminPengumumanScreen> createState() => _AdminPengumumanScreenState();
}

class _AdminPengumumanScreenState extends State<AdminPengumumanScreen> {
  final PresensiService _service = PresensiService();
  List<Pengumuman> _list = [];
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
      final data = await _service.fetchPengumuman();
      if (!mounted) return;
      setState(() {
        _list = data;
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

  Future<void> _tambahPengumuman() async {
    final judulCtrl = TextEditingController();
    final isiCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Pengumuman'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: judulCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: isiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Isi Pengumuman',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
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
    );

    if (result != true) return;

    final judul = judulCtrl.text.trim();
    final isi = isiCtrl.text.trim();
    if (judul.isEmpty || isi.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan isi tidak boleh kosong')),
      );
      return;
    }

    try {
      await _service.addPengumuman(judul: judul, isi: isi);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengumuman berhasil ditambahkan'),
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

  Future<void> _hapusPengumuman(Pengumuman p) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengumuman'),
        content: Text('Yakin ingin menghapus "${p.judul}"?'),
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
      await _service.deletePengumuman(p.id);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengumuman berhasil dihapus'),
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

  String _formatTanggal(String tanggal) {
    try {
      final dt = DateTime.parse(tanggal);
      return DateFormat('d MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengumuman'),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahPengumuman,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
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
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700)),
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
              : _list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign_outlined,
                              size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada pengumuman',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: _list.length,
                        itemBuilder: (context, index) {
                          final item = _list[index];
                          return Dismissible(
                            key: Key('pengumuman-${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (_) async {
                              final konfirmasi = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Pengumuman'),
                                  content: Text(
                                      'Yakin ingin menghapus "${item.judul}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              return konfirmasi == true;
                            },
                            onDismissed: (_) => _hapusPengumuman(item),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.judul,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20),
                                          onPressed: () =>
                                              _hapusPengumuman(item),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.isi,
                                      style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                          height: 1.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 12,
                                            color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTanggal(item.tanggal),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
