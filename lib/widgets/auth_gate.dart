import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';

/// Auth Gate Widget - Routes based on authentication state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<UserProfileProvider>(context);

    // Not authenticated - show login screen
    if (!authProvider.isAuthenticated) {
      if (profileProvider.loadedUserId != null ||
          profileProvider.userProfile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.read<UserProfileProvider>().clearProfile();
        });
      }
      return const LoginScreen();
    }

    // User is authenticated
    final userId = authProvider.user!.id;

    // Load user profile if not loaded yet (non-blocking UI)
    if (!profileProvider.isLoadedFor(userId) && !profileProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<UserProfileProvider>().loadUserProfile(userId);
      });
    }

    // While profile is loading, show the dashboard to reduce perceived load time
    if (profileProvider.isLoading) {
      return const HomeDashboardScreen();
    }

    // If profile doesn't exist, show profile setup screen
    if (profileProvider.userProfile == null) {
      return const ProfileScreen(forceInitialSetup: true);
    }

    // Profile loaded - show main screen
    return const HomeDashboardScreen();
  }
}
