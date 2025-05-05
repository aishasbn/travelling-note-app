// lib/screens/tambah_lokasi_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/lokasi.dart';
import '../services/lokasi_service.dart';

class TambahLokasiPage extends StatefulWidget {
  final Lokasi? lokasi;

  const TambahLokasiPage({super.key, this.lokasi});

  @override
  State<TambahLokasiPage> createState() => _TambahLokasiPageState();
}

class _TambahLokasiPageState extends State<TambahLokasiPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _catatanController = TextEditingController();
  final _searchController = TextEditingController();
  
  final LokasiService _lokasiService = LokasiService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSearching = false;
  String _kota = 'Mencari lokasi...';
  double _latitude = 0.0;
  double _longitude = 0.0;
  late MapController _mapController;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isPinDraggable = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    if (widget.lokasi != null) {
      // Edit mode
      _judulController.text = widget.lokasi!.judul;
      _catatanController.text = widget.lokasi!.catatan;
      _latitude = widget.lokasi!.latitude;
      _longitude = widget.lokasi!.longitude;
      _kota = widget.lokasi!.kota;
      _isLoading = false;
    } else {
      // Create mode - get current location
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _lokasiService.getCurrentPosition();
      final kota = await _lokasiService.getKotaFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _kota = kota;
          _isLoading = false;
        });
        
        _mapController.move(LatLng(_latitude, _longitude), 13);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _kota = 'Tidak dapat menemukan lokasi';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _searchLocations() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() => _isSearching = true);
    
    try {
      final results = await _lokasiService.searchLocation(_searchController.text);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectLocation(double lat, double lng) async {
    setState(() {
      _latitude = lat;
      _longitude = lng;
      _kota = 'Memuat nama lokasi...';
      _searchResults = [];
      _searchController.clear();
    });
    
    _mapController.move(LatLng(lat, lng), 13);
    
    try {
      final kota = await _lokasiService.getKotaFromCoordinates(lat, lng);
      if (mounted) {
        setState(() {
          _kota = kota;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _kota = 'Tidak dapat menemukan nama lokasi';
        });
      }
    }
  }
  
  void _onTapMap(TapPosition tapPosition, LatLng point) {
    if (_isPinDraggable) {
      _selectLocation(point.latitude, point.longitude);
    }
  }

  Future<void> _saveLokasi() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final now = DateTime.now();
      final tanggal = DateFormat('dd MMM yyyy, HH:mm').format(now);
      
      final lokasi = Lokasi(
        id: widget.lokasi?.id,
        judul: _judulController.text,
        catatan: _catatanController.text,
        latitude: _latitude,
        longitude: _longitude,
        kota: _kota,
        tanggal: tanggal,
      );
      
      if (widget.lokasi == null) {
        await _databaseHelper.insertLokasi(lokasi);
      } else {
        await _databaseHelper.updateLokasi(lokasi);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan lokasi berhasil disimpan')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lokasi == null ? 'Tambah Catatan Lokasi' : 'Edit Catatan Lokasi'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Searching location
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Cari Lokasi',
                              hintText: 'Masukkan nama tempat...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchResults = [];
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) {
                                setState(() => _searchResults = []);
                              }
                            },
                            onSubmitted: (_) => _searchLocations(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSearching ? null : _searchLocations,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Cari'),
                        ),
                      ],
                    ),
                    
                    // Search results
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              title: Text(
                                result['name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Lat: ${result['latitude'].toStringAsFixed(4)}, Lng: ${result['longitude'].toStringAsFixed(4)}',
                              ),
                              onTap: () {
                                _selectLocation(
                                  result['latitude'],
                                  result['longitude'],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Toggle untuk fitur tap lokasi pada peta
                    Row(
                      children: [
                        Switch(
                          value: _isPinDraggable,
                          onChanged: (value) {
                            setState(() {
                              _isPinDraggable = value;
                            });
                          },
                        ),
                        const Text("Aktifkan pilih lokasi di peta"),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text("Lokasi Saya"),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Map
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(_latitude, _longitude),
                            initialZoom: 13,
                            onTap: _onTapMap,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.traveling_notes',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_latitude, _longitude),
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
                    const SizedBox(height: 16),
                    
                    // Lokasi terpilih
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lokasi Terpilih',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _kota,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Koordinat: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Form fields
                    TextFormField(
                      controller: _judulController,
                      decoration: const InputDecoration(
                        labelText: 'Judul',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _catatanController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Catatan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Button
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveLokasi,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving ? 'Menyimpan...' : 'Simpan Catatan Lokasi',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _judulController.dispose();
    _catatanController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}