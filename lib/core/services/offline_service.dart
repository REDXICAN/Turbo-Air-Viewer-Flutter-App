import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class OfflineService {
  static const String productsBox = 'products';
  static const String clientsBox = 'clients';
  static const String quotesBox = 'quotes';
  static const String cartBox = 'cart';
  static const String syncQueueBox = 'sync_queue';
  static const String searchHistoryBox = 'search_history';

  static const _uuid = Uuid();
  static final _supabase = Supabase.instance.client;

  /// Register all Hive adapters
  static Future<void> registerAdapters() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ClientAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(QuoteAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(QuoteItemAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(CartItemAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
  }

  /// Initialize offline storage
  static Future<void> initialize() async {
    // Open all boxes
    await Hive.openBox<Product>(productsBox);
    await Hive.openBox<Client>(clientsBox);
    await Hive.openBox<Quote>(quotesBox);
    await Hive.openBox<CartItem>(cartBox);
    await Hive.openBox<SyncQueueItem>(syncQueueBox);
    await Hive.openBox(searchHistoryBox);

    // Initial sync if online
    if (await isOnline()) {
      await syncAllData();
    }

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await syncPendingChanges();
      }
    });
  }

  /// Check if device is online
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Sync all data from Supabase
  static Future<void> syncAllData() async {
    try {
      // Sync products
      await syncProducts();

      // Sync user data
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await syncClients(userId);
        await syncQuotes(userId);
        await syncCart(userId);
      }
    } catch (e) {
      // Use debugPrint instead of print for production
      // print('Sync error: $e');
    }
  }

  /// Sync products from Supabase
  static Future<void> syncProducts() async {
    try {
      final response = await _supabase.from('products').select().order('sku');

      final productsBox =
          await Hive.openBox<Product>(OfflineService.productsBox);
      await productsBox.clear();

      for (final json in response as List) {
        final product = Product.fromJson(json);
        await productsBox.put(product.id, product);
      }
    } catch (e) {
      // Use debugPrint instead of print for production
      // print('Products sync error: $e');
    }
  }

  /// Sync clients from Supabase
  static Future<void> syncClients(String userId) async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .eq('user_id', userId)
          .order('company');

      final clientsBox = await Hive.openBox<Client>(OfflineService.clientsBox);

      for (final json in response as List) {
        final client = Client.fromJson(json);
        await clientsBox.put(client.id, client);
      }
    } catch (e) {
      // Use debugPrint instead of print for production
      // print('Clients sync error: $e');
    }
  }

  /// Sync quotes from Supabase
  static Future<void> syncQuotes(String userId) async {
    try {
      final response = await _supabase
          .from('quotes')
          .select('*, quote_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final quotesBox = await Hive.openBox<Quote>(OfflineService.quotesBox);

      for (final json in response as List) {
        final quote = Quote.fromJson(json);
        await quotesBox.put(quote.id, quote);
      }
    } catch (e) {
      // Use debugPrint instead of print for production
      // print('Quotes sync error: $e');
    }
  }

  /// Sync cart from Supabase
  static Future<void> syncCart(String userId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('*, products(*)')
          .eq('user_id', userId);

      final cartBox = await Hive.openBox<CartItem>(OfflineService.cartBox);
      await cartBox.clear();

      for (final json in response as List) {
        final cartItem = CartItem.fromJson(json);
        await cartBox.put(cartItem.id, cartItem);
      }
    } catch (e) {
      // Use debugPrint instead of print for production
      // print('Cart sync error: $e');
    }
  }

  /// Add item to sync queue for later syncing
  static Future<void> addToSyncQueue({
    required String tableName,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final syncBox = await Hive.openBox<SyncQueueItem>(syncQueueBox);

    final item = SyncQueueItem(
      id: _uuid.v4(),
      tableName: tableName,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );

    await syncBox.add(item);
  }

  /// Sync all pending changes
  static Future<void> syncPendingChanges() async {
    if (!await isOnline()) return;

    final syncBox = await Hive.openBox<SyncQueueItem>(syncQueueBox);
    final pendingItems = syncBox.values.where((item) => !item.synced).toList();

    for (final item in pendingItems) {
      try {
        await _syncItem(item);
        item.synced = true;
        await item.save();
      } catch (e) {
        // Use debugPrint instead of print for production
        // print('Failed to sync item: $e');
      }
    }

    // Clean up synced items
    final syncedItems = syncBox.values.where((item) => item.synced).toList();
    for (final item in syncedItems) {
      await item.delete();
    }
  }

  /// Sync individual queue item
  static Future<void> _syncItem(SyncQueueItem item) async {
    switch (item.operation) {
      case 'insert':
        await _supabase.from(item.tableName).insert(item.data);
        break;
      case 'update':
        final id = item.data['id'];
        final data = Map<String, dynamic>.from(item.data)..remove('id');
        await _supabase.from(item.tableName).update(data).eq('id', id);
        break;
      case 'delete':
        await _supabase.from(item.tableName).delete().eq('id', item.data['id']);
        break;
      case 'upsert':
        await _supabase.from(item.tableName).upsert(item.data);
        break;
    }
  }

  /// Save client offline
  static Future<Client> saveClientOffline(Client client) async {
    final clientsBox = await Hive.openBox<Client>(OfflineService.clientsBox);

    // Mark as not synced if offline
    if (!await isOnline()) {
      client.isSynced = false;

      // Add to sync queue
      await addToSyncQueue(
        tableName: 'clients',
        operation: client.id.startsWith('offline_') ? 'insert' : 'update',
        data: client.toJson(),
      );
    }

    await clientsBox.put(client.id, client);
    return client;
  }

  /// Save quote offline
  static Future<Quote> saveQuoteOffline(Quote quote) async {
    final quotesBox = await Hive.openBox<Quote>(OfflineService.quotesBox);

    // Mark as not synced if offline
    if (!await isOnline()) {
      quote.isSynced = false;

      // Add to sync queue
      await addToSyncQueue(
        tableName: 'quotes',
        operation: 'insert',
        data: quote.toJson(),
      );

      // Add quote items to sync queue
      for (final item in quote.items) {
        await addToSyncQueue(
          tableName: 'quote_items',
          operation: 'insert',
          data: item.toJson(),
        );
      }
    }

    await quotesBox.put(quote.id, quote);
    return quote;
  }

  /// Generate offline ID
  static String generateOfflineId() {
    return 'offline_${_uuid.v4()}';
  }

  /// Clear all offline data
  static Future<void> clearAllData() async {
    await Hive.deleteBoxFromDisk(productsBox);
    await Hive.deleteBoxFromDisk(clientsBox);
    await Hive.deleteBoxFromDisk(quotesBox);
    await Hive.deleteBoxFromDisk(cartBox);
    await Hive.deleteBoxFromDisk(syncQueueBox);
    await Hive.deleteBoxFromDisk(searchHistoryBox);
  }
}
