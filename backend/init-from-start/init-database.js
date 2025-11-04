/**
 * Database Initialization Script
 * 
 * This script creates the database schema from scratch.
 * Run this if shoprates.db gets deleted or corrupted.
 * 
 * Usage: node scripts/init-database.js
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const DB_PATH = path.resolve(__dirname, '../data/shoprates.db');
const DATA_DIR = path.resolve(__dirname, '../data');

console.log('🔧 Database Initialization Script');
console.log('==================================\n');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  console.log('📁 Creating data directory...');
  fs.mkdirSync(DATA_DIR, { recursive: true });
  console.log('✅ Data directory created\n');
}

// Check if database already exists
if (fs.existsSync(DB_PATH)) {
  console.log('⚠️  Database already exists at:', DB_PATH);
  console.log('⚠️  Delete it manually if you want to recreate it.\n');
  process.exit(0);
}

console.log('📦 Creating new database at:', DB_PATH);
console.log('');

const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('❌ Error creating database:', err.message);
    process.exit(1);
  }
  console.log('✅ Database file created\n');
});

// Enable foreign keys
db.run('PRAGMA foreign_keys = ON');

// Create tables
const schema = `
-- Commodities table
CREATE TABLE IF NOT EXISTS commodities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  unit TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rates table
CREATE TABLE IF NOT EXISTS rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  commodity_id INTEGER NOT NULL,
  ltp REAL NOT NULL,
  change REAL DEFAULT 0,
  change_percent REAL DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (commodity_id) REFERENCES commodities(id) ON DELETE CASCADE
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_rates_commodity_updated 
ON rates(commodity_id, updated_at DESC);

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fcm_token TEXT UNIQUE NOT NULL,
  device_type TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  commodity_id INTEGER NOT NULL,
  condition TEXT NOT NULL CHECK(condition IN ('<', '>')),
  target_price REAL NOT NULL,
  is_active BOOLEAN DEFAULT 1,
  triggered_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (commodity_id) REFERENCES commodities(id) ON DELETE CASCADE
);

-- Create index for faster alert queries
CREATE INDEX IF NOT EXISTS idx_alerts_active 
ON alerts(is_active, commodity_id);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  alert_id INTEGER,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data TEXT,
  sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (alert_id) REFERENCES alerts(id) ON DELETE SET NULL
);

-- Create index for faster notification queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_read 
ON notifications(user_id, read_at);

-- Insert GOLD 999 WITH GST commodity
INSERT INTO commodities (id, name, unit) 
VALUES (17, 'GOLD 999 WITH GST', 'per 10 grams');
`;

console.log('📋 Creating database schema...\n');

db.exec(schema, (err) => {
  if (err) {
    console.error('❌ Error creating schema:', err.message);
    db.close();
    process.exit(1);
  }

  console.log('✅ Schema created successfully!\n');
  console.log('📊 Tables created:');
  console.log('   ├─ commodities (with GOLD 999 WITH GST)');
  console.log('   ├─ rates');
  console.log('   ├─ users');
  console.log('   ├─ alerts');
  console.log('   └─ notifications\n');

  // Verify the setup
  db.get('SELECT * FROM commodities WHERE id = 17', (err, row) => {
    if (err) {
      console.error('❌ Error verifying setup:', err.message);
    } else if (row) {
      console.log('✅ Verified: GOLD 999 WITH GST commodity exists');
      console.log(`   ID: ${row.id}, Name: ${row.name}, Unit: ${row.unit}\n`);
    }

    db.close((err) => {
      if (err) {
        console.error('❌ Error closing database:', err.message);
        process.exit(1);
      }

      console.log('🎉 Database initialization complete!\n');
      console.log('📝 Next steps:');
      console.log('   1. Start the backend: npm start');
      console.log('   2. The rateFetcher will automatically start scraping prices');
      console.log('   3. Prices will be stored in the database\n');
      console.log('💡 Tip: Check backend logs to see rate fetching in action!');
    });
  });
});

