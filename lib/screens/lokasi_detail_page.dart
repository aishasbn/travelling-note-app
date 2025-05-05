// lib/screens/lokasi_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../db/database_helper.dart';
import '../models/lokasi.dart';
import 'tambah_lokasi_page.dart';

class LokasiDetailPage extends StatefulWidget {
  final int lokasiId;

  const LokasiDetailPage({super.key, required this.lokasiId});

  @override
  State<LokasiDetailPage> createState() => _LokasiDetailPageState();
}

class _LokasiDetailPageState extends State<LokasiDetailPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Lokasi? _lokasi;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLokasi();
  }

  Future<void> _loadLokasi() async {
    final lokasi = await _databaseHelper.getLokasi(widget.lokasiId);
    setState(() {
      _lokasi = lokasi;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Detail Lokasi' : _lokasi!.judul),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (!_isLoading && _lokasi != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TambahLokasiPage(lokasi: _lokasi),
                  ),
                );
                _loadLokasi();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lokasi == null
              ? const Center(child: Text('Lokasi tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Map
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 250,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                _lokasi!.latitude,
                                _lokasi!.longitude,
                              ),
                              initialZoom: 14,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.traveling_notes',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      _lokasi!.latitude,
                                      _lokasi!.longitude,
                                    ),
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Info Lokasi
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Lokasi',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _lokasi!.kota,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Koordinat: ${_lokasi!.latitude.toStringAsFixed(6)}, ${_lokasi!.longitude.toStringAsFixed(6)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 30),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Dibuat pada ${_lokasi!.tanggal}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Catatan
                      const Text(
                        'Catatan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _lokasi!.catatan,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}