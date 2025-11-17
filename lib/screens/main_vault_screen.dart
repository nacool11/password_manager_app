// ==========================================
// FILE: lib/screens/main_vault_screen.dart
// Updated: accepts onThemeChanged and forwards to SettingsScreen
// ==========================================

import 'package:flutter/material.dart';
import 'password_detail_screen.dart';
import 'credit_card_detail_screen.dart';
import 'settings_screen.dart';
import 'security_audit_screen.dart';
import 'password_generator_screen.dart';

class MainVaultScreen extends StatefulWidget {
  // Receive the theme-change callback from main/login and forward to SettingsScreen.
  final Function(bool)? onThemeChanged;

  const MainVaultScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<MainVaultScreen> createState() => _MainVaultScreenState();
}

class _MainVaultScreenState extends State<MainVaultScreen> {
  bool largeFont = false;
  String selectedCategory = 'All Items';

  final categories = [
    {'name': 'All Items', 'icon': Icons.list, 'color': Colors.indigo},
    {'name': 'Passwords', 'icon': Icons.key, 'color': Colors.indigo},
    {'name': 'Credit Cards', 'icon': Icons.credit_card, 'color': Colors.green},
    {'name': 'Secure Notes', 'icon': Icons.note, 'color': Colors.orange},
    {'name': 'Logins', 'icon': Icons.login, 'color': Colors.purple},
  ];

  final vaultItems = [
    {
      'title': 'Google',
      'subtitle': 'email@example.com',
      'type': 'password',
      'id': 1,
    },
    {
      'title': 'Personal Credit Card',
      'subtitle': '**** **** **** 1234',
      'type': 'card',
      'id': 2,
    },
    {'title': 'GitHub', 'subtitle': 'gituser', 'type': 'password', 'id': 3},
    {
      'title': 'Bank Login',
      'subtitle': 'bank_user',
      'type': 'password',
      'id': 4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double largeTitleSize = largeFont ? 20 : 18;
    final double largeFontSize = largeFont ? 16 : 14;

    return Scaffold(
      // Left drawer holds categories; drawer button shows automatically in AppBar.
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.indigo),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    ...categories.map((category) {
                      bool isSelected = selectedCategory == category['name'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEEF2FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: const Color(0xFFC7D2FE))
                              : null,
                        ),
                        child: ListTile(
                          leading: Icon(
                            category['icon'] as IconData,
                            color: category['color'] as Color,
                          ),
                          title: Text(
                            category['name'] as String,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: largeFont ? 16 : 14,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              selectedCategory = category['name'] as String;
                            });
                            // Close drawer after selection
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    }).toList(),
                    const Divider(height: 32),
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.indigo),
                      title: Text(
                        'Add Category',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.w600,
                          fontSize: largeFont ? 16 : 14,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showAddCategoryDialog();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        title: const Text('My Vault'),
        actions: [
          Switch(
            value: largeFont,
            onChanged: (value) {
              setState(() {
                largeFont = value;
              });
            },
            activeColor: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecurityAuditScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.password),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasswordGeneratorScreen(),
                ),
              );
            },
          ),
          // Pass the onThemeChanged callback when opening SettingsScreen.
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(onThemeChanged: widget.onThemeChanged),
                ),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  selectedCategory,
                  style: TextStyle(
                    fontSize: largeTitleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                if (selectedCategory != 'All Items')
                  Chip(
                    backgroundColor: Colors.indigo.shade50,
                    label: Text(selectedCategory),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 4),
                itemCount: vaultItems.length,
                itemBuilder: (context, index) {
                  final item = vaultItems[index];
                  final isCard = item['type'] == 'card';

                  // If you later add a 'category' field to items, filter here:
                  // if (selectedCategory != 'All Items' && item['category'] != selectedCategory) return Container();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isCard
                            ? Colors.green.shade50
                            : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isCard
                            ? Colors.green.shade100
                            : Colors.indigo.shade100,
                        child: Icon(
                          isCard ? Icons.credit_card : Icons.key,
                          color: isCard ? Colors.green : Colors.indigo,
                        ),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: largeFont ? 16 : 14,
                        ),
                      ),
                      subtitle: Text(
                        item['subtitle'] as String,
                        style: TextStyle(fontSize: largeFont ? 14 : 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          if (isCard) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreditCardDetailScreen(
                                      cardName: item['title'] as String,
                                    ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PasswordDetailScreen(
                                      siteName: item['title'] as String,
                                      username: item['subtitle'] as String,
                                    ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddItemDialog();
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Title')),
            TextField(decoration: const InputDecoration(labelText: 'Subtitle')),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Add'),
            onPressed: () {
              // TODO: implement add logic
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Category Name'),
          onSubmitted: (value) {
            // TODO: actually add category to the list/state
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
