# Shop Rates API Documentation

Base URL: `http://localhost:3000/api`

## 🪙 Commodities

### Get All Commodities
```http
GET /api/commodities
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "GOLD 995 WITH GST",
      "symbol": "XAU995",
      "unit": "1 KG",
      "type": "gold",
      "created_at": "2025-10-29T..."
    }
  ]
}
```

### Get Commodity by ID
```http
GET /api/commodities/:id
```

### Get Commodities by Type
```http
GET /api/commodities/type/:type
```
Types: `gold`, `silver`, `coin`

---

## 📈 Rates

### Get Latest Rates (All Commodities)
```http
GET /api/rates/latest
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 42,
      "commodity_id": 1,
      "commodity_name": "GOLD 995 WITH GST",
      "symbol": "XAU995",
      "unit": "1 KG",
      "type": "gold",
      "ltp": 122005.50,
      "buy_price": 122005.50,
      "sell_price": 122211.00,
      "high": 124018.00,
      "low": 120225.00,
      "updated_at": "2025-10-29T14:20:00Z",
      "source": "arihantspot.com"
    }
  ],
  "timestamp": "2025-10-29T14:20:00Z"
}
```

### Get Latest Rate for Specific Commodity
```http
GET /api/rates/:commodityId
```

### Get Rate History
```http
GET /api/rates/:commodityId/history?limit=100&offset=0
```

**Query Parameters:**
- `limit` (optional): Number of records (default: 100)
- `offset` (optional): Pagination offset (default: 0)

---

## 🔔 Alerts

### Get All Alerts
```http
GET /api/alerts?userId=1
```

**Query Parameters:**
- `userId` (optional): User ID (default: 1)

### Get Active Alerts
```http
GET /api/alerts/active?userId=1
```

### Get Alert by ID
```http
GET /api/alerts/:id
```

### Create Alert
```http
POST /api/alerts
Content-Type: application/json

{
  "userId": 1,
  "commodityId": 1,
  "condition": "<",
  "targetPrice": 120000
}
```

**Request Body:**
- `userId` (optional): User ID (default: 1)
- `commodityId` (required): Commodity ID
- `condition` (required): `"<"` or `">"`
- `targetPrice` (required): Price threshold

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 7,
    "user_id": 1,
    "commodity_id": 1,
    "commodity_name": "GOLD 995 WITH GST",
    "symbol": "XAU995",
    "condition": "<",
    "target_price": 120000,
    "active": 1,
    "created_at": "2025-10-29T...",
    "triggered_at": null
  },
  "message": "Alert created successfully"
}
```

### Update Alert
```http
PUT /api/alerts/:id
Content-Type: application/json

{
  "targetPrice": 121000,
  "active": true
}
```

**Request Body (all optional):**
- `condition`: `"<"` or `">"`
- `targetPrice`: New price threshold
- `active`: true/false

### Delete Alert
```http
DELETE /api/alerts/:id
```

---

## ⚙️ Preferences

### Get Preferences
```http
GET /api/preferences?userId=1
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "refresh_interval": 15,
    "currency": "INR",
    "notifications_on": 1,
    "theme": "light"
  }
}
```

### Create Preferences
```http
POST /api/preferences
Content-Type: application/json

{
  "userId": 1
}
```

### Update Preferences
```http
PUT /api/preferences?userId=1
Content-Type: application/json

{
  "refreshInterval": 30,
  "theme": "dark",
  "notificationsOn": true,
  "currency": "INR"
}
```

**Request Body (all optional):**
- `refreshInterval`: Seconds between rate fetches
- `currency`: Currency code
- `notificationsOn`: Enable/disable notifications
- `theme`: `"light"`, `"dark"`, or `"system"`

---

## 🏥 Health Check

### Server Health
```http
GET /health
```

**Response:**
```json
{
  "status": "OK",
  "timestamp": "2025-10-29T14:20:00Z",
  "uptime": 3600.5
}
```

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "success": false,
  "error": "Error message here"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `404` - Not Found
- `409` - Conflict
- `500` - Internal Server Error
