import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../taskroom/providers/project_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isDarkMode = false;
  final Map<String, bool> _projectNotifPrefs = {};

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(
      text: authProvider.currentUser?.name ?? '',
    );
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );
    for (var project in projectProvider.userProjects) {
      _projectNotifPrefs[project.id] =
          prefs.getBool('notif_${project.id}') ?? true;
    }
  }

  Future<void> _saveNotifPref(String projectId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$projectId', value);
    setState(() {
      _projectNotifPrefs[projectId] = value;
    });
  }

  Future<void> _saveThemePref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text('Are you sure? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteAccount();
      if (success && context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Failed to delete account',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    if (_formKey.currentState!.validate()) {
      final success = await authProvider.updateProfile(_nameController.text);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Failed to update profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Settings', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Text(
                'Profile',
                style: AppTextStyles.heading3.copyWith(
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontFamily: 'Montserrat',
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Name cannot be empty'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: user.email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontFamily: 'Montserrat',
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              () => _updateProfile(context, authProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: AppTextStyles.button.copyWith(
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Notification Preferences
              Text(
                'Notification Preferences',
                style: AppTextStyles.heading3.copyWith(
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children:
                      projectProvider.userProjects
                          .map(
                            (project) => SwitchListTile(
                              title: Text(
                                project.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              value: _projectNotifPrefs[project.id] ?? true,
                              onChanged:
                                  (value) => _saveNotifPref(project.id, value),
                              activeColor: AppColors.primary,
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 24),
              // Theme
              Text(
                'Appearance',
                style: AppTextStyles.heading3.copyWith(
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  value: _isDarkMode,
                  onChanged: _saveThemePref,
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              // Delete Account
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _deleteAccount(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Delete Account',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.error,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
