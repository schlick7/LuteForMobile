import 'dart:async';
import 'package:dio/dio.dart';
import 'api_request_queue.dart';
import '../services/server_health_service.dart';

class QueuedDioInterceptor extends Interceptor {
  final ApiRequestQueue _queue;

  QueuedDioInterceptor(this._queue);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_queue.isServerReachable) {
      handler.next(options);
    } else {
      unawaited(
        _queue
            .enqueue(Dio(), options)
            .then(
              (response) => handler.resolve(response),
              onError: (error) => handler.reject(error as DioException),
            ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isReachable = await ServerHealthService.isReachable(
      err.requestOptions.baseUrl,
    );

    if (isReachable) {
      handler.next(err);
    } else {
      unawaited(
        _queue
            .enqueue(Dio(), err.requestOptions)
            .then(
              (response) => handler.resolve(response),
              onError: (error) => handler.reject(error as DioException),
            ),
      );
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    handler.next(response);
  }
}
