import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/api_config.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import '../../core/delete_confirmation_dialog.dart';
import 'dashboard_screen.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  String _selectedType = 'Complaints'; 
  
  List<dynamic> _deletedWinners = [];
  List<dynamic> _deletedComplaints = [];
  bool _isLoading = true;

  Set<int> _selectedComplaintIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _selectedComplaintIds.clear(); 
    });
    try {
      if (_selectedType == 'Winners') {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/admin/winners/deleted'),
          headers: await AdminApiService.getAuthHeader(),
        );
        if (response.statusCode == 200) {
          setState(() {
            _deletedWinners = json.decode(response.body);
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load deleted winners');
        }
      } else {
        final data = await AdminApiService.getDeletedComplaints(0, 100);
        setState(() {
          _deletedComplaints = data['complaints'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _restoreComplaint(int id) async {
    try {
      await AdminApiService.restoreComplaint(id);
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint restored!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _permanentDeleteComplaint(int id, String subject) async {
    final confirm = await showPermanentDeleteConfirmation(context, subject);
    if (confirm) {
      try {
        await AdminApiService.permanentDeleteComplaint(id);
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint permanently deleted'), backgroundColor: Colors.red));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ✅ UPDATED: Bulk delete now uses the "Type delete" confirmation dialog
  Future<void> _bulkPermanentDeleteComplaints() async {
    if (_selectedComplaintIds.isEmpty) return;

    final confirm = await showPermanentDeleteConfirmation(
      context, 
      '${_selectedComplaintIds.length} selected complaints'
    );

    if (confirm == true) {
      try {
        for (int id in _selectedComplaintIds) {
          await AdminApiService.permanentDeleteComplaint(id);
        }
        setState(() {
          _selectedComplaintIds.clear();
        });
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected complaints permanently deleted'), backgroundColor: Colors.red)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red)
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh'),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AdminTheme.surface,
            child: Row(
              children: [
                const Text('Viewing: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedType,
                  dropdownColor: AdminTheme.surface,
                  underline: const SizedBox(),
                  style: const TextStyle(color: AdminTheme.secondary, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'Complaints', child: Text('Deleted Complaints')),
                    DropdownMenuItem(value: 'Winners', child: Text('Deleted Winners')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                      _loadData();
                    }
                  },
                ),
              ],
            ),
          ),
          
          if (_selectedType == 'Complaints' && _selectedComplaintIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.red.withOpacity(0.2),
              child: Row(
                children: [
                  Text('${_selectedComplaintIds.length} selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                    tooltip: 'Delete Selected',
                    onPressed: _bulkPermanentDeleteComplaints,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70, size: 28),
                    tooltip: 'Clear Selection',
                    onPressed: () {
                      setState(() {
                        _selectedComplaintIds.clear();
                      });
                    },
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_selectedType == 'Complaints') {
      if (_deletedComplaints.isEmpty) {
        return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_sweep, size: 80, color: Colors.grey), SizedBox(height: 16), Text('No deleted complaints', style: TextStyle(fontSize: 18, color: Colors.grey))]));
      }
      
      final allSelected = _deletedComplaints.isNotEmpty && _selectedComplaintIds.length == _deletedComplaints.length;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AdminTheme.surface.withOpacity(0.5),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  tristate: true,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedComplaintIds.addAll(_deletedComplaints.map((c) => c['id'] as int));
                      } else {
                        _selectedComplaintIds.clear();
                      }
                    });
                  },
                ),
                const Text('Select All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _deletedComplaints.length,
              itemBuilder: (context, index) {
                final complaint = _deletedComplaints[index];
                final deletedAt = complaint['deletedAt'] != null ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(complaint['deletedAt'])) : 'Unknown';
                return Card(
                  color: AdminTheme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _selectedComplaintIds.contains(complaint['id']),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedComplaintIds.add(complaint['id'] as int);
                                  } else {
                                    _selectedComplaintIds.remove(complaint['id']);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)), child: Text(complaint['status'] ?? 'OPEN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            const Spacer(),
                            Text('Deleted: $deletedAt', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(complaint['subject'] ?? 'No Subject', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
                        Text('From: ${complaint['user']?['name'] ?? 'Unknown'}', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: ElevatedButton.icon(onPressed: () => _restoreComplaint(complaint['id']), icon: const Icon(Icons.restore), label: const Text('RESTORE'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))),
                            const SizedBox(width: 8),
                            Expanded(child: ElevatedButton.icon(onPressed: () => _permanentDeleteComplaint(complaint['id'], complaint['subject']), icon: const Icon(Icons.delete_forever), label: const Text('PERMANENTLY DELETE'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      if (_deletedWinners.isEmpty) {
        return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_sweep, size: 80, color: Colors.grey), SizedBox(height: 16), Text('No deleted winners', style: TextStyle(fontSize: 18, color: Colors.grey))]));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _deletedWinners.length,
        itemBuilder: (context, index) {
          final winner = _deletedWinners[index];
          final deletedAt = winner['deletedAt'] != null ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(winner['deletedAt'])) : 'Unknown';
          return Card(
            color: AdminTheme.surface,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(20)), child: Text(winner['category'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      const Spacer(),
                      Text('Deleted: $deletedAt', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(winner['winnerName'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton.icon(onPressed: () { /* Add restore winner logic if needed */ }, icon: const Icon(Icons.restore), label: const Text('RESTORE'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton.icon(onPressed: () { /* Add permanent delete winner logic if needed */ }, icon: const Icon(Icons.delete_forever), label: const Text('PERMANENTLY DELETE'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
