import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:acms_app/core/database/database_service.dart';
import 'package:acms_app/core/database/isar_schemas.dart';

/// Service for managing online/offline sync operations.
///
/// Handles connectivity monitoring, operation queuing when offline,
/// and processing the sync queue when back online.
class SyncService {
  static SyncService? _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  final _onlineController = StreamController<bool>.broadcast();

  // Callbacks for when connectivity changes
  final List<VoidCallback> _onOnlineCallbacks = [];

  SyncService._();

  /// Get the singleton instance.
  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  /// Stream of online status changes.
  Stream<bool> get onlineStream => _onlineController.stream;

  /// Current online status.
  bool get isOnline => _isOnline;

  /// Initialize the sync service.
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(results);

      if (_isOnline != wasOnline) {
        _onlineController.add(_isOnline);
        debugPrint('SyncService: Connectivity changed - online: $_isOnline');

        if (_isOnline) {
          _processQueue();
          _notifyOnlineCallbacks();
        }
      }
    });

    debugPrint('SyncService: Initialized, online: $_isOnline');
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }

  /// Register a callback to be called when coming back online.
  void registerOnlineCallback(VoidCallback callback) {
    _onOnlineCallbacks.add(callback);
  }

  /// Unregister an online callback.
  void unregisterOnlineCallback(VoidCallback callback) {
    _onOnlineCallbacks.remove(callback);
  }

  void _notifyOnlineCallbacks() {
    for (final callback in _onOnlineCallbacks) {
      callback();
    }
  }

  /// Queue an operation to be synced when online.
  Future<void> queueOperation({
    required String operationType,
    required Map<String, dynamic> payload,
    int maxRetries = 3,
  }) async {
    if (!DatabaseService.isInitialized) {
      debugPrint(
        'SyncService: Database not initialized, cannot queue operation',
      );
      return;
    }

    final db = DatabaseService.instance;
    final operation = SyncQueueEntity()
      ..operationType = operationType
      ..payloadJson = jsonEncode(payload)
      ..retryCount = 0
      ..maxRetries = maxRetries
      ..queuedAt = DateTime.now();

    await db.queueOperation(operation);
    debugPrint('SyncService: Queued operation - $operationType');

    // If online, process immediately
    if (_isOnline) {
      _processQueue();
    }
  }

  /// Process the sync queue.
  Future<void> _processQueue() async {
    if (!DatabaseService.isInitialized) return;

    final db = DatabaseService.instance;
    final operations = await db.getPendingOperations();

    if (operations.isEmpty) return;

    debugPrint(
      'SyncService: Processing ${operations.length} queued operations',
    );

    for (final operation in operations) {
      try {
        final success = await _processOperation(operation);
        if (success) {
          await db.removeOperation(operation.id);
          debugPrint(
            'SyncService: Completed operation - ${operation.operationType}',
          );
        } else {
          // Increment retry count
          final newRetryCount = operation.retryCount + 1;
          if (newRetryCount >= operation.maxRetries) {
            // Max retries reached, mark as failed (but keep for manual retry)
            await db.updateOperationRetry(
              operation.id,
              retryCount: newRetryCount,
              error: 'Max retries reached',
            );
            debugPrint(
              'SyncService: Operation failed after max retries - ${operation.operationType}',
            );
          } else {
            await db.updateOperationRetry(
              operation.id,
              retryCount: newRetryCount,
            );
          }
        }
      } catch (e) {
        debugPrint('SyncService: Error processing operation: $e');
        await db.updateOperationRetry(
          operation.id,
          retryCount: operation.retryCount + 1,
          error: e.toString(),
        );
      }
    }
  }

  /// Process a single operation. Override this in subclass or use callbacks.
  Future<bool> _processOperation(SyncQueueEntity operation) async {
    // This will be handled by specific handlers registered for each operation type
    final handler = _operationHandlers[operation.operationType];
    if (handler != null) {
      return await handler(jsonDecode(operation.payloadJson));
    }
    debugPrint(
      'SyncService: No handler for operation type: ${operation.operationType}',
    );
    return false;
  }

  // Operation handlers registry
  final Map<String, Future<bool> Function(Map<String, dynamic>)>
  _operationHandlers = {};

  /// Register a handler for a specific operation type.
  void registerOperationHandler(
    String operationType,
    Future<bool> Function(Map<String, dynamic>) handler,
  ) {
    _operationHandlers[operationType] = handler;
  }

  /// Force process the queue (e.g., after login).
  Future<void> processQueueNow() async {
    if (_isOnline) {
      await _processQueue();
    }
  }

  /// Get count of pending operations.
  Future<int> getPendingCount() async {
    if (!DatabaseService.isInitialized) return 0;
    final operations = await DatabaseService.instance.getPendingOperations();
    return operations.length;
  }

  /// Dispose resources.
  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineController.close();
    _onOnlineCallbacks.clear();
  }
}
