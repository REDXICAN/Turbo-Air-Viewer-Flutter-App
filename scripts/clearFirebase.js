// scripts/clearFirebase.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Replace with your actual database URL from Firebase Console
const DATABASE_URL = 'https://turbo-air-viewer-default-rtdb.firebaseio.com/';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: DATABASE_URL
});

const db = admin.database();
const auth = admin.auth();

async function clearFirebase() {
  try {
    // 1. Clear all database data
    console.log('Clearing database...');
    await db.ref('/').remove();
    console.log('Database cleared');

    // 2. Delete all users
    console.log('Deleting all users...');
    const listUsersResult = await auth.listUsers(1000);
    const deletePromises = listUsersResult.users.map(user => 
      auth.deleteUser(user.uid)
    );
    await Promise.all(deletePromises);
    console.log(`Deleted ${listUsersResult.users.length} users`);

    // 3. Set up new database structure
    console.log('Setting up new structure...');
    const initialStructure = {
      app_settings: {
        site_name: "TurboAir Quote System",
        currency: "USD",
        tax_rate: 0.08,
        updated_at: Date.now()
      },
      cart_items: {},
      clients: {},
      database_backups: {},
      products: {},
      quote_items: {},
      quotes: {},
      search_history: {},
      user_profiles: {}
    };

    await db.ref('/').set(initialStructure);
    console.log('New structure created');
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

clearFirebase();