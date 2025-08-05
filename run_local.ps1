$url = "https://lxaritlhujdevalclhfc.supabase.co"
$key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4YXJpdGxodWpkZXZhbGNsaGZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzOTg4NTIsImV4cCI6MjA2ODk3NDg1Mn0.2rapqW5LdMO9s4JeQOsuiqzfDmIcvvQT8OYDkA3albc"

Write-Host "Starting Turbo Air app in Microsoft Edge..." -ForegroundColor Green
flutter run -d edge --dart-define=SUPABASE_URL=$url --dart-define=SUPABASE_ANON_KEY=$key
