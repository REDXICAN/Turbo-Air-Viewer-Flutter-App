// lib/core/services/offline_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class OfflineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Connectivity _connectivity = Connectivity();

  static StreamController<bool>? _connectionController;
  static Stream<bool>? _connectionStream;
  static bool _isOnline = true;
  static Timer? _syncTimer;

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

    // Check initial connection
    await checkConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) async {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      _connectionController?.add(_isOnline);

      if (_isOnline && wasOffline) {
        // Back online - sync pending changes
        await syncPendingChanges();
      }
    });

    // Set up periodic sync (every 30 seconds when online)
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isOnline) {
        await syncPendingChanges();
      }
    });
  }

  /// Dispose resources
  static void dispose() {
    _connectionController?.close();
    _syncTimer?.cancel();
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
      _connectionStream ?? const Stream.empty();

  /// Check if currently online
  static bool get isOnline => _isOnline;

  /// Add product to cart with offline support
  static Future<void> addToCart({
    required String productId,
    required String clientId,
    required int quantity,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final cartItem = {
      'user_id': userId,
      'product_id': productId,
      'client_id': clientId,
      'quantity': quantity,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'synced': _isOnline,
    };

    try {
      // Try to add to Firestore
      final docRef = await _firestore.collection('cart_items').add(cartItem);

      if (!_isOnline) {
        // Track this operation as pending
        _pendingOperations.add(PendingOperation(
          id: docRef.id,
          collection: 'cart_items',
          operation: OperationType.create,
          data: cartItem,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      // If offline, the operation is queued by Firebase
      print('Offline operation queued: $e');
    }
  }

  /// Create quote with offline support
  static Future<String> createQuote({
    required String clientId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double taxRate,
    required double taxAmount,
    required double totalAmount,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final quoteNumber = 'Q${DateTime.now().millisecondsSinceEpoch}';

    final quoteData = {
      'user_id': userId,
      'client_id': clientId,
      'quote_number': quoteNumber,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'status': 'draft',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'synced': _isOnline,
    };

    try {
      // Create quote document
      final quoteRef = await _firestore.collection('quotes').add(quoteData);

      // Add quote items
      final batch = _firestore.batch();
      for (final item in items) {
        final itemRef = _firestore.collection('quote_items').doc();
        batch.set(itemRef, {
          ...item,
          'quote_id': quoteRef.id,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (!_isOnline) {
        // Track as pending
        _pendingOperations.add(PendingOperation(
          id: quoteRef.id,
          collection: 'quotes',
          operation: OperationType.create,
          data: quoteData,
          timestamp: DateTime.now(),
        ));
      }

      return quoteRef.id;
    } catch (e) {
      print('Error creating quote: $e');
      rethrow;
    }
  }

  /// Update client with offline support
  static Future<void> updateClient(
      String clientId, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    data['synced'] = _isOnline;

    try {
      await _firestore.collection('clients').doc(clientId).update(data);

      if (!_isOnline) {
        _pendingOperations.add(PendingOperation(
          id: clientId,
          collection: 'clients',
          operation: OperationType.update,
          data: data,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      print('Offline update queued: $e');
    }
  }

  /// Get pending operations count
  static int get pendingOperationsCount => _pendingOperations.length;

  /// Get pending operations
  static List<PendingOperation> get pendingOperations =>
      List.unmodifiable(_pendingOperations);

  /// Sync pending changes when back online
  static Future<void> syncPendingChanges() async {
    if (!_isOnline || _pendingOperations.isEmpty) return;

    print('Syncing ${_pendingOperations.length} pending operations...');

    final operationsToSync = List<PendingOperation>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operationsToSync) {
      try {
        // Update synced flag
        await _firestore
            .collection(operation.collection)
            .doc(operation.id)
            .update({'synced': true});
      } catch (e) {
        print('Failed to sync operation ${operation.id}: $e');
        // Re-add to pending if sync failed
        _pendingOperations.add(operation);
      }
    }

    // Save pending operations to local storage
    await _savePendingOperations();
  }

  /// Force sync all unsynced data
  static Future<void> forceSyncAll() async {
    if (!_isOnline) {
      throw Exception('Cannot sync while offline');
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Find and sync unsynced documents
    final collections = ['clients', 'quotes', 'cart_items'];

    for (final collection in collections) {
      try {
        final unsyncedDocs = await _firestore
            .collection(collection)
            .where('user_id', isEqualTo: userId)
            .where('synced', isEqualTo: false)
            .get();

        for (final doc in unsyncedDocs.docs) {
          await doc.reference.update({'synced': true});
        }

        print('Synced ${unsyncedDocs.docs.length} documents from $collection');
      } catch (e) {
        print('Error syncing $collection: $e');
      }
    }
  }

  /// Clear offline cache (use carefully!)
  static Future<void> clearOfflineCache() async {
    await _firestore.clearPersistence();
    _pendingOperations.clear();
    await _savePendingOperations();
  }

  /// Get cache size info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'pending_operations': _pendingOperations.length,
      'is_online': _isOnline,
      'last_sync': prefs.getString('last_sync') ?? 'Never',
      'cache_enabled': true,
    };
  }

  /// Save pending operations to local storage
  static Future<void> _savePendingOperations() async {
    final prefs = await SharedPreferences.getInstance();

    // Convert operations to JSON
    final operationsJson = _pendingOperations.map((op) => op.toJson()).toList();

    await prefs.setString('pending_operations', operationsJson.toString());
    await prefs.setString('last_sync', DateTime.now().toIso8601String());
  }

  /// Load pending operations from local storage
  static Future<void> _loadPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final operationsString = prefs.getString('pending_operations');

    if (operationsString != null && operationsString.isNotEmpty) {
      // Parse and load operations
      // This is simplified - you'd need proper JSON parsing
      print('Loaded pending operations from storage');
    }
  }

  /// Enable offline mode for specific collections
  static Future<void> enableOfflineCollection(String collection) async {
    // Pre-cache collection data for offline use
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Force cache of user's documents
      await _firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .get(const GetOptions(source: Source.server));

      print('Cached $collection for offline use');
    } catch (e) {
      print('Error caching $collection: $e');
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
