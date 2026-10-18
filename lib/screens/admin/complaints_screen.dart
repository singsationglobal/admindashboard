import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import 'dashboard_screen.dart';
import 'complaints_bin_screen.dart'; // ✅ CRITICAL: This import was missing or broken

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<dynamic> _complaints = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = true;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getComplaints(_currentPage, 20, status: _statusFilter.isEmpty ? null : _statusFilter);
      setState(() {
        _complaints = data['complaints'];
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load complaints: $e')));
    }
  }

  Future<void> _replyToComplaint(Map<String, dynamic> complaint) async {
    final replyController = TextEditingController(text: complaint['adminReply'] ?? '');
    String status = complaint['status'] ?? 'OPEN';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AdminTheme.surface,
            title: const Text('Reply to Complaint', style: TextStyle(color: AdminTheme.textLight)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: status, 
                  decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: Colors.white70)),
                  dropdownColor: AdminTheme.surface,
                  items: const [
                    DropdownMenuItem(value: 'OPEN', child: Text('OPEN')), 
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS')), 
                    DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED'))
                  ], 
                  onChanged: (value) => setDialogState(() => status = value!)
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: replyController, 
                  decoration: const InputDecoration(labelText: 'Admin Reply', hintText: 'Type your response here...', labelStyle: TextStyle(color: Colors.white70)), 
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white70))),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('SEND REPLY')),
            ],
          );
        },
      ),
    );
    if (result == true) {
      try {
        await AdminApiService.replyToComplaint(complaint['id'], replyController.text.trim(), status);
        _loadComplaints();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply sent successfully'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send reply: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ✅ UPDATED: Moves to bin instead of permanent delete
  Future<void> _deleteComplaint(Map<String, dynamic> complaint) async {
    try {
      await AdminApiService.softDeleteComplaint(complaint['id']);
      _loadComplaints();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moved to Recycle Bin'), backgroundColor: Colors.orange));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN': return Colors.red;
      case 'IN_PROGRESS': return Colors.orange;
      case 'RESOLVED': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))),
        actions: [
          // ✅ NEW: Button to view the bin
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'View Recycle Bin',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ComplaintsBinScreen())),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _statusFilter.isEmpty ? null : _statusFilter,
              hint: const Text('All', style: TextStyle(color: Colors.white70)),
              dropdownColor: AdminTheme.surface,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: '', child: Text('All', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'OPEN', child: Text('OPEN', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value ?? '';
                  _currentPage = 0;
                  _loadComplaints();
                });
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Complaints: $_totalElements', style: const TextStyle(color: AdminTheme.textLight)), Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(color: AdminTheme.textLight))])),
                Expanded(
                  child: ListView.builder(
                    itemCount: _complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaints[index];
                      final user = complaint['user'] ?? {};
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: AdminTheme.surface,
                        child: ExpansionTile(
                          title: Text(complaint['subject'] ?? 'No Subject', style: const TextStyle(color: AdminTheme.textLight)),
                          subtitle: Row(
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _getStatusColor(complaint['status'] ?? 'OPEN'), borderRadius: BorderRadius.circular(12)), child: Text(complaint['status'] ?? 'OPEN', style: const TextStyle(color: Colors.white, fontSize: 10))),
                              const SizedBox(width: 8),
                              Text('From: ${user['name'] ?? 'Unknown'}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(complaint['message'] ?? '', style: const TextStyle(color: AdminTheme.textLight)),
                                  const SizedBox(height: 12),
                                  if (complaint['adminReply'] != null && complaint['adminReply'].isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Admin Response:', style: TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.secondary)),
                                          const SizedBox(height: 4),
                                          Text(complaint['adminReply'], style: const TextStyle(color: AdminTheme.textLight)),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: ElevatedButton(onPressed: () => _replyToComplaint(complaint), style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary), child: const Text('REPLY'))),
                                      const SizedBox(width: 8),
                                      // ✅ UPDATED: Delete button now moves to bin
                                      Expanded(child: ElevatedButton(onPressed: () => _deleteComplaint(complaint), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('MOVE TO BIN'))),
                                    ],
                                  ),
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
                      if (_currentPage > 0) ElevatedButton(onPressed: () { setState(() { _currentPage--; _loadComplaints(); }); }, child: const Text('PREVIOUS')),
                      if (_currentPage < _totalPages - 1) ElevatedButton(onPressed: () { setState(() { _currentPage++; _loadComplaints(); }); }, child: const Text('NEXT')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
