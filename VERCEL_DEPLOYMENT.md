# Vercel Deployment Guide

## 🚀 Quick Deploy

### Step 1: Push Latest Changes
```bash
git add .
git commit -m "Add Vercel deployment scripts"
git push origin main
```

### Step 2: Configure Vercel
1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Import your GitHub repository
3. Configure build settings:
   - **Framework Preset**: Other
   - **Build Command**: `bash build-vercel.sh`
   - **Install Command**: `bash install-flutter.sh`
   - **Output Directory**: `build/web`

### Step 3: Add Environment Variables
In Vercel project settings, add these environment variables:

```env
# Required for build
ADMIN_EMAIL=andres@turboairmexico.com
ADMIN_PASSWORD=[your-secure-password]
FIREBASE_PROJECT_ID=turbo-air-viewer
FIREBASE_DATABASE_URL=https://turbo-air-viewer-default-rtdb.firebaseio.com
FIREBASE_API_KEY_WEB=[your-api-key]
FIREBASE_AUTH_DOMAIN=turbo-air-viewer.firebaseapp.com
FIREBASE_STORAGE_BUCKET=turbo-air-viewer.appspot.com
FIREBASE_MESSAGING_SENDER_ID=[your-sender-id]
FIREBASE_APP_ID_WEB=[your-app-id]

# Email configuration
EMAIL_SENDER_ADDRESS=turboairquotes@gmail.com
EMAIL_APP_PASSWORD=[your-app-password]
```

## 📁 Files Created

### `vercel.json`
Main configuration file for Vercel deployment

### `install-flutter.sh`
- Installs Flutter SDK
- Sets up environment
- Gets dependencies
- Creates .env file if missing

### `build-vercel.sh`
- Builds optimized web release
- Uses HTML renderer for better compatibility
- Creates routing configuration
- Verifies build output

### `.env.example`
Template for environment variables

## 🔧 Troubleshooting

### Build Fails
1. Check build logs in Vercel dashboard
2. Ensure all environment variables are set
3. Verify scripts have correct line endings (LF, not CRLF)

### Flutter Not Found
The install script automatically downloads Flutter. If issues persist:
1. Clear build cache in Vercel
2. Redeploy

### Missing Dependencies
The install script runs `flutter pub get` automatically

## 🎯 Important Notes

1. **Environment Variables**: Must be set in Vercel dashboard, not in repository
2. **Build Time**: First build may take 5-10 minutes due to Flutter installation
3. **Caching**: Subsequent builds will be faster due to dependency caching
4. **Web Renderer**: Using HTML renderer for better browser compatibility

## ✅ Deployment Checklist

- [ ] All changes pushed to GitHub
- [ ] Environment variables set in Vercel
- [ ] Build scripts have Unix line endings (LF)
- [ ] .env.example updated with all required variables
- [ ] Firebase project configured correctly

## 🚨 Security

- Never commit `.env` file
- Use Vercel environment variables for sensitive data
- Regularly rotate passwords and API keys
- Monitor build logs for exposed secrets