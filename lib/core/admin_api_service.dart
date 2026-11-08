import 'dart:async';
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
import 'error_helper.dart';
import '../screens/admin/login_screen.dart';

class AdminApiService {
  // ---------------------------------------------------------------------------
  // AUTH HEADER
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // LOW-LEVEL HELPERS  (centralise timeout + error normalisation)
  // ---------------------------------------------------------------------------

  static Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
    String context = 'loading data',
  }) async {
    try {
      return await http
          .get(uri, headers: headers ?? await _authHeader())
          .timeout(ApiConfig.standardTimeout);
    } on TimeoutException {
      throw Exception(
          ErrorHelper.friendly(TimeoutException('timeout'), context: context));
    } catch (e) {
      throw Exception(ErrorHelper.friendly(e, context: context));
    }
  }

  static Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    String context = 'completing that request',
  }) async {
    try {
      return await http
          .post(
            uri,
            headers: headers ?? await _authHeader(),
            body: body == null ? null : json.encode(body),
          )
          .timeout(ApiConfig.standardTimeout);
    } on TimeoutException {
      throw Exception(
          ErrorHelper.friendly(TimeoutException('timeout'), context: context));
    } catch (e) {
      throw Exception(ErrorHelper.friendly(e, context: context));
    }
  }

  static Future<http.Response> _put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    String context = 'saving changes',
  }) async {
    try {
      return await http
          .put(
            uri,
            headers: headers ?? await _authHeader(),
            body: body == null ? null : json.encode(body),
          )
          .timeout(ApiConfig.standardTimeout);
    } on TimeoutException {
      throw Exception(
          ErrorHelper.friendly(TimeoutException('timeout'), context: context));
    } catch (e) {
      throw Exception(ErrorHelper.friendly(e, context: context));
    }
  }

  static Future<http.Response> _delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    String context = 'deleting',
  }) async {
    try {
      return await http
          .delete(
            uri,
            headers: headers ?? await _authHeader(),
            body: body == null ? null : json.encode(body),
          )
          .timeout(ApiConfig.standardTimeout);
    } on TimeoutException {
      throw Exception(
          ErrorHelper.friendly(TimeoutException('timeout'), context: context));
    } catch (e) {
      throw Exception(ErrorHelper.friendly(e, context: context));
    }
  }

  static Future<http.Response> _sendMultipart(
    http.MultipartRequest request, {
    String context = 'uploading file',
  }) async {
    try {
      final streamed = await request.send().timeout(ApiConfig.uploadTimeout);
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw Exception(
          ErrorHelper.friendly(TimeoutException('timeout'), context: context));
    } catch (e) {
      throw Exception(ErrorHelper.friendly(e, context: context));
    }
  }

  static Map<String, dynamic> _decodeMap(
    http.Response response, {
    required String context,
  }) {
    if (response.body.isEmpty) {
      throw Exception('Server returned an empty response while $context.');
    }
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw Exception('Unexpected response format while $context.');
    } catch (_) {
      throw Exception('Server returned an invalid response while $context.');
    }
  }

  static String _serverError(http.Response response, String fallback) {
    try {
      final data = json.decode(response.body);
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
    } catch (_) {}
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/auth/login'),
      headers: ApiConfig.headers,
      body: {'email': email, 'password': password},
      context: 'logging in',
    );
    if (response.statusCode == 200) {
      final data = _decodeMap(response, context: 'logging in');
      await AdminLocalStorage.saveToken(data['token']);
      await AdminLocalStorage.saveAdmin(data['admin']);
      await AdminLocalStorage.saveRole(data['admin']['role']?['name'] ?? 'SUPPORT');
      return data;
    }
    throw Exception(_serverError(response, 'Login failed'));
  }

  // ---------------------------------------------------------------------------
  // USERS
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getUsers(int page, int size) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/users?page=$page&size=$size'),
      context: 'loading users',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'loading users');
    }
    throw Exception(_serverError(
        response, 'Failed to load users (${response.statusCode})'));
  }

  static Future<Map<String, dynamic>> searchUsers(
      String query, int page, int size) async {
    final response = await _get(
      Uri.parse(
          '${ApiConfig.baseUrl}/admin/users/search?query=${Uri.encodeComponent(query)}&page=$page&size=$size'),
      context: 'searching users',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'searching users');
    }
    throw Exception(_serverError(
        response, 'Failed to search users (${response.statusCode})'));
  }

  static Future<Map<String, dynamic>> sendMessageToUser(
      int userId, String messageType, String messageContent) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/message'),
      body: {'messageType': messageType, 'messageContent': messageContent},
      context: 'sending the message',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'sending the message');
    }
    throw Exception(_serverError(
        response, 'Failed to send message (${response.statusCode})'));
  }

  static Future<void> banUser(int userId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/ban'),
      context: 'banning the user',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to ban user'));
    }
  }

  static Future<void> unbanUser(int userId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/unban'),
      context: 'unbanning the user',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to unban user'));
    }
  }

  static Future<void> softDeleteUser(int userId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/bin'),
      context: 'moving the user to bin',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to move user to bin'));
    }
  }

  static Future<void> restoreUser(int userId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/restore'),
      context: 'restoring the user',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to restore user'));
    }
  }

  static Future<void> permanentDeleteUser(int userId) async {
    final response = await _delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/permanent'),
      context: 'permanently deleting the user',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to permanently delete user'));
    }
  }

  // ---------------------------------------------------------------------------
  // SONGS
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getSongs(int page, int size) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs?page=$page&size=$size'),
      context: 'loading songs',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'loading songs');
    }
    throw Exception(_serverError(
        response, 'Failed to load songs (${response.statusCode})'));
  }

  static Future<Map<String, dynamic>> createSong(
      Map<String, dynamic> songData) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs'),
      body: songData,
      context: 'creating the song',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'creating the song');
    }
    throw Exception(_serverError(response, 'Failed to create song'));
  }

  static Future<Map<String, dynamic>> updateSong(
      int songId, Map<String, dynamic> songData) async {
    final response = await _put(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId'),
      body: songData,
      context: 'updating the song',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'updating the song');
    }
    throw Exception(_serverError(response, 'Failed to update song'));
  }

  static Future<void> hideSong(int songId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/hide'),
      context: 'hiding the song',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to hide song'));
    }
  }

  static Future<void> unhideSong(int songId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/unhide'),
      context: 'unhiding the song',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to unhide song'));
    }
  }

  static Future<void> softDeleteSong(int songId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/bin'),
      context: 'moving the song to bin',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to move song to bin'));
    }
  }

  static Future<void> restoreSong(int songId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/restore'),
      context: 'restoring the song',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to restore song'));
    }
  }

  static Future<void> permanentDeleteSong(int songId) async {
    final response = await _delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/permanent'),
      context: 'permanently deleting the song',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to permanently delete song'));
    }
  }

  static Future<Map<String, dynamic>> uploadSongFiles(
      int songId, {
      XFile? audioFile,
      XFile? videoFile,
      XFile? coverFile,
      String cloudProvider = 'oracle',
    }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId/upload-files'),
    );
    request.headers.addAll(await _authHeader());
    request.fields['cloudProvider'] = cloudProvider;

    if (audioFile != null) {
      if (kIsWeb) {
        final bytes = await audioFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('audioFile', bytes,
            filename: audioFile.name, contentType: MediaType('audio', 'mpeg')));
      } else {
        request.files.add(await http.MultipartFile.fromPath('audioFile',
            audioFile.path,
            contentType: MediaType('audio', 'mpeg')));
      }
    }
    if (videoFile != null) {
      if (kIsWeb) {
        final bytes = await videoFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('videoFile', bytes,
            filename: videoFile.name, contentType: MediaType('video', 'mp4')));
      } else {
        request.files.add(await http.MultipartFile.fromPath('videoFile',
            videoFile.path,
            contentType: MediaType('video', 'mp4')));
      }
    }
    if (coverFile != null) {
      if (kIsWeb) {
        final bytes = await coverFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('coverImage', bytes,
            filename: coverFile.name, contentType: MediaType('image', 'jpeg')));
      } else {
        request.files.add(await http.MultipartFile.fromPath('coverImage',
            coverFile.path,
            contentType: MediaType('image', 'jpeg')));
      }
    }

    final response = await _sendMultipart(request,
        context: 'uploading the song files');
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'uploading the song files');
    }
    throw Exception(_serverError(response, 'Failed to upload song files'));
  }

  // ---------------------------------------------------------------------------
  // WINNERS
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> announceWinner(
      Map<String, dynamic> winnerData) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/winners/announce'),
      body: winnerData,
      context: 'announcing the winner',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'announcing the winner');
    }
    throw Exception(_serverError(response, 'Failed to announce winner'));
  }

  static Future<List<dynamic>> getActiveWinners() async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/winners/active'),
      context: 'loading winners',
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
    }
    return [];
  }

  static Future<void> softDeleteWinner(int winnerId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId/bin'),
      context: 'moving the winner to bin',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to move winner to bin'));
    }
  }

  static Future<void> restoreWinner(int winnerId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId/restore'),
      context: 'restoring the winner',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to restore winner'));
    }
  }

  static Future<void> permanentDeleteWinner(int winnerId) async {
    final response = await _delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/winners/$winnerId/permanent'),
      context: 'permanently deleting the winner',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to permanently delete winner'));
    }
  }

  // ---------------------------------------------------------------------------
  // COMPLAINTS
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getComplaints(int page, int size,
      {String? status}) async {
    String url = '${ApiConfig.baseUrl}/admin/complaints?page=$page&size=$size';
    if (status != null && status.isNotEmpty) url += '&status=$status';
    final response = await _get(
      Uri.parse(url),
      context: 'loading complaints',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'loading complaints');
    }
    throw Exception(_serverError(response, 'Failed to load complaints'));
  }

  static Future<Map<String, dynamic>> getDeletedComplaints(
      int page, int size) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/complaints/bin?page=$page&size=$size'),
      context: 'loading deleted complaints',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'loading deleted complaints');
    }
    throw Exception(
        _serverError(response, 'Failed to load deleted complaints'));
  }

  static Future<Map<String, dynamic>> replyToComplaint(
      int complaintId, String adminReply, String status) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId/reply'),
      body: {'adminReply': adminReply, 'status': status},
      context: 'sending the reply',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'sending the reply');
    }
    throw Exception(_serverError(response, 'Failed to reply to complaint'));
  }

  static Future<void> softDeleteComplaint(int complaintId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId/bin'),
      context: 'moving the complaint to bin',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to move to bin'));
    }
  }

  static Future<void> restoreComplaint(int complaintId) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId/restore'),
      context: 'restoring the complaint',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to restore complaint'));
    }
  }

  static Future<void> permanentDeleteComplaint(int complaintId) async {
    final response = await _delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/complaints/$complaintId/permanent'),
      context: 'permanently deleting the complaint',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to permanently delete'));
    }
  }

  // ---------------------------------------------------------------------------
  // PAYMENTS
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getPayments(int page, int size) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/payments?page=$page&size=$size'),
      context: 'loading payments',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'loading payments');
    }
    throw Exception(_serverError(response, 'Failed to load payments'));
  }

  // ---------------------------------------------------------------------------
  // STAFF
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getStaff() async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/staff'),
      context: 'loading staff',
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
    }
    throw Exception(_serverError(response, 'Failed to load staff'));
  }

  static Future<Map<String, dynamic>> createStaff(Map<String, dynamic> staffData,
      String roleName, String rawPassword) async {
    final response = await _post(
      Uri.parse(
          '${ApiConfig.baseUrl}/admin/staff?roleName=$roleName&rawPassword=$rawPassword'),
      body: staffData,
      context: 'creating the staff account',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'creating the staff account');
    }
    throw Exception(_serverError(response, 'Failed to create staff'));
  }

  static Future<void> deleteStaff(int staffId) async {
    final headers = await _authHeader();
    final adminData = await AdminLocalStorage.getAdmin();
    headers['X-Admin-Id'] = adminData['id'].toString();

    final response = await _delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/staff/$staffId'),
      headers: headers,
      context: 'deleting the staff account',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to delete staff'));
    }
  }

  static Future<List<dynamic>> getRoles() async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/staff/roles'),
      context: 'loading roles',
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // ACTIVITY LOGS
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getUserActivityLogs(
      int page, int size) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/logs/user-activity?page=$page&size=$size'),
      context: 'loading activity logs',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'loading activity logs');
    }
    throw Exception(_serverError(response, 'Failed to load user activity logs'));
  }

  // ---------------------------------------------------------------------------
  // SPLASH SCREEN
  // ---------------------------------------------------------------------------

  static Future<List<dynamic>> getAllSplashScreens() async {
    try {
      final response = await _get(
        Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/all'),
        context: 'loading splash screens',
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
      }
      return [];
    } catch (e) {
      print('getAllSplashScreens: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getDeletedSplashScreens() async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/deleted'),
      context: 'loading deleted splash screens',
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) return decoded;
    }
    throw Exception(_serverError(response, 'Failed to load deleted splash screens'));
  }

  static Future<void> softDeleteSplashScreen(int id) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id/bin'),
      context: 'moving the splash screen to bin',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to move splash screen to bin'));
    }
  }

  static Future<void> restoreSplashScreen(int id) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id/restore'),
      context: 'restoring the splash screen',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to restore splash screen'));
    }
  }

  static Future<void> permanentDeleteSplashScreen(int id) async {
    final response = await _delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/$id/permanent'),
      context: 'permanently deleting the splash screen',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to permanently delete splash screen'));
    }
  }

  static Future<Map<String, dynamic>> uploadSplashScreen(
      FilePickerResult? result,
      {String? imageUrl,
      String cloudProvider = 'oracle'}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final response = await _post(
        Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/url'),
        body: {'imageUrl': imageUrl},
        context: 'saving the splash screen URL',
      );
      if (response.statusCode == 200) {
        return _decodeMap(response, context: 'saving the splash screen URL');
      }
      throw Exception(_serverError(response, 'Failed to save splash screen URL'));
    }
    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen/upload'),
    );
    request.headers.addAll(await _authHeader());
    request.fields['cloudProvider'] = cloudProvider;

    final file = result.files.first;
    final bytes = file.bytes;
    final filename = file.name;

    if (bytes != null) {
      String mimeType = 'image/jpeg';
      if (filename.endsWith('.png')) mimeType = 'image/png';
      if (filename.endsWith('.gif')) mimeType = 'image/gif';
      if (filename.endsWith('.mp4')) mimeType = 'video/mp4';
      if (filename.endsWith('.webm')) mimeType = 'video/webm';
      request.files.add(http.MultipartFile.fromBytes('image', bytes,
          filename: filename, contentType: MediaType.parse(mimeType)));
    } else if (file.path != null && !kIsWeb) {
      request.files.add(await http.MultipartFile.fromPath('image', file.path!));
    }

    final response = await _sendMultipart(request,
        context: 'uploading the splash screen');
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'uploading the splash screen');
    }
    throw Exception(_serverError(response, 'Failed to upload splash screen'));
  }

  static Future<Map<String, dynamic>> getSplashScreen() async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/splash-screen'),
      context: 'loading the splash screen',
    );
    if (response.statusCode == 200) {
      final data = _decodeMap(response, context: 'loading the splash screen');
      return {
        'imageUrl': data['imageUrl'] ??
            'https://objectstorage.af-johannesburg-1.oraclecloud.com/n/axcbefxpjvzm/b/karaokeimages/o/Splashscreensplash.jpg'
      };
    }
    return {
      'imageUrl':
          'https://objectstorage.af-johannesburg-1.oraclecloud.com/n/axcbefxpjvzm/b/karaokeimages/o/Splashscreensplash.jpg'
    };
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getDashboardStats(
      {BuildContext? context}) async {
    try {
      final headers = await _authHeader();
      final response = await _get(
        Uri.parse('${ApiConfig.baseUrl}/admin/dashboard/stats'),
        headers: headers,
        context: 'loading dashboard stats',
      );
      if (response.statusCode == 401) {
        await handleUnauthorized(context);
        throw Exception('Session expired. Please log in again.');
      }
      if (response.statusCode == 200) {
        return _decodeMap(response, context: 'loading dashboard stats');
      }
    } catch (e) {
      print('getDashboardStats primary: $e');
    }

    // Fallback: derive counts from the individual lists
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
      print('getDashboardStats fallback: $e');
      return {
        'totalUsers': 0,
        'totalSongs': 0,
        'totalPayments': 0,
        'totalComplaints': 0,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // BULK SONG OPERATIONS
  // ---------------------------------------------------------------------------

  static Future<void> hideSongsBulk(List<int> songIds) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/hide-bulk'),
      body: songIds,
      context: 'hiding the selected songs',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to hide songs in bulk'));
    }
  }

  static Future<void> unhideSongsBulk(List<int> songIds) async {
    final response = await _post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/unhide-bulk'),
      body: songIds,
      context: 'unhiding the selected songs',
    );
    if (response.statusCode != 200) {
      throw Exception(_serverError(response, 'Failed to unhide songs in bulk'));
    }
  }

  // ---------------------------------------------------------------------------
  // VOTING / COINS  (admin reads user coin stats)
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getUserCoinStats(int userId) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/admin/voting/user-coins/$userId'),
      context: 'loading coin stats',
    );
    if (response.statusCode == 200) {
      return _decodeMap(response, context: 'loading coin stats');
    }
    throw Exception(_serverError(response, 'Failed to load coin stats'));
  }
}
