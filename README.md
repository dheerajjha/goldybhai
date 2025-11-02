# Gold Price Tracker

A real-time gold price tracking application with push notifications for price alerts. Tracks **GOLD 999 WITH GST** prices with minimal network load and provides instant alerts when price thresholds are crossed.

## Features

- 📊 **Real-time Price Tracking**: Live gold price updates (GOLD 999 WITH GST only)
- 📈 **24-Hour Charts**: Visual price history with AM/PM time format
- 🔔 **Price Alerts**: Set custom price thresholds with push notifications
- 📱 **Push Notifications**: FCM-powered notifications (foreground, background, terminated)
- 🚀 **Lightweight**: Optimized network usage with caching
- 🌐 **Multi-platform**: iOS, Android, and Web support

## Tech Stack

### Backend
- **Node.js** + **Express.js**: REST API server
- **SQLite3**: Lightweight database
- **Firebase Admin SDK**: Push notification service
- **node-cron**: Scheduled tasks for price fetching and alert checking

### Frontend (Flutter)
- **Flutter**: Cross-platform mobile framework
- **Provider**: State management
- **Dio**: HTTP client with caching
- **fl_chart**: Beautiful charts
- **Firebase Messaging**: Push notifications
- **flutter_local_notifications**: Local notifications

### Web Consumer
- **HTML/CSS/JavaScript**: Simple web interface
- **Axios**: HTTP client
- Auto-refresh every 30 seconds

## Project Structure

```
goldybhai/
├── backend/                    # Node.js backend
│   ├── src/
│   │   ├── server.js          # Main server file
│   │   ├── database/          # Database migrations and setup
│   │   ├── services/          # Business logic (rate fetching, alerts, FCM)
│   │   ├── controllers/       # Request handlers
│   │   └── routes/            # API routes
│   ├── test-notification.js   # Test script for push notifications
│   ├── test-data-only.js      # Test script for data-only messages
│   └── package.json
│
├── app/                        # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── screens/           # UI screens
│   │   ├── services/          # API clients and FCM service
│   │   ├── models/            # Data models
│   │   └── widgets/           # Reusable UI components
│   ├── ios/                   # iOS configuration
│   ├── android/               # Android configuration
│   └── pubspec.yaml
│
└── web/                        # Web consumer
    ├── index.html             # Main web page
    ├── styles.css
    └── script.js
```

## Setup Instructions

### Prerequisites

- **Node.js** (v16 or higher)
- **Flutter** (v3.0 or higher)
- **Firebase Project** (for push notifications)
- **Apple Developer Account** (for iOS push notifications)

### Backend Setup

1. **Install dependencies**:
   ```bash
   cd backend
   npm install
   ```

2. **Configure Firebase**:
   - Place `firebase-service-account.json` in `backend/` directory
   - Get this from Firebase Console → Project Settings → Service Accounts

3. **Run database migrations**:
   ```bash
   npm run migrate
   ```

4. **Start the server**:
   ```bash
   npm start
   ```

   Server runs on `http://localhost:3000`

### Flutter App Setup

1. **Install dependencies**:
   ```bash
   cd app
   flutter pub get
   ```

2. **Configure Firebase**:
   - iOS: Place `GoogleService-Info.plist` in `app/ios/Runner/`
   - Android: Place `google-services.json` in `app/android/app/`

3. **Update backend URL** (for physical device):
   - Edit `app/lib/services/fcm_service.dart`
   - Edit `app/lib/services/gold999_client.dart`
   - Replace `localhost` with your machine's IP address

4. **Run the app**:
   ```bash
   flutter run
   ```

### Web Consumer Setup

1. **Update backend URL**:
   - Edit `web/script.js`
   - Set `API_URL` to your backend URL

2. **Open in browser**:
   ```bash
   open web/index.html
   ```

## API Endpoints

### Gold 999 Endpoints

```
GET  /api/gold999/current        # Get current LTP (ultra-lightweight)
GET  /api/gold999/chart          # Get 24-hour chart data
GET  /api/gold999/alerts         # Get all alerts
POST /api/gold999/alerts         # Create new alert
DELETE /api/gold999/alerts/:id   # Delete alert
```

### FCM Endpoints

```
POST /api/fcm/register           # Register FCM token
POST /api/fcm/unregister         # Unregister FCM token
```

## Test Scripts

### 1. Test Push Notifications

Send a test notification to a specific device:

```bash
cd backend
node test-notification.js "YOUR_FCM_TOKEN"
```

**What it does**:
- Sends a test notification with title and body
- Tests APNs authentication
- Verifies Firebase → Apple APNs connection
- Works for both foreground and background states

**Example**:
```bash
node test-notification.js "fEu5xPdH7kt3v1uXA_eBAB:APA91b..."
```

**Output**:
```
✅ Successfully sent notification: projects/gold-price-tracker-a04ef/messages/1762087109381721
Check your iPhone for the notification!
```

### 2. Test Data-Only Messages

Send a data-only message (bypasses APNs notification payload):

```bash
cd backend
node test-data-only.js "YOUR_FCM_TOKEN"
```

