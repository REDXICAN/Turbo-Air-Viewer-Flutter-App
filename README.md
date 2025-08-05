# Turbo Air Equipment Viewer - Flutter Version

A cross-platform B2B equipment catalog and quote management system built with Flutter, Supabase, and deployed on Vercel.

## Features

- 🌐 **Multi-Platform Support**: iOS, Android, macOS, Windows, and Web
- 📱 **Offline-First Architecture**: Full functionality without internet connection
- 🔐 **Secure Authentication**: Supabase Auth with role-based access control
- 📧 **Email Integration**: Professional quote emails via Supabase Edge Functions
- 📊 **Quote Management**: Create, edit, and export quotes as PDF/Excel
- 🔍 **Advanced Search**: Real-time product search with category filtering
- 👥 **Client Management**: Manage clients and their quotes
- 🛒 **Shopping Cart**: Persistent cart with automatic sync
- 📈 **Analytics Dashboard**: Track quotes, clients, and sales metrics

## Tech Stack

### Frontend
- **Flutter 3.x**: Cross-platform UI framework
- **Riverpod**: State management
- **Hive**: Local storage for offline support
- **Dio**: HTTP client with interceptors

### Backend
- **Supabase**: PostgreSQL database with real-time subscriptions
- **Supabase Auth**: Authentication and authorization
- **Supabase Edge Functions**: Serverless functions for email and processing
- **Supabase Storage**: Product images and documents

### Deployment
- **Vercel**: Web deployment with edge functions
- **GitHub Actions**: CI/CD pipeline
- **App Store / Google Play**: Mobile distribution

## Architecture

### Offline-First Strategy

The app uses a sophisticated offline-first architecture:

1. **Local Storage (Hive)**: All data is cached locally using Hive boxes
2. **Sync Queue**: Offline changes are queued and synced when online
3. **Conflict Resolution**: Last-write-wins with timestamp tracking
4. **Real-time Updates**: When online, uses Supabase real-time subscriptions

### Data Flow

```
User Action → Local Storage → Sync Queue → Supabase
                    ↓              ↓
              Immediate UI    Background Sync
```

## Setup Instructions

### Prerequisites

1. Flutter SDK (3.0 or later)
2. Dart SDK
3. Supabase account
4. Vercel account (for web deployment)

### Local Development

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/turbo-air-flutter.git
cd turbo-air-flutter
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Set up Supabase**
   - Create a new Supabase project
   - Run the SQL migrations from `supabase/migrations/`
   - Copy your Supabase URL and anon key

4. **Configure environment**
   - Update `lib/core/config/app_config.dart` with your Supabase credentials

5. **Run the app**
```bash
# For web
flutter run -d chrome

# For iOS (requires macOS)
flutter run -d ios

# For Android
flutter run -d android

# For desktop
flutter run -d macos  # or windows/linux
```

### Supabase Setup

1. **Create tables** - Run the following SQL in Supabase SQL editor:

```sql
-- Products table
CREATE TABLE products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sku TEXT UNIQUE NOT NULL,
    category TEXT,
    subcategory TEXT,
    product_type TEXT,
    description TEXT,
    price DECIMAL(10,2),
    -- ... other fields from schema
);

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Products are viewable by everyone" 
ON products FOR SELECT 
USING (true);

-- Repeat for other tables (clients, quotes, cart_items, etc.)
```

2. **Deploy Edge Functions**
```bash
supabase functions deploy send-email
supabase functions deploy sync-data
```

3. **Set up Storage buckets**
```bash
supabase storage create product-images
supabase storage create quote-documents
```

### Vercel Deployment

1. **Connect GitHub repository to Vercel**

2. **Configure build settings**:
   - Framework Preset: Other
   - Build Command: `flutter build web --release`
   - Output Directory: `build/web`

3. **Set environment variables** in Vercel dashboard:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

