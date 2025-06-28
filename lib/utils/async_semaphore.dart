import 'dart:async';

/// 並列実行数を制限するためのシンプルなPoolクラス
class AsyncSemaphore {
  final int _maxConcurrent;
  int _current = 0;
  final List<Completer<void>> _waiters = [];

  AsyncSemaphore(this._maxConcurrent);

  Future<T> run<T>(Future<T> Function() task) async {
    await _acquire();
    try {
      return await task();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_current < _maxConcurrent) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _current--;
    }
  }
}
