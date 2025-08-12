// lib/core/services/offline_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';

class OfflineService {
  static const String _offlineQueueBox = 'offline_queue';
  static const String _cacheBox = 'cache_data';
  static const String _productsBox = 'products_cache';
  static const String _clientsBox = 'clients_cache';
  static const String _quotesBox = 'quotes_cache';
  static const String _cartBox = 'cart_cache';

  static late Box _queueBox;
  static late Box _cacheBox;
  static late Box _productsBox;
  static late Box _clientsBox;
  static late Box _quotesBox;
  static late Box _cartBox;

  static StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  static Stream<bool> get connectivityStream => _connectivityController.stream;

  static bool _isOnline = true;
  static bool get isOnline => _isOnline;

  // Initialize Hive and open boxes
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Open boxes
    _queueBox = await Hive.openBox(_offlineQueueBox);
    _cacheBox = await Hive.openBox(_cacheBox);
    _productsBox = await Hive.openBox(_productsBox);
    _clientsBox = await Hive.openBox(_clientsBox);
    _quotesBox = await Hive.openBox(_quotesBox);
    _cartBox = await Hive.openBox(_cartBox);

    // Monitor connectivity
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      _connectivityController.add(_isOnline);

      if (_isOnline) {
        _processPendingQueue();
      }
    });

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = !connectivityResult.contains(ConnectivityResult.none);
  }

  // Queue operations for offline sync
  static Future<void> queueOperation({
    required String type,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final queueItem = {
      'id': '${type}_${DateTime.now().millisecondsSinceEpoch}',
      'type': type,
      'operation': operation,
      'data': data,
      'timestamp': timestamp,
      'retryCount': 0,
    };

    await _queueBox.add(queueItem);
  }

  // Process pending queue when online
  static Future<void> _processPendingQueue() async {
    if (!_isOnline || _queueBox.isEmpty) return;

    final List<int> keysToRemove = [];

    for (int i = 0; i < _queueBox.length; i++) {
      final item = _queueBox.getAt(i);
      if (item != null) {
        try {
          await _processQueueItem(item);
          keysToRemove.add(i);
        } catch (e) {
          // Increment retry count
          item['retryCount'] = (item['retryCount'] ?? 0) + 1;

          // Remove if too many retries
          if (item['retryCount'] > 3) {
            keysToRemove.add(i);
          } else {
            await _queueBox.putAt(i, item);
          }
        }
      }
    }

    // Remove processed items (in reverse order to maintain indices)
    for (int key in keysToRemove.reversed) {
      await _queueBox.deleteAt(key);
    }
  }

  // Process individual queue item
  static Future<void> _processQueueItem(Map<dynamic, dynamic> item) async {
    final type = item['type'];
    final operation = item['operation'];
    final data = Map<String, dynamic>.from(item['data']);

    // Process based on type and operation
    // This would integrate with your RealtimeDatabaseService
    switch (type) {
      case 'client':
        await _processClientOperation(operation, data);
        break;
      case 'cart':
        await _processCartOperation(operation, data);
        break;
      case 'quote':
        await _processQuoteOperation(operation, data);
        break;
    }
  }

  static Future<void> _processClientOperation(
      String operation, Map<String, dynamic> data) async {
    // Implement client sync operations
    // This would call your RealtimeDatabaseService methods
  }

  static Future<void> _processCartOperation(
      String operation, Map<String, dynamic> data) async {
    // Implement cart sync operations
  }

  static Future<void> _processQuoteOperation(
      String operation, Map<String, dynamic> data) async {
    // Implement quote sync operations
  }

  // Cache management methods
  static Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    for (final product in products) {
      await _productsBox.put(product['id'], jsonEncode(product));
    }
  }

  static List<Map<String, dynamic>> getCachedProducts() {
    final List<Map<String, dynamic>> products = [];
    for (final key in _productsBox.keys) {
      final productJson = _productsBox.get(key);
      if (productJson != null) {
        products.add(Map<String, dynamic>.from(jsonDecode(productJson)));
      }
    }
    return products;
  }

  static Future<void> cacheClients(List<Map<String, dynamic>> clients) async {
    for (final client in clients) {
      await _clientsBox.put(client['id'], jsonEncode(client));
    }
  }

  static List<Map<String, dynamic>> getCachedClients() {
    final List<Map<String, dynamic>> clients = [];
    for (final key in _clientsBox.keys) {
      final clientJson = _clientsBox.get(key);
      if (clientJson != null) {
        clients.add(Map<String, dynamic>.from(jsonDecode(clientJson)));
      }
    }
    return clients;
  }

  static Future<void> cacheQuotes(List<Map<String, dynamic>> quotes) async {
    for (final quote in quotes) {
      await _quotesBox.put(quote['id'], jsonEncode(quote));
    }
  }

  static List<Map<String, dynamic>> getCachedQuotes() {
    final List<Map<String, dynamic>> quotes = [];
    for (final key in _quotesBox.keys) {
      final quoteJson = _quotesBox.get(key);
      if (quoteJson != null) {
        quotes.add(Map<String, dynamic>.from(jsonDecode(quoteJson)));
      }
    }
    return quotes;
  }

  static Future<void> cacheCartItems(List<Map<String, dynamic>> items) async {
    await _cartBox.clear();
    for (int i = 0; i < items.length; i++) {
      await _cartBox.put(i, jsonEncode(items[i]));
    }
  }

  static List<Map<String, dynamic>> getCachedCartItems() {
    final List<Map<String, dynamic>> items = [];
    for (final key in _cartBox.keys) {
      final itemJson = _cartBox.get(key);
      if (itemJson != null) {
        items.add(Map<String, dynamic>.from(jsonDecode(itemJson)));
      }
    }
    return items;
  }

  // Clear all caches
  static Future<void> clearCache() async {
    await _cacheBox.clear();
    await _productsBox.clear();
    await _clientsBox.clear();
    await _quotesBox.clear();
    await _cartBox.clear();
  }

  // Clear offline queue
  static Future<void> clearQueue() async {
    await _queueBox.clear();
  }

  // Get pending operations count
  static int getPendingOperationsCount() {
    return _queueBox.length;
  }

  // Sync all data
  static Future<void> syncAll() async {
    if (_isOnline) {
      await _processPendingQueue();
    }
  }

  // Close all boxes
  static Future<void> dispose() async {
    await _queueBox.close();
    await _cacheBox.close();
    await _productsBox.close();
    await _clientsBox.close();
    await _quotesBox.close();
    await _cartBox.close();
    _connectivityController.close();
  }
}
