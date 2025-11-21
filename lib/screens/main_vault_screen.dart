import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/vault_item.dart';
import '../state/session_manager.dart';
import 'credit_card_detail_screen.dart';
import 'password_detail_screen.dart';
import 'password_generator_screen.dart';
import 'security_audit_screen.dart';
import 'settings_screen.dart';

class MainVaultScreen extends StatefulWidget {
  const MainVaultScreen({Key? key}) : super(key: key);

  @override
  State<MainVaultScreen> createState() => _MainVaultScreenState();
}

class _MainVaultScreenState extends State<MainVaultScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionManager>().ensureVaultLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final largeFont = session.settings.largeFont;
    final settingsBusy = session.settingsSaving;
    final filteredItems = _filterItems(session.items);

    return Scaffold(
      drawer: _VaultDrawer(
        categories: session.categories,
        selectedCategory: _selectedCategoryId,
        largeFont: largeFont,
        onCategorySelected: (value) {
          setState(() {
            _selectedCategoryId = value;
          });
        },
        onAddCategory: _showAddCategoryDialog,
      ),
      appBar: AppBar(
        title: const Text('My Vault'),
        actions: [
          Switch(
            value: largeFont,
            onChanged: settingsBusy
                ? null
                : (value) {
              final newSettings =
              session.settings.copyWith(largeFont: value);
              session.updateSettings(newSettings);
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
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
                  _selectedCategoryTitle(session.categories),
                  style: TextStyle(
                    fontSize: largeFont ? 20 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: session.loading
                      ? null
                      : () => session.loadVault(),
                  icon: session.loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => session.loadVault(),
                child: filteredItems.isEmpty
                    ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text('No items yet, add one to get started'),
                    ),
                  ],
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isCard = item.isCard;
                    final subtitle = _itemSubtitle(item);
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
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: largeFont ? 16 : 14,
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: largeFont ? 14 : 12,
                          ),
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
                                        cardName: item.title,
                                        item: item,
                                      ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PasswordDetailScreen(
                                        siteName: item.title,
                                        username: item.data?['username']?.toString() ?? '',
                                        item: item,
                                      ),
                                ),
                              );
                            }
                          },
                        ),
                        onLongPress: () => _confirmDelete(item),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemSheet,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  List<VaultItem> _filterItems(List<VaultItem> items) {
    if (_selectedCategoryId == null) return items;
    return items
        .where((item) => item.categoryId == _selectedCategoryId)
        .toList();
  }

  String _selectedCategoryTitle(List<CategoryModel> categories) {
    if (_selectedCategoryId == null) return 'All Items';
    final cat = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
      orElse: () => CategoryModel(id: '', name: 'All Items'),
    );
    return cat.name;
  }

  String _itemSubtitle(VaultItem item) {
    if (item.subtitle != null && item.subtitle!.isNotEmpty) {
      return item.subtitle!;
    }
    final data = item.data ?? {};
    if (item.isCard) {
      return data['cardholderName']?.toString() ??
          data['cardNumber']?.toString() ??
          'Credit Card';
    }
    return data['username']?.toString() ??
        data['email']?.toString() ??
        data['login']?.toString() ??
        'Password';
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    final session = context.read<SessionManager>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Category Name'),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(dialogContext);
                _createCategory(value.trim(), session, scaffoldMessenger);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(dialogContext);
                _createCategory(value, session, scaffoldMessenger);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((_) {
      // Dispose controller after dialog is closed
      controller.dispose();
    });
  }

  Future<void> _createCategory(
    String name,
    SessionManager session,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    try {
      await session.createCategory(name: name);
    } catch (err) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(err.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: _AddItemForm(
          defaultCategory: _selectedCategoryId,
        ),
      ),
    );
  }

  void _confirmDelete(VaultItem item) {
    final session = context.read<SessionManager>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete ${item.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await session.deleteItem(item.id);
              if (!mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _VaultDrawer extends StatelessWidget {
  const _VaultDrawer({
    required this.categories,
    required this.selectedCategory,
    required this.largeFont,
    required this.onCategorySelected,
    required this.onAddCategory,
  });

  final List<CategoryModel> categories;
  final String? selectedCategory;
  final bool largeFont;
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: largeFont ? 22 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  _CategoryTile(
                    name: 'All Items',
                    isSelected: selectedCategory == null,
                    largeFont: largeFont,
                    icon: Icons.list,
                    color: Colors.indigo,
                    onTap: () {
                      onCategorySelected(null);
                      Navigator.of(context).pop();
                    },
                  ),
                  ...categories.map(
                        (category) => _CategoryTile(
                      name: category.name,
                      isSelected: selectedCategory == category.id,
                      largeFont: largeFont,
                      icon: Icons.folder,
                      color: Colors.indigo,
                      onTap: () {
                        onCategorySelected(category.id);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
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
                      onAddCategory();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.isSelected,
    required this.largeFont,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final bool largeFont;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: const Color(0xFFC7D2FE))
            : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          name,
          style: TextStyle(
            fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: largeFont ? 16 : 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AddItemForm extends StatefulWidget {
  const _AddItemForm({this.defaultCategory});

  final String? defaultCategory;

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _cardholderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String _type = 'password';
  String? _selectedCategory;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.defaultCategory;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Item',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(
                    value: 'password',
                    child: Text('Password / Login'),
                  ),
                  DropdownMenuItem(
                    value: 'card',
                    child: Text('Credit Card'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _selectedCategory,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No category'),
                  ),
                  ...session.categories.map(
                        (cat) => DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(cat.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              if (_type == 'password') ...[
                TextFormField(
                  controller: _usernameController,
                  decoration:
                  const InputDecoration(labelText: 'Username / Email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(labelText: 'URL or Notes'),
                ),
              ] else ...[
                TextFormField(
                  controller: _cardholderController,
                  decoration:
                  const InputDecoration(labelText: 'Cardholder Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cardNumberController,
                  decoration:
                  const InputDecoration(labelText: 'Card Number'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryController,
                        decoration:
                        const InputDecoration(labelText: 'Expiry (MM/YY)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(labelText: 'CVV'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () => _submit(session),
                      child: _submitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit(SessionManager session) async {
    if (!_formKey.currentState!.validate()) return;
    final data = _type == 'password'
        ? {
      'username': _usernameController.text.trim(),
      'password': _passwordController.text.trim(),
      'url': _urlController.text.trim(),
    }
        : {
      'cardholderName': _cardholderController.text.trim(),
      'cardNumber': _cardNumberController.text.trim(),
      'expiry': _expiryController.text.trim(),
      'cvv': _cvvController.text.trim(),
    };
    setState(() => _submitting = true);
    try {
      await session.createItem(
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        type: _type,
        data: data,
        categoryId: _selectedCategory,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _cardholderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}