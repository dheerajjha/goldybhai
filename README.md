# 🪙 Shop Rates - Gold & Silver Price Tracker

A real-time commodity price tracking application with price alerts. Built with Flutter (frontend) and Node.js + Express (backend).

## 📁 Project Structure

```
goldybhai/
├── app/                    # Flutter mobile application
├── backend/                # Node.js + Express API server
├── shared/                 # Shared documentation and configs
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites
- **Node.js** v18+ and npm ([Download](https://nodejs.org/))
- **Flutter** SDK 3.0+ ([Install Guide](https://docs.flutter.dev/get-started/install))
- **SQLite3** (pre-installed on macOS/Linux, [Windows setup](https://www.sqlite.org/download.html))
- A code editor (VS Code recommended)

### 1. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# The .env file is already configured, but you can customize it:
# - PORT: Server port (default: 3000)
# - RATE_FETCH_INTERVAL: Seconds between rate fetches (default: 15)
# - CHECK_ALERTS_INTERVAL: Seconds between alert checks (default: 30)

# Run database migrations (creates tables)
npm run migrate

# Seed initial data (adds commodities and guest user)
npm run seed

# Start development server with auto-reload
npm run dev
```

**Expected Output:**
```
✅ Database connected
✅ Migrations completed
✅ Initial data seeded
📡 Rate fetcher starting (every 15 seconds)
🔔 Alert checker starting (every 30 seconds)
✨ Server running on http://localhost:3000
```

**Verify Backend:**
```bash
curl http://localhost:3000/health
# Should return: {"status":"OK","timestamp":"...","uptime":...}
```

### 2. Frontend Setup

```bash
# In a NEW terminal window, navigate to app directory
cd app

# Install Flutter dependencies
flutter pub get

# Check Flutter setup
flutter doctor

# Run app (choose your platform):

# Web (Chrome)
flutter run -d chrome

# iOS Simulator (macOS only)
flutter run -d "iPhone 15"

# Android Emulator
flutter run -d emulator-5554

# Physical device
flutter devices           # List connected devices
flutter run -d <device-id>
```

**Note:** Backend must be running for the app to display data.

### 3. Testing the Integration

1. **Backend** running on `http://localhost:3000` ✅
2. **Flutter app** connected and showing rates ✅
3. Rates update automatically every 15 seconds ✅

## 🏗️ Architecture

### Backend (Node.js + Express)
- **Database**: SQLite3 (local file-based)
- **Cron Jobs**: Auto-fetch rates every 15 seconds
- **APIs**: RESTful endpoints for rates, alerts, preferences

### Frontend (Flutter)
- **State Management**: Provider/Riverpod
- **Notifications**: Local notifications (flutter_local_notifications)
- **HTTP Client**: dio package

## 🧪 Testing

### Backend Tests (Independent)

The backend can be fully tested without the Flutter app:

```bash
cd backend

# Run all automated tests
npm test

# Run tests with coverage report
npm test -- --coverage

# Run specific test file
npm test -- __tests__/api.test.js

# Watch mode (re-run on file changes)
npm run test:watch
```

**What's Tested:**
- ✅ All API endpoints (commodities, rates, alerts, preferences)
- ✅ Database operations (CRUD)
- ✅ Input validation
- ✅ Error handling
- ✅ Alert creation and updates

**Manual API Testing:**

Test APIs using curl or Postman:

```bash
# Get all commodities
curl http://localhost:3000/api/commodities

# Get latest rates
curl http://localhost:3000/api/rates/latest

# Create an alert
curl -X POST http://localhost:3000/api/alerts \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "commodityId": 1,
    "condition": "<",
    "targetPrice": 120000
  }'

# Get user preferences
curl http://localhost:3000/api/preferences?userId=1
```

### Frontend Tests (Independent)

Flutter app can be tested independently by running it and observing behavior:

```bash
cd app

# Lint check
flutter analyze

# Format check
flutter format --set-exit-if-changed .

# Build check
flutter build apk --debug  # Android
flutter build ios --debug  # iOS

# Run on different devices
flutter run -d chrome        # Test web version
flutter run -d emulator-5554 # Test Android
```

**Manual Testing Checklist:**
- [ ] App launches successfully
- [ ] Loading state displays while fetching
- [ ] Rates display in cards with proper formatting
- [ ] Pull-to-refresh works
- [ ] Error handling when backend is down
- [ ] Retry button works after error

### End-to-End Testing

Test complete integration:

1. **Start backend:** `cd backend && npm run dev`
2. **Start Flutter:** `cd app && flutter run`
3. **Verify:**
   - Rates load and display
   - Data updates every 15 seconds
   - Create alert via API, verify it triggers

See **[TESTING.md](TESTING.md)** for comprehensive testing guide.

## 📊 Database Schema

See [shared/ERD.md](shared/ERD.md) for complete entity-relationship diagram.

**Core Tables:**
- `commodities` - Gold, Silver, Coin types
- `rates` - Historical and latest prices
- `alerts` - User price alerts
- `users` - User accounts (simple for now)
- `preferences` - App settings

## 🔔 Features

- ✅ Real-time commodity price tracking
- ✅ Price alerts (above/below target)
- ✅ Local notifications
- ✅ Historical rate tracking
- ✅ Multiple commodities (Gold 995, 999, Silver, etc.)
- ✅ Customizable refresh intervals

## 📝 API Documentation

See [backend/API.md](backend/API.md) for detailed endpoint documentation.

## 🛠️ Development

### Backend Development
```bash
cd backend
npm run dev     # Auto-reload with nodemon
```

### Flutter Hot Reload
```bash
cd app
flutter run     # Press 'r' for hot reload, 'R' for hot restart
```

## 📄 License

MIT

## 👤 Author

Dheeraj Jha
