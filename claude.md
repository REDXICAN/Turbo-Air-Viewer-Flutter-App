# Turbo Air Equipment Viewer - Technical Documentation

## 🚀 Project Overview
Production-ready B2B equipment catalog with Flutter + Firebase, featuring offline-first architecture, real-time sync, and enterprise security.

## 🛠️ Technology Stack

### Core Technologies
- **Flutter 3.x** - Cross-platform framework
- **Firebase Realtime Database** - NoSQL with real-time sync
- **Firebase Auth** - Secure authentication
- **Riverpod** - State management
- **Hive** - Offline storage
- **Go Router** - Navigation
- **Logger** - Comprehensive logging

### Deployment
- **Vercel** - Web hosting
- **GitHub** - Version control
- **Environment Variables** - Secure configuration

## 📁 Project Structure

```
lib/
├── main.dart                    # Firebase init + dotenv
├── core/
│   ├── config/
│   │   ├── env_config.dart     # Environment variables
│   │   └── secure_email_config.dart # Email settings
│   ├── services/
│   │   ├── realtime_database_service.dart
│   │   ├── offline_service.dart
│   │   ├── firebase_auth_service.dart
│   │   ├── email_service.dart
│   │   ├── export_service.dart
│   │   ├── excel_upload_service.dart
│   │   └── logging_service.dart
│   └── widgets/
├── features/
│   ├── auth/
│   ├── products/
│   ├── clients/
│   ├── cart/
│   ├── quotes/
│   ├── admin/
│   └── profile/
└── assets/
    └── screenshots/             # Product images by SKU
```

## 🔐 Security Configuration

### Environment Variables (.env)
```env
ADMIN_EMAIL=andres@turboairmexico.com
ADMIN_PASSWORD=[secure_password]
FIREBASE_PROJECT_ID=turbo-air-viewer
FIREBASE_DATABASE_URL=https://turbo-air-viewer-default-rtdb.firebaseio.com
EMAIL_SENDER_ADDRESS=turboairquotes@gmail.com
EMAIL_APP_PASSWORD=[app_password]
```

### Security Features
- ✅ All credentials in environment variables
- ✅ Comprehensive .gitignore
- ✅ Role-based access (Admin/Sales/Distributor)
- ✅ Firebase security rules
- ✅ Production-grade logging

## 📊 Database Schema

```json
{
  "products": { "sku", "category", "price", "image_url" },
  "clients": { "company", "email", "phone" },
  "quotes": { "client_id", "items[]", "total", "status" },
  "cart_items": { "product_id", "quantity", "price" },
  "user_profiles": { "email", "role", "display_name" }
}
```

## 🔧 Key Features

### Super Admin (andres@turboairmexico.com)
- Excel bulk import with preview
- User management
- System configuration
- Full database access

### Offline-First Architecture
- Hive local storage
- Sync queue for offline ops
- Automatic reconnection
- Conflict resolution

### Excel Import System
```dart
// Preview before import
final preview = await ExcelUploadService.previewExcel(file);
// Confirm and save
await ExcelUploadService.saveProducts(products, clearExisting);
```

### Logging System
- Multi-level (Debug/Info/Warning/Error/Critical)
- Category-based (Auth/Database/UI/Network)
- Console + Firebase output
- Production monitoring ready

## 🚀 Deployment

### Vercel Configuration
```json
{
  "buildCommand": "flutter build web --release",
  "installCommand": "git clone https://github.com/flutter/flutter.git -b stable && export PATH=\"$PATH:$PWD/flutter/bin\" && flutter pub get",
  "outputDirectory": "build/web"
}
```

### Build Script (build.sh)
```bash
#!/bin/bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$PWD/flutter/bin"
flutter pub get
flutter build web --release --web-renderer html
```

## ⚡ Quick Commands

```bash
# Local development
flutter run -d chrome

# Build for production
flutter build web --release

# Stage changes for commit
git add -A

# Commit changes (manually)
git commit -m "Your commit message"

# Push to GitHub (requires manual confirmation)
git push origin main

# Deploy to Vercel
vercel --prod

# Check logs
flutter logs
```

## 📋 Recent Updates

- ✅ **Security Hardening**: All sensitive data in .env
- ✅ **Excel Import**: Bulk upload with preview
- ✅ **Logging Framework**: Comprehensive monitoring
- ✅ **Vercel Ready**: Full deployment configuration
- ✅ **Production Security**: Complete audit passed

## 🐛 Known Issues

### File Picker Warning
Non-critical warning about file_picker plugin implementation. Does not affect functionality.

### Vercel Build
Ensure Flutter is installed via install command in vercel.json.

## 📧 Support

- **Admin**: andres@turboairmexico.com
- **Support**: turboairquotes@gmail.com
- **GitHub**: [Repository](https://github.com/REDXICAN/Turbo-Air-Viewer-Flutter-App)

## ✅ Production Checklist

- [x] Environment variables configured
- [x] .gitignore comprehensive
- [x] Firebase security rules
- [x] Logging system active
- [x] Excel import tested
- [x] Vercel deployment ready
- [x] Admin user configured
- [x] Email service working