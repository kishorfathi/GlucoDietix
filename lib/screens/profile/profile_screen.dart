import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/user_profile.dart';
import '../../widgets/loading_indicator.dart';

/// Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _diabetes = false;
  String _glucoseRange = 'normal';
  bool _cholesterolConcern = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);

    if (authProvider.user != null) {
      await profileProvider.loadUserProfile(authProvider.user!.id);

      if (profileProvider.userProfile != null && mounted) {
        setState(() {
          _diabetes = profileProvider.userProfile!.diabetes;
          _glucoseRange = profileProvider.userProfile!.glucoseRange;
          _cholesterolConcern = profileProvider.userProfile!.cholesterolConcern;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);

      if (authProvider.user != null) {
        final profile = UserProfile(
          id: authProvider.user!.id,
          diabetes: _diabetes,
          glucoseRange: _glucoseRange,
          cholesterolConcern: _cholesterolConcern,
        );

        final success = await profileProvider.saveUserProfile(profile);

        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  profileProvider.errorMessage ?? 'Failed to save profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: profileProvider.isLoading
          ? const LoadingIndicator()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Health Information',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Do you have diabetes?'),
                      value: _diabetes,
                      onChanged: (value) {
                        setState(() {
                          _diabetes = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Glucose Range:'),
                    RadioListTile<String>(
                      title: const Text('Low'),
                      value: 'low',
                      groupValue: _glucoseRange,
                      onChanged: (value) {
                        setState(() {
                          _glucoseRange = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Normal'),
                      value: 'normal',
                      groupValue: _glucoseRange,
                      onChanged: (value) {
                        setState(() {
                          _glucoseRange = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('High'),
                      value: 'high',
                      groupValue: _glucoseRange,
                      onChanged: (value) {
                        setState(() {
                          _glucoseRange = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Cholesterol Concern?'),
                      value: _cholesterolConcern,
                      onChanged: (value) {
                        setState(() {
                          _cholesterolConcern = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
