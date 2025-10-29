# 🔔 Alert Implementation Plan

## Current State

### ✅ What's Already Working
1. **Backend Alert Checker**: Runs every 5 seconds, checks GOLD 999 alerts
2. **Notification Creation**: Creates notifications in database when alerts trigger
3. **Alert Tracking**: Marks alerts as `triggered_at` when conditions are met
4. **Database Schema**: `notifications` table exists with proper structure

### ❌ What's Missing
1. **API Endpoint**: No way to fetch notifications from frontend
2. **Frontend Polling**: App doesn't check for new notifications
3. **Notification Display**: No UI to show triggered alerts
4. **Local Notifications**: No push notifications on device
5. **Unread Count**: No badge showing pending notifications

---

## Implementation Plan

### Phase 1: Backend API (Required)

#### 1.1 Create Notifications Endpoint
**Endpoint**: `GET /api/gold999/notifications`
- Get all notifications for user's GOLD 999 alerts
- Filter by `alert_id` → `commodity_id = 2`
- Order by `sent_at DESC`
- Return unread count

**Response Format**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "alert_id": 5,
      "message": "GOLD 999 WITH GST dropped below ₹120,000 (Current: ₹119,850)",
      "sent_at": "2025-10-29T19:30:00Z",
      "delivered": true,
      "read": false,
      "alert": {
        "id": 5,
        "target_price": 120000,
        "condition": "<"
      }
    }
  ],
  "unread_count": 2
}
```

#### 1.2 Mark Notification as Read
**Endpoint**: `PUT /api/gold999/notifications/:id/read`
- Mark notification as read
- Track read status (might need to add `read` column or track separately)

#### 1.3 Get Unread Count
**Endpoint**: `GET /api/gold999/notifications/unread-count`
- Quick endpoint to check if there are new notifications
- Lightweight (~50 bytes)

---

### Phase 2: Frontend API Client (Required)

#### 2.1 Add Notification Methods to `gold999_client.dart`
```dart
Future<List<Notification>> getNotifications({int userId = 1})
Future<void> markNotificationAsRead(int notificationId)
Future<int> getUnreadCount({int userId = 1})
```

#### 2.2 Create Notification Model
```dart
class Notification {
  final int id;
  final int alertId;
  final String message;
  final DateTime sentAt;
  final bool delivered;
  final bool read;
  final Alert? alert;
}
```

---

### Phase 3: Frontend UI (Required)

#### 3.1 Notification Badge
- Add badge to Alerts tab showing unread count
- Show red dot/number if unread notifications exist

#### 3.2 Notification List Screen
- New screen/widget showing all notifications
- Group by date
- Show "Mark all as read" button
- Tap notification → Navigate to alert details

#### 3.3 In-App Notification Banner
- Show banner/popup when new notification arrives
- Auto-dismiss after 5 seconds
- Tap to go to notifications screen

---

### Phase 4: Local Notifications (Highly Recommended)

#### 4.1 Setup `flutter_local_notifications`
- Already in dependencies ✅
- Need to configure Android/iOS channels
- Request permissions

#### 4.2 Trigger Local Notification
- When poll detects new notification
- Show native notification
- Tap opens app to notification screen

#### 4.3 Notification Sound/Vibration
- Custom sound for alert triggers
- Vibration pattern

---

### Phase 5: Real-time Updates (Optional Enhancement)

#### 5.1 Polling Strategy
- Poll `/api/gold999/notifications/unread-count` every 5-10 seconds
- If count > 0, fetch full notifications
- Update UI automatically

#### 5.2 WebSocket/SSE (Future)
- Real-time push instead of polling
- More efficient but requires additional setup

---

## Implementation Steps

### Step 1: Backend API (Priority 1)
1. Create `notificationsController.js`
2. Add routes in `gold999.js`
3. Test with curl

### Step 2: Frontend API Client (Priority 1)
1. Add notification methods to `gold999_client.dart`
2. Create Notification model
3. Test API calls

### Step 3: Basic UI (Priority 2)
1. Add notification badge to Alerts tab
2. Create notification list widget
3. Integrate into Gold999Screen

### Step 4: Polling (Priority 2)
1. Add polling timer in Gold999Screen
2. Check for new notifications every 10 seconds
3. Update badge when new notifications arrive

### Step 5: Local Notifications (Priority 3)
1. Configure flutter_local_notifications
2. Request permissions
3. Show notification when alert triggers
4. Handle notification taps

---

## Database Changes Needed

### Option 1: Add `read` column to notifications table
```sql
ALTER TABLE notifications ADD COLUMN read BOOLEAN DEFAULT 0;
CREATE INDEX idx_notifications_read ON notifications(read, sent_at DESC);
```

### Option 2: Track reads separately (better for analytics)
```sql
CREATE TABLE notification_reads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  notification_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  read_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE
);
```

**Recommendation**: Option 1 (simpler, sufficient for current needs)

---

## API Endpoints to Add

### 1. Get Notifications
```
GET /api/gold999/notifications?userId=1&limit=50&unreadOnly=false
```

### 2. Mark as Read
```
PUT /api/gold999/notifications/:id/read
```

### 3. Mark All as Read
```
PUT /api/gold999/notifications/read-all?userId=1
```

### 4. Unread Count
```
GET /api/gold999/notifications/unread-count?userId=1
```

---

## Frontend Flow

### Initial Load
1. Load alerts list
2. Load notifications (with unread count)
3. Show badge if unread > 0

### Auto-Refresh
1. Poll unread count every 10 seconds
2. If count increased:
   - Fetch new notifications
   - Show in-app banner
   - Update badge
   - Trigger local notification (if enabled)

### User Interaction
1. Tap notification badge → Show notification list
2. Tap notification → Mark as read + show alert details
3. Swipe to dismiss
4. "Mark all as read" button

---

## Testing Strategy

### Backend Testing
```bash
# Create alert
curl -X POST http://localhost:3000/api/gold999/alerts \
  -H "Content-Type: application/json" \
  -d '{"condition": "<", "targetPrice": 120000}'

# Wait for alert to trigger (or manually trigger)

# Get notifications
curl http://localhost:3000/api/gold999/notifications

# Mark as read
curl -X PUT http://localhost:3000/api/gold999/notifications/1/read

# Get unread count
curl http://localhost:3000/api/gold999/notifications/unread-count
```

### Frontend Testing
1. Create alert with easily triggerable price
2. Wait for backend to trigger
3. Verify notification appears in app
4. Verify badge updates
5. Verify local notification (if implemented)
6. Test mark as read
7. Test "mark all as read"

---

## Priority Order

### Must Have (MVP)
1. ✅ Backend API endpoints
2. ✅ Frontend API client
3. ✅ Notification list UI
4. ✅ Unread badge
5. ✅ Polling for new notifications

### Should Have
6. ⚠️ Local notifications
7. ⚠️ In-app notification banner
8. ⚠️ Mark all as read

### Nice to Have
9. 🔮 WebSocket for real-time
10. 🔮 Notification sound customization
11. 🔮 Notification history/archive

---

## Estimated Effort

- **Backend API**: 1-2 hours
- **Frontend API Client**: 30 minutes
- **Basic UI**: 2-3 hours
- **Polling**: 1 hour
- **Local Notifications**: 2-3 hours
- **Testing**: 1-2 hours

**Total**: ~8-12 hours for complete implementation

---

## Next Steps

1. Start with Backend API (highest priority)
2. Test endpoints with curl
3. Implement Frontend API client
4. Build basic UI
5. Add polling
6. Add local notifications last

---

**Ready to implement?** Let's start with the backend API endpoints!

