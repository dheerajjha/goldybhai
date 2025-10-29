# 🧪 Shop Rates - Testing Guide

This document explains how to test the Shop Rates application locally, both backend and frontend independently.

---

## 📋 Prerequisites

Before testing, ensure you have installed:

- **Node.js** v18+ and npm
- **Flutter** SDK 3.0+
- **SQLite3** (usually pre-installed on macOS/Linux)

---

## 🔧 Backend Testing

### 1. Setup Backend

```bash
cd backend

# Install dependencies
npm install

# Create .env file (already exists, but verify)
cat .env

# Run database migrations
npm run migrate

# Seed initial data
npm run seed
```

### 2. Start Backend Server

```bash
# Start in development mode (with auto-reload)
npm run dev
```

**Expected Output:**
```
🚀 Starting Shop Rates Backend...
✅ Database connected
✅ Migrations completed
✅ Initial data seeded
📡 Starting rate fetcher service...
🔔 Starting alert checker service...
✨ Server running on http://localhost:3000
```

### 3. Test Backend APIs Manually

#### Health Check
```bash
curl http://localhost:3000/health
```

#### Get All Commodities
```bash
curl http://localhost:3000/api/commodities
```

#### Get Latest Rates
```bash
curl http://localhost:3000/api/rates/latest
```

#### Create an Alert
```bash
curl -X POST http://localhost:3000/api/alerts \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "commodityId": 1,
    "condition": "<",
    "targetPrice": 120000
  }'
```

#### Get All Alerts
```bash
curl http://localhost:3000/api/alerts?userId=1
```

#### Get Preferences
```bash
curl http://localhost:3000/api/preferences?userId=1
```

### 4. Run Automated Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm test -- --coverage

# Run tests in watch mode
npm run test:watch
```

**What gets tested:**
- ✅ Commodities API (GET all, GET by ID, GET by type)
- ✅ Rates API (latest rates, rate history)
- ✅ Alerts API (create, read, update, delete)
- ✅ Preferences API (read, update)
- ✅ Input validation
- ✅ Error handling

### 5. Verify Services

**Rate Fetcher Service:**
- Watch console logs every 15 seconds
- Check `data/shoprates.db` for new rate entries

**Alert Checker Service:**
- Create an alert with achievable target
- Watch console for alert triggers
- Check notifications table

---

## 📱 Frontend Testing

### 1. Setup Flutter App

```bash
cd app

# Install dependencies
flutter pub get

# Verify Flutter installation
flutter doctor
```

### 2. Configure Backend URL (if needed)

If backend is not on `localhost:3000`, edit:

**File:** `app/lib/services/api_client.dart`

```dart
ApiClient({this.baseUrl = 'http://YOUR_IP:3000/api'}) {
  // ...
}
```

### 3. Run Flutter App

**On Chrome (Web):**
```bash
flutter run -d chrome
```

**On iOS Simulator:**
```bash
flutter run -d "iPhone 15"
```

**On Android Emulator:**
```bash
flutter run -d emulator-5554
```

**On Physical Device:**
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### 4. Test App Functionality

#### Manual Testing Checklist

**Home Screen:**
- [  ] App loads without errors
- [  ] Rates are displayed in cards
- [  ] Pull to refresh works
- [  ] Data updates automatically
- [  ] Error handling displays properly

**Navigation:**
- [  ] Bottom navigation works (if implemented)
- [  ] Screen transitions are smooth

**API Integration:**
- [  ] Rates load from backend
- [  ] Loading states display correctly
- [  ] Error states handle backend down scenario

### 5. Test Error Scenarios

**Backend Down:**
```bash
# Stop backend server
# App should show connection error with retry button
```

**Network Delay:**
```bash
# Use network throttling in Chrome DevTools
# App should show loading indicator
```

---

## 🔄 End-to-End Testing

### Complete Flow Test

1. **Start Backend:**
   ```bash
   cd backend && npm run dev
   ```

2. **Start Flutter:**
   ```bash
   cd app && flutter run
   ```

3. **Test Workflow:**
   - ✅ App loads and shows rates
   - ✅ Rates update every 15 seconds
   - ✅ Create alert via API
   - ✅ Wait for alert to trigger
   - ✅ Verify notification created

4. **API → App Flow:**
   ```bash
   # Create alert
   curl -X POST http://localhost:3000/api/alerts \
     -H "Content-Type: application/json" \
     -d '{
       "userId": 1,
       "commodityId": 1,
       "condition": ">",
       "targetPrice": 100000
     }'

   # Wait for rate fetcher to update
   # Check app - should reflect alert when you implement alerts screen
   ```

---

## 🐛 Debugging Tips

### Backend Issues

**Database locked:**
```bash
rm backend/data/shoprates.db
cd backend && npm run migrate && npm run seed
```

**Port 3000 already in use:**
```bash
# Find and kill process
lsof -ti:3000 | xargs kill -9

# Or change PORT in backend/.env
PORT=3001
```

**Dependencies issues:**
```bash
cd backend
rm -rf node_modules package-lock.json
npm install
```

### Flutter Issues

**Build errors:**
```bash
cd app
flutter clean
flutter pub get
flutter run
```

**Hot reload not working:**
```
Press 'R' in terminal for hot restart
```

**API connection issues:**
```bash
# For iOS Simulator or Android Emulator, use:
# http://10.0.2.2:3000/api (Android)
# http://localhost:3000/api (iOS Simulator)

# For physical device, use your computer's IP:
# http://192.168.1.x:3000/api
```

---

## 📊 Test Coverage

### Backend Tests Cover:

- **Unit Tests:**
  - Database operations
  - Model validation
  - Utility functions

- **Integration Tests:**
  - API endpoints
  - Request/response handling
  - Error scenarios

- **Service Tests:**
  - Rate fetcher logic
  - Alert checker logic

### Expected Coverage:

- Statements: >80%
- Branches: >75%
- Functions: >80%
- Lines: >80%

---

## ✅ Acceptance Criteria

Before considering testing complete:

**Backend:**
- [  ] All API tests pass
- [  ] Server starts without errors
- [  ] Database migrations work
- [  ] Seed data loads correctly
- [  ] Rate fetcher runs automatically
- [  ] Alert checker detects triggers

**Frontend:**
- [  ] App builds successfully
- [  ] Rates display correctly
- [  ] API client communicates with backend
- [  ] Error handling works
- [  ] Loading states display properly

**Integration:**
- [  ] Backend + Frontend work together
- [  ] Data flows from API to UI
- [  ] Real-time updates function

---

## 🚀 Next Steps

After successful testing:

1. **Implement remaining screens:**
   - Alerts list screen
   - Add/Edit alert screen
   - Settings screen

2. **Add local notifications:**
   - Configure flutter_local_notifications
   - Test on physical device

3. **Deploy backend:**
   - Consider hosting options (Heroku, Railway, Render)
   - Update Flutter app with production URL

4. **Build production app:**
   ```bash
   flutter build apk  # Android
   flutter build ios  # iOS
   ```

---

Happy Testing! 🎉
