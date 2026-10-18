import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'api_config.dart';
import 'admin_local_storage.dart';
import '../screens/admin/login_screen.dart';

class AdminApiService {
  static Future<Map<String, String>> _authHeader() async {
    final token = await AdminLocalStorage.getToken();
    if (token.isNotEmpty) {
      return {...ApiConfig.headers, 'Authorization': 'Bearer $token'};
    }
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
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/auth/login'),
      headers: ApiConfig.headers,
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await AdminLocalStorage.saveToken(data['token']);
      await AdminLocalStorage.saveAdmin(data['admin']);
      await AdminLocalStorage.saveRole(data['admin']['role']?['name'] ?? 'SUPPORT');
      return data;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> getUsers(int page, int size) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/users?page=$page&size=$size'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load users: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> searchUsers(String query, int page, int size) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/search?query=${Uri.encodeComponent(query)}&page=$page&size=$size'),
      headers: await _authHeader(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to search users: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> sendMessageToUser(int userId, String messageType, String messageContent) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/message'),
      headers: await _authHeader(),
      body: json.encode({'messageType': messageType, 'messageContent': messageContent}),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to send message: ${response.statusCode}');
  }

  static Future<void> banUser(int userId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/ban'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to ban user');
  }

  static Future<void> unbanUser(int userId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/unban'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to unban user');
  }

  // ✅ UPDATED: Soft Delete, Restore, and Permanent Delete for Users
  static Future<void> softDeleteUser(int userId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/bin'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to move user to bin');
  }

  static Future<void> restoreUser(int userId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/restore'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to restore user');
  }

  static Future<void> permanentDeleteUser(int userId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/permanent'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to permanently delete user');
  }

  static Future<Map<String, dynamic>> getSongs(int page, int size) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/songs?page=$page&size=$size'), headers: await _authHeader());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load songs: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createSong(Map<String, dynamic> songData) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/songs'), headers: await _authHeader(), body: json.encode(songData));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to create song');
  }

  static Future<Map<String, dynamic>> updateSong(int songId, Map<String, dynamic> songData) async {
    final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId'), headers: await _authHeader(), body: json.encode(songData));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to update song');
  }

  static Future<void> hideSong(int songId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/hide'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to hide song');
  }

  static Future<void> unhideSong(int songId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/unhide'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to unhide song');
  }

  // ✅ UPDATED: Soft Delete, Restore, and Permanent Delete for Songs
  static Future<void> softDeleteSong(int songId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/bin'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to move song to bin');
  }

  static Future<void> restoreSong(int songId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/restore'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to restore song');
  }

  static Future<void> permanentDeleteSong(int songId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/permanent'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to permanently delete song');
  }

  static Future<Map<String, dynamic>> uploadSongFiles(int songId, {XFile? audioFile, XFile? videoFile}) async {
    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/upload-files'));
    request.headers.addAll(await _authHeader());
    if (audioFile != null) {
      if (kIsWeb) {
        final bytes = await audioFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('audioFile', bytes, filename: audioFile.name, contentType: MediaType('audio', 'mpeg')));
      } else {
        request.files.add(await http.MultipartFile.fromPath('audioFile', audioFile.path, contentType: MediaType('audio', 'mpeg')));
      }
    }
    if (videoFile != null) {
      if (kIsWeb) {
        final bytes = await videoFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('videoFile', bytes, filename: videoFile.name, contentType: MediaType('video', 'mp4')));
      } else {
        request.files.add(await http.MultipartFile.fromPath('videoFile', videoFile.path, contentType: MediaType('video', 'mp4')));
      }
    }
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) return json.decode(responseBody);
    throw Exception('Failed to upload song files');
  }

  static Future<Map<String, dynamic>> announceWinner(Map<String, dynamic> winnerData) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/winners/announce'), headers: await _authHeader(), body: json.encode(winnerData));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to announce winner');
  }

  static Future<List<dynamic>> getActiveWinners() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/winners/active'), headers: await _authHeader());
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  static Future<void> softDeleteWinner(int winnerId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId/bin'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to move winner to bin');
  }

  static Future<void> restoreWinner(int winnerId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId/restore'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to restore winner');
  }

  static Future<void> permanentDeleteWinner(int winnerId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId/permanent'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to permanently delete winner');
  }

  static Future<Map<String, dynamic>> getComplaints(int page, int size, {String? status}) async {
    String url = '${ApiConfig.baseUrl}/admin/complaints?page=$page&size=$size';
    if (status != null && status.isNotEmpty) url += '&status=$status';
    final response = await http.get(Uri.parse(url), headers: await _authHeader());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load complaints');
  }

  static Future<Map<String, dynamic>> getDeletedComplaints(int page, int size) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/complaints/bin?page=$page&size=$size'), headers: await _authHeader());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load deleted complaints');
  }

  static Future<Map<String, dynamic>> replyToComplaint(int complaintId, String adminReply, String status) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId/reply'), headers: await _authHeader(), body: json.encode({'adminReply': adminReply, 'status': status}));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to reply to complaint');
  }

  static Future<void> softDeleteComplaint(int complaintId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId/bin'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to move to bin');
  }

  static Future<void> restoreComplaint(int complaintId) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId/restore'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to restore complaint');
  }

  static Future<void> permanentDeleteComplaint(int complaintId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId/permanent'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to permanently delete');
  }

  static Future<Map<String, dynamic>> getPayments(int page, int size) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/payments?page=$page&size=$size'), headers: await _authHeader());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load payments');
  }

  static Future<List<dynamic>> getStaff() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/staff'), headers: await _authHeader());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load staff');
  }

  static Future<Map<String, dynamic>> createStaff(Map<String, dynamic> staffData, String roleName, String rawPassword) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/staff?roleName=$roleName&rawPassword=$rawPassword'), headers: await _authHeader(), body: json.encode(staffData));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to create staff');
  }

  static Future<void> deleteStaff(int staffId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/admin/staff/$staffId'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to delete staff');
  }

  static Future<List<dynamic>> getRoles() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/staff/roles'), headers: await _authHeader());
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> getUserActivityLogs(int page, int size) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/logs/user-activity?page=$page&size=$size'), headers: await _authHeader());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load user activity logs');
  }

  static Future<List<dynamic>> getAllSplashScreens() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/all'), headers: await _authHeader());
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  // ✅ UPDATED: Soft Delete, Restore, and Permanent Delete for Splash Screens
  static Future<void> softDeleteSplashScreen(int id) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id/bin'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to move splash screen to bin');
  }

  static Future<void> restoreSplashScreen(int id) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id/restore'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to restore splash screen');
  }

  static Future<void> permanentDeleteSplashScreen(int id) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id/permanent'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to permanently delete splash screen');
  }

  static Future<Map<String, dynamic>> uploadSplashScreen(FilePickerResult? result, {String? imageUrl}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/url'), headers: await _authHeader(), body: json.encode({'imageUrl': imageUrl}));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to save splash screen URL');
    }
    if (result == null || result.files.isEmpty) throw Exception('No file selected');
    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/upload'));
    request.headers.addAll(await _authHeader());
    final file = result.files.first;
    final bytes = file.bytes;
    final filename = file.name;
    if (bytes != null) {
      String mimeType = 'image/jpeg';
      if (filename.endsWith('.png')) mimeType = 'image/png';
      if (filename.endsWith('.gif')) mimeType = 'image/gif';
      if (filename.endsWith('.mp4')) mimeType = 'video/mp4';
      if (filename.endsWith('.webm')) mimeType = 'video/webm';
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename, contentType: MediaType.parse(mimeType)));
    } else if (file.path != null && !kIsWeb) {
      request.files.add(await http.MultipartFile.fromPath('image', file.path!));
    }
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) return json.decode(responseBody);
    throw Exception('Failed to upload splash screen');
  }

  static Future<Map<String, dynamic>> getSplashScreen() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen'), headers: await _authHeader());
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {'imageUrl': data['imageUrl'] ?? 'https://objectstorage.af-johannesburg-1.oraclecloud.com/n/axcbefxpjvzm/b/karaokeimages/o/Splashscreensplash.jpg'};
    }
    return {'imageUrl': 'https://objectstorage.af-johannesburg-1.oraclecloud.com/n/axcbefxpjvzm/b/karaokeimages/o/Splashscreensplash.jpg'};
  }

  static Future<Map<String, dynamic>> getDashboardStats({BuildContext? context}) async {
    try {
      final headers = await _authHeader();
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/dashboard/stats'), headers: headers);
      if (response.statusCode == 401) {
        await handleUnauthorized(context);
        throw Exception('Session expired. Please log in again.');
      }
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      print('Dashboard stats error: $e');
    }
    try {
      final users = await getUsers(0, 1);
      final songs = await getSongs(0, 1);
      final payments = await getPayments(0, 1);
      final complaints = await getComplaints(0, 1);
      return {
        'totalUsers': users['totalElements'] ?? 0,
        'totalSongs': songs['totalElements'] ?? 0,
        'totalPayments': payments['totalElements'] ?? 0,
        'totalComplaints': complaints['totalElements'] ?? 0,
      };
    } catch (e) {
      return {'totalUsers': 0, 'totalSongs': 0, 'totalPayments': 0, 'totalComplaints': 0};
    }
  }

  static Future<void> hideSongsBulk(List<int> songIds) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/songs/hide-bulk'), headers: await _authHeader(), body: json.encode(songIds));
    if (response.statusCode != 200) throw Exception('Failed to hide songs in bulk');
  }

  static Future<void> unhideSongsBulk(List<int> songIds) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/songs/unhide-bulk'), headers: await _authHeader(), body: json.encode(songIds));
    if (response.statusCode != 200) throw Exception('Failed to unhide songs in bulk');
  }

  static Future<Map<String, dynamic>> getUserCoinStats(int userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/voting/user-coins/$userId'), headers: await getAuthHeader());
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load coin stats');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
