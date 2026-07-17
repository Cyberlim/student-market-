import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// Returns the backend base URL based on the current platform.
///
/// - On **Release Mode (Production)**: points to Render backend URL
/// - On **Chrome/Web (Debug)**: uses `localhost`
/// - On **Android physical device (Debug)**: uses the local Wi-Fi IP of the dev machine
String get backendBaseUrl {
  if (kReleaseMode) {
    return 'https://cloudnotes-backend.onrender.com/api';
  }
  if (kIsWeb) {
    return 'http://localhost:5001/api';
  } else {
    // Wi-Fi IP of the developer's machine running the backend
    // Run `ipconfig` to get the current IP if connection fails
    return 'http://10.138.27.220:5001/api';
  }
}
