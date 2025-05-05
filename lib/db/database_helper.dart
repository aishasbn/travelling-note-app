// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lokasi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'traveling_notes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lokasi(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT,
        catatan TEXT,
        latitude REAL,
        longitude REAL,
        kota TEXT,
        tanggal TEXT
      )
    ''');
  }

  Future<int> insertLokasi(Lokasi lokasi) async {
    Database db = await database;
    return await db.insert('lokasi', lokasi.toMap());
  }

  Future<List<Lokasi>> getLokasiList() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('lokasi');
    return List.generate(maps.length, (i) {
      return Lokasi.fromMap(maps[i]);
    });
  }

  Future<Lokasi?> getLokasi(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'lokasi',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Lokasi.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateLokasi(Lokasi lokasi) async {
    Database db = await database;
    return await db.update(
      'lokasi',
      lokasi.toMap(),
      where: 'id = ?',
      whereArgs: [lokasi.id],
    );
  }

  Future<int> deleteLokasi(int id) async {
    Database db = await database;
    return await db.delete(
      'lokasi',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}