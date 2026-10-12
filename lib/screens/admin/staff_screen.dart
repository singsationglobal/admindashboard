import 'package:flutter/material.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import '../../core/admin_local_storage.dart';
import 'dashboard_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<dynamic> _staff = [];
  List<dynamic> _roles = [];
  bool _isLoading = true;
  String _currentAdminRole = 'SUPPORT';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'ADMIN';

  @override
  void initState() {
    super.initState();
    _loadCurrentAdminRole();
    _loadStaff();
    _loadRoles();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAdminRole() async {
    _currentAdminRole = await AdminLocalStorage.getRole();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final staff = await AdminApiService.getStaff();
      setState(() {
        _staff = staff;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load staff: $e')));
    }
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await AdminApiService.getRoles();
      setState(() => _roles = roles);
    } catch (e) {
      print('Failed to load roles: $e');
    }
  }

  Future<void> _createStaff() async {
    if (_formKey.currentState!.validate()) {
      final staffData = {'name': _nameController.text.trim(), 'surname': _surnameController.text.trim(), 'email': _emailController.text.trim()};
      try {
        await AdminApiService.createStaff(staffData, _selectedRole, _passwordController.text.trim());
        _clearForm();
        _loadStaff();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff created successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create staff: $e')));
      }
    }
  }

  Future<void> _deleteStaff(int staffId, String staffName, String staffRole) async {
    if (staffRole == 'SUPER_ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete Super Admin account')));
      return;
    }
    if (_currentAdminRole == 'ADMIN' && (staffRole == 'ADMIN' || staffRole == 'SUPER_ADMIN')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin cannot delete other Admin accounts')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Delete $staffName? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('DELETE')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminApiService.deleteStaff(staffId);
        _loadStaff();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete staff: $e')));
      }
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'First Name'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _surnameController, decoration: const InputDecoration(labelText: 'Last Name'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address'), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Temporary Password'), obscureText: true, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'Role'),
            items: _roles.isEmpty
                ? const [DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')), DropdownMenuItem(value: 'MODERATOR', child: Text('MODERATOR')), DropdownMenuItem(value: 'SUPPORT', child: Text('SUPPORT'))]
                : _roles.where((role) {
                    if (_currentAdminRole == 'ADMIN') return role['name'] != 'ADMIN' && role['name'] != 'SUPER_ADMIN';
                    return role['name'] != 'SUPER_ADMIN';
                  }).map<DropdownMenuItem<String>>((role) {
                    return DropdownMenuItem(value: role['name'] ?? 'ADMIN', child: Text(role['name'] ?? 'ADMIN'));
                  }).toList(),
            onChanged: (value) => setState(() => _selectedRole = value ?? 'ADMIN'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _surnameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedRole = 'ADMIN';
  }

  void _showCreateStaffDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Staff Account'),
        content: SingleChildScrollView(child: _buildForm()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: _createStaff, child: const Text('CREATE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))),
        actions: [if (_currentAdminRole == 'SUPER_ADMIN' || _currentAdminRole == 'ADMIN') IconButton(icon: const Icon(Icons.add), onPressed: _showCreateStaffDialog, tooltip: 'Add Staff')],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
              ? const Center(child: Text('No staff members found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staff.length,
                  itemBuilder: (context, index) {
                    final staff = _staff[index];
                    final role = staff['role'] ?? {};
                    final roleName = role['name'] ?? 'Unknown';
                    final isSuperAdmin = roleName == 'SUPER_ADMIN';
                    final canDelete = _currentAdminRole == 'SUPER_ADMIN' && !isSuperAdmin;
                    return Card(
                      color: AdminTheme.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: isSuperAdmin ? Colors.amber : AdminTheme.primary, child: Text(staff['name']?.substring(0, 1).toUpperCase() ?? '?', style: const TextStyle(color: Colors.white))),
                        title: Text('${staff['name'] ?? ''} ${staff['surname'] ?? ''}', style: const TextStyle(color: AdminTheme.textLight)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff['email'] ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            Text('Role: $roleName', style: TextStyle(color: isSuperAdmin ? Colors.amber : Colors.grey[500], fontSize: 10)),
                          ],
                        ),
                        trailing: canDelete ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteStaff(staff['id'], staff['name'], roleName), tooltip: 'Delete Staff') : null,
                      ),
                    );
                  },
                ),
    );
  }
}