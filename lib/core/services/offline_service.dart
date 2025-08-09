// lib/core/services/offline_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Connectivity _connectivity = Connectivity();

  static StreamController<bool>? _connectionController;
  static Stream<bool>? _connectionStream;
  static StreamController<List<PendingOperation>>? _queueController;
  static Stream<List<PendingOperation>>? _queueStream;

  static bool _isOnline = true;
  static Timer? _syncTimer;
  static Timer? _cacheCleanupTimer;

  // Cache durations
  static const Duration activeCacheDuration = Duration(days: 7);
  static const Duration referenceCacheDuration = Duration(days: 30);

  // Collections categorization
  static const Set<String> activeCollections = {
    'quotes',
    'cart_items',
    'clients'
  };
  static const Set<String> referenceCollections = {
    'products',
    'categories',
    'settings'
  };

  // Offline queue for tracking pending operations
  static final List<PendingOperation> _pendingOperations = [];

  /// Initialize offline support
  static Future<void> initialize() async {
    // Enable Firebase offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Initialize connection monitoring
    _connectionController = StreamController<bool>.broadcast();
    _connectionStream = _connectionController!.stream;

    // Initialize queue monitoring
    _queueController = StreamController<List<PendingOperation>>.broadcast();
    _queueStream = _queueController!.stream;

    // Load pending operations from storage
    await _loadPendingOperations();

    // Check initial connection
    await checkConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) async {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      _connectionController?.add(_isOnline);

      if (_isOnline && wasOffline) {
        if (kDebugMode) {
          print('Connection restored. Starting automatic sync...');
        }
        await syncPendingChanges();
      }
    });

    // Set up periodic sync (every 30 seconds when online)
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isOnline) {
        await syncPendingChanges();
      }
    });

    // Set up cache cleanup timer (every hour)
    _cacheCleanupTimer =
        Timer.periodic(const Duration(hours: 1), (timer) async {
      await cleanupExpiredCache();
    });
  }

  /// Dispose resources
  static void dispose() {
    _connectionController?.close();
    _queueController?.close();
    _syncTimer?.cancel();
    _cacheCleanupTimer?.cancel();
  }

  /// Check current connectivity
  static Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    _connectionController?.add(_isOnline);
    return _isOnline;
  }

  /// Get connection status stream
  static Stream<bool> get connectionStream =>
      _connectionStream ?? Stream.value(true);

  /// Get queue status stream
  static Stream<List<PendingOperation>> get queueStream =>
      _queueStream ?? Stream.value([]);

  /// Get current online status
  static bool get isOnline => _isOnline;

  /// Get pending operations count
  static int get pendingOperationsCount => _pendingOperations.length;

  /// Get pending operations
  static List<PendingOperation> get pendingOperations =>
      List.unmodifiable(_pendingOperations);

  /// Sync pending changes when back online with last-write-wins
  static Future<void> syncPendingChanges() async {
    if (!_isOnline || _pendingOperations.isEmpty) return;

    if (kDebugMode) {
      print('Syncing ${_pendingOperations.length} pending operations...');
    }

    // Sort operations by timestamp (oldest first)
    final operationsToSync = List<PendingOperation>.from(_pendingOperations)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _pendingOperations.clear();
    int successCount = 0;
    int failCount = 0;

    for (final operation in operationsToSync) {
      try {
        // Apply last-write-wins conflict resolution
        final docRef =
            _firestore.collection(operation.collection).doc(operation.id);

        if (operation.operation == OperationType.delete) {
          await docRef.delete();
        } else {
          // Get server version to check timestamp
          final serverDoc = await docRef.get();

          if (serverDoc.exists) {
            final serverTimestamp =
                serverDoc.data()?['updated_at'] as Timestamp?;
            final localTimestamp = operation.timestamp;

            // Only update if local version is newer (last-write-wins)
            if (serverTimestamp == null ||
                localTimestamp.isAfter(serverTimestamp.toDate())) {
              await docRef.set({
                ...operation.data,
                'synced': true,
                'updated_at': FieldValue.serverTimestamp(),
                'sync_timestamp': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              successCount++;
            } else {
              if (kDebugMode) {
                print('Skipping ${operation.id}: Server version is newer');
              }
            }
          } else if (operation.operation == OperationType.create) {
            // Create if doesn't exist
            await docRef.set({
              ...operation.data,
              'synced': true,
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            });
            successCount++;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync operation ${operation.id}: $e');
        }
        _pendingOperations.add(operation);
        failCount++;
      }
    }

    if (kDebugMode) {
      print('Sync complete: $successCount succeeded, $failCount failed');
    }

    // Update queue stream
    _queueController?.add(_pendingOperations);

    // Save updated pending operations
    await _savePendingOperations();

    // Update last sync time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync', DateTime.now().toIso8601String());
  }

  /// Clean up expired cache based on collection type
  static Future<void> cleanupExpiredCache() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (kDebugMode) {
      print('Starting cache cleanup...');
    }

    for (final collection in activeCollections) {
      await _cleanupCollection(collection, activeCacheDuration);
    }

    for (final collection in referenceCollections) {
      await _cleanupCollection(collection, referenceCacheDuration);
    }

    await prefs.setString(
        'last_cache_cleanup', DateTime.now().toIso8601String());
  }

  static Future<void> _cleanupCollection(
      String collection, Duration maxAge) async {
    try {
      final cutoffDate = DateTime.now().subtract(maxAge);

      // Query for old cached documents
      final oldDocs = await _firestore
          .collection(collection)
          .where('cached_at', isLessThan: Timestamp.fromDate(cutoffDate))
          .get(const GetOptions(source: Source.cache));

      for (final doc in oldDocs.docs) {
        // Remove from cache
        await doc.reference.delete();
      }

      if (oldDocs.docs.isNotEmpty) {
        if (kDebugMode) {
          print(
              'Cleaned ${oldDocs.docs.length} expired documents from $collection');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning cache for $collection: $e');
      }
    }
  }

  /// Generate offline ID
  static String generateOfflineId() {
    return 'offline_${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid ?? 'anonymous'}';
  }

  /// Create operation with offline support
  static Future<void> addOperation(
    String collection,
    String id,
    OperationType operation,
    Map<String, dynamic> data,
  ) async {
    final pendingOp = PendingOperation(
      id: id,
      collection: collection,
      operation: operation,
      data: data,
      timestamp: DateTime.now(),
    );

    _pendingOperations.add(pendingOp);
    _queueController?.add(_pendingOperations);
    await _savePendingOperations();

    if (_isOnline) {
      // Try immediate sync if online
      await syncPendingChanges();
    }
  }

  /// Save pending operations to local storage
  static Future<void> _savePendingOperations() async {
    final prefs = await SharedPreferences.getInstance();

    final operationsJson =
        _pendingOperations.map((op) => jsonEncode(op.toJson())).toList();

    await prefs.setStringList('pending_operations', operationsJson);
    await prefs.setString(
        'last_queue_update', DateTime.now().toIso8601String());
  }

  /// Load pending operations from local storage
  static Future<void> _loadPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final operationsJson = prefs.getStringList('pending_operations') ?? [];

    _pendingOperations.clear();
    for (final json in operationsJson) {
      try {
        final operation = PendingOperation.fromJson(jsonDecode(json));
        _pendingOperations.add(operation);
      } catch (e) {
        if (kDebugMode) {
          print('Error loading pending operation: $e');
        }
      }
    }

    _queueController?.add(_pendingOperations);
    if (kDebugMode) {
      print(
          'Loaded ${_pendingOperations.length} pending operations from storage');
    }
  }

  /// Enable offline mode for specific collections with cache timestamps
  static Future<void> enableOfflineCollection(String collection) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Determine if this is active or reference data
      final isActiveData = activeCollections.contains(collection);

      // Force cache of user's documents with timestamp
      final snapshot = await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .get(const GetOptions(source: Source.server));

      // Add cache timestamp to documents
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'cached_at': FieldValue.serverTimestamp(),
          'cache_type': isActiveData ? 'active' : 'reference',
        });
      }
      await batch.commit();

      if (kDebugMode) {
        print(
            'Cached ${snapshot.docs.length} documents from $collection for offline use');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching $collection: $e');
      }
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'pending_operations': _pendingOperations.length,
      'is_online': _isOnline,
      'last_sync': prefs.getString('last_sync') ?? 'Never',
      'last_cache_cleanup': prefs.getString('last_cache_cleanup') ?? 'Never',
      'cache_enabled': true,
      'active_cache_duration_days': activeCacheDuration.inDays,
      'reference_cache_duration_days': referenceCacheDuration.inDays,
    };
  }

  /// Clear specific pending operation
  static Future<void> clearPendingOperation(String operationId) async {
    _pendingOperations.removeWhere((op) => op.id == operationId);
    _queueController?.add(_pendingOperations);
    await _savePendingOperations();
  }

  /// Retry specific pending operation
  static Future<void> retryPendingOperation(String operationId) async {
    final operation = _pendingOperations.firstWhere(
      (op) => op.id == operationId,
      orElse: () => throw Exception('Operation not found'),
    );

    if (_isOnline) {
      try {
        final docRef =
            _firestore.collection(operation.collection).doc(operation.id);

        if (operation.operation == OperationType.delete) {
          await docRef.delete();
        } else {
          await docRef.set({
            ...operation.data,
            'synced': true,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // Remove from pending if successful
        await clearPendingOperation(operationId);
      } catch (e) {
        if (kDebugMode) {
          print('Retry failed for operation $operationId: $e');
        }
        rethrow;
      }
    } else {
      throw Exception('Cannot retry while offline');
    }
  }
}

/// Enum for operation types
enum OperationType {
  create,
  update,
  delete,
}

/// Model for tracking pending operations
class PendingOperation {
  final String id;
  final String collection;
  final OperationType operation;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PendingOperation({
    required this.id,
    required this.collection,
    required this.operation,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection': collection,
      'operation': operation.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      collection: json['collection'],
      operation: OperationType.values.firstWhere(
        (e) => e.toString() == json['operation'],
      ),
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
