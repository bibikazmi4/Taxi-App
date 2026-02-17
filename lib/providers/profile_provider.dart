import 'package:flutter/material.dart';

import '../models/profile_model.dart';
import '../services/database_service.dart';

class ProfileProvider extends ChangeNotifier {
  final DatabaseService _db;

  ProfileProvider(this._db) {
    // Load immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      load();
    });
  }

  ProfileModel? _profile;
  ProfileModel? get profile => _profile;

  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Try to get from database
      final savedProfile = await _db.getProfile();

      if (savedProfile != null) {
        _profile = savedProfile;
      } else {
        // Create default profile
        _profile = const ProfileModel(
          name: "User",
          phone: "+92 300 0000000",
          email: "user@example.com",
        );
        // Save default to database
        await _db.saveProfile(_profile!);
      }
    } catch (e) {
      error = "Failed to load profile: ${e.toString()}";
      // Even on error, provide a default
      _profile = const ProfileModel(
        name: "User",
        phone: "+92 300 0000000",
        email: "user@example.com",
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(ProfileModel updated) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _db.saveProfile(updated);
      _profile = updated;
    } catch (e) {
      error = "Failed to save profile: ${e.toString()}";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
