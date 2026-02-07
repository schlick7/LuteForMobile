import 'dart:async';
import 'package:dio/dio.dart';
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

  static const int _kMaxTableStatsConcurrent = 2;
  int _tableStatsActive = 0;
  final List<Completer<void>> _tableStatsWaiters = [];

  bool get isServerReachable => _isServerReachable;

  bool _isTableStatsRequest(RequestOptions options) {
    return options.uri.path.contains('/book/table_stats/');
  }

  Future<void> _acquireTableStatsSlot() async {
    print(
      'DEBUG: _acquireTableStatsSlot - active=$_tableStatsActive, waiters=${_tableStatsWaiters.length}',
    );
    if (_tableStatsActive < _kMaxTableStatsConcurrent) {
      _tableStatsActive++;
      print(
        'DEBUG: _acquireTableStatsSlot - acquired slot, active=$_tableStatsActive',
      );
      return;
    }
    final completer = Completer<void>();
    _tableStatsWaiters.add(completer);
    print(
      'DEBUG: _acquireTableStatsSlot - queued, total waiters=${_tableStatsWaiters.length}',
    );
    await completer.future;
    print('DEBUG: _acquireTableStatsSlot - slot released, proceeding');
  }

  void _releaseTableStatsSlot() {
    print(
      'DEBUG: _releaseTableStatsSlot - active=$_tableStatsActive, waiters=${_tableStatsWaiters.length}',
    );
    if (_tableStatsWaiters.isNotEmpty) {
      final nextCompleter = _tableStatsWaiters.removeAt(0);
      nextCompleter.complete();
      print(
        'DEBUG: _releaseTableStatsSlot - released to waiter, remaining waiters=${_tableStatsWaiters.length}',
      );
    } else {
      _tableStatsActive--;
      print(
        'DEBUG: _releaseTableStatsSlot - decremented active to $_tableStatsActive',
      );
    }
  }

  void initialize(String serverUrl, Dio dio) {
    if (_serverUrl != null && _serverUrl == serverUrl) {
      print(
        'DEBUG: ApiRequestQueue already initialized with same URL, skipping',
      );
      return;
    }

    _serverUrl = serverUrl;
    _isServerReachable = ServerStatusManager.isReachable;

    ServerStatusManager.addListener(_onServerStatusChanged);

    print(
      'DEBUG: ApiRequestQueue initialized with URL: $serverUrl, initial reachable: $_isServerReachable, tableStatsActive=$_tableStatsActive',
    );
    _startPolling();
  }

  void _onServerStatusChanged() {
    _isServerReachable = ServerStatusManager.isReachable;
    print(
      'DEBUG: Server status changed → $_isServerReachable, triggering queue',
    );
    unawaited(_processQueue());
  }

  void _startPolling() {
    _pollTimer?.cancel();
    print('DEBUG: ApiRequestQueue starting timer (200ms)');
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _processQueue,
    );
  }

  void dispose() {
    ServerStatusManager.removeListener(_onServerStatusChanged);
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
    final isStats = _isTableStatsRequest(options);
    print(
      'DEBUG: enqueue - ${options.uri}, isTableStats=$isStats, queueLength=${_queue.length}',
    );

    unawaited(_processQueue());

    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_serverUrl == null || _serverUrl!.isEmpty) return;

    if (_queue.isEmpty) return;

    if (_isProcessing) return;

    _isProcessing = true;

    if (_isServerReachable && _queue.isNotEmpty) {
      final requestsToProcess = List<QueuedRequest>.from(_queue);
      _queue.clear();
      print(
        'DEBUG: _processQueue - processing ${requestsToProcess.length} requests',
      );

      for (final request in requestsToProcess) {
        _pendingSignatures.remove(request.signature);
        final isStats = _isTableStatsRequest(request.options);
        print(
          'DEBUG: _processQueue - request: ${request.options.uri}, isTableStats=$isStats',
        );

        if (isStats) {
          await _acquireTableStatsSlot();
        }

        try {
          final response = await request.dio.fetch(request.options);
          request.completer.complete(response);
        } catch (e) {
          request.completer.completeError(e);
        } finally {
          if (isStats) {
            _releaseTableStatsSlot();
          }
        }
      }
    }

    _isProcessing = false;
  }

  int get queueLength => _queue.length;
  bool get isProcessing => _isProcessing;
}
