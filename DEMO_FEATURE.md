# Demo Feature Documentation

## 🎯 Overview
A "Try Demo" button has been added to the login screen that allows users to instantly explore the app with pre-populated sample data without needing to create a real account.

## 📍 Location
The demo button appears at the **bottom center** of the login screen, below the main login form.

## 🎨 Design
- **Style**: Outlined button with play icon
- **Color**: White outline with translucent background
- **Text**: "Try Demo" with description below
- **Position**: Fixed at bottom of screen with safe area padding

## 🚀 How It Works

### 1. **One-Click Demo Access**
When a user clicks "Try Demo", the app automatically:
- Creates a unique demo account (demo_[timestamp]@turboair.com)
- Signs in the user
- Populates the account with sample data
- Redirects to the main dashboard

### 2. **Sample Data Included**

#### Products (8 items)
- Reach-In Refrigerators
- Food Prep Tables
- Undercounter Units
- Glass Door Merchandisers
- Display Cases
- Underbar Equipment
- Milk Coolers
- Worktop Refrigeration

#### Clients (3 companies)
- Restaurant Supply Co.
- City Cafe
- Fresh Market

#### Quotes (3 samples)
- **Sent Quote**: $13,528 - Multiple items
- **Draft Quote**: $7,141 - In progress
- **Accepted Quote**: $14,394 - Completed sale

### 3. **Demo Account Details**
- **Email Format**: demo_[timestamp]@turboair.com
- **Password**: demo123456 (auto-generated)
- **Name**: Demo User
- **Role**: Distributor

## 💡 Benefits

### For Potential Users
- **Instant Access**: No registration required
- **Full Features**: Access to all app functionality
- **Real Experience**: See actual workflow with data
- **Risk-Free**: Explore without commitment

### For Sales/Marketing
- **Lower Barrier**: Users can try before signing up
- **Better Conversion**: Users understand value immediately
- **Demo Ready**: Perfect for presentations
- **Self-Service**: No manual demo setup needed

## 🔒 Security Considerations

1. **Isolated Data**: Each demo account is separate
2. **Unique Accounts**: Timestamp ensures no conflicts
3. **Limited Permissions**: Demo accounts have standard user permissions
4. **No Real Data**: Only sample data is used

## 📱 User Experience Flow

```
Login Screen
    ↓
[Try Demo] Button
    ↓
Auto-creates account
    ↓
Loads sample data
    ↓
Dashboard with data
    ↓
Full app exploration
```

## 🛠️ Technical Implementation

### Files Modified
1. **login_screen.dart**: Added demo button and handler
2. **sample_data_service.dart**: Enhanced with quotes data

### Key Methods
```dart
// Creates demo account and loads data
Future<void> _handleDemoLogin() async {
  // 1. Generate unique demo credentials
  // 2. Create account
  // 3. Sign in
  // 4. Initialize sample data
  // 5. Navigate to dashboard
}
```

### Sample Data Service
```dart
SampleDataService.initializeSampleData()
  ├── Products (8 items with specs)
  ├── Clients (3 companies)
  ├── Quotes (3 with different statuses)
  └── App Settings (tax, currency)
```

## 📊 Demo Statistics

After clicking "Try Demo", users will see:
- **8** Products in catalog
- **3** Clients in database
- **3** Quotes with different statuses
- **$34,063** Total quoted value
- **0** Items in cart (starts empty)

## 🎯 Use Cases

### 1. **Sales Demonstrations**
Sales team can quickly show the app to prospects without setup.

### 2. **User Onboarding**
New users can explore features before committing to registration.

### 3. **Testing & Training**
Perfect for training sessions or testing new features.

### 4. **Marketing Materials**
Screenshots and videos can use consistent demo data.

## 🔄 Future Enhancements

Potential improvements for the demo feature:
- [ ] Guided tour overlay
- [ ] Reset demo data button
- [ ] Multiple demo scenarios
- [ ] Industry-specific demos
- [ ] Time-limited demo sessions

## ⚡ Quick Start

1. Open the app
2. On login screen, look at the bottom
3. Click "Try Demo"
4. Wait 2-3 seconds for setup
5. Explore the full app!

## 📝 Notes

- Demo accounts are temporary and for exploration only
- Each demo creates a new account to avoid conflicts
- Sample data includes realistic prices and specifications
- Perfect for showcasing app capabilities without setup