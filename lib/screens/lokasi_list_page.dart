// lib/screens/lokasi_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../db/database_helper.dart';
import '../models/lokasi.dart';
import 'tambah_lokasi_page.dart';
import 'lokasi_detail_page.dart';

class LokasiListPage extends StatefulWidget {
  const LokasiListPage({super.key});

  @override
  State<LokasiListPage> createState() => _LokasiListPageState();
}

class _LokasiListPageState extends State<LokasiListPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Lokasi> _lokasiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshLokasiList();
  }

  Future<void> _refreshLokasiList() async {
    setState(() => _isLoading = true);
    final lokasiList = await _databaseHelper.getLokasiList();
    setState(() {
      _lokasiList = lokasiList;
      _isLoading = false;
    });
  }

  Future<void> _deleteLokasi(int id) async {
    await _databaseHelper.deleteLokasi(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan lokasi berhasil dihapus')),
    );
    _refreshLokasiList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travelling Notes'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lokasiList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada catatan lokasi',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TambahLokasiPage(),
                            ),
                          );
                          _refreshLokasiList();
                        },
                        icon: const Icon(Icons.add_location),
                        label: const Text('Tambah Catatan Lokasi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshLokasiList,
                  child: ListView.builder(
                    itemCount: _lokasiList.length,
                    itemBuilder: (context, index) {
                      final lokasi = _lokasiList[index];
                      return Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _deleteLokasi(lokasi.id!),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Hapus',
                            ),
                          ],
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(
                              lokasi.judul,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        lokasi.kota,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 4),
                                    Text(lokasi.tanggal),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LokasiDetailPage(
                                    lokasiId: lokasi.id!,
                                  ),
                                ),
                              );
                              _refreshLokasiList();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TambahLokasiPage()),
          );
          _refreshLokasiList();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}