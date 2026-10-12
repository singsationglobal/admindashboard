import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import 'dashboard_screen.dart';

class UserActivityLogsScreen extends StatefulWidget {
  const UserActivityLogsScreen({super.key});
  @override
  State<UserActivityLogsScreen> createState() => _UserActivityLogsScreenState();
}

class _UserActivityLogsScreenState extends State<UserActivityLogsScreen> {
  List<dynamic> _logs = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = true;
  String _filterType = 'all';
  final List<String> _filterOptions = ['all', 'login', 'song_play', 'profile_update', 'complaint', 'payment', 'competition'];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getUserActivityLogs(_currentPage, 50);
      setState(() {
        _logs = data['logs'];
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load user activity logs: $e')));
      }
    }
  }

  List<dynamic> get _filteredLogs {
    if (_filterType == 'all') return _logs;
    return _logs.where((log) => log['action'] == _filterType).toList();
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'login': return Icons.login;
      case 'song_play': return Icons.play_circle;
      case 'profile_update': return Icons.edit;
      case 'complaint': return Icons.report_problem;
      case 'payment': return Icons.payment;
      case 'competition': return Icons.emoji_events;
      default: return Icons.history;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'login': return Colors.green;
      case 'song_play': return Colors.blue;
      case 'profile_update': return Colors.orange;
      case 'complaint': return Colors.red;
      case 'payment': return Colors.purple;
      case 'competition': return Colors.amber;
      default: return AdminTheme.primary;
    }
  }

  String _formatActionName(String action) {
    switch (action) {
      case 'login': return 'User Login';
      case 'song_play': return 'Song Played';
      case 'profile_update': return 'Profile Updated';
      case 'complaint': return 'Complaint Submitted';
      case 'payment': return 'Payment Made';
      case 'competition': return 'Competition Entry';
      default: return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Activity Logs'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs, tooltip: 'Refresh')],
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
                      Text('Total Activities: $_totalElements', style: const TextStyle(color: AdminTheme.textLight)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AdminTheme.primary)),
                        child: DropdownButton<String>(
                          value: _filterType,
                          dropdownColor: AdminTheme.surface,
                          underline: const SizedBox(),
                          icon: Icon(Icons.filter_list, color: AdminTheme.primary),
                          items: _filterOptions.map((String option) {
                            return DropdownMenuItem<String>(value: option, child: Text(option == 'all' ? 'All Types' : _formatActionName(option), style: const TextStyle(color: AdminTheme.textLight)));
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _filterType = newValue ?? 'all';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(_logs.isEmpty ? 'No user activity logs found' : 'No ${_formatActionName(_filterType)} activities found', style: TextStyle(color: Colors.grey[500])),
                              const SizedBox(height: 8),
                              if (_logs.isEmpty) const Text('User actions will appear here when they use the app', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            final user = log['user'] ?? {};
                            final details = log['details'] ?? {};
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              color: AdminTheme.surface,
                              child: ListTile(
                                leading: Icon(_getActionIcon(log['action'] ?? ''), color: _getActionColor(log['action'] ?? ''), size: 30),
                                title: Text(_formatActionName(log['action'] ?? 'Unknown'), style: const TextStyle(color: AdminTheme.textLight, fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('User: ${user['name'] ?? 'Unknown'} (${user['userid'] ?? user['email'] ?? 'No ID'})', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                    if (details.isNotEmpty) Text('Details: ${details.toString()}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                    Text(log['createdAt'] != null ? DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.parse(log['createdAt'])) : 'Unknown', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                  ],
                                ),
                                isThreeLine: details.isNotEmpty,
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
                      if (_currentPage > 0) ElevatedButton(onPressed: () { setState(() { _currentPage--; _loadLogs(); }); }, child: const Text('PREVIOUS')),
                      if (_currentPage < _totalPages - 1) ElevatedButton(onPressed: () { setState(() { _currentPage++; _loadLogs(); }); }, child: const Text('NEXT')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}