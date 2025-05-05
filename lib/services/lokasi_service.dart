// lib/services/lokasi_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LokasiService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah layanan lokasi diaktifkan
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi dinonaktifkan.');
    }

    // Cek izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak secara permanen.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
  }

  Future<String> getKotaFromCoordinates(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=10'
    );
    
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'}
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['address'];
      
      String lokasi = address['city'] ?? 
                     address['town'] ?? 
                     address['village'] ?? 
                     address['suburb'] ?? 
                     address['county'] ?? 
                     'Lokasi tidak diketahui';
                     
      return "$lokasi, ${address['country'] ?? ''}";
    } else {
      return 'Lokasi tidak diketahui';
    }
  }

  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5'
    );
    
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'}
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) {
        return {
          'name': item['display_name'],
          'latitude': double.parse(item['lat']),
          'longitude': double.parse(item['lon']),
        };
      }).toList();
    } else {
      return [];
    }
  }
}