4. **Deploy**
```bash
vercel --prod
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Main app widget
├── core/
│   ├── config/              # App configuration
│   ├── theme/               # Theme definitions
│   ├── router/              # Navigation
│   ├── services/            # Core services
│   └── widgets/             # Shared widgets
├── features/
│   ├── auth/                # Authentication
│   ├── products/            # Product catalog
│   ├── clients/             # Client management
│   ├── cart/                # Shopping cart
│   ├── quotes/              # Quote management
│   └── profile/             # User profile
└── shared/
    ├── models/              # Data models
    ├── providers/           # Riverpod providers
    └── utils/               # Utility functions

supabase/
├── functions/
│   ├── send-email/          # Email sending function
│   └── sync-data/           # Data sync function
└── migrations/              # Database migrations

assets/
├── images/                  # App images
├── logos/                   # Company logos
└── screenshots/             # Product screenshots (CRT-77-1R-N, etc.)

## Key Features Implementation

### Authentication with Supabase Auth

Benefits over manual auth:
- **Security**: Industry-standard JWT tokens, secure password reset
- **Session Management**: Automatic token refresh, no manual handling
- **Multi-device**: Sessions persist across devices
- **Social Login Ready**: Easy to add Google, Apple, GitHub auth
- **Row Level Security**: Automatic data isolation per user
- **MFA Support**: Built-in multi-factor authentication

```dart
// Simple authentication with Supabase
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// Automatic session persistence
final user = supabase.auth.currentUser;
```

### Offline Synchronization

The app maintains full functionality offline:

```dart
// All operations work offline first
final client = await OfflineService.saveClientOffline(
  Client(
    id: OfflineService.generateOfflineId(),
    company: 'ACME Corp',
    // ...
  ),
);

// Automatic sync when online
Connectivity().onConnectivityChanged.listen((result) {
  if (result != ConnectivityResult.none) {
    OfflineService.syncPendingChanges();
  }
});
```

### Email via Edge Functions

Emails are sent server-side for security:

```dart
// Client-side call
await supabase.functions.invoke(
  'send-email',
  body: {
    'to': clientEmail,
    'quoteData': quote.toJson(),
    'attachPdf': true,
  },
);
```

### Real-time Updates

When online, see changes from other users instantly:

```dart
// Subscribe to real-time changes
supabase
  .from('quotes')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .listen((data) {
    // Update local cache
    updateQuotes(data);
  });
```

## Mobile App Distribution

### iOS Deployment

1. **Configure in Xcode**:
   - Open `ios/Runner.xcworkspace`
   - Set bundle identifier
   - Configure signing certificates

2. **Build and deploy**:
```bash
flutter build ios --release
# Upload via Xcode or Transporter
```

### Android Deployment

1. **Configure signing**:
   - Create keystore
   - Update `android/app/build.gradle`

2. **Build and deploy**:
```bash
flutter build appbundle --release
# Upload to Google Play Console
```

### Desktop Deployment

**macOS**:
```bash
flutter build macos --release
# Distribute via DMG or Mac App Store
```

**Windows**:
```bash
flutter build windows --release
# Create installer with Inno Setup or MSIX
```

## API Migration from Python

### Authentication
- **Python**: Manual JWT tokens with SQLite
- **Flutter**: Supabase Auth with automatic session management

### Database
- **Python**: SQLite with manual sync
- **Flutter**: Hive for local storage + Supabase for cloud

### Email
- **Python**: Direct SMTP from client
- **Flutter**: Supabase Edge Functions (secure server-side)

### File Storage
- **Python**: Local file system
- **Flutter**: Supabase Storage with CDN

## Performance Optimizations

1. **Lazy Loading**: Products load on-demand with pagination
2. **Image Caching**: `CachedNetworkImage` for efficient image loading
3. **State Management**: Riverpod for efficient rebuilds
4. **Database Indexing**: Proper indexes on frequently queried fields
5. **Connection Pooling**: Reuse database connections

## Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test

# Widget tests
flutter test test/widgets

# Coverage report
flutter test --coverage
```

## Monitoring

- **Sentry**: Error tracking and performance monitoring
- **Firebase Analytics**: User behavior tracking
- **Supabase Dashboard**: Database metrics and logs

## Security

1. **Row Level Security (RLS)**: Database-level access control
2. **Environment Variables**: Sensitive data in environment files
3. **HTTPS Only**: All network requests over HTTPS
4. **Input Validation**: Client and server-side validation
5. **Rate Limiting**: API rate limits via Edge Functions

## Troubleshooting

### Common Issues

1. **Build fails on Vercel**
   - Ensure Flutter is in PATH
   - Check build command in `vercel.json`

2. **Offline sync not working**
   - Check Hive box initialization
   - Verify sync queue implementation

3. **Images not loading**
   - Verify asset paths
   - Check Supabase Storage policies

4. **Authentication errors**
   - Verify Supabase URL and anon key
   - Check RLS policies

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

This project is proprietary software owned by Turbo Air.

## Support

For support, email: turboairquotes@gmail.com

## Roadmap

- [ ] Advanced analytics dashboard
- [ ] Barcode scanning
- [ ] Voice search
- [ ] AR product preview
- [ ] Multi-language support
- [ ] Advanced reporting
- [ ] Integration with ERP systems
- [ ] Push notifications
- [ ] Offline PDF generation
- [ ] Custom pricing rules