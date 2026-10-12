import 'package:flutter/material.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import 'dashboard_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getUsers(_currentPage, 20);
      if (!mounted) return;
      setState(() {
        _users = data['users'];
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _isSearching = false;
    });
    _loadUsers();
  }

  Future<void> _performSearch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.searchUsers(_searchQuery, _currentPage, 20);
      if (!mounted) return;
      setState(() {
        _users = data['users'];
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    }
  }

  Future<void> _banUser(dynamic userId, String userName) async {
    try {
      await AdminApiService.banUser(userId is int ? userId : int.parse(userId.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userName has been banned.')));
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to ban user: $e')));
    }
  }

  Future<void> _unbanUser(dynamic userId, String userName) async {
    try {
      await AdminApiService.unbanUser(userId is int ? userId : int.parse(userId.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userName has been unbanned.')));
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unban user: $e')));
    }
  }

  Future<void> _deleteUser(dynamic userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminApiService.deleteUser(userId is int ? userId : int.parse(userId.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userName has been deleted.')));
        _loadUsers();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
      }
    }
  }

  void _showMessageDialog(dynamic user) {
    final messageController = TextEditingController();
    String selectedType = 'SUPPORT'; // Default message type

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Message User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send a message to ${user['name'] ?? ''} ${user['surname'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // NEW: Dropdown to categorize the message for the user's app
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Message Category',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'SUPPORT', child: Text('Support')),
                  DropdownMenuItem(value: 'COMPLAINT', child: Text('Complaint')),
                  DropdownMenuItem(value: 'GENERAL', child: Text('General Announcement')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setStateDialog(() {
                      selectedType = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.trim().isNotEmpty) {
                  try {
                    await AdminApiService.sendMessageToUser(
                      user['id'] is int ? user['id'] : int.parse(user['id'].toString()),
                      selectedType, // Sends 'SUPPORT', 'COMPLAINT', or 'GENERAL' to your backend
                      messageController.text.trim(),
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message sent successfully to user\'s app'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      setState(() {
                        _searchQuery = value;
                        _isSearching = value.isNotEmpty;
                      });
                      _performSearch();
                    },
                    style: const TextStyle(color: AdminTheme.textLight),
                    decoration: InputDecoration(
                      hintText: 'Search by name, surname, ID, email, or contact...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: _clearSearch) : null,
                      filled: true,
                      fillColor: AdminTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_isSearching ? 'Search Results: $_totalElements' : 'Total Users: $_totalElements', style: const TextStyle(color: AdminTheme.textLight)),
                      Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(color: AdminTheme.textLight)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _users.isEmpty
                      ? const Center(child: Text('No users found.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isActive = user['isActive'] ?? true;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              color: AdminTheme.surface,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isActive ? Colors.green : Colors.red,
                                  child: Text((user['name'] ?? '?').substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                                ),
                                title: Text('${user['name'] ?? 'Unknown'} ${user['surname'] ?? ''}', style: const TextStyle(color: AdminTheme.textLight)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['email'] ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                    Text('UserID: ${user['userid'] ?? 'N/A'} | Contact: ${user['contact'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                    if (user['age'] != null && user['age'] != 0) Text('Age: ${user['age']} | Province: ${user['province'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                  ],
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(icon: const Icon(Icons.message, color: Colors.blue), onPressed: () => _showMessageDialog(user), tooltip: 'Message User'),
                                    if (isActive) IconButton(icon: const Icon(Icons.block, color: Colors.orange), onPressed: () => _banUser(user['id'], user['name']), tooltip: 'Ban'),
                                    if (!isActive) IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _unbanUser(user['id'], user['name']), tooltip: 'Unban'),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(user['id'], user['name']), tooltip: 'Delete'),
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
                      if (_currentPage > 0)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentPage--;
                              _isSearching ? _performSearch() : _loadUsers();
                            });
                          },
                          child: const Text('PREVIOUS'),
                        ),
                      if (_currentPage < _totalPages - 1)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentPage++;
                              _isSearching ? _performSearch() : _loadUsers();
                            });
                          },
                          child: const Text('NEXT'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
