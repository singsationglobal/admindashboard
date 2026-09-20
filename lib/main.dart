import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

// IMPORT YOUR PUBLIC PAGES HERE
import 'home_page.dart';
import 'about_page.dart';
import 'app_download_page.dart';
import 'contact_page.dart';
import 'faq_page.dart';
import 'privacy_page.dart';

// ============================================================================
// API CONFIGURATION
// ============================================================================
class ApiConfig {
  /// Single source of truth for the backend base URL.
  /// Same URL as before on every platform — web, Windows, Android, iOS.
  static const String baseUrl =
      'https://singsation-api-d5hd.onrender.com/api';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

// ============================================================================
// LOCAL STORAGE
// ============================================================================
class AdminLocalStorage {
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }
  static Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString('admin_token', token);
    print('✅ Token saved: ${token.substring(0, 20)}...');
  }
  static Future<String> getToken() async {
    final prefs = await _getPrefs();
    final token = prefs.getString('admin_token') ?? '';
    print('🔑 Token retrieved: ${token.isNotEmpty ? token.substring(0, 20) + "..." : "EMPTY"}');
    return token;
  }
  static Future<void> saveAdmin(Map<String, dynamic> admin) async {
    final prefs = await _getPrefs();
    await prefs.setString('admin_data', json.encode(admin));
    print('✅ Admin data saved: ${admin['email']}');
  }
  static Future<Map<String, dynamic>> getAdmin() async {
    final prefs = await _getPrefs();
    final data = prefs.getString('admin_data');
    if (data != null && data.isNotEmpty) {
      try {
        return json.decode(data) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Failed to parse admin data: $e');
        return {};
      }
    }
    return {};
  }
  static Future<void> saveRole(String role) async {
    final prefs = await _getPrefs();
    await prefs.setString('admin_role', role);
  }
  static Future<String> getRole() async {
    final prefs = await _getPrefs();
    return prefs.getString('admin_role') ?? 'SUPPORT';
  }
  static Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.remove('admin_token');
    await prefs.remove('admin_data');
    await prefs.remove('admin_role');
    print('🧹 Admin storage cleared');
  }
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token.isNotEmpty;
  }
}

