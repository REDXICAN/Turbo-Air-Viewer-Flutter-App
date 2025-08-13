# 🚀 Deploy Turbo Air Flutter App to Vercel - Step by Step

## 📋 Prerequisites
1. Delete all existing Vercel projects (as requested)
2. Have your Firebase configuration ready
3. GitHub repository is up to date

## 🔧 Step 1: Prepare Your Vercel Account

1. **Go to Vercel Dashboard**: https://vercel.com/dashboard
2. **Delete any existing projects** (if needed):
   - Click on each project
   - Go to Settings → Delete Project
   - Confirm deletion

## 🚀 Step 2: Deploy via Vercel Website

### A. Start Import Process

1. **Go to**: https://vercel.com/new
2. **Click**: "Import Git Repository"
3. **If not connected to GitHub**:
   - Click "Add GitHub Account"
   - Authorize Vercel to access your repositories
4. **Search for**: `Turbo-Air-Viewer-Flutter-App`
5. **Click**: "Import"

### B. Configure Your Project

**IMPORTANT: Configure these settings EXACTLY as shown**

1. **Project Name**: 
   ```
   turbo-air-viewer
   ```

2. **Framework Preset**: 
   ```
   Other
   ```

3. **Root Directory**:
   ```
   ./
   ```
   (Leave as default)

4. **Build and Output Settings** - Click "Override" and set:
   - **Build Command**:
     ```
     bash build-vercel.sh
     ```
   - **Output Directory**:
     ```
     build/web
     ```
   - **Install Command**:
     ```
     bash install-flutter.sh
     ```

### C. Add Environment Variables

**Click "Environment Variables" and add ALL of these:**

```bash
# Flutter Configuration
FLUTTER_ROOT=./flutter

# Firebase Configuration (REQUIRED - Get from Firebase Console)
FIREBASE_PROJECT_ID=turbo-air-viewer
FIREBASE_DATABASE_URL=https://turbo-air-viewer-default-rtdb.firebaseio.com
FIREBASE_API_KEY_WEB=AIzaSyDxLfqmJHQqRZQvBKfqQxYJe4XVKFGXFVU
FIREBASE_AUTH_DOMAIN=turbo-air-viewer.firebaseapp.com
FIREBASE_STORAGE_BUCKET=turbo-air-viewer.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_APP_ID_WEB=1:123456789:web:abcdef123456

# Admin Account (REQUIRED)
ADMIN_EMAIL=andres@turboairmexico.com
ADMIN_PASSWORD=andres123!@#

# Email Service (REQUIRED for email functionality)
EMAIL_SENDER_ADDRESS=turboairquotes@gmail.com
EMAIL_APP_PASSWORD=your_gmail_app_password_here
```

**⚠️ IMPORTANT**: Replace the Firebase values with your ACTUAL values from Firebase Console!

### D. Getting Your Firebase Configuration

1. **Go to**: https://console.firebase.google.com
2. **Select**: Your `turbo-air-viewer` project
3. **Navigate to**: Project Settings (gear icon) → General
4. **Scroll to**: "Your apps" → Web app
5. **Copy**: The configuration values

Example Firebase config:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...", // <- Copy this for FIREBASE_API_KEY_WEB
  authDomain: "turbo-air-viewer.firebaseapp.com",
  databaseURL: "https://turbo-air-viewer-default-rtdb.firebaseio.com",
  projectId: "turbo-air-viewer",
  storageBucket: "turbo-air-viewer.appspot.com",
  messagingSenderId: "123456789", // <- Copy this
  appId: "1:123456789:web:..." // <- Copy this for FIREBASE_APP_ID_WEB
};
```

### E. Deploy

1. **Review all settings**
2. **Click**: "Deploy"
3. **Wait**: First deployment takes 5-10 minutes (Flutter installation)

## 📊 Step 3: Monitor Deployment

1. **Watch the build logs** in real-time
2. **Expected output**:
   ```
   🚀 Installing Flutter for Vercel...
   📦 Cloning Flutter stable branch...
   🔍 Verifying Flutter installation...
   📝 Generating firebase_options.dart...
   📚 Installing project dependencies...
   ✅ Flutter installation complete!
   🔨 Building Flutter web application...
   🏗️ Building optimized web release...
   ✅ Build complete!
   ```

## ✅ Step 4: Verify Deployment

Once deployed, you'll get a URL like: `https://turbo-air-viewer.vercel.app`

1. **Visit the URL**
2. **Test login** with:
   - Email: `andres@turboairmexico.com`
   - Password: `andres123!@#`
3. **Verify**:
   - Products load
   - Can create quotes
   - Email functionality works

## 🔧 Troubleshooting

### If Build Fails:

1. **Check Build Logs** for specific errors
2. **Common Issues**:

   **Error: "firebase_options.dart not found"**
   - Ensure all Firebase env variables are set
   - Check generate-firebase-config.sh is present

   **Error: "Build timeout"**
   - Normal for first build (Flutter installation)
   - Vercel allows up to 45 minutes

   **Error: "Module not found"**
   - Check all files are committed to GitHub
   - Run `git status` to verify

3. **Test Locally First**:
   ```bash
   flutter build web --release
   cd build/web
   python -m http.server 8000
   ```

## 🎯 Alternative: Deploy via Vercel CLI

If the web interface doesn't work, use CLI:

1. **Install Vercel CLI**:
   ```bash
   npm i -g vercel
   ```

2. **Login**:
   ```bash
   vercel login
   ```

3. **Deploy** (from project directory):
   ```bash
   vercel
   ```

4. **Answer prompts**:
   - Set up and deploy? **Y**
   - Which scope? **Your account**
   - Link to existing project? **N**
   - Project name? **turbo-air-viewer**
   - Directory? **./**
   - Override settings? **N**

5. **Add environment variables**:
   ```bash
   vercel env add FIREBASE_PROJECT_ID
   vercel env add FIREBASE_API_KEY_WEB
   # ... add all variables
   ```

6. **Deploy to production**:
   ```bash
   vercel --prod
   ```

## 📝 Post-Deployment Checklist

- [ ] Application loads without errors
- [ ] Login works with admin credentials
- [ ] Products display correctly
- [ ] Can create and save quotes
- [ ] Email sending works (test with a quote)
- [ ] Offline mode functions
- [ ] All images load properly

## 🆘 Need Help?

1. **Check Vercel Logs**: Project → Functions → View Logs
2. **Check Browser Console**: F12 → Console tab
3. **Firebase Console**: Check Realtime Database for data
4. **GitHub Issues**: Create an issue with error details

## 🎉 Success!

Your app should now be live at your Vercel URL!

Custom domain setup (optional):
1. Go to Project Settings → Domains
2. Add your domain
3. Update DNS records as instructed

---

**Quick Reference - Environment Variables Needed:**
```
FLUTTER_ROOT
FIREBASE_PROJECT_ID
FIREBASE_DATABASE_URL
FIREBASE_API_KEY_WEB
FIREBASE_AUTH_DOMAIN
FIREBASE_STORAGE_BUCKET
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_APP_ID_WEB
ADMIN_EMAIL
ADMIN_PASSWORD
EMAIL_SENDER_ADDRESS
EMAIL_APP_PASSWORD
```

© 2025 Turbo Air Inc. All rights reserved.