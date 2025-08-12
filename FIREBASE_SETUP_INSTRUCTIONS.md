# Firebase Setup Instructions - Existing Databases Integration

## Your Current Setup
- **Realtime Database**: Contains products data
- **Firestore**: Contains user data
- **Super Admin**: andres@turboairmexico.com

## Step 1: Deploy Security Rules

### 1.1 Update Realtime Database Rules
1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project: `turbo-air-viewer`
3. Go to **Realtime Database** → **Rules**
4. Replace with these rules:

```json
{
  "rules": {
    "products": {
      ".read": true,
      ".write": "auth != null && (auth.token.email == 'andres@turboairmexico.com' || auth.token.admin == true)"
    },
    "clients": {
      "$uid": {
        ".read": "$uid === auth.uid || auth.token.email == 'andres@turboairmexico.com'",
        ".write": "$uid === auth.uid || auth.token.email == 'andres@turboairmexico.com'"
      }
    },
    "quotes": {
      "$uid": {
        ".read": "$uid === auth.uid || auth.token.email == 'andres@turboairmexico.com'",
        ".write": "$uid === auth.uid || auth.token.email == 'andres@turboairmexico.com'"
      }
    },
    "cart_items": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "app_settings": {
      ".read": true,
      ".write": "auth != null && auth.token.email == 'andres@turboairmexico.com'"
    }
  }
}
```

5. Click **Publish**

### 1.2 Update Firestore Rules
1. Go to **Firestore Database** → **Rules**
2. Replace with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && 
        (request.auth.uid == userId || request.auth.token.email == 'andres@turboairmexico.com');
      allow write: if request.auth != null && 
        (request.auth.uid == userId || request.auth.token.email == 'andres@turboairmexico.com');
    }
    
    // User profiles (if separate from users)
    match /user_profiles/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.auth.uid == userId || request.auth.token.email == 'andres@turboairmexico.com');
    }
  }
}
```

3. Click **Publish**

## Step 2: Deploy Rules via CLI (Alternative)

If you prefer using Firebase CLI:

```bash
# Deploy database rules
firebase deploy --only database

# Deploy firestore rules  
firebase deploy --only firestore
```

## Step 3: Initialize App Settings

Run this in Firebase Console → Realtime Database → Data:

1. Click on the root node
2. Add child: `app_settings`
3. Add these values:
```json
{
  "tax_rate": 0.0825,
  "currency": "USD",
  "site_name": "TurboAir Equipment Viewer",
  "updated_at": "2024-12-17T00:00:00Z"
}
```

## Step 4: Test the Application

### 4.1 Run the Application
```bash
cd "C:\Users\andre\Desktop\-- Flutter App"
flutter run -d chrome
```

### 4.2 Login as Super Admin
- Email: `andres@turboairmexico.com`
- Password: `andres123!@#`

### 4.3 Verify Functionality
✅ **Products** should load from Realtime Database  
✅ **User profile** should load from Firestore  
✅ **Cart** operations should work (user-specific)  
✅ **Clients** management (super admin sees all)  
✅ **Quotes** creation and viewing  

## Step 5: Data Structure Verification

### Realtime Database Structure
```
turbo-air-viewer/
├── products/              ← Your existing products
│   └── {productId}/
├── clients/
│   └── {userId}/          ← User-specific
│       └── {clientId}/
├── quotes/
│   └── {userId}/          ← User-specific
│       └── {quoteId}/
├── cart_items/
│   └── {userId}/          ← User-specific
│       └── {itemId}/
└── app_settings/          ← Global settings
```

### Firestore Structure
```
firestore/
├── users/                 ← Your existing users
│   └── {userId}/
│       ├── email
│       ├── displayName
│       ├── role
│       └── createdAt
```

## Troubleshooting

### Issue: Permission Denied Errors
- Ensure you're logged in with correct credentials
- Check that rules are published
- Verify email matches exactly: `andres@turboairmexico.com`

### Issue: Products Not Loading
- Check Realtime Database has products at path `/products`
- Verify products have required fields: `sku`, `category`, `description`, `price`

### Issue: User Profile Not Loading
- Check Firestore has user document at path `/users/{uid}`
- Verify user document has fields: `email`, `displayName`, `role`

### Issue: Duplicate Navigation
- Fixed in code - removed nested Scaffold
- Single navigation system now active

## Code Changes Made

1. **Created `HybridDatabaseService`** - Handles both databases
2. **Fixed Navigation** - Removed duplicate Scaffold in home_screen.dart
3. **Updated Auth Provider** - Added hybrid database provider
4. **Security Rules** - Configured for super admin access

## Super Admin Privileges

As `andres@turboairmexico.com`, you have:
- ✅ Read/write access to all products
- ✅ View all users' clients and quotes
- ✅ Modify app settings
- ✅ Admin panel access
- ✅ Full system visibility

## Next Steps

1. **Verify Products**: Check your existing products are visible
2. **Test User Creation**: Create a test distributor account
3. **Create Sample Data**: Add clients and quotes
4. **Test Cart**: Add products to cart and create quotes

## Support

If you encounter issues:
1. Check browser console for errors (F12)
2. Verify Firebase Console shows correct data
3. Ensure you're using the latest code with fixes