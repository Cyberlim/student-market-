import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../services/notification_service.dart';
import '../constants/api_config.dart';

class FileDownloadHelper {
  static final Dio _dio = Dio();
  static int _downloadIdCounter = 1000;

  static Future<String> getLocalFilePath(String noteId) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/note_$noteId.pdf';
  }

  static Future<bool> isDownloaded(String noteId) async {
    final path = await getLocalFilePath(noteId);
    return File(path).exists();
  }

  static Future<void> openLocalFile(String noteId, Function(String) onStatus) async {
    final path = await getLocalFilePath(noteId);
    final file = File(path);
    if (await file.exists()) {
      onStatus('Opening notes...');
      OpenFilex.open(path);
    } else {
      onStatus('File not found. Please download again.');
    }
  }

  static Future<void> downloadAndOpen(String fileUrl, String title, String noteId, Function(String) onStatus, {VoidCallback? onSuccess}) async {
    if (fileUrl.isEmpty) {
      onStatus('Download link not available.');
      return;
    }

    String finalUrl = fileUrl;
    if (fileUrl.startsWith('/')) {
      finalUrl = backendBaseUrl.replaceAll('/api', '') + fileUrl;
    }

    onStatus('Starting download...');

    try {
      final savePath = await getLocalFilePath(noteId);
      final downloadId = _downloadIdCounter++;
      
      NotificationService.instance.showProgressNotification(
        id: downloadId,
        title: 'Downloading $title',
        body: 'Download in progress...',
        progress: 0,
        maxProgress: 100,
      );

      await _dio.download(
        finalUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toInt();
            NotificationService.instance.showProgressNotification(
              id: downloadId,
              title: 'Downloading $title',
              body: '$progress% completed',
              progress: progress,
              maxProgress: 100,
            );
          }
        },
      );

      NotificationService.instance.showNotification(
        id: downloadId,
        title: 'Download Complete',
        body: title,
      );

      onStatus('Download Complete. Opening file...');
      if (onSuccess != null) {
        onSuccess();
      }
      OpenFilex.open(savePath);
    } catch (e) {
      debugPrint('Download error: $e');
      onStatus('Failed to download file.');
    }
  }
}
