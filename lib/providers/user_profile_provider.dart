import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

/// User Profile Provider
class UserProfileProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  UserProfile? _userProfile;
  String? _loadedUserId;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get userProfile => _userProfile;
  String? get loadedUserId => _loadedUserId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool isLoadedFor(String userId) => _loadedUserId == userId;

  Future<void> loadUserProfile(String userId) async {
    if (_isLoading && _loadedUserId == userId) return;

    _isLoading = true;
    _loadedUserId = userId;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _supabaseService.getUserProfile(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveUserProfile(UserProfile profile) async {
    _isLoading = true;
    _loadedUserId = profile.id;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.upsertUserProfile(profile);
      _userProfile = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearProfile() {
    _userProfile = null;
    _loadedUserId = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
