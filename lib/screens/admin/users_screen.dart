  Future<void> _deleteUser(dynamic userId, String userName) async {
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
