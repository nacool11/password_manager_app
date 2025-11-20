import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vault_item.dart';

class PasswordDetailScreen extends StatefulWidget {
  const PasswordDetailScreen({Key? key, required this.item}) : super(key: key);

  final VaultItem item;

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _showPassword = false;

  String get _password => widget.item.data?['password']?.toString() ?? '';
  String get _username =>
      widget.item.data?['username']?.toString() ?? widget.item.subtitle ?? '';
  String get _url => widget.item.data?['url']?.toString() ?? '';

  void _showSecurityDialog() {
    if (_password.isEmpty) {
      setState(() => _showPassword = true);
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SecurityVerificationDialog(
        onVerified: () {
          setState(() {
            _showPassword = true;
          });
        },
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
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
        title: Text(widget.item.title),
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
              value:
                  _password.isEmpty ? 'Not stored' : _showPassword ? _password : '••••••••••••',
              icon: Icons.lock,
              onCopy: _password.isEmpty
                  ? null
                  : () => _copyToClipboard(_password, 'Password'),
              onToggleVisibility: () {
                if (!_showPassword) {
                  _showSecurityDialog();
                } else {
                  setState(() {
                    _showPassword = false;
                  });
                }
              },
              showVisibility: _password.isNotEmpty,
              isVisible: _showPassword,
            ),
            const SizedBox(height: 16),
            if (_url.isNotEmpty)
              _buildDetailCard(
                label: 'URL / Notes',
                value: _url,
                icon: Icons.link,
                onCopy: () => _copyToClipboard(_url, 'URL'),
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
                      'Passwords are encrypted and require two-factor authentication to view.',
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

}

class _SecurityVerificationDialog extends StatefulWidget {
  final VoidCallback onVerified;

  const _SecurityVerificationDialog({required this.onVerified});

  @override
  State<_SecurityVerificationDialog> createState() =>
      _SecurityVerificationDialogState();
}

class _SecurityVerificationDialogState
    extends State<_SecurityVerificationDialog> {
  final _masterPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Unlock to View',
        style: TextStyle(color: Color(0xFFD97706)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_step == 1) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 1: Enter Master Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _masterPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Master Password',
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 2: Enter OTP from Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        hintText: '123456',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: Colors.green.shade400,
                    width: 4,
                  ),
                ),
              ),
              child: const Text(
                'The actual saved password is only decrypted and shown after successful two-factor authentication.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_step == 1) {
              setState(() {
                _step = 2;
              });
            } else {
              Navigator.pop(context);
              widget.onVerified();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
          ),
          child: Text(_step == 1 ? 'Next' : 'Verify & Show'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _masterPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}


// ==========================================
// FILE 6: lib/screens/credit_card_detail_screen.dart
// ==========================================
