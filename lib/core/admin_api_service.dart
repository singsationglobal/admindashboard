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

  static Future<void> deleteSong(int songId) async {
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/admin/songs/$songId'), headers: await _authHeader());
    if (response.statusCode != 200) throw Exception('Failed to delete song');
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

  // =========================================================================
  // NEW: BULK HIDE/UNHIDE METHODS (Added for bulk selection feature)
  // =========================================================================
  static Future<void> hideSongsBulk(List<int> songIds) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/hide-bulk'),
      headers: await _authHeader(),
      body: json.encode(songIds),
    );
    if (response.statusCode != 200) throw Exception('Failed to hide songs in bulk');
  }

  static Future<void> unhideSongsBulk(List<int> songIds) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/songs/unhide-bulk'),
      headers: await _authHeader(),
      body: json.encode(songIds),
    );
    if (response.statusCode != 200) throw Exception('Failed to unhide songs in bulk');
  }
}
