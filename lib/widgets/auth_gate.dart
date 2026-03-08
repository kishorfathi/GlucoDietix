import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/meal/meal_builder_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/loading_indicator.dart';

/// Auth Gate Widget - Routes based on authentication state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<UserProfileProvider>(context);

    debugPrint('AuthGate: isAuthenticated=${authProvider.isAuthenticated}');
    debugPrint('AuthGate: isLoading=${profileProvider.isLoading}');
    debugPrint('AuthGate: hasProfile=${profileProvider.userProfile != null}');

    // Not authenticated - show login screen
    if (!authProvider.isAuthenticated) {
      debugPrint('AuthGate: Showing LoginScreen');
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
    debugPrint('AuthGate: Authenticated userId=$userId');

    // Load user profile if not loaded yet
    if (!profileProvider.isLoadedFor(userId) && !profileProvider.isLoading) {
      debugPrint('AuthGate: Loading profile for $userId');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<UserProfileProvider>().loadUserProfile(userId);
      });
      return const Scaffold(
        body: SafeArea(
          child: LoadingIndicator(),
        ),
      );
    }

    // Show loading while profile is being fetched
    if (profileProvider.isLoading) {
      debugPrint('AuthGate: Showing loading indicator');
      return const Scaffold(
        body: SafeArea(
          child: LoadingIndicator(),
        ),
      );
    }

    // If profile doesn't exist, show profile setup screen
    if (profileProvider.userProfile == null) {
      debugPrint('AuthGate: No profile found, showing ProfileScreen');
      return const ProfileScreen(forceInitialSetup: true);
    }

    // Profile loaded - show main screen
    debugPrint('AuthGate: Showing MealBuilderScreen');
    return const MealBuilderScreen();
  }
}
