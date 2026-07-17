import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class OnboardingCache {
  static final OnboardingCache instance = OnboardingCache._internal();
  OnboardingCache._internal();

  final List<VideoPlayerController?> controllers = [null, null, null];
  
  final List<String> videoUrls = [
    'https://res.cloudinary.com/dbtxwousd/video/upload/v1782985156/onpdsw3iwffo8pbqmxq9.gif',
    'https://res.cloudinary.com/dbtxwousd/image/upload/v1782979755/szbmysjmyukr9dqssegt.gif',
    'https://res.cloudinary.com/dbtxwousd/video/upload/v1782991108/yrrgp7zpvfxhrx0yfqfx.gif',
  ];

  bool _isPreloaded = false;

  // Returns a Future that resolves only when all videos are fully initialized and ready to play
  Future<void> preload() async {
    if (_isPreloaded) return;
    _isPreloaded = true;
    
    final List<Future<void>> initializations = [];

    for (int i = 0; i < videoUrls.length; i++) {
      final url = videoUrls[i];
      if (!url.endsWith('.gif')) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        controllers[i] = controller;
        
        final initFuture = controller.initialize().then((_) {
          controller.setLooping(true);
          controller.setVolume(0.0);
        }).catchError((e) {
          debugPrint('Preloading video at index $i failed: $e');
        });
        
        initializations.add(initFuture);
      }
    }

    if (initializations.isNotEmpty) {
      // Wait for all video assets to resolve, with an 8-second safety timeout
      await Future.wait(initializations).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('Preloading onboarding videos timed out; continuing with fallback.');
          return [];
        },
      );
    }
  }

  void dispose() {
    for (int i = 0; i < controllers.length; i++) {
      controllers[i]?.dispose();
      controllers[i] = null;
    }
    _isPreloaded = false;
  }
}
