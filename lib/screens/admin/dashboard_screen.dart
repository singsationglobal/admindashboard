import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_local_storage.dart';
import '../../core/admin_api_service.dart';
import 'login_screen.dart';
import 'users_screen.dart';
import 'songs_screen.dart';
import 'payments_screen.dart';
import 'complaints_screen.dart';
import 'splash_screen_management_screen.dart';
import 'winners_screen.dart';
import 'staff_screen.dart';
import 'user_activity_logs_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  Map<String, dynamic> _admin = {};
  String _userRole = 'SUPPORT';

  @override
  void initState() {
    super.initState();
    _loadAdminAndStats();
  }

  Future<void> _loadAdminAndStats() async {
    setState(() => _isLoading = true);
    _admin = await AdminLocalStorage.getAdmin();
    _userRole = await AdminLocalStorage.getRole();
    try {
      final stats = await AdminApiService.getDashboardStats(context: context);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load stats: $e')));
      }
    }
  }

  Future<void> _refreshStats() async {
    await _loadAdminAndStats();
  }

  void _logout() async {
    await AdminLocalStorage.clear();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  void _navigateTo(String screen) {
    switch (screen) {
      case 'users':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UsersScreen()));
        break;
      case 'songs':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SongsScreen()));
        break;
      case 'payments':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentsScreen()));
        break;
      case 'complaints':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ComplaintsScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminName = '${_admin['name'] ?? ''} ${_admin['surname'] ?? ''}'.trim();
    final displayName = adminName.isNotEmpty ? adminName : 'Admin';
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $displayName'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshStats, tooltip: 'Refresh'),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshStats,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: GoogleFonts.bebasNeue(fontSize: 28, color: AdminTheme.textLight)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          GestureDetector(onTap: () => _navigateTo('users'), child: _buildStatCard('Total Users', _stats['totalUsers']?.toString() ?? '0', Icons.people, Colors.blue)),
                          GestureDetector(onTap: () => _navigateTo('songs'), child: _buildStatCard('Total Songs', _stats['totalSongs']?.toString() ?? '0', Icons.music_note, Colors.green)),
                          GestureDetector(onTap: () => _navigateTo('payments'), child: _buildStatCard('Total Payments', _stats['totalPayments']?.toString() ?? '0', Icons.payments, Colors.orange)),
                          GestureDetector(onTap: () => _navigateTo('complaints'), child: _buildStatCard('Total Complaints', _stats['totalComplaints']?.toString() ?? '0', Icons.report_problem, Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: AdminTheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[400]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AdminTheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AdminTheme.primary),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('SINGSATION', style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Admin Panel', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
          ),
          _drawerTile(Icons.dashboard, 'Dashboard', 0, () => Navigator.pop(context)),
          _drawerTile(Icons.people, 'Users', 1, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UsersScreen()))),
          _drawerTile(Icons.music_note, 'Songs', 2, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SongsScreen()))),
          if (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN') _drawerTile(Icons.image, 'Splash Screen', 3, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SplashScreenManagementScreen()))),
          _drawerTile(Icons.emoji_events, 'Winners', 4, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WinnersScreen()))),
          _drawerTile(Icons.report_problem, 'Complaints', 5, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ComplaintsScreen()))),
          _drawerTile(Icons.payments, 'Payments', 6, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentsScreen()))),
          if (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN') _drawerTile(Icons.admin_panel_settings, 'Staff', 7, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StaffScreen()))),
          if (_userRole != 'SUPPORT') _drawerTile(Icons.history, 'Activity Logs', 8, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserActivityLogsScreen()))),
          const Divider(color: Colors.grey),
          _drawerTile(Icons.logout, 'Logout', 9, () {
            AdminLocalStorage.clear();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          }),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, int index, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: AdminTheme.primary), title: Text(title, style: const TextStyle(color: AdminTheme.textLight)), onTap: onTap);
  }
}