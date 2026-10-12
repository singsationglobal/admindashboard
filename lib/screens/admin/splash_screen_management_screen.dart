import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../core/api_config.dart';
import '../../core/admin_api_service.dart';
import '../../core/admin_theme.dart';
import 'dashboard_screen.dart';

class SplashScreenManagementScreen extends StatefulWidget {
  const SplashScreenManagementScreen({super.key});
  @override
  State<SplashScreenManagementScreen> createState() => _SplashScreenManagementScreenState();
}

class _SplashScreenManagementScreenState extends State<SplashScreenManagementScreen> {
  List<dynamic> _allSplashScreens = [];
  String? _currentActiveImageUrl;
  bool _isLoading = true;
  bool _isUploading = false;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllSplashScreens();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSplashScreens() async {
    setState(() => _isLoading = true);
    try {
      final allScreens = await AdminApiService.getAllSplashScreens();
      final current = await AdminApiService.getSplashScreen();
      setState(() {
        _allSplashScreens = allScreens;
        _currentActiveImageUrl = current['imageUrl'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load splash screens: $e')));
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'webm']);
      if (result != null) {
        setState(() => _isUploading = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading splash screen...'), duration: Duration(seconds: 2)));
        final uploadResult = await AdminApiService.uploadSplashScreen(result);
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _currentActiveImageUrl = uploadResult['imageUrl'];
          _isUploading = false;
        });
        await _loadAllSplashScreens();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Splash screen uploaded and activated successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid URL')));
      return;
    }
    setState(() => _isUploading = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving splash screen URL...'), duration: Duration(seconds: 1)));
      final result = await AdminApiService.uploadSplashScreen(null, imageUrl: url);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _currentActiveImageUrl = result['imageUrl'];
        _isUploading = false;
        _urlController.clear();
      });
      await _loadAllSplashScreens();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Splash screen URL saved successfully'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save URL: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _activateSplashScreen(int id, String imageUrl) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activating splash screen...'), duration: Duration(seconds: 1)));
    try {
      final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id/activate'), headers: await AdminApiService.getAuthHeader());
      if (response.statusCode == 200) {
        setState(() => _currentActiveImageUrl = imageUrl);
        await Future.delayed(const Duration(milliseconds: 300));
        await _loadAllSplashScreens();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Splash screen activated successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to activate: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteSplashScreen(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Splash Screen'),
        content: const Text('Are you sure you want to delete this splash screen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('DELETE')),
        ],
      ),
    );
    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting splash screen...'), duration: Duration(seconds: 1)));
      try {
        final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id'), headers: await AdminApiService.getAuthHeader());
        if (response.statusCode == 200) {
          await _loadAllSplashScreens();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Splash screen deleted successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.upload_file, color: AdminTheme.primary), title: const Text('Upload Image/Video', style: TextStyle(color: AdminTheme.textLight)), onTap: () { Navigator.pop(context); _pickAndUploadFile(); }),
            ListTile(leading: const Icon(Icons.link, color: AdminTheme.secondary), title: const Text('Enter URL', style: TextStyle(color: AdminTheme.textLight)), onTap: () { Navigator.pop(context); _showUrlDialog(); }),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog() {
    _urlController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Image/Video URL'),
        content: TextField(controller: _urlController, decoration: const InputDecoration(hintText: 'https://...', border: OutlineInputBorder()), keyboardType: TextInputType.url),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: _saveUrl, child: const Text('SAVE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Splash Screen Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showUploadOptions, tooltip: 'Add Splash Screen'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllSplashScreens, tooltip: 'Refresh'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green, width: 2)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 20), const SizedBox(width: 8), Text('CURRENTLY ACTIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))]),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              width: 200,
                              height: 350,
                              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminTheme.primary, width: 1)),
                              child: _currentActiveImageUrl != null && _currentActiveImageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: _currentActiveImageUrl!.contains('.mp4') || _currentActiveImageUrl!.contains('.webm')
                                          ? const Center(child: Text('🎬 Video', style: TextStyle(color: Colors.white70)))
                                          : Image.network(_currentActiveImageUrl!, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, color: AdminTheme.primary));
                                            }, errorBuilder: (context, error, stackTrace) => Center(child: Text('Failed to load', style: TextStyle(color: Colors.grey[400])))),
                                    )
                                  : Center(child: Text('No active splash screen', style: TextStyle(color: Colors.grey[400]))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [const Icon(Icons.history, color: AdminTheme.secondary, size: 20), const SizedBox(width: 8), Text('ALL SPLASH SCREENS', style: TextStyle(color: AdminTheme.textLight, fontWeight: FontWeight.bold, fontSize: 14))]),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _allSplashScreens.isEmpty
                          ? const Center(child: Text('No splash screens uploaded yet.\nTap + to add one.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _allSplashScreens.length,
                              itemBuilder: (context, index) {
                                final screen = _allSplashScreens[index];
                                final isActive = screen['active'] == true;
                                final imageUrl = screen['imageUrl'];
                                final id = screen['id'];
                                return Card(
                                  color: AdminTheme.surface,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isActive ? Colors.green : Colors.transparent, width: 2)),
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 80,
                                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                                      child: imageUrl.contains('.mp4') || imageUrl.contains('.webm') ? const Icon(Icons.video_library, color: Colors.white70) : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.grey[500]))),
                                    ),
                                    title: Text(imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl, style: const TextStyle(color: AdminTheme.textLight, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    subtitle: Text('ID: $id | ${isActive ? "ACTIVE" : "Inactive"}', style: TextStyle(color: isActive ? Colors.green : Colors.grey[500], fontSize: 10)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isActive) IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green), onPressed: () => _activateSplashScreen(id, imageUrl), tooltip: 'Activate'),
                                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSplashScreen(id), tooltip: 'Delete'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                if (_isUploading)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Processing...', style: TextStyle(color: Colors.white))])),
                  ),
              ],
            ),
    );
  }
}