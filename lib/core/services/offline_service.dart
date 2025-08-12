// lib/core/services/offline_service.dart
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';

enum SyncStatus { idle, syncing, success, error }

enum OperationType { create, update, delete }

class PendingOperation {
  final String id;
  final String collection;
  final OperationType operation;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;

  PendingOperation({
    required this.id,
    required this.collection,
    required this.operation,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection': collection,
      'operation': operation.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory PendingOperation.fromMap(Map<String, dynamic> map) {
    return PendingOperation(
      id: map['id'],
      collection: map['collection'],
      operation: OperationType.values.firstWhere(
        (e) => e.toString() == map['operation'],
      ),
      data: Map<String, dynamic>.from(map['data']),
      timestamp: DateTime.parse(map['timestamp']),
      retryCount: map['retryCount'] ?? 0,
    );
  }
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  late Box<dynamic> _cacheBox;
  late Box<dynamic> _productsBox;
  late Box<dynamic> _clientsBox;
  late Box<dynamic> _quotesBox;
  late Box<dynamic> _cartBox;
  late Box<dynamic> _pendingOperationsBox;

  final _connectivity = Connectivity();
  final _connectivityController = StreamController<bool>.broadcast();
  bool _isOnline = true;

  final List<PendingOperation> _pendingOperations = [];
  final _queueController = StreamController<List<PendingOperation>>.broadcast();

  Stream<bool> get connectionStream => _connectivityController.stream;
  Stream<List<PendingOperation>> get queueStream => _queueController.stream;
  List<PendingOperation> get pendingOperations => _pendingOperations;

  bool get isOnline => _isOnline;

  SyncStatus _syncStatus = SyncStatus.idle;
  SyncStatus get syncStatus => _syncStatus;

  Future<void> initialize() async {
    _cacheBox = await Hive.openBox('cache');
    _productsBox = await Hive.openBox('products');
    _clientsBox = await Hive.openBox('clients');
    _quotesBox = await Hive.openBox('quotes');
    _cartBox = await Hive.openBox('cart');
    _pendingOperationsBox = await Hive.openBox('pendingOperations');

    // Load pending operations
    await _loadPendingOperations();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      _connectivityController.add(_isOnline);

      if (_isOnline && wasOffline) {
        syncPendingChanges();
      }
    });

    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline =
        connectivityResult.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _loadPendingOperations() async {
    final operations = _pendingOperationsBox.values.toList();
    _pendingOperations.clear();
    for (var op in operations) {
      _pendingOperations
          .add(PendingOperation.fromMap(Map<String, dynamic>.from(op)));
    }
    _queueController.add(_pendingOperations);
  }

  // Products
  Future<void> saveProduct(Product product) async {
    await _productsBox.put(product.id, product.toMap());
  }

  List<Product> getProducts() {
    return _productsBox.keys.map((key) {
      final data = _productsBox.get(key);
      return Product.fromMap(Map<String, dynamic>.from(data));
    }).toList();
  }

  // Clients
  Future<void> saveClient(Client client) async {
    await _clientsBox.put(client.id, client.toMap());
  }

  List<Client> getClients() {
    return _clientsBox.keys.map((key) {
      final data = _clientsBox.get(key);
      return Client.fromMap(Map<String, dynamic>.from(data));
    }).toList();
  }

  // Quotes
  Future<void> saveQuote(Quote quote) async {
    await _quotesBox.put(quote.id, quote.toMap());
  }

  List<Quote> getQuotes() {
    return _quotesBox.keys.map((key) {
      final data = _quotesBox.get(key);
      return Quote.fromMap(Map<String, dynamic>.from(data));
    }).toList();
  }

  // Cart
  Future<void> saveCart(List<CartItem> items) async {
    await _cartBox.clear();
    for (var item in items) {
      await _cartBox.put(item.productId, item.toMap());
    }
  }

  List<CartItem> getCart() {
    return _cartBox.keys.map((key) {
      final data = _cartBox.get(key);
      return CartItem.fromMap(Map<String, dynamic>.from(data));
    }).toList();
  }

  // Sync methods
  Future<void> syncPendingChanges() async {
    if (!_isOnline || _pendingOperations.isEmpty) return;

    _syncStatus = SyncStatus.syncing;

    for (var operation in List.from(_pendingOperations)) {
      try {
        // Here you would sync with Firebase/Supabase
        // For now, just remove from queue
        _pendingOperations.remove(operation);
        await _pendingOperationsBox.delete(operation.id);
      } catch (e) {
        operation.retryCount++;
        if (operation.retryCount > 3) {
          _pendingOperations.remove(operation);
          await _pendingOperationsBox.delete(operation.id);
        }
      }
    }

    _syncStatus = SyncStatus.success;
    _queueController.add(_pendingOperations);
  }

  Future<void> syncWithFirebase() async {
    // Sync implementation
    await syncPendingChanges();
  }

  Future<bool> hasOfflineData() async {
    return _pendingOperations.isNotEmpty;
  }

  Future<int> getSyncQueueCount() async {
    return _pendingOperations.length;
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    return {
      'products': _productsBox.length,
      'clients': _clientsBox.length,
      'quotes': _quotesBox.length,
      'cart': _cartBox.length,
      'pending': _pendingOperations.length,
    };
  }

  Future<void> clearAll() async {
    await _cacheBox.clear();
    await _productsBox.clear();
    await _clientsBox.clear();
    await _quotesBox.clear();
    await _cartBox.clear();
    _pendingOperations.clear();
    _queueController.add(_pendingOperations);
  }

  Future<void> dispose() async {
    await _connectivityController.close();
    await _queueController.close();
    await _cacheBox.close();
    await _productsBox.close();
    await _clientsBox.close();
    await _quotesBox.close();
    await _cartBox.close();
  }
}
