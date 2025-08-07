// scripts/importProducts.js
const XLSX = require('xlsx');
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Replace with your actual database URL from Firebase Console
const DATABASE_URL = 'https://turbo-air-viewer-default-rtdb.firebaseio.com/';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: DATABASE_URL
});

const db = admin.database();

function cleanValue(value) {
  if (value === null || value === undefined || value === '') return '';
  return String(value).trim();
}

function parsePrice(value) {
  if (!value) return 0;
  const cleaned = String(value).replace(/[$,]/g, '');
  return parseFloat(cleaned) || 0;
}

async function importProducts() {
  try {
    console.log('Reading turbo_air_products.xlsx...');
    const workbook = XLSX.readFile('turbo_air_products.xlsx');
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const data = XLSX.utils.sheet_to_json(worksheet);

    console.log(`Found ${data.length} products to import`);

    const productsRef = db.ref('products');
    let imported = 0;
    let failed = 0;

    for (const row of data) {
      try {
        const sku = cleanValue(row['SKU']);
        
        if (!sku) {
          console.log('Skipping row with no SKU');
          failed++;
          continue;
        }

        const product = {
          sku: sku,
          category: cleanValue(row['Category']),
          subcategory: cleanValue(row['Subcategory']),
          product_type: cleanValue(row['Product Type']),
          description: cleanValue(row['Description']),
          voltage: cleanValue(row['Voltage']),
          amperage: cleanValue(row['Amperage']),
          phase: cleanValue(row['Phase']),
          frequency: cleanValue(row['Frequency']),
          plug_type: cleanValue(row['Plug Type']),
          dimensions: cleanValue(row['Dimensions']),
          dimensions_metric: cleanValue(row['Dimensions (Metric)']),
          weight: cleanValue(row['Weight']),
          weight_metric: cleanValue(row['Weight (Metric)']),
          temperature_range: cleanValue(row['Temperature Range']),
          temperature_range_metric: cleanValue(row['Temperature Range (Metric)']),
          refrigerant: cleanValue(row['Refrigerant']),
          compressor: cleanValue(row['Compressor']),
          capacity: cleanValue(row['Capacity']),
          doors: cleanValue(row['Doors']),
          shelves: cleanValue(row['Shelves']),
          features: cleanValue(row['Features']),
          certifications: cleanValue(row['Certifications']),
          price: parsePrice(row['Price']),
          created_at: Date.now()
        };

        // Use SKU as the key (replace any invalid characters)
        const safeKey = sku.replace(/[.#$\/\[\]]/g, '_');
        await productsRef.child(safeKey).set(product);
        
        imported++;
        console.log(`✓ Imported: ${sku} (${imported}/${data.length})`);
      } catch (error) {
        failed++;
        console.error(`✗ Failed to import row:`, error.message);
      }
    }

    console.log('\n=== Import Complete ===');
    console.log(`Successfully imported: ${imported} products`);
    console.log(`Failed: ${failed} products`);
    
    process.exit(0);
  } catch (error) {
    console.error('Import failed:', error);
    process.exit(1);
  }
}

importProducts();