// ============================================================================
// API SERVICE
// ============================================================================
class AdminApiService {
  static Future<Map<String, String>> _authHeader() async {
    final token = await AdminLocalStorage.getToken();
    if (token.isNotEmpty) {
      return {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      };
    }
    print('⚠️ No token found - request will be unauthorized');
    return ApiConfig.headers;
  }
  static Future<Map<String, String>> getAuthHeader() async {
    return await _authHeader();
  }
  static Future<void> handleUnauthorized(BuildContext? context) async {
    await AdminLocalStorage.clear();
    if (context != null && Navigator.canPop(context)) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
  static Future<Map<String, dynamic>> login(String email, String password) async {
    print('🔐 Attempting login for: $email');
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/auth/login'),
      headers: ApiConfig.headers,
      body: json.encode({'email': email, 'password': password}),
    );
    print('📡 Login response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await AdminLocalStorage.saveToken(data['token']);
      await AdminLocalStorage.saveAdmin(data['admin']);
      await AdminLocalStorage.saveRole(data['admin']['role']?['name'] ?? 'SUPPORT');
      print('✅ Login successful, token saved');
      return data;
    } else {
      print('❌ Login failed: ${response.body}');
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }
  static Future<Map<String, dynamic>> getUsers(int page, int size) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/users?page=$page&size=$size'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load users: ${response.statusCode}');
  }
  static Future<Map<String, dynamic>> checkUserIdExists(String userId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/check-userid?userid=$userId'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {'exists': false};
  }
  static Future<void> banUser(int userId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/ban'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) throw Exception('Failed to ban user');
  }
  static Future<void> unbanUser(int userId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/unban'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) throw Exception('Failed to unban user');
  }
  static Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete user');
  }
  static Future<Map<String, dynamic>> getSongs(int page, int size) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs?page=$page&size=$size'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load songs: ${response.statusCode}');
  }
  static Future<Map<String, dynamic>> createSong(Map<String, dynamic> songData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs'),
      headers: await _authHeader(),
      body: json.encode(songData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create song');
  }
  static Future<Map<String, dynamic>> updateSong(int songId, Map<String, dynamic> songData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId'),
      headers: await _authHeader(),
      body: json.encode(songData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update song');
  }
  static Future<void> hideSong(int songId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/hide'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) throw Exception('Failed to hide song');
  }
  static Future<void> unhideSong(int songId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/unhide'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) throw Exception('Failed to unhide song');
  }
  static Future<void> deleteSong(int songId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete song');
  }
  static Future<Map<String, dynamic>> uploadSongFiles(int songId, {XFile? audioFile, XFile? videoFile}) async {
    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/upload-files'));
    request.headers.addAll(await _authHeader());
    if (audioFile != null) {
      if (kIsWeb) {
        final bytes = await audioFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'audioFile',
          bytes,
          filename: audioFile.name,
          contentType: MediaType('audio', 'mpeg'),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'audioFile',
          audioFile.path,
          contentType: MediaType('audio', 'mpeg'),
        ));
      }
    }
    if (videoFile != null) {
      if (kIsWeb) {
        final bytes = await videoFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'videoFile',
          bytes,
          filename: videoFile.name,
          contentType: MediaType('video', 'mp4'),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'videoFile',
          videoFile.path,
          contentType: MediaType('video', 'mp4'),
        ));
      }
    }
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      return json.decode(responseBody);
    }
    throw Exception('Failed to upload song files');
  }
  static Future<Map<String, dynamic>> announceWinner(Map<String, dynamic> winnerData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/winners/announce'),
      headers: await _authHeader(),
      body: json.encode(winnerData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to announce winner');
  }
  static Future<List<dynamic>> getActiveWinners() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/winners/active'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }
  static Future<Map<String, dynamic>> getComplaints(int page, int size, {String? status}) async {
    String url = '${ApiConfig.baseUrl}/admin/complaints?page=$page&size=$size';
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load complaints');
  }
  static Future<Map<String, dynamic>> getComplaintById(int complaintId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load complaint');
  }
  static Future<Map<String, dynamic>> replyToComplaint(int complaintId, String adminReply, String status) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId/reply'),
      headers: await _authHeader(),
      body: json.encode({'adminReply': adminReply, 'status': status}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to reply to complaint');
  }
  static Future<Map<String, dynamic>> getPayments(int page, int size) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/payments?page=$page&size=$size'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load payments');
  }
  static Future<List<dynamic>> getStaff() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/staff'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load staff');
  }
  static Future<Map<String, dynamic>> createStaff(Map<String, dynamic> staffData, String roleName, String rawPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/staff?roleName=$roleName&rawPassword=$rawPassword'),
      headers: await _authHeader(),
      body: json.encode(staffData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create staff');
  }
  static Future<void> deleteStaff(int staffId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/staff/$staffId'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete staff');
  }
  static Future<List<dynamic>> getRoles() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/staff/roles'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }
  static Future<Map<String, dynamic>> getUserActivityLogs(int page, int size) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/logs/user-activity?page=$page&size=$size'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load user activity logs');
  }
  static Future<Map<String, dynamic>> getLogs(int adminId, int page, int size) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/logs/admin/$adminId?page=$page&size=$size'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load logs');
  }
  static Future<List<dynamic>> getAllSplashScreens() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/all'),
        headers: await _authHeader(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Failed to load all splash screens: $e');
      return [];
    }
  }
  static Future<Map<String, dynamic>> activateSplashScreen(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id/activate'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to activate splash screen');
  }
  static Future<Map<String, dynamic>> uploadSplashScreen(FilePickerResult? result, {String? imageUrl}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/url'),
        headers: await _authHeader(),
        body: json.encode({'imageUrl': imageUrl}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to save splash screen URL');
    }
    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }
    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/upload'));
    request.headers.addAll(await _authHeader());
    final file = result.files.first;
    final bytes = file.bytes;
    final filename = file.name;
    if (bytes != null) {
      String mimeType = _getMimeType(filename);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));
    } else if (file.path != null && !kIsWeb) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        file.path!,
      ));
    }
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      return json.decode(responseBody);
    }
    throw Exception('Failed to upload splash screen');
  }
  static String _getMimeType(String filename) {
    if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) return 'image/jpeg';
    if (filename.endsWith('.png')) return 'image/png';
    if (filename.endsWith('.gif')) return 'image/gif';
    if (filename.endsWith('.mp4')) return 'video/mp4';
    if (filename.endsWith('.webm')) return 'video/webm';
    return 'image/jpeg';
  }
  static Future<Map<String, dynamic>> getSplashScreen() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'imageUrl': data['imageUrl'] ?? 'https://objectstorage.af-johannesburg-1.oraclecloud.com/n/axcbefxpjvzm/b/karaokeimages/o/Splashscreensplash.jpg',
      };
    }
    return {
      'imageUrl': 'https://objectstorage.af-johannesburg-1.oraclecloud.com/n/axcbefxpjvzm/b/karaokeimages/o/Splashscreensplash.jpg',
    };
  }
  static Future<void> deleteSplashScreenById(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete splash screen');
  }
  static Future<void> deleteSplashScreen() async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen'),
      headers: await _authHeader(),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete splash screen');
  }
  static Future<Map<String, dynamic>> getDashboardStats({BuildContext? context}) async {
    print('📊 Fetching dashboard stats...');
    try {
      final headers = await _authHeader();
      print('📡 Request headers: $headers');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/dashboard/stats'),
        headers: headers,
      );
      print('📡 Dashboard stats response status: ${response.statusCode}');
      print('📡 Dashboard stats response body: ${response.body}');
      if (response.statusCode == 401) {
        await handleUnauthorized(context);
        throw Exception('Session expired. Please log in again.');
      }
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Dashboard stats from dedicated endpoint: $data');
        return data;
      } else {
        print('⚠️ Dedicated endpoint returned ${response.statusCode}, falling back...');
      }
    } catch (e, stackTrace) {
      print('❌ Dedicated endpoint error: $e');
      print('Stack trace: $stackTrace');
    }
    print('🔄 Falling back to individual count endpoints...');
    try {
      final users = await getUsers(0, 1);
      final songs = await getSongs(0, 1);
      final payments = await getPayments(0, 1);
      final complaints = await getComplaints(0, 1);
      final totalUsers = users['totalElements'] ?? 0;
      final totalSongs = songs['totalElements'] ?? 0;
      final totalPayments = payments['totalElements'] ?? 0;
      final totalComplaints = complaints['totalElements'] ?? 0;
      print('📊 Fallback counts - Users: $totalUsers, Songs: $totalSongs, Payments: $totalPayments, Complaints: $totalComplaints');
      return {
        'totalUsers': totalUsers,
        'totalSongs': totalSongs,
        'totalPayments': totalPayments,
        'totalComplaints': totalComplaints,
      };
    } catch (e, stackTrace) {
      print('❌ Fallback also failed: $e');
      print('Stack trace: $stackTrace');
      return {
        'totalUsers': 0,
        'totalSongs': 0,
        'totalPayments': 0,
        'totalComplaints': 0,
      };
    }
  }
}

