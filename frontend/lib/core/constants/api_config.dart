import 'package:flutter/foundation.dart' show kIsWeb;

/// Returns the backend base URL based on the current platform.
///
/// - On **Chrome/Web**: uses `localhost` (same machine as the backend server)
/// - On **Android physical device**: uses the local Wi-Fi IP of the dev machine
String get backendBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:5001/api';
  } else {
    // Wi-Fi IP of the developer's machine running the backend
    // Run `ipconfig` to get the current IP if connection fails
    return 'http://10.138.27.220:5001/api';
  }
}
