#!/bin/bash

# Live database viewer for Shop Rates
DB_PATH="./data/shoprates.db"

while true; do
  clear
  echo "═══════════════════════════════════════════════════════════════"
  echo "           📊 SHOP RATES DATABASE LIVE VIEWER"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  echo "🔹 Latest Rates (Last 6 entries):"
  echo "────────────────────────────────────────────────────────────────"
  sqlite3 "$DB_PATH" -header -column "
    SELECT
      c.name as Commodity,
      printf('₹%.2f', r.ltp) as LTP,
      printf('₹%.2f', r.buy_price) as Buy,
      printf('₹%.2f', r.sell_price) as Sell,
      r.updated_at as Updated
    FROM rates r
    JOIN commodities c ON r.commodity_id = c.id
    ORDER BY r.id DESC
    LIMIT 6;
  "

  echo ""
  echo "🔹 Total Rates Recorded: $(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM rates;")"
  echo ""

  echo "🔔 Active Alerts:"
  echo "────────────────────────────────────────────────────────────────"
  ALERT_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM alerts WHERE active = 1;")
  if [ "$ALERT_COUNT" -eq 0 ]; then
    echo "   No active alerts"
  else
    sqlite3 "$DB_PATH" -header -column "
      SELECT
        c.name as Commodity,
        a.condition as Condition,
        printf('₹%.2f', a.target_price) as 'Target Price',
        CASE WHEN a.triggered_at IS NULL THEN '⏳ Pending' ELSE '✅ Triggered' END as Status
      FROM alerts a
      JOIN commodities c ON a.commodity_id = c.id
      WHERE a.active = 1;
    "
  fi

  echo ""
  echo "📬 Recent Notifications (Last 5):"
  echo "────────────────────────────────────────────────────────────────"
  NOTIF_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM notifications;")
  if [ "$NOTIF_COUNT" -eq 0 ]; then
    echo "   No notifications yet"
  else
    sqlite3 "$DB_PATH" -header -column "
      SELECT
        message as Message,
        created_at as Time
      FROM notifications
      ORDER BY id DESC
      LIMIT 5;
    "
  fi

  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "Refreshing in 2 seconds... (Press Ctrl+C to exit)"
  echo "═══════════════════════════════════════════════════════════════"

  sleep 2
done
