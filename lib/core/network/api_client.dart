import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required String baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'text/html'},
        ),
      ) {
    if (baseUrl.isEmpty) {
      throw Exception(
        'Server URL is not configured. Please set your server URL in settings.',
      );
    }
  }

  Future<Response<String>> get(String path) async {
    return await dio.get<String>(path);
  }

  Future<Response<String>> post(String path, {dynamic data}) async {
    return await dio.post<String>(path, data: data);
  }
}
