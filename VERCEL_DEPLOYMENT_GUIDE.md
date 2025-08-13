# Vercel Deployment Guide for Turbo Air Flutter App

## Prerequisites

1. Vercel account
2. GitHub repository connected to Vercel
3. Environment variables configured in Vercel dashboard

## Required Environment Variables

Add these in Vercel Dashboard → Settings → Environment Variables:

```bash
# Firebase Configuration (Required)
FIREBASE_PROJECT_ID=turbo-air-viewer
FIREBASE_DATABASE_URL=https://turbo-air-viewer-default-rtdb.firebaseio.com
FIREBASE_API_KEY_WEB=[YOUR_API_KEY]
FIREBASE_AUTH_DOMAIN=turbo-air-viewer.firebaseapp.com
FIREBASE_STORAGE_BUCKET=turbo-air-viewer.appspot.com
FIREBASE_MESSAGING_SENDER_ID=[YOUR_SENDER_ID]
FIREBASE_APP_ID_WEB=[YOUR_APP_ID]

# Email Service Configuration
EMAIL_SENDER_ADDRESS=turboairquotes@gmail.com
EMAIL_APP_PASSWORD=[YOUR_APP_PASSWORD]
EMAIL_SENDER_NAME=TurboAir Quote System

# Admin Credentials
ADMIN_EMAIL=andres@turboairmexico.com
ADMIN_PASSWORD=[YOUR_PASSWORD]

# Flutter Build Settings
FLUTTER_SUPPRESS_ANALYTICS=true
PUB_CACHE=/tmp/pub-cache
```

## Build Configuration

The project uses:
- `build-vercel.sh` - Main build script
- `install-flutter.sh` - Flutter installation helper
- `vercel.json` - Vercel configuration

## Deployment Steps

1. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Deploy to Vercel"
   git push origin main
   ```

2. **Vercel Auto-Deploy**
   - Vercel automatically detects pushes to main branch
   - Runs build-vercel.sh script
   - Deploys to production

3. **Manual Deploy (if needed)**
   ```bash
   vercel --prod
   ```

## Build Process

The build script:
1. Installs Flutter SDK (3.24.0 stable)
2. Generates firebase_options.dart from environment variables
3. Installs dependencies
4. Builds optimized web release
5. Outputs to build/web directory

## Troubleshooting

### Build Failures
- Check Vercel build logs
- Ensure all environment variables are set
- Verify Flutter version compatibility

### Missing firebase_options.dart
- The file is generated during build
- Check generate-firebase-config.sh script
- Verify Firebase environment variables

### Performance Issues
- Build uses default web renderer (auto-detect)
- CanvasKit for desktop browsers
- HTML renderer for mobile browsers

## Security Notes

- Never commit .env files
- firebase_options.dart is gitignored
- API keys are stored in Vercel environment variables
- Service account keys should never be committed

## Support

For issues, contact: andres@turboairmexico.com