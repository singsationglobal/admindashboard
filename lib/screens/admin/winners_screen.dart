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

  // ✅ FIXED: This now accepts the Dialog's setState function so the popup updates instantly
  Future<void> _filterUsers(String query, void Function(VoidCallback) dialogSetState) async {
    if (query.trim().isEmpty) {
      dialogSetState(() => _filteredUsers = []);
      return;
    }

    dialogSetState(() => _isSearching = true);

    try {
      // This uses the exact same working API call as your UsersScreen
      final data = await AdminApiService.searchUsers(query, 0, 20);
      
      if (mounted) {
        final List<dynamic> results = data['users'] ?? data['content'] ?? [];
        
        // ✅ CRITICAL FIX: We use dialogSetState here instead of the parent setState
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

    // We don't need setState here for the controllers, they update automatically
    _winnerNameController.text = fullName;
    _winnerUseridController.text = (user['userid'] ?? user['userId'] ?? '').toString();

    final age = user['age'];
    _winnerAgeController.text = (age != null) ? age.toString() : '0';
    _provinceController.text = user['province'] ?? '';

    _searchController.clear();
    _filteredUsers = []; // Clear dropdown after selection
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
        Navigator.pop(context); // Close dialog
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

  // ... (Keep your existing _updateWinner, _deleteWinner, _editWinner methods here) ...
  // For brevity, I'm omitting them, but keep them in your file!
  Future<void> _updateWinner() async { /* ... your existing code ... */ }
  Future<void> _deleteWinner(int winnerId, String winnerName) async { /* ... your existing code ... */ }
  void _editWinner(Map<String, dynamic> winner) { /* ... your existing code ... */ }

  // ✅ FIXED: The Dialog now uses StatefulBuilder
  void _showAnnounceDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // <--- THIS IS THE MAGIC FIX
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Announce Winner'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. SEARCH FIELD
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search User (Name or ID)',
                        hintText: 'Start typing...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      // ✅ Pass the dialog's setState function here
                      onChanged: (query) => _filterUsers(query, setStateDialog),
                    ),
                    const SizedBox(height: 8),

                    // 2. DROPDOWN (Only shows if _filteredUsers has data)
                    if (_filteredUsers.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple, width: 2),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredUsers.length > 5 ? 5 : _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final name = user['name'] ?? user['firstName'] ?? '';
                            final surname = user['surname'] ?? user['lastName'] ?? '';
                            final fullName = '$name $surname'.trim();
                            final userId = user['userid'] ?? user['userId'] ?? 'N/A';
                            
                            return ListTile(
                              dense: true,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.purple,
                                child: Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('ID: $userId | Province: ${user['province'] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                              onTap: () => _selectUser(user),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 3. CATEGORY
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category *', filled: true, fillColor: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'ADULTS', child: Text('Adults (18+)')),
                        DropdownMenuItem(value: 'CHILDREN', child: Text('Children (6-17)')),
                        DropdownMenuItem(value: 'CELEBRITY', child: Text('Celebrity')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() => _selectedCategory = value ?? 'ADULTS');
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // 4. NAME
                    TextFormField(
                      controller: _winnerNameController,
                      decoration: const InputDecoration(labelText: 'Winner Name *', filled: true, fillColor: Colors.white),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // 5. USER ID
                    TextFormField(
                      controller: _winnerUseridController,
                      decoration: const InputDecoration(labelText: 'Winner User ID *', filled: true, fillColor: Colors.white),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // 6. AGE
                    TextFormField(
                      controller: _winnerAgeController,
                      decoration: const InputDecoration(labelText: 'Winner Age *', filled: true, fillColor: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // 7. PROVINCE
                    TextFormField(
                      controller: _provinceController,
                      decoration: const InputDecoration(labelText: 'Province *', filled: true, fillColor: Colors.white),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // 8. MESSAGE
                    TextFormField(
                      controller: _messageController,
                      decoration: const InputDecoration(labelText: 'Message (Optional)', filled: true, fillColor: Colors.white),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              ElevatedButton(onPressed: _announceWinner, child: const Text('ANNOUNCE')),
            ],
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
    // ... (Keep your existing build method for the main list of winners) ...
    // It remains exactly the same as before.
    final bool canModify = (_userRole == 'SUPER_ADMIN' || _userRole == 'ADMIN');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Winner Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAnnounceDialog, tooltip: 'Announce Winner'),
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
                                if (canModify) IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _editWinner(winner)),
                                if (canModify) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteWinner(winner['id'], winner['winnerName'])),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(winner['winnerName'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
                            Text('User ID: ${winner['winnerUserid'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[400])),
                            Text('Age: ${winner['winnerAge']} | Province: ${winner['province'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
