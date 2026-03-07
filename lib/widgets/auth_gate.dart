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

    if (!authProvider.isAuthenticated) {
      if (profileProvider.loadedUserId != null || profileProvider.userProfile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.read<UserProfileProvider>().clearProfile();
        });
      }
      return const LoginScreen();
    }

    final userId = authProvider.user!.id;

    if (!profileProvider.isLoadedFor(userId) && !profileProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<UserProfileProvider>().loadUserProfile(userId);
      });
      return const Scaffold(body: SafeArea(child: LoadingIndicator()));
    }

    if (profileProvider.isLoading && profileProvider.isLoadedFor(userId)) {
      return const Scaffold(body: SafeArea(child: LoadingIndicator()));
    }

    if (profileProvider.userProfile == null) {
      return const ProfileScreen(forceInitialSetup: true);
    }

    return const MealBuilderScreen();
  }
}
