require('dotenv').config();
const { initDatabase, run, closeDatabase } = require('../config/database');

const migrations = [
  // 1. Create users table
  `CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`,

  // 2. Create commodities table
  `CREATE TABLE IF NOT EXISTS commodities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    symbol TEXT UNIQUE NOT NULL,
    unit TEXT NOT NULL DEFAULT '1 KG',
    type TEXT NOT NULL CHECK(type IN ('gold', 'silver', 'coin')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`,

  // 3. Create rates table
  `CREATE TABLE IF NOT EXISTS rates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    commodity_id INTEGER NOT NULL,
    ltp REAL,
    buy_price REAL,
    sell_price REAL,
    high REAL,
    low REAL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    source TEXT DEFAULT 'arihantspot.com',
    FOREIGN KEY (commodity_id) REFERENCES commodities(id) ON DELETE CASCADE
  )`,

  // 4. Create alerts table
  `CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    commodity_id INTEGER NOT NULL,
    condition TEXT NOT NULL CHECK(condition IN ('<', '>')),
    target_price REAL NOT NULL,
    active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    triggered_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (commodity_id) REFERENCES commodities(id) ON DELETE CASCADE
  )`,

  // 5. Create preferences table
  `CREATE TABLE IF NOT EXISTS preferences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER UNIQUE NOT NULL,
    refresh_interval INTEGER DEFAULT 15,
    currency TEXT DEFAULT 'INR',
    notifications_on BOOLEAN DEFAULT 1,
    theme TEXT DEFAULT 'light' CHECK(theme IN ('light', 'dark', 'system')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  )`,

  // 6. Create notifications table (optional)
  `CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    alert_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    delivered BOOLEAN DEFAULT 0,
    FOREIGN KEY (alert_id) REFERENCES alerts(id) ON DELETE CASCADE
  )`,

  // 7. Create indexes for performance
  `CREATE INDEX IF NOT EXISTS idx_rates_commodity_updated
   ON rates(commodity_id, updated_at DESC)`,

  `CREATE INDEX IF NOT EXISTS idx_alerts_user_active
   ON alerts(user_id, active)`,

  `CREATE INDEX IF NOT EXISTS idx_alerts_commodity
   ON alerts(commodity_id)`,

  `CREATE INDEX IF NOT EXISTS idx_notifications_alert
   ON notifications(alert_id, sent_at DESC)`,

  // 8. Add read column to notifications table (if not exists)
  // Note: SQLite doesn't support IF NOT EXISTS for ALTER TABLE ADD COLUMN
  // We'll handle this in code below

  `CREATE INDEX IF NOT EXISTS idx_notifications_read
   ON notifications(read, sent_at DESC)`
];

async function migrate() {
  try {
    console.log('Starting database migration...');
    await initDatabase();

    // Check if read column exists, add if not
    try {
      await run(`SELECT read FROM notifications LIMIT 1`);
      console.log('   read column already exists, skipping...');
    } catch (e) {
      console.log('   Adding read column to notifications table...');
      await run(`ALTER TABLE notifications ADD COLUMN read BOOLEAN DEFAULT 0`);
    }

    for (let i = 0; i < migrations.length; i++) {
      console.log(`Running migration ${i + 1}/${migrations.length}...`);
      try {
        await run(migrations[i]);
      } catch (error) {
        // Skip if already exists (for CREATE IF NOT EXISTS)
        if (error.message.includes('already exists') || 
            error.message.includes('duplicate column')) {
          console.log(`   Skipping (already exists): ${error.message}`);
          continue;
        }
        throw error;
      }
    }

    console.log('✅ Migration completed successfully!');
    await closeDatabase();
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    await closeDatabase();
    process.exit(1);
  }
}

// Run migration if this file is executed directly
if (require.main === module) {
  migrate();
}

module.exports = migrate;
