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

  final _winnerNameController = TextEditingController();
  final _winnerUseridController = TextEditingController();
  final _winnerAgeController = TextEditingController();
  final _provinceController = TextEditingController();
  final _messageController = TextEditingController();

  int? _editingWinnerId;

  // Search variables
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

  // ✅ FIXED: Accepts the Sheet's setState function so the popup updates instantly
  Future<void> _filterUsers(String query, void Function(VoidCallback) sheetSetState) async {
    if (query.trim().isEmpty) {
      sheetSetState(() => _filteredUsers = []);
      return;
    }

    sheetSetState(() => _isSearching = true);

    try {
      final data = await AdminApiService.searchUsers(query, 0, 20);
      if (mounted) {
        final List<dynamic> results = data['users'] ?? data['content'] ?? [];
        sheetSetState(() {
          _filteredUsers = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      sheetSetState(() => _isSearching = false);
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

    _winnerNameController.text = fullName;
    _winnerUseridController.text = (user['userid'] ?? user['userId'] ?? '').toString();

    final age = user['age'];
    _winnerAgeController.text = (age != null) ? age.toString() : '0';
    _provinceController.text = user['province'] ?? '';

    _searchController.clear();
    _filteredUsers = [];
    FocusScope.of(context).unfocus();

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
        'winnerAge': int.tryParse(_winnerAgeController.text.trim()) ?? 0,
        'province': _provinceController.text.trim(),
        'message': _messageController.text.trim(),
      };
      try {
        await AdminApiService.announceWinner(winnerData);
        _clearForm();
        _loadWinners();
        Navigator.pop(context); // Close bottom sheet
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
        'winnerAge': int.tryParse(_winnerAgeController.text.trim()) ?? 0,
        'province': _provinceController.text.trim(),
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Winner Announcement'),
        content: Text('Are you sure you want to permanently delete the announcement for "$winnerName"? It will disappear from the app immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId'),
          headers: await AdminApiService.getAuthHeader(),
        );

        if (response.statusCode == 200) {
          _loadWinners();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Winner announcement deleted successfully.'), backgroundColor: Colors.green),
          );
        } else {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['error'] ?? 'Failed to delete winner');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editWinner(Map<String, dynamic> winner) {
    _editingWinnerId = winner['id'];
    _selectedCategory = winner['category'] ?? 'ADULTS';
    _winnerNameController.text = winner['winnerName'] ?? '';
    _winnerUseridController.text = winner['winnerUserid'] ?? winner['winnerUserId'] ?? '';
    _winnerAgeController.text = (winner['winnerAge'] ?? 0).toString();
    _provinceController.text = winner['province'] ?? '';
    _messageController.text = winner['message'] ?? '';
    
    // Re-use the same bottom sheet for editing
    _showAnnounceDialog(isEditing: true);
  }

  // ✅ FIXED: Uses showModalBottomSheet to prevent mobile overlap
  void _showAnnounceDialog({bool isEditing = false}) {
    if (!isEditing) _clearForm();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AdminTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEditing ? 'Edit Winner' : 'Announce Winner', 
                             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),

                    // 1. SEARCH FIELD (Only show if not editing, or keep it if you want to allow changing the user)
                    if (!isEditing) ...[
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AdminTheme.textLight),
                        decoration: InputDecoration(
                          labelText: 'Search User (Name or ID)',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: 'Start typing...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        onChanged: (query) => _filterUsers(query, setStateDialog),
                      ),
                      const SizedBox(height: 8),

                      // 2. DROPDOWN
                      if (_filteredUsers.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple, width: 2),
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
                              
                              return ListTile(
                                dense: true,
                                leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.person, color: Colors.white, size: 20)),
                                title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                                subtitle: Text('ID: $userId', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                onTap: () => _selectUser(user),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // 3. CATEGORY
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: AdminTheme.surface,
                      style: const TextStyle(color: AdminTheme.textLight),
                      decoration: const InputDecoration(labelText: 'Category *', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                      items: const [
                        DropdownMenuItem(value: 'ADULTS', child: Text('Adults (18+)')),
                        DropdownMenuItem(value: 'CHILDREN', child: Text('Children (6-17)')),
                        DropdownMenuItem(value: 'CELEBRITY', child: Text('Celebrity')),
                      ],
                      onChanged: (value) => setStateDialog(() => _selectedCategory = value ?? 'ADULTS'),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // 4. NAME
                    TextFormField(controller: _winnerNameController, style: const TextStyle(color: AdminTheme.textLight), decoration: const InputDecoration(labelText: 'Winner Name *', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),

                    // 5. USER ID
                    TextFormField(controller: _winnerUseridController, style: const TextStyle(color: AdminTheme.textLight), decoration: const InputDecoration(labelText: 'Winner User ID *', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),

                    // 6. AGE
                    TextFormField(controller: _winnerAgeController, keyboardType: TextInputType.number, style: const TextStyle(color: AdminTheme.textLight), decoration: const InputDecoration(labelText: 'Winner Age *', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),

                    // 7. PROVINCE
                    TextFormField(controller: _provinceController, style: const TextStyle(color: AdminTheme.textLight), decoration: const InputDecoration(labelText: 'Province *', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),

                    // 8. MESSAGE
                    TextFormField(controller: _messageController, maxLines: 3, style: const TextStyle(color: AdminTheme.textLight), decoration: const InputDecoration(labelText: 'Message (Optional)', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
                    const SizedBox(height: 20),

                    // ACTION BUTTONS
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isEditing ? _updateWinner : _announceWinner,
                        icon: Icon(isEditing ? Icons.save : Icons.emoji_events),
                        label: Text(isEditing ? 'SAVE CHANGES' : 'ANNOUNCE WINNER', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, padding: const EdgeInsets.symmetric(vertical: 15)),
                      ),
                    ),
                    const SizedBox(height: 10), // Bottom padding for safe area
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _clearForm() {
    _editingWinnerId = null;
    _selectedCategory = 'ADULTS';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
        ),
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
                                  decoration: BoxDecoration(
                                    color: winner['category'] == 'CELEBRITY' ? Colors.amber : AdminTheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(winner['category'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('dd MMM yyyy').format(DateTime.parse(winner['announcedAt'])),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                                if (canModify)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => _editWinner(winner),
                                    tooltip: 'Edit Winner',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                if (canModify)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _deleteWinner(winner['id'], winner['winnerName']),
                                    tooltip: 'Delete Winner',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              winner['winnerName'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textLight),
                            ),
                            Text('User ID: ${winner['winnerUserid'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[400])),
                            Text('Age: ${winner['winnerAge']} | Province: ${winner['province'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[400])),
                            if (winner['message'] != null && winner['message'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  winner['message'],
                                  style: TextStyle(color: Colors.grey[300], fontStyle: FontStyle.italic),
                                ),
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
