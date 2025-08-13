# Vercel Deployment Guide for Turbo Air Flutter App

## ✅ Pre-Deployment Checklist

All required files are ready for deployment:
- ✅ `vercel.json` - Configuration file (fixed PATH issue)
- ✅ `install-flutter.sh` - Flutter installation script
- ✅ `build-vercel.sh` - Build script for production
- ✅ `.env.example` - Environment variables template
- ✅ Flutter web support enabled

## 🚀 Deployment Steps

### Option 1: Deploy via Vercel CLI (Recommended)

1. **Install Vercel CLI** (if not already installed):
```bash
npm i -g vercel
```

2. **Login to Vercel**:
```bash
vercel login
```

3. **Deploy the project**:
```bash
# From the project root directory
vercel

# For production deployment
vercel --prod
```

4. **Follow the prompts**:
- Set up and deploy: `Y`
- Which scope: Select your account
- Link to existing project?: `N` (for first time)
- Project name: `turbo-air-viewer` (or your preference)
- Directory: `./` (current directory)
- Override settings?: `N`

### Option 2: Deploy via GitHub Integration

1. **Go to Vercel Dashboard**: https://vercel.com/new

2. **Import Git Repository**:
   - Click "Import Project"
   - Select "Import Git Repository"
   - Choose: `REDXICAN/Turbo-Air-Viewer-Flutter-App`

3. **Configure Project**:
   - **Framework Preset**: Other
   - **Build Command**: `bash build-vercel.sh`
   - **Output Directory**: `build/web`
   - **Install Command**: `bash install-flutter.sh`

4. **Add Environment Variables** (IMPORTANT):
   Click "Environment Variables" and add:

   ```
   FLUTTER_ROOT = ./flutter
   
   # Firebase Configuration (Required)
   FIREBASE_PROJECT_ID = turbo-air-viewer
   FIREBASE_DATABASE_URL = https://turbo-air-viewer-default-rtdb.firebaseio.com
   FIREBASE_API_KEY_WEB = [your-api-key]
   FIREBASE_AUTH_DOMAIN = turbo-air-viewer.firebaseapp.com
   FIREBASE_STORAGE_BUCKET = turbo-air-viewer.appspot.com
   FIREBASE_MESSAGING_SENDER_ID = [your-sender-id]
   FIREBASE_APP_ID_WEB = [your-app-id]
   
   # Admin Configuration (Optional for build)
   ADMIN_EMAIL = andres@turboairmexico.com
   ADMIN_PASSWORD = [secure-password]
   
   # Email Service (Optional for build)
   EMAIL_SENDER_ADDRESS = turboairquotes@gmail.com
   EMAIL_APP_PASSWORD = [app-password]
   ```

5. **Click "Deploy"**

## 📝 Environment Variables Setup

### Required for Production:
- All Firebase configuration values
- Admin credentials (for initial setup)
- Email service credentials (for quote emails)

### Getting Firebase Values:
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: `turbo-air-viewer`
3. Go to Project Settings > General
4. Find your Web app configuration

### Getting Gmail App Password:
1. Go to Google Account settings
2. Security > 2-Step Verification
3. App passwords > Generate new
4. Use this password for `EMAIL_APP_PASSWORD`

## 🔧 Build Configuration Details

### What happens during deployment:

1. **Install Phase** (`install-flutter.sh`):
   - Clones Flutter stable branch
   - Sets up Flutter environment
   - Installs project dependencies
   - Creates minimal .env file for build

2. **Build Phase** (`build-vercel.sh`):
   - Cleans previous builds
   - Builds optimized web release
   - Creates _redirects for client-side routing
   - Verifies build output

### Build Settings in Vercel:
```json
{
  "framework": null,
  "buildCommand": "bash build-vercel.sh",
  "outputDirectory": "build/web",
  "installCommand": "bash install-flutter.sh",
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

## 🚨 Troubleshooting

### Common Issues:

1. **Build Timeout**:
   - Increase build timeout in Vercel settings
   - Flutter first-time setup can take 5-10 minutes

2. **Missing Dependencies**:
   - Ensure all pubspec.yaml dependencies are committed
   - Check pubspec.lock is in repository

3. **Environment Variables**:
   - Double-check all Firebase values are correct
   - Ensure no quotes around values in Vercel UI

4. **Build Failures**:
   - Check build logs in Vercel dashboard
   - Run `flutter build web --release` locally to test

### Local Testing:
```bash
# Test the build locally
flutter build web --release

# Serve locally
cd build/web
python -m http.server 8000
# Visit http://localhost:8000
```

## 📊 Post-Deployment

### Verify Deployment:
1. Visit your Vercel URL
2. Test login with admin credentials
3. Check Firebase connectivity
4. Test email functionality

### Custom Domain (Optional):
1. Go to Vercel project settings
2. Domains > Add domain
3. Follow DNS configuration steps

### Performance Monitoring:
- Vercel Analytics (built-in)
- Firebase Performance Monitoring
- Check Web Vitals in Vercel dashboard

## 🔐 Security Notes

- Never commit `.env` file with real credentials
- Use Vercel environment variables for sensitive data
- Enable Firebase security rules
- Set up proper CORS headers if needed

## 📞 Support

If deployment fails, check:
1. Vercel build logs
2. GitHub Actions (if using CI/CD)
3. Firebase Console for connectivity

For help:
- Vercel Docs: https://vercel.com/docs
- Flutter Web: https://flutter.dev/web
- Project Issues: https://github.com/REDXICAN/Turbo-Air-Viewer-Flutter-App/issues

---

## Quick Deploy Command:
```bash
# One-line deploy from project root
vercel --prod
```

Ready to deploy! 🚀