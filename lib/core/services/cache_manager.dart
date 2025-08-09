// lib/core/services/cache_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache configuration
  static const Map<CacheType, Duration> cacheDurations = {
    CacheType.active: Duration(days: 7),
    CacheType.reference: Duration(days: 30),
  };

  static const Map<String, CacheType> collectionTypes = {
    'quotes': CacheType.active,
    'cart_items': CacheType.active,
    'clients': CacheType.active,
    'products': CacheType.reference,
    'categories': CacheType.reference,
    'settings': CacheType.reference,
  };

  /// Mark document as cached with appropriate expiration
  static Future<void> markAsCached(
    String collection,
    String documentId,
  ) async {
    final cacheType = collectionTypes[collection] ?? CacheType.active;
    final expirationDate = DateTime.now().add(cacheDurations[cacheType]!);

    await _firestore.collection(collection).doc(documentId).update({
      'cached_at': FieldValue.serverTimestamp(),
      'cache_expires_at': Timestamp.fromDate(expirationDate),
      'cache_type': cacheType.toString(),
    });
  }

  /// Check if a document is still within cache validity
  static Future<bool> isCacheValid(
    String collection,
    String documentId,
  ) async {
    try {
      final doc = await _firestore
          .collection(collection)
          .doc(documentId)
          .get(const GetOptions(source: Source.cache));

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final expiresAt = data['cache_expires_at'] as Timestamp?;
      if (expiresAt == null) return false;

      return expiresAt.toDate().isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Refresh cache for a collection
  static Future<void> refreshCollection(
    String collection, {
    String? userId,
    Map<String, dynamic>? queryFilters,
  }) async {
    Query query = _firestore.collection(collection);

    if (userId != null) {
      query = query.where('user_id', isEqualTo: userId);
    }

    if (queryFilters != null) {
      queryFilters.forEach((field, value) {
        query = query.where(field, isEqualTo: value);
      });
    }

    final snapshot = await query.get(const GetOptions(source: Source.server));
    final cacheType = collectionTypes[collection] ?? CacheType.active;
    final expirationDate = DateTime.now().add(cacheDurations[cacheType]!);

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'cached_at': FieldValue.serverTimestamp(),
        'cache_expires_at': Timestamp.fromDate(expirationDate),
        'cache_type': cacheType.toString(),
      });
    }

    await batch.commit();

    // Update cache metadata
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cache_refresh_$collection',
      DateTime.now().toIso8601String(),
    );
  }

  /// Get cache statistics for a collection
  static Future<CacheStats> getCollectionCacheStats(String collection) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRefresh = prefs.getString('cache_refresh_$collection');

    // Count cached documents
    final cachedDocs = await _firestore
        .collection(collection)
        .where('cached_at', isNotEqualTo: null)
        .count()
        .get();

    // Count expired documents
    final expiredDocs = await _firestore
        .collection(collection)
        .where('cache_expires_at', isLessThan: Timestamp.now())
        .count()
        .get();

    return CacheStats(
      collection: collection,
      cachedCount: cachedDocs.count ?? 0,
      expiredCount: expiredDocs.count ?? 0,
      lastRefresh: lastRefresh != null ? DateTime.parse(lastRefresh) : null,
      cacheType: collectionTypes[collection] ?? CacheType.active,
      maxAge: cacheDurations[collectionTypes[collection] ?? CacheType.active]!,
    );
  }

  /// Clear expired cache entries
  static Future<int> clearExpiredCache() async {
    int clearedCount = 0;

    for (final collection in collectionTypes.keys) {
      try {
        final expiredDocs = await _firestore
            .collection(collection)
            .where('cache_expires_at', isLessThan: Timestamp.now())
            .get();

        for (final doc in expiredDocs.docs) {
          await doc.reference.delete();
          clearedCount++;
        }
      } catch (e) {
        // Use kDebugMode to conditionally print in debug mode only
        if (kDebugMode) {
          print('Error clearing expired cache for $collection: $e');
        }
      }
    }

    return clearedCount;
  }

  /// Force clear all cache
  static Future<void> clearAllCache() async {
    await _firestore.clearPersistence();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Preload critical data for offline use
  static Future<void> preloadCriticalData(String userId) async {
    // Preload active data collections
    for (final collection in collectionTypes.entries
        .where((e) => e.value == CacheType.active)
        .map((e) => e.key)) {
      await refreshCollection(collection, userId: userId);
    }

    // Preload reference data (less frequently updated)
    for (final collection in collectionTypes.entries
        .where((e) => e.value == CacheType.reference)
        .map((e) => e.key)) {
      // Check if reference data needs refresh (older than 7 days)
      final prefs = await SharedPreferences.getInstance();
      final lastRefresh = prefs.getString('cache_refresh_$collection');

      if (lastRefresh == null ||
          DateTime.parse(lastRefresh)
              .isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
        await refreshCollection(collection);
      }
    }
  }
}

/// Cache type enumeration
enum CacheType {
  active, // 7 days cache
  reference, // 30 days cache
}

/// Cache statistics model
class CacheStats {
  final String collection;
  final int cachedCount;
  final int expiredCount;
  final DateTime? lastRefresh;
  final CacheType cacheType;
  final Duration maxAge;

  CacheStats({
    required this.collection,
    required this.cachedCount,
    required this.expiredCount,
    this.lastRefresh,
    required this.cacheType,
    required this.maxAge,
  });

  int get validCount => cachedCount - expiredCount;

  double get cacheHealthPercentage {
    if (cachedCount == 0) return 0;
    return (validCount / cachedCount) * 100;
  }

  bool get needsRefresh {
    if (lastRefresh == null) return true;

    // Active data needs refresh after 1 day
    if (cacheType == CacheType.active) {
      return lastRefresh!
          .isBefore(DateTime.now().subtract(const Duration(days: 1)));
    }

    // Reference data needs refresh after 7 days
    return lastRefresh!
        .isBefore(DateTime.now().subtract(const Duration(days: 7)));
  }
}
