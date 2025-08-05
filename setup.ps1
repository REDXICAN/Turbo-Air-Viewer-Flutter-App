# Complete setup script for Flutter project
# Save as: setup.ps1 in project root

Write-Host "Setting up Turbo Air Flutter App..." -ForegroundColor Green

# Create all necessary directories
Write-Host "Creating directories..." -ForegroundColor Yellow
$directories = @(
    "lib\core\router",
    "lib\core\theme",
    "lib\core\widgets",
    "lib\features\auth\presentation\screens",
    "lib\features\auth\presentation\providers",
    "lib\features\products\presentation\screens",
    "lib\features\cart\presentation\screens",
    "lib\features\clients\presentation\screens",
    "lib\features\quotes\presentation\screens",
    "lib\features\profile\presentation\screens"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Gray
    }
}

# Move misplaced files if they exist in root
if (Test-Path "app_router.dart") {
    Move-Item "app_router.dart" "lib\core\router\app_router.dart" -Force
    Write-Host "Moved app_router.dart to correct location" -ForegroundColor Green
}

# Get Flutter dependencies
Write-Host "Installing Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

# Check if successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now you can run the app with:" -ForegroundColor Cyan
    Write-Host ".\run_local.ps1" -ForegroundColor White
} else {
    Write-Host "Error installing dependencies. Make sure Flutter is installed." -ForegroundColor Red
    Write-Host "Install Flutter from: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
}