import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// Returns the backend base URL based on the current platform.
String get backendBaseUrl {
  // To use your local backend in debug mode, uncomment the block below:
  /*
  if (!kReleaseMode) {
    if (kIsWeb) {
      return 'http://localhost:5001/api';
    } else {
      return 'http://10.138.27.220:5001/api';
    }
  }
  */

  // Default to live Render backend for testing and production
  return 'https://student-market-vzfm.onrender.com/api';
}
