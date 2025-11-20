import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vault_item.dart';

class CreditCardDetailScreen extends StatefulWidget {
  const CreditCardDetailScreen({Key? key, required this.item}) : super(key: key);

  final VaultItem item;

  @override
  State<CreditCardDetailScreen> createState() => _CreditCardDetailScreenState();
}

class _CreditCardDetailScreenState extends State<CreditCardDetailScreen> {
  bool _showCardNumber = false;
  bool _showCVV = false;

  Map<String, dynamic> get _data => widget.item.data ?? {};
  String get _cardholderName => _data['cardholderName']?.toString() ?? 'N/A';
  String get _cardNumber => _data['cardNumber']?.toString() ?? '';
  String get _expiry => _data['expiry']?.toString() ?? '--/--';
  String get _cvv => _data['cvv']?.toString() ?? '';

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
    final lastDigits = _cardNumber.isEmpty
        ? ''
        : _cardNumber.substring(
            _cardNumber.length >= 4 ? _cardNumber.length - 4 : 0,
          );
    final maskedNumber = _cardNumber.isEmpty
        ? '•••• •••• •••• ••••'
        : '•••• •••• •••• ${lastDigits.padLeft(4, '•')}';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 50,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const Text(
                        'VISA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _showCardNumber && _cardNumber.isNotEmpty
                        ? _cardNumber
                        : maskedNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CARD HOLDER',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cardholderName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXPIRES',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _expiry,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildDetailCard(
              label: 'Cardholder Name',
              value: _cardholderName,
              icon: Icons.person,
              color: Colors.green,
              onCopy: () =>
                  _copyToClipboard(_cardholderName, 'Cardholder name'),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              label: 'Card Number',
              value: _showCardNumber && _cardNumber.isNotEmpty
                  ? _cardNumber
                  : maskedNumber,
              icon: Icons.credit_card,
              color: Colors.green,
              onCopy: _cardNumber.isEmpty
                  ? null
                  : () => _copyToClipboard(_cardNumber, 'Card number'),
              onToggleVisibility: _cardNumber.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _showCardNumber = !_showCardNumber;
                      });
                    },
              showVisibility: _cardNumber.isNotEmpty,
              isVisible: _showCardNumber,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    label: 'Expiry Date',
                    value: _expiry,
                    icon: Icons.calendar_today,
                    color: Colors.green,
                    onCopy: () => _copyToClipboard(_expiry, 'Expiry date'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailCard(
                    label: 'CVV',
                    value: _showCVV && _cvv.isNotEmpty ? _cvv : '•••',
                    icon: Icons.security,
                    color: Colors.green,
                    onCopy:
                        _cvv.isEmpty ? null : () => _copyToClipboard(_cvv, 'CVV'),
                    onToggleVisibility: _cvv.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _showCVV = !_showCVV;
                            });
                          },
                    showVisibility: _cvv.isNotEmpty,
                    isVisible: _showCVV,
                  ),
                ),
              ],
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
    required Color color,
    VoidCallback? onCopy,
    VoidCallback? onToggleVisibility,
    bool showVisibility = false,
    bool isVisible = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
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
                    color: color,
                  ),
                  onPressed: onToggleVisibility,
                ),
              IconButton(
                icon: Icon(Icons.copy, color: color, size: 20),
                onPressed: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }

}
