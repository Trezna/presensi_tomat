import 'package:flutter/material.dart';
import '../dto/petugas.dart';
import '../services/presensi_service.dart';

class AdminKelolaPetugasScreen extends StatefulWidget {
  const AdminKelolaPetugasScreen({super.key});

  @override
  State<AdminKelolaPetugasScreen> createState() =>
      _AdminKelolaPetugasScreenState();
}

class _AdminKelolaPetugasScreenState extends State<AdminKelolaPetugasScreen> {
  final PresensiService _service = PresensiService();
  List<Petugas> _list = [];
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
      final data = await _service.fetchPetugasList();
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

  Future<void> _tambahPetugas() async {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    bool showPassword = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Petugas Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setDialogState(() => showPassword = !showPassword),
                    ),
                  ),
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

    final nama = namaCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (nama.isEmpty || username.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nama, username, dan password wajib diisi')),
      );
      return;
    }

    try {
      await _service.addPetugas(
        username: username,
        password: password,
        nama: nama,
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Petugas berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Akun Petugas'),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahPetugas,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah Petugas'),
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
                            style:
                                TextStyle(color: Colors.grey.shade700)),
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
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: _list.length,
                    itemBuilder: (context, index) {
                      final p = _list[index];
                      final isAdmin = p.role == 'admin';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAdmin
                                ? colorScheme.primary.withAlpha(30)
                                : Colors.blue.shade50,
                            child: Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person_outline,
                              color: isAdmin
                                  ? colorScheme.primary
                                  : Colors.blue.shade700,
                            ),
                          ),
                          title: Text(
                            p.nama,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '@${p.username}  •  ${p.role}',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12),
                          ),
                          trailing: isAdmin
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withAlpha(20),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: colorScheme.primary
                                            .withAlpha(80)),
                                  ),
                                  child: Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
