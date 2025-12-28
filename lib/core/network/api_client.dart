import 'package:dio/dio.dart';
import '../../config/app_config.dart';

class ApiClient {
  final Dio dio;

  ApiClient({String? baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? AppConfig.serverUrl,
          connectTimeout: AppConfig.defaultTimeout,
          receiveTimeout: AppConfig.defaultTimeout,
          headers: {'Content-Type': 'text/html'},
        ),
      ) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  Future<Response<String>> get(String path) async {
    return await dio.get<String>(path);
  }

  Future<Response<String>> post(String path, {dynamic data}) async {
    return await dio.post<String>(path, data: data);
  }
}
