import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SecurityAuditScreen extends StatefulWidget {
  const SecurityAuditScreen({Key? key}) : super(key: key);

  @override
  State<SecurityAuditScreen> createState() => _SecurityAuditScreenState();
}

class _SecurityAuditScreenState extends State<SecurityAuditScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _auditData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAudit();
  }

  Future<void> _loadAudit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getAudit();
      setState(() {
        _auditData = data['audit'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Health Audit'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadAudit,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAudit,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildScoreCard(),
                      const SizedBox(height: 24),
                      const Text(
                        'Security Issues',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_auditData != null && _auditData!['issues'] != null)
                        ...(_auditData!['issues'] as List)
                            .map((issue) => _buildIssueCardFromData(issue))
                            .toList(),
                      if (_auditData == null ||
                          _auditData!['issues'] == null ||
                          (_auditData!['issues'] as List).isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'No security issues found! Your passwords are secure.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tips_and_updates, color: Colors.green.shade700),
                                const SizedBox(width: 12),
                                Text(
                                  'Security Tips',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTip('Use unique passwords for each account'),
                            _buildTip('Enable two-factor authentication'),
                            _buildTip('Use the password generator for strong passwords'),
                            _buildTip('Update passwords regularly'),
                            _buildTip('Never share your master password'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadAudit,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Audit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreCard() {
    if (_auditData == null) {
      return const SizedBox.shrink();
    }
    final score = _auditData!['scorePercent'] ?? 0;
    final riskLevel = _auditData!['riskLevel'] ?? 'low';
    final summary = _auditData!['summary'] ?? {};
    final totalItems = summary['totalItems'] ?? 0;
    final flaggedItems = summary['flaggedItems'] ?? 0;

    MaterialColor scoreColor;
    String scoreLabel;
    if (score >= 70) {
      scoreColor = Colors.green;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Medium';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Poor';
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.shade400, scoreColor.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Security Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    scoreLabel,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            totalItems == 0
                ? 'No items in vault yet.'
                : flaggedItems == 0
                    ? 'All passwords are secure!'
                    : '$flaggedItems of $totalItems items need attention.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCardFromData(Map<String, dynamic> issue) {
    final check = issue['check'] ?? '';
    final reason = issue['reason'] ?? '';
    final title = issue['title'] ?? 'Unknown';
    final type = issue['type'] ?? '';

    // Determine severity based on check type
    Color severityColor;
    String severity;
    IconData icon;

    if (check.contains('hasPassword') || check.contains('cardExpiry')) {
      severityColor = Colors.red;
      severity = 'High';
      icon = Icons.error;
    } else if (check.contains('length') || check.contains('entropy')) {
      severityColor = Colors.orange;
      severity = 'Medium';
      icon = Icons.warning;
    } else {
      severityColor = Colors.yellow.shade700;
      severity = 'Low';
      icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildIssueCard(
        title: '$title - $check',
        description: reason,
        severity: severity,
        severityColor: severityColor,
        icon: icon,
        items: [],
      ),
    );
  }

  Widget _buildIssueCard({
    required String title,
    required String description,
    required String severity,
    required Color severityColor,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...items.map(
              (item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: severityColor.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: severityColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 14)),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Fix')),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