// ============================================================================
// THEME
// ============================================================================
class AdminTheme {
  static const Color primary = Color(0xFF8E44AD);
  static const Color secondary = Color(0xFFFDB400);
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);
  static const Color error = Color(0xFFE94560);
  static const Color success = Color(0xFF00FF88);
  static const Color textLight = Colors.white;
  static const Color textDark = Color(0xFF0F3460);
}

// ============================================================================
// MAIN APP
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SingsationAdminApp());
}

class SingsationAdminApp extends StatefulWidget {
  const SingsationAdminApp({super.key});

  @override
  State<SingsationAdminApp> createState() => _SingsationAdminAppState();
}

class _SingsationAdminAppState extends State<SingsationAdminApp> {
  bool? _isLoggedIn;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final loggedIn = await AdminLocalStorage.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Container(
            color: AdminTheme.background,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Singsation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AdminTheme.primary,
        scaffoldBackgroundColor: AdminTheme.background,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: AdminTheme.surface,
          foregroundColor: AdminTheme.textLight,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminTheme.primary, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primary,
            foregroundColor: AdminTheme.textLight,
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      // THIS IS THE KEY CHANGE: Start with the public HomePage.
      // The admin panel remains fully accessible via the hidden footer button.
      home: const HomePage(),
    );
  }
}

// ============================================================================
// LOGIN SCREEN
// ============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AdminApiService.login(_emailController.text.trim(), _passwordController.text.trim());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AdminTheme.background, AdminTheme.surface],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: AdminTheme.surface,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 80, color: AdminTheme.secondary),
                    const SizedBox(height: 16),
                    Text(
                      'SINGSATION ADMIN',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 32,
                        color: AdminTheme.textLight,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD SCREEN
// ============================================================================
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
    print('👤 Dashboard admin loaded: ${_admin['name']} ${_admin['surname']}');
    print('👤 User role: $_userRole');
    try {
      final stats = await AdminApiService.getDashboardStats(context: context);
      print('📊 Dashboard stats loaded: $stats');
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Dashboard stats error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stats: $e')),
        );
      }
    }
  }

  Future<void> _refreshStats() async {
    await _loadAdminAndStats();
  }

  void _logout() async {
    await AdminLocalStorage.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _navigateTo(String screen) {
    switch (screen) {
      case 'users':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UsersScreen()),
        );
        break;
      case 'songs':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SongsScreen()),
        );
        break;
      case 'payments':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentsScreen()),
        );
        break;
      case 'complaints':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ComplaintsScreen()),
        );
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStats,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
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
                    Text(
                      'Dashboard',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 28,
                        color: AdminTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          GestureDetector(
                            onTap: () => _navigateTo('users'),
                            child: _buildStatCard(
                              'Total Users',
                              _stats['totalUsers']?.toString() ?? '0',
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateTo('songs'),
                            child: _buildStatCard(
                              'Total Songs',
                              _stats['totalSongs']?.toString() ?? '0',
                              Icons.music_note,
                              Colors.green,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateTo('payments'),
                            child: _buildStatCard(
                              'Total Payments',
                              _stats['totalPayments']?.toString() ?? '0',
                              Icons.payments,
                              Colors.orange,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateTo('complaints'),
                            child: _buildStatCard(
                              'Total Complaints',
                              _stats['totalComplaints']?.toString() ?? '0',
                              Icons.report_problem,
                              Colors.red,
                            ),
                          ),
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AdminTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
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
            decoration: const BoxDecoration(
              color: AdminTheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'SINGSATION',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _drawerTile(Icons.dashboard, 'Dashboard', 0, () {
            Navigator.pop(context);
          }),
          _drawerTile(Icons.people, 'Users', 1, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UsersScreen()),
            );
          }),
          _drawerTile(Icons.music_note, 'Songs', 2, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SongsScreen()),
            );
          }),
          if (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN')
            _drawerTile(Icons.image, 'Splash Screen', 3, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SplashScreenManagementScreen()),
              );
            }),
          _drawerTile(Icons.emoji_events, 'Winners', 4, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WinnersScreen()),
            );
          }),
          _drawerTile(Icons.report_problem, 'Complaints', 5, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ComplaintsScreen()),
            );
          }),
          _drawerTile(Icons.payments, 'Payments', 6, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PaymentsScreen()),
            );
          }),
          if (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN')
            _drawerTile(Icons.admin_panel_settings, 'Staff', 7, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StaffScreen()),
              );
            }),
          if (_userRole != 'SUPPORT')
            _drawerTile(Icons.history, 'Activity Logs', 8, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserActivityLogsScreen()),
              );
            }),
          const Divider(color: Colors.grey),
          _drawerTile(Icons.logout, 'Logout', 9, () {
            AdminLocalStorage.clear();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, int index, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AdminTheme.primary),
      title: Text(title, style: const TextStyle(color: AdminTheme.textLight)),
      onTap: onTap,
    );
  }
}

