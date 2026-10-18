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

  // ✅ FIXED: Properly inside the State class, uses softDeleteUser
  Future<void> _deleteUser(dynamic userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Recycle Bin?'),
        content: Text('Are you sure you want to move $userName to the Recycle Bin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Move to Bin', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminApiService.softDeleteUser(userId is int ? userId : int.parse(userId.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName moved to Recycle Bin.'), backgroundColor: Colors.orange)
        );
        _loadUsers();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move to bin: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetails(dynamic user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final int userId = user['id'] is int ? user['id'] : int.parse(user['id'].toString());
      final coinStats = await AdminApiService.getUserCoinStats(userId);
      
      if (!mounted) return;
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AdminTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: (user['profileImageUrl'] != null && 
                            user['profileImageUrl'].toString().isNotEmpty && 
                            user['profileImageUrl'] != 'null')
                        ? () => _showFullImage(context, user['profileImageUrl'])
                        : null,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: AdminTheme.primary,
                      backgroundImage: (user['profileImageUrl'] != null && 
                                      user['profileImageUrl'].toString().isNotEmpty && 
                                      user['profileImageUrl'] != 'null')
                          ? NetworkImage(user['profileImageUrl'])
                          : null,
                      child: (user['profileImageUrl'] == null || 
                              user['profileImageUrl'].toString().isEmpty || 
                              user['profileImageUrl'] == 'null')
                          ? Text(
                              (user['name'] ?? '?').substring(0, 1).toUpperCase(), 
                              style: const TextStyle(color: Colors.white, fontSize: 24)
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${user['name'] ?? ''} ${user['surname'] ?? ''}', 
                             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
                        const SizedBox(height: 4),
                        Text('User ID: ${user['userid'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow('Email', user['email'] ?? 'N/A'),
              _buildDetailRow('Contact', user['contact'] ?? 'N/A'),
              _buildDetailRow('Province', user['province'] ?? 'N/A'),
              _buildDetailRow('Age', user['age']?.toString() ?? 'N/A'),
              const SizedBox(height: 16),
              const Text('Coin & Voting Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.primary)),
              const SizedBox(height: 8),
              _buildDetailRow('Current Balance', '${coinStats['currentBalance'] ?? 0} Coins', color: Colors.green),
              _buildDetailRow('Total Bought', '${coinStats['totalCoinsBought'] ?? 0} Coins', color: Colors.blue),
              _buildDetailRow('Total Spent (Voting)', '${coinStats['totalCoinsSpent'] ?? 0} Coins', color: Colors.orange),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showMessageDialog(user);
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Message User'),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load user details: $e')));
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(value, style: TextStyle(color: color ?? AdminTheme.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  void _showMessageDialog(dynamic user) {
    final messageController = TextEditingController();
    String selectedType = 'SUPPORT';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Message User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send a message to ${user['name'] ?? ''} ${user['surname'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Message Category', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'SUPPORT', child: Text('Support')),
                  DropdownMenuItem(value: 'COMPLAINT', child: Text('Complaint')),
                  DropdownMenuItem(value: 'GENERAL', child: Text('General Announcement')),
                ],
                onChanged: (value) {
                  if (value != null) setStateDialog(() => selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Type your message here...', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.trim().isNotEmpty) {
                  try {
                    await AdminApiService.sendMessageToUser(
                      user['id'] is int ? user['id'] : int.parse(user['id'].toString()),
                      selectedType,
                      messageController.text.trim(),
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent successfully'), backgroundColor: Colors.green));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red));
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
                      hintText: 'Search by name, ID, email...',
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
                      Text(_isSearching ? 'Results: $_totalElements' : 'Total: $_totalElements', style: const TextStyle(color: AdminTheme.textLight)),
                      Text('Page ${_currentPage + 1}/$_totalPages', style: const TextStyle(color: AdminTheme.textLight)),
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
                            final String? profileImageUrl = user['profileImageUrl'];
                            final bool hasImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              color: AdminTheme.surface,
                              child: ListTile(
                                onTap: () => _showUserDetails(user),
                                leading: GestureDetector(
                                  onTap: hasImage ? () => _showFullImage(context, profileImageUrl!) : null,
                                  child: CircleAvatar(
                                    backgroundColor: isActive ? Colors.green : Colors.red,
                                    backgroundImage: hasImage ? NetworkImage(profileImageUrl!) : null,
                                    child: !hasImage 
                                        ? Text((user['name'] ?? '?').substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white))
                                        : null,
                                  ),
                                ),
                                title: Text('${user['name'] ?? 'Unknown'} ${user['surname'] ?? ''}', style: const TextStyle(color: AdminTheme.textLight, fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['email'] ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                    Text('ID: ${user['userid'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                  ],
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    if (isActive) IconButton(icon: const Icon(Icons.block, color: Colors.orange, size: 20), onPressed: () => _banUser(user['id'], user['name']), tooltip: 'Ban'),
                                    if (!isActive) IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 20), onPressed: () => _unbanUser(user['id'], user['name']), tooltip: 'Unban'),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteUser(user['id'], user['name']), tooltip: 'Delete'),
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
                            setState(() { _currentPage--; _isSearching ? _performSearch() : _loadUsers(); });
                          },
                          child: const Text('PREVIOUS'),
                        ),
                      if (_currentPage < _totalPages - 1)
                        ElevatedButton(
                          onPressed: () {
                            setState(() { _currentPage++; _isSearching ? _performSearch() : _loadUsers(); });
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
