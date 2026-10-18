import 'dart:convert'; // ✅ ADDED: This was missing, causing the json.decode error
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/api_config.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import '../../core/delete_confirmation_dialog.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  List<dynamic> _deletedWinners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedWinners();
  }

  Future<void> _loadDeletedWinners() async {
    setState(() => _isLoading = true);
    try {
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
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _restoreWinner(int winnerId, String winnerName) async {
    try {
      await AdminApiService.restoreWinner(winnerId);
      _loadDeletedWinners();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$winnerName restored!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _permanentDelete(int winnerId, String winnerName) async {
    final confirm = await showPermanentDeleteConfirmation(context, winnerName);
    
    if (confirm) {
      try {
        await AdminApiService.permanentDeleteWinner(winnerId);
        _loadDeletedWinners();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$winnerName permanently deleted'), backgroundColor: Colors.red));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Winners Recycle Bin'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedWinners.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_sweep, size: 80, color: Colors.grey), SizedBox(height: 16), Text('Recycle bin is empty', style: TextStyle(fontSize: 18, color: Colors.grey))]))
              : ListView.builder(
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
                                const Icon(Icons.delete, color: Colors.red, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(winner['winnerName'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
                            Text('Deleted: $deletedAt', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: ElevatedButton.icon(onPressed: () => _restoreWinner(winner['id'], winner['winnerName']), icon: const Icon(Icons.restore), label: const Text('RESTORE'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))),
                                const SizedBox(width: 8),
                                Expanded(child: ElevatedButton.icon(onPressed: () => _permanentDelete(winner['id'], winner['winnerName']), icon: const Icon(Icons.delete_forever), label: const Text('PERMANENTLY DELETE'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red))),
                              ],
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
