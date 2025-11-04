# Database Recovery Guide

## What to do if `shoprates.db` gets deleted?

Don't panic! The database can be easily recreated from scratch. The backend will automatically start populating it with fresh data.

---

## Quick Recovery (Automatic)

**Option 1: Just restart the backend**

If the database file is deleted, simply restart the backend and it will automatically create the database structure:

```bash
cd backend
pm2 restart goldybhai-backend
# or
npm start
```

The backend's `initDatabase()` function will:
1. Create a new `shoprates.db` file
2. Set up all tables (commodities, rates, users, alerts, notifications)
3. The `rateFetcher` will start scraping and populating prices automatically

**That's it!** Within 1-2 minutes, you'll have fresh price data.

---

## Manual Recovery (If needed)

**Option 2: Use the initialization script**

We've created a dedicated script to rebuild the database:

```bash
cd backend

# Make sure the old database is deleted (if corrupted)
rm -f data/shoprates.db

# Run the initialization script
node scripts/init-database.js
```

This script will:
- ✅ Create the `data/` directory if missing
- ✅ Create a new `shoprates.db` file
- ✅ Set up all tables with proper schema
- ✅ Insert the GOLD 999 WITH GST commodity (ID: 17)
- ✅ Create all necessary indexes for performance

Then start the backend:
```bash
npm start
# or
pm2 restart goldybhai-backend
```

---

## What Gets Lost?

When the database is deleted, you lose:

### ❌ Lost Data:
- Historical price data
- User FCM tokens (users need to reopen the app to re-register)
- Active alerts (users need to recreate them)
- Notification history

### ✅ Preserved:
- Backend code and configuration
- Firebase service account (for FCM)
- App functionality (nothing breaks)
- User experience (app continues to work)

---

## What Happens After Recovery?

1. **Immediate (0-1 minute):**
   - Database structure is created
   - Backend starts successfully

2. **Within 1-2 minutes:**
   - `rateFetcher` scrapes first price from Arihant Capital
   - First rate is stored in database
   - App starts showing live prices

3. **Within 5-10 minutes:**
   - Enough data for 1-hour chart to populate
   - Chart becomes visible in the app

4. **User Actions Required:**
   - Users need to reopen the app (to register FCM token)
   - Users need to recreate their price alerts

---

## Prevention Tips

### Backup Strategy:

**Option 1: Periodic Backups**
```bash
# Create a backup script
cd backend
cp data/shoprates.db data/backups/shoprates-$(date +%Y%m%d-%H%M%S).db
```

**Option 2: Automated Daily Backups**
```bash
# Add to crontab (runs daily at 2 AM)
0 2 * * * cd /path/to/backend && cp data/shoprates.db data/backups/shoprates-$(date +\%Y\%m\%d).db
```

**Option 3: Keep Multiple Days**
```bash
# Keep last 7 days of backups
cd backend/data/backups
ls -t shoprates-*.db | tail -n +8 | xargs rm -f
```

### Restore from Backup:
```bash
cd backend
pm2 stop goldybhai-backend
cp data/backups/shoprates-20250104.db data/shoprates.db
pm2 start goldybhai-backend
```

---

## Troubleshooting

### Issue: "Database is locked"
```bash
# Stop all processes using the database
pm2 stop goldybhai-backend
# Wait a few seconds
sleep 3
# Delete and recreate
rm -f data/shoprates.db
node scripts/init-database.js
pm2 start goldybhai-backend
```

### Issue: "Table already exists"
This means the database file exists but is corrupted. Delete it first:
```bash
rm -f data/shoprates.db
node scripts/init-database.js
```

### Issue: "No such file or directory: data/"
The script will create it automatically, but you can also:
```bash
mkdir -p backend/data
node scripts/init-database.js
```

---

## Database Schema Reference

For reference, here's what gets created:

```sql
-- Commodities (stores gold types)
commodities: id, name, unit, created_at

-- Rates (stores price history)
rates: id, commodity_id, ltp, change, change_percent, updated_at

-- Users (stores FCM tokens)
users: id, fcm_token, device_type, created_at, updated_at

-- Alerts (stores user price alerts)
alerts: id, user_id, commodity_id, condition, target_price, 
        is_active, triggered_at, created_at

-- Notifications (stores notification history)
notifications: id, user_id, alert_id, title, body, data, 
               sent_at, read_at
```

---

## Summary

**TL;DR:**
1. Database deleted? → Just restart backend: `pm2 restart goldybhai-backend`
2. Corrupted database? → Delete and run: `node scripts/init-database.js`
3. Want backups? → Copy `data/shoprates.db` periodically
4. Lost data? → Users reopen app, recreate alerts, fresh prices in 1-2 minutes

The system is designed to be resilient and self-healing! 🚀

