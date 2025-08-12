// scripts/initialize_firebase_data.js
const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json'); // You'll need to download this from Firebase Console

// Initialize admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://turbo-air-viewer-default-rtdb.firebaseio.com'
});

const db = admin.database();

async function initializeData() {
  console.log('Initializing Firebase data...');
  
  // Add sample products
  const productsRef = db.ref('products');
  const productsSnapshot = await productsRef.once('value');
  
  if (!productsSnapshot.exists()) {
    console.log('Adding sample products...');
    const products = [
      {
        sku: 'TST-72-30M-B-D4',
        category: 'FOOD PREP TABLES',
        subcategory: 'Mega Top Sandwich & Salad Units',
        product_type: 'Refrigerated Counter',
        description: '72" Mega Top Sandwich/Salad Unit',
        price: 4599.00,
        image_url: 'assets/screenshots/TST-72-30M-B-D4/P.1.png',
      },
      {
        sku: 'M3R-47-2-N',
        category: 'REACH-IN REFRIGERATION',
        subcategory: 'M3 Series Reach-In Refrigerators',
        product_type: 'Two Section Reach-In Refrigerator',
        description: '52" Two Section Reach-In Refrigerator',
        price: 3299.00,
        image_url: 'assets/screenshots/M3R-47-2-N/P.1.png',
      },
      {
        sku: 'TGM-50R-N',
        category: 'GLASS DOOR MERCHANDISERS',
        subcategory: 'Glass Door Merchandisers',
        product_type: 'Two Section Glass Door Merchandiser',
        description: '50" Two Section Glass Door Refrigerator',
        price: 3899.00,
        image_url: 'assets/screenshots/TGM-50R-N/P.1.png',
      },
    ];
    
    for (const product of products) {
      await productsRef.push({
        ...product,
        created_at: admin.database.ServerValue.TIMESTAMP,
        updated_at: admin.database.ServerValue.TIMESTAMP,
      });
    }
    console.log(`Added ${products.length} products`);
  } else {
    console.log('Products already exist');
  }
  
  // Add app settings
  const settingsRef = db.ref('app_settings');
  const settingsSnapshot = await settingsRef.once('value');
  
  if (!settingsSnapshot.exists()) {
    console.log('Adding app settings...');
    await settingsRef.set({
      tax_rate: 0.0825,
      currency: 'USD',
      site_name: 'TurboAir Equipment Viewer',
      updated_at: admin.database.ServerValue.TIMESTAMP,
    });
    console.log('App settings added');
  } else {
    console.log('App settings already exist');
  }
  
  console.log('Firebase initialization complete!');
  process.exit(0);
}

initializeData().catch(err => {
  console.error('Error initializing data:', err);
  process.exit(1);
});