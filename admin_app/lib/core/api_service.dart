import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;

class AdminApiService {
  static final Dio _dio = Dio();
  
  static const List<String> _hosts = [
    'http://192.168.1.40:5001',
    'http://localhost:5001',
    'http://10.0.2.2:5001',
    'http://10.66.158.220:5001',
    'http://10.138.27.220:5001',
    'https://student-market-1-kx64.onrender.com',
  ];

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  // Pick an image from the local device and upload it to the backend
  static Future<String?> uploadImage() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      List<int> bytes;
      if (kIsWeb) {
        if (file.bytes == null) return null;
        bytes = file.bytes!;
      } else {
        if (file.path == null) return null;
        bytes = await io.File(file.path!).readAsBytes();
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      });

      final response = await request('POST', '/api/admin/upload', data: formData);
      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        return response.data['url'] as String?;
      }
    } catch (e) {
      debugPrint('[AdminAPI] Image upload failed: $e');
    }
    return null;
  }

  // Generic request handler that automatically tries localhost, emulator, and hotspot fallbacks
  static Future<Response?> request(
    String method,
    String path, {
    dynamic data,
  }) async {
    final headers = await _getHeaders();
    final requestOptions = Options(
      method: method,
      headers: headers,
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
    );

    // If web, only use localhost/current origin
    final activeHosts = kIsWeb ? [_hosts.first] : _hosts;

    for (var host in activeHosts) {
      try {
        final dioInstance = Dio();
        dioInstance.options.connectTimeout = const Duration(seconds: 5);
        // Don't throw on non-2xx responses so we can handle them
        dioInstance.options.validateStatus = (status) => status != null && status < 500;
        final response = await dioInstance.request(
          '$host$path',
          data: data,
          options: requestOptions,
        );
        debugPrint('[AdminAPI] $method $host$path -> ${response.statusCode}');
        return response;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          debugPrint('[AdminAPI] Connection failed for $host$path, trying next host...');
          continue; // Try next host
        }
        // For non-connection errors (like 4xx/5xx with response), return the response
        if (e.response != null) {
          debugPrint('[AdminAPI] $method $host$path -> ${e.response?.statusCode}');
          return e.response;
        }
        debugPrint('[AdminAPI] DioException: ${e.message}');
        continue;
      } catch (e) {
        debugPrint('[AdminAPI] Unexpected error: $e');
        continue;
      }
    }
    debugPrint('[AdminAPI] All hosts failed for $method $path');
    return null;
  }
}

