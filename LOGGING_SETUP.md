# Complete Logging Setup Documentation

## 🚀 Overview
A comprehensive logging system has been implemented for the Flutter app with Vercel deployment and GitHub CI/CD integration.

## 📋 Features

### 1. **Multi-Level Logging**
- **Debug**: Development information
- **Info**: General application events  
- **Warning**: Potential issues
- **Error**: Recoverable errors
- **Critical**: System failures requiring immediate attention

### 2. **Category-Based Logging**
- **Auth**: Authentication events
- **Database**: Database operations
- **UI**: User interface events
- **Network**: API calls and connectivity
- **Business**: Business logic events
- **Performance**: Performance metrics
- **Security**: Security-related events
- **General**: Miscellaneous logs

### 3. **Multi-Channel Output**
- **Console**: Color-coded debug output
- **Firebase**: Remote logging for production
- **Local Storage**: In-memory buffer for recent logs
- **Webhooks**: Discord/Slack notifications for critical errors
- **Vercel API**: Centralized logging endpoint

## 🔧 Setup Instructions

### 1. Environment Variables

Add these to your `.env` file:
```env
# Firebase
FIREBASE_PROJECT_ID=turbo-air-viewer
FIREBASE_DATABASE_URL=https://turbo-air-viewer-default-rtdb.firebaseio.com

# Webhooks (optional)
DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
SLACK_WEBHOOK=https://hooks.slack.com/services/...

# Vercel
VERCEL_ORG_ID=your-org-id
VERCEL_PROJECT_ID=your-project-id
VERCEL_TOKEN=your-token
```

### 2. GitHub Secrets

Add these secrets to your GitHub repository:
1. Go to Settings → Secrets and variables → Actions
2. Add:
   - `VERCEL_TOKEN`
   - `VERCEL_ORG_ID`
   - `VERCEL_PROJECT_ID`
   - `DISCORD_WEBHOOK` (optional)
   - `FIREBASE_API_KEY`
   - `SENTRY_DSN` (optional)

### 3. Vercel Configuration

1. Link your GitHub repository to Vercel
2. Set environment variables in Vercel dashboard:
   ```
   FIREBASE_PROJECT_ID
   FIREBASE_CLIENT_EMAIL
   FIREBASE_PRIVATE_KEY
   FIREBASE_DATABASE_URL
   DISCORD_WEBHOOK (optional)
   ```

### 4. Initialize in Your App

The logging is already initialized in `main.dart`:
```dart
await logger.initialize(
  environment: kDebugMode ? 'development' : 'production',
  enableRemoteLogging: !kDebugMode,
  enableConsoleLogging: kDebugMode,
  minLogLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
);
```

## 📝 Usage Examples

### Basic Logging
```dart
// Debug
logger.debug('User clicked button', metadata: {'button': 'submit'});

// Info
logger.info('User logged in', category: LogCategory.auth);

// Warning
logger.warning('API response slow', metadata: {'duration': '3000ms'});

// Error
logger.error('Failed to load data', stackTrace: stackTrace);

// Critical
logger.critical('Database connection lost', forceRemote: true);
```

### Performance Monitoring
```dart
// Async operation
final result = await PerformanceMonitor.measureAsync(
  'fetch_products',
  () => fetchProductsFromAPI(),
  metadata: {'category': 'electronics'},
);

// Sync operation
final data = PerformanceMonitor.measureSync(
  'process_data',
  () => processLargeDataset(items),
);

// Manual timing
PerformanceMonitor.startOperation('complex_calculation');
// ... do work ...
PerformanceMonitor.endOperation('complex_calculation');
```

### Error Handling
```dart
// Business error
ErrorHandler.handleBusinessError(
  'Failed to create quote',
  error: e,
  context: context,
  metadata: {'quoteId': quote.id},
);

// Network error
ErrorHandler.handleNetworkError(
  'product_fetch',
  error,
  context: context,
);

// Try-catch wrapper
final result = await ErrorHandler.tryAsync(
  () => dangerousOperation(),
  operationName: 'dangerous_operation',
  context: context,
);
```

### Auth Event Logging
```dart
logger.logAuthEvent('sign_in', 
  userId: user.uid,
  email: user.email,
  metadata: {'method': 'email'},
);
```

### Business Event Logging
```dart
logger.logBusinessEvent('quote_created',
  metadata: {
    'quoteId': quote.id,
    'value': quote.total,
    'items': quote.items.length,
  },
);
```

## 🔍 Viewing Logs

