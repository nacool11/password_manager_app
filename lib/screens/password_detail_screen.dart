// ==========================================
// FILE 5: lib/screens/password_detail_screen.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_item.dart';

class PasswordDetailScreen extends StatefulWidget {
  final String siteName;
  final String username;
  final VaultItem? item;

  const PasswordDetailScreen({
    Key? key,
    this.siteName = '',
    this.username = '',
    this.item,
  }) : super(key: key);

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _showPassword = false;
  
  String get _password {
    if (widget.item?.data != null) {
      return widget.item!.data!['password']?.toString() ?? 
             widget.item!.data!['pass']?.toString() ?? 
             '••••••••';
    }
    return '••••••••';
  }
  
  String get _url {
    if (widget.item?.data != null) {
      return widget.item!.data!['url']?.toString() ?? '';
    }
    return '';
  }
  
  String get _siteName {
    return widget.siteName.isNotEmpty 
        ? widget.siteName 
        : (widget.item?.title ?? 'Password');
  }
  
  String get _username {
    return widget.username.isNotEmpty 
        ? widget.username 
        : (widget.item?.data?['username']?.toString() ?? 
           widget.item?.data?['email']?.toString() ?? '');
  }

  void _showSecurityDialog() {
    // Removed OTP and master password requirement - just toggle password visibility
    setState(() {
      _showPassword = true;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_siteName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.language,
                  size: 40,
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildDetailCard(
              label: 'Username',
              value: _username,
              icon: Icons.person,
              onCopy: () => _copyToClipboard(_username, 'Username'),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              label: 'Password',
              value: _showPassword ? _password : '••••••••••••',
              icon: Icons.lock,
              onCopy: () => _copyToClipboard(_password, 'Password'),
              onToggleVisibility: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
              showVisibility: true,
              isVisible: _showPassword,
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              label: 'URL',
              value: _url,
              icon: Icons.link,
              onCopy: () => _copyToClipboard(_url, 'URL'),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showDeleteDialog();
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEFCE8),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: Colors.yellow.shade700,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.yellow.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Passwords are encrypted and stored securely.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onCopy,
    VoidCallback? onToggleVisibility,
    bool showVisibility = false,
    bool isVisible = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4338CA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showVisibility)
                IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.indigo,
                  ),
                  onPressed: onToggleVisibility,
                ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.indigo, size: 20),
                onPressed: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password'),
        content: Text('Are you sure you want to delete $_siteName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}



// ==========================================
// FILE 6: lib/screens/credit_card_detail_screen.dart
// ==========================================
