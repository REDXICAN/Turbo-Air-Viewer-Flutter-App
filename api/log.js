// api/log.js - Vercel serverless function for logging
import admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
    databaseURL: process.env.FIREBASE_DATABASE_URL,
  });
}

const db = admin.database();

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { level, category, message, metadata, userId, environment } = req.body;

    // Validate required fields
    if (!level || !message) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Create log entry
    const logEntry = {
      level,
      category: category || 'general',
      message,
      metadata: metadata || {},
      userId: userId || null,
      environment: environment || 'production',
      timestamp: admin.database.ServerValue.TIMESTAMP,
      source: 'vercel-api',
      ip: req.headers['x-forwarded-for'] || req.connection.remoteAddress,
      userAgent: req.headers['user-agent'],
    };

    // Store in Firebase
    const logRef = db.ref(`logs/vercel/${environment || 'production'}`).push();
    await logRef.set(logEntry);

    // For critical errors, send notifications
    if (level === 'critical' || level === 'error') {
      await sendNotification(logEntry);
    }

    // Track metrics
    await updateMetrics(level, category);

    res.status(200).json({ 
      success: true, 
      logId: logRef.key,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Logging error:', error);
    res.status(500).json({ error: 'Failed to log entry' });
  }
}

async function sendNotification(logEntry) {
  // Send to Discord webhook if configured
  if (process.env.DISCORD_WEBHOOK) {
    try {
      await fetch(process.env.DISCORD_WEBHOOK, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          embeds: [{
            title: `🚨 ${logEntry.level.toUpperCase()} Alert`,
            description: logEntry.message,
            color: logEntry.level === 'critical' ? 0xFF0000 : 0xFFA500,
            fields: [
              {
                name: 'Environment',
                value: logEntry.environment,
                inline: true
              },
              {
                name: 'Category',
                value: logEntry.category,
                inline: true
              },
              {
                name: 'User',
                value: logEntry.userId || 'Anonymous',
                inline: true
              }
            ],
            timestamp: new Date().toISOString()
          }]
        })
      });
    } catch (e) {
      console.error('Discord notification failed:', e);
    }
  }
}

async function updateMetrics(level, category) {
  try {
    const metricsRef = db.ref(`metrics/${new Date().toISOString().split('T')[0]}`);
    await metricsRef.transaction((current) => {
      if (!current) {
        current = {
          total: 0,
          byLevel: {},
          byCategory: {}
        };
      }
      
      current.total = (current.total || 0) + 1;
      current.byLevel[level] = (current.byLevel[level] || 0) + 1;
      current.byCategory[category] = (current.byCategory[category] || 0) + 1;
      
      return current;
    });
  } catch (e) {
    console.error('Metrics update failed:', e);
  }
}