// ============================================================================
// SPLASH SCREEN MANAGEMENT SCREEN
// ============================================================================
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load splash screens: $e')),
      );
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'webm'],
      );
      if (result != null) {
        setState(() => _isUploading = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading splash screen...'), duration: Duration(seconds: 2)),
        );
        final uploadResult = await AdminApiService.uploadSplashScreen(result);
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _currentActiveImageUrl = uploadResult['imageUrl'];
          _isUploading = false;
        });
        await _loadAllSplashScreens();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Splash screen uploaded and activated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving splash screen URL...'), duration: Duration(seconds: 1)),
      );
      final result = await AdminApiService.uploadSplashScreen(null, imageUrl: url);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _currentActiveImageUrl = result['imageUrl'];
        _isUploading = false;
        _urlController.clear();
      });
      await _loadAllSplashScreens();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Splash screen URL saved successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save URL: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _activateSplashScreen(int id, String imageUrl) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activating splash screen...'), duration: Duration(seconds: 1)),
    );
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id/activate'),
        headers: await AdminApiService._authHeader(),
      );
      if (response.statusCode == 200) {
        setState(() {
          _currentActiveImageUrl = imageUrl;
        });
        await Future.delayed(const Duration(milliseconds: 300));
        await _loadAllSplashScreens();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Splash screen activated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to activate: $e'), backgroundColor: Colors.red),
      );
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting splash screen...'), duration: Duration(seconds: 1)),
      );
      try {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id'),
          headers: await AdminApiService._authHeader(),
        );
        if (response.statusCode == 200) {
          await _loadAllSplashScreens();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Splash screen deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file, color: AdminTheme.primary),
              title: const Text('Upload Image/Video', style: TextStyle(color: AdminTheme.textLight)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AdminTheme.secondary),
              title: const Text('Enter URL', style: TextStyle(color: AdminTheme.textLight)),
              onTap: () {
                Navigator.pop(context);
                _showUrlDialog();
              },
            ),
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
        content: TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showUploadOptions,
            tooltip: 'Add Splash Screen',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllSplashScreens,
            tooltip: 'Refresh',
          ),
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
                      decoration: BoxDecoration(
                        color: AdminTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'CURRENTLY ACTIVE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              width: 200,
                              height: 350,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AdminTheme.primary, width: 1),
                              ),
                              child: _currentActiveImageUrl != null && _currentActiveImageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: _currentActiveImageUrl!.contains('.mp4') || _currentActiveImageUrl!.contains('.webm')
                                          ? const Center(
                                              child: Text(
                                                '🎬 Video',
                                                style: TextStyle(color: Colors.white70),
                                              ),
                                            )
                                          : Image.network(
                                              _currentActiveImageUrl!,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                        : null,
                                                    color: AdminTheme.primary,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) => Center(
                                                child: Text(
                                                  'Failed to load',
                                                  style: TextStyle(color: Colors.grey[400]),
                                                ),
                                              ),
                                            ),
                                    )
                                  : Center(
                                      child: Text(
                                        'No active splash screen',
                                        style: TextStyle(color: Colors.grey[400]),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: AdminTheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ALL SPLASH SCREENS',
                            style: TextStyle(
                              color: AdminTheme.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _allSplashScreens.isEmpty
                          ? const Center(
                              child: Text(
                                'No splash screens uploaded yet.\nTap + to add one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isActive ? Colors.green : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: imageUrl.contains('.mp4') || imageUrl.contains('.webm')
                                          ? const Icon(Icons.video_library, color: Colors.white70)
                                          : ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ),
                                    ),
                                    title: Text(
                                      imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl,
                                      style: const TextStyle(
                                        color: AdminTheme.textLight,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'ID: $id | ${isActive ? "ACTIVE" : "Inactive"}',
                                      style: TextStyle(
                                        color: isActive ? Colors.green : Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isActive)
                                          IconButton(
                                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                            onPressed: () => _activateSplashScreen(id, imageUrl),
                                            tooltip: 'Activate',
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteSplashScreen(id),
                                          tooltip: 'Delete',
                                        ),
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
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing...', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ============================================================================
// USERS SCREEN
// ============================================================================
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

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getUsers(_currentPage, 20);
      setState(() {
        _users = data['users'];
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  Future<void> _banUser(int userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: Text('Are you sure you want to ban $userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('BAN'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminApiService.banUser(userId);
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User banned successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ban user: $e')),
        );
      }
    }
  }

  Future<void> _unbanUser(int userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unban User'),
        content: Text('Are you sure you want to unban $userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('UNBAN'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminApiService.unbanUser(userId);
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unbanned successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unban user: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(int userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Permanently delete $userName? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminApiService.deleteUser(userId);
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        ),
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
                      Text(
                        'Total Users: $_totalElements',
                        style: const TextStyle(color: AdminTheme.textLight),
                      ),
                      Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(color: AdminTheme.textLight),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
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
                            child: Text(
                              user['name']?.substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            user['name'] ?? 'Unknown',
                            style: const TextStyle(color: AdminTheme.textLight),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['email'] ?? '',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                              Text(
                                'UserID: ${user['userid'] ?? 'N/A'} | Competition: ${user['hasCompletedEntry'] == true ? 'Yes' : 'No'}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 10),
                              ),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              if (isActive)
                                IconButton(
                                  icon: const Icon(Icons.block, color: Colors.orange),
                                  onPressed: () => _banUser(user['id'], user['name']),
                                  tooltip: 'Ban',
                                ),
                              if (!isActive)
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _unbanUser(user['id'], user['name']),
                                  tooltip: 'Unban',
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(user['id'], user['name']),
                                tooltip: 'Delete',
                              ),
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
                              _loadUsers();
                            });
                          },
                          child: const Text('PREVIOUS'),
                        ),
                      if (_currentPage < _totalPages - 1)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentPage++;
                              _loadUsers();
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

// ============================================================================
// SONGS SCREEN
// ============================================================================
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  List<dynamic> _songs = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _urlController = TextEditingController();
  final _videoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedAudioFile;
  XFile? _selectedVideoFile;
  bool _isUploadingFiles = false;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _urlController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getSongs(_currentPage, 20);
      setState(() {
        _songs = data['songs'];
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load songs: $e')),
      );
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      );
      if (result != null) {
        final file = XFile(result.files.first.path!);
        setState(() => _selectedAudioFile = file);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected audio: ${result.files.first.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick audio: $e')),
      );
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        setState(() => _selectedVideoFile = file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    }
  }

  Future<void> _addSong() async {
    if (_formKey.currentState!.validate()) {
      final songData = {
        'title': _titleController.text.trim(),
        'artist': _artistController.text.trim(),
        'url': _urlController.text.trim(),
        'video': _videoController.text.trim(),
      };
      try {
        final result = await AdminApiService.createSong(songData);
        final songId = result['id'];
        if (_selectedAudioFile != null || _selectedVideoFile != null) {
          setState(() => _isUploadingFiles = true);
          await AdminApiService.uploadSongFiles(
            songId,
            audioFile: _selectedAudioFile,
            videoFile: _selectedVideoFile,
          );
          setState(() => _isUploadingFiles = false);
        }
        _clearForm();
        _loadSongs();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song added successfully')),
        );
      } catch (e) {
        setState(() => _isUploadingFiles = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add song: $e')),
        );
      }
    }
  }

  Future<void> _editSong(Map<String, dynamic> song) async {
    _titleController.text = song['title'] ?? '';
    _artistController.text = song['artist'] ?? '';
    _urlController.text = song['url'] ?? '';
    _videoController.text = song['video'] ?? '';
    _selectedAudioFile = null;
    _selectedVideoFile = null;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Song'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildForm(),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Upload Files (Optional)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textLight,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickAudioFile,
                      icon: const Icon(Icons.audio_file),
                      label: Text(
                        _selectedAudioFile != null ? '✓ ${_selectedAudioFile!.name}' : 'Select Audio',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(140, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideoFile,
                      icon: const Icon(Icons.video_file),
                      label: Text(
                        _selectedVideoFile != null ? '✓ ${_selectedVideoFile!.name}' : 'Select Video',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(140, 40),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedAudioFile != null || _selectedVideoFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Files will be uploaded after saving',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: _isUploadingFiles
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final songData = {
                        'title': _titleController.text.trim(),
                        'artist': _artistController.text.trim(),
                        'url': _urlController.text.trim(),
                        'video': _videoController.text.trim(),
                      };
                      try {
                        await AdminApiService.updateSong(song['id'], songData);
                        if (_selectedAudioFile != null || _selectedVideoFile != null) {
                          setState(() => _isUploadingFiles = true);
                          await AdminApiService.uploadSongFiles(
                            song['id'],
                            audioFile: _selectedAudioFile,
                            videoFile: _selectedVideoFile,
                          );
                          setState(() => _isUploadingFiles = false);
                        }
                        _clearForm();
                        _loadSongs();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Song updated successfully')),
                        );
                      } catch (e) {
                        setState(() => _isUploadingFiles = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update song: $e')),
                        );
                      }
                    }
                  },
            child: _isUploadingFiles
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleHideSong(Map<String, dynamic> song) async {
    final isActive = song['active'] ?? true;
    try {
      if (isActive) {
        await AdminApiService.hideSong(song['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song hidden from users')),
        );
      } else {
        await AdminApiService.unhideSong(song['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song visible to users')),
        );
      }
      _loadSongs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _deleteSong(Map<String, dynamic> song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Delete "${song['title']}" by ${song['artist']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminApiService.deleteSong(song['id']);
        _loadSongs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete song: $e')),
        );
      }
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Song Title', hintText: 'Enter song title'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _artistController,
            decoration: const InputDecoration(labelText: 'Artist', hintText: 'Enter artist name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Audio URL (Fallback)',
              hintText: 'https://... (kept for backup)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _videoController,
            decoration: const InputDecoration(
              labelText: 'Video URL (Fallback)',
              hintText: 'https://... (kept for backup)',
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _titleController.clear();
    _artistController.clear();
    _urlController.clear();
    _videoController.clear();
    _selectedAudioFile = null;
    _selectedVideoFile = null;
  }

  void _showAddSongDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Song'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildForm(),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Upload Files (Optional)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textLight,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickAudioFile,
                      icon: const Icon(Icons.audio_file),
                      label: Text(
                        _selectedAudioFile != null ? '✓ ${_selectedAudioFile!.name}' : 'Select Audio',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(140, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideoFile,
                      icon: const Icon(Icons.video_file),
                      label: Text(
                        _selectedVideoFile != null ? '✓ ${_selectedVideoFile!.name}' : 'Select Video',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(140, 40),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedAudioFile != null || _selectedVideoFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Files will be uploaded after saving',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: _isUploadingFiles ? null : _addSong,
            child: _isUploadingFiles
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('ADD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSongDialog,
            tooltip: 'Add Song',
          ),
        ],
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
                      Text(
                        'Total Songs: $_totalElements',
                        style: const TextStyle(color: AdminTheme.textLight),
                      ),
                      Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(color: AdminTheme.textLight),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      final isActive = song['active'] ?? true;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: AdminTheme.surface,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive ? Colors.green : Colors.grey,
                            child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            song['title'] ?? 'Unknown',
                            style: const TextStyle(color: AdminTheme.textLight),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song['artist'] ?? 'Unknown',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              if (song['audioFileUrl'] != null)
                                Text(
                                  '🎵 Audio: Uploaded',
                                  style: TextStyle(color: Colors.green[400], fontSize: 11),
                                ),
                              if (song['videoFileUrl'] != null)
                                Text(
                                  '🎬 Video: Uploaded',
                                  style: TextStyle(color: Colors.blue[400], fontSize: 11),
                                ),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editSong(song),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.remove_red_eye,
                                      color: isActive ? Colors.green : Colors.red,
                                    ),
                                    if (!isActive)
                                      Positioned(
                                        child: Container(
                                          width: 24,
                                          height: 2,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                                onPressed: () => _toggleHideSong(song),
                                tooltip: isActive ? 'Hide' : 'Unhide',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteSong(song),
                                tooltip: 'Delete',
                              ),
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
                              _loadSongs();
                            });
                          },
                          child: const Text('PREVIOUS'),
                        ),
                      if (_currentPage < _totalPages - 1)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentPage++;
                              _loadSongs();
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

// ============================================================================
// WINNERS SCREEN
// ============================================================================
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
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    _userRole = await AdminLocalStorage.getRole();
    print('👤 WinnersScreen user role: $_userRole');
    setState(() {});
  }

  Future<void> _loadWinners() async {
    setState(() => _isLoading = true);
    try {
      final winners = await AdminApiService.getActiveWinners();
      setState(() {
        _winners = winners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load winners: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _announceWinner() async {
    if (_formKey.currentState!.validate()) {
      final winnerData = {
        'category': _selectedCategory,
        'winnerName': _winnerNameController.text.trim(),
        'winnerUserid': _winnerUseridController.text.trim(),
        'winnerAge': int.parse(_winnerAgeController.text.trim()),
        'province': _provinceController.text.trim(),
        'message': _messageController.text.trim(),
      };
      try {
        await AdminApiService.announceWinner(winnerData);
        _clearForm();
        _loadWinners();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Winner announced successfully'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to announce winner: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateWinner() async {
    if (_formKey.currentState!.validate() && _editingWinnerId != null) {
      final winnerData = {
        'category': _selectedCategory,
        'winnerName': _winnerNameController.text.trim(),
        'winnerUserid': _winnerUseridController.text.trim(),
        'winnerAge': int.parse(_winnerAgeController.text.trim()),
        'province': _provinceController.text.trim(),
        'message': _messageController.text.trim(),
      };
      try {
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/admin/winners/${_editingWinnerId}'),
          headers: await AdminApiService.getAuthHeader(),
          body: json.encode(winnerData),
        );
        if (response.statusCode == 200) {
          _clearForm();
          _loadWinners();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Winner updated successfully'), backgroundColor: Colors.green),
          );
        } else {
          throw Exception('Failed to update winner');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update winner: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteWinner(int winnerId, String winnerName) async {
    if (_userRole != 'SUPER_ADMIN' && _userRole != 'ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to delete winners'), backgroundColor: Colors.orange),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId'),
          headers: await AdminApiService.getAuthHeader(),
        );
        if (response.statusCode == 200) {
          _loadWinners();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Winner deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete winner: $e'), backgroundColor: Colors.red),
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
          TextButton(
            onPressed: () {
              _clearForm();
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
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
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'ADULTS', child: Text('Adults')),
              DropdownMenuItem(value: 'CHILDREN', child: Text('Children')),
              DropdownMenuItem(value: 'CELEBRITY', child: Text('Celebrity')),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value ?? 'ADULTS'),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _winnerNameController,
            decoration: const InputDecoration(labelText: 'Winner Name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _winnerUseridController,
            decoration: const InputDecoration(labelText: 'Winner User ID'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _winnerAgeController,
            decoration: const InputDecoration(labelText: 'Winner Age'),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _provinceController,
            decoration: const InputDecoration(labelText: 'Province'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: 'Message (Optional)'),
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
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAnnounceDialog,
            tooltip: 'Announce Winner',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWinners,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _winners.isEmpty
              ? const Center(
                  child: Text(
                    'No winners announced yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
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
                                  child: Text(
                                    winner['category'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('dd MMM yyyy').format(DateTime.parse(winner['announcedAt'])),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                                if (canModify)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => _editWinner(winner),
                                    tooltip: 'Edit Winner',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                if (canModify)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _deleteWinner(winner['id'], winner['winnerName']),
                                    tooltip: 'Delete Winner',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              winner['winnerName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.textLight,
                              ),
                            ),
                            Text(
                              'User ID: ${winner['winnerUserid'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            Text(
                              'Age: ${winner['winnerAge']} | Province: ${winner['province'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            if (winner['message'] != null && winner['message'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  winner['message'],
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
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

// ============================================================================
// COMPLAINTS SCREEN
// ============================================================================
class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<dynamic> _complaints = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = true;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getComplaints(
        _currentPage,
        20,
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );
      setState(() {
        _complaints = data['complaints'];
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load complaints: $e')),
      );
    }
  }

  Future<void> _replyToComplaint(Map<String, dynamic> complaint) async {
    final replyController = TextEditingController(text: complaint['adminReply'] ?? '');
    String status = complaint['status'] ?? 'OPEN';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Reply to Complaint'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'OPEN', child: Text('OPEN')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS')),
                    DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED')),
                  ],
                  onChanged: (value) => setDialogState(() => status = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: replyController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Reply',
                    hintText: 'Type your response here...',
                  ),
                  maxLines: 5,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('SEND REPLY'),
              ),
            ],
          );
        },
      ),
    );
    if (result == true) {
      try {
        await AdminApiService.replyToComplaint(
          complaint['id'],
          replyController.text.trim(),
          status,
        );
        _loadComplaints();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _statusFilter.isEmpty ? null : _statusFilter,
              hint: const Text('All', style: TextStyle(color: Colors.white70)),
              dropdownColor: AdminTheme.surface,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: '', child: Text('All', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'OPEN', child: Text('OPEN', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value ?? '';
                  _currentPage = 0;
                  _loadComplaints();
                });
              },
            ),
          ),
        ],
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
                      Text(
                        'Total Complaints: $_totalElements',
                        style: const TextStyle(color: AdminTheme.textLight),
                      ),
                      Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(color: AdminTheme.textLight),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaints[index];
                      final user = complaint['user'] ?? {};
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: AdminTheme.surface,
                        child: ExpansionTile(
                          title: Text(
                            complaint['subject'] ?? 'No Subject',
                            style: const TextStyle(color: AdminTheme.textLight),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(complaint['status'] ?? 'OPEN'),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  complaint['status'] ?? 'OPEN',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'From: ${user['name'] ?? 'Unknown'}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    complaint['message'] ?? '',
                                    style: const TextStyle(color: AdminTheme.textLight),
                                  ),
                                  const SizedBox(height: 12),
                                  if (complaint['adminReply'] != null && complaint['adminReply'].isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Admin Response:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AdminTheme.secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            complaint['adminReply'],
                                            style: const TextStyle(color: AdminTheme.textLight),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => _replyToComplaint(complaint),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AdminTheme.primary,
                                    ),
                                    child: const Text('REPLY'),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                              _loadComplaints();
                            });
                          },
                          child: const Text('PREVIOUS'),
                        ),
                      if (_currentPage < _totalPages - 1)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentPage++;
                              _loadComplaints();
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

// ============================================================================
// PAYMENTS SCREEN
// ============================================================================
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<dynamic> _payments = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getPayments(_currentPage, 20);
      setState(() {
        _payments = data['payments'];
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load payments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        ),
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
                      Text(
                        'Total Payments: $_totalElements',
                        style: const TextStyle(color: AdminTheme.textLight),
                      ),
                      Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(color: AdminTheme.textLight),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      final user = payment['user'] ?? {};
                      final song = payment['song'] ?? {};
                      final competitionEntry = payment['competitionEntry'] ?? {};
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: AdminTheme.surface,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              'R',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            'R ${payment['amount'] ?? '0.00'}',
                            style: const TextStyle(
                              color: AdminTheme.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User: ${user['name'] ?? 'Unknown'} (${user['userid'] ?? 'No ID'})',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                              Text(
                                'Province: ${competitionEntry['province'] ?? user['province'] ?? 'Not specified'}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                              ),
                              Text(
                                'Song: ${song['title'] ?? 'Unknown'}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Transaction ID', payment['transactionId'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Status', payment['status'] ?? 'UNKNOWN'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Payment Date', payment['paymentDate'] != null
                                      ? DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.parse(payment['paymentDate']))
                                      : 'Unknown'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Competition Entry Date', competitionEntry['entryDate'] != null
                                      ? DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.parse(competitionEntry['entryDate']))
                                      : 'Not entered'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Category', competitionEntry['category'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Artist Name', competitionEntry['artistName'] ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Contact', competitionEntry['contactInfo'] ?? user['contact'] ?? 'N/A'),
                                ],
                              ),
                            ),
                          ],
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
                              _loadPayments();
                            });
                          },
                          child: const Text('PREVIOUS'),
                        ),
                      if (_currentPage < _totalPages - 1)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentPage++;
                              _loadPayments();
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: TextStyle(
              color: AdminTheme.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AdminTheme.textLight, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// STAFF SCREEN
// ============================================================================
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
    print('Current admin role: $_currentAdminRole');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load staff: $e')),
      );
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
      final staffData = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'email': _emailController.text.trim(),
      };
      try {
        await AdminApiService.createStaff(staffData, _selectedRole, _passwordController.text.trim());
        _clearForm();
        _loadStaff();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff created successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create staff: $e')),
        );
      }
    }
  }

  Future<void> _deleteStaff(int staffId, String staffName, String staffRole) async {
    if (staffRole == 'SUPER_ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete Super Admin account')),
      );
      return;
    }
    if (_currentAdminRole == 'ADMIN' && (staffRole == 'ADMIN' || staffRole == 'SUPER_ADMIN')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin cannot delete other Admin accounts')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Delete $staffName? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminApiService.deleteStaff(staffId);
        _loadStaff();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete staff: $e')),
        );
      }
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'First Name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _surnameController,
            decoration: const InputDecoration(labelText: 'Last Name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email Address'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Temporary Password'),
            obscureText: true,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'Role'),
            items: _roles.isEmpty
                ? const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(value: 'MODERATOR', child: Text('MODERATOR')),
                    DropdownMenuItem(value: 'SUPPORT', child: Text('SUPPORT')),
                  ]
                : _roles
                    .where((role) {
                      if (_currentAdminRole == 'ADMIN') {
                        return role['name'] != 'ADMIN' && role['name'] != 'SUPER_ADMIN';
                      }
                      return role['name'] != 'SUPER_ADMIN';
                    })
                    .map<DropdownMenuItem<String>>((role) {
                      return DropdownMenuItem(
                        value: role['name'] ?? 'ADMIN',
                        child: Text(role['name'] ?? 'ADMIN'),
                      );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        ),
        actions: [
          if (_currentAdminRole == 'SUPER_ADMIN' || _currentAdminRole == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateStaffDialog,
              tooltip: 'Add Staff',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
              ? const Center(
                  child: Text(
                    'No staff members found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
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
                        leading: CircleAvatar(
                          backgroundColor: isSuperAdmin ? Colors.amber : AdminTheme.primary,
                          child: Text(
                            staff['name']?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          '${staff['name'] ?? ''} ${staff['surname'] ?? ''}',
                          style: const TextStyle(color: AdminTheme.textLight),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff['email'] ?? '',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            Text(
                              'Role: $roleName',
                              style: TextStyle(
                                color: isSuperAdmin ? Colors.amber : Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        trailing: canDelete
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteStaff(staff['id'], staff['name'], roleName),
                                tooltip: 'Delete Staff',
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}

// ============================================================================
// USER ACTIVITY LOGS SCREEN
// ============================================================================
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
      print('✅ Loaded ${_logs.length} user activity logs');
    } catch (e) {
      print('❌ Failed to load user activity logs: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user activity logs: $e')),
        );
      }
    }
  }

  List<dynamic> get _filteredLogs {
    if (_filterType == 'all') return _logs;
    return _logs.where((log) => log['action'] == _filterType).toList();
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'song_play':
        return Icons.play_circle;
      case 'profile_update':
        return Icons.edit;
      case 'complaint':
        return Icons.report_problem;
      case 'payment':
        return Icons.payment;
      case 'competition':
        return Icons.emoji_events;
      default:
        return Icons.history;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'login':
        return Colors.green;
      case 'song_play':
        return Colors.blue;
      case 'profile_update':
        return Colors.orange;
      case 'complaint':
        return Colors.red;
      case 'payment':
        return Colors.purple;
      case 'competition':
        return Colors.amber;
      default:
        return AdminTheme.primary;
    }
  }

  String _formatActionName(String action) {
    switch (action) {
      case 'login':
        return 'User Login';
      case 'song_play':
        return 'Song Played';
      case 'profile_update':
        return 'Profile Updated';
      case 'complaint':
        return 'Complaint Submitted';
      case 'payment':
        return 'Payment Made';
      case 'competition':
        return 'Competition Entry';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Activity Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
        ],
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
                      Text(
                        'Total Activities: $_totalElements',
                        style: const TextStyle(color: AdminTheme.textLight),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AdminTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminTheme.primary),
                        ),
                        child: DropdownButton<String>(
                          value: _filterType,
                          dropdownColor: AdminTheme.surface,
                          underline: const SizedBox(),
                          icon: Icon(Icons.filter_list, color: AdminTheme.primary),
                          items: _filterOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(
                                option == 'all' ? 'All Types' : _formatActionName(option),
                                style: const TextStyle(color: AdminTheme.textLight),
                              ),
                            );
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
                              Text(
                                _logs.isEmpty
                                    ? 'No user activity logs found'
                                    : 'No ${_formatActionName(_filterType)} activities found',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 8),
                              if (_logs.isEmpty)
                                const Text(
                                  'User actions will appear here when they use the app',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
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
                                leading: Icon(
                                  _getActionIcon(log['action'] ?? ''),
                                  color: _getActionColor(log['action'] ?? ''),
                                  size: 30,
                                ),
                                title: Text(
                                  _formatActionName(log['action'] ?? 'Unknown'),
                                  style: const TextStyle(
                                    color: AdminTheme.textLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'User: ${user['name'] ?? 'Unknown'} (${user['userid'] ?? user['email'] ?? 'No ID'})',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                    if (details.isNotEmpty)
                                      Text(
                                        'Details: ${details.toString()}',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                      ),
                                    Text(
                                      log['createdAt'] != null
                                          ? DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.parse(log['createdAt']))
                                          : 'Unknown',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                    ),
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
                      if (_currentPage > 0)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentPage--;
                              _loadLogs();
                            });
                          },
                          child: const Text('PREVIOUS'),
                        ),
                      if (_currentPage < _totalPages - 1)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentPage++;
                              _loadLogs();
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
