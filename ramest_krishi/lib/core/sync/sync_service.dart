import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_repository.dart';

enum SyncStatus { idle, syncing, error, offline }

class SyncService extends ChangeNotifier {
  final SyncRepository _repository;
  Timer? _timer;
  SyncStatus _status = SyncStatus.idle;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  SyncStatus get status => _status;

  SyncService(this._repository) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline && _status == SyncStatus.offline) {
        // We just came back online, trigger immediate sync
        _runSyncCycle();
      } else if (!isOnline) {
        _setStatus(SyncStatus.offline);
      }
    });
  }

  // Starts the foreground periodic loop (e.g., every 30 seconds)
  void startPeriodicSync({int intervalSeconds = 30}) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      _runSyncCycle();
    });
    // Trigger one immediately
    _runSyncCycle();
  }

  void stopPeriodicSync() {
    _timer?.cancel();
  }

  // Exposed for manual pull-to-refresh
  Future<void> triggerManualSync() async {
    await _runSyncCycle();
  }

  Future<void> _runSyncCycle() async {
    if (_status == SyncStatus.syncing) return; // Prevent overlapping syncs

    // Network check
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      _setStatus(SyncStatus.offline);
      return;
    }

    try {
      _setStatus(SyncStatus.syncing);

      // Phase 1: PUSH local queue to cloud
      final pendingActions = await _repository.getPendingSyncActions();
      for (var actionRow in pendingActions) {
        await _repository.pushActionToCloud(actionRow);
        await _repository.removeSyncAction(actionRow['id']);
      }

      // Phase 2: PULL from cloud to local
      await _repository.pullUpdatesFromCloud();

      _setStatus(SyncStatus.idle);
    } catch (e) {
      debugPrint("Sync Error: $e");
      _setStatus(SyncStatus.error);
    }
  }

  void _setStatus(SyncStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPeriodicSync();
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
