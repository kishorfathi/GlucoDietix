import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  /// Safely notify listeners, deferring if during build phase
  void _safeNotifyListeners() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> loadUserProfile(String userId) async {
    if (_isLoading && _loadedUserId == userId) {
      debugPrint('UserProfileProvider: Already loading profile for $userId');
      return;
    }

    debugPrint('UserProfileProvider: Loading profile for $userId');
    _isLoading = true;
    _loadedUserId = userId;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _userProfile = await _supabaseService.getUserProfile(userId);
      debugPrint(
          'UserProfileProvider: Profile loaded successfully: ${_userProfile != null}');
      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('UserProfileProvider: Error loading profile: $e');
      _errorMessage = e.toString();
      _userProfile = null;
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> saveUserProfile(UserProfile profile) async {
    _isLoading = true;
    _loadedUserId = profile.id;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _supabaseService.upsertUserProfile(profile);
      _userProfile = profile;
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void clearProfile() {
    _userProfile = null;
    _loadedUserId = null;
    _isLoading = false;
    _errorMessage = null;
    _safeNotifyListeners();
  }
}
