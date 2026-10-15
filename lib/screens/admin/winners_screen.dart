import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import '../../core/admin_local_storage.dart';
import 'dashboard_screen.dart';

class WinnersScreen extends StatefulWidget {
  const WinnersScreen({super.key});

  @override
  State<WinnersScreen> createState() => _WinnersScreenState();
}

class _WinnersScreenState extends State<WinnersScreen> {
  List<dynamic> _winners = [];
  bool _isLoading = true;
  String _userRole = '';
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'ADULTS';
  String _selectedMessageType = 'ANNOUNCEMENT';

  final _winnerNameController = TextEditingController();
  final _winnerUseridController = TextEditingController();
  final _winnerAgeController = TextEditingController();
  final _provinceController = TextEditingController();
  final _messageController = TextEditingController();

  int? _editingWinnerId;
  final _searchController = TextEditingController();
  List<dynamic> _filteredUsers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadWinners();
  }

  @override
  void dispose() {
    _winnerNameController.dispose();
    _winnerUseridController.dispose();
    _winnerAgeController.dispose();
    _provinceController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    _userRole = await AdminLocalStorage.getRole();
    if (mounted) setState(() {});
  }

  Future<void> _loadWinners() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final winners = await AdminApiService.getActiveWinners();
      if (mounted) {
        setState(() {
          _winners = winners;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load winners: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _filterUsers(String query, void Function(VoidCallback) dialogSetState) async {
    if (query.trim().isEmpty) {
      dialogSetState(() => _filteredUsers = []);
      return;
    }
    dialogSetState(() => _isSearching = true);
    try {
      final data = await AdminApiService.searchUsers(query, 0, 20);
      if (mounted) {
        final List<dynamic> results = data['users'] ?? data['content'] ?? [];
        dialogSetState(() {
          _filteredUsers = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      dialogSetState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    final name = user['name'] ?? user['firstName'] ?? '';
    final surname = user['surname'] ?? user['lastName'] ?? '';
    final fullName = '$name $surname'.trim();

    setState(() {
      _winnerNameController.text = fullName;
      _winnerUseridController.text = (user['userid'] ?? user['userId'] ?? '').toString();
      
      final age = user['age'];
      _winnerAgeController.text = (age != null) ? age.toString() : '';
      
      _provinceController.text = user['province'] ?? '';
      
      _searchController.clear();
      _filteredUsers = [];
      FocusScope.of(context).unfocus();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Auto-filled: $fullName'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _announceWinner() async {
    if (_formKey.currentState!.validate()) {
      final winnerData = {
        'category': _selectedCategory,
        'winnerName': _winnerNameController.text.trim(),
        'winnerUserid': _winnerUseridController.text.trim(),
        'winnerAge': _winnerAgeController.text.trim().isEmpty ? null : int.tryParse(_winnerAgeController.text.trim()),
        'province': _provinceController.text.trim().isEmpty ? null : _provinceController.text.trim(),
        'message': _messageController.text.trim(),
        'messageType': _selectedMessageType,
      };
      try {
        await AdminApiService.announceWinner(winnerData);
        _clearForm();
        _loadWinners();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Winner announced successfully!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to announce winner: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateWinner() async {
    if (_formKey.currentState!.validate() && _editingWinnerId != null) {
      final winnerData = {
        'category': _selectedCategory,
        'winnerName': _winnerNameController.text.trim(),
        'winnerUserid': _winnerUseridController.text.trim(),
        'winnerAge': _winnerAgeController.text.trim().isEmpty ? null : int.tryParse(_winnerAgeController.text.trim()),
        'province': _provinceController.text.trim().isEmpty ? null : _provinceController.text.trim(),
        'message': _messageController.text.trim(),
      };
      try {
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/admin/winners/${_editingWinnerId}'),
          headers: await AdminApiService.getAuthHeader(),
          body: json.encode(winnerData),
        );
        if (response.statusCode == 200) {
          _clearForm();
          _loadWinners();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Winner updated successfully'), backgroundColor: Colors.green),
          );
        } else {
          throw Exception('Failed to update winner');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update winner: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteWinner(int winnerId, String winnerName) async {
    if (_userRole != 'SUPER_ADMIN' && _userRole != 'ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission Denied: Only Admins can delete winners.'), backgroundColor: Colors.red),
      );
      return;
    }

    String confirmText = '';
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final bool isPermanent = confirmText.toLowerCase().trim() == 'delete';
          return AlertDialog(
            title: const Text('Delete Winner', style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type "delete" to permanently remove "$winnerName".\nLeave blank to move to the Recycle Bin (can be restored later).'),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setStateDialog(() => confirmText = value),
                  decoration: InputDecoration(
                    hintText: 'Type "delete" or leave blank',
                    border: const OutlineInputBorder(),
                    fillColor: isPermanent ? Colors.red.shade50 : Colors.grey.shade100,
                    filled: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _executeDelete(winnerId, winnerName, isPermanent);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPermanent ? Colors.red : Colors.orange,
                ),
                child: Text(isPermanent ? 'PERMANENTLY DELETE' : 'MOVE TO BIN'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeDelete(int winnerId, String winnerName, bool isPermanent) async {
    try {
      if (isPermanent) {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId/permanent'),
          headers: await AdminApiService.getAuthHeader(),
        );
        if (response.statusCode != 200) {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['error'] ?? 'Failed to permanently delete');
        }
      } else {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId/delete'),
          headers: await AdminApiService.getAuthHeader(),
        );
        if (response.statusCode != 200) {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['error'] ?? 'Failed to move to bin');
        }
      }

      _loadWinners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPermanent ? 'Permanently deleted.' : 'Moved to Recycle Bin.'),
          backgroundColor: isPermanent ? Colors.red : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _editWinner(Map<String, dynamic> winner) {
    _editingWinnerId = winner['id'];
    _selectedCategory = winner['category'] ?? 'ADULTS';
    _winnerNameController.text = winner['winnerName'] ?? '';
    _winnerUseridController.text = winner['winnerUserid'] ?? winner['winnerUserId'] ?? '';
    _winnerAgeController.text = (winner['winnerAge'] ?? '').toString();
    _provinceController.text = winner['province'] ?? '';
    _messageController.text = winner['message'] ?? '';
    
    _showAnnounceDialog(isEditing: true);
  }

  void _showAnnounceDialog({bool isEditing = false}) {
    if (!isEditing) _clearForm();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              isEditing ? 'Edit Winner' : 'Announce Winner',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isEditing) ...[
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search User',
                          hintText: 'Name or ID...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _isSearching 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : null,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (query) => _filterUsers(query, setStateDialog),
                      ),
                      const SizedBox(height: 12),
                      if (_filteredUsers.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredUsers.length > 4 ? 4 : _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final name = user['name'] ?? user['firstName'] ?? '';
                              final surname = user['surname'] ?? user['lastName'] ?? '';
                              final fullName = '$name $surname'.trim();
                              final userId = user['userid'] ?? user['userId'] ?? 'N/A';
                              final profileImage = user['profileImageUrl'];
                              final hasImage = profileImage != null && profileImage.toString().isNotEmpty && profileImage != 'null';
                              
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple,
                                  backgroundImage: hasImage ? NetworkImage(profileImage) : null,
                                  child: !hasImage ? Text(fullName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16)) : null,
                                ),
                                title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                                subtitle: Text('ID: $userId | Province: ${user['province'] ?? 'Unknown'}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                onTap: () => _selectUser(user),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    if (!isEditing) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedMessageType,
                        decoration: InputDecoration(labelText: 'Message Type', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        items: const [
                          DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('Winner Announcement')),
                          DropdownMenuItem(value: 'SUPPORT', child: Text('Support Message')),
                          DropdownMenuItem(value: 'GENERAL', child: Text('General Announcement')),
                        ],
                        onChanged: (value) => setStateDialog(() => _selectedMessageType = value ?? 'ANNOUNCEMENT'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(labelText: 'Category *', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: const [
                        DropdownMenuItem(value: 'ADULTS', child: Text('Adults (18+)')),
                        DropdownMenuItem(value: 'CHILDREN', child: Text('Children (6-17)')),
                        DropdownMenuItem(value: 'CELEBRITY', child: Text('Celebrity')),
                      ],
                      onChanged: (value) => setStateDialog(() => _selectedCategory = value ?? 'ADULTS'),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _winnerNameController,
                      decoration: InputDecoration(labelText: 'Winner Name *', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _winnerUseridController,
                      decoration: InputDecoration(labelText: 'Winner User ID *', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _winnerAgeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Winner Age (Optional)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _provinceController,
                      decoration: InputDecoration(
                        labelText: 'Province (Optional)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: 'Message (Optional)', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isEditing ? _updateWinner : _announceWinner,
                        icon: Icon(isEditing ? Icons.save : Icons.emoji_events),
                        label: Text(isEditing ? 'SAVE CHANGES' : 'ANNOUNCE WINNER', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ],
          );
        },
      ),
    );
  }

  void _clearForm() {
    _editingWinnerId = null;
    _selectedCategory = 'ADULTS';
    _selectedMessageType = 'ANNOUNCEMENT';
    _winnerNameController.clear();
    _winnerUseridController.clear();
    _winnerAgeController.clear();
    _provinceController.clear();
    _messageController.clear();
    _searchController.clear();
    _filteredUsers = [];
  }

  @override
  Widget build(BuildContext context) {
    final bool canModify = (_userRole == 'SUPER_ADMIN' || _userRole == 'ADMIN');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Winner Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAnnounceDialog(isEditing: false), tooltip: 'Announce Winner'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWinners, tooltip: 'Refresh'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _winners.isEmpty
              ? const Center(child: Text('No winners announced yet', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _winners.length,
                  itemBuilder: (context, index) {
                    final winner = _winners[index];
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: winner['category'] == 'CELEBRITY' ? Colors.amber : AdminTheme.primary, borderRadius: BorderRadius.circular(20)),
                                  child: Text(winner['category'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const Spacer(),
                                Text(DateFormat('dd MMM yyyy').format(DateTime.parse(winner['announcedAt'])), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                if (canModify) IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _editWinner(winner), tooltip: 'Edit Winner', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                if (canModify) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteWinner(winner['id'], winner['winnerName']), tooltip: 'Delete Winner', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(winner['winnerName'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
                            Text('User ID: ${winner['winnerUserid'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[400])),
                            Text('Age: ${winner['winnerAge'] ?? 'N/A'} | Province: ${winner['province'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[400])),
                            if (winner['message'] != null && winner['message'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(winner['message'], style: TextStyle(color: Colors.grey[300], fontStyle: FontStyle.italic)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
