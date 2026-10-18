import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import '../../core/delete_confirmation_dialog.dart'; // ✅ CRITICAL: Required for the "type delete" dialog
import 'dashboard_screen.dart';

class ComplaintsBinScreen extends StatefulWidget {
  const ComplaintsBinScreen({super.key});

  @override
  State<ComplaintsBinScreen> createState() => _ComplaintsBinScreenState();
}

class _ComplaintsBinScreenState extends State<ComplaintsBinScreen> {
  List<dynamic> _deletedComplaints = [];
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedComplaints();
  }

  Future<void> _loadDeletedComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getDeletedComplaints(_currentPage, 20);
      setState(() {
        _deletedComplaints = data['complaints'];
        _totalPages = data['totalPages'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load bin: $e')));
    }
  }

  Future<void> _restoreComplaint(int id) async {
    try {
      await AdminApiService.restoreComplaint(id);
      _loadDeletedComplaints();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restored successfully'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  // ✅ UPDATED: Uses the "Type 'delete'" confirmation dialog
  Future<void> _permanentDelete(int id, String subject) async {
    final confirm = await showPermanentDeleteConfirmation(context, subject);

    if (confirm) {
      try {
        await AdminApiService.permanentDeleteComplaint(id);
        _loadDeletedComplaints();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permanently deleted'), backgroundColor: Colors.red));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints Recycle Bin'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedComplaints.isEmpty
              ? const Center(child: Text('Bin is empty', style: TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _deletedComplaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _deletedComplaints[index];
                          final deletedAt = complaint['deletedAt'] != null 
                              ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(complaint['deletedAt'])) 
                              : 'Unknown';
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            color: AdminTheme.surface,
                            child: ListTile(
                              title: Text(complaint['subject'] ?? 'No Subject', style: const TextStyle(color: AdminTheme.textLight)),
                              subtitle: Text('Deleted: $deletedAt', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => _restoreComplaint(complaint['id']), tooltip: 'Restore'),
                                  IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _permanentDelete(complaint['id'], complaint['subject']), tooltip: 'Permanent Delete'),
                                ],
                              ),
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
                          if (_currentPage > 0) ElevatedButton(onPressed: () { setState(() { _currentPage--; _loadDeletedComplaints(); }); }, child: const Text('PREVIOUS')),
                          if (_currentPage < _totalPages - 1) ElevatedButton(onPressed: () { setState(() { _currentPage++; _loadDeletedComplaints(); }); }, child: const Text('NEXT')),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
