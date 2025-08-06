import 'package:cloud_firestore/cloud_firestore.dart';

class DataMigration {
  static Future<void> createInitialStructure() async {
    final db = FirebaseFirestore.instance;

    // Create collections structure
    await db.collection('products').doc('_metadata').set({
      'created': FieldValue.serverTimestamp(),
      'version': '1.0.0',
    });

    await db.collection('clients').doc('_metadata').set({
      'created': FieldValue.serverTimestamp(),
      'version': '1.0.0',
    });

    // Add more collections as needed
  }
}
