import 'dart:async';
import 'package:dio/dio.dart';

class ServerHealthService {
  static const Duration _kDefaultTimeout = Duration(milliseconds: 500);

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: _kDefaultTimeout,
      receiveTimeout: _kDefaultTimeout,
      sendTimeout: _kDefaultTimeout,
    ),
  )..interceptors.clear();

  static Future<bool> isReachable(String url) async {
    if (url.isEmpty) {
      print('ServerHealthService: URL is empty, returning false');
      return false;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      print('ServerHealthService: Invalid URI "$url", returning false');
      return false;
    }

    try {
      // Use /info endpoint for health check (designed for this purpose)
      final healthUri = uri.replace(path: '/info');
      print('ServerHealthService: Sending HEAD request to $healthUri');

      final startTime = DateTime.now();
      final response = await _dio.headUri(healthUri);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      print(
        'ServerHealthService: HEAD $healthUri -> ${response.statusCode} in ${elapsed}ms',
      );
      return response.statusCode == 200;
    } on TimeoutException catch (e) {
      print('ServerHealthService: HEAD $url TIMEOUT - ${e.duration}');
      return false;
    } on DioException catch (e) {
      print('ServerHealthService: HEAD $url DIO ERROR');
      print('  - type: ${e.type}');
      print('  - message: ${e.message}');
      print('  - error: ${e.error}');
      print('  - stack trace: ${e.stackTrace}');
      return false;
    } on Exception catch (e) {
      print('ServerHealthService: HEAD $url EXCEPTION - ${e.runtimeType}: $e');
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
