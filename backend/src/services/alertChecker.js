const cron = require('node-cron');
const { all, run, get } = require('../config/database');
const { GOLD999_COMMODITY_ID } = require('../controllers/gold999Controller');

let cronJob = null;
let cachedRate = null;
let cacheTimestamp = null;
const CACHE_TTL = 5; // Cache rate for 5 seconds

/**
 * Get latest rate for GOLD 999 (with caching)
 */
async function getLatestRate(commodityId) {
  // Use cache if available and fresh
  if (cachedRate && cacheTimestamp && 
      commodityId === GOLD999_COMMODITY_ID &&
      Date.now() - cacheTimestamp < CACHE_TTL * 1000) {
    return cachedRate;
  }

  const rate = await get(
    `SELECT * FROM rates
     WHERE commodity_id = ?
     ORDER BY updated_at DESC
     LIMIT 1`,
    [commodityId]
  );

  // Cache for GOLD 999
  if (commodityId === GOLD999_COMMODITY_ID) {
    cachedRate = rate;
    cacheTimestamp = Date.now();
  }

  return rate;
}

/**
 * Check all active alerts for GOLD 999 only
 */
async function checkAlerts() {
  try {
    // Get latest rate once (cached)
    const latestRate = await getLatestRate(GOLD999_COMMODITY_ID);
    
    if (!latestRate) {
      return [];
    }

    const currentPrice = latestRate.ltp;

    // Get only GOLD 999 active alerts that haven't been triggered
    const alerts = await all(
      `SELECT
         a.id,
         a.user_id,
         a.commodity_id,
         a.condition,
         a.target_price,
         c.name as commodity_name,
         c.symbol
       FROM alerts a
       JOIN commodities c ON a.commodity_id = c.id
       WHERE a.commodity_id = ?
         AND a.active = 1 
         AND a.triggered_at IS NULL`,
      [GOLD999_COMMODITY_ID]
    );

    if (alerts.length === 0) {
      return [];
    }

    const triggeredAlerts = [];

    // Batch check all alerts with same price
    for (const alert of alerts) {
      if (isAlertTriggered(alert, currentPrice)) {
        const notification = await createNotification(alert, currentPrice);
        triggeredAlerts.push({
          alert,
          notification,
          currentPrice
        });
      }
    }

    if (triggeredAlerts.length > 0) {
      console.log(`✅ ${triggeredAlerts.length} GOLD 999 alert(s) triggered`);
    }

    return triggeredAlerts;
  } catch (error) {
    console.error('❌ Error checking alerts:', error.message);
    return [];
  }
}

/**
 * Check if alert condition is met
 */
function isAlertTriggered(alert, currentPrice) {
  if (!currentPrice) return false;

  if (alert.condition === '<') {
    return currentPrice <= alert.target_price;
  } else if (alert.condition === '>') {
    return currentPrice >= alert.target_price;
  }

  return false;
}

/**
 * Create notification for triggered alert
 */
async function createNotification(alert, currentPrice) {
  try {
    const conditionText = alert.condition === '<' ? 'dropped below' : 'rose above';
    const message = `${alert.commodity_name} ${conditionText} ₹${alert.target_price.toLocaleString()} (Current: ₹${currentPrice.toLocaleString()})`;

    await run(
      `INSERT INTO notifications (alert_id, message, sent_at, delivered, read)
       VALUES (?, ?, CURRENT_TIMESTAMP, 1, 0)`,
      [alert.id, message]
    );

    console.log(`🔔 Notification created: ${message}`);

    // Mark alert as triggered
    await run(
      `UPDATE alerts SET triggered_at = CURRENT_TIMESTAMP WHERE id = ?`,
      [alert.id]
    );

    return { message, alertId: alert.id };
  } catch (error) {
    console.error('Error creating notification:', error.message);
    throw error;
  }
}

/**
 * Check all active alerts
 */
async function checkAlerts() {
  try {
    console.log('🔍 Checking alerts...');

    // Get all active alerts that haven't been triggered
    const alerts = await all(
      `SELECT
         a.id,
         a.user_id,
         a.commodity_id,
         a.condition,
         a.target_price,
         c.name as commodity_name,
         c.symbol
       FROM alerts a
       JOIN commodities c ON a.commodity_id = c.id
       WHERE a.active = 1 AND a.triggered_at IS NULL`
    );

    if (alerts.length === 0) {
      console.log('   No active alerts to check');
      return [];
    }

    console.log(`   Checking ${alerts.length} active alert(s)...`);

    const triggeredAlerts = [];

    for (const alert of alerts) {
      // Get latest rate for this commodity
      const latestRate = await getLatestRate(alert.commodity_id);

      if (!latestRate) {
        console.log(`   ⚠️  No rate data for ${alert.commodity_name}`);
        continue;
      }

      // Check if alert is triggered
      const currentPrice = latestRate.ltp || latestRate.buy_price;

      if (isAlertTriggered(alert, currentPrice)) {
        console.log(`   🎯 Alert triggered: ${alert.commodity_name} ${alert.condition} ${alert.target_price}`);

        const notification = await createNotification(alert, currentPrice);
        triggeredAlerts.push({
          alert,
          notification,
          currentPrice
        });
      }
    }

    if (triggeredAlerts.length > 0) {
      console.log(`✅ ${triggeredAlerts.length} alert(s) triggered`);
    } else {
      console.log('   ✓ No alerts triggered');
    }

    return triggeredAlerts;
  } catch (error) {
    console.error('❌ Error checking alerts:', error.message);
    return [];
  }
}

/**
 * Start the alert checker cron job
 */
function start() {
  const interval = parseInt(process.env.CHECK_ALERTS_INTERVAL || 5); // Check every 5 seconds

  console.log(`🔔 Alert checker starting (every ${interval} seconds) - GOLD 999 only`);

  // Check immediately on start
  checkAlerts();

  // Use setInterval for frequent checks (optimized for 1s refresh)
  cronJob = setInterval(checkAlerts, interval * 1000);
}

/**
 * Stop the alert checker
 */
function stop() {
  if (cronJob) {
    if (typeof cronJob === 'object' && cronJob.stop) {
      cronJob.stop();
    } else {
      clearInterval(cronJob);
    }
    console.log('🛑 Alert checker stopped');
  }
}

/**
 * Check alerts once (manual trigger)
 */
async function checkOnce() {
  return await checkAlerts();
}

module.exports = {
  start,
  stop,
  checkOnce,
  checkAlerts
};
