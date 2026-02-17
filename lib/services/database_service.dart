import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/profile_model.dart';
import '../models/ride_model.dart';

class DatabaseService {
  static const _dbName = 'swiftride.db';
  static const _ridesTable = 'rides';
  static const _profileTable = 'profile';

  Database? _db;

  // For web/desktop fallback
  Map<String, dynamic> _inMemoryProfile = {};
  List<Map<String, dynamic>> _inMemoryRides = [];

  Future<Database?> _open() async {
    // Skip database on web/desktop
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return null;
    }

    if (_db != null) return _db!;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, _dbName);

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_ridesTable(
              id TEXT PRIMARY KEY,
              createdAt TEXT NOT NULL,
              payload TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE $_profileTable(
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              phone TEXT NOT NULL,
              email TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
        },
      );
      return _db!;
    } catch (e) {
      print("Database error: $e");
      return null;
    }
  }

  // --------------------- PROFILE ---------------------

  Future<ProfileModel?> getProfile() async {
    final db = await _open();

    if (db == null) {
      // In-memory storage for web/desktop
      if (_inMemoryProfile.isEmpty) {
        return const ProfileModel(
          name: "User",
          phone: "+92 300 0000000",
          email: "user@example.com",
        );
      }
      return ProfileModel.fromMap(_inMemoryProfile);
    }

    try {
      final rows = await db.query(_profileTable,
          where: 'id = ?', whereArgs: [1], limit: 1);

      if (rows.isEmpty) {
        return null;
      }

      return ProfileModel.fromMap(rows.first);
    } catch (e) {
      print("Error loading profile: $e");
      return null;
    }
  }

  Future<void> saveProfile(ProfileModel profile) async {
    final db = await _open();

    if (db == null) {
      // In-memory storage for web/desktop
      _inMemoryProfile = profile.toMap();
      _inMemoryProfile['updatedAt'] = DateTime.now().toIso8601String();
      return;
    }

    try {
      await db.insert(
        _profileTable,
        {
          'id': 1,
          'name': profile.name,
          'phone': profile.phone,
          'email': profile.email,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error saving profile: $e");
      rethrow;
    }
  }

  // --------------------- RIDES ---------------------

  Future<void> saveRide(RideModel ride) async {
    final db = await _open();

    if (db == null) {
      // In-memory storage for web/desktop
      _inMemoryRides.add({
        'id': ride.id,
        'createdAt': ride.createdAt.toIso8601String(),
        'payload': jsonEncode(ride.toJson()),
      });
      return;
    }

    try {
      await db.insert(
        _ridesTable,
        {
          'id': ride.id,
          'createdAt': ride.createdAt.toIso8601String(),
          'payload': jsonEncode(ride.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error saving ride: $e");
      rethrow;
    }
  }

  Future<List<RideModel>> getRides() async {
    final db = await _open();

    if (db == null) {
      // In-memory storage for web/desktop
      return _inMemoryRides.map((row) {
        try {
          final payload = row['payload'] as String;
          return RideModel.fromJson(
              jsonDecode(payload) as Map<String, dynamic>);
        } catch (e) {
          throw Exception("Failed to parse ride data");
        }
      }).toList();
    }

    try {
      final rows = await db.query(_ridesTable, orderBy: 'createdAt DESC');

      return rows.map((row) {
        try {
          final payload = row['payload'] as String;
          return RideModel.fromJson(
              jsonDecode(payload) as Map<String, dynamic>);
        } catch (e) {
          throw Exception("Failed to parse ride data");
        }
      }).toList();
    } catch (e) {
      print("Error loading rides: $e");
      return [];
    }
  }

  // Other methods
  Future<void> upsertRide(RideModel ride) async => saveRide(ride);

  Future<void> deleteRide(String id) async {
    final db = await _open();
    if (db == null) {
      _inMemoryRides.removeWhere((ride) => ride['id'] == id);
      return;
    }
    await db.delete(_ridesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearRides() async {
    final db = await _open();
    if (db == null) {
      _inMemoryRides.clear();
      return;
    }
    await db.delete(_ridesTable);
  }

  Future<void> deleteProfile() async {
    final db = await _open();
    if (db == null) {
      _inMemoryProfile.clear();
      return;
    }
    await db.delete(_profileTable, where: 'id = ?', whereArgs: [1]);
  }
}
