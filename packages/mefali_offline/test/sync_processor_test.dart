import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_offline/mefali_offline.dart';

void main() {
  late MefaliDatabase db;

  setUp(() {
    db = MefaliDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> enqueue(String type, String id, {int retryCount = 0}) async {
    await db.enqueueSync(
      entityType: type,
      entityId: id,
      payload: {'test': true},
    );
    // Manually set retryCount if needed (enqueueSync defaults to 0).
    if (retryCount > 0) {
      final entries = await db.getPendingSyncEntries();
      final entry = entries.firstWhere((e) => e.entityId == id);
      for (var i = 0; i < retryCount; i++) {
        await db.incrementRetryCount(entry.id);
      }
    }
  }

  group('SyncProcessor.processQueue', () {
    test('removes entry on SyncResult.success', () async {
      await enqueue('rating', 'order-1');

      final processor = SyncProcessor(
        db: db,
        handler: (_) async => SyncResult.success,
      );
      await processor.processQueue();

      final remaining = await db.getPendingSyncEntries();
      expect(remaining, isEmpty);
    });

    test('removes entry on SyncResult.conflict (409)', () async {
      await enqueue('rating', 'order-2');

      final processor = SyncProcessor(
        db: db,
        handler: (_) async => SyncResult.conflict,
      );
      await processor.processQueue();

      final remaining = await db.getPendingSyncEntries();
      expect(remaining, isEmpty);
    });

    test('increments retryCount on SyncResult.retryable', () async {
      await enqueue('rating', 'order-3');

      final processor = SyncProcessor(
        db: db,
        handler: (_) async => SyncResult.retryable,
      );
      await processor.processQueue();

      final remaining = await db.getPendingSyncEntries();
      expect(remaining, hasLength(1));
      expect(remaining.first.retryCount, 1);
    });

    test('increments retryCount when handler throws', () async {
      await enqueue('rating', 'order-4');

      final processor = SyncProcessor(
        db: db,
        handler: (_) async => throw Exception('network error'),
      );
      await processor.processQueue();

      final remaining = await db.getPendingSyncEntries();
      expect(remaining, hasLength(1));
      expect(remaining.first.retryCount, 1);
    });

    test('dead-letters entry after maxRetries', () async {
      await enqueue('rating', 'order-5', retryCount: 5);

      final handlerCalled = <String>[];
      final processor = SyncProcessor(
        db: db,
        maxRetries: 5,
        handler: (entry) async {
          handlerCalled.add(entry.entityId);
          return SyncResult.retryable;
        },
      );
      await processor.processQueue();

      // Entry should be removed without calling the handler.
      expect(handlerCalled, isEmpty);
      final remaining = await db.getPendingSyncEntries();
      expect(remaining, isEmpty);
    });

    test('processes multiple entries in order', () async {
      await enqueue('rating', 'order-a');
      await enqueue('rating', 'order-b');
      await enqueue('rating', 'order-c');

      final processed = <String>[];
      final processor = SyncProcessor(
        db: db,
        handler: (entry) async {
          processed.add(entry.entityId);
          return SyncResult.success;
        },
      );
      await processor.processQueue();

      expect(processed, ['order-a', 'order-b', 'order-c']);
      final remaining = await db.getPendingSyncEntries();
      expect(remaining, isEmpty);
    });

    test('is re-entrant — concurrent calls do not double-process', () async {
      await enqueue('rating', 'order-6');

      var callCount = 0;
      final processor = SyncProcessor(
        db: db,
        handler: (entry) async {
          callCount++;
          // Simulate slow network call.
          await Future.delayed(const Duration(milliseconds: 50));
          return SyncResult.success;
        },
      );

      // Fire two concurrent processQueue calls.
      await Future.wait([
        processor.processQueue(),
        processor.processQueue(),
      ]);

      expect(callCount, 1);
    });
  });

  group('MefaliDatabase.enqueueSync deduplication', () {
    test('replaces existing entry for same entityType + entityId', () async {
      await db.enqueueSync(
        entityType: 'rating',
        entityId: 'order-dup',
        payload: {'score': 3},
      );
      await db.enqueueSync(
        entityType: 'rating',
        entityId: 'order-dup',
        payload: {'score': 5},
      );

      final entries = await db.getPendingSyncEntries();
      expect(entries, hasLength(1));
      expect(entries.first.payload, contains('"score":5'));
    });

    test('does not deduplicate different entityIds', () async {
      await db.enqueueSync(
        entityType: 'rating',
        entityId: 'order-x',
        payload: {'x': 1},
      );
      await db.enqueueSync(
        entityType: 'rating',
        entityId: 'order-y',
        payload: {'y': 2},
      );

      final entries = await db.getPendingSyncEntries();
      expect(entries, hasLength(2));
    });
  });
}
