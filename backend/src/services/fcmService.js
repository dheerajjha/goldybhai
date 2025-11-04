const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let initialized = false;

/**
 * Initialize Firebase Admin SDK
 */
function initializeFirebase() {
  if (initialized) {
    return;
  }

  try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || 
                              path.join(__dirname, '../../firebase-service-account.json');

    if (!fs.existsSync(serviceAccountPath)) {
      console.warn('⚠️  Firebase service account file not found:', serviceAccountPath);
      console.warn('   Push notifications will be disabled. See FCM_SETUP_GUIDE.md');
      return;
    }

    const serviceAccount = require(serviceAccountPath);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    initialized = true;
    console.log('✅ Firebase Admin SDK initialized');
  } catch (error) {
    console.error('❌ Firebase Admin SDK initialization failed:', error.message);
    console.error('   Push notifications will be disabled. See FCM_SETUP_GUIDE.md');
  }
}

/**
 * Send FCM notification to a single token
 * @param {string} token - FCM token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Additional data payload
 * @returns {Promise<object>} Response from FCM
 */
async function sendNotification(token, title, body, data = {}) {
  if (!initialized) {
    console.warn('⚠️  Firebase not initialized, skipping FCM notification');
    return null;
  }

  try {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        // Ensure all data values are strings (FCM requirement)
        timestamp: Date.now().toString(),
      },
      token: token,
      // Android-specific options
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'gold_alerts',
        },
      },
      // iOS-specific options
      apns: {
        headers: {
          'apns-priority': '10', // High priority for immediate delivery
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
            'content-available': 1, // Enable background notification delivery
            'mutable-content': 1, // Allow notification modification
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log('✅ FCM notification sent successfully:', response);
    return response;
  } catch (error) {
    console.error('❌ FCM notification failed:', error.message);
    
    // Handle invalid token
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      console.log('   Token is invalid, should be removed from database');
      return { invalidToken: true, error: error.message };
    }
    
    return { error: error.message };
  }
}

/**
 * Send FCM notification to multiple tokens
 * @param {string[]} tokens - Array of FCM tokens
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Additional data payload
 * @returns {Promise<object>} Results with success/failure counts
 */
async function sendMulticastNotification(tokens, title, body, data = {}) {
  if (!initialized) {
    console.warn('⚠️  Firebase not initialized, skipping FCM notification');
    return { successCount: 0, failureCount: tokens.length };
  }

  if (!tokens || tokens.length === 0) {
    return { successCount: 0, failureCount: 0 };
  }

  try {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        timestamp: Date.now().toString(),
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'gold_alerts',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10', // High priority for immediate delivery
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
            'content-available': 1, // Enable background notification delivery
            'mutable-content': 1, // Allow notification modification
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      ...message,
    });

    console.log(`✅ FCM multicast: ${response.successCount} succeeded, ${response.failureCount} failed`);

    // Check for invalid tokens to remove
    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && 
            (resp.error?.code === 'messaging/invalid-registration-token' ||
             resp.error?.code === 'messaging/registration-token-not-registered')) {
          invalidTokens.push(tokens[idx]);
        }
      });
      
      if (invalidTokens.length > 0) {
        console.log(`   Found ${invalidTokens.length} invalid tokens to remove`);
        return {
          successCount: response.successCount,
          failureCount: response.failureCount,
          invalidTokens: invalidTokens,
        };
      }
    }

    return {
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('❌ FCM multicast failed:', error.message);
    return {
      successCount: 0,
      failureCount: tokens.length,
      error: error.message,
    };
  }
}

/**
 * Send notification for a triggered alert
 * @param {string[]} tokens - Array of FCM tokens
 * @param {object} alert - Alert object with commodity info
 * @param {number} currentPrice - Current LTP that triggered the alert
 * @returns {Promise<object>} Send result
 */
async function sendAlertNotification(tokens, alert, currentPrice) {
  // Calculate price change
  const priceDiff = Math.abs(currentPrice - alert.target_price);
  const changePercent = ((priceDiff / alert.target_price) * 100).toFixed(2);
  
  // Create engaging title and body
  let title, body;
  
  if (alert.condition === '<') {
    // Price dropped
    title = '📉 Gold Price Alert!';
    body = `Price dropped to ₹${currentPrice.toLocaleString('en-IN')} (Your target: ₹${alert.target_price.toLocaleString('en-IN')})`;
  } else {
    // Price rose
    title = '📈 Gold Price Alert!';
    body = `Price rose to ₹${currentPrice.toLocaleString('en-IN')} (Your target: ₹${alert.target_price.toLocaleString('en-IN')})`;
  }
  
  const data = {
    type: 'alert',
    alertId: alert.id.toString(),
    commodityId: alert.commodity_id.toString(),
    currentPrice: currentPrice.toString(),
    targetPrice: alert.target_price.toString(),
    condition: alert.condition,
    priceDiff: priceDiff.toString(),
    changePercent: changePercent,
  };

  return await sendMulticastNotification(tokens, title, body, data);
}

module.exports = {
  initializeFirebase,
  sendNotification,
  sendMulticastNotification,
  sendAlertNotification,
  isInitialized: () => initialized,
};


