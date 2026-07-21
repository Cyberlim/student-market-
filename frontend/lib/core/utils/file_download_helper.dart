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

  static Future<void> downloadAndOpen(String fileUrl, String title, Function(String) onStatus) async {
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
      // Use application documents directory so no storage permissions are required
      final Directory dir = await getApplicationDocumentsDirectory();
      
      // Try to extract a reasonable filename from URL, fallback to safe name
      String fileName = finalUrl.split('/').last;
      if (!fileName.contains('.')) {
        fileName = 'Note_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }
      // sanitize filename
      fileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      
      final String savePath = '${dir.path}/$fileName';
      final int notificationId = _downloadIdCounter++;
      
      int lastProgress = -1;

      await _dio.download(
        finalUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            int progress = ((received / total) * 100).toInt();
            
            // Only update notification if progress advanced by at least 1% 
            // to avoid spamming the notification channel
            if (progress != lastProgress) {
              lastProgress = progress;
              NotificationService.instance.showProgressNotification(
                id: notificationId,
                title: 'Downloading $title',
                body: '$progress% completed',
                progress: progress,
                maxProgress: 100,
              );
            }
          }
        },
      );

      // Download complete
      NotificationService.instance.showNotification(
        id: notificationId,
        title: 'Download Complete',
        body: 'Tap to open $title',
      );
      
      onStatus('Download complete! Opening file...');

      // Open the file
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        onStatus('Could not open file: ${result.message}');
      }
    } catch (e) {
      debugPrint('Download error: $e');
      onStatus('Download failed: $e');
    }
  }
}
