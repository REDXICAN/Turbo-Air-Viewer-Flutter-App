import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔧 Testing Firebase Realtime Database Connection...\n');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // Get database instance
    final database = FirebaseDatabase.instance;
    print('✅ Database instance obtained');
    
    // Test root access
    print('\n📊 Testing database access...');
    
    // Test reading products
    try {
      final productsSnapshot = await database.ref('products').limitToFirst(5).get();
      if (productsSnapshot.exists) {
        final data = productsSnapshot.value as Map?;
        print('✅ Products accessible: ${data?.length ?? 0} products found');
        if (data != null && data.isNotEmpty) {
          print('   Sample product: ${data.keys.first}');
        }
      } else {
        print('⚠️ Products node exists but is empty');
      }
    } catch (e) {
      print('❌ Cannot read products: $e');
    }
    
    // Test reading clients
    try {
      final clientsSnapshot = await database.ref('clients').limitToFirst(5).get();
      if (clientsSnapshot.exists) {
        print('✅ Clients accessible');
      } else {
        print('⚠️ Clients node empty or not accessible');
      }
    } catch (e) {
      print('❌ Cannot read clients: $e');
    }
    
    // Test reading quotes
    try {
      final quotesSnapshot = await database.ref('quotes').limitToFirst(5).get();
      if (quotesSnapshot.exists) {
        print('✅ Quotes accessible');
      } else {
        print('⚠️ Quotes node empty or not accessible');
      }
    } catch (e) {
      print('❌ Cannot read quotes: $e');
    }
    
    // Test database rules
    print('\n🔒 Database Security Rules Status:');
    print('   If you see permission errors above, update rules at:');
    print('   https://console.firebase.google.com/project/turbo-air-viewer/database/turbo-air-viewer-default-rtdb/rules');
    
    print('\n📝 Suggested rules for development:');
    print('''
{
  "rules": {
    ".read": true,
    ".write": "auth != null",
    "products": {
      ".read": true,
      ".write": "auth != null && auth.token.email == 'andres@turboairmexico.com'"
    },
    "clients": {
      "\$uid": {
        ".read": "auth != null && (auth.uid == \$uid || auth.token.email == 'andres@turboairmexico.com')",
        ".write": "auth != null && (auth.uid == \$uid || auth.token.email == 'andres@turboairmexico.com')"
      }
    },
    "quotes": {
      "\$uid": {
        ".read": "auth != null && (auth.uid == \$uid || auth.token.email == 'andres@turboairmexico.com')",
        ".write": "auth != null && (auth.uid == \$uid || auth.token.email == 'andres@turboairmexico.com')"
      }
    }
  }
}
    ''');
    
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
  }
}