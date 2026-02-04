import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../services/server_health_service.dart';
import '../../shared/providers/server_status_provider.dart';

class QueuedRequest {
  final String signature;
  final RequestOptions options;
  final Completer<Response> completer;
  final DateTime enqueuedAt;
  final Dio dio;

  QueuedRequest({
    required this.signature,
    required this.options,
    required this.completer,
    required this.enqueuedAt,
    required this.dio,
  });
}

class ApiRequestQueue {
  static final ApiRequestQueue _instance = ApiRequestQueue._internal();
  factory ApiRequestQueue() => _instance;
  ApiRequestQueue._internal();

  final List<QueuedRequest> _queue = [];
  final Map<String, Completer<Response>> _pendingSignatures = {};
  Timer? _pollTimer;
  bool _isProcessing = false;
  bool _isServerReachable = true;
  String? _serverUrl;

  void initialize(String serverUrl, Dio dio) {
    _serverUrl = serverUrl;
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _processQueue,
    );
  }

  void _updatePollingInterval() {
    _pollTimer?.cancel();
    final interval = _isServerReachable
        ? const Duration(seconds: 5)
        : const Duration(milliseconds: 200);
    _pollTimer = Timer.periodic(interval, (_) => _processQueue);
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    for (final request in _queue) {
      request.completer.completeError(Exception('Queue disposed'));
    }
    _queue.clear();
    _pendingSignatures.clear();
    _isProcessing = false;
  }

  String _computeSignature(RequestOptions options) {
    final method = options.method;
    final url = options.uri.toString();
    final body = options.data?.toString() ?? '';
    return '$method:$url:$body';
  }

  Future<Response> enqueue(Dio dio, RequestOptions options) async {
    final signature = _computeSignature(options);

    if (_pendingSignatures.containsKey(signature)) {
      final existingCompleter = _pendingSignatures[signature]!;
      return existingCompleter.future;
    }

    final completer = Completer<Response>();
    _pendingSignatures[signature] = completer;

    final queuedRequest = QueuedRequest(
      signature: signature,
      options: options,
      completer: completer,
      enqueuedAt: DateTime.now(),
      dio: dio,
    );

    _queue.add(queuedRequest);

    if (!_isServerReachable) {
      _updatePollingInterval();
    }

    unawaited(_processQueue());

    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_serverUrl == null || _serverUrl!.isEmpty) return;

    final isReachable = await ServerHealthService.isReachable(_serverUrl!);

    if (isReachable != _isServerReachable) {
      _isServerReachable = isReachable;
      ServerStatusManager.setReachable(isReachable);
      _updatePollingInterval();
    }

    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    if (isReachable) {
      final requestsToProcess = List<QueuedRequest>.from(_queue);
      _queue.clear();

      for (final request in requestsToProcess) {
        _pendingSignatures.remove(request.signature);
        try {
          final response = await request.dio.fetch(request.options);
          request.completer.complete(response);
        } catch (e) {
          request.completer.completeError(e);
        }
      }
    }

    _isProcessing = false;
  }

  int get queueLength => _queue.length;
  bool get isProcessing => _isProcessing;
}
