# Turbo Air Equipment Viewer - Flutter Application

A cross-platform B2B equipment catalog and quote management system built with Flutter and Firebase, featuring offline-first architecture and real-time synchronization.

## 🚀 Features

- **Multi-Platform Support**: iOS, Android, Web, Windows, macOS
- **Offline-First Architecture**: Full functionality without internet
- **Secure Authentication**: Firebase Auth with role-based access (Admin, Sales, Distributor)
- **Real-time Database**: Firebase Realtime Database with automatic sync
- **Quote Management**: Create, edit, and export quotes as PDF/Excel
- **Email Integration**: Professional quote emails via Gmail SMTP
- **Excel Import**: Super admin can bulk import products via Excel
- **Advanced Search**: Real-time product search with category filtering
- **Client Management**: Complete CRM for managing clients and quotes
- **Persistent Cart**: Shopping cart syncs across devices

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.x**: Cross-platform UI framework
- **Riverpod**: State management solution
- **Hive**: Local database for offline support
- **Go Router**: Navigation and routing

### Backend Services
- **Firebase Realtime Database**: NoSQL cloud database with real-time sync
- **Firebase Authentication**: Secure user authentication
- **Firebase Storage**: Product images and documents
- **Gmail SMTP**: Email service for quotes

### Deployment
- **Vercel**: Web deployment platform
- **GitHub Actions**: CI/CD pipeline (optional)

## 📁 Project Structure

```
lib/
├── main.dart                         # App entry point with Firebase init
├── app.dart                          # Main application widget
├── firebase_options.dart             # Firebase configuration (git-ignored)
├── core/
│   ├── config/
│   │   ├── env_config.dart          # Environment variables access
│   │   └── secure_email_config.dart # Secure email configuration
│   ├── theme/
│   │   └── app_theme.dart           # Material theme definitions
│   ├── router/
│   │   └── app_router.dart          # Navigation configuration
│   ├── services/
│   │   ├── realtime_database_service.dart  # Database operations
│   │   ├── offline_service.dart            # Offline data management
│   │   ├── firebase_auth_service.dart      # Auth wrapper
│   │   ├── email_service.dart              # Email functionality
│   │   ├── export_service.dart             # PDF/Excel export
│   │   ├── excel_upload_service.dart       # Excel import for admin
│   │   └── logging_service.dart            # Centralized logging
│   └── widgets/
│       └── offline_status_widget.dart      # Connection indicator
├── features/
│   ├── auth/                        # Login/Register screens
│   ├── products/                    # Product catalog & details
│   ├── clients/                     # Client management
│   ├── cart/                        # Shopping cart
│   ├── quotes/                      # Quote creation & management
│   ├── admin/                       # Admin panel
│   └── profile/                     # User profile
└── assets/
    └── screenshots/                  # Product images by SKU
```

## 🔐 Security Configuration

### Environment Variables
Create a `.env` file in the project root (never commit this):

```env
# Admin Credentials
ADMIN_EMAIL=andres@turboairmexico.com
ADMIN_PASSWORD=your_secure_password

# Firebase Configuration
FIREBASE_PROJECT_ID=turbo-air-viewer
FIREBASE_DATABASE_URL=https://turbo-air-viewer-default-rtdb.firebaseio.com
FIREBASE_API_KEY_WEB=your_web_api_key
FIREBASE_AUTH_DOMAIN=turbo-air-viewer.firebaseapp.com
FIREBASE_STORAGE_BUCKET=turbo-air-viewer.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID_WEB=your_web_app_id

# Email Service
EMAIL_SENDER_ADDRESS=turboairquotes@gmail.com
EMAIL_APP_PASSWORD=your_app_specific_password
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
```

### Security Features
- All sensitive data in environment variables
- Comprehensive `.gitignore` preventing credential leaks
- Firebase security rules for data access control
- Role-based permissions (Admin, Sales, Distributor)
- Secure email configuration with app-specific passwords

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK 3.0+
- Firebase CLI
- Node.js (for Vercel deployment)
- Git

### Local Development

1. **Clone the repository**
```bash
git clone https://github.com/REDXICAN/Turbo-Air-Viewer-Flutter-App.git
cd Turbo-Air-Viewer-Flutter-App
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Set up environment variables**
- Copy `.env.example` to `.env`
- Fill in your Firebase and email credentials

4. **Run the application**
```bash
# Web
flutter run -d chrome

# iOS
flutter run -d ios

# Android
flutter run -d android

# Windows
flutter run -d windows

# Or use the PowerShell script
./run_local.ps1
```

## 🌐 Deployment

### Vercel Deployment (Web)

1. **Push to GitHub**
```bash
git add .
git commit -m "Ready for deployment"
git push origin main
```

2. **Deploy on Vercel**
- Go to https://vercel.com/new
- Import your GitHub repository
- Vercel will auto-detect Flutter configuration
- Add environment variables in Vercel dashboard
- Deploy!

### Build Commands

**Web**
```bash
flutter build web --release
```

**Android**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

**Windows**
```bash
flutter build windows --release
```

## 📊 Database Schema

### Realtime Database Structure
```json
{
  "products": {
    "$productId": {
      "sku": "string",
      "category": "string",
      "description": "string",
      "price": "number"
    }
  },
  "clients": {
    "$clientId": {
      "company": "string",
      "email": "string"
    }
  },
  "quotes": {
    "$quoteId": {
      "client_id": "string",
      "items": [],
      "total": "number"
    }
  }
}
```

## 🔧 Key Features

### Offline-First Architecture
- Local caching with Hive
- Automatic sync when online
- Conflict resolution with timestamps
- Queue system for offline operations

### Super Admin Features
- Excel bulk import for products
- User management
- System configuration
- Access: andres@turboairmexico.com

### Real-time Synchronization
- Live updates across devices
- Automatic reconnection handling
- Optimistic UI updates

## 📱 Platform-Specific Notes

### Web
- Deployed on Vercel
- HTML renderer for better compatibility
- Responsive design for all screen sizes

### Mobile (iOS/Android)
- Native performance
- Platform-specific UI adaptations
- Push notifications ready

### Desktop (Windows/macOS)
- Full feature parity
- Native file system access
- Keyboard shortcuts

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter test integration_test
```

## 🐛 Troubleshooting

### Common Issues

1. **Build fails on Vercel**
   - Check `vercel.json` configuration
   - Ensure environment variables are set

2. **Firebase connection issues**
   - Verify `.env` file configuration
   - Check Firebase project settings

3. **Offline sync not working**
   - Clear Hive cache: Delete app data
   - Check network permissions

4. **Email sending fails**
   - Verify Gmail app-specific password
   - Check SMTP settings

## 📧 Support

For technical support:
- Email: turboairquotes@gmail.com
- GitHub Issues: [Create Issue](https://github.com/REDXICAN/Turbo-Air-Viewer-Flutter-App/issues)

## 📜 License

Proprietary software owned by Turbo Air Inc. All rights reserved.

## ✅ Recent Updates

- **Security Hardening**: All credentials moved to environment variables
- **Excel Import**: Super admin can bulk import products
- **Logging System**: Comprehensive logging with logger package
- **Preview Feature**: Excel upload preview before database commit
- **Vercel Ready**: Full deployment configuration for Vercel
- **Production Ready**: Complete security audit passed