**What it does**:
- Sends a data-only message without notification payload
- Tests FCM connectivity without APNs
- Useful for debugging FCM vs APNs issues
- App receives data in background handler

### 3. Database Migration

Run database migrations to set up or update schema:

```bash
cd backend
npm run migrate
```

**What it does**:
- Creates `rates` table for price data
- Creates `alerts` table for user alerts
- Creates `notifications` table for notification history
- Creates `fcm_tokens` table for device tokens
- Idempotent (safe to run multiple times)

### 4. Start Backend Server

```bash
cd backend
npm start
```

**What it does**:
- Starts Express server on port 3000
- Initializes Firebase Admin SDK
- Starts cron jobs:
  - Fetches rates every 5 minutes
  - Checks alerts every minute
- Serves static web consumer files

## Environment Configuration

### Backend

The backend uses the following configuration:

- **Port**: 3000 (default)
- **Database**: `backend/src/database/database.sqlite`
- **Firebase**: `backend/firebase-service-account.json`

### Flutter App

For **physical device** testing, update the base URL in:

1. `app/lib/services/fcm_service.dart`:
   ```dart
   final String _baseUrl = 'http://YOUR_IP:3000';
   ```

2. `app/lib/services/gold999_client.dart`:
   ```dart
   Gold999Client({this.baseUrl = 'http://YOUR_IP:3000/api'})
   ```

Find your IP:
```bash
ifconfig en0 | grep "inet " | awk '{print $2}'
```

## Firebase Configuration

### Required Files

1. **Backend**: `firebase-service-account.json`
   - Download from: Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"

2. **iOS**: `GoogleService-Info.plist`
   - Download from: Firebase Console → Project Settings → General → iOS apps
   - Place in: `app/ios/Runner/`

3. **Android**: `google-services.json`
   - Download from: Firebase Console → Project Settings → General → Android apps
   - Place in: `app/android/app/`

### APNs Setup (iOS)

1. **Create APNs Key** in Apple Developer Console:
   - Go to: Certificates, Identifiers & Profiles → Keys
   - Create new key with "Apple Push Notifications service (APNs)"
   - Download `AuthKey_XXXXXXXXXX.p8`

2. **Upload to Firebase**:
   - Go to: Firebase Console → Cloud Messaging → Apple app configuration
   - Upload the `.p8` file
   - Enter Key ID and Team ID

3. **Enable in Xcode**:
   - Open `app/ios/Runner.xcworkspace`
   - Select Runner target → Signing & Capabilities
   - Add "Push Notifications" capability
   - Add "Background Modes" → Enable "Remote notifications"

## How It Works

### 1. Price Fetching

- Backend fetches gold prices every 5 minutes via cron job
- Stores in SQLite database with timestamp
- Provides lightweight API endpoints for clients

### 2. Price Alerts

- Users create alerts with target price and direction (above/below)
- Backend checks alerts every minute
- When triggered:
  - Creates notification record
  - Sends push notification via FCM
  - Marks alert as triggered

### 3. Push Notifications

**Flow**:
```
App Start → FCM Token Generated → Register with Backend → Store in Database
Alert Triggered → Backend sends FCM message → Firebase → APNs → iPhone
```

**States**:
- **Foreground**: Local notification displayed
- **Background**: Push notification from APNs
- **Terminated**: Push notification wakes app

### 4. Chart Data

- Backend aggregates price data for last 24 hours
- Returns hourly data points
- Flutter app renders with `fl_chart`
- Time formatted in AM/PM

## Troubleshooting

### Push Notifications Not Working

1. **Check FCM token registration**:
   ```bash
   # Look for this in app logs:
   flutter: 📱 FCM Token: ...
   flutter: ✅ FCM token registered successfully
   ```

2. **Test with script**:
   ```bash
   node test-notification.js "YOUR_TOKEN"
   ```

3. **Verify APNs setup**:
   - Check Firebase Console → Cloud Messaging → APNs Authentication Key
   - Verify Key ID and Team ID match Apple Developer account

4. **Check iOS capabilities**:
   - Push Notifications enabled in Xcode
   - Background Modes → Remote notifications enabled

### App Not Connecting to Backend

1. **For physical device**, use IP address instead of `localhost`
2. **Check firewall**: Ensure port 3000 is accessible
3. **Verify backend is running**: `curl http://localhost:3000/api/gold999/current`

### Database Issues

1. **Reset database**:
   ```bash
   rm backend/src/database/database.sqlite
   npm run migrate
   ```

2. **Check migrations**: Look at `backend/src/database/migrate.js`

## Development

### Adding New Features

1. **Backend**: Add routes in `backend/src/routes/`
2. **Flutter**: Add screens in `app/lib/screens/`
3. **Services**: Add business logic in respective `services/` folders

### Code Style

- **Backend**: ESLint with standard config
- **Flutter**: Follow Flutter style guide
- **Commits**: Use conventional commits

## License

MIT License - feel free to use this project for learning or commercial purposes.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Firebase Console for configuration issues
3. Check backend logs for API errors
4. Review Flutter logs for client-side issues

---

**Built with ❤️ for real-time gold price tracking**
