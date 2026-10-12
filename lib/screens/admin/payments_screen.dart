import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import 'dashboard_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<dynamic> _payments = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getPayments(_currentPage, 20);
      setState(() {
        _payments = data['payments'];
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load payments: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Payments: $_totalElements', style: const TextStyle(color: AdminTheme.textLight)), Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(color: AdminTheme.textLight))])),
                Expanded(
                  child: ListView.builder(
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      final user = payment['user'] ?? {};
                      final song = payment['song'] ?? {};
                      final competitionEntry = payment['competitionEntry'] ?? {};
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: AdminTheme.surface,
                        child: ExpansionTile(
                          leading: CircleAvatar(backgroundColor: Colors.green, child: Text('R', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          title: Text('R ${payment['amount'] ?? '0.00'}', style: const TextStyle(color: AdminTheme.textLight, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('User: ${user['name'] ?? 'Unknown'} (${user['userid'] ?? 'No ID'})', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              Text('Province: ${competitionEntry['province'] ?? user['province'] ?? 'Not specified'}', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                              Text('Song: ${song['title'] ?? 'Unknown'}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Transaction ID', payment['transactionId'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Status', payment['status'] ?? 'UNKNOWN'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Payment Date', payment['paymentDate'] != null ? DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.parse(payment['paymentDate'])) : 'Unknown'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Competition Entry Date', competitionEntry['entryDate'] != null ? DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.parse(competitionEntry['entryDate'])) : 'Not entered'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Category', competitionEntry['category'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Artist Name', competitionEntry['artistName'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Contact', competitionEntry['contactInfo'] ?? user['contact'] ?? 'N/A'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0) ElevatedButton(onPressed: () { setState(() { _currentPage--; _loadPayments(); }); }, child: const Text('PREVIOUS')),
                      if (_currentPage < _totalPages - 1) ElevatedButton(onPressed: () { setState(() { _currentPage++; _loadPayments(); }); }, child: const Text('NEXT')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text('$label:', style: TextStyle(color: AdminTheme.secondary, fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: AdminTheme.textLight, fontSize: 12))),
      ],
    );
  }
}