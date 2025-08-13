#!/bin/bash
# Script to clean sensitive data from git history

echo "⚠️  WARNING: This will rewrite git history!"
echo "A backup branch 'backup-before-cleanup' has been created."
echo ""
read -p "Do you want to continue? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "🧹 Cleaning git history..."

# Remove sensitive files from all history
git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch lib/firebase_options.dart \
 android/app/google-services.json \
 ios/Runner/GoogleService-Info.plist \
 .env \
 .env.* \
 DEPLOY_TO_VERCEL.md \
 VERCEL_DEPLOY.md \
 VERCEL_DEPLOYMENT.md \
 generate-firebase-config.sh' \
--prune-empty --tag-name-filter cat -- --all

echo "✅ History cleaned locally"
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "1. Review the changes with: git log --oneline"
echo "2. Force push to GitHub (THIS WILL OVERWRITE REMOTE!):"
echo "   git push origin --force --all"
echo "3. Also push tags:"
echo "   git push origin --force --tags"
echo "4. Tell all collaborators to fresh clone the repo"
echo ""
echo "🗑️  To clean up local backup refs:"
echo "   rm -rf .git/refs/original/"
echo "   git reflog expire --expire=now --all"
echo "   git gc --prune=now --aggressive"