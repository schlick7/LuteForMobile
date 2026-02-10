import 'dart:async';
import 'package:dio/dio.dart';
import 'api_request_queue.dart';
import '../services/server_health_service.dart';
import '../../shared/providers/server_status_provider.dart';

class QueuedDioInterceptor extends Interceptor {
  final ApiRequestQueue _queue;
  final Set<String> _pendingTermFormSignatures = {};

  QueuedDioInterceptor(this._queue);

  bool _isTermFormFetch(RequestOptions options) {
    return options.method == 'GET' &&
        options.uri.path.contains('/read/edit_term/');
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_queue.isServerReachable) {
      handler.next(options);
    } else {
      ServerStatusManager.markError();

      if (_isTermFormFetch(options)) {
        final signature = _computeSignature(options);
        if (_pendingTermFormSignatures.contains(signature)) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Term form fetch dropped (connection issue)',
              type: DioExceptionType.connectionError,
            ),
          );
          return;
        }
        _pendingTermFormSignatures.add(signature);
        unawaited(
          _queue
              .enqueue(Dio(), options)
              .then(
                (response) {
                  _pendingTermFormSignatures.remove(signature);
                  handler.resolve(response);
                },
                onError: (error) {
                  _pendingTermFormSignatures.remove(signature);
                  handler.reject(error as DioException);
                },
              ),
        );
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
  }

  String _computeSignature(RequestOptions options) {
    final method = options.method;
    final url = options.uri.toString();
    return '$method:$url';
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isReachable = await ServerHealthService.isReachable(
      err.requestOptions.baseUrl,
    );

    if (isReachable) {
      handler.next(err);
    } else {
      _queue.markServerUnreachable();
      ServerStatusManager.markError();

      if (_isTermFormFetch(err.requestOptions)) {
        final signature = _computeSignature(err.requestOptions);
        if (_pendingTermFormSignatures.contains(signature)) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: 'Term form fetch dropped (connection issue)',
              type: DioExceptionType.connectionError,
            ),
          );
          return;
        }
        _pendingTermFormSignatures.add(signature);
        unawaited(
          _queue
              .enqueue(Dio(), err.requestOptions)
              .then(
                (response) {
                  _pendingTermFormSignatures.remove(signature);
                  handler.resolve(response);
                },
                onError: (error) {
                  _pendingTermFormSignatures.remove(signature);
                  handler.reject(error as DioException);
                },
              ),
        );
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
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    handler.next(response);
  }
}
