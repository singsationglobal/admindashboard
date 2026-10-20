import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import 'dashboard_screen.dart';

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
        _complaints = data['complaints'] ?? [];
        _totalPages = data['totalPages'] ?? 0;
        _totalElements = data['totalElements'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load complaints: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _replyToComplaint(Map<String, dynamic> complaint) async {
    final replyController = TextEditingController(text: '');
    String status = complaint['status'] ?? 'OPEN';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AdminTheme.surface,
            title: const Text('Reply to Complaint', style: TextStyle(color: AdminTheme.textLight)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: status, 
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: const [
                      DropdownMenuItem(value: 'OPEN', child: Text('OPEN')), 
                      DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS')), 
                      DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED'))
                    ], 
                    onChanged: (value) => setDialogState(() => status = value!)
                  ),
                  const SizedBox(height: 16),
                  const Text('Your Reply', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: replyController, 
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    maxLines: 5,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type your response here...', 
                      hintStyle: TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8E44AD), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply sent successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send reply: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _deleteComplaint(Map<String, dynamic> complaint) async {
    try {
      await AdminApiService.softDeleteComplaint(complaint['id']);
      _loadComplaints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moved to Recycle Bin'), backgroundColor: Colors.orange)
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN': return Colors.red;
      case 'IN_PROGRESS': return Colors.orange;
      case 'RESOLVED': return Colors.green;
      default: return Colors.grey;
    }
  }

  // Parse conversation into individual messages for Chat UI
  List<Map<String, dynamic>> _parseConversation(Map<String, dynamic> complaint) {
    List<Map<String, dynamic>> messages = [];
    
    // Add original complaint
    messages.add({
      'sender': 'user',
      'message': complaint['message'] ?? '',
      'timestamp': complaint['createdAt'] ?? '',
      'isOriginal': true,
    });
    
    // Parse user replies
    String? userReply = complaint['userReply'];
    if (userReply != null && userReply.isNotEmpty) {
      List<String> userBlocks = userReply.split('==============================');
      for (var block in userBlocks) {
        if (block.trim().isEmpty) continue;
        RegExpMatch? match = RegExp(r'Your Reply \(([^)]+)\):\s*(.*)', dotAll: true).firstMatch(block);
        if (match != null) {
          messages.add({
            'sender': 'user',
            'message': match.group(2)!.trim(),
            'timestamp': match.group(1)!.trim(),
            'isOriginal': false,
          });
        }
      }
    }
    
    // Parse admin replies
    String? adminReply = complaint['adminReply'];
    if (adminReply != null && adminReply.isNotEmpty) {
      List<String> adminBlocks = adminReply.split('==============================');
      for (var block in adminBlocks) {
        if (block.trim().isEmpty) continue;
        RegExpMatch? match = RegExp(r'Admin Reply \(([^)]+)\):\s*(.*)', dotAll: true).firstMatch(block);
        if (match != null) {
          messages.add({
            'sender': 'admin',
            'message': match.group(2)!.trim(),
            'timestamp': match.group(1)!.trim(),
            'isOriginal': false,
          });
        }
      }
    }
    
    // Sort by timestamp
    messages.sort((a, b) {
      try {
        DateTime timeA = DateFormat('dd MMM yyyy, HH:mm').parse(a['timestamp']);
        DateTime timeB = DateFormat('dd MMM yyyy, HH:mm').parse(b['timestamp']);
        return timeA.compareTo(timeB);
      } catch (e) {
        return 0;
      }
    });
    
    return messages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh List',
            onPressed: _loadComplaints,
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _statusFilter.isEmpty ? null : _statusFilter,
              hint: const Text('All', style: TextStyle(color: Colors.white70)),
              dropdownColor: AdminTheme.surface,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white),
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
                Padding(
                  padding: const EdgeInsets.all(16), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text('Total Complaints: $_totalElements', style: const TextStyle(color: AdminTheme.textLight)), 
                      Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(color: AdminTheme.textLight))
                    ]
                  )
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaints[index];
                      final user = complaint['user'] ?? {};
                      final messages = _parseConversation(complaint);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: AdminTheme.surface,
                        child: ExpansionTile(
                          title: Text(complaint['subject'] ?? 'No Subject', style: const TextStyle(color: AdminTheme.textLight)),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                                decoration: BoxDecoration(color: _getStatusColor(complaint['status'] ?? 'OPEN'), borderRadius: BorderRadius.circular(12)), 
                                child: Text(complaint['status'] ?? 'OPEN', style: const TextStyle(color: Colors.white, fontSize: 10))
                              ),
                              const SizedBox(width: 8),
                              Text('From: ${user['name'] ?? 'Unknown'}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxHeight: 400),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ✅ CHAT INTERFACE: Display messages like WhatsApp
                                    ...messages.map((msg) {
                                      bool isUser = msg['sender'] == 'user';
                                      return Align(
                                        alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          constraints: const BoxConstraints(maxWidth: 300),
                                          decoration: BoxDecoration(
                                            color: isUser ? Colors.blue.shade800 : AdminTheme.primary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (msg['isOriginal'] == true)
                                                const Text('Original Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white70))
                                              else
                                                Text(isUser ? 'User' : 'Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white70)),
                                              const SizedBox(height: 4),
                                              Text(msg['message'], style: const TextStyle(color: Colors.white)),
                                              const SizedBox(height: 4),
                                              Text(msg['timestamp'], style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.7))),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _replyToComplaint(complaint), 
                                            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary), 
                                            child: const Text('REPLY')
                                          )
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _deleteComplaint(complaint), 
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), 
                                            child: const Text('MOVE TO BIN')
                                          )
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
                      if (_currentPage > 0) 
                        ElevatedButton(
                          onPressed: () { setState(() { _currentPage--; _loadComplaints(); }); }, 
                          child: const Text('PREVIOUS')
                        ),
                      if (_currentPage < _totalPages - 1) 
                        ElevatedButton(
                          onPressed: () { setState(() { _currentPage++; _loadComplaints(); }); }, 
                          child: const Text('NEXT')
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
