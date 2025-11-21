import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../state/session_manager.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  // Receive the callback so the settings screen can tell main.dart to change theme.
  final Function(bool)? onThemeChanged;

  const SettingsScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Sync theme with current settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = context.read<SessionManager>();
      if (session.settings.darkMode && widget.onThemeChanged != null) {
        widget.onThemeChanged!(true);
      }
    });
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final settings = session.settings;
    final settingsBusy = session.settingsSaving;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: ListView(
          children: [
            _buildSettingsCard(
              title: 'Appearance',
              icon: Icons.palette,
              color: Colors.purple,
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: settings.darkMode,
                  onChanged: settingsBusy
                      ? null
                      : (value) async {
                          // Update theme immediately via callback
                          widget.onThemeChanged?.call(value);
                          
                          // Update settings in SessionManager (which saves to backend)
                          final newSettings = settings.copyWith(darkMode: value);
                          try {
                            await session.updateSettings(newSettings);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save settings: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            // Revert theme change on error
                            widget.onThemeChanged?.call(!value);
                          }
                        },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.format_size),
                  title: const Text('Large Font'),
                  subtitle: const Text('Increase font sizes'),
                  value: settings.largeFont,
                  onChanged: settingsBusy
                      ? null
                      : (value) async {
                          // Update settings in SessionManager (which saves to backend)
                          final newSettings = settings.copyWith(largeFont: value);
                          try {
                            await session.updateSettings(newSettings);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save settings: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              title: 'Account',
              icon: Icons.person,
              color: Colors.indigo,
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    // Show confirmation dialog
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      try {
                        await ApiService.logout();
                        if (!context.mounted) return;
                        // Navigate to login screen and clear navigation stack
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Logout error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Example: Close settings and go back.
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
