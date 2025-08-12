// lib/core/utils/performance_monitor.dart
import 'package:flutter/foundation.dart';
import '../services/logging_service.dart';

class PerformanceMonitor {
  static final Map<String, DateTime> _operations = {};
  static final Map<String, List<int>> _metrics = {};

  /// Start monitoring an operation
  static void startOperation(String operationName) {
    _operations[operationName] = DateTime.now();
    
    if (kDebugMode) {
      logger.debug('Started operation: $operationName', 
        category: LogCategory.performance);
    }
  }

  /// End monitoring an operation and log the duration
  static Duration? endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final startTime = _operations.remove(operationName);
    
    if (startTime == null) {
      logger.warning('Attempted to end non-existent operation: $operationName',
        category: LogCategory.performance);
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    
    // Track metrics
    _metrics[operationName] ??= [];
    _metrics[operationName]!.add(duration.inMilliseconds);
    
    // Log performance
    logger.logPerformance(operationName, duration, metadata: metadata);
    
    // Alert on slow operations
    if (duration.inMilliseconds > 3000) {
      logger.warning(
        'Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
        category: LogCategory.performance,
        metadata: {
          'operation': operationName,
          'duration_ms': duration.inMilliseconds,
          'threshold_ms': 3000,
          ...?metadata,
        },
      );
    }
    
    return duration;
  }

  /// Measure async operation
  static Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    startOperation(operationName);
    
    try {
      final result = await operation();
      endOperation(operationName, metadata: metadata);
      return result;
    } catch (e, stackTrace) {
      endOperation(operationName, metadata: {
        ...?metadata,
        'error': e.toString(),
      });
      
      logger.error(
        'Operation "$operationName" failed: $e',
        category: LogCategory.performance,
        metadata: metadata,
        stackTrace: stackTrace,
      );
      
      rethrow;
    }
  }

  /// Measure sync operation
  static T measureSync<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? metadata,
  }) {
    startOperation(operationName);
    
    try {
      final result = operation();
      endOperation(operationName, metadata: metadata);
      return result;
    } catch (e, stackTrace) {
      endOperation(operationName, metadata: {
        ...?metadata,
        'error': e.toString(),
      });
      
      logger.error(
        'Operation "$operationName" failed: $e',
        category: LogCategory.performance,
        metadata: metadata,
        stackTrace: stackTrace,
      );
      
      rethrow;
    }
  }

  /// Get average duration for an operation
  static double? getAverageDuration(String operationName) {
    final metrics = _metrics[operationName];
    if (metrics == null || metrics.isEmpty) return null;
    
    final sum = metrics.reduce((a, b) => a + b);
    return sum / metrics.length;
  }

  /// Get metrics summary
  static Map<String, dynamic> getMetricsSummary(String operationName) {
    final metrics = _metrics[operationName];
    if (metrics == null || metrics.isEmpty) {
      return {'error': 'No metrics found for $operationName'};
    }
    
    metrics.sort();
    final sum = metrics.reduce((a, b) => a + b);
    final avg = sum / metrics.length;
    final median = metrics[metrics.length ~/ 2];
    final min = metrics.first;
    final max = metrics.last;
    
    return {
      'operation': operationName,
      'count': metrics.length,
      'average_ms': avg.toStringAsFixed(2),
      'median_ms': median,
      'min_ms': min,
      'max_ms': max,
      'total_ms': sum,
    };
  }

  /// Clear metrics for an operation
  static void clearMetrics([String? operationName]) {
    if (operationName != null) {
      _metrics.remove(operationName);
    } else {
      _metrics.clear();
    }
  }

  /// Log all metrics summaries
  static void logAllMetrics() {
    if (_metrics.isEmpty) {
      logger.info('No performance metrics to report', 
        category: LogCategory.performance);
      return;
    }
    
    final allMetrics = <String, dynamic>{};
    for (final operation in _metrics.keys) {
      allMetrics[operation] = getMetricsSummary(operation);
    }
    
    logger.info(
      'Performance metrics summary',
      category: LogCategory.performance,
      metadata: allMetrics,
    );
  }
}