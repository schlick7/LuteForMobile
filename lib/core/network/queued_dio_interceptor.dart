import 'dart:async';
import 'package:dio/dio.dart';
import 'api_request_queue.dart';
import '../services/server_health_service.dart';
import '../../shared/providers/server_status_provider.dart';

class QueuedDioInterceptor extends Interceptor {
  final ApiRequestQueue _queue;
  bool _hasQueuedTermForm = false;
  bool _wasUnreachable = false;

  QueuedDioInterceptor(this._queue) {
    ServerStatusManager.addListener(_onServerStatusChanged);
  }

  void _onServerStatusChanged() {
    final isReachable = ServerStatusManager.isReachable;
    if (_wasUnreachable && isReachable) {
      _hasQueuedTermForm = false;
    }
    _wasUnreachable = !isReachable;
  }

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
        if (_hasQueuedTermForm) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Term form fetch dropped (connection issue)',
              type: DioExceptionType.connectionError,
            ),
          );
          return;
        }
        _hasQueuedTermForm = true;
        unawaited(
          _queue
              .enqueue(Dio(), options)
              .then(
                (response) {
                  handler.resolve(response);
                },
                onError: (error) {
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
        if (_hasQueuedTermForm) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: 'Term form fetch dropped (connection issue)',
              type: DioExceptionType.connectionError,
            ),
          );
          return;
        }
        _hasQueuedTermForm = true;
        unawaited(
          _queue
              .enqueue(Dio(), err.requestOptions)
              .then(
                (response) {
                  handler.resolve(response);
                },
                onError: (error) {
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
