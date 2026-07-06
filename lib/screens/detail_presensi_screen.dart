import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../dto/presensi.dart';

class DetailPresensiScreen extends StatelessWidget {
  const DetailPresensiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Menerima data presensi lewat argumen (Kriteria: Routing/Navigation dengan data)
    final Presensi item = ModalRoute.of(context)!.settings.arguments as Presensi;

    // Status langsung dari backend (field item.status sudah dihitung di server)
    final statusText = item.status;
    final statusColor = item.status == 'Hadir' ? Colors.green : Colors.red;

    final hasLocation = item.latitude != null && item.longitude != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Presensi', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Foto Full Size dengan Hero animation + CachedNetworkImage ──
            Hero(
              tag: 'foto-presensi-${item.id}',
              child: CachedNetworkImage(
                imageUrl: item.fotoUrl,
                width: double.infinity,
                height: 350,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 350,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 350,
                  color: Colors.grey.shade300,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 80, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('Gagal memuat foto',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nama & Status ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.namaPetugas,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor, width: 1.5),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.calendar_today, 'Tanggal', item.tanggal),
                  const Divider(),
                  _buildDetailRow(Icons.access_time, 'Jam', item.jam),
                  const Divider(),
                  _buildDetailRow(Icons.fingerprint, 'ID Presensi', '#${item.id}'),

                  // ── Lokasi GPS (jika tersedia) ───────────────────────────
                  if (hasLocation) ...[
                    const Divider(),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'Koordinat',
                      '${item.latitude!.toStringAsFixed(6)}, ${item.longitude!.toStringAsFixed(6)}',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lokasi Presensi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter:
                                LatLng(item.latitude!, item.longitude!),
                            initialZoom: 16,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom |
                                  InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.presensi_kebun_tomat',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                      item.latitude!, item.longitude!),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_pin,
                                      color: Colors.red, size: 40),
                                ),
                              ],
                            ),
                            const RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                    'OpenStreetMap contributors'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(
                            'https://www.google.com/maps?q=${item.latitude},${item.longitude}');
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Buka di Google Maps'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
