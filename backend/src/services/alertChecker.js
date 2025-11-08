const cron = require('node-cron');
const { all, run, get } = require('../config/database');
const { getGold999CommodityId } = require('../controllers/gold999Controller');
const fcmService = require('./fcmService');
const { getTokensForNotification, removeInvalidTokens } = require('../controllers/fcmController');
const { formatForSQLite } = require('../utils/timezone');

let cronJob = null;
let cachedRate = null;
let cacheTimestamp = null;
let cachedCommodityId = null; // Cache the commodity ID
const CACHE_TTL = 5; // Cache rate for 5 seconds

/**
 * Get latest rate for GOLD 999 (with caching)
 */
async function getLatestRate(commodityId) {
  // Use cache if available and fresh
  if (cachedRate && cacheTimestamp &&
      commodityId === cachedCommodityId &&
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
  cachedRate = rate;
  cacheTimestamp = Date.now();
  cachedCommodityId = commodityId;

  return rate;
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
    // Calculate price change
    const priceDiff = Math.abs(currentPrice - alert.target_price);
    const changePercent = ((priceDiff / alert.target_price) * 100).toFixed(2);
    
    // Create engaging message based on condition
    let message;
    if (alert.condition === '<') {
      // Price dropped
      message = `🔔 Gold Alert: Price dropped to ₹${currentPrice.toLocaleString('en-IN')}! (Target: ₹${alert.target_price.toLocaleString('en-IN')})`;
    } else {
      // Price rose
      message = `🔔 Gold Alert: Price rose to ₹${currentPrice.toLocaleString('en-IN')}! (Target: ₹${alert.target_price.toLocaleString('en-IN')})`;
    }
    
    const istTimestamp = formatForSQLite();

    await run(
      `INSERT INTO notifications (alert_id, message, sent_at, delivered, read)
       VALUES (?, ?, ?, 1, 0)`,
      [alert.id, message, istTimestamp]
    );

    console.log(`🔔 Notification created: ${message}`);

    // Mark alert as triggered
    await run(
      `UPDATE alerts SET triggered_at = ? WHERE id = ?`,
      [istTimestamp, alert.id]
    );

    return { message, alertId: alert.id };
  } catch (error) {
    console.error('Error creating notification:', error.message);
    throw error;
  }
}

/**
 * Send FCM push notifications for triggered alerts
 */
async function sendFCMNotifications(triggeredAlerts) {
  if (!fcmService.isInitialized()) {
    console.log('⚠️  FCM not initialized, skipping push notifications');
    return;
  }

  for (const item of triggeredAlerts) {
    try {
      // Get FCM tokens for the user who set the alert
      const tokens = await getTokensForNotification(item.alert.user_id);

      if (tokens.length === 0) {
        console.log(`   No FCM tokens found for user ${item.alert.user_id}`);
        continue;
      }

      // Send FCM notification
      const result = await fcmService.sendAlertNotification(
        tokens,
        item.alert,
        item.currentPrice
      );

      // Remove invalid tokens if any
      if (result.invalidTokens && result.invalidTokens.length > 0) {
        await removeInvalidTokens(result.invalidTokens);
      }

      if (result.successCount > 0) {
        console.log(`✅ Sent ${result.successCount} FCM notification(s) for alert ${item.alert.id}`);
      }
    } catch (error) {
      console.error(`❌ Error sending FCM for alert ${item.alert.id}:`, error.message);
    }
  }
}

/**
 * Check all active alerts for GOLD 999 only
 */
async function checkAlerts() {
  try {
    const commodityId = await getGold999CommodityId();

    // Get latest rate once (cached)
    const latestRate = await getLatestRate(commodityId);

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
      [commodityId]
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
      
      // Send FCM push notifications
      await sendFCMNotifications(triggeredAlerts);
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
  console.log(`⚡ Note: Alerts are also checked immediately after each rate update for instant notifications`);

  // Initialize Firebase (if not already done)
  fcmService.initializeFirebase();

  // Check immediately on start
  checkAlerts();

  // Use setInterval for frequent checks (optimized for 1s refresh)
  // This acts as a backup in case the immediate trigger misses anything
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
