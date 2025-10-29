const cron = require('node-cron');
const { all, run, get } = require('../config/database');

let cronJob = null;

/**
 * Get latest rate for a commodity
 */
async function getLatestRate(commodityId) {
  const rate = await get(
    `SELECT * FROM rates
     WHERE commodity_id = ?
     ORDER BY updated_at DESC
     LIMIT 1`,
    [commodityId]
  );
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
    const conditionText = alert.condition === '<' ? 'dropped below' : 'rose above';
    const message = `${alert.commodity_name} ${conditionText} ₹${alert.target_price.toLocaleString()} (Current: ₹${currentPrice.toLocaleString()})`;

    await run(
      `INSERT INTO notifications (alert_id, message, sent_at, delivered)
       VALUES (?, ?, CURRENT_TIMESTAMP, 1)`,
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
  const interval = parseInt(process.env.CHECK_ALERTS_INTERVAL || 30);

  console.log(`🔔 Alert checker starting (every ${interval} seconds)`);

  // Check immediately on start
  checkAlerts();

  // Schedule regular checks
  if (interval < 60) {
    // Use setInterval for sub-minute intervals
    cronJob = setInterval(checkAlerts, interval * 1000);
  } else {
    // Use cron for minute-based intervals
    const minutes = Math.floor(interval / 60);
    cronJob = cron.schedule(`*/${minutes} * * * *`, checkAlerts);
  }
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
