// lib/core/services/sample_data_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_logger.dart';

class SampleDataService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initializeSampleData() async {
    try {
      // Check if user is authenticated first
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.info('No authenticated user, skipping sample data initialization', category: LogCategory.database);
        return;
      }

      // Check if products exist (public read allowed)
      try {
        final productsSnapshot = await _db.ref('products').once();
        if (!productsSnapshot.snapshot.exists || 
            (productsSnapshot.snapshot.value as Map?)?.isEmpty == true) {
          await _addSampleProducts();
        }
      } catch (e) {
        AppLogger.warning('Could not check/add products', data: e.toString());
      }

      // Check if app settings exist (public read allowed)
      try {
        final settingsSnapshot = await _db.ref('app_settings').once();
        if (!settingsSnapshot.snapshot.exists) {
          await _addAppSettings();
        }
      } catch (e) {
        AppLogger.warning('Could not check/add app settings', data: e.toString());
      }

      // Only add sample data for demo accounts
      if (user.email?.startsWith('demo_') == true) {
        // Add sample clients for demo user
        try {
          final clientsSnapshot = await _db
              .ref('clients/${user.uid}')
              .once();
          
          if (!clientsSnapshot.snapshot.exists || 
              (clientsSnapshot.snapshot.value as Map?)?.isEmpty == true) {
            await _addSampleClients(user.uid);
          }
        } catch (e) {
          AppLogger.warning('Could not check/add sample clients', data: e.toString());
        }

        // Add sample quotes for demo user
        try {
          final quotesSnapshot = await _db
              .ref('quotes/${user.uid}')
              .once();
          
          if (!quotesSnapshot.snapshot.exists || 
              (quotesSnapshot.snapshot.value as Map?)?.isEmpty == true) {
            await _addSampleQuotes(user.uid);
          }
        } catch (e) {
          AppLogger.warning('Could not check/add sample quotes', data: e.toString());
        }
      }
    } catch (e) {
      AppLogger.error('Error initializing sample data', error: e, category: LogCategory.database);
    }
  }

  static Future<void> _addSampleProducts() async {
    final products = [
      {
        'sku': 'TST-72-30M-B-D4',
        'category': 'FOOD PREP TABLES',
        'subcategory': 'Mega Top Sandwich & Salad Units',
        'product_type': 'Refrigerated Counter',
        'description': '72" Mega Top Sandwich/Salad Unit with 4 Drawers',
        'price': 4599.00,
        'image_url': 'assets/screenshots/TST-72-30M-B-D4/P.1.png',
        'in_stock': true,
        'specifications': {
          'width': '72 inches',
          'depth': '30 inches',
          'height': '44 inches',
          'capacity': '23 cu. ft.',
          'temperature': '33°F - 41°F'
        }
      },
      {
        'sku': 'M3R-47-2-N',
        'category': 'REACH-IN REFRIGERATION',
        'subcategory': 'M3 Series Reach-In Refrigerators',
        'product_type': 'Two Section Reach-In Refrigerator',
        'description': '52" Two Section Reach-In Refrigerator',
        'price': 3299.00,
        'image_url': 'assets/screenshots/M3R-47-2-N/P.1.png',
      },
      {
        'sku': 'TGM-50R-N',
        'category': 'GLASS DOOR MERCHANDISERS',
        'subcategory': 'Glass Door Merchandisers',
        'product_type': 'Two Section Glass Door Merchandiser',
        'description': '50" Two Section Glass Door Refrigerator',
        'price': 3899.00,
        'image_url': 'assets/screenshots/TGM-50R-N/P.1.png',
      },
      {
        'sku': 'JUR-48-N',
        'category': 'UNDERCOUNTER REFRIGERATION',
        'subcategory': 'J Series Undercounter',
        'product_type': 'Undercounter Refrigerator',
        'description': '48" Undercounter Refrigerator',
        'price': 2199.00,
        'image_url': 'assets/screenshots/JUR-48-N/P.1.png',
      },
      {
        'sku': 'TOM-60S-N',
        'category': 'DISPLAY CASES',
        'subcategory': 'Open Display Merchandisers',
        'product_type': 'Open Display Merchandiser',
        'description': '60" Open Display Merchandiser',
        'price': 5499.00,
        'image_url': 'assets/screenshots/TOM-60S-N/P.1.png',
      },
      {
        'sku': 'TBB-24-60G-N',
        'category': 'UNDERBAR EQUIPMENT',
        'subcategory': 'Back Bar Coolers',
        'product_type': 'Back Bar Cooler',
        'description': '61" Back Bar Cooler with Glass Doors',
        'price': 2799.00,
        'image_url': 'assets/screenshots/TBB-24-60G-N/P.1.png',
      },
      {
        'sku': 'TMW-36F-N',
        'category': 'MILK COOLERS',
        'subcategory': 'Milk Coolers',
        'product_type': 'Forced Air Milk Cooler',
        'description': '36" Forced Air Milk Cooler',
        'price': 1899.00,
        'image_url': 'assets/screenshots/TMW-36F-N/P.1.png',
      },
      {
        'sku': 'TWR-28-N',
        'category': 'WORKTOP REFRIGERATION',
        'subcategory': 'Worktop Refrigerators',
        'product_type': 'Worktop Refrigerator',
        'description': '28" Worktop Refrigerator',
        'price': 1599.00,
        'image_url': 'assets/screenshots/TWR-28-N/P.1.png',
      },
    ];

    for (final product in products) {
      await _db.ref('products').push().set({
        ...product,
        'created_at': ServerValue.timestamp,
        'updated_at': ServerValue.timestamp,
      });
    }
    
    AppLogger.info('Added ${products.length} sample products', category: LogCategory.database);
  }

  static Future<void> _addSampleClients(String userId) async {
    final clients = [
      {
        'company': 'Restaurant Supply Co.',
        'contact_name': 'John Smith',
        'email': 'john@restaurantsupply.com',
        'phone': '(555) 123-4567',
        'address': '123 Main St, Dallas, TX 75201',
      },
      {
        'company': 'City Cafe',
        'contact_name': 'Maria Garcia',
        'email': 'maria@citycafe.com',
        'phone': '(555) 234-5678',
        'address': '456 Oak Ave, Houston, TX 77002',
      },
      {
        'company': 'Fresh Market',
        'contact_name': 'David Lee',
        'email': 'david@freshmarket.com',
        'phone': '(555) 345-6789',
        'address': '789 Pine Rd, Austin, TX 78701',
      },
    ];

    for (final client in clients) {
      await _db.ref('clients/$userId').push().set({
        ...client,
        'created_at': ServerValue.timestamp,
        'updated_at': ServerValue.timestamp,
      });
    }
    
    AppLogger.info('Added ${clients.length} sample clients for user $userId', category: LogCategory.database);
  }

  static Future<void> _addAppSettings() async {
    await _db.ref('app_settings').set({
      'tax_rate': 0.0825, // 8.25% tax
      'currency': 'USD',
      'site_name': 'TurboAir Equipment Viewer',
      'updated_at': ServerValue.timestamp,
    });
    
    AppLogger.info('Added app settings', category: LogCategory.database);
  }

  static Future<void> _addSampleQuotes(String userId) async {
    final quotes = [
      {
        'client_id': 'demo_client_1',
        'client_name': 'Restaurant Supply Co.',
        'quote_number': 'Q2025001',
        'items': [
          {
            'product_id': 'demo_product_1',
            'product_name': '72" Mega Top Sandwich/Salad Unit',
            'sku': 'TST-72-30M-B-D4',
            'quantity': 2,
            'unit_price': 4599.00,
            'total_price': 9198.00,
          },
          {
            'product_id': 'demo_product_2',
            'product_name': '52" Two Section Reach-In Refrigerator',
            'sku': 'M3R-47-2-N',
            'quantity': 1,
            'unit_price': 3299.00,
            'total_price': 3299.00,
          }
        ],
        'subtotal': 12497.00,
        'tax_rate': 0.0825,
        'tax_amount': 1031.00,
        'total_amount': 13528.00,
        'status': 'sent',
        'created_at': ServerValue.timestamp,
        'updated_at': ServerValue.timestamp,
      },
      {
        'client_id': 'demo_client_2',
        'client_name': 'City Cafe',
        'quote_number': 'Q2025002',
        'items': [
          {
            'product_id': 'demo_product_3',
            'product_name': '48" Undercounter Refrigerator',
            'sku': 'JUR-48-N',
            'quantity': 3,
            'unit_price': 2199.00,
            'total_price': 6597.00,
          }
        ],
        'subtotal': 6597.00,
        'tax_rate': 0.0825,
        'tax_amount': 544.00,
        'total_amount': 7141.00,
        'status': 'draft',
        'created_at': ServerValue.timestamp,
        'updated_at': ServerValue.timestamp,
      },
      {
        'client_id': 'demo_client_3',
        'client_name': 'Fresh Market',
        'quote_number': 'Q2025003',
        'items': [
          {
            'product_id': 'demo_product_4',
            'product_name': '50" Two Section Glass Door Refrigerator',
            'sku': 'TGM-50R-N',
            'quantity': 2,
            'unit_price': 3899.00,
            'total_price': 7798.00,
          },
          {
            'product_id': 'demo_product_5',
            'product_name': '60" Open Display Merchandiser',
            'sku': 'TOM-60S-N',
            'quantity': 1,
            'unit_price': 5499.00,
            'total_price': 5499.00,
          }
        ],
        'subtotal': 13297.00,
        'tax_rate': 0.0825,
        'tax_amount': 1097.00,
        'total_amount': 14394.00,
        'status': 'accepted',
        'created_at': ServerValue.timestamp,
        'updated_at': ServerValue.timestamp,
      }
    ];

    for (final quote in quotes) {
      await _db.ref('quotes/$userId').push().set(quote);
    }
    
    AppLogger.info('Added ${quotes.length} sample quotes for demo user', category: LogCategory.database);
  }
}