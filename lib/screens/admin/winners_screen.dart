import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import '../../core/admin_local_storage.dart';
import 'dashboard_screen.dart';
import 'recycle_bin_screen.dart'; // ✅ Import the bin screen

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

  // ... [Keep your existing _filterUsers, _selectUser, _announceWinner, _updateWinner, _editWinner, _showAnnounceDialog, _clearForm methods exactly as they were] ...
  // (To save space, assume your existing form logic is here. The critical changes are below)

  Future<void> _filterUsers(String query, void Function(VoidCallback) dialogSetState) async {
    if (query.trim().isEmpty) { dialogSetState(() => _filteredUsers = []); return; }
    dialogSetState(() => _isSearching = true);
    try {
      final data = await AdminApiService.searchUsers(query, 0, 20);
      if (mounted) {
        final List<dynamic> results = data['users'] ?? data['content'] ?? [];
        dialogSetState(() { _filteredUsers = results; _isSearching = false; });
      }
    } catch (e) {
      dialogSetState(() => _isSearching = false);
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _winnerNameController.text = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
      _winnerUseridController.text = (user['userid'] ?? user['userId'] ?? '').toString();
      _winnerAgeController.text = (user['age'] != null) ? user['age'].toString() : '';
      _provinceController.text = user['province'] ?? '';
      _searchController.clear();
      _filteredUsers = [];
      FocusScope.of(context).unfocus();
    });
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
      };
      try {
        await AdminApiService.announceWinner(winnerData);
        _clearForm();
        _loadWinners();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Winner announced successfully!'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ✅ FIXED: NO POPUP. One click moves it straight to the Recycle Bin.
  Future<void> _deleteWinner(int winnerId, String winnerName) async {
    try {
      await AdminApiService.softDeleteWinner(winnerId);
      _loadWinners();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moved to Recycle Bin'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _editWinner(Map<String, dynamic> winner) {
    _editingWinnerId = winner['id'];
    _selectedCategory = winner['category'] ?? 'ADULTS';
    _winnerNameController.text = winner['winnerName'] ?? '';
    _winnerUseridController.text = winner['winnerUserid'] ?? '';
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
            title: Text(isEditing ? 'Edit Winner' : 'Announce Winner'),
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
                        decoration: const InputDecoration(labelText: 'Search User', hintText: 'Name or ID...', prefixIcon: Icon(Icons.search), filled: true, fillColor: Colors.grey),
                        onChanged: (query) => _filterUsers(query, setStateDialog),
                      ),
                      const SizedBox(height: 8),
                      if (_filteredUsers.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredUsers.length > 4 ? 4 : _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return ListTile(
                                dense: true,
                                title: Text('${user['name'] ?? ''} ${user['surname'] ?? ''}'),
                                subtitle: Text('ID: ${user['userid'] ?? 'N/A'}'),
                                onTap: () => _selectUser(user),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category *', filled: true, fillColor: Colors.grey),
                      items: const [
                        DropdownMenuItem(value: 'ADULTS', child: Text('Adults (18+)')),
                        DropdownMenuItem(value: 'CHILDREN', child: Text('Children (6-17)')),
                        DropdownMenuItem(value: 'CELEBRITY', child: Text('Celebrity')),
                      ],
                      onChanged: (value) => setStateDialog(() => _selectedCategory = value ?? 'ADULTS'),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: _winnerNameController, decoration: const InputDecoration(labelText: 'Winner Name *', filled: true, fillColor: Colors.grey), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _winnerUseridController, decoration: const InputDecoration(labelText: 'Winner User ID *', filled: true, fillColor: Colors.grey), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _winnerAgeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Winner Age (Optional)', filled: true, fillColor: Colors.grey)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _provinceController, decoration: const InputDecoration(labelText: 'Province (Optional)', filled: true, fillColor: Colors.grey)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _messageController, maxLines: 3, decoration: const InputDecoration(labelText: 'Message (Optional)', filled: true, fillColor: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: isEditing ? _updateWinner : _announceWinner,
                      icon: Icon(isEditing ? Icons.save : Icons.emoji_events),
                      label: Text(isEditing ? 'SAVE CHANGES' : 'ANNOUNCE WINNER'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL'))],
          );
        },
      ),
    );
  }

  void _clearForm() {
    _editingWinnerId = null;
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
          // ✅ NEW: Button to open the Recycle Bin
          IconButton(icon: const Icon(Icons.delete_sweep), tooltip: 'Recycle Bin', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecycleBinScreen()))),
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
                                // ✅ FIXED: Shows Date AND Time
                                Text(
                                  DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(winner['announcedAt'])), 
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12)
                                ),
                                if (canModify) ...[
                                  const SizedBox(width: 8),
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _editWinner(winner), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                  const SizedBox(width: 8),
                                  // ✅ FIXED: One-click delete to bin, no popup
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteWinner(winner['id'], winner['winnerName']), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                ],
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