### 1. **Development Console**
Logs appear color-coded in debug console:
- Gray: Debug
- Cyan: Info
- Yellow: Warning
- Red: Error
- Magenta: Critical

### 2. **Firebase Console**
1. Go to Firebase Console → Realtime Database
2. Navigate to `logs/` node
3. Filter by environment, date, or level

### 3. **Vercel Dashboard**
1. Go to Vercel dashboard → Functions
2. View logs for `api/log` function
3. Check metrics and errors

### 4. **GitHub Actions**
1. Go to Actions tab in GitHub
2. Click on workflow run
3. View logs for each step

### 5. **Export Logs**
```dart
// Get recent logs
final logs = logger.getRecentLogs(
  minLevel: LogLevel.warning,
  category: LogCategory.database,
  limit: 50,
);

// Export as JSON
final json = logger.exportLogsAsJson();

// Export as CSV
final csv = logger.exportLogsAsCsv();
```

## 📊 Metrics & Analytics

### Performance Metrics
```dart
// Get average duration
final avg = PerformanceMonitor.getAverageDuration('api_call');

// Get full metrics
final metrics = PerformanceMonitor.getMetricsSummary('api_call');
// Returns: {count, average_ms, median_ms, min_ms, max_ms}

// Log all metrics
PerformanceMonitor.logAllMetrics();
```

### Daily Metrics (stored in Firebase)
```
/metrics/2024-01-15/
  ├── total: 1523
  ├── byLevel/
  │   ├── info: 1200
  │   ├── warning: 300
  │   └── error: 23
  └── byCategory/
      ├── auth: 150
      ├── database: 500
      └── ui: 873
```

## 🚨 Alerts & Notifications

### Discord Notifications
Critical errors automatically post to Discord:
```json
{
  "title": "🚨 CRITICAL Alert",
  "description": "Database connection lost",
  "fields": [
    {"name": "Environment", "value": "production"},
    {"name": "Category", "value": "database"},
    {"name": "User", "value": "user123"}
  ]
}
```

### Slack Notifications
Configure Slack webhook for team alerts.

## 🔐 Security Considerations

1. **Sensitive Data**: Never log passwords, tokens, or PII
2. **Rate Limiting**: Automatic throttling for excessive logging
3. **Access Control**: Logs restricted by Firebase security rules
4. **Encryption**: All logs transmitted over HTTPS
5. **Retention**: Old logs automatically deleted after 30 days

## 🎯 Best Practices

### Do's ✅
- Use appropriate log levels
- Include relevant metadata
- Log business events for analytics
- Monitor performance of critical operations
- Handle errors gracefully with context

### Don'ts ❌
- Log sensitive information
- Use console.log in production
- Ignore error handling
- Log excessively in loops
- Forget to add context to errors

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
1. **Test**: Run Flutter tests
2. **Build**: Create production build
3. **Deploy**: Push to Vercel
4. **Log**: Record deployment in Firebase
5. **Notify**: Send Discord/Slack notifications

### Deployment Tracking
Every deployment is logged with:
- Commit SHA
- Branch name
- Timestamp
- Deployment URL
- Author
- Commit message

## 📈 Monitoring Dashboard

Access monitoring at:
- **Vercel Analytics**: https://vercel.com/[your-project]/analytics
- **Firebase Console**: https://console.firebase.google.com
- **GitHub Insights**: Repository → Insights → Actions

## 🛠️ Troubleshooting

### Logs not appearing in Firebase
1. Check authentication
2. Verify security rules
3. Ensure network connectivity
4. Check log level threshold

### Performance issues
1. Reduce log verbosity in production
2. Use batching for multiple logs
3. Implement local caching
4. Adjust retention policies

### Missing notifications
1. Verify webhook URLs
2. Check webhook permissions
3. Test with curl command
4. Review webhook logs

## 📚 Additional Resources

- [Flutter Logging Best Practices](https://flutter.dev/docs/testing/errors)
- [Vercel Logging](https://vercel.com/docs/concepts/observability/logs)
- [Firebase Realtime Database](https://firebase.google.com/docs/database)
- [GitHub Actions](https://docs.github.com/en/actions)

## 🎉 Summary

You now have a production-ready logging system with:
- ✅ Multi-level, categorized logging
- ✅ Local and remote storage
- ✅ Performance monitoring
- ✅ Error tracking
- ✅ CI/CD integration
- ✅ Real-time notifications
- ✅ Analytics and metrics
- ✅ Security best practices

The system automatically scales with your app and provides comprehensive insights into application behavior, performance, and errors.