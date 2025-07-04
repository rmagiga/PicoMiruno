import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pico_miruno/utils/async_semaphore.dart';

void main() {
  group('AsyncSemaphore', () {
    test('同時実行数が制限される', () async {
      final AsyncSemaphore semaphore = AsyncSemaphore(2);
      int running = 0;
      final List<int> results = <int>[];
      final List<Completer<void>> completers = List<Completer<void>>.generate(
        4,
        (_) => Completer<void>(),
      );

      Future<int> task(int i) async {
        running++;
        expect(running <= 2, true, reason: '同時実行数が2を超えている');
        await completers[i].future;
        running--;
        results.add(i);
        return i;
      }

      final List<Future<int>> futures = List<Future<int>>.generate(
        4,
        (int i) => semaphore.run(() => task(i)),
      );
      // 2つだけ先に進む
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(running, 2);
      // 1つ解放
      completers[0].complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(running, 2);
      // もう1つ解放
      completers[1].complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(running, 2);
      // 残りも解放
      completers[2].complete();
      completers[3].complete();
      await Future.wait<int>(futures);
      expect(results.length, 4);
      expect(results.toSet(), <int>{0, 1, 2, 3});
    });

    test('runの戻り値が正しい', () async {
      final AsyncSemaphore semaphore = AsyncSemaphore(1);
      final int result = await semaphore.run(() async => 42);
      expect(result, 42);
    });

    test('例外が発生してもリリースされる', () async {
      final AsyncSemaphore semaphore = AsyncSemaphore(1);
      bool threw = false;
      try {
        await semaphore.run(() async {
          throw Exception('error');
        });
      } catch (_) {
        threw = true;
      }
      expect(threw, true);
      // 次のrunが実行できること
      final String result = await semaphore.run(() async => 'ok');
      expect(result, 'ok');
    });
  });
}
