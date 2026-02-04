import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ServerHealthService {
  static const Duration _kDefaultTimeout = Duration(milliseconds: 500);

  static Future<bool> isReachable(String url) async {
    if (url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;

    try {
      final client = http.Client();
      final response = await client
          .head(uri, headers: {'Connection': 'close'})
          .timeout(_kDefaultTimeout);
      client.close();
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } on Exception {
      return false;
    }
  }

  static Future<bool> waitForReachable(
    String url, {
    Duration interval = const Duration(milliseconds: 200),
    int maxAttempts = 100,
  }) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      if (await isReachable(url)) {
        return true;
      }
      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(interval);
      }
    }
    return false;
  }
}
