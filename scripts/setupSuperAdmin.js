// scripts/setupSuperAdmin.js
// Run this script to clear all users and prepare for first super admin signup
// Usage: node scripts/setupSuperAdmin.js

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://turbo-air-viewer-default-rtdb.firebaseio.com'
});

const auth = admin.auth();
const firestore = admin.firestore();

async function setupSuperAdmin() {
  try {
    console.log('🔧 Starting Super Admin Setup...\n');
    
    // Step 1: List all existing users
    console.log('📋 Fetching existing users...');
    const listUsersResult = await auth.listUsers(1000);
    console.log(`Found ${listUsersResult.users.length} existing users`);
    
    // Step 2: Delete all existing users
    if (listUsersResult.users.length > 0) {
      console.log('\n🗑️  Deleting all existing users...');
      const deletePromises = listUsersResult.users.map(user => {
        console.log(`  - Deleting user: ${user.email}`);
        return auth.deleteUser(user.uid);
      });
      await Promise.all(deletePromises);
      console.log('✅ All users deleted');
    }
    
    // Step 3: Clear user_profiles collection in Firestore
    console.log('\n🗑️  Clearing user_profiles collection...');
    const userProfiles = await firestore.collection('user_profiles').get();
    const batch = firestore.batch();
    userProfiles.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log('✅ User profiles collection cleared');
    
    // Step 4: Display instructions
    console.log('\n' + '='.repeat(60));
    console.log('✨ SETUP COMPLETE!');
    console.log('='.repeat(60));
    console.log('\n📌 NEXT STEPS:');
    console.log('1. Start your Flutter app');
    console.log('2. Sign up with these credentials:');
    console.log('   Email: andres@turboairmexico.com');
    console.log('   Password: andres123!@#');
    console.log('   Company: Turbo Air Mexico');
    console.log('\n3. This account will automatically become the Super Admin');
    console.log('4. You can then assign admin roles to other users from the Admin Panel');
    console.log('='.repeat(60));
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during setup:', error);
    process.exit(1);
  }
}

// Run the setup
setupSuperAdmin();