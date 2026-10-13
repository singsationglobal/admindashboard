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
  
  final _userSearchController = TextEditingController();
  List<dynamic> _searchedUsers = [];
  bool _isSearchingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadWinners();
    // Pre-load users so search is instant
    _preloadUsers();
  }

  @override
  void dispose() {
    _winnerNameController.dispose();
    _winnerUseridController.dispose();
    _winnerAgeController.dispose();
    _provinceController.dispose();
    _messageController.dispose();
    _userSearchController.dispose();
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
          SnackBar(content: Text('Failed to load winners: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  // Pre-load users to make search instant and reliable
  List<dynamic> _allUsers = [];
  Future<void> _preloadUsers() async {
    try {
      final data = await AdminApiService.getUsers(0, 500);
      if (data['users'] is List) {
        _allUsers = data['users'];
        print('DEBUG: Pre-loaded ${_allUsers.length} users');
      }
    } catch (e) {
      print('DEBUG: Failed to preload users: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    print('DEBUG: Searching for: "$query"');
    if (query.isEmpty) {
      if (mounted) setState(() => _searchedUsers = []);
      return;
    }
    
    if (mounted) setState(() => _isSearchingUsers = true);
    
    try {
      // Use pre-loaded users for instant response, or fetch if empty
      List<dynamic> usersToSearch = _allUsers;
      if (usersToSearch.isEmpty) {
        final data = await AdminApiService.getUsers(0, 500);
        if (data['users'] is List) {
          usersToSearch = data['users'];
          _allUsers = usersToSearch;
        }
      }

      final searchLower = query.toLowerCase();
      final filtered = usersToSearch.where((user) {
        final name = (user['name'] ?? '').toLowerCase();
        final surname = (user['surname'] ?? '').toLowerCase();
        final userid = (user['userid'] ?? '').toLowerCase();
        return name.contains(searchLower) || surname.contains(searchLower) || userid.contains(searchLower);
      }).toList();

      print('DEBUG: Found ${filtered.length} matching users');
      
      if (mounted) {
        setState(() {
          _searchedUsers = filtered;
          _isSearchingUsers = false;
        });
      }
    } catch (e) {
      print('DEBUG: Failed to search users: $e');
      if (mounted) {
        setState(() => _isSearchingUsers = false);
      }
    }
  }

  void _autoFillUserData(Map<String, dynamic> user) {
    print('DEBUG: Auto-filling with user: ${user['name']} ${user['surname']}');
    setState(() {
      _winnerNameController.text = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
      _winnerUseridController.text = user['userid'] ?? '';
      _winnerAgeController.text = (user['age'] ?? 0).toString();
      _provinceController.text = user['province'] ?? '';
      
      // Clear search after selection
      _searchedUsers = [];
      _userSearchController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Auto-filled: ${user['name']} ${user['surname']}'),
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Winner announced successfully!'), backgroundColor: Colors.green)
        );
        print('DEBUG: Winner announced successfully');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to announce winner: $e'), backgroundColor: Colors.red)
        );
        print('DEBUG: Failed to announce winner: $e');
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
          body: json.encode(winnerData)
        );
        if (response.statusCode == 200) {
          _clearForm();
          _loadWinners();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Winner updated successfully'), backgroundColor: Colors.green)
          );
        } else {
          throw Exception('Failed to update winner');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update winner: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _deleteWinner(int winnerId, String winnerName) async {
    if (_userRole != 'SUPER_ADMIN' && _userRole != 'ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to delete winners'), backgroundColor: Colors.orange)
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Winner'),
        content: Text('Are you sure you want to delete "$winnerName"? This will remove it from all users\' apps.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('DELETE')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId'), 
          headers: await AdminApiService.getAuthHeader()
        );
        if (response.statusCode == 200) {
          _loadWinners();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Winner deleted successfully'), backgroundColor: Colors.green)
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete winner: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _editWinner(Map<String, dynamic> winner) {
    _editingWinnerId = winner['id'];
    _selectedCategory = winner['category'] ?? 'ADULTS';
    _winnerNameController.text = winner['winnerName'] ?? '';
    _winnerUseridController.text = winner['winnerUserid'] ?? '';
    _winnerAgeController.text = (winner['winnerAge'] ?? 0).toString();
    _provinceController.text = winner['province'] ?? '';
    _messageController.text = winner['message'] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Winner'),
        content: SingleChildScrollView(child: _buildForm()),
        actions: [
          TextButton(onPressed: () { _clearForm(); Navigator.pop(context); }, child: const Text('CANCEL')),
          ElevatedButton(onPressed: _updateWinner, child: const Text('UPDATE')),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SEARCH FIELD
          TextField(
            controller: _userSearchController,
            decoration: const InputDecoration(
              labelText: 'Search User (Name or ID)',
              hintText: 'Type name or User ID to auto-fill...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _searchUsers,
          ),
          const SizedBox(height: 8),
          
          // SEARCH RESULTS DROPDOWN (Highly Visible)
          if (_isSearchingUsers)
            const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
          else if (_searchedUsers.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white, // Explicit white background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple, width: 2), // Highly visible border
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchedUsers.length > 5 ? 5 : _searchedUsers.length,
                itemBuilder: (context, index) {
                  final user = _searchedUsers[index];
                  final fullName = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${user['userid'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87)),
                        Text('Age: ${user['age'] ?? 'N/A'} | Province: ${user['province'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    onTap: () {
                      print('DEBUG: Tapped user to auto-fill: $user');
                      _autoFillUserData(user);
                    },
                  );
                },
              ),
            ),
            
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category *', filled: true, fillColor: Colors.white),
            items: const [
              DropdownMenuItem(value: 'ADULTS', child: Text('Adults (18+)')),
              DropdownMenuItem(value: 'CHILDREN', child: Text('Children (6-17)')),
              DropdownMenuItem(value: 'CELEBRITY', child: Text('Celebrity')),
            ],
            onChanged: (value) {
              setState(() => _selectedCategory = value ?? 'ADULTS');
              _searchedUsers.clear();
              _userSearchController.clear();
            },
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _winnerNameController,
            decoration: const InputDecoration(labelText: 'Winner Name *', filled: true, fillColor: Colors.white),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _winnerUseridController,
            decoration: const InputDecoration(labelText: 'Winner User ID *', filled: true, fillColor: Colors.white),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _winnerAgeController,
            decoration: const InputDecoration(labelText: 'Winner Age *', filled: true, fillColor: Colors.white),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _provinceController,
            decoration: const InputDecoration(labelText: 'Province *', filled: true, fillColor: Colors.white),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: 'Message (Optional)', filled: true, fillColor: Colors.white),
            maxLines: 3,
          ),
        ],
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
    _userSearchController.clear();
    _searchedUsers = [];
  }

  void _showAnnounceDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Announce Winner'),
        content: SingleChildScrollView(child: _buildForm()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: _announceWinner, child: const Text('ANNOUNCE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canModify = (_userRole == 'SUPER_ADMIN' || _userRole == 'ADMIN');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Winner Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))
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
                                Text(DateFormat('dd MMM yyyy').format(DateTime.parse(winner['announcedAt'])), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                if (canModify) IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _editWinner(winner), tooltip: 'Edit Winner', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                if (canModify) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteWinner(winner['id'], winner['winnerName']), tooltip: 'Delete Winner', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(winner['winnerName'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
                            Text('User ID: ${winner['winnerUserid'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[400])),
                            Text('Age: ${winner['winnerAge']} | Province: ${winner['province'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[400])),
                            if (winner['message'] != null && winner['message'].isNotEmpty)
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
