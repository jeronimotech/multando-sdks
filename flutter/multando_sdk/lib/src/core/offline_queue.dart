import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../models/report.dart';
import 'http_client.dart';

/// Hive-backed offline queue that stores report-creation payloads while the
/// device is offline and flushes them automatically when connectivity returns.
class OfflineQueue {
  OfflineQueue({
    required MultandoHttpClient httpClient,
    Connectivity? connectivity,
  })  : _httpClient = httpClient,
        _connectivity = connectivity ?? Connectivity();

  static const _boxName = 'multando_offline_queue';

  final MultandoHttpClient _httpClient;
  final Connectivity _connectivity;
  Box<String>? _box;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _flushing = false;

  /// Number of items currently waiting in the queue.
  int get count => _box?.length ?? 0;

  /// Open the Hive box and start listening for connectivity changes.
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<String>(_boxName);
    } else {
      _box = Hive.box<String>(_boxName);
    }

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection =
          results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        flush();
      }
    });
  }

  /// Enqueue a [ReportCreate] payload for later submission.
  Future<void> enqueue(ReportCreate report) async {
    final json = jsonEncode(report.toJson());
    await _box?.add(json);
  }

  /// Attempt to flush all queued reports to the API.
  /// Silently skips items that succeed and keeps items that fail.
  Future<void> flush() async {
    if (_flushing || _box == null || _box!.isEmpty) return;
    _flushing = true;

    try {
      final keys = List<dynamic>.from(_box!.keys);
      for (final key in keys) {
        final json = _box!.get(key);
        if (json == null) continue;

        try {
          final data = jsonDecode(json) as Map<String, dynamic>;
          await _httpClient.post<Map<String, dynamic>>(
            '/reports',
            data: data,
          );
          await _box!.delete(key);
        } catch (_) {
          // Leave the item in the queue for the next attempt.
          break;
        }
      }
    } finally {
      _flushing = false;
    }
  }

  /// Clear all queued items without sending them.
  Future<void> clear() async {
    await _box?.clear();
  }

  /// Release resources.
  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _box?.close();
  }
}
