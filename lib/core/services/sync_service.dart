import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../../features/expenses/data/datasources/expense_local_datasource.dart';
import '../../features/expenses/data/datasources/expense_remote_datasource.dart';

/// Listens for connectivity changes and flushes the pending-sync queue.
///
/// When the device goes offline, [ExpenseRepositoryImpl] stores created /
/// updated expenses in a [AppConstants.pendingSyncBox] Hive box.  When
/// connectivity is restored this service reads that queue and pushes each
/// item to Firestore, then marks the local record as synced.
///
/// Call [start] once at app startup (after Hive is initialized) and
/// [dispose] when the app is shutting down.
class SyncService {
  final ExpenseLocalDataSource _local;
  final ExpenseRemoteDataSource _remote;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  SyncService({
    required ExpenseLocalDataSource local,
    required ExpenseRemoteDataSource remote,
    required Connectivity connectivity,
  })  : _local = local,
        _remote = remote,
        _connectivity = connectivity;

  Box<Map> get _pendingBox => Hive.box<Map>(AppConstants.pendingSyncBox);

  /// Starts listening for connectivity changes and triggers a sync immediately
  /// in case the app launched while already online with pending items.
  void start() {
    _subscription =
        _connectivity.onConnectivityChanged.listen((results) async {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) await _flush();
    });

    // Flush on startup in case there are pending items from a previous session.
    _flushSafe();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _flushSafe() async {
    try {
      await _flush();
    } catch (e) {
      log('[SyncService] Startup flush failed: $e');
    }
  }

  Future<void> _flush() async {
    if (_pendingBox.isEmpty) return;

    log('[SyncService] Flushing ${_pendingBox.length} pending item(s)...');

    // Take a snapshot of keys to avoid mutating while iterating.
    final keys = _pendingBox.keys.toList();

    for (final key in keys) {
      final entry = _pendingBox.get(key);
      if (entry == null) continue;

      final id = entry['id'] as String?;
      final operation = entry['operation'] as String?;
      if (id == null || operation == null) {
        await _pendingBox.delete(key);
        continue;
      }

      try {
        final localExpense = _local.getExpenseById(id);
        if (localExpense == null) {
          // Item was deleted locally before sync — just remove from queue.
          await _pendingBox.delete(key);
          continue;
        }

        if (operation == 'create') {
          await _remote.createExpense(localExpense);
        } else if (operation == 'update') {
          await _remote.updateExpense(localExpense);
        }

        // Mark synced in local storage.
        await _local.saveExpense(localExpense.copyWith(isSynced: true));
        await _pendingBox.delete(key);

        log('[SyncService] Synced $operation for expense $id');
      } catch (e) {
        // Leave in queue — will retry on next connectivity event.
        log('[SyncService] Failed to sync $operation for $id: $e');
      }
    }

    log('[SyncService] Flush complete.');
  }
}
