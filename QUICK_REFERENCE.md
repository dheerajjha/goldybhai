# 🚀 Shop Rates - Quick Reference

## ⚡ Quick Commands

### Backend

```bash
cd backend

# Setup (first time only)
./setup.sh              # Or: npm install && npm run migrate && npm run seed

# Development
npm run dev             # Start server with auto-reload
npm test                # Run tests
npm test -- --coverage  # Run tests with coverage

# Database
npm run migrate         # Create/update tables
npm run seed            # Add initial data
```

### Flutter App

```bash
cd app

# Setup (first time only)
flutter pub get

# Development
flutter run -d chrome           # Run on web
flutter run -d "iPhone 15"      # Run on iOS simulator
flutter run -d emulator-5554    # Run on Android emulator

# Testing
flutter analyze                 # Lint check
flutter build apk --debug       # Build Android
flutter build ios --debug       # Build iOS
```

---

## 📡 API Endpoints

**Base URL:** `http://localhost:3000/api`

### Commodities
```
GET    /commodities           # Get all
GET    /commodities/:id       # Get by ID
GET    /commodities/type/:type # Get by type (gold/silver/coin)
```

### Rates
```
GET    /rates/latest          # Latest rates for all
GET    /rates/:commodityId    # Latest rate for one
GET    /rates/:commodityId/history?limit=100 # History
```

### Alerts
```
GET    /alerts?userId=1       # Get all alerts
GET    /alerts/active?userId=1 # Get active alerts
GET    /alerts/:id            # Get specific alert
POST   /alerts                # Create alert
PUT    /alerts/:id            # Update alert
DELETE /alerts/:id            # Delete alert
```

### Preferences
```
GET    /preferences?userId=1  # Get preferences
PUT    /preferences?userId=1  # Update preferences
```

---

## 🧪 Quick Tests

### Test Backend
```bash
# Health check
curl http://localhost:3000/health

# Get commodities
curl http://localhost:3000/api/commodities

# Get latest rates
curl http://localhost:3000/api/rates/latest

# Create alert
curl -X POST http://localhost:3000/api/alerts \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"commodityId":1,"condition":"<","targetPrice":120000}'
```

### Test Integration
1. Start backend: `cd backend && npm run dev`
2. Start Flutter: `cd app && flutter run`
3. Verify app shows rates and updates

---

## 🗂️ Project Structure

```
goldybhai/
├── app/                  # Flutter (Frontend)
│   ├── lib/
│   │   ├── models/      # Data models
│   │   ├── services/    # API client
│   │   └── main.dart    # Entry point
│   └── pubspec.yaml
│
├── backend/             # Node.js (Backend)
│   ├── src/
│   │   ├── routes/     # API routes
│   │   ├── controllers/ # Business logic
│   │   ├── services/   # Background jobs
│   │   └── server.js   # Entry point
│   ├── __tests__/      # API tests
│   └── package.json
│
└── shared/             # Documentation
    └── ERD.md         # Database schema
```

---

## 🔧 Configuration

### Backend (.env)
```bash
PORT=3000
DB_PATH=./data/shoprates.db
RATE_FETCH_INTERVAL=15    # seconds
CHECK_ALERTS_INTERVAL=30  # seconds
```

### Flutter (api_client.dart)
```dart
ApiClient({this.baseUrl = 'http://localhost:3000/api'})
```

---

## 🐛 Common Issues

### "Port 3000 already in use"
```bash
lsof -ti:3000 | xargs kill -9
# Or change PORT in backend/.env
```

### "Database is locked"
```bash
cd backend
rm -rf data/*.db
npm run migrate && npm run seed
```

### Flutter build errors
```bash
cd app
flutter clean
flutter pub get
flutter run
```

### Backend not connecting from Flutter
- **Web/iOS Simulator**: Use `http://localhost:3000`
- **Android Emulator**: Use `http://10.0.2.2:3000`
- **Physical Device**: Use `http://YOUR_COMPUTER_IP:3000`

---

## 📚 Documentation

- **[README.md](README.md)** - Main documentation & setup
- **[TESTING.md](TESTING.md)** - Comprehensive testing guide
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - What's built
- **[backend/API.md](backend/API.md)** - API reference
- **[shared/ERD.md](shared/ERD.md)** - Database schema

---

## ✅ Testing Checklist

### Backend
- [ ] Server starts on port 3000
- [ ] Health endpoint responds
- [ ] Commodities API returns data
- [ ] Rates API returns data
- [ ] All tests pass (`npm test`)

### Flutter
- [ ] App builds successfully
- [ ] Home screen displays rates
- [ ] Pull-to-refresh works
- [ ] Error handling works
- [ ] Data updates automatically

### Integration
- [ ] Backend + Flutter work together
- [ ] Rates update every 15 seconds
- [ ] Alert system functional

---

## 💡 Tips

1. **Run in parallel**: Use 2 terminal windows (backend + flutter)
2. **Hot reload**: Press 'r' in Flutter terminal for instant updates
3. **Check logs**: Backend logs show rate fetcher activity
4. **Test independently**: Backend and frontend can be tested separately
5. **Use coverage**: Run `npm test -- --coverage` to see test coverage

---

Happy coding! 🎉
