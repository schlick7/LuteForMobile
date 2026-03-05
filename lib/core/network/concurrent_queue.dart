import 'dart:async';

class ConcurrentQueue<T> {
  final int maxConcurrent;
  final String name;
  final List<_QueueItem<T>> _queue = [];
  int _activeCount = 0;
  bool _isDisposed = false;

  ConcurrentQueue({required this.maxConcurrent, required this.name});

  Future<T> enqueue(Future<T> Function() task) {
    if (_isDisposed) {
      throw Exception('ConcurrentQueue "$name" is disposed');
    }

    final completer = Completer<T>();
    _queue.add(
      _QueueItem(task: task, completer: completer, enqueuedAt: DateTime.now()),
    );

    _processQueue();
    return completer.future;
  }

  void _processQueue() {
    while (_activeCount < maxConcurrent && _queue.isNotEmpty) {
      final item = _queue.removeAt(0);
      _activeCount++;

      item
          .task()
          .then((result) {
            _activeCount--;
            if (!item.completer.isCompleted) {
              item.completer.complete(result);
            }
            _processQueue();
          })
          .catchError((error) {
            _activeCount--;
            if (!item.completer.isCompleted) {
              item.completer.completeError(error);
            }
            _processQueue();
          });
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    for (final item in _queue) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(Exception('Queue disposed'));
      }
    }
    _queue.clear();
  }

  int get queueLength => _queue.length;
  int get activeCount => _activeCount;
  bool get isDisposed => _isDisposed;
}

class _QueueItem<T> {
  final Future<T> Function() task;
  final Completer<T> completer;
  final DateTime enqueuedAt;

  _QueueItem({
    required this.task,
    required this.completer,
    required this.enqueuedAt,
  });
}
