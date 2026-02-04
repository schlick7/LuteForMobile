import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ServerHealthService {
  static const Duration _kDefaultTimeout = Duration(milliseconds: 500);

  static Future<bool> isReachable(String url) async {
    if (url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;

    try {
      final client = Dio(
        BaseOptions(
          connectTimeout: _kDefaultTimeout,
          receiveTimeout: _kDefaultTimeout,
          sendTimeout: _kDefaultTimeout,
        ),
      );

      final response = await client.headUri(uri);
      client.close();
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } on DioException {
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
